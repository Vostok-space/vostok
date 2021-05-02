#!/bin/bash

RESULT=result/benchmark
GCDA=$RESULT/gcda

generate() {
	rm -rf $RESULT
	mkdir -p $RESULT/asrt $RESULT/san $RESULT/java $RESULT/js
	SOURCE="-m source/blankJava -m source/blankOberon -m source/blankJs -m source/en-only -m source"
	NOCHECK="-init noinit -no-array-index-check -no-nil-check -no-arithmetic-overflow-check"
	result/ost to-c "RepeatTran.Go(10)" $RESULT/asrt -infr . $SOURCE -m test/benchmark
	result/ost to-c "RepeatTran.Go(10)" $RESULT/san  -infr . $SOURCE -m test/benchmark $NOCHECK

	result/ost to-class "RepeatTran.Go(10)" $RESULT/java -infr . $SOURCE -m test/benchmark
	result/ost to-js "RepeatTran.Go(1)" $RESULT/ost.js -infr . $SOURCE -m test/benchmark
	result/ost to-js "RepeatTran.Go(1)" $RESULT/ost-nai.js -infr . $SOURCE -m test/benchmark -no-array-index-check
	result/ost to-js "RepeatTran.Go(1)" $RESULT/ost-naiao.js -infr . $SOURCE -m test/benchmark -no-array-index-check -no-arithmetic-overflow-check
}

export ASAN_OPTIONS=detect_odr_violation=0

LIST_OST="ost ost-asrt ost-usan ost-asan ost-uasan ost-uasan-asrt"

compile() {
	SI=singularity/implementation
	CFILES="$SI/o7.c $SI/CFiles.c $SI/CLI.c $SI/Platform.c $SI/OsEnv.c $SI/OsExec.c $SI/Unistd_.c $SI/CDir.c $SI/Wlibloaderapi.c"
	CC=gcc
	MAIN="$CC -O3 -flto -s -DO7_MEMNG_MODEL=O7_MEMNG_NOFREE -Isingularity/implementation $CFILES"
	if [[ $CC == clang* ]]; then
		TRAP="-fsanitize-undefined-trap-on-error"
	else
		TRAP="-fsanitize-undefined-trap-on-error -static-libasan"
	fi
	USAN="-fsanitize=undefined -fno-sanitize=alignment"
	ASAN="-fsanitize=address -DO7_LSAN_LEAK_IGNORE"
	INIT_NO="-DNDEBUG -DO7_INIT_MODEL=O7_INIT_NO"
	INIT_UNDEF="-DO7_INIT_MODEL=O7_INIT_UNDEF -DO7_ASSERT_NO_MESSAGE"

	NPROC=`nproc || sysctl -n hw.ncpu`

	PROFILE="$1 -fprofile-dir=$GCDA"
	PROFILE_ASRT="$PROFILE-asrt"
	PROFILE_UASAN_ASRT="$PROFILE-uasan-asrt"
	PROFILE_UASAN="$PROFILE-uasan"
	PROFILE_ASAN="$PROFILE-asan"
	PROFILE_USAN="$PROFILE-usan"
	if [[ $CC == clang* ]]; then
		if [[ $1 == "-fprofile-generate" ]]; then
			PROFILE=-fprofile-instr-generate
		fi
		if [[ $1 == "-fprofile-use" ]]; then
			for ost in $LIST_OST; do
				llvm-profdata merge $RESULT/$ost.profraw -output=$RESULT/$ost.profdata
			done
			PROFILE=-fprofile-instr-use=$RESULT/ost.profdata
			PROFILE_ASRT=-fprofile-instr-use=$RESULT/ost-asrt.profdata
			PROFILE_UASAN_ASRT=-fprofile-instr-use=$RESULT/ost-uasan-asrt.profdata
			PROFILE_UASAN=-fprofile-instr-use=$RESULT/ost-uasan.profdata
			PROFILE_ASAN=-fprofile-instr-use=$RESULT/ost-asan.profdata
			PROFILE_USAN=-fprofile-instr-use=$RESULT/ost-usan.profdata
		fi
	else if [[ $CC == ccomp ]]; then
		PROFILE=
	fi fi
	if [[ $PROFILE == -fprofile-instr-generate ]] || [[ $PROFILE == "" ]]; then
		PROFILE_ASRT=$PROFILE
		PROFILE_UASAN_ASRT=$PROFILE
		PROFILE_UASAN=$PROFILE
		PROFILE_ASAN=$PROFILE
		PROFILE_USAN=$PROFILE
	fi
	ASRT_SET="$INIT_UNDEF -I$RESULT/asrt $RESULT/asrt/*.c"
	SAN_SET="$INIT_NO -I$RESULT/san $RESULT/san/*.c"
	# parallelize compilation
	echo \
	"$MAIN $PROFILE_ASRT $ASRT_SET -o $RESULT/ost-asrt" \
	,\
	"$MAIN $PROFILE_UASAN_ASRT $ASRT_SET $USAN $ASAN $TRAP -o $RESULT/ost-uasan-asrt" \
	,\
	"$MAIN $PROFILE_UASAN $SAN_SET $USAN $ASAN $TRAP -o $RESULT/ost-uasan" \
	,\
	"$MAIN $PROFILE_ASAN $SAN_SET $ASAN $TRAP -o $RESULT/ost-asan" \
	,\
	"$MAIN $PROFILE_USAN $SAN_SET $USAN $TRAP -o $RESULT/ost-usan" \
	,\
	"$MAIN $PROFILE $SAN_SET -o $RESULT/ost" \
	| xargs -d , -n 1 -P $NPROC sh -c
}

runc() {
	for ost in $LIST_OST; do
		if [ -f $RESULT/$ost ]; then
			echo
			ls -l $RESULT/$ost
			mkdir -p /tmp/ost-bench-$ost
			for i in $@; do
				LLVM_PROFILE_FILE="$RESULT/$ost.profraw" \
				/usr/bin/time -f '%e sec  %M KiB' \
					$RESULT/$ost to-c "Translator.Go" /tmp/ost-bench-$ost -infr . -m source
			done
			crc32 <(cat /tmp/ost-bench-$ost/*)
			rm -r /tmp/ost-bench-$ost
		fi
	done
}

runjs() {
	mkdir -p /tmp/ost-bench-js

	echo
	for tr in ost ost-nai ost-naiao; do
		ls -l $RESULT/$tr.js
		/usr/bin/time -f '%e sec  %M KiB' \
			node $RESULT/$tr.js to-c "Translator.Go" /tmp/ost-bench-js -infr . -m source
		crc32 <(cat /tmp/ost-bench-js/*)
	done

	rm -r /tmp/ost-bench-js
}

runjava() {
	mkdir -p /tmp/ost-bench-java

	echo
	echo java classes
	for i in $@; do
		/usr/bin/time -f '%e sec  %M KiB' \
			java -cp result/benchmark/java \
				o7.script to-c "Translator.Go" /tmp/ost-bench-java -infr . -m source
	done
	crc32 <(cat /tmp/ost-bench-java/*)

	rm -r /tmp/ost-bench-java
}

compile_with_profile() {
	DIRS="$GCDA $GCDA-asrt $GCDA-usan $GCDA-asan $GCDA-uasan $GCDA-uasan-asrt"
	mkdir -p $DIRS

	echo Compiles and runs for profiling
	compile -fprofile-generate
	runc 0

	echo Compiles using profiling
	compile -fprofile-use
}

generate
compile_with_profile
runc 0 1 2 3 4
runjava 0 1 2 3 4
runjs

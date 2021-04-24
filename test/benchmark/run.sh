#!/bin/bash

RESULT=result/benchmark
GCDA=$RESULT/gcda

generate() {
	rm -rf $RESULT
	mkdir -p $RESULT/asrt $RESULT/san
	result/ost to-c "RepeatTran.Go(10)" $RESULT/asrt -infr . -m source -m test/benchmark
	result/ost to-c "RepeatTran.Go(10)" $RESULT/san  -infr . -m source -m test/benchmark \
	           -init noinit -no-array-index-check -no-nil-check -no-arithmetic-overflow-check
}

export ASAN_OPTIONS=detect_odr_violation=0

compile() {
	SI=singularity/implementation
	CFILES="$SI/o7.c $SI/CFiles.c $SI/CLI.c $SI/Platform.c $SI/OsEnv.c $SI/OsExec.c $SI/Unistd_.c $SI/CDir.c $SI/Wlibloaderapi.c"
	MAIN="gcc -O3 -flto -s -DO7_MEMNG_MODEL=O7_MEMNG_NOFREE -Isingularity/implementation $CFILES"
	TRAP="-fsanitize-undefined-trap-on-error -static-libasan"
	USAN="-fsanitize=undefined -fno-sanitize=alignment"
	ASAN="-fsanitize=address -DO7_LSAN_LEAK_IGNORE"
	INIT_NO="-DNDEBUG -DO7_INIT_MODEL=O7_INIT_NO"
	INIT_UNDEF="-DO7_INIT_MODEL=O7_INIT_UNDEF -DO7_ASSERT_NO_MESSAGE"

	NPROC=`nproc || sysctl -n hw.ncpu`

	PROFILE="$1 -fprofile-dir=$GCDA"

	# parallelize compilation
	echo \
"$MAIN $PROFILE-asrt $INIT_UNDEF -I$RESULT/asrt $RESULT/asrt/*.c -o $RESULT/ost-asrt" \
,\
"$MAIN $PROFILE-uasan-asrt $INIT_UNDEF -I$RESULT/asrt $RESULT/asrt/*.c $USAN $ASAN $TRAP -o $RESULT/ost-uasan-asrt" \
,\
"$MAIN $PROFILE-uasan $INIT_NO -I$RESULT/san $RESULT/san/*.c $USAN $ASAN $TRAP -o $RESULT/ost-uasan" \
,\
"$MAIN $PROFILE-asan $INIT_NO -I$RESULT/san $RESULT/san/*.c $ASAN $TRAP -o $RESULT/ost-asan" \
,\
"$MAIN $PROFILE-usan $INIT_NO -I$RESULT/san $RESULT/san/*.c $USAN $TRAP -o $RESULT/ost-usan" \
,\
"$MAIN $PROFILE $INIT_NO -I$RESULT/san $RESULT/san/*.c -o $RESULT/ost" \
	| xargs -d , -n 1 -P $NPROC sh -c
}

run() {
	LIST="ost ost-asrt ost-usan ost-asan ost-uasan ost-uasan-asrt"

	for ost in $LIST; do
		if [ -f $RESULT/$ost ]; then
			echo
			ls -l $RESULT/$ost
			mkdir -p /tmp/ost-bench-$ost
			for i in $@; do
				/usr/bin/time -f "%e sec  %M KiB" $RESULT/$ost to-c "RepeatTran.Go(10)" \
					/tmp/ost-bench-$ost -infr . -m source -m test/benchmark
			done
			crc32 <(cat /tmp/ost-bench-$ost/*)
			rm -r /tmp/ost-bench-$ost
		fi
	done
}

compile_with_profile() {
	DIRS="$GCDA $GCDA-asrt $GCDA-usan $GCDA-asan $GCDA-uasan $GCDA-uasan-asrt"
	rm -rf $DIRS
	mkdir -p $DIRS

	compile -fprofile-generate
	run 0
	compile -fprofile-use
}

generate
compile_with_profile
run 0 1 2 3 4

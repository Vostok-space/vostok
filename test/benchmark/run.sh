RESULT=result/benchmark

mkdir -p $RESULT/asrt $RESULT/san
result/ost to-c "RepeatTran.Go(10)" $RESULT/asrt -infr . -m source -m test/benchmark
result/ost to-c "RepeatTran.Go(10)" $RESULT/san  -infr . -m source -m test/benchmark -init noinit

export ASAN_OPTIONS=detect_odr_violation=0

compile() {
MAIN="gcc -O3 -flto -s -DO7_MEMNG_MODEL=O7_MEMNG_NOFREE -Isingularity/implementation singularity/implementation/o7.c singularity/implementation/CFiles.c singularity/implementation/CLI.c singularity/implementation/Platform.c singularity/implementation/OsEnv.c singularity/implementation/OsExec.c singularity/implementation/Unistd_.c"
TRAP="-fsanitize-undefined-trap-on-error -static-libasan"
USAN="-fsanitize=undefined -fno-sanitize=alignment"
ASAN="-fsanitize=address -DO7_LSAN_LEAK_IGNORE"
INIT_NO="-DNDEBUG -DO7_INIT_MODEL=O7_INIT_NO"
INIT_UNDEF="-DO7_INIT_MODEL=O7_INIT_UNDEF -DO7_ASSERT_NO_MESSAGE"

NPROC=`nproc || sysctl -n hw.ncpu`

# parallelize compilation
echo \
"$MAIN $INIT_UNDEF -I$RESULT/asrt $RESULT/asrt/*.c -o $RESULT/ost-asrt" \
,\
"$MAIN $INIT_UNDEF -I$RESULT/asrt $RESULT/asrt/*.c $USAN $ASAN $TRAP -o $RESULT/ost-uasan-asrt" \
,\
"$MAIN $INIT_NO -I$RESULT/san $RESULT/san/*.c $USAN $ASAN $TRAP -o $RESULT/ost-uasan" \
,\
"$MAIN $INIT_NO -I$RESULT/san $RESULT/san/*.c $ASAN $TRAP -o $RESULT/ost-asan" \
,\
"$MAIN $INIT_NO -I$RESULT/san $RESULT/san/*.c $USAN $TRAP -o $RESULT/ost-usan" \
,\
"$MAIN $INIT_NO -I$RESULT/san $RESULT/san/*.c -o $RESULT/ost" \
| xargs -d , -n 1 -P $NPROC sh -c
}

compile

LIST="ost ost-asrt ost-usan ost-asan ost-uasan ost-uasan-asrt"

for ost in $LIST; do
	echo
	ls -l $RESULT/$ost
	mkdir -p /tmp/ost-bench-$ost
	for i in 0 1 2 3 4; do
		/usr/bin/time -f "%e sec  %M KiB" $RESULT/$ost to-c "RepeatTran.Go(10)" /tmp/ost-bench-$ost -infr . -m source -m test/benchmark 2>&1
	done;
	crc32 <(cat /tmp/ost-bench-$ost/*)
	rm -r /tmp/ost-bench-$ost
done

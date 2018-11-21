RESULT=result/benchmark

mkdir -p $RESULT/asrt $RESULT/san
result/o7c to-c "RepeatTran.Go(10)" $RESULT/asrt -infr . -m source -m test/benchmark
result/o7c to-c "RepeatTran.Go(10)" $RESULT/san  -infr . -m source -m test/benchmark -init noinit

export ASAN_OPTIONS=detect_odr_violation=0
MAIN="gcc -Wno-logical-op-parentheses -O3 -flto -s -DO7_MEMNG_MODEL=O7_MEMNG_NOFREE -Isingularity/implementation singularity/implementation/*.c"
TRAP="-fsanitize-undefined-trap-on-error -static-libasan"

$MAIN -DNDEBUG -DO7_VAR_INIT_MODEL=O7_INIT_NO -I$RESULT/san $RESULT/san/*.c -o $RESULT/o7c &

$MAIN -DO7_VAR_INIT_MODEL=O7_INIT_UNDEF -I$RESULT/asrt $RESULT/asrt/*.c -o $RESULT/o7c-asrt &

$MAIN -DO7_VAR_INIT_MODEL=O7_INIT_NO -DNDEBUG -I$RESULT/san $RESULT/san/*.c -fsanitize=undefined $TRAP -o $RESULT/o7c-usan &

$MAIN -DO7_VAR_INIT_MODEL=O7_INIT_NO -DNDEBUG -I$RESULT/san $RESULT/san/*.c -fsanitize=address $TRAP -DO7_LSAN_LEAK_IGNORE -o $RESULT/o7c-asan &

$MAIN -DO7_VAR_INIT_MODEL=O7_INIT_NO -DNDEBUG -I$RESULT/san $RESULT/san/*.c -fsanitize=undefined -fsanitize=address $TRAP -DO7_LSAN_LEAK_IGNORE -o $RESULT/o7c-uasan

$MAIN -DO7_VAR_INIT_MODEL=O7_INIT_UNDEF -I$RESULT/asrt $RESULT/asrt/*.c -fsanitize=undefined -fsanitize=address $TRAP -DO7_LSAN_LEAK_IGNORE -o $RESULT/o7c-uasan-asrt

strip $RESULT/o7c*

LIST="$RESULT/o7c $RESULT/o7c-asrt $RESULT/o7c-usan $RESULT/o7c-asan $RESULT/o7c-uasan $RESULT/o7c-uasan-asrt"

mkdir -p /tmp/o7c-bench
for o7c in $LIST; do
	echo
	ls -l $o7c
	for i in 0 1 2 3 4; do
		/usr/bin/time -p $o7c to-c "RepeatTran.Go(10)" /tmp/o7c-bench -infr . -m source -m test/benchmark 2>&1 | grep real
	done
done

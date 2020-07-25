RESULT=result/benchmark

mkdir -p $RESULT/asrt $RESULT/san
result/ost to-c "RepeatTran.Go(10)" $RESULT/asrt -infr . -m source -m test/benchmark
result/ost to-c "RepeatTran.Go(10)" $RESULT/san  -infr . -m source -m test/benchmark -init noinit

export ASAN_OPTIONS=detect_odr_violation=0
MAIN="gcc -O3 -flto -s -DO7_MEMNG_MODEL=O7_MEMNG_NOFREE -Isingularity/implementation singularity/implementation/*.c"
TRAP="-fsanitize-undefined-trap-on-error -static-libasan"

$MAIN -DNDEBUG -DO7_INIT_MODEL=O7_INIT_NO -I$RESULT/san $RESULT/san/*.c -o $RESULT/ost &

$MAIN -DO7_INIT_MODEL=O7_INIT_UNDEF -I$RESULT/asrt $RESULT/asrt/*.c -o $RESULT/ost-asrt &

$MAIN -DO7_INIT_MODEL=O7_INIT_NO -DNDEBUG -I$RESULT/san $RESULT/san/*.c -fsanitize=undefined $TRAP -o $RESULT/ost-usan &

$MAIN -DO7_INIT_MODEL=O7_INIT_NO -DNDEBUG -I$RESULT/san $RESULT/san/*.c -fsanitize=address $TRAP -DO7_LSAN_LEAK_IGNORE -o $RESULT/ost-asan &

$MAIN -DO7_INIT_MODEL=O7_INIT_NO -DNDEBUG -I$RESULT/san $RESULT/san/*.c -fsanitize=undefined -fsanitize=address $TRAP -DO7_LSAN_LEAK_IGNORE -o $RESULT/ost-uasan

$MAIN -DO7_INIT_MODEL=O7_INIT_UNDEF -I$RESULT/asrt $RESULT/asrt/*.c -fsanitize=undefined -fsanitize=address $TRAP -DO7_LSAN_LEAK_IGNORE -o $RESULT/ost-uasan-asrt

strip $RESULT/ost*

LIST="$RESULT/ost $RESULT/ost-asrt $RESULT/ost-usan $RESULT/ost-asan $RESULT/ost-uasan $RESULT/ost-uasan-asrt"

mkdir -p /tmp/ost-bench
for ost in $LIST; do
	echo
	ls -l $ost
	for i in 0 1 2 3 4; do
		/usr/bin/time -p $ost to-c "RepeatTran.Go(10)" /tmp/ost-bench -infr . -m source -m test/benchmark 2>&1 | grep real
	done
done

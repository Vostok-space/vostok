RESULT=result/benchmark

mkdir -p $RESULT
result/o7c to-c Translator.Benchmark $RESULT -infr . -m source

MAIN="gcc -O3 -flto -DO7C_MEM_MAN_MODEL=O7C_MEM_MAN_NOFREE -I$RESULT -Isingularity/implementation $RESULT/*.c singularity/implementation/*.c"

$MAIN -DNDEBUG -o $RESULT/o7c

$MAIN -o $RESULT/o7c-asrt

$MAIN -fsanitize=undefined -DNDEBUG -o $RESULT/o7c-usan

$MAIN -fsanitize=address -DO7C_LSAN_LEAK_IGNORE -DNDEBUG -o $RESULT/o7c-asan

$MAIN -fsanitize=undefined -fsanitize=address -DO7C_LSAN_LEAK_IGNORE -DNDEBUG -o $RESULT/o7c-uasan

$MAIN -fsanitize=undefined -fsanitize=address -DO7C_LSAN_LEAK_IGNORE -o $RESULT/o7c-uasan-asrt

strip $RESULT/o7c*

LIST="$RESULT/o7c $RESULT/o7c-asrt $RESULT/o7c-usan $RESULT/o7c-asan $RESULT/o7c-uasan $RESULT/o7c-uasan-asrt"

mkdir -p /tmp/o7c-bench
for o7c in $LIST; do
	echo
	ls -l $o7c
	for i in 0 1 2; do
		/usr/bin/time -p $o7c to-c Translator.Benchmark /tmp/o7c-bench -infr . -m source 2>&1 | grep real
	done
done

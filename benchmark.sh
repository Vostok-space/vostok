RESULT=result/benchmark

mkdir -p $RESULT/asrt $RESULT/san
result/o7c to-c Translator.Benchmark $RESULT/asrt -infr . -m source
result/o7c to-c Translator.Benchmark $RESULT/san -infr . -m source -init no

MAIN="gcc -Wno-logical-op-parentheses -O3 -flto -s -DO7C_MEM_MAN_MODEL=O7C_MEM_MAN_NOFREE -Isingularity/implementation singularity/implementation/*.c"

$MAIN -DNDEBUG -DO7C_VAR_INIT_MODEL=O7C_VAR_INIT_NO -I$RESULT/san $RESULT/san/*.c -o $RESULT/o7c

$MAIN -DO7C_VAR_INIT_MODEL=O7C_VAR_INIT_UNDEF -I$RESULT/asrt $RESULT/asrt/*.c -o $RESULT/o7c-asrt

$MAIN -DO7C_VAR_INIT_MODEL=O7C_VAR_INIT_NO -DNDEBUG -I$RESULT/san $RESULT/san/*.c -fsanitize=undefined -o $RESULT/o7c-usan

$MAIN -DO7C_VAR_INIT_MODEL=O7C_VAR_INIT_NO -DNDEBUG -I$RESULT/san $RESULT/san/*.c -fsanitize=address -DO7C_LSAN_LEAK_IGNORE -o $RESULT/o7c-asan

$MAIN -DO7C_VAR_INIT_MODEL=O7C_VAR_INIT_NO -DNDEBUG -I$RESULT/san $RESULT/san/*.c -fsanitize=undefined -fsanitize=address -DO7C_LSAN_LEAK_IGNORE -o $RESULT/o7c-uasan

$MAIN -DO7C_VAR_INIT_MODEL=O7C_VAR_INIT_UNDEF -I$RESULT/asrt $RESULT/asrt/*.c -fsanitize=undefined -fsanitize=address -DO7C_LSAN_LEAK_IGNORE -o $RESULT/o7c-uasan-asrt

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

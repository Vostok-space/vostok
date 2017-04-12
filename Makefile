O7CI := result/bs-o7c

O7C := result/o7c

SING_O7 := singularity/definition
SING_C := singularity/implementation
SING_BS := singularity/bootstrap

SELF := result/self

SRC := $(wildcard source/*.mod)
SANITIZE := -ftrapv -fsanitize=undefined -fsanitize=address -DO7C_LSAN_LEAK_IGNORE
SANITIZE_TEST := $(SANITIZE)
O7C_OPT := -DO7C_MEM_MAN_MODEL=O7C_MEM_MAN_NOFREE
#LD_OPT := -lgc
LD_OPT :=
WARN := -Wall -Wno-parentheses -Wno-pointer-sign
DEBUG := -g
OPTIM := -O1
CC_OPT:= $(WARN) $(OPTIM) $(DEBUG) $(O7C_OPT)

RM := trash

TESTS := $(addprefix result/test/,$(basename $(notdir $(wildcard test/source/*.mod))))

result/o7c : $(patsubst source/%.mod,result/%.o, $(SRC))
	$(CC) $(CC_OPT) $(SANITIZE) -Iresult -I$(SING_BS)/singularity result/*.o $(SING_BS)/singularity/*.c $(LD_OPT) -o $@

result/%.o : $(patsubst source/%.mod,result/%.c, $(SRC)) Makefile
	$(CC) $(CC_OPT) $(SANITIZE) -Iresult -I$(SING_BS)/singularity $(basename $@).c -c -o $@

result/%.c : $(SRC) $(O7CI)
	@mkdir -p result
	$(O7CI) $(patsubst result/%.c,source/%.mod, $@) $(basename $@) source $(SING_O7)

result/Translator.c : $(SRC) $(O7CI)
	@mkdir -p result
	$(O7CI) source/Translator.mod result/Translator.c source $(SING_O7)

result/bs-o7c:
	@mkdir -p result
	$(CC) $(CC_OPT) $(SANITIZE) -I$(SING_BS) -I$(SING_BS)/singularity $(SING_BS)/*.c $(SING_BS)/singularity/*.c -o $@

result/test/% : test/source/%.mod always
	@mkdir -p result/test
	$(O7C) to-c $< result/test -i $(SING_O7) test/source
	$(CC) -g $(SANITIZE_TEST) -DO7C_MEM_MAN_MODEL=O7C_MEM_MAN_NOFREE $@.c $(SING_C)/*.c -I $(SING_C) $(LD_OPT) -o $@
	$@

test : result/o7c $(TESTS)

help :
	@echo "Основные цели Makefile:\n\
	   result/o7c - цель по умолчанию, сбор транслятора через bootstrap\n\
	   test       - прогон тестов первичным транслятором\n\
	   self       - сбор транслятора им самим и прогон тестов\n\
	   self-full  - сбор транслятора версией, полученной от self и прогон тестов\n\
	   clean      - удаление всех результатов\n\
	Основные переменные-параметры:\n\
	   CC       - компилятор C\n\
	   SANITIZE - опции компиляторов gcc-v5 и clang для контроля корректности\n\
	   OPTIM    - уровень оптимизации\n\
	Пример сбора транслятора без опций -sanitize с помощью tcc:\n\
	   make CC:=tcc SANITIZE:=\n\
	"

clean :
	-$(RM) result

.PHONY : clean test self always self-full help

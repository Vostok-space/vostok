O7CI := result/bs-o7c

O7C := result/o7c

SING_O7 := singularity/definition
SING_C := singularity/implementation
SING_BS := singularity/bootstrap

SELF := result/self

SRC := $(wildcard source/*.mod)
SANITIZE := -ftrapv -fsanitize=undefined -fsanitize=address -DO7_LSAN_LEAK_IGNORE
SANITIZE_TEST := $(SANITIZE)
O7_OPT := -DO7_MEMNG_MODEL=O7_MEMNG_NOFREE
#LD_OPT := -lgc
LD_OPT := -lm
WARN := -Wall -Wno-parentheses
DEBUG := -g
OPTIM := -O1
CC_OPT:= $(WARN) $(OPTIM) $(DEBUG) $(O7_OPT)

RM := trash

TESTS := $(addprefix result/test/,$(basename $(notdir $(wildcard test/source/*.mod))))

result/o7c : $(SRC) $(O7CI)
	$(O7CI) to-c Translator.Start result -infr . -m source
	$(CC) $(CC_OPT) $(SANITIZE) -Iresult -I$(SING_BS)/singularity result/*.c $(SING_BS)/singularity/*.c $(LD_OPT) -o $@

result/bs-o7c:
	@mkdir -p result
	$(CC) $(CC_OPT) $(SANITIZE) -I$(SING_BS) -I$(SING_BS)/singularity $(SING_BS)/*.c $(SING_BS)/singularity/*.c -o $@

result/test/% : always
	@mkdir -p result/test
	-rm -rf $@.src
	$(O7C) to-bin $(@F).Go $@ -infr . -m test/source -t $@.src -cc "$(CC) -g $(SANITIZE_TEST) -DO7_MEMNG_MODEL=O7_MEMNG_NOFREE $(LD_OPT)"
	$@

test : result/o7c $(TESTS)

$(SELF)/o7c : $(O7C) $(SRC) Makefile
	-rm -rf $(SELF)
	$(O7C) to-bin Translator.Start $@ -infr . -m source -t $(SELF) -cc "$(CC) $(CC_OPT) $(SANITIZE) $(LD_OPT)"

self : $(SELF)/o7c
	+make test O7C:=$(SELF)/o7c

self-full : result/self/o7c
	+make self O7C:=$< SELF:=result/self2

help :
	@echo "Help in English:\n\
	   make help-en\n\
	Основные цели Makefile:\n\
	   result/o7c - цель по умолчанию, сбор транслятора через bootstrap\n\
	   test       - прогон тестов первичным транслятором\n\
	   self       - сбор транслятора им самим и прогон тестов\n\
	   self-full  - сбор транслятора версией, полученной от self и прогон тестов\n\
	   clean      - удаление всех результатов\n\
	Основные переменные-параметры:\n\
	   CC       - компилятор C\n\
	   SANITIZE - опции компиляторов gcc-v5 и clang для контроля корректности\n\
	   OPTIM    - уровень оптимизации\n\
	Пример сбора транслятора без опций -fsanitize с помощью tcc:\n\
	   make CC:=tcc SANITIZE:=\n\
	"

help-en :
	@echo "Main targets of Makefile:\n\
	   result/o7c - default target, build translator by bootstrap\n\
	   test       - tests by 1st generation translator\n\
	   self       - build itself then tests\n\
	   self-full  - build translator by 2nd generation translator then tests\n\
	   clean      - remove all builded results\n\
	Main variables-options:\n\
	   CC       - C compiler\n\
	   SANITIZE - options of gcc-v5 and clang for correctness control\n\
	   OPTIM    - optimization level\n\
	Example of build translator without -fsanitize by Tiny C:\n\
	   make CC:=tcc SANITIZE:=\n\
	"

clean :
	-$(RM) result

.PHONY : clean test self always self-full help

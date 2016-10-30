O7CI := result/bs-o7c

O7C := result/o7c

SING_O7 := singularity/definition
SING_C := singularity/implementation
SING_BS := singularity/bootstrap

SELF := result/self

SRC := $(filter-out $(wildcard source/VFileStream.*.mod),$(wildcard source/*.mod))
SANITIZE :=  -ftrapv -fsanitize=undefined -fsanitize=address -DO7C_LSAN_LEAK_IGNORE
WARN := -Wall -Wno-parentheses -Wno-pointer-sign
DEBUG := -g
OPTIM := -O1
CC_OPT:= $(WARN) $(OPTIM) $(DEBUG)

RM := trash

TESTS := $(addprefix result/test/,$(basename $(notdir $(wildcard test/source/*.mod))))

result/o7c : $(patsubst source/%.mod,result/%.c, $(SRC)) Makefile
	$(CC) $(CC_OPT) $(SANITIZE) -Iresult -I$(SING_BS)/singularity result/*.c $(SING_BS)/singularity/*.c -o $@

result/Translator.c : source/Translator.mod Makefile $(O7CI)
	@mkdir -p result
	$(O7CI) source/Translator.mod result/Translator.c source $(SING_O7)

result/%.c : source/%.mod Makefile $(O7CI)
	@mkdir -p result
	$(O7CI) $< $(basename $@) source $(SING_O7)

result/bs-o7c:
	@mkdir -p result
	$(CC) $(CC_OPT) $(SANITIZE) -I$(SING_BS) -I$(SING_BS)/singularity $(SING_BS)/*.c $(SING_BS)/singularity/*.c -o $@

result/test/% : test/source/%.mod always
	@mkdir -p result/test
	$(O7C) $< $@.c $(SING_O7) test/source
	$(CC) $@.c $(SING_C)/*.c -I $(SING_C) -o $@
	$@

$(SELF)/%.c : source/%.mod Makefile
	@mkdir -p $(SELF)
	$(O7C) $< $(basename $@) source $(SING_O7)

$(SELF)/Translator.c : source/Translator.mod Makefile
	$(O7C) source/Translator.mod $@ source $(SING_O7)

$(SELF)/o7c : result/o7c $(patsubst source/%.mod,$(SELF)/%.c, $(SRC)) Makefile
	$(CC) $(CC_OPT) $(SANITIZE) -I$(SELF) -I$(SING_C) $(SELF)/*.c $(SING_C)/*.c -o $@

self : $(SELF)/o7c
	make test O7C:=-$(SELF)/o7c

self-full : result/self/o7c
	make self O7C:=-result/self/o7c SELF:=result/self2

test : result/o7c result/test/RecordExt $(TESTS)

clean :
	-$(RM) result

.PHONY : clean test self always self-full

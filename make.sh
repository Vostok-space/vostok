#!/bin/sh

SING_BS=singularity/bootstrap

SANITIZE="-ftrapv -fsanitize=undefined -fsanitize=address -DO7_LSAN_LEAK_IGNORE"
SANITIZE_TEST="$SANITIZE"
O7_OPT="-DO7_MEMNG_MODEL=O7_MEMNG_NOFREE"
#LD_OPT=-lgc
LD_OPT=-lm
WARN="-Wall -Wno-parentheses"
DEBUG=-g
OPTIM=-O1
OPT=
CC=gcc
CC_OPT="$WARN $OPTIM $DEBUG $O7_OPT $OPT"

mkdir -p result
$CC $CC_OPT $SANITIZE -I$SING_BS -I$SING_BS/singularity $SING_BS/*.c $SING_BS/singularity/*.c -o result/bs-o7c

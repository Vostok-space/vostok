#!/bin/sh

SING_BS=bootstrap

#SANITIZE="-ftrapv"
#SANITIZE="-fsanitize=undefined -fsanitize=address -fsanitize-undefined-trap-on-error -static-libasan -DO7_LSAN_LEAK_IGNORE"
O7_OPT="-DO7_MEMNG_MODEL=O7_MEMNG_NOFREE"
WARN="-Wall -Wno-parentheses"
DEBUG=-g
OPTIM=-O1
OPT=
CC=cc
CC_OPT="$WARN $OPTIM $DEBUG $O7_OPT $OPT"

echo C compiler is $CC

mkdir -p result
$CC $CC_OPT $SANITIZE -I$SING_BS -I$SING_BS/singularity $SING_BS/*.c $SING_BS/singularity/*.c -o result/bs-ost

echo Bootstrap version of translator was built. Info about next steps:
echo "  result/bs-ost run make.Help -infr . -m source"

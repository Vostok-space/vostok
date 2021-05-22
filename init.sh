#!/bin/sh

BS=bootstrap
SING=singularity/implementation

O7_OPT="-DO7_MEMNG_MODEL=O7_MEMNG_NOFREE"
WARN="-Wall -Wno-parentheses"
DEBUG=-g
OPTIM=-O1
OPT=
LD_OPT=
CC_OPT="$WARN $OPTIM $DEBUG $O7_OPT $OPT $LD_OPT"

notfound() {
    echo Can not found c compiler
    exit 1
}

search_cc() {
    for CC in cc gcc clang tcc "zig cc" ccomp zapcc notfound; do
        if $CC -v >/dev/null 2>/dev/null; then
            echo Use \"$CC\" as C compiler
            break
        fi
    done
}

build() {
    mkdir -p result
    SING_C="$SING/CFiles.c $SING/CLI.c $SING/OsEnv.c $SING/OsExec.c $SING/Platform.c $SING/o7.c"
    $CC $CC_OPT -I$BS -I$SING $BS/*.c $SING_C -o result/bs-ost
}

info() {
    echo
    echo Bootstrap version of translator was built. Info about next steps:
    echo "  result/bs-ost run make.Help -infr . -m source"
    echo
    echo To build, test, and install run:
    echo "  result/bs-ost run 'make.Build; make.Test' -infr . -m source &&"
    echo "  /usr/bin/sudo result/ost run make.Install -infr . -m source"
}

search_cc
build && info

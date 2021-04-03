[Проект "Восток"](README-RU.md) - русская версия введения.

Project "Vostok"
==========================
[Oberon-07](documents/Language.md) translator.

The goal is to create the translator from several Oberon dialects into readable,
error-resistant code for industrial programming languages.
Also, a possible future target is machine code, probably through intermediaries
as LLVM.

The translator is written in its own input language - Oberon.
Generates code for:

  * A common subset of C and C++ compatible with gcc, clang, tcc and CompCert.
  * Java 1.7
  * JavaScript compatible with ECMAScript 5
  * Oberon-07, Active Oberon and Component Pascal

License is LGPL for translator's code and Apache for libraries, tests and
examples.

## Install in Ubuntu 18.04:
Add [repository](https://translate.google.com/translate?sl=ru&tl=en&u=https://wiki.oberon.org/repo) and execute command:

    $ /usr/bin/sudo apt install vostok-bin

## Building in POSIX:
Script init.sh build from pre-generated C-files the 0-version of the Oberon
translator - result/bs-ost, which can serve the rest of the tasks:
generating the executable code of the translator - result/ost from Oberon-source
and testing.

    $ ./init.sh

Short help about the main targets and variables of build script:

    $ result/bs-ost run make.Help -infr . -m source

Build the translator:

    $ result/bs-ost run make.Build -infr . -m source

Testing:

    $ result/bs-ost run 'make.Test; make.Self; make.SelfFull' -infr . -m source

## Building in Windows:

Build with direct using of [tcc](http://download.savannah.gnu.org/releases/tinycc/):

    > init.cmd
    > result\bs-ost run make.Build -infr . -m source -cc tcc

Of course, the directory with the tcc.exe must be specified in the PATH
environment variable.

Testing. C-compiler(gcc, clang, tcc) searched automatically:

    > result\bs-ost run 'make.Test; make.Self; make.SelfFull' -infr . -m source

## Installing in POSIX:
Copying the executable to /usr/local/bin/ and libraries to /usr/local/share:

    $ /usr/bin/sudo result/ost run make.Install -infr . -m source

## Usage:

Help about translator usage:

    $ ost help

Oberon-modules running example:

    $ ost run 'Out.Int(999 * 555, 0); Out.Ln'

Same from project directory without installed ost:

    $ result/ost run 'Out.Int(999 * 555, 0); Out.Ln' -infr .

The parameter '-infr .' indicates the path to the infrastructure, which also
includes the path, where located library module Out.

Example of executable binary build:

    $ result/ost to-bin ReadDir.Go result/Dir -infr . -m example
    $ result/Dir

In addition to the command line parameters from the previous examples, here
introduced the name of the final executable file - result/Dir, which is
required for the "to-bin" command. Also indicated an additional path for
searching modules - "-m example", because of ReadDir.mod located in directory
"example". ReadDir module contains "Go" - exported procedure without parameters.
It will be entry point for "result/Dir".

Launching a demo web server by 8080 port with the ability to edit and execute
code in a browser:

    $ cd demo-server
    $ go build server.go
    $ ./server

## Questions:
Russian-speaking forums, but possible to ask in english:
[forum.oberoncore.ru](https://forum.oberoncore.ru/viewtopic.php?f=115&t=6217),
[zx.oberon.org](https://zx.oberon.org/forum/viewtopic.php?f=117&t=297)

## News:
[Russian blog](https://vostok-space.blogspot.com/) through
[Google translate](https://translate.google.com/translate?sl=ru&tl=en&u=https://vostok-space.blogspot.com)

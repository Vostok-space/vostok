[Проект "Восток"](README-RU.md) - более полная версия введения.

Project "Vostok"
==========================
[Oberon-07](documents/Language.md) translator to C, Java and JavaScript.

License is LGPL for translator's code and Apache for libraries, tests and
examples.

## Build:

Build translator for POSIX:

    $ ./init.sh && result/bs-ost run make.Build -infr . -m source

Build under Windows using [tcc](http://download.savannah.gnu.org/releases/tinycc/):

    > init.cmd
    > result\bs-ost run make.Build -infr . -m source -cc tcc

Test under POSIX and Windows

    result/bs-ost run 'make.Test; make.Self; make.SelfFull' -infr . -m source -cc tcc

Short build help for POSIX systems:

    result/bs-ost run make.Help -infr . -m source

## Usage:

Help about translator usage:

    $ result/ost help

Oberon-modules running example:

    $ result/ost run 'Out.Int(999 * 555, 0); Out.Ln' -infr .

Example of executable binary build:

    $ result/ost to-bin ReadDir.Go result/Dir -infr . -m test/source
    $ result/Dir

Demo web-server:

    $ cd demo-server

    $ go build server.go && ./server

## Questions:
Russian-speaking forums, but possible to ask in english:
[forum.oberoncore.ru](https://forum.oberoncore.ru/viewtopic.php?f=115&t=6217),
[zx.oberon2.ru](https://zx.oberon2.ru/forum/viewforum.php?f=117)

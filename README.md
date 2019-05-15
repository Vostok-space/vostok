[Проект "Восток"](README-RU.md) - более полная версия введения.

Project "Vostok"
==========================
[Oberon-07](documents/Language.md) translator to C, Java and JavaScript.

License is LGPL for translator's code and Apache for libraries, tests and
examples.

## Build:

Short build help for POSIX systems:

    $ make help-en

Build translator for POSIX:

    $ make
    $ # or
    $ ./make.sh && result/bs-ost run make.Build -infr . -m source

Test under POSIX:

    $ make test self self-full

Build under Windows using [tcc](http://download.savannah.gnu.org/releases/tinycc/):

    > make.cmd
    > :: or
    > make.cmd
    > result/bs-ost run make.Build -infr . -m source -cc tcc

Test under POSIX and Windows

    result/bs-ost run 'make.Test; make.Self; make.SelfFull' -infr . -m source -cc tcc

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

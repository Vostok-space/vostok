Проект "Восток"
=======================
Транслятор [Oberon-07](documents/Language-ru.md).

Цель - создание транслятора из некоторых диалектов Oberon в читаемый,
устойчивый к ошибкам код для ряда промышленных языков программирования,
таких как: C, C++, Javascript и других, а также в машинный код, не исключая
посредников вроде LLVM.

Выдаёт код на:

  * Общем подмножестве С и С++, совместимом с gcc, clang, tcc, CompCert, MS VS.
  * Java стандарта 1.7
  * JavaScript стандарта ECMAScript 5
  * Oberon-07, Active Oberon и Component Pascal
  * Диаграммы активности Plant UML

Основной код транслятора написан на его входном языке - Обероне.
Привязки к библиотекам - на соответствующих выходных языках.

Код транслятора доступен под лицензией LGPL, а библиотеки, тесты и примеры -
под Apache License.

## Установка в Ubuntu 18.04:
Добавить [репозиторий](https://wiki.oberon.org/repo) в систему и выполнить команду:

    $ /usr/bin/sudo apt install vostok-bin

## Сборка в POSIX:
init.sh собирает из предварительно сгенерированных C-файлов 0-ю версию
транслятора Оберона result/bs-ost, которая уже может обслуживать
остальные сборочные задачи: генерацию исполнимого кода транслятора result/ost
непосредственно из исходных кодов на Обероне и тестирование.

    $ ./init.sh

Короткая справка по главным целям и переменным сборочного скрипта:

    $ result/bs-ost run make.Help -infr . -m source

Сборка транслятора:

    $ result/bs-ost run make.Build -infr . -m source

Тестирование:

    $ result/bs-ost run 'make.Test; make.Self; make.SelfFull' -infr . -m source

## Сборка в Windows:
Сборка c явным указанием
[Tiny C Compiler](http://download.savannah.gnu.org/releases/tinycc/),
каталог с исполняемым файлом которого должен быть прописан в переменной
окружения PATH:

    > init.cmd
    > result\bs-ost run make.Build -infr . -m source -cc tcc

Тестирование с автопоиском компилятора C (tcc, gcc, clang, vc):

    > result\bs-ost run 'make.Test; make.Self; make.SelfFull' -infr . -m source

## Установка в POSIX:
Копирование исполнимого файла в /usr/local/bin/ и библиотек в /usr/local/share

    $ /usr/bin/sudo result/ost run make.Install -infr . -m source

## Использование:
Справка о способах использования транслятора доступна при его запуске без
параметров или с командой help в более подробном варианте:

    $ ost help

Пример непосредственного запуска кода:

    $ ost run 'Out.Int(999 * 555, 0); Out.Ln'

После команды run, указан код на Обероне, который нужно выполнить.
Такой же код можно выполнить без установки транслятора в систему:

    $ result/ost run 'Out.Int(999 * 555, 0); Out.Ln' -infr .

Параметр '-infr .' указывает путь к инфраструктуре, которая включает в себя путь,
по которому, в том числе, содержится библиотечный модуль Out.

Пример сборки исполняемого файла:

    $ ost to-bin ReadDir.Go result/Dir -m example
    $ result/Dir

Помимо параметров командной строки из предыдущего примера здесь
указано название итогового исполнимого файла - result/Dir, что обязательно для
команды to-bin, а также дополнительный путь для поиска модулей -m example,
где и находится файл ReadDir.mod, в котором содержится модуль ReadDir, который
содержит экспортированную процедуру без параметров - Go.

Запуск демонстрационного веб-сервера по 8080-му порту с возможностью
редактировать и исполнять код в браузере:

    $ cd demo-server
    $ go build server.go
    $ ./server

## Вопросы:
Обсуждение ведётся на следующих площадках:
[forum.oberoncore.ru](https://forum.oberoncore.ru/viewtopic.php?f=115&t=6217),
[zx.oberon.org](https://zx.oberon.org/forum/viewtopic.php?f=117&t=297)

### Новости:
[Блог о проекте](https://vostok-space.blogspot.com/)

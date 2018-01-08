Project "Vostok"
=======================
Oberon-07 translator to C.

Short build help for POSIX systems:

	make help-en

Build translator for POSIX:

	make
	# or
	./make.sh & result/bs-o7c run make.Build -infr . -m source -m .

Test under POSIX:

	make test self self-full

Demo server:

	cd demo-server
	go run server.go


Build under Windows using [tcc](http://download.savannah.gnu.org/releases/tinycc/):

	make.cmd

Test under POSIX and Windows

	result/bs-o7c run 'make.Test; make.Self; make.SelfFull' -infr . -m source -m . -cc tcc


Проект "Восток"
=======================
Транслятор Oberon-07.

Цель - создание транслятора из ряда диалектов Oberon в читаемый,
устойчивый к ошибкам код для ряда промышленных языков программирования,
таких как: C, C++, Javascript и других, а также в машинный код, не исключая
посредников вроде LLVM.

Написан на собственном входном языке.
Генерирует совместимый с gcc, clang и tcc код на С.

Короткая справка по главным целям и переменным Makefile для сборки в POSIX
системах:

	make help
	# или
	result/bs-o7c run make.Help -infr . -m source -m .

Сборка транслятора в POSIX:

	make
	# или
	./make.sh & result/bs-o7c run make.Build -infr . -m source -m .

Тестирование в POSIX:

	make test self self-full
	# или
	result/bs-o7c run 'make.Test; make.Self; make.SelfFull' -infr . -m source -m .

Запуск демонстрационного сервера с возможностью редактировать и запускать код:

	cd demo-server
	go run server.go

Сборка под Windows, используя [tcc](http://download.savannah.gnu.org/releases/tinycc/),
каталог с которым должен быть прописан в переменной окружения PATH

	make.cmd
	:: или
	make.cmd
	result/bs-o7c run make.Build -infr . -m source -m . -cc tcc

Тестирование в POSIX и Windows

	result/bs-o7c run 'make.Test; make.Self; make.SelfFull' -infr . -m source -m . -cc tcc

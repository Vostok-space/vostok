Project "Vostok"
=======================
Oberon-07 translator to C.

Short build help:

	make help-en

Build translator:

	make

Test:

	make test self self-full

Demo server:

	cd demo-server
	go run server.go


Проект "Восток"
=======================
Транслятор Oberon-07.

Цель - создание транслятора из ряда диалектов Oberon в читаемый,
устойчивый к ошибкам код для ряда промышленных языков программирования,
таких как: C, C++, Javascript и других, а также в машинный код, не исключая
посредников вроде LLVM.

Написан на собственном входном языке.
Генерирует совместимый с gcc, clang и tcc код на С.

Короткая справка по главным целям и переменным Makefile:

	make help

Сборка транслятора:

	make

Тестирование:

	make test self self-full

Запуск демонстрационного сервера с возможностью редактировать и запускать код:

	cd demo-server
	go run server.go

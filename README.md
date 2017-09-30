Project "Vostok"
=======================
Oberon-07 translator to C.

Short build help:

	make help-en

Build translator:

	make

Test:

	make test self self-full

Проект "Восток"
=======================
Ранняя стадия развития транслятора Oberon-07.

Цель - создание транслятора из ряда диалектов Oberon в хорошо читаемый код для
ряда промышленных языков программирования, таких как: C, C++, Javascript и
других, а также в машинный код, не исключая посредников вроде LLVM.

Написан на собственном входном языке.
Генерирует совместимый с gcc, clang и tcc код на С.

Короткая справка по главным целям и переменным Makefile:

	make help

Сборка транслятора:

	make

Тестирование:

	make test self self-full

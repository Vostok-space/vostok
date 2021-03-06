Oberon-07
===========

[Сообщение о языке](https://www.inf.ethz.ch/personal/wirth/Oberon/Oberon07.Report.pdf)
от его автора и [перевод](https://online.oberon.org/oberon) на
русский язык.

## Уточнения:

| Тип      |  Пределы                    |
|----------|-----------------------------|
| INTEGER  | -2147483647  .. 2147483647  |
| REAL     | -1,8×10+308 .. 1,8×10+308   |
| SET      | \{} .. \{0 .. 31}           |
| CHAR     | 0X .. 0FFX                  |

| Expression | Value
|------------|------
| ORD(FALSE) | 0
| ORD(TRUE)  | 1

## Управление динамической памятью
Осуществляется по 1-му из 3-х сценариев, обеспечивающих целостность данных и
не требующих дополнительных средств на уровне языка:

 * Без освобождения памяти.
 * Сборщик мусора.
 * Подсчёт ссылок без автоматического разрыва циклических связей.

Ошибками считаются:

 * Исходный код, который не может быть выведен из синтаксических уравнений.
 * Арифметическое переполнение и деление на 0 как для целых, так и дробных чисел.
 * Отрицательный целочисленный делитель.
 * Присваивания переменой BYTE значения, выходящего за пределы 0 .. 255.
 * CHR(int), где  int < 0 или 255 < int.
 * Переполнение SET, но проверка наличия чисел, выходящих за пределы, приемлема.
 * ORD(set), при выполнении условия (31 IN set).
 * Обращение к массиву по индексу, выходящем за его пределы.
 * Присваивание значений открытых массивов и строк массивам недостаточного размера.
 * Обращение к неинициализированной переменной.
 * Обращения по адресу NIL.
 * Наличие в CASE меток с пересекающимися значениями.
 * Отсутствие метки, включающей значение из входного выражения оператора CASE.
 * Проверка типа с помощью IS для указателя, имеющего значение NIL.
 * Циклы с константным условием и вечные циклы.
 * FOR с шагом, не соответствующим его пределам.

Желательным действием на ошибки является их выявление. Список возможных типов
диагностик в порядке уменьшения предпочтительности:

 * Сообщение о проблеме во время предварительной проверки.
 * Уведомление об ошибке во время исполнения с продолжением работы, если ошибка
   произошла во вспомогательном или бесполезном в данном случае коде.
 * Уведомление об ошибке и аварийная остановка во время исполнения.
 * Отсутствие реакции, что возможно из-за сложности в диагностике или
   необходимости эффективности.

## Неполнота воплощения:
 * Не сделан CASE для записей и указателей.
 * Отсутствует модуль SYSTEM

## Расширения:
 * Опционально доступны кириллические имена.
   Смешивание латиницы и кириллицы в одном имени недопустимо.

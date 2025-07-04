Oberon-07
===========

## Уточнения воплощения языка:

| Тип      |  Пределы                    |
|----------|-----------------------------|
| INTEGER  | -2147483647  .. 2147483647  |
| REAL     | -1,8×10+308 .. 1,8×10+308   |
| SET      | \{} .. \{0 .. 31}           |
| CHAR     | 0X .. 0FFX                  |

| Выражение  | Значение
|------------|------
| ORD(FALSE) | 0
| ORD(TRUE)  | 1

## Управление динамической памятью
Осуществляется по 1-му из 3-х сценариев, обеспечивающих целостность данных и
не требующих дополнительных средств на уровне языка:

 * Без освобождения памяти
 * Сборщик мусора
 * Подсчёт ссылок без автоматического разрыва циклических связей

Ошибками считаются:

 * Исходный код, который не может быть выведен из синтаксических уравнений
 * Арифметическое переполнение и деление на 0 как для целых, так и дробных чисел
 * Отрицательный целочисленный делитель
 * Присваивания переменой BYTE значения, выходящего за пределы 0 .. 255
 * CHR(int), где  int < 0 или 255 < int
 * Переполнение SET по наполнению или проверке, то есть, применение чисел за
   пределами 0 .. 31
 * ORD(set), при выполнении условия (31 IN set)
 * Обращение к массиву по индексу, выходящем за его пределы
 * Присваивание значений открытых массивов и строк массивам недостаточного размера
 * Обращение к неинициализированной переменной
 * Обращение по указателю со значеним NIL
 * Наличие в CASE меток с пересекающимися значениями
 * Отсутствие метки, включающей значение из входного выражения оператора CASE
 * Проверка типа с помощью IS для указателя, имеющего значение NIL
 * Циклы с константным условием и вечные циклы
 * FOR с шагом, не соответствующим его пределам
 * Обращение по недопустимым адресам в SYSTEM.GET,PUT,COPY

Желательным действием на ошибки является их выявление. Список возможных типов
диагностик в порядке уменьшения предпочтительности:

 * Сообщение о проблеме во время предварительной проверки (трансляции)
 * Уведомление об ошибке во время исполнения с продолжением работы, если ошибка
   произошла во вспомогательном или бесполезном в данном случае коде
 * Уведомление об ошибке и аварийная остановка во время исполнения
 * Отсутствие реакции, что возможно из-за сложности в диагностике или
   необходимости эффективности

## Расширения:
 * Опционально доступны кириллические имена.
   Мягкий и твёрдый знаки допустимы только после согласных или по одиночке.
   Смешивание латиницы и кириллицы в одном имени недопустимо

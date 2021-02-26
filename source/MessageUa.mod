(*  Ukrainian messages for interface
 *  Copyright (C) 2018-2021 ComdivByZero
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published
 *  by the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)
MODULE MessageUa;

IMPORT Cli := CliParser, Out, Utf8;

PROCEDURE S(s: ARRAY OF CHAR);
BEGIN
	Out.String(s);
	Out.Ln
END S;

PROCEDURE Usage*(full: BOOLEAN);
BEGIN
S("Транслятор Oberon-07 в C, Java, Javascript, Oberon. 2021");
S("Використання: ");
S(" 0) ost help     # докладна довідка");
S(" 1) ost to-c     Код ВихТека {-m ТзМ | -i ТзІ | -infr Інфр}");
S(" 2) ost to-bin   Код Викон {-m ТМ|-i ТІ|-infr І|-c Тhc|-cc Компіл|-t ТимчТек}");
S(" 3) ost to-java  Код ВихТека {-m ТзМ | -i ТзІ | -infr Інфр}");
S(" 4) ost run      Код {-m ТзМ|-i ТзІ|-c Тhc|-t ТимчТек} [-- Пар-ри]");
S(" 5) ost to-class Код ВихТек {-m TМ|-i ТІ|-infr І|-jv ТJ|-javac Компіл|-t ТмчТк}");
S(" 6) ost run-java Код {-m ТзМ|-i TзІ|-jv ТJ|-t ТимчТек} [-- Пар-ри]");
S(" 7) ost to-js    Код ВихТек {-m ТзМ | -i ТзІ | -infr Інфр}");
S(" 8) ost run-js   Код {-m ТзМ|-i ТзІ|-js ТJs|-t ТимчТек} [-- Пар-ри]");
S(" 9) ost to-mod   Мод ВихТека {-m ТзМ | -i ТзІ | -infr Інфр | -std:(O7|AO|CP)}");
S(" A) ost          Файл.mod         [ Пар-ри ]");
S(" B) ost .Команда Файл.mod         [ Пар-ри ]");
S(" C) ost .        Файл.mod Команда [ Пар-ри ]");
IF full THEN
S("");
S("1) to-c     перетворює модулі у набір .h и .c файлів");
S("2) to-bin   перетворює модулі у виконуваний файл крізь неявні .c файли");
S("3) run      запускає неявний виконуваний файл, створений по Коду");
S("4) to-java  перетворює модулі в набір .java файлів");
S("5) to-class перетворює модулі в .class файли крізь неявні .java файли");
S("6) run-java запускає неявний клас з main, створений по Коду");
S("7) to-js    перетворює модулі в набір .js файлів");
S("8) run-js   запускає неявний .js файл, створений по Коду");
S("9) to-mod   перетворює модулі назад у код одного з діалектів Оберону");
S("A-C) запускає код модуля у файлі, сумістно з she-bang");
S("");
S("Код - це спрощений текст на Обероні, що описується різновидом РБНФ:");
S("  Код = Виклик { ; Виклик } . Виклик = Модуль [ .Процедура [ '('Пар-ри')' ] ] .");
S("ВихТек - Вихідна Тека для створених .h и .c файлів.");
S("Викон - ім'я створеного виконуваного файлу.");
S("");
S("-m ТзМ - ім'я Теки з Модулями, потрібної для їх пошуку.");
S("  Приклад: -m library -m source -m test/source");
S("-i ТзІ - ім'я Теки з Інтерфейсними модулями без справжнього втілення");
S("  Приклад: -i singularity/definition");
S("-c Тhc - ім'я Теки з .h и .c файлами-втіленнями інтерфейсних модулів");
S("  Приклад: -c singularity/implementation");
S("-infr Інфр - тека з Інфр_аструктурою. '-infr p' - це скорочення для:");
S("  -i p/singularity/definition -c p/singularity/implementation -m p/library");
S("-t ТимчТек - нова Тимчасова Тека для збереження проміжного .h и .c коду");
S("  Приклад: -t result/test/ReadDir.src");
S("-cc Компіл - Компілятор C для збору .c-коду, за замовчуванням 'cc -g -O1'");
S("  Приклад: -cc 'clang -O3 -flto -s'");
S("-- Пар-ри - Параметри командного рядку для виконуваного файлу");
S("");
S("Опції, які впливають на генератор коду:");
S("-init ( noinit | undef | zero )  - різновид авто-ініціалізації змінних.");
S("  noinit -  без будь-якої ініціалізації.");
S("  undef* -  спец. значення для діагностики під час виконання.");
S("  zero   -  заповнення 0-ми.");
S("-memng ( nofree | counter | gc ) - різновид управління динамічною пам'ятью.");
S("  nofree*  -  без звільнення.");
S("  counter  -  автоматичний підрахунок посилань без розриву циклів.");
S("  gc       -  консервативний збір сміття.");
S("-no-array-index-check         - без перевірки звернення за межі масиву.");
S("-no-nil-check                 - вимкнути перевірку звернення по 0-му адресу.");
S("-no-arithmetic-overflow-check - вимкнути перевірку аріфметичного переповнення.");
S("");
S("-C90 | -C99 | -C11            - вибір ISO стандарту генеруємого C-коду");
S("-out:O7 | -out:AO             - вибір діалекту Oberon для генеруємих модулів");
S("");
S("-cyrillic[-same|-escape|-translit] - дозволяє кирилицю в іменах вихідного коду.");
S("   за замовченням підбирає спосіб генерації, що краще пасує компілятору.");
S("  -same     передає імена в С в ідентичному вигляді.");
S("  -escape   використовує екранований спосіб запису юнікоду - \uXXXX.");
S("  -translit використовує транслітерацію для імен в C.")
END
END Usage;

PROCEDURE CliError*(err: INTEGER);
BEGIN
	CASE err OF
	  Cli.ErrWrongArgs:
		Usage(FALSE)
	| Cli.ErrTooLongSourceName:
		S("Занадто довге ім'я вихідного файла"); Out.Ln
	| Cli.ErrTooLongOutName:
		S("Занадто довге ім'я файлу-результату"); Out.Ln
	| Cli.ErrOpenSource:
		S("Не вдається відкрити вихідний файл")
	| Cli.ErrOpenH:
		S("Не вдається відкрити вихідний .h файл")
	| Cli.ErrOpenC:
		S("Не вдається відкрити вихідний .c файл")
	| Cli.ErrUnknownCommand:
		S("Невідома команда");
		Usage(FALSE)
	| Cli.ErrNotEnoughArgs:
		S("Недостатньо аргументів для команди")
	| Cli.ErrTooLongModuleDirs:
		S("Загальна довжина імен тек з модулями занадто велика")
	| Cli.ErrTooManyModuleDirs:
		S("Занадто багато тек з модулями")
	| Cli.ErrTooLongCDirs:
		S("Загальна довжина імен тек з .c-файлами занадто велика")
	| Cli.ErrTooLongCc:
		S("Довжина опцій компілятору C занадто велика")
	| Cli.ErrTooLongTemp:
		S("Ім'я тимчасової теки занадто велике")
	| Cli.ErrCCompiler:
		S("Помилка при виклику компілятору C")
	| Cli.ErrTooLongRunArgs:
		S("Занадто довгі параметри командного рядку")
	| Cli.ErrUnexpectArg:
		S("Неочікуваний аргумент")
	| Cli.ErrUnknownInit:
		S("Вказаний спосіб ініціалізації змінних невідомий")
	| Cli.ErrUnknownMemMan:
		S("Вказаний тип управління динамічною пам'ятью невідомий")
	| Cli.ErrCantCreateOutDir:
		S("Не вдається створити вихідну теку")
	| Cli.ErrCantRemoveOutDir:
		S("Не вдається видалити вихідну теку")
	| Cli.ErrCantFoundCCompiler:
		S("Не вдалося знайти компілятор C")

	| Cli.ErrOpenJava:
		S("Не вдається відкрити вихідний java файл")
	| Cli.ErrJavaCompiler:
		S("Помилка при виклику компілятору Java")
	| Cli.ErrCantFoundJavaCompiler:
		S("Не вдалося знайти компілятор Java")
	| Cli.ErrTooLongJavaDirs:
		S("Загальна довжина тек з .java-файлами завелика")

	| Cli.ErrOpenJs:
		S("Не вдається відкрити вихідний .js файл")
	| Cli.ErrTooLongJsDirs:
		S("Загальна довжина тек з .js-файлами завелика")

	| Cli.ErrOpenOberon:
		S("Не вдається відкрити вихідний Oberon модуль")

	| Cli.ErrDisabledGenC:
		S("Генерація через C виключена")
	| Cli.ErrDisabledGenJava:
		S("Генерація через Java виключена")
	| Cli.ErrDisabledGenJs:
		S("Генерація через JavaScript виключена")
	| Cli.ErrDisabledGenOberon:
		S("Генерація через Oberon виключена")
	END
END CliError;

END MessageUa.

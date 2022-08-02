(*  Russian messages for interface
 *
 *  Copyright (C) 2017-2022 ComdivByZero
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
MODULE MessageRu;

IMPORT Cli := CliParser, Out, Utf8;

PROCEDURE S(s: ARRAY OF CHAR);
BEGIN
	Out.String(s);
	Out.Ln
END S;

PROCEDURE Usage*(full: BOOLEAN);
BEGIN
S("Транслятор Oberon-07 в C, Java, JavaScript, Oberon. 2022");
S("Использование: ");
S(" 0) ost help     # подробная справка");
S(" 1) ost to-c     Код ВыхКат {-m ПкМ | -i ПкИ | -infr Инфр}");
S(" 2) ost to-bin   Код Исполн {-m ПМ|-i ПИ|-infr И|-c ПHC|-cc Компил|-t ВремКат}");
S(" 3) ost run      Код {-m ПкМ|-i ПкИ|-c ПHC|-infr И|-cc К|-t ВрКат} [-- Пар-ры]");
S(" 4) ost to-java  Код ВыхКат {-m ПкМ | -i ПкИ | -infr Инфр}");
S(" 5) ost to-class Код ВыхКат {-m ПМ|-i ПИ|-infr И|-jv ПJ|-javac Компил|-t ВрКат}");
S(" 6) ost to-jar   Код Jar {-m ПМ|-i ПИ|-infr И|-jv ПJ|-javac Компил|-t ВрКат}");
S(" 7) ost run-java Код {-m ПкМ|-i ПкИ|-jv ПJ|-t ВремКат} [-- Пар-ры]");
S(" 8) ost to-js    Код Вых {-m ПкМ | -i ПкИ | -infr Инфр}");
S(" 9) ost run-js   Код {-m ПкМ|-i ПкИ|-js ПJs|-t ВремКат} [-- Пар-ры]");
S(" A) ost to-mod   Мод ВыхКат {-m ПкМ | -i ПкИ | -infr Инфр | -std:(O7|AO|CP)}");
S("    ost to-modef Мод ВыхКат {-m ПкМ | -i ПкИ | -infr Инфр | -std:(O7|AO|CP)}");
S("    ost to-puml  Мод ВыхКат {-m ПкМ | -i ПкИ | -infr Инфр}");
S(" B) ost          Файл.mod         [ Пар-ры ]");
S("    ost .Команда Файл.mod         [ Пар-ры ]");
S("    ost .        Файл.mod Команда [ Пар-ры ]");
IF full THEN
S("");
S("1) to-c     преобразовывает модули в набор .h и .c файлов");
S("2) to-bin   превращает модули в исполнимый файл через неявные .c файлы");
S("3) run      выполняет неявный исполнимый файл, созданный по Коду");
S("4) to-java  преобразовывает модули в набор .java файлов");
S("5) to-class превращает модули в .class файлы через неявные .java файлы");
S("6) to-jar   превращает модули в .jar файл через неявные .java файлы");
S("7) run-java выполняет неявный класс с main, созданный по Коду");
S("8) to-js    преобразовывает модули в набор .js файлов");
S("9) run-js   выполняет неявный .js файл, созданный по Коду");
S("A) to-mod   преобразует модули обратно в код 1-го из диалектов Оберона");
S("   to-modef преобразует модули в декларации модулей Оберона");
S("   to-puml  преобразует модули в формат Plant UML");
S("B) запускает код модуля в файле, можно использовать вместе с she-bang");
S("");
S("Код - это упрощенный текст на Обероне, выражаемый через разновидность РБНФ:");
S("  Код = Вызов { ; Вызов } . Вызов = Модуль [ .Процедура [ '('Пар-ры')' ] ] .");
S("Команда - имя экспортированной процедуры модуля.");
S("ВыхКат - Выходной Каталог для создаваемых файлов, может быть заменено на -");
S("         или пустой аргумент для печати на стандартный вывод");
S("Исполн - имя создаваемого исполнимого файла.");
S("");
S("-m ПкМ - Путь к каталогу с Модулями, нужного для поиска.");
S("  Пример: -m library -m source -m test/source");
S("-i ПкИ - Путь к каталогу с Интерфейсными модулями без настоящего воплощения");
S("  Пример: -i singularity/definition");
S("-c ПHC - Путь к каталогу с .h и .c файлами-воплощениями интерфейсных модулей");
S("  Пример: -c singularity/implementation");
S("-jv ПJ - Путь к каталогу с .java файлами-воплощениями интерфейсных модулей");
S("  Пример: -jv singularity/implementation.java");
S("-js ПJs - Путь к каталогу с .js файлами-воплощениями интерфейсных модулей");
S("  Пример: -js singularity/implementation.js");
S("-infr Инфр - путь к Инфр_аструктуре. '-infr p' - это сокращение для:");
S("   -i p/singularity/definition -c p/singularity/implementation");
S("   -j p/singularity/implementation.java -m p/library");
S("-t ВремКат - новый Временный Каталог для хранения промежуточного .h и .c кода");
S("  Пример: -t result/test/ReadDir.src");
S("-cc Компил - Компилятор C для сбора .c-кода, по умолчанию 'cc -g -O1'");
S("  Пример: -cc 'clang -O3 -flto -s'");
S("  Опция Компил может быть разбита по ... на две части для компиляторов,");
S("  которые могут требовать указывать некоторые ключи после имен .c-файлов");
S("  Пример: -cc 'g++ -I/usr/include/openbabel-2.0' ... '-lopenbabel'");
S("-javac Компил - Компилятор Java для сбора .java-кода, по умолчанию 'javac'");
S("-- Пар-ры - Параметры командной строки для запускаемого исполнимого файла");
S("");
S("-multi-errors  возможность выдачи сообщений о нескольких ошибках за раз");
S("");
S("-allow-system  разрешает опасный платформоспецифичный псевдомодуль");
S("");
S("Опции, влияющие на генератор кода:");
S("-init ( noinit | undef | zero )  - вид авто-инициализации переменных.");
S("  noinit -  без какой-либо инициализации.");
S("  undef* -  спец. значения для диагностики во время исполнения.");
S("  zero   -  заполнение 0-ми.");
S("-memng ( nofree | counter | gc ) - вид управления динамической памятью.");
S("  nofree*  -  без освобождения.");
S("  counter  -  автоматический подсчёт ссылок без разрыва циклов.");
S("  gc       -  консервативный сбор мусора.");
S("-no-array-index-check         - без проверки обращения за границами массива.");
S("-no-nil-check                 - выключить проверку обращения по 0-му адресу.");
S("-no-arithmetic-overflow-check - выключить проверку арифметического переполнения.");
S("");
S("-C90 | -C99 | -C11            - выбор ISO стандарта генерируемого C-кода");
S("-out:O7|-out:AO|-out:CP       - выбор диалекта генерируемого Oberon-кода");
S("");
S("-cyrillic[-same|-escape|-translit] - позволяет русские имена в исходном коде.");
S("   по умолчанию подбирается способ генерации, лучше подходящий компилятору.");
S("  -same     переводит в имена на С в идентичном виде.");
S("  -escape   использет экранированный способ записи юникода - \uXXXX.");
S("  -translit использует транслитерацию в получаемых именах на C.");
S("");
S("-native-string - генерировать более естественные строки для целевого языка");
S("");
S("Пользовательский интерфейс:");
S("-msg-lang:(eng|rus|ukr) - установить язык сообщений транслятора")
END
END Usage;

PROCEDURE CliError*(err: INTEGER);
BEGIN
	CASE err OF
	  Cli.ErrWrongArgs:
		Usage(FALSE)
	| Cli.ErrTooLongSourceName:
		S("Слишком длинное имя исходного файла"); Out.Ln
	| Cli.ErrTooLongOutName:
		S("Слишком длинное выходное имя"); Out.Ln
	| Cli.ErrOpenSource:
		S("Не получается открыть исходный файл")
	| Cli.ErrOpenH:
		S("Не получается открыть выходной .h файл")
	| Cli.ErrOpenC:
		S("Не получается открыть выходной .c файл")
	| Cli.ErrUnknownCommand:
		S("Неизвестная команда");
		Usage(FALSE)
	| Cli.ErrNotEnoughArgs:
		S("Недостаточно аргументов для команды");
	| Cli.ErrTooLongModuleDirs:
		S("Суммарная длина путей с модулями слишком велика")
	| Cli.ErrTooManyModuleDirs:
		S("Cлишком много путей с модулями")
	| Cli.ErrTooLongCDirs:
		S("Общая длина путей с .c-файлами слишком велика")
	| Cli.ErrTooLongCc:
		S("Длина опций компилятора C слишком велика")
	| Cli.ErrTooLongTemp:
		S("Имя временного каталога слишком велико")
	| Cli.ErrCCompiler:
		S("Ошибка при вызове компилятора C")
	| Cli.ErrTooLongRunArgs:
		S("Слишком длинные параметры командной строки")
	| Cli.ErrUnexpectArg:
		S("Неожиданный аргумент")
	| Cli.ErrUnknownInit:
		S("Указанный способ инициализации переменных науке неизвестен")
	| Cli.ErrUnknownMemMan:
		S("Указан неизвестный тип управления динамической памятью")
	| Cli.ErrCantCreateOutDir:
		S("Не получается создать выходной каталог")
	| Cli.ErrCantRemoveOutDir:
		S("Не получается удалить выходной каталог")
	| Cli.ErrCantFoundCCompiler:
		S("Не найден компилятор C")

	| Cli.ErrOpenJava:
		S("Не получается открыть выходной java файл")
	| Cli.ErrJavaCompiler:
		S("Ошибка при вызове компилятора Java")
	| Cli.ErrCantFoundJavaCompiler:
		S("Не получается найти компилятор Java")
	| Cli.ErrTooLongJavaDirs:
		S("Общая длина путей с .java-файлами слишком велика")
	| Cli.ErrTooLongJarArgs:
		S("Общая длина параметров для jar слишком велика")
	| Cli.ErrJarExec:
		S("Ошибка при вызове jar")
	| Cli.ErrJarGetCurrentDir:
		S("Ошибка выяснения текущего каталога для настройки вызова jar")
	| Cli.ErrJarSetDirBefore:
		S("Ошибка установки текущего каталога для настройки вызова jar")
	| Cli.ErrJarSetDirAfter:
		S("Ошибка восстановления текущего каталога после вызова jar")

	| Cli.ErrOpenJs:
		S("Не получается открыть выходной .js файл")
	| Cli.ErrTooLongJsDirs:
		S("Общая длина путей с .js-файлами слишком велика")

	| Cli.ErrOpenOberon:
		S("Не получается открыть выходной Oberon модуль")

	| Cli.ErrDisabledGenC:
		S("Генерация через C выключена")
	| Cli.ErrDisabledGenJava:
		S("Генерация через Java выключена")
	| Cli.ErrDisabledGenJs:
		S("Генерация через JavaScript выключена")
	| Cli.ErrDisabledGenOberon:
		S("Генерация через Oberon выключена")
	END
END CliError;

END MessageRu.

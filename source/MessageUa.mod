(*  Ukraine messages for interface
 *  Copyright (C) 2018-2019 ComdivByZero
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

IMPORT Ast, Parser, Cli := CliParser, Scanner, Out, Utf8;

PROCEDURE C(s: ARRAY OF CHAR);
BEGIN
	Out.String(s)
END C;

PROCEDURE S(s: ARRAY OF CHAR);
BEGIN
	Out.String(s);
	Out.Ln
END S;

PROCEDURE AstError*(code: INTEGER);
BEGIN
	CASE code OF
	  Ast.ErrImportNameDuplicate:
		C("Ім'я модуля вже є у списці імпорту")
	| Ast.ErrImportSelf:
		C("Модуль імпортує себе")
	| Ast.ErrImportLoop:
		C("Прямий або опосередкований циклічний імпорт заборонений")
	| Ast.ErrDeclarationNameDuplicate:
		C("Повторна об'ява імені в тій самій області видимості")
	| Ast.ErrDeclarationNameHide:
		C("Ім'я декларації перекриває декларацію з модулю")
	| Ast.ErrPredefinedNameHide:
		C("Ім'я декларації перекриває зумовлене ім'я")
	| Ast.ErrMultExprDifferentTypes:
		C("Типи підвиразів у множенні несумісні")
	| Ast.ErrDivExprDifferentTypes:
		C("Типи підвиразів у діленні несумісні")
	| Ast.ErrNotBoolInLogicExpr:
		C("У логічному виразі повинні бути підвирази також логічного типу")
	| Ast.ErrNotIntInDivOrMod:
		C("У цілочисельному ділені допускаються тільки цілочисельні підвирази")
	| Ast.ErrNotRealTypeForRealDiv:
		C("У дробовому ділені дозволенні тільки підвирази дробового типу")
	| Ast.ErrNotIntSetElem:
		C("В якості елементів множини дозволені тільки цілі числа")
	| Ast.ErrSetElemOutOfRange:
		C("Елемент множини вдається за межі можливих значень - 0 .. 31")
	| Ast.ErrSetLeftElemBiggerRightElem:
		C("Лівий елемент діапазону більший за правий")
	| Ast.ErrSetElemMaxNotConvertToInt:
		C("Множина, що вміщає 31 не може бути перетворена у ціле")
	| Ast.ErrAddExprDifferenTypes:
		C("Типи підвиразів у додаванні несумісні")
	| Ast.ErrNotNumberAndNotSetInMult:
		C("У виразах з *, /, DIV, MOD дозволені тільки цілі та множини")
	| Ast.ErrNotNumberAndNotSetInAdd:
		C("У виразах з +, - дозволені тільки цілі та множини")
	| Ast.ErrSignForBool:
		C("Унарний '-' не підходить до логічного виразу")
	| Ast.ErrRelationExprDifferenTypes:
		C("Типи підвиразів у порівнянні не співпадають")
	| Ast.ErrExprInWrongTypes:
		C("Лівий член виразу повинен бути цілочисельним, правий - множиною")
	| Ast.ErrExprInRightNotSet:
		C("Правий член виразу IN повинен бути множиною")
	| Ast.ErrExprInLeftNotInteger:
		C("Лівий член виразу IN повинен бути цілочисельним")
	| Ast.ErrRelIncompatibleType:
		C("В порівнянні вирази несумісних типів")
	| Ast.ErrIsExtTypeNotRecord:
		C("Перевірка IS можлива тільки для записів")
	| Ast.ErrIsExtVarNotRecord:
		C("Лівий член перевірки IS повинен мати тип запису або покажчика на неї")
	| Ast.ErrIsExtMeshupPtrAndRecord:
		C("Тип змінної ліворуч від IS повинен бути того ж сорту, що й тип праворуч")
	| Ast.ErrIsExtExpectRecordExt:
		C("Праворуч від IS потрібен розширений тип по відношенню до типу змінної ліворуч")
	| Ast.ErrConstDeclExprNotConst:
		C("Стала зіставляється з виразом, що не може бути розрахованим під час трансляції")
	| Ast.ErrAssignIncompatibleType:
		C("Несумісні типи у присвоєнні")
	| Ast.ErrAssignExpectVarParam:
		C("Очікувалась змінна у присвоєнні")
	| Ast.ErrAssignStringToNotEnoughArray:
		C("Присвоєння літерного рядку масиву недостатнього розміру")
	| Ast.ErrCallNotProc:
		C("Виклик дозволений тільки для підпрограм та змінних підпрограмного типу")
	| Ast.ErrCallIgnoredReturn:
		C("Вихідне значення підпрограми не задіяно у виразі")
	| Ast.ErrCallExprWithoutReturn:
		C("Викликана підпрограма не повертає значення і не повинна бути у виразі")
	| Ast.ErrCallExcessParam:
		C("Зайві фактичні параметри у виклику підпрограми")
	| Ast.ErrCallIncompatibleParamType:
		C("Несумісний тип фактичного параметру")
	| Ast.ErrCallExpectVarParam:
		C("Фактичний параметр повинен бути змінним")
	| Ast.ErrCallVarPointerTypeNotSame:
		C("Для змінного параметру - покажчика повинен використовуватись аргумент того ж типу")
	| Ast.ErrCallParamsNotEnough:
		C("Не вистачає фактичних параметрів у виклику підпрограми")
	| Ast.ErrCaseExprNotIntOrChar:
		C("Вираз у CASE повинен бути цілочисельним або літерою")
	| Ast.ErrCaseLabelNotIntOrChar:
		C("Мітка CASE повинна бути цілочисельною або літерою")
	| Ast.ErrCaseElemExprTypeMismatch:
		C("Мітки CASE повинні бути цілочисельними або літерами")
	| Ast.ErrCaseElemDuplicate:
		C("Дублирование значения меток в CASE")
	| Ast.ErrCaseRangeLabelsTypeMismatch:
		C("Не співпадає тип меток CASE")
	| Ast.ErrCaseLabelLeftNotLessRight:
		C("Ліва частина діапазону значень у мітці CASE повинна бути менше правої")
	| Ast.ErrCaseLabelNotConst:
		C("Мітки CASE повинні бути сталими")
	| Ast.ErrCaseElseAlreadyExist:
		C("ELSE вітка в CASE вже є")
	| Ast.ErrProcHasNoReturn:
		C("Підпрограма не повертає значення")
	| Ast.ErrReturnIncompatibleType:
		C("Тип возврату несумісний з типом, що вказаний у заголовку підпрограми")
	| Ast.ErrExpectReturn:
		C("Очікувалось повернення значення, бо у заголовку підпрограми вказаний тип повернення")
	| Ast.ErrDeclarationNotFound:
		C("Попередня декларація імені не було знайдена")
	| Ast.ErrConstRecursive:
		C("Некоректне використання сталої для задання власного значення")
	| Ast.ErrImportModuleNotFound:
		C("Імпортований модуль не знайдений")
	| Ast.ErrImportModuleWithError:
		C("Імпортований модуль має помилки")
	| Ast.ErrDerefToNotPointer:
		C("Розіменування прикладено не до покажчика")
	| Ast.ErrArrayLenLess1:
		C("Довжина масиву повина бути > 0")
	| Ast.ErrArrayLenTooBig:
		C("Загальна довжина масиву занадто велика")
	| Ast.ErrArrayItemToNotArray:
		C("Спроба отримання елементу не від масиву")
	| Ast.ErrArrayIndexNotInt:
		C("Індекс масиву не цілочисельний")
	| Ast.ErrArrayIndexNegative:
		C("Від'ємний індекс масиву")
	| Ast.ErrArrayIndexOutOfRange:
		C("Індекс масиву виходить за його межі")
	| Ast.ErrGuardExpectRecordExt:
		C("У захисті типу очікується розширений запис")
	| Ast.ErrGuardExpectPointerExt:
		C("У захисті типу очікується покажчик на розширений запис")
	| Ast.ErrGuardedTypeNotExtensible:
		C("У захисті типу змінна повинна бути або записом, або покажчиком на запис")
	| Ast.ErrDotSelectorToNotRecord:
		C("Селектор елементу запису прикладений не до запису")
	| Ast.ErrDeclarationNotVar:
		C("Очікувалась змінна")
	| Ast.ErrForIteratorNotInteger:
		C("Ітератор FOR має бути іменем змінної типу INTEGER")
	| Ast.ErrNotBoolInIfCondition:
		C("Вираз у охороні умовного оператору має бути логічного типу")
	| Ast.ErrNotBoolInWhileCondition:
		C("Вираз у охороні циклу WHILE ма бути логічного типу")
	| Ast.ErrWhileConditionAlwaysFalse:
		C("Охорона циклу WHILE завжда неістинна")
	| Ast.ErrWhileConditionAlwaysTrue:
		C("Цикл незкінчений, бо охорона WHILE завжди істинна")
	| Ast.ErrNotBoolInUntil:
		C("Вираз в умові завершення циклу REPEAT повинен бути логічним")
	| Ast.ErrUntilAlwaysFalse:
		C("Цикл незкінчений, бо умова завершення завжди неістинна")
	| Ast.ErrUntilAlwaysTrue:
		C("Умова завершення завжди істинна")
	| Ast.ErrDeclarationIsPrivate:
		C("Декларація не експортована")
	| Ast.ErrNegateNotBool:
		C("Логічне заперечення прикладено не до логічного типу")
	| Ast.ErrConstAddOverflow:
		C("Переповнення у додаванні сталих")
	| Ast.ErrConstSubOverflow:
		C("Переповнення у відніманні сталих")
	| Ast.ErrConstMultOverflow:
		C("Переповнення у множені сталих")
	| Ast.ErrComDivByZero:
		C("Ділення на 0")
	| Ast.ErrNegativeDivisor:
		C("Ділення на від'ємне число не визначене")
	| Ast.ErrValueOutOfRangeOfByte:
		C("Значення виходить за межі BYTE")
	| Ast.ErrValueOutOfRangeOfChar:
		C("Значення виходить за межі CHAR")
	| Ast.ErrExpectIntExpr:
		C("Очікується цілочисельний вираз")
	| Ast.ErrExpectConstIntExpr:
		C("Очікується константное цілочисельний вираз")
	| Ast.ErrForByZero:
		C("Крок ітератору не може бути рівним 0")
	| Ast.ErrByShouldBePositive:
		C("Для проходу від меньшого до більшого крок ітератору повинен бути > 0")
	| Ast.ErrByShouldBeNegative:
		C("Для проходу від більшого до меньшему крок ітератору повинен бути < 0")
	| Ast.ErrForPossibleOverflow:
		C("Під час ітерації в FOR можливе переповнення")
	| Ast.ErrVarUninitialized:
		C("Використання неініціалізованої змінної")
	| Ast.ErrVarMayUninitialized:
		C("Використання змінної, що може бути не ініціалізована")
	| Ast.ErrDeclarationNotProc:
		C("Ім'я має вказувати на підпрограму")
	| Ast.ErrProcNotCommandHaveReturn:
		C("В якості команди може бути тільки підпрограма, що не повертає значення")
	| Ast.ErrProcNotCommandHaveParams:
		C("В якості команди може бути тільки підпрограма без параметрів")
	| Ast.ErrReturnTypeArrayOrRecord:
		C("Тип значення, що повертається з підпрограми не може бути масивом та записом")
	| Ast.ErrRecordForwardUndefined:
		C("Є незадекларовний запис, на який посилається покажчик")
	| Ast.ErrPointerToNotRecord:
		C("Покажчик може посилатись тільки на запис")
	| Ast.ErrAssertConstFalse:
		C("Вираз в Assert завжди неістинний")
	| Ast.ErrVarOfRecordForward:
		C("Була задекларована змінна, тип якої є незадекларованим записом")
	| Ast.ErrVarOfPointerToRecordForward:
		C("Задекларована змінна, тип якої є покажчиком на незадекларований запис")
	| Ast.ErrArrayTypeOfRecordForward:
		C("Незадекларований запис в якості підтипу масиву")
	| Ast.ErrArrayTypeOfPointerToRecordForward:
		C("Покажчик на незадекларований запис в якості підтипу масиву")
	| Ast.ErrDeclarationUnused:
		C("Існує незадіяна декларація в цій області видимості - ")
	| Ast.ErrProcNestedTooDeep:
		C("Занадто велика вкладеність підпрограм")
	| Ast.ErrExpectProcNameWithoutParams:
		C("Очікувалось ім'я команди - підпрограми без параметрів")
	END
END AstError;

PROCEDURE ParseError*(code: INTEGER);
BEGIN
	CASE code OF
	  Scanner.ErrUnexpectChar:
		C("Неочікувана літера у тексті")
	| Scanner.ErrNumberTooBig:
		C("Значення сталої занадто велике")
	| Scanner.ErrRealScaleTooBig:
		C("ErrRealScaleTooBig")
	| Scanner.ErrWordLenTooBig:
		C("ErrWordLenTooBig")
	| Scanner.ErrExpectHOrX:
		C("У кінці 16-ричного числа очікується 'H' або 'X'")
	| Scanner.ErrExpectDQuote:
		C("Очікувалась "); C(Utf8.DQuote)
	| Scanner.ErrExpectDigitInScale:
		C("ErrExpectDigitInScale")
	| Scanner.ErrUnclosedComment:
		C("Незавершений коментар")

	| Parser.ErrExpectModule:
		C("Очікується 'MODULE'")
	| Parser.ErrExpectIdent:
		C("Очікується ім'я")
	| Parser.ErrExpectColon:
		C("Очікується ':'")
	| Parser.ErrExpectSemicolon:
		C("Очікується ';'")
	| Parser.ErrExpectEnd:
		C("Очікується 'END'")
	| Parser.ErrExpectDot:
		C("Очікується '.'")
	| Parser.ErrExpectModuleName:
		C("Очікується ім'я модулю")
	| Parser.ErrExpectEqual:
		C("Очікується '='")
	| Parser.ErrExpectBrace1Open:
		C("Очікується '('")
	| Parser.ErrExpectBrace1Close:
		C("Очікується ')'")
	| Parser.ErrExpectBrace2Open:
		C("Очікується '['")
	| Parser.ErrExpectBrace2Close:
		C("Очікується ']'")
	| Parser.ErrExpectBrace3Open:
		C("Очікується '{'")
	| Parser.ErrExpectBrace3Close:
		C("Очікується '}'")
	| Parser.ErrExpectOf:
		C("Очікується OF")
	| Parser.ErrExpectTo:
		C("Очікується TO")
	| Parser.ErrExpectStructuredType:
		C("Очікується структурний тип: масив, запис, покажчик, підпрограмний")
	| Parser.ErrExpectRecord:
		C("Очікується запис")
	| Parser.ErrExpectStatement:
		C("Очікується оператор")
	| Parser.ErrExpectThen:
		C("Очікується THEN")
	| Parser.ErrExpectAssign:
		C("Очікується :=")
	| Parser.ErrExpectVarRecordOrPointer:
		C("Очікується змінна типу запис або покажчика на нього")
	| Parser.ErrExpectType:
		C("Очікується тип")
	| Parser.ErrExpectUntil:
		C("Очікується UNTIL")
	| Parser.ErrExpectDo:
		C("Очікується DO")
	| Parser.ErrExpectDesignator:
		C("Очікується кваліфікатор")
	| Parser.ErrExpectProcedure:
		C("Очікується підпрограма")
	| Parser.ErrExpectConstName:
		C("Очікується ім'я сталої")
	| Parser.ErrExpectProcedureName:
		C("Очікується завершуюче ім'я підпрограми")
	| Parser.ErrExpectExpression:
		C("Очікується вираз")
	| Parser.ErrExcessSemicolon:
		C("Зайва ';'")
	| Parser.ErrEndModuleNameNotMatch:
		C("Заключне ім'я у кінці модуля не співпадає з його ім'ям")
	| Parser.ErrArrayDimensionsTooMany:
		C("Занадто велика n-мірність масиву")
	| Parser.ErrEndProcedureNameNotMatch:
		C("Заключне ім'я у тілі підпрограми не співпадає з її ім'ям")
	| Parser.ErrFunctionWithoutBraces:
		C("Декларація підпрограми, що повертає значення не має дужок ( )")
	| Parser.ErrExpectIntOrStrOrQualident:
		C("Очікувалось число або строка")
	| Parser.ErrMaybeAssignInsteadEqual:
		C("Неочікуваний '='. Можливо, мався на увазі ':=' для присвоювання")
	| Parser.ErrUnexpectStringInCaseLabel:
		C("У якості мітки CASE не дозволені не односимвольні рядки")
	| Parser.ErrExpectAnotherModuleName:
		C("Очікувався модуль з іншим ім'ям")
	| Parser.ErrUnexpectedContentInScript:
		C("Неочікуваний початок тексту коду")
	END
END ParseError;

PROCEDURE Usage*(full: BOOLEAN);
BEGIN
S("Транслятор Oberon-07 в C та Java. 2018");
S("Використання: ");
S("  1) ost help");
S("  2) ost to-c   Код ВихКат {-m ТзМ | -i ТзІ | -infr Інфр}");
S("  3) ost to-bin Код Викон {-m ТМ|-i ТІ|-infr І|-c Тhc|-cc Компіл|-t ТимчТек}");
S("  4) ost run    Код {-m ТзМ|-i ТзІ|-c Тhc|-t ТимчТек} [-- Пар-ри]");
IF full THEN
S("");
S("2) to-c   перетворює модулі у набір .h и .c файлів");
S("3) to-bin перетворює модулі у виконуваний файл крізь неявні .c файли");
S("4) run    запускає неявний виконуваний файл, створений по Коду");
S("");
S("Код - це спрощений текст на Обероні, що описується різновидом РБНФ:");
S("  Код = Виклик { ; Виклик } . Виклик = Модуль [ .Процедура [ '('Пар-ри')' ] ] .");
S("ВихКат - Вихідний Каталог для створених .h и .c файлів.");
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
S("-C90 | -C99 | -C11            - вибір ISO стандарту генеруемого C-коду");
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
	END
END CliError;

PROCEDURE Text*(str: ARRAY OF CHAR);
BEGIN
	IF str = "Found errors in the module " THEN
		C("Знайдені помилки у модулі ")
	ELSIF str = "Can not found or open file of module " THEN
		C("Не вдається знайти або відкрити файл модулю ")
	ELSE
		C(str)
	END
END Text;

END MessageUa.

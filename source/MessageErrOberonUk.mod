(*  Ukrainian messages for syntax and semantic errors. Extracted from MessageUa.
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
MODULE MessageErrOberonUk;

IMPORT AST := Ast, Parser, Cli := CliParser, Scanner, Out, Utf8;

PROCEDURE C(s: ARRAY OF CHAR);
BEGIN
	Out.String(s)
END C;

PROCEDURE Ast*(code: INTEGER);
BEGIN
	CASE code OF
	  AST.ErrImportNameDuplicate:
		C("Ім'я модуля вже є у списці імпорту")
	| AST.ErrImportSelf:
		C("Модуль імпортує себе")
	| AST.ErrImportLoop:
		C("Прямий або опосередкований циклічний імпорт заборонений")
	| AST.ErrDeclarationNameDuplicate:
		C("Повторна об'ява імені в тій самій області видимості")
	| AST.ErrDeclarationNameHide:
		C("Ім'я декларації перекриває декларацію з модулю")
	| AST.ErrPredefinedNameHide:
		C("Ім'я декларації перекриває зумовлене ім'я")
	| AST.ErrMultExprDifferentTypes:
		C("Типи підвиразів у множенні несумісні")
	| AST.ErrDivExprDifferentTypes:
		C("Типи підвиразів у діленні несумісні")
	| AST.ErrNotBoolInLogicExpr:
		C("У логічному виразі повинні бути підвирази також логічного типу")
	| AST.ErrNotIntInDivOrMod:
		C("У цілочисельному ділені допускаються тільки цілочисельні підвирази")
	| AST.ErrNotRealTypeForRealDiv:
		C("У дробовому ділені дозволенні тільки підвирази дробового типу")
	| AST.ErrNotIntSetElem:
		C("В якості елементів множини дозволені тільки цілі числа")
	| AST.ErrSetElemOutOfRange:
		C("Елемент множини вдається за межі можливих значень - 0 .. 31")
	| AST.ErrSetElemOutOfLongRange:
		C("Елемент множини вдається за межі можливих значень - 0 .. 63")
	| AST.ErrSetLeftElemBiggerRightElem:
		C("Лівий елемент діапазону більший за правий")
	| AST.ErrSetElemMaxNotConvertToInt:
		C("Множина, що вміщає >=31 не може бути перетворена у ціле")
	| AST.ErrSetFromLongSet:
		C("Неможливо зберегти значення великої множини в звичайній")
	| AST.ErrAddExprDifferenTypes:
		C("Типи підвиразів у додаванні несумісні")
	| AST.ErrNotNumberAndNotSetInMult:
		C("У виразах з *, /, DIV, MOD дозволені тільки цілі та множини")
	| AST.ErrNotNumberAndNotSetInAdd:
		C("У виразах з +, - дозволені тільки цілі та множини")
	| AST.ErrSignForBool:
		C("Унарний '-' не підходить до логічного виразу")
	| AST.ErrRelationExprDifferenTypes:
		C("Типи підвиразів у порівнянні не співпадають")
	| AST.ErrExprInWrongTypes:
		C("Лівий член виразу повинен бути цілочисельним, правий - множиною")
	| AST.ErrExprInRightNotSet:
		C("Правий член виразу IN повинен бути множиною")
	| AST.ErrExprInLeftNotInteger:
		C("Лівий член виразу IN повинен бути цілочисельним")
	| AST.ErrRelIncompatibleType:
		C("В порівнянні вирази несумісних типів")
	| AST.ErrIsExtTypeNotRecord:
		C("Перевірка IS можлива тільки для записів")
	| AST.ErrIsExtVarNotRecord:
		C("Лівий член перевірки IS повинен мати тип запису або покажчика на неї")
	| AST.ErrIsExtMeshupPtrAndRecord:
		C("Тип змінної ліворуч від IS повинен бути того ж сорту, що й тип праворуч")
	| AST.ErrIsExtExpectRecordExt:
		C("Праворуч від IS потрібен розширений тип по відношенню до типу змінної ліворуч")
	| AST.ErrIsEqualProc:
		C("Безпосереднє порівняння підпрограм неприпустимо")
	| AST.ErrConstDeclExprNotConst:
		C("Стала зіставляється з виразом, що не може бути розрахованим під час трансляції")
	| AST.ErrAssignIncompatibleType:
		C("Несумісні типи у присвоєнні")
	| AST.ErrAssignExpectVarParam:
		C("Очікувалась змінна у присвоєнні")
	| AST.ErrAssignStringToNotEnoughArray:
		C("Присвоєння літерного рядку масиву недостатнього розміру")
	| AST.ErrCallNotProc:
		C("Виклик дозволений тільки для підпрограм та змінних підпрограмного типу")
	| AST.ErrCallIgnoredReturn:
		C("Вихідне значення підпрограми не задіяно у виразі")
	| AST.ErrCallExprWithoutReturn:
		C("Викликана підпрограма не повертає значення і не повинна бути у виразі")
	| AST.ErrCallExcessParam:
		C("Зайві фактичні параметри у виклику підпрограми")
	| AST.ErrCallIncompatibleParamType:
		C("Несумісний тип фактичного параметру")
	| AST.ErrCallExpectVarParam:
		C("Фактичний параметр повинен бути змінним")
	| AST.ErrCallExpectAddressableParam:
		C("Фактичний параметр має бути адресованим")
	| AST.ErrCallVarPointerTypeNotSame:
		C("Для змінного параметру - покажчика повинен використовуватись аргумент того ж типу")
	| AST.ErrCallParamsNotEnough:
		C("Не вистачає фактичних параметрів у виклику підпрограми")
	| AST.ErrCaseExprNotIntOrChar:
		C("Вираз у CASE повинен бути цілочисельним або літерою")
	| AST.ErrCaseLabelNotIntOrChar:
		C("Мітка CASE повинна бути цілочисельною або літерою")
	| AST.ErrCaseElemExprTypeMismatch:
		C("Мітки CASE повинні бути цілочисельними або літерами")
	| AST.ErrCaseElemDuplicate:
		C("Дублирование значения меток в CASE")
	| AST.ErrCaseRangeLabelsTypeMismatch:
		C("Не співпадає тип меток CASE")
	| AST.ErrCaseLabelLeftNotLessRight:
		C("Ліва частина діапазону значень у мітці CASE повинна бути менше правої")
	| AST.ErrCaseLabelNotConst:
		C("Мітки CASE повинні бути сталими")
	| AST.ErrCaseElseAlreadyExist:
		C("ELSE вітка в CASE вже є")
	| AST.ErrProcHasNoReturn:
		C("Підпрограма не повертає значення")
	| AST.ErrReturnIncompatibleType:
		C("Тип возврату несумісний з типом, що вказаний у заголовку підпрограми")
	| AST.ErrExpectReturn:
		C("Очікувалось повернення значення, бо у заголовку підпрограми вказаний тип повернення")
	| AST.ErrDeclarationNotFound:
		C("Попередня декларація імені не було знайдена")
	| AST.ErrConstRecursive:
		C("Некоректне використання сталої для задання власного значення")
	| AST.ErrImportModuleNotFound:
		C("Імпортований модуль не знайдений")
	| AST.ErrImportModuleWithError:
		C("Імпортований модуль має помилки")
	| AST.ErrDerefToNotPointer:
		C("Розіменування прикладено не до покажчика")
	| AST.ErrArrayLenLess1:
		C("Довжина масиву повина бути > 0")
	| AST.ErrArrayLenTooBig:
		C("Загальна довжина масиву занадто велика")
	| AST.ErrArrayItemToNotArray:
		C("Спроба отримання елементу не від масиву")
	| AST.ErrArrayIndexNotInt:
		C("Індекс масиву не цілочисельний")
	| AST.ErrArrayIndexNegative:
		C("Від'ємний індекс масиву")
	| AST.ErrArrayIndexOutOfRange:
		C("Індекс масиву виходить за його межі")
	| AST.ErrStringIndexing:
		C("Індексація строкового літералу не дозволена")
	| AST.ErrGuardExpectRecordExt:
		C("У захисті типу очікується розширений запис")
	| AST.ErrGuardExpectPointerExt:
		C("У захисті типу очікується покажчик на розширений запис")
	| AST.ErrGuardedTypeNotExtensible:
		C("У захисті типу змінна повинна бути або записом, або покажчиком на запис")
	| AST.ErrDotSelectorToNotRecord:
		C("Селектор елементу запису прикладений не до запису")
	| AST.ErrDeclarationNotVar:
		C("Очікувалась змінна")
	| AST.ErrForIteratorNotInteger:
		C("Ітератор FOR має бути іменем змінної типу INTEGER")
	| AST.ErrNotBoolInIfCondition:
		C("Вираз у охороні умовного оператору має бути логічного типу")
	| AST.ErrNotBoolInWhileCondition:
		C("Вираз у охороні циклу WHILE ма бути логічного типу")
	| AST.ErrWhileConditionAlwaysFalse:
		C("Охорона циклу WHILE завжда неістинна")
	| AST.ErrWhileConditionAlwaysTrue:
		C("Цикл незкінчений, бо охорона WHILE завжди істинна")
	| AST.ErrNotBoolInUntil:
		C("Вираз в умові завершення циклу REPEAT повинен бути логічним")
	| AST.ErrUntilAlwaysFalse:
		C("Цикл незкінчений, бо умова завершення завжди неістинна")
	| AST.ErrUntilAlwaysTrue:
		C("Умова завершення завжди істинна")
	| AST.ErrDeclarationIsPrivate:
		C("Декларація не експортована")
	| AST.ErrNegateNotBool:
		C("Логічне заперечення прикладено не до логічного типу")
	| AST.ErrConstAddOverflow:
		C("Переповнення у додаванні сталих")
	| AST.ErrConstSubOverflow:
		C("Переповнення у відніманні сталих")
	| AST.ErrConstMultOverflow:
		C("Переповнення у множені сталих")
	| AST.ErrComDivByZero:
		C("Ділення на 0")
	| AST.ErrNegativeDivisor:
		C("Ділення на від'ємне число не визначене")
	| AST.ErrValueOutOfRangeOfByte:
		C("Значення виходить за межі BYTE")
	| AST.ErrValueOutOfRangeOfChar:
		C("Значення виходить за межі CHAR")
	| AST.ErrExpectIntExpr:
		C("Очікується цілочисельний вираз")
	| AST.ErrExpectConstIntExpr:
		C("Очікується константное цілочисельний вираз")
	| AST.ErrForByZero:
		C("Крок ітератору не може бути рівним 0")
	| AST.ErrByShouldBePositive:
		C("Для проходу від меньшого до більшого крок ітератору повинен бути > 0")
	| AST.ErrByShouldBeNegative:
		C("Для проходу від більшого до меньшему крок ітератору повинен бути < 0")
	| AST.ErrForPossibleOverflow:
		C("Під час ітерації в FOR можливе переповнення")
	| AST.ErrVarUninitialized:
		C("Використання неініціалізованої змінної")
	| AST.ErrVarMayUninitialized:
		C("Використання змінної, що може бути не ініціалізована")
	| AST.ErrDeclarationNotProc:
		C("Ім'я має вказувати на підпрограму")
	| AST.ErrProcNotCommandHaveReturn:
		C("В якості команди може бути тільки підпрограма, що не повертає значення")
	| AST.ErrProcNotCommandHaveParams:
		C("В якості команди може бути тільки підпрограма без параметрів")
	| AST.ErrReturnTypeArrayOrRecord:
		C("Тип значення, що повертається з підпрограми не може бути масивом та записом")
	| AST.ErrRecordForwardUndefined:
		C("Є незадекларовний запис, на який посилається покажчик")
	| AST.ErrPointerToNotRecord:
		C("Покажчик може посилатись тільки на запис")
	| AST.ErrAssertConstFalse:
		C("Вираз в Assert завжди неістинний")
	| AST.ErrVarOfRecordForward:
		C("Була задекларована змінна, тип якої є незадекларованим записом")
	| AST.ErrVarOfPointerToRecordForward:
		C("Задекларована змінна, тип якої є покажчиком на незадекларований запис")
	| AST.ErrArrayTypeOfRecordForward:
		C("Незадекларований запис в якості підтипу масиву")
	| AST.ErrArrayTypeOfPointerToRecordForward:
		C("Покажчик на незадекларований запис в якості підтипу масиву")
	| AST.ErrDeclarationUnused:
		C("Існує незадіяна декларація в цій області видимості - ")
	| AST.ErrProcNestedTooDeep:
		C("Занадто велика вкладеність підпрограм")
	| AST.ErrExpectProcNameWithoutParams:
		C("Очікувалось ім'я команди - підпрограми без параметрів")
	| AST.ErrParamOutInFunc:
		C("Функція не може мати вихідного параметру")
	END
END Ast;

PROCEDURE Syntax*(code: INTEGER);
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
END Syntax;

PROCEDURE Text*(str: ARRAY OF CHAR);
BEGIN
	IF str = "Found errors in the module " THEN
		C("Знайдені помилки у модулі ")
	ELSIF str = "Can not found or open file of module -" THEN
		C("Не вдається знайти або відкрити файл модулю - ")
	ELSIF str = "Name of potential module is too large - " THEN
		C("Ім'я потенційного модуля завелике - ")
	ELSE
		C(str)
	END
END Text;

END MessageErrOberonUk.

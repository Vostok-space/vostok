(*  Russian messages for interface
 *  Copyright (C) 2017-2018 ComdivByZero
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
		C("Имя модуля уже встречается в списке импорта")
	| Ast.ErrImportSelf:
		C("Модуль импортирует себя")
	| Ast.ErrImportLoop:
		C("Прямой или косвенный циклический импорт запрещён")
	| Ast.ErrDeclarationNameDuplicate:
		C("Повторное объявление имени в той же области видимости")
	| Ast.ErrDeclarationNameHide:
		C("Имя объявления затеняет объявление из модуля")
	| Ast.ErrPredefinedNameHide:
		C("Имя объявления затеняет предопределённое имя")
	| Ast.ErrMultExprDifferentTypes:
		C("Типы подвыражений в умножении несовместимы")
	| Ast.ErrDivExprDifferentTypes:
		C("Типы подвыражений в делении несовместимы")
	| Ast.ErrNotBoolInLogicExpr:
		C("В логическом выражении должны использоваться подвыражения логического же типа")
	| Ast.ErrNotIntInDivOrMod:
		C("В целочисленном делении допустимы только целочисленные подвыражения")
	| Ast.ErrNotRealTypeForRealDiv:
		C("В дробном делении допустимы только подвыражения дробного типа")
	| Ast.ErrNotIntSetElem:
		C("В качестве элементов множества допустимы только целые числа")
	| Ast.ErrSetElemOutOfRange:
		C("Элемент множества выходит за границы возможных значений - 0 .. 31")
	| Ast.ErrSetLeftElemBiggerRightElem:
		C("Левый элемент диапазона больше правого")
	| Ast.ErrSetElemMaxNotConvertToInt:
		C("Множество, содержащее 31 не может быть преобразовано в целое")
	| Ast.ErrAddExprDifferenTypes:
		C("Типы подвыражений в сложении несовместимы")
	| Ast.ErrNotNumberAndNotSetInMult:
		C("В выражениях *, /, DIV, MOD допустимы только числа и множества")
	| Ast.ErrNotNumberAndNotSetInAdd:
		C("В выражениях +, - допустимы только числа и множества")
	| Ast.ErrSignForBool:
		C("Унарный знак не применим к логическому выражению")
	| Ast.ErrRelationExprDifferenTypes:
		C("Типы подвыражений в сравнении не совпадают")
	| Ast.ErrExprInWrongTypes:
		C("Левый член выражения должен быть целочисленным, правый - множеством")
	| Ast.ErrExprInRightNotSet:
		C("Правый член выражения IN должен быть множеством")
	| Ast.ErrExprInLeftNotInteger:
		C("Левый член выражения IN должен быть целочисленным")
	| Ast.ErrRelIncompatibleType:
		C("В сравнении выражения несовместимых типов")
	| Ast.ErrIsExtTypeNotRecord:
		C("Проверка IS применима только к записям")
	| Ast.ErrIsExtVarNotRecord:
		C("Левый член проверки IS должен иметь тип записи или указателя на неё")
	| Ast.ErrIsExtMeshupPtrAndRecord:
		C("Тип переменной слева от IS должен быть того же сорта, что и тип справа")
	| Ast.ErrIsExtExpectRecordExt:
		C("Справа от IS нужен расширенный тип по отношению к типу переменной слева")
	| Ast.ErrConstDeclExprNotConst:
		C("Постоянная сопоставляется выражению, невычислимым на этапе перевода")
	| Ast.ErrAssignIncompatibleType:
		C("Несовместимые типы в присваивании")
	| Ast.ErrAssignExpectVarParam:
		C("Ожидалось изменяемое выражение в присваивании")
	| Ast.ErrCallNotProc:
		C("Вызов допустим только для процедур и переменных процедурного типа")
	| Ast.ErrCallIgnoredReturn:
		C("Возвращаемое значение не задействовано в выражении")
	| Ast.ErrCallExprWithoutReturn:
		C("Вызываемая подпрограмма не возвращает значения")
	| Ast.ErrCallExcessParam:
		C("Лишние параметры при вызове процедуры")
	| Ast.ErrCallIncompatibleParamType:
		C("Несовместимый тип параметра")
	| Ast.ErrCallExpectVarParam:
		C("Параметр должен быть изменяемым значением")
	| Ast.ErrCallVarPointerTypeNotSame:
		C("Для переменного параметра - указателя должен использоваться аргумент того же типа")
	| Ast.ErrCallParamsNotEnough:
		C("Не хватает фактических параметров в вызове процедуры")
	| Ast.ErrCaseExprNotIntOrChar:
		C("Выражение в CASE должно быть целочисленным или литерой")
	| Ast.ErrCaseLabelNotIntOrChar:
		C("Метка CASE должна быть целочисленной или литерой")
	| Ast.ErrCaseElemExprTypeMismatch:
		C("Метки CASE должно быть целочисленными или литерами")
	| Ast.ErrCaseElemDuplicate:
		C("Дублирование значения меток в CASE")
	| Ast.ErrCaseRangeLabelsTypeMismatch:
		C("Не совпадает тип меток CASE")
	| Ast.ErrCaseLabelLeftNotLessRight:
		C("Левая часть диапазона значений в метке CASE должна быть меньше правой")
	| Ast.ErrCaseLabelNotConst:
		C("Метки CASE должны быть константами")
	| Ast.ErrCaseElseAlreadyExist:
		C("ELSE ветка в CASE уже есть")
	| Ast.ErrProcHasNoReturn:
		C("Подпрограмма не имеет возвращаемого значения")
	| Ast.ErrReturnIncompatibleType:
		C("Тип возвращаемого значения не совместим типом, указанном в заголовке процедуры")
	| Ast.ErrExpectReturn:
		C("Ожидался возврат значения, так как в заголовке процедуры указан возвращаемый тип")
	| Ast.ErrDeclarationNotFound:
		C("Предварительное объявление имени не было найдено")
	| Ast.ErrConstRecursive:
		C("Недопустимое использование константы для задания собственного значения")
	| Ast.ErrImportModuleNotFound:
		C("Импортированный модуль не был найден")
	| Ast.ErrImportModuleWithError:
		C("Импортированный модуль содержит ошибки")
	| Ast.ErrDerefToNotPointer:
		C("Разыменовывание применено не к указателю")
	| Ast.ErrArrayLenLess1:
		C("Длина массива должна быть > 0")
	| Ast.ErrArrayLenTooBig:
		C("Общая длина массива слишком большая")
	| Ast.ErrArrayItemToNotArray:
		C("Получение элемента не массива")
	| Ast.ErrArrayIndexNotInt:
		C("Индекс массива не целочисленный")
	| Ast.ErrArrayIndexNegative:
		C("Отрицательный индекс массива")
	| Ast.ErrArrayIndexOutOfRange:
		C("Индекс массива выходит за его границы")
	| Ast.ErrGuardExpectRecordExt:
		C("В защите типа ожидается расширенная запись")
	| Ast.ErrGuardExpectPointerExt:
		C("В защите типа ожидается указатель на расширенную запись")
	| Ast.ErrGuardedTypeNotExtensible:
		C("В защите типа переменная должна быть либо записью, либо указателем на запись")
	| Ast.ErrDotSelectorToNotRecord:
		C("Селектор элемента записи применён не к записи")
	| Ast.ErrDeclarationNotVar:
		C("Ожидалась переменная")
	| Ast.ErrForIteratorNotInteger:
		C("Итератор FOR не целочисленного типа")
	| Ast.ErrNotBoolInIfCondition:
		C("Выражение в охране условного оператора должно быть логическим")
	| Ast.ErrNotBoolInWhileCondition:
		C("Выражение в охране цикла WHILE должно быть логическим")
	| Ast.ErrWhileConditionAlwaysFalse:
		C("Охрана цикла WHILE всегда ложна")
	| Ast.ErrWhileConditionAlwaysTrue:
		C("Цикл бесконечен, так как охрана WHILE всегда истинна")
	| Ast.ErrNotBoolInUntil:
		C("Выражение в условии завершения цикла REPEAT должно быть логическим")
	| Ast.ErrUntilAlwaysFalse:
		C("Цикл бесконечен, так как условие завершения всегда ложно")
	| Ast.ErrUntilAlwaysTrue:
		C("Условие завершения всегда истинно")
	| Ast.ErrDeclarationIsPrivate:
		C("Объявление не экспортировано")
	| Ast.ErrNegateNotBool:
		C("Логическое отрицание применено не к логическому типу")
	| Ast.ErrConstAddOverflow:
		C("Переполнение при сложении постоянных")
	| Ast.ErrConstSubOverflow:
		C("Переполнение при вычитании постоянных")
	| Ast.ErrConstMultOverflow:
		C("Переполнение при умножении постоянных")
	| Ast.ErrComDivByZero:
		C("Деление на 0")
	| Ast.ErrValueOutOfRangeOfByte:
		C("Значение выходит за границы BYTE")
	| Ast.ErrValueOutOfRangeOfChar:
		C("Значение выходит за границы CHAR")
	| Ast.ErrExpectIntExpr:
		C("Ожидается целочисленное выражение")
	| Ast.ErrExpectConstIntExpr:
		C("Ожидается константное целочисленное выражение")
	| Ast.ErrForByZero:
		C("Шаг итератора не может быть равен 0")
	| Ast.ErrByShouldBePositive:
		C("Для прохода от меньшего к большему шаг итератора должен быть > 0")
	| Ast.ErrByShouldBeNegative:
		C("Для прохода от большего к меньшему шаг итератора должен быть < 0")
	| Ast.ErrForPossibleOverflow:
		C("Во время итерации в FOR возможно переполнение")
	| Ast.ErrVarUninitialized:
		C("Использование неинициализированной переменной")
	| Ast.ErrVarMayUninitialized:
		C("Использование переменной, которая может быть не инициализирована")
	| Ast.ErrDeclarationNotProc:
		C("Имя должно указывать на процедуру")
	| Ast.ErrProcNotCommandHaveReturn:
		C("В качестве команды может выступать только процедура без возращаемого значения")
	| Ast.ErrProcNotCommandHaveParams:
		C("В качестве команды может выступать только процедура без параметров")
	| Ast.ErrReturnTypeArrayOrRecord:
		C("Тип возвращаемого значения процедуры не может быть массивом или записью")
	| Ast.ErrRecordForwardUndefined:
		C("Есть необъявленная запись, на которую предварительно ссылается указатель")
	| Ast.ErrPointerToNotRecord:
		C("Указатель может ссылаться только на запись")
	| Ast.ErrAssertConstFalse:
		C("Выражение в Assert всегда ложно")
	| Ast.ErrVarOfRecordForward:
		C("Объявлена переменная, чей тип - это недообъявленная запись")
	| Ast.ErrArrayTypeOfRecordForward:
		C("Недообъявленная запись в качестве подтипа массива")
	| Ast.ErrDeclarationUnused:
		C("Существует незадействованное объявление в этой области видимости")
	| Ast.ErrProcNestedTooDeep:
		C("Слишком глубокая вложенность подпрограмм")
	END
END AstError;

PROCEDURE ParseError*(code: INTEGER);
BEGIN
	CASE code OF
	  Scanner.ErrUnexpectChar:
		C("Неожиданный символ в тексте")
	| Scanner.ErrNumberTooBig:
		C("Значение константы слишком велико")
	| Scanner.ErrRealScaleTooBig:
		C("ErrRealScaleTooBig")
	| Scanner.ErrWordLenTooBig:
		C("ErrWordLenTooBig")
	| Scanner.ErrExpectHOrX:
		C("В конце 16-ричного числа ожидается 'H' или 'X'")
	| Scanner.ErrExpectDQuote:
		C("Ожидалась "); C(Utf8.DQuote)
	| Scanner.ErrExpectDigitInScale:
		C("ErrExpectDigitInScale")
	| Scanner.ErrUnclosedComment:
		C("Незакрытый комментарий")

	| Parser.ErrExpectModule:
		C("Ожидается 'MODULE'")
	| Parser.ErrExpectIdent:
		C("Ожидается имя")
	| Parser.ErrExpectColon:
		C("Ожидается ':'")
	| Parser.ErrExpectSemicolon:
		C("Ожидается ';'")
	| Parser.ErrExpectEnd:
		C("Ожидается 'END'")
	| Parser.ErrExpectDot:
		C("Ожидается '.'")
	| Parser.ErrExpectModuleName:
		C("Ожидается имя модуля")
	| Parser.ErrExpectEqual:
		C("Ожидается '='")
	| Parser.ErrExpectBrace1Close:
		C("Ожидается ')'")
	| Parser.ErrExpectBrace2Close:
		C("Ожидается ']'")
	| Parser.ErrExpectBrace3Close:
		C("Ожидается '}'")
	| Parser.ErrExpectOf:
		C("Ожидается OF")
	| Parser.ErrExpectTo:
		C("Ожидается TO")
	| Parser.ErrExpectStructuredType:
		C("Ожидается структурный тип: массив, запись, указатель, процедурный")
	| Parser.ErrExpectRecord:
		C("Ожидается запись")
	| Parser.ErrExpectStatement:
		C("Ожидается оператор")
	| Parser.ErrExpectThen:
		C("Ожидается THEN")
	| Parser.ErrExpectAssign:
		C("Ожидается :=")
	| Parser.ErrExpectVarRecordOrPointer:
		C("Ожидается переменная типа запись либо указателя на неё")
	| Parser.ErrExpectType:
		C("Ожидается тип")
	| Parser.ErrExpectUntil:
		C("Ожидается UNTIL")
	| Parser.ErrExpectDo:
		C("Ожидается DO")
	| Parser.ErrExpectDesignator:
		C("Ожидается обозначение")
	| Parser.ErrExpectProcedure:
		C("Ожидается процедура")
	| Parser.ErrExpectConstName:
		C("Ожидается имя константы")
	| Parser.ErrExpectProcedureName:
		C("Ожидается завершающее имя процедуры")
	| Parser.ErrExpectExpression:
		C("Ожидается выражение")
	| Parser.ErrExcessSemicolon:
		C("Лишняя ';'")
	| Parser.ErrEndModuleNameNotMatch:
		C("Завершающее имя в конце модуля не совпадает с его именем")
	| Parser.ErrArrayDimensionsTooMany:
		C("Слишком большая n-мерность массива")
	| Parser.ErrEndProcedureNameNotMatch:
		C("Завершающее имя в теле процедуры не совпадает с её именем")
	| Parser.ErrFunctionWithoutBraces:
		C("Объявление процедуры с возвращаемым значением не содержит скобки")
	| Parser.ErrExpectIntOrStrOrQualident:
		C("Ожидалось число или строка")
	| Parser.ErrMaybeAssignInsteadEqual:
		C("Неуместный '='. Возможно, имелcя ввиду ':=' для присваивания")
	| Parser.ErrUnexpectStringInCaseLabel:
		C("В качестве метки CASE недопустимы не односимвольные строки")
	| Parser.ErrExpectAnotherModuleName:
		C("Ожидался модуль с другим именем")
	END
END ParseError;

PROCEDURE Usage*;
BEGIN
S("Использование: ");
S("  1) o7c help");
S("  2) o7c to-c   Код ВыхКат {-m ПкМ | -i ПкИ | -infr Инфр}");
S("  3) o7c to-bin Код Исполн {-m ПМ|-i ПИ|-infr И|-c ПHC|-cc Компил|-t ВремКат}");
S("  4) o7c run    Код {-m ПкМ|-i ПкИ|-c ПHC|-t ВремКат} [-- Пар-ры]");
S("2) to-c   преобразовывает модули в набор .h и .c файлов");
S("3) to-bin превращает модули в исполнимый файл через неявные .c файлы");
S("4) run    выполняет неявный исполнимый файл, созданный по Коду");
S("Код - это упрощенный текст на Обероне, выражаемый через разновидность РБНФ:");
S("  Код = Вызов { ; Вызов } . Вызов = Модуль.Процедура [ '('Пар-ры')' ] .");
S("ВыхКат - Выходной Каталог для создаваемых .h и .c файлов.");
S("Исполн - имя создаваемого исполнимого файла.");
S("-m ПкМ - Путь к каталогу с Модулями, нужного для поиска.");
S("  Пример: -m library -m source -m test/source");
S("-i ПкИ - Путь к каталогу с Интерфейсными модулями без настоящего воплощения");
S("  Пример: -i singularity/definition");
S("-c ПHC - Путь к каталогу с .h и .c файлами-воплощениями интерфейсных модулей");
S("  Пример: -c singularity/implementation");
S("-infr Инфр - путь к Инфр_аструктуре. '-infr p' - это сокращение для:");
S("  -i p/singularity/definition -c p/singularity/implementation -m p/library");
S("-t ВремКат - новый Временный Каталог для хранения промежуточного .h и .c кода");
S("  Пример: -t result/test/ReadDir.src");
S("-cc Компил - Компилятро C для сбора .c-кода, по умолчанию 'cc -g -O1'");
S("  Пример: -cc 'clang -O3 -flto -s'");
S("-- Пар-ры - Параметры командной строки для запускаемого исполнимого файла")
END Usage;

PROCEDURE CliError*(err: INTEGER; cmd: ARRAY OF CHAR);
BEGIN
	CASE err OF
	  Cli.ErrWrongArgs:
		Usage
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
		C("Неизвестная команда: ");
		S(cmd);
		Usage
	| Cli.ErrNotEnoughArgs:
		C("Недостаточно аргументов для команды: ");
		S(cmd)
	| Cli.ErrTooLongModuleDirs:
		S("Суммарная длина путей с модулями слишком велика")
	| Cli.ErrTooManyModuleDirs:
		S("Cлишком много путей с модулями")
	| Cli.ErrTooLongCDirs:
		S("Суммарная длина путей с .c-файлами слишком велика")
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
	END
END CliError;

PROCEDURE Text*(str: ARRAY OF CHAR);
BEGIN
	IF str = "Found errors in the module " THEN
		C("Найдены ошибки в модуле ")
	ELSIF str = "Can not found or open file of module " THEN
		C("Не получается найти или открыть файл модуля ")
	ELSE
		C(str)
	END
END Text;

END MessageRu.

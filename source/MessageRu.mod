(*  Russian messages for interface
 *  Copyright (C) 2017  ComdivByZero
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
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

PROCEDURE O(s: ARRAY OF CHAR);
BEGIN
	Out.String(s)
END O;

PROCEDURE S(s: ARRAY OF CHAR);
BEGIN
	Out.String(s);
	Out.Ln
END S;

PROCEDURE AstError*(code: INTEGER);
BEGIN
	CASE code OF
	  Ast.ErrImportNameDuplicate:
		O("Имя модуля уже встречается в списке импорта")
	| Ast.ErrImportSelf:
		O("Модуль импортирует себя")
	| Ast.ErrImportLoop:
		O("Прямой или косвенный циклический импорт запрещён")
	| Ast.ErrDeclarationNameDuplicate:
		O("Повторное объявление имени в той же области видимости")
	| Ast.ErrDeclarationNameHide:
		O("Имя объявления затеняет объявление из модуля")
	| Ast.ErrMultExprDifferentTypes:
		O("Типы подвыражений в умножении несовместимы")
	| Ast.ErrDivExprDifferentTypes:
		O("Типы подвыражений в делении несовместимы")
	| Ast.ErrNotBoolInLogicExpr:
		O("В логическом выражении должны использоваться подвыражения логического же типа")
	| Ast.ErrNotIntInDivOrMod:
		O("В целочисленном делении допустимы только целочисленные подвыражения")
	| Ast.ErrNotRealTypeForRealDiv:
		O("В дробном делении допустимы только подвыражения дробного типа")
	| Ast.ErrNotIntSetElem:
		O("В качестве элементов множества допустимы только целые числа")
	| Ast.ErrSetElemOutOfRange:
		O("Элемент множества выходит за границы возможных значений - 0 .. 31")
	| Ast.ErrSetLeftElemBiggerRightElem:
		O("Левый элемент диапазона больше правого")
	| Ast.ErrAddExprDifferenTypes:
		O("Типы подвыражений в сложении несовместимы")
	| Ast.ErrNotNumberAndNotSetInMult:
		O("В выражениях *, /, DIV, MOD допустимы только числа и множества")
	| Ast.ErrNotNumberAndNotSetInAdd:
		O("В выражениях +, - допустимы только числа и множества")
	| Ast.ErrSignForBool:
		O("Унарный знак не применим к логическому выражению")
	| Ast.ErrRelationExprDifferenTypes:
		O("Типы подвыражений в сравнении не совпадают")
	| Ast.ErrExprInWrongTypes:
		O("Ast.ErrExprInWrongTypes")
	| Ast.ErrExprInRightNotSet:
		O("Ast.ErrExprInRightNotSet")
	| Ast.ErrExprInLeftNotInteger:
		O("Левый член выражения IN должен быть целочисленным")
	| Ast.ErrRelIncompatibleType:
		O("В сравнении выражения несовместимых типов")
	| Ast.ErrIsExtTypeNotRecord:
		O("Проверка IS применима только к записям")
	| Ast.ErrIsExtVarNotRecord:
		O("Левый член проверки IS должен иметь тип записи или указателя на неё")
	| Ast.ErrIsExtMeshupPtrAndRecord:
		O("Тип переменной слева от IS должен быть того же сорта, что и тип справа")
	| Ast.ErrIsExtExpectRecordExt:
		O("Справа от IS нужен расширенный тип по отношению к типу переменной слева")
	| Ast.ErrConstDeclExprNotConst:
		O("Постоянная сопоставляется выражению, невычислимым на этапе перевода")
	| Ast.ErrAssignIncompatibleType:
		O("Несовместимые типы в присваивании")
	| Ast.ErrAssignExpectVarParam:
		O("Ожидалось изменяемое выражение в присваивании")
	| Ast.ErrCallNotProc:
		O("Вызов допустим только для процедур и переменных процедурного типа")
	| Ast.ErrCallIgnoredReturn:
		O("Возвращаемое значение не задействовано в выражении")
	| Ast.ErrCallExprWithoutReturn:
		O("Вызываемая процедура не возвращает значения")
	| Ast.ErrCallExcessParam:
		O("Лишние параметры при вызове процедуры")
	| Ast.ErrCallIncompatibleParamType:
		O("Несовместимый тип параметра")
	| Ast.ErrCallExpectVarParam:
		O("Параметр должен быть изменяемым значением")
	| Ast.ErrCallVarPointerTypeNotSame:
		O("Для переменного параметра - указателя должен использоваться аргумент того же типа")
	| Ast.ErrCallParamsNotEnough:
		O("Не хватает фактических параметров в вызове процедуры")
	| Ast.ErrCaseExprNotIntOrChar:
		O("Выражение в CASE должно быть целочисленным или литерой")
	| Ast.ErrCaseElemExprTypeMismatch:
		O("Метки CASE должно быть целочисленными или литерами")
	| Ast.ErrCaseElemDuplicate:
		O("Дублирование значения меток в CASE")
	| Ast.ErrCaseRangeLabelsTypeMismatch:
		O("Не совпадает тип меток CASE")
	| Ast.ErrCaseLabelLeftNotLessRight:
		O("Левая часть диапазона значений в метке CASE должна быть меньше правой")
	| Ast.ErrCaseLabelNotConst:
		O("Метки CASE должны быть константами")
	| Ast.ErrProcHasNoReturn:
		O("Процедура не имеет возвращаемого значения")
	| Ast.ErrReturnIncompatibleType:
		O("Тип возвращаемого значения не совместим типом, указанном в заголовке процедуры")
	| Ast.ErrExpectReturn:
		O("Ожидался возврат значения, так как в заголовке процедуры указан возвращаемый тип")
	| Ast.ErrDeclarationNotFound:
		O("Предварительное объявление имени не было найдено")
	| Ast.ErrConstRecursive:
		O("Недопустимое использование константы для задания собственного значения")
	| Ast.ErrImportModuleNotFound:
		O("Импортированный модуль не был найден")
	| Ast.ErrImportModuleWithError:
		O("Импортированный модуль содержит ошибки")
	| Ast.ErrDerefToNotPointer:
		O("Разыменовывание применено не к указателю")
	| Ast.ErrArrayLenLess1:
		O("Длина массива должна быть > 0")
	| Ast.ErrArrayLenTooBig:
		O("Общая длина массива слишком большая")
	| Ast.ErrArrayItemToNotArray:
		O("Получение элемента не массива")
	| Ast.ErrArrayIndexNotInt:
		O("Индекс массива не целочисленный")
	| Ast.ErrArrayIndexNegative:
		O("Отрицательный индекс массива")
	| Ast.ErrArrayIndexOutOfRange:
		O("Индекс массива выходит за его границы")
	| Ast.ErrGuardExpectRecordExt:
		O("В защите типа ожидается расширенная запись")
	| Ast.ErrGuardExpectPointerExt:
		O("В защите типа ожидается указатель на расширенную запись")
	| Ast.ErrGuardedTypeNotExtensible:
		O("В защите типа переменная должна быть либо записью, либо указателем на запись")
	| Ast.ErrDotSelectorToNotRecord:
		O("Селектор элемента записи применён не к записи")
	| Ast.ErrDeclarationNotVar:
		O("Ожидалась переменная")
	| Ast.ErrForIteratorNotInteger:
		O("Итератор FOR не целочисленного типа")
	| Ast.ErrNotBoolInIfCondition:
		O("Выражение в охране условного оператора должно быть логическим")
	| Ast.ErrNotBoolInWhileCondition:
		O("Выражение в охране цикла WHILE должно быть логическим")
	| Ast.ErrWhileConditionAlwaysFalse:
		O("Охрана цикла WHILE всегда ложна")
	| Ast.ErrWhileConditionAlwaysTrue:
		O("Цикл бесконечен, так как охрана WHILE всегда истинна")
	| Ast.ErrNotBoolInUntil:
		O("Выражение в условии завершения цикла REPEAT должно быть логическим")
	| Ast.ErrUntilAlwaysFalse:
		O("Цикл бесконечен, так как условие завершения всегда ложно")
	| Ast.ErrUntilAlwaysTrue:
		O("Условие завершения всегда истинно")
	| Ast.ErrDeclarationIsPrivate:
		O("Объявление не экспортировано")
	| Ast.ErrNegateNotBool:
		O("Логическое отрицание применено не к логическому типу")
	| Ast.ErrConstAddOverflow:
		O("Переполнение при сложении постоянных")
	| Ast.ErrConstSubOverflow:
		O("Переполнение при вычитании постоянных")
	| Ast.ErrConstMultOverflow:
		O("Переполнение при умножении постоянных")
	| Ast.ErrComDivByZero:
		O("Деление на 0")
	| Ast.ErrValueOutOfRangeOfByte:
		O("Значение выходит за границы BYTE")
	| Ast.ErrValueOutOfRangeOfChar:
		O("Значение выходит за границы CHAR")
	| Ast.ErrExpectIntExpr:
		O("Ожидается целочисленное выражение")
	| Ast.ErrExpectConstIntExpr:
		O("Ожидается константное целочисленное выражение")
	| Ast.ErrForByZero:
		O("Шаг итератора не может быть равен 0")
	| Ast.ErrByShouldBePositive:
		O("Для прохода от меньшего к большему шаг итератора должен быть > 0")
	| Ast.ErrByShouldBeNegative:
		O("Для прохода от большего к меньшему шаг итератора должен быть < 0")
	| Ast.ErrForPossibleOverflow:
		O("Во время итерации в FOR возможно переполнение")
	| Ast.ErrVarUninitialized:
		O("Использование неинициализированной переменной")
	| Ast.ErrDeclarationNotProc:
		O("Имя должно указывать на процедуру")
	| Ast.ErrProcNotCommandHaveReturn:
		O("В качестве команды может выступать только процедура без возращаемого значения")
	| Ast.ErrProcNotCommandHaveParams:
		O("В качестве команды может выступать только процедура без параметров")
	| Ast.ErrReturnTypeArrayOrRecord:
		O("Тип возвращаемого значения процедуры не может быть массивом или записью")
	| Ast.ErrRecordForwardUndefined:
		O("Есть необъявленная запись, на которую предварительно ссылается указатель")
	| Ast.ErrPointerToNotRecord:
		O("Указатель может ссылаться только на запись")
	END
END AstError;

PROCEDURE ParseError*(code: INTEGER);
BEGIN
	CASE code OF
	  Scanner.ErrUnexpectChar:
		O("Неожиданный символ в тексте")
	| Scanner.ErrNumberTooBig:
		O("Значение константы слишком велико")
	| Scanner.ErrRealScaleTooBig:
		O("ErrRealScaleTooBig")
	| Scanner.ErrWordLenTooBig:
		O("ErrWordLenTooBig")
	| Scanner.ErrExpectHOrX:
		O("В конце 16-ричного числа ожидается 'H' или 'X'")
	| Scanner.ErrExpectDQuote:
		O("Ожидалась "); O(Utf8.DQuote)
	| Scanner.ErrExpectDigitInScale:
		O("ErrExpectDigitInScale")
	| Scanner.ErrUnclosedComment:
		O("Незакрытый комментарий")

	| Parser.ErrExpectModule:
		O("Ожидается 'MODULE'")
	| Parser.ErrExpectIdent:
		O("Ожидается имя")
	| Parser.ErrExpectColon:
		O("Ожидается ':'")
	| Parser.ErrExpectSemicolon:
		O("Ожидается ';'")
	| Parser.ErrExpectEnd:
		O("Ожидается 'END'")
	| Parser.ErrExpectDot:
		O("Ожидается '.'")
	| Parser.ErrExpectModuleName:
		O("Ожидается имя модуля")
	| Parser.ErrExpectEqual:
		O("Ожидается '='")
	| Parser.ErrExpectBrace1Close:
		O("Ожидается ')'")
	| Parser.ErrExpectBrace2Close:
		O("Ожидается ']'")
	| Parser.ErrExpectBrace3Close:
		O("Ожидается '}'")
	| Parser.ErrExpectOf:
		O("Ожидается OF")
	| Parser.ErrExpectTo:
		O("Ожидается TO")
	| Parser.ErrExpectStructuredType:
		O("Ожидается структурный тип: массив, запись, указатель, процедурный")
	| Parser.ErrExpectRecord:
		O("Ожидается запись")
	| Parser.ErrExpectStatement:
		O("Ожидается оператор")
	| Parser.ErrExpectThen:
		O("Ожидается THEN")
	| Parser.ErrExpectAssign:
		O("Ожидается :=")
	| Parser.ErrExpectVarRecordOrPointer:
		O("Ожидается переменная типа запись либо указателя на неё")
	| Parser.ErrExpectType:
		O("Ожидается тип")
	| Parser.ErrExpectUntil:
		O("Ожидается UNTIL")
	| Parser.ErrExpectDo:
		O("Ожидается DO")
	| Parser.ErrExpectDesignator:
		O("Ожидается обозначение")
	| Parser.ErrExpectProcedure:
		O("Ожидается процедура")
	| Parser.ErrExpectConstName:
		O("Ожидается имя константы")
	| Parser.ErrExpectProcedureName:
		O("Ожидается завершающее имя процедуры")
	| Parser.ErrExpectExpression:
		O("Ожидается выражение")
	| Parser.ErrExcessSemicolon:
		O("Лишняя ';'")
	| Parser.ErrEndModuleNameNotMatch:
		O("Завершающее имя в конце модуля не совпадает с его именем")
	| Parser.ErrArrayDimensionsTooMany:
		O("Слишком большая n-мерность массива")
	| Parser.ErrEndProcedureNameNotMatch:
		O("Завершающее имя в теле процедуры не совпадает с её именем")
	| Parser.ErrFunctionWithoutBraces:
		O("Объявление процедуры с возвращаемым значением не содержит скобки")
	| Parser.ErrExpectIntOrStrOrQualident:
		O("Ожидалось число или строка")
	| Parser.ErrMaybeAssignInsteadEqual:
		O("Неуместный '='. Возможно, имелcя ввиду ':=' для присваивания")
	| Parser.ErrUnexpectStringInCaseLabel:
		O("В качестве метки CASE недопустимы не односимвольные строки")
	END
END ParseError;

PROCEDURE Usage*;
BEGIN
S("Использование: ");
S("  1) o7c help");
S("  2) o7c to-c команда вых.каталог {-m путьКмодулям | -i кат.с_интерф-ми_мод-ми}");
S("Команда - это модуль[.процедура_без_параметров] .");
S("В случае успешной трансляции создаст в выходном каталоге набор .h и .c-файлов,");
S("соответствующих как самому исходному модулю, так и используемых им модулей,");
S("кроме лежащих в каталогах, указанным после опции -i, служащих интерфейсами");
S("для других .h и .с-файлов.");
S("  3) o7c to-bin ком-да результат {-m пКм | -i кИм | -c .h,c-файлы} [-cc компил.]");
S("После трансляции указанного модуля вызывает компилятор cc по умолчанию, либо");
S("указанный после опции -cc, для сбора результата - исполнимого файла, в состав");
S("которого также войдут .h,c файлы, находящиеся в каталогах, указанных после -c.");
S("  4) o7c run команда {-m путь_к_м. | -i к.с_инт_м. | -c .h,c-файлы} -- параметры");
S("Запускает собранный модуль с параметрами, указанными после --");
S("Также, доступен параметр -infr путь , который эквивалентен совокупности:");
S("-i путь/singularity/definition -c путь/singularity/implementation -m путь/library")
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
		O("Неизвестная команда: ");
		S(cmd);
		Usage
	| Cli.ErrNotEnoughArgs:
		O("Недостаточно аргументов для команды: ");
		S(cmd)
	| Cli.ErrTooLongModuleDirs:
		S("Суммарная длина путей с модулями слишком велика")
	| Cli.ErrTooManyModuleDirs:
		S("Cлишком много путей с модулями")
	| Cli.ErrTooLongCDirs:
		S("Суммарная длина путей с .c-файлами слишком велика")
	| Cli.ErrTooLongCc:
		S("Длина опций компилятора C слишком велика")
	| Cli.ErrCCompiler:
		S("Ошибка при вызове компилятора C")
	| Cli.ErrTooLongRunArgs:
		S("Слишком длинные параметры командной строки")
	| Cli.ErrUnexpectArg:
		S("Неожиданный аргумент")
	| Cli.ErrUnknownInit:
		S("Указанный способ инициализации науке неизвестен")
	| Cli.ErrCantCreateOutDir:
		S("Не получается создать выходной каталог")
	| Cli.ErrCantRemoveOutDir:
		S("Не получается удалить выходной каталог")
	END
END CliError;

PROCEDURE Text*(str: ARRAY OF CHAR);
BEGIN
	IF str = "Found errors in the module " THEN
		O("Найдены ошибки в модуле ")
	ELSIF str = "Can not found or open file of module" THEN
		O("Не получается найти или открыть файл модуля")
	ELSE
		O(str)
	END
END Text;

END MessageRu.

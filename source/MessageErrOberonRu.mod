(*  Russian messages for syntax and semantic errors. Extracted from MessageRu.
 *  Copyright (C) 2017-2023 ComdivByZero
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
MODULE MessageErrOberonRu;

IMPORT AST := Ast, Parser, Cli := CliParser, Scanner, Out, Utf8;

PROCEDURE C(s: ARRAY OF CHAR);
BEGIN
	Out.String(s)
END C;

PROCEDURE Ast*(code: INTEGER);
BEGIN
	CASE code OF
	  AST.ErrImportNameDuplicate:
		C("Имя модуля уже встречается в списке импорта - ")
	| AST.ErrImportSelf:
		C("Модуль импортирует себя - ")
	| AST.ErrImportLoop:
		C("Прямой или косвенный циклический импорт запрещён - ")
	| AST.ErrDeclarationNameDuplicate:
		C("Повторное объявление имени в той же области видимости - ")
	| AST.ErrDeclarationNameHide:
		C("Имя объявления затеняет объявление из модуля - ")
	| AST.ErrPredefinedNameHide:
		C("Имя объявления затеняет предопределённое имя - ")
	| AST.ErrMultExprDifferentTypes:
		C("Типы подвыражений в умножении несовместимы")
	| AST.ErrDivExprDifferentTypes:
		C("Типы подвыражений в делении несовместимы")
	| AST.ErrNotBoolInLogicExpr:
		C("В логическом выражении должны использоваться подвыражения логического же типа")
	| AST.ErrNotIntInDivOrMod:
		C("В целочисленном делении допустимы только целочисленные подвыражения")
	| AST.ErrNotRealTypeForRealDiv:
		C("В дробном делении допустимы только подвыражения дробного типа")
	| AST.ErrNotIntSetElem:
		C("В качестве элементов множества допустимы только целые числа")
	| AST.ErrSetElemOutOfRange:
		C("Элемент множества выходит за границы возможных значений - 0 .. 31")
	| AST.ErrSetElemOutOfLongRange:
		C("Элемент множества выходит за границы возможных значений - 0 .. 63")
	| AST.ErrSetLeftElemBiggerRightElem:
		C("Левый элемент диапазона больше правого")
	| AST.ErrSetElemMaxNotConvertToInt:
		C("Множество, содержащее >=31 не может быть преобразовано в целое")
	| AST.ErrSetFromLongSet:
		C("Нельзя сохранить значение длинного множества в обычном")
	| AST.ErrAddExprDifferenTypes:
		C("Типы подвыражений в сложении несовместимы")
	| AST.ErrNotNumberAndNotSetInMult:
		C("В выражениях *, /, DIV, MOD допустимы только числа и множества")
	| AST.ErrNotNumberAndNotSetInAdd:
		C("В выражениях +, - допустимы только числа и множества")
	| AST.ErrSignForBool:
		C("Унарный знак не применим к логическому выражению")
	| AST.ErrRelationExprDifferenTypes:
		C("Типы подвыражений в сравнении не совпадают")
	| AST.ErrExprInWrongTypes:
		C("Левый член выражения должен быть целочисленным, правый - множеством")
	| AST.ErrExprInRightNotSet:
		C("Правый член выражения IN должен быть множеством")
	| AST.ErrExprInLeftNotInteger:
		C("Левый член выражения IN должен быть целочисленным")
	| AST.ErrRelIncompatibleType:
		C("В сравнении выражения несовместимых типов")
	| AST.ErrIsExtTypeNotRecord:
		C("Проверка IS применима только к записям")
	| AST.ErrIsExtVarNotRecord:
		C("Левый член проверки IS должен иметь тип записи или указателя на неё")
	| AST.ErrIsExtMeshupPtrAndRecord:
		C("Тип переменной слева от IS должен быть того же сорта, что и тип справа")
	| AST.ErrIsExtExpectRecordExt:
		C("Справа от IS нужен расширенный тип по отношению к типу переменной слева")
	| AST.ErrIsEqualProc:
		C("Непосредственное сравнение подпрограмм недопустимо")
	| AST.ErrConstDeclExprNotConst:
		C("Постоянная сопоставляется выражению, невычислимым на этапе перевода")
	| AST.ErrAssignIncompatibleType:
		C("Несовместимые типы в присваивании")
	| AST.ErrAssignExpectVarParam:
		C("Ожидалось изменяемое выражение в присваивании")
	| AST.ErrAssignStringToNotEnoughArray:
		C("Присваивание строки массиву недостаточного размера")
	| AST.ErrCallNotProc:
		C("Вызов допустим только для процедур и переменных процедурного типа")
	| AST.ErrCallIgnoredReturn:
		C("Возвращаемое значение не задействовано в выражении")
	| AST.ErrCallExprWithoutReturn:
		C("Вызываемая подпрограмма не возвращает значения")
	| AST.ErrCallExcessParam:
		C("Лишние параметры при вызове процедуры")
	| AST.ErrCallIncompatibleParamType:
		C("Несовместимый тип параметра")
	| AST.ErrCallExpectVarParam:
		C("Параметр должен быть изменяемым")
	| AST.ErrCallExpectAddressableParam:
		C("Параметр должен быть адресуемым")
	| AST.ErrCallVarPointerTypeNotSame:
		C("Для переменного параметра - указателя должен использоваться аргумент того же типа")
	| AST.ErrCallParamsNotEnough:
		C("Не хватает фактических параметров в вызове процедуры")
	| AST.ErrInfiniteCall:
		C("Неограниченная рекурсия")
	| AST.ErrCaseExprWrongType:
		C("Выражение в CASE должно быть целочисленным, литерой, указателем или записью")
	| AST.ErrCaseLabelWrongType:
		C("Метка CASE должна быть целочисленной или литерой, или быть типом указатель или запись")
	| AST.ErrCaseRecordNotLocalVar:
		C("Выражение в CASE указательного или записевого типа не является локальной переменной")
	| AST.ErrCasePointerVarParam:
		C("Выражение в CASE не должно быть VAR-параметром указательного типа")
	| AST.ErrCaseRecordNotParam:
		C("Переменная-запись в CASE должна быть формальным параметром")
	| AST.ErrCaseLabelNotRecExt:
		C("Тип метки в CASE должен быть расширением типа выражения в CASE")
	| AST.ErrCaseElemExprTypeMismatch:
		C("Тип метки CASE должен соответствовать типу выражения в CASE")
	| AST.ErrCaseElemDuplicate:
		C("Дублирование значения меток в CASE")
	| AST.ErrCaseRangeLabelsTypeMismatch:
		C("Не совпадает тип меток CASE")
	| AST.ErrCaseLabelLeftNotLessRight:
		C("Левая часть диапазона значений в метке CASE должна быть меньше правой")
	| AST.ErrCaseLabelNotConst:
		C("Метки CASE должны быть константами")
	| AST.ErrCaseElseAlreadyExist:
		C("ELSE ветка в CASE уже есть")
	| AST.ErrProcHasNoReturn:
		C("Подпрограмма не имеет возвращаемого значения")
	| AST.ErrReturnIncompatibleType:
		C("Тип возвращаемого значения не совместим с типом, указанном в заголовке процедуры")
	| AST.ErrExpectReturn:
		C("Ожидался возврат значения, так как в заголовке процедуры указан возвращаемый тип")
	| AST.ErrDeclarationNotFound:
		C("Не было найдено предварительного объявления имени - ")
	| AST.ErrConstRecursive:
		C("Недопустимое использование константы для задания собственного значения")
	| AST.ErrImportModuleNotFound:
		C("Импортированный модуль не был найден - ")
	| AST.ErrImportModuleWithError:
		C("Импортированный модуль содержит ошибки - ")
	| AST.ErrDerefToNotPointer:
		C("Разыменование применено не к указателю")
	| AST.ErrArrayLenLess1:
		C("Длина массива должна быть > 0")
	| AST.ErrArrayLenTooBig:
		C("Общая длина массива слишком большая")
	| AST.ErrArrayItemToNotArray:
		C("Получение элемента не массива")
	| AST.ErrArrayIndexNotInt:
		C("Индекс массива не целочисленный")
	| AST.ErrArrayIndexNegative:
		C("Отрицательный индекс массива")
	| AST.ErrArrayIndexOutOfRange:
		C("Индекс массива выходит за его границы")
	| AST.ErrStringIndexing:
		C("Индексация строкового литерала не разрешена")
	| AST.ErrGuardExpectRecordExt:
		C("В защите типа ожидается расширенная запись")
	| AST.ErrGuardExpectPointerExt:
		C("В защите типа ожидается указатель на расширенную запись")
	| AST.ErrGuardedTypeNotExtensible:
		C("В защите типа переменная должна быть либо записью, либо указателем на запись")
	| AST.ErrDotSelectorToNotRecord:
		C("Селектор элемента записи применён не к записи")
	| AST.ErrDeclarationNotVar:
		C("Ожидалась переменная вместо ")
	| AST.ErrForIteratorNotInteger:
		C("Итератор FOR должен задаваться именем переменной типа INTEGER")
	| AST.ErrNotBoolInIfCondition:
		C("Выражение в охране условного оператора должно быть логическим")
	| AST.ErrNotBoolInWhileCondition:
		C("Выражение в охране цикла WHILE должно быть логическим")
	| AST.ErrWhileConditionAlwaysFalse:
		C("Охрана цикла WHILE всегда ложна")
	| AST.ErrWhileConditionAlwaysTrue:
		C("Цикл бесконечен, так как охрана WHILE всегда истинна")
	| AST.ErrNotBoolInUntil:
		C("Выражение в условии завершения цикла REPEAT должно быть логическим")
	| AST.ErrUntilAlwaysFalse:
		C("Цикл бесконечен, так как условие завершения всегда ложно")
	| AST.ErrUntilAlwaysTrue:
		C("Условие завершения всегда истинно")
	| AST.ErrDeclarationIsPrivate:
		C("Объявление не экспортировано - ")
	| AST.ErrNegateNotBool:
		C("Логическое отрицание применено не к логическому типу")
	| AST.ErrConstAddOverflow:
		C("Переполнение при сложении постоянных")
	| AST.ErrConstSubOverflow:
		C("Переполнение при вычитании постоянных")
	| AST.ErrConstMultOverflow:
		C("Переполнение при умножении постоянных")
	| AST.ErrComDivByZero:
		C("Деление на 0")
	| AST.ErrNegativeDivisor:
		C("Деление на отрицательное число не определено")
	| AST.ErrValueOutOfRangeOfByte:
		C("Значение выходит за границы BYTE")
	| AST.ErrValueOutOfRangeOfChar:
		C("Значение выходит за границы CHAR")
	| AST.ErrExpectIntExpr:
		C("Ожидается целочисленное выражение")
	| AST.ErrExpectConstIntExpr:
		C("Ожидается константное целочисленное выражение")
	| AST.ErrForByZero:
		C("Шаг итератора не может быть равен 0")
	| AST.ErrByShouldBePositive:
		C("Для прохода от меньшего к большему шаг итератора должен быть > 0")
	| AST.ErrByShouldBeNegative:
		C("Для прохода от большего к меньшему шаг итератора должен быть < 0")
	| AST.ErrForPossibleOverflow:
		C("Во время итерации в FOR возможно переполнение")
	| AST.ErrVarUninitialized:
		C("Использование неинициализированной переменной - ")
	| AST.ErrVarMayUninitialized:
		C("Использование переменной, которая может быть не инициализирована - ")
	| AST.ErrDeclarationNotProc:
		C("Имя должно указывать на процедуру")
	| AST.ErrProcNotCommandHaveReturn:
		C("В качестве команды может выступать только процедура без возращаемого значения")
	| AST.ErrProcNotCommandHaveParams:
		C("В качестве команды может выступать только процедура без параметров")
	| AST.ErrReturnTypeArrayOrRecord:
		C("Тип возвращаемого значения процедуры не может быть массивом или записью")
	| AST.ErrRecordForwardUndefined:
		C("Есть необъявленная запись, на которую предварительно ссылается указатель")
	| AST.ErrPointerToNotRecord:
		C("Указатель может ссылаться только на запись")
	| AST.ErrAssertConstFalse:
		C("Выражение в Assert всегда ложно")
	| AST.ErrVarOfRecordForward:
		C("Объявлена переменная, чей тип - это недообъявленная запись")
	| AST.ErrVarOfPointerToRecordForward:
		C("Объявлена переменная, чей тип - это указатель на недообъявленную запись")
	| AST.ErrArrayTypeOfRecordForward:
		C("Недообъявленная запись в качестве подтипа массива")
	| AST.ErrArrayTypeOfPointerToRecordForward:
		C("Указатель на недообъявленную запись в качестве подтипа массива")
	| AST.ErrParamOfSelfProcType:
		C("Параметр задаёт рекурсивность собственного процедурного типа")
	| AST.ErrDeclarationUnused:
		C("Существует незадействованное объявление в этой области видимости - ")
	| AST.ErrProcNestedTooDeep:
		C("Слишком глубокая вложенность подпрограмм")
	| AST.ErrExpectProcNameWithoutParams:
		C("Ожидалось имя команды - подпрограммы без параметров")
	| AST.ErrParamOutInFunc:
		C("Функция не может быть с выходным параметром")
	| AST.ErrNegativeShift:
		C("Отрицательное смещение недопустимо")
	| AST.ErrLslTooLargeShift:
		C("Слишком большое смещение")
	| AST.ErrLslOverflow:
		C("Переполнение в LSL")
	| AST.ErrShiftGeBits:
		C("Смещение ≥ 32")
	END
END Ast;

PROCEDURE Syntax*(code: INTEGER);
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
	| Scanner.ErrCyrSignAfterNonConsonant:
		C("Ъ Ь ' разрешены только после согласных")
	| Scanner.ErrCyrApostropheEnd:
		C("' не может завершать слово")

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
	| Parser.ErrExpectBrace1Open:
		C("Ожидается '('")
	| Parser.ErrExpectBrace1Close:
		C("Ожидается ')'")
	| Parser.ErrExpectBrace2Open:
		C("Ожидается '['")
	| Parser.ErrExpectBrace2Close:
		C("Ожидается ']'")
	| Parser.ErrExpectBrace3Open:
		C("Ожидается '{'")
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
		C("Неуместный '='. Возможно, имелся ввиду ':=' для присваивания")
	| Parser.ErrUnexpectStringInCaseLabel:
		C("В качестве метки CASE недопустимы не односимвольные строки")
	| Parser.ErrExpectAnotherModuleName:
		C("Ожидался модуль с другим именем")
	| Parser.ErrUnexpectedContentInScript:
		C("Неожиданное содержимое в начала текста кода")
	END
END Syntax;

PROCEDURE Text*(str: ARRAY OF CHAR);
BEGIN
	IF str = "Found errors in the module " THEN
		C("Найдены ошибки в модуле ")
	ELSIF str = "Can not found or open file of module - " THEN
		C("Не получается найти или открыть файл модуля - ")
	ELSIF str = "Name of potential module is too large - " THEN
		C("Имя потенциального модуля слишком велико - ")
	ELSE
		C(str)
	END
END Text;

END MessageErrOberonRu.

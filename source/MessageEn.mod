(*  Command line interface for Oberon-07 translator
 *  Copyright (C) 2016  ComdivByZero
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
		O("Module name already declare in the import list")
	| Ast.ErrDeclarationNameDuplicate:
		O("Redeclaration of name in the same scope")
	| Ast.ErrDeclarationNameHide:
		O("Declaration's name shadow module's declaration")
	| Ast.ErrMultExprDifferentTypes:
		O("Subexpressions types are incompatible")
	| Ast.ErrDivExprDifferentTypes:
		O("Subexpressions types in division are incompatible")
	| Ast.ErrNotBoolInLogicExpr:
		O("In a logic expression must be subexpressions of boolean type")
	| Ast.ErrNotIntInDivOrMod:
		O("In integer division available only integer subexpressions")
	| Ast.ErrNotRealTypeForRealDiv:
		O("In a float point division available only float point subexpressions")
	| Ast.ErrNotIntSetElem:
		O("Set can contain only integers")
	| Ast.ErrSetElemOutOfRange:
		O("Item's  value of set out of range - [0 .. 31]")
	| Ast.ErrSetLeftElemBiggerRightElem:
		O("Left item of range bigger then right item")
	| Ast.ErrAddExprDifferenTypes:
		O("Subexpressions types in sum are incompatible")
	| Ast.ErrNotNumberAndNotSetInMult:
		S("In expressions *, / available only numbers and sets.");
		O("DIV, MOD applicable only for integers")
	| Ast.ErrNotNumberAndNotSetInAdd:
		O("In expresions +, - available only numbers and sets")
	| Ast.ErrSignForBool:
		O("Unary sign not applicable to logic type")
	| Ast.ErrRelationExprDifferenTypes:
		O("Subexpressions types in comparison are not compatible")
	| Ast.ErrExprInWrongTypes:
		O("Ast.ErrExprInWrongTypes")
	| Ast.ErrExprInRightNotSet:
		O("Ast.ErrExprInRightNotSet")
	| Ast.ErrExprInLeftNotInteger:
		O("Left subexpression of IN must be integer")
	| Ast.ErrRelIncompatibleType:
		O("Relation not applicable to such type")
	| Ast.ErrIsExtTypeNotRecord:
		O("IS applicable only to records")
	| Ast.ErrIsExtVarNotRecord:
		O("Left part of IS be record or pointer to record")
	| Ast.ErrConstDeclExprNotConst:
		O("Constant declaration matched to not constant expression")
	| Ast.ErrAssignIncompatibleType:
		O("Incompatible types in assignment")
	| Ast.ErrAssignExpectVarParam:
		O("Expected variable expression in assignment")
	| Ast.ErrCallNotProc:
		O("Call applicable onlty to procedures and procedure's variables")
	| Ast.ErrCallIgnoredReturn:
		O("Returned value can not be ignored")
	| Ast.ErrCallExprWithoutReturn:
		O("Called procedure not return value")
	| Ast.ErrCallExcessParam:
		O("Excess parameters in procedure call")
	| Ast.ErrCallIncompatibleParamType:
		O("Incompatible parameter's type")
	| Ast.ErrCallExpectVarParam:
		O("Parameter must be variable")
	| Ast.ErrCallVarPointerTypeNotSame:
		O("For variable parameter - pointer must used argument of same type")
	| Ast.ErrCallParamsNotEnough:
		O("Not enough parameters in call of procedure")
	| Ast.ErrCaseExprNotIntOrChar:
		O("Expression in CASE must be integer or char")
	| Ast.ErrCaseElemExprTypeMismatch:
		O("Label of CASE must be integer or char")
	| Ast.ErrCaseElemDuplicate:
		O("Values of labels of CASE are duplicated")
	| Ast.ErrCaseRangeLabelsTypeMismatch:
		O("Types of labels in CASE are not equal")
	| Ast.ErrCaseLabelLeftNotLessRight:
		O("Left part of range in label of CASE must be less than right part")
	| Ast.ErrCaseLabelNotConst:
		O("Labels in CASE must be constant")
	| Ast.ErrProcHasNoReturn:
		O("Procedure have not return")
	| Ast.ErrReturnIncompatibleType:
		O("Type of  expression in return is not compatible with declared type in header")
	| Ast.ErrExpectReturn:
		O("Expected return")
	| Ast.ErrDeclarationNotFound:
		O("Declaraion not found")
	| Ast.ErrConstRecursive:
		O("Recursive declaration of constant denied")
	| Ast.ErrImportModuleNotFound:
		O("Imported module not found")
	| Ast.ErrImportModuleWithError:
		O("Imported module contain mistakes")
	| Ast.ErrDerefToNotPointer:
		O("Dereference applicable only to pointers")
	| Ast.ErrArrayItemToNotArray:
		O("[ index ] applicable only to array")
	| Ast.ErrArrayIndexNotInt:
		O("Array index is not integer")
	| Ast.ErrArrayIndexNegative:
		O("Negative array index")
	| Ast.ErrArrayIndexOutOfRange:
		O("Array index out of range")
	| Ast.ErrGuardExpectRecordExt:
		O("In type's guard expected extended record")
	| Ast.ErrGuardExpectPointerExt:
		O("In type's guard expected pointer to extended record")
	| Ast.ErrGuardedTypeNotExtensible:
		O("In a type's guard must be designator of record or pointer to record")
	| Ast.ErrDotSelectorToNotRecord:
		O("Selector '.' applicable only to record and pointer to record")
	| Ast.ErrDeclarationNotVar:
		O("Expected variable")
	| Ast.ErrForIteratorNotInteger:
		O("Iterato of FOR not integer")
	| Ast.ErrNotBoolInIfCondition:
		O("Expression in IF must be of boolean type")
	| Ast.ErrNotBoolInWhileCondition:
		O("Expression in WHILE must be of boolean type")
	| Ast.ErrWhileConditionAlwaysFalse:
		O("Expression in WHILE always false")
	| Ast.ErrWhileConditionAlwaysTrue:
		O("WHILE loop is indefinite becase guard expression always true")
	| Ast.ErrNotBoolInUntil:
		O("Expression in UNTIL must be of boolean type")
	| Ast.ErrUntilAlwaysFalse:
		O("Loop is indefinite because of end condion always false")
	| Ast.ErrUntilAlwaysTrue:
		O("End conditin always true")
	| Ast.ErrDeclarationIsPrivate:
		O("Declaration is not exported")
	| Ast.ErrNegateNotBool:
		O("Логическое отрицание применено не к логическому типу")
	| Ast.ErrConstAddOverflow:
		O("Переполнение при сложении постоянных")
	| Ast.ErrConstSubOverflow:
		O("Переполнение при вычитании постоянных")
	| Ast.ErrConstMultOverflow:
		O("Переполнение при умножении постоянных")
	| Ast.ErrConstDivByZero:
		O("Деление на 0")
	| Ast.ErrValueOutOfRangeOfByte:
		O("Значение выходит за границы BYTE")
	| Ast.ErrValueOutOfRangeOfChar:
		O("Значение выходит за границы CHAR")
	| Ast.ErrExpectIntExpr:
		O("Expected целочисленное выражение")
	| Ast.ErrExpectConstIntExpr:
		O("Expected константное целочисленное выражение")
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
		O("Expected 'MODULE'")
	| Parser.ErrExpectIdent:
		O("Expected name")
	| Parser.ErrExpectColon:
		O("Expected ':'")
	| Parser.ErrExpectSemicolon:
		O("Expected ';'")
	| Parser.ErrExpectEnd:
		O("Expected 'END'")
	| Parser.ErrExpectDot:
		O("Expected '.'")
	| Parser.ErrExpectModuleName:
		O("Expected имя модуля")
	| Parser.ErrExpectEqual:
		O("Expected '='")
	| Parser.ErrExpectBrace1Close:
		O("Expected ')'")
	| Parser.ErrExpectBrace2Close:
		O("Expected ']'")
	| Parser.ErrExpectBrace3Close:
		O("Expected '}'")
	| Parser.ErrExpectOf:
		O("Expected OF")
	| Parser.ErrExpectTo:
		O("Expected TO")
	| Parser.ErrExpectStructuredType:
		O("Expected structured type: array, record, pointer, procedure")
	| Parser.ErrExpectRecord:
		O("Expected record")
	| Parser.ErrExpectStatement:
		O("Expected statement")
	| Parser.ErrExpectThen:
		O("Expected THEN")
	| Parser.ErrExpectAssign:
		O("Expected :=")
	| Parser.ErrExpectVarRecordOrPointer:
		O("Expected variable, which type is record or pointer")
	| Parser.ErrExpectType:
		O("Expected type")
	| Parser.ErrExpectUntil:
		O("Expected UNTIL")
	| Parser.ErrExpectDo:
		O("Expected DO")
	| Parser.ErrExpectDesignator:
		O("Expected designator")
	| Parser.ErrExpectProcedure:
		O("Expected procedure")
	| Parser.ErrExpectConstName:
		O("Expected name of constant")
	| Parser.ErrExpectProcedureName:
		O("Expected procedure's name after end")
	| Parser.ErrExpectExpression:
		O("Expected expression")
	| Parser.ErrExcessSemicolon:
		O("Excess ';'")
	| Parser.ErrEndModuleNameNotMatch:
		O("Завершающее имя в конце модуля не совпадает с его именем")
	| Parser.ErrArrayDimensionsTooMany:
		O("Слишком большая n-мерность массива")
	| Parser.ErrEndProcedureNameNotMatch:
		O("Завершающее имя в теле процедуры не совпадает с её именем")
	| Parser.ErrFunctionWithoutBraces:
		O("Объявление процедуры с возвращаемым значением не содержит скобки")
	| Parser.ErrArrayLenLess1:
		O("Длина массива должна быть > 0")
	| Parser.ErrExpectIntOrStrOrQualident:
		O("Expected number or string")
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

END MessageRu.

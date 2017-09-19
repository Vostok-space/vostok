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
MODULE MessageEn;

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
		O("Logic negative ~ applicable only to boolean values")
	| Ast.ErrConstAddOverflow:
		O("Overflow in constants sum")
	| Ast.ErrConstSubOverflow:
		O("Overflow in constants difference")
	| Ast.ErrConstMultOverflow:
		O("Overflow in constants multiplication")
	| Ast.ErrComDivByZero:
		O("Division by zero")
	| Ast.ErrValueOutOfRangeOfByte:
		O("Value out of byte's range")
	| Ast.ErrValueOutOfRangeOfChar:
		O("Value out of char's range")
	| Ast.ErrExpectIntExpr:
		O("Expected integer expression")
	| Ast.ErrExpectConstIntExpr:
		O("Expected constant integer expression")
	| Ast.ErrForByZero:
		O("Iterator's step can not be 0")
	| Ast.ErrByShouldBePositive:
		O("For enumeration from low to high iterator's step must be > 0")
	| Ast.ErrByShouldBeNegative:
		O("For enumeration from low to high iterator's step must be < 0")
	| Ast.ErrForPossibleOverflow:
		O("Iterator in FOR can overflow")
	| Ast.ErrVarUninitialized:
		O("Using uninitialized variable")
	| Ast.ErrDeclarationNotProc:
		O("Expected name of procedure")
	| Ast.ErrProcNotCommandHaveReturn:
		O("As command can be procedure without return")
	| Ast.ErrProcNotCommandHaveParams:
		O("As command can be procedure without parameters")
	| Ast.ErrReturnTypeArrayOrRecord:
		O("Returned type can not be array or record")
	| Ast.ErrRecordForwardUndefined:
		O("Exist undeclared record, previously referenced in pointer")
	| Ast.ErrPointerToNotRecord:
		O("Pointer can reference only to record")
	END
END AstError;

PROCEDURE ParseError*(code: INTEGER);
BEGIN
	CASE code OF
	  Scanner.ErrUnexpectChar:
		O("Unexpected char in text")
	| Scanner.ErrNumberTooBig:
		O("Value of constant is too big")
	| Scanner.ErrRealScaleTooBig:
		O("Scale of real value is too big")
	| Scanner.ErrWordLenTooBig:
		O("Length of word too big")
	| Scanner.ErrExpectHOrX:
		O("In end of hexadecimal number expected 'H' for number or 'X' for char")
	| Scanner.ErrExpectDQuote:
		O("Expected "); O(Utf8.DQuote)
	| Scanner.ErrExpectDigitInScale:
		O("ErrExpectDigitInScale")
	| Scanner.ErrUnclosedComment:
		O("Unclosed comment")

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
		O("Name after end do not match with module's name")
	| Parser.ErrArrayDimensionsTooMany:
		O("Too many dimensions in array")
	| Parser.ErrEndProcedureNameNotMatch:
		O("Name after end do not match with procedure's name")
	| Parser.ErrFunctionWithoutBraces:
		O("Declaration of procedure with return must have ()")
	| Parser.ErrArrayLenLess1:
		O("Array's length must be > 0")
	| Parser.ErrExpectIntOrStrOrQualident:
		O("Expected number or string")
	END
END ParseError;

PROCEDURE Usage*;
BEGIN
S("Usage: ");
S("  1) o7c help");
S("  2) o7c to-c   Script OutDir {-m PTM|-i PTI|-infr Infr}");
S("  3) o7c to-bin Script Result {-m PTM|-i PTI|-infr Infr|-c PTHC|-cc CComp}");
S("  4) o7c run    Script {-m PTM|-i PTI|-c PTHC|-cc CComp} -- options");
S("Script = Call { ; Call } . Call = Module.Procedure[(Parameters)] .");
S("PTM - Path To directories with Modules for search");
S("PTI - Path To directories with Interface Modules without real implementation");
S("PTHC - Path To directories with .H & .C -implementations of interface modules");
S("Infr - path to infrastructure. '-infr p' is shortening to:");
S("  -i p/singularity/definition -c p/singularity/implementation -m p/library");
S("CComp - C Compiler for build generated .c-files")
END Usage;

PROCEDURE CliError*(err: INTEGER; cmd: ARRAY OF CHAR);
BEGIN
	CASE err OF
	  Cli.ErrWrongArgs:
		Usage
	| Cli.ErrTooLongSourceName:
		S("Too long name of source file"); Out.Ln
	| Cli.ErrTooLongOutName:
		S("Too long destination name"); Out.Ln
	| Cli.ErrOpenSource:
		S("Can not open source file")
	| Cli.ErrOpenH:
		S("Can not open destination .h file")
	| Cli.ErrOpenC:
		S("Can not open destination .c file")
	| Cli.ErrUnknownCommand:
		O("Unknown command: ");
		S(cmd);
		Usage
	| Cli.ErrNotEnoughArgs:
		O("Not enough count of arguments for command: ");
		S(cmd)
	| Cli.ErrTooLongModuleDirs:
		S("Too long overall length of paths to modules")
	| Cli.ErrTooManyModuleDirs:
		S("Too many paths to modules")
	| Cli.ErrTooLongCDirs:
		S("Too long overall length of paths to .c files")
	| Cli.ErrTooLongCc:
		S("Too long length of C compiler options")
	| Cli.ErrCCompiler:
		S("Error during C compiler call")
	| Cli.ErrTooLongRunArgs:
		S("Too long command line options")
	| Cli.ErrUnexpectArg:
		S("Unexpected option")
	| Cli.ErrUnknownInit:
		S("Unknown initialization method")
	| Cli.ErrCantCreateOutDir:
		S("Can not create output directory")
	| Cli.ErrCantRemoveOutDir:
		S("Can not remove output directory")
	END
END CliError;

PROCEDURE Text*(str: ARRAY OF CHAR);
BEGIN
	O(str)
END Text;

END MessageEn.

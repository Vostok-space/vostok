(*  English messages for syntax and semantic errors. Extracted from MessageEn.
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
MODULE MessageErrOberonEn;

IMPORT AST := Ast, Parser, Scanner, Out, Utf8;

PROCEDURE C(s: ARRAY OF CHAR);
BEGIN
	Out.String(s)
END C;

PROCEDURE S(s: ARRAY OF CHAR);
BEGIN
	Out.String(s);
	Out.Ln
END S;

PROCEDURE Ast*(code: INTEGER);
BEGIN
	CASE code OF
	  AST.ErrImportNameDuplicate:
		C("Module's name already declared in the import list - ")
	| AST.ErrImportSelf:
		C("Module imports itself - ")
	| AST.ErrImportLoop:
		C("Cyclic import of modules is prohibited - ")
	| AST.ErrDeclarationNameDuplicate:
		C("Redeclaration of name in the same scope - ")
	| AST.ErrDeclarationNameHide:
		C("Declaration's name shadows module's declaration - ")
	| AST.ErrPredefinedNameHide:
		C("Declaration's name shadows predefined identifier - ")
	| AST.ErrMultExprDifferentTypes:
		C("Subexpressions types are incompatible")
	| AST.ErrDivExprDifferentTypes:
		C("Subexpressions types in division are incompatible")
	| AST.ErrNotBoolInLogicExpr:
		C("In a logic expression must be subexpressions of boolean type")
	| AST.ErrNotIntInDivOrMod:
		C("In integer division available only integer subexpressions")
	| AST.ErrNotRealTypeForRealDiv:
		C("In a float point division available only float point subexpressions")
	| AST.ErrNotIntSetElem:
		C("Set can contain only integers")
	| AST.ErrSetElemOutOfRange:
		C("Item's value of set is out of range - [0 .. 31]")
	| AST.ErrSetElemOutOfLongRange:
		C("Item's value of set is out of range - [0 .. 63]")
	| AST.ErrSetLeftElemBiggerRightElem:
		C("Left item of range is bigger than right item")
	| AST.ErrSetElemMaxNotConvertToInt:
		C("Set, which contain >=31 can not be converted to integer")
	| AST.ErrSetFromLongSet:
		C("Can not store the value of long set in the usual set")
	| AST.ErrAddExprDifferenTypes:
		C("Subexpressions types in sum are incompatible")
	| AST.ErrNotNumberAndNotSetInMult:
		S("In expressions *, / available only numbers and sets.");
		C("DIV, MOD applicable only for integers")
	| AST.ErrNotNumberAndNotSetInAdd:
		C("In expresions +, - available only numbers and sets")
	| AST.ErrSignForBool:
		C("Unary sign not applicable to logic type")
	| AST.ErrRelationExprDifferenTypes:
		C("Subexpressions types in comparison are not compatible")
	| AST.ErrExprInWrongTypes:
		C("Left subexpression must be integer, right - Set")
	| AST.ErrExprInRightNotSet:
		C("Right subexpression after IN must be Set")
	| AST.ErrExprInLeftNotInteger:
		C("Left subexpression before IN must be integer")
	| AST.ErrRelIncompatibleType:
		C("Relation not applicable to such type")
	| AST.ErrIsExtTypeNotRecord:
		C("IS applicable only to records and pointers")
	| AST.ErrIsExtVarNotRecord:
		C("Left part of IS be record or pointer to record")
	| AST.ErrIsExtMeshupPtrAndRecord:
		C("Type of left part of IS expression must be same kind that right type")
	| AST.ErrIsExtExpectRecordExt:
		C("In right part of IS expected extended record")
	| AST.ErrIsEqualProc:
		C("Direct subroutines comparison is disallowed")
	| AST.ErrConstDeclExprNotConst:
		C("Constant declaration matched to not constant expression")
	| AST.ErrAssignIncompatibleType:
		C("Incompatible types in assignment")
	| AST.ErrAssignExpectVarParam:
		C("Expected assignable designator")
	| AST.ErrAssignStringToNotEnoughArray:
		C("Assign string to array with not enough size")
	| AST.ErrCallNotProc:
		C("Call applicable only to subroutines and subroutine's variables")
	| AST.ErrCallIgnoredReturn:
		C("Returned value can not be ignored")
	| AST.ErrCallExprWithoutReturn:
		C("Called subroutine not return value")
	| AST.ErrCallExcessParam:
		C("Excess parameter in subroutine's call")
	| AST.ErrCallIncompatibleParamType:
		C("Incompatible parameter's type")
	| AST.ErrCallExpectVarParam:
		C("The parameter must be variable")
	| AST.ErrCallExpectAddressableParam:
		C("The parameter must be addressable")
	| AST.ErrCallVarPointerTypeNotSame:
		C("For variable parameter - pointer must used argument of same type")
	| AST.ErrCallParamsNotEnough:
		C("Not enough parameters in subroutine's call")
	| AST.ErrCaseExprWrongType:
		C("Expression in CASE must be integer, char, record or pointer")
	| AST.ErrCaseLabelWrongType:
		C("Label of CASE must have integer or char type, or be type record or pointer")
	| AST.ErrCaseRecordNotLocalVar:
		C("Expression in CASE of record or pointer type is not a local variable")
	| AST.ErrCasePointerVarParam:
		C("Expression in CASE should not be a VAR-parameter of pointer")
	| AST.ErrCaseRecordNotParam:
		C("Variable of record type in CASE should ber formal parameter")
	| AST.ErrCaseLabelNotRecExt:
		C("Type guard shoud be extension of type of expression in CASE")
	| AST.ErrCaseElemExprTypeMismatch:
		C("Label of CASE must be integer or char")
	| AST.ErrCaseElemDuplicate:
		C("Values of labels of CASE are duplicated")
	| AST.ErrCaseRangeLabelsTypeMismatch:
		C("Types of labels in CASE are not equal")
	| AST.ErrCaseLabelLeftNotLessRight:
		C("Left part of range in label of CASE must be less than right part")
	| AST.ErrCaseLabelNotConst:
		C("Labels in CASE must be constant")
	| AST.ErrCaseElseAlreadyExist:
		C("Else branch in CASE already exist")
	| AST.ErrProcHasNoReturn:
		C("Subroutine have not return")
	| AST.ErrReturnIncompatibleType:
		C("Type of expression in return is not compatible with declared type in header")
	| AST.ErrExpectReturn:
		C("Expected return")
	| AST.ErrDeclarationNotFound:
		C("Declaration not found - ")
	| AST.ErrConstRecursive:
		C("Recursive declaration of constant denied")
	| AST.ErrImportModuleNotFound:
		C("Imported module not found - ")
	| AST.ErrImportModuleWithError:
		C("Imported module contain mistakes - ")
	| AST.ErrDerefToNotPointer:
		C("Dereference applicable only to pointers")
	| AST.ErrArrayLenLess1:
		C("Array's length must be > 0")
	| AST.ErrArrayLenTooBig:
		C("Overall length of array too large")
	| AST.ErrArrayItemToNotArray:
		C("[ index ] applicable only to array")
	| AST.ErrArrayIndexNotInt:
		C("Array index is not integer")
	| AST.ErrArrayIndexNegative:
		C("Negative array index")
	| AST.ErrArrayIndexOutOfRange:
		C("Array index out of range")
	| AST.ErrStringIndexing:
		C("A string literal indexing is disallowed")
	| AST.ErrGuardExpectRecordExt:
		C("In type's guard expected extended record")
	| AST.ErrGuardExpectPointerExt:
		C("In type's guard expected pointer to extended record")
	| AST.ErrGuardedTypeNotExtensible:
		C("In a type's guard must be designator of record or pointer to record")
	| AST.ErrDotSelectorToNotRecord:
		C("Selector '.' applicable only to record and pointer to record")
	| AST.ErrDeclarationNotVar:
		C("Expected variable instead of ")
	| AST.ErrForIteratorNotInteger:
		C("Iterator of 'FOR'-loop should be and identifier of INTEGER variable")
	| AST.ErrNotBoolInIfCondition:
		C("Expression in IF must be of boolean type")
	| AST.ErrNotBoolInWhileCondition:
		C("Expression in WHILE must be of boolean type")
	| AST.ErrWhileConditionAlwaysFalse:
		C("Expression in WHILE always false")
	| AST.ErrWhileConditionAlwaysTrue:
		C("WHILE loop is indefinite becase guard expression always true")
	| AST.ErrNotBoolInUntil:
		C("Expression in UNTIL must be of boolean type")
	| AST.ErrUntilAlwaysFalse:
		C("Loop is indefinite because of end condion always false")
	| AST.ErrUntilAlwaysTrue:
		C("End conditin always true")
	| AST.ErrDeclarationIsPrivate:
		C("Declaration is not exported - ")
	| AST.ErrNegateNotBool:
		C("Logic negative ~ applicable only to boolean values")
	| AST.ErrConstAddOverflow:
		C("Overflow in constants sum")
	| AST.ErrConstSubOverflow:
		C("Overflow in constants difference")
	| AST.ErrConstMultOverflow:
		C("Overflow in constants multiplication")
	| AST.ErrComDivByZero:
		C("Division by zero")
	| AST.ErrNegativeDivisor:
		C("Division by negative number is undefined")
	| AST.ErrValueOutOfRangeOfByte:
		C("Value out of byte's range")
	| AST.ErrValueOutOfRangeOfChar:
		C("Value out of char's range")
	| AST.ErrExpectIntExpr:
		C("Expected integer expression")
	| AST.ErrExpectConstIntExpr:
		C("Expected constant integer expression")
	| AST.ErrForByZero:
		C("Iterator's step can not be 0")
	| AST.ErrByShouldBePositive:
		C("For enumeration from low to high iterator's step must be > 0")
	| AST.ErrByShouldBeNegative:
		C("For enumeration from low to high iterator's step must be < 0")
	| AST.ErrForPossibleOverflow:
		C("Iterator in FOR can overflow")
	| AST.ErrVarUninitialized:
		C("Using uninitialized variable - ")
	| AST.ErrVarMayUninitialized:
		C("Using variable, which may be uninitialized - ")
	| AST.ErrDeclarationNotProc:
		C("Expected name of procedure")
	| AST.ErrProcNotCommandHaveReturn:
		C("As command can be subroutine without return")
	| AST.ErrProcNotCommandHaveParams:
		C("As command can be subroutine without parameters")
	| AST.ErrReturnTypeArrayOrRecord:
		C("Returned type can not be array or record")
	| AST.ErrRecordForwardUndefined:
		C("Exist undeclared record, previously referenced in pointer")
	| AST.ErrPointerToNotRecord:
		C("Pointer can reference only to record")
	| AST.ErrAssertConstFalse:
		C("Assertion always false")
	| AST.ErrVarOfRecordForward:
		C("Declared variable which type is incompletely declared record")
	| AST.ErrVarOfPointerToRecordForward:
		C("Declared variable which type is pointer to incompletely declared record")
	| AST.ErrArrayTypeOfRecordForward:
		C("Incompletely declared record is used as subtype of array")
	| AST.ErrArrayTypeOfPointerToRecordForward:
		C("Pointer to incompletely declared record is used as subtype of array")
	| AST.ErrDeclarationUnused:
		C("Exist unused declaration in the scope - ");
	| AST.ErrProcNestedTooDeep:
		C("Too deep nesting of subroutines")
	| AST.ErrExpectProcNameWithoutParams:
		C("Expect command name - subroutine without parameters")
	| AST.ErrParamOutInFunc:
		C("Function can not have an output parameter")
	END
END Ast;

PROCEDURE Syntax*(code: INTEGER);
BEGIN
	CASE code OF
	  Scanner.ErrUnexpectChar:
		C("Unexpected char in text")
	| Scanner.ErrNumberTooBig:
		C("Value of constant is too large")
	| Scanner.ErrRealScaleTooBig:
		C("Scale of real value is too large")
	| Scanner.ErrWordLenTooBig:
		C("Length of word too large")
	| Scanner.ErrExpectHOrX:
		C("In end of hexadecimal number expected 'H' for number or 'X' for char")
	| Scanner.ErrExpectDQuote:
		C("Expected "); C(Utf8.DQuote)
	| Scanner.ErrExpectDigitInScale:
		C("ErrExpectDigitInScale")
	| Scanner.ErrUnclosedComment:
		C("Unclosed comment")

	| Parser.ErrExpectModule:
		C("Expected 'MODULE'")
	| Parser.ErrExpectIdent:
		C("Expected name")
	| Parser.ErrExpectColon:
		C("Expected ':'")
	| Parser.ErrExpectSemicolon:
		C("Expected ';'")
	| Parser.ErrExpectEnd:
		C("Expected 'END'")
	| Parser.ErrExpectDot:
		C("Expected '.'")
	| Parser.ErrExpectModuleName:
		C("Expected имя модуля")
	| Parser.ErrExpectEqual:
		C("Expected '='")
	| Parser.ErrExpectBrace1Open:
		C("Expected '('")
	| Parser.ErrExpectBrace1Close:
		C("Expected ')'")
	| Parser.ErrExpectBrace2Open:
		C("Expected '['")
	| Parser.ErrExpectBrace2Close:
		C("Expected ']'")
	| Parser.ErrExpectBrace3Open:
		C("Expected '{'")
	| Parser.ErrExpectBrace3Close:
		C("Expected '}'")
	| Parser.ErrExpectOf:
		C("Expected OF")
	| Parser.ErrExpectTo:
		C("Expected TO")
	| Parser.ErrExpectStructuredType:
		C("Expected structured type: array, record, pointer, procedure")
	| Parser.ErrExpectRecord:
		C("Expected record")
	| Parser.ErrExpectStatement:
		C("Expected statement")
	| Parser.ErrExpectThen:
		C("Expected THEN")
	| Parser.ErrExpectAssign:
		C("Expected :=")
	| Parser.ErrExpectVarRecordOrPointer:
		C("Expected variable, which type is record or pointer")
	| Parser.ErrExpectType:
		C("Expected type")
	| Parser.ErrExpectUntil:
		C("Expected UNTIL")
	| Parser.ErrExpectDo:
		C("Expected DO")
	| Parser.ErrExpectDesignator:
		C("Expected designator")
	| Parser.ErrExpectProcedure:
		C("Expected procedure")
	| Parser.ErrExpectConstName:
		C("Expected name of constant")
	| Parser.ErrExpectProcedureName:
		C("Expected procedure's name after end")
	| Parser.ErrExpectExpression:
		C("Expected expression")
	| Parser.ErrExcessSemicolon:
		C("Excess ';'")
	| Parser.ErrEndModuleNameNotMatch:
		C("Name after end do not match with module's name")
	| Parser.ErrArrayDimensionsTooMany:
		C("Too many dimensions in array")
	| Parser.ErrEndProcedureNameNotMatch:
		C("Name after end do not match with procedure's name")
	| Parser.ErrFunctionWithoutBraces:
		C("Declaration of procedure with return must have ()")
	| Parser.ErrExpectIntOrStrOrQualident:
		C("Expected number or string")
	| Parser.ErrMaybeAssignInsteadEqual:
		C("Unexpected '='. Maybe, you mean ':=' for assignment")
	| Parser.ErrUnexpectStringInCaseLabel:
		C("As label in CASE not accepted not 1 char strings")
	| Parser.ErrExpectAnotherModuleName:
		C("Expect module with another name")
	| Parser.ErrUnexpectedContentInScript:
		C("Unexpected content at the start of the code")
	END
END Syntax;

PROCEDURE Text*(str: ARRAY OF CHAR);
BEGIN
	C(str)
END Text;

END MessageErrOberonEn.

(*  English messages for interface
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
MODULE MessageEn;

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
		C("Module's name already declared in the import list")
	| Ast.ErrImportSelf:
		C("Module imports itself")
	| Ast.ErrImportLoop:
		C("Cyclic import of modules is prohibited")
	| Ast.ErrDeclarationNameDuplicate:
		C("Redeclaration of name in the same scope")
	| Ast.ErrDeclarationNameHide:
		C("Declaration's name shadows module's declaration")
	| Ast.ErrPredefinedNameHide:
		C("Declaration's name shadows predefined identifier")
	| Ast.ErrMultExprDifferentTypes:
		C("Subexpressions types are incompatible")
	| Ast.ErrDivExprDifferentTypes:
		C("Subexpressions types in division are incompatible")
	| Ast.ErrNotBoolInLogicExpr:
		C("In a logic expression must be subexpressions of boolean type")
	| Ast.ErrNotIntInDivOrMod:
		C("In integer division available only integer subexpressions")
	| Ast.ErrNotRealTypeForRealDiv:
		C("In a float point division available only float point subexpressions")
	| Ast.ErrNotIntSetElem:
		C("Set can contain only integers")
	| Ast.ErrSetElemOutOfRange:
		C("Item's value of set is out of range - [0 .. 31]")
	| Ast.ErrSetLeftElemBiggerRightElem:
		C("Left item of range is bigger then right item")
	| Ast.ErrSetElemMaxNotConvertToInt:
		C("Set, which contain 31 can not be converted to integer")
	| Ast.ErrAddExprDifferenTypes:
		C("Subexpressions types in sum are incompatible")
	| Ast.ErrNotNumberAndNotSetInMult:
		S("In expressions *, / available only numbers and sets.");
		C("DIV, MOD applicable only for integers")
	| Ast.ErrNotNumberAndNotSetInAdd:
		C("In expresions +, - available only numbers and sets")
	| Ast.ErrSignForBool:
		C("Unary sign not applicable to logic type")
	| Ast.ErrRelationExprDifferenTypes:
		C("Subexpressions types in comparison are not compatible")
	| Ast.ErrExprInWrongTypes:
		C("Left subexpression must be integer, right - Set")
	| Ast.ErrExprInRightNotSet:
		C("Right subexpression after IN must be Set")
	| Ast.ErrExprInLeftNotInteger:
		C("Left subexpression before IN must be integer")
	| Ast.ErrRelIncompatibleType:
		C("Relation not applicable to such type")
	| Ast.ErrIsExtTypeNotRecord:
		C("IS applicable only to records and pointers")
	| Ast.ErrIsExtVarNotRecord:
		C("Left part of IS be record or pointer to record")
	| Ast.ErrIsExtMeshupPtrAndRecord:
		C("Type of left part of IS expression must be same kind that right type")
	| Ast.ErrIsExtExpectRecordExt:
		C("In right part of IS expected extended record")
	| Ast.ErrConstDeclExprNotConst:
		C("Constant declaration matched to not constant expression")
	| Ast.ErrAssignIncompatibleType:
		C("Incompatible types in assignment")
	| Ast.ErrAssignExpectVarParam:
		C("Expected assignable designator")
	| Ast.ErrAssignStringToNotEnoughArray:
		C("Assign string to array with not enough size")
	| Ast.ErrCallNotProc:
		C("Call applicable only to subroutines and subroutine's variables")
	| Ast.ErrCallIgnoredReturn:
		C("Returned value can not be ignored")
	| Ast.ErrCallExprWithoutReturn:
		C("Called subroutine not return value")
	| Ast.ErrCallExcessParam:
		C("Excess parameter in subroutine's call")
	| Ast.ErrCallIncompatibleParamType:
		C("Incompatible parameter's type")
	| Ast.ErrCallExpectVarParam:
		C("Parameter must be variable")
	| Ast.ErrCallVarPointerTypeNotSame:
		C("For variable parameter - pointer must used argument of same type")
	| Ast.ErrCallParamsNotEnough:
		C("Not enough parameters in subroutine's call")
	| Ast.ErrCaseExprNotIntOrChar:
		C("Expression in CASE must be integer or char")
	| Ast.ErrCaseLabelNotIntOrChar:
		C("Case label must have integer or char type")
	| Ast.ErrCaseElemExprTypeMismatch:
		C("Label of CASE must be integer or char")
	| Ast.ErrCaseElemDuplicate:
		C("Values of labels of CASE are duplicated")
	| Ast.ErrCaseRangeLabelsTypeMismatch:
		C("Types of labels in CASE are not equal")
	| Ast.ErrCaseLabelLeftNotLessRight:
		C("Left part of range in label of CASE must be less than right part")
	| Ast.ErrCaseLabelNotConst:
		C("Labels in CASE must be constant")
	| Ast.ErrCaseElseAlreadyExist:
		C("Else branch in CASE already exist")
	| Ast.ErrProcHasNoReturn:
		C("Subroutine have not return")
	| Ast.ErrReturnIncompatibleType:
		C("Type of expression in return is not compatible with declared type in header")
	| Ast.ErrExpectReturn:
		C("Expected return")
	| Ast.ErrDeclarationNotFound:
		C("Declaration not found")
	| Ast.ErrConstRecursive:
		C("Recursive declaration of constant denied")
	| Ast.ErrImportModuleNotFound:
		C("Imported module not found")
	| Ast.ErrImportModuleWithError:
		C("Imported module contain mistakes")
	| Ast.ErrDerefToNotPointer:
		C("Dereference applicable only to pointers")
	| Ast.ErrArrayLenLess1:
		C("Array's length must be > 0")
	| Ast.ErrArrayLenTooBig:
		C("Overall length of array too big")
	| Ast.ErrArrayItemToNotArray:
		C("[ index ] applicable only to array")
	| Ast.ErrArrayIndexNotInt:
		C("Array index is not integer")
	| Ast.ErrArrayIndexNegative:
		C("Negative array index")
	| Ast.ErrArrayIndexOutOfRange:
		C("Array index out of range")
	| Ast.ErrGuardExpectRecordExt:
		C("In type's guard expected extended record")
	| Ast.ErrGuardExpectPointerExt:
		C("In type's guard expected pointer to extended record")
	| Ast.ErrGuardedTypeNotExtensible:
		C("In a type's guard must be designator of record or pointer to record")
	| Ast.ErrDotSelectorToNotRecord:
		C("Selector '.' applicable only to record and pointer to record")
	| Ast.ErrDeclarationNotVar:
		C("Expected variable")
	| Ast.ErrForIteratorNotInteger:
		C("Iterator of 'FOR'-loop not integer")
	| Ast.ErrNotBoolInIfCondition:
		C("Expression in IF must be of boolean type")
	| Ast.ErrNotBoolInWhileCondition:
		C("Expression in WHILE must be of boolean type")
	| Ast.ErrWhileConditionAlwaysFalse:
		C("Expression in WHILE always false")
	| Ast.ErrWhileConditionAlwaysTrue:
		C("WHILE loop is indefinite becase guard expression always true")
	| Ast.ErrNotBoolInUntil:
		C("Expression in UNTIL must be of boolean type")
	| Ast.ErrUntilAlwaysFalse:
		C("Loop is indefinite because of end condion always false")
	| Ast.ErrUntilAlwaysTrue:
		C("End conditin always true")
	| Ast.ErrDeclarationIsPrivate:
		C("Declaration is not exported")
	| Ast.ErrNegateNotBool:
		C("Logic negative ~ applicable only to boolean values")
	| Ast.ErrConstAddOverflow:
		C("Overflow in constants sum")
	| Ast.ErrConstSubOverflow:
		C("Overflow in constants difference")
	| Ast.ErrConstMultOverflow:
		C("Overflow in constants multiplication")
	| Ast.ErrComDivByZero:
		C("Division by zero")
	| Ast.ErrNegativeDivisor:
		C("Division by negative number is undefined")
	| Ast.ErrValueOutOfRangeOfByte:
		C("Value out of byte's range")
	| Ast.ErrValueOutOfRangeOfChar:
		C("Value out of char's range")
	| Ast.ErrExpectIntExpr:
		C("Expected integer expression")
	| Ast.ErrExpectConstIntExpr:
		C("Expected constant integer expression")
	| Ast.ErrForByZero:
		C("Iterator's step can not be 0")
	| Ast.ErrByShouldBePositive:
		C("For enumeration from low to high iterator's step must be > 0")
	| Ast.ErrByShouldBeNegative:
		C("For enumeration from low to high iterator's step must be < 0")
	| Ast.ErrForPossibleOverflow:
		C("Iterator in FOR can overflow")
	| Ast.ErrVarUninitialized:
		C("Using uninitialized variable")
	| Ast.ErrVarMayUninitialized:
		C("Using variable, which may be uninitialized")
	| Ast.ErrDeclarationNotProc:
		C("Expected name of procedure")
	| Ast.ErrProcNotCommandHaveReturn:
		C("As command can be subroutine without return")
	| Ast.ErrProcNotCommandHaveParams:
		C("As command can be subroutine without parameters")
	| Ast.ErrReturnTypeArrayOrRecord:
		C("Returned type can not be array or record")
	| Ast.ErrRecordForwardUndefined:
		C("Exist undeclared record, previously referenced in pointer")
	| Ast.ErrPointerToNotRecord:
		C("Pointer can reference only to record")
	| Ast.ErrAssertConstFalse:
		C("Assertion always false")
	| Ast.ErrVarOfRecordForward:
		C("Declared variable which type is incompletely declared record")
	| Ast.ErrVarOfPointerToRecordForward:
		C("Declared variable which type is pointer to incompletely declared record")
	| Ast.ErrArrayTypeOfRecordForward:
		C("Incompletely declared record is used as subtype of array")
	| Ast.ErrArrayTypeOfPointerToRecordForward:
		C("Pointer to incompletely declared record is used as subtype of array")
	| Ast.ErrDeclarationUnused:
		C("Exist unused declaration in the scope")
	| Ast.ErrProcNestedTooDeep:
		C("Too deep nesting of subroutines")
	END
END AstError;

PROCEDURE ParseError*(code: INTEGER);
BEGIN
	CASE code OF
	  Scanner.ErrUnexpectChar:
		C("Unexpected char in text")
	| Scanner.ErrNumberTooBig:
		C("Value of constant is too big")
	| Scanner.ErrRealScaleTooBig:
		C("Scale of real value is too big")
	| Scanner.ErrWordLenTooBig:
		C("Length of word too big")
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
END ParseError;

PROCEDURE Usage*(full: BOOLEAN);
BEGIN
S("Translator from Oberon-07 to C, Java and Javascript. 2019");
S("Usage: ");
S(" 1) o7c help");
S(" 2) o7c to-c     Code OutDir { -m PM | -i PI | -infr Infr }");
S(" 3) o7c to-bin   Code OutBin {-m PM|-i PI|-infr I|-c PHC|-cc CComp|-t Temp}");
S(" 4) o7c run      Code {-m PM|-i PI|-c PHC|-cc CComp|-t Temp} [-- Args]");
S(" 5) o7c to-java  Code OutDir {-m PM | -i PI | -infr Infr}");
S(" 6) o7c to-class Code OutDir {-m PM|-i PI|-infr I|-jv PJv|-javac JComp|-t Temp}");
S(" 7) o7c run-java Code {-m PM|-i PI|-jv PJv|-t Temp} [-- Args]");
S(" 8) o7c to-js    Code Out {-m PM | -i PI | -infr Infr}");
S(" 9) o7c run-js   Code {-m PM|-i PI|-js PJs|-t Temp} [-- Args]");
IF full THEN
S("");
S("2) to-c     converts modules to .h & .c files");
S("3) to-bin   converts modules to executable through implicit .c files");
S("4) run      executes implicit executable file");
S("5) to-java  converts modules to .java files");
S("6) to-class converts modules to .class through implicit .java files");
S("7) run-java executes implicit class, created from Code");
S("8) to-js    converts modules to .js files");
S("9) run-js   executes implicit .js file, created by Code");
S("");
S("Code is simple Oberon-source. Can be described in kind of EBNF:");
S("  Code = Call { ; Call } . Call = Module [ .Procedure [ '('Parameters')' ] ] .");
S("OutDir - directory for saving translated .h & .c files");
S("OutBin - name of output executable file");
S("");
S("-m PM - Path to directory with Modules for search.");
S("  For example: -m library -m source -m test/source");
S("-i PI - Path to directory with Interface modules without real implementation");
S("  For example: -i singularity/definition");
S("-c PHC - Path to directory with .h & .c -implementations of interface modules");
S("  For example: -c singularity/implementation");
S("-infr Infr - path to Infr_astructure. '-infr p' is shortening to:");
S("  -i p/singularity/definition -c p/singularity/implementation -m p/library");
S("-t Temp - new directory, where translator store intermediate .h & .c files");
S("  For example: -t result/test/ReadDir.src");
S("-cc CComp - C Compiler for build .c-files, by default used 'cc -g -O1'");
S("  For example: -cc 'clang -O3 -flto -s'");
S("-- Args - command line arguments for runned code");
S("");
S("Generator's arguments:");
S("-init ( noinit | undef | zero )  - kind of variables auto-initializing.");
S("  noinit -  without initialization.");
S("  undef* -  special values for error's diagnostic.");
S("  zero   -  fill by zeroes.");
S("-memng ( nofree | counter | gc ) - kind of dynamic memory management.");
S("  nofree*  -  without release.");
S("  counter  -  automatic reference counting without automatic loops destroying.");
S("  gc       -  garbage collection by Boehm-Demers-Weiser library.");
S("-no-array-index-check         - turn off runtime check that index within range.");
S("-no-nil-check                 - turn off runtime check pointer on nil.");
S("-no-arithmetic-overflow-check - turn off runtime check arithmetic overflow.");
S("");
S("-C90 | -C99 | -C11            - ISO standard of generated C-code");
S("");
S("-cyrillic[-same|-escape|-translit] - allow russian identifiers in a source.");
S("   by default used suitable method of name generation, specific for compiler.");
S("  -same     translate to identical C names.");
S("  -escape   translate with escaped unicode chars - \uXXXX.");
S("  -translit use transliteration in output names in C.")
END
END Usage;

PROCEDURE CliError*(err: INTEGER);
BEGIN
	CASE err OF
	  Cli.ErrWrongArgs:
		Usage(FALSE)
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
		S("Unknown command");
		Usage(FALSE)
	| Cli.ErrNotEnoughArgs:
		S("Not enough count of arguments for command")
	| Cli.ErrTooLongModuleDirs:
		S("Too long overall length of paths to modules")
	| Cli.ErrTooManyModuleDirs:
		S("Too many paths to modules")
	| Cli.ErrTooLongCDirs:
		S("Too long overall length of paths to .c files")
	| Cli.ErrTooLongCc:
		S("Too long length of C compiler options")
	| Cli.ErrTooLongTemp:
		S("Too long name of temporary directory")
	| Cli.ErrCCompiler:
		S("Error during C compiler call")
	| Cli.ErrTooLongRunArgs:
		S("Too long command line options")
	| Cli.ErrUnexpectArg:
		S("Unexpected option")
	| Cli.ErrUnknownInit:
		S("Unknown initialization method")
	| Cli.ErrUnknownMemMan:
		S("Unknown kind of memory management")
	| Cli.ErrCantCreateOutDir:
		S("Can not create output directory")
	| Cli.ErrCantRemoveOutDir:
		S("Can not remove output directory")
	| Cli.ErrCantFoundCCompiler:
		S("Can not found C Compiler")

	| Cli.ErrOpenJava:
		S("Can not open output java file")
	| Cli.ErrJavaCompiler:
		S("Error during Java compiler calling")
	| Cli.ErrCantFoundJavaCompiler:
		S("Can not found Java compiler")
	| Cli.ErrTooLongJavaDirs:
		S("Too long overall length of paths to .java files")

	| Cli.ErrOpenJs:
		S("Can not open output .js file")
	| Cli.ErrTooLongJsDirs:
		S("Too long overall length of paths to .js files")
	END
END CliError;

PROCEDURE Text*(str: ARRAY OF CHAR);
BEGIN
	C(str)
END Text;

END MessageEn.

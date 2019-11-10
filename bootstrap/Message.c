#include <o7.h>

#include "Message.h"

static void C(o7_int_t s_len0, o7_char s[/*len0*/]) {
	Out_String(s_len0, s);
}

static void S(o7_int_t s_len0, o7_char s[/*len0*/]) {
	Out_String(s_len0, s);
	Out_Ln();
}

static void Str(struct StringStore_String *s) {
	o7_int_t i;
	o7_char buf[256];
	memset(&buf, 0, sizeof(buf));

	i = 0;
	if (StringStore_CopyToChars(256, buf, &i, &(*s))) {
		Out_String(256, buf);
	} else {
		Out_String(4, (o7_char *)"...");
	}
}

extern void Message_AstError(o7_int_t code, struct StringStore_String *str) {
	switch (code) {
	case -1:
		C(50, (o7_char *)"Module's name already declared in the import list");
		break;
	case -2:
		C(22, (o7_char *)"Module imports itself");
		break;
	case -3:
		C(39, (o7_char *)"Cyclic import of modules is prohibited");
		break;
	case -4:
		C(40, (o7_char *)"Redeclaration of name in the same scope");
		break;
	case -5:
		C(48, (o7_char *)"Declaration's name shadows module's declaration");
		break;
	case -6:
		C(49, (o7_char *)"Declaration's name shadows predefined identifier");
		break;
	case -7:
		C(38, (o7_char *)"Subexpressions types are incompatible");
		break;
	case -8:
		C(50, (o7_char *)"Subexpressions types in division are incompatible");
		break;
	case -9:
		C(61, (o7_char *)"In a logic expression must be subexpressions of boolean type");
		break;
	case -10:
		C(58, (o7_char *)"In integer division available only integer subexpressions");
		break;
	case -11:
		C(68, (o7_char *)"In a float point division available only float point subexpressions");
		break;
	case -12:
		C(30, (o7_char *)"Set can contain only integers");
		break;
	case -13:
		C(48, (o7_char *)"Item's value of set is out of range - [0 .. 31]");
		break;
	case -14:
		C(45, (o7_char *)"Left item of range is bigger then right item");
		break;
	case -15:
		C(54, (o7_char *)"Set, which contain 31 can not be converted to integer");
		break;
	case -16:
		C(45, (o7_char *)"Subexpressions types in sum are incompatible");
		break;
	case -17:
		S(53, (o7_char *)"In expressions *, / available only numbers and sets.");
		C(38, (o7_char *)"DIV, MOD applicable only for integers");
		break;
	case -18:
		C(51, (o7_char *)"In expresions +, - available only numbers and sets");
		break;
	case -19:
		C(40, (o7_char *)"Unary sign not applicable to logic type");
		break;
	case -20:
		C(54, (o7_char *)"Subexpressions types in comparison are not compatible");
		break;
	case -21:
		C(48, (o7_char *)"Left subexpression must be integer, right - Set");
		break;
	case -22:
		C(41, (o7_char *)"Right subexpression after IN must be Set");
		break;
	case -23:
		C(45, (o7_char *)"Left subexpression before IN must be integer");
		break;
	case -24:
		C(37, (o7_char *)"Relation not applicable to such type");
		break;
	case -25:
		C(43, (o7_char *)"IS applicable only to records and pointers");
		break;
	case -26:
		C(47, (o7_char *)"Left part of IS be record or pointer to record");
		break;
	case -27:
		C(69, (o7_char *)"Type of left part of IS expression must be same kind that right type");
		break;
	case -28:
		C(45, (o7_char *)"In right part of IS expected extended record");
		break;
	case -29:
		C(56, (o7_char *)"Constant declaration matched to not constant expression");
		break;
	case -30:
		C(33, (o7_char *)"Incompatible types in assignment");
		break;
	case -31:
		C(31, (o7_char *)"Expected assignable designator");
		break;
	case -111:
		C(44, (o7_char *)"Assign string to array with not enough size");
		break;
	case -32:
		C(63, (o7_char *)"Call applicable only to subroutines and subroutine's variables");
		break;
	case -34:
		C(34, (o7_char *)"Returned value can not be ignored");
		break;
	case -33:
		C(35, (o7_char *)"Called subroutine not return value");
		break;
	case -35:
		C(38, (o7_char *)"Excess parameter in subroutine's call");
		break;
	case -36:
		C(30, (o7_char *)"Incompatible parameter's type");
		break;
	case -37:
		C(27, (o7_char *)"Parameter must be variable");
		break;
	case -39:
		C(65, (o7_char *)"For variable parameter - pointer must used argument of same type");
		break;
	case -38:
		C(43, (o7_char *)"Not enough parameters in subroutine's call");
		break;
	case -40:
		C(43, (o7_char *)"Expression in CASE must be integer or char");
		break;
	case -41:
		C(42, (o7_char *)"Case label must have integer or char type");
		break;
	case -42:
		C(38, (o7_char *)"Label of CASE must be integer or char");
		break;
	case -43:
		C(40, (o7_char *)"Values of labels of CASE are duplicated");
		break;
	case -44:
		C(38, (o7_char *)"Types of labels in CASE are not equal");
		break;
	case -45:
		C(65, (o7_char *)"Left part of range in label of CASE must be less than right part");
		break;
	case -46:
		C(32, (o7_char *)"Labels in CASE must be constant");
		break;
	case -47:
		C(34, (o7_char *)"Else branch in CASE already exist");
		break;
	case -48:
		C(27, (o7_char *)"Subroutine have not return");
		break;
	case -49:
		C(76, (o7_char *)"Type of expression in return is not compatible with declared type in header");
		break;
	case -50:
		C(16, (o7_char *)"Expected return");
		break;
	case -51:
		C(22, (o7_char *)"Declaration not found");
		break;
	case -53:
		C(41, (o7_char *)"Recursive declaration of constant denied");
		break;
	case -54:
		C(26, (o7_char *)"Imported module not found");
		break;
	case -55:
		C(33, (o7_char *)"Imported module contain mistakes");
		break;
	case -56:
		C(40, (o7_char *)"Dereference applicable only to pointers");
		break;
	case -57:
		C(27, (o7_char *)"Array's length must be > 0");
		break;
	case -58:
		C(32, (o7_char *)"Overall length of array too big");
		break;
	case -59:
		C(35, (o7_char *)"[ index ] applicable only to array");
		break;
	case -60:
		C(27, (o7_char *)"Array index is not integer");
		break;
	case -61:
		C(21, (o7_char *)"Negative array index");
		break;
	case -62:
		C(25, (o7_char *)"Array index out of range");
		break;
	case -63:
		C(41, (o7_char *)"In type's guard expected extended record");
		break;
	case -64:
		C(52, (o7_char *)"In type's guard expected pointer to extended record");
		break;
	case -65:
		C(68, (o7_char *)"In a type's guard must be designator of record or pointer to record");
		break;
	case -66:
		C(61, (o7_char *)"Selector '.' applicable only to record and pointer to record");
		break;
	case -67:
		C(18, (o7_char *)"Expected variable");
		break;
	case -68:
		C(68, (o7_char *)"Iterator of 'FOR'-loop should be and identifier of INTEGER variable");
		break;
	case -69:
		C(41, (o7_char *)"Expression in IF must be of boolean type");
		break;
	case -70:
		C(44, (o7_char *)"Expression in WHILE must be of boolean type");
		break;
	case -71:
		C(33, (o7_char *)"Expression in WHILE always false");
		break;
	case -72:
		C(61, (o7_char *)"WHILE loop is indefinite becase guard expression always true");
		break;
	case -73:
		C(44, (o7_char *)"Expression in UNTIL must be of boolean type");
		break;
	case -74:
		C(55, (o7_char *)"Loop is indefinite because of end condion always false");
		break;
	case -75:
		C(25, (o7_char *)"End conditin always true");
		break;
	case -52:
		C(28, (o7_char *)"Declaration is not exported");
		break;
	case -76:
		C(51, (o7_char *)"Logic negative ~ applicable only to boolean values");
		break;
	case -77:
		C(26, (o7_char *)"Overflow in constants sum");
		break;
	case -78:
		C(33, (o7_char *)"Overflow in constants difference");
		break;
	case -79:
		C(37, (o7_char *)"Overflow in constants multiplication");
		break;
	case -80:
		C(17, (o7_char *)"Division by zero");
		break;
	case -81:
		C(41, (o7_char *)"Division by negative number is undefined");
		break;
	case -82:
		C(26, (o7_char *)"Value out of byte's range");
		break;
	case -83:
		C(26, (o7_char *)"Value out of char's range");
		break;
	case -84:
		C(28, (o7_char *)"Expected integer expression");
		break;
	case -85:
		C(37, (o7_char *)"Expected constant integer expression");
		break;
	case -86:
		C(29, (o7_char *)"Iterator's step can not be 0");
		break;
	case -87:
		C(61, (o7_char *)"For enumeration from low to high iterator's step must be > 0");
		break;
	case -88:
		C(61, (o7_char *)"For enumeration from low to high iterator's step must be < 0");
		break;
	case -89:
		C(29, (o7_char *)"Iterator in FOR can overflow");
		break;
	case -90:
		C(29, (o7_char *)"Using uninitialized variable");
		break;
	case -91:
		C(43, (o7_char *)"Using variable, which may be uninitialized");
		break;
	case -92:
		C(27, (o7_char *)"Expected name of procedure");
		break;
	case -93:
		C(44, (o7_char *)"As command can be subroutine without return");
		break;
	case -94:
		C(48, (o7_char *)"As command can be subroutine without parameters");
		break;
	case -95:
		C(41, (o7_char *)"Returned type can not be array or record");
		break;
	case -96:
		C(58, (o7_char *)"Exist undeclared record, previously referenced in pointer");
		break;
	case -97:
		C(37, (o7_char *)"Pointer can reference only to record");
		break;
	case -102:
		C(23, (o7_char *)"Assertion always false");
		break;
	case -98:
		C(61, (o7_char *)"Declared variable which type is incompletely declared record");
		break;
	case -99:
		C(72, (o7_char *)"Declared variable which type is pointer to incompletely declared record");
		break;
	case -100:
		C(57, (o7_char *)"Incompletely declared record is used as subtype of array");
		break;
	case -101:
		C(68, (o7_char *)"Pointer to incompletely declared record is used as subtype of array");
		break;
	case -103:
		C(41, (o7_char *)"Exist unused declaration in the scope - ");
		break;
	case -104:
		C(32, (o7_char *)"Too deep nesting of subroutines");
		break;
	case -105:
		C(52, (o7_char *)"Expect command name - subroutine without parameters");
		break;
	default:
		o7_case_fail(code);
		break;
	}
	if (StringStore_IsDefined(&(*str))) {
		Str(&(*str));
	}
}

extern void Message_ParseError(o7_int_t code) {
	switch (code) {
	case -1:
		C(24, (o7_char *)"Unexpected char in text");
		break;
	case -2:
		C(29, (o7_char *)"Value of constant is too big");
		break;
	case -3:
		C(31, (o7_char *)"Scale of real value is too big");
		break;
	case -4:
		C(23, (o7_char *)"Length of word too big");
		break;
	case -5:
		C(69, (o7_char *)"In end of hexadecimal number expected 'H' for number or 'X' for char");
		break;
	case -6:
		C(10, (o7_char *)"Expected ");
		C(2, (o7_char *)"\x22");
		break;
	case -7:
		C(22, (o7_char *)"ErrExpectDigitInScale");
		break;
	case -8:
		C(17, (o7_char *)"Unclosed comment");
		break;
	case -101:
		C(18, (o7_char *)"Expected 'MODULE'");
		break;
	case -102:
		C(14, (o7_char *)"Expected name");
		break;
	case -103:
		C(13, (o7_char *)"Expected ':'");
		break;
	case -104:
		C(13, (o7_char *)"Expected ';'");
		break;
	case -105:
		C(15, (o7_char *)"Expected 'END'");
		break;
	case -106:
		C(13, (o7_char *)"Expected '.'");
		break;
	case -107:
		C(29, (o7_char *)"Expected имя модуля");
		break;
	case -108:
		C(13, (o7_char *)"Expected '='");
		break;
	case -109:
		C(13, (o7_char *)"Expected '('");
		break;
	case -110:
		C(13, (o7_char *)"Expected ')'");
		break;
	case -111:
		C(13, (o7_char *)"Expected '['");
		break;
	case -112:
		C(13, (o7_char *)"Expected ']'");
		break;
	case -113:
		C(13, (o7_char *)"Expected '{'");
		break;
	case -114:
		C(13, (o7_char *)"Expected '}'");
		break;
	case -115:
		C(12, (o7_char *)"Expected OF");
		break;
	case -116:
		C(12, (o7_char *)"Expected TO");
		break;
	case -117:
		C(60, (o7_char *)"Expected structured type: array, record, pointer, procedure");
		break;
	case -118:
		C(16, (o7_char *)"Expected record");
		break;
	case -119:
		C(19, (o7_char *)"Expected statement");
		break;
	case -120:
		C(14, (o7_char *)"Expected THEN");
		break;
	case -121:
		C(12, (o7_char *)"Expected :=");
		break;
	case -122:
		C(51, (o7_char *)"Expected variable, which type is record or pointer");
		break;
	case -124:
		C(14, (o7_char *)"Expected type");
		break;
	case -125:
		C(15, (o7_char *)"Expected UNTIL");
		break;
	case -126:
		C(12, (o7_char *)"Expected DO");
		break;
	case -128:
		C(20, (o7_char *)"Expected designator");
		break;
	case -130:
		C(19, (o7_char *)"Expected procedure");
		break;
	case -131:
		C(26, (o7_char *)"Expected name of constant");
		break;
	case -132:
		C(36, (o7_char *)"Expected procedure's name after end");
		break;
	case -133:
		C(20, (o7_char *)"Expected expression");
		break;
	case -135:
		C(11, (o7_char *)"Excess ';'");
		break;
	case -150:
		C(47, (o7_char *)"Name after end do not match with module's name");
		break;
	case -152:
		C(29, (o7_char *)"Too many dimensions in array");
		break;
	case -153:
		C(50, (o7_char *)"Name after end do not match with procedure's name");
		break;
	case -154:
		C(50, (o7_char *)"Declaration of procedure with return must have ()");
		break;
	case -134:
		C(26, (o7_char *)"Expected number or string");
		break;
	case -136:
		C(52, (o7_char *)"Unexpected '='. Maybe, you mean ':=' for assignment");
		break;
	case -137:
		C(49, (o7_char *)"As label in CASE not accepted not 1 char strings");
		break;
	case -151:
		C(32, (o7_char *)"Expect module with another name");
		break;
	case -155:
		C(44, (o7_char *)"Unexpected content at the start of the code");
		break;
	default:
		o7_case_fail(code);
		break;
	}
}

extern void Message_Usage(o7_bool full) {
	S(58, (o7_char *)"Translator from Oberon-07 to C. 2019");
	S(41, (o7_char *)"Usage: ost command [parameter] {-option}");
	S(37, (o7_char *)" 0) ost help     # For detailed help");
	S(60, (o7_char *)" 1) ost to-c     Code OutDir { -m PM | -i PI | -infr Infr }");
	S(76, (o7_char *)" 2) ost to-bin   Code OutBin {-m PM|-i PI|-infr I|-c PHC|-cc CComp|-t Temp}");
	S(71, (o7_char *)" 3) ost run      Code {-m PM|-i PI|-c PHC|-cc CComp|-t Temp} [-- Args]");
	if (full) {
		S(1, (o7_char *)"");
		S(46, (o7_char *)"1) to-c     converts modules to .h & .c files");
		S(69, (o7_char *)"2) to-bin   converts modules to executable through implicit .c files");
		S(46, (o7_char *)"3) run      executes implicit executable file");
		S(1, (o7_char *)"");
		S(64, (o7_char *)"Code is simple Oberon-source. Can be described in kind of EBNF:");
		S(79, (o7_char *)"  Code = Call { ; Call } . Call = Module [ .Procedure [ '('Parameters')' ] ] .");
		S(55, (o7_char *)"OutDir - directory for saving translated .h & .c files");
		S(40, (o7_char *)"OutBin - name of output executable file");
		S(1, (o7_char *)"");
		S(51, (o7_char *)"-m PM - Path to directory with Modules for search.");
		S(51, (o7_char *)"  For example: -m library -m source -m test/source");
		S(77, (o7_char *)"-i PI - Path to directory with Interface modules without real implementation");
		S(41, (o7_char *)"  For example: -i singularity/definition");
		S(78, (o7_char *)"-c PHC - Path to directory with .h & .c -implementations of interface modules");
		S(45, (o7_char *)"  For example: -c singularity/implementation");
		S(66, (o7_char *)"-infr Infr - path to Infr_astructure. '-infr p' is shortening to:");
		S(75, (o7_char *)"  -i p/singularity/definition -c p/singularity/implementation -m p/library");
		S(75, (o7_char *)"-t Temp - new directory, where translator store intermediate .h & .c files");
		S(42, (o7_char *)"  For example: -t result/test/ReadDir.src");
		S(71, (o7_char *)"-cc CComp - C Compiler for build .c-files, by default used 'cc -g -O1'");
		S(40, (o7_char *)"  For example: -cc 'clang -O3 -flto -s'");
		S(49, (o7_char *)"-- Args - command line arguments for runned code");
		S(1, (o7_char *)"");
		S(23, (o7_char *)"Generator's arguments:");
		S(72, (o7_char *)"-init ( noinit | undef | zero )  - kind of variables auto-initializing.");
		S(36, (o7_char *)"  noinit -  without initialization.");
		S(51, (o7_char *)"  undef* -  special values for error's diagnostic.");
		S(28, (o7_char *)"  zero   -  fill by zeroes.");
		S(70, (o7_char *)"-memng ( nofree | counter | gc ) - kind of dynamic memory management.");
		S(31, (o7_char *)"  nofree*  -  without release.");
		S(79, (o7_char *)"  counter  -  automatic reference counting without automatic loops destroying.");
		S(65, (o7_char *)"  gc       -  garbage collection by Boehm-Demers-Weiser library.");
		S(80, (o7_char *)"-no-array-index-check         - turn off runtime check that index within range.");
		S(71, (o7_char *)"-no-nil-check                 - turn off runtime check pointer on nil.");
		S(76, (o7_char *)"-no-arithmetic-overflow-check - turn off runtime check arithmetic overflow.");
		S(1, (o7_char *)"");
		S(65, (o7_char *)"-C90 | -C99 | -C11            - ISO standard of generated C-code");
	}
}

extern void Message_CliError(o7_int_t err) {
	switch (err) {
	case -10:
		Message_Usage((0 > 1));
		break;
	case -11:
		S(29, (o7_char *)"Too long name of source file");
		Out_Ln();
		break;
	case -12:
		S(26, (o7_char *)"Too long destination name");
		Out_Ln();
		break;
	case -13:
		S(25, (o7_char *)"Can not open source file");
		break;
	case -14:
		S(33, (o7_char *)"Can not open destination .h file");
		break;
	case -15:
		S(33, (o7_char *)"Can not open destination .c file");
		break;
	case -16:
		S(16, (o7_char *)"Unknown command");
		Message_Usage((0 > 1));
		break;
	case -17:
		S(42, (o7_char *)"Not enough count of arguments for command");
		break;
	case -18:
		S(44, (o7_char *)"Too long overall length of paths to modules");
		break;
	case -19:
		S(26, (o7_char *)"Too many paths to modules");
		break;
	case -20:
		S(45, (o7_char *)"Too long overall length of paths to .c files");
		break;
	case -21:
		S(38, (o7_char *)"Too long length of C compiler options");
		break;
	case -22:
		S(37, (o7_char *)"Too long name of temporary directory");
		break;
	case -23:
		S(29, (o7_char *)"Error during C compiler call");
		break;
	case -24:
		S(30, (o7_char *)"Too long command line options");
		break;
	case -25:
		S(18, (o7_char *)"Unexpected option");
		break;
	case -26:
		S(30, (o7_char *)"Unknown initialization method");
		break;
	case -27:
		S(34, (o7_char *)"Unknown kind of memory management");
		break;
	case -28:
		S(32, (o7_char *)"Can not create output directory");
		break;
	case -29:
		S(32, (o7_char *)"Can not remove output directory");
		break;
	case -30:
		S(25, (o7_char *)"Can not found C Compiler");
		break;
	default:
		o7_case_fail(err);
		break;
	}
}

extern void Message_Text(o7_int_t str_len0, o7_char str[/*len0*/]) {
	C(str_len0, str);
}

extern void Message_Ln(void) {
	Out_Ln();
}

extern void Message_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		Ast_init();
		Parser_init();
		CliParser_init();
		Scanner_init();
		Out_init();
	}
	++initialized;
}

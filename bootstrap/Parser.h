#if !defined HEADER_GUARD_Parser
#    define  HEADER_GUARD_Parser 1

#include "V.h"
#include "Log.h"
#include "Utf8.h"
#include "Scanner.h"
#include "OberonSpecIdent.h"
#include "StringStore.h"
#include "Ast.h"
#include "VDataStream.h"
#include "TranslatorLimits.h"

#define Parser_Err_cnst (-100)

#define Parser_ErrExpectModule_cnst (-101)
#define Parser_ErrExpectIdent_cnst (-102)
#define Parser_ErrExpectColon_cnst (-103)
#define Parser_ErrExpectSemicolon_cnst (-104)
#define Parser_ErrExpectEnd_cnst (-105)
#define Parser_ErrExpectDot_cnst (-106)
#define Parser_ErrExpectModuleName_cnst (-107)
#define Parser_ErrExpectEqual_cnst (-108)
#define Parser_ErrExpectBrace1Open_cnst (-109)
#define Parser_ErrExpectBrace1Close_cnst (-110)
#define Parser_ErrExpectBrace2Open_cnst (-111)
#define Parser_ErrExpectBrace2Close_cnst (-112)
#define Parser_ErrExpectBrace3Open_cnst (-113)
#define Parser_ErrExpectBrace3Close_cnst (-114)

#define Parser_ErrExpectOf_cnst (-115)
#define Parser_ErrExpectTo_cnst (-116)
#define Parser_ErrExpectStructuredType_cnst (-117)
#define Parser_ErrExpectRecord_cnst (-118)
#define Parser_ErrExpectStatement_cnst (-119)
#define Parser_ErrExpectThen_cnst (-120)
#define Parser_ErrExpectAssign_cnst (-121)
#define Parser_ErrExpectVarRecordOrPointer_cnst (-122)
#define Parser_ErrExpectType_cnst (-124)
#define Parser_ErrExpectUntil_cnst (-125)
#define Parser_ErrExpectDo_cnst (-126)
#define Parser_ErrExpectDesignator_cnst (-128)
#define Parser_ErrExpectProcedure_cnst (-130)
#define Parser_ErrExpectConstName_cnst (-131)
#define Parser_ErrExpectProcedureName_cnst (-132)
#define Parser_ErrExpectExpression_cnst (-133)
#define Parser_ErrExpectIntOrStrOrQualident_cnst (-134)
#define Parser_ErrExcessSemicolon_cnst (-135)
#define Parser_ErrMaybeAssignInsteadEqual_cnst (-136)
#define Parser_ErrUnexpectStringInCaseLabel_cnst (-137)

#define Parser_ErrEndModuleNameNotMatch_cnst (-150)
#define Parser_ErrExpectAnotherModuleName_cnst (-151)
#define Parser_ErrArrayDimensionsTooMany_cnst (-152)
#define Parser_ErrEndProcedureNameNotMatch_cnst (-153)
#define Parser_ErrFunctionWithoutBraces_cnst (-154)

#define Parser_ErrUnexpectedContentInScript_cnst (-155)

#define Parser_ErrAstBegin_cnst (-200)
#define Parser_ErrAstEnd_cnst (-400)

#define Parser_ErrMin_cnst (-400)

typedef void (*Parser_PrintError)(o7_int_t code, struct StringStore_String *str);
typedef struct Parser_Options {
	V_Base _;
	o7_bool strictSemicolon;
	o7_bool strictReturn;
	o7_bool saveComments;
	o7_bool multiErrors;
	o7_bool cyrillic;
	Parser_PrintError printError;

	struct Ast_RProvider *provider;
} Parser_Options;
#define Parser_Options_tag V_Base_tag

extern void Parser_Options_undef(struct Parser_Options *r);

extern void Parser_DefaultOptions(struct Parser_Options *opt);

extern struct Ast_RModule *Parser_Parse(struct VDataStream_In *in_, struct Parser_Options *opt);

extern struct Ast_RModule *Parser_Script(o7_int_t in__len0, o7_char in_[/*len0*/], struct Parser_Options *opt);

extern void Parser_init(void);
#endif

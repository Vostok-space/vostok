#if !defined(HEADER_GUARD_Parser)
#define HEADER_GUARD_Parser

#include "V.h"
#include "Log.h"
#include "Out.h"
#include "Utf8.h"
#include "Scanner.h"
#include "StringStore.h"
#include "Ast.h"
#include "VDataStream.h"

#define Parser_Err_cnst (-20)
#define Parser_ErrExpectModule_cnst (-21)
#define Parser_ErrExpectIdent_cnst (-22)
#define Parser_ErrExpectColon_cnst (-23)
#define Parser_ErrExpectSemicolon_cnst (-24)
#define Parser_ErrExpectEnd_cnst (-25)
#define Parser_ErrExpectDot_cnst (-26)
#define Parser_ErrExpectModuleName_cnst (-27)
#define Parser_ErrExpectEqual_cnst (-28)
#define Parser_ErrExpectBrace1Close_cnst (-29)
#define Parser_ErrExpectBrace2Close_cnst (-30)
#define Parser_ErrExpectBrace3Close_cnst (-31)
#define Parser_ErrExpectOf_cnst (-32)
#define Parser_ErrExpectConstIntExpr_cnst (-34)
#define Parser_ErrExpectTo_cnst (-35)
#define Parser_ErrExpectNamedType_cnst (-36)
#define Parser_ErrExpectRecord_cnst (-37)
#define Parser_ErrExpectStatement_cnst (-38)
#define Parser_ErrExpectThen_cnst (-39)
#define Parser_ErrExpectAssign_cnst (-40)
#define Parser_ErrExpectAssignOrBrace1Open_cnst (-41)
#define Parser_ErrExpectVarRecordOrPointer_cnst (-42)
#define Parser_ErrExpectPointer_cnst (-43)
#define Parser_ErrExpectType_cnst (-44)
#define Parser_ErrExpectUntil_cnst (-45)
#define Parser_ErrExpectDo_cnst (-46)
#define Parser_ErrExpectVarArray_cnst (-47)
#define Parser_ErrExpectDesignator_cnst (-48)
#define Parser_ErrExpectVar_cnst (-49)
#define Parser_ErrExpectProcedure_cnst (-50)
#define Parser_ErrExpectConstName_cnst (-51)
#define Parser_ErrExpectProcedureName_cnst (-52)
#define Parser_ErrExpectExpression_cnst (-53)
#define Parser_ErrExpectIntOrStrOrQualident_cnst (-54)
#define Parser_ErrExcessSemicolon_cnst (-55)
#define Parser_ErrEndModuleNameNotMatch_cnst (-70)
#define Parser_ErrDeclarationNotVar_cnst (-71)
#define Parser_ErrArrayDimensionsTooMany_cnst (-72)
#define Parser_ErrEndProcedureNameNotMatch_cnst (-73)
#define Parser_ErrFunctionWithoutBraces_cnst (-74)
#define Parser_ErrArrayLenLess1_cnst (-75)
#define Parser_ErrNotImplemented_cnst (-90)
#define Parser_ErrAstBegin_cnst (-100)
#define Parser_ErrAstEnd_cnst (-150)

typedef struct Parser_Options {
	struct V_Base _;
	bool strictSemicolon;
	bool strictReturn;
	void (*printError)(int code);
} Parser_Options;
extern int Parser_Options_tag[15];


extern void Parser_DefaultOptions(struct Parser_Options *opt, int *opt_tag);

extern struct Ast_RModule *Parser_Parse(struct VDataStream_In *in_, int *in__tag, struct Ast_RProvider *prov, int *prov_tag, struct Parser_Options *opt, int *opt_tag);

extern void Parser_init_(void);
#endif

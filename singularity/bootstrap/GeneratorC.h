#if !defined HEADER_GUARD_GeneratorC
#    define  HEADER_GUARD_GeneratorC 1

#include "V.h"
#include "Ast.h"
#include "StringStore.h"
#include "SpecIdentChecker.h"
#include "Scanner.h"
#include "OberonSpecIdent.h"
#include "VDataStream.h"
#include "TextGenerator.h"
#include "Utf8.h"
#include "Log.h"
#include "TypesLimits.h"
#include "TranslatorLimits.h"


#define GeneratorC_IsoC90_cnst 0
#define GeneratorC_IsoC99_cnst 1
#define GeneratorC_IsoC11_cnst 2

#define GeneratorC_VarInitUndefined_cnst 0
#define GeneratorC_VarInitZero_cnst 1
#define GeneratorC_VarInitNo_cnst 2

#define GeneratorC_MemManagerNoFree_cnst 0
#define GeneratorC_MemManagerCounter_cnst 1
#define GeneratorC_MemManagerGC_cnst 2

#define GeneratorC_IdentEncSame_cnst 0
#define GeneratorC_IdentEncTranslit_cnst 1
#define GeneratorC_IdentEncEscUnicode_cnst 2

typedef struct GeneratorC_MemoryOut *GeneratorC_PMemoryOut;
typedef struct GeneratorC_MemoryOut {
	VDataStream_Out _;
	struct GeneratorC_GeneratorC__anon__0000 {
		o7_char buf[4096];
		o7_int_t len;
	} mem[2];
	o7_bool invert;

	struct GeneratorC_MemoryOut *next;
} GeneratorC_MemoryOut;
extern o7_tag_t GeneratorC_MemoryOut_tag;

extern void GeneratorC_MemoryOut_undef(struct GeneratorC_MemoryOut *r);

typedef struct GeneratorC_Options__s {
	V_Base _;
	o7_int_t std;

	o7_bool gnu;
	o7_bool plan9;
	o7_bool procLocal;
	o7_bool checkIndex;
	o7_bool vla;
	o7_bool vlaMark;
	o7_bool checkArith;
	o7_bool caseAbort;
	o7_bool checkNil;
	o7_bool o7Assert;
	o7_bool skipUnusedTag;
	o7_bool comment;
	o7_bool generatorNote;

	o7_int_t varInit;
	o7_int_t memManager;

	o7_bool main_;

	o7_int_t index;
	struct Ast_RRecord *records;
	struct Ast_RRecord *recordLast;

	o7_bool lastSelectorDereference;
	o7_bool expectArray;

	struct GeneratorC_MemoryOut *memOuts;
} *GeneratorC_Options;
#define GeneratorC_Options__s_tag V_Base_tag

extern void GeneratorC_Options__s_undef(struct GeneratorC_Options__s *r);

typedef struct GeneratorC_Generator {
	TextGenerator_Out _;
	struct Ast_RModule *module;

	o7_int_t localDeep;

	o7_int_t fixedLen;

	o7_bool interface_;
	struct GeneratorC_Options__s *opt;

	o7_bool expressionSemicolon;
	o7_bool insideSizeOf;

	struct GeneratorC_MemoryOut *memout;
} GeneratorC_Generator;
#define GeneratorC_Generator_tag TextGenerator_Out_tag

extern void GeneratorC_Generator_undef(struct GeneratorC_Generator *r);

extern struct GeneratorC_Options__s *GeneratorC_DefaultOptions(void);

extern void GeneratorC_Generate(struct VDataStream_Out *interface_, struct VDataStream_Out *implementation, struct Ast_RModule *module, struct Ast_RStatement *cmd, struct GeneratorC_Options__s *opt);

extern void GeneratorC_init(void);
#endif

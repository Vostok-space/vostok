#if !defined HEADER_GUARD_GeneratorC
#    define  HEADER_GUARD_GeneratorC 1

#include "V.h"
#include "Ast.h"
#include "Utf8.h"
#include "Hex.h"
#include "StringStore.h"
#include "Chars0X.h"
#include "SpecIdentChecker.h"
#include "Scanner.h"
#include "OberonSpecIdent.h"
#include "VDataStream.h"
#include "TextGenerator.h"
#include "TypesLimits.h"
#include "TranslatorLimits.h"
#include "GenOptions.h"
#include "GenCommon.h"

#define GeneratorC_Supported_cnst (0 < 1)

#define GeneratorC_IsoC90_cnst 0
#define GeneratorC_IsoC99_cnst 1
#define GeneratorC_IsoC11_cnst 2

#define GeneratorC_MemManagerNoFree_cnst 0
#define GeneratorC_MemManagerCounter_cnst 1
#define GeneratorC_MemManagerGC_cnst 2

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


typedef struct GeneratorC_Options__s {
	GenOptions_R _;
	o7_int_t std;

	o7_bool gnu;
	o7_bool plan9;
	o7_bool e2k;
	o7_bool procLocal;
	o7_bool vla;
	o7_bool vlaMark;
	o7_bool checkNil;
	o7_bool skipUnusedTag;

	o7_int_t memManager;

	o7_int_t index;
	struct Ast_RRecord *records;
	struct Ast_RRecord *recordLast;

	o7_bool lastSelectorDereference;
	o7_bool expectArray;
	o7_bool castToBase;

	struct GeneratorC_MemoryOut *memOuts;
} *GeneratorC_Options;
#define GeneratorC_Options__s_tag GenOptions_R_tag


extern struct GeneratorC_Options__s *GeneratorC_DefaultOptions(void);

extern void GeneratorC_Generate(struct VDataStream_Out *interface_, struct VDataStream_Out *implementation, struct Ast_RModule *module_, struct Ast_RStatement *cmd, struct GeneratorC_Options__s *opt);

extern void GeneratorC_init(void);
#endif

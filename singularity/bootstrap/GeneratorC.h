#if !defined(HEADER_GUARD_GeneratorC)
#define HEADER_GUARD_GeneratorC

#include "V.h"
#include "Ast.h"
#include "StringStore.h"
#include "Scanner.h"
#include "VDataStream.h"
#include "Utf8.h"
#include "Log.h"
#include "TranslatorLimits.h"

#define GeneratorC_IsoC90_cnst 0
#define GeneratorC_IsoC99_cnst 1

typedef struct GeneratorC_Options_s {
	struct V_Base _;
	int std;
	bool gnu;
	bool procLocal;
	bool main_;
	int index;
	struct V_Base *records;
	struct V_Base *recordLast;
	bool lastSelectorDereference;
} *GeneratorC_Options;
extern int GeneratorC_Options_s_tag[15];

typedef struct GeneratorC_Generator {
	struct V_Base _;
	struct VDataStream_Out *out;
	int len;
	struct Ast_RModule *module;
	int localDeep;
	int fixedLen;
	int tabs;
	bool interface_;
	struct GeneratorC_Options_s *opt;
	bool expressionSemicolon;
} GeneratorC_Generator;
extern int GeneratorC_Generator_tag[15];


extern struct GeneratorC_Options_s *GeneratorC_DefaultOptions(void);

extern void GeneratorC_Init(struct GeneratorC_Generator *g, int *g_tag, struct VDataStream_Out *out, int *out_tag);

extern void GeneratorC_Generate(struct GeneratorC_Generator *interface_, int *interface__tag, struct GeneratorC_Generator *implementation, int *implementation_tag, struct Ast_RModule *module, int *module_tag, struct GeneratorC_Options_s *opt, int *opt_tag);

extern void GeneratorC_init_(void);
#endif

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
	bool checkIndex;
	bool main_;
	int index;
	struct V_Base *records;
	struct V_Base *recordLast;
	bool lastSelectorDereference;
} *GeneratorC_Options;
extern o7c_tag_t GeneratorC_Options_s_tag;

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
extern o7c_tag_t GeneratorC_Generator_tag;


extern struct GeneratorC_Options_s *GeneratorC_DefaultOptions(void);

extern void GeneratorC_Init(struct GeneratorC_Generator *g, o7c_tag_t g_tag, struct VDataStream_Out *out, o7c_tag_t out_tag);

extern void GeneratorC_Generate(struct GeneratorC_Generator *interface_, o7c_tag_t interface__tag, struct GeneratorC_Generator *implementation, o7c_tag_t implementation_tag, struct Ast_RModule *module, o7c_tag_t module_tag, struct GeneratorC_Options_s *opt, o7c_tag_t opt_tag);

extern void GeneratorC_init_(void);
#endif

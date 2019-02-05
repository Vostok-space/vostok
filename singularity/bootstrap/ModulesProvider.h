#if !defined HEADER_GUARD_ModulesProvider
#    define  HEADER_GUARD_ModulesProvider 1

#include "Log.h"
#include "Out.h"
#include "Ast.h"
#include "CliParser.h"
#include "StringStore.h"
#include "Parser.h"
#include "TranslatorLimits.h"
#include "VFileStream.h"
#include "PlatformExec.h"
#include "Utf8.h"
#include "Message.h"

typedef struct ModulesProvider_Provider__s {
	Ast_RProvider _;
	struct Parser_Options opt;

	o7_char path[4096];
	unsigned sing;

	o7_char expectName[TranslatorLimits_LenName_cnst + 1];
	o7_int_t nameLen;
	o7_bool nameOk;
	o7_bool firstNotOk;
} *ModulesProvider_Provider;
extern o7_tag_t ModulesProvider_Provider__s_tag;

extern void ModulesProvider_Provider__s_undef(struct ModulesProvider_Provider__s *r);

extern void ModulesProvider_New(struct ModulesProvider_Provider__s **mp, struct CliParser_Args *args);

extern void ModulesProvider_SetParserOptions(struct ModulesProvider_Provider__s *p, struct Parser_Options *o);

extern void ModulesProvider_init(void);
#endif

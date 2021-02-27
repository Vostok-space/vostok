#if !defined(O7_INIT_MODEL)
#   define   O7_INIT_MODEL O7_INIT_ZERO
#endif

#include <o7.h>

#include "ModulesProvider.h"

o7_tag_t ModulesProvider_Provider__s_tag;

static struct Ast_RModule *GetModule(struct Ast_RProvider *p, struct Ast_RModule *host, o7_int_t name_len0, o7_char name[/*len0*/]);
static struct Ast_RModule *GetModule_Search(struct ModulesProvider_Provider__s *p) {
	struct VDataStream_In *source = NULL;
	struct Ast_RModule *m;
	o7_bool decl = 0 > 1;
	struct InputProvider_Iter *it = NULL;

	m = NULL;
	if (InputProvider_Get(p->in_, &it, TranslatorLimits_LenName_cnst + 1, p->expectName)) {
		do {
			if (InputProvider_Next(&it, &source, &decl)) {
				m = Parser_Parse(source, &p->opt);
				VDataStream_CloseIn(&source);
				if ((m != NULL) && (m->errors == NULL) && !p->nameOk) {
					m = NULL;
				} else if (m != NULL) {
					Log_Str(StringStore_BlockSize_cnst + 1, m->_._.name.block->s);
					Log_Str(4, (o7_char *)" : ");
					Log_Bool(decl);
					Log_Ln();
					m->_._.mark = decl;
				}
			}
		} while (!((m != NULL) || (it == NULL)));
	}
	return m;
}

static struct Ast_RModule *GetModule(struct Ast_RProvider *p, struct Ast_RModule *host, o7_int_t name_len0, o7_char name[/*len0*/]) {
	struct Ast_RModule *m;
	struct ModulesProvider_Provider__s *mp;

	mp = O7_GUARD(ModulesProvider_Provider__s, p);
	mp->nameLen = 0;
	if (!Chars0X_CopyString(TranslatorLimits_LenName_cnst + 1, mp->expectName, &mp->nameLen, name_len0, name)) {
		m = NULL;
		MessageErrOberon_Text(41, (o7_char *)"Name of potential module is too large - ");
		Out_String(name_len0, name);
		MessageErrOberon_Ln();
	} else {
		m = GetModule_Search(mp);
		if ((m == NULL) && mp->firstNotOk) {
			mp->firstNotOk = (0 > 1);
			MessageErrOberon_Text(40, (o7_char *)"Can not found or open file of module - ");
			Out_String(TranslatorLimits_LenName_cnst + 1, mp->expectName);
			MessageErrOberon_Ln();
		}
	}
	return m;
}

static o7_bool RegModule(struct Ast_RProvider *p, struct Ast_RModule *m);
static o7_bool RegModule_Reg(struct ModulesProvider_Provider__s *p, struct Ast_RModule *m) {
	Log_Str(11, (o7_char *)"RegModule ");
	Log_Str(StringStore_BlockSize_cnst + 1, m->_._.name.block->s);
	Log_Str(4, (o7_char *)" : ");
	Log_StrLn(TranslatorLimits_LenName_cnst + 1, p->expectName);
	p->nameOk = o7_strcmp(StringStore_BlockSize_cnst + 1, m->_._.name.block->s, TranslatorLimits_LenName_cnst + 1, p->expectName) == 0;
	return p->nameOk;
}

static o7_bool RegModule(struct Ast_RProvider *p, struct Ast_RModule *m) {
	return RegModule_Reg(O7_GUARD(ModulesProvider_Provider__s, p), m);
}

extern o7_bool ModulesProvider_New(struct ModulesProvider_Provider__s **mp, struct InputProvider_R *inp) {
	O7_ASSERT(inp != NULL);

	O7_NEW(&*mp, ModulesProvider_Provider__s);
	if (*mp != NULL) {
		Ast_ProviderInit(&(*mp)->_, GetModule, RegModule);

		(*mp)->in_ = inp;
		(*mp)->firstNotOk = (0 < 1);
	}
	return *mp != NULL;
}

extern void ModulesProvider_SetParserOptions(struct ModulesProvider_Provider__s *p, struct Parser_Options *o) {
	p->opt = *o;
}

extern void ModulesProvider_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		Log_init();
		Out_init();
		Ast_init();
		StringStore_init();
		Parser_init();
		VFileStream_init();
		VDataStream_init();
		PlatformExec_init();
		MessageErrOberon_init();
		InputProvider_init();

		O7_TAG_INIT(ModulesProvider_Provider__s, Ast_RProvider);
	}
	++initialized;
}

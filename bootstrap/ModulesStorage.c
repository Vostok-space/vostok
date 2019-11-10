#include <o7.h>

#include "ModulesStorage.h"

#define ModulesStorage_RContainer_tag o7_base_tag
extern void ModulesStorage_RContainer_undef(struct ModulesStorage_RContainer *r) {
	r->next = NULL;
	r->m = NULL;
}
o7_tag_t ModulesStorage_Provider__s_tag;
extern void ModulesStorage_Provider__s_undef(struct ModulesStorage_Provider__s *r) {
	Ast_RProvider_undef(&r->_);
	r->provider = NULL;
	r->first = NULL;
	r->last = NULL;
}

extern struct ModulesStorage_RContainer *ModulesStorage_Iterate(struct ModulesStorage_Provider__s *p) {
	return O7_REF(p)->first;
}

extern struct Ast_RModule *ModulesStorage_Next(struct ModulesStorage_RContainer **it) {
	(*it) = O7_REF((*it))->next;
	return O7_REF((*it))->m;
}

extern void ModulesStorage_Unlink(struct ModulesStorage_Provider__s **p) {
	struct ModulesStorage_RContainer *c, *tc;

	if ((*p) != NULL) {
		O7_REF(O7_REF((*p))->last)->next = NULL;
		c = O7_REF(O7_REF((*p))->first)->next;
		while (c != NULL) {
			tc = c;
			c = O7_REF(c)->next;
			Log_StrLn(StringStore_BlockSize_cnst + 1, O7_REF(O7_REF(O7_REF(tc)->m)->_._.name.block)->s);
			Ast_Unlinks(O7_REF(tc)->m);
			O7_REF(tc)->m = NULL;
		}
		(*p) = NULL;
	}
}

static struct Ast_RModule *SearchModule(struct ModulesStorage_Provider__s *mp, o7_int_t name_len0, o7_char name[/*len0*/], o7_int_t ofs, o7_int_t end) {
	struct ModulesStorage_RContainer *first, *mc;

	first = O7_REF(mp)->first;
	mc = O7_REF(first)->next;
	Log_StrLn(7, (o7_char *)"Search");
	while ((mc != first) && !StringStore_IsEqualToChars(&O7_REF(O7_REF(mc)->m)->_._.name, name_len0, name, ofs, end)) {
		Log_Str(StringStore_BlockSize_cnst + 1, O7_REF(O7_REF(O7_REF(mc)->m)->_._.name.block)->s);
		Log_Str(4, (o7_char *)" : ");
		Log_StrLn(name_len0, name);
		mc = O7_REF(mc)->next;
	}
	Log_StrLn(11, (o7_char *)"End Search");
	return O7_REF(mc)->m;
}

static void Add(struct ModulesStorage_Provider__s *mp, struct Ast_RModule *m) {
	struct ModulesStorage_RContainer *mc = NULL;

	O7_ASSERT(O7_REF(O7_REF(m)->_._.module_)->m == m);
	O7_NEW(&mc, ModulesStorage_RContainer);
	O7_REF(mc)->m = m;
	O7_REF(mc)->next = O7_REF(O7_REF(mp)->last)->next;

	O7_REF(O7_REF(mp)->last)->next = mc;
	O7_REF(mp)->last = mc;
}

extern struct Ast_RModule *ModulesStorage_GetModule(struct Ast_RProvider *p, struct Ast_RModule *host, o7_int_t name_len0, o7_char name[/*len0*/], o7_int_t ofs, o7_int_t end) {
	struct Ast_RModule *m;
	struct ModulesStorage_Provider__s *mp;

	mp = O7_GUARD(ModulesStorage_Provider__s, &p);
	m = SearchModule(mp, name_len0, name, ofs, end);
	if (m == NULL) {
		m = Ast_ProvideModule(O7_REF(mp)->provider, host, name_len0, name, ofs, end);
	} else {
		Log_Str(57, (o7_char *)"Найден уже разобранный модуль ");
		Log_StrLn(StringStore_BlockSize_cnst + 1, O7_REF(O7_REF(m)->_._.name.block)->s);
	}
	return m;
}

static o7_bool RegModule(struct Ast_RProvider *p, struct Ast_RModule *m);
static o7_bool RegModule_Reg(struct ModulesStorage_Provider__s *p, struct Ast_RModule *m) {
	o7_bool ok;

	ok = Ast_RegModule(O7_REF(p)->provider, m);
	if (ok) {
		Add(p, m);
	}
	return ok;
}

static o7_bool RegModule(struct Ast_RProvider *p, struct Ast_RModule *m) {
	return RegModule_Reg(O7_GUARD(ModulesStorage_Provider__s, &p), m);
}

extern void ModulesStorage_New(struct ModulesStorage_Provider__s **mp, struct Ast_RProvider *else_) {
	O7_NEW(&(*mp), ModulesStorage_Provider__s);
	Ast_ProviderInit(&(*mp)->_, ModulesStorage_GetModule, RegModule);

	O7_NEW(&O7_REF((*mp))->first, ModulesStorage_RContainer);
	O7_REF(O7_REF((*mp))->first)->m = NULL;
	O7_REF(O7_REF((*mp))->first)->next = O7_REF((*mp))->first;
	O7_REF((*mp))->last = O7_REF((*mp))->first;

	O7_REF((*mp))->provider = else_;
}

extern void ModulesStorage_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		Log_init();
		Ast_init();
		StringStore_init();

		O7_TAG_INIT(ModulesStorage_Provider__s, Ast_RProvider);
	}
	++initialized;
}


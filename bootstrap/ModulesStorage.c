#if !defined(O7_INIT_MODEL)
#   define   O7_INIT_MODEL O7_INIT_ZERO
#endif

#include <o7.h>

#include "ModulesStorage.h"

#define ModulesStorage_RContainer_tag o7_base_tag
o7_tag_t ModulesStorage_Provider__s_tag;

extern struct ModulesStorage_RContainer *ModulesStorage_Iterate(struct ModulesStorage_Provider__s *p) {
	return p->first;
}

extern struct Ast_RModule *ModulesStorage_Next(struct ModulesStorage_RContainer **it) {
	*it = (*it)->next;
	return (*it)->m;
}

extern void ModulesStorage_Unlink(struct ModulesStorage_Provider__s **p) {
	struct ModulesStorage_RContainer *c, *tc;

	if (*p != NULL) {
		(*p)->last->next = NULL;
		c = (*p)->first->next;
		while (c != NULL) {
			tc = c;
			c = c->next;
			Ast_Unlinks(tc->m);
			tc->m = NULL;
		}
		*p = NULL;
	}
}

static struct Ast_RModule *SearchModule(struct ModulesStorage_Provider__s *mp, o7_int_t name_len0, o7_char name[/*len0*/]) {
	struct ModulesStorage_RContainer *first, *mc;

	first = mp->first;
	mc = first->next;
	Log_StrLn(7, (o7_char *)"Search");
	while ((mc != first) && !StringStore_IsEqualToString(&mc->m->_._.name, name_len0, name)) {
		Log_Str(StringStore_BlockSize_cnst + 1, mc->m->_._.name.block->s);
		Log_Str(4, (o7_char *)" : ");
		Log_StrLn(name_len0, name);
		mc = mc->next;
	}
	Log_StrLn(11, (o7_char *)"End Search");
	return mc->m;
}

static void Add(struct ModulesStorage_Provider__s *mp, struct Ast_RModule *m) {
	struct ModulesStorage_RContainer *mc = NULL;

	O7_ASSERT(m->_._.module_->m == m);
	O7_NEW(&mc, ModulesStorage_RContainer);
	mc->m = m;
	mc->next = mp->last->next;

	mp->last->next = mc;
	mp->last = mc;
}

static struct Ast_RModule *GetModule(struct Ast_RProvider *p, struct Ast_RModule *host, o7_int_t name_len0, o7_char name[/*len0*/]) {
	struct Ast_RModule *m;
	struct ModulesStorage_Provider__s *mp;

	mp = O7_GUARD(ModulesStorage_Provider__s, p);
	m = SearchModule(mp, name_len0, name);
	if (m == NULL) {
		m = Ast_ProvideModule(mp->provider, host, name_len0, name);
	} else {
		Log_Str(57, (o7_char *)"Найден уже разобранный модуль ");
		Log_StrLn(StringStore_BlockSize_cnst + 1, m->_._.name.block->s);
	}
	return m;
}

static o7_bool RegModule(struct Ast_RProvider *p, struct Ast_RModule *m);
static o7_bool RegModule_Reg(struct ModulesStorage_Provider__s *p, struct Ast_RModule *m) {
	o7_bool ok;

	ok = Ast_RegModule(p->provider, m);
	if (ok) {
		Add(p, m);
	}
	return ok;
}

static o7_bool RegModule(struct Ast_RProvider *p, struct Ast_RModule *m) {
	return RegModule_Reg(O7_GUARD(ModulesStorage_Provider__s, p), m);
}

extern void ModulesStorage_New(struct ModulesStorage_Provider__s **mp, struct Ast_RProvider *else_) {
	O7_NEW(&*mp, ModulesStorage_Provider__s);
	Ast_ProviderInit(&(*mp)->_, GetModule, RegModule);

	O7_NEW(&(*mp)->first, ModulesStorage_RContainer);
	(*mp)->first->m = NULL;
	(*mp)->first->next = (*mp)->first;
	(*mp)->last = (*mp)->first;

	(*mp)->provider = else_;
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


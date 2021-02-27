#if !defined(O7_INIT_MODEL)
#   define   O7_INIT_MODEL O7_INIT_ZERO
#endif

#include <o7.h>

#include "InputProvider.h"

#define InputProvider_Iter_tag V_Base_tag
#define InputProvider_R_tag V_Base_tag

extern void InputProvider_Init(struct InputProvider_R *p, InputProvider_GetIterator get) {
	O7_ASSERT(get != NULL);
	V_Init(&(*p)._);
	p->get = get;
}

extern void InputProvider_InitIter(struct InputProvider_Iter *it, InputProvider_NextInput next) {
	O7_ASSERT(next != NULL);
	V_Init(&(*it)._);
	it->next = next;
}

extern o7_bool InputProvider_Get(struct InputProvider_R *p, struct InputProvider_Iter **it, o7_int_t name_len0, o7_char name[/*len0*/]) {
	O7_ASSERT(o7_strcmp(name_len0, name, 1, (o7_char *)"") != 0);
	*it = p->get(p, name_len0, name);
	return *it != NULL;
}

extern o7_bool InputProvider_Next(struct InputProvider_Iter **it, struct VDataStream_In **in_, o7_bool *declaration) {
	*in_ = (*it)->next(&(*(*it))._, NULL, declaration);
	if (*in_ == NULL) {
		*it = NULL;
	}
	return *in_ != NULL;
}

extern void InputProvider_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		VDataStream_init();
	}
	++initialized;
}


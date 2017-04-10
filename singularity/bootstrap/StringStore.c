#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#define O7C_BOOL_UNDEFINED
#include <o7c.h>

#include "StringStore.h"

o7c_tag_t StringStore_Block_s_tag;
o7c_tag_t StringStore_String_tag;
o7c_tag_t StringStore_Iterator_tag;
o7c_tag_t StringStore_Store_tag;

extern void StringStore_LogLoopStr(o7c_char s[/*len0*/], int s_len0, int j, int end) {
	while (o7c_cmp(j, end) !=  0) {
		Log_Char(s[o7c_ind(s_len0, j)]);
		j = o7c_mod((o7c_add(j, 1)), (o7c_sub(s_len0, 1)));
	}
}

extern void StringStore_UndefString(struct StringStore_String *s, o7c_tag_t s_tag) {
	(*s).block = NULL;
	(*s).ofs =  - 1;
}

extern o7c_bool StringStore_IsDefined(struct StringStore_String *s, o7c_tag_t s_tag) {
	return (*s).block != NULL;
}

static void Put_AddBlock(struct StringStore_Block_s **b, int *i) {
	assert((*b)->next == NULL);
	(*i) = 0;
	O7C_NEW(&(*b)->next, StringStore_Block_s_tag);
	V_Init(&(*(*b)->next)._, NULL);
	(*b)->next->num = o7c_add((*b)->num, 1);
	(*b) = (*b)->next;
	(*b)->next = NULL;
}

extern void StringStore_Put(struct StringStore_Store *store, o7c_tag_t store_tag, struct StringStore_String *w, o7c_tag_t w_tag, o7c_char s[/*len0*/], int s_len0, int j, int end) {
	struct StringStore_Block_s *b = NULL;
	int i = O7C_INT_UNDEF;

	assert((s_len0 % 2 == 1));
	assert((o7c_cmp(j, 0) >=  0) && (o7c_cmp(j, o7c_sub(s_len0, 1)) <  0));
	assert((o7c_cmp(end, 0) >=  0) && (o7c_cmp(end, o7c_sub(s_len0, 1)) <  0));
	b = (*store).last;
	i = (*store).ofs;
	(*w).block = b;
	(*w).ofs = i;
	while (o7c_cmp(j, end) !=  0) {
		if (o7c_cmp(i, sizeof(b->s) / sizeof (b->s[0]) - 1) ==  0) {
			assert(o7c_cmp(i, (*w).ofs) !=  0);
			b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] = 0x0Cu;
			Put_AddBlock(&b, &i);
		}
		b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] = s[o7c_ind(s_len0, j)];
		assert(s[o7c_ind(s_len0, j)] != 0x0Cu);
		i = o7c_add(i, 1);
		j = o7c_mod((o7c_add(j, 1)), (o7c_sub(s_len0, 1)));
	}
	b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] = 0x00u;
	if (o7c_cmp(i, sizeof(b->s) / sizeof (b->s[0]) - 2) <  0) {
		i = o7c_add(i, 1);
	} else {
		Put_AddBlock(&b, &i);
	}
	(*store).last = b;
	(*store).ofs = i;
}

extern o7c_bool StringStore_GetIter(struct StringStore_Iterator *iter, o7c_tag_t iter_tag, struct StringStore_String *s, o7c_tag_t s_tag, int ofs) {
	assert(o7c_cmp(ofs, 0) >=  0);
	if ((*s).block != NULL) {
		V_Init(&(*iter)._, iter_tag);
		(*iter).b = (*s).block;
		(*iter).i = (*s).ofs;
		while (1) if ((*iter).b->s[o7c_ind(StringStore_BlockSize_cnst + 1, (*iter).i)] == 0x0Cu) {
			(*iter).b = (*iter).b->next;
			(*iter).i = 0;
		} else if ((o7c_cmp(ofs, 0) >  0) && ((*iter).b->s[o7c_ind(StringStore_BlockSize_cnst + 1, (*iter).i)] != 0x00u)) {
			ofs = o7c_sub(ofs, 1);
			(*iter).i = o7c_add((*iter).i, 1);
		} else break;
		(*iter).char_ = (*iter).b->s[o7c_ind(StringStore_BlockSize_cnst + 1, (*iter).i)];
	}
	return ((*s).block != NULL) && ((*iter).b->s[o7c_ind(StringStore_BlockSize_cnst + 1, (*iter).i)] != 0x00u);
}

extern o7c_bool StringStore_IterNext(struct StringStore_Iterator *iter, o7c_tag_t iter_tag) {
	if ((*iter).char_ != 0x00u) {
		(*iter).i = o7c_add((*iter).i, 1);
		if ((*iter).b->s[o7c_ind(StringStore_BlockSize_cnst + 1, (*iter).i)] == 0x0Cu) {
			(*iter).b = (*iter).b->next;
			(*iter).i = 0;
		}
		(*iter).char_ = (*iter).b->s[o7c_ind(StringStore_BlockSize_cnst + 1, (*iter).i)];
	}
	return (*iter).char_ != 0x00u;
}

extern o7c_bool StringStore_IsEqualToChars(struct StringStore_String *w, o7c_tag_t w_tag, o7c_char s[/*len0*/], int s_len0, int j, int end) {
	int i = O7C_INT_UNDEF;
	struct StringStore_Block_s *b = NULL;

	assert((s_len0 % 2 == 1));
	assert((o7c_cmp(j, 0) >=  0) && (o7c_cmp(j, o7c_sub(s_len0, 1)) <  0));
	assert((o7c_cmp(end, 0) >=  0) && (o7c_cmp(end, o7c_sub(s_len0, 1)) <  0));
	i = (*w).ofs;
	b = (*w).block;
	while (1) if (b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == s[o7c_ind(s_len0, j)]) {
		i = o7c_add(i, 1);
		j = o7c_mod((o7c_add(j, 1)), (o7c_sub(s_len0, 1)));
	} else if (b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == 0x0Cu) {
		b = b->next;
		i = 0;
	} else break;
	return (b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == 0x00u) && (o7c_cmp(j, end) ==  0);
}

extern o7c_bool StringStore_IsEqualToString(struct StringStore_String *w, o7c_tag_t w_tag, o7c_char s[/*len0*/], int s_len0) {
	int i = O7C_INT_UNDEF, j = O7C_INT_UNDEF;
	struct StringStore_Block_s *b = NULL;

	j = 0;
	i = (*w).ofs;
	b = (*w).block;
	while (1) if ((b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == s[o7c_ind(s_len0, j)]) && (s[o7c_ind(s_len0, j)] != 0x00u)) {
		i = o7c_add(i, 1);
		j = o7c_add(j, 1);
	} else if (b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == 0x0Cu) {
		b = b->next;
		i = 0;
	} else break;
	return b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == s[o7c_ind(s_len0, j)];
}

extern void StringStore_CopyToChars(o7c_char d[/*len0*/], int d_len0, int *dofs, struct StringStore_String *w, o7c_tag_t w_tag) {
	struct StringStore_Block_s *b = NULL;
	int i = O7C_INT_UNDEF;

	b = (*w).block;
	i = (*w).ofs;
	while (1) if (b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] > 0x0Cu) {
		d[o7c_ind(d_len0, (*dofs))] = b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)];
		(*dofs) = o7c_add((*dofs), 1);
		i = o7c_add(i, 1);
	} else if (b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] != 0x00u) {
		assert(b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == 0x0Cu);
		b = b->next;
		i = 0;
	} else break;
	d[o7c_ind(d_len0, (*dofs))] = 0x00u;
}

extern void StringStore_StoreInit(struct StringStore_Store *s, o7c_tag_t s_tag) {
	V_Init(&(*s)._, s_tag);
	O7C_NEW(&(*s).first, StringStore_Block_s_tag);
	V_Init(&(*(*s).first)._, NULL);
	(*s).first->num = 0;
	(*s).last = (*s).first;
	(*s).last->next = NULL;
	(*s).ofs = 0;
}

extern void StringStore_StoreDone(struct StringStore_Store *s, o7c_tag_t s_tag) {
	while ((*s).first != NULL) {
		(*s).first = (*s).first->next;
	}
	(*s).last = NULL;
}

extern o7c_bool StringStore_CopyChars(o7c_char dest[/*len0*/], int dest_len0, int *destOfs, o7c_char src[/*len0*/], int src_len0, int srcOfs, int srcEnd) {
	o7c_bool ret = O7C_BOOL_UNDEF;

	assert((o7c_cmp((*destOfs), 0) >=  0) && (o7c_cmp(srcOfs, 0) >=  0) && (o7c_cmp(srcEnd, srcOfs) >=  0) && (o7c_cmp(srcEnd, src_len0) <=  0));
	ret = o7c_cmp(o7c_sub(o7c_add((*destOfs), srcEnd), srcOfs), o7c_sub(dest_len0, 1)) <  0;
	if (ret) {
		while (o7c_cmp(srcOfs, srcEnd) <  0) {
			dest[o7c_ind(dest_len0, (*destOfs))] = src[o7c_ind(src_len0, srcOfs)];
			(*destOfs) = o7c_add((*destOfs), 1);
			srcOfs = o7c_add(srcOfs, 1);
		}
	}
	dest[o7c_ind(dest_len0, (*destOfs))] = 0x00u;
	return o7c_bl(ret);
}

/*	копирование содержимого строки, не включая завершающего 0 в поток вывода
	TODO учесть возможность ошибки при записи */
extern int StringStore_Write(struct VDataStream_Out *out, o7c_tag_t out_tag, struct StringStore_String *str, o7c_tag_t str_tag) {
	int i = O7C_INT_UNDEF, len = O7C_INT_UNDEF, ofs = O7C_INT_UNDEF;
	struct StringStore_Block_s *block = NULL;

	block = (*str).block;
	i = (*str).ofs;
	ofs = i;
	len = 0;
	while (1) if (block->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == 0x0Cu) {
		len = o7c_add(len, VDataStream_Write(&(*out), out_tag, block->s, StringStore_BlockSize_cnst + 1, ofs, o7c_sub(i, ofs)));
		block = block->next;
		ofs = 0;
		i = 0;
	} else if (block->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] != 0x00u) {
		i = o7c_add(i, 1);
	} else break;
	assert(block->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == 0x00u);
	len = VDataStream_Write(&(*out), out_tag, block->s, StringStore_BlockSize_cnst + 1, ofs, o7c_sub(i, ofs));
	return len;
}

extern void StringStore_init(void) {
	static int initialized = 0;
	if (0 == initialized) {
		Log_init();
		Utf8_init();
		V_init();
		VDataStream_init();

		o7c_tag_init(StringStore_Block_s_tag, V_Base_tag);
		o7c_tag_init(StringStore_String_tag, V_Base_tag);
		o7c_tag_init(StringStore_Iterator_tag, V_Base_tag);
		o7c_tag_init(StringStore_Store_tag, V_Base_tag);

	}
	++initialized;
}


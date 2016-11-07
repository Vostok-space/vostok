#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#include <o7c.h>

#include "StringStore.h"

o7c_tag_t StringStore_Block_s_tag;
o7c_tag_t StringStore_String_tag;
o7c_tag_t StringStore_Store_tag;

static void Put_AddBlock(struct StringStore_Block_s **b, int *i) {
	assert((*b)->next == NULL);
	(*i) = 0;
	(*b)->next = o7c_new(sizeof(*(*b)->next), StringStore_Block_s_tag);
	V_Init(&(*(*b)->next)._, NULL);
	(*b)->next->num = o7c_add((*b)->num, 1);
	(*b) = (*b)->next;
	(*b)->next = NULL;
}

extern void StringStore_Put(struct StringStore_Store *store, o7c_tag_t store_tag, struct StringStore_String *w, o7c_tag_t w_tag, o7c_char s[/*len0*/], int s_len0, int j, int end) {
	struct StringStore_Block_s *b = NULL;
	int i = O7C_INT_UNDEFINED;

	assert((end >= 0) && (end < o7c_sub(s_len0, 1)));
	b = (*store).last;
	i = (*store).ofs;
	(*w).block = b;
	(*w).ofs = i;
	while (j != end) {
		if (i == sizeof(b->s) / sizeof (b->s[0]) - 1) {
			if (i != (*w).ofs) {
				b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] = 0x0Cu;
				Put_AddBlock(&b, &i);
			} else {
				Put_AddBlock(&b, &i);
				(*w).block = b;
				(*w).ofs = 0;
			}
		}
		b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] = s[o7c_ind(s_len0, j)];
		i++;
		j = o7c_mod((o7c_add(j, 1)), (o7c_sub(s_len0, 1)));
	}
	b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] = 0x00u;
	if (i < sizeof(b->s) / sizeof (b->s[0]) - 1) {
		i++;
	} else {
		Put_AddBlock(&b, &i);
	}
	(*store).last = b;
	(*store).ofs = i;
}

extern bool StringStore_IsEqualToChars(struct StringStore_String *w, o7c_tag_t w_tag, o7c_char s[/*len0*/], int s_len0, int j, int end) {
	int i = O7C_INT_UNDEFINED;
	struct StringStore_Block_s *b = NULL;

	assert((end >= 0) && (end < o7c_sub(s_len0, 1)));
	i = (*w).ofs;
	b = (*w).block;
	while (1) if (b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == s[o7c_ind(s_len0, j)]) {
		i++;
		j = o7c_mod((o7c_add(j, 1)), (o7c_sub(s_len0, 1)));
	} else if (b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == 0x0Cu) {
		b = b->next;
		i = 0;
	} else break;
	return (b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == 0x00u) && (j == end);
}

extern bool StringStore_IsEqualToString(struct StringStore_String *w, o7c_tag_t w_tag, o7c_char s[/*len0*/], int s_len0) {
	int i = O7C_INT_UNDEFINED, j = O7C_INT_UNDEFINED;
	struct StringStore_Block_s *b = NULL;

	j = 0;
	i = (*w).ofs;
	b = (*w).block;
	while (1) if ((b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == s[o7c_ind(s_len0, j)]) && (s[o7c_ind(s_len0, j)] != 0x00u)) {
		i++;
		j++;
	} else if (b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == 0x0Cu) {
		b = b->next;
		i = 0;
	} else break;
	return b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == s[o7c_ind(s_len0, j)];
}

extern void StringStore_CopyToChars(o7c_char d[/*len0*/], int d_len0, int *dofs, struct StringStore_String *w, o7c_tag_t w_tag) {
	struct StringStore_Block_s *b = NULL;
	int i = O7C_INT_UNDEFINED;

	b = (*w).block;
	i = (*w).ofs;
	while (1) if (b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] > 0x0Cu) {
		d[o7c_ind(d_len0, (*dofs))] = b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)];
		(*dofs)++;
		i++;
	} else if (b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] != 0x00u) {
		assert(b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == 0x0Cu);
		b = b->next;
		i = 0;
	} else break;
	d[o7c_ind(d_len0, (*dofs))] = 0x00u;
}

extern void StringStore_StoreInit(struct StringStore_Store *s, o7c_tag_t s_tag) {
	V_Init(&(*s)._, s_tag);
	(*s).first = o7c_new(sizeof(*(*s).first), StringStore_Block_s_tag);
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

extern bool StringStore_CopyChars(o7c_char dest[/*len0*/], int dest_len0, int *destOfs, o7c_char src[/*len0*/], int src_len0, int srcOfs, int srcEnd) {
	bool ret = 0 > 1;

	assert(((*destOfs) >= 0) && (srcOfs >= 0) && (srcEnd >= srcOfs) && (srcEnd <= src_len0));
	ret = o7c_sub(o7c_add((*destOfs), srcEnd), srcOfs) < o7c_sub(dest_len0, 1);
	if (ret) {
		while (srcOfs < srcEnd) {
			dest[o7c_ind(dest_len0, (*destOfs))] = src[o7c_ind(src_len0, srcOfs)];
			(*destOfs)++;
			srcOfs++;
		}
	}
	dest[o7c_ind(dest_len0, (*destOfs))] = 0x00u;
	return ret;
}

extern int StringStore_Write(struct VDataStream_Out *out, o7c_tag_t out_tag, struct StringStore_String *str, o7c_tag_t str_tag) {
	int i = O7C_INT_UNDEFINED, len = O7C_INT_UNDEFINED;
	struct StringStore_Block_s *block = NULL;

	block = (*str).block;
	i = (*str).ofs;
	len = 0;
	while (1) if (block->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] > 0x0Cu) {
		i++;
	} else if (block->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == 0x0Cu) {
		assert(len == 0);
		assert(i > (*str).ofs);
		len = o7c_add(len, VDataStream_Write(&(*out), out_tag, block->s, StringStore_BlockSize_cnst + 1, (*str).ofs, o7c_sub(i, (*str).ofs)));
		block = block->next;
		i = 0;
	} else break;
	assert(block->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == 0x00u);
	if (len == 0) {
		len = VDataStream_Write(&(*out), out_tag, block->s, StringStore_BlockSize_cnst + 1, (*str).ofs, o7c_sub(i, (*str).ofs));
	} else {
		len = o7c_add(len, VDataStream_Write(&(*out), out_tag, block->s, StringStore_BlockSize_cnst + 1, 0, i));
	}
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
		o7c_tag_init(StringStore_Store_tag, V_Base_tag);

	}
	++initialized;
}


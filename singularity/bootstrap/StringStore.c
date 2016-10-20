#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#include <o7c.h>

#include "StringStore.h"

int StringStore_Block_s_tag[15];

int StringStore_String_tag[15];

int StringStore_Store_tag[15];


static void Put_AddBlock(struct StringStore_Block_s **b, int *b_tag, int *i) {
	assert((*b)->next == NULL);
	(*i) = 0;
	(*b)->next = o7c_new(sizeof(*(*b)->next), StringStore_Block_s_tag);
	V_Init(&(*(*b)->next)._, NULL);
	(*b)->next->num = (*b)->num + 1;
	(*b) = (*b)->next;
	(*b)->next = NULL;
}

extern void StringStore_Put(struct StringStore_Store *store, int *store_tag, struct StringStore_String *w, int *w_tag, char unsigned s[/*len0*/], int s_len0, int j, int end) {
	struct StringStore_Block_s *b;
	int i;

	assert((end >= 0) && (end < s_len0 - 1));
	b = (*store).last;
	i = (*store).ofs;
	(*w).block = b;
	(*w).ofs = i;
	while (j != end) {
		if (i == sizeof(b->s) / sizeof (b->s[0]) - 1) {
			if (i != (*w).ofs) {
				b->s[i] = 0x0Cu;
				Put_AddBlock(&b, NULL, &i);
			} else {
				Put_AddBlock(&b, NULL, &i);
				(*w).block = b;
				(*w).ofs = 0;
			}
		}
		b->s[i] = s[j];
		i++;
		j = (j + 1) % (s_len0 - 1);
	}
	b->s[i] = 0x00u;
	if (i < sizeof(b->s) / sizeof (b->s[0]) - 1) {
		i++;
	} else {
		Put_AddBlock(&b, NULL, &i);
	}
	(*store).last = b;
	(*store).ofs = i;
}

extern bool StringStore_IsEqualToChars(struct StringStore_String *w, int *w_tag, char unsigned s[/*len0*/], int s_len0, int j, int end) {
	int i;
	struct StringStore_Block_s *b;

	assert((end >= 0) && (end < s_len0 - 1));
	i = (*w).ofs;
	b = (*w).block;
	while (1) if (b->s[i] == s[j]) {
		i++;
		j = (j + 1) % (s_len0 - 1);
	} else if (b->s[i] == 0x0Cu) {
		b = b->next;
		i = 0;
	} else break;
	return (b->s[i] == 0x00u) && (j == end);
}

extern bool StringStore_IsEqualToString(struct StringStore_String *w, int *w_tag, char unsigned s[/*len0*/], int s_len0) {
	int i;
	int j;
	struct StringStore_Block_s *b;

	j = 0;
	i = (*w).ofs;
	b = (*w).block;
	while (1) if ((b->s[i] == s[j]) && (s[j] != 0x00u)) {
		i++;
		j++;
	} else if (b->s[i] == 0x0Cu) {
		b = b->next;
		i = 0;
	} else break;
	return b->s[i] == s[j];
}

extern void StringStore_CopyToChars(char unsigned d[/*len0*/], int d_len0, int *dofs, struct StringStore_String *w, int *w_tag) {
	struct StringStore_Block_s *b;
	int i;

	b = (*w).block;
	i = (*w).ofs;
	while (1) if (b->s[i] > 0x0Cu) {
		d[(*dofs)] = b->s[i];
		(*dofs)++;
		i++;
	} else if (b->s[i] != 0x00u) {
		assert(b->s[i] == 0x0Cu);
		b = b->next;
		i = 0;
	} else break;
	d[(*dofs)] = 0x00u;
}

extern void StringStore_StoreInit(struct StringStore_Store *s, int *s_tag) {
	V_Init(&(*s)._, s_tag);
	(*s).first = o7c_new(sizeof(*(*s).first), StringStore_Block_s_tag);
	(*s).last = (*s).first;
	(*s).last->next = NULL;
	(*s).ofs = 0;
}

extern void StringStore_StoreDone(struct StringStore_Store *s, int *s_tag) {
	while ((*s).first != NULL) {
		(*s).first = (*s).first->next;
	}
	(*s).last = NULL;
}

extern bool StringStore_CopyChars(char unsigned dest[/*len0*/], int dest_len0, int *destOfs, char unsigned src[/*len0*/], int src_len0, int srcOfs, int srcEnd) {
	bool ret;

	assert(((*destOfs) >= 0) && (srcOfs >= 0) && (srcEnd >= srcOfs) && (srcEnd <= src_len0));
	ret = (*destOfs) + srcEnd - srcOfs < dest_len0 - 1;
	if (ret) {
		while (srcOfs < srcEnd) {
			dest[(*destOfs)] = src[srcOfs];
			(*destOfs)++;
			srcOfs++;
		}
	}
	dest[(*destOfs)] = 0x00u;
	return ret;
}

extern int StringStore_Write(struct VDataStream_Out *out, int *out_tag, struct StringStore_String *str, int *str_tag) {
	int i;
	int len;
	struct StringStore_Block_s *block;

	block = (*str).block;
	i = (*str).ofs;
	len = 0;
	while (1) if (block->s[i] > 0x0Cu) {
		i++;
	} else if (block->s[i] == 0x0Cu) {
		assert(len == 0);
		assert(i > (*str).ofs);
		len = len + VDataStream_Write(&(*out), out_tag, block->s, StringStore_BlockSize_cnst + 1, (*str).ofs, i - (*str).ofs);
		block = block->next;
		i = 0;
	} else break;
	assert(block->s[i] == 0x00u);
	if (len == 0) {
		len = VDataStream_Write(&(*out), out_tag, block->s, StringStore_BlockSize_cnst + 1, (*str).ofs, i - (*str).ofs);
	} else {
		len = len + VDataStream_Write(&(*out), out_tag, block->s, StringStore_BlockSize_cnst + 1, 0, i);
	}
	return len;
}

extern void StringStore_init_(void) {
	static int initialized__ = 0;
	if (0 == initialized__) {
		Log_init_();
		Utf8_init_();
		V_init_();
		VDataStream_init_();

		o7c_tag_init(StringStore_Block_s_tag, V_Base_tag);
		o7c_tag_init(StringStore_String_tag, V_Base_tag);
		o7c_tag_init(StringStore_Store_tag, V_Base_tag);

	}
	++initialized__;
}


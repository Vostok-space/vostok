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
o7c_tag_t StringStore_Store_tag;

static void LogLoopStr(o7c_char s[/*len0*/], int s_len0, int j, int end) {
	while (o7c_cmp(j, end) !=  0) {
		Log_Char(s[o7c_ind(s_len0, j)]);
		j = o7c_mod((o7c_add(j, 1)), (o7c_sub(s_len0, 1)));
	}
}

static void Put_AddBlock(struct StringStore_Block_s **b, int *i) {
	assert((*b)->next == NULL);
	(*i) = 0;
	(*b)->next = o7c_new(sizeof(*(*b)->next), StringStore_Block_s_tag);
	V_Init(&(*(*b)->next)._, NULL);
	(*b)->next->num = o7c_add((*b)->num, 1);
	O7C_ASSIGN(&((*b)), (*b)->next);
	O7C_ASSIGN(&((*b)->next), NULL);
}

extern void StringStore_Put(struct StringStore_Store *store, o7c_tag_t store_tag, struct StringStore_String *w, o7c_tag_t w_tag, o7c_char s[/*len0*/], int s_len0, int j, int end) {
	struct StringStore_Block_s *b = NULL;
	int i = O7C_INT_UNDEF;

	assert((s_len0 % 2 == 1));
	assert((o7c_cmp(j, 0) >=  0) && (o7c_cmp(j, o7c_sub(s_len0, 1)) <  0));
	assert((o7c_cmp(end, 0) >=  0) && (o7c_cmp(end, o7c_sub(s_len0, 1)) <  0));
	O7C_ASSIGN(&(b), (*store).last);
	i = (*store).ofs;
	O7C_ASSIGN(&((*w).block), b);
	(*w).ofs = i;
	while (o7c_cmp(j, end) !=  0) {
		if (o7c_cmp(i, sizeof(b->s) / sizeof (b->s[0]) - 1) ==  0) {
			assert(o7c_cmp(i, (*w).ofs) !=  0);
			b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] = 0x0Cu;
			Put_AddBlock(&b, &i);
		}
		b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] = s[o7c_ind(s_len0, j)];
		assert(s[o7c_ind(s_len0, j)] != 0x0Cu);
		i = o7c_add(i, 1);;
		j = o7c_mod((o7c_add(j, 1)), (o7c_sub(s_len0, 1)));
	}
	b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] = 0x00u;
	if (o7c_cmp(i, sizeof(b->s) / sizeof (b->s[0]) - 2) <  0) {
		i = o7c_add(i, 1);;
	} else {
		Put_AddBlock(&b, &i);
	}
	O7C_ASSIGN(&((*store).last), b);
	(*store).ofs = i;
	o7c_release(b);
}

extern o7c_bool StringStore_IsEqualToChars(struct StringStore_String *w, o7c_tag_t w_tag, o7c_char s[/*len0*/], int s_len0, int j, int end) {
	o7c_bool o7c_return;

	int i = O7C_INT_UNDEF;
	struct StringStore_Block_s *b = NULL;

	assert((s_len0 % 2 == 1));
	assert((o7c_cmp(j, 0) >=  0) && (o7c_cmp(j, o7c_sub(s_len0, 1)) <  0));
	assert((o7c_cmp(end, 0) >=  0) && (o7c_cmp(end, o7c_sub(s_len0, 1)) <  0));
	i = (*w).ofs;
	O7C_ASSIGN(&(b), (*w).block);
	while (1) if (b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == s[o7c_ind(s_len0, j)]) {
		i = o7c_add(i, 1);;
		j = o7c_mod((o7c_add(j, 1)), (o7c_sub(s_len0, 1)));
	} else if (b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == 0x0Cu) {
		O7C_ASSIGN(&(b), b->next);
		i = 0;
	} else break;
	o7c_return = (b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == 0x00u) && (o7c_cmp(j, end) ==  0);
	o7c_release(b);
	return o7c_return;
}

extern o7c_bool StringStore_IsEqualToString(struct StringStore_String *w, o7c_tag_t w_tag, o7c_char s[/*len0*/], int s_len0) {
	o7c_bool o7c_return;

	int i = O7C_INT_UNDEF, j = O7C_INT_UNDEF;
	struct StringStore_Block_s *b = NULL;

	j = 0;
	i = (*w).ofs;
	O7C_ASSIGN(&(b), (*w).block);
	while (1) if ((b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == s[o7c_ind(s_len0, j)]) && (s[o7c_ind(s_len0, j)] != 0x00u)) {
		i = o7c_add(i, 1);;
		j = o7c_add(j, 1);;
	} else if (b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == 0x0Cu) {
		O7C_ASSIGN(&(b), b->next);
		i = 0;
	} else break;
	o7c_return = b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == s[o7c_ind(s_len0, j)];
	o7c_release(b);
	return o7c_return;
}

extern void StringStore_CopyToChars(o7c_char d[/*len0*/], int d_len0, int *dofs, struct StringStore_String *w, o7c_tag_t w_tag) {
	struct StringStore_Block_s *b = NULL;
	int i = O7C_INT_UNDEF;

	O7C_ASSIGN(&(b), (*w).block);
	i = (*w).ofs;
	while (1) if (b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] > 0x0Cu) {
		d[o7c_ind(d_len0, (*dofs))] = b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)];
		(*dofs) = o7c_add((*dofs), 1);;
		i = o7c_add(i, 1);;
	} else if (b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] != 0x00u) {
		assert(b->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == 0x0Cu);
		O7C_ASSIGN(&(b), b->next);
		i = 0;
	} else break;
	d[o7c_ind(d_len0, (*dofs))] = 0x00u;
	o7c_release(b);
}

extern void StringStore_StoreInit(struct StringStore_Store *s, o7c_tag_t s_tag) {
	V_Init(&(*s)._, s_tag);
	(*s).first = o7c_new(sizeof(*(*s).first), StringStore_Block_s_tag);
	V_Init(&(*(*s).first)._, NULL);
	(*s).first->num = 0;
	O7C_ASSIGN(&((*s).last), (*s).first);
	O7C_ASSIGN(&((*s).last->next), NULL);
	(*s).ofs = 0;
}

extern void StringStore_StoreDone(struct StringStore_Store *s, o7c_tag_t s_tag) {
	while ((*s).first != NULL) {
		O7C_ASSIGN(&((*s).first), (*s).first->next);
	}
	O7C_ASSIGN(&((*s).last), NULL);
}

extern o7c_bool StringStore_CopyChars(o7c_char dest[/*len0*/], int dest_len0, int *destOfs, o7c_char src[/*len0*/], int src_len0, int srcOfs, int srcEnd) {
	o7c_bool o7c_return;

	o7c_bool ret = O7C_BOOL_UNDEF;

	assert((o7c_cmp((*destOfs), 0) >=  0) && (o7c_cmp(srcOfs, 0) >=  0) && (o7c_cmp(srcEnd, srcOfs) >=  0) && (o7c_cmp(srcEnd, src_len0) <=  0));
	ret = o7c_cmp(o7c_sub(o7c_add((*destOfs), srcEnd), srcOfs), o7c_sub(dest_len0, 1)) <  0;
	if (ret) {
		while (o7c_cmp(srcOfs, srcEnd) <  0) {
			dest[o7c_ind(dest_len0, (*destOfs))] = src[o7c_ind(src_len0, srcOfs)];
			(*destOfs) = o7c_add((*destOfs), 1);;
			srcOfs = o7c_add(srcOfs, 1);;
		}
	}
	dest[o7c_ind(dest_len0, (*destOfs))] = 0x00u;
	o7c_return = o7c_bl(ret);
	return o7c_return;
}

extern int StringStore_Write(struct VDataStream_Out *out, o7c_tag_t out_tag, struct StringStore_String *str, o7c_tag_t str_tag) {
	int o7c_return;

	int i = O7C_INT_UNDEF, len = O7C_INT_UNDEF;
	struct StringStore_Block_s *block = NULL;

	O7C_ASSIGN(&(block), (*str).block);
	i = (*str).ofs;
	len = 0;
	while (1) if (block->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] > 0x0Cu) {
		i = o7c_add(i, 1);;
	} else if (block->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == 0x0Cu) {
		assert(o7c_cmp(len, 0) ==  0);
		assert(o7c_cmp(i, (*str).ofs) >  0);
		len = o7c_add(len, VDataStream_Write(&(*out), out_tag, block->s, StringStore_BlockSize_cnst + 1, (*str).ofs, o7c_sub(i, (*str).ofs)));
		O7C_ASSIGN(&(block), block->next);
		i = 0;
	} else break;
	assert(block->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == 0x00u);
	if (o7c_cmp(len, 0) ==  0) {
		len = VDataStream_Write(&(*out), out_tag, block->s, StringStore_BlockSize_cnst + 1, (*str).ofs, o7c_sub(i, (*str).ofs));
	} else {
		len = o7c_add(len, VDataStream_Write(&(*out), out_tag, block->s, StringStore_BlockSize_cnst + 1, 0, i));
	}
	o7c_return = len;
	o7c_release(block);
	return o7c_return;
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


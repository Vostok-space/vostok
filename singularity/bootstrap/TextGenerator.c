#define O7_BOOL_UNDEFINED
#include <o7.h>

#include "TextGenerator.h"

#define TextGenerator_Out_tag V_Base_tag
extern void TextGenerator_Out_undef(struct TextGenerator_Out *r) {
	V_Base_undef(&r->_);
	r->out = NULL;
	r->len = O7_INT_UNDEF;
	r->tabs = O7_INT_UNDEF;
	r->isNewLine = O7_BOOL_UNDEF;
}

extern void TextGenerator_Init(struct TextGenerator_Out *g, struct VDataStream_Out *out) {
	O7_ASSERT(out != NULL);

	V_Init(&(*g)._);
	(*g).tabs = 0;
	(*g).out = out;
	(*g).len = 0;
	(*g).isNewLine = (0 > 1);
}

extern void TextGenerator_SetTabs(struct TextGenerator_Out *g, struct TextGenerator_Out *d) {
	(*g).tabs = o7_int((*d).tabs);
}

extern o7_int_t TextGenerator_CalcLen(o7_int_t str_len0, o7_char str[/*len0*/], o7_int_t ofs) {
	o7_int_t i;

	i = ofs;
	while ((i < str_len0) && (str[o7_ind(str_len0, i)] != 0x00u)) {
		i = o7_add(i, 1);
	}
	return o7_sub(i, ofs);
}

static void CharFill(struct TextGenerator_Out *gen, o7_char ch, o7_int_t count) {
	o7_char c[1];
	memset(&c, 0, sizeof(c));

	O7_ASSERT(0 <= count);
	c[0] = ch;
	while (o7_cmp(count, 0) > 0) {
		(*gen).len = o7_add((*gen).len, VDataStream_WriteChars(&(*O7_REF((*gen).out)), NULL, 1, c, 0, 1));
		count = o7_sub(count, 1);
	}
}

extern void TextGenerator_Char(struct TextGenerator_Out *gen, o7_char ch) {
	o7_char c[1];
	memset(&c, 0, sizeof(c));

	c[0] = ch;
	(*gen).len = o7_add((*gen).len, VDataStream_WriteChars(&(*O7_REF((*gen).out)), NULL, 1, c, 0, 1));
}

static void NewLine(struct TextGenerator_Out *gen) {
	if (o7_bl((*gen).isNewLine)) {
		(*gen).isNewLine = (0 > 1);
		CharFill(&(*gen), 0x09u, (*gen).tabs);
	}
}

extern void TextGenerator_Str(struct TextGenerator_Out *gen, o7_int_t str_len0, o7_char str[/*len0*/]) {
	NewLine(&(*gen));
	(*gen).len = o7_add((*gen).len, VDataStream_WriteChars(&(*O7_REF((*gen).out)), NULL, str_len0, str, 0, TextGenerator_CalcLen(str_len0, str, 0)));
}

extern void TextGenerator_StrLn(struct TextGenerator_Out *gen, o7_int_t str_len0, o7_char str[/*len0*/]) {
	NewLine(&(*gen));
	(*gen).len = o7_add((*gen).len, VDataStream_WriteChars(&(*O7_REF((*gen).out)), NULL, str_len0, str, 0, TextGenerator_CalcLen(str_len0, str, 0)));
	(*gen).len = o7_add((*gen).len, VDataStream_WriteChars(&(*O7_REF((*gen).out)), NULL, 1, (o7_char *)"\x0A", 0, 1));
	(*gen).isNewLine = (0 < 1);
}

extern void TextGenerator_Ln(struct TextGenerator_Out *gen) {
	(*gen).len = o7_add((*gen).len, VDataStream_WriteChars(&(*O7_REF((*gen).out)), NULL, 1, (o7_char *)"\x0A", 0, 1));
	(*gen).isNewLine = (0 < 1);
}

extern void TextGenerator_StrOpen(struct TextGenerator_Out *gen, o7_int_t str_len0, o7_char str[/*len0*/]) {
	TextGenerator_StrLn(&(*gen), str_len0, str);
	(*gen).tabs = o7_add((*gen).tabs, 1);
}

extern void TextGenerator_IndentOpen(struct TextGenerator_Out *gen) {
	(*gen).tabs = o7_add((*gen).tabs, 1);
}

extern void TextGenerator_IndentClose(struct TextGenerator_Out *gen) {
	O7_ASSERT(o7_cmp(0, (*gen).tabs) < 0);
	(*gen).tabs = o7_sub((*gen).tabs, 1);
}

extern void TextGenerator_StrClose(struct TextGenerator_Out *gen, o7_int_t str_len0, o7_char str[/*len0*/]) {
	TextGenerator_IndentClose(&(*gen));
	TextGenerator_Str(&(*gen), str_len0, str);
}

extern void TextGenerator_StrLnClose(struct TextGenerator_Out *gen, o7_int_t str_len0, o7_char str[/*len0*/]) {
	TextGenerator_IndentClose(&(*gen));
	TextGenerator_StrLn(&(*gen), str_len0, str);
}

extern void TextGenerator_StrIgnoreIndent(struct TextGenerator_Out *gen, o7_int_t str_len0, o7_char str[/*len0*/]) {
	(*gen).len = o7_add((*gen).len, VDataStream_WriteChars(&(*O7_REF((*gen).out)), NULL, str_len0, str, 0, TextGenerator_CalcLen(str_len0, str, 0)));
}

extern void TextGenerator_String(struct TextGenerator_Out *gen, struct StringStore_String *word) {
	NewLine(&(*gen));
	(*gen).len = o7_add((*gen).len, StringStore_Write(&(*O7_REF((*gen).out)), NULL, &(*word)));
}

extern void TextGenerator_Data(struct TextGenerator_Out *g, o7_int_t data_len0, o7_char data[/*len0*/], o7_int_t ofs, o7_int_t count) {
	NewLine(&(*g));
	(*g).len = o7_add((*g).len, VDataStream_WriteChars(&(*O7_REF((*g).out)), NULL, data_len0, data, ofs, count));
}

extern void TextGenerator_ScreeningString(struct TextGenerator_Out *gen, struct StringStore_String *str) {
	o7_int_t i, last;
	struct StringStore_RBlock *block;

	NewLine(&(*gen));
	block = (*str).block;
	i = o7_int((*str).ofs);
	last = i;
	O7_ASSERT(O7_REF(block)->s[o7_ind(StringStore_BlockSize_cnst + 1, i)] == (o7_char)'"');
	i = o7_add(i, 1);
	while (1) if (O7_REF(block)->s[o7_ind(StringStore_BlockSize_cnst + 1, i)] == 0x0Cu) {
		(*gen).len = o7_add((*gen).len, VDataStream_WriteChars(&(*O7_REF((*gen).out)), NULL, StringStore_BlockSize_cnst + 1, O7_REF(block)->s, last, o7_sub(i, last)));
		block = O7_REF(block)->next;
		i = 0;
		last = 0;
	} else if (O7_REF(block)->s[o7_ind(StringStore_BlockSize_cnst + 1, i)] == (o7_char)'\\') {
		(*gen).len = o7_add((*gen).len, VDataStream_WriteChars(&(*O7_REF((*gen).out)), NULL, StringStore_BlockSize_cnst + 1, O7_REF(block)->s, last, o7_add(o7_sub(i, last), 1)));
		(*gen).len = o7_add((*gen).len, VDataStream_WriteChars(&(*O7_REF((*gen).out)), NULL, 1, (o7_char *)"\x5C", 0, 1));
		i = o7_add(i, 1);
		last = o7_int(i);
	} else if (O7_REF(block)->s[o7_ind(StringStore_BlockSize_cnst + 1, i)] != 0x00u) {
		i = o7_add(i, 1);
	} else break;
	O7_ASSERT(O7_REF(block)->s[o7_ind(StringStore_BlockSize_cnst + 1, i)] == 0x00u);
	(*gen).len = o7_add((*gen).len, VDataStream_WriteChars(&(*O7_REF((*gen).out)), NULL, StringStore_BlockSize_cnst + 1, O7_REF(block)->s, last, o7_sub(i, last)));
}

extern void TextGenerator_Int(struct TextGenerator_Out *gen, o7_int_t int_) {
	o7_char buf[14];
	o7_int_t i;
	o7_bool sign;
	memset(&buf, 0, sizeof(buf));

	NewLine(&(*gen));
	sign = int_ < 0;
	if (sign) {
		int_ = o7_sub(0, int_);
	}
	i = O7_LEN(buf);
	do {
		i = o7_sub(i, 1);
		buf[o7_ind(14, i)] = o7_chr(o7_add((o7_int_t)(o7_char)'0', o7_mod(int_, 10)));
		int_ = o7_div(int_, 10);
	} while (!(o7_cmp(int_, 0) == 0));
	if (o7_bl(sign)) {
		i = o7_sub(i, 1);
		buf[o7_ind(14, i)] = (o7_char)'-';
	}
	(*gen).len = o7_add((*gen).len, VDataStream_WriteChars(&(*O7_REF((*gen).out)), NULL, 14, buf, i, o7_sub(O7_LEN(buf), i)));
}

extern void TextGenerator_Real(struct TextGenerator_Out *gen, double real) {
	NewLine(&(*gen));
	TextGenerator_Str(&(*gen), 20, (o7_char *)"Real not implemented");
}

extern void TextGenerator_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		StringStore_init();
		VDataStream_init();
	}
	++initialized;
}

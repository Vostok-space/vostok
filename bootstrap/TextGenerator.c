#if !defined(O7_INIT_MODEL)
#   define   O7_INIT_MODEL O7_INIT_ZERO
#endif

#include <o7.h>

#include "TextGenerator.h"

#define TextGenerator_Out_tag V_Base_tag

extern void TextGenerator_Init(struct TextGenerator_Out *g, struct VDataStream_Out *out) {
	O7_ASSERT(out != NULL);

	V_Init(&(*g)._);
	g->tabs = 0;
	g->out = out;
	g->len = 0;
	g->isNewLine = (0 > 1);
	g->defered[0] = 0x00u;
}

extern void TextGenerator_SetTabs(struct TextGenerator_Out *g, struct TextGenerator_Out *d) {
	g->tabs = d->tabs;
}

static void Write(struct TextGenerator_Out *gen, o7_int_t str_len0, o7_char str[/*len0*/], o7_int_t ofs, o7_int_t size) {
	gen->len = o7_add(gen->len, VDataStream_WriteChars(&(*gen->out), NULL, str_len0, str, ofs, size));
}

extern void TextGenerator_CharFill(struct TextGenerator_Out *gen, o7_char ch, o7_int_t count) {
	o7_char c[1];
	memset(&c, 0, sizeof(c));

	O7_ASSERT(0 <= count);
	c[0] = ch;
	while (count > 0) {
		Write(gen, 1, c, 0, 1);
		count = o7_sub(count, 1);
	}
}

static void IndentInNewLine(struct TextGenerator_Out *gen) {
	if (gen->isNewLine) {
		gen->isNewLine = (0 > 1);
		TextGenerator_CharFill(gen, 0x09u, gen->tabs);
	}
}

extern void TextGenerator_Char(struct TextGenerator_Out *gen, o7_char ch) {
	o7_char c[1];
	memset(&c, 0, sizeof(c));

	IndentInNewLine(gen);
	c[0] = ch;
	Write(gen, 1, c, 0, 1);
}

extern void TextGenerator_DeferChar(struct TextGenerator_Out *gen, o7_char ch) {
	O7_ASSERT(ch != 0x00u);
	O7_ASSERT(gen->defered[0] == 0x00u);

	gen->defered[0] = ch;
}

extern void TextGenerator_CancelDeferedOrWriteChar(struct TextGenerator_Out *gen, o7_char ch) {
	if (gen->defered[0] == 0x00u) {
		TextGenerator_Char(gen, ch);
	} else {
		gen->defered[0] = 0x00u;
	}
}

static void NewLine(struct TextGenerator_Out *gen) {
	IndentInNewLine(gen);
	if (gen->defered[0] != 0x00u) {
		Write(gen, 1, gen->defered, 0, 1);
		gen->defered[0] = 0x00u;
	}
}

extern void TextGenerator_Str(struct TextGenerator_Out *gen, o7_int_t str_len0, o7_char str[/*len0*/]) {
	NewLine(gen);
	Write(gen, str_len0, str, 0, Chars0X_CalcLen(str_len0, str, 0));
}

extern void TextGenerator_StrLn(struct TextGenerator_Out *gen, o7_int_t str_len0, o7_char str[/*len0*/]) {
	NewLine(gen);
	Write(gen, str_len0, str, 0, Chars0X_CalcLen(str_len0, str, 0));
	Write(gen, 2, (o7_char *)"\x0A", 0, 1);
	gen->isNewLine = (0 < 1);
}

extern void TextGenerator_Ln(struct TextGenerator_Out *gen) {
	Write(gen, 2, (o7_char *)"\x0A", 0, 1);
	gen->isNewLine = (0 < 1);
}

extern void TextGenerator_StrOpen(struct TextGenerator_Out *gen, o7_int_t str_len0, o7_char str[/*len0*/]) {
	TextGenerator_StrLn(gen, str_len0, str);
	gen->tabs = o7_add(gen->tabs, 1);
}

extern void TextGenerator_IndentOpen(struct TextGenerator_Out *gen) {
	gen->tabs = o7_add(gen->tabs, 1);
}

extern void TextGenerator_IndentClose(struct TextGenerator_Out *gen) {
	O7_ASSERT(0 < gen->tabs);
	gen->tabs = o7_sub(gen->tabs, 1);
}

extern void TextGenerator_StrClose(struct TextGenerator_Out *gen, o7_int_t str_len0, o7_char str[/*len0*/]) {
	TextGenerator_IndentClose(gen);
	TextGenerator_Str(gen, str_len0, str);
}

extern void TextGenerator_StrLnClose(struct TextGenerator_Out *gen, o7_int_t str_len0, o7_char str[/*len0*/]) {
	TextGenerator_IndentClose(gen);
	TextGenerator_StrLn(gen, str_len0, str);
}

extern void TextGenerator_LnStrClose(struct TextGenerator_Out *gen, o7_int_t str_len0, o7_char str[/*len0*/]) {
	TextGenerator_Ln(gen);
	TextGenerator_IndentClose(gen);
	TextGenerator_Str(gen, str_len0, str);
}

extern void TextGenerator_StrIgnoreIndent(struct TextGenerator_Out *gen, o7_int_t str_len0, o7_char str[/*len0*/]) {
	Write(gen, str_len0, str, 0, Chars0X_CalcLen(str_len0, str, 0));
}

extern void TextGenerator_String(struct TextGenerator_Out *gen, struct StringStore_String *word) {
	NewLine(gen);
	gen->len = o7_add(gen->len, StringStore_Write(&(*gen->out), NULL, word));
}

extern void TextGenerator_Data(struct TextGenerator_Out *gen, o7_int_t data_len0, o7_char data[/*len0*/], o7_int_t ofs, o7_int_t count) {
	NewLine(gen);
	Write(gen, data_len0, data, ofs, count);
}

extern void TextGenerator_ScreeningString(struct TextGenerator_Out *gen, struct StringStore_String *str) {
	o7_int_t i, last;
	struct StringStore_RBlock *block;

	NewLine(gen);
	block = str->block;
	i = str->ofs;
	last = i;
	O7_ASSERT(block->s[o7_ind(StringStore_BlockSize_cnst + 1, i)] == (o7_char)'"');
	i = o7_add(i, 1);
	while (1) if (block->s[o7_ind(StringStore_BlockSize_cnst + 1, i)] == 0x0Cu) {
		Write(gen, StringStore_BlockSize_cnst + 1, block->s, last, o7_sub(i, last));
		block = block->next;
		i = 0;
		last = 0;
	} else if (block->s[o7_ind(StringStore_BlockSize_cnst + 1, i)] == (o7_char)'\\') {
		Write(gen, StringStore_BlockSize_cnst + 1, block->s, last, o7_add(o7_sub(i, last), 1));
		Write(gen, 2, (o7_char *)"\x5C", 0, 1);
		i = o7_add(i, 1);
		last = i;
	} else if (block->s[o7_ind(StringStore_BlockSize_cnst + 1, i)] != 0x00u) {
		i = o7_add(i, 1);
	} else break;
	O7_ASSERT(block->s[o7_ind(StringStore_BlockSize_cnst + 1, i)] == 0x00u);
	Write(gen, StringStore_BlockSize_cnst + 1, block->s, last, o7_sub(i, last));
}

extern void TextGenerator_Int(struct TextGenerator_Out *gen, o7_int_t int_) {
	o7_char buf[14];
	o7_int_t i;
	o7_bool sign;
	memset(&buf, 0, sizeof(buf));

	NewLine(gen);
	sign = int_ < 0;
	if (sign) {
		int_ = o7_sub(0, int_);
	}
	i = O7_LEN(buf);
	do {
		i = o7_sub(i, 1);
		buf[o7_ind(14, i)] = o7_chr(o7_add(((o7_int_t)(o7_char)'0'), o7_mod(int_, 10)));
		int_ = o7_div(int_, 10);
	} while (!(int_ == 0));
	if (sign) {
		i = o7_sub(i, 1);
		buf[o7_ind(14, i)] = (o7_char)'-';
	}
	Write(gen, 14, buf, i, o7_sub(O7_LEN(buf), i));
}

extern void TextGenerator_Real(struct TextGenerator_Out *gen, double real) {
	NewLine(gen);
	TextGenerator_Str(gen, 21, (o7_char *)"Real not implemented");
}

extern void TextGenerator_HexSeparateHighBit(struct TextGenerator_Out *gen, o7_int_t v, o7_bool highBit) {
	o7_char buf[8];
	o7_int_t i;
	memset(&buf, 0, sizeof(buf));

	O7_ASSERT(v >= 0);

	i = O7_LEN(buf) - 1;
	buf[o7_ind(8, i)] = Hex_To(o7_mod(v, 16));
	v = o7_add(o7_div(v, 16), o7_mul((o7_int_t)highBit, 134217728));
	while (v != 0) {
		i = o7_sub(i, 1);
		buf[o7_ind(8, i)] = Hex_To(o7_mod(v, 16));
		v = o7_div(v, 16);
	}
	Write(gen, 8, buf, i, o7_sub(O7_LEN(buf), i));
}

extern void TextGenerator_Hex(struct TextGenerator_Out *gen, o7_int_t v) {
	if (v < 0) {
		TextGenerator_HexSeparateHighBit(gen, o7_add(o7_add(v, TypesLimits_IntegerMax_cnst), 1), (0 < 1));
	} else {
		TextGenerator_HexSeparateHighBit(gen, v, (0 > 1));
	}
}

extern void TextGenerator_Set(struct TextGenerator_Out *gen, o7_set_t *set) {
	TextGenerator_HexSeparateHighBit(gen, o7_sti(*set & ~(1u << TypesLimits_SetMax_cnst)), !!( (1u << TypesLimits_SetMax_cnst) & *set));
}

extern void TextGenerator_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		StringStore_init();
		VDataStream_init();
	}
	++initialized;
}

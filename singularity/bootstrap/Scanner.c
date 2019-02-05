#define O7_BOOL_UNDEFINED
#include <o7.h>

#include "Scanner.h"

#define NewPage_cnst 0x0Cu

#define IntMax_cnst 2147483647
#define CharMax_cnst 0xFFu
#define RealScaleMax_cnst 512

#define Scanner_Scanner_tag V_Base_tag
extern void Scanner_Scanner_undef(struct Scanner_Scanner *r) {
	V_Base_undef(&r->_);
	r->in_ = NULL;
	r->line = O7_INT_UNDEF;
	r->column = O7_INT_UNDEF;
	memset(&r->buf, 0, sizeof(r->buf));
	r->ind = O7_INT_UNDEF;
	r->lexStart = O7_INT_UNDEF;
	r->lexEnd = O7_INT_UNDEF;
	r->emptyLines = O7_INT_UNDEF;
	r->isReal = O7_BOOL_UNDEF;
	r->isChar = O7_BOOL_UNDEF;
	r->integer = O7_INT_UNDEF;
	r->real = O7_DBL_UNDEF;
	memset(&r->opt, 0, sizeof(r->opt));
	r->commentOfs = O7_INT_UNDEF;
	r->commentEnd = O7_INT_UNDEF;
}

typedef o7_bool (*Suit)(o7_char ch);
typedef o7_int_t (*SuitDigit)(o7_char ch);

static void PreInit(struct Scanner_Scanner *s) {
	V_Init(&(*s)._);
	(*s).column = 0;
	(*s).line = 0;
	(*s).commentOfs =  - 1;
	(*s).opt.cyrillic = (0 > 1);
	(*s).opt.tabSize = 8;
}

extern void Scanner_Init(struct Scanner_Scanner *s, struct VDataStream_In *in_) {
	O7_ASSERT(in_ != NULL);
	PreInit(&(*s));
	(*s).in_ = in_;
	(*s).ind = O7_LEN((*s).buf) - 1;
	(*s).buf[0] = 0x0Cu;
	(*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] = 0x0Cu;
}

extern o7_bool Scanner_InitByString(struct Scanner_Scanner *s, o7_int_t in__len0, o7_char in_[/*len0*/]) {
	o7_int_t len;
	o7_bool ret;

	PreInit(&(*s));
	(*s).in_ = NULL;
	(*s).ind = 0;
	(*s).buf[0] = (o7_char)' ';

	len = 1;
	ret = StringStore_CopyCharsNull(Scanner_BlockSize_cnst * 2 + 1, (*s).buf, &len, in__len0, in_);
	(*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, len)] = 0x04u;
	return ret;
}

static void FillBuf(o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t *ind, struct VDataStream_In *in_, o7_tag_t *in__tag);
static void FillBuf_Normalize(o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t i, o7_int_t end) {
	while (i < end) {
		if ((buf[o7_ind(buf_len0, i)] == 0x0Cu) || (buf[o7_ind(buf_len0, i)] == 0x04u)) {
			buf[o7_ind(buf_len0, i)] = 0x16u;
		}
		i = o7_add(i, 1);
	}
}

static void FillBuf(o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t *ind, struct VDataStream_In *in_, o7_tag_t *in__tag) {
	o7_int_t size;

	O7_ASSERT((buf_len0 % 2 == 1));
	if (o7_mod((*ind), (o7_div(buf_len0, 2))) != 0) {
		Log_StrLn(77, (o7_char *)"индекс новой страницы в неожиданном месте");
		O7_ASSERT(buf[o7_ind(buf_len0, (*ind))] == 0x0Cu);
		buf[o7_ind(buf_len0, (*ind))] = 0x00u;
	} else {
		(*ind) = o7_mod((*ind), (o7_sub(buf_len0, 1)));
		if (buf[o7_ind(buf_len0, (*ind))] == 0x0Cu) {
			size = VDataStream_ReadChars(&(*in_), in__tag, buf_len0, buf, (*ind), o7_div(buf_len0, 2));
			FillBuf_Normalize(buf_len0, buf, (*ind), o7_add((*ind), size));
			if (o7_cmp(size, o7_div(buf_len0, 2)) == 0) {
				buf[o7_ind(buf_len0, o7_mod((o7_add((*ind), o7_div(buf_len0, 2))), (o7_sub(buf_len0, 1))))] = 0x0Cu;
			} else {
				buf[o7_ind(buf_len0, o7_add((*ind), size))] = 0x04u;
			}
		}
	}
}

static o7_char Lookup(struct Scanner_Scanner *s, o7_int_t i) {
	i = o7_add(i, 1);
	if ((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x0Cu) {
		FillBuf(Scanner_BlockSize_cnst * 2 + 1, (*s).buf, &i, &(*O7_REF((*s).in_)), NULL);
	}
	return (*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)];
}

static void ScanChars(struct Scanner_Scanner *s, Suit suit) {
	while (1) if (suit((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)])) {
		(*s).ind = o7_add((*s).ind, 1);
		(*s).column = o7_add((*s).column, 1);
	} else if (((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] == 0x0Cu) && ((*s).in_ != NULL)) {
		FillBuf(Scanner_BlockSize_cnst * 2 + 1, (*s).buf, &(*s).ind, &(*O7_REF((*s).in_)), NULL);
	} else break;
}

static o7_bool IsDigit(o7_char ch) {
	return ((o7_char)'0' <= ch) && (ch <= (o7_char)'9');
}

static o7_bool IsHexDigit(o7_char ch) {
	return ((o7_char)'0' <= ch) && (ch <= (o7_char)'9') || ((o7_char)'A' <= ch) && (ch <= (o7_char)'F');
}

static o7_int_t ValDigit(o7_char ch) {
	o7_int_t i;

	if ((ch >= (o7_char)'0') && (ch <= (o7_char)'9')) {
		i = o7_sub((o7_int_t)ch, (o7_int_t)(o7_char)'0');
	} else {
		i =  - 1;
	}
	return i;
}

static o7_int_t ValHexDigit(o7_char ch) {
	o7_int_t i;

	if ((ch >= (o7_char)'0') && (ch <= (o7_char)'9')) {
		i = o7_sub((o7_int_t)ch, (o7_int_t)(o7_char)'0');
	} else if ((ch >= (o7_char)'A') && (ch <= (o7_char)'F')) {
		i = o7_sub(o7_add(10, (o7_int_t)ch), (o7_int_t)(o7_char)'A');
	} else {
		i =  - 1;
	}
	return i;
}

static o7_int_t SNumber(struct Scanner_Scanner *s);
static void SNumber_Val(struct Scanner_Scanner *s, o7_int_t *lex, o7_int_t capacity, SuitDigit valDigit) {
	o7_int_t d, val, i;

	val = 0;
	i = o7_int((*s).lexStart);
	d = valDigit((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
	while (1) if (d >= 0) {
		if (o7_div(IntMax_cnst, capacity) >= val) {
			val = o7_mul(val, capacity);
			if (o7_cmp(o7_sub(IntMax_cnst, d), val) >= 0) {
				val = o7_add(val, d);
			} else {
				(*lex) = Scanner_ErrNumberTooBig_cnst;
			}
		} else {
			(*lex) = Scanner_ErrNumberTooBig_cnst;
		}
		i = o7_add(i, 1);
		d = valDigit((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
	} else if ((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x0Cu) {
		i = 0;
		d = valDigit((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
	} else break;
	(*s).integer = o7_int(val);
}

static void SNumber_ValReal(struct Scanner_Scanner *s, o7_int_t *lex) {
	o7_int_t i, d, scale;
	o7_bool scMinus;
	double val, t;

	val = 1.0;
	i = o7_int((*s).lexStart);
	d = ValDigit((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
	while (1) if (d >= 0) {
		val = o7_fadd(o7_fmul(val, 10.0), o7_flt(d));
		i = o7_add(i, 1);
		d = ValDigit((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
	} else if ((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x0Cu) {
		i = 0;
		d = ValDigit((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
	} else break;
	i = o7_add(i, 1);
	t = 10.0;
	d = ValDigit((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
	while (1) if (o7_cmp(d, 0) >= 0) {
		(*s).column = o7_add((*s).column, 1);
		val = o7_fadd(val, o7_fdiv(o7_flt(d), t));
		t = o7_fmul(t, 10.0);
		i = o7_add(i, 1);
		d = ValDigit((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
	} else if ((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x0Cu) {
		FillBuf(Scanner_BlockSize_cnst * 2 + 1, (*s).buf, &i, &(*O7_REF((*s).in_)), NULL);
		d = ValDigit((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
	} else break;
	if ((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == (o7_char)'E') {
		i = o7_add(i, 1);
		(*s).column = o7_add((*s).column, 1);
		if ((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x0Cu) {
			FillBuf(Scanner_BlockSize_cnst * 2 + 1, (*s).buf, &i, &(*O7_REF((*s).in_)), NULL);
		}
		scMinus = (*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == (o7_char)'-';
		if (scMinus || ((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == (o7_char)'+')) {
			i = o7_add(i, 1);
			(*s).column = o7_add((*s).column, 1);
			if ((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x0Cu) {
				FillBuf(Scanner_BlockSize_cnst * 2 + 1, (*s).buf, &i, &(*O7_REF((*s).in_)), NULL);
			}
		}
		d = ValDigit((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
		if (d >= 0) {
			scale = 0;
			while (1) if (d >= 0) {
				(*s).column = o7_add((*s).column, 1);
				if (scale < IntMax_cnst / 10) {
					scale = o7_add(o7_mul(scale, 10), d);
				}
				i = o7_add(i, 1);
				d = ValDigit((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
			} else if ((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x0Cu) {
				FillBuf(Scanner_BlockSize_cnst * 2 + 1, (*s).buf, &i, &(*O7_REF((*s).in_)), NULL);
				d = ValDigit((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
			} else break;
			if (o7_cmp(scale, RealScaleMax_cnst) <= 0) {
				while (scale > 0) {
					if (scMinus) {
						val = o7_fmul(val, 10.0);
					} else {
						val = o7_fdiv(val, 10.0);
					}
					scale = o7_sub(scale, 1);
				}
			} else {
				(*lex) = Scanner_ErrRealScaleTooBig_cnst;
			}
		} else {
			(*lex) = Scanner_ErrExpectDigitInScale_cnst;
		}
	}
	(*s).ind = o7_int(i);
	(*s).real = o7_dbl(val);
}

static o7_int_t SNumber(struct Scanner_Scanner *s) {
	o7_int_t lex;
	o7_char ch;

	lex = Scanner_Number_cnst;
	ScanChars(&(*s), IsDigit);
	ch = (*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)];
	(*s).isReal = (ch == (o7_char)'.') && (Lookup(&(*s), (*s).ind) != (o7_char)'.');
	if (o7_bl((*s).isReal)) {
		(*s).ind = o7_add((*s).ind, 1);
		(*s).column = o7_add((*s).column, 1);
		SNumber_ValReal(&(*s), &lex);
	} else if ((ch >= (o7_char)'A') && (ch <= (o7_char)'F') || (ch == (o7_char)'H') || (ch == (o7_char)'X')) {
		ScanChars(&(*s), IsHexDigit);
		ch = (*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)];
		SNumber_Val(&(*s), &lex, 16, ValHexDigit);
		if (ch == (o7_char)'X') {
			if (o7_cmp((*s).integer, (o7_int_t)0xFFu) <= 0) {
				lex = Scanner_String_cnst;
				(*s).isChar = (0 < 1);
			} else {
				lex = Scanner_ErrNumberTooBig_cnst;
			}
		} else if (ch != (o7_char)'H') {
			lex = Scanner_ErrExpectHOrX_cnst;
		}
		if ((ch == (o7_char)'X') || (ch == (o7_char)'H')) {
			(*s).column = o7_add((*s).column, 1);
			(*s).ind = o7_add((*s).ind, 1);
		}
	} else {
		SNumber_Val(&(*s), &lex, 10, ValDigit);
	}
	Log_Str(13, (o7_char *)"Number lex = ");
	Log_Int(lex);
	Log_Ln();
	return o7_int(lex);
}

static o7_bool IsLetterOrDigit(o7_char ch) {
	return (ch >= (o7_char)'A') && (ch <= (o7_char)'Z') || (ch >= (o7_char)'a') && (ch <= (o7_char)'z') || (ch >= (o7_char)'0') && (ch <= (o7_char)'9');
}

static o7_int_t SWord(struct Scanner_Scanner *s) {
	o7_int_t len, l;

	ScanChars(&(*s), IsLetterOrDigit);
	len = o7_add(o7_sub((*s).ind, (*s).lexStart), o7_mul((o7_int_t)(o7_cmp((*s).ind, (*s).lexStart) < 0), (O7_LEN((*s).buf) - 1)));
	O7_ASSERT(0 < len);
	if (o7_cmp(len, TranslatorLimits_LenName_cnst) <= 0) {
		l = Scanner_Ident_cnst;
	} else {
		l = Scanner_ErrWordLenTooBig_cnst;
	}
	return l;
}

static o7_bool IsCurrentCyrillic(struct Scanner_Scanner *s);
static o7_bool IsCurrentCyrillic_ForD0(o7_char c) {
	return (0x90u <= c) && (c <= 0xBFu) || (c == 0x81u) || (c == 0x84u) || (c == 0x86u) || (c == 0x87u) || (c == 0x8Eu);
}

static o7_bool IsCurrentCyrillic_ForD1(o7_char c) {
	return (0x80u <= c) && (c <= 0x8Fu) || (c == 0x91u) || (c == 0x94u) || (c == 0x96u) || (c == 0x97u) || (c == 0x9Eu);
}

static o7_bool IsCurrentCyrillic_ForD2(o7_char c) {
	return (c == 0x90u) || (c == 0x91u);
}

static o7_bool IsCurrentCyrillic(struct Scanner_Scanner *s) {
	o7_bool ret;

	{ o7_int_t o7_case_expr = (*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)];
		switch (o7_case_expr) {
		case 208:
			ret = IsCurrentCyrillic_ForD0(Lookup(&(*s), (*s).ind));
			break;
		case 209:
			ret = IsCurrentCyrillic_ForD1(Lookup(&(*s), (*s).ind));
			break;
		case 210:
			ret = IsCurrentCyrillic_ForD2(Lookup(&(*s), (*s).ind));
			break;
		default:
			if ((0 <= o7_case_expr && o7_case_expr <= 207) || (211 <= o7_case_expr && o7_case_expr <= 255)) {
				ret = (0 > 1);
			} else o7_case_fail(o7_case_expr);
			break;
		}
	}
	return ret;
}

static o7_int_t CyrWord(struct Scanner_Scanner *s) {
	o7_int_t len, l;

	while (1) if (IsCurrentCyrillic(&(*s))) {
		(*s).ind = o7_mod((o7_add((*s).ind, 2)), (O7_LEN((*s).buf) - 1));
		(*s).column = o7_add((*s).column, 1);
	} else if (((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] == 0x0Cu) && ((*s).in_ != NULL)) {
		FillBuf(Scanner_BlockSize_cnst * 2 + 1, (*s).buf, &(*s).ind, &(*O7_REF((*s).in_)), NULL);
	} else break;
	len = o7_add(o7_sub((*s).ind, (*s).lexStart), o7_mul((o7_int_t)(o7_cmp((*s).ind, (*s).lexStart) < 0), (O7_LEN((*s).buf) - 1)));
	O7_ASSERT(0 < len);
	if (o7_cmp(len, TranslatorLimits_LenName_cnst) <= 0) {
		l = Scanner_Ident_cnst;
	} else {
		l = Scanner_ErrWordLenTooBig_cnst;
	}
	return l;
}

static o7_bool ScanBlank(struct Scanner_Scanner *s) {
	o7_int_t i, column, comment, commentsCount;

	i = o7_int((*s).ind);
	O7_ASSERT(0 <= i);
	column = o7_int((*s).column);
	comment = 0;
	commentsCount = 0;
	(*s).emptyLines =  - 1;
	while (1) if ((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == (o7_char)' ') {
		i = o7_add(i, 1);
		column = o7_add(column, 1);
	} else if ((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x0Du) {
		i = o7_add(i, 1);
		column = 0;
	} else if ((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x09u) {
		i = o7_add(i, 1);
		column = o7_mul(o7_div((o7_add(column, (*s).opt.tabSize)), (*s).opt.tabSize), (*s).opt.tabSize);
	} else if ((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x0Au) {
		(*s).line = o7_add((*s).line, 1);
		(*s).emptyLines = o7_add((*s).emptyLines, 1);
		column = 0;
		i = o7_add(i, 1);
	} else if ((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x0Cu) {
		FillBuf(Scanner_BlockSize_cnst * 2 + 1, (*s).buf, &i, &(*O7_REF((*s).in_)), NULL);
	} else if (((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == (o7_char)'(') && (Lookup(&(*s), i) == (o7_char)'*')) {
		i = o7_mod((o7_add(i, 2)), (O7_LEN((*s).buf) - 1));
		column = o7_add(column, 2);
		comment = o7_add(comment, 1);
		commentsCount = o7_add(commentsCount, 1);
		if (o7_cmp(commentsCount, 1) == 0) {
			(*s).commentOfs = i;
		}
	} else if ((o7_cmp(0, comment) < 0) && ((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] != 0x00u)) {
		if (((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == (o7_char)'*') && (Lookup(&(*s), i) == (o7_char)')')) {
			comment = o7_sub(comment, 1);
			if (o7_cmp(comment, 0) == 0) {
				(*s).commentEnd = i;
				(*s).emptyLines =  - 1;
			}
			i = o7_mod((o7_add(i, 2)), (O7_LEN((*s).buf) - 1));
			column = o7_add(column, 2);
		} else {
			if (((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] < 0x80u) || (0xC0u <= (*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)])) {
				column = o7_add(column, 1);
			}
			i = o7_add(i, 1);
		}
	} else if ((0xEFu == (*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)]) && (0xBBu == Lookup(&(*s), i)) && (0xBFu == Lookup(&(*s), o7_mod((o7_add(i, 1)), (O7_LEN((*s).buf) - 1))))) {
		i = o7_mod((o7_add(i, 3)), (O7_LEN((*s).buf) - 1));
	} else break;

	(*s).column = o7_int(column);
	(*s).ind = o7_int(i);
	return o7_cmp(comment, 0) <= 0;
}

static o7_int_t ScanString(struct Scanner_Scanner *s) {
	o7_int_t l, i, j, count, column;

	i = o7_add((*s).ind, 1);
	column = o7_add((*s).column, 1);
	if ((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x0Cu) {
		FillBuf(Scanner_BlockSize_cnst * 2 + 1, (*s).buf, &i, &(*O7_REF((*s).in_)), NULL);
	}
	j = o7_int(i);
	count = 0;
	while (1) if (((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] != (o7_char)'"') && (((o7_char)' ' <= (*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)]) || ((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x09u))) {
		if (((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] < 0x80u) || ((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] >= 0xC0u)) {
			column = o7_add(column, 1);
			count = o7_add(count, 1);
		}
		i = o7_add(i, 1);
	} else if ((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x0Cu) {
		FillBuf(Scanner_BlockSize_cnst * 2 + 1, (*s).buf, &i, &(*O7_REF((*s).in_)), NULL);
	} else break;
	(*s).isChar = (0 > 1);
	if ((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == (o7_char)'"') {
		l = Scanner_String_cnst;
		if (count == 1) {
			(*s).isChar = (0 < 1);
			(*s).integer = (o7_int_t)(*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, j)];
		}
	} else {
		l = Scanner_ErrExpectDQuote_cnst;
	}
	(*s).ind = o7_add(i, 1);
	(*s).column = column;
	return l;
}

static void Next_L(o7_int_t *lex, struct Scanner_Scanner *s, o7_int_t l) {
	(*s).ind = o7_add((*s).ind, 1);
	(*lex) = l;
}

static void Next_Li(o7_int_t *lex, struct Scanner_Scanner *s, o7_char ch, o7_int_t then, o7_int_t else_) {
	(*s).ind = o7_add((*s).ind, 1);
	if ((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] == 0x0Cu) {
		FillBuf(Scanner_BlockSize_cnst * 2 + 1, (*s).buf, &(*s).ind, &(*O7_REF((*s).in_)), NULL);
	}
	if ((*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] == ch) {
		(*lex) = then;
		(*s).ind = o7_add((*s).ind, 1);
	} else {
		(*lex) = else_;
	}
}

extern o7_int_t Scanner_Next(struct Scanner_Scanner *s) {
	o7_int_t lex;

	if (!ScanBlank(&(*s))) {
		lex = Scanner_ErrUnclosedComment_cnst;
	} else {
		(*s).lexStart = o7_int((*s).ind);
		{ o7_int_t o7_case_expr = (*s).buf[o7_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)];
			switch (o7_case_expr) {
			case 4:
				lex = Scanner_EndOfFile_cnst;
				break;
			case 43:
				Next_L(&lex, &(*s), Scanner_Plus_cnst);
				break;
			case 45:
				Next_L(&lex, &(*s), Scanner_Minus_cnst);
				break;
			case 42:
				Next_L(&lex, &(*s), Scanner_Asterisk_cnst);
				break;
			case 47:
				Next_L(&lex, &(*s), Scanner_Slash_cnst);
				break;
			case 46:
				Next_Li(&lex, &(*s), (o7_char)'.', Scanner_Range_cnst, Scanner_Dot_cnst);
				break;
			case 44:
				Next_L(&lex, &(*s), Scanner_Comma_cnst);
				break;
			case 58:
				Next_Li(&lex, &(*s), (o7_char)'=', Scanner_Assign_cnst, Scanner_Colon_cnst);
				break;
			case 59:
				Next_L(&lex, &(*s), Scanner_Semicolon_cnst);
				break;
			case 94:
				Next_L(&lex, &(*s), Scanner_Dereference_cnst);
				break;
			case 61:
				Next_L(&lex, &(*s), Scanner_Equal_cnst);
				break;
			case 35:
				Next_L(&lex, &(*s), Scanner_Inequal_cnst);
				break;
			case 126:
				Next_L(&lex, &(*s), Scanner_Negate_cnst);
				break;
			case 60:
				Next_Li(&lex, &(*s), (o7_char)'=', Scanner_LessEqual_cnst, Scanner_Less_cnst);
				break;
			case 62:
				Next_Li(&lex, &(*s), (o7_char)'=', Scanner_GreaterEqual_cnst, Scanner_Greater_cnst);
				break;
			case 38:
				Next_L(&lex, &(*s), Scanner_And_cnst);
				break;
			case 124:
				Next_L(&lex, &(*s), Scanner_Alternative_cnst);
				break;
			case 40:
				Next_L(&lex, &(*s), Scanner_Brace1Open_cnst);
				break;
			case 41:
				Next_L(&lex, &(*s), Scanner_Brace1Close_cnst);
				break;
			case 91:
				Next_L(&lex, &(*s), Scanner_Brace2Open_cnst);
				break;
			case 93:
				Next_L(&lex, &(*s), Scanner_Brace2Close_cnst);
				break;
			case 123:
				Next_L(&lex, &(*s), Scanner_Brace3Open_cnst);
				break;
			case 125:
				Next_L(&lex, &(*s), Scanner_Brace3Close_cnst);
				break;
			case 34:
				lex = ScanString(&(*s));
				break;
			default:
				if ((0 <= o7_case_expr && o7_case_expr <= 3) || (5 <= o7_case_expr && o7_case_expr <= 33) || (o7_case_expr == 36) || (o7_case_expr == 37) || (o7_case_expr == 39) || (o7_case_expr == 63) || (o7_case_expr == 64) || (o7_case_expr == 92) || (o7_case_expr == 95) || (o7_case_expr == 96) || (127 <= o7_case_expr && o7_case_expr <= 207) || (211 <= o7_case_expr && o7_case_expr <= 255)) {
					lex = Scanner_ErrUnexpectChar_cnst;
					(*s).ind = o7_add((*s).ind, 1);
				} else if ((48 <= o7_case_expr && o7_case_expr <= 57)) {
					lex = SNumber(&(*s));
				} else if ((97 <= o7_case_expr && o7_case_expr <= 122) || (65 <= o7_case_expr && o7_case_expr <= 90)) {
					lex = SWord(&(*s));
				} else if ((208 <= o7_case_expr && o7_case_expr <= 210)) {
					if (o7_bl((*s).opt.cyrillic) && IsCurrentCyrillic(&(*s))) {
						lex = CyrWord(&(*s));
					} else {
						lex = Scanner_ErrUnexpectChar_cnst;
					}
				} else o7_case_fail(o7_case_expr);
				break;
			}
		}
		(*s).lexEnd = o7_int((*s).ind);
	}
	return o7_int(lex);
}

extern o7_bool Scanner_TakeCommentPos(struct Scanner_Scanner *s, o7_int_t *ofs, o7_int_t *end) {
	o7_bool ret;

	ret = o7_cmp((*s).commentOfs, 0) >= 0;
	if (ret) {
		(*ofs) = o7_int((*s).commentOfs);
		(*end) = o7_int((*s).commentEnd);
		(*s).commentOfs =  - 1;
	}
	return o7_bl(ret);
}

extern void Scanner_ResetComment(struct Scanner_Scanner *s) {
	(*s).commentOfs =  - 1;
}

extern void Scanner_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		VDataStream_init();
		StringStore_init();
		Log_init();

		O7_STATIC_ASSERT(TranslatorLimits_LenName_cnst < Scanner_BlockSize_cnst);
	}
	++initialized;
}

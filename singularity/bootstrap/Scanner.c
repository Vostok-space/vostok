#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#define O7C_BOOL_UNDEFINED
#include <o7c.h>

#include "Scanner.h"

#define NewPage_cnst "\x0C"
#define IntMax_cnst 2147483647
#define CharMax_cnst "\xFF"
#define RealScaleMax_cnst 512

o7c_tag_t Scanner_Scanner_tag;
typedef o7c_bool (*Suit)(o7c_char ch);
typedef int (*SuitDigit)(o7c_char ch);

extern void Scanner_Init(struct Scanner_Scanner *s, o7c_tag_t s_tag, struct VDataStream_In *in_) {
	o7c_retain(in_);
	assert(in_ != NULL);
	V_Init(&(*s)._, s_tag);
	(*s).column = 0;
	(*s).tabs = 0;
	(*s).line = 0;
	O7C_ASSIGN(&((*s).in_), in_);
	(*s).ind = sizeof((*s).buf) / sizeof ((*s).buf[0]) - 1;
	(*s).buf[0] = 0x0Cu;
	(*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] = 0x0Cu;
	o7c_release(in_);
}

static void FillBuf(o7c_char buf[/*len0*/], int buf_len0, int *ind, struct VDataStream_In *in_, o7c_tag_t in__tag) {
	int size = O7C_INT_UNDEF;

	assert((buf_len0 % 2 == 1));
	if (o7c_cmp(o7c_mod((*ind), (o7c_div(buf_len0, 2))), 0) !=  0) {
		Log_StrLn("индекс новой страницы в неожиданном месте", 78);
		assert(buf[o7c_ind(buf_len0, (*ind))] == 0x0Cu);
		buf[o7c_ind(buf_len0, (*ind))] = 0x00u;
	} else {
		(*ind) = o7c_mod((*ind), (o7c_sub(buf_len0, 1)));
		if (buf[o7c_ind(buf_len0, (*ind))] == 0x0Cu) {
			size = VDataStream_Read(&(*in_), in__tag, buf, buf_len0, (*ind), o7c_div(buf_len0, 2));
			if (buf[o7c_ind(buf_len0, (*ind))] == 0x0Cu) {
				buf[o7c_ind(buf_len0, (*ind))] = 0x00u;
			} else if (o7c_cmp(size, o7c_div(buf_len0, 2)) ==  0) {
				buf[o7c_ind(buf_len0, o7c_mod((o7c_add((*ind), o7c_div(buf_len0, 2))), (o7c_sub(buf_len0, 1))))] = 0x0Cu;
			} else {
				buf[o7c_ind(buf_len0, o7c_add((*ind), size))] = 0x00u;
			}
		}
	}
}

static o7c_char ScanChar(struct Scanner_Scanner *s, o7c_tag_t s_tag) {
	o7c_char o7c_return;

	o7c_char ch = '\0';

	(*s).ind = o7c_add((*s).ind, 1);;
	ch = (*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)];
	if (ch == 0x0Cu) {
		FillBuf((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &(*s).ind, &(*(*s).in_), NULL);
		ch = (*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)];
	}
	o7c_return = ch;
	return o7c_return;
}

static void ScanChars(o7c_char buf[/*len0*/], int buf_len0, int *i, Suit suit, struct VDataStream_In *in_, o7c_tag_t in__tag) {
	while (1) if (suit(buf[o7c_ind(buf_len0, (*i))])) {
		(*i) = o7c_add((*i), 1);;
	} else if (buf[o7c_ind(buf_len0, (*i))] == 0x0Cu) {
		FillBuf(buf, buf_len0, &(*i), &(*in_), in__tag);
	} else break;
}

static o7c_bool IsDigit(o7c_char ch) {
	o7c_bool o7c_return;

	o7c_return = (ch >= (char unsigned)'0') && (ch <= (char unsigned)'9');
	return o7c_return;
}

static o7c_bool IsHexDigit(o7c_char ch) {
	o7c_bool o7c_return;

	o7c_return = (ch >= (char unsigned)'0') && (ch <= (char unsigned)'9') || (ch >= (char unsigned)'A') && (ch <= (char unsigned)'F');
	return o7c_return;
}

static int ValDigit(o7c_char ch) {
	int o7c_return;

	int i = O7C_INT_UNDEF;

	if ((ch >= (char unsigned)'0') && (ch <= (char unsigned)'9')) {
		i = o7c_sub((int)ch, (int)(char unsigned)'0');
	} else {
		i =  - 1;
	}
	o7c_return = i;
	return o7c_return;
}

static int ValHexDigit(o7c_char ch) {
	int o7c_return;

	int i = O7C_INT_UNDEF;

	if ((ch >= (char unsigned)'0') && (ch <= (char unsigned)'9')) {
		i = o7c_sub((int)ch, (int)(char unsigned)'0');
	} else if ((ch >= (char unsigned)'A') && (ch <= (char unsigned)'F')) {
		i = o7c_sub(o7c_add(10, (int)ch), (int)(char unsigned)'A');
	} else {
		i =  - 1;
	}
	o7c_return = i;
	return o7c_return;
}

static int SNumber(struct Scanner_Scanner *s, o7c_tag_t s_tag);
static void SNumber_Val(struct Scanner_Scanner *s, o7c_tag_t s_tag, int *lex, int capacity, SuitDigit valDigit) {
	int d = O7C_INT_UNDEF, val = O7C_INT_UNDEF, i = O7C_INT_UNDEF;

	val = 0;
	i = (*s).lexStart;
	d = valDigit((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
	while (1) if (o7c_cmp(d, 0) >=  0) {
		if (o7c_cmp(o7c_div(IntMax_cnst, capacity), val) >=  0) {
			val = o7c_mul(val, capacity);
			if (o7c_cmp(o7c_sub(IntMax_cnst, d), val) >=  0) {
				val = o7c_add(val, d);
			} else {
				(*lex) = Scanner_ErrNumberTooBig_cnst;
			}
		} else {
			(*lex) = Scanner_ErrNumberTooBig_cnst;
		}
		i = o7c_add(i, 1);;
		d = valDigit((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
	} else if ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x0Cu) {
		i = 0;
		d = valDigit((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
	} else break;
	(*s).integer = val;
}

static void SNumber_ValReal(struct Scanner_Scanner *s, o7c_tag_t s_tag, int *lex) {
	int i = O7C_INT_UNDEF, d = O7C_INT_UNDEF, scale = O7C_INT_UNDEF;
	o7c_bool scMinus = O7C_BOOL_UNDEF;
	double val = O7C_DBL_UNDEF, t = O7C_DBL_UNDEF;

	val = 1.0;
	i = (*s).lexStart;
	d = ValDigit((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
	while (1) if (o7c_cmp(d, 0) >=  0) {
		val = o7c_fadd(o7c_fmul(val, 10.0), (double)d);
		i = o7c_add(i, 1);;
		d = ValDigit((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
	} else if ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x0Cu) {
		i = 0;
		d = ValDigit((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
	} else break;
	i = o7c_add(i, 1);;
	t = 10.0;
	d = ValDigit((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
	while (1) if (o7c_cmp(d, 0) >=  0) {
		val = o7c_fadd(val, o7c_fdiv((double)d, t));
		t = o7c_fmul(t, 10.0);
		i = o7c_add(i, 1);;
		d = ValDigit((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
	} else if ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x0Cu) {
		FillBuf((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &i, &(*(*s).in_), NULL);
		d = ValDigit((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
	} else break;
	if ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == (char unsigned)'E') {
		i = o7c_add(i, 1);;
		if ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x0Cu) {
			FillBuf((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &i, &(*(*s).in_), NULL);
		}
		scMinus = (*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == (char unsigned)'-';
		if (o7c_bl(scMinus) || ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == (char unsigned)'+')) {
			i = o7c_add(i, 1);;
			if ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x0Cu) {
				FillBuf((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &i, &(*(*s).in_), NULL);
			}
		}
		d = ValDigit((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
		if (o7c_cmp(d, 0) >=  0) {
			scale = 0;
			while (1) if (o7c_cmp(d, 0) >=  0) {
				if (o7c_cmp(scale, IntMax_cnst / 10) <  0) {
					scale = o7c_add(o7c_mul(scale, 10), d);
				}
				i = o7c_add(i, 1);;
				d = ValDigit((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
			} else if ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x0Cu) {
				FillBuf((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &i, &(*(*s).in_), NULL);
				d = ValDigit((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)]);
			} else break;
			if (o7c_cmp(scale, RealScaleMax_cnst) <=  0) {
				while (o7c_cmp(scale, 0) >  0) {
					if (scMinus) {
						val = o7c_fmul(val, 10.0);
					} else {
						val = o7c_fdiv(val, 10.0);
					}
					scale = o7c_sub(scale, 1);;
				}
			} else {
				(*lex) = Scanner_ErrRealScaleTooBig_cnst;
			}
		} else {
			(*lex) = Scanner_ErrExpectDigitInScale_cnst;
		}
	}
	(*s).ind = i;
	(*s).real = val;
}

static int SNumber(struct Scanner_Scanner *s, o7c_tag_t s_tag) {
	int o7c_return;

	int lex = O7C_INT_UNDEF;
	o7c_char ch = '\0';

	lex = Scanner_Number_cnst;
	ScanChars((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &(*s).ind, IsDigit, &(*(*s).in_), NULL);
	ch = (*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)];
	(*s).isReal = ch == (char unsigned)'.';
	if ((*s).isReal) {
		(*s).ind = o7c_add((*s).ind, 1);;
		SNumber_ValReal(&(*s), s_tag, &lex);
	} else if ((ch >= (char unsigned)'A') && (ch <= (char unsigned)'F') || (ch == (char unsigned)'H') || (ch == (char unsigned)'X')) {
		ScanChars((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &(*s).ind, IsHexDigit, &(*(*s).in_), NULL);
		ch = (*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)];
		SNumber_Val(&(*s), s_tag, &lex, 16, ValHexDigit);
		if (ch == (char unsigned)'X') {
			if (o7c_cmp((*s).integer, (int)0xFFu) <=  0) {
				lex = Scanner_String_cnst;
				(*s).isChar = true;
			} else {
				lex = Scanner_ErrNumberTooBig_cnst;
			}
		} else if (ch != (char unsigned)'H') {
			lex = Scanner_ErrExpectHOrX_cnst;
		}
		if ((ch == (char unsigned)'X') || (ch == (char unsigned)'H')) {
			(*s).ind = o7c_add((*s).ind, 1);;
		}
	} else {
		SNumber_Val(&(*s), s_tag, &lex, 10, ValDigit);
	}
	Log_Str("Number lex = ", 14);
	Log_Int(lex);
	Log_Ln();
	o7c_return = lex;
	return o7c_return;
}

static o7c_bool IsWordEqual(o7c_char str[/*len0*/], int str_len0, o7c_char buf[/*len0*/], int buf_len0, int ind, int end) {
	o7c_bool o7c_return;

	int i = O7C_INT_UNDEF, j = O7C_INT_UNDEF;

	assert(o7c_cmp(str_len0, o7c_div(buf_len0, 2)) <=  0);
	j = 1;
	i = o7c_add(ind, 1);
	while (1) if (buf[o7c_ind(buf_len0, i)] == str[o7c_ind(str_len0, j)]) {
		i = o7c_add(i, 1);;
		j = o7c_add(j, 1);;
	} else if (buf[o7c_ind(buf_len0, i)] == 0x0Cu) {
		i = 0;
	} else break;
	o7c_return = (buf[o7c_ind(buf_len0, i)] == 0x08u) && (str[o7c_ind(str_len0, j)] == 0x00u);
	return o7c_return;
}

static o7c_bool CheckPredefined_Eq(o7c_char str[/*len0*/], int str_len0, o7c_char buf[/*len0*/], int buf_len0, int begin, int end) {
	o7c_bool o7c_return;

	o7c_return = IsWordEqual(str, str_len0, buf, buf_len0, begin, end);
	return o7c_return;
}

static int CheckPredefined_O(o7c_char str[/*len0*/], int str_len0, o7c_char buf[/*len0*/], int buf_len0, int begin, int end, int id) {
	int o7c_return;

	if (!IsWordEqual(str, str_len0, buf, buf_len0, begin, end)) {
		id = Scanner_Ident_cnst;
	}
	o7c_return = id;
	return o7c_return;
}

static int CheckPredefined_T(o7c_char s1[/*len0*/], int s1_len0, o7c_char buf[/*len0*/], int buf_len0, int begin, int end, int id1, o7c_char s2[/*len0*/], int s2_len0, int id2) {
	int o7c_return;

	if (IsWordEqual(s1, s1_len0, buf, buf_len0, begin, end)) {
		id2 = id1;
	} else if (!IsWordEqual(s2, s2_len0, buf, buf_len0, begin, end)) {
		id2 = Scanner_Ident_cnst;
	}
	o7c_return = id2;
	return o7c_return;
}

extern int Scanner_CheckPredefined(o7c_char buf[/*len0*/], int buf_len0, int begin, int end) {
	int o7c_return;

	int id = O7C_INT_UNDEF;
	o7c_char save = '\0';

	save = buf[o7c_ind(buf_len0, end)];
	buf[o7c_ind(buf_len0, end)] = 0x08u;
	switch (buf[o7c_ind(buf_len0, begin)]) {
	case 65:
		if (CheckPredefined_Eq("ABS", 4, buf, buf_len0, begin, end)) {
			id = Scanner_Abs_cnst;
		} else {
			id = CheckPredefined_T("ASR", 4, buf, buf_len0, begin, end, Scanner_Asr_cnst, "ASSERT", 7, Scanner_Assert_cnst);
		}
		break;
	case 66:
		id = CheckPredefined_T("BOOLEAN", 8, buf, buf_len0, begin, end, Scanner_Boolean_cnst, "BYTE", 5, Scanner_Byte_cnst);
		break;
	case 67:
		id = CheckPredefined_T("CHAR", 5, buf, buf_len0, begin, end, Scanner_Char_cnst, "CHR", 4, Scanner_Chr_cnst);
		break;
	case 68:
		id = CheckPredefined_O("DEC", 4, buf, buf_len0, begin, end, Scanner_Dec_cnst);
		break;
	case 69:
		id = CheckPredefined_O("EXCL", 5, buf, buf_len0, begin, end, Scanner_Excl_cnst);
		break;
	case 70:
		id = CheckPredefined_T("FLOOR", 6, buf, buf_len0, begin, end, Scanner_Floor_cnst, "FLT", 4, Scanner_Flt_cnst);
		break;
	case 73:
		if (CheckPredefined_Eq("INC", 4, buf, buf_len0, begin, end)) {
			id = Scanner_Inc_cnst;
		} else {
			id = CheckPredefined_T("INCL", 5, buf, buf_len0, begin, end, Scanner_Incl_cnst, "INTEGER", 8, Scanner_Integer_cnst);
		}
		break;
	case 76:
		id = CheckPredefined_T("LEN", 4, buf, buf_len0, begin, end, Scanner_Len_cnst, "LSL", 4, Scanner_Lsl_cnst);
		break;
	case 78:
		id = CheckPredefined_O("NEW", 4, buf, buf_len0, begin, end, Scanner_New_cnst);
		break;
	case 79:
		id = CheckPredefined_T("ODD", 4, buf, buf_len0, begin, end, Scanner_Odd_cnst, "ORD", 4, Scanner_Ord_cnst);
		break;
	case 80:
		id = CheckPredefined_O("PACK", 5, buf, buf_len0, begin, end, Scanner_Pack_cnst);
		break;
	case 82:
		id = CheckPredefined_T("REAL", 5, buf, buf_len0, begin, end, Scanner_Real_cnst, "ROR", 4, Scanner_Ror_cnst);
		break;
	case 83:
		id = CheckPredefined_O("SET", 4, buf, buf_len0, begin, end, Scanner_Set_cnst);
		break;
	case 85:
		id = CheckPredefined_O("UNPK", 5, buf, buf_len0, begin, end, Scanner_Unpk_cnst);
		break;
	default:
		if ((buf[o7c_ind(buf_len0, begin)] == 71) || (buf[o7c_ind(buf_len0, begin)] == 72) || (buf[o7c_ind(buf_len0, begin)] == 74) || (buf[o7c_ind(buf_len0, begin)] == 75) || (buf[o7c_ind(buf_len0, begin)] == 77) || (buf[o7c_ind(buf_len0, begin)] == 84) || (86 <= buf[o7c_ind(buf_len0, begin)] && buf[o7c_ind(buf_len0, begin)] <= 90) || (97 <= buf[o7c_ind(buf_len0, begin)] && buf[o7c_ind(buf_len0, begin)] <= 122)) {
			id = Scanner_Ident_cnst;
		} else abort();
		break;
	}
	buf[o7c_ind(buf_len0, end)] = save;
	o7c_return = id;
	return o7c_return;
}

static int CheckWord(o7c_char buf[/*len0*/], int buf_len0, int ind, int end);
static o7c_bool CheckWord_Eq(o7c_char str[/*len0*/], int str_len0, o7c_char buf[/*len0*/], int buf_len0, int ind, int end) {
	o7c_bool o7c_return;

	o7c_return = IsWordEqual(str, str_len0, buf, buf_len0, ind, end);
	return o7c_return;
}

static void CheckWord_O(int *lex, o7c_char str[/*len0*/], int str_len0, o7c_char buf[/*len0*/], int buf_len0, int ind, int end, int l) {
	if (IsWordEqual(str, str_len0, buf, buf_len0, ind, end)) {
		(*lex) = l;
	} else {
		(*lex) = Scanner_Ident_cnst;
	}
}

static void CheckWord_T(int *lex, o7c_char s1[/*len0*/], int s1_len0, int l1, o7c_char s2[/*len0*/], int s2_len0, int l2, o7c_char buf[/*len0*/], int buf_len0, int ind, int end) {
	if (IsWordEqual(s1, s1_len0, buf, buf_len0, ind, end)) {
		(*lex) = l1;
	} else if (IsWordEqual(s2, s2_len0, buf, buf_len0, ind, end)) {
		(*lex) = l2;
	} else {
		(*lex) = Scanner_Ident_cnst;
	}
}

static int CheckWord(o7c_char buf[/*len0*/], int buf_len0, int ind, int end) {
	int o7c_return;

	int lex = O7C_INT_UNDEF;
	o7c_char save = '\0';

	save = buf[o7c_ind(buf_len0, end)];
	buf[o7c_ind(buf_len0, end)] = 0x08u;
	switch (buf[o7c_ind(buf_len0, ind)]) {
	case 65:
		CheckWord_O(&lex, "ARRAY", 6, buf, buf_len0, ind, end, Scanner_Array_cnst);
		break;
	case 66:
		CheckWord_T(&lex, "BEGIN", 6, Scanner_Begin_cnst, "BY", 3, Scanner_By_cnst, buf, buf_len0, ind, end);
		break;
	case 67:
		CheckWord_T(&lex, "CASE", 5, Scanner_Case_cnst, "CONST", 6, Scanner_Const_cnst, buf, buf_len0, ind, end);
		break;
	case 68:
		CheckWord_T(&lex, "DIV", 4, Scanner_Div_cnst, "DO", 3, Scanner_Do_cnst, buf, buf_len0, ind, end);
		break;
	case 69:
		if (CheckWord_Eq("ELSE", 5, buf, buf_len0, ind, end)) {
			lex = Scanner_Else_cnst;
		} else {
			CheckWord_T(&lex, "ELSIF", 6, Scanner_Elsif_cnst, "END", 4, Scanner_End_cnst, buf, buf_len0, ind, end);
		}
		break;
	case 70:
		CheckWord_T(&lex, "FALSE", 6, Scanner_False_cnst, "FOR", 4, Scanner_For_cnst, buf, buf_len0, ind, end);
		break;
	case 73:
		if (CheckWord_Eq("IF", 3, buf, buf_len0, ind, end)) {
			lex = Scanner_If_cnst;
		} else if (CheckWord_Eq("IMPORT", 7, buf, buf_len0, ind, end)) {
			lex = Scanner_Import_cnst;
		} else {
			CheckWord_T(&lex, "IN", 3, Scanner_In_cnst, "IS", 3, Scanner_Is_cnst, buf, buf_len0, ind, end);
		}
		break;
	case 77:
		CheckWord_T(&lex, "MOD", 4, Scanner_Mod_cnst, "MODULE", 7, Scanner_Module_cnst, buf, buf_len0, ind, end);
		break;
	case 78:
		CheckWord_O(&lex, "NIL", 4, buf, buf_len0, ind, end, Scanner_Nil_cnst);
		break;
	case 79:
		CheckWord_T(&lex, "OF", 3, Scanner_Of_cnst, "OR", 3, Scanner_Or_cnst, buf, buf_len0, ind, end);
		break;
	case 80:
		CheckWord_T(&lex, "POINTER", 8, Scanner_Pointer_cnst, "PROCEDURE", 10, Scanner_Procedure_cnst, buf, buf_len0, ind, end);
		break;
	case 82:
		if (CheckWord_Eq("RECORD", 7, buf, buf_len0, ind, end)) {
			lex = Scanner_Record_cnst;
		} else {
			CheckWord_T(&lex, "REPEAT", 7, Scanner_Repeat_cnst, "RETURN", 7, Scanner_Return_cnst, buf, buf_len0, ind, end);
		}
		break;
	case 84:
		if (CheckWord_Eq("THEN", 5, buf, buf_len0, ind, end)) {
			lex = Scanner_Then_cnst;
		} else if (CheckWord_Eq("TO", 3, buf, buf_len0, ind, end)) {
			lex = Scanner_To_cnst;
		} else {
			CheckWord_T(&lex, "TRUE", 5, Scanner_True_cnst, "TYPE", 5, Scanner_Type_cnst, buf, buf_len0, ind, end);
		}
		break;
	case 85:
		CheckWord_O(&lex, "UNTIL", 6, buf, buf_len0, ind, end, Scanner_Until_cnst);
		break;
	case 86:
		CheckWord_O(&lex, "VAR", 4, buf, buf_len0, ind, end, Scanner_Var_cnst);
		break;
	case 87:
		CheckWord_O(&lex, "WHILE", 6, buf, buf_len0, ind, end, Scanner_While_cnst);
		break;
	default:
		if ((0 <= buf[o7c_ind(buf_len0, ind)] && buf[o7c_ind(buf_len0, ind)] <= 64) || (buf[o7c_ind(buf_len0, ind)] == 71) || (buf[o7c_ind(buf_len0, ind)] == 72) || (74 <= buf[o7c_ind(buf_len0, ind)] && buf[o7c_ind(buf_len0, ind)] <= 76) || (buf[o7c_ind(buf_len0, ind)] == 81) || (buf[o7c_ind(buf_len0, ind)] == 83) || (88 <= buf[o7c_ind(buf_len0, ind)] && buf[o7c_ind(buf_len0, ind)] <= 255)) {
			lex = Scanner_Ident_cnst;
		} else abort();
		break;
	}
	buf[o7c_ind(buf_len0, end)] = save;
	o7c_return = lex;
	return o7c_return;
}

static o7c_bool IsLetterOrDigit(o7c_char ch) {
	o7c_bool o7c_return;

	o7c_return = (ch >= (char unsigned)'A') && (ch <= (char unsigned)'Z') || (ch >= (char unsigned)'a') && (ch <= (char unsigned)'z') || (ch >= (char unsigned)'0') && (ch <= (char unsigned)'9');
	return o7c_return;
}

static int SWord(struct Scanner_Scanner *s, o7c_tag_t s_tag) {
	int o7c_return;

	int len = O7C_INT_UNDEF, l = O7C_INT_UNDEF;

	ScanChars((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &(*s).ind, IsLetterOrDigit, &(*(*s).in_), NULL);
	len = o7c_add(o7c_sub((*s).ind, (*s).lexStart), o7c_mul((int)(o7c_cmp((*s).ind, (*s).lexStart) <  0), (sizeof((*s).buf) / sizeof ((*s).buf[0]) - 1)));
	assert(o7c_cmp(len, 0) >  0);
	if (o7c_cmp(len, TranslatorLimits_MaxLenName_cnst) <=  0) {
		l = CheckWord((*s).buf, Scanner_BlockSize_cnst * 2 + 1, (*s).lexStart, (*s).ind);
	} else {
		l = Scanner_ErrWordLenTooBig_cnst;
	}
	o7c_return = l;
	return o7c_return;
}

static o7c_bool ScanBlank(struct Scanner_Scanner *s, o7c_tag_t s_tag) {
	o7c_bool o7c_return;

	int start = O7C_INT_UNDEF, i = O7C_INT_UNDEF, comment = O7C_INT_UNDEF;

	i = (*s).ind;
	assert(o7c_cmp(i, 0) >=  0);
	start = i;
	comment = 0;
	while (1) if (((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == (char unsigned)' ') || ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x0Du)) {
		i = o7c_add(i, 1);;
	} else if ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x09u) {
		i = o7c_add(i, 1);;
		(*s).tabs = o7c_add((*s).tabs, 1);;
	} else if ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x0Au) {
		(*s).line = o7c_add((*s).line, 1);;
		(*s).column = 0;
		(*s).tabs = 0;
		i = o7c_add(i, 1);;
		start = i;
	} else if ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x0Cu) {
		FillBuf((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &i, &(*(*s).in_), NULL);
		start = o7c_sub(start, o7c_mul((int)(o7c_cmp(i, 0) ==  0), (sizeof((*s).buf) / sizeof ((*s).buf[0]) - 1)));
	} else if (((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == (char unsigned)'(') && (o7c_cmp(comment, 0) >=  0)) {
		(*s).ind = i;
		if (ScanChar(&(*s), s_tag) == (char unsigned)'*') {
			comment = o7c_add(comment, 1);;
			(*s).ind = o7c_add((*s).ind, 1);;
		} else if (o7c_cmp(comment, 0) ==  0) {
			(*s).ind = i;
			comment =  - 1;
		}
		i = (*s).ind;
	} else if ((o7c_cmp(comment, 0) >  0) && ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)] != 0x00u)) {
		if ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == (char unsigned)'*') {
			(*s).ind = i;
			if (ScanChar(&(*s), s_tag) == (char unsigned)')') {
				comment = o7c_sub(comment, 1);;
				i = (*s).ind;
			}
		}
		i = o7c_add(i, 1);;
	} else break;
	(*s).column = o7c_add((*s).column, (o7c_sub(i, start)));
	assert(o7c_cmp((*s).column, 0) >=  0);
	(*s).ind = i;
	o7c_return = o7c_cmp(comment, 0) <=  0;
	return o7c_return;
}

static int ScanString(struct Scanner_Scanner *s, o7c_tag_t s_tag) {
	int o7c_return;

	int l = O7C_INT_UNDEF, i = O7C_INT_UNDEF, j = O7C_INT_UNDEF, count = O7C_INT_UNDEF;

	i = o7c_add((*s).ind, 1);
	if ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x0Cu) {
		FillBuf((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &i, &(*(*s).in_), NULL);
	}
	j = i;
	count = 0;
	while (1) if (((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)] != (char unsigned)'"') && (((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)] >= (char unsigned)' ') || ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x09u))) {
		i = o7c_add(i, 1);;
		count = o7c_add(count, 1);;
	} else if ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == 0x0Cu) {
		FillBuf((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &i, &(*(*s).in_), NULL);
	} else break;
	(*s).isChar = false;
	if ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, i)] == (char unsigned)'"') {
		l = Scanner_String_cnst;
		if (o7c_cmp(count, 1) ==  0) {
			(*s).isChar = true;
			(*s).integer = (int)(*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, j)];
		}
		i = o7c_add(i, 1);;
	} else {
		l = Scanner_ErrExpectDQuote_cnst;
	}
	(*s).ind = i;
	o7c_return = l;
	return o7c_return;
}

static void Next_L(int *lex, struct Scanner_Scanner *s, o7c_tag_t s_tag, int l) {
	(*s).ind = o7c_add((*s).ind, 1);;
	(*lex) = l;
}

static void Next_Li(int *lex, struct Scanner_Scanner *s, o7c_tag_t s_tag, o7c_char ch, int then, int else_) {
	(*s).ind = o7c_add((*s).ind, 1);;
	if ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] == 0x0Cu) {
		FillBuf((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &(*s).ind, &(*(*s).in_), NULL);
	}
	if ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] == ch) {
		(*lex) = then;
		(*s).ind = o7c_add((*s).ind, 1);;
	} else {
		(*lex) = else_;
	}
}

extern int Scanner_Next(struct Scanner_Scanner *s, o7c_tag_t s_tag) {
	int o7c_return;

	int lex = O7C_INT_UNDEF;

	if (!ScanBlank(&(*s), s_tag)) {
		lex = Scanner_ErrUnclosedComment_cnst;
	} else {
		(*s).lexStart = (*s).ind;
		switch ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)]) {
		case 0:
			lex = Scanner_End_cnst;
			break;
		case 43:
			Next_L(&lex, &(*s), s_tag, Scanner_Plus_cnst);
			break;
		case 45:
			Next_L(&lex, &(*s), s_tag, Scanner_Minus_cnst);
			break;
		case 42:
			Next_L(&lex, &(*s), s_tag, Scanner_Asterisk_cnst);
			break;
		case 47:
			Next_L(&lex, &(*s), s_tag, Scanner_Slash_cnst);
			break;
		case 46:
			Next_Li(&lex, &(*s), s_tag, (char unsigned)'.', Scanner_Range_cnst, Scanner_Dot_cnst);
			break;
		case 44:
			Next_L(&lex, &(*s), s_tag, Scanner_Comma_cnst);
			break;
		case 58:
			Next_Li(&lex, &(*s), s_tag, (char unsigned)'=', Scanner_Assign_cnst, Scanner_Colon_cnst);
			break;
		case 59:
			Next_L(&lex, &(*s), s_tag, Scanner_Semicolon_cnst);
			break;
		case 94:
			Next_L(&lex, &(*s), s_tag, Scanner_Dereference_cnst);
			break;
		case 61:
			Next_L(&lex, &(*s), s_tag, Scanner_Equal_cnst);
			break;
		case 35:
			Next_L(&lex, &(*s), s_tag, Scanner_Inequal_cnst);
			break;
		case 126:
			Next_L(&lex, &(*s), s_tag, Scanner_Negate_cnst);
			break;
		case 60:
			Next_Li(&lex, &(*s), s_tag, (char unsigned)'=', Scanner_LessEqual_cnst, Scanner_Less_cnst);
			break;
		case 62:
			Next_Li(&lex, &(*s), s_tag, (char unsigned)'=', Scanner_GreaterEqual_cnst, Scanner_Greater_cnst);
			break;
		case 38:
			Next_L(&lex, &(*s), s_tag, Scanner_And_cnst);
			break;
		case 124:
			Next_L(&lex, &(*s), s_tag, Scanner_Alternative_cnst);
			break;
		case 40:
			Next_L(&lex, &(*s), s_tag, Scanner_Brace1Open_cnst);
			break;
		case 41:
			Next_L(&lex, &(*s), s_tag, Scanner_Brace1Close_cnst);
			break;
		case 91:
			Next_L(&lex, &(*s), s_tag, Scanner_Brace2Open_cnst);
			break;
		case 93:
			Next_L(&lex, &(*s), s_tag, Scanner_Brace2Close_cnst);
			break;
		case 123:
			Next_L(&lex, &(*s), s_tag, Scanner_Brace3Open_cnst);
			break;
		case 125:
			Next_L(&lex, &(*s), s_tag, Scanner_Brace3Close_cnst);
			break;
		case 34:
			lex = ScanString(&(*s), s_tag);
			break;
		default:
			if ((1 <= (*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] && (*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] <= 33) || ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] == 36) || ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] == 37) || ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] == 39) || ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] == 63) || ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] == 64) || ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] == 92) || ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] == 95) || ((*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] == 96) || (127 <= (*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] && (*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] <= 255)) {
				lex = Scanner_UnexpectChar_cnst;
			} else if ((48 <= (*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] && (*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] <= 57)) {
				lex = SNumber(&(*s), s_tag);
			} else if ((97 <= (*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] && (*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] <= 122) || (65 <= (*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] && (*s).buf[o7c_ind(Scanner_BlockSize_cnst * 2 + 1, (*s).ind)] <= 90)) {
				lex = SWord(&(*s), s_tag);
			} else abort();
			break;
		}
		(*s).lexEnd = (*s).ind;
		(*s).lexLen = o7c_sub(o7c_add((*s).lexEnd, o7c_mul((int)(o7c_cmp((*s).lexEnd, (*s).lexStart) <  0), (sizeof((*s).buf) / sizeof ((*s).buf[0]) - 1))), (*s).lexStart);
		assert(o7c_cmp((*s).lexLen, 0) >  0);
		(*s).column = o7c_add((*s).column, (*s).lexLen);
		assert(o7c_cmp((*s).column, 0) >=  0);
	}
	o7c_return = lex;
	return o7c_return;
}

extern void Scanner_init(void) {
	static int initialized = 0;
	if (0 == initialized) {
		V_init();
		VDataStream_init();
		Utf8_init();
		TranslatorLimits_init();
		Log_init();

		o7c_tag_init(Scanner_Scanner_tag, V_Base_tag);

		assert(TranslatorLimits_MaxLenName_cnst < Scanner_BlockSize_cnst);
	}
	++initialized;
}


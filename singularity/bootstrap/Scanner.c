#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#include <o7c.h>

#include "Scanner.h"

#define IntMax_cnst 2147483647
#define CharMax_cnst "\xFF"
#define RealScaleMax_cnst 512

int Scanner_Scanner_tag[15];

typedef bool (*Suit)(char unsigned ch);
typedef int (*SuitDigit)(char unsigned ch);

extern void Scanner_Init(struct Scanner_Scanner *s, int *s_tag, struct VDataStream_In *in_, int *in__tag) {
	assert(in_ != NULL);
	V_Init(&(*s)._, s_tag);
	(*s).column = 0;
	(*s).tabs = 0;
	(*s).line = 0;
	(*s).in_ = in_;
	(*s).ind = sizeof((*s).buf) / sizeof ((*s).buf[0]) - 1;
	(*s).buf[(*s).ind] = 0x0Cu;
}

static void FillBuf(char unsigned buf[/*len0*/], int buf_len0, int *ind, struct VDataStream_In *in_, int *in__tag) {
	int size;

	if ((*ind) % (buf_len0 / 2) != 0) {
		assert(buf[(*ind)] == 0x0Cu);
		buf[(*ind)] = 0x00u;
	} else {
		buf[(*ind)] = 0x0Cu;
		(*ind) = (*ind) % (buf_len0 - 1);
		size = VDataStream_Read(&(*in_), in__tag, buf, buf_len0, (*ind), buf_len0 / 2);
		if (buf[(*ind)] == 0x0Cu) {
			buf[(*ind)] = 0x00u;
		} else if (size == buf_len0 / 2) {
			buf[((*ind) + buf_len0 / 2) % (buf_len0 - 1)] = 0x0Cu;
		} else {
			buf[(*ind) + size] = 0x00u;
		}
	}
}

static char unsigned ScanChar(struct Scanner_Scanner *s, int *s_tag) {
	char unsigned ch;

	(*s).ind++;
	ch = (*s).buf[(*s).ind];
	if (ch == 0x0Cu) {
		FillBuf((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &(*s).ind, &(*(*s).in_), NULL);
		ch = (*s).buf[(*s).ind];
	}
	return ch;
}

static void ScanChars(char unsigned buf[/*len0*/], int buf_len0, int *i, Suit suit, struct VDataStream_In *in_, int *in__tag) {
	while (1) if (suit(buf[(*i)])) {
		(*i)++;
	} else if (buf[(*i)] == 0x0Cu) {
		FillBuf(buf, buf_len0, &(*i), &(*in_), in__tag);
	} else break;
}

static bool IsDigit(char unsigned ch) {
	return (ch >= (char unsigned)'0') && (ch <= (char unsigned)'9');
}

static bool IsHexDigit(char unsigned ch) {
	return (ch >= (char unsigned)'0') && (ch <= (char unsigned)'9') || (ch >= (char unsigned)'A') && (ch <= (char unsigned)'F');
}

static int ValDigit(char unsigned ch) {
	int i;

	if ((ch >= (char unsigned)'0') && (ch <= (char unsigned)'9')) {
		i = (int)ch - (int)(char unsigned)'0';
	} else {
		i =  - 1;
	}
	return i;
}

static int ValHexDigit(char unsigned ch) {
	int i;

	if ((ch >= (char unsigned)'0') && (ch <= (char unsigned)'9')) {
		i = (int)ch - (int)(char unsigned)'0';
	} else if ((ch >= (char unsigned)'A') && (ch <= (char unsigned)'F')) {
		i = 10 + (int)ch - (int)(char unsigned)'A';
	} else {
		i =  - 1;
	}
	return i;
}

static int SNumber(struct Scanner_Scanner *s, int *s_tag);
static void SNumber_Val(struct Scanner_Scanner *s, int *s_tag, int *lex, int capacity, SuitDigit valDigit) {
	int d;
	int val;
	int i;

	val = 0;
	i = (*s).lexStart;
	d = valDigit((*s).buf[i]);
	while (1) if (d >= 0) {
		if (IntMax_cnst / capacity >= val) {
			val = val * capacity;
			if (IntMax_cnst - d >= val) {
				val = val + d;
			} else {
				(*lex) = Scanner_ErrNumberTooBig_cnst;
			}
		} else {
			(*lex) = Scanner_ErrNumberTooBig_cnst;
		}
		i++;
		d = valDigit((*s).buf[i]);
	} else if ((*s).buf[i] == 0x0Cu) {
		i = 0;
		d = valDigit((*s).buf[i]);
	} else break;
	(*s).integer = val;
}

static void SNumber_ValReal(struct Scanner_Scanner *s, int *s_tag, int *lex) {
	int i;
	int d;
	int scale;
	bool scMinus;
	double val;
	double t;

	val = 1.0;
	i = (*s).lexStart;
	d = ValDigit((*s).buf[i]);
	while (1) if (d >= 0) {
		val = val * 10.0 + (double)d;
		i++;
		d = ValDigit((*s).buf[i]);
	} else if ((*s).buf[i] == 0x0Cu) {
		i = 0;
		d = ValDigit((*s).buf[i]);
	} else break;
	i++;
	t = 10.0;
	d = ValDigit((*s).buf[i]);
	while (1) if (d >= 0) {
		val = val + (double)d / t;
		t = t * 10.0;
		i++;
		d = ValDigit((*s).buf[i]);
	} else if ((*s).buf[i] == 0x0Cu) {
		FillBuf((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &i, &(*(*s).in_), NULL);
		d = ValDigit((*s).buf[i]);
	} else break;
	if ((*s).buf[i] == (char unsigned)'E') {
		i++;
		if ((*s).buf[i] == 0x0Cu) {
			FillBuf((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &i, &(*(*s).in_), NULL);
		}
		scMinus = (*s).buf[i] == (char unsigned)'-';
		if (scMinus || ((*s).buf[i] == (char unsigned)'+')) {
			i++;
			if ((*s).buf[i] == 0x0Cu) {
				FillBuf((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &i, &(*(*s).in_), NULL);
			}
		}
		d = ValDigit((*s).buf[i]);
		if (d >= 0) {
			scale = 0;
			while (1) if (d >= 0) {
				if (scale < IntMax_cnst / 10) {
					scale = scale * 10 + d;
				}
				i++;
				d = ValDigit((*s).buf[i]);
			} else if ((*s).buf[i] == 0x0Cu) {
				FillBuf((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &i, &(*(*s).in_), NULL);
				d = ValDigit((*s).buf[i]);
			} else break;
			if (scale <= RealScaleMax_cnst) {
				while (scale > 0) {
					if (scMinus) {
						val = val * 10.0;
					} else {
						val = val / 10.0;
					}
					scale--;
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

static int SNumber(struct Scanner_Scanner *s, int *s_tag) {
	int lex;
	char unsigned ch;

	lex = Scanner_Number_cnst;
	ScanChars((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &(*s).ind, IsDigit, &(*(*s).in_), NULL);
	ch = (*s).buf[(*s).ind];
	(*s).isReal = ch == (char unsigned)'.';
	if ((*s).isReal) {
		(*s).ind++;
		SNumber_ValReal(&(*s), s_tag, &lex);
	} else if ((ch >= (char unsigned)'A') && (ch <= (char unsigned)'F') || (ch == (char unsigned)'H') || (ch == (char unsigned)'X')) {
		ScanChars((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &(*s).ind, IsHexDigit, &(*(*s).in_), NULL);
		ch = (*s).buf[(*s).ind];
		SNumber_Val(&(*s), s_tag, &lex, 16, ValHexDigit);
		if (ch == (char unsigned)'X') {
			if ((*s).integer <= (int)0xFFu) {
				lex = Scanner_String_cnst;
				(*s).isChar = true;
			} else {
				lex = Scanner_ErrNumberTooBig_cnst;
			}
		} else if (ch != (char unsigned)'H') {
			lex = Scanner_ErrExpectHOrX_cnst;
		}
		if ((ch == (char unsigned)'X') || (ch == (char unsigned)'H')) {
			(*s).ind++;
		}
	} else {
		SNumber_Val(&(*s), s_tag, &lex, 10, ValDigit);
	}
	Log_Str("Number lex = ", 14);
	Log_Int(lex);
	Log_Ln();
	return lex;
}

static bool IsWordEqual(char unsigned str[/*len0*/], int str_len0, char unsigned buf[/*len0*/], int buf_len0, int ind, int end) {
	int i;
	int j;

	assert(str_len0 <= buf_len0 / 2);
	j = 1;
	i = ind + 1;
	while (1) if (buf[i] == str[j]) {
		i++;
		j++;
	} else if (buf[i] == 0x0Cu) {
		i = 0;
	} else break;
	return (buf[i] == 0x08u) && (str[j] == 0x00u);
}

static bool CheckPredefined_Eq(char unsigned str[/*len0*/], int str_len0, char unsigned buf[/*len0*/], int buf_len0, int begin, int end) {
	return IsWordEqual(str, str_len0, buf, buf_len0, begin, end);
}

static int CheckPredefined_O(char unsigned str[/*len0*/], int str_len0, char unsigned buf[/*len0*/], int buf_len0, int begin, int end, int id) {
	if (!CheckPredefined_Eq(str, str_len0, buf, buf_len0, begin, end)) {
		id = Scanner_Ident_cnst;
	}
	return id;
}

static int CheckPredefined_T(char unsigned s1[/*len0*/], int s1_len0, char unsigned buf[/*len0*/], int buf_len0, int begin, int end, int id1, char unsigned s2[/*len0*/], int s2_len0, int id2) {
	if (CheckPredefined_Eq(s1, s1_len0, buf, buf_len0, begin, end)) {
		id2 = id1;
	} else if (!CheckPredefined_Eq(s2, s2_len0, buf, buf_len0, begin, end)) {
		id2 = Scanner_Ident_cnst;
	}
	return id2;
}

extern int Scanner_CheckPredefined(char unsigned buf[/*len0*/], int buf_len0, int begin, int end) {
	int id;
	char unsigned save;

	save = buf[end];
	buf[end] = 0x08u;
	{ int o7_case_expr = buf[begin];
		if ((o7_case_expr == 65)) {
			if (CheckPredefined_Eq("ABS", 4, buf, buf_len0, begin, end)) {
				id = Scanner_Abs_cnst;
			} else {
				id = CheckPredefined_T("ASR", 4, buf, buf_len0, begin, end, Scanner_Asr_cnst, "ASSERT", 7, Scanner_Assert_cnst);
			}
		} else if ((o7_case_expr == 66)) {
			id = CheckPredefined_T("BOOLEAN", 8, buf, buf_len0, begin, end, Scanner_Boolean_cnst, "BYTE", 5, Scanner_Byte_cnst);
		} else if ((o7_case_expr == 67)) {
			id = CheckPredefined_T("CHAR", 5, buf, buf_len0, begin, end, Scanner_Char_cnst, "CHR", 4, Scanner_Chr_cnst);
		} else if ((o7_case_expr == 68)) {
			id = CheckPredefined_O("DEC", 4, buf, buf_len0, begin, end, Scanner_Dec_cnst);
		} else if ((o7_case_expr == 69)) {
			id = CheckPredefined_O("EXCL", 5, buf, buf_len0, begin, end, Scanner_Excl_cnst);
		} else if ((o7_case_expr == 70)) {
			id = CheckPredefined_T("FLOOR", 6, buf, buf_len0, begin, end, Scanner_Floor_cnst, "FLT", 4, Scanner_Flt_cnst);
		} else if ((o7_case_expr == 73)) {
			if (CheckPredefined_Eq("INC", 4, buf, buf_len0, begin, end)) {
				id = Scanner_Inc_cnst;
			} else {
				id = CheckPredefined_T("INCL", 5, buf, buf_len0, begin, end, Scanner_Incl_cnst, "INTEGER", 8, Scanner_Integer_cnst);
			}
		} else if ((o7_case_expr == 76)) {
			id = CheckPredefined_T("LEN", 4, buf, buf_len0, begin, end, Scanner_Len_cnst, "LSL", 4, Scanner_Lsl_cnst);
		} else if ((o7_case_expr == 78)) {
			id = CheckPredefined_O("NEW", 4, buf, buf_len0, begin, end, Scanner_New_cnst);
		} else if ((o7_case_expr == 79)) {
			id = CheckPredefined_T("ODD", 4, buf, buf_len0, begin, end, Scanner_Odd_cnst, "ORD", 4, Scanner_Ord_cnst);
		} else if ((o7_case_expr == 80)) {
			id = CheckPredefined_O("PACK", 5, buf, buf_len0, begin, end, Scanner_Pack_cnst);
		} else if ((o7_case_expr == 82)) {
			id = CheckPredefined_T("REAL", 5, buf, buf_len0, begin, end, Scanner_Real_cnst, "ROR", 4, Scanner_Ror_cnst);
		} else if ((o7_case_expr == 83)) {
			id = CheckPredefined_O("SET", 4, buf, buf_len0, begin, end, Scanner_Set_cnst);
		} else if ((o7_case_expr == 85)) {
			id = CheckPredefined_O("UNPK", 5, buf, buf_len0, begin, end, Scanner_Unpk_cnst);
		} else if ((o7_case_expr == 71) || (o7_case_expr == 72) || (o7_case_expr == 74) || (o7_case_expr == 75) || (o7_case_expr == 77) || (o7_case_expr == 84) || (86 <= o7_case_expr && o7_case_expr <= 90) || (97 <= o7_case_expr && o7_case_expr <= 122)) {
			id = Scanner_Ident_cnst;
		} else assert(0); 
	}
	buf[end] = save;
	return id;
}

static int CheckWord(char unsigned buf[/*len0*/], int buf_len0, int ind, int end);
static bool CheckWord_Eq(char unsigned str[/*len0*/], int str_len0, char unsigned buf[/*len0*/], int buf_len0, int ind, int end) {
	return IsWordEqual(str, str_len0, buf, buf_len0, ind, end);
}

static void CheckWord_O(int *lex, char unsigned str[/*len0*/], int str_len0, char unsigned buf[/*len0*/], int buf_len0, int ind, int end, int l) {
	if (CheckWord_Eq(str, str_len0, buf, buf_len0, ind, end)) {
		(*lex) = l;
	} else {
		(*lex) = Scanner_Ident_cnst;
	}
}

static void CheckWord_T(int *lex, char unsigned s1[/*len0*/], int s1_len0, int l1, char unsigned s2[/*len0*/], int s2_len0, int l2, char unsigned buf[/*len0*/], int buf_len0, int ind, int end) {
	if (CheckWord_Eq(s1, s1_len0, buf, buf_len0, ind, end)) {
		(*lex) = l1;
	} else if (CheckWord_Eq(s2, s2_len0, buf, buf_len0, ind, end)) {
		(*lex) = l2;
	} else {
		(*lex) = Scanner_Ident_cnst;
	}
}

static int CheckWord(char unsigned buf[/*len0*/], int buf_len0, int ind, int end) {
	int lex;
	char unsigned save;

	save = buf[end];
	buf[end] = 0x08u;
	{ int o7_case_expr = buf[ind];
		if ((o7_case_expr == 65)) {
			CheckWord_O(&lex, "ARRAY", 6, buf, buf_len0, ind, end, Scanner_Array_cnst);
		} else if ((o7_case_expr == 66)) {
			CheckWord_T(&lex, "BEGIN", 6, Scanner_Begin_cnst, "BY", 3, Scanner_By_cnst, buf, buf_len0, ind, end);
		} else if ((o7_case_expr == 67)) {
			CheckWord_T(&lex, "CASE", 5, Scanner_Case_cnst, "CONST", 6, Scanner_Const_cnst, buf, buf_len0, ind, end);
		} else if ((o7_case_expr == 68)) {
			CheckWord_T(&lex, "DIV", 4, Scanner_Div_cnst, "DO", 3, Scanner_Do_cnst, buf, buf_len0, ind, end);
		} else if ((o7_case_expr == 69)) {
			if (CheckWord_Eq("ELSE", 5, buf, buf_len0, ind, end)) {
				lex = Scanner_Else_cnst;
			} else {
				CheckWord_T(&lex, "ELSIF", 6, Scanner_Elsif_cnst, "END", 4, Scanner_End_cnst, buf, buf_len0, ind, end);
			}
		} else if ((o7_case_expr == 70)) {
			CheckWord_T(&lex, "FALSE", 6, Scanner_False_cnst, "FOR", 4, Scanner_For_cnst, buf, buf_len0, ind, end);
		} else if ((o7_case_expr == 73)) {
			if (CheckWord_Eq("IF", 3, buf, buf_len0, ind, end)) {
				lex = Scanner_If_cnst;
			} else if (CheckWord_Eq("IMPORT", 7, buf, buf_len0, ind, end)) {
				lex = Scanner_Import_cnst;
			} else {
				CheckWord_T(&lex, "IN", 3, Scanner_In_cnst, "IS", 3, Scanner_Is_cnst, buf, buf_len0, ind, end);
			}
		} else if ((o7_case_expr == 77)) {
			CheckWord_T(&lex, "MOD", 4, Scanner_Mod_cnst, "MODULE", 7, Scanner_Module_cnst, buf, buf_len0, ind, end);
		} else if ((o7_case_expr == 78)) {
			CheckWord_O(&lex, "NIL", 4, buf, buf_len0, ind, end, Scanner_Nil_cnst);
		} else if ((o7_case_expr == 79)) {
			CheckWord_T(&lex, "OF", 3, Scanner_Of_cnst, "OR", 3, Scanner_Or_cnst, buf, buf_len0, ind, end);
		} else if ((o7_case_expr == 80)) {
			CheckWord_T(&lex, "POINTER", 8, Scanner_Pointer_cnst, "PROCEDURE", 10, Scanner_Procedure_cnst, buf, buf_len0, ind, end);
		} else if ((o7_case_expr == 82)) {
			if (CheckWord_Eq("RECORD", 7, buf, buf_len0, ind, end)) {
				lex = Scanner_Record_cnst;
			} else {
				CheckWord_T(&lex, "REPEAT", 7, Scanner_Repeat_cnst, "RETURN", 7, Scanner_Return_cnst, buf, buf_len0, ind, end);
			}
		} else if ((o7_case_expr == 84)) {
			if (CheckWord_Eq("THEN", 5, buf, buf_len0, ind, end)) {
				lex = Scanner_Then_cnst;
			} else if (CheckWord_Eq("TO", 3, buf, buf_len0, ind, end)) {
				lex = Scanner_To_cnst;
			} else {
				CheckWord_T(&lex, "TRUE", 5, Scanner_True_cnst, "TYPE", 5, Scanner_Type_cnst, buf, buf_len0, ind, end);
			}
		} else if ((o7_case_expr == 85)) {
			CheckWord_O(&lex, "UNTIL", 6, buf, buf_len0, ind, end, Scanner_Until_cnst);
		} else if ((o7_case_expr == 86)) {
			CheckWord_O(&lex, "VAR", 4, buf, buf_len0, ind, end, Scanner_Var_cnst);
		} else if ((o7_case_expr == 87)) {
			CheckWord_O(&lex, "WHILE", 6, buf, buf_len0, ind, end, Scanner_While_cnst);
		} else if ((0 <= o7_case_expr && o7_case_expr <= 64) || (o7_case_expr == 71) || (o7_case_expr == 72) || (74 <= o7_case_expr && o7_case_expr <= 76) || (o7_case_expr == 81) || (o7_case_expr == 83) || (88 <= o7_case_expr && o7_case_expr <= 255)) {
			lex = Scanner_Ident_cnst;
		} else assert(0); 
	}
	buf[end] = save;
	return lex;
}

static bool IsLetterOrDigit(char unsigned ch) {
	return (ch >= (char unsigned)'A') && (ch <= (char unsigned)'Z') || (ch >= (char unsigned)'a') && (ch <= (char unsigned)'z') || (ch >= (char unsigned)'0') && (ch <= (char unsigned)'9');
}

static int SWord(struct Scanner_Scanner *s, int *s_tag) {
	int len;
	int l;

	ScanChars((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &(*s).ind, IsLetterOrDigit, &(*(*s).in_), NULL);
	len = (*s).ind - (*s).lexStart + (int)((*s).ind < (*s).lexStart) * (sizeof((*s).buf) / sizeof ((*s).buf[0]) - 1);
	assert(len > 0);
	if (len <= TranslatorLimits_MaxLenName_cnst) {
		l = CheckWord((*s).buf, Scanner_BlockSize_cnst * 2 + 1, (*s).lexStart, (*s).ind);
	} else {
		l = Scanner_ErrWordLenTooBig_cnst;
	}
	return l;
}

static bool ScanBlank(struct Scanner_Scanner *s, int *s_tag) {
	int start;
	int i;
	int comment;

	i = (*s).ind;
	assert(i >= 0);
	start = i;
	comment = 0;
	while (1) if (((*s).buf[i] == (char unsigned)' ') || ((*s).buf[i] == 0x0Du)) {
		i++;
	} else if ((*s).buf[i] == 0x09u) {
		i++;
		(*s).tabs++;
	} else if ((*s).buf[i] == 0x0Au) {
		(*s).line++;
		(*s).column = 0;
		(*s).tabs = 0;
		i++;
		start = i;
	} else if ((*s).buf[i] == 0x0Cu) {
		FillBuf((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &i, &(*(*s).in_), NULL);
		start = start - (int)(i == 0) * (sizeof((*s).buf) / sizeof ((*s).buf[0]) - 1);
	} else if (((*s).buf[i] == (char unsigned)'(') && (comment >= 0)) {
		(*s).ind = i;
		if (ScanChar(&(*s), s_tag) == (char unsigned)'*') {
			comment++;
			(*s).ind++;
		} else if (comment == 0) {
			if ((*s).ind > 0) {
				(*s).ind--;
			} else {
				(*s).ind = Scanner_BlockSize_cnst * 2 - 1;
			}
			comment =  - 1;
		}
		i = (*s).ind;
	} else if ((comment > 0) && ((*s).buf[i] != 0x00u)) {
		if ((*s).buf[i] == (char unsigned)'*') {
			(*s).ind = i;
			if (ScanChar(&(*s), s_tag) == (char unsigned)')') {
				comment--;
				i = (*s).ind;
			}
		}
		i++;
	} else break;
	(*s).column = (*s).column + (i - start);
	assert((*s).column >= 0);
	(*s).ind = i;
	return comment <= 0;
}

static int ScanString(struct Scanner_Scanner *s, int *s_tag) {
	int l;
	int i;
	int j;
	int count;

	i = (*s).ind + 1;
	if ((*s).buf[i] == 0x0Cu) {
		FillBuf((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &i, &(*(*s).in_), NULL);
	}
	j = i;
	count = 0;
	while (1) if (((*s).buf[i] != (char unsigned)'"') && (((*s).buf[i] >= (char unsigned)' ') || ((*s).buf[i] == 0x09u))) {
		i++;
		count++;
	} else if ((*s).buf[i] == 0x0Cu) {
		FillBuf((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &i, &(*(*s).in_), NULL);
	} else break;
	(*s).isChar = false;
	if ((*s).buf[i] == (char unsigned)'"') {
		l = Scanner_String_cnst;
		if (count == 1) {
			(*s).isChar = true;
			(*s).integer = (int)(*s).buf[j];
		}
		i++;
	} else {
		l = Scanner_ErrExpectDQuote_cnst;
	}
	(*s).ind = i;
	return l;
}

static void Next_L(int *lex, struct Scanner_Scanner *s, int *s_tag, int l) {
	(*s).ind++;
	(*lex) = l;
}

static void Next_Li(int *lex, struct Scanner_Scanner *s, int *s_tag, char unsigned ch, int then, int else_) {
	(*s).ind++;
	if ((*s).buf[(*s).ind] == 0x0Cu) {
		FillBuf((*s).buf, Scanner_BlockSize_cnst * 2 + 1, &(*s).ind, &(*(*s).in_), NULL);
	}
	if ((*s).buf[(*s).ind] == ch) {
		(*lex) = then;
		(*s).ind++;
	} else {
		(*lex) = else_;
	}
}

extern int Scanner_Next(struct Scanner_Scanner *s, int *s_tag) {
	int lex;

	if (!ScanBlank(&(*s), s_tag)) {
		lex = Scanner_ErrUnclosedComment_cnst;
	} else {
		(*s).lexStart = (*s).ind;
		{ int o7_case_expr = (*s).buf[(*s).ind];
			if ((o7_case_expr == 0)) {
				lex = Scanner_End_cnst;
			} else if ((1 <= o7_case_expr && o7_case_expr <= 33) || (o7_case_expr == 36) || (o7_case_expr == 37) || (o7_case_expr == 39) || (o7_case_expr == 63) || (o7_case_expr == 64) || (o7_case_expr == 92) || (o7_case_expr == 95) || (o7_case_expr == 96) || (127 <= o7_case_expr && o7_case_expr <= 255)) {
				lex = Scanner_UnexpectChar_cnst;
			} else if ((48 <= o7_case_expr && o7_case_expr <= 57)) {
				lex = SNumber(&(*s), s_tag);
			} else if ((97 <= o7_case_expr && o7_case_expr <= 122) || (65 <= o7_case_expr && o7_case_expr <= 90)) {
				lex = SWord(&(*s), s_tag);
			} else if ((o7_case_expr == 43)) {
				Next_L(&lex, &(*s), s_tag, Scanner_Plus_cnst);
			} else if ((o7_case_expr == 45)) {
				Next_L(&lex, &(*s), s_tag, Scanner_Minus_cnst);
			} else if ((o7_case_expr == 42)) {
				Next_L(&lex, &(*s), s_tag, Scanner_Asterisk_cnst);
			} else if ((o7_case_expr == 47)) {
				Next_L(&lex, &(*s), s_tag, Scanner_Slash_cnst);
			} else if ((o7_case_expr == 46)) {
				Next_Li(&lex, &(*s), s_tag, (char unsigned)'.', Scanner_Range_cnst, Scanner_Dot_cnst);
			} else if ((o7_case_expr == 44)) {
				Next_L(&lex, &(*s), s_tag, Scanner_Comma_cnst);
			} else if ((o7_case_expr == 58)) {
				Next_Li(&lex, &(*s), s_tag, (char unsigned)'=', Scanner_Assign_cnst, Scanner_Colon_cnst);
			} else if ((o7_case_expr == 59)) {
				Next_L(&lex, &(*s), s_tag, Scanner_Semicolon_cnst);
			} else if ((o7_case_expr == 94)) {
				Next_L(&lex, &(*s), s_tag, Scanner_Dereference_cnst);
			} else if ((o7_case_expr == 61)) {
				Next_L(&lex, &(*s), s_tag, Scanner_Equal_cnst);
			} else if ((o7_case_expr == 35)) {
				Next_L(&lex, &(*s), s_tag, Scanner_Inequal_cnst);
			} else if ((o7_case_expr == 126)) {
				Next_L(&lex, &(*s), s_tag, Scanner_Negate_cnst);
			} else if ((o7_case_expr == 60)) {
				Next_Li(&lex, &(*s), s_tag, (char unsigned)'=', Scanner_LessEqual_cnst, Scanner_Less_cnst);
			} else if ((o7_case_expr == 62)) {
				Next_Li(&lex, &(*s), s_tag, (char unsigned)'=', Scanner_GreaterEqual_cnst, Scanner_Greater_cnst);
			} else if ((o7_case_expr == 38)) {
				Next_L(&lex, &(*s), s_tag, Scanner_And_cnst);
			} else if ((o7_case_expr == 124)) {
				Next_L(&lex, &(*s), s_tag, Scanner_Alternative_cnst);
			} else if ((o7_case_expr == 40)) {
				Next_L(&lex, &(*s), s_tag, Scanner_Brace1Open_cnst);
			} else if ((o7_case_expr == 41)) {
				Next_L(&lex, &(*s), s_tag, Scanner_Brace1Close_cnst);
			} else if ((o7_case_expr == 91)) {
				Next_L(&lex, &(*s), s_tag, Scanner_Brace2Open_cnst);
			} else if ((o7_case_expr == 93)) {
				Next_L(&lex, &(*s), s_tag, Scanner_Brace2Close_cnst);
			} else if ((o7_case_expr == 123)) {
				Next_L(&lex, &(*s), s_tag, Scanner_Brace3Open_cnst);
			} else if ((o7_case_expr == 125)) {
				Next_L(&lex, &(*s), s_tag, Scanner_Brace3Close_cnst);
			} else if ((o7_case_expr == 34)) {
				lex = ScanString(&(*s), s_tag);
			} else assert(0); 
		}
		(*s).lexEnd = (*s).ind;
		(*s).lexLen = (*s).lexEnd + (int)((*s).lexEnd < (*s).lexStart) * (sizeof((*s).buf) / sizeof ((*s).buf[0]) - 1) - (*s).lexStart;
		assert((*s).lexLen > 0);
		(*s).column = (*s).column + (*s).lexLen;
		assert((*s).column >= 0);
	}
	return lex;
}

extern void Scanner_init_(void) {
	static int initialized__ = 0;
	if (0 == initialized__) {
		V_init_();
		VDataStream_init_();
		Utf8_init_();
		TranslatorLimits_init_();
		Log_init_();

		o7c_tag_init(Scanner_Scanner_tag, V_Base_tag);

		assert(TranslatorLimits_MaxLenName_cnst < Scanner_BlockSize_cnst);
	}
	++initialized__;
}


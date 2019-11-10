#include <o7.h>

#include "OberonSpecIdent.h"

static o7_bool Eq(o7_int_t str_len0, o7_char str[/*len0*/], o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t ind, o7_int_t end) {
	o7_int_t i, j;

	O7_ASSERT(str_len0 <= o7_div(buf_len0, 2));
	j = 1;
	i = o7_add(ind, 1);
	while (1) if ((j < str_len0) && (buf[o7_ind(buf_len0, i)] == str[o7_ind(str_len0, j)])) {
		i = o7_add(i, 1);
		j = o7_add(j, 1);
	} else if (buf[o7_ind(buf_len0, i)] == 0x0Cu) {
		i = 0;
	} else break;
	return (buf[o7_ind(buf_len0, i)] == 0x08u) && ((j == str_len0) || (str[o7_ind(str_len0, j)] == 0x00u));
}

static o7_bool O(o7_int_t *lex, o7_int_t str_len0, o7_char str[/*len0*/], o7_int_t l, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t ind, o7_int_t end) {
	o7_bool spec;

	spec = Eq(str_len0, str, buf_len0, buf, ind, end);
	if (spec) {
		(*lex) = l;
	}
	return spec;
}

static o7_bool T(o7_int_t *lex, o7_int_t s1_len0, o7_char s1[/*len0*/], o7_int_t l1, o7_int_t s2_len0, o7_char s2[/*len0*/], o7_int_t l2, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t ind, o7_int_t end) {
	o7_bool spec;

	if (Eq(s1_len0, s1, buf_len0, buf, ind, end)) {
		spec = (0 < 1);
		(*lex) = l1;
	} else if (Eq(s2_len0, s2, buf_len0, buf, ind, end)) {
		spec = (0 < 1);
		(*lex) = l2;
	} else {
		spec = (0 > 1);
	}
	return spec;
}

extern o7_bool OberonSpecIdent_IsKeyWord(o7_int_t *kw, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t ind, o7_int_t end) {
	o7_char save;
	o7_bool spec;

	save = buf[o7_ind(buf_len0, end)];
	buf[o7_ind(buf_len0, end)] = 0x08u;
	{ o7_int_t o7_case_expr = buf[o7_ind(buf_len0, ind)];
		switch (o7_case_expr) {
		case 65:
			spec = O(&(*kw), 6, (o7_char *)"ARRAY", OberonSpecIdent_Array_cnst, buf_len0, buf, ind, end);
			break;
		case 66:
			spec = T(&(*kw), 6, (o7_char *)"BEGIN", OberonSpecIdent_Begin_cnst, 3, (o7_char *)"BY", OberonSpecIdent_By_cnst, buf_len0, buf, ind, end);
			break;
		case 67:
			spec = T(&(*kw), 5, (o7_char *)"CASE", OberonSpecIdent_Case_cnst, 6, (o7_char *)"CONST", OberonSpecIdent_Const_cnst, buf_len0, buf, ind, end);
			break;
		case 68:
			spec = T(&(*kw), 4, (o7_char *)"DIV", OberonSpecIdent_Div_cnst, 3, (o7_char *)"DO", OberonSpecIdent_Do_cnst, buf_len0, buf, ind, end);
			break;
		case 69:
			if (Eq(5, (o7_char *)"ELSE", buf_len0, buf, ind, end)) {
				spec = (0 < 1);
				(*kw) = OberonSpecIdent_Else_cnst;
			} else {
				spec = T(&(*kw), 6, (o7_char *)"ELSIF", OberonSpecIdent_Elsif_cnst, 4, (o7_char *)"END", OberonSpecIdent_End_cnst, buf_len0, buf, ind, end);
			}
			break;
		case 70:
			spec = T(&(*kw), 6, (o7_char *)"FALSE", OberonSpecIdent_False_cnst, 4, (o7_char *)"FOR", OberonSpecIdent_For_cnst, buf_len0, buf, ind, end);
			break;
		case 73:
			if (Eq(3, (o7_char *)"IF", buf_len0, buf, ind, end)) {
				spec = (0 < 1);
				(*kw) = OberonSpecIdent_If_cnst;
			} else if (Eq(7, (o7_char *)"IMPORT", buf_len0, buf, ind, end)) {
				spec = (0 < 1);
				(*kw) = OberonSpecIdent_Import_cnst;
			} else {
				spec = T(&(*kw), 3, (o7_char *)"IN", OberonSpecIdent_In_cnst, 3, (o7_char *)"IS", OberonSpecIdent_Is_cnst, buf_len0, buf, ind, end);
			}
			break;
		case 77:
			spec = T(&(*kw), 4, (o7_char *)"MOD", OberonSpecIdent_Mod_cnst, 7, (o7_char *)"MODULE", OberonSpecIdent_Module_cnst, buf_len0, buf, ind, end);
			break;
		case 78:
			spec = O(&(*kw), 4, (o7_char *)"NIL", OberonSpecIdent_Nil_cnst, buf_len0, buf, ind, end);
			break;
		case 79:
			spec = T(&(*kw), 3, (o7_char *)"OF", OberonSpecIdent_Of_cnst, 3, (o7_char *)"OR", OberonSpecIdent_Or_cnst, buf_len0, buf, ind, end);
			break;
		case 80:
			spec = T(&(*kw), 8, (o7_char *)"POINTER", OberonSpecIdent_Pointer_cnst, 10, (o7_char *)"PROCEDURE", OberonSpecIdent_Procedure_cnst, buf_len0, buf, ind, end);
			break;
		case 82:
			if (Eq(7, (o7_char *)"RECORD", buf_len0, buf, ind, end)) {
				spec = (0 < 1);
				(*kw) = OberonSpecIdent_Record_cnst;
			} else {
				spec = T(&(*kw), 7, (o7_char *)"REPEAT", OberonSpecIdent_Repeat_cnst, 7, (o7_char *)"RETURN", OberonSpecIdent_Return_cnst, buf_len0, buf, ind, end);
			}
			break;
		case 84:
			if (Eq(5, (o7_char *)"THEN", buf_len0, buf, ind, end)) {
				spec = (0 < 1);
				(*kw) = OberonSpecIdent_Then_cnst;
			} else if (Eq(3, (o7_char *)"TO", buf_len0, buf, ind, end)) {
				spec = (0 < 1);
				(*kw) = OberonSpecIdent_To_cnst;
			} else {
				spec = T(&(*kw), 5, (o7_char *)"TRUE", OberonSpecIdent_True_cnst, 5, (o7_char *)"TYPE", OberonSpecIdent_Type_cnst, buf_len0, buf, ind, end);
			}
			break;
		case 85:
			spec = O(&(*kw), 6, (o7_char *)"UNTIL", OberonSpecIdent_Until_cnst, buf_len0, buf, ind, end);
			break;
		case 86:
			spec = O(&(*kw), 4, (o7_char *)"VAR", OberonSpecIdent_Var_cnst, buf_len0, buf, ind, end);
			break;
		case 87:
			spec = O(&(*kw), 6, (o7_char *)"WHILE", OberonSpecIdent_While_cnst, buf_len0, buf, ind, end);
			break;
		default:
			if ((0 <= o7_case_expr && o7_case_expr <= 64) || (o7_case_expr == 71) || (o7_case_expr == 72) || (74 <= o7_case_expr && o7_case_expr <= 76) || (o7_case_expr == 81) || (o7_case_expr == 83) || (88 <= o7_case_expr && o7_case_expr <= 255)) {
				spec = (0 > 1);
			} else o7_case_fail(o7_case_expr);
			break;
		}
	}
	buf[o7_ind(buf_len0, end)] = save;
	return spec;
}

extern o7_bool OberonSpecIdent_IsPredefined(o7_int_t *pd, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t begin, o7_int_t end) {
	o7_char save;
	o7_bool spec;

	save = buf[o7_ind(buf_len0, end)];
	buf[o7_ind(buf_len0, end)] = 0x08u;
	{ o7_int_t o7_case_expr = buf[o7_ind(buf_len0, begin)];
		switch (o7_case_expr) {
		case 65:
			if (Eq(4, (o7_char *)"ABS", buf_len0, buf, begin, end)) {
				spec = (0 < 1);
				(*pd) = OberonSpecIdent_Abs_cnst;
			} else {
				spec = T(&(*pd), 4, (o7_char *)"ASR", OberonSpecIdent_Asr_cnst, 7, (o7_char *)"ASSERT", OberonSpecIdent_Assert_cnst, buf_len0, buf, begin, end);
			}
			break;
		case 66:
			spec = T(&(*pd), 8, (o7_char *)"BOOLEAN", OberonSpecIdent_Boolean_cnst, 5, (o7_char *)"BYTE", OberonSpecIdent_Byte_cnst, buf_len0, buf, begin, end);
			break;
		case 67:
			spec = T(&(*pd), 5, (o7_char *)"CHAR", OberonSpecIdent_Char_cnst, 4, (o7_char *)"CHR", OberonSpecIdent_Chr_cnst, buf_len0, buf, begin, end);
			break;
		case 68:
			spec = O(&(*pd), 4, (o7_char *)"DEC", OberonSpecIdent_Dec_cnst, buf_len0, buf, begin, end);
			break;
		case 69:
			spec = O(&(*pd), 5, (o7_char *)"EXCL", OberonSpecIdent_Excl_cnst, buf_len0, buf, begin, end);
			break;
		case 70:
			spec = T(&(*pd), 6, (o7_char *)"FLOOR", OberonSpecIdent_Floor_cnst, 4, (o7_char *)"FLT", OberonSpecIdent_Flt_cnst, buf_len0, buf, begin, end);
			break;
		case 73:
			if (Eq(4, (o7_char *)"INC", buf_len0, buf, begin, end)) {
				spec = (0 < 1);
				(*pd) = OberonSpecIdent_Inc_cnst;
			} else {
				spec = T(&(*pd), 5, (o7_char *)"INCL", OberonSpecIdent_Incl_cnst, 8, (o7_char *)"INTEGER", OberonSpecIdent_Integer_cnst, buf_len0, buf, begin, end);
			}
			break;
		case 76:
			spec = T(&(*pd), 4, (o7_char *)"LEN", OberonSpecIdent_Len_cnst, 4, (o7_char *)"LSL", OberonSpecIdent_Lsl_cnst, buf_len0, buf, begin, end);
			break;
		case 78:
			spec = O(&(*pd), 4, (o7_char *)"NEW", OberonSpecIdent_New_cnst, buf_len0, buf, begin, end);
			break;
		case 79:
			spec = T(&(*pd), 4, (o7_char *)"ODD", OberonSpecIdent_Odd_cnst, 4, (o7_char *)"ORD", OberonSpecIdent_Ord_cnst, buf_len0, buf, begin, end);
			break;
		case 80:
			spec = O(&(*pd), 5, (o7_char *)"PACK", OberonSpecIdent_Pack_cnst, buf_len0, buf, begin, end);
			break;
		case 82:
			spec = T(&(*pd), 5, (o7_char *)"REAL", OberonSpecIdent_Real_cnst, 4, (o7_char *)"ROR", OberonSpecIdent_Ror_cnst, buf_len0, buf, begin, end);
			break;
		case 83:
			spec = O(&(*pd), 4, (o7_char *)"SET", OberonSpecIdent_Set_cnst, buf_len0, buf, begin, end);
			break;
		case 85:
			spec = O(&(*pd), 5, (o7_char *)"UNPK", OberonSpecIdent_Unpk_cnst, buf_len0, buf, begin, end);
			break;
		default:
			if ((o7_case_expr == 71) || (o7_case_expr == 72) || (o7_case_expr == 74) || (o7_case_expr == 75) || (o7_case_expr == 77) || (o7_case_expr == 81) || (o7_case_expr == 84) || (86 <= o7_case_expr && o7_case_expr <= 90) || (97 <= o7_case_expr && o7_case_expr <= 122) || (192 <= o7_case_expr && o7_case_expr <= 255)) {
				spec = (0 > 1);
			} else o7_case_fail(o7_case_expr);
			break;
		}
	}
	buf[o7_ind(buf_len0, end)] = save;
	return spec;
}

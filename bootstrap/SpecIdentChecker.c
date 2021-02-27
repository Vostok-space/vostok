#if !defined(O7_INIT_MODEL)
#   define   O7_INIT_MODEL O7_INIT_ZERO
#endif

#include <o7.h>

#include "SpecIdentChecker.h"

static o7_bool Eq(struct StringStore_String *name, o7_int_t str_len0, o7_char str[/*len0*/]) {
	return StringStore_IsEqualToString(name, str_len0, str);
}

static o7_bool EqIc(struct StringStore_String *name, o7_int_t str_len0, o7_char str[/*len0*/]) {
	return StringStore_IsEqualToStringIgnoreCase(name, str_len0, str);
}

extern o7_bool SpecIdentChecker_IsCKeyWord(struct StringStore_String *n) {
	o7_bool o;

	{ o7_int_t o7_case_expr = n->block->s[o7_ind(StringStore_BlockSize_cnst + 1, n->ofs)];
		switch (o7_case_expr) {
		case 97:
			o = Eq(n, 5, (o7_char *)"auto") || Eq(n, 4, (o7_char *)"asm");
			break;
		case 98:
			o = Eq(n, 6, (o7_char *)"break");
			break;
		case 99:
			o = Eq(n, 5, (o7_char *)"case") || Eq(n, 5, (o7_char *)"char") || Eq(n, 6, (o7_char *)"const") || Eq(n, 9, (o7_char *)"continue");
			break;
		case 100:
			o = Eq(n, 8, (o7_char *)"default") || Eq(n, 3, (o7_char *)"do") || Eq(n, 7, (o7_char *)"double");
			break;
		case 101:
			o = Eq(n, 5, (o7_char *)"else") || Eq(n, 5, (o7_char *)"enum") || Eq(n, 7, (o7_char *)"extern");
			break;
		case 102:
			o = Eq(n, 6, (o7_char *)"float") || Eq(n, 4, (o7_char *)"for");
			break;
		case 103:
			o = Eq(n, 5, (o7_char *)"goto");
			break;
		case 105:
			o = Eq(n, 3, (o7_char *)"if") || Eq(n, 7, (o7_char *)"inline") || Eq(n, 4, (o7_char *)"int");
			break;
		case 108:
			o = Eq(n, 5, (o7_char *)"long");
			break;
		case 114:
			o = Eq(n, 9, (o7_char *)"register") || Eq(n, 9, (o7_char *)"restrict") || Eq(n, 7, (o7_char *)"return");
			break;
		case 115:
			o = Eq(n, 6, (o7_char *)"short") || Eq(n, 7, (o7_char *)"signed") || Eq(n, 7, (o7_char *)"sizeof") || Eq(n, 7, (o7_char *)"static") || Eq(n, 7, (o7_char *)"struct") || Eq(n, 7, (o7_char *)"switch");
			break;
		case 116:
			o = Eq(n, 8, (o7_char *)"typedef") || Eq(n, 7, (o7_char *)"typeof");
			break;
		case 117:
			o = Eq(n, 6, (o7_char *)"union") || Eq(n, 9, (o7_char *)"unsigned");
			break;
		case 118:
			o = Eq(n, 5, (o7_char *)"void") || Eq(n, 9, (o7_char *)"volatile");
			break;
		case 119:
			o = Eq(n, 6, (o7_char *)"while");
			break;
		default:
			if ((o7_case_expr == 104) || (o7_case_expr == 106) || (o7_case_expr == 107) || (109 <= o7_case_expr && o7_case_expr <= 113) || (120 <= o7_case_expr && o7_case_expr <= 122)) {
				o = (0 > 1);
			} else o7_case_fail(o7_case_expr);
			break;
		}
	}
	return o;
}

extern o7_bool SpecIdentChecker_IsCLib(struct StringStore_String *n) {
	o7_bool o;

	{ o7_int_t o7_case_expr = n->block->s[o7_ind(StringStore_BlockSize_cnst + 1, n->ofs)];
		switch (o7_case_expr) {
		case 97:
			o = Eq(n, 6, (o7_char *)"abort") || Eq(n, 7, (o7_char *)"assert") || Eq(n, 5, (o7_char *)"atof") || Eq(n, 5, (o7_char *)"atoi") || Eq(n, 5, (o7_char *)"atol") || Eq(n, 6, (o7_char *)"atoll") || Eq(n, 4, (o7_char *)"abs") || Eq(n, 7, (o7_char *)"atexit");
			break;
		case 98:
			o = Eq(n, 5, (o7_char *)"bool") || Eq(n, 8, (o7_char *)"bsearch");
			break;
		case 99:
			o = Eq(n, 7, (o7_char *)"calloc");
			break;
		case 100:
			o = Eq(n, 4, (o7_char *)"div");
			break;
		case 101:
			o = Eq(n, 6, (o7_char *)"errno") || Eq(n, 5, (o7_char *)"exit");
			break;
		case 102:
			o = Eq(n, 5, (o7_char *)"free") || Eq(n, 6, (o7_char *)"fputc") || Eq(n, 6, (o7_char *)"fputs");
			break;
		case 103:
			o = Eq(n, 7, (o7_char *)"getenv");
			break;
		case 108:
			o = Eq(n, 5, (o7_char *)"labs") || Eq(n, 5, (o7_char *)"ldiv") || Eq(n, 6, (o7_char *)"llabs") || Eq(n, 6, (o7_char *)"lldiv");
			break;
		case 109:
			o = Eq(n, 5, (o7_char *)"main") || Eq(n, 7, (o7_char *)"malloc") || Eq(n, 7, (o7_char *)"memchr") || Eq(n, 7, (o7_char *)"memcmp") || Eq(n, 7, (o7_char *)"memcpy") || Eq(n, 7, (o7_char *)"memset") || Eq(n, 6, (o7_char *)"mblen") || Eq(n, 7, (o7_char *)"mbtowc") || Eq(n, 9, (o7_char *)"mbstowcs");
			break;
		case 112:
			o = Eq(n, 5, (o7_char *)"putc") || Eq(n, 8, (o7_char *)"putchar") || Eq(n, 5, (o7_char *)"puts");
			break;
		case 113:
			o = Eq(n, 6, (o7_char *)"qsort");
			break;
		case 114:
			o = Eq(n, 5, (o7_char *)"rand") || Eq(n, 8, (o7_char *)"realloc");
			break;
		case 115:
			o = Eq(n, 8, (o7_char *)"strcspn") || Eq(n, 9, (o7_char *)"strerror") || Eq(n, 7, (o7_char *)"strspn") || Eq(n, 8, (o7_char *)"strrchr") || Eq(n, 8, (o7_char *)"strpbrk") || Eq(n, 7, (o7_char *)"strchr") || Eq(n, 7, (o7_char *)"strcat") || Eq(n, 7, (o7_char *)"strstr") || Eq(n, 8, (o7_char *)"strncat") || Eq(n, 7, (o7_char *)"strcmp") || Eq(n, 8, (o7_char *)"strcoll") || Eq(n, 7, (o7_char *)"strcpy") || Eq(n, 8, (o7_char *)"strncpy") || Eq(n, 7, (o7_char *)"strlen") || Eq(n, 7, (o7_char *)"strtok") || Eq(n, 7, (o7_char *)"strtol") || Eq(n, 8, (o7_char *)"strtoll") || Eq(n, 8, (o7_char *)"strtoul") || Eq(n, 9, (o7_char *)"strtoull") || Eq(n, 7, (o7_char *)"strtod") || Eq(n, 7, (o7_char *)"strtof") || Eq(n, 8, (o7_char *)"strtold") || Eq(n, 8, (o7_char *)"strxfrm") || Eq(n, 6, (o7_char *)"srand") || Eq(n, 7, (o7_char *)"system");
			break;
		case 119:
			o = Eq(n, 7, (o7_char *)"wctomb") || Eq(n, 9, (o7_char *)"wcstombs");
			break;
		default:
			if ((o7_case_expr == 104) || (105 <= o7_case_expr && o7_case_expr <= 107) || (110 <= o7_case_expr && o7_case_expr <= 111) || (116 <= o7_case_expr && o7_case_expr <= 118) || (120 <= o7_case_expr && o7_case_expr <= 122)) {
				o = (0 > 1);
			} else o7_case_fail(o7_case_expr);
			break;
		}
	}
	return o;
}

extern o7_bool SpecIdentChecker_IsCMath(struct StringStore_String *n) {
	o7_bool o;

	{ o7_int_t o7_case_expr = n->block->s[o7_ind(StringStore_BlockSize_cnst + 1, n->ofs)];
		switch (o7_case_expr) {
		case 97:
			o = Eq(n, 5, (o7_char *)"acos") || Eq(n, 6, (o7_char *)"acosf") || Eq(n, 6, (o7_char *)"acosl") || Eq(n, 6, (o7_char *)"acosh") || Eq(n, 7, (o7_char *)"acoshf") || Eq(n, 7, (o7_char *)"acoshl") || Eq(n, 5, (o7_char *)"asin") || Eq(n, 6, (o7_char *)"asinf") || Eq(n, 6, (o7_char *)"asinl") || Eq(n, 6, (o7_char *)"asinh") || Eq(n, 7, (o7_char *)"asinhf") || Eq(n, 7, (o7_char *)"asinhl") || Eq(n, 5, (o7_char *)"atan") || Eq(n, 6, (o7_char *)"atanf") || Eq(n, 6, (o7_char *)"atanl") || Eq(n, 6, (o7_char *)"atan2") || Eq(n, 7, (o7_char *)"atan2f") || Eq(n, 7, (o7_char *)"atan2l") || Eq(n, 6, (o7_char *)"atanh") || Eq(n, 7, (o7_char *)"atanhf") || Eq(n, 7, (o7_char *)"atanhl");
			break;
		case 99:
			o = Eq(n, 5, (o7_char *)"cbrt") || Eq(n, 6, (o7_char *)"cbrtf") || Eq(n, 6, (o7_char *)"cbrtl") || Eq(n, 5, (o7_char *)"ceil") || Eq(n, 6, (o7_char *)"ceilf") || Eq(n, 6, (o7_char *)"ceill") || Eq(n, 9, (o7_char *)"copysign") || Eq(n, 10, (o7_char *)"copysignf") || Eq(n, 10, (o7_char *)"copysignl") || Eq(n, 4, (o7_char *)"cos") || Eq(n, 5, (o7_char *)"cosf") || Eq(n, 5, (o7_char *)"cosl") || Eq(n, 5, (o7_char *)"cosh") || Eq(n, 6, (o7_char *)"coshf") || Eq(n, 6, (o7_char *)"coshl");
			break;
		case 101:
			o = Eq(n, 4, (o7_char *)"erf") || Eq(n, 5, (o7_char *)"erff") || Eq(n, 5, (o7_char *)"erfl") || Eq(n, 5, (o7_char *)"erfc") || Eq(n, 6, (o7_char *)"erfcf") || Eq(n, 6, (o7_char *)"erfcl") || Eq(n, 4, (o7_char *)"exp") || Eq(n, 5, (o7_char *)"expf") || Eq(n, 5, (o7_char *)"expl") || Eq(n, 5, (o7_char *)"exp2") || Eq(n, 6, (o7_char *)"exp2f") || Eq(n, 6, (o7_char *)"exp2l") || Eq(n, 6, (o7_char *)"expm1") || Eq(n, 7, (o7_char *)"expm1f") || Eq(n, 7, (o7_char *)"expm1l");
			break;
		case 102:
			o = Eq(n, 5, (o7_char *)"fabs") || Eq(n, 6, (o7_char *)"fabsf") || Eq(n, 6, (o7_char *)"fabsl") || Eq(n, 5, (o7_char *)"fdim") || Eq(n, 6, (o7_char *)"fdimf") || Eq(n, 6, (o7_char *)"fdiml") || Eq(n, 6, (o7_char *)"floor") || Eq(n, 7, (o7_char *)"floorf") || Eq(n, 7, (o7_char *)"floorl") || Eq(n, 5, (o7_char *)"fmax") || Eq(n, 6, (o7_char *)"fmaxf") || Eq(n, 6, (o7_char *)"fmaxl") || Eq(n, 5, (o7_char *)"fmin") || Eq(n, 6, (o7_char *)"fminf") || Eq(n, 6, (o7_char *)"fminl") || Eq(n, 4, (o7_char *)"fma") || Eq(n, 5, (o7_char *)"fmaf") || Eq(n, 5, (o7_char *)"fmal") || Eq(n, 5, (o7_char *)"fmod") || Eq(n, 6, (o7_char *)"fmodf") || Eq(n, 6, (o7_char *)"fmodl") || Eq(n, 11, (o7_char *)"fpclassify") || Eq(n, 6, (o7_char *)"frexp") || Eq(n, 7, (o7_char *)"frexpf") || Eq(n, 7, (o7_char *)"frexpl");
			break;
		case 104:
			o = Eq(n, 6, (o7_char *)"hypot") || Eq(n, 7, (o7_char *)"hypotf") || Eq(n, 7, (o7_char *)"hypotl");
			break;
		case 105:
			o = Eq(n, 6, (o7_char *)"ilogb") || Eq(n, 7, (o7_char *)"ilogbf") || Eq(n, 7, (o7_char *)"ilogbl") || Eq(n, 10, (o7_char *)"isgreater") || Eq(n, 15, (o7_char *)"isgreaterequal") || Eq(n, 9, (o7_char *)"isfinite") || Eq(n, 6, (o7_char *)"isinf") || Eq(n, 7, (o7_char *)"isless") || Eq(n, 12, (o7_char *)"islessequal") || Eq(n, 14, (o7_char *)"islessgreater") || Eq(n, 6, (o7_char *)"isnan") || Eq(n, 9, (o7_char *)"isnormal");
			break;
		case 108:
			o = Eq(n, 6, (o7_char *)"ldexp") || Eq(n, 7, (o7_char *)"ldexpf") || Eq(n, 7, (o7_char *)"ldexpl") || Eq(n, 7, (o7_char *)"lgamma") || Eq(n, 8, (o7_char *)"lgammaf") || Eq(n, 8, (o7_char *)"lgammal") || Eq(n, 4, (o7_char *)"log") || Eq(n, 5, (o7_char *)"logf") || Eq(n, 5, (o7_char *)"logl") || Eq(n, 6, (o7_char *)"log10") || Eq(n, 7, (o7_char *)"log10f") || Eq(n, 7, (o7_char *)"log10l") || Eq(n, 6, (o7_char *)"log1p") || Eq(n, 7, (o7_char *)"log1pf") || Eq(n, 7, (o7_char *)"log1pl") || Eq(n, 5, (o7_char *)"log2") || Eq(n, 6, (o7_char *)"log2f") || Eq(n, 6, (o7_char *)"log2l") || Eq(n, 5, (o7_char *)"logb") || Eq(n, 6, (o7_char *)"logbf") || Eq(n, 6, (o7_char *)"logbl") || Eq(n, 7, (o7_char *)"lround") || Eq(n, 8, (o7_char *)"lroundf") || Eq(n, 8, (o7_char *)"lroundl") || Eq(n, 8, (o7_char *)"llround") || Eq(n, 9, (o7_char *)"llroundf") || Eq(n, 9, (o7_char *)"llroundl") || Eq(n, 6, (o7_char *)"lrint") || Eq(n, 7, (o7_char *)"lrintf") || Eq(n, 7, (o7_char *)"lrintl") || Eq(n, 7, (o7_char *)"llrint") || Eq(n, 8, (o7_char *)"llrintf") || Eq(n, 8, (o7_char *)"llrintl");
			break;
		case 109:
			o = Eq(n, 5, (o7_char *)"modf") || Eq(n, 6, (o7_char *)"modff") || Eq(n, 6, (o7_char *)"modfl");
			break;
		case 110:
			o = Eq(n, 4, (o7_char *)"nan") || Eq(n, 5, (o7_char *)"nanf") || Eq(n, 5, (o7_char *)"nanl") || Eq(n, 10, (o7_char *)"nearbyint") || Eq(n, 11, (o7_char *)"nearbyintf") || Eq(n, 11, (o7_char *)"nearbyintl") || Eq(n, 10, (o7_char *)"nextafter") || Eq(n, 11, (o7_char *)"nextafterf") || Eq(n, 11, (o7_char *)"nextafterl") || Eq(n, 11, (o7_char *)"nexttoward") || Eq(n, 12, (o7_char *)"nexttowardf") || Eq(n, 12, (o7_char *)"nexttowardl");
			break;
		case 112:
			o = Eq(n, 4, (o7_char *)"pow") || Eq(n, 5, (o7_char *)"powf") || Eq(n, 5, (o7_char *)"powl");
			break;
		case 114:
			o = Eq(n, 10, (o7_char *)"remainder") || Eq(n, 11, (o7_char *)"remainderf") || Eq(n, 11, (o7_char *)"remainderl") || Eq(n, 7, (o7_char *)"remquo") || Eq(n, 8, (o7_char *)"remquof") || Eq(n, 8, (o7_char *)"remquol") || Eq(n, 5, (o7_char *)"rint") || Eq(n, 6, (o7_char *)"rintf") || Eq(n, 6, (o7_char *)"rintl") || Eq(n, 6, (o7_char *)"round") || Eq(n, 7, (o7_char *)"roundf") || Eq(n, 7, (o7_char *)"roundl");
			break;
		case 115:
			o = Eq(n, 7, (o7_char *)"scalbn") || Eq(n, 8, (o7_char *)"scalbnf") || Eq(n, 8, (o7_char *)"scalbnl") || Eq(n, 8, (o7_char *)"scalbln") || Eq(n, 9, (o7_char *)"scalblnf") || Eq(n, 9, (o7_char *)"scalblnl") || Eq(n, 8, (o7_char *)"signbit") || Eq(n, 4, (o7_char *)"sin") || Eq(n, 5, (o7_char *)"sinf") || Eq(n, 5, (o7_char *)"sinl") || Eq(n, 5, (o7_char *)"sinh") || Eq(n, 6, (o7_char *)"sinhf") || Eq(n, 6, (o7_char *)"sinhl") || Eq(n, 5, (o7_char *)"sqrt") || Eq(n, 6, (o7_char *)"sqrtf") || Eq(n, 6, (o7_char *)"sqrtl");
			break;
		case 116:
			o = Eq(n, 4, (o7_char *)"tan") || Eq(n, 5, (o7_char *)"tanf") || Eq(n, 5, (o7_char *)"tanl") || Eq(n, 5, (o7_char *)"tanh") || Eq(n, 6, (o7_char *)"tanhf") || Eq(n, 6, (o7_char *)"tanhl") || Eq(n, 7, (o7_char *)"tgamma") || Eq(n, 8, (o7_char *)"tgammaf") || Eq(n, 8, (o7_char *)"tgammal") || Eq(n, 6, (o7_char *)"trunc") || Eq(n, 7, (o7_char *)"truncf") || Eq(n, 7, (o7_char *)"truncl");
			break;
		default:
			if ((o7_case_expr == 98) || (o7_case_expr == 100) || (o7_case_expr == 103) || (o7_case_expr == 106) || (o7_case_expr == 107) || (o7_case_expr == 111) || (o7_case_expr == 113) || (117 <= o7_case_expr && o7_case_expr <= 122)) {
				o = (0 > 1);
			} else o7_case_fail(o7_case_expr);
			break;
		}
	}
	return o;
}

extern o7_bool SpecIdentChecker_IsCMacros(struct StringStore_String *n) {
	return Eq(n, 5, (o7_char *)"unix") || Eq(n, 6, (o7_char *)"linux") || Eq(n, 4, (o7_char *)"BSD");
}

extern o7_bool SpecIdentChecker_IsCppKeyWord(struct StringStore_String *n) {
	o7_bool o;

	{ o7_int_t o7_case_expr = n->block->s[o7_ind(StringStore_BlockSize_cnst + 1, n->ofs)];
		switch (o7_case_expr) {
		case 97:
			o = Eq(n, 6, (o7_char *)"array");
			break;
		case 99:
			o = Eq(n, 6, (o7_char *)"catch") || Eq(n, 6, (o7_char *)"class");
			break;
		case 100:
			o = Eq(n, 9, (o7_char *)"decltype") || Eq(n, 9, (o7_char *)"delegate") || Eq(n, 7, (o7_char *)"delete") || Eq(n, 11, (o7_char *)"deprecated") || Eq(n, 10, (o7_char *)"dllexport") || Eq(n, 10, (o7_char *)"dllimport") || Eq(n, 10, (o7_char *)"dllexport");
			break;
		case 101:
			o = Eq(n, 6, (o7_char *)"event") || Eq(n, 9, (o7_char *)"explicit") || Eq(n, 5, (o7_char *)"each");
			break;
		case 102:
			o = Eq(n, 8, (o7_char *)"finally") || Eq(n, 7, (o7_char *)"friend");
			break;
		case 103:
			o = Eq(n, 6, (o7_char *)"gcnew") || Eq(n, 8, (o7_char *)"generic");
			break;
		case 105:
			o = Eq(n, 3, (o7_char *)"in") || Eq(n, 9, (o7_char *)"initonly") || Eq(n, 10, (o7_char *)"interface");
			break;
		case 108:
			o = Eq(n, 8, (o7_char *)"literal");
			break;
		case 109:
			o = Eq(n, 8, (o7_char *)"mutable");
			break;
		case 110:
			o = Eq(n, 6, (o7_char *)"naked") || Eq(n, 10, (o7_char *)"namespace") || Eq(n, 4, (o7_char *)"new") || Eq(n, 9, (o7_char *)"noinline") || Eq(n, 9, (o7_char *)"noreturn") || Eq(n, 8, (o7_char *)"nothrow") || Eq(n, 9, (o7_char *)"novtable") || Eq(n, 8, (o7_char *)"nullptr");
			break;
		case 111:
			o = Eq(n, 9, (o7_char *)"operator");
			break;
		case 112:
			o = Eq(n, 8, (o7_char *)"private") || Eq(n, 9, (o7_char *)"property") || Eq(n, 10, (o7_char *)"protected") || Eq(n, 7, (o7_char *)"public");
			break;
		case 114:
			o = Eq(n, 4, (o7_char *)"ref");
			break;
		case 115:
			o = Eq(n, 9, (o7_char *)"safecast") || Eq(n, 7, (o7_char *)"sealed") || Eq(n, 10, (o7_char *)"selectany") || Eq(n, 6, (o7_char *)"super");
			break;
		case 116:
			o = Eq(n, 9, (o7_char *)"template") || Eq(n, 5, (o7_char *)"this") || Eq(n, 7, (o7_char *)"thread") || Eq(n, 6, (o7_char *)"throw") || Eq(n, 4, (o7_char *)"try") || Eq(n, 7, (o7_char *)"typeid") || Eq(n, 9, (o7_char *)"typename");
			break;
		case 117:
			o = Eq(n, 5, (o7_char *)"uuid");
			break;
		case 118:
			o = Eq(n, 6, (o7_char *)"value") || Eq(n, 8, (o7_char *)"virtual");
			break;
		default:
			if ((o7_case_expr == 98) || (o7_case_expr == 104) || (o7_case_expr == 106) || (o7_case_expr == 107) || (o7_case_expr == 113) || (119 <= o7_case_expr && o7_case_expr <= 122)) {
				o = (0 > 1);
			} else o7_case_fail(o7_case_expr);
			break;
		}
	}
	return o;
}

extern o7_bool SpecIdentChecker_IsJsKeyWord(struct StringStore_String *n) {
	o7_bool o;

	{ o7_int_t o7_case_expr = n->block->s[o7_ind(StringStore_BlockSize_cnst + 1, n->ofs)];
		switch (o7_case_expr) {
		case 97:
			o = Eq(n, 9, (o7_char *)"abstract") || Eq(n, 10, (o7_char *)"arguments");
			break;
		case 98:
			o = Eq(n, 8, (o7_char *)"boolean") || Eq(n, 5, (o7_char *)"byte");
			break;
		case 100:
			o = Eq(n, 9, (o7_char *)"debugger");
			break;
		case 101:
			o = Eq(n, 5, (o7_char *)"eval") || Eq(n, 7, (o7_char *)"export") || Eq(n, 8, (o7_char *)"extends");
			break;
		case 102:
			o = Eq(n, 6, (o7_char *)"final") || Eq(n, 9, (o7_char *)"function");
			break;
		case 105:
			o = Eq(n, 11, (o7_char *)"implements") || Eq(n, 7, (o7_char *)"import") || Eq(n, 11, (o7_char *)"instanceof") || Eq(n, 10, (o7_char *)"interface");
			break;
		case 108:
			o = Eq(n, 4, (o7_char *)"let");
			break;
		case 110:
			o = Eq(n, 7, (o7_char *)"native") || Eq(n, 5, (o7_char *)"null");
			break;
		case 112:
			o = Eq(n, 8, (o7_char *)"package") || Eq(n, 8, (o7_char *)"private") || Eq(n, 10, (o7_char *)"protected");
			break;
		case 115:
			o = Eq(n, 13, (o7_char *)"synchronized");
			break;
		case 116:
			o = Eq(n, 7, (o7_char *)"throws") || Eq(n, 10, (o7_char *)"transient");
			break;
		case 118:
			o = Eq(n, 4, (o7_char *)"var");
			break;
		default:
			if ((o7_case_expr == 99) || (o7_case_expr == 103) || (o7_case_expr == 104) || (o7_case_expr == 106) || (o7_case_expr == 107) || (o7_case_expr == 109) || (o7_case_expr == 111) || (o7_case_expr == 113) || (o7_case_expr == 114) || (o7_case_expr == 117) || (119 <= o7_case_expr && o7_case_expr <= 122)) {
				o = (0 > 1);
			} else o7_case_fail(o7_case_expr);
			break;
		}
	}
	return o;
}

extern o7_bool SpecIdentChecker_IsJavaLib(struct StringStore_String *n) {
	o7_bool o;

	{ o7_int_t o7_case_expr = n->block->s[o7_ind(StringStore_BlockSize_cnst + 1, n->ofs)];
		switch (o7_case_expr) {
		case 67:
			o = Eq(n, 6, (o7_char *)"Class");
			break;
		case 77:
			o = Eq(n, 5, (o7_char *)"Math");
			break;
		case 83:
			o = Eq(n, 7, (o7_char *)"String");
			break;
		default:
			if ((65 <= o7_case_expr && o7_case_expr <= 66) || (68 <= o7_case_expr && o7_case_expr <= 76) || (78 <= o7_case_expr && o7_case_expr <= 82) || (84 <= o7_case_expr && o7_case_expr <= 90)) {
				o = (0 > 1);
			} else o7_case_fail(o7_case_expr);
			break;
		}
	}
	return o;
}

static o7_bool O7(struct StringStore_String *n) {
	return Eq(n, 12, (o7_char *)"initialized") || Eq(n, 5, (o7_char *)"NULL") || Eq(n, 7, (o7_char *)"module");
}

extern o7_bool SpecIdentChecker_IsSpecName(struct StringStore_String *n, o7_set_t filter) {
	return O7(n) || ((o7_char)'a' <= n->block->s[o7_ind(StringStore_BlockSize_cnst + 1, n->ofs)]) && (n->block->s[o7_ind(StringStore_BlockSize_cnst + 1, n->ofs)] <= (o7_char)'z') && (SpecIdentChecker_IsCKeyWord(n) || SpecIdentChecker_IsCLib(n) || !(!!( (1u << SpecIdentChecker_MathC_cnst) & filter)) && SpecIdentChecker_IsCMath(n) || SpecIdentChecker_IsCMacros(n) || SpecIdentChecker_IsCppKeyWord(n) || SpecIdentChecker_IsJsKeyWord(n));
}

extern o7_bool SpecIdentChecker_IsSpecModuleName(struct StringStore_String *n) {
	return Eq(n, 3, (o7_char *)"O7") || Eq(n, 3, (o7_char *)"o7") || Eq(n, 3, (o7_char *)"ru");
}

extern o7_bool SpecIdentChecker_IsSpecCHeaderName(struct StringStore_String *n) {
	return EqIc(n, 7, (o7_char *)"assert") || EqIc(n, 8, (o7_char *)"complex") || EqIc(n, 6, (o7_char *)"ctype") || EqIc(n, 6, (o7_char *)"errno") || EqIc(n, 5, (o7_char *)"fenv") || EqIc(n, 6, (o7_char *)"float") || EqIc(n, 9, (o7_char *)"inttypes") || EqIc(n, 7, (o7_char *)"iso646") || EqIc(n, 7, (o7_char *)"limits") || EqIc(n, 7, (o7_char *)"locale") || EqIc(n, 5, (o7_char *)"math") || EqIc(n, 7, (o7_char *)"setjmp") || EqIc(n, 7, (o7_char *)"signal") || EqIc(n, 9, (o7_char *)"stdalign") || EqIc(n, 7, (o7_char *)"stdarg") || EqIc(n, 10, (o7_char *)"stdatomic") || EqIc(n, 8, (o7_char *)"stdbool") || EqIc(n, 7, (o7_char *)"stddef") || EqIc(n, 7, (o7_char *)"stdint") || EqIc(n, 6, (o7_char *)"stdio") || EqIc(n, 7, (o7_char *)"stdlib") || EqIc(n, 12, (o7_char *)"stdnoreturn") || EqIc(n, 7, (o7_char *)"string") || EqIc(n, 8, (o7_char *)"strings") || EqIc(n, 7, (o7_char *)"tgmath") || EqIc(n, 8, (o7_char *)"threads") || EqIc(n, 5, (o7_char *)"time") || EqIc(n, 6, (o7_char *)"uchar") || EqIc(n, 6, (o7_char *)"wchar") || EqIc(n, 7, (o7_char *)"wctype") || EqIc(n, 7, (o7_char *)"unistd");
}

extern o7_bool SpecIdentChecker_IsO7SpecName(struct StringStore_String *name) {
	return Eq(name, 5, (o7_char *)"init") || Eq(name, 5, (o7_char *)"cnst") || Eq(name, 4, (o7_char *)"len") || Eq(name, 5, (o7_char *)"proc");
}

extern void SpecIdentChecker_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		StringStore_init();
	}
	++initialized;
}


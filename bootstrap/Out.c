#include <o7.h>

#include "Out.h"
#include "CFiles.h"

#include <stdio.h>

static o7_bool success;
static o7_char ln[2];
static o7_int_t lnOfs = O7_INT_UNDEF;

extern void Out_String(o7_int_t s_len0, o7_char s[/*len0*/]) {
	o7_int_t i;

	i = 0;
	while ((i < s_len0) && (s[o7_ind(s_len0, i)] != 0x00u)) {
		i = o7_add(i, 1);
	}
	success = i == CFiles_WriteChars(CFiles_out, s_len0, s, 0, i);
}

extern void Out_Char(o7_char ch) {
	o7_char s[1];

	s[0] = ch;
	success = 1 == CFiles_WriteChars(CFiles_out, 1, s, 0, 1);
}

extern void Out_Int(o7_int_t x, o7_int_t n) {
	o7_char s[32];
	int i;
	i = sprintf((char *)s, "%d", x);
	success = i == CFiles_WriteChars(CFiles_out, 32, s, 0, i);
}

extern void Out_Ln(void) {
	success = O7_LEN(ln) - lnOfs == CFiles_WriteChars(CFiles_out, 2, ln, lnOfs, O7_LEN(ln) - lnOfs) && CFiles_Flush(CFiles_out);
}

extern void Out_Real(double x, int n) {
	o7_char s[64];
	int i;
	i = sprintf((char *)s, "%f", x);
	success = i == CFiles_WriteChars(CFiles_out, 64, s, 0, i);
}

extern void Out_Open(void) {
	success = (0 < 1);
}

extern void Out_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		CFiles_init();

		ln[0] = 0x0Du;
		ln[1] = 0x0Au;
		lnOfs = (o7_int_t)o7_bl(Platform_Posix);
	}
	++initialized;
}

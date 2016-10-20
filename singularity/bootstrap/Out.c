#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include <assert.h>
#include <stdbool.h>

#include "Out.h"

extern void Out_String(char s[/*len0*/], int s_len0) {
	int wr;
	wr = printf("%s", s);
	assert(wr < s_len0);
}

extern void Out_Char(char ch) {
	printf("%c", ch);
}

extern void Out_Int(int x, int n) {
	printf("%d", x);
}

extern void Out_Ln(void) {
	puts("");
}

extern void Out_Real(double x, int n) {
	printf("%f", x);
}

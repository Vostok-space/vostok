#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#include <o7c.h>

#include "Log.h"

bool Log_state;
static bool init;

extern void Log_Str(char unsigned s[/*len0*/], int s_len0) {
	if (Log_state) {
		Out_String(s, s_len0);
	}
}

extern void Log_StrLn(char unsigned s[/*len0*/], int s_len0) {
	if (Log_state) {
		Out_String(s, s_len0);
		Out_Ln();
	}
}

extern void Log_Char(char unsigned ch) {
	if (Log_state) {
		Out_Char(ch);
	}
}

extern void Log_Int(int x) {
	if (Log_state) {
		Out_Int(x, 0);
	}
}

extern void Log_Ln(void) {
	if (Log_state) {
		Out_Ln();
	}
}

extern void Log_Real(double x) {
	if (Log_state) {
		Out_Real(x, 0);
	}
}

extern void Log_Turn(bool st) {
	if (st && !init) {
		init = true;
		Out_Open();
	}
	Log_state = st;
}

extern void Log_init_(void) {
	static int initialized__ = 0;
	if (0 == initialized__) {
		Out_init_();

		init = false;
		Log_state = false;
	}
	++initialized__;
}


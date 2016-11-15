#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#define O7C_BOOL_UNDEFINED
#include <o7c.h>

#include "Log.h"

o7c_bool Log_state = O7C_BOOL_UNDEF;
static o7c_bool init_ = O7C_BOOL_UNDEF;

extern void Log_Str(o7c_char s[/*len0*/], int s_len0) {
	if (Log_state) {
		Out_String(s, s_len0);
	}
}

extern void Log_StrLn(o7c_char s[/*len0*/], int s_len0) {
	if (Log_state) {
		Out_String(s, s_len0);
		Out_Ln();
	}
}

extern void Log_Char(o7c_char ch) {
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

extern void Log_Turn(o7c_bool st) {
	if (o7c_bl(st) && !init_) {
		init_ = true;
		Out_Open();
	}
	Log_state = st;
}

extern void Log_init(void) {
	static int initialized = 0;
	if (0 == initialized) {
		Out_init();

		init_ = false;
		Log_state = false;
	}
	++initialized;
}


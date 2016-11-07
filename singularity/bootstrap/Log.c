#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#include <o7c.h>

#include "Log.h"

bool Log_state = 0 > 1;
static bool init_ = 0 > 1;

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

extern void Log_Turn(bool st) {
	if (st && !init_) {
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


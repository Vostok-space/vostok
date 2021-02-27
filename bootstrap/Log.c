#if !defined(O7_INIT_MODEL)
#   define   O7_INIT_MODEL O7_INIT_ZERO
#endif

#include <o7.h>

#include "Log.h"

o7_bool Log_state = 0 > 1;
static o7_bool init = 0 > 1;

extern void Log_Str(o7_int_t s_len0, o7_char s[/*len0*/]) {
	if (Log_state) {
		Out_String(s_len0, s);
	}
}

extern void Log_StrLn(o7_int_t s_len0, o7_char s[/*len0*/]) {
	if (Log_state) {
		Out_String(s_len0, s);
		Out_Ln();
	}
}

extern void Log_Char(o7_char ch) {
	if (Log_state) {
		Out_Char(ch);
	}
}

extern void Log_Int(o7_int_t x) {
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

extern void Log_Bool(o7_bool b) {
	if (!Log_state) {
	} else if (b) {
		Out_String(5, (o7_char *)"TRUE");
	} else {
		Out_String(6, (o7_char *)"FALSE");
	}
}

extern void Log_Set(o7_set_t s) {
	o7_int_t i;

	if (Log_state) {
		Out_String(3, (o7_char *)"{ ");
		for (i = 0; i <= 31; ++i) {
			if (o7_in(i, s)) {
				Out_Int(i, 0);
				Out_String(2, (o7_char *)"\x20");
			}
		}
		Out_String(2, (o7_char *)"\x7D");
	}
}

extern void Log_Turn(o7_bool st) {
	if (st && !init) {
		init = (0 < 1);
		Out_Open();
	}
	Log_state = st;
}

extern void Log_On(void) {
	Log_Turn((0 < 1));
}

extern void Log_Off(void) {
	Log_Turn((0 > 1));
}

extern void Log_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		Out_init();

		init = (0 > 1);
		Log_state = (0 > 1);
	}
	++initialized;
}

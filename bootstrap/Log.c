#include <o7.h>

#include "Log.h"

o7_bool Log_state = O7_BOOL_UNDEF;
static o7_bool init = O7_BOOL_UNDEF;

extern void Log_Str(o7_int_t s_len0, o7_char s[/*len0*/]) {
	if (o7_bl(Log_state)) {
		Out_String(s_len0, s);
	}
}

extern void Log_StrLn(o7_int_t s_len0, o7_char s[/*len0*/]) {
	if (o7_bl(Log_state)) {
		Out_String(s_len0, s);
		Out_Ln();
	}
}

extern void Log_Char(o7_char ch) {
	if (o7_bl(Log_state)) {
		Out_Char(ch);
	}
}

extern void Log_Int(o7_int_t x) {
	if (o7_bl(Log_state)) {
		Out_Int(x, 0);
	}
}

extern void Log_Ln(void) {
	if (o7_bl(Log_state)) {
		Out_Ln();
	}
}

extern void Log_Real(double x) {
	if (o7_bl(Log_state)) {
		Out_Real(x, 0);
	}
}

extern void Log_Bool(o7_bool b) {
	if (!o7_bl(Log_state)) {
	} else if (b) {
		Out_String(5, (o7_char *)"TRUE");
	} else {
		Out_String(6, (o7_char *)"FALSE");
	}
}

extern void Log_Turn(o7_bool st) {
	if (st && !o7_bl(init)) {
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

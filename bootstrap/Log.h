#if !defined HEADER_GUARD_Log
#    define  HEADER_GUARD_Log 1

#include "Out.h"

extern o7_bool Log_state;

extern void Log_Str(o7_int_t s_len0, o7_char s[/*len0*/]);

extern void Log_StrLn(o7_int_t s_len0, o7_char s[/*len0*/]);

extern void Log_Char(o7_char ch);

extern void Log_Int(o7_int_t x);

extern void Log_Ln(void);

extern void Log_Real(double x);

extern void Log_Bool(o7_bool b);

extern void Log_Turn(o7_bool st);

extern void Log_On(void);

extern void Log_Off(void);

extern void Log_init(void);
#endif

#if !defined(HEADER_GUARD_Log)
#define HEADER_GUARD_Log

#include "Out.h"

extern bool Log_state;

extern void Log_Str(char unsigned s[/*len0*/], int s_len0);

extern void Log_StrLn(char unsigned s[/*len0*/], int s_len0);

extern void Log_Char(char unsigned ch);

extern void Log_Int(int x);

extern void Log_Ln(void);

extern void Log_Real(double x);

extern void Log_Turn(bool st);

extern void Log_init_(void);
#endif

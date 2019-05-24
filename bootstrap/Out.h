#if !defined HEADER_GUARD_Out
#    define  HEADER_GUARD_Out 1

#include "CFiles.h"
#include "Platform.h"

extern void Out_String(o7_int_t s_len0, o7_char s[/*len0*/]);

extern void Out_Char(o7_char ch);

extern void Out_Int(o7_int_t x, o7_int_t n);

extern void Out_Ln(void);

extern void Out_Real(double x, o7_int_t n);

extern void Out_Open(void);

extern void Out_init(void);
#endif

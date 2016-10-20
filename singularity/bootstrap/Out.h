#if !defined(MODULE_Out_HEADER)
#define MODULE_Out_HEADER 1


extern void Out_String(char s[/*len0*/], int s_len0);

extern void Out_Char(char ch);

extern void Out_Int(int x, int n);

extern void Out_Ln(void);

extern void Out_Real(double x, int n);

static inline void Out_Open(void) { ; }

static inline void Out_init_(void) { ; }

#endif

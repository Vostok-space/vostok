#if !defined(HEADER_GUARD_OsExec)
#define HEADER_GUARD_OsExec

#define OsExec_Ok_cnst 0

extern int OsExec_Do(int len, o7c_char const cmd[O7C_VLA_LEN(len)]);

static inline void OsExec_init(void) { ; }
#endif

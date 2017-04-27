#if !defined(HEADER_GUARD_OsExec)
#define HEADER_GUARD_OsExec

#define OsExec_Ok_cnst 0

extern int OsExec_Do(o7c_char const cmd[/*len0*/], int cmd_len0);

static inline void OsExec_init(void) { ; }
#endif

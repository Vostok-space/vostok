#if !defined HEADER_GUARD_OsExec
#    define  HEADER_GUARD_OsExec 1

#define OsExec_Ok_cnst 0

extern o7_int_t OsExec_Do(o7_int_t len, o7_char const cmd[O7_VLA(len)]);

O7_ALWAYS_INLINE void OsExec_init(void) { ; }
O7_ALWAYS_INLINE void OsExec_done(void) { ; }
#endif

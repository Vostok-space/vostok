#if !defined HEADER_GUARD_OsEnv
#    define  HEADER_GUARD_OsEnv 1


#define OsEnv_MaxLen_cnst 4096

extern o7_bool OsEnv_Exist(o7_int_t len, o7_char const name[O7_VLA(len)]);

extern o7_bool OsEnv_Get(o7_int_t len, o7_char val[O7_VLA(len)], o7_int_t *ofs,
                         o7_int_t name_len, o7_char const name[O7_VLA(name_len)]);

O7_ALWAYS_INLINE void OsEnv_init(void) { ; }
O7_ALWAYS_INLINE void OsEnv_done(void) { ; }
#endif

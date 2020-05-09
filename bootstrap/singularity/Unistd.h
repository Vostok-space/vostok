#if !defined HEADER_GUARD_Unistd
#    define  HEADER_GUARD_Unistd 1

extern o7_int_t Unistd_pageSize;

extern o7_int_t
Unistd_Readlink(o7_int_t path_len, o7_char const pathname[O7_VLA(path_len)],
                o7_int_t buf_len, o7_char buf[O7_VLA(buf_len)]);

extern o7_int_t Unistd_Sysconf(o7_int_t name);

O7_ALWAYS_INLINE void Unistd_init(void) { ; }
#endif

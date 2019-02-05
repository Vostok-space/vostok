#if !defined HEADER_GUARD_CLI
#    define  HEADER_GUARD_CLI 1

extern int CLI_count;

extern o7_cbool CLI_GetName(
	o7_int_t len, char unsigned str[O7_VLA(len)], o7_int_t *ofs);

extern o7_cbool CLI_Get(
	o7_int_t len, char unsigned str[O7_VLA(len)], o7_int_t *ofs, o7_int_t arg);

extern void CLI_SetExitCode(int code);

extern void CLI_init(void);
O7_ALWAYS_INLINE void CLI_done(void) {}

#endif

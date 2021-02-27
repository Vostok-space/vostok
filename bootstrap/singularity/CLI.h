#if !defined HEADER_GUARD_CLI
#    define  HEADER_GUARD_CLI 1

#define CLI_MaxLen_cnst 4096

extern int CLI_count;

extern o7_cbool CLI_GetName(O7_FPA(char unsigned, str), o7_int_t *ofs);

extern o7_cbool CLI_Get(O7_FPA(char unsigned, str), o7_int_t *ofs, o7_int_t arg);

extern void CLI_SetExitCode(int code);

extern void CLI_init(void);

#endif

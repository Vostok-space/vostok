#if !defined(HEADER_GUARD_CLI)
#define HEADER_GUARD_CLI

extern int CLI_count;

extern bool CLI_Get(char str[/*len0*/], int str_len0, int *ofs, int arg);

extern void CLI_SetExitCode(int code);

extern void CLI_init_(void);

#endif

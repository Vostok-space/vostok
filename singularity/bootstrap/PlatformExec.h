#if !defined(HEADER_GUARD_PlatformExec)
#define HEADER_GUARD_PlatformExec

#include "V.h"
#include "Utf8.h"
#include "OsExec.h"
#include "Log.h"

#define PlatformExec_CodeSize_cnst 65536
#define PlatformExec_Ok_cnst 0

typedef struct PlatformExec_Code {
	V_Base _;
	o7c_char buf[PlatformExec_CodeSize_cnst];
	int len;
} PlatformExec_Code;
extern o7c_tag_t PlatformExec_Code_tag;


extern o7c_bool PlatformExec_Init(struct PlatformExec_Code *c, o7c_tag_t c_tag, o7c_char name[/*len0*/], int name_len0);

extern o7c_bool PlatformExec_Add(struct PlatformExec_Code *c, o7c_tag_t c_tag, o7c_char arg[/*len0*/], int arg_len0, int ofs);

extern o7c_bool PlatformExec_AddClean(struct PlatformExec_Code *c, o7c_tag_t c_tag, o7c_char arg[/*len0*/], int arg_len0);

extern o7c_bool PlatformExec_FirstPart(struct PlatformExec_Code *c, o7c_tag_t c_tag, o7c_char arg[/*len0*/], int arg_len0);

extern o7c_bool PlatformExec_AddPart(struct PlatformExec_Code *c, o7c_tag_t c_tag, o7c_char arg[/*len0*/], int arg_len0);

extern o7c_bool PlatformExec_LastPart(struct PlatformExec_Code *c, o7c_tag_t c_tag, o7c_char arg[/*len0*/], int arg_len0);

extern int PlatformExec_Do(struct PlatformExec_Code *c, o7c_tag_t c_tag);

extern void PlatformExec_Log(struct PlatformExec_Code *c, o7c_tag_t c_tag);

extern void PlatformExec_init(void);
#endif

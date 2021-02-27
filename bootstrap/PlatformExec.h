#if !defined HEADER_GUARD_PlatformExec
#    define  HEADER_GUARD_PlatformExec 1

#include "V.h"
#include "Utf8.h"
#include "OsExec.h"
#include "Log.h"
#include "Platform.h"
#include "Chars0X.h"

#define PlatformExec_CodeSize_cnst 8192

#define PlatformExec_Ok_cnst 0

typedef struct PlatformExec_Code {
	V_Base _;
	o7_char buf[PlatformExec_CodeSize_cnst];
	o7_int_t len;

	o7_bool parts;
	o7_bool partsQuote;
} PlatformExec_Code;
#define PlatformExec_Code_tag V_Base_tag


extern o7_char PlatformExec_dirSep[2];

extern o7_bool PlatformExec_AddQuote(struct PlatformExec_Code *c);

extern o7_bool PlatformExec_Init(struct PlatformExec_Code *c, o7_int_t name_len0, o7_char name[/*len0*/]);

extern o7_bool PlatformExec_AddByOfs(struct PlatformExec_Code *c, o7_int_t arg_len0, o7_char arg[/*len0*/], o7_int_t ofs);

extern o7_bool PlatformExec_Add(struct PlatformExec_Code *c, o7_int_t arg_len0, o7_char arg[/*len0*/]);

extern o7_bool PlatformExec_AddClean(struct PlatformExec_Code *c, o7_int_t arg_len0, o7_char arg[/*len0*/]);

extern o7_bool PlatformExec_AddDirSep(struct PlatformExec_Code *c);

extern o7_bool PlatformExec_FirstPart(struct PlatformExec_Code *c, o7_int_t arg_len0, o7_char arg[/*len0*/]);

extern o7_bool PlatformExec_AddPart(struct PlatformExec_Code *c, o7_int_t arg_len0, o7_char arg[/*len0*/]);

extern o7_bool PlatformExec_LastPart(struct PlatformExec_Code *c, o7_int_t arg_len0, o7_char arg[/*len0*/]);

extern void PlatformExec_Log(struct PlatformExec_Code *c);

extern o7_int_t PlatformExec_Do(struct PlatformExec_Code *c);

extern void PlatformExec_AutoCorrectDirSeparator(o7_bool state);

extern void PlatformExec_init(void);
#endif

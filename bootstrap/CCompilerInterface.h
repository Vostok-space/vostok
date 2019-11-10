#if !defined HEADER_GUARD_CCompilerInterface
#    define  HEADER_GUARD_CCompilerInterface 1

#include "PlatformExec.h"
#include "Platform.h"
#include "V.h"

#define CCompilerInterface_Unknown_cnst 0
#define CCompilerInterface_Tiny_cnst 1
#define CCompilerInterface_Gnu_cnst 2
#define CCompilerInterface_Clang_cnst 3
#define CCompilerInterface_CompCert_cnst 4

typedef struct CCompilerInterface_Compiler {
	V_Base _;
	struct PlatformExec_Code cmd;
	o7_int_t id;
} CCompilerInterface_Compiler;
#define CCompilerInterface_Compiler_tag V_Base_tag

extern void CCompilerInterface_Compiler_undef(struct CCompilerInterface_Compiler *r);

extern o7_bool CCompilerInterface_Set(struct CCompilerInterface_Compiler *c, o7_int_t cmd_len0, o7_char cmd[/*len0*/]);

extern o7_bool CCompilerInterface_Search(struct CCompilerInterface_Compiler *c, o7_bool forRun);

extern o7_bool CCompilerInterface_AddOutputExe(struct CCompilerInterface_Compiler *c, o7_int_t o_len0, o7_char o[/*len0*/]);

extern o7_bool CCompilerInterface_AddInclude(struct CCompilerInterface_Compiler *c, o7_int_t path_len0, o7_char path[/*len0*/], o7_int_t ofs);

extern o7_bool CCompilerInterface_AddC(struct CCompilerInterface_Compiler *c, o7_int_t file_len0, o7_char file[/*len0*/], o7_int_t ofs);

extern o7_bool CCompilerInterface_AddOpt(struct CCompilerInterface_Compiler *c, o7_int_t opt_len0, o7_char opt[/*len0*/]);

extern o7_bool CCompilerInterface_AddOptByOfs(struct CCompilerInterface_Compiler *c, o7_int_t opt_len0, o7_char opt[/*len0*/], o7_int_t ofs);

extern o7_int_t CCompilerInterface_Do(struct CCompilerInterface_Compiler *c);

extern void CCompilerInterface_init(void);
#endif

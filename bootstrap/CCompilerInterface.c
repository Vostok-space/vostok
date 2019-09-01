#define O7_BOOL_UNDEFINED
#include <o7.h>

#include "CCompilerInterface.h"

#define CCompilerInterface_Compiler_tag V_Base_tag
extern void CCompilerInterface_Compiler_undef(struct CCompilerInterface_Compiler *r) {
	V_Base_undef(&r->_);
	PlatformExec_Code_undef(&r->cmd);
	r->id = O7_INT_UNDEF;
}

extern o7_bool CCompilerInterface_Set(struct CCompilerInterface_Compiler *c, o7_int_t cmd_len0, o7_char cmd[/*len0*/]) {
	V_Init(&(*c)._);
	O7_ASSERT(PlatformExec_Init(&(*c).cmd, 0, (o7_char *)""));
	/* TODO */
	(*c).id = CCompilerInterface_Unknown_cnst;
	return PlatformExec_AddClean(&(*c).cmd, cmd_len0, cmd);
}

static o7_bool Search_Test(struct CCompilerInterface_Compiler *cc, o7_int_t id, o7_int_t c_len0, o7_char c[/*len0*/], o7_int_t ver_len0, o7_char ver[/*len0*/]) {
	struct PlatformExec_Code exec;
	o7_bool ok;
	PlatformExec_Code_undef(&exec);

	ok = PlatformExec_Init(&exec, c_len0, c) && ((o7_strcmp(ver_len0, ver, 0, (o7_char *)"") == 0) || PlatformExec_Add(&exec, ver_len0, ver)) && ((o7_bl(Platform_Posix) && PlatformExec_AddClean(&exec, 23, (o7_char *)" >/dev/null 2>/dev/null")) || (o7_bl(Platform_Windows) && PlatformExec_AddClean(&exec, 10, (o7_char *)">NUL 2>NUL"))) && (PlatformExec_Ok_cnst == PlatformExec_Do(&exec));
	if (ok) {
		O7_ASSERT(PlatformExec_Init(&(*cc).cmd, c_len0, c));
		(*cc).id = id;
	}
	return o7_bl(ok);
}

extern o7_bool CCompilerInterface_Search(struct CCompilerInterface_Compiler *c, o7_bool forRun) {
	V_Init(&(*c)._);
	return forRun && Search_Test(&(*c), CCompilerInterface_Tiny_cnst, 3, (o7_char *)"tcc", 12, (o7_char *)"-dumpversion") && PlatformExec_AddClean(&(*c).cmd, 6, (o7_char *)" -g -w") || (Search_Test(&(*c), CCompilerInterface_Gnu_cnst, 3, (o7_char *)"gcc", 12, (o7_char *)"-dumpversion") && PlatformExec_AddClean(&(*c).cmd, 7, (o7_char *)" -g -O1") || Search_Test(&(*c), CCompilerInterface_Clang_cnst, 5, (o7_char *)"clang", 12, (o7_char *)"-dumpversion") && PlatformExec_AddClean(&(*c).cmd, 7, (o7_char *)" -g -O1") || !forRun && Search_Test(&(*c), CCompilerInterface_Tiny_cnst, 3, (o7_char *)"tcc", 12, (o7_char *)"-dumpversion") && PlatformExec_AddClean(&(*c).cmd, 3, (o7_char *)" -g") || Search_Test(&(*c), CCompilerInterface_CompCert_cnst, 5, (o7_char *)"ccomp", 9, (o7_char *)"--version") && PlatformExec_AddClean(&(*c).cmd, 6, (o7_char *)" -g -O") || Search_Test(&(*c), CCompilerInterface_Unknown_cnst, 2, (o7_char *)"cc", 12, (o7_char *)"-dumpversion") && PlatformExec_AddClean(&(*c).cmd, 7, (o7_char *)" -g -O1") || o7_bl(Platform_Windows) && Search_Test(&(*c), CCompilerInterface_Unknown_cnst, 6, (o7_char *)"cl.exe", 0, (o7_char *)"")) && (!forRun || PlatformExec_AddClean(&(*c).cmd, 3, (o7_char *)" -w"));
}

extern o7_bool CCompilerInterface_AddOutput(struct CCompilerInterface_Compiler *c, o7_int_t o_len0, o7_char o[/*len0*/]) {
	return PlatformExec_Add(&(*c).cmd, 2, (o7_char *)"-o") && PlatformExec_Add(&(*c).cmd, o_len0, o);
}

extern o7_bool CCompilerInterface_AddInclude(struct CCompilerInterface_Compiler *c, o7_int_t path_len0, o7_char path[/*len0*/], o7_int_t ofs) {
	return PlatformExec_Add(&(*c).cmd, 2, (o7_char *)"-I") && PlatformExec_AddByOfs(&(*c).cmd, path_len0, path, ofs);
}

extern o7_bool CCompilerInterface_AddC(struct CCompilerInterface_Compiler *c, o7_int_t file_len0, o7_char file[/*len0*/], o7_int_t ofs) {
	return PlatformExec_AddByOfs(&(*c).cmd, file_len0, file, ofs);
}

extern o7_bool CCompilerInterface_AddOpt(struct CCompilerInterface_Compiler *c, o7_int_t opt_len0, o7_char opt[/*len0*/]) {
	return PlatformExec_AddByOfs(&(*c).cmd, opt_len0, opt, 0);
}

extern o7_bool CCompilerInterface_AddOptByOfs(struct CCompilerInterface_Compiler *c, o7_int_t opt_len0, o7_char opt[/*len0*/], o7_int_t ofs) {
	return PlatformExec_AddByOfs(&(*c).cmd, opt_len0, opt, ofs);
}

extern o7_int_t CCompilerInterface_Do(struct CCompilerInterface_Compiler *c) {
	PlatformExec_Log(&(*c).cmd);
	return PlatformExec_Do(&(*c).cmd);
}

extern void CCompilerInterface_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		PlatformExec_init();
		Platform_init();
	}
	++initialized;
}


#define O7_BOOL_UNDEFINED
#include <o7.h>

#include "FileSystemUtil.h"

extern o7_bool FileSystemUtil_MakeDir(o7_int_t name_len0, o7_char name[/*len0*/]) {
	struct PlatformExec_Code cmd;
	PlatformExec_Code_undef(&cmd);

	if (o7_bl(Platform_Posix)) {
		O7_ASSERT(PlatformExec_Init(&cmd, 5, (o7_char *)"mkdir") && PlatformExec_Add(&cmd, name_len0, name) && (o7_bl(Platform_Java) || PlatformExec_AddClean(&cmd, 12, (o7_char *)" 2>/dev/null")));
	} else {
		O7_ASSERT(o7_bl(Platform_Windows));
		O7_ASSERT(PlatformExec_Init(&cmd, 5, (o7_char *)"mkdir") && PlatformExec_Add(&cmd, name_len0, name));
	}
	return PlatformExec_Do(&cmd) == PlatformExec_Ok_cnst;
}

extern o7_bool FileSystemUtil_RemoveDir(o7_int_t name_len0, o7_char name[/*len0*/]) {
	struct PlatformExec_Code cmd;
	PlatformExec_Code_undef(&cmd);

	if (o7_bl(Platform_Posix)) {
		O7_ASSERT(PlatformExec_Init(&cmd, 2, (o7_char *)"rm") && PlatformExec_Add(&cmd, 2, (o7_char *)"-r") && PlatformExec_Add(&cmd, name_len0, name) && (o7_bl(Platform_Java) || PlatformExec_AddClean(&cmd, 12, (o7_char *)" 2>/dev/null")));
	} else {
		O7_ASSERT(o7_bl(Platform_Windows));
		O7_ASSERT(PlatformExec_Init(&cmd, 5, (o7_char *)"rmdir") && PlatformExec_AddClean(&cmd, 5, (o7_char *)" /s/q") && PlatformExec_Add(&cmd, name_len0, name));
	}
	return PlatformExec_Do(&cmd) == PlatformExec_Ok_cnst;
}

extern void FileSystemUtil_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		Platform_init();
		PlatformExec_init();
	}
	++initialized;
}


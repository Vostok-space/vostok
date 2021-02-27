#if !defined(O7_INIT_MODEL)
#   define   O7_INIT_MODEL O7_INIT_ZERO
#endif

#include <o7.h>

#include "FileSystemUtil.h"

extern o7_bool FileSystemUtil_MakeDir(o7_int_t name_len0, o7_char name[/*len0*/]) {
	struct PlatformExec_Code cmd;
	memset(&cmd, 0, sizeof(cmd));

	if (Platform_Posix) {
		O7_ASSERT(PlatformExec_Init(&cmd, 6, (o7_char *)"mkdir") && PlatformExec_Add(&cmd, name_len0, name) && (Platform_Java || PlatformExec_AddClean(&cmd, 13, (o7_char *)" 2>/dev/null")));
	} else {
		O7_ASSERT(Platform_Windows);
		O7_ASSERT(PlatformExec_Init(&cmd, 6, (o7_char *)"mkdir") && PlatformExec_Add(&cmd, name_len0, name));
	}
	return PlatformExec_Do(&cmd) == PlatformExec_Ok_cnst;
}

extern o7_bool FileSystemUtil_RemoveDir(o7_int_t name_len0, o7_char name[/*len0*/]) {
	struct PlatformExec_Code cmd;
	memset(&cmd, 0, sizeof(cmd));

	if (Platform_Posix) {
		O7_ASSERT(PlatformExec_Init(&cmd, 3, (o7_char *)"rm") && PlatformExec_Add(&cmd, 3, (o7_char *)"-r") && PlatformExec_Add(&cmd, name_len0, name) && (Platform_Java || PlatformExec_AddClean(&cmd, 13, (o7_char *)" 2>/dev/null")));
	} else {
		O7_ASSERT(Platform_Windows);
		O7_ASSERT(PlatformExec_Init(&cmd, 6, (o7_char *)"rmdir") && PlatformExec_AddClean(&cmd, 6, (o7_char *)" /s/q") && PlatformExec_Add(&cmd, name_len0, name));
	}
	return PlatformExec_Do(&cmd) == PlatformExec_Ok_cnst;
}

extern o7_bool FileSystemUtil_Copy(o7_int_t src_len0, o7_char src[/*len0*/], o7_int_t dest_len0, o7_char dest[/*len0*/], o7_bool dir) {
	struct PlatformExec_Code cmd;
	memset(&cmd, 0, sizeof(cmd));

	if (Platform_Posix) {
		O7_ASSERT(PlatformExec_Init(&cmd, 3, (o7_char *)"cp") && (!dir || PlatformExec_Add(&cmd, 3, (o7_char *)"-r")) && PlatformExec_Add(&cmd, src_len0, src) && PlatformExec_Add(&cmd, dest_len0, dest));
	} else {
		O7_ASSERT((0 > 1));
	}
	return PlatformExec_Do(&cmd) == PlatformExec_Ok_cnst;
}

extern o7_bool FileSystemUtil_CopyFile(o7_int_t src_len0, o7_char src[/*len0*/], o7_int_t dest_len0, o7_char dest[/*len0*/]) {
	return FileSystemUtil_Copy(src_len0, src, dest_len0, dest, (0 > 1));
}

extern o7_bool FileSystemUtil_CopyDir(o7_int_t src_len0, o7_char src[/*len0*/], o7_int_t dest_len0, o7_char dest[/*len0*/]) {
	return FileSystemUtil_Copy(src_len0, src, dest_len0, dest, (0 < 1));
}

extern o7_bool FileSystemUtil_RemoveFile(o7_int_t src_len0, o7_char src[/*len0*/]) {
	return CFiles_Remove(src_len0, src, 0);
}

extern void FileSystemUtil_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		PlatformExec_init();
		CFiles_init();
	}
	++initialized;
}


#if !defined HEADER_GUARD_FileSystemUtil
#    define  HEADER_GUARD_FileSystemUtil 1

#include "Platform.h"
#include "PlatformExec.h"

extern o7_bool FileSystemUtil_MakeDir(o7_int_t name_len0, o7_char name[/*len0*/]);

extern o7_bool FileSystemUtil_RemoveDir(o7_int_t name_len0, o7_char name[/*len0*/]);

extern void FileSystemUtil_init(void);
#endif

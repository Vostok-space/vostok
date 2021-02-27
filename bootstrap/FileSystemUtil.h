#if !defined HEADER_GUARD_FileSystemUtil
#    define  HEADER_GUARD_FileSystemUtil 1

#include "Platform.h"
#include "PlatformExec.h"
#include "CFiles.h"

extern o7_bool FileSystemUtil_MakeDir(o7_int_t name_len0, o7_char name[/*len0*/]);

extern o7_bool FileSystemUtil_RemoveDir(o7_int_t name_len0, o7_char name[/*len0*/]);

extern o7_bool FileSystemUtil_Copy(o7_int_t src_len0, o7_char src[/*len0*/], o7_int_t dest_len0, o7_char dest[/*len0*/], o7_bool dir);

extern o7_bool FileSystemUtil_CopyFile(o7_int_t src_len0, o7_char src[/*len0*/], o7_int_t dest_len0, o7_char dest[/*len0*/]);

extern o7_bool FileSystemUtil_CopyDir(o7_int_t src_len0, o7_char src[/*len0*/], o7_int_t dest_len0, o7_char dest[/*len0*/]);

extern o7_bool FileSystemUtil_RemoveFile(o7_int_t src_len0, o7_char src[/*len0*/]);

extern void FileSystemUtil_init(void);
#endif

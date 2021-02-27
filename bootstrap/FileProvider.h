#if !defined HEADER_GUARD_FileProvider
#    define  HEADER_GUARD_FileProvider 1

#include "V.h"
#include "InputProvider.h"
#include "TranslatorLimits.h"
#include "PlatformExec.h"
#include "VDataStream.h"
#include "VFileStream.h"
#include "Chars0X.h"
#include "ArrayCopy.h"
#include "Log.h"

#define FileProvider_PathesMaxLen_cnst 4096

extern o7_bool FileProvider_New(struct InputProvider_R **out, o7_int_t searchPathes_len0, o7_char searchPathes[/*len0*/], o7_int_t pathesLen, o7_set_t pathForDecl);

extern void FileProvider_init(void);
#endif

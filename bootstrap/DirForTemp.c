#include <o7.h>

#include "DirForTemp.h"

extern o7_bool DirForTemp_Get(o7_int_t val_len0, o7_char val[/*len0*/], o7_int_t *ofs) {
	o7_bool ok;
	o7_int_t start;

	if (Platform_Posix) {
		start = *ofs;
		if (OsEnv_Get(val_len0, val, ofs, 7, (o7_char *)"TMPDIR")) {
			ok = (start == *ofs) || Chars0X_CopyString(val_len0, val, ofs, 2, (o7_char *)"\x2F");
		} else {
			ok = (start == *ofs) && Chars0X_CopyString(val_len0, val, ofs, 6, (o7_char *)"/tmp/");
		}
	} else if (Platform_Windows) {
		ok = OsEnv_Get(val_len0, val, ofs, 5, (o7_char *)"TEMP") && Chars0X_CopyString(val_len0, val, ofs, 2, (o7_char *)"\x5C");
	} else {
		O7_ASSERT(0 > 1);
	}
	return ok;
}

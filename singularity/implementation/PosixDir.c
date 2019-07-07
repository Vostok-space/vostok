/* Copyright 2017-2018 ComdivByZero
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#include <stdbool.h>

#define O7_BOOL_UNDEFINED
#include <o7.h>

#include "PosixDir.h"

#if defined(__unix__) || defined(__unix) \
 || defined(__linux__) || defined(__linux) \
 || defined(__minix__) || defined(__minix) \
 || defined(__FreeBSD__) || defined(__NetBSD__) || defined(__OpenBSD__) || defined(__bsdi__) \
 || defined(__MINGW32__) || defined(__MINGW64__) \
 || defined(__HAIKU__) || defined(__APPLE__) \
 || defined(__sun__) || defined(__sun)
	o7_bool PosixDir_supported = 0 < 1;
#	include <dirent.h>
#else
	o7_bool PosixDir_supported = 0 > 1;
	typedef struct PosixDir_Dir_s DIR;
	struct dirent { char d_name[1]; };
	O7_INLINE PosixDir_Dir opendir(char const *name) { return NULL; }
	O7_INLINE int closedir(PosixDir_Dir dir) { return -1; }
	O7_INLINE PosixDir_Ent readdir(PosixDir_Dir dir) { return NULL; }
#endif

extern o7_bool PosixDir_Open(PosixDir_Dir *d,
                             o7_int_t len, o7_char name[O7_VLA(len)], o7_int_t ofs)
{
	assert((0 <= ofs) && (ofs < len));
	*d = (PosixDir_Dir)opendir((char *)(name + ofs));
	return NULL != *d;
}

extern o7_bool PosixDir_Close(PosixDir_Dir *d) {
	if ((NULL != *d) && (0 == closedir((DIR *)*d))) {
		*d = NULL;
	}
	return NULL == *d;
}

extern o7_bool PosixDir_Read(PosixDir_Ent *e, PosixDir_Dir d) {
	*e = readdir((DIR *)d);
	return NULL != *e;
}

extern o7_bool PosixDir_CopyName(o7_int_t len, o7_char buf[O7_VLA(len)], o7_int_t *ofs,
                                 PosixDir_Ent e)
{
	o7_int_t i, j;
	assert((0 <= *ofs) && (*ofs < len));
	i = 0;
	j = *ofs;
	while ((e->d_name[i] != '\0') && (j < len - 1)) {
		buf[j] = e->d_name[i];
		i += 1;
		j += 1;
	}
	buf[j] = '\0';
	*ofs = j;
	return e->d_name[i] == '\0';
}


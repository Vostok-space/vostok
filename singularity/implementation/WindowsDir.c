/* Copyright 2017-2018,2023 ComdivByZero
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
#define O7_BOOL_UNDEFINED
#include <o7.h>

#if (defined(_WIN16) || defined(_WIN32) || defined(_WIN64)) \
&& !(defined(__MINGW32__) || defined(__MINGW64__))
	o7_bool WindowsDir_supported = 0 < 1;
#	include <io.h>
#	include <direct.h>
	typedef intptr_t handle_t;
#else
	o7_bool WindowsDir_supported = 0 > 1;
	typedef int handle_t;
	struct _finddata_t { char name[1]; };

	O7_INLINE handle_t _findfirst(char const *filespec, struct _finddata_t *fileinfo)
	{ (void)filespec; (void)fileinfo; return -1; }
	O7_INLINE int _findnext(handle_t handle, struct _finddata_t *fileinfo)
	{ (void)handle; (void)fileinfo; return -1; }
	O7_INLINE int _findclose(handle_t handle) { (void)handle; return -1; }
	O7_INLINE int _mkdir(char const *name) { return -1; }
#endif

#include "WindowsDir.h"

struct WindowsDir_FindData_s {
	struct _finddata_t d;
};
extern void WindowsDir_FindData_s_undef(WindowsDir_FindData r) {
	memset(&r->d, 0, sizeof(r->d));
}

struct WindowsDir_FindId_s {
	handle_t h;
};
extern void WindowsDir_FindId_s_undef(WindowsDir_FindId r) {
	r->h = -1;
}

extern o7_bool WindowsDir_FindFirst(WindowsDir_FindId *id, WindowsDir_FindData *d,
                                    o7_int_t len, o7_char filespec[O7_VLA(len)], o7_int_t ofs)
{
	o7_cbool ret;
	assert((0 <= ofs) && (ofs < len - 1));
	if (O7_NEW(id, WindowsDir_FindId_s) && O7_NEW(d, WindowsDir_FindData_s)) {
		(*id)->h = _findfirst((char *)(filespec + ofs), &(*d)->d);
	}
	if ((NULL == *id) || (NULL == *d) || (-1 == (*id)->h)) {
		O7_NULL(id);
		O7_NULL(d);
	}
	return (*id != NULL);
}

extern o7_bool WindowsDir_FindNext(WindowsDir_FindData *d, WindowsDir_FindId id)
{
	assert(id != NULL);

	if (O7_NEW(d, WindowsDir_FindData_s)
	 && (0 != _findnext(id->h, &(*d)->d)))
	{
		O7_NULL(d);
	}
	return *d != NULL;
}

extern o7_bool WindowsDir_Close(WindowsDir_FindId *id) {
	o7_cbool ret;
	ret = (*id == NULL);
	if (!ret) {
		ret = (0 == _findclose((*id)->h));
		if (ret) {
			O7_NULL(id);
		}
	}
	return ret;
}

extern o7_bool WindowsDir_CopyName(o7_int_t len, o7_char buf[O7_VLA(len)], o7_int_t *ofs,
                                   WindowsDir_FindData f)
{
	o7_int_t i, j;
	assert(f != NULL);
	assert((0 <= *ofs) && (*ofs < len));
	i = 0;
	j = *ofs;
	while ((f->d.name[i] != '\0') && (j < len - 1)) {
		buf[j] = f->d.name[i];
		i += 1;
		j += 1;
	}
	buf[j] = '\0';
	*ofs = j;
	return f->d.name[i] == '\0';
}

extern o7_bool WindowsDir_Mkdir(o7_int_t len, o7_char name[O7_VLA(len)], o7_int_t ofs) {
	assert((0 <= ofs) && (ofs < len));
	return 0 == _mkdir((char *)name + ofs);
}

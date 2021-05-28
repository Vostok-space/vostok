/* Partial wrapper for macOS mach-o/dyld.h
 *
 * Copyright 2021 ComdivByZero
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
#include <o7.h>

#include "MachObjDyld.h"

#if defined(__APPLE__)
#	include <mach-o/dyld.h>
#else
	O7_ALWAYS_INLINE int _NSGetExecutablePath(char* buf, o7_uint_t * bufsize) {
		abort();
		return -1;
	}
#endif

extern o7_int_t MachObjDyld_NSGetExecutablePath(o7_int_t path_len, o7_char path[/*len*/]) {
	o7_int_t res;
	o7_uint_t len;
	O7_ASSERT(path_len > 1);
	len = path_len;
	res = _NSGetExecutablePath((char *)path, &len);
	if (res < 0) {
		path[path_len - 1] = '\0';
	} else {
		len = strlen((char *)path);
	}
	return (o7_int_t)len;
}

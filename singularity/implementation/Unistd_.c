/* Bindings of some functions from unistd.h
 * Copyright 2019-2020 ComdivByZero
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

#include "Unistd_.h"

#if defined(_WIN16) || defined(_WIN32) || defined(_WIN64)
	O7_ALWAYS_INLINE o7_int_t readlink(char const path[], char buf[], size_t len) {
		O7_ASSERT(0>1);
		return -1;
	}
	O7_ALWAYS_INLINE o7_int_t sysconf(o7_int_t name) {
		O7_ASSERT(0>1);
		return -1;
	}
#	define _SC_PAGESIZE 0
#else
#	include <unistd.h>
#endif

o7_int_t Unistd_pageSize = _SC_PAGESIZE;

static o7_int_t Len(O7_FPA(o7_char const, str)) {
	o7_int_t i;

	i = 0;
	while ((i < O7_FPA_LEN(str)) && (str[i] != 0x00u)) {
		i += 1;
	}
	return i;
}

extern o7_int_t Unistd_Readlink(O7_FPA(o7_char const, pathname), O7_FPA(o7_char, buf)) {
	O7_ASSERT(Len(O7_APA(pathname)) < O7_FPA_LEN(pathname));
	return (o7_int_t)readlink((char const *)pathname, (char *)buf, (o7_uint_t)O7_FPA_LEN(buf));
}

extern o7_int_t Unistd_Sysconf(o7_int_t name) {
	return sysconf(name);
}

extern o7_int_t Unistd_Chdir(O7_FPA(o7_char const, path)) {
	O7_ASSERT(Len(O7_APA(path)) < O7_FPA_LEN(path));
	return (o7_int_t)chdir((char const *)path);
}

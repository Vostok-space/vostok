/* Bindings of some functions from unistd.h
 * Copyright 2019 ComdivByZero
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

#include "Unistd.h"

#if defined(_WIN16) || defined(_WIN32) || defined(_WIN64)
	O7_ALWAYS_INLINE o7_int_t readlink(char const path[], char buf[], size_t len) {
		O7_ASSERT(0>1);
		return -1;
	}
#else
#	include <unistd.h>
#endif

static o7_int_t Len(o7_int_t str_len, o7_char const str[/*len0*/]) {
	o7_int_t i;

	i = 0;
	while ((i < str_len) && (str[i] != 0x00u)) {
		i += 1;
	}
	return i;
}

extern o7_int_t
Unistd_Readlink(o7_int_t path_len, o7_char const pathname[O7_VLA(path_len)],
                o7_int_t buf_len, o7_char buf[O7_VLA(buf_len)]) {
	O7_ASSERT(Len(path_len, pathname) < path_len);
	return (o7_int_t)readlink((char const *)pathname, (char *)buf, (o7_uint_t)buf_len);
}


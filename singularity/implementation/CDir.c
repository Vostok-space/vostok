/* Copyright 2018 ComdivByZero
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

#include "CDir.h"

#include <string.h>
#include <unistd.h>

extern o7_cbool
CDir_SetCurrent(o7_int_t len, o7_char path[O7_VLA(len)], o7_int_t ofs) {
	O7_ASSERT((0 <= ofs) && (ofs < len));
	return 0 == chdir(path + ofs);
}

extern o7_cbool
CDir_GetCurrent(o7_int_t len, o7_char path[O7_VLA(len)], o7_int_t *pofs) {
	o7_int_t ofs;
	o7_cbool ok;
	ofs = *pofs;
	O7_ASSERT((0 <= ofs) && (ofs < len));
	ok = NULL != getcwd(path + ofs, len - ofs);
	if (ok) {
		*pofs = ofs + strlen(path + ofs);
	}
	return ok;
}


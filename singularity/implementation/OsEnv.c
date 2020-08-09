/* Copyright 2017,2020 ComdivByZero
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

#include "OsEnv.h"

extern o7_bool OsEnv_Exist(O7_FPA(o7_char const, name)) {
	return NULL != getenv((char *)name);
}

extern o7_bool OsEnv_Get(O7_FPA(o7_char, val), o7_int_t *ofs, O7_FPA(o7_char const, name)) {
	char *env;
	o7_int_t i, j;
	assert((0 <= *ofs) && (*ofs < O7_FPA_LEN(val) - 1));

	env = getenv((char *)name);
	if (NULL != env) {
		i = *ofs;
		j = 0;
		while ((i < O7_FPA_LEN(val) - 1) && (env[j] != '\0')) {
			val[i] = (o7_char)env[j];
			i += 1;
			j += 1;
		}
		val[i] = '\0';
		*ofs = i;
	}
	return (NULL != env) && ('\0' == env[j]);
}


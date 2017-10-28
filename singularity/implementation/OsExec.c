/* Copyright 2017 ComdivByZero
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
#define O7C_BOOL_UNDEFINED
#include <o7c.h>

#include "OsExec.h"

extern int OsExec_Do(int len, o7c_char const cmd[O7C_VLA(len)]) {
	return system((char const *)cmd);
}


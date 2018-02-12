/* Copyright 2016 ComdivByZero
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
#if !defined HEADER_GUARD_CLI
#    define  HEADER_GUARD_CLI 1

extern int CLI_count;

extern o7_cbool CLI_Get(
	o7_int_t len, char unsigned str[O7_VLA(len)], o7_int_t *ofs, o7_int_t arg);

extern void CLI_SetExitCode(int code);

extern void CLI_init(void);
O7_ALWAYS_INLINE void CLI_done(void) {}

#endif

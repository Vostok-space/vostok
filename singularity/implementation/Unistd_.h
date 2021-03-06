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
#if !defined HEADER_GUARD_Unistd
#    define  HEADER_GUARD_Unistd 1

extern o7_int_t Unistd_pageSize;

extern o7_int_t Unistd_Readlink(O7_FPA(o7_char const, pathname), O7_FPA(o7_char, buf));

extern o7_int_t Unistd_Sysconf(o7_int_t name);

extern o7_int_t Unistd_Chdir(O7_FPA(o7_char const, path));

O7_ALWAYS_INLINE void Unistd_init(void) { ; }
O7_ALWAYS_INLINE void Unistd_done(void) { ; }
#endif

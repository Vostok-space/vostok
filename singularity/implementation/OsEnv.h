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
#if !defined HEADER_GUARD_OsEnv
#    define  HEADER_GUARD_OsEnv 1


#define OsEnv_MaxLen_cnst 4096

extern o7_bool OsEnv_Exist(O7_FPA(o7_char const, name));
extern o7_bool OsEnv_Get(O7_FPA(o7_char, val), o7_int_t *ofs, O7_FPA(o7_char const, name));

O7_ALWAYS_INLINE void OsEnv_init(void) { ; }
O7_ALWAYS_INLINE void OsEnv_done(void) { ; }
#endif

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
#if !defined HEADER_GUARD_CDir
#    define  HEADER_GUARD_CDir 1

extern o7_cbool
CDir_SetCurrent(o7_int_t len, o7_char path[O7_VLA(len)], o7_int_t ofs);

extern o7_cbool
CDir_GetCurrent(o7_int_t len, o7_char path[O7_VLA(len)], o7_int_t *ofs);

O7_ALWAYS_INLINE void CDir_init(void) { ; }
#endif

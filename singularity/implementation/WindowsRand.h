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
#if !defined HEADER_GUARD_WindowsRand
#    define  HEADER_GUARD_WindowsRand 1

extern o7_cbool WindowsRand_Open(void);

extern void WindowsRand_Close(void);

extern o7_cbool WindowsRand_Read(o7_int_t len, char unsigned buf[O7_VLA(len)],
                                 o7_int_t ofs, o7_int_t count);

static inline void WindowsRand_init(void) { ; }
static inline void WindowsRand_done(void) { ; }
#endif

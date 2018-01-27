/* Copyright 2017-2018 ComdivByZero
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
#if !defined HEADER_GUARD_WindowsDir
#    define  HEADER_GUARD_WindowsDir 1

typedef struct WindowsDir_FindData_s *WindowsDir_FindData;
#define WindowsDir_FindData_s_tag o7_base_tag
extern void WindowsDir_FindData_s_undef(WindowsDir_FindData r);

typedef struct WindowsDir_FindId_s *WindowsDir_FindId;
#define WindowsDir_FindId_s_tag o7_base_tag
extern void WindowsDir_FindId_s_undef(WindowsDir_FindId r);

extern o7_bool WindowsDir_supported;

extern o7_bool WindowsDir_FindFirst(WindowsDir_FindId *id, WindowsDir_FindData *d,
                                    int len, o7_char filespec[O7_VLA(len)], int ofs);

extern o7_bool WindowsDir_FindNext(WindowsDir_FindData *d, WindowsDir_FindId id);

extern o7_bool WindowsDir_Close(WindowsDir_FindId *id);

extern o7_bool WindowsDir_CopyName(int len, o7_char buf[O7_VLA(len)], int *ofs,
                                   WindowsDir_FindData f);

O7_INLINE void WindowsDir_init(void) {}
#endif

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
#if !defined HEADER_GUARD_PosixDir
#    define  HEADER_GUARD_PosixDir 1

typedef struct PosixDir_Dir_s *PosixDir_Dir;
#define PosixDir_Dir_s_tag o7_base_tag
O7_INLINE void PosixDir_Dir_s_undef(PosixDir_Dir r) {}

typedef struct dirent *PosixDir_Ent;
#define PosixDir_Ent_s_tag o7_base_tag
O7_INLINE void PosixDir_Ent_s_undef(PosixDir_Ent r) {}

extern o7_bool PosixDir_supported;

extern o7_bool PosixDir_Open(PosixDir_Dir *d,
                             o7_int_t len, o7_char name[O7_VLA(len)], o7_int_t ofs);

extern o7_bool PosixDir_Close(PosixDir_Dir *d);

extern o7_bool PosixDir_Read(PosixDir_Ent *e, PosixDir_Dir d);

extern o7_bool PosixDir_CopyName(o7_int_t len, o7_char buf[O7_VLA(len)], o7_int_t *ofs,
                                 PosixDir_Ent e);

O7_INLINE void PosixDir_init(void) {}
#endif

/* Copyright 2016-2017,2020,2023 ComdivByZero
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
#if !defined HEADER_GUARD_CFiles
#    define  HEADER_GUARD_CFiles 1

#define CFiles_KiB_cnst 1024
#define CFiles_MiB_cnst (CFiles_KiB_cnst * 1024)
#define CFiles_GiB_cnst (CFiles_MiB_cnst * 1024)

typedef struct CFiles_Implement* CFiles_File;

extern CFiles_File CFiles_in, CFiles_out, CFiles_err;

extern CFiles_File CFiles_Open(
	O7_FPA(o7_char, name), o7_int_t ofs,
	O7_FPA(o7_char, mode));

extern void CFiles_Close(CFiles_File *file);

extern int CFiles_Read (CFiles_File file, O7_FPA(o7_char, buf), o7_int_t ofs, o7_int_t count);
extern int CFiles_Write(CFiles_File file, O7_FPA(o7_char, buf), o7_int_t ofs, o7_int_t count);

O7_ALWAYS_INLINE
int CFiles_ReadChars(CFiles_File file, O7_FPA(o7_char, buf), o7_int_t ofs, o7_int_t count) {
	return CFiles_Read(file, O7_APA(buf), ofs, count);
}

O7_ALWAYS_INLINE
int CFiles_WriteChars(CFiles_File file, O7_FPA(o7_char, buf), o7_int_t ofs, o7_int_t count) {
	return CFiles_Write(file, O7_APA(buf), ofs, count);
}

extern o7_cbool CFiles_Flush(CFiles_File file);

extern o7_int_t CFiles_Seek(CFiles_File file, o7_int_t gibs, o7_int_t bytes);

extern o7_int_t CFiles_Tell(CFiles_File file, o7_int_t *gibs, o7_int_t *bytes);

extern o7_int_t CFiles_Remove(O7_FPA(o7_char const, name), o7_int_t ofs);

extern o7_cbool CFiles_Exist(O7_FPA(o7_char const, name), o7_int_t ofs);

extern o7_cbool CFiles_Rename(O7_FPA(o7_char const, src ), o7_int_t sofs,
                              O7_FPA(o7_char const, dest), o7_int_t dofs);

extern void CFiles_init(void);
O7_ALWAYS_INLINE void CFiles_done(void) { ; }

#endif

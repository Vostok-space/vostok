/* Copyright 2016-2017,2020,2023-2024 ComdivByZero
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
#include <stdio.h>
#include <errno.h>

#include <o7.h>
#include "CFiles.h"

struct CFiles_Implement {
	FILE *file;
};
static o7_tag_t CFiles_File_tag;

typedef char RawData[O7_MEMINFO_SIZE + sizeof(struct CFiles_Implement)];

static RawData fin, fout, ferr;

CFiles_File CFiles_in  = (CFiles_File)(fin  + O7_MEMINFO_SIZE),
            CFiles_out = (CFiles_File)(fout + O7_MEMINFO_SIZE),
            CFiles_err = (CFiles_File)(ferr + O7_MEMINFO_SIZE);

extern CFiles_File CFiles_Open(
	O7_FPA(o7_char, name), o7_int_t ofs,
	O7_FPA(o7_char, mode))
{
	CFiles_File file = NULL;
	assert(0 <= O7_FPA_LEN(name));
	assert(ofs < O7_FPA_LEN(name));
	O7_NEW2(&file, CFiles_File_tag, NULL);
	if (NULL != file) {
		file->file = fopen((char *)(name + ofs), (char *)mode);
		if (NULL == file->file) {
			O7_NULL(&file);
		}
	}
	o7_unhold(file);
	return file;
}

extern void CFiles_Close(CFiles_File *file) {
	if (*file != NULL) {
		fclose((*file)->file);
		(*file)->file = NULL;
		O7_NULL(file);
	}
}

extern int CFiles_Read(CFiles_File file, O7_FPA(o7_char, buf), o7_int_t ofs, o7_int_t count) {
	assert(file->file != NULL);
	assert(ofs >= 0);
	assert(count >= 0);
	assert(O7_FPA_LEN(buf) - count >= ofs);
	return fread(buf + ofs, 1, count, file->file);
}

extern int CFiles_Write(CFiles_File file, O7_FPA(o7_char, buf), o7_int_t ofs, o7_int_t count) {
	assert(file->file != NULL);
	assert(ofs >= 0);
	assert(count >= 0);
	assert(O7_FPA_LEN(buf) - count >= ofs);
	return fwrite(buf + ofs, 1, count, file->file);
}

extern o7_cbool CFiles_Flush(CFiles_File file) {
	assert(file->file != NULL);
	return 0 == fflush(file->file);
}

extern o7_int_t CFiles_Seek(CFiles_File file, o7_int_t gibs, o7_int_t bytes) {
	assert(file->file != NULL);
	assert((gibs >= 0) && ((INT_MAX < LONG_MAX / CFiles_GiB_cnst)
	                   || (gibs < LONG_MAX / CFiles_GiB_cnst)));
	assert((bytes >= 0) && (bytes < CFiles_GiB_cnst));
	return fseek(file->file, (long)gibs * CFiles_GiB_cnst + bytes, SEEK_SET) == 0;
}

extern o7_int_t CFiles_Tell(CFiles_File file, o7_int_t *gibs, o7_int_t *bytes) {
	long pos;
	assert(file->file != NULL);

	pos = ftell(file->file);
	if (pos >= 0) {
		*gibs = pos / CFiles_GiB_cnst;
		*bytes = pos % CFiles_GiB_cnst;
	} else {
		*gibs = INT_MIN;
		*bytes = INT_MIN;
	}
	return pos >= 0;
}

extern o7_int_t CFiles_Remove(O7_FPA(o7_char const, name), o7_int_t ofs) {
	assert(0 <= ofs);
	assert(ofs < O7_FPA_LEN(name) - 1);
	return remove((char const *)name + ofs) == 0;
}

extern o7_cbool CFiles_Exist(O7_FPA(o7_char const, name), o7_int_t ofs) {
	o7_cbool exist;
	FILE *file;
	assert(0 <= ofs);
	assert(ofs < O7_FPA_LEN(name) - 1);
	file = fopen((char const *)(name + ofs), "rb");
	exist = (NULL != file) || (errno != ENOENT);
	if (NULL != file) {
		fclose(file);
	}
	return exist;
}

extern o7_cbool CFiles_Rename(O7_FPA(o7_char const, src ), o7_int_t sofs,
                              O7_FPA(o7_char const, dest), o7_int_t dofs) {
	assert(0 <= sofs);
	assert(sofs < O7_FPA_LEN(src) - 1);

	assert(0 <= dofs);
	assert(dofs < O7_FPA_LEN(dest) - 1);

	return 0 == rename((char *)src + sofs, (char *)dest + dofs);
}

static void release(CFiles_File f) {
	if (NULL != f->file) {
		fclose(f->file);
		f->file = NULL;
	}
}

extern void CFiles_init(void) {
	static char initialized = 0;
	if (0 == initialized) {
		initialized += 1;
		CFiles_File_tag.release = (void (*)(void *))release;

		o7_mem_info_init((void *)fin, &CFiles_File_tag);
		CFiles_in->file = stdin;

		o7_mem_info_init((void *)fout, &CFiles_File_tag);
		CFiles_out->file = stdout;

		o7_mem_info_init((void *)ferr, &CFiles_File_tag);
		CFiles_err->file = stderr;
	}
}

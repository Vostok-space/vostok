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
#include <stdlib.h>
#include <stddef.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>
#include <stdio.h>

#include <o7c.h>

#include "CFiles.h"

struct CFiles_Implement {
	FILE *file;
};

extern CFiles_File CFiles_Open(char unsigned name[/*len*/], int name_len,
							   int ofs, char unsigned mode[/*len*/], int mode_len) {
	CFiles_File file = NULL;
	assert(name_len >= 0);
	assert(ofs < name_len);
	O7C_NEW(&file, NULL);
	if (NULL != file) {
		file->file = fopen((char *)(name + ofs), mode);
		if (NULL == file->file) {
			O7C_NULL(&file);
		}
	}
	return file;
}

extern void CFiles_Close(CFiles_File *file) {
	if (*file != NULL) {
		fclose((*file)->file);
		(*file)->file = NULL;
		O7C_NULL(file);
	}
}

extern int CFiles_Read(CFiles_File file,
					   char unsigned buf[/*len*/], int buf_len, int ofs, int count) {
	assert(buf != NULL);
	assert(ofs >= 0);
	assert(count >= 0);
	assert(buf_len - count >= ofs);
	return fread(buf + ofs, 1, count, file->file);
}

extern int CFiles_Write(CFiles_File file,
						char unsigned buf[/*len*/], int buf_len, int ofs, int count) {
	assert(ofs >= 0);
	assert(count >= 0);
	assert(buf_len - count >= ofs);
	return fwrite(buf + ofs, 1, count, file->file);
}

extern int CFiles_Seek(CFiles_File file, int gibs, int bytes) {
	assert((gibs >= 0) && (gibs < LONG_MAX / CFiles_GiB_cnst));
	assert((bytes >= 0) && (bytes < CFiles_GiB_cnst));
	return fseek(file->file, (long)gibs * CFiles_GiB_cnst + bytes, SEEK_SET) == 0;
}

extern int CFiles_Tell(CFiles_File file, int *gibs, int *bytes) {
	long pos;
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

extern int CFiles_Remove(char unsigned name[/*len*/], int name_len, int ofs) {
	assert(ofs >= 0);
	assert(name_len > 1);
	return remove(name) == 0;
}

extern void CFiles_init(void) {
	;
}

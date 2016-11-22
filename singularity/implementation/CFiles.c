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
	CFiles_File file;
	assert(name_len >= 0);
	assert(ofs < name_len);
	file = (CFiles_File)o7c_new(sizeof(*file), NULL);
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
		O7C_NULL(file);
	}
}

extern int CFiles_Read(CFiles_File file,
					   char unsigned buf[/*len*/], int buf_len, int ofs, int count) {
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

extern void CFiles_init(void) {
	;
}

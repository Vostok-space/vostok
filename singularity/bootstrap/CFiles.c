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
	file = (CFiles_File)malloc(sizeof(*file));
	if (NULL != file) {
		/*printf("open %s %s\n", (char *)(name + ofs), mode);*/
		file->file = fopen((char *)(name + ofs), mode);
		if (NULL == file->file) {
			free(file); file = NULL;
		}
	}
	return file;
}

extern void CFiles_Close(CFiles_File *file, int *file_tag) {
	fclose((*file)->file);
	*file = NULL;
}

extern int CFiles_Read(CFiles_File file, int *file_tag,
					   char unsigned buf[/*len*/], int buf_len, int ofs, int count) {
	assert(ofs >= 0);
	assert(count >= 0);
	assert(buf_len - count >= ofs);
	return fread(buf + ofs, 1, count, file->file);
}

extern int CFiles_Write(CFiles_File file, int *file_tag,
						char unsigned buf[/*len*/], int buf_len, int ofs, int count) {
	assert(ofs >= 0);
	assert(count >= 0);
	assert(buf_len - count >= ofs);
	return fwrite(buf + ofs, 1, count, file->file);
}

extern void CFiles_init_(void) {
	;
}

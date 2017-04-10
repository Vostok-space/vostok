/*  Implementations of VDataStream interfaces by CFiles
 *  Copyright (C) 2016  ComdivByZero
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#if !defined(HEADER_GUARD_VFileStream)
#define HEADER_GUARD_VFileStream

#include "VDataStream.h"
#include "CFiles.h"

typedef struct VFileStream_RIn *VFileStream_In;
typedef struct VFileStream_RIn {
	VDataStream_In _;
	CFiles_File file;
} VFileStream_RIn;
extern o7c_tag_t VFileStream_RIn_tag;

typedef struct VFileStream_ROut *VFileStream_Out;
typedef struct VFileStream_ROut {
	VDataStream_Out _;
	CFiles_File file;
} VFileStream_ROut;
extern o7c_tag_t VFileStream_ROut_tag;


extern struct VFileStream_RIn *VFileStream_OpenIn(o7c_char name[/*len0*/], int name_len0);

extern void VFileStream_CloseIn(struct VFileStream_RIn **in_);

extern struct VFileStream_ROut *VFileStream_OpenOut(o7c_char name[/*len0*/], int name_len0);

extern void VFileStream_CloseOut(struct VFileStream_ROut **out);

extern void VFileStream_init(void);
#endif

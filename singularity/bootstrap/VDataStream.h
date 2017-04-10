/*  Abstract interfaces for data input and output
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
#if !defined(HEADER_GUARD_VDataStream)
#define HEADER_GUARD_VDataStream

#include "V.h"

typedef struct VDataStream_In *VDataStream_PIn;
typedef struct VDataStream_In {
	V_Base _;
	int (*read)(struct VDataStream_In *in_, o7c_tag_t in__tag, o7c_char buf[/*len0*/], int buf_len0, int ofs, int count);
} VDataStream_In;
extern o7c_tag_t VDataStream_In_tag;

typedef struct VDataStream_Out *VDataStream_POut;
typedef struct VDataStream_Out {
	V_Base _;
	int (*write)(struct VDataStream_Out *out, o7c_tag_t out_tag, o7c_char buf[/*len0*/], int buf_len0, int ofs, int count);
} VDataStream_Out;
extern o7c_tag_t VDataStream_Out_tag;

typedef int (*VDataStream_ReadProc)(struct VDataStream_In *in_, o7c_tag_t in__tag, o7c_char buf[/*len0*/], int buf_len0, int ofs, int count);
typedef int (*VDataStream_WriteProc)(struct VDataStream_Out *out, o7c_tag_t out_tag, o7c_char buf[/*len0*/], int buf_len0, int ofs, int count);

extern void VDataStream_InitIn(struct VDataStream_In *in_, o7c_tag_t in__tag, VDataStream_ReadProc read);

extern int VDataStream_Read(struct VDataStream_In *in_, o7c_tag_t in__tag, o7c_char buf[/*len0*/], int buf_len0, int ofs, int count);

extern void VDataStream_InitOut(struct VDataStream_Out *out, o7c_tag_t out_tag, VDataStream_WriteProc write);

extern int VDataStream_Write(struct VDataStream_Out *out, o7c_tag_t out_tag, o7c_char buf[/*len0*/], int buf_len0, int ofs, int count);

extern void VDataStream_init(void);
#endif

/*  Strings storage
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
#if !defined(HEADER_GUARD_StringStore)
#define HEADER_GUARD_StringStore

#include "Log.h"
#include "Utf8.h"
#include "V.h"
#include "VDataStream.h"

#define StringStore_BlockSize_cnst 256

typedef struct StringStore_Block_s {
	V_Base _;
	o7c_char s[StringStore_BlockSize_cnst + 1];
	struct StringStore_Block_s *next;
	int num;
} *StringStore_Block;
extern o7c_tag_t StringStore_Block_s_tag;

typedef struct StringStore_String {
	V_Base _;
	struct StringStore_Block_s *block;
	int ofs;
} StringStore_String;
extern o7c_tag_t StringStore_String_tag;

typedef struct StringStore_Iterator {
	V_Base _;
	o7c_char char_;
	struct StringStore_Block_s *b;
	int i;
} StringStore_Iterator;
extern o7c_tag_t StringStore_Iterator_tag;

typedef struct StringStore_Store {
	V_Base _;
	struct StringStore_Block_s *first;
	struct StringStore_Block_s *last;
	int ofs;
} StringStore_Store;
extern o7c_tag_t StringStore_Store_tag;


extern void StringStore_LogLoopStr(o7c_char s[/*len0*/], int s_len0, int j, int end);

extern void StringStore_Undef(struct StringStore_String *s, o7c_tag_t s_tag);

extern o7c_bool StringStore_IsDefined(struct StringStore_String *s, o7c_tag_t s_tag);

extern void StringStore_Put(struct StringStore_Store *store, o7c_tag_t store_tag, struct StringStore_String *w, o7c_tag_t w_tag, o7c_char s[/*len0*/], int s_len0, int j, int end);

extern o7c_bool StringStore_GetIter(struct StringStore_Iterator *iter, o7c_tag_t iter_tag, struct StringStore_String *s, o7c_tag_t s_tag, int ofs);

extern o7c_bool StringStore_IterNext(struct StringStore_Iterator *iter, o7c_tag_t iter_tag);

extern o7c_bool StringStore_IsEqualToChars(struct StringStore_String *w, o7c_tag_t w_tag, o7c_char s[/*len0*/], int s_len0, int j, int end);

extern o7c_bool StringStore_IsEqualToString(struct StringStore_String *w, o7c_tag_t w_tag, o7c_char s[/*len0*/], int s_len0);

extern o7c_bool StringStore_CopyToChars(o7c_char d[/*len0*/], int d_len0, int *dofs, struct StringStore_String *w, o7c_tag_t w_tag);

extern void StringStore_StoreInit(struct StringStore_Store *s, o7c_tag_t s_tag);

extern void StringStore_StoreDone(struct StringStore_Store *s, o7c_tag_t s_tag);

extern o7c_bool StringStore_CopyChars(o7c_char dest[/*len0*/], int dest_len0, int *destOfs, o7c_char src[/*len0*/], int src_len0, int srcOfs, int srcEnd);

extern o7c_bool StringStore_CopyCharsNull(o7c_char dest[/*len0*/], int dest_len0, int *destOfs, o7c_char src[/*len0*/], int src_len0);

extern int StringStore_CalcLen(o7c_char str[/*len0*/], int str_len0, int ofs);

extern int StringStore_Write(struct VDataStream_Out *out, o7c_tag_t out_tag, struct StringStore_String *str, o7c_tag_t str_tag);

extern void StringStore_init(void);
#endif

#if !defined HEADER_GUARD_StringStore
#    define  HEADER_GUARD_StringStore 1

#include "Log.h"
#include "Utf8.h"
#include "V.h"
#include "VDataStream.h"

#define StringStore_BlockSize_cnst 256

typedef struct StringStore_RBlock *StringStore_Block;
typedef struct StringStore_RBlock {
	V_Base _;
	o7_char s[StringStore_BlockSize_cnst + 1];
	struct StringStore_RBlock *next;
	o7_int_t num;
} StringStore_RBlock;
#define StringStore_RBlock_tag V_Base_tag


typedef struct StringStore_String {
	V_Base _;
	struct StringStore_RBlock *block;
	o7_int_t ofs;
} StringStore_String;
#define StringStore_String_tag V_Base_tag


typedef struct StringStore_Iterator {
	V_Base _;
	o7_char char_;
	struct StringStore_RBlock *b;
	o7_int_t i;
} StringStore_Iterator;
#define StringStore_Iterator_tag V_Base_tag


typedef struct StringStore_Store {
	V_Base _;
	struct StringStore_RBlock *first;
	struct StringStore_RBlock *last;
	o7_int_t ofs;
} StringStore_Store;
#define StringStore_Store_tag V_Base_tag


extern void StringStore_Undef(struct StringStore_String *s);

extern o7_bool StringStore_IsDefined(struct StringStore_String *s);

extern void StringStore_Put(struct StringStore_Store *store, struct StringStore_String *w, o7_int_t s_len0, o7_char s[/*len0*/], o7_int_t j, o7_int_t end);

extern o7_bool StringStore_GetIter(struct StringStore_Iterator *iter, struct StringStore_String *s, o7_int_t ofs);

extern o7_bool StringStore_IterNext(struct StringStore_Iterator *iter);

extern o7_char StringStore_GetChar(struct StringStore_String *s, o7_int_t i);

extern o7_bool StringStore_IsEqualToChars(struct StringStore_String *w, o7_int_t s_len0, o7_char s[/*len0*/], o7_int_t j, o7_int_t end);

extern o7_bool StringStore_IsEqualToString(struct StringStore_String *w, o7_int_t s_len0, o7_char s[/*len0*/]);

extern o7_bool StringStore_IsEqualToStringIgnoreCase(struct StringStore_String *w, o7_int_t s_len0, o7_char s[/*len0*/]);

extern o7_int_t StringStore_Compare(struct StringStore_String *w1, struct StringStore_String *w2);

extern o7_bool StringStore_SearchSubString(struct StringStore_String *w, o7_int_t s_len0, o7_char s[/*len0*/]);

extern o7_bool StringStore_CopyToChars(o7_int_t d_len0, o7_char d[/*len0*/], o7_int_t *dofs, struct StringStore_String *w);

extern void StringStore_StoreInit(struct StringStore_Store *s);

extern void StringStore_StoreDone(struct StringStore_Store *s);

extern o7_int_t StringStore_Write(struct VDataStream_Out *out, o7_tag_t *out_tag, struct StringStore_String *str);

extern void StringStore_init(void);
#endif

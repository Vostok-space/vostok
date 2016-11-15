#if !defined(HEADER_GUARD_StringStore)
#define HEADER_GUARD_StringStore

#include "Log.h"
#include "Utf8.h"
#include "V.h"
#include "VDataStream.h"

#define StringStore_BlockSize_cnst 256

typedef struct StringStore_Block_s {
	struct V_Base _;
	o7c_char s[StringStore_BlockSize_cnst + 1];
	struct StringStore_Block_s *next;
	int num;
} *StringStore_Block;
extern o7c_tag_t StringStore_Block_s_tag;

typedef struct StringStore_String {
	struct V_Base _;
	struct StringStore_Block_s *block;
	int ofs;
} StringStore_String;
extern o7c_tag_t StringStore_String_tag;

typedef struct StringStore_Store {
	struct V_Base _;
	struct StringStore_Block_s *first;
	struct StringStore_Block_s *last;
	int ofs;
} StringStore_Store;
extern o7c_tag_t StringStore_Store_tag;


extern void StringStore_Put(struct StringStore_Store *store, o7c_tag_t store_tag, struct StringStore_String *w, o7c_tag_t w_tag, o7c_char s[/*len0*/], int s_len0, int j, int end);

extern o7c_bool StringStore_IsEqualToChars(struct StringStore_String *w, o7c_tag_t w_tag, o7c_char s[/*len0*/], int s_len0, int j, int end);

extern o7c_bool StringStore_IsEqualToString(struct StringStore_String *w, o7c_tag_t w_tag, o7c_char s[/*len0*/], int s_len0);

extern void StringStore_CopyToChars(o7c_char d[/*len0*/], int d_len0, int *dofs, struct StringStore_String *w, o7c_tag_t w_tag);

extern void StringStore_StoreInit(struct StringStore_Store *s, o7c_tag_t s_tag);

extern void StringStore_StoreDone(struct StringStore_Store *s, o7c_tag_t s_tag);

extern o7c_bool StringStore_CopyChars(o7c_char dest[/*len0*/], int dest_len0, int *destOfs, o7c_char src[/*len0*/], int src_len0, int srcOfs, int srcEnd);

extern int StringStore_Write(struct VDataStream_Out *out, o7c_tag_t out_tag, struct StringStore_String *str, o7c_tag_t str_tag);

extern void StringStore_init(void);
#endif

#if !defined(HEADER_GUARD_StringStore)
#define HEADER_GUARD_StringStore

#include "Log.h"
#include "Utf8.h"
#include "V.h"
#include "VDataStream.h"

#define StringStore_BlockSize_cnst 256

typedef struct StringStore_Block_s {
	struct V_Base _;
	char unsigned s[StringStore_BlockSize_cnst + 1];
	struct StringStore_Block_s *next;
	int num;
} *StringStore_Block;
extern int StringStore_Block_s_tag[15];

typedef struct StringStore_String {
	struct V_Base _;
	struct StringStore_Block_s *block;
	int ofs;
} StringStore_String;
extern int StringStore_String_tag[15];

typedef struct StringStore_Store {
	struct V_Base _;
	struct StringStore_Block_s *first;
	struct StringStore_Block_s *last;
	int ofs;
} StringStore_Store;
extern int StringStore_Store_tag[15];


extern void StringStore_Put(struct StringStore_Store *store, int *store_tag, struct StringStore_String *w, int *w_tag, char unsigned s[/*len0*/], int s_len0, int j, int end);

extern bool StringStore_IsEqualToChars(struct StringStore_String *w, int *w_tag, char unsigned s[/*len0*/], int s_len0, int j, int end);

extern bool StringStore_IsEqualToString(struct StringStore_String *w, int *w_tag, char unsigned s[/*len0*/], int s_len0);

extern void StringStore_CopyToChars(char unsigned d[/*len0*/], int d_len0, int *dofs, struct StringStore_String *w, int *w_tag);

extern void StringStore_StoreInit(struct StringStore_Store *s, int *s_tag);

extern void StringStore_StoreDone(struct StringStore_Store *s, int *s_tag);

extern bool StringStore_CopyChars(char unsigned dest[/*len0*/], int dest_len0, int *destOfs, char unsigned src[/*len0*/], int src_len0, int srcOfs, int srcEnd);

extern int StringStore_Write(struct VDataStream_Out *out, int *out_tag, struct StringStore_String *str, int *str_tag);

extern void StringStore_init_(void);
#endif

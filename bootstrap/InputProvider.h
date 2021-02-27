#if !defined HEADER_GUARD_InputProvider
#    define  HEADER_GUARD_InputProvider 1

#include "V.h"
#include "VDataStream.h"

typedef struct InputProvider_Iter *InputProvider_PIter;
typedef struct VDataStream_In *(*InputProvider_NextInput)(struct V_Base *iter, o7_tag_t *iter_tag, o7_bool *declaration);
typedef struct InputProvider_Iter {
	V_Base _;
	InputProvider_NextInput next;
} InputProvider_Iter;
#define InputProvider_Iter_tag V_Base_tag


typedef struct InputProvider_R *InputProvider_P;
typedef struct InputProvider_Iter *(*InputProvider_GetIterator)(struct InputProvider_R *prov, o7_int_t name_len0, o7_char name[/*len0*/]);
typedef struct InputProvider_R {
	V_Base _;
	InputProvider_GetIterator get;
} InputProvider_R;
#define InputProvider_R_tag V_Base_tag


extern void InputProvider_Init(struct InputProvider_R *p, InputProvider_GetIterator get);

extern void InputProvider_InitIter(struct InputProvider_Iter *it, InputProvider_NextInput next);

extern o7_bool InputProvider_Get(struct InputProvider_R *p, struct InputProvider_Iter **it, o7_int_t name_len0, o7_char name[/*len0*/]);

extern o7_bool InputProvider_Next(struct InputProvider_Iter **it, struct VDataStream_In **in_, o7_bool *declaration);

extern void InputProvider_init(void);
#endif

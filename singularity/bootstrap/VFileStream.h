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

#if !defined(HEADER_GUARD_VDataStream)
#define HEADER_GUARD_VDataStream

#include "V.h"

typedef struct VDataStream_In *VDataStream_PIn;
typedef struct VDataStream_In {
	struct V_Base _;
	int (*read)(struct VDataStream_In *in_, int *in__tag, char unsigned buf[/*len0*/], int buf_len0, int ofs, int count);
} VDataStream_In;
extern int VDataStream_In_tag[15];

typedef struct VDataStream_Out *VDataStream_POut;
typedef struct VDataStream_Out {
	struct V_Base _;
	int (*write)(struct VDataStream_Out *out, int *out_tag, char unsigned buf[/*len0*/], int buf_len0, int ofs, int count);
} VDataStream_Out;
extern int VDataStream_Out_tag[15];

typedef int (*VDataStream_ReadProc)(struct VDataStream_In *in_, int *in__tag, char unsigned buf[/*len0*/], int buf_len0, int ofs, int count);
typedef int (*VDataStream_WriteProc)(struct VDataStream_Out *out, int *out_tag, char unsigned buf[/*len0*/], int buf_len0, int ofs, int count);

extern void VDataStream_InitIn(struct VDataStream_In *in_, int *in__tag, VDataStream_ReadProc read);

extern int VDataStream_Read(struct VDataStream_In *in_, int *in__tag, char unsigned buf[/*len0*/], int buf_len0, int ofs, int count);

extern void VDataStream_InitOut(struct VDataStream_Out *out, int *out_tag, VDataStream_WriteProc write);

extern int VDataStream_Write(struct VDataStream_Out *out, int *out_tag, char unsigned buf[/*len0*/], int buf_len0, int ofs, int count);

extern void VDataStream_init_(void);
#endif

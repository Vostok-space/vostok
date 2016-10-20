#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#include <o7c.h>

#include "VFileStream.h"

int VFileStream_RIn_tag[15];

int VFileStream_ROut_tag[15];


static int Read(struct VDataStream_In *in_, int *in__tag, char unsigned buf[/*len0*/], int buf_len0, int ofs, int count) {
	return CFiles_Read((O7C_GUARD(VFileStream_RIn, &(*in_), in__tag)).file, NULL, buf, buf_len0, ofs, count);
}

extern struct VFileStream_RIn *VFileStream_OpenIn(char unsigned name[/*len0*/], int name_len0) {
	struct VFileStream_RIn *in_;
	CFiles_File file;

	in_ = o7c_new(sizeof(*in_), VFileStream_RIn_tag);
	if (in_ != NULL) {
		file = CFiles_Open(name, name_len0, 0, "rb", 3);
		if (file == NULL) {
			in_ = NULL;
		} else {
			VDataStream_InitIn(&(*in_)._, VFileStream_RIn_tag, Read);
			in_->file = file;
		}
	}
	return in_;
}

extern void VFileStream_CloseIn(struct VFileStream_RIn **in_, int *in__tag) {
	CFiles_Close(&(*in_)->file, NULL);
	(*in_) = NULL;
}

static int Write(struct VDataStream_Out *out, int *out_tag, char unsigned buf[/*len0*/], int buf_len0, int ofs, int count) {
	return CFiles_Write((O7C_GUARD(VFileStream_ROut, &(*out), out_tag)).file, NULL, buf, buf_len0, ofs, count);
}

extern struct VFileStream_ROut *VFileStream_OpenOut(char unsigned name[/*len0*/], int name_len0) {
	struct VFileStream_ROut *out;
	CFiles_File file;

	out = o7c_new(sizeof(*out), VFileStream_ROut_tag);
	if (out != NULL) {
		file = CFiles_Open(name, name_len0, 0, "wb", 3);
		if (file == NULL) {
			out = NULL;
		} else {
			VDataStream_InitOut(&(*out)._, VFileStream_ROut_tag, Write);
			out->file = file;
		}
	}
	return out;
}

extern void VFileStream_CloseOut(struct VFileStream_ROut **out, int *out_tag) {
	CFiles_Close(&(*out)->file, NULL);
	(*out) = NULL;
}

extern void VFileStream_init_(void) {
	static int initialized__ = 0;
	if (0 == initialized__) {
		VDataStream_init_();
		CFiles_init_();

		o7c_tag_init(VFileStream_RIn_tag, VDataStream_In_tag);
		o7c_tag_init(VFileStream_ROut_tag, VDataStream_Out_tag);

	}
	++initialized__;
}


#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#define O7C_BOOL_UNDEFINED
#include <o7c.h>

#include "VFileStream.h"

o7c_tag_t VFileStream_RIn_tag;
o7c_tag_t VFileStream_ROut_tag;

static int Read(struct VDataStream_In *in_, o7c_tag_t in__tag, o7c_char buf[/*len0*/], int buf_len0, int ofs, int count) {
	int o7c_return;

	o7c_return = CFiles_Read(O7C_GUARD_R(VFileStream_RIn, &(*in_), in__tag).file, buf, buf_len0, ofs, count);
	return o7c_return;
}

extern struct VFileStream_RIn *VFileStream_OpenIn(o7c_char name[/*len0*/], int name_len0) {
	VFileStream_In o7c_return = NULL;

	struct VFileStream_RIn *in_ = NULL;
	CFiles_File file = NULL;

	in_ = o7c_new(sizeof(*in_), VFileStream_RIn_tag);
	if (in_ != NULL) {
		O7C_ASSIGN(&(file), CFiles_Open(name, name_len0, 0, "rb", 3));
		if (file == NULL) {
			O7C_ASSIGN(&(in_), NULL);
		} else {
			VDataStream_InitIn(&(*in_)._, VFileStream_RIn_tag, Read);
			O7C_ASSIGN(&(in_->file), file);
		}
	}
	O7C_ASSIGN(&o7c_return, in_);
	o7c_release(in_); o7c_release(file);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern void VFileStream_CloseIn(struct VFileStream_RIn **in_) {
	CFiles_Close(&(*in_)->file);
	O7C_ASSIGN(&((*in_)), NULL);
}

static int Write(struct VDataStream_Out *out, o7c_tag_t out_tag, o7c_char buf[/*len0*/], int buf_len0, int ofs, int count) {
	int o7c_return;

	o7c_return = CFiles_Write(O7C_GUARD_R(VFileStream_ROut, &(*out), out_tag).file, buf, buf_len0, ofs, count);
	return o7c_return;
}

extern struct VFileStream_ROut *VFileStream_OpenOut(o7c_char name[/*len0*/], int name_len0) {
	VFileStream_Out o7c_return = NULL;

	struct VFileStream_ROut *out = NULL;
	CFiles_File file = NULL;

	out = o7c_new(sizeof(*out), VFileStream_ROut_tag);
	if (out != NULL) {
		O7C_ASSIGN(&(file), CFiles_Open(name, name_len0, 0, "wb", 3));
		if (file == NULL) {
			O7C_ASSIGN(&(out), NULL);
		} else {
			VDataStream_InitOut(&(*out)._, VFileStream_ROut_tag, Write);
			O7C_ASSIGN(&(out->file), file);
		}
	}
	O7C_ASSIGN(&o7c_return, out);
	o7c_release(out); o7c_release(file);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern void VFileStream_CloseOut(struct VFileStream_ROut **out) {
	if ((*out) != NULL) {
		CFiles_Close(&(*out)->file);
		O7C_ASSIGN(&((*out)), NULL);
	}
}

extern void VFileStream_init(void) {
	static int initialized = 0;
	if (0 == initialized) {
		VDataStream_init();
		CFiles_init();

		o7c_tag_init(VFileStream_RIn_tag, VDataStream_In_tag);
		o7c_tag_init(VFileStream_ROut_tag, VDataStream_Out_tag);

	}
	++initialized;
}


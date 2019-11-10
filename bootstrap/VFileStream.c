#include <o7.h>

#include "VFileStream.h"

o7_tag_t VFileStream_RIn_tag;
extern void VFileStream_RIn_undef(struct VFileStream_RIn *r) {
	VDataStream_In_undef(&r->_);
	r->file = NULL;
}
o7_tag_t VFileStream_ROut_tag;
extern void VFileStream_ROut_undef(struct VFileStream_ROut *r) {
	VDataStream_Out_undef(&r->_);
	r->file = NULL;
}

static o7_int_t Read(struct V_Base *in_, o7_tag_t *in__tag, o7_int_t buf_len0, char unsigned buf[/*len0*/], o7_int_t ofs, o7_int_t count) {
	return CFiles_Read(O7_GUARD_R(VFileStream_RIn, &(*in_), in__tag).file, buf_len0, buf, ofs, count);
}

static o7_int_t ReadChars(struct V_Base *in_, o7_tag_t *in__tag, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t ofs, o7_int_t count) {
	return CFiles_ReadChars(O7_GUARD_R(VFileStream_RIn, &(*in_), in__tag).file, buf_len0, buf, ofs, count);
}

static void CloseRIn(struct V_Base *in_, o7_tag_t *in__tag) {
	CFiles_Close(&O7_GUARD_R(VFileStream_RIn, &(*in_), in__tag).file);
}

extern struct VFileStream_RIn *VFileStream_OpenIn(o7_int_t name_len0, o7_char name[/*len0*/]) {
	struct VFileStream_RIn *in_ = NULL;
	CFiles_File file;

	O7_NEW(&in_, VFileStream_RIn);
	if (in_ != NULL) {
		file = CFiles_Open(name_len0, name, 0, 3, (o7_char *)"rb");
		if (file == NULL) {
			in_ = NULL;
		} else {
			VDataStream_InitIn(&(*O7_REF(in_))._, Read, ReadChars, CloseRIn);
			O7_REF(in_)->file = file;
		}
	}
	return in_;
}

extern void VFileStream_CloseIn(struct VFileStream_RIn **in_) {
	if ((*in_) != NULL) {
		CFiles_Close(&O7_REF((*in_))->file);
		(*in_) = NULL;
	}
}

static o7_int_t Write(struct V_Base *out, o7_tag_t *out_tag, o7_int_t buf_len0, char unsigned buf[/*len0*/], o7_int_t ofs, o7_int_t count) {
	return CFiles_Write(O7_GUARD_R(VFileStream_ROut, &(*out), out_tag).file, buf_len0, buf, ofs, count);
}

static o7_int_t WriteChars(struct V_Base *out, o7_tag_t *out_tag, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t ofs, o7_int_t count) {
	return CFiles_WriteChars(O7_GUARD_R(VFileStream_ROut, &(*out), out_tag).file, buf_len0, buf, ofs, count);
}

static void CloseROut(struct V_Base *out, o7_tag_t *out_tag) {
	CFiles_Close(&O7_GUARD_R(VFileStream_ROut, &(*out), out_tag).file);
}

extern struct VFileStream_ROut *VFileStream_OpenOut(o7_int_t name_len0, o7_char name[/*len0*/]) {
	struct VFileStream_ROut *out = NULL;
	CFiles_File file;

	O7_NEW(&out, VFileStream_ROut);
	if (out != NULL) {
		file = CFiles_Open(name_len0, name, 0, 3, (o7_char *)"wb");
		if (file == NULL) {
			out = NULL;
		} else {
			VDataStream_InitOut(&(*O7_REF(out))._, Write, WriteChars, CloseROut);
			O7_REF(out)->file = file;
		}
	}
	return out;
}

extern void VFileStream_CloseOut(struct VFileStream_ROut **out) {
	if ((*out) != NULL) {
		CFiles_Close(&O7_REF((*out))->file);
		(*out) = NULL;
	}
}

extern void VFileStream_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		VDataStream_init();
		CFiles_init();

		O7_TAG_INIT(VFileStream_RIn, VDataStream_In);
		O7_TAG_INIT(VFileStream_ROut, VDataStream_Out);
	}
	++initialized;
}

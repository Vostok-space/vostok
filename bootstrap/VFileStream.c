#if !defined(O7_INIT_MODEL)
#   define   O7_INIT_MODEL O7_INIT_ZERO
#endif

#include <o7.h>

#include "VFileStream.h"

o7_tag_t VFileStream_RIn_tag;
o7_tag_t VFileStream_ROut_tag;

struct VFileStream_ROut *VFileStream_out = NULL;
struct VFileStream_RIn *VFileStream_in = NULL;

static o7_int_t Read(struct V_Base *i, o7_tag_t *i_tag, o7_int_t buf_len0, char unsigned buf[/*len0*/], o7_int_t ofs, o7_int_t count) {
	return CFiles_Read(O7_GUARD_R(VFileStream_RIn, i, i_tag).file, buf_len0, buf, ofs, count);
}

static o7_int_t ReadChars(struct V_Base *i, o7_tag_t *i_tag, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t ofs, o7_int_t count) {
	return CFiles_ReadChars(O7_GUARD_R(VFileStream_RIn, i, i_tag).file, buf_len0, buf, ofs, count);
}

static void CloseRIn(struct V_Base *i, o7_tag_t *i_tag) {
	CFiles_Close(&O7_GUARD_R(VFileStream_RIn, i, i_tag).file);
}

extern struct VFileStream_RIn *VFileStream_OpenIn(o7_int_t name_len0, o7_char name[/*len0*/]) {
	struct VFileStream_RIn *i = NULL;
	CFiles_File file;

	O7_NEW(&i, VFileStream_RIn);
	if (i != NULL) {
		file = CFiles_Open(name_len0, name, 0, 3, (o7_char *)"rb");
		if (file == NULL) {
			i = NULL;
		} else {
			VDataStream_InitIn(&(*i)._, Read, ReadChars, CloseRIn);
			i->file = file;
		}
	}
	return i;
}

extern void VFileStream_CloseIn(struct VFileStream_RIn **i) {
	if (*i != NULL) {
		CFiles_Close(&(*i)->file);
		*i = NULL;
	}
}

static o7_int_t Write(struct V_Base *o, o7_tag_t *o_tag, o7_int_t buf_len0, char unsigned buf[/*len0*/], o7_int_t ofs, o7_int_t count) {
	return CFiles_Write(O7_GUARD_R(VFileStream_ROut, o, o_tag).file, buf_len0, buf, ofs, count);
}

static o7_int_t WriteChars(struct V_Base *o, o7_tag_t *o_tag, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t ofs, o7_int_t count) {
	return CFiles_WriteChars(O7_GUARD_R(VFileStream_ROut, o, o_tag).file, buf_len0, buf, ofs, count);
}

static void CloseROut(struct V_Base *o, o7_tag_t *o_tag) {
	CFiles_Close(&O7_GUARD_R(VFileStream_ROut, o, o_tag).file);
}

extern struct VFileStream_ROut *VFileStream_OpenOut(o7_int_t name_len0, o7_char name[/*len0*/]) {
	struct VFileStream_ROut *o = NULL;
	CFiles_File file;

	O7_NEW(&o, VFileStream_ROut);
	if (o != NULL) {
		file = CFiles_Open(name_len0, name, 0, 3, (o7_char *)"wb");
		if (file == NULL) {
			o = NULL;
		} else {
			VDataStream_InitOut(&(*o)._, Write, WriteChars, CloseROut);
			o->file = file;
		}
	}
	return o;
}

extern void VFileStream_CloseOut(struct VFileStream_ROut **o) {
	if (*o != NULL) {
		CFiles_Close(&(*o)->file);
		*o = NULL;
	}
}

static void WrapOut(void) {
	O7_NEW(&VFileStream_out, VFileStream_ROut);
	if (VFileStream_out != NULL) {
		VDataStream_InitOut(&(*VFileStream_out)._, Write, WriteChars, NULL);
		VFileStream_out->file = CFiles_out;
	}
}

static void WrapIn(void) {
	O7_NEW(&VFileStream_in, VFileStream_RIn);
	if (VFileStream_in != NULL) {
		VDataStream_InitIn(&(*VFileStream_in)._, Read, ReadChars, NULL);
		VFileStream_in->file = CFiles_in;
	}
}

extern void VFileStream_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		VDataStream_init();
		CFiles_init();

		O7_TAG_INIT(VFileStream_RIn, VDataStream_In);
		O7_TAG_INIT(VFileStream_ROut, VDataStream_Out);

		WrapOut();
		WrapIn();
	}
	++initialized;
}


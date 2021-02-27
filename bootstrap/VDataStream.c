#if !defined(O7_INIT_MODEL)
#   define   O7_INIT_MODEL O7_INIT_ZERO
#endif

#include <o7.h>

#include "VDataStream.h"

o7_tag_t VDataStream_Stream_tag;
#define VDataStream_In_tag VDataStream_Stream_tag
#define VDataStream_InOpener_tag V_Base_tag
#define VDataStream_Out_tag VDataStream_Stream_tag
#define VDataStream_OutOpener_tag V_Base_tag

static void EmptyClose(struct V_Base *stream, o7_tag_t *stream_tag) {
	O7_ASSERT(o7_is_r(stream_tag, stream, &VDataStream_Stream_tag));
}

static void Init(struct VDataStream_Stream *stream, VDataStream_CloseStream close) {
	V_Init(&(*stream)._);
	if (close == NULL) {
		stream->close = EmptyClose;
	} else {
		stream->close = close;
	}
}

extern void VDataStream_Close(struct VDataStream_Stream *stream) {
	if (stream != NULL) {
		stream->close(&(*stream)._, NULL);
	}
}

extern void VDataStream_InitIn(struct VDataStream_In *in_, VDataStream_ReadProc read, VDataStream_ReadCharsProc readChars, VDataStream_CloseStream close) {
	O7_ASSERT((read != NULL) || (readChars != NULL));

	Init(&(*in_)._, close);
	in_->read = read;
	in_->readChars = readChars;
}

extern void VDataStream_CloseIn(struct VDataStream_In **in_) {
	if (*in_ != NULL) {
		(*in_)->_.close(&(*(*in_))._._, NULL);
		*in_ = NULL;
	}
}

extern o7_int_t VDataStream_Read(struct VDataStream_In *in_, o7_tag_t *in__tag, o7_int_t buf_len0, char unsigned buf[/*len0*/], o7_int_t ofs, o7_int_t count) {
	o7_int_t r;

	O7_ASSERT((0 <= ofs) && (0 <= count) && (ofs <= o7_sub(buf_len0, count)));
	r = in_->read(&(*in_)._._, in__tag, buf_len0, buf, ofs, count);
	O7_ASSERT((0 <= r) && (r <= count));
	return r;
}

extern o7_int_t VDataStream_ReadWhole(struct VDataStream_In *in_, o7_tag_t *in__tag, o7_int_t buf_len0, char unsigned buf[/*len0*/]) {
	return VDataStream_Read(in_, in__tag, buf_len0, buf, 0, buf_len0);
}

extern o7_int_t VDataStream_ReadChars(struct VDataStream_In *in_, o7_tag_t *in__tag, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t ofs, o7_int_t count) {
	o7_int_t r;

	O7_ASSERT((0 <= ofs) && (0 <= count) && (ofs <= o7_sub(buf_len0, count)));
	r = in_->readChars(&(*in_)._._, in__tag, buf_len0, buf, ofs, count);
	O7_ASSERT((0 <= r) && (r <= count));
	return r;
}

extern o7_int_t VDataStream_ReadCharsWhole(struct VDataStream_In *in_, o7_tag_t *in__tag, o7_int_t buf_len0, o7_char buf[/*len0*/]) {
	return VDataStream_ReadChars(in_, in__tag, buf_len0, buf, 0, buf_len0);
}

extern void VDataStream_InitOut(struct VDataStream_Out *out, VDataStream_WriteProc write, VDataStream_WriteCharsProc writeChars, VDataStream_CloseStream close) {
	O7_ASSERT((write != NULL) || (writeChars != NULL));

	Init(&(*out)._, close);
	out->write = write;
	out->writeChars = writeChars;
}

extern void VDataStream_CloseOut(struct VDataStream_Out **out) {
	if (*out != NULL) {
		(*out)->_.close(&(*(*out))._._, NULL);
		*out = NULL;
	}
}

extern o7_int_t VDataStream_Write(struct VDataStream_Out *out, o7_tag_t *out_tag, o7_int_t buf_len0, char unsigned buf[/*len0*/], o7_int_t ofs, o7_int_t count) {
	o7_int_t w;

	O7_ASSERT((0 <= ofs) && (0 <= count) && (ofs <= o7_sub(buf_len0, count)));
	w = out->write(&(*out)._._, out_tag, buf_len0, buf, ofs, count);
	O7_ASSERT((0 <= w) && (w <= count));
	return w;
}

extern o7_int_t VDataStream_WriteChars(struct VDataStream_Out *out, o7_tag_t *out_tag, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t ofs, o7_int_t count) {
	o7_int_t w;

	O7_ASSERT((0 <= ofs) && (0 <= count) && (ofs <= o7_sub(buf_len0, count)));
	w = out->writeChars(&(*out)._._, out_tag, buf_len0, buf, ofs, count);
	O7_ASSERT((0 <= w) && (w <= count));
	return w;
}

extern void VDataStream_InitInOpener(struct VDataStream_InOpener *opener, VDataStream_OpenInStream open) {
	O7_ASSERT(open != NULL);
	V_Init(&(*opener)._);
	opener->open = open;
}

extern void VDataStream_InitOutOpener(struct VDataStream_OutOpener *opener, VDataStream_OpenOutStream open) {
	O7_ASSERT(open != NULL);
	V_Init(&(*opener)._);
	opener->open = open;
}

extern struct VDataStream_In *VDataStream_OpenIn(struct VDataStream_InOpener *opener) {
	return opener->open(&(*opener)._);
}

extern struct VDataStream_Out *VDataStream_OpenOut(struct VDataStream_OutOpener *opener) {
	return opener->open(&(*opener)._);
}

extern void VDataStream_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		O7_TAG_INIT(VDataStream_Stream, V_Base);
	}
	++initialized;
}

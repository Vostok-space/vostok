#if !defined(O7_INIT_MODEL)
#   define   O7_INIT_MODEL O7_INIT_ZERO
#endif

#include <o7.h>

#include "VCopy.h"

#define BlockSize_cnst (O7_MUL(4, 1024))

extern void VCopy_UntilEnd(struct VDataStream_In *in_, o7_tag_t *in__tag, struct VDataStream_Out *out, o7_tag_t *out_tag) {
	char unsigned buf[BlockSize_cnst];
	o7_int_t size;
	memset(&buf, 0, sizeof(buf));

	size = VDataStream_Read(in_, in__tag, BlockSize_cnst, buf, 0, O7_LEN(buf));
	while ((size > 0) && (size == VDataStream_Write(out, out_tag, BlockSize_cnst, buf, 0, size))) {
		size = VDataStream_Read(in_, in__tag, BlockSize_cnst, buf, 0, O7_LEN(buf));
	}
}

extern void VCopy_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		VDataStream_init();
	}
	++initialized;
}

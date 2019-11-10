#include <o7.h>

#include "ArrayCopy.h"

extern void ArrayCopy_Chars(o7_int_t dest_len0, o7_char dest[/*len0*/], o7_int_t destOfs, o7_int_t src_len0, o7_char src[/*len0*/], o7_int_t srcOfs, o7_int_t count) {
	o7_int_t di, si, last;

	O7_ASSERT(count > 0);
	O7_ASSERT((0 <= destOfs) && (destOfs <= o7_sub(dest_len0, count)));
	O7_ASSERT((0 <= srcOfs) && (srcOfs <= o7_sub(src_len0, count)));

	last = o7_sub(o7_add(destOfs, count), 1);
	if (destOfs == srcOfs) {
		for (di = destOfs; di <= last; ++di) {
			dest[o7_ind(dest_len0, di)] = src[o7_ind(src_len0, di)];
		}
	} else {
		si = srcOfs;
		for (di = destOfs; di <= last; ++di) {
			dest[o7_ind(dest_len0, di)] = src[o7_ind(src_len0, si)];
			si = o7_add(si, 1);
		}
	}
}

extern void ArrayCopy_Bytes(o7_int_t dest_len0, char unsigned dest[/*len0*/], o7_int_t destOfs, o7_int_t src_len0, char unsigned src[/*len0*/], o7_int_t srcOfs, o7_int_t count) {
	o7_int_t di, si, last;

	O7_ASSERT(count > 0);
	O7_ASSERT((0 <= destOfs) && (destOfs <= o7_sub(dest_len0, count)));
	O7_ASSERT((0 <= srcOfs) && (srcOfs <= o7_sub(src_len0, count)));

	last = o7_sub(o7_add(destOfs, count), 1);
	if (destOfs == srcOfs) {
		for (di = destOfs; di <= last; ++di) {
			dest[o7_ind(dest_len0, di)] = src[o7_ind(src_len0, di)];
		}
	} else {
		si = srcOfs;
		for (di = destOfs; di <= last; ++di) {
			dest[o7_ind(dest_len0, di)] = src[o7_ind(src_len0, si)];
			si = o7_add(si, 1);
		}
	}
}

extern void ArrayCopy_CharsToBytes(o7_int_t dest_len0, char unsigned dest[/*len0*/], o7_int_t destOfs, o7_int_t src_len0, o7_char src[/*len0*/], o7_int_t srcOfs, o7_int_t count) {
	o7_int_t di, si, last;

	O7_ASSERT(count > 0);
	O7_ASSERT((0 <= destOfs) && (destOfs <= o7_sub(dest_len0, count)));
	O7_ASSERT((0 <= srcOfs) && (srcOfs <= o7_sub(src_len0, count)));

	last = o7_sub(o7_add(destOfs, count), 1);
	if (destOfs == srcOfs) {
		for (di = destOfs; di <= last; ++di) {
			dest[o7_ind(dest_len0, di)] = o7_byte((o7_int_t)src[o7_ind(src_len0, di)]);
		}
	} else {
		si = srcOfs;
		for (di = destOfs; di <= last; ++di) {
			dest[o7_ind(dest_len0, di)] = o7_byte((o7_int_t)src[o7_ind(src_len0, si)]);
			si = o7_add(si, 1);
		}
	}
}

extern void ArrayCopy_BytesToChars(o7_int_t dest_len0, o7_char dest[/*len0*/], o7_int_t destOfs, o7_int_t src_len0, char unsigned src[/*len0*/], o7_int_t srcOfs, o7_int_t count) {
	o7_int_t di, si, last;

	O7_ASSERT(count > 0);
	O7_ASSERT((0 <= destOfs) && (destOfs <= o7_sub(dest_len0, count)));
	O7_ASSERT((0 <= srcOfs) && (srcOfs <= o7_sub(src_len0, count)));

	last = o7_sub(o7_add(destOfs, count), 1);
	if (destOfs == srcOfs) {
		for (di = destOfs; di <= last; ++di) {
			dest[o7_ind(dest_len0, di)] = o7_chr(src[o7_ind(src_len0, di)]);
		}
	} else {
		si = srcOfs;
		for (di = destOfs; di <= last; ++di) {
			dest[o7_ind(dest_len0, di)] = o7_chr(src[o7_ind(src_len0, si)]);
			si = o7_add(si, 1);
		}
	}
}

extern void ArrayCopy_Data(o7_set_t direction, o7_int_t destBytes_len0, char unsigned destBytes[/*len0*/], o7_int_t destChars_len0, o7_char destChars[/*len0*/], o7_int_t destOfs, o7_int_t srcBytes_len0, char unsigned srcBytes[/*len0*/], o7_int_t srcChars_len0, o7_char srcChars[/*len0*/], o7_int_t srcOfs, o7_int_t count) {
#	define CC_cnst o7_sti(ArrayCopy_FromCharsToChars_cnst)
#	define CB_cnst o7_sti(ArrayCopy_FromCharsToBytes_cnst)
#	define BC_cnst o7_sti(ArrayCopy_FromBytesToChars_cnst)
#	define BB_cnst o7_sti(ArrayCopy_FromBytesToBytes_cnst)

	switch (o7_sti(direction)) {
	case 5:
		ArrayCopy_Chars(destChars_len0, destChars, destOfs, srcChars_len0, srcChars, srcOfs, count);
		break;
	case 9:
		ArrayCopy_CharsToBytes(destBytes_len0, destBytes, destOfs, srcChars_len0, srcChars, srcOfs, count);
		break;
	case 6:
		ArrayCopy_BytesToChars(destChars_len0, destChars, destOfs, srcBytes_len0, srcBytes, srcOfs, count);
		break;
	case 10:
		ArrayCopy_Bytes(destBytes_len0, destBytes, destOfs, srcBytes_len0, srcBytes, srcOfs, count);
		break;
	default:
		o7_case_fail(o7_sti(direction));
		break;
	}
#	undef CC_cnst
#	undef CB_cnst
#	undef BC_cnst
#	undef BB_cnst
}


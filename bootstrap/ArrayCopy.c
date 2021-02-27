#if !defined(O7_INIT_MODEL)
#   define   O7_INIT_MODEL O7_INIT_ZERO
#endif

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

extern void ArrayCopy_Data(o7_int_t direction, o7_int_t destBytes_len0, char unsigned destBytes[/*len0*/], o7_int_t destChars_len0, o7_char destChars[/*len0*/], o7_int_t destOfs, o7_int_t srcBytes_len0, char unsigned srcBytes[/*len0*/], o7_int_t srcChars_len0, o7_char srcChars[/*len0*/], o7_int_t srcOfs, o7_int_t count) {
	switch (direction) {
	case 0:
		ArrayCopy_Chars(destChars_len0, destChars, destOfs, srcChars_len0, srcChars, srcOfs, count);
		break;
	case 2:
		ArrayCopy_CharsToBytes(destBytes_len0, destBytes, destOfs, srcChars_len0, srcChars, srcOfs, count);
		break;
	case 1:
		ArrayCopy_BytesToChars(destChars_len0, destChars, destOfs, srcBytes_len0, srcBytes, srcOfs, count);
		break;
	case 3:
		ArrayCopy_Bytes(destBytes_len0, destBytes, destOfs, srcBytes_len0, srcBytes, srcOfs, count);
		break;
	default:
		o7_case_fail(direction);
		break;
	}
}


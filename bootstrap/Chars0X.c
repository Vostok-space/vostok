#if !defined(O7_INIT_MODEL)
#   define   O7_INIT_MODEL O7_INIT_ZERO
#endif

#include <o7.h>

#include "Chars0X.h"

extern o7_int_t Chars0X_CalcLen(o7_int_t str_len0, o7_char str[/*len0*/], o7_int_t ofs) {
	o7_int_t i;

	i = ofs;
	while (str[o7_ind(str_len0, i)] != 0x00u) {
		i = o7_add(i, 1);
	}
	return o7_sub(i, ofs);
}

extern o7_bool Chars0X_Fill(o7_char ch, o7_int_t count, o7_int_t dest_len0, o7_char dest[/*len0*/], o7_int_t *ofs) {
	o7_bool ok;
	o7_int_t i, end;

	O7_ASSERT(ch != 0x00u);
	O7_ASSERT((0 <= *ofs) && (*ofs < dest_len0));

	ok = count < o7_sub(dest_len0, *ofs);
	i = *ofs;
	if (ok) {
		end = o7_add(i, count);
		while (i < end) {
			dest[o7_ind(dest_len0, i)] = ch;
			i = o7_add(i, 1);
		}
		*ofs = i;
	}
	dest[o7_ind(dest_len0, i)] = 0x00u;
	return ok;
}

extern o7_bool Chars0X_CopyAtMost(o7_int_t dest_len0, o7_char dest[/*len0*/], o7_int_t *destOfs, o7_int_t src_len0, o7_char src[/*len0*/], o7_int_t *srcOfs, o7_int_t atMost) {
	o7_bool ok;
	o7_int_t s, d, lim;

	s = *srcOfs;
	d = *destOfs;
	O7_ASSERT((0 <= s) && (s <= src_len0));
	O7_ASSERT((0 <= d) && (d <= dest_len0));
	O7_ASSERT(0 <= atMost);

	lim = o7_add(d, atMost);
	if (o7_sub(dest_len0, 1) < lim) {
		lim = o7_sub(dest_len0, 1);
	}

	while ((d < lim) && (src[o7_ind(src_len0, s)] != 0x00u)) {
		dest[o7_ind(dest_len0, d)] = src[o7_ind(src_len0, s)];
		d = o7_add(d, 1);
		s = o7_add(s, 1);
	}

	ok = (d == o7_add(*destOfs, atMost)) || (src[o7_ind(src_len0, s)] == 0x00u);

	dest[o7_ind(dest_len0, d)] = 0x00u;
	*srcOfs = s;
	*destOfs = d;

	O7_ASSERT((*destOfs == dest_len0) || (dest[o7_ind(dest_len0, *destOfs)] == 0x00u));
	return ok;
}

extern o7_bool Chars0X_Copy(o7_int_t dest_len0, o7_char dest[/*len0*/], o7_int_t *destOfs, o7_int_t src_len0, o7_char src[/*len0*/], o7_int_t *srcOfs) {
	o7_int_t s, d;

	s = *srcOfs;
	d = *destOfs;
	O7_ASSERT((0 <= s) && (s <= src_len0));
	O7_ASSERT((0 <= d) && (d <= dest_len0));

	while ((d < o7_sub(dest_len0, 1)) && (src[o7_ind(src_len0, s)] != 0x00u)) {
		dest[o7_ind(dest_len0, d)] = src[o7_ind(src_len0, s)];
		d = o7_add(d, 1);
		s = o7_add(s, 1);
	}

	dest[o7_ind(dest_len0, d)] = 0x00u;
	*srcOfs = s;
	*destOfs = d;

	O7_ASSERT(dest[o7_ind(dest_len0, *destOfs)] == 0x00u);
	return src[o7_ind(src_len0, s)] == 0x00u;
}

extern o7_bool Chars0X_CopyChars(o7_int_t dest_len0, o7_char dest[/*len0*/], o7_int_t *destOfs, o7_int_t src_len0, o7_char src[/*len0*/], o7_int_t srcOfs, o7_int_t srcEnd) {
	o7_int_t s, d;
	o7_bool ok;

	s = srcOfs;
	d = *destOfs;
	O7_ASSERT((0 <= s) && (s <= src_len0));
	O7_ASSERT((0 <= d) && (d <= dest_len0));
	O7_ASSERT(s <= srcEnd);

	ok = d < o7_sub(dest_len0, (o7_sub(srcEnd, srcOfs)));
	if (!ok) {
		srcEnd = o7_sub(o7_sub(dest_len0, (o7_sub(srcEnd, srcOfs))), 1);
	}
	while (s < srcEnd) {
		O7_ASSERT(src[o7_ind(src_len0, s)] != 0x00u);
		dest[o7_ind(dest_len0, d)] = src[o7_ind(src_len0, s)];
		d = o7_add(d, 1);
		s = o7_add(s, 1);
	}
	dest[o7_ind(dest_len0, d)] = 0x00u;
	*destOfs = d;
	return ok;
}

extern o7_bool Chars0X_CopyCharsUntil(o7_int_t dest_len0, o7_char dest[/*len0*/], o7_int_t *destOfs, o7_int_t src_len0, o7_char src[/*len0*/], o7_int_t *srcOfs, o7_char until) {
	o7_int_t s, d;

	s = *srcOfs;
	d = *destOfs;
	O7_ASSERT((0 <= s) && (s < src_len0));
	O7_ASSERT((0 <= d) && (d <= dest_len0));

	while ((src[o7_ind(src_len0, s)] != until) && (d < o7_sub(dest_len0, 1))) {
		O7_ASSERT(src[o7_ind(src_len0, s)] != 0x00u);
		dest[o7_ind(dest_len0, d)] = src[o7_ind(src_len0, s)];
		d = o7_add(d, 1);
		s = o7_add(s, 1);
	}
	dest[o7_ind(dest_len0, d)] = 0x00u;
	*destOfs = d;
	*srcOfs = s;
	return src[o7_ind(src_len0, s)] == until;
}

extern o7_bool Chars0X_CopyString(o7_int_t dest_len0, o7_char dest[/*len0*/], o7_int_t *ofs, o7_int_t src_len0, o7_char src[/*len0*/]) {
	o7_int_t i;

	i = 0;
	return Chars0X_Copy(dest_len0, dest, ofs, src_len0, src, &i);
}

extern o7_bool Chars0X_CopyChar(o7_int_t dest_len0, o7_char dest[/*len0*/], o7_int_t *ofs, o7_char ch) {
	o7_bool ok;
	o7_int_t i;

	i = *ofs;
	O7_ASSERT(ch != 0x00u);
	O7_ASSERT((0 <= i) && (i < dest_len0));
	ok = i < o7_sub(dest_len0, 1);
	if (ok) {
		dest[o7_ind(dest_len0, i)] = ch;
		i = o7_add(i, 1);
	}
	dest[o7_ind(dest_len0, i)] = 0x00u;
	*ofs = i;
	return ok;
}

extern o7_bool Chars0X_SearchChar(o7_int_t str_len0, o7_char str[/*len0*/], o7_int_t *pos, o7_char c) {
	o7_int_t i;

	i = *pos;
	O7_ASSERT((0 <= i) && (i < str_len0));

	while ((str[o7_ind(str_len0, i)] != c) && (str[o7_ind(str_len0, i)] != 0x00u)) {
		i = o7_add(i, 1);
	}
	*pos = i;
	return str[o7_ind(str_len0, i)] == c;
}

extern o7_int_t Chars0X_Trim(o7_int_t str_len0, o7_char str[/*len0*/], o7_int_t ofs) {
	o7_int_t i, j;

	i = ofs;
	while ((str[o7_ind(str_len0, i)] == (o7_char)' ') || (str[o7_ind(str_len0, i)] == 0x09u)) {
		i = o7_add(i, 1);
	}
	if (ofs < i) {
		j = ofs;
		while (str[o7_ind(str_len0, i)] != 0x00u) {
			str[o7_ind(str_len0, j)] = str[o7_ind(str_len0, i)];
			j = o7_add(j, 1);
			i = o7_add(i, 1);
		}
	} else {
		j = o7_add(ofs, Chars0X_CalcLen(str_len0, str, ofs));
	}
	while ((ofs < j) && ((str[o7_ind(str_len0, o7_sub(j, 1))] == (o7_char)' ') || (str[o7_ind(str_len0, o7_sub(j, 1))] == 0x09u))) {
		j = o7_sub(j, 1);
	}
	str[o7_ind(str_len0, j)] = 0x00u;
	return o7_sub(j, ofs);
}

#if !defined HEADER_GUARD_Chars0X
#    define  HEADER_GUARD_Chars0X 1

#include "Utf8.h"

extern o7_int_t Chars0X_CalcLen(o7_int_t str_len0, o7_char str[/*len0*/], o7_int_t ofs);

extern o7_bool Chars0X_Fill(o7_char ch, o7_int_t count, o7_int_t dest_len0, o7_char dest[/*len0*/], o7_int_t *ofs);

extern o7_bool Chars0X_CopyAtMost(o7_int_t dest_len0, o7_char dest[/*len0*/], o7_int_t *destOfs, o7_int_t src_len0, o7_char src[/*len0*/], o7_int_t *srcOfs, o7_int_t atMost);

extern o7_bool Chars0X_Copy(o7_int_t dest_len0, o7_char dest[/*len0*/], o7_int_t *destOfs, o7_int_t src_len0, o7_char src[/*len0*/], o7_int_t *srcOfs);

extern o7_bool Chars0X_CopyChars(o7_int_t dest_len0, o7_char dest[/*len0*/], o7_int_t *destOfs, o7_int_t src_len0, o7_char src[/*len0*/], o7_int_t srcOfs, o7_int_t srcEnd);

extern o7_bool Chars0X_CopyCharsUntil(o7_int_t dest_len0, o7_char dest[/*len0*/], o7_int_t *destOfs, o7_int_t src_len0, o7_char src[/*len0*/], o7_int_t *srcOfs, o7_char until);

extern o7_bool Chars0X_CopyString(o7_int_t dest_len0, o7_char dest[/*len0*/], o7_int_t *ofs, o7_int_t src_len0, o7_char src[/*len0*/]);

extern o7_bool Chars0X_CopyChar(o7_int_t dest_len0, o7_char dest[/*len0*/], o7_int_t *ofs, o7_char ch);

extern o7_bool Chars0X_SearchChar(o7_int_t str_len0, o7_char str[/*len0*/], o7_int_t *pos, o7_char c);

extern o7_int_t Chars0X_Trim(o7_int_t str_len0, o7_char str[/*len0*/], o7_int_t ofs);

#endif

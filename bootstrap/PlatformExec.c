#if !defined(O7_INIT_MODEL)
#   define   O7_INIT_MODEL O7_INIT_ZERO
#endif

#include <o7.h>

#include "PlatformExec.h"

#define PlatformExec_Code_tag V_Base_tag

static o7_bool autoCorrectDirSeparator = 0 > 1;
o7_char PlatformExec_dirSep[2];

static o7_bool Copy(o7_int_t d_len0, o7_char d[/*len0*/], o7_int_t *i, o7_int_t s_len0, o7_char s[/*len0*/], o7_int_t j, o7_bool parts);
static o7_bool Copy_IsBackSlash(o7_char c) {
	return (c == (o7_char)'\\') || (c == (o7_char)'/') && autoCorrectDirSeparator;
}

static o7_bool Copy(o7_int_t d_len0, o7_char d[/*len0*/], o7_int_t *i, o7_int_t s_len0, o7_char s[/*len0*/], o7_int_t j, o7_bool parts) {
	o7_int_t k;

	if (Platform_Posix) {
		while (1) if ((j < s_len0) && (s[o7_ind(s_len0, j)] == (o7_char)'\'') && (*i < o7_sub(d_len0, 4))) {
			d[o7_ind(d_len0, *i)] = (o7_char)'\'';
			d[o7_ind(d_len0, o7_add(*i, 1))] = (o7_char)'\\';
			d[o7_ind(d_len0, o7_add(*i, 2))] = (o7_char)'\'';
			d[o7_ind(d_len0, o7_add(*i, 3))] = (o7_char)'\'';
			*i = o7_add(*i, 4);
			j = o7_add(j, 1);
		} else if ((j < s_len0) && (s[o7_ind(s_len0, j)] != 0x00u) && (*i < o7_sub(d_len0, 1))) {
			if ((s[o7_ind(s_len0, j)] != (o7_char)'\\') || !autoCorrectDirSeparator) {
				d[o7_ind(d_len0, *i)] = s[o7_ind(s_len0, j)];
			} else {
				d[o7_ind(d_len0, *i)] = (o7_char)'/';
			}
			*i = o7_add(*i, 1);
			j = o7_add(j, 1);
		} else break;
	} else {
		O7_ASSERT(Platform_Windows);
		while ((j < s_len0) && (s[o7_ind(s_len0, j)] != 0x00u)) {
			if (Copy_IsBackSlash(s[o7_ind(s_len0, j)])) {
				k = 0;
				do {
					k = o7_add(k, 1);
					j = o7_add(j, 1);
				} while (!((j == s_len0) || !Copy_IsBackSlash(s[o7_ind(s_len0, j)])));
				if ((j == s_len0) || (s[o7_ind(s_len0, j)] == 0x00u)) {
					if (!parts) {
						k = o7_mul(k, 2);
					}
				} else if (s[o7_ind(s_len0, j)] == (o7_char)'"') {
					k = o7_add(o7_mul(k, 2), 1);
				}
				if (*i > o7_sub(o7_sub(d_len0, 1), k)) {
					j = o7_sub(j, 1);
					k = o7_sub(o7_sub(d_len0, 1), *i);
				}
				while (k > 0) {
					d[o7_ind(d_len0, *i)] = (o7_char)'\\';
					*i = o7_add(*i, 1);
					k = o7_sub(k, 1);
				}
			} else {
				d[o7_ind(d_len0, *i)] = s[o7_ind(s_len0, j)];
				*i = o7_add(*i, 1);
				j = o7_add(j, 1);
			}
		}
	}
	d[o7_ind(d_len0, *i)] = 0x00u;
	if (*i < o7_sub(d_len0, 1)) {
		d[o7_ind(d_len0, o7_add(*i, 1))] = 0x00u;
	}
	return (j == s_len0) || (s[o7_ind(s_len0, j)] == 0x00u);
}

static o7_bool Quote(o7_int_t d_len0, o7_char d[/*len0*/], o7_int_t *i) {
	o7_bool ok;

	ok = *i < o7_sub(d_len0, 1);
	if (ok && !Platform_Java) {
		if (Platform_Posix) {
			d[o7_ind(d_len0, *i)] = (o7_char)'\'';
		} else {
			O7_ASSERT(Platform_Windows);
			d[o7_ind(d_len0, *i)] = (o7_char)'"';
		}
		*i = o7_add(*i, 1);
		d[o7_ind(d_len0, *i)] = 0x00u;
	}
	return ok;
}

extern o7_bool PlatformExec_AddQuote(struct PlatformExec_Code *c) {
	return Quote(PlatformExec_CodeSize_cnst, c->buf, &c->len);
}

static o7_bool CheckIsNeedQuote(o7_int_t s_len0, o7_char s[/*len0*/], o7_int_t ofs) {
	o7_char c;

	ofs = o7_sub(ofs, 1);
	do {
		ofs = o7_add(ofs, 1);
		c = s[o7_ind(s_len0, ofs)];
	} while (((o7_char)'A' <= c) && (c <= (o7_char)'Z') || ((o7_char)'a' <= c) && (c <= (o7_char)'z') || ((o7_char)'0' <= c) && (c <= (o7_char)'9') || (c == (o7_char)'_') || (c == (o7_char)'-') || (c == (o7_char)'/') || (c == (o7_char)'.'));
	return c != 0x00u;
}

static o7_bool FullCopy(o7_int_t d_len0, o7_char d[/*len0*/], o7_int_t *i, o7_int_t s_len0, o7_char s[/*len0*/], o7_int_t j) {
	o7_bool ok;

	if (CheckIsNeedQuote(s_len0, s, j)) {
		ok = Quote(d_len0, d, i) && Copy(d_len0, d, i, s_len0, s, j, (0 > 1)) && Quote(d_len0, d, i);
	} else {
		ok = Chars0X_Copy(d_len0, d, i, s_len0, s, &j);
	}
	return ok;
}

extern o7_bool PlatformExec_Init(struct PlatformExec_Code *c, o7_int_t name_len0, o7_char name[/*len0*/]) {
	o7_bool ok;

	V_Init(&(*c)._);
	c->parts = (0 > 1);
	c->len = 0;
	if (o7_strcmp(name_len0, name, 1, (o7_char *)"") == 0) {
		c->buf[o7_ind(PlatformExec_CodeSize_cnst, c->len)] = 0x00u;
		ok = (0 < 1);
	} else if (Platform_Posix) {
		ok = FullCopy(PlatformExec_CodeSize_cnst, c->buf, &c->len, name_len0, name, 0);
	} else {
		O7_ASSERT(Platform_Windows);
		ok = Copy(PlatformExec_CodeSize_cnst, c->buf, &c->len, name_len0, name, 0, c->parts);
	}
	return ok;
}

extern o7_bool PlatformExec_AddByOfs(struct PlatformExec_Code *c, o7_int_t arg_len0, o7_char arg[/*len0*/], o7_int_t ofs) {
	o7_bool ok;

	ok = c->len < O7_LEN(c->buf) - 1;
	if (ok) {
		if (c->len > 0) {
			c->buf[o7_ind(PlatformExec_CodeSize_cnst, c->len)] = (o7_char)' ';
			c->len = o7_add(c->len, 1);
			ok = FullCopy(PlatformExec_CodeSize_cnst, c->buf, &c->len, arg_len0, arg, ofs);
		} else if (Platform_Posix) {
			ok = FullCopy(PlatformExec_CodeSize_cnst, c->buf, &c->len, arg_len0, arg, ofs);
		} else {
			O7_ASSERT(Platform_Windows);
			ok = Copy(PlatformExec_CodeSize_cnst, c->buf, &c->len, arg_len0, arg, ofs, c->parts);
		}
	}
	return ok;
}

extern o7_bool PlatformExec_Add(struct PlatformExec_Code *c, o7_int_t arg_len0, o7_char arg[/*len0*/]) {
	return PlatformExec_AddByOfs(c, arg_len0, arg, 0);
}

extern o7_bool PlatformExec_AddClean(struct PlatformExec_Code *c, o7_int_t arg_len0, o7_char arg[/*len0*/]) {
	return Chars0X_CopyString(PlatformExec_CodeSize_cnst, c->buf, &c->len, arg_len0, arg);
}

extern o7_bool PlatformExec_AddDirSep(struct PlatformExec_Code *c) {
	o7_bool ok;

	ok = c->len < O7_LEN(c->buf) - 1;
	if (ok) {
		c->buf[o7_ind(PlatformExec_CodeSize_cnst, c->len)] = PlatformExec_dirSep[0];
		c->len = o7_add(c->len, 1);
		c->buf[o7_ind(PlatformExec_CodeSize_cnst, c->len)] = 0x00u;
	}
	return ok;
}

extern o7_bool PlatformExec_FirstPart(struct PlatformExec_Code *c, o7_int_t arg_len0, o7_char arg[/*len0*/]) {
	o7_bool ok;

	O7_ASSERT(!c->parts);
	c->parts = (0 < 1);

	ok = c->len < O7_LEN(c->buf) - 3;
	if (ok) {
		if (c->len > 0) {
			c->partsQuote = (0 < 1);
			c->buf[o7_ind(PlatformExec_CodeSize_cnst, c->len)] = (o7_char)' ';
			c->len = o7_add(c->len, 1);
		} else {
			c->partsQuote = Platform_Posix;
		}
		ok = ok && (!c->partsQuote || Quote(PlatformExec_CodeSize_cnst, c->buf, &c->len)) && Copy(PlatformExec_CodeSize_cnst, c->buf, &c->len, arg_len0, arg, 0, c->parts);
	}
	return ok;
}

extern o7_bool PlatformExec_AddPart(struct PlatformExec_Code *c, o7_int_t arg_len0, o7_char arg[/*len0*/]) {
	O7_ASSERT(c->parts);
	return Copy(PlatformExec_CodeSize_cnst, c->buf, &c->len, arg_len0, arg, 0, c->parts);
}

extern o7_bool PlatformExec_LastPart(struct PlatformExec_Code *c, o7_int_t arg_len0, o7_char arg[/*len0*/]) {
	O7_ASSERT(c->parts);
	c->parts = (0 > 1);
	return Copy(PlatformExec_CodeSize_cnst, c->buf, &c->len, arg_len0, arg, 0, c->parts) && (!c->partsQuote || Quote(PlatformExec_CodeSize_cnst, c->buf, &c->len));
}

extern void PlatformExec_Log(struct PlatformExec_Code *c) {
	Log_StrLn(PlatformExec_CodeSize_cnst, c->buf);
}

extern o7_int_t PlatformExec_Do(struct PlatformExec_Code *c) {
	O7_ASSERT(0 < c->len);
	return OsExec_Do(PlatformExec_CodeSize_cnst, c->buf);
}

extern void PlatformExec_AutoCorrectDirSeparator(o7_bool state) {
	autoCorrectDirSeparator = state;
}

extern void PlatformExec_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		Log_init();

		autoCorrectDirSeparator = (0 > 1);

		if (Platform_Posix) {
			memcpy(PlatformExec_dirSep, (o7_char *)"\x2F", 2);
		} else {
			O7_ASSERT(Platform_Windows);
			memcpy(PlatformExec_dirSep, (o7_char *)"\x5C", 2);
		}
	}
	++initialized;
}

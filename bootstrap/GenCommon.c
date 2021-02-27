#if !defined(O7_INIT_MODEL)
#   define   O7_INIT_MODEL O7_INIT_ZERO
#endif

#include <o7.h>

#include "GenCommon.h"

extern void GenCommon_Ident(struct TextGenerator_Out *gen, struct StringStore_String *ident, o7_int_t identEnc) {
	o7_char buf[O7_MUL(TranslatorLimits_LenName_cnst, 6) + 2];
	o7_int_t i;
	struct StringStore_Iterator it;
	memset(&buf, 0, sizeof(buf));
	memset(&it, 0, sizeof(it));

	O7_ASSERT(StringStore_GetIter(&it, ident, 0));
	i = 0;
	if ((identEnc == GenOptions_IdentEncSame_cnst) || (it.char_ < 0x80u)) {
		do {
			buf[o7_ind(O7_MUL(TranslatorLimits_LenName_cnst, 6) + 2, i)] = it.char_;
			i = o7_add(i, 1);
			if (it.char_ == (o7_char)'_') {
				buf[o7_ind(O7_MUL(TranslatorLimits_LenName_cnst, 6) + 2, i)] = (o7_char)'_';
				i = o7_add(i, 1);
			}
		} while (StringStore_IterNext(&it));
	} else {
		o7_case_fail(identEnc);
	}
	TextGenerator_Data(gen, O7_MUL(TranslatorLimits_LenName_cnst, 6) + 2, buf, 0, i);
}

static void Comment(struct TextGenerator_Out *gen, struct GenOptions_R *opt, struct StringStore_String *text, o7_int_t open_len0, o7_char open[/*len0*/], o7_int_t close_len0, o7_char close[/*len0*/]) {
	struct StringStore_Iterator i;
	o7_char prev;
	memset(&i, 0, sizeof(i));

	if (opt->comment && StringStore_GetIter(&i, text, 0)) {
		do {
			prev = i.char_;
		} while (!(!StringStore_IterNext(&i) || (prev == open[0]) && (i.char_ == (o7_char)'*') || (prev == (o7_char)'*') && (i.char_ == close[o7_ind(close_len0, 1)])));

		if (i.char_ == 0x00u) {
			TextGenerator_Str(gen, open_len0, open);
			TextGenerator_String(gen, text);
			TextGenerator_StrLn(gen, close_len0, close);
		}
	}
}

extern void GenCommon_CommentC(struct TextGenerator_Out *out, struct GenOptions_R *opt, struct StringStore_String *text) {
	Comment(out, opt, text, 3, (o7_char *)"/*", 3, (o7_char *)"*/");
}

extern void GenCommon_CommentOberon(struct TextGenerator_Out *out, struct GenOptions_R *opt, struct StringStore_String *text) {
	Comment(out, opt, text, 3, (o7_char *)"(*", 3, (o7_char *)"*)");
}

extern void GenCommon_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		TextGenerator_init();
		StringStore_init();
	}
	++initialized;
}


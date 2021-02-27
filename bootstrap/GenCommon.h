#if !defined HEADER_GUARD_GenCommon
#    define  HEADER_GUARD_GenCommon 1

#include "TextGenerator.h"
#include "StringStore.h"
#include "Utf8.h"
#include "GenOptions.h"
#include "TranslatorLimits.h"

extern void GenCommon_Ident(struct TextGenerator_Out *gen, struct StringStore_String *ident, o7_int_t identEnc);

extern void GenCommon_CommentC(struct TextGenerator_Out *out, struct GenOptions_R *opt, struct StringStore_String *text);

extern void GenCommon_CommentOberon(struct TextGenerator_Out *out, struct GenOptions_R *opt, struct StringStore_String *text);

extern void GenCommon_init(void);
#endif

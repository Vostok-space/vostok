#if !defined HEADER_GUARD_SpecIdentChecker
#    define  HEADER_GUARD_SpecIdentChecker 1

#include "StringStore.h"

#define SpecIdentChecker_MathC_cnst 0

extern o7_bool SpecIdentChecker_IsCKeyWord(struct StringStore_String *n);

extern o7_bool SpecIdentChecker_IsCLib(struct StringStore_String *n);

extern o7_bool SpecIdentChecker_IsCMath(struct StringStore_String *n);

extern o7_bool SpecIdentChecker_IsCMacros(struct StringStore_String *n);

extern o7_bool SpecIdentChecker_IsCppKeyWord(struct StringStore_String *n);

extern o7_bool SpecIdentChecker_IsJsKeyWord(struct StringStore_String *n);

extern o7_bool SpecIdentChecker_IsJavaLib(struct StringStore_String *n);

extern o7_bool SpecIdentChecker_IsSpecName(struct StringStore_String *n, unsigned filter);

extern o7_bool SpecIdentChecker_IsSpecModuleName(struct StringStore_String *n);

extern o7_bool SpecIdentChecker_IsO7SpecName(struct StringStore_String *name);

extern void SpecIdentChecker_init(void);
#endif

#if !defined HEADER_GUARD_LongSet
#    define  HEADER_GUARD_LongSet 1

#include "TypesLimits.h"

#define LongSet_Max_cnst 63

typedef unsigned LongSet_Type[2];

extern o7_bool LongSet_CheckRange(o7_int_t int_);

extern void LongSet_Add(LongSet_Type s, LongSet_Type a);

extern void LongSet_Sub(LongSet_Type s, LongSet_Type a);

extern o7_bool LongSet_Equal(LongSet_Type s1, LongSet_Type s2);

extern o7_bool LongSet_In(o7_int_t i, LongSet_Type s);

extern void LongSet_Neg(LongSet_Type s);

extern o7_bool LongSet_ConvertableToInt(LongSet_Type s);

extern o7_int_t LongSet_Ord(LongSet_Type s);

extern void LongSet_Empty(LongSet_Type s);
#endif

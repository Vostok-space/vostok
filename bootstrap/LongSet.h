#if !defined HEADER_GUARD_LongSet
#    define  HEADER_GUARD_LongSet 1

#include "TypesLimits.h"

#define LongSet_Max_cnst 63

typedef o7_set_t LongSet_Type[2];

extern void LongSet_Empty(LongSet_Type s);

extern o7_bool LongSet_InRange(o7_int_t i);

extern void LongSet_Union(LongSet_Type s, LongSet_Type a);

extern void LongSet_Diff(LongSet_Type s, LongSet_Type a);

extern o7_bool LongSet_Equal(LongSet_Type s1, LongSet_Type s2);

extern o7_bool LongSet_In(o7_int_t i, LongSet_Type s);

extern void LongSet_Not(LongSet_Type s);

extern o7_bool LongSet_ConvertableToInt(LongSet_Type s);

extern o7_int_t LongSet_Ord(LongSet_Type s);

#endif

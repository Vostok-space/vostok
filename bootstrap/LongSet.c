#include <o7.h>

#include "LongSet.h"

extern o7_bool LongSet_CheckRange(o7_int_t int_) {
	return (0 <= int_) && (int_ <= LongSet_Max_cnst);
}

extern void LongSet_Add(LongSet_Type s, LongSet_Type a) {
	s[0] = s[0] | a[0];
	s[1] = s[1] | a[1];
}

extern void LongSet_Sub(LongSet_Type s, LongSet_Type a) {
	s[0] = s[0] & ~a[0];
	s[1] = s[1] & ~a[1];
}

extern o7_bool LongSet_Equal(LongSet_Type s1, LongSet_Type s2) {
	return (s1[0] == s2[0]) && (s1[1] == s2[1]);
}

extern o7_bool LongSet_In(o7_int_t i, LongSet_Type s) {
	return LongSet_CheckRange(i) && (o7_in(o7_mod(i, (TypesLimits_SetMax_cnst + 1)), s[o7_ind(2, o7_div(i, (TypesLimits_SetMax_cnst + 1)))]));
}

extern void LongSet_Neg(LongSet_Type s) {
	s[0] =  ~s[0];
	s[1] =  ~s[1];
}

extern o7_bool LongSet_ConvertableToInt(LongSet_Type s) {
	return !(!!( (1u << TypesLimits_SetMax_cnst) & s[0])) && (s[1] == 0);
}

extern o7_int_t LongSet_Ord(LongSet_Type s) {
	O7_ASSERT(LongSet_ConvertableToInt(s));
	return o7_sti(s[0]);
}

extern void LongSet_Empty(LongSet_Type s) {
	s[0] = 0;
	s[1] = 0;
}


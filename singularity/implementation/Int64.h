#if !defined(HEADER_GUARD_Int64)
#define HEADER_GUARD_Int64

#if !O7C_GNUC_BUILTIN_OVERFLOW
#	define O7C_GNUC_BUILTIN_OVERFLOW (0 > 1)
#	if !defined(__builtin_add_overflow)
#		define O7C_GNUC_BUILTIN_OVERFLOW_NEED_UNDEF
#		define __builtin_add_overflow(a, b, res) (0 < sizeof(*(res) = (a)+(b)))
#		define __builtin_sub_overflow(a, b, res) (0 < sizeof(*(res) = (a)-(b)))
#		define __builtin_mul_overflow(a, b, res) (0 < sizeof(*(res) = (a)*(b)))
#	endif
#endif

#if __STDC_VERSION__ >= 199901L
#	include <stdint.h>
	typedef int_least64_t Int64_t;
	typedef uint_least64_t Int64_ut;
#	define Int64_Max INT_LEAST64_MAX
#	define Int64_Min INT_LEAST64_MIN
#elif LONG_MAX > 2147483647l
	typedef long Int64_t;
	typedef unsigned long Int64_ut;
#	define Int64_Max LONG_MAX
#	define Int64_Min LONG_MIN
#else
	typedef long long Int64_t;
	typedef unsigned long long Int64_ut;
#	define Int64_Max LLONG_MAX
#	define Int64_Min LLONG_MIN
#endif

typedef o7c_char Int64_Type[8];

static Int64_Type Int64_min;
static Int64_Type Int64_max;

static O7C_INLINE void Int64_FromInt(Int64_Type v, int high, int low)
	O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE void Int64_FromInt(Int64_Type v, int high, int low) {
	*(Int64_t *)v = o7c_int(high) * (Int64_t)INT_MAX + o7c_int(low);
}

static O7C_INLINE void Int64_ToInt(int *i, Int64_Type v)
	O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE void Int64_ToInt(int *i, Int64_Type v) {
	o7c_bool ov;
	if (O7C_OVERFLOW && O7C_GNUC_BUILTIN_OVERFLOW) {
		ov = __builtin_add_overflow(*(Int64_t *)v, 0, i);
		assert(!ov);
	} else {
		if (O7C_OVERFLOW) {
			assert((-INT_MAX <= *(Int64_t *)v) && (*(Int64_t *)v <= INT_MAX));
		}
		*i = *(Int64_t *)v;
	}
}

static O7C_INLINE void Int64_Add(Int64_Type sum,
	Int64_Type a1, Int64_Type a2) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE void
	Int64_Add(Int64_Type sum, Int64_Type a1, Int64_Type a2)
{
	o7c_bool overflow;
	if (O7C_OVERFLOW && O7C_GNUC_BUILTIN_OVERFLOW) {
		overflow = __builtin_add_overflow(*(Int64_t *)a1, *(Int64_t *)a2,
		                                  (Int64_t *)sum);
		assert(!overflow);
	} else {
		if (!O7C_OVERFLOW) {
			;
		} else if (*(Int64_t *)a2 >= 0) {
			assert(*(Int64_t *)a1 <= Int64_Max - *(Int64_t *)a2);
		} else {
			assert(*(Int64_t *)a1 >= Int64_Min - *(Int64_t *)a2);
		}
		*(Int64_t *)sum = *(Int64_t *)a1 + *(Int64_t *)a2;
	}
}

static O7C_INLINE void Int64_Sub(Int64_Type diff,
	Int64_Type m, Int64_Type s) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE void
	Int64_Sub(Int64_Type diff, Int64_Type m, Int64_Type s)
{
	o7c_bool overflow;
	if (O7C_OVERFLOW && O7C_GNUC_BUILTIN_OVERFLOW) {
		overflow = __builtin_sub_overflow(*(Int64_t *)m, *(Int64_t *)s,
		                                  (Int64_t *)diff);
		assert(!overflow);
	} else {
		if (!O7C_OVERFLOW) {
			;
		} else if (*(Int64_t *)s >= 0) {
			assert(*(Int64_t *)m >= Int64_Min + *(Int64_t *)s);
		} else {
			assert(*(Int64_t *)m <= Int64_Max + *(Int64_t *)s);
		}
		*(Int64_t *)diff = *(Int64_t *)m - *(Int64_t *)s;
	}
}

static O7C_INLINE void Int64_Mul(Int64_Type prod,
	Int64_Type m1, Int64_Type m2) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE void
	Int64_Mul(Int64_Type prod, Int64_Type m1, Int64_Type m2)
{
	o7c_bool overflow;
	if (O7C_OVERFLOW && O7C_GNUC_BUILTIN_OVERFLOW) {
		overflow = __builtin_mul_overflow(*(Int64_t *)m1, *(Int64_t *)m2,
		                                  (Int64_t *)prod);
		assert(!overflow);
	} else {
		if (!O7C_OVERFLOW) {
			;
		} else if (*(Int64_t *)m2 > 0) {
			if (*(Int64_t *)m1 >= 0) {
				assert(*(Int64_t *)m1 <= Int64_Max / *(Int64_t *)m2);
			} else {
				assert(*(Int64_t *)m1 >= Int64_Min / *(Int64_t *)m2);
			}
		} else if (*(Int64_t *)m2 != 0) {
			if (*(Int64_t *)m1 >= 0) {
				assert(*(Int64_t *)m1 <=
				        ((Int64_ut)(-1 - Int64_Min) + 1u)
				      / ((Int64_ut)(-1 - *(Int64_t *)m2) + 1u)
				);
			} else {
				assert(*(Int64_t *)m1 >= Int64_Max / *(Int64_t *)m2);
			}
		}
		*(Int64_t *)prod = *(Int64_t *)m1 * *(Int64_t *)m2;
	}
}

static O7C_INLINE void Int64_CheckDiv(Int64_Type n, Int64_Type d)
	O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE void Int64_CheckDiv(Int64_Type n, Int64_Type d) {
	if (O7C_OVERFLOW) {
		if (O7C_DIV_ZERO) {
			assert(*(Int64_t *)d != 0);
		}
		if (Int64_Min < -Int64_Max) {
			assert((*(Int64_t *)d != -1) || (*(Int64_t *)n != Int64_Min));
		}
	}
}

static O7C_INLINE void Int64_Div(Int64_Type div,
	Int64_Type n, Int64_Type d) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE void
	Int64_Div(Int64_Type div, Int64_Type n, Int64_Type d)
{
	Int64_CheckDiv(n, d);
	*(Int64_t *)div = *(Int64_t *)n / *(Int64_t *)d;
}

static O7C_INLINE void Int64_Mod(Int64_Type mod,
	Int64_Type n, Int64_Type d) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE void
	Int64_Mod(Int64_Type mod, Int64_Type n, Int64_Type d)
{
	Int64_CheckDiv(n, d);
	*(Int64_t *)mod = *(Int64_t *)n % *(Int64_t *)d;
}

static O7C_INLINE void Int64_DivMod(Int64_Type div, Int64_Type mod,
	Int64_Type n, Int64_Type d) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE void
	Int64_DivMod(Int64_Type div, Int64_Type mod, Int64_Type n, Int64_Type d)
{
	Int64_CheckDiv(n, d);
	*(Int64_t *)div = *(Int64_t *)n / *(Int64_t *)d;
	*(Int64_t *)mod = *(Int64_t *)n % *(Int64_t *)d;
}

static O7C_INLINE void Int64_init(void) {
	*(Int64_t *)Int64_min = Int64_Min;
	*(Int64_t *)Int64_max = Int64_Max;
}

#if defined(O7C_GNUC_BUILTIN_OVERFLOW_NEED_UNDEF)
#	undef O7C_GNUC_BUILTIN_OVERFLOW_NEED_UNDEF
#	undef __builtin_add_overflow
#	undef __builtin_sub_overflow
#	undef __builtin_mul_overflow
#endif

#endif

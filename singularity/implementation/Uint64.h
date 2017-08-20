/* Copyright 2016 ComdivByZero
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
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
	typedef uint_least64_t Uint64_t;
#	define Uint64_Max UINT_LEAST64_MAX
#elif ULONG_MAX > 4294967295l
	typedef unsigned long Uint64_t;
#	define Uint64_Max ULONG_MAX
#else
	typedef unsigned long long Uint64_t;
#	define Uint64_Max ULLONG_MAX
#endif

#define Uint64_Size_cnst sizeof(Uint64_t)

typedef o7c_char Uint64_Type[Uint64_Size_cnst];

static Uint64_Type Uint64_max;

O7C_ALWAYS_INLINE void Uint64_FromInt(Uint64_Type v, int high, int low) {
	*(Uint64_t *)v = o7c_int(high) * (Uint64_t)INT_MAX + o7c_int(low);
}

O7C_ALWAYS_INLINE void Uint64_ToInt(int *i, Uint64_Type v) {
	o7c_bool ov;
	if (O7C_OVERFLOW && O7C_GNUC_BUILTIN_OVERFLOW) {
		ov = __builtin_add_overflow(*(Uint64_t *)v, 0, i);
		assert(!ov);
	} else {
		if (O7C_OVERFLOW) {
			assert(*(Uint64_t *)v <= INT_MAX);
		}
		*i = *(Uint64_t *)v;
	}
}

O7C_ALWAYS_INLINE void
	Uint64_Add(Uint64_Type sum, Uint64_Type a1, Uint64_Type a2)
{
	o7c_bool overflow;
	if (O7C_OVERFLOW && O7C_GNUC_BUILTIN_OVERFLOW) {
		overflow = __builtin_add_overflow(*(Uint64_t *)a1, *(Uint64_t *)a2,
		                                  (Uint64_t *)sum);
		assert(!overflow);
	} else {
		if (O7C_OVERFLOW) {
			assert(*(Uint64_t *)a1 <= Uint64_Max - *(Uint64_t *)a2);
		}
		*(Uint64_t *)sum = *(Uint64_t *)a1 + *(Uint64_t *)a2;
	}
}

O7C_ALWAYS_INLINE void
	Uint64_Sub(Uint64_Type diff, Uint64_Type m, Uint64_Type s)
{
	o7c_bool overflow;
	if (O7C_OVERFLOW && O7C_GNUC_BUILTIN_OVERFLOW) {
		overflow = __builtin_sub_overflow(*(Uint64_t *)m, *(Uint64_t *)s,
		                                  (Uint64_t *)diff);
		assert(!overflow);
	} else {
		if (O7C_OVERFLOW) {
			assert(*(Uint64_t *)m >= *(Uint64_t *)s);
		}
		*(Uint64_t *)diff = *(Uint64_t *)m - *(Uint64_t *)s;
	}
}

O7C_ALWAYS_INLINE void
	Uint64_Mul(Uint64_Type prod, Uint64_Type m1, Uint64_Type m2)
{
	o7c_bool overflow;
	if (O7C_OVERFLOW && O7C_GNUC_BUILTIN_OVERFLOW) {
		overflow = __builtin_mul_overflow(*(Uint64_t *)m1, *(Uint64_t *)m2,
		                                  (Uint64_t *)prod);
		assert(!overflow);
	} else {
		if (O7C_OVERFLOW) {
			assert((*(Uint64_t *)m2 == 0)
			    || (*(Uint64_t *)m1 <= Uint64_Max / *(Uint64_t *)m2));
		}
		*(Uint64_t *)prod = *(Uint64_t *)m1 * *(Uint64_t *)m2;
	}
}

O7C_ALWAYS_INLINE void Uint64_CheckDiv(Uint64_Type n, Uint64_Type d) {
	if (O7C_OVERFLOW && O7C_DIV_ZERO) {
		assert(*(Uint64_t *)d != 0);
	}
}

O7C_ALWAYS_INLINE void
	Uint64_Div(Uint64_Type div, Uint64_Type n, Uint64_Type d)
{
	Uint64_CheckDiv(n, d);
	*(Uint64_t *)div = *(Uint64_t *)n / *(Uint64_t *)d;
}

O7C_ALWAYS_INLINE void
	Uint64_Mod(Uint64_Type mod, Uint64_Type n, Uint64_Type d)
{
	Uint64_CheckDiv(n, d);
	*(Uint64_t *)mod = *(Uint64_t *)n % *(Uint64_t *)d;
}

O7C_ALWAYS_INLINE void
	Uint64_DivMod(Uint64_Type div, Uint64_Type mod, Uint64_Type n, Uint64_Type d)
{
	Uint64_CheckDiv(n, d);
	*(Uint64_t *)div = *(Uint64_t *)n / *(Uint64_t *)d;
	*(Uint64_t *)mod = *(Uint64_t *)n % *(Uint64_t *)d;
}

O7C_ALWAYS_INLINE void Uint64_init(void) {
	*(Uint64_t *)Uint64_max = Uint64_Max;
}

#if defined(O7C_GNUC_BUILTIN_OVERFLOW_NEED_UNDEF)
#	undef O7C_GNUC_BUILTIN_OVERFLOW_NEED_UNDEF
#	undef __builtin_add_overflow
#	undef __builtin_sub_overflow
#	undef __builtin_mul_overflow
#endif

#endif

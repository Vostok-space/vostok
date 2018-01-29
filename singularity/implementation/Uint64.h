/* Copyright 2016, 2018 ComdivByZero
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
#if !defined HEADER_GUARD_Uint64
#    define  HEADER_GUARD_Uint64 1

typedef o7_ulong_t Uint64_t;
#define Uint64_Max O7_ULONG_MAX

#define Uint64_Size_cnst ((int)sizeof(Uint64_t))

typedef o7_char Uint64_Type[Uint64_Size_cnst];

static Uint64_Type Uint64_min, Uint64_max;

O7_ALWAYS_INLINE void Uint64_FromInt(Uint64_Type v, o7_int_t high, o7_int_t low) {
	*(Uint64_t *)v = o7_int(high) * (Uint64_t)INT_MAX + o7_int(low);
}

O7_ALWAYS_INLINE void Uint64_ToInt(o7_int_t *i, Uint64_Type v) {
	if (O7_OVERFLOW) {
		assert(*(Uint64_t *)v <= O7_INT_MAX);
	}
	*i = *(Uint64_t *)v;
}

O7_ALWAYS_INLINE void
	Uint64_Add(Uint64_Type sum, Uint64_Type a1, Uint64_Type a2)
{
	o7_bool overflow;
	if (O7_OVERFLOW && O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = O7_GNUC_UADDL(*(Uint64_t *)a1, *(Uint64_t *)a2, (Uint64_t *)sum);
		assert(!overflow);
	} else {
		if (O7_OVERFLOW) {
			assert(*(Uint64_t *)a1 <= Uint64_Max - *(Uint64_t *)a2);
		}
		*(Uint64_t *)sum = *(Uint64_t *)a1 + *(Uint64_t *)a2;
	}
}

O7_ALWAYS_INLINE void
	Uint64_Sub(Uint64_Type diff, Uint64_Type m, Uint64_Type s)
{
	o7_bool overflow;
	if (O7_OVERFLOW && O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = O7_GNUC_USUBL(*(Uint64_t *)m, *(Uint64_t *)s, (Uint64_t *)diff);
		assert(!overflow);
	} else {
		if (O7_OVERFLOW) {
			assert(*(Uint64_t *)s <= *(Uint64_t *)m);
		}
		*(Uint64_t *)diff = *(Uint64_t *)m - *(Uint64_t *)s;
	}
}

O7_ALWAYS_INLINE void
	Uint64_Mul(Uint64_Type prod, Uint64_Type m1, Uint64_Type m2)
{
	o7_bool overflow;
	if (O7_OVERFLOW && O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = O7_GNUC_UMULL(*(Uint64_t *)m1, *(Uint64_t *)m2, (Uint64_t *)prod);
		assert(!overflow);
	} else {
		if (O7_OVERFLOW) {
			assert((*(Uint64_t *)m2 == 0)
			    || (*(Uint64_t *)m1 <= Uint64_Max / *(Uint64_t *)m2));
		}
		*(Uint64_t *)prod = *(Uint64_t *)m1 * *(Uint64_t *)m2;
	}
}

O7_ALWAYS_INLINE void Uint64_CheckDiv(Uint64_Type n, Uint64_Type d) {
	if (O7_OVERFLOW && O7_DIV_ZERO) {
		assert(*(Uint64_t *)d != 0);
	}
}

O7_ALWAYS_INLINE void Uint64_Div(Uint64_Type div, Uint64_Type n, Uint64_Type d) {
	Uint64_CheckDiv(n, d);
	*(Uint64_t *)div = *(Uint64_t *)n / *(Uint64_t *)d;
}

O7_ALWAYS_INLINE void Uint64_Mod(Uint64_Type mod, Uint64_Type n, Uint64_Type d) {
	Uint64_CheckDiv(n, d);
	*(Uint64_t *)mod = *(Uint64_t *)n % *(Uint64_t *)d;
}

O7_ALWAYS_INLINE void
	Uint64_DivMod(Uint64_Type div, Uint64_Type mod, Uint64_Type n, Uint64_Type d)
{
	Uint64_CheckDiv(n, d);
	*(Uint64_t *)div = *(Uint64_t *)n / *(Uint64_t *)d;
	*(Uint64_t *)mod = *(Uint64_t *)n % *(Uint64_t *)d;
}

O7_ALWAYS_INLINE int Uint64_Cmp(Uint64_Type l, Uint64_Type r) {
	int cmp;
	if (*(Uint64_t *)l < *(Uint64_t *)r) {
		cmp = -1;
	} else if (*(Uint64_t *)l > *(Uint64_t *)r) {
		cmp = +1;
	} else {
		cmp = 0;
	}
	return cmp;
}

O7_ALWAYS_INLINE void Uint64_init(void) {
	*(Uint64_t *)Uint64_min = 0;
	*(Uint64_t *)Uint64_max = Uint64_Max;
}

#endif

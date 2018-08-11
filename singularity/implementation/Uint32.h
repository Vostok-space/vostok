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
#if !defined HEADER_GUARD_Uint32
#    define  HEADER_GUARD_Uint32 1

typedef o7_uint_t Uint32_t;
#define Uint32_Max O7_UINT_MAX

#define Uint32_Size_cnst ((int)sizeof(Uint32_t))

typedef o7_char Uint32_Type[Uint32_Size_cnst];

static Uint32_Type Uint32_min, Uint32_max;

O7_ALWAYS_INLINE void Uint32_FromInt(Uint32_Type v, o7_int_t i) {
	*(Uint32_t *)v = o7_int(i);
}

O7_ALWAYS_INLINE o7_int_t Uint32_ToInt(Uint32_Type v) {
	if (O7_OVERFLOW) {
		assert(*(Uint32_t *)v <= O7_INT_MAX);
	}
	return *(Uint32_t *)v;
}

O7_ALWAYS_INLINE void
Uint32_Add(Uint32_Type sum, Uint32_Type a1, Uint32_Type a2)
{
	o7_cbool overflow;
	if (O7_OVERFLOW && O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = O7_GNUC_UADD(*(Uint32_t *)a1, *(Uint32_t *)a2, (Uint32_t *)sum);
		assert(!overflow);
	} else {
		if (O7_OVERFLOW) {
			assert(*(Uint32_t *)a1 <= Uint32_Max - *(Uint32_t *)a2);
		}
		*(Uint32_t *)sum = *(Uint32_t *)a1 + *(Uint32_t *)a2;
	}
}

O7_ALWAYS_INLINE void
Uint32_Sub(Uint32_Type diff, Uint32_Type m, Uint32_Type s)
{
	o7_cbool overflow;
	if (O7_OVERFLOW && O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = O7_GNUC_USUB(*(Uint32_t *)m, *(Uint32_t *)s, (Uint32_t *)diff);
		assert(!overflow);
	} else {
		if (O7_OVERFLOW) {
			assert(*(Uint32_t *)s <= *(Uint32_t *)m);
		}
		*(Uint32_t *)diff = *(Uint32_t *)m - *(Uint32_t *)s;
	}
}

O7_ALWAYS_INLINE void
Uint32_Mul(Uint32_Type prod, Uint32_Type m1, Uint32_Type m2)
{
	o7_cbool overflow;
	if (O7_OVERFLOW && O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = O7_GNUC_UMUL(*(Uint32_t *)m1, *(Uint32_t *)m2, (Uint32_t *)prod);
		assert(!overflow);
	} else {
		if (O7_OVERFLOW) {
			assert((*(Uint32_t *)m2 == 0)
			    || (*(Uint32_t *)m1 <= Uint32_Max / *(Uint32_t *)m2));
		}
		*(Uint32_t *)prod = *(Uint32_t *)m1 * *(Uint32_t *)m2;
	}
}

O7_ALWAYS_INLINE void Uint32_CheckDiv(Uint32_Type n, Uint32_Type d) {
	if (O7_OVERFLOW && O7_DIV_ZERO) {
		assert(*(Uint32_t *)d != 0);
	}
}

O7_ALWAYS_INLINE void Uint32_Div(Uint32_Type div, Uint32_Type n, Uint32_Type d) {
	Uint32_CheckDiv(n, d);
	*(Uint32_t *)div = *(Uint32_t *)n / *(Uint32_t *)d;
}

O7_ALWAYS_INLINE void Uint32_Mod(Uint32_Type mod, Uint32_Type n, Uint32_Type d) {
	Uint32_CheckDiv(n, d);
	*(Uint32_t *)mod = *(Uint32_t *)n % *(Uint32_t *)d;
}

O7_ALWAYS_INLINE void
Uint32_DivMod(Uint32_Type div, Uint32_Type mod, Uint32_Type n, Uint32_Type d)
{
	Uint32_CheckDiv(n, d);
	*(Uint32_t *)div = *(Uint32_t *)n / *(Uint32_t *)d;
	*(Uint32_t *)mod = *(Uint32_t *)n % *(Uint32_t *)d;
}

O7_ALWAYS_INLINE int Uint32_Cmp(Uint32_Type l, Uint32_Type r) {
	int cmp;
	if (*(Uint32_t *)l < *(Uint32_t *)r) {
		cmp = -1;
	} else if (*(Uint32_t *)l > *(Uint32_t *)r) {
		cmp = +1;
	} else {
		cmp = 0;
	}
	return cmp;
}

O7_ALWAYS_INLINE void Uint32_init(void) {
	*(Uint32_t *)Uint32_min = 0;
	*(Uint32_t *)Uint32_max = Uint32_Max;
}
O7_ALWAYS_INLINE void Uint32_done(void) {}

#endif

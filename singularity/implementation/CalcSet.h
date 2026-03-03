/* Arithmetic and bits operations for SET as two's complement 32-bit integers.
 * Efficient implementation as usual integers
 *
 * Copyright 2026 ComdivByZero
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
#if !defined HEADER_GUARD_CalcSet
#    define  HEADER_GUARD_CalcSet 1

#define CalcSet_Len_cnst 32
#define CalcSet_Last_cnst 31

#define CalcSet_Min_cnst  0x80000000u
#define CalcSet_Max_cnst  0x7FFFFFFFu
#define CalcSet_MaxU_cnst 0xFFFFFFFFu

O7_CONST_INLINE o7_int_t CalcSet_ToInt(o7_set_t s) {
  o7_assert(s != (o7_set_t)CalcSet_Min_cnst);
  return (o7_int_t)s;
}

O7_CONST_INLINE o7_set_t CalcSet_FromInt(o7_int_t i) {
  return (o7_set_t)i;
}

O7_CONST_INLINE o7_int_t CalcSet_ToByte(o7_set_t s, o7_int_t i) {
  o7_assert(0 <= i && i <= 3);
  return (s >> (i * 8)) % 0x100;
}

O7_ALWAYS_INLINE void CalcSet_ToBytes(o7_set_t s, o7_int_t len, char unsigned bytes[/*len*/]) {
  o7_assert(len >= 4);
  if (O7_BYTE_ORDER == O7_ORDER_LE) {
    memcpy(bytes, &s, 4);
  } else {
    bytes[0] = s % 0x100;
    bytes[1] = s / 0x100 % 0x100;
    bytes[2] = s / 0x10000 % 0x100;
    bytes[3] = s / 0x1000000;
  }
}

O7_CONST_INLINE o7_set_t CalcSet_FromByte(char unsigned b, o7_int_t i) {
  o7_assert(0 <= i && i <= 3);
  return (o7_set_t)b << (i * 8);
}

O7_PURE_INLINE o7_set_t CalcSet_FromBytes(o7_int_t len, char unsigned bytes[/*len*/]) {
  o7_set_t s;
  o7_assert(len >= 4);
  if (O7_BYTE_ORDER == O7_ORDER_LE) {
    memcpy(&s, bytes, 4);
  } else {
    s = (o7_set_t)bytes[0]
      | ((o7_set_t)bytes[1] * 0x100)
      | ((o7_set_t)bytes[2] * 0x10000)
      | ((o7_set_t)bytes[3] * 0x1000000);
  }
  return s;
}

O7_CONST_INLINE o7_set_t CalcSet_Lsl(o7_set_t s, o7_int_t n) {
  o7_assert(n >= 0);
  return s << n;
}

O7_CONST_INLINE o7_set_t CalcSet_Lsr(o7_set_t s, o7_int_t n) {
  o7_assert(n >= 0);
  return s >> n;
}

O7_CONST_INLINE o7_set_t CalcSet_Asr(o7_set_t s, o7_int_t n) {
  o7_assert(0 <= n && n <= CalcSet_Last_cnst);
  return (o7_set_t)O7_ASR((o7_int_t)s, n);
}

O7_CONST_INLINE o7_set_t CalcSet_Ror(o7_set_t s, o7_int_t n) {
  o7_assert(0 <= n);
  return (o7_set_t)O7_ROR((o7_int_t)s, n % CalcSet_Len_cnst);
}

O7_CONST_INLINE o7_set_t CalcSet_WrapInc(o7_set_t s) {
  return s + 1;
}

O7_CONST_INLINE o7_set_t CalcSet_WrapDec(o7_set_t s) {
  return s - 1;
}

O7_CONST_INLINE o7_set_t CalcSet_WrapNeg(o7_set_t s) {
  return -s;
}

O7_ALWAYS_INLINE o7_set_t CalcSet_AddWithCarry(o7_set_t a1, o7_set_t a2, o7_int_t *carry) {
  o7_set64_t s;
  o7_int_t c;
  c = *carry;
  o7_assert(c == 0 || c == 1);
  s = a1 + a2 + c;
  *carry = s >> 32;
  return (o7_set_t)s;
}

O7_CONST_INLINE o7_set_t CalcSet_WrapAddWithCarry(o7_set_t a1, o7_set_t a2, o7_int_t c) {
  return CalcSet_AddWithCarry(a1, a2, &c);
}

O7_CONST_INLINE o7_set_t CalcSet_WrapAdd(o7_set_t a1, o7_set_t a2) {
  return a1 + a2;
}

O7_CONST_INLINE o7_set_t CalcSet_WrapSub(o7_set_t a1, o7_set_t a2) {
  return a1 - a2;
}

O7_CONST_INLINE o7_set_t CalcSet_WrapMulU(o7_set_t m1, o7_set_t m2) {
  return m1 * m2;
}

O7_CONST_INLINE o7_set_t CalcSet_WrapMul(o7_set_t m1, o7_set_t m2) {
  o7_cbool neg;
  o7_set_t r;
  neg = m1 >= CalcSet_Max_cnst;
  if (neg) {
    m1 = ~m1 + 1;
  }
  if (m2 >= CalcSet_Max_cnst) {
    neg = !neg;
    m2 = ~m2 + 1;
  }
  r = m1 * m2;
  if (neg) {
    r = ~r + 1;
  }
  return r;
}

O7_CONST_INLINE o7_int_t CalcSet_CmpU(o7_set_t a, o7_set_t b) {
  o7_int_t r;
  if (a < b) {
    r = -1;
  } else if (a > b) {
    r = +1;
  } else {
    r = 0;
  }
  return r;
}

O7_CONST_INLINE o7_int_t CalcSet_Cmp(o7_set_t a, o7_set_t b) {
  o7_int_t r;

  if ((a ^ CalcSet_Min_cnst) < (b ^ CalcSet_Min_cnst)) {
    r = -1;
  } else if (a != b) {
    r = +1;
  } else {
    r = 0;
  }
  return r;
}

O7_ALWAYS_INLINE o7_set_t CalcSet_DivModU(o7_set_t d, o7_set_t s, o7_set_t *mod) {
  o7_set_t r;
  o7_assert(s != 0);

  r = d / s;
  *mod = d - r * s;
  return r;
}

O7_CONST_INLINE o7_set_t CalcSet_DivU(o7_set_t d, o7_set_t s) {
  o7_assert(s != 0);
  return d / s;
}

O7_CONST_INLINE o7_set_t CalcSet_ModU(o7_set_t d, o7_set_t s) {
  o7_assert(s != 0);
  return d % s;
}

O7_CONST_INLINE o7_long_t CalcSet_ToLong(o7_set_t v) {
  return (o7_long_t)(v ^ CalcSet_Min_cnst) - CalcSet_Min_cnst;
}


O7_ALWAYS_INLINE o7_int_t CalcSet_Divide(o7_int_t a, o7_int_t b) {
  o7_int_t c;
  if (a > 0) {
    if (b > 0) {
      c = a / b;
    } else {
      c = -1 - (-1 + a) / -b;
    }
  } else {
    if (b > 0) {
      c = -1 - (-1 - a) / b;
    } else if (a >= O7_INT_MAX || b < -1) {
      c = a / b;
    } else {
      c = a;
    }
  }
  return c;
}

O7_ALWAYS_INLINE o7_int_t CalcSet_Module(o7_int_t a, o7_int_t b) {
  o7_int_t c;
  if (a > 0) {
    if (b > 0) {
      c = a % b;
    } else {
      c = b - (-1 - (-1 + a) % -b);
    }
  } else {
    if (b > 0) {
      c = b + (-1 - (-1 - a) % b);
    } else if (a >= O7_INT_MAX || b < -1) {
      c = a % b;
    } else {
      c = 0;
    }
  }
  return c;
}

O7_ALWAYS_INLINE o7_set_t CalcSet_DivMod(o7_set_t d, o7_set_t s, o7_set_t *mod) {
  o7_int_t a, b, c;
  o7_assert(s != 0);

  a = (o7_int_t)d;
  b = (o7_int_t)s;
  c = CalcSet_Divide(a, b);
  *mod = (o7_set_t)(a - (o7_long_t)b * c);
  o7_assert(c != CalcSet_MaxU_cnst || s == 1);
  return (o7_set_t)c;
}

O7_CONST_INLINE o7_set_t CalcSet_Div(o7_set_t d, o7_set_t s) {
  o7_assert(s != 0);
  return (o7_set_t)CalcSet_Divide((o7_int_t)d, (o7_int_t)s);
}

O7_CONST_INLINE o7_set_t CalcSet_Mod(o7_set_t d, o7_set_t s) {
  o7_assert(s != 0);
  return (o7_set_t)CalcSet_Module((o7_int_t)d, (o7_int_t)s);
}

O7_INLINE void CalcSet_init(void) { ; }
#endif

/* Copyright 2018 ComdivByZero
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
#if !defined HEADER_GUARD_Uint64Bits
#    define  HEADER_GUARD_Uint64Bits 1

#include "Uint64.h"

O7_CONST_INLINE o7_uint_t Uint64Bits_BitsLow(Uint64_Type v) {
  /* TODO incorrect for big endian */
  return (o7_uint_t)*(Uint64_t *)v;
}

O7_CONST_INLINE o7_uint_t Uint64Bits_BitsHigh(Uint64_Type v) {
  /* TODO incorrect for big endian */
  return (o7_uint_t)(*(Uint64_t *)v >> 32);
}

O7_ALWAYS_INLINE o7_uint_t Uint64Bits_Bits(Uint64_Type v) {
  Uint64_t u;
  u = *(Uint64_t *)v;
  assert(u <= O7_UINT_MAX);
  return (o7_uint_t)u;
}

O7_ALWAYS_INLINE void
  Uint64Bits_And(Uint64_Type res, Uint64_Type a1, Uint64_Type a2)
{
  *(Uint64_t *)res = *(Uint64_t *)a1 & *(Uint64_t *)a2;
}

O7_ALWAYS_INLINE void
  Uint64Bits_Or(Uint64_Type res, Uint64_Type a1, Uint64_Type a2)
{
  *(Uint64_t *)res = *(Uint64_t *)a1 | *(Uint64_t *)a2;
}

O7_ALWAYS_INLINE void
  Uint64Bits_Xor(Uint64_Type res, Uint64_Type a1, Uint64_Type a2)
{
  *(Uint64_t *)res = *(Uint64_t *)a1 ^ *(Uint64_t *)a2;
}

O7_ALWAYS_INLINE void Uint64Bits_Not(Uint64_Type res, Uint64_Type a) {
  *(Uint64_t *)res = ~*(Uint64_t *)a;
}

O7_ALWAYS_INLINE void
  Uint64Bits_Shl(Uint64_Type res, Uint64_Type a, int shift)
{
  assert(0 <= shift);
  *(Uint64_t *)res = *(Uint64_t *)a << (unsigned)shift;
}

O7_ALWAYS_INLINE void
  Uint64Bits_Shr(Uint64_Type res, Uint64_Type a, int shift)
{
  assert(0 <= shift);
  *(Uint64_t *)res = *(Uint64_t *)a >> (unsigned)shift;
}

O7_ALWAYS_INLINE void Uint64Bits_init(void) {}
O7_ALWAYS_INLINE void Uint64Bits_done(void) {}

#endif

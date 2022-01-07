/* Filling arrays of chars and bytes
 *
 * Copyright 2022 ComdivByZero
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
#if !defined HEADER_GUARD_ArrayFill
#    define  HEADER_GUARD_ArrayFill 1

O7_ALWAYS_INLINE void
ArrayFill_Char(o7_int_t len, o7_char a[O7_VLA(len)], o7_int_t ofs, o7_char ch, o7_int_t n)
{
    O7_ASSERT(0 <= n);
    O7_ASSERT((0 <= ofs) && (ofs <= len - n));
    memset(a + ofs, ch, (size_t)n);
}

O7_ALWAYS_INLINE void
ArrayFill_Char0(o7_int_t len, o7_char a[O7_VLA(len)], o7_int_t ofs, o7_int_t n)
{
    ArrayFill_Char(len, a, ofs, 0u, n);
}

O7_ALWAYS_INLINE void
ArrayFill_Byte(o7_int_t len, char unsigned a[O7_VLA(len)], o7_int_t ofs, char unsigned b, o7_int_t n)
{
    O7_ASSERT(0 <= n);
    O7_ASSERT((0 <= ofs) && (ofs <= len - n));
    memset(a + ofs, b, (size_t)n);
}

O7_ALWAYS_INLINE void
ArrayFill_Byte0(o7_int_t len, char unsigned a[O7_VLA(len)], o7_int_t ofs, o7_int_t n)
{
    ArrayFill_Byte(len, a, ofs, 0u, n);
}

O7_ALWAYS_INLINE void ArrayFill_init(void) {}
O7_ALWAYS_INLINE void ArrayFill_done(void) {}
#endif

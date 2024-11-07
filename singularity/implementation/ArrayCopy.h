/* Copying arrays of chars and bytes in any direction
 *
 * Copyright 2022,2024 ComdivByZero
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
#if !defined HEADER_GUARD_ArrayCopy
#    define  HEADER_GUARD_ArrayCopy 1

#define ArrayCopy_FromChars_cnst 0
#define ArrayCopy_FromBytes_cnst 1
#define ArrayCopy_ToChars_cnst 0
#define ArrayCopy_ToBytes_cnst 2

#define ArrayCopy_FromCharsToChars_cnst (ArrayCopy_FromChars_cnst + ArrayCopy_ToChars_cnst)
#define ArrayCopy_FromCharsToBytes_cnst (ArrayCopy_FromChars_cnst + ArrayCopy_ToBytes_cnst)
#define ArrayCopy_FromBytesToChars_cnst (ArrayCopy_FromBytes_cnst + ArrayCopy_ToChars_cnst)
#define ArrayCopy_FromBytesToBytes_cnst (ArrayCopy_FromBytes_cnst + ArrayCopy_ToBytes_cnst)

O7_ALWAYS_INLINE void ArrayCopy_Params_Check(
    o7_int_t dest_len, o7_int_t destOfs,
    o7_int_t src_len, o7_int_t srcOfs,
    o7_int_t count)
{
    O7_ASSERT(count > 0);
    O7_ASSERT((0 <= destOfs) && (destOfs <= dest_len - count));
    O7_ASSERT((0 <= srcOfs) && (srcOfs <= src_len - count));
}

O7_ALWAYS_INLINE void ArrayCopy_Chars(
    o7_int_t dest_len, o7_char dest[O7_VLA(dest_len)], o7_int_t destOfs,
    o7_int_t src_len, o7_char src[O7_VLA(src_len)], o7_int_t srcOfs,
    o7_int_t count)
{
    ArrayCopy_Params_Check(dest_len, destOfs, src_len, srcOfs, count);
    memcpy(dest + destOfs, src + srcOfs, (size_t)count);
}

O7_ALWAYS_INLINE void ArrayCopy_Bytes(
    o7_int_t dest_len, char unsigned dest[O7_VLA(dest_len)], o7_int_t destOfs,
    o7_int_t src_len, char unsigned src[O7_VLA(src_len)], o7_int_t srcOfs,
    o7_int_t count)
{
    ArrayCopy_Params_Check(dest_len, destOfs, src_len, srcOfs, count);
    memcpy(dest + destOfs, src + srcOfs, (size_t)count);
}

O7_ALWAYS_INLINE void ArrayCopy_CharsToBytes(
    o7_int_t dest_len, char unsigned dest[O7_VLA(dest_len)], o7_int_t destOfs,
    o7_int_t src_len, o7_char src[O7_VLA(src_len)], o7_int_t srcOfs,
    o7_int_t count)
{
    ArrayCopy_Params_Check(dest_len, destOfs, src_len, srcOfs, count);
    memcpy(dest + destOfs, src + srcOfs, (size_t)count);
}

O7_ALWAYS_INLINE void ArrayCopy_BytesToChars(
    o7_int_t dest_len, o7_char dest[O7_VLA(dest_len)], o7_int_t destOfs,
    o7_int_t src_len, char unsigned src[O7_VLA(src_len)], o7_int_t srcOfs, o7_int_t count)
{
    ArrayCopy_Params_Check(dest_len, destOfs, src_len, srcOfs, count);
    memcpy(dest + destOfs, src + srcOfs, (size_t)count);
}

#if (__GNUC__ > 10) && !defined(__clang__)
#   pragma GCC diagnostic push
#   pragma GCC diagnostic ignored "-Wstringop-overflow"
#   pragma GCC diagnostic ignored "-Wstringop-overread"
#endif

O7_ALWAYS_INLINE void ArrayCopy_Data(o7_int_t direction,
    o7_int_t destBytes_len, char unsigned destBytes[O7_VLA(destBytes_len)],
    o7_int_t destChars_len, o7_char destChars[O7_VLA(destChars_len)], o7_int_t destOfs,
    o7_int_t srcBytes_len, char unsigned srcBytes[O7_VLA(srcBytes_len)],
    o7_int_t srcChars_len, o7_char srcChars[O7_VLA(srcChars_len)], o7_int_t srcOfs, o7_int_t count)
{
    switch (direction) {
    case ArrayCopy_FromCharsToChars_cnst:
        ArrayCopy_Chars(destChars_len, destChars, destOfs, srcChars_len, srcChars, srcOfs, count);
        break;
    case ArrayCopy_FromCharsToBytes_cnst:
        ArrayCopy_CharsToBytes(destBytes_len, destBytes, destOfs, srcChars_len, srcChars, srcOfs, count);
        break;
    case ArrayCopy_FromBytesToChars_cnst:
        ArrayCopy_BytesToChars(destChars_len, destChars, destOfs, srcBytes_len, srcBytes, srcOfs, count);
        break;
    case ArrayCopy_FromBytesToBytes_cnst:
        ArrayCopy_Bytes(destBytes_len, destBytes, destOfs, srcBytes_len, srcBytes, srcOfs, count);
        break;
    default:
        o7_case_fail(direction);
        break;
    }
}

#if (__GNUC__ > 10) && !defined(__clang__)
#   pragma GCC diagnostic pop
#endif

O7_ALWAYS_INLINE void ArrayCopy_init(void) {}
O7_ALWAYS_INLINE void ArrayCopy_done(void) {}
#endif

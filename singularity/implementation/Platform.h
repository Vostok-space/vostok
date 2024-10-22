/* Copyright 2017-2018,2021-2022,2024 ComdivByZero
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
#if !defined HEADER_GUARD_Platform
#    define  HEADER_GUARD_Platform 1

#define Platform_LittleEndian_cnst O7_ORDER_LE
#define Platform_BigEndian_cnst    O7_ORDER_BE

extern o7_cbool const
  Platform_Posix,
  Platform_Linux,
  Platform_Bsd,
  Platform_Mingw,
  Platform_Dos,
  Platform_Windows,
  Platform_Darwin,
  Platform_Haiku,
  Platform_Wasm,
  Platform_Wasi,
  Platform_C,
  Platform_Java,
  Platform_JavaScript;

#define Platform_ByteOrder O7_BYTE_ORDER

O7_ALWAYS_INLINE void Platform_init(void) {}
O7_ALWAYS_INLINE void Platform_done(void) {}
#endif

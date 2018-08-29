/* Copyright 2017-2018 ComdivByZero
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
#if !defined(HEADER_GUARD_Platform)
#define HEADER_GUARD_Platform 1

extern o7_bool const
  Platform_Posix,
  Platform_Linux,
  Platform_Bsd,
  Platform_Mingw,
  Platform_Dos,
  Platform_Windows,
  Platform_Java;

O7_INLINE void Platform_init(void) {}
#endif

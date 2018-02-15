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
#define O7_BOOL_UNDEFINED
#include <o7.h>

#include "Platform.h"


#if defined(__linux__) || defined(__linux)
  o7_cbool const Platform_Linux = 0 < 1;
#else
  o7_cbool const Platform_Linux = 0 > 1;
#endif

#if defined(_WIN16) || defined(_WIN32) || defined(_WIN64)
  o7_cbool const Platform_Windows = 0 < 1;
#else
  o7_cbool const Platform_Windows = 0 > 1;
#endif

#if defined(__MINGW32__) || defined(__MINGW64__)
  o7_cbool const Platform_Mingw = 0 < 1;
#else
  o7_cbool const Platform_Mingw = 0 > 1;
#endif

#if defined(BSD) || defined(__bsdi__)
  o7_cbool const Platform_Bsd = 0 < 1;
#else
  o7_cbool const Platform_Bsd = 0 > 1;
#endif

#if defined(MSDOS) || defined(__MSDOS__) || defined(__DOS__)
  o7_cbool const Platform_Dos = 0 < 1;
#else
  o7_cbool const Platform_Dos = 0 > 1;
#endif

#if defined(__linux__) || defined(__linux) || defined(BSD) || defined(__bsdi__)
  o7_cbool const Platform_Posix = 0 < 1;
#else
  o7_cbool const Platform_Posix = 0 > 1;
#endif



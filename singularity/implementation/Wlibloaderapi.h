/* Wrapper of Windows libloaderapi.h for Oberon
 *
 * Copyright 2021 ComdivByZero
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
#if !defined HEADER_GUARD_Wlibloaderapi
#    define  HEADER_GUARD_Wlibloaderapi 1

typedef struct Wlibloaderapi_HMODULE__s { char nothing; } *Wlibloaderapi_HMODULE;
#define Wlibloaderapi_HMODULE__s_tag o7_base_tag

O7_ALWAYS_INLINE void Wlibloaderapi_HMODULE__s_undef(Wlibloaderapi_HMODULE *r) {}

extern o7_int_t Wlibloaderapi_GetModuleFileNameA(
    Wlibloaderapi_HMODULE hmodule,
    o7_int_t lpFilename_len, o7_char lpFilename[/*len*/]);

O7_ALWAYS_INLINE void Wlibloaderapi_init(void) {}
#endif

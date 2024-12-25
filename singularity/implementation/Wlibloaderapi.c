/* Wrapper of Windows libloaderapi.h for Oberon
 *
 * Copyright 2021,2024 ComdivByZero
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
#include <o7.h>

#include "Wlibloaderapi.h"

#if defined(_WIN32) || defined(_WIN64)
#	include <windows.h>
#else
	typedef void *HMODULE;

	O7_ALWAYS_INLINE unsigned GetModuleFileNameA(void *hmodule, char *lpFilename, unsigned nSize) {
		return 0;
	}
#endif

extern o7_int_t Wlibloaderapi_GetModuleFileNameA(
	Wlibloaderapi_HMODULE hmodule,
	o7_int_t lpFilename_len, o7_char lpFilename[/*len*/])
{
	O7_ASSERT(lpFilename_len > 1);
	return (o7_int_t)GetModuleFileNameA((HMODULE)hmodule, (char *)lpFilename, (unsigned)lpFilename_len);
}

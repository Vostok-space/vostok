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
#include <stdbool.h>

#define O7_BOOL_UNDEFINED
#include <o7.h>

#include "WindowsRand.h"
#include "stdio.h"

#if (defined(_WIN16) || defined(_WIN32) || defined(_WIN64)) && !defined(__TINYC__)
#	include <windows.h>
#	include <Wincrypt.h>
#else
	typedef int HCRYPTPROV;
	enum PRF { PROV_RSA_FULL };
	enum NBK { NTE_BAD_KEYSET, NBK_UNKNOWN };
	enum CNK { CNK_DEFAULT, CRYPT_NEWKEYSET };

	O7_INLINE o7_cbool
	CryptAcquireContext(HCRYPTPROV *p, void *v1, void *v2, enum PRF pr, enum CNK i)
	{(void)p; (void)v1; (void)v2; (void)pr; (void)i; return 0>1;}

	O7_INLINE void CryptReleaseContext(HCRYPTPROV p, int i)
	{(void)p; (void)i;}

	O7_INLINE enum NBK GetLastError(void) {return NBK_UNKNOWN;}

	O7_INLINE o7_cbool CryptGenRandom(HCRYPTPROV p, int c, char unsigned buf[])
	{(void)p; (void)c; (void)buf;}
#endif

static HCRYPTPROV provider = 0;
static o7_cbool   init     = 0 > 1;

extern o7_cbool WindowsRand_Open(void) {
	if (!init) {
		init = CryptAcquireContext(&provider, NULL, NULL, PROV_RSA_FULL, 0);
		if (!init && (GetLastError() == NTE_BAD_KEYSET)) {
			init = CryptAcquireContext(&provider, NULL, NULL, PROV_RSA_FULL, CRYPT_NEWKEYSET);
		}
	}
	return init;
}

extern void WindowsRand_Close(void) {
	if (init) {
		CryptReleaseContext(provider, 0);
		provider = 0;
		init     = 0 > 1;
	}
}

extern o7_cbool WindowsRand_Read(o7_int_t len, char unsigned buf[O7_VLA(len)],
                                 o7_int_t ofs, o7_int_t count) {
	assert(0 < count);
	assert((0 <= ofs) && (ofs <= len - count));
	return init && CryptGenRandom(provider, count, buf + ofs);
}

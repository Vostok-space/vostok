/* Copyright 2016 ComdivByZero
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
#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include <assert.h>
#include <stdbool.h>

#include "o7c.h"

#include "Out.h"

extern void Out_String(char s[/*len*/], int s_len) {
	int wr;
	wr = printf("%s", s);
	assert(wr < s_len);
}

extern void Out_Char(char ch) {
	printf("%c", ch);
}

extern void Out_Int(int x, int n) {
	printf("%d", x);
}

extern void Out_Ln(void) {
	puts("");
}

extern void Out_Real(double x, int n) {
	printf("%f", x);
}

extern void Out_Open(void) { ; }

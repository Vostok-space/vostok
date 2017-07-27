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
#if !defined(MODULE_Out_HEADER)
#define MODULE_Out_HEADER 1

extern void Out_String(int len, char unsigned s[O7C_VLA_LEN(len)]);

extern void Out_Char(char unsigned ch);

extern void Out_Int(int x, int n);

extern void Out_Ln(void);

extern void Out_Real(double x, int n);

extern void Out_Open(void);

O7C_INLINE void Out_init(void) { ; }

#endif

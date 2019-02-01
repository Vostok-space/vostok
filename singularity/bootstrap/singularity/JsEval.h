/* Copyright 2019 ComdivByZero
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
#if !defined HEADER_GUARD_JsEval
#    define  HEADER_GUARD_JsEval 1

typedef struct JsEval_Code__s { char nothing; } *JsEval_Code;
#define JsEval_Code__s_tag o7_base_tag

O7_ALWAYS_INLINE void JsEval_Code__s_undef(JsEval_Code r) {}

static const o7_cbool JsEval_supported = 0 > 1;

O7_ALWAYS_INLINE o7_cbool JsEval_New(JsEval_Code *c)
{ O7_ASSERT(0 > 1); return 0 > 1; }

O7_ALWAYS_INLINE o7_cbool JsEval_Add(JsEval_Code c, o7_int_t codePart_len0,
                                     o7_char codePart[/*len0*/])
{ O7_ASSERT(0 > 1); return 0 > 1; }

O7_ALWAYS_INLINE o7_cbool JsEval_AddBytes(JsEval_Code c, o7_int_t codePart_len0,
                                          o7_char codePart[/*len0*/])
{ O7_ASSERT(0 > 1); return 0 > 1; }

O7_ALWAYS_INLINE o7_cbool JsEval_End(JsEval_Code c, o7_int_t arg) { O7_ASSERT(0 > 1); return 0 > 1; }

O7_ALWAYS_INLINE o7_cbool JsEval_Do(JsEval_Code c)
{ O7_ASSERT(0 > 1); return 0 > 1; }

O7_ALWAYS_INLINE o7_cbool JsEval_DoStr(o7_int_t str_len0, o7_char str[/*len0*/])
{ O7_ASSERT(0 > 1); return 0 > 1; }

O7_ALWAYS_INLINE void JsEval_init(void) {}
#endif

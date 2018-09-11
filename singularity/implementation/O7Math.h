/* Copyright 2017, 2018 ComdivByZero
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

#if !defined HEADER_GUARD_Math
#    define  HEADER_GUARD_Math 1

#define Math_pi_cnst 3.14159265358979323846
#define Math_e_cnst 2.71828182845904523536

extern double Math_sqrt(double x);

extern double Math_power(double x, double base);

extern double Math_exp(double x);

extern double Math_ln(double x);

extern double Math_log(double x, double base);

extern double Math_round(double x);

extern double Math_sin(double x);

extern double Math_cos(double x);

extern double Math_tan(double x);

extern double Math_arcsin(double x);

extern double Math_arccos(double x);

extern double Math_arctan(double x);

extern double Math_arctan2(double x, double y);

extern double Math_sinh(double x);

extern double Math_cosh(double x);

extern double Math_tanh(double x);

extern double Math_arcsinh(double x);

extern double Math_arccosh(double x);

extern double Math_arctanh(double x);

O7_ALWAYS_INLINE void Math_init(void) { ; }
O7_ALWAYS_INLINE void Math_done(void) { ; }

#endif

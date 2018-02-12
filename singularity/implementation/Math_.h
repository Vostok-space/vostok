/* Copyright 2017 ComdivByZero
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

#define Math__pi_cnst 3.14159265358979323846
#define Math__e_cnst 2.71828182845904523536

extern double Math__sqrt(double x);

extern double Math__power(double x, double base);

extern double Math__exp(double x);

extern double Math__ln(double x);

extern double Math__log(double x, double base);

extern double Math__round(double x);

extern double Math__sin(double x);

extern double Math__cos(double x);

extern double Math__tan(double x);

extern double Math__arcsin(double x);

extern double Math__arccos(double x);

extern double Math__arctan(double x);

extern double Math__arctan2(double x, double y);

extern double Math__sinh(double x);

extern double Math__cosh(double x);

extern double Math__tanh(double x);

extern double Math__arcsinh(double x);

extern double Math__arccosh(double x);

extern double Math__arctanh(double x);

O7_ALWAYS_INLINE void Math_init(void) { ; }
O7_ALWAYS_INLINE void Math_done(void) { ; }

#endif

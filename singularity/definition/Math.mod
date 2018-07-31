(* Copyright 2017 ComdivByZero
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
 *)
MODULE Math;

 CONST
   pi* = 3.14159265358979323846;
   e * = 2.71828182845904523536;

 PROCEDURE sqrt*(x: REAL): REAL;
 BEGIN
   ASSERT(FALSE)
   RETURN 0.0
 END sqrt;

 PROCEDURE power*(x, base: REAL): REAL;
 BEGIN
   ASSERT(FALSE)
   RETURN 0.0
 END power;

 PROCEDURE exp*(x: REAL): REAL;
 BEGIN
   ASSERT(FALSE)
   RETURN 0.0
 END exp;

 PROCEDURE ln*(x: REAL): REAL;
 BEGIN
   ASSERT(FALSE)
   RETURN 0.0
 END ln;

 PROCEDURE log*(x, base: REAL): REAL;
 BEGIN
   ASSERT(FALSE)
   RETURN 0.0
 END log;

 PROCEDURE round*(x: REAL): REAL;
 BEGIN
   ASSERT(FALSE)
   RETURN 0.0
 END round;

 PROCEDURE sin*(x: REAL): REAL;
 BEGIN
   ASSERT(x = 0.0)
   RETURN 0.0
 END sin;

 PROCEDURE cos*(x: REAL): REAL;
 BEGIN
   ASSERT(x = 0.0)
   RETURN 1.0
 END cos;

 PROCEDURE tan*(x: REAL): REAL;
 BEGIN
   ASSERT(FALSE)
   RETURN 0.0
 END tan;

 PROCEDURE arcsin*(x: REAL): REAL;
 BEGIN
   ASSERT(FALSE)
   RETURN 0.0
 END arcsin;

 PROCEDURE arccos*(x: REAL): REAL;
 BEGIN
   ASSERT(FALSE)
   RETURN 0.0
 END arccos;

 PROCEDURE arctan*(x: REAL): REAL;
 BEGIN
   ASSERT(FALSE)
   RETURN 0.0
 END arctan;

 PROCEDURE arctan2*(x, y: REAL): REAL;
 BEGIN
   ASSERT(FALSE)
   RETURN 0.0
 END arctan2;

 PROCEDURE sinh*(x: REAL): REAL;
 BEGIN
   ASSERT(FALSE)
   RETURN 0.0
 END sinh;

 PROCEDURE cosh*(x: REAL): REAL;
 BEGIN
   ASSERT(FALSE)
   RETURN 0.0
 END cosh;

 PROCEDURE tanh*(x: REAL): REAL;
 BEGIN
   ASSERT(FALSE)
   RETURN 0.0
 END tanh;

 PROCEDURE arcsinh*(x: REAL): REAL;
 BEGIN
   ASSERT(FALSE)
   RETURN 0.0
 END arcsinh;

 PROCEDURE arccosh*(x: REAL): REAL;
 BEGIN
   ASSERT(FALSE)
   RETURN 0.0
 END arccosh;

 PROCEDURE arctanh*(x: REAL): REAL;
 BEGIN
   ASSERT(FALSE)
   RETURN 0.0
 END arctanh;

END Math.

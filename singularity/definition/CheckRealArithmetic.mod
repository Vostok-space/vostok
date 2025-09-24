Copyright 2025 ComdivByZero

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

MODULE CheckRealArithmetic;

 IMPORT Real := Real64, Real64Pack10;

 PROCEDURE Add*(VAR r: REAL; a, b: REAL): BOOLEAN;
 VAR c, d: Real.T;
 BEGIN
  Real.From(c, a);
  Real.From(d, b);
  Real.Add(c, c, d)
 RETURN
  Real.To(r, c)
 END Add;

 PROCEDURE Sub*(VAR r: REAL; a, b: REAL): BOOLEAN;
 VAR c, d: Real.T;
 BEGIN
  Real.From(c, a);
  Real.From(d, b);
  Real.Sub(c, c, d)
 RETURN
  Real.To(r, c)
 END Sub;

 PROCEDURE Mul*(VAR r: REAL; a, b: REAL): BOOLEAN;
 VAR c, d: Real.T;
 BEGIN
  Real.From(c, a);
  Real.From(d, b);
  Real.Mul(c, c, d)
 RETURN
  Real.To(r, c)
 END Mul;

 PROCEDURE Div*(VAR r: REAL; a, b: REAL): BOOLEAN;
 VAR c, d: Real.T;
 BEGIN
  Real.From(c, a);
  Real.From(d, b);
  Real.Div(c, c, d)
 RETURN
  Real.To(r, c)
 END Div;

 PROCEDURE Pack*(VAR r: REAL; n: INTEGER): BOOLEAN;
 VAR c: Real.T;
 BEGIN
  Real.From(c, r);
  Real.Pack(c, n)
 RETURN
  Real.To(r, c)
 END Pack;

 PROCEDURE Unpk*(VAR r: REAL; VAR n: INTEGER): BOOLEAN;
 VAR c: Real.T;
 BEGIN
  Real.From(c, r);
  Real.Unpk(c, n)
 RETURN
  Real.To(r, c)
 END Unpk;

 (* x' := x * 10**e; ABS(e) ≤ TypesLimits.RealScaleMax - TypesLimits.RealScaleMin *)
 PROCEDURE Pack10*(VAR x: REAL; n: INTEGER): BOOLEAN;
 VAR x64: Real.T;
 BEGIN
  Real.From(x64, x);
  Real64Pack10.Do(x64, n)
 RETURN
  Real.To(x, x64)
 END Pack10;

END CheckRealArithmetic.

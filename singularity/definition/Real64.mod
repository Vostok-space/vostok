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

MODULE Real64;

 TYPE
  T* = RECORD v: REAL END;

 PROCEDURE IsNan*(r: T): BOOLEAN;
 RETURN
  r.v # r.v
 END IsNan;

 PROCEDURE IsFinite*(r: T): BOOLEAN;
 RETURN
  r.v = r.v
 END IsFinite;

 PROCEDURE From*(VAR r: T; s: REAL);
 BEGIN
  r.v := s
 END From;

 PROCEDURE To*(VAR r: REAL; s: T): BOOLEAN;
 VAR ok: BOOLEAN;
 BEGIN
  ok := IsFinite(s);
  IF ok THEN
    r := s.v
  END
 RETURN
  ok
 END To;

 PROCEDURE Neg*(VAR r: T; a: T);
 BEGIN
  r.v := -a.v
 END Neg;

 PROCEDURE Add*(VAR r: T; a, b: T);
 BEGIN
  r.v := a.v + b.v
 END Add;

 PROCEDURE Sub*(VAR r: T; a, b: T);
 BEGIN
  r.v := a.v - b.v
 END Sub;

 PROCEDURE Mul*(VAR r: T; a, b: T);
 BEGIN
  r.v := a.v * b.v
 END Mul;

 PROCEDURE Div*(VAR r: T; a, b: T);
 BEGIN
  r.v := a.v / b.v
 END Div;

 PROCEDURE Pack*(VAR r: T; n: INTEGER);
 BEGIN
  PACK(r.v, n)
 END Pack;

 PROCEDURE Unpk*(VAR r: T; VAR n: INTEGER);
 BEGIN
  UNPK(r.v, n)
 END Unpk;

END Real64.

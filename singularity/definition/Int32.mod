(* Copyright 2016, 2018 ComdivByZero
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
MODULE Int32;

 CONST
   Size = 4;

 TYPE
   Type* = ARRAY Size OF BYTE;

 VAR
   min*, max*: Type;

 PROCEDURE FromInt*(VAR v: Type; i: INTEGER);
 BEGIN
   IF 0 <= i THEN
     v[0] := i MOD 100H;
     v[1] := i DIV 100H MOD 100H;
     v[2] := i DIV 10000H MOD 100H;
     v[3] := i DIV 1000000H
   ELSE
     i := -i;
     v[0] := 100H - i MOD 100H;
     v[1] := 100H - i DIV 100H MOD 100H;
     v[2] := 100H - i DIV 10000H MOD 100H;
     v[3] := 100H - i DIV 1000000H
   END
 END FromInt;

 PROCEDURE ToInt*(v: Type): INTEGER;
 BEGIN
   ASSERT(FALSE)
   RETURN 0
 END ToInt;

 PROCEDURE Add*(VAR sum: Type; a1, a2: Type);
 BEGIN
   ASSERT(FALSE)
 END Add;

 PROCEDURE Sub*(VAR diff: Type; m, s: Type);
 BEGIN
   ASSERT(FALSE)
 END Sub;

 PROCEDURE Mul*(VAR prod: Type; m1, m2: Type);
 BEGIN
   ASSERT(FALSE)
 END Mul;

 PROCEDURE Div*(VAR div: Type; n, d: Type);
 BEGIN
   ASSERT(FALSE)
 END Div;

 PROCEDURE Mod*(VAR mod: Type; n, d: Type);
 BEGIN
   ASSERT(FALSE)
 END Mod;

 PROCEDURE DivMod*(VAR div, mod: Type; n, d: Type);
 BEGIN
   ASSERT(FALSE)
 END DivMod;

 PROCEDURE Cmp*(l, r: Type): INTEGER;
 BEGIN
   ASSERT(FALSE)
   RETURN 0
 END Cmp;

BEGIN
  min[0] := 0;
  min[1] := 0;
  min[2] := 0;
  min[3] := 80H;

  max[0] := 0FFH;
  max[1] := 0FFH;
  max[2] := 0FFH;
  max[3] := 7FH
END Int32.

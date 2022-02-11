(* Copyright 2016,2018,2020,2022 ComdivByZero
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

   LittleEndian* = 1;
   BigEndian*    = 2;

 TYPE
   Type* = ARRAY Size OF BYTE;

 VAR
   min*, max*: Type;
   ByteOrder*: INTEGER;

 PROCEDURE FromInt*(VAR v: Type; i: INTEGER);
 BEGIN
   v[0] := i              MOD 100H;
   v[1] := i DIV 100H     MOD 100H;
   v[2] := i DIV 10000H   MOD 100H;
   v[3] := i DIV 1000000H MOD 100H
 END FromInt;

 PROCEDURE ToInt*(v: Type): INTEGER;
 BEGIN
   ASSERT(FALSE)
   RETURN 0
 END ToInt;

 PROCEDURE SwapOrder*(VAR v: Type);
 VAR k: INTEGER; b: BYTE;
 BEGIN
   FOR k := 0 TO LEN(v) DIV 2 - 1 DO
     b             := v[k];
     v[k]          := v[LEN(v) - k];
     v[LEN(v) - k] := b
   END
 END SwapOrder;

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
  max[3] := 7FH;

  ByteOrder := LittleEndian
END Int32.

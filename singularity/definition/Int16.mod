(* Copyright 2019 ComdivByZero
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
MODULE Int16;

 CONST
   Size = 2;

   Min* = -8000H;
   Max* =  7FFFH;

 TYPE
   Type* = ARRAY Size OF BYTE;

 VAR
   min*, max*: Type;

 PROCEDURE FromInt*(VAR v: Type; i: INTEGER);
 BEGIN
   ASSERT((Min <= i) & (i <= Max));
   IF i < 0 THEN
     INC(i, 10000H)
   END;
   v[0] := i MOD 100H;
   v[1] := i DIV 100H
 END FromInt;

 PROCEDURE ToInt*(v: Type): INTEGER;
 VAR i: INTEGER;
 BEGIN
   i := v[0] + v[1] * 100H;
   IF i > Max THEN
     DEC(i, 10000H)
   END
 RETURN
   i
 END ToInt;

 PROCEDURE Add*(VAR sum: Type; a1, a2: Type);
 BEGIN
   FromInt(sum, ToInt(a1) + ToInt(a2))
 END Add;

 PROCEDURE Sub*(VAR diff: Type; m, s: Type);
 BEGIN
   FromInt(diff, ToInt(m) - ToInt(s))
 END Sub;

 PROCEDURE Mul*(VAR prod: Type; m1, m2: Type);
 BEGIN
   FromInt(prod, ToInt(m1) * ToInt(m2))
 END Mul;

 PROCEDURE Div*(VAR div: Type; n, d: Type);
 VAR r, ni, di: INTEGER;
 BEGIN
   ni := ToInt(n);
   di := ToInt(d);
   IF ni >= 0 THEN
     IF di >= 0 THEN
       r := ni DIV di
     ELSE
       r := -ni DIV (-di)
     END
   ELSE
     IF di >= 0 THEN
       r := -(-ni) DIV di
     ELSE
       r := (-ni) DIV (-di)
     END
   END;
   FromInt(div, r)
 END Div;

 PROCEDURE Mod*(VAR mod: Type; n, d: Type);
 VAR r, ni, di: INTEGER;
 BEGIN
   ni := ToInt(n);
   di := ToInt(d);
   IF ni >= 0 THEN
     IF di >= 0 THEN
       r := ni MOD di
     ELSE
       r := -ni MOD (-di)
     END
   ELSE
     IF di >= 0 THEN
       r := -(-ni) MOD di
     ELSE
       r := (-ni) MOD (-di)
     END
   END;
   FromInt(mod, r)
 END Mod;

 PROCEDURE DivMod*(VAR div, mod: Type; n, d: Type);
 VAR ni, di, divi, modi: INTEGER;
 BEGIN
   ni := ToInt(n);
   di := ToInt(d);
   divi := ni DIV di;
   modi := ni - divi * di;
   FromInt(div, divi);
   FromInt(mod, modi)
 END DivMod;

 PROCEDURE Cmp*(l, r: Type): INTEGER;
 VAR li, ri, cmp: INTEGER;
 BEGIN
   li := ToInt(l);
   ri := ToInt(r);
   IF li < ri THEN
     cmp := -1
   ELSIF li > ri THEN
     cmp := 1
   ELSE
     cmp := 0
   END
 RETURN
   cmp
 END Cmp;

BEGIN
  min[0] := 0;
  min[1] := 80H;

  max[0] := 0FFH;
  max[1] := 7FH
END Int16.

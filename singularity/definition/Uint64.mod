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
MODULE Uint64;

 CONST
   Size = 8;

 TYPE
   Type* = ARRAY Size OF BYTE;

 VAR
   min*, max*: Type;

 (* v = high * (INTEGER_MAX + 1) + low  *)
 PROCEDURE FromInt*(VAR v: Type; high, low: INTEGER);
 VAR k: INTEGER;
 BEGIN
   ASSERT((0 <= low) & (0 <= high));
   FOR k := 0 TO LEN(v) DIV 2 - 2 DO
     v[k] := low MOD 100H;
     low  := low DIV 100H
   END;
   v[LEN(v) DIV 2 - 1] := low MOD 100H + high MOD 2 * 80H;
   high := high DIV 2;
   FOR k := LEN(v) DIV 2 TO LEN(v) - 2 DO
     v[k] := high MOD 100H;
     high := high DIV 100H
   END;
   v[LEN(v) - 1] := high
 END FromInt;

 PROCEDURE ToInt*(v: Type): INTEGER;
 VAR k, int: INTEGER;
 BEGIN
   ASSERT(v[LEN(v) - 1] < 80H);

   int := v[LEN(v) - 1];
   FOR k := LEN(v) - 2 TO 0 BY -1 DO
     int := int * 100H + v[k]
   END
 RETURN
   int
 END ToInt;

 PROCEDURE Add*(VAR sum: Type; a1, a2: Type);
 VAR i, r: INTEGER;
 BEGIN
   r := a1[0] + a2[0];
   sum[0] := r MOD 100H;
   FOR i := 1 TO LEN(sum) - 1 DO
     r := a1[i] + a2[i] + r DIV 100H;
     sum[i] := r MOD 100H;
   END;
   ASSERT(r = 0)
 END Add;

 PROCEDURE Sub*(VAR diff: Type; m, s: Type);
 VAR i, r: INTEGER;
 BEGIN
   r := 100H;
   FOR i := 0 TO LEN(diff) - 1 DO
     r := (0FFH + r DIV 100H) + m[i] - s[i];
     diff[i] := r MOD 100H
   END;
   ASSERT(r = 100H)
 END Sub;

 PROCEDURE Mul*(VAR prod: Type; m1, m2: Type);
 VAR i, j, b2, e1, e2, r: INTEGER;

   PROCEDURE Begin(v: Type): INTEGER;
   VAR i: INTEGER;
   BEGIN
     i := 0;
     WHILE v[i] = 0 DO
       INC(i)
     END
   RETURN
     i
   END Begin;

   PROCEDURE End(VAR end: INTEGER; v: Type): BOOLEAN;
   BEGIN
     end := LEN(v);
     REPEAT
       DEC(end)
     UNTIL (v[end] # 0) OR (end = 0)
   RETURN
     v[end] = 0
   END End;

 BEGIN
   prod := min;
   IF ~End(e1, m1) & ~End(e2, m2) THEN
     ASSERT(e1 + e2 <= LEN(prod));

     i  := Begin(m1);
     b2 := Begin(m2);

     WHILE i <= e1 DO
       r := 0;
       j := b2;
       WHILE j <= e2 DO
         r := r + m1[i] * m2[j] + prod[i + j];
         prod[i + j] := r MOD 100H;
         r := r DIV 100H;
         INC(j)
       END;
       IF r > 0 THEN
         prod[i + j] := r
       END;
       INC(i)
     END
   END
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
 VAR i, cmp: INTEGER;
 BEGIN
   i := LEN(l) - 1;
   WHILE (0 < i) & (l[i] = r[i]) DO
     DEC(i)
   END;
   IF l[i] < r[i] THEN
     cmp := -1
   ELSIF l[i] > r[i] THEN
     cmp :=  1
   ELSE
     cmp := 0
   END
   RETURN cmp
 END Cmp;

 PROCEDURE Init;
 VAR i: INTEGER;
 BEGIN
   FOR i := 0 TO LEN(min) - 1 DO
     min[i] := 0;
     max[i] := 0FFH
   END
 END Init;

BEGIN
  Init
END Uint64.

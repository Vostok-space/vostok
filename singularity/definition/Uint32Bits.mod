(* Copyright 2018 ComdivByZero
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
MODULE Uint32Bits;

 IMPORT U := Uint32;

 PROCEDURE Bits*(v: U.Type): SET;
 VAR i, j, b: INTEGER; s: SET;
 BEGIN
   s := {};
   FOR i := 0 TO LEN(v) - 1 DO
     b := v[i];
     FOR j := i * 8 TO i * 8 + 7 DO
       IF ODD(b) THEN
         INCL(s, j)
       END;
       b := b DIV 2
     END
   END
 RETURN
   s
 END Bits;

 PROCEDURE ByteBits(b: BYTE): SET;
 VAR i: INTEGER; s: SET;
 BEGIN
   s := {};
   FOR i := 0 TO 7 DO
     IF ODD(b) THEN
       INCL(s, i)
     END;
     b := b DIV 2
   END
 RETURN
   s
 END ByteBits;

 PROCEDURE And*(VAR and: U.Type; a1, a2: U.Type);
 VAR i: INTEGER;
 BEGIN
   FOR i := 0 TO LEN(a1) - 1 DO
     and[i] := ORD(ByteBits(a1[i]) * ByteBits(a2[i]))
   END
 END And;

 PROCEDURE Or*(VAR or: U.Type; a1, a2: U.Type);
 VAR i: INTEGER;
 BEGIN
   FOR i := 0 TO LEN(a1) - 1 DO
     or[i] := ORD(ByteBits(a1[i]) + ByteBits(a2[i]))
   END
 END Or;

 PROCEDURE Xor*(VAR xor: U.Type; a1, a2: U.Type);
 VAR i: INTEGER;
 BEGIN
   FOR i := 0 TO LEN(a1) - 1 DO
     xor[i] := ORD(ByteBits(a1[i]) / ByteBits(a2[i]))
   END
 END Xor;

 PROCEDURE Not*(VAR not: U.Type; a: U.Type);
 VAR i: INTEGER;
 BEGIN
   FOR i := 0 TO LEN(a) - 1 DO
     not[i] := 0FFH - a[i]
   END
 END Not;

 PROCEDURE Shl*(VAR shl: U.Type; a: U.Type; shift: INTEGER);
 VAR bytes, bits, i, d, m: INTEGER;
 BEGIN
   ASSERT(0 <= shift);

   bytes := shift DIV 8;
   IF bytes >= LEN(shl) THEN
     shl := U.min
   ELSE
     bits := shift MOD 8;
     IF bits = 0 THEN
       FOR i := LEN(shl) - 1 TO bytes BY -1 DO
         shl[i] := a[i - bytes]
       END
     ELSE
       m := ORD({bits});
       d := ORD({8 - bits});
       FOR i := LEN(shl) - 1 TO bytes + 1 BY -1 DO
         shl[i] := a[i - bytes] * m MOD 100H + a[i - bytes - 1] DIV d
       END;
       shl[bytes] := a[0] * m MOD 100H
     END;
     FOR i := 0 TO bytes - 1 DO
       shl[i] := 0
     END
   END
 END Shl;

 PROCEDURE Shr*(VAR shr: U.Type; a: U.Type; shift: INTEGER);
 BEGIN
   ASSERT(0 <= shift);
   ASSERT(FALSE)
 END Shr;

END Uint32Bits.

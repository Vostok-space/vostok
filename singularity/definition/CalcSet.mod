Arithmetic and bits operations for SET as two's complement 32-bit integers.
Executable specification.

Copyright 2022,2024-2025 ComdivByZero

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Арифметические и битовые операции для SET как 32-битных целых в дополнительном коде.
Исполняемая спецификация.

MODULE CalcSet;

 CONST
  Len*  = 32;
  Last* = Len - 1;

  Min* = {Last};
  Max* = {0..Last-1};
  MaxU* = {0..Last};

 PROCEDURE ToInt*(s: SET): INTEGER;
 VAR i: INTEGER;
 BEGIN
  ASSERT(s # Min);
  IF Last IN s THEN
    i := -1 - ORD(-s)
  ELSE
    i := ORD(s)
  END
 RETURN
  i
 END ToInt;

 PROCEDURE FromInt*(i: INTEGER): SET;
 VAR s: SET; k: INTEGER;
 BEGIN
  IF i >= 0 THEN
    s := {}
  ELSE
    i := i + 7FFFFFFFH + 1;
    s := {Last}
  END;
  k := 0;
  WHILE i # 0 DO
    IF ODD(i) THEN
      INCL(s, k)
    END;
    INC(k);
    i := i DIV 2
  END
 RETURN
  s
 END FromInt;

 PROCEDURE ToByte*(s: SET; i: INTEGER): INTEGER;
 VAR b: INTEGER;
 BEGIN
  ASSERT(i IN {0 .. 3});

  b := ASR(ORD(s - {31}), i*8) MOD 100H
     + ORD((31 IN s) & (i = 3)) * 80H;

  ASSERT((0 <= b) & (b < 100H))
 RETURN
  b
 END ToByte;

 PROCEDURE ToBytes*(s: SET; VAR bytes: ARRAY OF BYTE);
 VAR i, v: INTEGER;
 BEGIN
  ASSERT(LEN(bytes) >= 4);

  v := ORD(s - {31});
  FOR i := 0 TO 2 DO
    bytes[i] := v MOD 100H;
    v := v DIV 100H;
  END;
  bytes[3] := v + ORD(31 IN s) * 80H
 END ToBytes;

 PROCEDURE FromByte*(b: BYTE; i: INTEGER): SET;
 VAR s: SET;
 BEGIN
  ASSERT(i IN {0 .. 3});
  s := {};
  i := i * 8;
  WHILE b # 0 DO
    IF ODD(b) THEN INCL(s, i) END;
    b := b DIV 2;
    INC(i)
  END
 RETURN
  s
 END FromByte;

 PROCEDURE FromBytes*(bytes: ARRAY OF BYTE): SET;
 VAR s: SET; i: INTEGER;
 BEGIN
  ASSERT(LEN(bytes) >= 4);
  s := FromByte(bytes[0], 0);
  FOR i := 1 TO 3 DO
    s := s + FromByte(bytes[i], i)
  END
 RETURN
  s
 END FromBytes;

 (* Logical shift left *)
 PROCEDURE Lsl*(s: SET; n: INTEGER): SET;
 VAR r: SET; i: INTEGER;
 BEGIN
  ASSERT(n >= 0);
  r := {};
  IF n < Len THEN
    FOR i := n TO Last DO
      IF i - n IN s THEN
        INCL(r, i)
      END
    END
  END
 RETURN
  r
 END Lsl;

 (* Logical shift right *)
 PROCEDURE Lsr*(s: SET; n: INTEGER): SET;
 VAR r: SET; i: INTEGER;
 BEGIN
  ASSERT((0 <= n) & (n <= Last));
  r := {};
  FOR i := Last - n TO 0 BY -1 DO
    IF i + n IN s THEN
      INCL(r, i)
    END
  END
 RETURN
  r
 END Lsr;

 (* Arithmetic shift right *)
 PROCEDURE Asr*(s: SET; n: INTEGER): SET;
 VAR r: SET; i, l: INTEGER;
 BEGIN
  ASSERT((0 <= n) & (n <= Last));
  r := {};
  l := Last - n;
  FOR i := 0 TO l DO
    IF i + n IN s THEN
      INCL(r, i)
    END
  END;
  IF Last IN s THEN
    FOR i := l + 1 TO Last DO
      INCL(r, i)
    END
  END
 RETURN
  r
 END Asr;

 (* Rotate right *)
 PROCEDURE Ror*(s: SET; n: INTEGER): SET;
 BEGIN
  ASSERT(n >= 0);
  n := n MOD Len
 RETURN
  Lsr(s, n) + Lsl(s, Len - n)
 END Ror;

 PROCEDURE WrapInc*(s: SET): SET;
 VAR i: INTEGER;
 BEGIN
  i := 0;
  WHILE (i < 32) & (i IN s) DO
    EXCL(s, i);
    INC(i)
  END;
  IF i <= Last THEN
    INCL(s, i)
  END
 RETURN
  s
 END WrapInc;

 PROCEDURE WrapDec*(s: SET): SET;
 VAR i: INTEGER; ns: SET;
 BEGIN
  i := 0;
  ns := -s;
  WHILE (i <= Last) & (i IN ns) DO
    INCL(s, i);
    INC(i)
  END;
  IF i <= Last THEN
    EXCL(s, i)
  END
 RETURN
  s
 END WrapDec;

 PROCEDURE WrapNeg*(s: SET): SET;
 RETURN
  WrapInc(-s)
 END WrapNeg;

 PROCEDURE AddWithCarry*(a1, a2: SET; VAR carry: INTEGER): SET;
 VAR i, c: INTEGER; s: SET;
 BEGIN
  ASSERT(carry IN {0..1});
  c := carry + 1;
  s := {};
  FOR i := 0 TO Last DO
    c := c DIV 2 + ORD(i IN a1) + ORD(i IN a2);
    IF ODD(c) THEN
      INCL(s, i)
    END
  END;
  carry := c DIV 2
 RETURN
  s
 END AddWithCarry;

 PROCEDURE WrapAddWithCarry*(a1, a2: SET; c: INTEGER): SET;
 BEGIN
  ASSERT(c IN {0..1})
 RETURN
  AddWithCarry(a1, a2, c)
 END WrapAddWithCarry;

 PROCEDURE WrapAdd*(a1, a2: SET): SET;
 RETURN
  WrapAddWithCarry(a1, a2, 0)
 END WrapAdd;

 PROCEDURE WrapSub*(a1, a2: SET): SET;
 RETURN
  WrapAddWithCarry(a1, -a2, 1)
 END WrapSub;

 PROCEDURE WrapMulU*(m1, m2: SET): SET;
 VAR i: INTEGER; p: SET;
 BEGIN
  p := {};
  FOR i := 0 TO Last DO
    IF i IN m2 THEN
      p := WrapAdd(p, Lsl(m1, i))
    END
  END
 RETURN
  p
 END WrapMulU;

 PROCEDURE WrapMul*(m1, m2: SET): SET;
 VAR cs: BOOLEAN; p: SET;
 BEGIN
  cs := Last IN m1;
  IF cs THEN
    m1 := WrapNeg(m1)
  END;
  IF Last IN m2 THEN
    m2 := WrapNeg(m2);
    cs := ~cs
  END;
  p := WrapMulU(m1, m2);
  IF cs THEN
    p := WrapNeg(p)
  END
 RETURN
  p
 END WrapMul;

 PROCEDURE CmpU*(a, b: SET): INTEGER;
 VAR d, i: INTEGER;
 BEGIN
  IF a = b THEN
    d := 0
  ELSE
    i := Last;
    b := -(a / b);
    WHILE i IN b DO DEC(i) END;
    d := ORD(i IN a) * 2 - 1
  END
 RETURN
  d
 END CmpU;

 PROCEDURE Cmp*(a, b: SET): INTEGER;
 VAR d, i: INTEGER;
 BEGIN
  IF a = b THEN
    d := 0
  ELSIF (Last IN a) # (Last IN b) THEN
    d := ORD(Last IN b) * 2 - 1
  ELSE
    i := Last - 1;
    b := -(a / b);
    WHILE i IN b DO DEC(i) END;
    d := ORD(i IN a) * 2 - 1
  END
 RETURN
  d
 END Cmp;

 PROCEDURE DivModU*(d, s: SET; VAR mod: SET): SET;
 VAR i, n: INTEGER; e: SET;

  PROCEDURE Ge(a, b: SET; l, n: INTEGER): BOOLEAN;
  BEGIN
    ASSERT((0 <= n) & (n <= Last));
    ASSERT((0 <= l) & (l <= Last));

    WHILE (n > 0) & ((l IN a) = (n IN b)) DO DEC(n); DEC(l) END
  RETURN
    (l IN a) OR ~(n IN b)
  END Ge;

  PROCEDURE Sub(a, b: SET; l, n: INTEGER): SET;
  VAR i, d: INTEGER;
  BEGIN
    ASSERT((0 <= n) & (n <= Last));
    ASSERT((0 <= l) & (l <= Last));

    DEC(l, n);
    d := 0;
    FOR i := 0 TO n DO
      d := d DIV 2 + ORD(l IN a) - ORD(i IN b);
      IF ODD(d) THEN
        INCL(a, l)
      ELSE
        EXCL(a, l)
      END;
      INC(l)
    END;
    IF l < Len THEN
      EXCL(a, l)
    END
  RETURN
    a
  END Sub;

 BEGIN
  ASSERT(s # {});

  e := {};
  IF d # {} THEN
    IF s = {} THEN
      n := -1
    ELSE
      n := Last; WHILE ~(n IN s) DO DEC(n) END
    END;

    i := Last;
    WHILE ~(i IN d) & (i >= n) DO DEC(i) END;
    WHILE i >= n DO
      IF Ge(d, s, i, n) THEN
        d := Sub(d, s, i, n);
        INCL(e, i - n);
        DEC(i)
      ELSIF i > n THEN
        DEC(i);
        d := Sub(d, s, i, n);
        INCL(e, i - n)
      ELSE
        DEC(i)
      END;
      WHILE (i >= 0) & ~(i IN d) & (i >= n) DO DEC(i) END;
    END
  END;
  mod := d
 RETURN
  e
 END DivModU;

 PROCEDURE DivU*(d, s: SET): SET;
 VAR mod: SET;
 RETURN
  DivModU(d, s, mod)
 END DivU;

 PROCEDURE ModU*(d, s: SET): SET;
 VAR mod: SET;
 BEGIN
  d := DivModU(d, s, mod)
 RETURN
  mod
 END ModU;

 PROCEDURE DivMod*(d, s: SET; VAR mod: SET): SET;
 VAR m: SET; c: INTEGER;
 BEGIN
  IF ~(Last IN d) THEN
    IF ~(Last IN s) THEN
      (* d>=0, s>=0; d, mod := d DIV s *)
      d := DivModU(d, s, mod)
    ELSE
      (* d>=0, s<0; d, m := (d - 1) DIV (-s); d := -1 - d; mod := s + 1 + m *)
      d := -DivModU(WrapDec(d), WrapNeg(s), m);
      c := 1;
      mod := AddWithCarry(s, m, c)
    END
  ELSE
    IF ~(Last IN s) THEN
      (* d<0, s>=0; d, m := (-1 - d) DIV s; d := -1 - d; mod := s + (-1 - m) *)
      d := -DivModU(-d, s, m);
      mod := WrapAdd(s, -m)
    ELSE
      (* d<0, s<0; d, m := (-d) DIV (-s); mod := -m *)
      d := DivModU(WrapNeg(d), WrapNeg(s), m);
      mod := WrapNeg(m)
    END
  END
 RETURN
  d
 END DivMod;

 PROCEDURE Div*(d, s: SET): SET;
 VAR mod: SET;
 RETURN
  DivMod(d, s, mod)
 END Div;

 PROCEDURE Mod*(d, s: SET): SET;
 VAR mod: SET;
 BEGIN
  d := DivMod(d, s, mod)
 RETURN
  mod
 END Mod;

END CalcSet.

Real numbers converter to 0X-terminated chars

Copyright 2021,2023,2025 ComdivByZero

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

MODULE RealToCharz;

  IMPORT ArrayFill, ArrayCopy, Real10, Int10 := MathPowerInt10;

  PROCEDURE Digit(i: INTEGER): CHAR;
  BEGIN
    ASSERT((0 <= i) & (i < 10))
  RETURN
    CHR(ORD("0") + i)
  END Digit;

  PROCEDURE Exp*(VAR str: ARRAY OF CHAR; VAR ofs: INTEGER; x: REAL; n: INTEGER): BOOLEAN;
  VAR s: ARRAY 32 OF CHAR;
      i, e, se, dE, eLen, lim: INTEGER;
      sign, ok: BOOLEAN;

    PROCEDURE Exponent(VAR s: ARRAY OF CHAR; VAR i: INTEGER; len, sign: INTEGER; e: INTEGER);
    VAR l: INTEGER;
    BEGIN
      IF len > 0 THEN
        l := i + len;
        i := l;

        REPEAT
          s[l] := Digit(e MOD 10);
          e := e DIV 10;
          DEC(l)
        UNTIL e = 0;
        IF sign < 0 THEN
          s[l] := "-";
          DEC(l)
        END;
        s[l] := "E"
      END
    END Exponent;

    PROCEDURE Significand(VAR s: ARRAY OF CHAR; VAR i: INTEGER; x: REAL; l: INTEGER; VAR dE: INTEGER);
    VAR d, d1, n: INTEGER; p10, xp: REAL;
      PROCEDURE Inc(VAR s: ARRAY OF CHAR; VAR i, dE: INTEGER);
      VAR j: INTEGER;
      BEGIN
        j := i;
        WHILE s[j] = "9" DO
          DEC(j)
        END;
        DEC(j, ORD(s[j] = "."));
        IF s[j] # "9" THEN
          s[j] := CHR(ORD(s[j]) + 1);
        ELSE
          s[j] := "1";
          INC(j, 2);
          s[j] := "0";
          dE := 1
        END;
        i := j
      END Inc;

      PROCEDURE Digits(VAR s: ARRAY OF CHAR; i, n, d: INTEGER);
      VAR k: INTEGER;
      BEGIN
        ASSERT(d >= 0);
        FOR k := n - 1 TO 0 BY -1 DO
          ASSERT(d >= 0);
          s[i + k] := Digit(d MOD 10);
          d := d DIV 10
        END;
        ASSERT(d = 0)
      END Digits;
    BEGIN
      INC(i);
      n := l - i;
      IF n > 9 THEN n := 9 END;
      ASSERT(x >= 0.0);
      xp := x * FLT(Int10.val[n - 1]);
      d := FLOOR(xp);
      Digits(s, i, n, d);
      s[i - 1] := s[i];
      s[i] := ".";
      INC(i, n);
      IF i < l THEN
        p10 := FLT(Int10.val[l - i]);
        xp := x * (1.E8 * p10) - FLT(d) * p10;
        IF xp >= 0.0 THEN
          d1 := FLOOR(xp)
        ELSE (* из-за погрешности *)
          d1 := 0
        END;
        Digits(s, i, l - i, d1);

        x := x * (1.E9 * p10) - FLT(d) *  FLT(Int10.val[l - i + 1]) - FLT(d1 * 10);
        i := l - 1;
      ELSE
        x := x * FLT(Int10.val[n]) - FLT(d) * 10.0
      END;
      
      dE := 0;
      IF 5.0 <= x THEN
        Inc(s, i, dE)
      ELSE
        WHILE s[i] = "0" DO
          DEC(i)
        END
      END
    END Significand;

  BEGIN
    ASSERT(n >= 0);
    ASSERT((0 <= ofs) & (ofs < LEN(str)));

    sign := x < 0.0;
    i := ORD(sign);
    IF sign THEN
      s[0] := "-";
      x := -x
    END;
    IF x # x THEN
      ArrayCopy.Chars(s, i, "NaN", 0, 3);
      INC(i, 2)
    ELSIF x = 0.0 THEN
      ArrayCopy.Chars(s, i, "0.0", 0, 3);
      INC(i, 2)
    ELSE
      Real10.Unpk(x, se);
      e := ABS(se);
      IF e = 0 THEN
        eLen := 0
      ELSE
        IF e < 10 THEN
          eLen := 2
        ELSIF e < 100 THEN
          eLen := 3
        ELSE
          eLen := 4
        END;
        INC(eLen, ORD(se < 0))
      END;
      IF n = 0 THEN
        lim := 17
      ELSE
        lim := n - eLen;
        IF lim < 3 THEN lim := 3 END
      END;
      Significand(s, i, x, lim, dE);
      IF s[i] # "." THEN
        ;
      ELSIF e # 0 THEN
        DEC(i)
      ELSE
        INC(i)
      END;
      IF se > 0 THEN
        Exponent(s, i, eLen, 1, e + dE)
      ELSE
        Exponent(s, i, eLen, -1, e - dE)
      END
    END;
    INC(i);
    IF n > i THEN
      n := n - i
    ELSE
      n := 0
    END;

    ok := n + i < LEN(str) - ofs;
    IF ok THEN
      ArrayFill.Char(str, ofs, " ", n);
      ArrayCopy.Chars(str, ofs + n, s, 0, i);
      INC(ofs, i + n);
      str[ofs] := 0X
    END
  RETURN
    ok
  END Exp;

END RealToCharz.

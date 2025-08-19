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

  IMPORT ArrayFill, ArrayCopy, Real10;

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
    BEGIN
      IF len > 0 THEN
        s[i + 1] := "E";
        INC(i, 2);
        IF sign > 0 THEN
          s[i] := "+"
        ELSE
          s[i] := "-"
        END;
        INC(i, len - 2);
        REPEAT
          s[i] := Digit(e MOD 10);
          e := e DIV 10;
          DEC(i)
        UNTIL e = 0;
        INC(i, len - 2)
      END
    END Exponent;

    PROCEDURE Significand(VAR s: ARRAY OF CHAR; VAR i: INTEGER; x: REAL; l: INTEGER; VAR dE: INTEGER);
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
    BEGIN
      s[i] := Digit(FLOOR(x));
      INC(i);
      s[i] := ".";
      REPEAT
        x := (x - FLT(FLOOR(x))) * 10.0;
        INC(i);
        s[i] := Digit(FLOOR(x))
      UNTIL i >= l;
      dE := 0;
      IF 0.5 <= x - FLT(FLOOR(x)) THEN
        Inc(s, i, dE)
      ELSE
        WHILE s[i] = "0" DO
          DEC(i)
        END;
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
      IF e > 308 THEN
        ArrayCopy.Chars(s, i, "inf", 0, 3);
        INC(i, 2)
      ELSE
        IF e = 0 THEN
          eLen := 0
        ELSIF e < 10 THEN
          eLen := 3
        ELSIF e < 100 THEN
          eLen := 4
        ELSE
          eLen := 5
        END;
        IF n = 0 THEN
          lim := 16
        ELSE
          lim := n - eLen
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

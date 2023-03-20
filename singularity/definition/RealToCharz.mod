Real numbers converter to 0X-terminated chars

Copyright 2021,2023 ComdivByZero

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

  IMPORT ArrayFill, ArrayCopy;

  PROCEDURE Digit(i: INTEGER): CHAR;
  BEGIN
    ASSERT((0 <= i) & (i < 10))
  RETURN
    CHR(ORD("0") + i)
  END Digit;

  PROCEDURE Exp*(VAR str: ARRAY OF CHAR; VAR ofs: INTEGER; x: REAL; n: INTEGER): BOOLEAN;
  VAR s: ARRAY 32 OF CHAR;
      i, e, eLen, lim: INTEGER;
      eSign: CHAR;
      sign, ok: BOOLEAN;
      x0: REAL;

    PROCEDURE ExtractExp(VAR x: REAL; VAR sign: CHAR; VAR len: INTEGER): INTEGER;
    VAR e: INTEGER; tens: REAL;
    BEGIN
      e := 1;
      tens := 10.0;
      IF x < 1.0 THEN
        sign := "-";
        WHILE x * tens < 1.0 DO
          INC(e);
          tens := tens * 10.0
        END;
        x := x * tens
      ELSIF 10.0 <= x THEN
        sign := "+";
        WHILE (x / tens >= 10.0) & (e <= 308) DO
          INC(e);
          tens := tens * 10.0
        END;
        x := x / tens
      ELSE ASSERT((1.0 <= x) & (x < 10.0));
        e := 0
      END;
      IF e = 0 THEN
        len := 0
      ELSIF e < 10 THEN
        len := 3
      ELSIF e < 100 THEN
        len := 4
      ELSE
        len := 5
      END
    RETURN
      e
    END ExtractExp;

    PROCEDURE Exponent(VAR s: ARRAY OF CHAR; VAR i: INTEGER; len: INTEGER; sign: CHAR; e: INTEGER);
    BEGIN
      IF len > 0 THEN
        s[i + 1] := "E";
        INC(i, 2);
        s[i] := sign;
        INC(i, len - 2);
        REPEAT
          s[i] := Digit(e MOD 10);
          e := e DIV 10;
          DEC(i)
        UNTIL e = 0;
        INC(i, len - 2)
      END
    END Exponent;

    PROCEDURE Significand(VAR s: ARRAY OF CHAR; VAR i: INTEGER; x: REAL; l: INTEGER);
      PROCEDURE Inc(VAR s: ARRAY OF CHAR; VAR i: INTEGER);
      VAR j: INTEGER;
      BEGIN
        j := i;
        WHILE s[j] = "9" DO
          DEC(j)
        END;
        IF (s[j] = ".") & (s[j - 1] # "9") THEN
          DEC(j)
        END;
        IF s[j] # "9" THEN
          s[j] := CHR(ORD(s[j]) + 1);
          IF s[j + 1] = "." THEN
            s[j + 2] := "0";
            i := j + 1
          ELSE
            i := j
          END
        END
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
      IF 0.5 <= x - FLT(FLOOR(x)) THEN
        Inc(s, i)
      ELSE
        WHILE s[i] = "0" DO
          DEC(i)
        END;
      END
    END Significand;

  BEGIN
    ASSERT(n >= 0);
    ASSERT((0 <= ofs) & (ofs < LEN(str)));

    x0 := x;
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
      e := ExtractExp(x, eSign, eLen);
      IF e > 308 THEN
        ArrayCopy.Chars(s, i, "inf", 0, 3);
        INC(i, 2)
      ELSE
        IF n = 0 THEN
          lim := 16
        ELSE
          lim := n - eLen
        END;
        Significand(s, i, x, lim);
        IF s[i] # "." THEN
          ;
        ELSIF e # 0 THEN
          DEC(i)
        ELSE
          INC(i)
        END;
        Exponent(s, i, eLen, eSign, e)
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

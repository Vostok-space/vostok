Integers converter to 0X-terminated chars

Copyright 2021 ComdivByZero

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

MODULE IntToChars0X;

  IMPORT Hx := Hex, ArrayFill;

  PROCEDURE DCount(VAR v: INTEGER; VAR neg: BOOLEAN): INTEGER;
  CONST T = 1000;
  VAR c, i: INTEGER;
  BEGIN
    i := v;
    IF i >= 0 THEN
      c := 0;
      neg := FALSE;
    ELSE
      neg := TRUE;
      c := 1;
      i := -i;
      v := i
    END;
    IF i < 10 * T THEN
      IF i < 100 THEN
        INC(c, 2 - ORD(i < 10))
      ELSE
        INC(c, 4 - ORD(i < T))
      END
    ELSIF i < T * T THEN
      INC(c, 6 - ORD(i < 100 * T))
    ELSIF i < 100 * T * T THEN
      INC(c, 8 - ORD(i < 10 * T * T))
    ELSE
      INC(c, 10 - ORD(i < T * T * T))
    END
  RETURN
    c
  END DCount;

  PROCEDURE HCount(VAR v: INTEGER; VAR neg: BOOLEAN): INTEGER;
  CONST T = 10000H;
  VAR c, i: INTEGER;
  BEGIN
    i := v;
    IF i >= 0 THEN
      c := 0;
      neg := FALSE;
    ELSE
      neg := TRUE;
      c := 1;
      i := -i;
      v := i
    END;
    IF i < 10000H THEN
      IF i < 100H THEN
        INC(c, 2 - ORD(i < 10H))
      ELSE
        INC(c, 4 - ORD(i < 1000H))
      END
    ELSIF i < 100H * T THEN
      INC(c, 6 - ORD(i < 10H * T))
    ELSE
      INC(c, 8 - ORD(i < 1000H * T))
    END
  RETURN
    c
  END HCount;

  PROCEDURE DecCount*(i: INTEGER): INTEGER;
  VAR neg: BOOLEAN;
  RETURN
    DCount(i, neg)
  END DecCount;

  PROCEDURE HexCount*(i: INTEGER): INTEGER;
  VAR neg: BOOLEAN;
  RETURN
    HCount(i, neg)
  END HexCount;

  PROCEDURE Dec*(VAR str: ARRAY OF CHAR; VAR ofs: INTEGER; value, n: INTEGER): BOOLEAN;
  VAR s, i, c: INTEGER; ok, neg: BOOLEAN;
  BEGIN
    ASSERT((0 <= ofs) & (ofs < LEN(str)));
    s := ofs;

    c := DCount(value, neg);
    IF c < n THEN
      c := n
    END;
    ok := s < LEN(str) - c;
    IF ok THEN
      i := s + c;
      ofs := i;
      str[i] := 0X;

      REPEAT
        DEC(i);
        str[i] := CHR(ORD("0") + value MOD 10);
        value := value DIV 10
      UNTIL value = 0;

      IF neg THEN
        DEC(i);
        str[i] := "-"
      END;

      ArrayFill.Char(str, s, " ", i - s)
    END
  RETURN
    ok
  END Dec;

  PROCEDURE Hex*(VAR str: ARRAY OF CHAR; VAR ofs: INTEGER; value, n: INTEGER): BOOLEAN;
  VAR s, i, c: INTEGER; ok, neg: BOOLEAN;
  BEGIN
    ASSERT((0 <= ofs) & (ofs < LEN(str)));
    s := ofs;

    c := HCount(value, neg);
    IF c < n THEN
      c := n
    END;
    ok := s < LEN(str) - c;
    IF ok THEN
      i := s + c;
      ofs := i;
      str[i] := 0X;

      REPEAT
        DEC(i);
        str[i] := Hx.To(value MOD 10H);
        value := value DIV 10H
      UNTIL value = 0;

      IF neg THEN
        DEC(i);
        str[i] := "-"
      END;

      ArrayFill.Char(str, s, 0X, i - s)
    END
  RETURN
    ok
  END Hex;

END IntToChars0X.

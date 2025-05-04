(* Converter of hexadecimal digit in CHAR to INTEGER and vise versa
 *
 * Copyright 2019,2021,2025 ComdivByZero
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
MODULE HexDigit;

CONST
  Range* = {0 .. 0FH};

  PROCEDURE From*(d: INTEGER): CHAR;
  BEGIN
    ASSERT(d IN Range);
    IF d < 0AH THEN
      INC(d, ORD("0"))
    ELSE
      INC(d, ORD("A") - 10)
    END
  RETURN
    CHR(d)
  END From;

  PROCEDURE Is*(ch: CHAR): BOOLEAN;
  RETURN
      ("0" <= ch) & (ch <= "9")
   OR ("A" <= ch) & (ch <= "F")
  END Is;

  PROCEDURE WithLowCaseIs*(ch: CHAR): BOOLEAN;
  RETURN
      ("0" <= ch) & (ch <= "9")
   OR ("A" <= ch) & (ch <= "F")
   OR ("a" <= ch) & (ch <= "f")
  END WithLowCaseIs;

  PROCEDURE ToInt*(d: CHAR): INTEGER;
  VAR i: INTEGER;
  BEGIN
    ASSERT(Is(d));

    IF d <= "9" THEN
      i := ORD(d) - ORD("0")
    ELSE
      i := ORD(d) - (ORD("A") - 10)
    END
  RETURN
    i
  END ToInt;

  PROCEDURE WithLowCaseToInt*(d: CHAR): INTEGER;
  VAR i: INTEGER;
  BEGIN
    ASSERT(WithLowCaseIs(d));

    IF d <= "9" THEN
      i := ORD(d) - ORD("0")
    ELSIF d <= "F" THEN
      i := ORD(d) - (ORD("A") - 10)
    ELSE
      i := ORD(d) - (ORD("a") - 10)
    END
  RETURN
    i
  END WithLowCaseToInt;

END HexDigit.

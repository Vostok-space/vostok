(* Converter of hexadecimal in char to integer and vise versa
 *
 * Copyright 2019,2021 ComdivByZero
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
MODULE Hex;

CONST
  Range* = {0 .. 0FH};

  PROCEDURE To*(d: INTEGER): CHAR;
  BEGIN
    ASSERT(d IN Range);
    IF d < 0AH THEN
      INC(d, ORD("0"))
    ELSE
      INC(d, ORD("A") - 10)
    END;
  RETURN
    CHR(d)
  END To;

  PROCEDURE InRange*(ch: CHAR): BOOLEAN;
  RETURN
      ("0" <= ch) & (ch <= "9")
   OR ("A" <= ch) & (ch <= "F")
  END InRange;

  PROCEDURE InRangeWithLowCase*(ch: CHAR): BOOLEAN;
  RETURN
      ("0" <= ch) & (ch <= "9")
   OR ("A" <= ch) & (ch <= "F")
   OR ("a" <= ch) & (ch <= "f")
  END InRangeWithLowCase;

  PROCEDURE From*(d: CHAR): INTEGER;
  VAR i: INTEGER;
  BEGIN
    ASSERT(InRange(d));

    IF ("0" <= d) & (d <= "9") THEN
      i := ORD(d) - ORD("0")
    ELSE ASSERT(("A" <= d) & (d <= "F"));
      i := 10 + ORD(d) - ORD("A")
    END;
  RETURN
    i
  END From;

  PROCEDURE FromWithLowCase*(d: CHAR): INTEGER;
  VAR i: INTEGER;
  BEGIN
    ASSERT(InRangeWithLowCase(d));

    IF ("0" <= d) & (d <= "9") THEN
      i := ORD(d) - ORD("0")
    ELSIF ("A" <= d) & (d <= "F") THEN
      i := 10 + ORD(d) - ORD("A")
    ELSE
      i := 10 + ORD(d) - ORD("a")
    END;
  RETURN
    i
  END FromWithLowCase;

END Hex.

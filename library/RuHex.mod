Converter of a hexadecimal in chars to integer and vise versa, using АБВГДЕ instead of ABCDEF

Copyright 2023 ComdivByZero

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

MODULE RuHex;

 CONST
  Range* = {0 .. 0FH};

 PROCEDURE To*(d: INTEGER; VAR s: ARRAY OF CHAR; VAR ofs: INTEGER);
 VAR i: INTEGER;
 BEGIN
  ASSERT(d IN Range);

  i := ofs;
  IF d < 10 THEN
    s[i] := CHR(ORD("0") + d);
    INC(i)
  ELSE
    (* А - это D090 в UTF-8 *)
    s[i] := 0D0X;
    s[i + 1] := CHR(d + (90H - 10));
    INC(i, 2)
  END;
  ofs := i
 END To;

 PROCEDURE InRange*(s: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
 VAR c: CHAR; y: BOOLEAN;
 BEGIN
  c := s[ofs];
  y := ("0" <= c) & (c <= "9");
  IF (c = 0D0X) & (ofs < LEN(s)) THEN
    c := s[ofs + 1];
    y := (90X <= c) & (c <= 95X)
  END
 RETURN
  y
 END InRange;

 PROCEDURE InRangeWithLowCase*(s: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
 VAR c: CHAR; y: BOOLEAN;
 BEGIN
  c := s[ofs];
  y := ("0" <= c) & (c <= "9");
  IF (c = 0D0X) & (ofs < LEN(s)) THEN
    c := s[ofs + 1];
    y := ( 90X <= c) & (c <=  95X)
      OR (0B0X <= c) & (c <= 0B5X)
  END
 RETURN
  y
 END InRangeWithLowCase;

 PROCEDURE From*(s: ARRAY OF CHAR; VAR ofs: INTEGER; VAR code: INTEGER): BOOLEAN;
 VAR c: CHAR; ok: BOOLEAN; i: INTEGER;
 BEGIN
  i := ofs;
  
  c := s[i];
  IF c <= "9" THEN
    ok := "0" <= c;
    IF ok THEN
      ofs := i + 1;
      code := ORD(c) - ORD("0")
    END
  ELSIF (c = 0D0X) & (i < LEN(s)) THEN
    c := s[i + 1];
    ok := (90X <= c) & (c <= 95X);
    IF ok THEN
      ofs := i + 2;
      code := ORD(c) - (90H - 10)
    END
  ELSE
    ok := FALSE
  END
 RETURN
  ok
 END From;

 PROCEDURE FromWithLowCase*(s: ARRAY OF CHAR; VAR ofs: INTEGER; VAR code: INTEGER): BOOLEAN;
 VAR c: CHAR; ok: BOOLEAN; i: INTEGER;
 BEGIN
  i := ofs;
  
  c := s[i];
  ok := FALSE;
  IF c <= "9" THEN
    ok := "0" <= c;
    IF ok THEN
      ofs := i + 1;
      code := ORD(c) - ORD("0")
    END
  ELSIF (c = 0D0X) & (i < LEN(s) - 1) THEN
    c := s[i + 1];
    IF c <= 95X THEN
      ok := 90X <= c;
      IF ok THEN
        ofs := i + 2;
        code := ORD(c) - (90H - 10)
      ELSIF (0B0X <= c) & (c <= 0B5X) THEN
        ok := TRUE;
        ofs := i + 2;
        code := ORD(c) - (0B0H - 10)
      END
    END
  END
 RETURN
  ok
 END FromWithLowCase;

END RuHex.

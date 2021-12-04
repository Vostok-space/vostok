(* Operations with arrays of chars, which represent 0-terminated strings
 * Copyright 2018-2019,2021 ComdivByZero
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

(* Модуль для работы с цепочками литер, имитирующих строки.
 * Конец строки определяется по положению 0-го символа с
 * наименьшим индексом
 *)
MODULE Chars0X;

  IMPORT Utf8, ArrayFill;

  PROCEDURE CalcLen*(str: ARRAY OF CHAR; ofs: INTEGER): INTEGER;
  VAR i: INTEGER;
  BEGIN
    i := ofs;
    WHILE str[i] # Utf8.Null DO
      INC(i)
    END
  RETURN
    i - ofs
  END CalcLen;

  PROCEDURE Fill*(ch: CHAR; count: INTEGER;
                  VAR dest: ARRAY OF CHAR; VAR ofs: INTEGER): BOOLEAN;
  VAR ok: BOOLEAN;
      i, end: INTEGER;
  BEGIN
    ASSERT(ch # Utf8.Null);
    ASSERT((0 <= ofs) & (ofs < LEN(dest)));

    ok := count < LEN(dest) - ofs;
    i := ofs;
    IF ok THEN
      end := i + count;
      WHILE i < end DO
        dest[i] := ch;
        INC(i)
      END;
      ofs := i
    END;
    dest[i] := Utf8.Null
  RETURN
    ok
  END Fill;

  PROCEDURE CopyAtMost*(VAR dest: ARRAY OF CHAR; VAR destOfs: INTEGER;
                        src: ARRAY OF CHAR; VAR srcOfs: INTEGER;
                        atMost: INTEGER): BOOLEAN;
  VAR ok: BOOLEAN;
      s, d, lim: INTEGER;
  BEGIN
    s := srcOfs;
    d := destOfs;
    ASSERT((0 <= s) & (s <= LEN(src)));
    ASSERT((0 <= d) & (d <= LEN(dest)));
    ASSERT(0 <= atMost);

    lim := d + atMost;
    IF LEN(dest) - 1 < lim THEN
      lim := LEN(dest) - 1
    END;

    WHILE (d < lim) & (src[s] # Utf8.Null) DO
      dest[d] := src[s];
      INC(d);
      INC(s)
    END;

    ok := (d = destOfs + atMost) OR (src[s] = Utf8.Null);

    dest[d] := Utf8.Null;
    srcOfs  := s;
    destOfs := d;

    ASSERT((destOfs = LEN(dest)) OR (dest[destOfs] = Utf8.Null))
  RETURN
    ok
  END CopyAtMost;

  PROCEDURE Copy*(VAR dest: ARRAY OF CHAR; VAR destOfs: INTEGER;
                  src: ARRAY OF CHAR; VAR srcOfs: INTEGER)
                 : BOOLEAN;
  VAR s, d: INTEGER;
  BEGIN
    s := srcOfs;
    d := destOfs;
    ASSERT((0 <= s) & (s <= LEN(src)));
    ASSERT((0 <= d) & (d <= LEN(dest)));

    WHILE (d < LEN(dest) - 1) & (src[s] # Utf8.Null) DO
      dest[d] := src[s];
      INC(d);
      INC(s)
    END;

    dest[d] := Utf8.Null;
    srcOfs  := s;
    destOfs := d;

    ASSERT(dest[destOfs] = Utf8.Null)
  RETURN
    src[s] = Utf8.Null
  END Copy;

  PROCEDURE CopyChars*(VAR dest: ARRAY OF CHAR; VAR destOfs: INTEGER;
                       src: ARRAY OF CHAR; srcOfs, srcEnd: INTEGER): BOOLEAN;
  VAR s, d: INTEGER; ok: BOOLEAN;
  BEGIN
    s := srcOfs;
    d := destOfs;
    ASSERT((0 <= s) & (s <= LEN(src)));
    ASSERT((0 <= d) & (d <= LEN(dest)));
    ASSERT(s <= srcEnd);

    ok := d < LEN(dest) - (srcEnd - srcOfs);
    IF ~ok THEN
      srcEnd := LEN(dest) - (srcEnd - srcOfs) - 1
    END;
    WHILE s < srcEnd DO
      ASSERT(src[s] # Utf8.Null);
      dest[d] := src[s];
      INC(d);
      INC(s)
    END;
    dest[d] := Utf8.Null;
    destOfs := d
  RETURN
    ok
  END CopyChars;

  PROCEDURE CopyCharsUntil*(VAR dest: ARRAY OF CHAR; VAR destOfs: INTEGER;
                            src: ARRAY OF CHAR; VAR srcOfs: INTEGER; until: CHAR): BOOLEAN;
  VAR s, d: INTEGER;
  BEGIN
    s := srcOfs;
    d := destOfs;
    ASSERT((0 <= s) & (s < LEN(src)));
    ASSERT((0 <= d) & (d <= LEN(dest)));

    WHILE (src[s] # until) & (d < LEN(dest) - 1) DO
      ASSERT(src[s] # Utf8.Null);
      dest[d] := src[s];
      INC(d);
      INC(s)
    END;
    dest[d] := Utf8.Null;
    destOfs := d;
    srcOfs  := s
  RETURN
    src[s] = until
  END CopyCharsUntil;

  PROCEDURE CopyString*(VAR dest: ARRAY OF CHAR; VAR ofs: INTEGER;
                        src: ARRAY OF CHAR): BOOLEAN;
  VAR i: INTEGER;
  BEGIN
    i := 0
  RETURN
    Copy(dest, ofs, src, i)
  END CopyString;

  PROCEDURE Set*(VAR dest: ARRAY OF CHAR; src: ARRAY OF CHAR): BOOLEAN;
  VAR i, j: INTEGER;
  BEGIN
    i := 0;
    j := 0;
  RETURN
    Copy(dest, i, src, j)
  END Set;

  PROCEDURE CopyChar*(VAR dest: ARRAY OF CHAR; VAR ofs: INTEGER;
                      ch: CHAR; n: INTEGER): BOOLEAN;
  VAR ok: BOOLEAN; i: INTEGER;
  BEGIN
    i := ofs;
    ASSERT(0 <= n);
    ASSERT(ch # Utf8.Null);
    ASSERT((0 <= i) & (i < LEN(dest)));
    ok := i < LEN(dest) - n;
    IF ok THEN
      ArrayFill.Char(dest, i, ch, n);
      INC(i, n)
    END;
    dest[i] := Utf8.Null;
    ofs := i
  RETURN
    ok
  END CopyChar;

  PROCEDURE PutChar*(VAR dest: ARRAY OF CHAR; VAR ofs: INTEGER;
                     ch: CHAR): BOOLEAN;
  RETURN
    CopyChar(dest, ofs, ch, 1)
  END PutChar;

  PROCEDURE SearchChar*(str: ARRAY OF CHAR; VAR pos: INTEGER; c: CHAR): BOOLEAN;
  VAR i: INTEGER;
  BEGIN
    i := pos;
    ASSERT((0 <= i) & (i < LEN(str)));

    WHILE (str[i] # c) & (str[i] # Utf8.Null) DO
      INC(i)
    END;
    pos := i
  RETURN
    str[i] = c
  END SearchChar;

  PROCEDURE SearchCharLast*(str: ARRAY OF CHAR; VAR pos: INTEGER; c: CHAR): BOOLEAN;
  VAR i, j: INTEGER;
  BEGIN
    i := pos;
    ASSERT((0 <= i) & (i < LEN(str)));

    j := -1;
    WHILE str[i] # Utf8.Null DO
      IF str[i] = c THEN
        j := i
      END;
      INC(i)
    END;
    pos := j
  RETURN
    0 <= j
  END SearchCharLast;

  PROCEDURE Trim*(VAR str: ARRAY OF CHAR; ofs: INTEGER): INTEGER;
  VAR i, j: INTEGER;
  BEGIN
    i := ofs;
    WHILE (str[i] = " ") OR (str[i] = Utf8.Tab) DO
      INC(i)
    END;
    IF ofs < i THEN
      j := ofs;
      WHILE str[i] # Utf8.Null DO
        str[j] := str[i];
        INC(j); INC(i)
      END
    ELSE
      j := ofs + CalcLen(str, ofs)
    END;
    WHILE (ofs < j) & ((str[j - 1] = " ") OR (str[j - 1] = Utf8.Tab)) DO
      DEC(j)
    END;
    str[j] := Utf8.Null
  RETURN
    j - ofs
  END Trim;

END Chars0X.

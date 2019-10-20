(*  Transformations from cyrillic Utf-8 to ASC II
 *  Copyright (C) 2016, 2019 ComdivByZero
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published
 *  by the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)
MODULE Utf8Transform;

  IMPORT Strings := StringStore, Chars0X;

  PROCEDURE Puts(VAR buf: ARRAY OF CHAR; VAR i: INTEGER; str: ARRAY OF CHAR);
  BEGIN
    ASSERT(Chars0X.CopyString(buf, i, str))
  END Puts;

  PROCEDURE Escape*(VAR buf: ARRAY OF CHAR; VAR i: INTEGER;
                    VAR it: Strings.Iterator);
  VAR u: INTEGER;
    PROCEDURE Hex(d: INTEGER): CHAR;
    VAR c: INTEGER;
    BEGIN
      IF d < 10 THEN
        ASSERT(0 <= d);
        c := ORD("0") + d
      ELSE ASSERT(d <= 0FH);
        c := ORD("A") + d - 0AH
      END
      RETURN CHR(c)
    END Hex;
  BEGIN
    REPEAT
      CASE it.char OF
        "0" .. "9":
        buf[i] := it.char;
        INC(i)
      | "_":
        buf[i    ] := "_";
        buf[i + 1] := "_";
        INC(i, 2)
      | 0D0X, 0D1X:
        u := ORD(it.char) MOD 32;
        ASSERT(Strings.IterNext(it));
        u := u * 64 + ORD(it.char) MOD 64;
        Puts(buf, i, "\u0");
        buf[i    ] := Hex(u DIV 100H);
        buf[i + 1] := Hex(u DIV 10H MOD 10H);
        buf[i + 2] := Hex(u MOD 10H);
        INC(i, 3)
      END
    UNTIL ~Strings.IterNext(it);
  END Escape;

  PROCEDURE Transliterate*(VAR buf: ARRAY OF CHAR; VAR i: INTEGER;
                           VAR it: Strings.Iterator);
  BEGIN
    ASSERT((0 <= i) & (i < LEN(buf)));
    REPEAT
      CASE it.char OF
        "0" .. "9":
        buf[i] := it.char;
        INC(i)
      | "_":
        buf[i    ] := "_";
        buf[i + 1] := "_";
        INC(i, 2)
      | 0D0X:
        ASSERT(Strings.IterNext(it));
        CASE ORD(it.char) - 90H + 15 OF
            0: Puts(buf, i, "_Yo")
        |   3: Puts(buf, i, "_E1")
        |   5: Puts(buf, i, "_I1")
        |   6: Puts(buf, i, "_Yi")
        |  13: Puts(buf, i, "_W")

        |  15: Puts(buf, i, "_A")
        |  16: Puts(buf, i, "_B")
        |  17: Puts(buf, i, "_V")
        |  18: Puts(buf, i, "_G")
        |  19: Puts(buf, i, "_D")
        |  20: Puts(buf, i, "_Ye")
        |  21: Puts(buf, i, "_Zh")
        |  22: Puts(buf, i, "_Z")
        |  23: Puts(buf, i, "_I")
        |  24: Puts(buf, i, "_Y")
        |  25: Puts(buf, i, "_K")
        |  26: Puts(buf, i, "_L")
        |  27: Puts(buf, i, "_M")
        |  28: Puts(buf, i, "_N")
        |  29: Puts(buf, i, "_O")
        |  30: Puts(buf, i, "_P")
        |  31: Puts(buf, i, "_R")
        |  32: Puts(buf, i, "_S")
        |  33: Puts(buf, i, "_T")
        |  34: Puts(buf, i, "_U")
        |  35: Puts(buf, i, "_F")
        |  36: Puts(buf, i, "_Kh")
        |  37: Puts(buf, i, "_Ts")
        |  38: Puts(buf, i, "_Ch")
        |  39: Puts(buf, i, "_Sh")
        |  40: Puts(buf, i, "_Shch")
        |  41: Puts(buf, i, "_Tz")
        |  42: Puts(buf, i, "_Yy")
        |  43: Puts(buf, i, "_Mz")
        |  44: Puts(buf, i, "_E")
        |  45: Puts(buf, i, "_Yu")
        |  46: Puts(buf, i, "_Ya")
        |  47: Puts(buf, i, "_a")
        |  48: Puts(buf, i, "_b")
        |  49: Puts(buf, i, "_v")
        |  50: Puts(buf, i, "_g")
        |  51: Puts(buf, i, "_d")
        |  52: Puts(buf, i, "_ye")

        |  53: Puts(buf, i, "_zh")
        |  54: Puts(buf, i, "_z")
        |  55: Puts(buf, i, "_i")
        |  56: Puts(buf, i, "_y")
        |  57: Puts(buf, i, "_k")
        |  58: Puts(buf, i, "_l")
        |  59: Puts(buf, i, "_m")
        |  60: Puts(buf, i, "_n")
        |  61: Puts(buf, i, "_o")
        |  62: Puts(buf, i, "_p")
        END
      | 0D1X:
        ASSERT(Strings.IterNext(it));
        CASE ORD(it.char) - 80H OF
           0: Puts(buf, i, "_r")
        |  1: Puts(buf, i, "_s")
        |  2: Puts(buf, i, "_t")
        |  3: Puts(buf, i, "_u")
        |  4: Puts(buf, i, "_f")
        |  5: Puts(buf, i, "_kh")
        |  6: Puts(buf, i, "_ts")
        |  7: Puts(buf, i, "_ch")
        |  8: Puts(buf, i, "_sh")
        |  9: Puts(buf, i, "_shch")
        | 10: Puts(buf, i, "_tz")
        | 11: Puts(buf, i, "_yy")
        | 12: Puts(buf, i, "_mz")
        | 13: Puts(buf, i, "_e")
        | 14: Puts(buf, i, "_yu")
        | 15: Puts(buf, i, "_ya")

        | 17: Puts(buf, i, "_yo")
        | 20: Puts(buf, i, "_e1")
        | 22: Puts(buf, i, "_i1")
        | 23: Puts(buf, i, "_yi")
        | 30: Puts(buf, i, "_w")
        END
      | 0D2X:
        CASE ORD(it.char) - 90H OF
          0: Puts(buf, i, "_G1")
        | 1: Puts(buf, i, "_g1")
        END
      END
    UNTIL ~Strings.IterNext(it);
  END Transliterate;

END Utf8Transform.

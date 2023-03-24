(*  Transformations from cyrillic Utf-8 to ASC II
 *
 *  Copyright (C) 2016,2019,2021,2023 ComdivByZero
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

  IMPORT Strings := StringStore, Charz, Hex;

  PROCEDURE Puts(VAR buf: ARRAY OF CHAR; VAR i: INTEGER; str: ARRAY OF CHAR);
  BEGIN
    ASSERT(Charz.CopyString(buf, i, str))
  END Puts;

  PROCEDURE EscapeCyrillic*(VAR buf: ARRAY OF CHAR; VAR ofs: INTEGER;
                            VAR it: Strings.Iterator);
  VAR u, i: INTEGER;
  BEGIN
    i := ofs;
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
        buf[i    ] := Hex.To(u DIV 100H);
        buf[i + 1] := Hex.To(u DIV 10H MOD 10H);
        buf[i + 2] := Hex.To(u MOD 10H);
        INC(i, 3)
      END
    UNTIL ~Strings.IterNext(it);
    ofs := i
  END EscapeCyrillic;

  PROCEDURE EscapeForC90*(VAR buf: ARRAY OF CHAR; VAR ofs: INTEGER;
                          VAR it: Strings.Iterator);
  VAR i: INTEGER; lastEscaped: BOOLEAN;
  BEGIN
    i := ofs;
    lastEscaped := FALSE;
    REPEAT
      IF (it.char < 80X)
      & ~(lastEscaped & Hex.InRangeWithLowCase(it.char))
      THEN
        buf[i] := it.char;
        INC(i);
        lastEscaped := FALSE
      ELSE
        buf[i] := "\";
        buf[i + 1] := "x";
        buf[i + 2] := Hex.To(ORD(it.char) DIV 10H);
        buf[i + 3] := Hex.To(ORD(it.char) MOD 10H);
        INC(i, 4);
        lastEscaped := FALSE
      END
    UNTIL ~Strings.IterNext(it);
    ofs := i
  END EscapeForC90;

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
        Puts(buf, i, "__")
      | "'":
        Puts(buf, i, "qh")
      | 0D0X:
        ASSERT(Strings.IterNext(it));
        CASE ORD(it.char) - 90H + 15 OF
            0: Puts(buf, i, "Yo")
        |   3: Puts(buf, i, "Ye")
        |   5: Puts(buf, i, "Iq")
        |   6: Puts(buf, i, "Yi")
        |  13: Puts(buf, i, "Uq")

        |  15: Puts(buf, i, "A")
        |  16: Puts(buf, i, "B")
        |  17: Puts(buf, i, "V")
        |  18: Puts(buf, i, "G")
        |  19: Puts(buf, i, "D")
        |  20: Puts(buf, i, "E")
        |  21: Puts(buf, i, "Zh")
        |  22: Puts(buf, i, "Z")
        |  23: Puts(buf, i, "I")
        |  24: Puts(buf, i, "J")
        |  25: Puts(buf, i, "K")
        |  26: Puts(buf, i, "L")
        |  27: Puts(buf, i, "M")
        |  28: Puts(buf, i, "N")
        |  29: Puts(buf, i, "O")
        |  30: Puts(buf, i, "P")
        |  31: Puts(buf, i, "R")
        |  32: Puts(buf, i, "S")
        |  33: Puts(buf, i, "T")
        |  34: Puts(buf, i, "U")
        |  35: Puts(buf, i, "F")
        |  36: Puts(buf, i, "X")
        |  37: Puts(buf, i, "C")
        |  38: Puts(buf, i, "Ch")
        |  39: Puts(buf, i, "Sh")
        |  40: Puts(buf, i, "Shh")
        |  41: Puts(buf, i, "Qq")
        |  42: Puts(buf, i, "Yq")
        |  43: Puts(buf, i, "Q")
        |  44: Puts(buf, i, "Eq")
        |  45: Puts(buf, i, "Yu")
        |  46: Puts(buf, i, "Ya")
        |  47: Puts(buf, i, "a")
        |  48: Puts(buf, i, "b")
        |  49: Puts(buf, i, "v")
        |  50: Puts(buf, i, "g")
        |  51: Puts(buf, i, "d")
        |  52: Puts(buf, i, "e")
        |  53: Puts(buf, i, "zh")
        |  54: Puts(buf, i, "z")
        |  55: Puts(buf, i, "i")
        |  56: Puts(buf, i, "j")
        |  57: Puts(buf, i, "k")
        |  58: Puts(buf, i, "l")
        |  59: Puts(buf, i, "m")
        |  60: Puts(buf, i, "n")
        |  61: Puts(buf, i, "o")
        |  62: Puts(buf, i, "p")
        END
      | 0D1X:
        ASSERT(Strings.IterNext(it));
        CASE ORD(it.char) - 80H OF
           0: Puts(buf, i, "r")
        |  1: Puts(buf, i, "s")
        |  2: Puts(buf, i, "t")
        |  3: Puts(buf, i, "u")
        |  4: Puts(buf, i, "f")
        |  5: Puts(buf, i, "x")
        |  6: Puts(buf, i, "c")
        |  7: Puts(buf, i, "ch")
        |  8: Puts(buf, i, "sh")
        |  9: Puts(buf, i, "shh")
        | 10: Puts(buf, i, "qq")
        | 11: Puts(buf, i, "yq")
        | 12: Puts(buf, i, "q")
        | 13: Puts(buf, i, "eq")
        | 14: Puts(buf, i, "yu")
        | 15: Puts(buf, i, "ya")

        | 17: Puts(buf, i, "yo")
        | 20: Puts(buf, i, "ye")
        | 22: Puts(buf, i, "iq")
        | 23: Puts(buf, i, "yi")
        | 30: Puts(buf, i, "uq")
        END
      | 0D2X:
        CASE ORD(it.char) - 90H OF
          0: Puts(buf, i, "Gh")
        | 1: Puts(buf, i, "gh")
        END
      END
    UNTIL ~Strings.IterNext(it);
  END Transliterate;

END Utf8Transform.

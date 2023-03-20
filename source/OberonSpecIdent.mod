(*  List of Oberon-07 keywords and predefined identifers
 *
 *  Copyright (C) 2016-2018,2020-2022 ComdivByZero
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
MODULE OberonSpecIdent;

  IMPORT Utf8, Strings := StringStore;

  CONST
    Array*          = 100;
    Begin*          = 101;
    By*             = 102;
    Case*           = 103;
    Const*          = 104;
    Div*            = 105;
    Do*             = 106;
    Else*           = 107;
    Elsif*          = 108;
    End*            = 109;
    False*          = 110;
    For*            = 111;
    If*             = 112;
    Import*         = 113;
    In*             = 114;
    Is*             = 115;
    Mod*            = 116;
    Module*         = 117;
    Nil*            = 118;
    Of*             = 119;
    Or*             = 120;
    Pointer*        = 121;
    Procedure*      = 122;
    Record*         = 123;
    Repeat*         = 124;
    Return*         = 125;
    Then*           = 126;
    To*             = 127;
    True*           = 128;
    Type*           = 129;
    Until*          = 130;
    Var*            = 131;
    While*          = 132;

    (* Предопределенные идентификаторы имеют стабильный порядок *)
    PredefinedFirst* = 200;
    Abs*        = 200;
    Asr*        = 201;
    Assert*     = 202;
    Boolean*    = 203;
    Byte*       = 204;
    Char*       = 205;
    Chr*        = 206;
    Dec*        = 207;
    Excl*       = 208;
    Floor*      = 209;
    Flt*        = 210;
    Inc*        = 211;
    Incl*       = 212;
    Integer*    = 213;
    Len*        = 214;
    LongInt*    = 215;
    LongSet*    = 216;
    Lsl*        = 217;
    New*        = 218;
    Odd*        = 219;
    Ord*        = 220;
    Pack*       = 221;
    Real*       = 222;
    Real32*     = 223;
    Ror*        = 224;
    Set*        = 225;
    Unpk*       = 226;

    (*SYSTEM*)
    SystemFirst* = 227;
    Adr*        = 227;
    Size*       = 228;
    Bit*        = 229;
    Get*        = 230;
    Put*        = 231;
    Copy*       = 232;
    SystemLast*  = 232;

    PredefinedLast* = 232;

  PROCEDURE Eq(str, buf: ARRAY OF CHAR; ind, end: INTEGER): BOOLEAN;
  VAR i, j: INTEGER;
  BEGIN
    ASSERT(buf[ind] = str[0]);
    ASSERT(LEN(str) <= LEN(buf) DIV 2);

    j := 1;
    i := ind + 1;
    WHILE buf[i] = str[j] DO
      INC(i); INC(j)
    ELSIF buf[i] = Utf8.NewPage DO
      i := 0
    END
  RETURN
    (buf[i] = Utf8.BackSpace) & (str[j] = Utf8.Null)
  END Eq;

  PROCEDURE O(VAR lex: INTEGER; str: ARRAY OF CHAR; l: INTEGER;
              buf: ARRAY OF CHAR; ind, end: INTEGER): BOOLEAN;
  VAR spec: BOOLEAN;
  BEGIN
    spec := Eq(str, buf, ind, end);
    IF spec THEN
      lex := l
    END
  RETURN
    spec
  END O;

  PROCEDURE T(VAR lex: INTEGER;
              s1: ARRAY OF CHAR; l1: INTEGER;
              s2: ARRAY OF CHAR; l2: INTEGER;
              buf: ARRAY OF CHAR; ind, end: INTEGER): BOOLEAN;
  VAR spec: BOOLEAN;
  BEGIN
    IF Eq(s1, buf, ind, end) THEN
      spec := TRUE;
      lex := l1
    ELSIF Eq(s2, buf, ind, end) THEN
      spec := TRUE;
      lex := l2
    ELSE
      spec := FALSE
    END
  RETURN
    spec
  END T;

  PROCEDURE IsModule*(VAR buf: ARRAY OF CHAR; ind, end: INTEGER): BOOLEAN;
  VAR save: CHAR; match: BOOLEAN;
  BEGIN
    match := "M" = buf[ind];
    IF match THEN
        save := buf[end];
        buf[end] := Utf8.BackSpace;
        match := Eq("MODULE", buf, ind, end);
        buf[end] := save
    END
  RETURN
    match
  END IsModule;

  PROCEDURE IsKeyWord*(VAR kw: INTEGER;
                       VAR buf: ARRAY OF CHAR; ind, end: INTEGER): BOOLEAN;
  VAR save: CHAR;
      spec: BOOLEAN;
  BEGIN
    save := buf[end];
    buf[end] := Utf8.BackSpace;
    CASE buf[ind] OF
     "A": spec := O(kw, "ARRAY", Array, buf, ind, end)
    |"B": spec := T(kw, "BEGIN", Begin, "BY", By, buf, ind, end)
    |"C": spec := T(kw, "CASE", Case, "CONST", Const, buf, ind, end)
    |"D": spec := T(kw, "DIV", Div, "DO", Do, buf, ind, end)
    |"E": spec := O(kw, "ELSE", Else, buf, ind, end)
               OR T(kw, "ELSIF", Elsif, "END", End, buf, ind, end)
    |"F": spec := T(kw, "FALSE", False, "FOR", For, buf, ind, end)
    |"I": spec := T(kw, "IF", If, "IMPORT", Import, buf, ind, end)
               OR T(kw, "IN", In, "IS", Is, buf, ind, end)
    |"M": spec := T(kw, "MOD", Mod, "MODULE", Module, buf, ind, end)
    |"N": spec := O(kw, "NIL", Nil, buf, ind, end)
    |"O": spec := T(kw, "OF", Of, "OR", Or, buf, ind, end)
    |"P": spec := T(kw, "POINTER", Pointer, "PROCEDURE", Procedure, buf, ind, end)
    |"R": spec := O(kw, "RECORD", Record, buf, ind, end)
               OR T(kw, "REPEAT", Repeat, "RETURN", Return, buf, ind, end)
    |"T": spec := T(kw, "THEN", Then, "TO", To, buf, ind, end)
               OR T(kw, "TRUE", True, "TYPE", Type, buf, ind, end)
    |"U": spec := O(kw, "UNTIL", Until, buf, ind, end)
    |"V": spec := O(kw, "VAR", Var, buf, ind, end)
    |"W": spec := O(kw, "WHILE", While, buf, ind, end)
    |0X .. 40X, "G", "H", "J" .. "L", "Q", "S", "X" .. 0FFX:
      spec := FALSE
    END;
    buf[end] := save
  RETURN
    spec
  END IsKeyWord;

  PROCEDURE IsPredefined*(VAR pd: INTEGER;
                          VAR buf: ARRAY OF CHAR; begin, end: INTEGER): BOOLEAN;
  VAR save: CHAR;
      spec: BOOLEAN;
  BEGIN
    save := buf[end];
    buf[end] := Utf8.BackSpace;
    CASE buf[begin] OF
     "A": spec := O(pd, "ABS", Abs, buf, begin, end)
               OR T(pd, "ASR", Asr, "ASSERT", Assert, buf, begin, end)
    |"B": spec := T(pd, "BOOLEAN", Boolean, "BYTE", Byte, buf, begin, end)
    |"C": spec := T(pd, "CHAR", Char, "CHR", Chr, buf, begin, end)
    |"D": spec := O(pd, "DEC", Dec, buf, begin, end)
    |"E": spec := O(pd, "EXCL", Excl, buf, begin, end)
    |"F": spec := T(pd, "FLOOR", Floor, "FLT", Flt, buf, begin, end)
    |"I": spec := O(pd, "INC", Inc, buf, begin, end)
               OR T(pd, "INCL", Incl, "INTEGER", Integer, buf, begin, end)
    |"L": spec := T(pd, "LEN", Len, "LSL", Lsl, buf, begin, end)
    |"N": spec := O(pd, "NEW", New, buf, begin, end)
    |"O": spec := T(pd, "ODD", Odd, "ORD", Ord, buf, begin, end)
    |"P": spec := O(pd, "PACK", Pack, buf, begin, end)
    |"R": spec := T(pd, "REAL", Real, "ROR", Ror, buf, begin, end)
    |"S": spec := O(pd, "SET", Set, buf, begin, end)
    |"U": spec := O(pd, "UNPK", Unpk, buf, begin, end)
    |"G", "H", "J", "K", "M", "Q", "T", "V" .. "Z", "a" .. "z", 0C0X..0FFX:
      spec := FALSE
    END;
    buf[end] := save
  RETURN
    spec
  END IsPredefined;

  PROCEDURE IsSystemProc*(VAR pd: INTEGER;
                          VAR buf: ARRAY OF CHAR; begin, end: INTEGER): BOOLEAN;
  VAR save: CHAR;
      spec: BOOLEAN;
  BEGIN
    save := buf[end];
    buf[end] := Utf8.BackSpace;
    CASE buf[begin] OF
     "A": spec := O(pd, "ADR", Adr, buf, begin, end)
    |"B": spec := O(pd, "BIT", Bit, buf, begin, end)
    |"C": spec := O(pd, "COPY", Copy, buf, begin, end)
    |"G": spec := O(pd, "GET", Get, buf, begin, end)
    |"P": spec := O(pd, "PUT", Put, buf, begin, end)
    |"S": spec := O(pd, "SIZE", Size, buf, begin, end)
    |"D" .. "F", "H" .. "O", "Q", "R", "T" .. "Z", "a" .. "z", 0C0X..0FFX:
      spec := FALSE
    END;
    buf[end] := save
  RETURN
    spec
  END IsSystemProc;

  PROCEDURE IsSpecName*(n: Strings.String): BOOLEAN;
  (* TODO *)
  RETURN
    FALSE
  END IsSpecName;

END OberonSpecIdent.

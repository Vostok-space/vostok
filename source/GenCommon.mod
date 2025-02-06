(*  Common subroutines for code-generators by Oberon-07 abstract syntax tree
 *
 *  Copyright (C) 2019,2024-2025 ComdivByZero
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
MODULE GenCommon;

IMPORT
  Text := TextGenerator, Strings := StringStore, Utf8Transform, Utf8, Hex,
  GenOptions,
  TranLim := TranslatorLimits;

  PROCEDURE Ident*(VAR gen: Text.Out; ident: Strings.String; identEnc: INTEGER);
  VAR buf: ARRAY TranLim.LenName * 6 + 2 OF CHAR;
      i: INTEGER; it: Strings.Iterator;
  BEGIN
    ASSERT(Strings.GetIter(it, ident, 0));
    i := 0;
    IF (identEnc = GenOptions.IdentEncSame) OR (it.char < 80X) THEN
      REPEAT
        buf[i] := it.char;
        INC(i);
        IF it.char = "_" THEN
          buf[i] := "_";
          INC(i)
        ELSIF it.char = "'" THEN
          buf[i - 1] := "_";
          buf[i    ] := "q";
          buf[i + 1] := "_";
          INC(i, 2)
        END
      UNTIL ~Strings.IterNext(it)
    ELSIF identEnc = GenOptions.IdentEncEscUnicode THEN
      Utf8Transform.EscapeCyrillic(buf, i, it)
    ELSE ASSERT(identEnc = GenOptions.IdentEncTranslit);
      Utf8Transform.Transliterate(buf, i, it)
    END;
    Text.Data(gen, buf, 0, i)
  END Ident;

  PROCEDURE Comment(VAR gen: Text.Out; opt: GenOptions.R; text: Strings.String;
                    open, close: ARRAY OF CHAR);
  VAR i: Strings.Iterator; prev: CHAR;
  BEGIN
    IF opt.comment & Strings.GetIter(i, text, 0) THEN
      REPEAT
        prev := i.char
      UNTIL ~Strings.IterNext(i)
        OR (prev = open[0]) & (i.char = "*")
        OR (prev = "*") & (i.char = close[1]);

      IF i.char = Utf8.Null THEN
        Text.Str(gen, open);
        Text.String(gen, text);
        Text.StrLn(gen, close)
      END
    END
  END Comment;

  PROCEDURE CommentC*(VAR out: Text.Out; opt: GenOptions.R; text: Strings.String);
  BEGIN
    Comment(out, opt, text, "/*", "*/")
  END CommentC;

  (* TODO позволить вложенные комментарии *)
  PROCEDURE CommentOberon*(VAR out: Text.Out; opt: GenOptions.R; text: Strings.String);
  BEGIN
    Comment(out, opt, text, "(*", "*)")
  END CommentOberon;

  PROCEDURE JString*(VAR g: Text.Out; w: Strings.String; char: INTEGER);
  VAR s: ARRAY 8 OF CHAR; len: INTEGER;
  BEGIN
    IF w.ofs >= 0 THEN
      Text.ScreeningString(g, w, FALSE)
    ELSE
      s[0] := Utf8.DQuote;
      s[1] := "\";
      len := 4;
      IF char = ORD("\") THEN
        s[2] := "\"
      ELSIF char = 0AH THEN
        s[2] := "n"
      ELSIF char = ORD(Utf8.DQuote) THEN
        s[2] := Utf8.DQuote
      ELSE
        s[2] := "u";
        s[3] := "0";
        s[4] := "0";
        s[5] := Hex.To(char DIV 10H);
        s[6] := Hex.To(char MOD 10H);
        len := 8
      END;
      s[len - 1] := Utf8.DQuote;
      Text.Data(g, s, 0, len)
    END

  END JString;

END GenCommon.

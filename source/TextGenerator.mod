(*  Formatted plain text generator
 *  Copyright (C) 2017,2019 ComdivByZero
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
MODULE TextGenerator;

IMPORT
	V,
	Utf8,
	Strings := StringStore, Chars0X,
	Stream  := VDataStream,
	Limits  := TypesLimits;

TYPE
	Out* = RECORD(V.Base)
		out: Stream.POut;
		len*: INTEGER;
		tabs: INTEGER;
		isNewLine: BOOLEAN
	END;

PROCEDURE Init*(VAR g: Out; out: Stream.POut);
BEGIN
	ASSERT(out # NIL);

	V.Init(g);
	g.tabs := 0;
	g.out := out;
	g.len := 0;
	g.isNewLine := FALSE
END Init;

PROCEDURE SetTabs*(VAR g: Out; d: Out);
BEGIN
	g.tabs := d.tabs
END SetTabs;

PROCEDURE CharFill*(VAR gen: Out; ch: CHAR; count: INTEGER);
VAR c: ARRAY 1 OF CHAR;
BEGIN
	ASSERT(0 <= count);
	c[0] := ch;
	WHILE count > 0 DO
		gen.len := gen.len + Stream.WriteChars(gen.out^, c, 0, 1);
		DEC(count)
	END
END CharFill;

PROCEDURE Char*(VAR gen: Out; ch: CHAR);
VAR c: ARRAY 1 OF CHAR;
BEGIN
	c[0] := ch;
	gen.len := gen.len + Stream.WriteChars(gen.out^, c, 0, 1);
END Char;

PROCEDURE NewLine(VAR gen: Out);
BEGIN
	IF gen.isNewLine THEN
		gen.isNewLine := FALSE;
		CharFill(gen, Utf8.Tab, gen.tabs)
	END
END NewLine;

PROCEDURE Str*(VAR gen: Out; str: ARRAY OF CHAR);
BEGIN
	NewLine(gen);
	gen.len := gen.len + Stream.WriteChars(gen.out^, str, 0, Chars0X.CalcLen(str, 0))
END Str;

PROCEDURE StrLn*(VAR gen: Out; str: ARRAY OF CHAR);
BEGIN
	NewLine(gen);
	gen.len := gen.len + Stream.WriteChars(gen.out^, str, 0, Chars0X.CalcLen(str, 0));
	gen.len := gen.len + Stream.WriteChars(gen.out^, Utf8.NewLine, 0, 1);
	gen.isNewLine := TRUE
END StrLn;

PROCEDURE Ln*(VAR gen: Out);
BEGIN
	gen.len := gen.len + Stream.WriteChars(gen.out^, Utf8.NewLine, 0, 1);
	gen.isNewLine := TRUE
END Ln;

PROCEDURE StrOpen*(VAR gen: Out; str: ARRAY OF CHAR);
BEGIN
	StrLn(gen, str);
	INC(gen.tabs)
END StrOpen;

PROCEDURE IndentOpen*(VAR gen: Out);
BEGIN
	INC(gen.tabs)
END IndentOpen;

PROCEDURE IndentClose*(VAR gen: Out);
BEGIN
	ASSERT(0 < gen.tabs);
	DEC(gen.tabs)
END IndentClose;

PROCEDURE StrClose*(VAR gen: Out; str: ARRAY OF CHAR);
BEGIN
	IndentClose(gen);
	Str(gen, str)
END StrClose;

PROCEDURE StrLnClose*(VAR gen: Out; str: ARRAY OF CHAR);
BEGIN
	IndentClose(gen);
	StrLn(gen, str)
END StrLnClose;

PROCEDURE StrIgnoreIndent*(VAR gen: Out; str: ARRAY OF CHAR);
BEGIN
	gen.len := gen.len + Stream.WriteChars(gen.out^, str, 0, Chars0X.CalcLen(str, 0))
END StrIgnoreIndent;

PROCEDURE String*(VAR gen: Out; word: Strings.String);
BEGIN
	NewLine(gen);
	gen.len := gen.len + Strings.Write(gen.out^, word)
END String;

PROCEDURE Data*(VAR g: Out; data: ARRAY OF CHAR; ofs, count: INTEGER);
BEGIN
	NewLine(g);
	g.len := g.len + Stream.WriteChars(g.out^, data, ofs, count)
END Data;

PROCEDURE ScreeningString*(VAR gen: Out; str: Strings.String);
VAR i, last: INTEGER;
	block: Strings.Block;
BEGIN
	NewLine(gen);
	block := str.block;
	i := str.ofs;
	last := i;
	ASSERT(block.s[i] = Utf8.DQuote);
	INC(i);
	WHILE block.s[i] = Utf8.NewPage DO
		gen.len := gen.len + Stream.WriteChars(gen.out^, block.s, last, i - last);
		block := block.next;
		i := 0;
		last := 0
	ELSIF block.s[i] = "\" DO
		gen.len := gen.len + Stream.WriteChars(gen.out^, block.s, last, i - last + 1);
		gen.len := gen.len + Stream.WriteChars(gen.out^, "\", 0, 1);
		INC(i);
		last := i
	ELSIF block.s[i] # Utf8.Null DO
		INC(i)
	END;
	ASSERT(block.s[i] = Utf8.Null);
	gen.len := gen.len + Stream.WriteChars(gen.out^, block.s, last, i - last)
END ScreeningString;

PROCEDURE Int*(VAR gen: Out; int: INTEGER);
VAR buf: ARRAY 14 OF CHAR;
	i: INTEGER;
	sign: BOOLEAN;
BEGIN
	NewLine(gen);
	sign := int < 0;
	IF sign THEN
		int := -int
	END;
	i := LEN(buf);
	REPEAT
		DEC(i);
		buf[i] := CHR(ORD("0") + int MOD 10);
		int := int DIV 10
	UNTIL int = 0;
	IF sign THEN
		DEC(i);
		buf[i] := "-"
	END;
	gen.len := gen.len + Stream.WriteChars(gen.out^, buf, i, LEN(buf) - i)
END Int;

PROCEDURE Real*(VAR gen: Out; real: REAL);
BEGIN
	NewLine(gen);
	Str(gen, "Real not implemented")
END Real;

PROCEDURE ToHex(d: INTEGER): CHAR;
BEGIN
	ASSERT(d IN {0 .. 0FH});
	IF d < 10 THEN
		INC(d, ORD("0"))
	ELSE
		INC(d, ORD("A") - 10)
	END
	RETURN CHR(d)
END ToHex;

PROCEDURE HexSeparateHighBit*(VAR gen: Out; v: INTEGER; highBit: BOOLEAN);
VAR buf: ARRAY 8 OF CHAR; i: INTEGER;
BEGIN
	ASSERT(v >= 0);

	i := LEN(buf) - 1;
	buf[i] := ToHex(v MOD 10H);
	v := v DIV 10H + ORD(highBit) * 8000000H;
	WHILE v # 0 DO
		DEC(i);
		buf[i] := ToHex(v MOD 10H);
		v := v DIV 10H;
	END;
	gen.len := gen.len + Stream.WriteChars(gen.out^, buf, i, LEN(buf) - i)
END HexSeparateHighBit;

PROCEDURE Hex*(VAR gen: Out; v: INTEGER);
BEGIN
	IF v < 0 THEN
		HexSeparateHighBit(gen, v + Limits.IntegerMax + 1, TRUE)
	ELSE
		HexSeparateHighBit(gen, v, FALSE)
	END
END Hex;

PROCEDURE Set*(VAR gen: Out; VAR set: SET);
BEGIN
	HexSeparateHighBit(gen, ORD(set - {Limits.SetMax}), Limits.SetMax IN set)
END Set;

END TextGenerator.

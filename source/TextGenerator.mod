(*  Formatted plain text generator
 *  Copyright (C) 2017,2019-2020,2022-2023 ComdivByZero
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
	Utf8, Hexadecimal := Hex, RuHexadecimal := RuHex,
	Strings := StringStore, Charz,
	Stream  := VDataStream,
	Limits  := TypesLimits,
	ArrayFill;

TYPE
	Options* = RECORD(V.Base)
		indent*: RECORD
			char*: CHAR;
			count*: INTEGER
		END
	END;

	Out* = RECORD(V.Base)
		out: Stream.POut;
		opt: Options;
		len*, lines*: INTEGER;
		indent: INTEGER;
		isNewLine: BOOLEAN;
		defered: ARRAY 1 OF CHAR
	END;

PROCEDURE DefaultOptions*(VAR opt: Options);
BEGIN
	V.Init(opt);
	opt.indent.char := " ";
	opt.indent.count := 2
END DefaultOptions;

PROCEDURE Init*(VAR g: Out; out: Stream.POut);
BEGIN
	ASSERT(out # NIL);

	V.Init(g);
	DefaultOptions(g.opt);
	g.indent := 0;
	g.out := out;
	g.len := 0;
	g.lines := 0;
	g.isNewLine := FALSE;
	g.defered[0] := Utf8.Null
END Init;

PROCEDURE SetOptions*(VAR g: Out; opt: Options);
BEGIN
	g.opt := opt
END SetOptions;

PROCEDURE TransiteOptions*(VAR g: Out; d: Out);
BEGIN
	g.opt := d.opt;
	g.indent := d.indent
END TransiteOptions;

PROCEDURE Write(VAR g: Out; str: ARRAY OF CHAR; ofs, size: INTEGER);
BEGIN
	INC(g.len, Stream.WriteChars(g.out^, str, ofs, size))
END Write;

PROCEDURE CharFill*(VAR g: Out; ch: CHAR; count: INTEGER);
VAR c: ARRAY 32 OF CHAR;
BEGIN
	ASSERT(0 <= count);
	IF count < LEN(c) THEN
		ArrayFill.Char(c, 0, ch, count);
	ELSE
		ArrayFill.Char(c, 0, ch, LEN(c));
		WHILE count > LEN(c) DO
			Write(g, c, 0, LEN(c));
			DEC(count, LEN(c))
		END
	END;
	Write(g, c, 0, count)
END CharFill;

PROCEDURE IndentInNewLine(VAR g: Out);
VAR len: INTEGER;
BEGIN
	IF g.isNewLine THEN
		g.isNewLine := FALSE;
		len := g.indent;
		IF g.opt.indent.char # " " THEN
			len := len * g.opt.indent.count
		ELSIF len > 2 THEN
			len := 2 + (len - 2) * g.opt.indent.count
		END;
		CharFill(g, g.opt.indent.char, len)
	END
END IndentInNewLine;

PROCEDURE Char*(VAR g: Out; ch: CHAR);
VAR c: ARRAY 1 OF CHAR;
BEGIN
	IndentInNewLine(g);
	c[0] := ch;
	Write(g, c, 0, 1)
END Char;

PROCEDURE DeferChar*(VAR g: Out; ch: CHAR);
BEGIN
	ASSERT(ch # Utf8.Null);
	ASSERT(g.defered[0] = Utf8.Null);

	g.defered[0] := ch
END DeferChar;

PROCEDURE CancelDeferedOrWriteChar*(VAR g: Out; ch: CHAR);
BEGIN
	IF g.defered[0] = Utf8.Null THEN
		Char(g, ch)
	ELSE (* взаимозачёт *)
		g.defered[0] := Utf8.Null
	END
END CancelDeferedOrWriteChar;

PROCEDURE NewLine(VAR g: Out);
BEGIN
	IndentInNewLine(g);
	IF g.defered[0] # Utf8.Null THEN
		Write(g, g.defered, 0, 1);
		g.defered[0] := Utf8.Null
	END
END NewLine;

PROCEDURE Str*(VAR g: Out; str: ARRAY OF CHAR);
BEGIN
	NewLine(g);
	Write(g, str, 0, Charz.CalcLen(str, 0))
END Str;

PROCEDURE StrLn*(VAR g: Out; str: ARRAY OF CHAR);
BEGIN
	NewLine(g);
	Write(g, str, 0, Charz.CalcLen(str, 0));
	Write(g, Utf8.NewLine, 0, 1);
	INC(g.lines);
	g.isNewLine := TRUE
END StrLn;

PROCEDURE Ln*(VAR g: Out);
BEGIN
	Write(g, Utf8.NewLine, 0, 1);
	INC(g.lines);
	g.isNewLine := TRUE
END Ln;

PROCEDURE StrOpen*(VAR g: Out; str: ARRAY OF CHAR);
BEGIN
	StrLn(g, str);
	INC(g.indent)
END StrOpen;

PROCEDURE IndentOpen*(VAR g: Out);
BEGIN
	INC(g.indent)
END IndentOpen;

PROCEDURE IndentClose*(VAR g: Out);
BEGIN
	ASSERT(0 < g.indent);
	DEC(g.indent)
END IndentClose;

PROCEDURE StrClose*(VAR g: Out; str: ARRAY OF CHAR);
BEGIN
	IndentClose(g);
	Str(g, str)
END StrClose;

PROCEDURE StrLnClose*(VAR g: Out; str: ARRAY OF CHAR);
BEGIN
	IndentClose(g);
	StrLn(g, str)
END StrLnClose;

PROCEDURE LnStrClose*(VAR g: Out; str: ARRAY OF CHAR);
BEGIN
	Ln(g);
	IndentClose(g);
	Str(g, str)
END LnStrClose;

PROCEDURE StrIgnoreIndent*(VAR g: Out; str: ARRAY OF CHAR);
BEGIN
	Write(g, str, 0, Charz.CalcLen(str, 0))
END StrIgnoreIndent;

PROCEDURE String*(VAR g: Out; word: Strings.String);
BEGIN
	NewLine(g);
	INC(g.len, Strings.Write(g.out^, word))
END String;

PROCEDURE Data*(VAR g: Out; data: ARRAY OF CHAR; ofs, count: INTEGER);
BEGIN
	NewLine(g);
	Write(g, data, ofs, count)
END Data;

PROCEDURE EscapeHighChar(VAR buf: ARRAY OF CHAR; c: CHAR);
BEGIN
	buf[0] := "\";
	buf[1] := "x";
	buf[2] := Hexadecimal.To(ORD(c) DIV 10H);
	buf[3] := Hexadecimal.To(ORD(c) MOD 10H)
END EscapeHighChar;

PROCEDURE ScreeningString*(VAR g: Out; str: Strings.String; escapeHighChars: BOOLEAN);
VAR i, last: INTEGER; buf: ARRAY 4 OF CHAR; lastEscaped: BOOLEAN;
	block: Strings.Block;
BEGIN
	NewLine(g);
	block := str.block;
	i := str.ofs;
	last := i;
	ASSERT(block.s[i] = Utf8.DQuote);
	INC(i);
	lastEscaped := FALSE;
	WHILE block.s[i] = Utf8.NewPage DO
		Write(g, block.s, last, i - last);
		block := block.next;
		i := 0;
		last := 0
	ELSIF block.s[i] = "\" DO
		Write(g, block.s, last, i - last + 1);
		Write(g, "\", 0, 1);
		INC(i);
		last := i;
		lastEscaped := FALSE
	ELSIF escapeHighChars
	   & (   (block.s[i] >= 80X)
	      OR lastEscaped & Hexadecimal.InRangeWithLowCase(block.s[i])
	     )
	DO
		Write(g, block.s, last, i - last);
		EscapeHighChar(buf, block.s[i]);
		Write(g, buf, 0, 4);
		INC(i);
		last := i;
		lastEscaped := TRUE
	ELSIF block.s[i] # Utf8.Null DO
		INC(i);
		lastEscaped := FALSE
	END;
	ASSERT(block.s[i] = Utf8.Null);
	Write(g, block.s, last, i - last)
END ScreeningString;

PROCEDURE Int*(VAR g: Out; int: INTEGER);
VAR buf: ARRAY 14 OF CHAR;
	i: INTEGER;
	sign: BOOLEAN;
BEGIN
	NewLine(g);
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
	Write(g, buf, i, LEN(buf) - i)
END Int;

PROCEDURE IntBy3v0*(VAR g: Out; int: INTEGER; sep: CHAR);
VAR buf: ARRAY 14 OF CHAR; i, l, d, digit: INTEGER;
BEGIN
	NewLine(g);

	IF int >= 0 THEN
		i := 0
	ELSE
		buf[0] := "-";
		i := 1;
		int := -int
	END;

	d := 1000000000;
	l := 10;
	WHILE int < d DO
		d := d DIV 10;
		DEC(l)
	END;

	i := 0;
	REPEAT
		IF (i > 0) & (l MOD 3 = 0) THEN
			buf[i] := sep;
			INC(i)
		END;

		digit := int DIV d;
		buf[i] := CHR(ORD("0") + digit);
		DEC(int, digit * d);
		INC(i);
		DEC(l);
		int := int DIV 10;
	UNTIL int = 0;
	Write(g, buf, 0, i)
END IntBy3v0;

PROCEDURE IntBy3*(VAR g: Out; int: INTEGER; sep: CHAR);
VAR buf: ARRAY 14 OF CHAR; i : INTEGER; sign: BOOLEAN;
BEGIN
	NewLine(g);

	sign := int < 0;
	IF sign THEN int := -int END;

	i := LEN(buf);
	WHILE int >= 1000 DO
		DEC(i); buf[i] := CHR(ORD("0") + int MOD 10); int := int DIV 10;
		DEC(i); buf[i] := CHR(ORD("0") + int MOD 10); int := int DIV 10;
		DEC(i); buf[i] := CHR(ORD("0") + int MOD 10); int := int DIV 10;
		DEC(i); buf[i] := sep;
	END;

	WHILE int >= 10 DO
		DEC(i); buf[i] := CHR(ORD("0") + int MOD 10); int := int DIV 10
	END;
	DEC(i); buf[i] := CHR(ORD("0") + int);

	IF sign THEN DEC(i); buf[i] := "-" END;

	Write(g, buf, i, LEN(buf) - i)
END IntBy3;

PROCEDURE Real*(VAR g: Out; real: REAL);
BEGIN
	NewLine(g);
	Str(g, "Real not implemented")
END Real;

PROCEDURE RealString*(VAR g: Out; s: Strings.String);
VAR i, c: INTEGER; b: Strings.Block; ch, last: CHAR; sep, buf: ARRAY 1 OF CHAR;
BEGIN
	NewLine(g);

	i := s.ofs + 1;
	b := s.block;
	c := 1;
	WHILE b.s[i] = Utf8.NewPage DO
		b := b.next; i := 0
	ELSIF b.s[i] # "." DO
		INC(c); INC(i)
	END;

	sep[0] := "`";

	i := s.ofs;
	b := s.block;
	Write(g, b.s, i, 1);
	INC(i); ch := b.s[i];
	WHILE ch = Utf8.NewPage DO
		b := b.next;
		i := 0; ch := b.s[i]
	ELSIF ch # "." DO
		DEC(c);
		IF c MOD 3 = 0 THEN
			Write(g, sep, 0, 1);
		END;
		Write(g, b.s, i, 1);
		INC(i); ch := b.s[i]
	END;

	buf[0] := ",";
	Write(g, buf, 0, 1);

	INC(i); ch := b.s[i];
	c := 0;
	IF ~(("0" <= ch) & (ch <= "9")) THEN
		buf[0] := "0";
		Write(g, buf, 0, 1)
	ELSE
		last := ch;
		WHILE ("0" <= ch) & (ch <= "9") DO
			IF (c MOD 3 = 0) & (c > 0) THEN
				Write(g, sep, 0, 1)
			END;
			INC(c);
			Write(g, b.s, i, 1);
			last := ch;
			INC(i); ch := b.s[i]
		ELSIF ch = Utf8.NewPage DO
			b := b.next;
			i := 0; ch := b.s[i]
		END;
		IF last # "0" THEN
			Write(g, "…", 0, 3)
		END
	END;
	WHILE ch = Utf8.NewPage DO
		b := b.next;
		i := 0; ch := b.s[i]
	ELSIF ch # Utf8.Null DO
		Write(g, b.s, i, 1);
		INC(i); ch := b.s[i]
	END
END RealString;

PROCEDURE HexSeparateHighBit*(VAR g: Out; v: INTEGER; highBit: BOOLEAN);
VAR buf: ARRAY 8 OF CHAR; i: INTEGER;
BEGIN
	ASSERT(v >= 0);

	i := LEN(buf) - 1;
	buf[i] := Hexadecimal.To(v MOD 10H);
	v := v DIV 10H + ORD(highBit) * 8000000H;
	WHILE v # 0 DO
		DEC(i);
		buf[i] := Hexadecimal.To(v MOD 10H);
		v := v DIV 10H;
	END;
	Write(g, buf, i, LEN(buf) - i)
END HexSeparateHighBit;

PROCEDURE Hex*(VAR g: Out; v: INTEGER);
BEGIN
	IF v < 0 THEN
		HexSeparateHighBit(g, v + Limits.IntegerMax + 1, TRUE)
	ELSE
		HexSeparateHighBit(g, v, FALSE)
	END
END Hex;

PROCEDURE Set*(VAR g: Out; VAR set: SET);
BEGIN
	HexSeparateHighBit(g, ORD(set - {Limits.SetMax}), Limits.SetMax IN set)
END Set;

PROCEDURE RuHexSeparateHighBit*(VAR g: Out; v: INTEGER; highBit: BOOLEAN);
VAR buf: ARRAY 17 OF CHAR; i: INTEGER;

	PROCEDURE Four(VAR buf: ARRAY OF CHAR; VAR i: INTEGER; val: INTEGER);
	BEGIN
		ASSERT((0 <= val) & (val < 10000H));

		RuHexadecimal.To(val DIV 1000H, buf, i);
		RuHexadecimal.To(val DIV 100H MOD 10H, buf, i);
		RuHexadecimal.To(val DIV 10H MOD 10H, buf, i);
		RuHexadecimal.To(val MOD 10H, buf, i)
	END Four;
BEGIN
	ASSERT(v >= 0);

	i := 0;
	IF v < 10000H THEN
		Four(buf, i, v)
	ELSE
		Four(buf, i, v DIV 10000H);
		buf[i] := "`";
		INC(i);
		Four(buf, i, v MOD 10000H)
	END;
	Write(g, buf, 0, i)
END RuHexSeparateHighBit;

PROCEDURE RuHex*(VAR g: Out; v: INTEGER);
BEGIN
	IF v < 0 THEN
		RuHexSeparateHighBit(g, v + Limits.IntegerMax + 1, TRUE)
	ELSE
		RuHexSeparateHighBit(g, v, FALSE)
	END
END RuHex;

END TextGenerator.

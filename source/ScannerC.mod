(*  Scanner of C lexems, based on Scanner for Oberon
 *  Copyright (C) 2016-2020 ComdivByZero
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
MODULE ScannerC;

IMPORT
	V,
	Stream := VDataStream,
	Utf8,
	TranLim := TranslatorLimits,
	Chars0X,
	Log := DLog;

CONST
	NewPage = Utf8.NewPage;

	EndOfFile*      = 0;

	Plus*           = 1;
	Minus*          = 2;
	Or*             = 3;

	Dot*            = 4;
	Range*          = 5;
	Comma*          = 6;
	Colon*          = 7;
	Assign*         = 8;
	Semicolon*      = 9;

	RelationFirst* = 11;
		Equal*          = 11;
		Inequal*        = 12;
		Less*           = 13;
		LessEqual*      = 14;
		Greater*        = 15;
		GreaterEqual*   = 16;
	RelationLast*  = 18;

	MultFirst*      = 19;
		(* В C не только для умножения*)
		Asterisk*       = 19;
		Slash*          = 20;
		And*            = 21;
		(* % *)
		Mod*            = 23;
	MultLast*       = 23;

	Negate*         = 24;
	Brace1Open*     = 26;
	Brace1Close*    = 27;
	Brace2Open*     = 28;
	Brace2Close*    = 29;
	Brace3Open*     = 30;
	Brace3Close*    = 31;

	Number*         = 32;
	Char*           = 33;
	String*         = 34;
	Ident*          = 35;

	(* ++ *)
	Inc* = 36;
	(* -- *)
	Dec* = 37;

	Add*     = 38;
	Sub*     = 39;
	Mul*     = 40;
	DivAsgn* = 41;
	ModAsgn* = 42;

	BitNegate*= 50;
	BitOr*    = 51;
	BitAnd*   = 52;

	BitAndAsgn* = 53;
	BitOrAsgn*  = 54;
	BitXorAsgn* = 55;
	BitXor*     = 56;

	LeftShift*      = 57;
	LeftShiftAsgn*  = 58;
	RightShift*     = 59;
	RightShiftAsgn* = 60;

	Sharp*   = 70;
	NewLine* = 71;

	ErrUnexpectChar*        = -1;
	ErrNumberTooBig*        = -2;
	ErrRealScaleTooBig*     = -3;
	ErrWordLenTooBig*       = -4;
	ErrExpectHOrX*          = -5;
	ErrExpectDQuote*        = -6;
	ErrExpectDigitInScale*  = -7;
	ErrUnclosedComment*     = -8;

	ErrCharExpectChar*        = -20;
	ErrCharExpectSingleQuote* = -21;
	ErrExpectHexDigit*        = -22;
	ErrDecimalDigitInOctal*   = -23;

	ErrExpectHeaderName*      = -30;
	ErrExpectHeaderExtension* = -31;

	ErrMin*                 = -100;

	BlockSize = 4096 * 2;

	IntMax       = 07FFFFFFFH;
	RealScaleMax = 512;

TYPE
	Scanner* = RECORD(V.Base)
		in: Stream.PIn;
		line*, column*: INTEGER;
		buf*: ARRAY BlockSize * 2 + 1 OF CHAR;
		ind: INTEGER;

		lexStart*, lexEnd*, emptyLines*: INTEGER;

		isReal*, isChar*: BOOLEAN;
		integer*: INTEGER;
		real*: REAL;

		opt*: RECORD
			cyrillic*: BOOLEAN;
			tabSize*: INTEGER
		END;

		isPreProcessor: BOOLEAN;

		commentOfs, commentEnd: INTEGER
	END;

	Suit = PROCEDURE(ch: CHAR): BOOLEAN;
	SuitDigit = PROCEDURE(ch: CHAR): INTEGER;

PROCEDURE PreInit(VAR s: Scanner);
BEGIN
	V.Init(s);
	s.column := 0;
	s.line := 0;
	s.commentOfs := -1;
	s.opt.cyrillic := FALSE;
	s.opt.tabSize := 8
END PreInit;

PROCEDURE Init*(VAR s: Scanner; in: Stream.PIn);
BEGIN
	ASSERT(in # NIL);
	PreInit(s);
	s.in := in;
	s.ind := LEN(s.buf) - 1;
	s.buf[0] := NewPage;
	s.buf[s.ind] := NewPage;
	s.isPreProcessor := FALSE
END Init;

PROCEDURE InitByString*(VAR s: Scanner; in: ARRAY OF CHAR): BOOLEAN;
VAR len: INTEGER;
    ret: BOOLEAN;
BEGIN
	PreInit(s);
	s.in := NIL;
	s.ind := 0;
	s.buf[0] := " ";

	len := 1;
	ret := Chars0X.CopyString(s.buf, len, in);
	s.buf[len] := Utf8.TransmissionEnd
	RETURN ret
END InitByString;

PROCEDURE FillBuf(VAR buf: ARRAY OF CHAR; VAR ind: INTEGER; VAR in: Stream.In);
VAR size: INTEGER;

	PROCEDURE Normalize(VAR buf: ARRAY OF CHAR; i, end: INTEGER);
	BEGIN
		WHILE i < end DO
			IF (buf[i] = NewPage) OR (buf[i] = Utf8.TransmissionEnd) THEN
				buf[i] := Utf8.Idle
			END;
			INC(i)
		END
	END Normalize;
BEGIN
	ASSERT(ODD(LEN(buf)));
	IF ind MOD (LEN(buf) DIV 2) # 0 THEN
		Log.StrLn("индекс новой страницы в неожиданном месте");
		ASSERT(buf[ind] = NewPage);
		buf[ind] := Utf8.Null
	ELSE
		ind := ind MOD (LEN(buf) - 1);
		IF buf[ind] = NewPage THEN
			size := Stream.ReadChars(in, buf, ind, LEN(buf) DIV 2);
			Normalize(buf, ind, ind + size);
			IF size = LEN(buf) DIV 2 THEN
				buf[(ind + LEN(buf) DIV 2) MOD (LEN(buf) - 1)] := NewPage
			ELSE
				buf[ind + size] := Utf8.TransmissionEnd
			END
		END
	END
END FillBuf;

PROCEDURE Lookup(VAR s: Scanner; i: INTEGER): CHAR;
BEGIN
	INC(i);
	IF s.buf[i] = NewPage THEN
		FillBuf(s.buf, i, s.in^)
	END
	RETURN s.buf[i]
END Lookup;

PROCEDURE ScanChars(VAR s: Scanner; suit: Suit);
BEGIN
	WHILE suit(s.buf[s.ind]) DO
		INC(s.ind);
		INC(s.column)
	ELSIF s.buf[s.ind] = NewPage DO
		FillBuf(s.buf, s.ind, s.in^)
	END
END ScanChars;

PROCEDURE IsOctalDigit(ch: CHAR): BOOLEAN;
	RETURN ("0" <= ch) & (ch <= "7")
END IsOctalDigit;

PROCEDURE IsDigit(ch: CHAR): BOOLEAN;
	RETURN ("0" <= ch) & (ch <= "9")
END IsDigit;

PROCEDURE IsHexDigit(ch: CHAR): BOOLEAN;
	RETURN ("0" <= ch) & (ch <= "9")
	    OR ("A" <= ch) & (ch <= "F")
	    OR ("a" <= ch) & (ch <= "f")
END IsHexDigit;

PROCEDURE IsLetter(ch: CHAR): BOOLEAN;
	RETURN (ch >= "a") & (ch <= "z")
	    OR (ch >= "Z") & (ch <= "Z")
END IsLetter;

PROCEDURE IsLetterOrDigit(ch: CHAR): BOOLEAN;
	RETURN (ch >= "a") & (ch <= "a")
	    OR (ch >= "Z") & (ch <= "Z")
	    OR (ch >= "0") & (ch <= "9")
END IsLetterOrDigit;

PROCEDURE ValDigit(ch: CHAR): INTEGER;
VAR i: INTEGER;
BEGIN
	IF (ch >= "0") & (ch <= "9") THEN
		i := ORD(ch) - ORD("0")
	ELSE
		i := -1
	END
	RETURN i
END ValDigit;

PROCEDURE ValHexDigit(ch: CHAR): INTEGER;
VAR i: INTEGER;
BEGIN
	IF (ch >= "0") & (ch <= "9") THEN
		i := ORD(ch) - ORD("0")
	ELSIF (ch >= "A") & (ch <= "F") THEN
		i := 10 + ORD(ch) - ORD("A")
	ELSIF (ch >= "a") & (ch <= "f") THEN
		i := 10 + ORD(ch) - ORD("a")
	ELSE
		i := -1
	END
	RETURN i
END ValHexDigit;

PROCEDURE NextChar(VAR s: Scanner);
BEGIN
	INC(s.ind);
	IF s.buf[s.ind] = NewPage THEN
		FillBuf(s.buf, s.ind, s.in^)
	END
END NextChar;

PROCEDURE SNumber(VAR s: Scanner): INTEGER;
VAR lex, capacity: INTEGER; ch: CHAR; valDigit: SuitDigit;

	PROCEDURE Val(VAR s: Scanner; VAR lex: INTEGER; capacity: INTEGER;
	              valDigit: SuitDigit);
	VAR d, val, i: INTEGER;
	BEGIN
		val := 0;
		i := s.lexStart;
		d := valDigit(s.buf[i]);
		(*Log.Str("IntMax "); Log.Int(IntMax); Log.Ln;*)
		WHILE d >= 0 DO
			IF IntMax DIV capacity >= val THEN
				val := val * capacity;
				IF IntMax - d >= val THEN
					val := val + d
				ELSE
					lex := ErrNumberTooBig
				END
			ELSE
				lex := ErrNumberTooBig
			END;
			INC(i);
			d := valDigit(s.buf[i])
		ELSIF s.buf[i] = NewPage DO
			i := 0;
			d := valDigit(s.buf[i])
		END;
		s.integer := val
		(*Log.Str("Val integer "); Log.Int(s.integer); Log.Ln*)
	END Val;

	PROCEDURE ValReal(VAR s: Scanner; VAR lex: INTEGER); (* TODO *)
	VAR
		i, d, scale: INTEGER;
		scMinus: BOOLEAN;
		val, t: REAL;
	BEGIN
		val := 1.0;
		i := s.lexStart;
		d := ValDigit(s.buf[i]);
		WHILE d >= 0 DO
			val := val * 10.0 + FLT(d);
			INC(i);
			d := ValDigit(s.buf[i])
		ELSIF s.buf[i] = NewPage DO
			i := 0;
			d := ValDigit(s.buf[i])
		END;
		(* skip dot *)
		INC(i);
		t := 10.0;
		d := ValDigit(s.buf[i]);
		WHILE d >= 0 DO
			INC(s.column);
			val := val + FLT(d) / t;
			t := t * 10.0;
			INC(i);
			d := ValDigit(s.buf[i])
		ELSIF s.buf[i] = NewPage DO
			FillBuf(s.buf, i, s.in^);
			d := ValDigit(s.buf[i])
		END;
		IF (s.buf[i] = "E") OR (s.buf[i] = "e") THEN
			INC(i);
			INC(s.column);
			IF s.buf[i] = NewPage THEN
				FillBuf(s.buf, i, s.in^)
			END;
			scMinus := s.buf[i] = "-";
			IF scMinus OR (s.buf[i] = "+") THEN
				INC(i);
				INC(s.column);
				IF s.buf[i] = NewPage THEN
					FillBuf(s.buf, i, s.in^)
				END
			END;
			d := ValDigit(s.buf[i]);
			IF d >= 0 THEN
				scale := 0;
				WHILE d >= 0 DO
					INC(s.column);
					IF scale < IntMax DIV 10 THEN
						scale := scale * 10 + d
					END;
					INC(i);
					d := ValDigit(s.buf[i])
				ELSIF s.buf[i] = NewPage DO
					FillBuf(s.buf, i, s.in^);
					d := ValDigit(s.buf[i])
				END;
				IF scale <= RealScaleMax THEN
					(* TODO *)
					WHILE scale > 0 DO
						IF scMinus THEN
							val := val * 10.0
						ELSE
							val := val / 10.0
						END;
						DEC(scale)
					END
				ELSE
					lex := ErrRealScaleTooBig
				END
			ELSE
				lex := ErrExpectDigitInScale
			END
		END;
		s.ind := i;
		s.real := val
	END ValReal;
BEGIN
	lex := Number;
	capacity := 10;
	valDigit := ValDigit;
	IF s.buf[s.ind] = "0" THEN
		NextChar(s);
		ch := s.buf[s.ind];
		IF (ch = "X") OR (ch = "x") THEN
			NextChar(s);
			IF ~IsHexDigit(ch) THEN
				lex := ErrExpectHexDigit
			ELSE
				ScanChars(s, IsHexDigit);
				capacity := 16;
				valDigit := ValHexDigit
			END
		ELSE
			ScanChars(s, IsOctalDigit);
			IF IsDigit(s.buf[s.ind]) THEN
				ScanChars(s, IsDigit);
				IF s.buf[s.ind] # "." THEN
					lex := ErrDecimalDigitInOctal
				END
			ELSE
				capacity := 8
			END
		END
	ELSE
		ScanChars(s, IsDigit)
	END;
	IF lex = Number THEN
		ch := s.buf[s.ind];
		s.isReal := (ch = ".") & (Lookup(s, s.ind) # ".");
		IF s.isReal THEN
			INC(s.ind);
			INC(s.column);
			ValReal(s, lex)
		ELSE
			Val(s, lex, capacity, valDigit)
		END
	END;
	Log.Str("Number lex = "); Log.Int(lex); Log.Ln
	RETURN lex
END SNumber;

PROCEDURE SWord(VAR s: Scanner): INTEGER;
VAR len, l: INTEGER;
BEGIN
	ScanChars(s, IsLetterOrDigit);
	len := s.ind - s.lexStart + ORD(s.ind < s.lexStart) * (LEN(s.buf) - 1);
	ASSERT(0 < len);
	IF len <= TranLim.LenName THEN
		l := Ident
	ELSE
		l := ErrWordLenTooBig
	END
	RETURN l
END SWord;

PROCEDURE IsCurrentCyrillic(VAR s: Scanner): BOOLEAN;
VAR ret: BOOLEAN;
	PROCEDURE ForD0(c: CHAR): BOOLEAN;
	RETURN (90X <= c) & (c <= 0BFX)
	    OR (c = 81X) OR (c = 84X) OR (c = 86X) OR (c = 87X) OR (c = 8EX)
	END ForD0;

	PROCEDURE ForD1(c: CHAR): BOOLEAN;
	RETURN (80X <= c) & (c <= 8FX)
	    OR (c = 91X) OR (c = 94X) OR (c = 96X) OR (c = 97X) OR (c = 9EX)
	END ForD1;

	PROCEDURE ForD2(c: CHAR): BOOLEAN;
	RETURN (c = 90X) OR (c = 91X)
	END ForD2;
BEGIN
	CASE s.buf[s.ind] OF
	  0X .. 0CFX, 0D3X .. 0FFX:
	        ret := FALSE
	| 0D0X: ret := ForD0(Lookup(s, s.ind))
	| 0D1X: ret := ForD1(Lookup(s, s.ind))
	| 0D2X: ret := ForD2(Lookup(s, s.ind))
	END
	RETURN ret
END IsCurrentCyrillic;

PROCEDURE CyrWord(VAR s: Scanner): INTEGER;
VAR len, l: INTEGER;
BEGIN
	WHILE IsCurrentCyrillic(s) DO
		s.ind := (s.ind + 2) MOD (LEN(s.buf) - 1);
		INC(s.column)
	ELSIF (s.buf[s.ind] = NewPage) & (s.in # NIL) DO
		FillBuf(s.buf, s.ind, s.in^)
	END;
	len := s.ind - s.lexStart + ORD(s.ind < s.lexStart) * (LEN(s.buf) - 1);
	ASSERT(0 < len);
	IF len <= TranLim.LenName THEN
		l := Ident
	ELSE
		l := ErrWordLenTooBig
	END
	RETURN l
END CyrWord;

PROCEDURE ScanBlank(VAR s: Scanner): BOOLEAN;
VAR i, column: INTEGER; comment, commentLine: BOOLEAN;
BEGIN
	i := s.ind;
	(*Log.Str("ScanBlank ind = "); Log.Int(i); Log.Ln;*)
	ASSERT(0 <= i);
	column := s.column;
	comment := FALSE;
	commentLine := FALSE;
	s.emptyLines := -1;
	WHILE s.buf[i] = " " DO
		INC(i);
		INC(column)
	ELSIF s.buf[i] = Utf8.Tab DO
		INC(i);
		column := (column + s.opt.tabSize) DIV s.opt.tabSize * s.opt.tabSize
	ELSIF s.buf[i] = Utf8.CarRet DO
		INC(i);
		column := 0;
	ELSIF (s.buf[i] = Utf8.NewLine) & ~s.isPreProcessor DO
		INC(s.line);
		INC(s.emptyLines);
		column := 0;
		INC(i)
	ELSIF s.buf[i] = NewPage DO
		FillBuf(s.buf, i, s.in^)
	ELSIF ~comment & (s.buf[i] = "/") & (Lookup(s, i) = "*") DO
		i := (i + 2) MOD (LEN(s.buf) - 1);
		INC(column, 2);
		comment := TRUE;
		s.commentOfs := i
	ELSIF comment & (s.buf[i] # Utf8.Null) (* & ~blank *) DO
		IF commentLine THEN
			comment := s.buf[i] # Utf8.NewLine
		ELSE
			comment := (s.buf[i] # "*") OR (Lookup(s, i) # "/")
		END;
		IF ~comment THEN
			commentLine := FALSE;
			s.commentEnd := i;
			s.emptyLines := -1;
			i := (i + 2) MOD (LEN(s.buf) - 1);
			INC(column, 2)
		ELSE
			IF (s.buf[i] < 80X) OR (0C0X <= s.buf[i]) THEN
				INC(column)
			END;
			INC(i)
		END
	ELSIF (0EFX = s.buf[i])
	    & (0BBX = Lookup(s, i))
	    & (0BFX = Lookup(s, (i + 1) MOD (LEN(s.buf) - 1)))
	DO
		(* Пробел 0-й длины, также, используемый как BOM в UTF *)
		i := (i + 3) MOD (LEN(s.buf) - 1)
	END;

	s.column := column;
	s.ind := i
	RETURN ~comment
END ScanBlank;

PROCEDURE ScanString(VAR s: Scanner): INTEGER;
VAR l, i, j, column: INTEGER;
BEGIN
	(* TODO *)
	i := s.ind + 1;
	column := s.column  + 1;
	IF s.buf[i] = NewPage THEN
		FillBuf(s.buf, i, s.in^)
	END;
	j := i;
	WHILE (s.buf[i] # Utf8.DQuote) & (" " <= s.buf[i]) DO
		IF (s.buf[i] < 80X) OR (s.buf[i] >= 0C0X) THEN
			INC(column)
		END;
		INC(i)
	ELSIF s.buf[i] = Utf8.Tab DO
		INC(i);
		column := (column + s.opt.tabSize) DIV s.opt.tabSize * s.opt.tabSize
	ELSIF s.buf[i] = NewPage DO
		FillBuf(s.buf, i, s.in^)
	END;
	s.isChar := FALSE;
	IF s.buf[i] = Utf8.DQuote THEN
		l := String;
	ELSE
		l := ErrExpectDQuote
	END;
	s.ind := i + 1;
	s.column := column
	RETURN l
END ScanString;

PROCEDURE SChar(VAR s: Scanner): INTEGER;
VAR l: INTEGER;
BEGIN
	(* TODO *)
	NextChar(s);
	s.isChar := TRUE;
	IF (s.buf[s.ind] = "'")
	OR (s.buf[s.ind] < " ") & (s.buf[s.ind] # Utf8.Tab)
	THEN
		l := ErrCharExpectChar
	ELSE
		s.integer := ORD(s.buf[s.ind]);
		NextChar(s);
		IF s.buf[s.ind] = "'" THEN
			l := String;
			INC(s.ind);
			INC(s.column, 3)
		ELSE
			l := ErrCharExpectSingleQuote;
			INC(s.column, 2)
		END
	END
	RETURN l
END SChar;

PROCEDURE HeaderName(VAR s: Scanner; lexEnd: INTEGER): INTEGER;
VAR first: CHAR; lex: INTEGER;
BEGIN
	first := s.buf[s.ind];
	ASSERT((first = Utf8.DQuote) OR (first = "<"));

	NextChar(s);
	IF ~IsLetter(s.buf[s.ind]) THEN
		lex := ErrExpectHeaderName
	ELSE
		s.lexStart := s.ind;
		lex := SWord(s);
		lexEnd := s.ind;
		IF (s.buf[s.ind] = ".") & (Lookup(s, s.ind) = "h") THEN
			NextChar(s)
		ELSE
			lex := ErrExpectHeaderExtension
		END
	END
	RETURN lex
END HeaderName;

PROCEDURE L2(VAR lex: INTEGER; VAR s: Scanner; ch: CHAR; then, else: INTEGER);
BEGIN
	ASSERT(then # else);
	NextChar(s);
	IF s.buf[s.ind] = ch THEN
		lex := then;
		INC(s.ind)
	ELSE
		lex := else
	END
END L2;

PROCEDURE L3(VAR lex: INTEGER; VAR s: Scanner; lex0: INTEGER; ch1: CHAR; lex1: INTEGER; ch2: CHAR; lex2: INTEGER);
BEGIN
	L2(lex, s, ch1, lex1, lex0);
	IF (lex = lex0) & (s.buf[s.ind] = ch2) THEN
		lex := lex2;
		INC(s.ind)
	END
END L3;

PROCEDURE Next*(VAR s: Scanner): INTEGER;
VAR lex, lexEnd: INTEGER;

	PROCEDURE L(VAR lex: INTEGER; VAR s: Scanner; l: INTEGER);
	BEGIN
		INC(s.ind);
		lex := l
	END L;

	PROCEDURE L4(VAR lex: INTEGER; VAR s: Scanner;
	             lex0: INTEGER; ch1: CHAR; lex1: INTEGER; ch2: CHAR; lex2: INTEGER; ch21: CHAR; lex21: INTEGER);
	BEGIN
		L3(lex, s, lex0, ch1, lex1, ch2, lex2);
		IF lex = lex2 THEN
			IF s.buf[s.ind] = NewPage THEN
				FillBuf(s.buf, s.ind, s.in^)
			END;
			IF s.buf[s.ind] = ch21 THEN
				lex := lex21;
				INC(s.ind)
			END
		END
	END L4;

BEGIN
	IF ~ScanBlank(s) THEN
		lex := ErrUnclosedComment
	ELSE
		s.lexStart := s.ind;
		lexEnd := -1;
		CASE s.buf[s.ind] OF
		  0X..3X, 5X..9X, 11X .. " ", "$", "?", "@", "\", "_", "`", 7FX..0CFX, 0D3X..0FFX:
			lex := ErrUnexpectChar;
			INC(s.ind)
		| Utf8.TransmissionEnd:
			lex := EndOfFile
		| Utf8.NewLine:
			ASSERT(s.isPreProcessor);

			lex := NewLine;
			s.isPreProcessor := FALSE;
			INC(s.ind);
			INC(s.line);
			s.column     := 0;
			s.emptyLines := 0
		| "0" .. "9":
			lex := SNumber(s)
		| "a" .. "z", "A" .. "Z":
			lex := SWord(s)
		| "'":
			lex := SChar(s)
		| 0D0X .. 0D2X:
			IF s.opt.cyrillic & IsCurrentCyrillic(s) THEN
				lex := CyrWord(s)
			ELSE
				lex := ErrUnexpectChar
			END
		| "+": L2(lex, s, "=", Add, Plus)
		| "-": L2(lex, s, "=", Sub, Minus)
		| "*": L2(lex, s, "=", Mul, Asterisk)
		| "/": L2(lex, s, "=", DivAsgn, Slash)
		| "%": L2(lex, s, "=", ModAsgn, Mod)
		| ".": L2(lex, s, ".", Range, Dot)
		| ",": L(lex, s, Comma)
		| ":": L(lex, s, Colon)
		| ";": L(lex, s, Semicolon)
		| "=": L2(lex, s, "=", Equal, Assign)
		| "#": L(lex, s, Sharp); s.isPreProcessor := TRUE
		| "~": L(lex, s, BitNegate)
		| "!": L2(lex, s, "=", Inequal, Negate)
		| "<": L4(lex, s, Less, "=", LessEqual, "<", LeftShift, "=", LeftShiftAsgn)
		| ">": L4(lex, s, Greater, "=", GreaterEqual, ">", RightShift, "=", RightShiftAsgn)
		| "&": L3(lex, s, BitAnd, "&", And, "=", BitAndAsgn)
		| "|": L3(lex, s, BitOr, "|", Or, "=", BitOrAsgn)
		| "^": L2(lex, s, "=", BitXorAsgn, BitXor)
		| "(": L(lex, s, Brace1Open)
		| ")": L(lex, s, Brace1Close)
		| "[": L(lex, s, Brace2Open)
		| "]": L(lex, s, Brace2Close)
		| "{": L(lex, s, Brace3Open)
		| "}": L(lex, s, Brace3Close)
		| Utf8.DQuote:
			IF s.isPreProcessor THEN
				lex := HeaderName(s, lexEnd)
			ELSE
				lex := ScanString(s)
			END
		END;
		(*
		Log.Str("Scan "); Log.Int(lex); Log.Ln;
		*)
		IF lexEnd < 0 THEN
			s.lexEnd := s.ind
		ELSE
			s.lexEnd := lexEnd
		END
	END
	RETURN lex
END Next;

PROCEDURE TakeCommentPos*(VAR s: Scanner; VAR ofs, end: INTEGER): BOOLEAN;
VAR ret: BOOLEAN;
BEGIN
	ret := s.commentOfs >= 0;
	IF ret THEN
		ofs := s.commentOfs;
		end := s.commentEnd;
		s.commentOfs := -1
	END
	RETURN ret
END TakeCommentPos;

PROCEDURE ResetComment*(VAR s: Scanner);
BEGIN
	s.commentOfs := -1
END ResetComment;

BEGIN
	ASSERT(TranLim.LenName < BlockSize)
END ScannerC.

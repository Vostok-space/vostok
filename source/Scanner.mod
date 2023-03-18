(*  Scanner of Oberon-07 lexems
 *  Copyright (C) 2016-2023 ComdivByZero
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
MODULE Scanner;

IMPORT
	V,
	Stream := VDataStream,
	Utf8,
	TranLim := TranslatorLimits,
	Chars0X,
	ArrayCopy,
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
	Dereference*    = 10;

	RelationFirst* = 11;
		Equal*          = 11;
		Inequal*        = 12;
		Less*           = 13;
		LessEqual*      = 14;
		Greater*        = 15;
		GreaterEqual*   = 16;
		In*             = 17;
		Is*             = 18;
	RelationLast*  = 18;

	MultFirst*      = 19;
		Asterisk*       = 19;
		Slash*          = 20;
		And*            = 21;
		Div*            = 22;
		Mod*            = 23;
	MultLast*       = 23;

	Negate*         = 24;
	Alternative*    = 25;
	Brace1Open*     = 26;
	Brace1Close*    = 27;
	Brace2Open*     = 28;
	Brace2Close*    = 29;
	Brace3Open*     = 30;
	Brace3Close*    = 31;

	Number*         = 32;
	CharHex*        = 33;
	String*         = 34;
	Ident*          = 35;

	ErrUnexpectChar*        = -1;
	ErrNumberTooBig*        = -2;
	ErrRealScaleTooBig*     = -3;
	ErrWordLenTooBig*       = -4;
	ErrExpectHOrX*          = -5;
	ErrExpectDQuote*        = -6;
	ErrExpectDigitInScale*  = -7;
	ErrUnclosedComment*     = -8;

	ErrMin*                 = -100;

	BlockSize = 4096 * 2;

	IntMax = 07FFFFFFFH;
	CharMax = 0FFX;
	RealScaleMax = 512;

TYPE
	Scanner* = RECORD(V.Base)
		in: Stream.PIn;
		line*, column*: INTEGER;
		buf*: ARRAY BlockSize * 2 + 1 OF CHAR;
		ind, transmissionEndPos: INTEGER;

		lexStart*, lexEnd*, emptyLines*: INTEGER;

		isReal*, isChar*: BOOLEAN;
		integer*: INTEGER;
		real*: REAL;

		opt*: RECORD
			cyrillic*: BOOLEAN;
			tabSize*: INTEGER
		END;

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
	s.transmissionEndPos := -1
END Init;

PROCEDURE InitByString*(VAR s: Scanner; in: ARRAY OF CHAR): BOOLEAN;
VAR len: INTEGER; ok: BOOLEAN;
BEGIN
	PreInit(s);
	s.in := NIL;
	s.ind := 0;
	s.buf[0] := " ";
	len := 1;
	ok := Chars0X.CopyString(s.buf, len, in)
	    & Chars0X.PutChar(s.buf, len, Utf8.TransmissionEnd);
	s.transmissionEndPos := len - 1
	RETURN ok
END InitByString;

PROCEDURE FillBuf(VAR s: Scanner; VAR ind: INTEGER): BOOLEAN;
VAR size: INTEGER; ok: BOOLEAN;
BEGIN
	ASSERT(ODD(LEN(s.buf)));
	ASSERT(s.buf[ind] = NewPage);
	ok := ind MOD (LEN(s.buf) DIV 2) = 0;
	IF ok THEN
		ind := ind MOD (LEN(s.buf) - 1);
		IF s.buf[ind] = NewPage THEN
			size := Stream.ReadChars(s.in^, s.buf, ind, LEN(s.buf) DIV 2);
			IF size = LEN(s.buf) DIV 2 THEN
				s.buf[(ind + LEN(s.buf) DIV 2) MOD (LEN(s.buf) - 1)] := NewPage
			ELSE
				s.transmissionEndPos := ind + size;
				s.buf[ind + size] := Utf8.TransmissionEnd
			END
		END
	END
	RETURN ok
END FillBuf;

PROCEDURE LookupEqual(VAR s: Scanner; i: INTEGER; sample: CHAR): BOOLEAN;
BEGIN
	INC(i)
	RETURN (s.buf[i] = sample)
	    OR (s.buf[i] = NewPage) & FillBuf(s, i) & (s.buf[i] = sample)
END LookupEqual;

PROCEDURE Lookup(VAR s: Scanner; i: INTEGER): CHAR;
VAR ignore: BOOLEAN; ch: CHAR;
BEGIN
	INC(i);
	ch := s.buf[i];
	IF ch = NewPage THEN
		ignore := FillBuf(s, i)
	END;
	RETURN ch
END Lookup;

PROCEDURE ScanChars(VAR s: Scanner; suit: Suit);
BEGIN
	WHILE suit(s.buf[s.ind]) DO
		INC(s.ind);
		INC(s.column)
	ELSIF (s.buf[s.ind] = NewPage) & FillBuf(s, s.ind) DO
		;
	END
END ScanChars;

PROCEDURE IsDigit(ch: CHAR): BOOLEAN;
	RETURN ("0" <= ch) & (ch <= "9")
END IsDigit;

PROCEDURE IsHexDigit(ch: CHAR): BOOLEAN;
	RETURN ("0" <= ch) & (ch <= "9")
        OR ("A" <= ch) & (ch <= "F")
END IsHexDigit;

PROCEDURE ValDigit(ch: CHAR): INTEGER;
VAR i: INTEGER;
BEGIN
	i := ORD(ch) - ORD("0");
	IF i > 9 THEN
		i := -1
	END
	RETURN i
END ValDigit;

PROCEDURE ValHexDigit(ch: CHAR): INTEGER;
VAR i: INTEGER;
BEGIN
	i := ORD(ch) - ORD("0");
	IF i < 0AH THEN
		;
	ELSIF (ch >= "A") & (ch <= "F") THEN
		i :=  ORD(ch) - (ORD("A") - 0AH)
	ELSE
		i := -1
	END
	RETURN i
END ValHexDigit;

PROCEDURE SNumber(VAR s: Scanner): INTEGER;
VAR
	lex: INTEGER;
	ch: CHAR;

	PROCEDURE Val(VAR s: Scanner; VAR lex: INTEGER; capacity: INTEGER;
	              valDigit: SuitDigit);
	VAR d, val, i: INTEGER;
	BEGIN
		val := 0;
		i := s.lexStart;
		d := valDigit(s.buf[i]);
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
	END Val;

	PROCEDURE ValReal(VAR s: Scanner; VAR lex: INTEGER); (* TODO *)
	VAR
		i, d, scale: INTEGER;
		scMinus, ignore: BOOLEAN;
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
		ELSIF (s.buf[i] = NewPage) & FillBuf(s, i) DO
			d := ValDigit(s.buf[i])
		END;
		IF s.buf[i] = "E" THEN
			INC(i);
			INC(s.column);
			IF s.buf[i] = NewPage THEN
				ignore := FillBuf(s, i)
			END;
			scMinus := s.buf[i] = "-";
			IF scMinus OR (s.buf[i] = "+") THEN
				INC(i);
				INC(s.column);
				IF s.buf[i] = NewPage THEN
					ignore := FillBuf(s, i)
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
				ELSIF (s.buf[i] = NewPage) & FillBuf(s, i) DO
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
	ScanChars(s, IsDigit);
	ch := s.buf[s.ind];
	s.isReal := (ch = ".") & (Lookup(s, s.ind) # ".");
	IF s.isReal THEN
		INC(s.ind);
		INC(s.column);
		ValReal(s, lex)
	ELSIF (ch >= "A") & (ch <= "F") OR (ch = "H") OR (ch = "X") THEN
		ScanChars(s, IsHexDigit);
		ch := s.buf[s.ind];
		Val(s, lex, 16, ValHexDigit);
		IF ch = "X" THEN
			IF s.integer <= ORD(CharMax) THEN
				lex := String;
				s.isChar := TRUE
			ELSE
				lex := ErrNumberTooBig
			END
		ELSIF ch # "H" THEN
			lex := ErrExpectHOrX
		END;
		IF (ch = "X") OR (ch = "H") THEN
			INC(s.column);
			INC(s.ind)
		END
	ELSE
		Val(s, lex, 10, ValDigit)
	END
	RETURN lex
END SNumber;

PROCEDURE IsLetterOrDigit(ch: CHAR): BOOLEAN;
	RETURN ("a" <= ch) & (ch <= "z")
	    OR ("A" <= ch) & (ch <= "Z")
	    OR ("0" <= ch) & (ch <= "9")
END IsLetterOrDigit;

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
	ELSIF (s.buf[s.ind] = NewPage) & FillBuf(s, s.ind) DO
		;
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
VAR i, column, comment, commentsCount: INTEGER;
BEGIN
	i := s.ind;
	ASSERT(0 <= i);
	column := s.column;
	comment := 0;
	commentsCount := 0;
	s.emptyLines := -1;
	WHILE s.buf[i] = " " DO
		INC(i);
		INC(column)
	ELSIF s.buf[i] = Utf8.Tab DO
		INC(i);
		column := (column + s.opt.tabSize) DIV s.opt.tabSize * s.opt.tabSize
	ELSIF s.buf[i] = Utf8.NewLine DO
		INC(s.line);
		INC(s.emptyLines);
		column := 0;
		INC(i)
	ELSIF (s.buf[i] = "(") & LookupEqual(s, i, "*") DO
		i := (i + 2) MOD (LEN(s.buf) - 1);
		INC(column, 2);
		INC(comment);
		INC(commentsCount);
		IF commentsCount = 1 THEN
			s.commentOfs := i
		END
	ELSIF (s.buf[i] = NewPage) & FillBuf(s, i) DO
		;
	ELSIF s.buf[i] = Utf8.CarRet DO
		INC(i);
		column := 0;
	ELSIF (0 < comment) & (s.buf[i] # Utf8.Null) (* & ~blank *) DO
		IF (s.buf[i] = "*") & LookupEqual(s, i, ")") THEN
			DEC(comment);
			IF comment = 0 THEN
				s.commentEnd := i;
				s.emptyLines := -1
			END;
			i := (i + 2) MOD (LEN(s.buf) - 1);
			INC(column, 2)
		ELSE
			IF (s.buf[i] < 80X) OR (0C0X <= s.buf[i]) THEN
				INC(column)
			END;
			INC(i)
		END
	ELSIF (s.buf[i] = 0EFX)
	    & LookupEqual(s, i, 0BBX)
	    & LookupEqual(s, (i + 1) MOD (LEN(s.buf) - 1), 0BFX)
	DO
		(* Пробел 0-й длины, также, используемый как BOM в UTF *)
		i := (i + 3) MOD (LEN(s.buf) - 1)
	END;

	s.column := column;
	s.ind := i
	RETURN comment <= 0
END ScanBlank;

PROCEDURE ScanString(VAR s: Scanner): INTEGER;
VAR l, i, j, count, column: INTEGER;
BEGIN
	i := s.ind + 1;
	column := s.column  + 1;
	j := i;
	count := 0;
	WHILE (s.buf[i] # Utf8.DQuote) & (" " <= s.buf[i]) DO
		IF Utf8.IsBegin(s.buf[i]) THEN
			INC(column)
		END;
		INC(count);
		INC(i)
	ELSIF s.buf[i] = Utf8.Tab DO
		INC(i);
		INC(count);
		column := (column + s.opt.tabSize) DIV s.opt.tabSize * s.opt.tabSize
	ELSIF (s.buf[i] = NewPage) & FillBuf(s, i) DO
		IF count = 0 THEN j := i END
	END;
	s.isChar := FALSE;
	IF s.buf[i] = Utf8.DQuote THEN
		l := String;
		IF count = 1 THEN
			s.isChar := TRUE;
			s.integer := ORD(s.buf[j])
		END
	ELSE
		l := ErrExpectDQuote
	END;
	s.ind := i + 1;
	s.column := column
	RETURN l
END ScanString;

PROCEDURE Next*(VAR s: Scanner): INTEGER;
VAR lex: INTEGER;

	PROCEDURE L(VAR s: Scanner; l: INTEGER): INTEGER;
	BEGIN
		INC(s.ind);
		RETURN l
	END L;

	PROCEDURE Li(VAR s: Scanner; lex: INTEGER; ch: CHAR; lexWithCh: INTEGER): INTEGER;
	VAR i: INTEGER;
	BEGIN
		i := s.ind + 1;
		IF (s.buf[i] = ch)
		OR (s.buf[i] = NewPage) & FillBuf(s, i) & (s.buf[i] = ch)
		THEN
			lex := lexWithCh;
			INC(i)
		END;
		s.ind := i
		RETURN lex
	END Li;
BEGIN
	IF ~ScanBlank(s) THEN
		lex := ErrUnclosedComment
	ELSE
		s.lexStart := s.ind;
		CASE s.buf[s.ind] OF
		  0X..03X, 05X.."!", "$", "%", "'", "?", "@", "\", "_", "`", 7FX..0CFX, 0D3X..0FFX,
		  Utf8.TransmissionEnd:
			IF s.ind = s.transmissionEndPos THEN
				lex := EndOfFile
			ELSE
				lex := ErrUnexpectChar;
				INC(s.ind)
			END
		| "0" .. "9":
			lex := SNumber(s)
		| "a" .. "z", "A" .. "Z":
			lex := SWord(s)
		| 0D0X .. 0D2X:
			IF s.opt.cyrillic & IsCurrentCyrillic(s) THEN
				lex := CyrWord(s)
			ELSE
				lex := ErrUnexpectChar;
				INC(s.ind)
			END
		| "+": lex := L (s, Plus)
		| "-": lex := L (s, Minus)
		| "*": lex := L (s, Asterisk)
		| "/": lex := L (s, Slash)
		| ".": lex := Li(s, Dot, ".", Range)
		| ",": lex := L (s, Comma)
		| ":": lex := Li(s, Colon, "=", Assign)
		| ";": lex := L (s, Semicolon)
		| "^": lex := L (s, Dereference)
		| "=": lex := L (s, Equal)
		| "#": lex := L (s, Inequal)
		| "~": lex := L (s, Negate)
		| "<": lex := Li(s, Less, "=", LessEqual)
		| ">": lex := Li(s, Greater, "=", GreaterEqual)
		| "&": lex := L (s, And)
		| "|": lex := L (s, Alternative)
		| "(": lex := L (s, Brace1Open)
		| ")": lex := L (s, Brace1Close)
		| "[": lex := L (s, Brace2Open)
		| "]": lex := L (s, Brace2Close)
		| "{": lex := L (s, Brace3Open)
		| "}": lex := L (s, Brace3Close)
		| Utf8.DQuote: lex := ScanString(s)
		END;
		s.lexEnd := s.ind
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

PROCEDURE CopyCurrent*(s: Scanner; VAR buf: ARRAY OF CHAR);
VAR len: INTEGER;
BEGIN
	IF s.lexStart < s.lexEnd THEN
		len := s.lexEnd - s.lexStart;
		ArrayCopy.Chars(buf, 0, s.buf, s.lexStart, len)
	ELSE
		len := LEN(s.buf) - 1 - s.lexStart;
		ArrayCopy.Chars(buf, 0, s.buf, s.lexStart, len);
		ArrayCopy.Chars(buf, len, s.buf, 0, s.lexEnd);
		INC(len, s.lexEnd)
	END;
	buf[len] := Utf8.Null
END CopyCurrent;

BEGIN
	ASSERT(TranLim.LenName < BlockSize)
END Scanner.

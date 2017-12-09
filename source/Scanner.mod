(*  Scanner of Oberon-07 lexems
 *  Copyright (C) 2016-2017 ComdivByZero
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
	Strings := StringStore,
	Log;

CONST
	NewPage = Utf8.NewPage;

	EndOfFile*      = 00;

	Plus*           = 10;
	Minus*          = 11;
	Or*             = 12;
	Dot*            = 14;
	Range*          = 15;
	Comma*          = 16;
	Colon*          = 17;
	Assign*         = 18;
	Semicolon*      = 19;
	Dereference*    = 20;

	RelationFirst* = 21;
		Equal*          = 21;
		Inequal*        = 22;
		Less*           = 23;
		LessEqual*      = 24;
		Greater*        = 25;
		GreaterEqual*   = 26;
		In*             = 27;
		Is*             = 28;
	RelationLast*  = 28;

	Negate*         = 29;
	Alternative*    = 31;
	Brace1Open*     = 32;
	Brace1Close*    = 33;
	Brace2Open*     = 34;
	Brace2Close*    = 35;
	Brace3Open*     = 36;
	Brace3Close*    = 37;

	Number*         = 40;
	CharHex*        = 41;
	String*         = 42;
	Ident*          = 43;

	Array*          = 50;
	Begin*          = 51;
	By*             = 52;
	Case*           = 53;
	Const*          = 54;
	Do*             = 56;
	Else*           = 57;
	Elsif*          = 58;
	End*            = 59;
	False*          = 60;
	For*            = 61;
	If*             = 62;
	Import*         = 63;
	Module*         = 67;
	Nil*            = 68;
	Of*             = 69;
	Pointer*        = 71;
	Procedure*      = 72;
	Record*         = 73;
	Repeat*         = 74;
	Return*         = 75;
	Then*           = 76;
	To*             = 77;
	True*           = 78;
	Type*           = 79;
	Until*          = 80;
	Var*            = 81;
	While*          = 82;

	MultFirst*      = 150;
		Asterisk*       = 150;
		Slash*          = 151;
		And*            = 152;
		Div*            = 153;
		Mod*            = 154;
	MultLast*       = 154;

	(* Предопределенные идентификаторы имеют стабильный порядок *)
	(* TODO Их нужно вынести за рамки сканера *)
	PredefinedFirst* = 90;
	Abs*        = 90;
	Asr*        = 91;
	Assert*     = 92;
	Boolean*    = 93;
	Byte*       = 94;
	Char*       = 95;
	Chr*        = 96;
	Dec*        = 97;
	Excl*       = 98;
	Floor*      = 99;
	Flt*        = 100;
	Inc*        = 101;
	Incl*       = 102;
	Integer*    = 103;
	Len*        = 104;
	LongInt*    = 105;
	LongSet*    = 106;
	Lsl*        = 107;
	New*        = 108;
	Odd*        = 109;
	Ord*        = 110;
	Pack*       = 111;
	Real*       = 112;
	Real32*     = 113;
	Ror*        = 114;
	Set*        = 115;
	Unpk*       = 116;
	PredefinedLast* = 116;

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
		line*, column*, tabs*: INTEGER;
		buf*: ARRAY BlockSize * 2 + 1 OF CHAR;
		ind: INTEGER;

		lexStart*, lexEnd*, lexLen*, emptyLines*: INTEGER;

		isReal*, isChar*: BOOLEAN;
		integer*: INTEGER;
		real*: REAL;

		commentOfs, commentEnd: INTEGER
	END;

	Suit = PROCEDURE(ch: CHAR): BOOLEAN;
	SuitDigit = PROCEDURE(ch: CHAR): INTEGER;

PROCEDURE PreInit(VAR s: Scanner);
BEGIN
	V.Init(s);
	s.column := 0;
	s.tabs := 0;
	s.line := 0;
	s.commentOfs := -1
END PreInit;

PROCEDURE Init*(VAR s: Scanner; in: Stream.PIn);
BEGIN
	ASSERT(in # NIL);
	PreInit(s);
	s.in := in;
	s.ind := LEN(s.buf) - 1;
	s.buf[0] := NewPage;
	s.buf[s.ind] := NewPage;
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
	ret := Strings.CopyCharsNull(s.buf, len, in);
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

(* TODO убрать*)
PROCEDURE ScanChar(VAR s: Scanner): CHAR;
VAR ch: CHAR;
BEGIN
	INC(s.ind);
	ch := s.buf[s.ind];
	IF ch = NewPage THEN
		FillBuf(s.buf, s.ind, s.in^);
		ch := s.buf[s.ind]
	END
	RETURN ch
END ScanChar;

PROCEDURE Lookup(VAR s: Scanner): CHAR;
VAR i: INTEGER;
BEGIN
	i := s.ind + 1;
	IF s.buf[i] = NewPage THEN
		FillBuf(s.buf, i, s.in^)
	END
	RETURN s.buf[i]
END Lookup;

PROCEDURE ScanChars(VAR s: Scanner; suit: Suit);
BEGIN
	WHILE suit(s.buf[s.ind]) DO
		INC(s.ind)
	ELSIF (s.buf[s.ind] = NewPage) & (s.in # NIL) DO
		FillBuf(s.buf, s.ind, s.in^)
	END
END ScanChars;

PROCEDURE IsDigit(ch: CHAR): BOOLEAN;
	RETURN ("0" <= ch) & (ch <= "9")
END IsDigit;

PROCEDURE IsHexDigit(ch: CHAR): BOOLEAN;
	RETURN ("0" <= ch) & (ch <= "9") OR ("A" <= ch) & (ch <= "F")
END IsHexDigit;

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
			val := val + FLT(d) / t;
			t := t * 10.0;
			INC(i);
			d := ValDigit(s.buf[i])
		ELSIF s.buf[i] = NewPage DO
			FillBuf(s.buf, i, s.in^);
			d := ValDigit(s.buf[i])
		END;
		IF s.buf[i] = "E" THEN
			INC(i);
			IF s.buf[i] = NewPage THEN
				FillBuf(s.buf, i, s.in^)
			END;
			scMinus := s.buf[i] = "-";
			IF scMinus OR (s.buf[i] = "+") THEN
				INC(i);
				IF s.buf[i] = NewPage THEN
					FillBuf(s.buf, i, s.in^)
				END
			END;
			d := ValDigit(s.buf[i]);
			IF d >= 0 THEN
				scale := 0;
				WHILE d >= 0 DO
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
	ScanChars(s, IsDigit);
	ch := s.buf[s.ind];
	s.isReal := (ch = ".") & (Lookup(s) # ".");
	IF s.isReal THEN
		INC(s.ind);
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
			INC(s.ind)
		END
	ELSE
		Val(s, lex, 10, ValDigit)
	END;
	Log.Str("Number lex = "); Log.Int(lex); Log.Ln
	RETURN lex
END SNumber;

PROCEDURE IsWordEqual(str, buf: ARRAY OF CHAR; ind, end: INTEGER): BOOLEAN;
VAR i, j: INTEGER;
BEGIN
	ASSERT(LEN(str) <= LEN(buf) DIV 2);
	j := 1;
	i := ind + 1;
	WHILE (j < LEN(str)) & (buf[i] = str[j]) DO
		INC(i); INC(j)
	ELSIF buf[i] = NewPage DO
		i := 0
	END
	RETURN (buf[i] = Utf8.BackSpace) & ((j = LEN(str)) OR (str[j] = Utf8.Null))
END IsWordEqual;

PROCEDURE CheckPredefined*(VAR buf: ARRAY OF CHAR; begin, end: INTEGER): INTEGER;
VAR id: INTEGER;
	save: CHAR;

	PROCEDURE Eq(str: ARRAY OF CHAR; buf: ARRAY OF CHAR; begin, end: INTEGER)
	            : BOOLEAN;
		RETURN IsWordEqual(str, buf, begin, end)
	END Eq;

	PROCEDURE O(str: ARRAY OF CHAR; buf: ARRAY OF CHAR; begin, end, id: INTEGER)
	           : INTEGER;
	BEGIN
		IF ~IsWordEqual(str, buf, begin, end) THEN
			id := Ident
		END
		RETURN id
	END O;

	PROCEDURE T(s1: ARRAY OF CHAR;
	            buf: ARRAY OF CHAR; begin, end: INTEGER;
	            id1: INTEGER; s2: ARRAY OF CHAR; id2: INTEGER): INTEGER;
	BEGIN
		IF     IsWordEqual(s1, buf, begin, end) THEN id2 := id1
		ELSIF ~IsWordEqual(s2, buf, begin, end) THEN id2 := Ident
		END
		RETURN id2
	END T;
BEGIN
	save := buf[end];
	buf[end] := Utf8.BackSpace;
	CASE buf[begin] OF
	 "A":
		IF Eq("ABS", buf, begin, end) THEN
			id := Abs
		ELSE
			id := T("ASR", buf, begin, end, Asr, "ASSERT", Assert)
		END
	|"B": id := T("BOOLEAN", buf, begin, end, Boolean, "BYTE", Byte)
	|"C": id := T("CHAR", buf, begin, end, Char, "CHR", Chr)
	|"D": id := O("DEC", buf, begin, end, Dec)
	|"E": id := O("EXCL", buf, begin, end, Excl)
	|"F": id := T("FLOOR", buf, begin, end, Floor, "FLT", Flt)
	|"I":
		IF Eq("INC", buf, begin, end) THEN
			id := Inc
		ELSE
			id := T("INCL", buf, begin, end, Incl, "INTEGER", Integer)
		END
	|"L": id := T("LEN", buf, begin, end, Len, "LSL", Lsl)
	|"N": id := O("NEW", buf, begin, end, New)
	|"O": id := T("ODD", buf, begin, end, Odd, "ORD", Ord)
	|"P": id := O("PACK", buf, begin, end, Pack)
	|"R": id := T("REAL", buf, begin, end, Real, "ROR", Ror)
	|"S": id := O("SET", buf, begin, end, Set)
	|"U": id := O("UNPK", buf, begin, end, Unpk)
	|"G", "H", "J", "K", "M", "Q", "T", "V" .. "Z", "a" .. "z":
		id := Ident
	END;
	buf[end] := save
	RETURN id
END CheckPredefined;

PROCEDURE CheckWord(VAR buf: ARRAY OF CHAR; ind, end: INTEGER): INTEGER;
VAR lex: INTEGER;
	save: CHAR;

	PROCEDURE Eq(str, buf: ARRAY OF CHAR; ind, end: INTEGER): BOOLEAN;
		RETURN IsWordEqual(str, buf, ind, end)
	END Eq;

	PROCEDURE O(VAR lex: INTEGER; str, buf: ARRAY OF CHAR; ind, end, l: INTEGER);
	BEGIN
		IF IsWordEqual(str, buf, ind, end) THEN lex := l ELSE lex := Ident END
	END O;
	PROCEDURE T(VAR lex: INTEGER;
	            s1: ARRAY OF CHAR; l1: INTEGER;
	            s2: ARRAY OF CHAR; l2: INTEGER;
	            buf: ARRAY OF CHAR; ind, end: INTEGER);
	BEGIN
		IF IsWordEqual(s1, buf, ind, end) THEN
			lex := l1
		ELSIF IsWordEqual(s2, buf, ind, end) THEN
			lex := l2
		ELSE
			lex := Ident
		END
	END T;

BEGIN
	save := buf[end];
	buf[end] := Utf8.BackSpace;
	(*
	Log.Str("lexStart "); Log.Int(ind); Log.Str(" ");
	Log.Int(ORD(buf[ind])); Log.Ln;
	*)
	CASE buf[ind] OF
	 "A": O(lex, "ARRAY", buf, ind, end, Array)
	|"B": T(lex, "BEGIN", Begin, "BY", By, buf, ind, end)
	|"C": T(lex, "CASE", Case, "CONST", Const, buf, ind, end)
	|"D": T(lex, "DIV", Div, "DO", Do, buf, ind, end)
	|"E":
		IF Eq("ELSE", buf, ind, end) THEN
			lex := Else
		ELSE
			T(lex, "ELSIF", Elsif, "END", End, buf, ind, end)
		END
	|"F": T(lex, "FALSE", False, "FOR", For, buf, ind, end)
	|"I":
		IF Eq("IF", buf, ind, end) THEN
			lex := If
		ELSIF Eq("IMPORT", buf, ind, end) THEN
			lex := Import
		ELSE
			T(lex, "IN", In, "IS", Is, buf, ind, end)
		END
	|"M": T(lex, "MOD", Mod, "MODULE", Module, buf, ind, end)
	|"N": O(lex, "NIL", buf, ind, end, Nil)
	|"O": T(lex, "OF", Of, "OR", Or, buf, ind, end)
	|"P": T(lex, "POINTER", Pointer, "PROCEDURE", Procedure, buf, ind, end)
	|"R":
		IF Eq("RECORD", buf, ind, end) THEN
			lex:= Record
		ELSE
			T(lex, "REPEAT", Repeat, "RETURN", Return, buf, ind, end)
		END
	|"T":
		IF Eq("THEN", buf, ind, end) THEN
			lex := Then
		ELSIF Eq("TO", buf, ind, end) THEN
			lex := To
		ELSE
			T(lex, "TRUE", True, "TYPE", Type, buf, ind, end)
		END
	|"U": O(lex, "UNTIL", buf, ind, end, Until)
	|"V": O(lex, "VAR", buf, ind, end, Var)
	|"W": O(lex, "WHILE", buf, ind, end, While)
	|0X .. 40X, "G", "H", "J" .. "L", "Q", "S", "X" .. 0FFX:
		lex := Ident
	END;
	buf[end] := save
	RETURN lex
END CheckWord;

PROCEDURE IsLetterOrDigit(ch: CHAR): BOOLEAN;
	RETURN (ch >= "A") & (ch <= "Z")
	    OR (ch >= "a") & (ch <= "z")
	    OR (ch >= "0") & (ch <= "9")
END IsLetterOrDigit;

PROCEDURE SWord(VAR s: Scanner): INTEGER;
VAR
	len, l: INTEGER;
BEGIN
	ScanChars(s, IsLetterOrDigit);
	len := s.ind - s.lexStart + ORD(s.ind < s.lexStart) * (LEN(s.buf) - 1);
	ASSERT(0 < len);
	IF len <= TranLim.MaxLenName THEN
		l := CheckWord(s.buf, s.lexStart, s.ind)
	ELSE
		l := ErrWordLenTooBig
	END
	RETURN l
END SWord;

(*	TODO поправить обработку комментариев - иногда ложно воспринимаются как
	комментарии строки с '(' и '*' *)
PROCEDURE ScanBlank(VAR s: Scanner): BOOLEAN;
VAR start, i, comment, commentsCount: INTEGER;
BEGIN
	i := s.ind;
	(*Log.Str("ScanBlank ind = "); Log.Int(i); Log.Ln;*)
	ASSERT(0 <= i);
	start := i;
	comment := 0;
	commentsCount := 0;
	s.emptyLines := -1;
	WHILE (s.buf[i] = " ") OR (s.buf[i] = Utf8.CarRet) DO
		INC(i)
	ELSIF s.buf[i] = Utf8.Tab DO
		INC(i);
		INC(s.tabs)
	ELSIF s.buf[i] = Utf8.NewLine DO
		INC(s.line);
		INC(s.emptyLines);
		s.column := 0; s.tabs := 0;
		INC(i);
		start := i
	ELSIF s.buf[i] = NewPage DO
		FillBuf(s.buf, i, s.in^);
		start := start - ORD(i = 0) * (LEN(s.buf) - 1)
	ELSIF (s.buf[i] = "(") & (comment >= 0) DO
		s.ind := i;
		IF ScanChar(s) = "*" THEN
			start := start - ORD(s.ind < start) * (LEN(s.buf) - 1);
			INC(s.ind);
			INC(comment);
			INC(commentsCount);
			IF commentsCount = 1 THEN
				IF s.ind = LEN(s.buf) - 1 THEN
					s.commentOfs := 0
				ELSE
					s.commentOfs := s.ind
				END
			END
		ELSIF comment = 0 THEN
			s.ind := i;
			comment := -1
		END;
		i := s.ind
	ELSIF (comment > 0) & (s.buf[i] # Utf8.Null) (* & ~blank *) DO
		IF s.buf[i] = "*" THEN
			s.ind := i;
			IF ScanChar(s) = ")" THEN
				start := start - ORD(s.ind < start) * (LEN(s.buf) - 1);
				DEC(comment);
				IF comment = 0 THEN
					s.commentEnd := i;
					s.emptyLines := -1
				END;
				i := s.ind
			END
		END;
		INC(i)
	END;
	s.column := s.column + (i - start);
	ASSERT(0 <= s.column);
	s.ind := i
	RETURN comment <= 0
END ScanBlank;

PROCEDURE ScanString(VAR s: Scanner): INTEGER;
VAR l, i, j, count: INTEGER;
BEGIN
	i := s.ind + 1;
	IF s.buf[i] = NewPage THEN
		FillBuf(s.buf, i, s.in^)
	END;
	j := i;
	count := 0;
	WHILE (s.buf[i] # Utf8.DQuote) & ((s.buf[i] >= " ")
	   OR (s.buf[i] = Utf8.Tab))
	DO
		INC(i);
		INC(count)
	ELSIF s.buf[i] = NewPage DO
		FillBuf(s.buf, i, s.in^)
	END;
	s.isChar := FALSE;
	IF s.buf[i] = Utf8.DQuote THEN
		l := String;
		IF count = 1 THEN
			s.isChar := TRUE;
			s.integer := ORD(s.buf[j])
		END;
		i := (i + 1) MOD (LEN(s.buf) - 1)
	ELSE
		l := ErrExpectDQuote
	END;
	s.ind := i
	RETURN l
END ScanString;

PROCEDURE Next*(VAR s: Scanner): INTEGER;
VAR
	lex: INTEGER;

	PROCEDURE L(VAR lex: INTEGER; VAR s: Scanner; l: INTEGER);
	BEGIN
		INC(s.ind);
		lex := l
	END L;

	PROCEDURE Li(VAR lex: INTEGER; VAR s: Scanner; ch: CHAR; then, else: INTEGER);
	BEGIN
		INC(s.ind);
		IF s.buf[s.ind] = NewPage THEN
			FillBuf(s.buf, s.ind, s.in^)
		END;
		IF s.buf[s.ind] = ch THEN
			lex := then;
			INC(s.ind)
		ELSE
			lex := else
		END
	END Li;
BEGIN
	IF ~ScanBlank(s) THEN
		lex := ErrUnclosedComment
	ELSE
		s.lexStart := s.ind;
		CASE s.buf[s.ind] OF
		  0X..03X, 05X.."!", "$", "%", "'", "?", "@", "\", "_", "`", 7FX..0FFX:
			lex := ErrUnexpectChar;
			INC(s.ind)
		| Utf8.TransmissionEnd:
			lex := EndOfFile
		| "0" .. "9":
			lex := SNumber(s)
		| "a" .. "z", "A" .. "Z":
			lex := SWord(s)
		| "+": L(lex, s, Plus)
		| "-": L(lex, s, Minus)
		| "*": L(lex, s, Asterisk)
		| "/": L(lex, s, Slash)
		| ".": Li(lex, s, ".", Range, Dot)
		| ",": L(lex, s, Comma)
		| ":": Li(lex, s, "=", Assign, Colon)
		| ";": L(lex, s, Semicolon)
		| "^": L(lex, s, Dereference)
		| "=": L(lex, s, Equal)
		| "#": L(lex, s, Inequal)
		| "~": L(lex, s, Negate)
		| "<": Li(lex, s, "=", LessEqual, Less)
		| ">": Li(lex, s, "=", GreaterEqual, Greater)
		| "&": L(lex, s, And)
		| "|": L(lex, s, Alternative)
		| "(": L(lex, s, Brace1Open)
		| ")": L(lex, s, Brace1Close)
		| "[": L(lex, s, Brace2Open)
		| "]": L(lex, s, Brace2Close)
		| "{": L(lex, s, Brace3Open)
		| "}": L(lex, s, Brace3Close)
		| Utf8.DQuote: lex := ScanString(s)
		END;
		(*
		Log.Str("Scan "); Log.Int(lex); Log.Ln;
		*)
		s.lexEnd := s.ind;
		s.lexLen := s.lexEnd + ORD(s.lexEnd < s.lexStart) * (LEN(s.buf) - 1)
		          - s.lexStart;
		ASSERT((0 < s.lexLen) OR (lex = EndOfFile));
		s.column := s.column + s.lexLen;
		ASSERT(0 <= s.column)
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
	ASSERT(TranLim.MaxLenName < BlockSize)
END Scanner.

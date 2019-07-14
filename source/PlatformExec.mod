(*  Wrapper over OS-specific execution
 *  Copyright (C) 2017-2018 ComdivByZero
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
MODULE PlatformExec;

IMPORT
	V,
	Utf8,
	OsExec,
	log := Log,
	Platform,
	Strings := StringStore;

CONST
	CodeSize* = 8192;

	Ok* = 0;

TYPE
	Code* = RECORD(V.Base)
		buf: ARRAY CodeSize OF CHAR;
		len: INTEGER;

		parts, partsQuote: BOOLEAN
	END;

VAR
	autoCorrectDirSeparator: BOOLEAN;
	dirSep*: ARRAY 1 OF CHAR;

PROCEDURE Copy(VAR d: ARRAY OF CHAR; VAR i: INTEGER;
               s: ARRAY OF CHAR; j: INTEGER;
               parts: BOOLEAN): BOOLEAN;
VAR k: INTEGER;
	PROCEDURE IsBackSlash(c: CHAR): BOOLEAN;
	RETURN (c = "\") OR (c = "/") & autoCorrectDirSeparator
	END IsBackSlash;
BEGIN
	IF Platform.Posix THEN
		WHILE (j < LEN(s)) & (s[j] = "'") & (i < LEN(d) - 4) DO
			d[i    ] := "'";
			d[i + 1] := "\";
			d[i + 2] := "'";
			d[i + 3] := "'";
			INC(i, 4);
			INC(j)
		ELSIF (j < LEN(s)) & (s[j] # Utf8.Null) & (i < LEN(d) - 1) DO
			IF (s[j] # "\") OR ~autoCorrectDirSeparator THEN
				d[i] := s[j]
			ELSE
				d[i] := "/"
			END;
			INC(i);
			INC(j)
		END
	ELSE ASSERT(Platform.Windows);
		(* TODO побороть безумную интерпретацию в cmd *)
		WHILE (j < LEN(s)) & (s[j] # Utf8.Null) DO
			IF IsBackSlash(s[j]) THEN
				k := 0;
				REPEAT
					INC(k);
					INC(j)
				UNTIL (j = LEN(s)) OR ~IsBackSlash(s[j]);
				IF (j = LEN(s)) OR (s[j] = Utf8.Null) THEN
					IF ~parts THEN
						k := k * 2
					END
				ELSIF s[j] = Utf8.DQuote THEN
					k := k * 2 + 1
				END;
				IF i > LEN(d) - 1 - k THEN
					DEC(j);
					k := LEN(d) - 1 - i
				END;
				WHILE k > 0 DO
					d[i] := "\";
					INC(i);
					DEC(k)
				END
			ELSE
				d[i] := s[j];
				INC(i);
				INC(j)
			END
		END
	END;
	d[i] := Utf8.Null;
	IF i < LEN(d) - 1 THEN
		d[i + 1] := Utf8.Null
	END
	RETURN (j = LEN(s)) OR (s[j] = Utf8.Null)
END Copy;

PROCEDURE Quote(VAR d: ARRAY OF CHAR; VAR i: INTEGER): BOOLEAN;
VAR ok: BOOLEAN;
BEGIN
	ok := i < LEN(d) - 1;
	IF ok & ~Platform.Java THEN
		IF Platform.Posix THEN
			d[i] := "'"
		ELSE ASSERT(Platform.Windows);
			d[i] := Utf8.DQuote
		END;
		INC(i);
		d[i] := Utf8.Null
	END
	RETURN ok
END Quote;

PROCEDURE FullCopy(VAR d: ARRAY OF CHAR; VAR i: INTEGER;
                   s: ARRAY OF CHAR; j: INTEGER): BOOLEAN;
	RETURN Quote(d, i) & Copy(d, i, s, j, FALSE) & Quote(d, i)
END FullCopy;

PROCEDURE Init*(VAR c: Code; name: ARRAY OF CHAR): BOOLEAN;
VAR ok: BOOLEAN;
BEGIN
	V.Init(c);
	c.parts := FALSE;
	c.len := 0;
	IF name = "" THEN
		c.buf[c.len] := Utf8.Null;
		ok := TRUE
	ELSIF Platform.Posix THEN
		ok := FullCopy(c.buf, c.len, name, 0)
	ELSE ASSERT(Platform.Windows);
		ok := Copy(c.buf, c.len, name, 0, c.parts)
	END
	RETURN ok
END Init;

PROCEDURE AddByOfs*(VAR c: Code; arg: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
VAR ok: BOOLEAN;
BEGIN
	ok := c.len < LEN(c.buf) - 1;
	IF ok THEN
		IF c.len > 0 THEN
			c.buf[c.len] := " ";
			INC(c.len);
			ok := FullCopy(c.buf, c.len, arg, ofs)
		ELSIF Platform.Posix THEN
			ok := FullCopy(c.buf, c.len, arg, ofs)
		ELSE ASSERT(Platform.Windows);
			ok := Copy(c.buf, c.len, arg, ofs, c.parts)
		END
	END
	RETURN ok
END AddByOfs;

PROCEDURE Add*(VAR c: Code; arg: ARRAY OF CHAR): BOOLEAN;
	RETURN AddByOfs(c, arg, 0)
END Add;

PROCEDURE AddClean*(VAR c: Code; arg: ARRAY OF CHAR): BOOLEAN;
	RETURN Strings.CopyCharsNull(c.buf, c.len, arg)
END AddClean;

PROCEDURE AddDirSep*(VAR c: Code): BOOLEAN;
VAR ok: BOOLEAN;
BEGIN
	ok := c.len < LEN(c.buf) - 1;
	IF ok THEN
		c.buf[c.len] := dirSep[0];
		INC(c.len);
		c.buf[c.len] := Utf8.Null
	END
	RETURN ok
END AddDirSep;

PROCEDURE FirstPart*(VAR c: Code; arg: ARRAY OF CHAR): BOOLEAN;
VAR ok: BOOLEAN;
BEGIN
	ASSERT(~c.parts);
	c.parts := TRUE;

	ok := c.len < LEN(c.buf) - 3;
	IF ok THEN
		IF c.len > 0 THEN
			c.partsQuote := TRUE;
			c.buf[c.len] := " ";
			INC(c.len)
		ELSE
			c.partsQuote := Platform.Posix
		END;
		ok := ok & (~c.partsQuote OR Quote(c.buf, c.len))
		         & Copy(c.buf, c.len, arg, 0, c.parts)
	END
	RETURN ok
END FirstPart;

PROCEDURE AddPart*(VAR c: Code; arg: ARRAY OF CHAR): BOOLEAN;
BEGIN
	ASSERT(c.parts)

	RETURN Copy(c.buf, c.len, arg, 0, c.parts)
END AddPart;

PROCEDURE LastPart*(VAR c: Code; arg: ARRAY OF CHAR): BOOLEAN;
BEGIN
	ASSERT(c.parts);
	c.parts := FALSE

	RETURN Copy(c.buf, c.len, arg, 0, c.parts) & (~c.partsQuote OR Quote(c.buf, c.len))
END LastPart;

PROCEDURE Log*(c: Code);
BEGIN
	log.StrLn(c.buf)
END Log;

PROCEDURE Do*(c: Code): INTEGER;
BEGIN
	ASSERT(0 < c.len)
	RETURN OsExec.Do(c.buf)
END Do;

PROCEDURE AutoCorrectDirSeparator*(state: BOOLEAN);
BEGIN
	autoCorrectDirSeparator := state
END AutoCorrectDirSeparator;

BEGIN
	autoCorrectDirSeparator := FALSE;

	IF Platform.Posix THEN
		dirSep[0] := "/"
	ELSE ASSERT(Platform.Windows);
		dirSep[0] := "\"
	END
END PlatformExec.

Init { Add | AddClean | ( FirstPart { AddPart } LastPart ) } [ Do ]

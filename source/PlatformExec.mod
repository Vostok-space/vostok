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
	Vlog := Log,
	Platform,
	Strings := StringStore;

CONST
	CodeSize* = 65536;

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
               s: ARRAY OF CHAR; j: INTEGER): BOOLEAN;
BEGIN
	(* TODO экранирование для windows *)
	WHILE Platform.Posix & (j < LEN(s)) & (s[j] = "'") & (i < LEN(d) - 4) DO
		d[i    ] := "'";
		d[i + 1] := "\";
		d[i + 2] := "'";
		d[i + 3] := "'";
		INC(i, 4);
		INC(j)
	ELSIF (j < LEN(s)) & (s[j] # Utf8.Null) & (i < LEN(d) - 1) DO
		d[i] := s[j];
		IF ~autoCorrectDirSeparator THEN
			;
		ELSIF s[j] = "/" THEN
			IF Platform.Windows THEN
				d[i] := "\"
			END
		ELSIF s[j] = "\" THEN
			IF Platform.Posix THEN
				d[i] := "/"
			END
		END;
		INC(i);
		INC(j)
	END;
	d[i] := Utf8.Null
	RETURN (j = LEN(s)) OR (s[j] = Utf8.Null)
END Copy;

PROCEDURE Quote(VAR d: ARRAY OF CHAR; VAR i: INTEGER): BOOLEAN;
VAR ok: BOOLEAN;
BEGIN
	ok := i < LEN(d) - 1;
	IF ok THEN
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

PROCEDURE FullCopy(VAR d: ARRAY OF CHAR; VAR i: INTEGER; s: ARRAY OF CHAR; j: INTEGER): BOOLEAN;
	RETURN Quote(d, i) & Copy(d, i, s, j) & Quote(d, i)
END FullCopy;

PROCEDURE Init*(VAR c: Code; name: ARRAY OF CHAR): BOOLEAN;
VAR ok: BOOLEAN;
BEGIN
	V.Init(c);
	c.parts := FALSE;
	c.len := 0;
	IF name[0] = Utf8.Null THEN
		c.buf[0] := Utf8.Null;
		ok := TRUE
	ELSIF Platform.Posix THEN
		ok := FullCopy(c.buf, c.len, name, 0)
	ELSE
		ok := Copy(c.buf, c.len, name, 0)
	END
	RETURN ok
END Init;

PROCEDURE Add*(VAR c: Code; arg: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
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
			ok := Copy(c.buf, c.len, arg, ofs)
		END
	END
	RETURN ok
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
		         & Copy(c.buf, c.len, arg, 0)
	END
	RETURN ok
END FirstPart;

PROCEDURE AddPart*(VAR c: Code; arg: ARRAY OF CHAR): BOOLEAN;
BEGIN
	ASSERT(c.parts)

	RETURN Copy(c.buf, c.len, arg, 0)
END AddPart;

PROCEDURE LastPart*(VAR c: Code; arg: ARRAY OF CHAR): BOOLEAN;
BEGIN
	ASSERT(c.parts);
	c.parts := FALSE

	RETURN Copy(c.buf, c.len, arg, 0) & (~c.partsQuote OR Quote(c.buf, c.len))
END LastPart;

PROCEDURE Do*(c: Code): INTEGER;
BEGIN
	ASSERT(0 < c.len)
	RETURN OsExec.Do(c.buf)
END Do;

PROCEDURE Log*(c: Code);
BEGIN
	Vlog.StrLn(c.buf)
END Log;

PROCEDURE AutoCorrectDirSeparator*(state: BOOLEAN);
BEGIN
	autoCorrectDirSeparator := state
END AutoCorrectDirSeparator;

BEGIN
	autoCorrectDirSeparator := FALSE;

	IF Platform.Posix THEN
		dirSep := "/"
	ELSE ASSERT(Platform.Windows);
		dirSep := "\"
	END
END PlatformExec.

Init { Add | AddClean | ( FirstPart { AddPart } LastPart ) } [ Do ]

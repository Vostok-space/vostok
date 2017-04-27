MODULE PlatformExec;

IMPORT
	V,
	Utf8,
	OsExec,
	Vlog := Log;

CONST
	CodeSize* = 65536;

	Ok* = 0;

TYPE
	Code* = RECORD(V.Base)
		buf: ARRAY CodeSize OF CHAR;
		len: INTEGER
	END;

PROCEDURE Copy(VAR d: ARRAY OF CHAR; VAR i: INTEGER; s: ARRAY OF CHAR; VAR j: INTEGER): BOOLEAN;
BEGIN
	WHILE (i < LEN(d) - 4) & (s[j] = "'") DO
		d[i] := "'";
		d[i + 1] := "\";
		d[i + 2] := "'";
		d[i + 3] := "'";
		INC(i, 4);
		INC(j)
	ELSIF (i < LEN(d) - 1) & (s[j] # Utf8.Null) DO
		d[i] := s[j];
		INC(i);
		INC(j)
	END;
	d[i] := Utf8.Null
	RETURN s[j] = Utf8.Null
END Copy;

PROCEDURE FullCopy(VAR d: ARRAY OF CHAR; VAR i: INTEGER; s: ARRAY OF CHAR; j: INTEGER): BOOLEAN;
VAR ret: BOOLEAN;
BEGIN
	d[i] := "'";
	INC(i);
	ret := Copy(d, i, s, j);
	IF ret THEN
		d[i] := "'"; (* TODO*)
		INC(i);
		d[i] := Utf8.Null
	END;

	RETURN s[j] = Utf8.Null
END FullCopy;

PROCEDURE Init*(VAR c: Code; name: ARRAY OF CHAR): BOOLEAN;
BEGIN
	V.Init(c);
	c.len := 0
	RETURN (name[0] = Utf8.Null)
	    OR FullCopy(c.buf, c.len, name, 0)
END Init;

PROCEDURE Add*(VAR c: Code; arg: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
VAR ret: BOOLEAN;
BEGIN
	ret := c.len < LEN(c.buf) - 1;
	IF ret THEN
		c.buf[c.len] := " ";
		INC(c.len);
		ret := FullCopy(c.buf, c.len, arg, ofs)
	END
	RETURN ret
END Add;

PROCEDURE AddClean*(VAR c: Code; arg: ARRAY OF CHAR): BOOLEAN;
VAR ofs: INTEGER;
BEGIN
	ofs := 0;
	RETURN Copy(c.buf, c.len, arg, ofs)
END AddClean;

PROCEDURE FirstPart*(VAR c: Code; arg: ARRAY OF CHAR): BOOLEAN;
VAR ret: BOOLEAN;
	ofs: INTEGER;
BEGIN
	ret := c.len < LEN(c.buf) - 2;
	IF ret THEN
		c.buf[c.len] := " ";
		c.buf[c.len + 1] := "'";
		INC(c.len, 2);
		ofs := 0;
		ret := Copy(c.buf, c.len, arg, ofs)
	END
	RETURN ret
END FirstPart;

PROCEDURE AddPart*(VAR c: Code; arg: ARRAY OF CHAR): BOOLEAN;
VAR ofs: INTEGER;
BEGIN
	ofs := 0
	RETURN Copy(c.buf, c.len, arg, ofs)
END AddPart;

PROCEDURE LastPart*(VAR c: Code; arg: ARRAY OF CHAR): BOOLEAN;
VAR ret: BOOLEAN;
	ofs: INTEGER;
BEGIN
	ofs := 0;
	ret := Copy(c.buf, c.len, arg, ofs) & (c.len < LEN(c.buf) - 2);
	IF ret THEN
		c.buf[c.len] := "'";
		c.buf[c.len + 1] := Utf8.Null;
		INC(c.len, 2);
	END
	RETURN ret
END LastPart;

PROCEDURE Do*(VAR c: Code): INTEGER;
BEGIN
	ASSERT(c.len > 0);
	RETURN OsExec.Do(c.buf)
END Do;

PROCEDURE Log*(c: Code);
BEGIN
	Vlog.StrLn(c.buf)
END Log;

END PlatformExec.

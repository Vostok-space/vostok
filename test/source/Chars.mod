MODULE Chars;

IMPORT O := Out;

CONST
	c2 = 030X;
	str = "12	";

TYPE Ch = ARRAY 7 OF CHAR;
    C32 = ARRAY 5 OF CHAR;

VAR ch: CHAR;

PROCEDURE Set(VAR c: Ch);
BEGIN
	c := "321"
END Set;

PROCEDURE Copy(VAR d: ARRAY OF C32; s: ARRAY OF C32);
VAR i: INTEGER;
BEGIN
	i := 0;
	WHILE s[i] # 0X DO
		d[i] := s[i];
		i := 1 + i
	END;
	d[i] := ""
END Copy;

PROCEDURE Equal(s, d: ARRAY OF C32): BOOLEAN;
VAR i: INTEGER;
BEGIN
	i := 0;
	WHILE (s[i] # 0X) & (s[i] = d[i]) DO
		INC(i)
	END
RETURN
	d[i] = s[i]
END Equal;

PROCEDURE EqualAll(s, d: ARRAY OF ARRAY OF C32): BOOLEAN;
VAR i: INTEGER;
BEGIN
	i := 0;
	WHILE (i < LEN(s)) & Equal(s[i], d[i]) DO
		i := i + 1
	END
RETURN
	i = LEN(s)
END EqualAll;

PROCEDURE Go*;
VAR c: Ch; a, b: ARRAY 7 OF C32; a1, b1: ARRAY 2 OF ARRAY 7 OF C32;
BEGIN
	ASSERT(ORD(c2) = 3 * 16);
	O.Char("a");
	ch := "b";
	O.Char(c2);
	O.Char(ch);
	O.Ln;
	O.String(str);
	O.Ln;
	ch := c2;

	Set(c);
	ASSERT(c = "321");

	a[0] := "К";
	a[1] := "у";
	a[2] := "б";
	a[3] := "и";
	a[4] := "з";
	a[5] := "м";
	a[6] := 0X;
	b[0] := "Z";
	ASSERT(~Equal(a, b));
	Copy(b, a);
	ASSERT(Equal(a, b));
	ASSERT(Equal(b, a));
	a1[0][0] := "Ы";
	b1[0][0] := "Ї";
	ASSERT(~EqualAll(a1, b1))
END Go;

END Chars.

MODULE Sandbox;

  IMPORT log;

  CONST Enough = 4;

  TYPE CharUtf8 = ARRAY Enough + 1 OF CHAR;

  VAR rd: INTEGER;

  PROCEDURE ReadChar(VAR ch: CharUtf8);
  BEGIN
    rd := 1 - rd;
    IF rd = 1 THEN
      ch := "Б"
    ELSE
      ch := "б"
    END
  END ReadChar;

  PROCEDURE Go*;
  VAR ch: CharUtf8; i: INTEGER;
  BEGIN
    FOR i := 0 TO 1 DO
      ReadChar(ch);
      log.bn(("А" <= ch) & (ch <= "Я"))
    END
  END Go;

BEGIN
  rd := 0
END Sandbox.

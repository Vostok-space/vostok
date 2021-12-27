MODULE Chars;

IMPORT O := Out;

CONST
	c2 = 030X;
	str = "12	";

TYPE Ch = ARRAY 7 OF CHAR;

VAR ch: CHAR;

PROCEDURE Set(VAR c: Ch);
BEGIN
	c := "321"
END Set;

PROCEDURE Go*;
VAR c: Ch;
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
	ASSERT(c = "321")
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

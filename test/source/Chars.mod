MODULE Chars;

IMPORT O := Out;

CONST
	c2 = 030X;
	str = "12	";

TYPE

VAR ch: CHAR;

PROCEDURE Go*;
BEGIN
	ASSERT(ORD(c2) = 3 * 16);
	O.Char("a");
	ch := "b";
	O.Char(c2);
	O.Char(ch);
	O.Ln;
	O.String(str);
	O.Ln;
	ch := c2
END Go;

END Chars.


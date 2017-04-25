MODULE Mult;

IMPORT Out;

CONST
	a = 3;
	b = TRUE;

TYPE

VAR

PROCEDURE Go*;
BEGIN
	Out.Int(a * a * 3 * 4, 0);
	Out.Ln;
	Out.Int(ORD((a >= 3) & (a >= 3) & (b)), 0);
	Out.Ln
END Go;

END Mult.

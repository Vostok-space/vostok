MODULE Real;

IMPORT Out;

CONST

TYPE

PROCEDURE Go;
VAR a, b, c: REAL;
BEGIN
	a := 0.1;
	b := 0.2;
	c := 1.0;
	c := a * b + c;
	Out.Real(c, 0);
	ASSERT(c = 1.02);
	Out.Ln
END Go;

BEGIN
	Out.Open
END Real.

MODULE Real;

IMPORT Out;

CONST

TYPE

PROCEDURE Pack;
VAR a: REAL;
BEGIN
	a := 1.0;
	PACK(a, 30);
	ASSERT(a = FLT(ORD({30})));

	PACK(a, 27);
	ASSERT(a = FLT(ORD({30})) * FLT(ORD({27})));
END Pack;

PROCEDURE Go*;
VAR a, b, c: REAL;

BEGIN
	a := 0.1;
	b := 0.2;
	c := 1.0;
	c := a * b + c;
	Out.Real(c, 0); Out.Ln;
	ASSERT(c = 1.02);

	Pack
END Go;

BEGIN
	Out.Open
END Real.

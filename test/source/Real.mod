MODULE Real;

IMPORT Out;

CONST
	ac = 1.0E307;
	bc* = ac;

VAR p1, p2: POINTER TO RECORD END;

PROCEDURE Pack(sign: INTEGER);
VAR a, b, c, one: REAL;
    n: INTEGER;
BEGIN
	ASSERT(ABS(sign) = 1);

	one := FLT(sign);
	a := one;
	PACK(a, 30);
	ASSERT(a = one * FLT(ORD({30})));

	b := a;
	UNPK(b, n);
	Out.Real(b, 0); Out.Ln;
	ASSERT(b = one);
	ASSERT(n = 30);

	PACK(a, 77);
	c := one * FLT(ORD({30})) * FLT(ORD({30})) * FLT(ORD({30})) * FLT(ORD({17}));
	ASSERT(a = c);

	b := a;
	UNPK(b, n);
	ASSERT(b = one);
	ASSERT(n = 107);

	PACK(a, -201);
	b := a;
	UNPK(b, n);
	ASSERT(b = one);
	ASSERT(n = -94)

END Pack;

PROCEDURE Fail*;
VAR a, b, c, d, e: REAL;
BEGIN
	b := 0.0;
	c := 0.1;
	a := b / c;
	Out.Real(a, 0); Out.Ln;
	(*b := 0.0 / 0.0;*)

	d := 1.0 / 1.0E-30;
	IF FALSE THEN
		d := 1.0;
		e := 1.0
	END;
	IF TRUE THEN
		a := d * e
	END;
	Out.Real(a, 0); Out.Ln
END Fail;

PROCEDURE Go*;
VAR a, b, c: REAL;
BEGIN
	a := 0.1;
	b := 0.2;
	c := 1.0;
	c := a * b + c;
	Out.Real(c, 0); Out.Ln;
	ASSERT(c = 1.02);

	Pack(+1);
	Pack(-1)
END Go;

BEGIN
	p1 := NIL;
	p2 := NIL;
	Out.Open
END Real.

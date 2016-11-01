MODULE Array;

CONST
	Len = 33;

TYPE

VAR
	a: ARRAY Len OF CHAR;
	p: PROCEDURE(a: ARRAY OF CHAR);
	aaa: ARRAY 4, 4, 4 OF INTEGER;
	bb: ARRAY 4, 5, 6 OF INTEGER;


PROCEDURE B(b: ARRAY OF CHAR);
VAR c: CHAR;
	l: INTEGER;
BEGIN
	c := b[32];
	l := LEN(b);
	ASSERT(Len = l)
END B;

PROCEDURE A(a: ARRAY OF CHAR);
CONST TYPE VAR
BEGIN
	IF FALSE THEN
		p(a)
	ELSE
		B(a)
	END
END A;

PROCEDURE C;
VAR c: ARRAY 3, 4, 5 OF INTEGER;
	i: INTEGER;
BEGIN
	c[2][2][2] := 222;
	i := c[1][2][3];
	i := aaa[2, 1, 0]
END C;

BEGIN
	p := A;
	p(a);
	A(a);
	C;
	ASSERT(LEN(bb) = 4);
	ASSERT(LEN(bb[0]) = 5);
	ASSERT(LEN(bb[0, 0]) = 6)
END Array.

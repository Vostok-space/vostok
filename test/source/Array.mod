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
	ELSIF 5 * 6 = 11 THEN
		p("11")
	ELSE
		B(a)
	END
END A;

PROCEDURE L0(a: ARRAY OF ARRAY OF INTEGER): INTEGER;
	RETURN LEN(a)
END L0;

PROCEDURE L11(a: ARRAY OF INTEGER): INTEGER;
RETURN LEN(a)
END L11;

PROCEDURE L1(a: ARRAY OF ARRAY OF INTEGER): INTEGER;
RETURN
	L11(a[1])

	(* a[1, 1] *)
END L1;

PROCEDURE S1(VAR a: ARRAY OF ARRAY OF INTEGER);
BEGIN
	a[LEN(a) - 1][LEN(a[0]) - 1] := 111;
	a[0][0] := 111;
	a[LEN(a) DIV 2][LEN(a[0]) DIV 2] := 111;
END S1;

PROCEDURE C;
VAR c: ARRAY 3, 4, 5 OF INTEGER;
	i: INTEGER;
BEGIN
	c[2][2][2] := 222;
	i := c[1][2][3];
	i := aaa[2, 1, 0]
END C;

PROCEDURE F(bb: ARRAY OF ARRAY OF ARRAY OF INTEGER);
BEGIN
	ASSERT(L0(bb[0]) = 5);
	ASSERT(L1(bb[0]) = 6);
	ASSERT(L11(bb[0][1]) = 6)
END F;

PROCEDURE Fs(VAR bb: ARRAY OF ARRAY OF ARRAY OF INTEGER);
BEGIN
	ASSERT(L0(bb[0]) = 5);
	ASSERT(L1(bb[0]) = 6);
	ASSERT(L11(bb[0][1]) = 6);
	S1(bb[0]);
	S1(bb[LEN(bb) - 1])
END Fs;

PROCEDURE For;
VAR i: INTEGER;
	a: ARRAY 3 OF INTEGER;
BEGIN
	a[0] := 0;
	FOR i := -1 TO LEN(a) DO
		INC(a[0])
	END;
	ASSERT(a[0] = 5)
END For;

PROCEDURE Set(VAR a: ARRAY OF ARRAY OF ARRAY OF INTEGER; i: INTEGER);
BEGIN
	a[i][i - 1][i + 1] := 777
END Set;

PROCEDURE Setbb(i, j ,k: INTEGER);
BEGIN
	bb[i][j][k] := 0FFH
END Setbb;

PROCEDURE Go*;
BEGIN
	p := A;
	p(a);
	A(a);
	C;
	S1(bb[0]);

	ASSERT(LEN(bb) = 4);
	ASSERT(LEN(bb[0]) = 5);
	ASSERT(LEN(bb[0, 0]) = 6);
	ASSERT(LEN(bb[0][0]) = 6);

	ASSERT(L0(bb[0]) = 5);
	ASSERT(L1(bb[0]) = 6);
	ASSERT(L11(bb[0][1]) = 6);

	F(bb);
	Fs(bb);

	Set(bb, 2);
	ASSERT(bb[2][1][3] = 777);

	Setbb(2, 1, 3);
	ASSERT(bb[2][1][3] = 0FFH)
END Go;

PROCEDURE Error*(s: INTEGER);
BEGIN
	IF 0 = s THEN
		Set(aaa, 0)
	END;
	IF 1 = s THEN
		Set(aaa, 3)
	END
END Error;

END Array.

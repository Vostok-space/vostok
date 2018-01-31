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

PROCEDURE A(pa: ARRAY OF CHAR);
CONST TYPE VAR
BEGIN
	IF FALSE THEN
		p(pa)
	ELSIF 5 * 6 = 11 THEN
		p("11")
	ELSE
		B(pa)
	END
END A;

PROCEDURE L0(pa: ARRAY OF ARRAY OF INTEGER): INTEGER;
	RETURN LEN(pa)
END L0;

PROCEDURE L11(pa: ARRAY OF INTEGER): INTEGER;
RETURN LEN(pa)
END L11;

PROCEDURE L1(pa: ARRAY OF ARRAY OF INTEGER): INTEGER;
RETURN
	L11(pa[1])

	(* pa[1, 1] *)
END L1;

PROCEDURE S1(VAR pa: ARRAY OF ARRAY OF INTEGER);
BEGIN
	pa[LEN(pa) - 1][LEN(pa[0]) - 1] := 111;
	pa[0][0] := 111;
	pa[LEN(pa) DIV 2][LEN(pa[0]) DIV 2] := 111;
END S1;

PROCEDURE C;
VAR c: ARRAY 3, 4, 5 OF INTEGER;
	i: INTEGER;
BEGIN
	c[2][2][2] := 222;
	c[1][2][3] := 0;
	i := c[1][2][3];
	i := aaa[2, 1, 0]
END C;

PROCEDURE F(pbb: ARRAY OF ARRAY OF ARRAY OF INTEGER);
BEGIN
	ASSERT(L0(pbb[0]) = 5);
	ASSERT(L1(pbb[0]) = 6);
	ASSERT(L11(pbb[0][1]) = 6)
END F;

PROCEDURE Fs(VAR pbb: ARRAY OF ARRAY OF ARRAY OF INTEGER);
BEGIN
	ASSERT(L0(pbb[0]) = 5);
	ASSERT(L1(pbb[0]) = 6);
	ASSERT(L11(pbb[0][1]) = 6);
	S1(pbb[0]);
	S1(pbb[LEN(pbb) - 1])
END Fs;

PROCEDURE For;
VAR i: INTEGER;
	ai: ARRAY 3 OF INTEGER;
BEGIN
	ai[0] := 0;
	FOR i := -1 TO LEN(ai) DO
		INC(ai[0])
	END;
	ASSERT(ai[0] = 5)
END For;

PROCEDURE Set(VAR pa: ARRAY OF ARRAY OF ARRAY OF INTEGER; i: INTEGER);
BEGIN
	pa[i][i - 1][i + 1] := 777
END Set;

PROCEDURE Setbb(i, j ,k: INTEGER);
BEGIN
	bb[i][j][k] := 0FFH
END Setbb;

PROCEDURE CopyChars(a2: ARRAY OF CHAR);
VAR a1: ARRAY 32 OF CHAR;
BEGIN
	a1 := a2;
	IF LEN(a1) = LEN("0123456789") THEN
		ASSERT(a1 = "0123456789");
		ASSERT(a2 = "0123456789");
		ASSERT(a2 = a1)
	END
END CopyChars;

PROCEDURE CopyInts(VAR a1: ARRAY OF INTEGER; a2: ARRAY OF INTEGER);
VAR i: INTEGER;
BEGIN
	a1 := a2;
	FOR i := 0 TO LEN(a2) - 1 DO
		ASSERT(a1[i] = a2[i])
	END
END CopyInts;

PROCEDURE Go*;
VAR i: INTEGER;
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
	ASSERT(bb[2][1][3] = 0FFH);

	For;

	CopyChars("0123456789");
	CopyChars("0123456789012345678901234567890");

	FOR i := 0 TO LEN(bb[2][1]) - 1 DO
		bb[2, 1][i] := 3 * i + 2
	END;
	CopyInts(bb[1, 0], bb[2][1]);
	FOR i := 0 TO LEN(bb[2][1]) - 1 DO
		ASSERT(bb[1][0,i] = 3 * i + 2)
	END
END Go;

PROCEDURE Error*(s: INTEGER);
VAR ai1, ai2: ARRAY 7 OF INTEGER;
    ai3: ARRAY 8 OF INTEGER;
BEGIN
	ai2[0] := 0;
	ai1 := ai2;
	IF 0 = s THEN
		Set(aaa, 0)
	END;
	ai3[0] := 0;
	(*ai3 := ai1;*)
	IF 1 = s THEN
		Set(aaa, 3)
	END
END Error;

END Array.

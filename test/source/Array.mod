MODULE Array;

CONST
	Len = 33;

TYPE

VAR
	a*: ARRAY Len OF CHAR;
	p: PROCEDURE(a: ARRAY OF CHAR);
	aaa: ARRAY 4, 4, 4 OF INTEGER;
	bb: ARRAY 4 OF ARRAY 5, 6 OF INTEGER;
	ind: INTEGER;

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

PROCEDURE OfRecord;
TYPE Rec = RECORD i,j: INTEGER END;
VAR r: ARRAY 3 OF Rec; i: INTEGER;
BEGIN
	r[0].i := 1;
	r[1].i := 3;
	r[2].i := 5;
	FOR i := 0 TO LEN(r) - 1 DO
		r[i].j := -r[i].i
	END;
	ASSERT(r[0].j = -1);
	ASSERT(r[1].j = -3);
	ASSERT(r[2].j = -5)
END OfRecord;

PROCEDURE IncInd(add: INTEGER): INTEGER;
BEGIN
	INC(ind, add)
	RETURN ind
END IncInd;

PROCEDURE DecHalf(VAR i: INTEGER);
BEGIN
	DEC(i, i DIV 2)
END DecHalf;

PROCEDURE IncI(VAR i: INTEGER): INTEGER;
BEGIN
	INC(i, 1)
	RETURN
		i
END IncI;

PROCEDURE UseInc;
VAR ia: ARRAY 4, 4 OF INTEGER;
BEGIN
	ind := -1;

	ia[IncInd(1)][0] := 7;
	ASSERT(ia[0][0] = 7);
	ASSERT(ind = 0);

	ia[0][IncInd(1)] := -7;
	ASSERT(-ia[0][1] = 7);
	ASSERT(ind = 1);

	DecHalf(ia[0][IncInd(-1)]);
	ASSERT(ia[0][0] = 4)

END UseInc;

PROCEDURE BuiltinProc;
VAR ar: ARRAY 2, 2 OF INTEGER; i, j: INTEGER; sets: ARRAY 3 OF SET; rl: ARRAY 2 OF REAL; set: SET;
BEGIN
	FOR i := 0 TO 3 DO
		ar[i DIV 2, i MOD 2] := 0
	END;

	INC(ar[1,0]);
	ASSERT(ar[1,0] = 1);
	DEC(ar[0,1]);
	ASSERT(ar[0,1] = -1);

	INC(ar[0,1], 100);
	ASSERT(ar[0,1] = 99);
	DEC(ar[1,0], 30);
	ASSERT(ar[1,0] = -29);

	set := {1, 8};
	INCL(set, 31);
	ASSERT(set = {1, 8, 31});

	sets[2] := {};
	INCL(sets[2], 17);
	ASSERT({17} = sets[2]);

	sets[1] := {1..23};
	EXCL(sets[1], 13);
	ASSERT({1..12,14..23} = sets[1]);

	rl[0] := 0.5;
	PACK(rl[0], 4);
	ASSERT(rl[0] = 8.0);

	UNPK(rl[0], ar[0, 0]);
	ASSERT(rl[0] = 1.0);
	ASSERT(ar[0,0] = 3);

	sets[2] := {5..11} - {7};
	ind := 1;
	EXCL(sets[IncInd(1)], 6);
	ASSERT(sets[2] = {5, 8..11});

	ind := 0;
	INCL(sets[IncInd(2)], 7);
	ASSERT(sets[2] = {5, 7..11});

	rl[1] := -1.5;
	PACK(rl[IncInd(-1)], 7);
	ASSERT(rl[1] = -192.0);

	ind := -1 + ind;
	j := 0;
	ar[0][0] := 0;
	UNPK(rl[IncInd(1)], ar[IncI(ar[0][0])][IncI(j)]);
	ASSERT(rl[1] = -1.5);
	ASSERT(ar[1][1] = 7)
END BuiltinProc;

PROCEDURE Assign*;
VAR a1, a2: ARRAY 2,2 OF ARRAY 2 OF INTEGER;
	ar1, ar2: ARRAY 2 OF RECORD
		aar: ARRAY 3 OF ARRAY 4 OF RECORD
			i: INTEGER
		END
	END;
BEGIN
	a1[0][0][0] := 5;
	a1[0][0, 1] := 7;

	a1[0, 1] := a1[0][0];
	ASSERT(a1[0,1,0] = 5);
	ASSERT(a1[0,1,1] = 7);

	a1[0,1,1] := -7;
	ASSERT(-a1[0,1,1] = 7);
	ASSERT(a1[0,0,1] = 7);

	a1[1] := a1[0];
	ASSERT(-7 = a1[1][1][1]);
	ASSERT(5 = a1[1][1][0]);

	a1[0,1,1] := 8;
	ASSERT(a1[1,1,1] = -7);

	a2 := a1;
	ASSERT(a2[0,1,0] = 5);
	a2[1,1,1] := 908;
	ASSERT(a2[1,1,1] = 908);
	ASSERT(a1[1,1,1] = -7);

	ar1[0].aar[2, 1].i := 333;
	ar2 := ar1;
	ASSERT(ar2[-1+3-2].aar[24 DIV 10][5-4].i = 222+111);
	ar1[0].aar[2, 1].i := -101;
	ASSERT(333 = ar2[0].aar[2, 1].i)
END Assign;

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
	END;

	OfRecord;

	BuiltinProc;

	UseInc;

	Assign
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

BEGIN
	a[32] := 11X;
	aaa[2,1,0] := 99
END Array.

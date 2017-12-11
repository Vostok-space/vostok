MODULE Test;

IMPORT Out;

CONST
	baba* = 101;
	str = "babababa";
	real = 1.0E23;

(* Comment *)

TYPE
	RecA* = RECORD
		rec*: RECORD
			rec: RECORD
				r: REAL
			END
		END
	END;

	PoToRe = POINTER TO RecAB;
	RecAB = RECORD
		a, b: REAL;
		prab: POINTER TO RecAB;
		ptr: PoToRe
	END;


	ArOfPoToAr = ARRAY 23 OF POINTER TO RECORD
								i: INTEGER
								;a: BOOLEAN(*ArOfPoToAr*)
							END;


VAR
	variable1, variable2*: INTEGER;

	arrayOfChar: ARRAY 10, 100, 1000 OF CHAR;

	bfd: CHAR;
	rer: BOOLEAN;

	pointerToRecord, ptr2: POINTER TO RECORD a, b: INTEGER END;

	proc1: PROCEDURE(a: INTEGER);
	aaaa: ARRAY 3, 2, 1 OF INTEGER;

	r1*, r2, r3* : POINTER TO RECORD a: BOOLEAN END;

PROCEDURE A(VAR az: INTEGER; VAR c: CHAR; d	: 	BOOLEAN) : INTEGER;
CONST b = 11111 * 2 * 3;
VAR a, coco: INTEGER;
BEGIN
	az := b;
	a := 1;
	d := a = 1;
	a := ORD(d);
	coco := 1;
	a := baba + 5 * 4 * (coco DIV 32 + 67);
	WHILE a = 6 DO
		a := 7;
		WHILE a = 5 + 4 DO
			a := 6
		ELSIF a = 6 DO
			a := 7
		ELSIF a = 5 DO
			a := 4
		END
	END
	RETURN 0
END A;

PROCEDURE P1(VAR a: ARRAY OF INTEGER);
BEGIN
	a[0] := LEN(a)
END P1;

PROCEDURE P2(VAR a: ARRAY OF REAL);
VAR l: INTEGER;
BEGIN
	l := LEN(a)
END P2;


PROCEDURE BC*(aa: ARRAY OF ARRAY OF INTEGER);
VAR a: ARRAY 3 + 3, 2 * (2 + 9), 2 OF INTEGER;
	b: ARRAY 311 OF INTEGER;
	d: INTEGER;
BEGIN
	b[0] := aa[2][3];
	IF TRUE THEN
		REPEAT
			P1(a[2, 2]);
			d := A(d, arrayOfChar[0, 0, 0], FALSE);
			d := 0
		UNTIL ~(d = 0)
	ELSIF FALSE THEN
		d := 1
	ELSIF 0 = 0 THEN
		d := ABS(-2)
	ELSE
		d := 3
	END
END BC;

PROCEDURE Irma(b: INTEGER);
VAR c: INTEGER;
BEGIN
	b := LSL(2, 13);
	c := ASR(2, 12);
	INC(b);
	INC(b, 3);
	DEC(c);
	DEC(c, 6);
	CASE b OF
	  10 .. 12: Irma(08)
	| 08, 09: Irma(06)
	| 06: Irma(04)
	| 04: Irma(02)
	| 02: CASE 3 OF 3: Irma(0) END
	END
END Irma;

PROCEDURE Doo(p: PoToRe);
VAR a, b: RECORD c, b, d: INTEGER END;
BEGIN
	b.b := 1;
	a := b;
	p.a := 4444.;
	p^.b := 0.;

	NEW(pointerToRecord);
	ptr2 := pointerToRecord;
	a.c := 1;
	b := a;

	ptr2^ := pointerToRecord^;

	NEW(ptr2)
END Doo;

PROCEDURE Boo(VAR r: RecA);
VAR pTo: POINTER TO RecA;
BEGIN
	pTo := NIL;
	NEW(pTo);
	IF pTo # NIL THEN
		Boo(pTo^)
	END
END Boo;

PROCEDURE String(p: ARRAY OF CHAR);
END String;

PROCEDURE Go*;
VAR p: PoToRe;
    r: RecA;
    aor: ARRAY 2 OF REAL;
    i: INTEGER;
    b: BOOLEAN;
    aop: ArOfPoToAr;
BEGIN
	NEW(p);
	i := ORD(str[0]);
	Doo(p);
	variable1 := 0;
	proc1 := Irma;
	Out.String("Hello"); Out.Ln;
	String("Hello");

	IF 0 > 1 THEN
		Boo(r);
		P2(aor);
		b := FALSE;
		rer := b;
		i := A(i, bfd, b);
		aaaa[0,0,0] := 3;
		aop[0] := NIL;
		i := LEN(str);
		aor[0] := real
	END
END Go;

PROCEDURE Fail*;
VAR rab: RecAB;
BEGIN
	rab.a := 4.0;
	rab.a := rab.a + rab.b
END Fail;

BEGIN
	r1 := NIL;
	r2 := NIL;
	r3 := NIL
END Test.

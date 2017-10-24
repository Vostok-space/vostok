MODULE Record;

(*
IMPORT RecordExt;
*)
TYPE
	R1 = RECORD
		a: INTEGER
	END;

	R2 = RECORD(R1)
		b: REAL
	END;

	R3 = RECORD(R2)
		r2: R2
	END;

	Record* = RECORD(*(RecordExt.Base)*)
		b: ARRAY 3 OF BOOLEAN
	END;

	PRec = POINTER TO Record;

(*
	PRec11 = POINTER TO Record11;
*)

VAR
	r1: R1;
	r2: R2;
	pr1: POINTER TO R1;
	pr2: POINTER TO R2;
	r3: R3;

PROCEDURE Pr1*(VAR p1: R1);
TYPE
	R = RECORD(R3)
		r: REAL
	END;
VAR r: R;

	PROCEDURE Check(r: R);
		PROCEDURE P(r: R1);
		BEGIN
			ASSERT(r IS R2);
			ASSERT(r IS R3)
		END P;
	BEGIN
		IF r.r = 0.0 THEN
			P(r)
		END
	END Check;
BEGIN
	r.r := 0.1;
	ASSERT(r.r = 0.1);
	Check(r)
END Pr1;

PROCEDURE Pr(p: PRec);
VAR l: INTEGER;
	p2: PRec;
BEGIN
	p2 := p;
	l := LEN(p.b);
	l := LEN(p2.b)
END Pr;

PROCEDURE Fail*;
VAR lr3: R3;
	b: REAL;
BEGIN
	lr3.a := 0;
	b := lr3.b + FLT(lr3.a)
END Fail;

PROCEDURE Fail2*;
VAR pr3: POINTER TO R3;
	b: REAL;
BEGIN
	NEW(pr3);
	pr3.a := 0;
	b := pr3.b + FLT(pr3.a)
END Fail2;

PROCEDURE Go*;
BEGIN
	r1.a := 0;
	r2.b := 1.0;
	r2.a := 2;

	ASSERT(r1.a = 0);
	ASSERT(r2.b = 1.0);
	ASSERT(r2.a = 2);

	r1 := r2;

	ASSERT(r1.a = 2);
	ASSERT(r2.a = 2);
	ASSERT(r2.b = 1.0);

	NEW(pr2);
	pr2.a := 3;
	pr1 := pr2;

	ASSERT(pr1.a = 3);
	ASSERT(pr2.a = 3);

	Pr1(r1);
	Pr1(r2);

	r3.r2.a := 4;
	r3.r2.b := 5.0;
	r3.b := 6.0;
	r2.a := 7;
	ASSERT(r3.r2.a = 4)
END Go;

BEGIN
	IF 0 > 1 THEN
		Pr(NIL)
	END
END Record.

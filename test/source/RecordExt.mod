MODULE RecordExt;

IMPORT Out;

TYPE
	Base* = RECORD
		a: INTEGER
	END;

	Ext1 = RECORD(Base)
		r: REAL
	END;

	Ext2 = RECORD(Base)
		c: CHAR
	END;

	Ext21 = RECORD(Ext2)
		b: BOOLEAN
	END;

	Pr* = POINTER TO RECORD
	END;

	PBase = POINTER TO Base;
	PExt1 = POINTER TO Ext1;

VAR
	b	: Base;
	e1	: Ext1;
	e2	: Ext2;
	e21	: Ext21;
	pb	: POINTER TO Base;
	pb1	: PBase;
	pe1	: PExt1;

PROCEDURE Print(VAR par: Base);
VAR i: INTEGER;
	r1: REAL;
BEGIN
	Out.String("Print: "); Out.Char(09X);
	IF par IS Ext1 THEN
		r1 := par(Ext1).r;
		i := FLOOR(r1);
		Out.String("Ext1: r = "); Out.Int(i, 0)
	ELSIF par IS Ext2 THEN
		Out.String("Ext2: c = "); Out.Int(ORD(par(Ext2).c), 0)
	ELSE
		Out.String("Base:")
	END;
	Out.String(" a = "); Out.Int(par.a, 0); Out.Ln
END Print;

PROCEDURE PrintExt21(VAR par: Base);
BEGIN
	Out.String("PrintExt21: "); Out.Char(" ");
	IF par IS Ext21 THEN
		Out.String("Ext21: r = "); Out.Int(ORD(par(Ext21).c), 0);
		Out.String(" par = "); Out.Int(ORD(par(Ext21).b), 0)
	ELSE
		Out.String("Base:")
	END;
	Out.String(" a = "); Out.Int(par.a, 0); Out.Ln
END PrintExt21;

PROCEDURE Pointer(par: PBase);
BEGIN
	IF par # NIL THEN
		par(PExt1).r := 111.0
	END
END Pointer;

PROCEDURE Go*;
BEGIN
	b.a := 1;

	e1.a := 2;
	e1.r := 3.0;

	e2.a := 4;
	e2.c := 5X;

	e21.a := 6;
	e21.c := 7X;
	e21.b := TRUE;

	Print(b);
	Print(e1);
	Print(e2);
	Print(e21);

	Out.Ln;

	PrintExt21(b);
	PrintExt21(e1);
	PrintExt21(e2);
	PrintExt21(e21);

	pb1 := NIL;
	pe1 := NIL;
	ASSERT(pb1 = pe1);
	ASSERT(pe1 = pb1);

	Pointer(pb1);
	pb := pb1
END Go;

END RecordExt.

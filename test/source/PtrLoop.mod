MODULE PtrLoop;

CONST
	UnLoop = TRUE;

TYPE
	Ptr = POINTER TO RPtr;
	RPtr = RECORD
		i: INTEGER;
		next: Ptr
	END;

(*
PROCEDURE Fail*;
VAR p: Ptr;
BEGIN
	p := NIL;
	IF p.i = 3 THEN
		p := NIL
	END
END Fail;
*)

PROCEDURE Go*;
VAR p: Ptr;
BEGIN
	NEW(p); p.next := p;
	p.i := 2;
	INC(p.next.i);
	IF UnLoop THEN
		p.next := NIL
	END;
	ASSERT(p.i = 3);
	p := NIL
END Go;

END PtrLoop.

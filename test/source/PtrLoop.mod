MODULE PtrLoop;

CONST
	UnLoop = TRUE;

TYPE
	Ptr = POINTER TO RECORD
		i: INTEGER;
		next: Ptr
	END;

VAR
	p: Ptr;

PROCEDURE Go*;
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

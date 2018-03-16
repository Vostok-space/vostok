MODULE LinkedList;

IMPORT Out;

CONST
	N = 33;
	Print = FALSE;

TYPE
	List = POINTER TO RList;
	RList = RECORD
		val: INTEGER;
		next : List
	END;

PROCEDURE Create(count: INTEGER): List;
VAR f, l: List;
BEGIN
	NEW(f);
	f.val := count;
	f.next := NIL;
	l := f;
	WHILE count > 1 DO
		DEC(count);
		NEW(l.next);
		l := l.next;
		l.val := count;
		l.next := NIL
	END
	RETURN f
END Create;

PROCEDURE Unlink(list: List);
VAR l: List;
	i: INTEGER;
BEGIN
	i := N;
	WHILE list # NIL DO
		l := list;
		IF Print THEN
			Out.Int(i, 0); Out.String(") l.val = "); Out.Int(l.val, 0); Out.Ln
		END;
		ASSERT(l.val = i);
		DEC(i);
		list := l.next;
		l.next := NIL
	END
END Unlink;

PROCEDURE Go*;
VAR l: List;
BEGIN
	Unlink(Create(N));
	l := Create(N)
END Go;

END LinkedList.

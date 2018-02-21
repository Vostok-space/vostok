MODULE While;

CONST

TYPE

(*
PROCEDURE Error*;
VAR i, a, b: INTEGER;
BEGIN
	i := 0;
	WHILE i < 2 DO
		INC(i);
		a := b;
		b := i
	END
END Error;
*)

PROCEDURE Go*;
VAR i, a, b: INTEGER;
    pa: POINTER TO RECORD i: INTEGER END;
BEGIN
	i := 0;
	pa := NIL;
	WHILE i < 4 DO
		ASSERT(i < 4);
		INC(i);
		IF i = 2 THEN
			a := b;
			ASSERT(a = 1);
			a := pa.i;
			ASSERT(a = 7)
		END;
		b := i;
		NEW(pa); pa.i := 7
	END;
	ASSERT(i = 4)
END Go;

END While.

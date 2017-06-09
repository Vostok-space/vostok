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
BEGIN
	i := 0;
	WHILE i < 4 DO
		ASSERT(i < 4);
		INC(i);
		IF i = 2 THEN
			a := b;
			ASSERT(a = 1)
		END;
		b := i
	END;
	ASSERT(i = 4)
END Go;

END While.

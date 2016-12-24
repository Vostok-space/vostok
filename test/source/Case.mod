MODULE Case;

(*
PROCEDURE err(i: INTEGER);
VAR n: INTEGER;
BEGIN
	CASE i OF
	  0: n := 0
	| 2: n := 1
	| 4: n := 2
	| 6: n := 3
	| 8, 8 .. 8: n := 4
	| 8: n := 5
	END;
	ASSERT(i = n * 2)
END err;
*)

PROCEDURE case(i: INTEGER);
VAR n: INTEGER;
BEGIN
	CASE i OF
	  0: n := 0
	| 2: n := 1
	| 4: n := 2
	| 6: n := 3
	| 8: n := 4
	|10: n := 5
	END;
	ASSERT(i = n * 2)
END case;

PROCEDURE Go*;
VAR i: INTEGER;
BEGIN
	FOR i := 0 TO 5 DO
		case(i * 2)
	END
END Go;

BEGIN
	Go
END Case.

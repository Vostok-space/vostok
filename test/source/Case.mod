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

PROCEDURE caseChar(c: CHAR);
CONST a = CHR(ORD("a"));
VAR n: INTEGER;
BEGIN
	CASE c OF
	| a  : n := 0
	|"b" : n := 1
	|"c" : n := 2
	|"d" : n := 3
	|"e" : n := 4
	|"f" : n := 5
	|"g" : n := 6
	|"h" : n := 7
	|
	|"z" : ASSERT(FALSE)
	END;
	ASSERT(ORD(c) - ORD("a") = n)
END caseChar;

PROCEDURE Go*;
VAR i: INTEGER;
BEGIN
	FOR i := 0 TO 5 DO
		case(i * 2)
	END;

	FOR i := 0 TO 7 DO
		caseChar(CHR(i + ORD("a")))
	END
END Go;

END Case.

MODULE For;

(*
PROCEDURE Mistakes;
VAR i, j: INTEGER;
BEGIN
	FOR i := 0 TO Count DO
		j := i
	END;
	j := 0;
	FOR i := 0 TO -1 DO
		INC(j)
	END;

	FOR i := 0 TO 1 BY -1 DO
		INC(j)
	END;

	FOR i := 0 TO 7FFFFFFFH DO
		INC(j)
	END;

	FOR i := 0 TO 7FFFFFFEH DO
		INC(j)
	END;

	FOR i := 0 TO -7FFFFFFEH BY -2 DO
		INC(j)
	END;

	FOR i := 0 TO -7FFFFFFDH BY -2 DO
		INC(j)
	END;

	FOR i := -7FFFFFFFH TO 7FFFFFFFH BY ORD(0 > 1) DO
		INC(i)
	END;

	FOR i := -7FFFFFFFH TO 7FFFFFFFH BY j DO
		INC(i)
	END
END Mistakes;
*)


PROCEDURE Inc(VAR i: INTEGER);
BEGIN
	INC(i)
END Inc;

PROCEDURE For;
VAR i, j: INTEGER;
BEGIN
	j := 0;
	FOR i := 0 TO 10 DO
		j := j + 1
	END;
	ASSERT((i = j) & (i = 11));

	j := 1;
	FOR i := 1 TO 13 BY 3 DO
		j := 3 + j
	END;
	ASSERT((i = j) & (i = 16));

	j := 22;
	FOR i := 22 TO -18 BY -1 DO
		j := -1 + j;
	END;
	ASSERT((i = j) & (i = -19));

	j := 9;
	FOR i := 9 TO -9 BY -2 DO
		j := j + (-2)
	END;
	ASSERT((i = j) & (i = -11))
END For;

PROCEDURE ForWithIteratorAlsoUsedAsVarArg;
VAR i, j: INTEGER;
BEGIN
	i := -1;
	(* Важно при трансляции в языки, где аналога VAR-параметра нет *)
	Inc(i);

	j := 0;
	FOR i := 0 TO 10 DO
		INC(j)
	END;
	ASSERT((i = j) & (i = 11));

	i := 1;
	FOR j := 1 TO 13 BY 3 DO
		INC(i, 3)
	END;
	ASSERT((i = j) & (i = 16));

	j := 22;
	FOR i := 22 TO -18 BY -1 DO
		DEC(j)
	END;
	ASSERT((i = j) & (i = -19));

	i := 9;
	FOR j := 9 TO -9 BY -2 DO
		DEC(i, 2)
	END;
	ASSERT((i = j) & (i = -11))
END ForWithIteratorAlsoUsedAsVarArg;

PROCEDURE Go*;
BEGIN
	For;
	ForWithIteratorAlsoUsedAsVarArg
END Go;

END For.

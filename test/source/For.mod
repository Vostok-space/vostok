MODULE For;

PROCEDURE Go*;
VAR i, j: INTEGER;
BEGIN
	j := 0;
	FOR i := 0 TO 10 DO
		INC(j)
	END;
	ASSERT((i = j) & (i = 11));

	j := 1;
	FOR i := 1 TO 13 BY 3 DO
		INC(j, 3)
	END;
	ASSERT((i = j) & (i = 16));

	j := 22;
	FOR i := 22 TO -18 BY -1 DO
		DEC(j)
	END;
	ASSERT((i = j) & (i = -19));

	j := 9;
	FOR i := 9 TO -9 BY -2 DO
		DEC(j, 2)
	END;
	ASSERT((i = j) & (i = -11))

END Go;

BEGIN
	Go
END For.

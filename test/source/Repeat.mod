MODULE Repeat;

PROCEDURE Go*;
VAR i, j: INTEGER;
BEGIN
	i := 11;
	j := 0;
	REPEAT
		DEC(i);
		ASSERT(i >= 0);
		INC(j)
	UNTIL i = 0;
	ASSERT(i = 0);
	ASSERT(j = 11)
END Go;

END Repeat.

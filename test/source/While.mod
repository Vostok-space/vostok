MODULE While;

CONST

TYPE

VAR i: INTEGER;

PROCEDURE Go*;
BEGIN
	i := 0;
	WHILE i < 4 DO
		ASSERT(i < 4);
		INC(i)
	END;
	ASSERT(i = 4)
END Go;

BEGIN
	Go
END While.

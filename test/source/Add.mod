MODULE Add;

PROCEDURE Go*;
VAR a, b, c: INTEGER;
BEGIN
	ASSERT(3 - 2 - 5 = -4);

	a := 3;
	b := 2;
	c := 5;
	ASSERT(a - b - c = -4)
END Go;

BEGIN
	Go
END Add.

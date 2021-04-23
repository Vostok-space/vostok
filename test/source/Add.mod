MODULE Add;

IMPORT Out;

CONST MAX* = 2147483647;


(* комментарий *)
PROCEDURE Go*;
VAR a, b, c, v: INTEGER;
BEGIN
	ASSERT(3 - 2 - 5 = -4);

	a := 3;
	b := 2;
	c := 5;
	ASSERT(a - b - c = -4);

	v := MAX;
	ASSERT(v + 0 > 0);

	ASSERT(+a - b = 1);
	ASSERT(-c + a = -2);
	ASSERT(-2 - (-3) = +1)
END Go;

PROCEDURE Add*(a, b: INTEGER);
BEGIN
	Out.Int(a + b, 0); Out.Ln
END Add;

END Add.

MODULE Const;

CONST
	A* = 77;
	B = -A;
	C = 7H;
	D* = C;
	E = 0FFX;
	F = E;
	Const = 4 + 5;

PROCEDURE Go*;
BEGIN
	ASSERT(A = 66 + 11);
	ASSERT(B = -78 + 1);
	ASSERT(C = (0 + 7 - 0));
	ASSERT(D = (3 + 4));
	ASSERT(E = F);
	ASSERT(E = CHR(255));
	ASSERT(CHR(255) = E);
	ASSERT(F = CHR(256 - 1));
	ASSERT(Const = 5+4)
END Go;

END Const.

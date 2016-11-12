MODULE Bool;

CONST

TYPE

VAR
	a, b, c: BOOLEAN;

PROCEDURE Go*;
BEGIN
	b := 0 < 1;
	a := b OR c & a;
	ASSERT(a);

	c := a OR FALSE;
	a := b OR c & a;
	ASSERT(a);

	b := ~a;
	ASSERT(~b = a)
END Go;

BEGIN
	Go
END Bool.

MODULE Char;

PROCEDURE C(c: CHAR): INTEGER;
	RETURN ORD(c)
END C;

PROCEDURE Go*;
VAR c: CHAR;
	i: INTEGER;
BEGIN
	i := 256;
	c := CHR(i - 1);
	i := C(CHR(i - 255));
	c := CHR(C(CHR(ORD(c) * 1)));
	c := CHR(C(CHR(255 - 25)));
	c := CHR(255);
	ASSERT(255 = ORD(c));
	ASSERT(249 < ORD(c) - 5)
END Go;

END Char.

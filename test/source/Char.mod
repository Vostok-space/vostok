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
	ASSERT(C("'") = 27H);
	ASSERT(C(" ") = 20H);
	ASSERT(255 = ORD(c));
	ASSERT(249 < ORD(c) - 5);
	ASSERT(" " < c);
	ASSERT(" " <= c);

	ASSERT(7FX = CHR(7FH));
	c := 7FX;
	CASE c OF
	7FX: ;
	END;

	c := 8FX;
	CASE c OF
	8FX: ;
	END;

	ASSERT(c = 8FX)
END Go;

END Char.

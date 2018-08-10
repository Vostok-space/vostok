MODULE Byte;

PROCEDURE B(b: BYTE): INTEGER;
	RETURN b
END B;

PROCEDURE I(i: INTEGER): INTEGER;
	RETURN i
END I;

PROCEDURE Go*;
VAR b: BYTE;
	i: INTEGER;
BEGIN
	i := 256;
	b := i - 1;
	ASSERT(b = 255);
	i := B(i - 255);
	ASSERT(i = 1);
	b := B(b * 1);
	b := B(255 - 25);
	ASSERT(b = 230);
	b := 255;
	ASSERT(255 = b);
	ASSERT(249 < b - 5);

	ASSERT(B(b) = 255);
	ASSERT(255 = I(b))
END Go;

BEGIN
	Go
END Byte.

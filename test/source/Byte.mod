MODULE Byte;

PROCEDURE B(b: BYTE): INTEGER;
	RETURN b
END B;

PROCEDURE Go*;
VAR b: BYTE;
	i: INTEGER;
BEGIN
	i := 256;
	b := i - 1;
	i := B(i - 255);
	b := B(b * 1);
	b := B(255 - 25);
	b := 255;
	ASSERT(255 = b);
	ASSERT(249 < b - 5)
END Go;

BEGIN
	Go
END Byte.

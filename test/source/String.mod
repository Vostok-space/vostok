MODULE String;

PROCEDURE Err;
VAR s1, s2: ARRAY 11 OF CHAR;
	i: INTEGER;
BEGIN
	s1 := "0123456789 ";
	FOR i := 0 TO 10 DO
		s2[i] := CHR(ORD("0") + i)
	END;
	ASSERT(s1 = s2);

	ASSERT(s1 = "0123456789")
END Err;

PROCEDURE Go*;
VAR s1, s2: ARRAY 11 OF CHAR;
	i: INTEGER;
BEGIN
	s1 := "0123456789";
	FOR i := 0 TO 9 DO
		s2[i] := CHR(ORD("0") + i)
	END;
	s2[10] := 0X;
	ASSERT(s1 = s2);

	ASSERT(s1 = "0123456789")
END Go;

END String.

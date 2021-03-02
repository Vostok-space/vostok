MODULE String;

CONST S  = "0123";
      L  = LEN(S);

      S1 = "0";
      S2 = CHR(ORD("0"));

      S3 = "01";

PROCEDURE Err*;
VAR s1, s2: ARRAY 12 OF CHAR;
	i: INTEGER;
BEGIN
	s1 := "0123456789 ";
	FOR i := 0 TO 10 DO
		s2[i] := CHR(ORD("0") + i)
	END;
	ASSERT(s1 = s2);

	ASSERT(s1 = "0123456789")
END Err;

PROCEDURE Eq(s1, s2: ARRAY OF CHAR): BOOLEAN;
	RETURN s1 = s2
END Eq;

PROCEDURE Eq1(s1, s2: ARRAY OF ARRAY OF CHAR): BOOLEAN;
	RETURN s1[1] = s2[0]
END Eq1;

PROCEDURE Eq2(s: ARRAY OF CHAR): BOOLEAN;
VAR b1, b2, b3, b4: BOOLEAN;
BEGIN
	b1 := s = "0";
	b2 := "0" = s;

	b3 := s # "0";
	b4 := "0" # s;

	ASSERT(b1 = b2);
	ASSERT(b3 = b4);
	ASSERT(b1 # b3);

	RETURN b1
END Eq2;

PROCEDURE EqLen(len: INTEGER; str: ARRAY OF CHAR);
BEGIN
	ASSERT(len = LEN(str));
	ASSERT(LEN(str) = len);
	ASSERT(str[len - 1] = 0X);
	ASSERT(0X = str[LEN(str) - 1])
END EqLen;

PROCEDURE Fail*;
(*
VAR s: ARRAY 2 OF CHAR;
BEGIN
  s := "ab"
*)
END Fail;

PROCEDURE Go*;
VAR s1, s2: ARRAY 11 OF CHAR;
    s3, s4: ARRAY 2, 11 OF CHAR;
    s0: ARRAY 5 OF CHAR;
    i: INTEGER;
BEGIN
	s1 := "0123456789";
	FOR i := 0 TO 9 DO
		s2[i] := CHR(ORD("0") + i);
		s3[1, i] := CHR(ORD("0") + i);
		s4[0, i] := CHR(ORD("0") + i)
	END;
	s3[1, 10] := 0X;
	s4[0, 10] := 0X;
	s3[0, 0] := "4";
	s4[1, 0] := "8";

	s2[10] := 0X;
	ASSERT(s1 = s2);
	ASSERT(s2 = s1);

	ASSERT(s1 = "0123456789");
	ASSERT("0123456789" = s1);

	ASSERT(s1 # "012345678");
	ASSERT("1123456789" # s2);

	ASSERT(Eq(s1, s2));
	ASSERT(Eq(s2, s1));

	s1[5] := "6";

	ASSERT(~Eq(s1, s2));
	ASSERT(~Eq(s2, s1));

	ASSERT(s1 # s2);
	ASSERT(s2 # s1);

	ASSERT(LEN("1234") = 5);
	ASSERT(5 = L);
	ASSERT(LEN(S) = 5);

	EqLen(6, "12345");
	EqLen(5, S);

	ASSERT(s2 = s3[1]);

	ASSERT(Eq(s3[1], s4[0]));
	ASSERT(Eq(s4[0], s3[1]));

	ASSERT(Eq1(s3, s4));
	s3[1][7] := "Z";
	ASSERT(~Eq1(s3, s4));

	ASSERT(S1 = S2);
	ASSERT(LEN(S1) = 2);
	i := LEN(S1);
	ASSERT(2 = i);

	s1[0] := S[0];
	ASSERT(s1[0] = "0");

	ASSERT(S[4 - 1] = "3");
	ASSERT(S1[0] = "0");

	ASSERT(S1 = S1[0]);

	ASSERT(Eq(S1, "0"));

	s1 := "\";
	ASSERT(Eq(s1, "\"));

	ASSERT(S1 # S3);
	ASSERT(S3 # S1);
	ASSERT(~(S1 = S3));
	ASSERT(~(S3 = S1));

	ASSERT(Eq2(S1));
	ASSERT(~Eq2(S3));

	s0 := S;
	ASSERT(Eq(s0, S));
	ASSERT(Eq(S, s0));
END Go;

END String.

MODULE Set;

CONST
	s  = {2 .. 4};
	s2 = {0 .. 31};
	s3 = s2 - s;
	s4 = {1 .. 3, 4 .. 6};
	s5 = {2, 4 .. 5, 13 .. 31};
	s6*= s2 - s;

	sinv = -s;

	bt = 27 IN s5;
	bf =  7 IN s5;

TYPE

VAR i: INTEGER;
	v4: SET;

PROCEDURE Go*;
VAR ls: SET;
BEGIN
	ASSERT(~(1 IN s));
	ASSERT(2 IN s);
	ASSERT(3 IN s);
	ASSERT(4 IN s);
	ASSERT(~(5 IN s));

	FOR i := 0 TO 31 DO
		ASSERT(i IN s2)
	END;

	ASSERT(1 IN s3);
	ASSERT(~(2 IN s3));
	ASSERT(~(3 IN s3));
	ASSERT(~(4 IN s3));
	ASSERT(5 IN s3);

	ASSERT(s4 = {1 .. 6});
	v4 := s4;
	EXCL(v4, 3);
	ASSERT(v4 = (s4 - {3}));
	INCL(v4, 8);
	ASSERT(v4 = (s4 - {3} + {8}));
	ASSERT(v4 = s4 - {3} + {8});

	ASSERT(v4 = (s4 + {8} - {3}));
	ASSERT(v4 = s4 + {8} - {3});

	ASSERT(v4 # (s4 - {3} + {8, 0}));
	ASSERT(v4 # s4 - {3} + {8, 0});

	ASSERT(1 IN -s5);
	ASSERT(2 IN s5);
	ASSERT(3 IN -s5);
	ASSERT(4 IN s5);
	ASSERT(5 IN s5);
	ASSERT(6 IN -s5);
	ASSERT(12 IN -s5);
	ASSERT(13 IN s5);
	ASSERT(23 IN s5);
	ASSERT(31 IN s5);

	ASSERT(s6 = s3);

	ASSERT(bt);
	ASSERT(~bf);

	ls := sinv;
	ASSERT(-ls = s);
	ASSERT(sinv = {0, 1, 5 .. 31})
END Go;

END Set.

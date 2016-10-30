MODULE ProcType;

TYPE
	Proc = PROCEDURE(i: INTEGER);

VAR
	p: Proc;

	PROCEDURE P(i: INTEGER);
		PROCEDURE P(i: INTEGER);
			PROCEDURE P(i: INTEGER);
			BEGIN
				ASSERT(FALSE)
			END P;
		BEGIN
			ASSERT(i = 1)
		END P;
	BEGIN
		ASSERT(i = 0);
		P(i + 1)
	END P;

BEGIN
	P(0);
	p := P;
	p(0)
END ProcType.

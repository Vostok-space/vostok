MODULE ProcType;

TYPE
	Proc = PROCEDURE(i: INTEGER);

VAR
	p: Proc;

	PROCEDURE P(i: INTEGER);
		PROCEDURE R(i: INTEGER);
			PROCEDURE R(i: INTEGER);
			BEGIN
				ASSERT(FALSE)
			END R;
		BEGIN
			ASSERT(i = 1);
			IF 0 > 1 THEN
				R(0)
			END
		END R;
	BEGIN
		ASSERT(i = 0);
		R(i + 1)
	END P;

PROCEDURE Go*;
BEGIN
	P(0);
	p := P;
	p(0)
END Go;

END ProcType.

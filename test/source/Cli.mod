MODULE Cli;

IMPORT CLI, Out;

CONST

TYPE

VAR
	buf: ARRAY 1024 * 1024 OF CHAR;
	ret: BOOLEAN;
	ofs, i: INTEGER;

BEGIN
	FOR i := 0 TO CLI.count - 1 DO
		ofs := 0;
		ret := CLI.Get(buf, ofs, i);
		ASSERT(ret);
		Out.Int(i, 0);
		Out.String(") ");
		Out.String(buf);
		Out.Ln
	END
END Cli.

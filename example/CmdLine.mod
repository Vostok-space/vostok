MODULE CmdLine;

IMPORT CLI, Out;

VAR
	buf: ARRAY CLI.MaxLen + 1 OF CHAR;
	ret: BOOLEAN;
	ofs, i: INTEGER;

PROCEDURE Go*;
BEGIN
	ofs := 0;
	ret := CLI.GetName(buf, ofs);
	Out.String(buf); Out.String(":"); Out.Ln;
	FOR i := 0 TO CLI.count - 1 DO
		ofs := 0;
		ret := CLI.Get(buf, ofs, i);
		ASSERT(ret);
		Out.Int(i, 0);
		Out.String(") ");
		Out.String(buf);
		Out.Ln
	END
END Go;

END CmdLine.

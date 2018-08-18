MODULE Eline;

  IMPORT Out, EditLine;

  PROCEDURE Go*;
  VAR line: ARRAY 256 OF CHAR;
  BEGIN
    WHILE EditLine.Read("Example> ", line) DO
      Out.String(line);
      line[0] := 0X
    END
  END Go;

END Eline.

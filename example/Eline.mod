MODULE Eline;

  IMPORT Out, EditLine;

  PROCEDURE Go*;
  VAR line: ARRAY 256 OF CHAR;
  BEGIN
    Out.Open;
    WHILE EditLine.Read("Example> ", line) DO
      Out.String(line); Out.Ln
    END
  END Go;

END Eline.

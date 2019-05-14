MODULE SelfExe;

  IMPORT Out, OsUtil;

  PROCEDURE Go*;
  VAR str: ARRAY 256 OF CHAR; len: INTEGER;
  BEGIN
    IF OsUtil.PathToSelfExe(str, len) THEN
      IF len >= LEN(str) THEN
        len := LEN(str) - 1
      END;
      str[len] := 0X;
      Out.String(str)
    ELSE
      Out.String("Can not determine path to self")
    END;
    Out.Ln
  END Go;

END SelfExe.

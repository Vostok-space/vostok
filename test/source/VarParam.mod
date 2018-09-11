MODULE VarParam;

  IMPORT Out;

  CONST

  TYPE

  VAR

  PROCEDURE IncProc(VAR p: INTEGER);
  BEGIN
    p := p + 1
  END IncProc;

  PROCEDURE IncFunc(p: INTEGER): INTEGER;
  BEGIN
    IncProc(p)
  RETURN
    p
  END IncFunc;

  PROCEDURE Go*;
  VAR i, j: INTEGER;
  BEGIN
    ASSERT(IncFunc(100) = 101);
    j := 111;
    FOR i := 111 TO 202 DO
      INC(j);
      ASSERT(j = IncFunc(i))
    END
  END Go;

END VarParam.

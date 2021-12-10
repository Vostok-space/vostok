MODULE Var1;

  VAR a*: INTEGER;
      f: BOOLEAN;

  PROCEDURE SetA*(v: INTEGER);
  BEGIN
    f := TRUE;
    a := v
  END SetA;

  PROCEDURE Go*;
  BEGIN
    IF ~f THEN
      ASSERT(a = 999)
    END;
    SetA(100H);
    ASSERT(a = 256);

    f := FALSE;
    a := 999
  END Go;

BEGIN
  f := FALSE;
  a := 999
END Var1.

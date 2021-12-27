MODULE Var2;

  IMPORT Var1;

  PROCEDURE Go*;
  VAR i, j, k: INTEGER;
  BEGIN
    ASSERT(999 = Var1.a);
    Var1.SetA(101);
    ASSERT(101 = Var1.a);

    Var1.Go;

    IF 0 > 1 THEN
      ASSERT(FALSE)
    ELSE
      i := 11
    END;
    j := i;

    IF 0 < 1 THEN
      k := 13
    ELSE
      ASSERT(FALSE)
    END;
    j := k
  END Go;

  PROCEDURE Fail*;
  VAR i, j: INTEGER;
  BEGIN
    IF FALSE THEN
      i := 1191
    END;
    IF TRUE THEN
      j := i
    END;
  END Fail;

END Var2.

MODULE Var2;

  IMPORT Var1;

  PROCEDURE Go*;
  BEGIN
    ASSERT(999 = Var1.a);
    Var1.SetA(101);
    ASSERT(101 = Var1.a);

    Var1.Go
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

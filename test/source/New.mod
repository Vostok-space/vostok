MODULE New;

  TYPE
    P = POINTER TO RECORD END;

  PROCEDURE Go*;
  VAR p: P;
  BEGIN
    NEW(p);
    ASSERT(p # NIL)
  END Go;

END New.

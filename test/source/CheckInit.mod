MODULE CheckInit;

  TYPE P = POINTER TO RECORD i: INTEGER END;

  PROCEDURE Get(c: BOOLEAN): INTEGER;
  VAR i: INTEGER;
  BEGIN
    IF c THEN
      i := 7
    END;
    IF ~c THEN
      i := 201
    END
  RETURN
    i
  END Get;

  PROCEDURE Go*;
  VAR i, j: INTEGER; p: P;
  BEGIN
    ASSERT(Get(FALSE) = 201);
    ASSERT(Get(TRUE) = 7);

    i := 1;
    REPEAT
      WHILE i < 0 DO
        j := 1;
        NEW(p)
      END;
      IF i < 0 THEN
        p.i := -1;
        ASSERT(j = 1)
      END
    UNTIL i > 0
  END Go;

END CheckInit.

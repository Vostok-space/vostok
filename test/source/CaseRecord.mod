MODULE CaseRecord;

  TYPE
    R = RECORD
      c: CHAR
    END;

    R1 = RECORD(R)
      a: INTEGER
    END;

    R2 = RECORD(R)
      a: REAL
    END;

    R21 = RECORD(R2)
      b: BOOLEAN
    END;

  PROCEDURE Set(VAR r: R);
  BEGIN
    r.c := " ";
    CASE r OF
      R1: r.a := -19; r.c := "1" |
      R2: r.c := "2"; r.a := 0.25
    END
  END Set;

  PROCEDURE Set2(VAR r: R);
  BEGIN
    CASE r OF
      R1 : r.a := 41 |
      R21: r.a := 10.5; r.b := TRUE
    END;
    r.c := "z";
  END Set2;

  PROCEDURE Go*;
  VAR r1: R1; r2: R2; r21: R21;
  BEGIN
    Set(r1);
    ASSERT(r1.c = "1");
    Set(r2);
    ASSERT(r2.c = "2");
    ASSERT(r1.a = -19);
    ASSERT(r2.a = 0.25);

    Set2(r21);
    ASSERT(r21.c = "z");
    ASSERT(r1.a = -19);
    Set2(r1);
    ASSERT(r1.c = "z");
    ASSERT(r1.a = 41);
    ASSERT(r21.a = 10.5);
    ASSERT(r21.b)
  END Go;

END CaseRecord.

MODULE CasePointer;

  TYPE
    R = RECORD
      c: CHAR
    END;
    P = POINTER TO R;

    P1 = POINTER TO RECORD(R)
      a: INTEGER
    END;

    R2 = RECORD(R)
      a: REAL
    END;
    P2 = POINTER TO R2;

    P21 = POINTER TO RECORD(R2)
      b: BOOLEAN
    END;

  PROCEDURE Set(r: P);
  BEGIN
    r.c := " ";
    CASE r OF
      P1: r.a := -19; r.c := "1" |
      P2: r.c := "2"; r.a := 0.25
    END
  END Set;

  PROCEDURE Set2(r: P);
  VAR p: P1;
  BEGIN
    p := NIL;
    r.c := "z";
    CASE r OF
      P1 : r.a := 41; r := p |
      P21: r.a := 10.5; r.b := TRUE
    END;
  END Set2;

  PROCEDURE Go*;
  VAR r1: P1; r2: P2; r21: P21;
  BEGIN
    NEW(r1);
    NEW(r2);
    NEW(r21);

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

END CasePointer.

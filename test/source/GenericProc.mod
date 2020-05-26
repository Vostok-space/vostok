MODULE GenericProc;

  IMPORT Out;

  PROCEDURE Swap(VAR a, b: POINTER);
  VAR t: POINTER;
  BEGIN
    t := a;
    a := b;
    b := t
  END Swap;

  PROCEDURE Reverse(VAR a: ARRAY OF POINTER);
  VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO LEN(a) DIV 2 DO
      Swap(a[i], a[LEN(a) - 1 - i])
    END
  END Reverse;

  PROCEDURE UseSwap;
  VAR r1, r2: POINTER TO RECORD v: REAL    END;
      i1, i2: POINTER TO RECORD v: INTEGER END;
      p: POINTER;
  BEGIN
    NEW(r1); r1.v := 1.1;
    NEW(r2); r2.v := 2.2;

    NEW(i1); i1.v := 1;
    NEW(i2); i2.v := 2;

    Swap(r1, r2);
    Out.Real(r1.v, 0); Out.String(", "); Out.Real(r2.v, 0); Out.Ln;
    ASSERT(r1.v = 2.2); ASSERT(r2.v = 1.1);

    Swap(i2, i1);
    Out.Int(i1.v, 0); Out.String(", "); Out.Int(i2.v, 0); Out.Ln;
    ASSERT(i1.v = 2); ASSERT(i2.v = 1);

    p := NIL;
    (* Ошибка
    Swap(i2, r2);
    Swap(r1, i2);
    Swap(r2, p)
    *)
  END UseSwap;

  PROCEDURE UseReverse;
  VAR a: ARRAY 17 OF POINTER TO RECORD v: INTEGER END;
      i: INTEGER;
  BEGIN
    FOR i := 0 TO LEN(a) - 1 DO
      NEW(a[i]); a[i].v := i
    END;

    Reverse(a);

    FOR i := 0 TO LEN(a) - 1 DO
      ASSERT(a[i].v = LEN(a) - 1 - i)
    END
  END UseReverse;

  PROCEDURE Go*;
  BEGIN
    UseSwap;
    UseReverse
  END Go;

END GenericProc.

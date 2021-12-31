MODULE System;

  IMPORT SYSTEM, Rand := OsRand, Platform;

  TYPE Ptr = POINTER TO RECORD END;

  VAR i: INTEGER; b: BOOLEAN; bt: BYTE; c: CHAR; r: REAL; s: SET;

  PROCEDURE Adr*;
  VAR a, v: INTEGER; ptr: Ptr;
  BEGIN
    NEW(ptr);
    a := SYSTEM.ADR(ptr^);

    v := SYSTEM.SIZE(INTEGER);
    a := SYSTEM.ADR(v);

    ASSERT(v >= 4)
  END Adr;

  PROCEDURE Bit;
  VAR set: SET; j, a: INTEGER;
  BEGIN
    set := {1..3, 14, 18..22, 29};
    a := SYSTEM.ADR(set);
    FOR j := 0 TO 31 DO
      ASSERT(SYSTEM.BIT(a, j) = (j IN set))
    END
  END Bit;

  PROCEDURE Get;
  VAR j, li: INTEGER; lb: BOOLEAN; lbt: BYTE; lc: CHAR; lr: REAL; ls: SET;
      ai, ab, abt, ac, ar, as: INTEGER;
  BEGIN
    ai := SYSTEM.ADR(i);
    ab := SYSTEM.ADR(b);
    abt:= SYSTEM.ADR(bt);
    ac := SYSTEM.ADR(c);
    ar := SYSTEM.ADR(r);
    as := SYSTEM.ADR(s);

    FOR j := 0 TO 111 DO
      ASSERT(Rand.Int(i));
      SYSTEM.GET(ai, li);
      ASSERT(li = i);

      b := ODD(i);
      SYSTEM.GET(ab, lb);
      ASSERT(b = lb);

      bt := i MOD 100H;
      SYSTEM.GET(abt, lbt);
      ASSERT(bt = lbt);

      c := CHR(i MOD 100H);
      SYSTEM.GET(ac, lc);
      ASSERT(c = lc);

      ASSERT(Rand.Real(r));
      SYSTEM.GET(ar, lr);
      ASSERT(r = lr);

      ASSERT(Rand.Set(s));
      SYSTEM.GET(as, ls);
      ASSERT(ls = s)
    END
  END Get;

  PROCEDURE Put;
  VAR j, li: INTEGER; lb: BOOLEAN; lbt: BYTE; lc: CHAR; lr: REAL; ls: SET;
      ai, ab, abt, ac, ar, as: INTEGER;
  BEGIN
    ai := SYSTEM.ADR(li);
    ab := SYSTEM.ADR(lb);
    abt:= SYSTEM.ADR(lbt);
    ac := SYSTEM.ADR(lc);
    ar := SYSTEM.ADR(lr);
    as := SYSTEM.ADR(ls);

    FOR j := 0 TO -111 BY -1 DO
      ASSERT(Rand.Int(i));
      SYSTEM.PUT(ai, i);
      ASSERT(li = i);

      b := ODD(i);
      SYSTEM.PUT(ab, b);
      ASSERT(b = lb);

      bt := i MOD 100H;
      SYSTEM.PUT(abt, bt);
      ASSERT(bt = lbt);

      c := CHR(i MOD 100H);
      SYSTEM.PUT(ac, c);
      ASSERT(c = lc);

      ASSERT(Rand.Real(r));
      SYSTEM.PUT(ar, r);
      ASSERT(r = lr);

      ASSERT(Rand.Set(s));
      SYSTEM.PUT(as, s);
      ASSERT(ls = s)
    END;

    SYSTEM.PUT(ai, 102030405);
    ASSERT(li = 102030405);

    SYSTEM.PUT(ac, " ");
    ASSERT(lc = 20X);

    SYSTEM.PUT(ar, 1.02030405);
    ASSERT(lr = 1.02030405);

    SYSTEM.PUT(ab, TRUE);
    ASSERT(lb = TRUE);
    SYSTEM.PUT(ab, FALSE);
    ASSERT(lb = FALSE);

    SYSTEM.PUT(as, {11..22, 0, 31});
    ASSERT(ls = {31, 0, 11..22})
  END Put;

  PROCEDURE Copy;
  VAR cc: ARRAY 32 OF CHAR; cb: ARRAY 32 OF BYTE; j, l, o, ab, ac: INTEGER;
  BEGIN
    FOR j := 0 TO LEN(cb) - 1 DO
      cb[j] := (j * (j MOD 2 * 2 - 1)) MOD 100H
    END;
    ab := SYSTEM.ADR(cb);
    ac := SYSTEM.ADR(cc);

    SYSTEM.COPY(ab, ac, LEN(cc) DIV 4);
    FOR j := 0 TO LEN(cb) - 1 DO
      ASSERT(cc[j] = CHR((j * (j MOD 2 * 2 - 1)) MOD 100H))
    END;

    FOR j := 0 TO 55 DO
      ASSERT(Rand.Int(o));
      l := j MOD (LEN(cc) - 3) + 1;
      o := (LEN(cc) - 3 - l) MOD (LEN(cc) - 3);

      ASSERT(Rand.Read(cb, o, l));
      DEC(o, l);
      SYSTEM.COPY(ab + o, ac + o, (l + 3) DIV 4);

      FOR l := 0 TO LEN(cb) - 1 DO
        ASSERT(ORD(cc[l]) = cb[l])
      END
    END
  END Copy;

  PROCEDURE Size;
  TYPE Rec = RECORD a: INTEGER; z: BOOLEAN END;
  BEGIN
    ASSERT(SYSTEM.SIZE(INTEGER) >= 4);
    ASSERT(SYSTEM.SIZE(BYTE) >= 1);
    ASSERT(SYSTEM.SIZE(BOOLEAN) >= 1);
    ASSERT(SYSTEM.SIZE(CHAR) >= 1);
    ASSERT(SYSTEM.SIZE(REAL) >= 4);
    ASSERT(SYSTEM.SIZE(SET) >= 4);
    ASSERT(SYSTEM.SIZE(Rec) >= 5)
  END Size;

  PROCEDURE Go*;
  BEGIN
    Size;
    IF SYSTEM.SIZE(Ptr) = 4 THEN
      Adr;
      IF Platform.C THEN
        Bit;
        ASSERT(Rand.Open());
        Get;
        Put;
        Copy;
        Rand.Close
      END
    END
  END Go;

END System.

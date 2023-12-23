MODULE System;

  IMPORT SYSTEM, Rand := OsRand, Platform, log;

  TYPE Ptr = POINTER TO RECORD END;

  VAR i: INTEGER; b: BOOLEAN; bt: BYTE; c: CHAR; r: REAL; s: SET; b4: ARRAY 4 OF BYTE;
      adr0, adr1: INTEGER;

  PROCEDURE Adr*;
  VAR a, v: INTEGER; ptr: Ptr;
  BEGIN
    NEW(ptr);
    a := SYSTEM.ADR(ptr^);

    v := SYSTEM.SIZE(INTEGER);
    a := SYSTEM.ADR(v);

    ASSERT(v >= 4)
  END Adr;

  PROCEDURE Bit*;
  VAR set: SET; j, a: INTEGER;
  BEGIN
    set := {1..3, 14, 18..22, 29};
    a := SYSTEM.ADR(set);
    log.s("set "); FOR j := 0 TO 31 DO log.i(ORD(j IN set)) END; log.n;
    log.s("int "); FOR j := 0 TO 31 DO log.i(ORD(SYSTEM.BIT(a + j DIV 8, j MOD 8))) END; log.n;
    IF Platform.ByteOrder = Platform.LittleEndian THEN
      FOR j := 0 TO 31 DO
        ASSERT(SYSTEM.BIT(a + j DIV 8, j MOD 8) = (j IN set))
      END
    ELSE
      FOR j := 0 TO 31 DO
        ASSERT(SYSTEM.BIT(a + j DIV 8, j MOD 8) = ((31 - j) IN set))
      END
    END
  END Bit;

  PROCEDURE Get*;
  VAR j, li: INTEGER; lb: BOOLEAN; lbt: BYTE; lc: CHAR; lr: REAL; ls: SET;
      ai, ab, abt, ac, ar, as: INTEGER;
  BEGIN
    ASSERT(Rand.Open());

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

  PROCEDURE Put*;
  VAR j, li: INTEGER; lb: BOOLEAN; lbt: BYTE; lc: CHAR; lr: REAL; ls: SET;
      ai, ab, abt, ac, ar, as: INTEGER;
  BEGIN
    ASSERT(Rand.Open());

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

  PROCEDURE Copy*;
  VAR cc: ARRAY 32 OF CHAR; cb: ARRAY 32 OF BYTE; j, l, o, ab, ac: INTEGER;
  BEGIN
    ASSERT(Rand.Open());

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

  PROCEDURE CopyParam*;
  VAR a1: ARRAY 14 OF SET; b1: ARRAY 15 OF INTEGER; a2: ARRAY 17 OF SET; b2: ARRAY 16 OF INTEGER;
      a11: ARRAY 5 OF ARRAY 7 OF SET; b11: ARRAY 4 OF ARRAY 8 OF INTEGER;

    PROCEDURE Cp(VAR as: ARRAY OF SET; ai: ARRAY OF INTEGER);
    VAR n: INTEGER;
    BEGIN
      n := LEN(as);
      IF n > LEN(ai) THEN n := LEN(ai) END;
      SYSTEM.COPY(SYSTEM.ADR(ai), SYSTEM.ADR(as), n);
      WHILE n > 0 DO
        DEC(n);
        ASSERT(ORD(as[n]) = ai[n])
      END
    END Cp;

    PROCEDURE Cp2(VAR ai: ARRAY OF ARRAY OF INTEGER; as: ARRAY OF ARRAY OF SET);
    VAR n, n2: INTEGER;
    BEGIN
      n := LEN(as) * LEN(as[0]);
      n2 := LEN(ai) * LEN(ai[0]);
      IF n > n2 THEN n := n2 END;
      SYSTEM.COPY(SYSTEM.ADR(as), SYSTEM.ADR(ai), n);
      WHILE n > 0 DO
        DEC(n);
        ASSERT(ORD(as[n DIV LEN(as[0])][n MOD LEN(as[0])]) = ai[n DIV LEN(ai[0])][n MOD LEN(ai[0])])
      END
    END Cp2;

    PROCEDURE Init(VAR ai: ARRAY OF INTEGER);
    VAR j, v: INTEGER;
    BEGIN
      FOR j := LEN(ai) - 1 TO 0 BY -1 DO
        ASSERT(Rand.Int(v));
        ai[j] := ABS(v)
      END
    END Init;

    PROCEDURE InitSets(VAR as: ARRAY OF ARRAY OF SET);
    VAR j, k: INTEGER; v: SET;
    BEGIN
      FOR j := LEN(as) - 1 TO 0 BY -1 DO
        FOR k := LEN(as[0]) -1 TO 0 BY -1 DO
          ASSERT(Rand.Set(v));
          as[j][k] := v - {31}
        END
      END
    END InitSets;
  BEGIN
    ASSERT(Rand.Open());
    Init(b1); Cp(a1, b1);
    Init(b2); Cp(a2, b2);

    InitSets(a11); Cp2(b11, a11);
  END CopyParam;

  PROCEDURE CopyGlobal*;
  VAR tb: BYTE;
  
    PROCEDURE GetAdr;
    VAR p: POINTER TO RECORD s: SET END;
    BEGIN
      adr0 := SYSTEM.ADR(b4);
      NEW(p);
      p.s := {0..30};
      adr1 := SYSTEM.ADR(p^)
    END GetAdr;
  BEGIN
    GetAdr;
    SYSTEM.PUT(adr0, {1..31});
    ASSERT(b4[1] = 0FFH);
    ASSERT(b4[2] = 0FFH);
    IF Platform.ByteOrder = Platform.LittleEndian THEN
      ASSERT(b4[0] = 0FEH);
      ASSERT(b4[3] = 0FFH);

      SYSTEM.GET(adr1, tb);
      ASSERT(tb = 0FFH);
      SYSTEM.GET(adr1 + 3, tb);
      ASSERT(tb = 07FH)
    ELSE
      ASSERT(b4[0] = 0FFH);
      ASSERT(b4[3] = 0FEH);

      SYSTEM.GET(adr1, tb);
      ASSERT(tb = 07FH);
      SYSTEM.GET(adr1 + 3, tb);
      ASSERT(tb = 0FFH)
    END
  END CopyGlobal;

  PROCEDURE CopyItem*;
  TYPE Rr = RECORD v: REAL END;
  VAR r0: Rr; a0: INTEGER;
  
    PROCEDURE GetAdr(): INTEGER;
    VAR p: ARRAY 2 OF POINTER TO RECORD r: ARRAY 3 OF POINTER TO RECORD r: REAL END END; j: INTEGER;
    BEGIN
      ASSERT(Rand.Int(j)); j := j MOD 6;
      NEW(p[j MOD 2]);
      NEW(p[j MOD 2].r[j DIV 2]);
      p[j MOD 2].r[j DIV 2].r := 4.4
    RETURN
      SYSTEM.ADR(p[j MOD 2].r[j DIV 2]^)
    END GetAdr;
  BEGIN
    ASSERT(Rand.Open());
    a0 := GetAdr();
    SYSTEM.COPY(a0, SYSTEM.ADR(r0), SYSTEM.SIZE(Rr) DIV SYSTEM.SIZE(INTEGER));
    ASSERT(r0.v = 4.4);
    r0.v := 5.5;
    SYSTEM.COPY(SYSTEM.ADR(r0), a0, SYSTEM.SIZE(Rr) DIV SYSTEM.SIZE(INTEGER))
  END CopyItem;

  PROCEDURE Size*;
  TYPE Rec = RECORD a: INTEGER; z: BOOLEAN END; Arr = ARRAY 321 OF BYTE;
  VAR bs: INTEGER;
  BEGIN
    ASSERT(SYSTEM.SIZE(INTEGER) >= 4);
    bs := SYSTEM.SIZE(BYTE);
    ASSERT(bs >= 1);
    ASSERT(SYSTEM.SIZE(BOOLEAN) >= 1);
    ASSERT(SYSTEM.SIZE(CHAR) >= 1);
    ASSERT(SYSTEM.SIZE(REAL) >= 4);
    ASSERT(SYSTEM.SIZE(SET) >= 4);
    ASSERT(SYSTEM.SIZE(Rec) >= 5);
    IF bs < 16 THEN
      ASSERT(SYSTEM.SIZE(Arr) = bs * 321)
    END
  END Size;

  PROCEDURE AllAdrCorrectInt*;
  VAR a, k, sum: INTEGER; sl: ARRAY 17 OF SET;
  BEGIN
    sum := 0;
    FOR k := 0 TO LEN(sl) - 1 DO
      a := SYSTEM.ADR(sl[k]);
      sum := sum + a MOD 2 + (a + (ORD({27}) - 1)) MOD 2
    END;
    ASSERT(sum = 17)
  END AllAdrCorrectInt;

  PROCEDURE Go*;
  BEGIN
    Size;
    IF (SYSTEM.SIZE(Ptr) = 4) OR (SYSTEM.SIZE(Ptr) = 8) THEN
      Adr;
      IF Platform.C THEN
        Bit;
        Get;
        Put;
        Copy;
        CopyParam;
        CopyGlobal;
        CopyItem;
        AllAdrCorrectInt;
        Rand.Close
      END
    END
  END Go;

END System.

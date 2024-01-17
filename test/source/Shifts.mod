MODULE Shifts;

  IMPORT Out;

  CONST A* = LSL(1, 30);

  TYPE

  VAR

  PROCEDURE lsl*(n, s: INTEGER): INTEGER;
  RETURN
    LSL(n, s)
  END lsl;

  PROCEDURE Lsl*;
  VAR i, a: INTEGER;
  BEGIN
    ASSERT(LSL(46, 5) = 46 * 32);
    a := 1;
    FOR i := 0 TO 29 DO
      ASSERT(LSL(1, i) = a);
      a := a * 2;
    END;
    ASSERT(i = 30);
    ASSERT(LSL(1, i) = a);
  END Lsl;

  PROCEDURE asr*(n, s: INTEGER): INTEGER;
  RETURN
    ASR(n, s)
  END asr;

  PROCEDURE Asr*;
  VAR i, a, b, ca, cb, sh: INTEGER;
  BEGIN
    ASSERT(ASR(-1, 0)  = -1);
    ASSERT(ASR(-1, 2)  = -1);
    sh := 31;
    ASSERT(ASR(-1, 31) = -1);
    INC(sh);
    ASSERT(ASR(-1, sh) = -1);
    INC(sh);
    ASSERT(ASR(-1, sh) = -1);
    ASSERT(ASR(-7FFFFFFFH, 5) = (-7FFFFFFFH) DIV 32);
    ASSERT(ASR(7FFFFFFFH, 31) = 0);
    sh := 32;
    ASSERT(ASR(7FFFFFFFH, sh) = 0);
    ASSERT(ASR(7FFFFFFFH, sh*2) = 0);
    a := -3F2CBD7AH;
    ca := a;
    b := 7A2D0C79H;
    cb := b;
    FOR i := 0 TO 31 DO
      ASSERT(ASR(-3F2CBD7AH, i) = a);
      ASSERT(a = ASR(ca, i));
      ASSERT(ASR(7A2D0C79H, i) = b);
      ASSERT(b = ASR(cb, i));
      a := a DIV 2;
      b := b DIV 2
    END
  END Asr;

  PROCEDURE ror*(n, s: INTEGER): INTEGER;
  RETURN
    ROR(n, s)
  END ror;

  PROCEDURE Ror*;
  VAR i, a, sh: INTEGER;
  BEGIN
    ASSERT(ROR(55555555H, 16) = 55555555H);
    ASSERT(ROR(28342341H, 0H) = 28342341H);
    sh := 96;
    ASSERT(ROR(28342341H, sh) = 28342341H);
    a := 55555555H;
    FOR i := 0 TO 40 BY 2 DO
      ASSERT(ROR(55555555H, i) = 55555555H);
      ASSERT(ROR(a, i) = 55555555H)
    END;

    a := 3F2CBD7AH;

    ASSERT(ROR(3F2CBD7AH, 24) = 2CBD7A3FH);
    ASSERT(ROR(a, 24) = 2CBD7A3FH);

    ASSERT(ROR(3F2CBD7AH, 8 ) = 7A3F2CBDH);
    ASSERT(ROR(a, 8 ) = 7A3F2CBDH)
  END Ror;

  PROCEDURE Go*;
  BEGIN
    Lsl;
    Asr;
    Ror
  END Go;

END Shifts.

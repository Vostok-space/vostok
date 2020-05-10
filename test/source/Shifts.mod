MODULE Shifts;

  IMPORT Out;

  CONST

  TYPE

  VAR

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

  PROCEDURE Asr*;
  VAR i, a, b, ca, cb: INTEGER;
  BEGIN
    ASSERT(ASR(-1, 0)  = -1);
    ASSERT(ASR(-1, 2)  = -1);
    ASSERT(ASR(-1, 31) = -1);
    ASSERT(ASR(-7FFFFFFFH, 5) = (-7FFFFFFFH) DIV 32);
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

  PROCEDURE Ror*;
  VAR i, a: INTEGER;
  BEGIN
    ASSERT(ROR(55555555H, 16) = 55555555H);
    ASSERT(ROR(28342341H, 0H) = 28342341H);
    ASSERT(ROR(28342341H, 96) = 28342341H);
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

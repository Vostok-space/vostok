MODULE Shifts;

  IMPORT Out;

  CONST

  TYPE

  VAR

  PROCEDURE Lsl;
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

  PROCEDURE Asr;
  VAR i, a, b: INTEGER;
  BEGIN
    ASSERT(ASR(-1, 0)  = -1);
    ASSERT(ASR(-1, 2)  = -1);
    ASSERT(ASR(-1, 31) = -1);
    ASSERT(ASR(-7FFFFFFFH, 5) = (-7FFFFFFFH) DIV 32);
    a := -3F2CBD7AH;
    b := 7A2D0C79H;
    FOR i := 0 TO 31 DO
      ASSERT(ASR(-3F2CBD7AH, i) = a);
      ASSERT(ASR(7A2D0C79H, i) = b);
      a := a DIV 2;
      b := b DIV 2
    END
  END Asr;

  PROCEDURE Ror;
  BEGIN
  END Ror;

  PROCEDURE Go*;
  BEGIN
    Lsl;
    Asr;
    Ror
  END Go;

END Shifts.

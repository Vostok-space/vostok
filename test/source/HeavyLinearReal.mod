MODULE HeavyLinearReal;

  IMPORT CLI, log;

  PROCEDURE P0(a: REAL): REAL;
  RETURN
    a
  END P0;

  PROCEDURE P1(a: REAL): REAL;
  RETURN
    P0(a) - P0(a*1.1) + P0(a/2.) - P0(a * 0.1) - P0(a/0.1) + P0(a*2.3) - P0(a*5.6) + P0(a)
  - P0(a / 2.0)
  END P1;

  PROCEDURE P2(a: REAL): REAL;
  RETURN
    P1(a * 0.1) + P1(a * 0.01) - P1(a * 0.55) + P1(a * 0.01) + P1(a * 0.03) - P1(a + 1.)
  + P1(a - 19.) - P1(a) + P1(a * 0.5)
  END P2;

  PROCEDURE P3(a: REAL): REAL;
  RETURN
    P2(a) * P2(a - 1.E-6) + P2(a + 2.E-3) * P2(a) + P2(a - 0.1) * P2(a) + P2(a / 6.) * P2(a / 7.)
  + P2(a)
  END P3;

  PROCEDURE P4(a: REAL): REAL;
  RETURN
    P3(a * 1.E-2) * P3(a * 1.E-3) * P3(-a * 1.E-1) * P3(a * 1.E-4) * P3(-a * 1.E-5) * P3(a * 1.E-3)
  * P3(a * 2.E-8) * P3(a) * P3(a * 1.E-11) * 1.E-100
  END P4;

  PROCEDURE P5(a: REAL): REAL;
  RETURN
    P4(a) * P4(a + 1.E-3) * P4(a - 1.E-3) + P4(a + 1.E-4) + P4(a - 1.E-4)
  + P4(a + 1.E-5) + P4(a - 1.E-5) + P4(a + 1.E-6) + P4(a - 1.E-6)
  END P5;

  PROCEDURE P6(a: REAL): REAL;
  RETURN
    P5(a) / P5(a - 1.E-6) + P5(a + 2.E-3) / P5(a) + P5(a - 0.1) / P5(a) + P5(a / 6.) / P5(a / 7.)
  + P5(a)
  END P6;

  PROCEDURE P7(a: REAL): REAL;
  RETURN
    P6(a * 1.E-2) * P6(a * 1.E-3) * P6(-a * 1.E-1) * P6(a * 1.E-4) * P6(-a * 1.E-5) * P6(a * 1.E-3)
  * P6(a * 2.E-8) * P6(a) * P6(a * 1.E-11)
  END P7;

  PROCEDURE P8(a: REAL): REAL;
  RETURN
    P7(a) / 1.E100 + P7(a + 1.E-3) / 1.E99 - P7(a - 1.E-3) + P7(a + 1.E-4) + P7(a - 1.E-4)
  + P7(a + 1.E-5) + P7(a - 1.E-5) + P7(a + 1.E-6) + P7(a - 1.E-6)
  END P8;

  PROCEDURE P9(a: REAL): REAL;
  RETURN
    P8(a) / P8(a - 1.E-6) + P8(a + 2.E-3) / P8(a) + P8(a - 0.1) / P8(a) + P8(a / 6.) / P8(a / 7.)
  + P8(a)
  END P9;

  PROCEDURE PA(a: REAL): REAL;
  RETURN
    P9(a * 1.E-2) - P9(a * 1.E-3) + P9(-a * 1.E-1) - P9(a * 1.E-4) + P9(-a * 1.E-5) - P9(a * 1.E-3)
  + P9(a * 2.E-8) - P9(a) + P9(a * 1.E-11)
  END PA;

  PROCEDURE PB(a: REAL): REAL;
  RETURN
    PA(a) / PA(a + 1.E-3) * PA(a - 1.E-3) / PA(a + 1.E-4) + PA(a - 1.E-4)
  + PA(a + 1.E-5) + PA(a - 1.E-5) + PA(a + 1.E-6) + PA(a - 1.E-6)
  END PB;

  PROCEDURE Go*;
  VAR i: INTEGER; arg: ARRAY 16 OF CHAR;
  BEGIN
    i := 0;
    IF (CLI.count > 0) & CLI.Get(arg, i, 0) THEN
      log.rn(PB(FLT(ORD(arg[0]) - ORD("0")) / 1000.))
    ELSE
      log.rn(P8(0.001))
    END
  END Go;

END HeavyLinearReal.

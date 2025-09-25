MODULE RealBuilder;

 IMPORT RealBuild, log; 

 PROCEDURE Go*;
 VAR b: RealBuild.T; i: INTEGER; r: REAL;
 BEGIN
  RealBuild.Begin(b);
    FOR i := 0 TO 10 DO
      RealBuild.Digit(b, i MOD 10)
    END;
    RealBuild.Dot(b);
    FOR i := 11 TO 22 DO
      RealBuild.Digit(b, i MOD 10)
    END;
  RealBuild.End(b, r);
  ASSERT(r = 1234567890.123456789012);

  RealBuild.Begin(b);
    FOR i := 9 TO 5 BY -1 DO
      RealBuild.Digit(b, i MOD 10)
    END;
    RealBuild.Dot(b);
    FOR i := 4 TO 0 BY -1 DO
      RealBuild.Digit(b, i MOD 10)
    END;
  RealBuild.End(b, r);
  ASSERT(r = 98765.43210);

  RealBuild.Begin(b);
    FOR i := 0 TO 30 DO
      RealBuild.Digit(b, 0)
    END;
    FOR i := 0 TO 30 DO
      RealBuild.Digit(b, i * 3 MOD 10)
    END;
  RealBuild.End(b, r);
  ASSERT(r = 0369258147036925814703692581470.)
 END Go;

END RealBuilder.

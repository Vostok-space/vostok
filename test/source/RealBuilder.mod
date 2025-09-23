MODULE RealBuilder;

 IMPORT RealBuild, log; 

 CONST

 TYPE

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
  log.rn(r);
  ASSERT(r = 1234567890.123456789012)
 END Go;

END RealBuilder.

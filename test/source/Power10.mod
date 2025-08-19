MODULE Power10;

 IMPORT MathPower10;

 PROCEDURE Go*;
 CONST eps = 1.E-14;
 VAR p, l, r: REAL; i: INTEGER;
 BEGIN
  ASSERT(MathPower10.Calc(10) = 1.E10);

  p := MathPower10.Calc(-308);
  ASSERT((0.999E-308 < p) & (p < 1.001E-308));

  p := MathPower10.Calc(308);
  ASSERT((0.999E308 < p) & (p < 1.001E308));

  ASSERT(MathPower10.Calc(0) = 1.);
  ASSERT(MathPower10.Calc(1) = 10.);
  ASSERT(MathPower10.Calc(-2) = 0.01);

  ASSERT(MathPower10.Calc(10) = 1.E10);
  ASSERT(MathPower10.Calc(-11) = 1.E-11);

  l := 1.E-308;
  FOR i := -307 TO 308 DO
    p := MathPower10.Calc(i);
    r := p / l;
    ASSERT((10. - eps < r) & (r < 10. + eps));
    l := p
  END
 END Go;

END Power10.

MODULE RealTen;

 IMPORT Real10, log; 

 PROCEDURE Go*;
 VAR x: REAL; n: INTEGER;
 BEGIN
  x := 0.321;
  Real10.Pack(x, 10);
  ASSERT(x = 3.21E9);
  Real10.Unpk(x, n);
  ASSERT(n = 9);
  ASSERT(x = 3.21);

  x := -2.777777E-200;
  Real10.Pack(x, 55);
  log.rn(x);
  ASSERT((-2.777777001E-145 < x) & (x <-2.777776999E-145));
  Real10.Unpk(x, n);
  ASSERT(n = -145);
  ASSERT((-2.777777001 < x) & (x <-2.777776999));

  x := 1.;
  Real10.Pack(x, 308);
  ASSERT((0.999E308 < x) & (x < 1.001E308))
 END Go;

END RealTen.

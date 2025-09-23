MODULE RealToChars;

 IMPORT RealToCharz, log, Charz;

 PROCEDURE Go*;
 VAR s: ARRAY 32 OF CHAR; i: INTEGER;
 BEGIN
  s := "#";
  i := 1;
  ASSERT(RealToCharz.Exp(s, i, 3405.987621, 0));
  log.sn(s);
  ASSERT("#3.405987621E3" = s);
  ASSERT(i = Charz.CalcLen(s, 0));

  s := "  ";
  i := 2;
  ASSERT(RealToCharz.Exp(s, i, 3.405987621E-100, 0));
  ASSERT("  3.405987621E-100" = s);
  ASSERT(i = Charz.CalcLen(s, 0));

  i := 0;
  ASSERT(RealToCharz.Exp(s, i, 0.15E309, 0));
  ASSERT("1.5E308" = s);
  ASSERT(i = Charz.CalcLen(s, 0));

  i := 0;
  ASSERT(RealToCharz.Exp(s, i, 0.11E-307, 0));
  ASSERT("1.1E-308" = s);
  ASSERT(i = Charz.CalcLen(s, 0))
 END Go;

END RealToChars.

MODULE CalcSetCheck;

 IMPORT CalcSet;

 PROCEDURE FromInt*;
  PROCEDURE Check(i: INTEGER; s: SET);
  VAR b: ARRAY 4 OF BYTE; k: INTEGER;
  BEGIN
    ASSERT(CalcSet.FromInt(i) = s);
    ASSERT(CalcSet.ToInt(CalcSet.FromInt(i)) = i);
    ASSERT((i < 0) OR (ORD(s) = i));

    CalcSet.ToBytes(s, b);
    FOR k := 0 TO 3 DO
      ASSERT(b[k] = i MOD 100H);
      ASSERT(b[k] = CalcSet.ToByte(s, k));
      i := i DIV 100H
    END;
    ASSERT(CalcSet.FromBytes(b) = s)
  END Check;

  PROCEDURE CheckMin;
  VAR b: ARRAY 4 OF BYTE; k: INTEGER;
  BEGIN
    CalcSet.ToBytes({31}, b);
    FOR k := 0 TO 2 DO
      ASSERT(b[k] = 0);
      ASSERT(CalcSet.ToByte({31}, k) = 0)
    END;
    ASSERT(b[3] = 80H);
    ASSERT(CalcSet.ToByte({31}, 3) = 80H);
    ASSERT(CalcSet.FromBytes(b) = {31})
  END CheckMin;
 BEGIN
  Check(0, {});
  Check(1, {0});
  Check(7FFFFFFFH,  {0..30});
  Check(-7FFFFFFFH, {0, 31});
  Check(-1, {0 .. 31});
  CheckMin
 END FromInt;

 PROCEDURE FromBytes*;
  PROCEDURE Check(i: INTEGER; s: SET);
  BEGIN
    ASSERT(CalcSet.FromInt(i) = s);
    ASSERT(CalcSet.ToInt(CalcSet.FromInt(i)) = i);
    ASSERT((i < 0) OR (ORD(s) = i))
  END Check;
 BEGIN
  Check(0, {});
  Check(1, {0});
  Check(7FFFFFFFH,  {0..30});
  Check(-7FFFFFFFH, {0, 31});
  Check(-1, {0 .. 31})
 END FromBytes;

 PROCEDURE Add*;
  PROCEDURE Check(a, b, s: SET);
  BEGIN
    ASSERT(CalcSet.WrapAdd(a, b) = s);
    ASSERT(CalcSet.WrapAdd(b, a) = s);

    ASSERT(CalcSet.WrapAdd(a, a) = CalcSet.WrapMulU(a, CalcSet.FromInt(2)));
    ASSERT(CalcSet.WrapAdd(b, b) = CalcSet.WrapMulU(CalcSet.FromInt(2), b));
    ASSERT(CalcSet.WrapAdd(s, s) = CalcSet.Lsl(s, 1));

    ASSERT(CalcSet.WrapAdd(a, CalcSet.WrapNeg(b))
         = CalcSet.WrapNeg(CalcSet.WrapAdd(b, CalcSet.WrapNeg(a))));
    ASSERT(CalcSet.WrapAdd(b, CalcSet.WrapNeg(s)) = CalcSet.WrapSub(b, s));

    ASSERT(CalcSet.WrapSub(s, a) = b);
    ASSERT(CalcSet.WrapSub(s, b) = a)
  END Check;
 BEGIN
  Check({}, {}, {});
  Check(CalcSet.Max, CalcSet.Min, CalcSet.FromInt(-1));
  Check(CalcSet.FromInt(344), CalcSet.FromInt(888), CalcSet.FromInt(1232));
  Check(CalcSet.FromInt(-344233), CalcSet.FromInt(-1111112), CalcSet.FromInt(-1455345));
 END Add;

 PROCEDURE Cmp*;
  PROCEDURE Check(a, b: SET; s, u: INTEGER);
  BEGIN
    ASSERT(CalcSet.Cmp(a, b) = s);
    ASSERT(CalcSet.Cmp(b, a) = -s);

    ASSERT(CalcSet.CmpU(a, b) = u);
    ASSERT(CalcSet.CmpU(b, a) = -u)
  END Check;
 BEGIN
  Check({}, {}, 0, 0);
  Check(CalcSet.Min, CalcSet.Max, -1, +1);
  Check(CalcSet.Max, CalcSet.Max, 0, 0);
  Check(CalcSet.Max, CalcSet.Max - {0}, +1, +1);
  Check(CalcSet.Min, CalcSet.Min + {0}, -1, -1);
  Check(CalcSet.FromInt(-1), CalcSet.FromInt(-2), 1, 1);
  Check(CalcSet.FromInt(1), CalcSet.FromInt(2), -1, -1);
  Check(CalcSet.FromInt(-1), CalcSet.FromInt(2), -1, 1);
  Check(CalcSet.FromInt(1), CalcSet.FromInt(-2), 1, -1)
 END Cmp;

 PROCEDURE Shifts*;
 BEGIN
  ASSERT(CalcSet.Lsl({}     , 18) = {});
  ASSERT(CalcSet.Lsl({0}    , 31) = {31});
  ASSERT(CalcSet.Lsr({31}   , 31) = {0});
  ASSERT(CalcSet.Lsl({31}   , 31) = {});

  ASSERT(CalcSet.Asr({31}   , 31) = {0..31});
  ASSERT(CalcSet.Asr({0..31}, 31) = {0..31});
  ASSERT(CalcSet.Asr(CalcSet.FromInt(-12), 2) = CalcSet.FromInt(-3));
  ASSERT(CalcSet.Asr(CalcSet.FromInt(+12), 2) = CalcSet.FromInt(+3));

  ASSERT(CalcSet.Ror(CalcSet.FromInt(+12), 0) = CalcSet.FromInt(+12));
  ASSERT(CalcSet.Ror(CalcSet.FromInt(+12), 1) = CalcSet.FromInt(+06));
  ASSERT(CalcSet.Ror(CalcSet.FromInt(+12), 2) = CalcSet.FromInt(+03));
  ASSERT(CalcSet.Ror(CalcSet.FromInt(+12), 2 + 64) = CalcSet.FromInt(+03));
  ASSERT(CalcSet.Ror(CalcSet.FromInt(+12), 3) = {0, 31});
  ASSERT(CalcSet.Ror(CalcSet.FromInt(+12), 31) = CalcSet.FromInt(+24))
 END Shifts;

 PROCEDURE DivU*;
  PROCEDURE Check(d, s, r, m: SET);
  VAR rr, rm: SET;
  BEGIN
    rr := CalcSet.DivModU(d, s, rm);
    ASSERT(r = rr);
    ASSERT(m = rm);

    ASSERT(r = CalcSet.DivU(d, s));
    ASSERT(m = CalcSet.ModU(d, s));

    ASSERT(CalcSet.WrapAdd(CalcSet.WrapMulU(r, s), m) = d)
  END Check;
 BEGIN
  Check(CalcSet.FromInt( 1), CalcSet.FromInt( 1), CalcSet.FromInt( 1), CalcSet.FromInt( 0));
  Check(CalcSet.FromInt( 5), CalcSet.FromInt( 1), CalcSet.FromInt( 5), CalcSet.FromInt( 0));
  Check(CalcSet.FromInt( 5), CalcSet.FromInt( 3), CalcSet.FromInt( 1), CalcSet.FromInt( 2));
  Check(CalcSet.FromInt(111), CalcSet.FromInt(7), CalcSet.FromInt(15), CalcSet.FromInt(6));

  Check(CalcSet.MaxU, CalcSet.FromInt(1), CalcSet.MaxU, {})
 END DivU;

 PROCEDURE Div*;
  PROCEDURE Check(d, s, r, m: SET);
  VAR rr, rm: SET;
  BEGIN
    rr := CalcSet.DivMod(d, s, rm);
    ASSERT(r = rr);
    ASSERT(m = rm);

    ASSERT(r = CalcSet.Div(d, s));
    ASSERT(m = CalcSet.Mod(d, s));

    ASSERT(CalcSet.WrapAdd(CalcSet.WrapMul(r, s), m) = d)
  END Check;
 BEGIN
  Check(CalcSet.FromInt( 5), CalcSet.FromInt( 3), CalcSet.FromInt( 1), CalcSet.FromInt( 2));
  Check(CalcSet.FromInt(-5), CalcSet.FromInt( 3), CalcSet.FromInt(-2), CalcSet.FromInt( 1));
  Check(CalcSet.FromInt( 5), CalcSet.FromInt(-3), CalcSet.FromInt(-2), CalcSet.FromInt(-1));
  Check(CalcSet.FromInt(-5), CalcSet.FromInt(-3), CalcSet.FromInt( 1), CalcSet.FromInt(-2));

  Check(CalcSet.FromInt( 111), CalcSet.FromInt( 7), CalcSet.FromInt( 15), CalcSet.FromInt( 6));
  Check(CalcSet.FromInt(-111), CalcSet.FromInt( 7), CalcSet.FromInt(-16), CalcSet.FromInt( 1));
  Check(CalcSet.FromInt( 111), CalcSet.FromInt(-7), CalcSet.FromInt(-16), CalcSet.FromInt(-1));
  Check(CalcSet.FromInt(-111), CalcSet.FromInt(-7), CalcSet.FromInt( 15), CalcSet.FromInt(-6));

  Check(CalcSet.Min, CalcSet.FromInt(-1), CalcSet.Min, {});
  Check(CalcSet.Min, CalcSet.FromInt(-2), CalcSet.FromInt(1073741824), {})
 END Div;

 PROCEDURE Go*;
 BEGIN
  FromInt;
  Cmp;
  Shifts;
  Add;
  DivU;
  Div
 END Go;

END CalcSetCheck.

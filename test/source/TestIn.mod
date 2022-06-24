MODULE TestIn;

IMPORT V, In, Io := VDefaultIO, Stream := VDataStream, ArrayCopy, Utf8;

TYPE
  SampleIn = RECORD(Stream.In)
    s: ARRAY 64 OF CHAR;
    i, l: INTEGER
  END;

PROCEDURE Go*;
VAR i: INTEGER; ch: CHAR; s: ARRAY 16 OF CHAR; r: REAL;
BEGIN
  In.Open;
  ASSERT(In.Done);

  In.Int(i);
  ASSERT(In.Done);
  ASSERT(i = 123);

  In.Char(ch);
  ASSERT(In.Done);
  ASSERT(ch = "*");

  In.Real(r);
  ASSERT(In.Done);
  ASSERT(r = 1.5);

  In.String(s);
  ASSERT(In.Done);
  ASSERT(s = "abc");

  In.String(s);
  ASSERT(In.Done);
  ASSERT(s = "Mod.Proc");

  In.LongReal(r);
  ASSERT(In.Done);
  ASSERT((3333.4443999E-30 < r) & (r < 3333.4444001E-30));

  In.Int(i);
  ASSERT(~In.Done);

  In.Char(ch);
  ASSERT(In.Done);
  ASSERT(ch = "U");

  In.Char(ch);
  ASSERT(~In.Done)
END Go;

PROCEDURE SampleRead(VAR in: V.Base; VAR buf: ARRAY OF CHAR; ofs, count: INTEGER): INTEGER;
VAR read, i: INTEGER;
BEGIN
  read := 0;
  i := in(SampleIn).i;
  IF i + count > in(SampleIn).l THEN
    count := in(SampleIn).l - i
  END;
  IF count > 0 THEN
    ArrayCopy.Chars(buf, ofs, in(SampleIn).s, i, count)
  ELSE
    ASSERT(count = 0)
  END;
  in(SampleIn).i := i + count
RETURN
  count
END SampleRead;

PROCEDURE OpenIn(VAR opener: V.Base): Stream.PIn;
VAR in: POINTER TO SampleIn; i: INTEGER;
BEGIN
  NEW(in);
  in.i := 0;
  in.s := "123*1.5 'abc' 'Mod.Proc'3333.4444E-30 U";
  i := 0; WHILE in.s[i] # 0X DO IF in.s[i] = "'" THEN in.s[i] := Utf8.DQuote END; INC(i) END;
  in.l := i;
  Stream.InitIn(in^, NIL, SampleRead, NIL)
RETURN
  in
END OpenIn;

PROCEDURE NewSample(): Stream.PInOpener;
VAR opener: Stream.PInOpener;
BEGIN
  NEW(opener);
  Stream.InitInOpener(opener, OpenIn)
RETURN
  opener
END NewSample;

BEGIN
  Io.SetIn(NewSample())
END TestIn.

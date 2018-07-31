MODULE Rand;

 IMPORT R := OsRand, Out;

 PROCEDURE Go*;
 VAR i, i1, i2: INTEGER;
     r1, r2: REAL;
 BEGIN
   IF R.Open() THEN
     FOR i := 0 TO 255 DO
       ASSERT(R.Int(i1) & R.Int(i2) & (i1 # i2));
       ASSERT(R.Real(r1) & R.Real(r2) & (r1 # r2))
     END;
     R.Close
   END
 END Go;

 PROCEDURE Int*;
 VAR i: INTEGER;
 BEGIN
   IF ~R.Open() THEN
     Out.String("Can not open source of random")
   ELSIF ~R.Int(i) THEN
     Out.String("Can not read random data for integer")
   ELSE
     Out.Int(i, 0)
   END;
   Out.Ln;
   R.Close
 END Int;

 PROCEDURE Real*;
 VAR r: REAL;
 BEGIN
   IF R.Open() & R.Real(r) THEN
     Out.Real(r, 0); Out.Ln
   END;
   R.Close
 END Real;

END Rand.

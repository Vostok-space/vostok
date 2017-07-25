MODULE Rand;

 IMPORT R := OsRand, Out;

 PROCEDURE Go*;
 VAR i, i1, i2: INTEGER;
     ret: BOOLEAN;
 BEGIN
   IF R.Open() THEN
     FOR i := 0 TO 255 DO
       ret := R.Int(i1) & R.Int(i2) & (i1 # i2);
       ASSERT(ret)
     END;
     R.Close
   END
 END Go;

 PROCEDURE Int*;
 VAR i: INTEGER;
 BEGIN
   IF R.Open() & R.Int(i) THEN
     Out.Int(i, 0); Out.Ln
   END;
   R.Close
 END Int;

END Rand.

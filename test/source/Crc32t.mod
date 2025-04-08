MODULE Crc32t;

 IMPORT Crc := Crc32;
 
 PROCEDURE Go*;
 VAR i: INTEGER; c: SET; src: ARRAY 10 OF CHAR; b: ARRAY 9 OF BYTE;
 BEGIN
  src := "123456789";

  Crc.Begin(c);
    i := 0;
    REPEAT
      Crc.NextByte(c, ORD(src[i]));
      b[i] := ORD(src[i]);
      INC(i)
    UNTIL src[i] = 0X;
  Crc.End(c);
  ASSERT(ORD(c / {31}) = 4BF43926H); (* CBF43926 *)

  ASSERT(ORD(Crc.Calc(b, 0, 9) / {31}) = 4BF43926H);

  ASSERT(ORD(Crc.Calc(b, 1, 7)) = 2BC9895BH)
 END Go;

END Crc32t.

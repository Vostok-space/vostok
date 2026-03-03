MODULE Crc32t;

 IMPORT Crc := Crc32, ArrayCopy;

 CONST Bs = "123456789wertyuiop[]asdfghjkl;'\zxcvbnm,./QWERTYUIOP{}ASDFGHJKL;|ZXCXVBNM,>?";
 
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

 PROCEDURE Bench*(n: INTEGER): SET;
 VAR i: INTEGER; c: SET; b: ARRAY LEN(Bs) OF BYTE;
 BEGIN
  ArrayCopy.CharsToBytes(b, 0, Bs, 0, LEN(Bs));
  c := {};
  FOR i := n TO 0 BY -1 DO
    c := c / Crc.Calc(b, 0, LEN(Bs))
  END
 RETURN
  c
 END Bench;

END Crc32t.

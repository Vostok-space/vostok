MODULE O_7;

IMPORT SYSTEM;

VAR
  ch*: ARRAY 100H, 2 OF SHORTCHAR;

  PROCEDURE Byte*(i: INTEGER): BYTE;
  BEGIN
    ASSERT((0 <= i) & (i < 100H));
  RETURN
    SHORT(SHORT(i - i DIV 80H * 100H))
  END Byte;

  PROCEDURE Ord*(s: SET): INTEGER;
  BEGIN RETURN
    SYSTEM.VAL(INTEGER, s)
  END Ord;

  PROCEDURE Bti*(b: BOOLEAN): INTEGER;
  VAR i: INTEGER;
  BEGIN
    IF b THEN
      i := 1
    ELSE
      i := 0
    END;
  RETURN
    i
  END Bti;

  PROCEDURE Ror*(v, n: INTEGER): INTEGER;
  BEGIN
    ASSERT((0 <= n) & (n < 32));
  RETURN
    SYSTEM.ROT(v, n)
  END Ror;

  PROCEDURE Pack*(VAR x: REAL; n: INTEGER);
  BEGIN
    (*TODO*)
    HALT(1)
  END Pack;

  PROCEDURE Unpk*(VAR x: REAL; n: INTEGER);
  BEGIN
    (*TODO*)
    HALT(1)
  END Unpk;

  PROCEDURE InitCh;
  VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO LEN(ch) - 1 DO
      ch[i, 0] := SHORT(CHR(i));
      ch[i, 1] := 0X
    END
  END InitCh;

BEGIN
  InitCh
END O_7.

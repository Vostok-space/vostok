MODULE TestCharsetWindows1251;

 IMPORT Cw1251 := OldCharsetWindows1251, Utf8; 

 PROCEDURE Go*;
 VAR i, k: INTEGER; b0, b1: ARRAY 5 OF CHAR;
 BEGIN
  FOR i := 0 TO 0FFH DO
    k := 0;
    ASSERT(Utf8.FromCode(b0, k, Cw1251.ToUnicode(i)));
    b0[k] := 0X;

    k := 0;
    ASSERT(Cw1251.ToUtf8(b1, k, i));
    b1[k] := 0X;

    ASSERT(b0 = b1)
  END
 END Go;

END TestCharsetWindows1251.

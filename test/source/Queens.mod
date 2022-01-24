From Algrorithms and Structures. Niklaus Wirth

MODULE Queens;

IMPORT Out;

VAR
  solutionsCount, ln: INTEGER;
  x: ARRAY 8 OF INTEGER;
  a: ARRAY 8 OF BOOLEAN;
  b, c: ARRAY 15 OF BOOLEAN;
  write: BOOLEAN;

PROCEDURE Write;
VAR i: INTEGER;
BEGIN
  FOR i := 0 TO LEN(x) - 1 DO Out.Int(x[i], 2) END;
  INC(ln); IF ln = 4 THEN Out.Ln; ln := 0 ELSE Out.String("  ") END
END Write;

PROCEDURE Init; VAR i: INTEGER;
BEGIN
  FOR i := 0 TO LEN(a) - 1 DO a[i] := TRUE; x[i] := -1   END;
  FOR i := 0 TO LEN(b) - 1 DO b[i] := TRUE; c[i] := TRUE END;
  solutionsCount := 0; ln := 0
END Init;

PROCEDURE Try(i: INTEGER);
VAR j: INTEGER;
BEGIN
  IF i < LEN(x) THEN
    FOR j := 0 TO LEN(x) - 1 DO
      IF a[j] & b[i + j] & c[i - j + 7] THEN
        x[i] := j;  a[j] := FALSE; b[i + j] := FALSE; c[i - j + 7] := FALSE;
        Try(i + 1);
        x[i] := -1; a[j] := TRUE;  b[i + j] := TRUE;  c[i - j + 7] := TRUE
      END
    END
  ELSE
    IF write THEN
      Write
    END;
    INC(solutionsCount)
  END
END Try;

PROCEDURE All*;
BEGIN
  Init;
  Try(0);
  IF write THEN
    Out.String("Count of solutions: "); Out.Int(solutionsCount, 0); Out.Ln
  END
END All;

PROCEDURE Go*;
BEGIN
  write := FALSE;
  All;
  ASSERT(solutionsCount = 92)
END Go;

BEGIN
  write := TRUE
END Queens.

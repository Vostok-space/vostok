Algorithms and Data Structures © N. Wirth 1985 (Oberon version: August 2004).
§ 3.3 Example of recursive progrma. Hilbert curve.
Adapted for Vostok at 2023.

MODULE Hilbert;

 IMPORT Draw := AdDraw; 

 VAR u: INTEGER;
     b, c, d: PROCEDURE (i: INTEGER);
 
 PROCEDURE A (i: INTEGER);
 BEGIN
  IF i > 0 THEN
    d(i-1); Draw.line(4, u); A(i-1); Draw.line(6, u); A(i-1); Draw.line(0, u); b(i-1)
  END
 END A;

 PROCEDURE B (i: INTEGER);
 BEGIN
  IF i > 0 THEN
    c(i-1); Draw.line(2, u); B(i-1); Draw.line(0, u); B(i-1); Draw.line(6, u); A(i-1)
  END
 END B;

 PROCEDURE C (i: INTEGER);
 BEGIN
  IF i > 0 THEN
    B(i-1); Draw.line(0, u); C(i-1); Draw.line(2, u); C(i-1); Draw.line(4, u); d(i-1)
  END
 END C;

 PROCEDURE D (i: INTEGER);
 BEGIN
  IF i > 0 THEN
    A(i-1); Draw.line(6, u); D(i-1); Draw.line(4, u); D(i-1); Draw.line(2, u); C(i-1)
  END
 END D;

 PROCEDURE Go* (n: INTEGER);
  CONST SquareSize = 512;
  VAR i, x0, y0: INTEGER;
 BEGIN
  Draw.Clear;
  x0 := Draw.width DIV 2; y0 := Draw.height DIV 2; u := SquareSize; i := 0;
  REPEAT
    INC(i); u := u DIV 2;
    x0 := x0 + (u DIV 2); y0 := y0 + (u DIV 2);
    Draw.Set(x0, y0); A(i)
  UNTIL i = n;
  Draw.End
 END Go;

BEGIN
 b := B; c := C; d := D
END Hilbert.

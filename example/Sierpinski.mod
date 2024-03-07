Algorithms and Data Structures © N. Wirth 1985 (Oberon version: August 2004).
§ 3.3 Example of recursive progrma. Sierpinski curve.
Adapted for Vostok at 2023.

MODULE Sierpinski;

 IMPORT Draw := AdDraw;
 
 VAR h: INTEGER;
  b, c, d: PROCEDURE (i: INTEGER);

 PROCEDURE A (k: INTEGER);
 BEGIN
  IF k > 0 THEN
    A(k-1); Draw.line(7, h); b(k-1); Draw.line(0, 2*h); d(k-1);
    Draw.line(1, h); A(k-1)
  END
 END A;

 PROCEDURE B (k: INTEGER);
 BEGIN
  IF k > 0 THEN
    B(k-1); Draw.line(5, h); c(k-1); Draw.line(6, 2*h); A(k-1);
    Draw.line(7, h); B(k-1)
  END
 END B;

 PROCEDURE C (k: INTEGER);
 BEGIN
  IF k > 0 THEN
    C(k-1); Draw.line(3, h); d(k-1); Draw.line(4, 2*h); B(k-1);
    Draw.line(5, h); C(k-1)
  END
 END C;

 PROCEDURE D (k: INTEGER);
 BEGIN
  IF k > 0 THEN
    D(k-1); Draw.line(1, h); A(k-1); Draw.line(2, 2*h); C(k-1);
    Draw.line(3, h); D(k-1)
  END
 END D;

 PROCEDURE Go* (n: INTEGER);
  CONST SquareSize = 512;
  VAR i, x0, y0: INTEGER;
 BEGIN
  Draw.Clear;
  h := SquareSize DIV 4;
  x0 := Draw.width DIV 2; y0 := Draw.height DIV 2 + h; i := 0;
  REPEAT
    INC(i); x0 := x0-h;
    h := h DIV 2; y0 := y0+h; Draw.Set(x0, y0); A(i); Draw.line(7,h);
    B(i); Draw.line(5,h);
    C(i); Draw.line(3,h); D(i); Draw.line(1,h)
  UNTIL i = n;
  Draw.End
 END Go;

BEGIN
 b := B; c := C; d := D
END Sierpinski.

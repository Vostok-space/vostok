MODULE ColorCells;

  IMPORT
    Drawable := AndroidO7Drawable,
    Canvas   := AndroidCanvas,
    Paint    := AndroidPaint;

  PROCEDURE Draw(ignored: Drawable.Context; cnv: Canvas.T);
  VAR i, j: INTEGER; x, y: REAL; paint: Paint.T; nx, ny: INTEGER;
  BEGIN
    nx := Drawable.Width () DIV 40;
    ny := Drawable.Height() DIV 20;

    paint := Paint.New();

    FOR i := 0 TO ny DO
      FOR j := 0 TO nx DO
        x := FLT(j * 40 + i MOD 2 * 20);
        y := FLT(i * 20);
        Paint.SetColor(paint, 0FF0000H + 0FFH * i DIV ny * 100H + 0FFH * j DIV nx);
        Canvas.Rect(cnv, x, y, x + 20.0, y + 20.0, paint)
      END
    END
  END Draw;

  PROCEDURE Go*;
  BEGIN
    Drawable.SetDrawer(Draw, NIL)
  END Go;

END ColorCells.

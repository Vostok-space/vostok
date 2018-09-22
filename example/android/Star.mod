MODULE Star;

  IMPORT
    Drawable := AndroidO7Drawable,
    Canvas   := AndroidCanvas,
    Paint    := AndroidPaint,
    Path     := AndroidGraphPath,
    Math;

  TYPE
    Context = POINTER TO RECORD(Drawable.RContext)
      rays: INTEGER;
      ratio: REAL
    END;

  PROCEDURE Draw*(cnv: Canvas.T; paint: Paint.T; path: Path.T;
                  rays: INTEGER; x0, y0, r1, r2, angle: REAL);
  VAR i: INTEGER;
      a, da: REAL;
      r: ARRAY 2 OF REAL;
  BEGIN
    a  := angle;
    da := Math.pi / FLT(rays);

    r[1] := r1;
    r[0] := r2;

    Path.Reset(path);
    Path.MoveTo(path,
                x0 + Math.sin(a) * r1,
                y0 - Math.cos(a) * r1);

    FOR i := rays * 2 TO 1 BY -1 DO
      a := a + da;
      Path.LineTo(path,
                  x0 + Math.sin(a) * r[i MOD 2],
                  y0 - Math.cos(a) * r[i MOD 2])
    END;
    Canvas.Path(cnv, path, paint)
  END Draw;

  PROCEDURE Drawer(ctx: Drawable.Context; cnv: Canvas.T);
  VAR x0, y0, r: REAL; paint: Paint.T; path: Path.T;
  BEGIN
    paint := Paint.New();
    path  := Path.New();
    Paint.SetColor(paint, 0FF0000H);

    x0 := FLT(Drawable.Width () DIV 2);
    y0 := FLT(Drawable.Height() DIV 2);
    IF x0 < y0 THEN
      r := x0 - 10.0
    ELSE
      r := y0 - 10.0
    END;
    Draw(cnv, paint, path, ctx(Context).rays, x0, y0, r, r * ctx(Context).ratio, 0.0)
  END Drawer;

  PROCEDURE Go*(rays: INTEGER; ratio: REAL);
  VAR ctx: Context;
  BEGIN
    NEW(ctx);
    IF rays > 256 THEN
      ctx.rays := 256
    ELSE
      ctx.rays := rays
    END;
    IF ratio < 0.0 THEN
      ctx.ratio := 0.0
    ELSIF ratio > 1.0 THEN
      ctx.ratio := 1.0
    ELSE
      ctx.ratio := ratio
    END;
    Drawable.SetDrawer(Drawer, ctx)
  END Go;

END Star.

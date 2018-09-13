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

  PROCEDURE Draw(ctx: Drawable.Context; cnv: Canvas.T);
  VAR i: INTEGER;
      x0, y0, a, da: REAL;
      r: ARRAY 2 OF REAL;
      color: Paint.T;
      path: Path.T;
  BEGIN
    color := Paint.New();
    Paint.SetColor(color, 0FF0000H);
    Paint.SetStyleFill(color);

    a := 0.0;
    da := Math.pi / FLT(ctx(Context).rays);
    x0 := 160.0;
    y0 := 160.0;
    r[1] := 128.0;
    r[0] := r[1] * ctx(Context).ratio;

    path := Path.New();
    Path.MoveTo(path, x0, y0 - r[1]);

    FOR i := ctx(Context).rays * 2 TO 1 BY -1 DO
      a := a + da;
      Path.LineTo(path,
                  x0 + Math.sin(a) * r[i MOD 2],
                  y0 - Math.cos(a) * r[i MOD 2])
    END;
    Canvas.Path(cnv, path, color)
  END Draw;

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
    Drawable.SetDrawer(Draw, ctx)
  END Go;

END Star.

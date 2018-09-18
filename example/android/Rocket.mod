MODULE Rocket;

  IMPORT
    Drawable := AndroidO7Drawable,
    Canvas   := AndroidCanvas,
    Paint    := AndroidPaint,
    Path     := AndroidGraphPath,
    Star,
    Math;

  TYPE
    Stars = ARRAY 63 OF RECORD
              x, y: INTEGER;
              wide: BOOLEAN
            END;

    Context = POINTER TO RECORD(Drawable.RContext)
      r, fr: REAL;
      i: INTEGER;

      path: Path.T;
      paint: Paint.T;

      stars: Stars;
      rand: INTEGER
    END;

  PROCEDURE Draw(cnv: Canvas.T; paint: Paint.T; path: Path.T;
                 x0, y0, size, a, r: REAL);
    PROCEDURE Flame(cnv: Canvas.T; paint: Paint.T; path: Path.T;
                    x0, y0, size, r: REAL);
    BEGIN
      Path.Reset(path);
      Path.MoveTo(path, x0, y0 + size * 0.8);
      Path.LineTo(path, x0 + size * 0.15, y0 + size * 0.935);
      Path.LineTo(path, x0 - r, y0 + size * 1.6);
      Path.LineTo(path, x0 - size * 0.15, y0 + size * 0.935);
      Path.LineTo(path, x0, y0 + size * 0.8);
      Paint.SetColor(paint, 0FFDD40H);
      Canvas.Path(cnv, path, paint);

      Path.Reset(path);
      Path.MoveTo(path, x0, y0 + size * 0.8);
      Path.LineTo(path, x0 + size * 0.1, y0 + size * 0.88);
      Path.LineTo(path, x0 - r / 2.0, y0 + size * 1.2);
      Path.LineTo(path, x0 - size * 0.1, y0 + size * 0.89);
      Path.LineTo(path, x0, y0 + size * 0.8);
      Paint.SetColor(paint, 0FFA240H);
      Canvas.Path(cnv, path, paint)
    END Flame;
  BEGIN
    Flame(cnv, paint, path, x0, y0, size, r);

    Path.Reset(path);
    Path.MoveTo(path, x0, y0);
    Path.LineTo(path, x0 + size * 0.22, y0 + size);
    Path.LineTo(path, x0, y0 + size * 0.8);
    Path.LineTo(path, x0 - size * 0.22, y0 + size);
    Path.LineTo(path, x0, y0);

    Paint.SetColor(paint, 0FFFFFFH);
    Canvas.Path(cnv, path, paint);

    Paint.SetColor(paint, 0FF0000H);
    Star.Draw(cnv, paint, path, 5,
              x0, y0 + size / 3.0, size / 20.0, size / 60.0, 0.0)
  END Draw;

  PROCEDURE Sky(cnv: Canvas.T; paint: Paint.T; stars: Stars);
  VAR i: INTEGER;
  BEGIN
    Paint.SetColor(paint, 0FFFFFFH);

    FOR i := 0 TO LEN(stars) - 1 DO
      Canvas.Line(cnv, FLT(stars[i].x), FLT(stars[i].y),
                       FLT(stars[i].x), FLT(stars[i].y + 30), paint);
      IF stars[i].wide THEN
        Canvas.Line(cnv, FLT(stars[i].x + 1), FLT(stars[i].y),
                         FLT(stars[i].x + 1), FLT(stars[i].y + 30), paint)
      END
    END
  END Sky;

  PROCEDURE InitStars(ctx: Context; w, h: INTEGER);
  VAR i: INTEGER;
  BEGIN
    ctx.rand := 13;
    FOR i := 0 TO LEN(ctx.stars) - 1 DO
      ctx.rand := (ctx.rand * 67 + 133) MOD 49547381;
      ctx.stars[i].x := ctx.rand DIV 8 MOD w;
      ctx.rand := (ctx.rand * 67 + 133) MOD 49547381;
      ctx.stars[i].y := ctx.rand DIV 8 MOD (h + 60);
      ctx.stars[i].wide := ctx.rand DIV 64 MOD 2 = 0
    END
  END InitStars;

  PROCEDURE MoveStars(ctx: Context; w, h: INTEGER);
  VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO LEN(ctx.stars) - 1 DO
      ctx.stars[i].y := ctx.stars[i].y + 14;
      IF ctx.stars[i].y > h THEN
        ctx.rand := (ctx.rand * 67 + 133) MOD 49547381;
        ctx.stars[i].x := ctx.rand DIV 8 MOD w;
        ctx.rand := (ctx.rand * 67 + 133) MOD 49547381;
        ctx.stars[i].y := - ctx.rand DIV 8 MOD 130
      END
    END
  END MoveStars;

  PROCEDURE Drawer(context: Drawable.Context; cnv: Canvas.T);
  VAR r: REAL; i: INTEGER; ctx: Context; w, h: INTEGER;
  BEGIN
    ctx := context(Context);

    w := Drawable.Width();
    h := Drawable.Height();
    IF ctx.rand = -1 THEN
      InitStars(ctx, w, h)
    ELSE
      MoveStars(ctx, w, h)
    END;

    r := ctx.r;
    i := ctx.i;
    ctx.i := (i + 1) MOD h;
    IF i MOD 3 = 0 THEN
      ctx.r := 0.0 - r
    END;
    IF (i + 1) MOD 2 = 0 THEN
      ctx.fr := 0.0 - ctx.fr
    END;
    Sky(cnv, ctx.paint, ctx.stars);
    Draw(cnv, ctx.paint, ctx.path,
         FLT(w DIV 2) + r, 20.0, FLT(h) * 0.6, 0.0, ctx.fr);

    Drawable.Invalidate
  END Drawer;

  PROCEDURE Go*;
  VAR ctx: Context;
  BEGIN
    NEW(ctx);
    ctx.r     := -1.0;
    ctx.fr    := 4.0;
    ctx.i     := 0;

    ctx.path  := Path.New();
    ctx.paint := Paint.New();

    ctx.rand := -1;

    Drawable.SetDrawer(Drawer, ctx)
  END Go;

END Rocket.

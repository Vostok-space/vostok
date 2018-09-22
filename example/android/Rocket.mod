MODULE Rocket;

  IMPORT
    Drawable := AndroidO7Drawable,
    Canvas   := AndroidCanvas,
    Paint    := AndroidPaint,
    Path     := AndroidGraphPath,
    Star,
    Math,
    Rand := OsRand;

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

      stars: Stars
    END;

  PROCEDURE Draw(cnv: Canvas.T; paint: Paint.T; path: Path.T;
                 x0, y0, size, a, r, df: REAL);
    PROCEDURE Flame(cnv: Canvas.T; paint: Paint.T; path: Path.T;
                    x0, y0, size, r, df: REAL);
    BEGIN
      Path.Reset(path);
      Path.MoveTo(path, x0, y0 + size * 0.8);
      Path.LineTo(path, x0 + size * 0.15, y0 + size * 0.935);
      Path.LineTo(path, x0 - r, y0 + size * (1.5 + df));
      Path.LineTo(path, x0 - size * 0.15, y0 + size * 0.935);
      Path.LineTo(path, x0, y0 + size * 0.8);
      Paint.SetColor(paint, 0FFDD40H);
      Canvas.Path(cnv, path, paint);

      Path.Reset(path);
      Path.MoveTo(path, x0, y0 + size * 0.8);
      Path.LineTo(path, x0 + size * 0.1, y0 + size * 0.88);
      Path.LineTo(path, x0 - r / 2.0, y0 + size * (1.1 + df / 4.0));
      Path.LineTo(path, x0 - size * 0.1, y0 + size * 0.89);
      Path.LineTo(path, x0, y0 + size * 0.8);
      Paint.SetColor(paint, 0FFA240H);
      Canvas.Path(cnv, path, paint)
    END Flame;
  BEGIN
    Flame(cnv, paint, path, x0, y0, size, r, df);

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
  VAR i, j, wide: INTEGER;
  BEGIN
    Paint.SetColor(paint, 0FFFFFFH);
    FOR i := 0 TO LEN(stars) - 1 DO
      wide := ORD(stars[i].wide);
      FOR j := 0 TO wide DO
        Canvas.Line(cnv,
          FLT(stars[i].x) + FLT(j) / 2.0, FLT(stars[i].y),
          FLT(stars[i].x) + FLT(j) / 2.0, FLT(stars[i].y + 30 DIV (2 - wide)),
          paint)
      END
    END
  END Sky;

  PROCEDURE InitStars(VAR stars: Stars; w, h: INTEGER);
  VAR i, r: INTEGER;
  BEGIN
    FOR i := 0 TO LEN(stars) - 1 DO
      IF Rand.Int(r) THEN
        stars[i].x := r MOD w;
        stars[i].y := r DIV w MOD (h + 60);
        stars[i].wide := r MOD 3 = 0
      END
    END
  END InitStars;

  PROCEDURE MoveStars(VAR stars: Stars; w, h: INTEGER);
  VAR i, r: INTEGER;
  BEGIN
    FOR i := 0 TO LEN(stars) - 1 DO
      stars[i].y := stars[i].y + 14 DIV (2 - ORD(stars[i].wide));
      IF (stars[i].y > h) & Rand.Int(r) THEN
        stars[i].x := r MOD w;
        stars[i].y := - r DIV w MOD 130
      END
    END
  END MoveStars;

  PROCEDURE Drawer(context: Drawable.Context; cnv: Canvas.T);
  VAR r: REAL; i, w, h, df: INTEGER; ctx: Context;
  BEGIN
    ctx := context(Context);

    w := Drawable.Width();
    h := Drawable.Height();
    IF ctx.paint = NIL THEN
      ctx.paint := Paint.New();
      InitStars(ctx.stars, w, h)
    ELSE
      MoveStars(ctx.stars, w, h)
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
    IF Rand.Int(df) THEN
      Draw(cnv, ctx.paint, ctx.path,
           FLT(w DIV 2) + r, 20.0, FLT(h) * 0.6, 0.0, ctx.fr,
           FLT(df MOD 32) / 200.)
    END;
    Drawable.Invalidate
  END Drawer;

  PROCEDURE Go*;
  VAR ctx: Context;
  BEGIN
    IF Rand.Open() THEN
      NEW(ctx);
      ctx.r     := -1.0;
      ctx.fr    := 4.0;
      ctx.i     := 0;

      ctx.path  := Path.New();

      Drawable.SetDrawer(Drawer, ctx)
    END
  END Go;

END Rocket.

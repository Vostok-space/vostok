MODULE TextAndTouch;

  IMPORT
    Drawable := AndroidO7Drawable,
    Canvas   := AndroidCanvas,
    Paint    := AndroidPaint,
    Path     := AndroidGraphPath,
    Motion   := AndroidMotionEvent,
    Itc      := IntToChars0X,
    Rtc      := RealToChars0X,
    Chars    := Chars0X,
    log;

  TYPE
    Context = POINTER TO RECORD(Drawable.RContext)
      text: ARRAY 4 OF ARRAY 256 OF CHAR
    END;

  PROCEDURE Drawer(context: Drawable.Context; cnv: Canvas.T);
  VAR x0, y0, w, h, asc, desc: REAL; paint: Paint.T; path: Path.T; ctx: Context; i, j: INTEGER;
      t: ARRAY 64 OF CHAR;
  BEGIN
    paint := Paint.New();

    w := FLT(Drawable.Width ());
    h := FLT(Drawable.Height());

    Paint.SetColor(paint, 0);
    Canvas.Rect(cnv, 0.0, 0.0, w, h, paint);

    path  := Path.New();

    x0 := w / 2.0;
    y0 := h / 2.0;

    Paint.SetTextSize(paint, 27.0);
    Paint.SetTextAlign(paint, Paint.Left);
    asc := Paint.Ascent(paint);
    desc := Paint.Descent(paint);

    j := 0;
    Paint.SetColor(paint, 7FFF7FH);
    ASSERT(Chars.CopyString(t, j, "ascent: ") & Rtc.Exp(t, j, asc, 0));
    Canvas.Text(cnv, t, 0, 10., 100., paint);
    j := 0;
    Paint.SetColor(paint, 7F7FFFH);
    ASSERT(Chars.CopyString(t, j, "descent: ") & Rtc.Exp(t, j, desc, 0));
    Canvas.Text(cnv, t, 0, 40., 140., paint);

    Paint.SetTextAlign(paint, Paint.Center);
    Paint.SetColor(paint, 0FFFFFFH);

    ctx := context(Context);
    FOR i := 0 TO LEN(ctx.text) - 1 DO
      Canvas.Text(cnv, ctx.text[i], 0, x0, y0 + (desc - asc) * FLT(i), paint)
    END;

    Paint.SetColor(paint, 7FFF7FH);
    Canvas.Line(cnv, 0.0, y0 + asc, w, y0 + asc, paint);
    Paint.SetColor(paint, 7F7F7FH);
    Canvas.Line(cnv, 0.0, y0, w, y0, paint);
    Paint.SetColor(paint, 7F7FFFH);
    Canvas.Line(cnv, 0.0, y0 + desc, w, y0 + desc, paint)
  END Drawer;

  PROCEDURE Sp(VAR str: ARRAY OF CHAR; VAR ofs: INTEGER): BOOLEAN;
  RETURN
    Chars.PutChar(str, ofs, " ")
  END Sp;

  PROCEDURE Touched*(ctx: Drawable.Context; e: Motion.T): BOOLEAN;
  VAR act, id: INTEGER;

    PROCEDURE Text0(VAR s: ARRAY OF CHAR; act, id: INTEGER; e: Motion.T): BOOLEAN;
    VAR i: INTEGER;
    BEGIN
      i := 0
    RETURN
      Chars.CopyString(s, i, "action: ")
    & Itc.Dec(s, i, act MOD 100H, 0)
    & Sp     (s, i)
    & Chars.CopyString(s, i, "id: ")
    & Itc.Dec(s, i, Motion.GetPointerId(e, id), 0)
    & Sp     (s, i)
    & Sp     (s, i)
    & Rtc.Exp(s, i, Motion.GetX(e, id), 8)
    & Chars.PutChar(s, i, ":")
    & Rtc.Exp(s, i, Motion.GetY(e, id), 8)
    END Text0;

    PROCEDURE Text1(VAR s: ARRAY OF ARRAY OF CHAR; id: INTEGER; e: Motion.T): BOOLEAN;
    VAR i, j, k: INTEGER;
    BEGIN
      i := 0;
      j := 0;
      k := 0
    RETURN
      Chars.CopyString(s[1], i, "source: ")
    & Itc.Hex         (s[1], i, Motion.GetSource(e), 0)
    & Chars.CopyString(s[2], j, " tool: ")
    & Rtc.Exp         (s[2], j, Motion.GetToolMajor(e, id), 8)
    & Chars.PutChar   (s[2], j, ":")
    & Rtc.Exp         (s[2], j, Motion.GetToolMinor(e, id), 8)
    & Chars.CopyString(s[3], k, " touch: ")
    & Rtc.Exp         (s[3], k, Motion.GetTouchMajor(e, id), 8)
    & Chars.PutChar   (s[3], k, ":")
    & Rtc.Exp         (s[3], k, Motion.GetTouchMinor(e, id), 8)

    END Text1;
  BEGIN
    act := Motion.GetAction(e);
    id := act DIV 100H;

    ASSERT(Text0(ctx(Context).text[0], act, id, e)
         & Text1(ctx(Context).text, id, e));

    Drawable.Invalidate

  RETURN
    TRUE
  END Touched;

  PROCEDURE Go*;
  VAR ctx: Context;
  BEGIN
    NEW(ctx);
    ctx.text[0] := 0X;
    ctx.text[1] := 0X;
    Drawable.SetDrawer(Drawer, ctx);
    Drawable.SetToucher(Touched)
  END Go;

END TextAndTouch.

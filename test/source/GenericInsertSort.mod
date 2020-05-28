MODULE GenericInsertSort;

  IMPORT Out, CLI;

  TYPE
    Compare = PROCEDURE(ctx, a, b: POINTER): INTEGER;

    IntPoint = POINTER TO RECORD
      x, y: INTEGER
    END;

  PROCEDURE Sort(VAR arr: ARRAY OF POINTER; cnt: INTEGER; cmp: Compare; ctx: POINTER);
  VAR i, j: INTEGER; a: POINTER;
  BEGIN
    FOR i := 1 TO cnt - 1 DO
      a := arr[i];
      j := i - 1;
      WHILE (j >= 0) & (cmp(ctx, a, arr[j]) < 0) DO
        arr[j + 1] := arr[j];
        DEC(j)
      END;
      arr[j + 1] := a
    END
  END Sort;

  PROCEDURE NewPoint(x, y: INTEGER): IntPoint;
  VAR p: IntPoint;
  BEGIN
    NEW(p);
    IF p # NIL THEN
      p.x := x;
      p.y := y
    END
  RETURN
    p
  END NewPoint;

  PROCEDURE IntPointCompare(c, a, b: IntPoint): INTEGER;
  VAR ax, ay, bx, by: INTEGER;
  BEGIN
    ax := a.x - c.x;
    ay := a.y - c.y;
    bx := b.x - c.x;
    by := b.y - c.y
  RETURN
    ax * ax + ay * ay - bx * bx - by * by
  END IntPointCompare;

  PROCEDURE InitArray(VAR arr: ARRAY OF IntPoint; cnt: INTEGER);
  VAR i: INTEGER;
  BEGIN
    i := cnt;
    WHILE i > 0 DO
      DEC(i);
      arr[i] := NewPoint(cnt - i, cnt - i)
    END
  END InitArray;

  PROCEDURE PrintArray(arr: ARRAY OF IntPoint; cnt: INTEGER; baseX, baseY: INTEGER);
  VAR i, x, y, ix, iy: INTEGER;
  BEGIN
    FOR i := 0 TO cnt - 1 DO
      ix := arr[i].x;
      x := ix - baseX;
      iy := arr[i].y;
      y := iy - baseY;
      Out.Int(i, 2); Out.String(") ("); Out.Int(ix, 3); Out.String(":");
      Out.Int(iy, 3); Out.String(") : "); Out.Int(x * x + y * y, 0);
      Out.Ln
    END
  END PrintArray;

  PROCEDURE ReleaseArray(VAR arr: ARRAY OF POINTER; cnt: INTEGER);
  VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO cnt - 1 DO
      arr[i] := NIL
    END
  END ReleaseArray;

  PROCEDURE Check(arr: ARRAY OF IntPoint; cnt: INTEGER);
  VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO cnt - 1 DO
      ASSERT(arr[i].x = i + 1);
      ASSERT(arr[i].y = i + 1)
    END
  END Check;

  PROCEDURE Go*;
  VAR cnt: INTEGER; points: ARRAY 20000 OF IntPoint; baseX, baseY: INTEGER;
  BEGIN
    baseX := 0; baseY := 0;
    IF CLI.count > 0 THEN
      cnt := 20
    ELSE
      cnt := 20000
    END;
    IF cnt > 0 THEN
      InitArray(points, cnt);
      IF cnt <= 20 THEN
        PrintArray(points, cnt, baseX, baseY);
        Out.Ln;
        Sort(points, cnt, IntPointCompare, NewPoint(baseX, baseY));
        PrintArray(points, cnt, baseX, baseY)
      ELSE
        Sort(points, cnt, IntPointCompare, NewPoint(baseX, baseY))
      END;
      Check(points, cnt);

      ReleaseArray(points, cnt)
    END
  END Go;

END GenericInsertSort.

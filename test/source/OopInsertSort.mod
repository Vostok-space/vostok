MODULE OopInsertSort;

IMPORT Out, CLI;

TYPE
	RElement = RECORD END;
	Element = POINTER TO RElement;

	Base = RECORD END;

	Comparator = RECORD(Base)
		compare: PROCEDURE(c: Base; a, b: Element): INTEGER
	END;

	(*
	Compare = PROCEDURE(c: Comparator; a, b: Element): INTEGER;
	*)

	IntPoint = POINTER TO RECORD(RElement)
		x, y: INTEGER
	END;

	PointComparator = RECORD(Comparator)
		x, y: INTEGER
	END;

	PointArray = POINTER TO RECORD
		arr: ARRAY 40000 OF Element;
		cnt: INTEGER
	END;

PROCEDURE sort(VAR arr: ARRAY OF Element; cnt: INTEGER; cmp: Comparator);
VAR i, j: INTEGER;
	a: Element;
BEGIN
	FOR i := 1 TO cnt - 1 DO
		a := arr[i];
		j := i - 1;
		WHILE (j >= 0) & (cmp.compare(cmp, a, arr[j]) < 0) DO
			arr[j + 1] := arr[j];
			DEC(j)
		END;
		arr[j + 1] := a
	END
END sort;

PROCEDURE NewPoint(x, y: INTEGER): IntPoint;
VAR p: IntPoint;
BEGIN
	NEW(p);
	IF p # NIL THEN
		p.x := x;
		p.y := y
	END
RETURN p
END NewPoint;

PROCEDURE compare(c: Base; a, b: Element): INTEGER;
	PROCEDURE cmp(c: PointComparator; a, b: IntPoint): INTEGER;
	VAR ax, ay, bx, by: INTEGER;
	BEGIN
		ax := a.x - c.x;
		ay := a.y - c.y;
		bx := b.x - c.x;
		by := b.y - c.y
	RETURN ax * ax + ay * ay - bx * bx - by * by
	END cmp;
RETURN cmp(c(PointComparator), a(IntPoint), b(IntPoint))
END compare;

PROCEDURE cmpInit(VAR cmp: PointComparator; x, y: INTEGER);
BEGIN
	cmp.compare := compare;
	cmp.x := x;
	cmp.y := y
END cmpInit;

PROCEDURE createArray(cnt: INTEGER): PointArray;
VAR arr: PointArray;
BEGIN
	NEW(arr);
	IF arr # NIL THEN
		arr.cnt := cnt;
		WHILE cnt > 0 DO
			DEC(cnt);
			arr.arr[cnt] := NewPoint(arr.cnt - cnt, arr.cnt - cnt)
		END
	END
RETURN arr
END createArray;

PROCEDURE printArray(arr: PointArray; baseX, baseY: INTEGER);
VAR i, x, y, ix, iy: INTEGER;
BEGIN
	FOR i := 0 TO arr.cnt - 1 DO
		ix := arr.arr[i](IntPoint).x;
		x := ix - baseX;
		iy := arr.arr[i](IntPoint).y;
		y := iy - baseY;
		Out.Int(i, 2); Out.String(") ("); Out.Int(ix, 3); Out.String(":");
		Out.Int(iy, 3); Out.String(") : "); Out.Int(x * x + y * y, 0);
		Out.Ln
	END
END printArray;

PROCEDURE releaseArray(arr: PointArray);
VAR i: INTEGER;
BEGIN
	FOR i := 0 TO arr.cnt - 1 DO
		arr.arr[i] := NIL
	END
END releaseArray;

PROCEDURE Check(arr: PointArray);
VAR i: INTEGER;
BEGIN
	FOR i := 0 TO arr.cnt - 1 DO
		ASSERT(arr.arr[i](IntPoint).x = i + 1);
		ASSERT(arr.arr[i](IntPoint).y = i + 1)
	END
END Check;

PROCEDURE Go*;
VAR cnt: INTEGER;
	points: PointArray;
	baseX, baseY: INTEGER;
	cmp: PointComparator;
BEGIN
	baseX := 0; baseY := 0;
	cmpInit(cmp, baseX, baseY);
	IF CLI.count > 0 THEN
		cnt := 20
	ELSE
		cnt := 200
	END;
	IF cnt > 0 THEN
		points := createArray(cnt);
		IF points # NIL THEN
			IF cnt <= 20 THEN
				printArray(points, baseX, baseY);
				Out.Ln;
				sort(points.arr, points.cnt, cmp);
				printArray(points, baseX, baseY)
			ELSE
				sort(points.arr, points.cnt, cmp)
			END;
			Check(points);

			releaseArray(points)
		END
	END
END Go;

END OopInsertSort.

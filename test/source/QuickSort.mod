MODULE QuickSort;

PROCEDURE Lr(VAR a: ARRAY OF INTEGER; l, r: INTEGER);
VAR i, j, m, t: INTEGER;
BEGIN
	i := l;
	j := r;
	m := (i + j) DIV 2;

	REPEAT
		WHILE a[i] < a[m] DO
			INC(i)
		END;
		WHILE a[j] > a[m] DO
			DEC(j)
		END;
		IF i <= j THEN
			t := a[i];
			a[i] := a[j];
			a[j] := t;
			INC(i);
			DEC(j)
		END
	UNTIL i > j;
	IF l < j THEN
		Lr(a, l, j)
	END;
	IF i < r THEN
		Lr(a, i, r)
	END
END Lr;

PROCEDURE SortLR*(VAR a: ARRAY OF INTEGER; l, r: INTEGER);
BEGIN
	ASSERT(0 <= l);
	ASSERT(r < LEN(a));
	ASSERT(l <= r);
	Lr(a, l, r)
END SortLR;

PROCEDURE Sort*(VAR a: ARRAY OF INTEGER);
BEGIN
	Lr(a, 0, LEN(a) - 1)
END Sort;

PROCEDURE Go*;
VAR i: INTEGER;
	a: ARRAY 11111 OF INTEGER;
BEGIN
	FOR i := 0 TO LEN(a) - 1 DO
		a[i] := LEN(a) - i
	END;

	Sort(a);

	FOR i := 0 TO LEN(a) - 1 DO
		ASSERT(a[i] = i + 1)
	END
END Go;

END QuickSort.

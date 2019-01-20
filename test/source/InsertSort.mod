MODULE InsertSort;

  PROCEDURE Sort*(VAR arr: ARRAY OF INTEGER);
  VAR i, j, a: INTEGER;
  BEGIN
    FOR i := 1 TO LEN(arr) - 1 DO
      a := arr[i];
      j := i - 1;
      WHILE (j >= 0) & (a < arr[j]) DO
        arr[j + 1] := arr[j];
        DEC(j)
      END;
      arr[j + 1] := a
    END
  END Sort;

  PROCEDURE Go*;
  VAR i: INTEGER;
      a: ARRAY 1837 OF INTEGER;
  BEGIN
    FOR i := 0 TO LEN(a) - 1 DO
      a[i] := LEN(a) - i
    END;

    Sort(a);

    FOR i := 0 TO LEN(a) - 1 DO
      ASSERT(a[i] = i + 1)
    END
  END Go;

END InsertSort.

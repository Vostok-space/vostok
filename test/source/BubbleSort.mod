MODULE BubbleSort;

 PROCEDURE Sort*(VAR a: ARRAY OF REAL);
 VAR tmp: REAL; i, j: INTEGER;
 BEGIN
   FOR i := 0 TO LEN(a) - 1 DO
     FOR j := 0 TO LEN(a) - 2 - i DO
       IF a[j + 1] < a[j] THEN
         tmp := a[j + 1];
         a[j + 1] := a[j];
         a[j] := tmp
       END
     END
   END
 END Sort;

 PROCEDURE Go*;
 END Go;

END BubbleSort.

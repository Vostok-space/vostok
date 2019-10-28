MODULE BubbleSort;

 PROCEDURE Sort*(VAR a: ARRAY OF REAL);
 VAR i, j: INTEGER;
   PROCEDURE Swap(VAR a, b: REAL);
   VAR t: REAL;
   BEGIN
     t := a;
     a := b;
     b := t
   END Swap;
 BEGIN
   FOR i := 0 TO LEN(a) - 1 DO
     FOR j := 0 TO LEN(a) - 2 - i DO
       IF a[j + 1] < a[j] THEN
         Swap(a[j + 1], a[j])
       END
     END
   END
 END Sort;

END BubbleSort.

(* По мотивам тестового кода Ивана Денисова
   https://zx.oberon2.ru/forum/viewtopic.php?f=112&t=284#p2568 *)
MODULE BubbleSortTest;

 IMPORT Out, OsRand, BubbleSort;

 VAR array*: ARRAY 1000 OF REAL;

 PROCEDURE Fill*;
 VAR i, v: INTEGER;
 BEGIN
   ASSERT(OsRand.Open());
   FOR i := 0 TO LEN(array) - 1 DO
     ASSERT(OsRand.Int(v));
     array[i] := (FLT(v) + 2147483647.0) / 4294967295.0
   END;
   OsRand.Close;
 END Fill;

 PROCEDURE Show*;
 VAR i: INTEGER;
 BEGIN
   Out.Open;
   FOR i := 0 TO LEN(array) - 1 DO
     Out.Real(array[i], 0); Out.Ln
   END
 END Show;

 PROCEDURE Check*;
 VAR i: INTEGER;
 BEGIN
   FOR i := 0 TO LEN(array) - 2 DO
     ASSERT(array[i] <= array[i + 1])
   END
 END Check;

 PROCEDURE Go*;
 BEGIN
   Fill;
   BubbleSort.Sort(array);
   Check
 END Go;

END BubbleSortTest.

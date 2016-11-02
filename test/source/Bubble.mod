(* Сделан на основе модуля, написанного Алексеем Веселовским
 * https://github.com/valexey/bubble_test *)
MODULE Bubble;

IMPORT Out;

CONST n = 4000;
	  Print = FALSE;

	PROCEDURE PrintAll(arr: ARRAY OF INTEGER);
	VAR i: INTEGER;
	BEGIN
		IF Print THEN
			FOR i := 0 TO LEN(arr) - 1 DO
				Out.Int(arr[i], 0);
				Out.Ln
			END
		END
	END PrintAll;

	PROCEDURE Check(arr: ARRAY OF INTEGER);
	VAR i: INTEGER;
	BEGIN
		FOR i := 1 TO LEN(arr) DO
			ASSERT(arr[i - 1] = i)
		END
	END Check;

	PROCEDURE DoIt*;
	VAR
		arr : ARRAY n OF INTEGER;
		i, j, tmp : INTEGER;
	BEGIN
		
		FOR i := 0 TO n - 1 DO
			arr[i] := n-i
		END;

		PrintAll(arr);
		Out.String("---");
		Out.Ln;
		
		FOR i:=0 TO n-1 DO
			FOR j:=0 TO n-2-i DO
				tmp := arr[j];
				IF arr[j] > arr[j+1] THEN
					arr[j] := arr[j+1];
					arr[j+1] := tmp
				END
			END
		END;

		PrintAll(arr);
		Check(arr)
	END DoIt;

BEGIN
	DoIt
END Bubble.

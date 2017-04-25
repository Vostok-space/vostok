(*	Автор: Trurl
	http://oberspace.dyndns.org/index.php/topic,689.msg21632.html#msg21632
 *)
MODULE Queens;

IMPORT Out;

VAR count:INTEGER;
	board: ARRAY 32 OF INTEGER;

PROCEDURE canplace(row,col:INTEGER):BOOLEAN;
VAR i:INTEGER;
BEGIN
	i:=1;
	WHILE (i < row) & (board[i] # col) & (ABS(board[i]-col) # ABS(i-row)) DO
		INC(i)
	END
	RETURN i = row
END canplace;

PROCEDURE queen(row, n:INTEGER);
VAR col:INTEGER;
BEGIN
	FOR col := 1 TO n DO
	IF canplace(row,col)  THEN
		board[row] := col;
		IF row = n THEN count := count + 1 ELSE queen(row+1, n)  END
		END
	END
END queen;

PROCEDURE solve(n:INTEGER);
BEGIN
	count := 0;
	queen(1,n)
END solve;

PROCEDURE Do*(N:INTEGER);
BEGIN
	Out.String("Solving "); Out.Int(N, 0); Out.String(" Queens Problem"); Out.Ln;
	solve(N);
	Out.Int(count, 0); Out.String(" solutions found"); Out.Ln
END Do;

PROCEDURE Go*;
BEGIN
	Do(11);
	ASSERT(count = 2680)
END Go;

END Queens.

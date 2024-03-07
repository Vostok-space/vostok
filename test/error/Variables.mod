MODULE Variables;

 VAR data*: ARRAY 11 OF BYTE; i*: INTEGER;

 PROCEDURE Go*;
 BEGIN
  data[i - 1] := 0FFH
 END Go;

BEGIN
  FOR i := LEN(data) - 1 TO 0 BY -1 DO data[i] := i * i END
END Variables.

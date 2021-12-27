MODULE Inc;

PROCEDURE Inc*(VAR i: INTEGER);
BEGIN
  INC(i)
END Inc;

PROCEDURE Go*;
VAR i, j: INTEGER;
BEGIN
  j := 2;
  i := 1;
  INC(i, j);
  ASSERT(i = 3);
  ASSERT(j = 2);

  Inc(j);
  ASSERT(j = 3)
END Go;

END Inc.

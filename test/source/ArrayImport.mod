MODULE ArrayImport;

IMPORT Array;

PROCEDURE Go*;
VAR l: INTEGER;
BEGIN
  l := LEN(Array.a);
  ASSERT(l = 33);

  ASSERT(Array.a[l - 1] = 11X)
END Go;

END ArrayImport.

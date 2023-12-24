MODULE UseWithoutImport;

 IMPORT Out;

 CONST

 TYPE

 VAR

 PROCEDURE Go*;
 BEGIN
  In.Open;
  IF In.Done THEN
    In.String(str);
    Out.String(str)
  END
 END Go;

END UseWithoutImport.

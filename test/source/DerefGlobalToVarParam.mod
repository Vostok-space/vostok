(* Выявление ложной статической диагностики использования неинициализированной
   переменной при разыменовании глобального указателя для передачи как
   VAR параметра *)
MODULE DerefGlobalToVarParam;

  TYPE
    Rec = RECORD
      i: INTEGER
    END;
    Ptr = POINTER TO Rec;

  VAR
    var: Ptr;

  PROCEDURE Init(VAR r: Rec);
  BEGIN
    r.i := 2
  END Init;

  PROCEDURE Go*;
  BEGIN
    Init(var^)
  END Go;

BEGIN
  NEW(var)
END DerefGlobalToVarParam.

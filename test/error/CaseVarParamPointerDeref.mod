MODULE CaseVarParamPointerDeref;

 TYPE R = RECORD END;
 P = POINTER TO R;
 Re = RECORD(R) END;

 PROCEDURE Case(VAR p: P);
 BEGIN
  CASE p^ OF
  Re: ;
  END
 END Case;

 PROCEDURE Go*;
 VAR p: P;
 BEGIN
  NEW(p);
  Case(p)
 END Go;

END CaseVarParamPointerDeref.

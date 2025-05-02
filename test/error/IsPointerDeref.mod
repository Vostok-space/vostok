MODULE IsPointerDeref;

 TYPE R = RECORD END;
 P = POINTER TO R;
 Re = RECORD(R) i: INTEGER END;

 PROCEDURE Is(VAR p: P);
 VAR b: BOOLEAN;
 BEGIN
  b := p^ IS Re
 END Case;

 PROCEDURE Go*;
 VAR p: P;
 BEGIN
  NEW(p);
  Case(p)
 END Go;

END IsPointerDeref.

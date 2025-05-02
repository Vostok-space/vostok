MODULE GuardPointerDeref;

 TYPE R = RECORD END;
 P = POINTER TO R;
 Re = RECORD(R) i: INTEGER END;

 PROCEDURE Guard(VAR p: P);
 BEGIN
  p^(Re).i := 1
 END Guard;

 PROCEDURE Go*;
 VAR p: P;
 BEGIN
  NEW(p);
  Guard(p)
 END Go;

END GuardPointerDeref.

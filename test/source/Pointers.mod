MODULE Pointers;

(*
 IMPORT Record;
*)

 TYPE
   R = RECORD END;
   P1 = POINTER TO R;
   P2 = POINTER TO R;

   R2 = RECORD(R) END;

(*
   Pi = POINTER TO INTEGER;

 VAR vp: POINTER TO Record.Record;
*)

 PROCEDURE Pr(): P1;
 VAR p: POINTER TO R2;
 BEGIN
   NEW(p);
 RETURN
    p
 END Pr;

 PROCEDURE Go*();
 VAR p1: P1;
     p2: P2;
     p3: POINTER TO R;
 BEGIN
   p1 := NIL;

   p2 := p1;
   p3 := p2;
   p3 := p1;
   p1 := p3;
   p1 := p2;
   p2 := p3;

   ASSERT(Pr() # NIL)
 END Go;

END Pointers.

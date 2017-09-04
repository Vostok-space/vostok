MODULE Pointers;

(*
 IMPORT Record;
*)

 TYPE
   R = RECORD END;
   P1 = POINTER TO R;
   P2 = POINTER TO R;

(*
   Pi = POINTER TO INTEGER;

 VAR vp: POINTER TO Record.Record;
*)


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
   p2 := p3
 END Go;

END Pointers.

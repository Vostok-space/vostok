(* Example of almost weak link, useful with links counter *)
MODULE WeakLink;

 TYPE
   Storage = POINTER TO RECORD
     a: ARRAY 37 OF POINTER TO Item
   END;

   WeakLink = POINTER TO RECORD
     s: Storage
   END;

   Item = RECORD
     s: WeakLink;
     i: INTEGER
   END;

 PROCEDURE Go*;
 VAR i: INTEGER;
     s: Storage;
     w: WeakLink;
 BEGIN
   NEW(s);
   NEW(w);
   w.s := s;
   FOR i := 0 TO LEN(s.a) - 1 DO
     NEW(s.a[i]);
     s.a[i].s := w;
     s.a[i].i := i
   END;

   (* One extra explicit NIL to destroy loop of links. Disappointed? *)
   w.s := NIL
 END Go;

END WeakLink.

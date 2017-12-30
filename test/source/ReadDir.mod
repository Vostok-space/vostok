MODULE ReadDir;

 IMPORT Out, PD := PosixDir;

 PROCEDURE Dir*(name: ARRAY OF CHAR);
 VAR d: PD.Dir;
     e: PD.Ent;
     l: INTEGER;
     n: ARRAY 256 OF CHAR;
 BEGIN
   IF ~PD.Open(d, name, 0) THEN
     Out.String("Can not open ");
     Out.String(name);
     Out.Ln
   ELSE
     WHILE PD.Read(e, d) DO
       l := 0;
       ASSERT(PD.CopyName(n, l, e));
       Out.String(n); Out.Ln;
     END;
     ASSERT(PD.Close(d))
   END
 END Dir;

 PROCEDURE Go*;
 BEGIN
   Dir(".")
 END Go;

END ReadDir.

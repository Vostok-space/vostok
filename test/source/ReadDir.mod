MODULE ReadDir;

 IMPORT Out, D := Dir;

 PROCEDURE Dir*(name: ARRAY OF CHAR);
 VAR d: D.Dir;
     e: D.File;
     l: INTEGER;
     n: ARRAY 256 OF CHAR;
 BEGIN
   IF ~D.Open(d, name, 0) THEN
     Out.String("Can not open ");
     Out.String(name);
     Out.Ln
   ELSE
     WHILE D.Read(e, d) DO
       l := 0;
       ASSERT(D.CopyName(n, l, e));
       Out.String(n); Out.Ln
     END;
     ASSERT(D.Close(d))
   END
 END Dir;

 PROCEDURE Go*;
 BEGIN
   Dir(".")
 END Go;

END ReadDir.

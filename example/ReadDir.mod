MODULE ReadDir;

 IMPORT Out, D := Dir, CLI;

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
 VAR dir: ARRAY 1024 OF CHAR;
     ofs: INTEGER;
 BEGIN
   ofs := 0;
   IF CLI.count <= 0 THEN
     Dir(".")
   ELSIF CLI.Get(dir, ofs, 0) THEN
     Dir(dir)
   ELSE
     Out.String("Too long name");
     Out.Ln
   END
 END Go;

END ReadDir.

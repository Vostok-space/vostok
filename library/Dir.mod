MODULE Dir;

 IMPORT Platform, Posix := PosixDir, Windows := WindowsDir;

 CONST
   NameLenMax* = 260;

 TYPE
   Dir* = RECORD
     p: Posix.Dir;
     w: Windows.FindId;
     f: Windows.FindData
   END;

   File* = RECORD
     p: Posix.Ent;
     w: Windows.FindData
   END;

 PROCEDURE Open*(VAR d: Dir; name: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
 VAR ok: BOOLEAN;
     spec: ARRAY 2 OF CHAR;
 BEGIN
   IF Platform.Posix THEN
     ok := Posix.Open(d.p, name, ofs)
   ELSIF Platform.Windows THEN
     spec := "*";
     ok := Windows.FindFirst(d.w, d.f, spec, 0)
   ELSE
     ok := FALSE
   END
   RETURN ok
 END Open;

 PROCEDURE Close*(VAR d: Dir): BOOLEAN;
 VAR ok: BOOLEAN;
 BEGIN
   IF Platform.Posix THEN
     ok := Posix.Close(d.p)
   ELSIF Platform.Windows THEN
     ok := Windows.Close(d.w)
   ELSE
     ok := FALSE
   END
   RETURN ok
 END Close;

 PROCEDURE Read*(VAR e: File; VAR d: Dir): BOOLEAN;
 VAR ok: BOOLEAN;
 BEGIN
   IF Platform.Posix THEN
     ok := Posix.Read(e.p, d.p)
   ELSIF Platform.Windows THEN
     IF d.f # NIL THEN
       e.w := d.f;
       d.f := NIL;
       ok := TRUE
     ELSE
       ok := Windows.FindNext(e.w, d.w)
     END
   ELSE
     ok := FALSE
   END
   RETURN ok
 END Read;

 PROCEDURE CopyName*(VAR buf: ARRAY OF CHAR; VAR ofs: INTEGER; f: File): BOOLEAN;
 VAR ok: BOOLEAN;
 BEGIN
   IF Platform.Posix THEN
     ok := Posix.CopyName(buf, ofs, f.p)
   ELSIF Platform.Windows THEN
     ok := Windows.CopyName(buf, ofs, f.w)
   ELSE
     ok := FALSE
   END
   RETURN ok
 END CopyName;

END Dir.

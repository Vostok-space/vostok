MODULE Dir;

 IMPORT Platform, Posix := PosixDir, Windows := WindowsDir;

 TYPE
   Dir* = RECORD
     p: Posix.Dir
   END;

   File* = RECORD
     p: Posix.Ent
   END;

 PROCEDURE Open*(VAR d: Dir; name: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
 VAR ok: BOOLEAN;
 BEGIN
   IF Platform.Posix THEN
     ok := Posix.Open(d.p, name, ofs)
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
   ELSE
     ok := FALSE
   END
   RETURN ok
 END CopyName;

END Dir.

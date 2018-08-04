MODULE JavaExecInterface;

  IMPORT V, Exec := PlatformExec;

  PROCEDURE Init*(VAR e: Exec.Code);
  BEGIN
    ASSERT(Exec.Init(e, "java"))
  END Init;

  PROCEDURE AddClassPath*(VAR e: Exec.Code;
                          path: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
  RETURN
    Exec.Add(e, "-cp", 0)
  & Exec.Add(e, path, ofs)
  END AddClassPath;

  PROCEDURE AddJar*(VAR e: Exec.Code; jar: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
  RETURN
    Exec.Add(e, "-jar", 0)
  & Exec.Add(e, jar, ofs)
  END AddJar;

END JavaExecInterface.

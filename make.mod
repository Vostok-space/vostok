MODULE make;

 IMPORT Log, Exec := PlatformExec, Dir, Platform;

 VAR ok*, windows, posix: BOOLEAN;

 PROCEDURE CopyFileName*(VAR n: ARRAY OF CHAR; nwe: ARRAY OF CHAR): BOOLEAN;
 VAR i: INTEGER;
 BEGIN
    i := 0;
    WHILE (i < LEN(n) - 1) & (i < LEN(nwe)) & (nwe[i] # ".") DO
      n[i] := nwe[i];
      INC(i)
    END;
    n[i] := 0X
    RETURN nwe[i] = "."
 END CopyFileName;

 PROCEDURE Execute(code: Exec.Code; name: ARRAY OF CHAR): INTEGER;
 VAR ret: INTEGER;
 BEGIN
   Exec.Log(code);
   ret := Exec.Do(code);
   IF ret # 0 THEN
     Log.Str("Failed "); Log.StrLn(name);
     Log.Str("error code = "); Log.Int(ret); Log.Ln
   END
   RETURN ret
 END Execute;

 PROCEDURE BuildBy(o7c, res, tmp: ARRAY OF CHAR): BOOLEAN;
 VAR code: Exec.Code;
 BEGIN
   IF posix THEN
     ok := Exec.Init(code, "rm") & Exec.Add(code, "-rf", 0);
   ELSE ASSERT(windows);
     Exec.AutoCorrectDirSeparator(FALSE);
     ok := Exec.Init(code, "rmdir") & Exec.Add(code, "/s/q", 0);
     Exec.AutoCorrectDirSeparator(TRUE)
   END;
   ok := ok & Exec.FirstPart(code, "result/") & Exec.LastPart(code, tmp)
       & (0 = Execute(code, "Delete old temp directory"));
   IF Exec.Init(code, "") & Exec.FirstPart(code, "result/") & Exec.LastPart(code, o7c)
    & Exec.AddClean(code, " to-bin Translator.Start result/") & Exec.AddClean(code, res)
    & (~windows OR Exec.AddClean(code, ".exe"))

    & ((tmp[1] = "0")
     & Exec.AddClean(code, " -i singularity/definition -c singularity/bootstrap/singularity")
     & Exec.AddClean(code, " -m source -m library -t result/") & Exec.AddClean(code, tmp)
    OR (tmp[1] # "0") & Exec.AddClean(code, " -infr . -m source")
      )

    & (~windows OR Exec.Add(code, "-cc tcc", 0))
   THEN
     ok := 0 = Execute(code, "Build")
   END
   RETURN ok
 END BuildBy;

 PROCEDURE Build*;
 BEGIN
   ok := BuildBy("bs-o7c", "o7c", "v0")
 END Build;

 PROCEDURE TestBy(o7c: ARRAY OF CHAR): BOOLEAN;
 VAR code: Exec.Code;
     dir: Dir.Dir;
     file: Dir.File;
     n, c: ARRAY 64 OF CHAR;
     l, j: INTEGER;
 BEGIN
   IF Dir.Open(dir, "test/source", 0) THEN
     ok := TRUE;
     WHILE Dir.Read(file, dir) DO
       l := 0;
       j := 0;
       IF Dir.CopyName(n, l, file) & (n[0] # ".")
        & Exec.Init(code, "")
        & Exec.FirstPart(code, "result/") & Exec.LastPart(code, o7c)
        & Exec.Add(code, "run", 0)
        & CopyFileName(c, n)
        & Exec.FirstPart(code, c) & Exec.LastPart(code, ".Go")
        & Exec.AddClean(code, " -infr . -m test/source ")
        & (~windows OR Exec.AddClean(code, "-cc tcc"))
       THEN
         ok := (Execute(code, n) = 0) & ok
       END
     END;
     ASSERT(Dir.Close(dir))
   END
   RETURN ok
 END TestBy;

 PROCEDURE Test*;
 BEGIN
   ok := TestBy("o7c")
 END Test;

 PROCEDURE Self*;
 BEGIN
   ok := BuildBy("o7c", "o7c-v1", "v1") & TestBy("o7c-v1")
 END Self;

 PROCEDURE SelfFull*;
 BEGIN
   ok := BuildBy("o7c-v1", "o7c-v2", "v2") & TestBy("o7c-v2")
 END SelfFull;

 PROCEDURE Help*;
 BEGIN
   Log.StrLn("Commands:");
   Log.StrLn("  Build   - build o7c translator by bootstrap");
   Log.StrLn("  Test    - build and run tests from test/source");
   Log.StrLn("  Self    - build itself then run tests");
   Log.StrLn("  SelfFull- build translator by 2nd generation translator then tests")
 END Help;

BEGIN
  Log.On;
  Exec.AutoCorrectDirSeparator(TRUE);

  windows := Platform.Windows;
  posix   := Platform.Posix
END make.

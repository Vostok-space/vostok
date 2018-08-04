(*  Build and test tasks for the translator
 *  Copyright (C) 2018 ComdivByZero
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published
 *  by the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)
MODULE make;

 IMPORT Log, Exec := PlatformExec, Dir, Platform;

 VAR ok*, windows, posix, java: BOOLEAN;

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
     ok := Exec.Init(code, "rmdir") & Exec.AddClean(code, " /s/q");
   END;
   ok := ok & Exec.FirstPart(code, "result/") & Exec.LastPart(code, tmp)
       & (0 = Execute(code, "Delete old temp directory"));
   ok :=
      Exec.Init(code, "") & Exec.FirstPart(code, "result/") & Exec.LastPart(code, o7c)
    & Exec.Add(code, "to-bin", 0) & Exec.Add(code, "Translator.Start", 0)
    & Exec.FirstPart(code, "result/") & Exec.AddPart(code, res)
    & (windows & Exec.LastPart(code, ".exe")
    OR posix & Exec.LastPart(code, "")
      )
    & ((tmp[1] = "0")
     & Exec.Add(code, "-i", 0) & Exec.Add(code, "singularity/definition", 0)
     & Exec.Add(code, "-c", 0) & Exec.Add(code, "singularity/bootstrap/singularity", 0)
     & Exec.AddClean(code, " -m source -m library -t")
    OR (tmp[1] # "0") & Exec.AddClean(code, " -infr . -m source -t")
      )
    & Exec.FirstPart(code, "result/") & Exec.LastPart(code, tmp)

    & (0 = Execute(code, "Build"))
   RETURN ok
 END BuildBy;

 PROCEDURE Build*;
 BEGIN
   ok := BuildBy("bs-o7c", "o7c", "v0")
 END Build;

 PROCEDURE AddRun(VAR code: Exec.Code): BOOLEAN;
 VAR ret: BOOLEAN;
 BEGIN
   IF java THEN
     ret := Exec.Add(code, "run-java", 0)
   ELSE
     ret := Exec.Add(code, "run", 0)
   END
   RETURN ret
 END AddRun;

 PROCEDURE TestBy(srcDir: ARRAY OF CHAR; example: BOOLEAN; o7c: ARRAY OF CHAR): BOOLEAN;
 VAR code: Exec.Code;
     dir: Dir.Dir;
     file: Dir.File;
     n, c: ARRAY 64 OF CHAR;
     l, j: INTEGER;
     pass, fail: INTEGER;
 BEGIN
   IF Dir.Open(dir, srcDir, 0) THEN
     pass := 0;
     fail := 0;
     WHILE Dir.Read(file, dir) DO
       l := 0;
       j := 0;
       IF Dir.CopyName(n, l, file) & (n[0] # ".")
        & Exec.Init(code, "")
        & Exec.FirstPart(code, "result/") & Exec.LastPart(code, o7c)
        & AddRun(code)
        & CopyFileName(c, n)
        & ( example & Exec.Add(code, c, 0)
         OR ~example & Exec.FirstPart(code, c) & Exec.LastPart(code, ".Go")
          )
        & Exec.Add(code, "-infr", 0) & Exec.Add(code, ".", 0)
        & Exec.Add(code, "-m", 0) & Exec.Add(code, "example", 0)
        & Exec.Add(code, "-m", 0) & Exec.Add(code, "test/source", 0)
        & Exec.Add(code, "-cyrillic", 0)
       THEN
         IF Execute(code, n) = 0 THEN
           INC(pass)
         ELSE
           INC(fail)
         END
       END
     END;
     ok := fail = 0;
     Log.Ln;
     Log.Str("Passed: "); Log.Int(pass); Log.Ln;
     Log.Str("Failed: "); Log.Int(fail); Log.Ln;
     ASSERT(Dir.Close(dir))
   END
   RETURN ok
 END TestBy;

 PROCEDURE Test*;
 BEGIN
   ok := TestBy("test/source", FALSE, "o7c")
 END Test;

 PROCEDURE Self*;
 BEGIN
   ok := BuildBy("o7c", "o7c-v1", "v1") & TestBy("test/source", FALSE, "o7c-v1")
 END Self;

 PROCEDURE SelfFull*;
 BEGIN
   ok := BuildBy("o7c-v1", "o7c-v2", "v2") & TestBy("test/source", FALSE, "o7c-v2")
 END SelfFull;

 PROCEDURE Example*;
 BEGIN
   ok := TestBy("example", TRUE, "o7c")
 END Example;

 PROCEDURE Help*;
 BEGIN
   Log.StrLn("Commands:");
   Log.StrLn("  Build   - build o7c translator by bootstrap");
   Log.StrLn("  Test    - build and run tests from test/source");
   Log.StrLn("  Example - build examples");
   Log.StrLn("  Self    - build itself then run tests");
   Log.StrLn("  SelfFull- build translator by 2nd generation translator then tests");
   Log.StrLn("  UseJava - turn translation throgh Java");
   Log.StrLn("  UseC    - turn translation throgh C")
 END Help;

 PROCEDURE UseJava*;
 BEGIN
   java := TRUE
 END UseJava;

 PROCEDURE UseC*;
 BEGIN
   java := FALSE
 END UseC;

BEGIN
  Log.On;
  Exec.AutoCorrectDirSeparator(TRUE);

  windows := Platform.Windows;
  posix   := Platform.Posix;

  java := FALSE
END make.

(*  Build and test tasks for the translator
 *  Copyright (C) 2018-2019 ComdivByZero
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

 CONST C = 0; Java = 1; Js = 2;

 VAR ok*, windows, posix: BOOLEAN;
     lang: INTEGER;
     cc: ARRAY 256 OF CHAR;

 PROCEDURE CopyFileName*(VAR n: ARRAY OF CHAR; nwe: ARRAY OF CHAR): BOOLEAN;
 VAR i: INTEGER;
 BEGIN
   i := 0;
   WHILE (i < LEN(n) - 1) & (i < LEN(nwe)) & (nwe[i] # ".") DO
     n[i] := nwe[i];
     INC(i)
   END;
   n[i] := 0X
 RETURN
   nwe[i] = "."
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
 RETURN
   ret
 END Execute;

 PROCEDURE BuildBy(o7c, res, tmp, cmd: ARRAY OF CHAR): BOOLEAN;
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
    & Exec.Add(code, cmd, 0) & Exec.Add(code, "Translator.Start", 0)
    & Exec.FirstPart(code, "result/") & Exec.AddPart(code, res)
    & ((lang = Js) & Exec.LastPart(code, ".js")
    OR windows & Exec.LastPart(code, ".exe")
    OR posix & Exec.LastPart(code, "")
      )
    & ((tmp[1] = "0")
     & Exec.Add(code, "-i", 0) & Exec.Add(code, "singularity/definition", 0)
     & Exec.Add(code, "-c", 0) & Exec.Add(code, "singularity/bootstrap/singularity", 0)
     & Exec.AddClean(code, " -m source -m library -t")
    OR (tmp[1] # "0") & Exec.AddClean(code, " -infr . -m source -t")
      )
    & Exec.FirstPart(code, "result/") & Exec.LastPart(code, tmp)

    & ((cc[0] = 0X) OR Exec.Add(code, "-cc", 0) & Exec.Add(code, cc, 0))

    & (0 = Execute(code, "Build"))
 RETURN
   ok
 END BuildBy;

 PROCEDURE Build*;
 BEGIN
   ok := BuildBy("bs-o7c", "o7c", "v0", "to-bin")
 END Build;

 PROCEDURE AddRun(VAR code: Exec.Code; class: BOOLEAN): BOOLEAN;
 VAR ret: BOOLEAN;
 BEGIN
   ret := ~class OR Exec.Add(code, "o7.Translator", 0);
   IF ret THEN
     CASE lang OF
       C   : ret := Exec.Add(code, "run", 0)
     | Java: ret := Exec.Add(code, "run-java", 0)
     | Js  : ret := Exec.Add(code, "run-js", 0)
     END
   END
 RETURN
   ret
 END AddRun;

 PROCEDURE TestBy(srcDir: ARRAY OF CHAR; example: BOOLEAN; o7c: ARRAY OF CHAR;
                  runLang: INTEGER): BOOLEAN;
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
       ASSERT(Dir.CopyName(n, l, file));
       IF n[0] # "." THEN
         ASSERT(
            (   (runLang = Java) & Exec.Init(code, "java") & Exec.Add(code, "-cp", 0)
             OR (runLang = Js) & Exec.Init(code, "node")
             OR (runLang = C) & Exec.Init(code, "")
            )
           & Exec.FirstPart(code, "result/") & Exec.LastPart(code, o7c)
           & AddRun(code, runLang = Java)
         );
         IF CopyFileName(c, n) THEN
           ASSERT(
             ( example & Exec.Add(code, c, 0)
            OR ~example & Exec.FirstPart(code, c) & Exec.LastPart(code, ".Go")
             )
             & Exec.Add(code, "-infr", 0) & Exec.Add(code, ".", 0)
             & Exec.Add(code, "-m", 0) & Exec.Add(code, "example", 0)
             & Exec.Add(code, "-m", 0) & Exec.Add(code, "test/source", 0)
             & Exec.Add(code, "-cyrillic", 0)
             & ((cc[0] = 0X) OR Exec.Add(code, "-cc", 0) & Exec.Add(code, cc, 0))
           );
           IF Execute(code, n) = 0 THEN
             INC(pass)
           ELSE
             INC(fail)
           END
         END
       END
     END;
     ok := fail = 0;
     Log.Ln;
     Log.Str("Passed: "); Log.Int(pass); Log.Ln;
     Log.Str("Failed: "); Log.Int(fail); Log.Ln;
     ASSERT(Dir.Close(dir))
   END
 RETURN
   ok
 END TestBy;

 PROCEDURE Test*;
 BEGIN
   ok := TestBy("test/source", FALSE, "o7c", C)
 END Test;

 PROCEDURE Self*;
 BEGIN
   CASE lang OF
     C:
     ok := BuildBy("o7c", "o7c-v1", "v1", "to-bin")
         & TestBy("test/source", FALSE, "o7c-v1", lang)
   | Java:
     ok := BuildBy("o7c", "o7c-v1-java", "o7c-v1-java", "to-class")
         & TestBy("test/source", FALSE, "o7c-v1-java", lang)
   | Js:
     ok := BuildBy("o7c", "o7c-v1-js", "o7c-v1-js", "to-js")
         & TestBy("test/source", FALSE, "o7c-v1-js", lang)
   END
 END Self;

 PROCEDURE SelfFull*;
 BEGIN
   ok := BuildBy("o7c-v1", "o7c-v2", "v2", "to-bin")
       & TestBy("test/source", FALSE, "o7c-v2", C)
 END SelfFull;

 PROCEDURE Example*;
 BEGIN
   ok := TestBy("example", TRUE, "o7c", C)
 END Example;

 PROCEDURE Help*;
 BEGIN
   Log.StrLn("Commands:");
   Log.StrLn("  Build     - build from source o7c translator by bootstrap");
   Log.StrLn("  Test      - build and run tests from test/source");
   Log.StrLn("  Example   - build examples");
   Log.StrLn("  Self      - build itself then run tests");
   Log.StrLn("  SelfFull  - build translator by 2nd generation translator then tests");
   Log.StrLn("  UseJava   - turn translation through Java");
   Log.StrLn("  UseC      - turn translation through C");
   Log.StrLn("  UseCC(cc) - set C compiler from string and turn translation through C");

   Log.Ln; Log.StrLn("Examples:");
   Log.StrLn("  result/bs-o7c run 'make.Build; make.Test; make.Self' -infr . -m source");
   Log.StrLn("  result/o7c run 'make.UseJava; make.Test' -infr . -m source")
 END Help;

 PROCEDURE UseC*;
 BEGIN
   lang := C
 END UseC;

 PROCEDURE UseJava*;
 BEGIN
   lang := Java
 END UseJava;

 PROCEDURE UseJs*;
 BEGIN
   lang := Js
 END UseJs;

 PROCEDURE UseCC*(cli: ARRAY OF CHAR);
 BEGIN
   cc   := cli;
   lang := C
 END UseCC;

BEGIN
  Log.On;
  Exec.AutoCorrectDirSeparator(TRUE);

  windows := Platform.Windows;
  posix   := Platform.Posix;

  lang := C;

  cc[0] := 0X
END make.

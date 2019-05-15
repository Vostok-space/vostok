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

 IMPORT Log, Exec := PlatformExec, Dir, Platform, FS := FileSystemUtil, Chars0X;

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

 PROCEDURE Msg(str: ARRAY OF CHAR);
 BEGIN
   Log.StrLn(str)
 END Msg;

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

 PROCEDURE BuildBy(ost, res, tmp, cmd: ARRAY OF CHAR): BOOLEAN;
 VAR code: Exec.Code;
 BEGIN
   IF posix THEN
     ok := Exec.Init(code, "rm") & Exec.Add(code, "-rf");
   ELSE ASSERT(windows);
     ok := Exec.Init(code, "rmdir") & Exec.AddClean(code, " /s/q");
   END;
   ok := ok & Exec.FirstPart(code, "result/") & Exec.LastPart(code, tmp)
       & (0 = Execute(code, "Delete old temp directory"));
   ok :=
      Exec.Init(code, "") & Exec.FirstPart(code, "result/") & Exec.LastPart(code, ost)
    & Exec.Add(code, cmd) & Exec.Add(code, "Translator.Start")
    & Exec.FirstPart(code, "result/") & Exec.AddPart(code, res)
    & ((lang = Js) & Exec.LastPart(code, ".js")
    OR windows & Exec.LastPart(code, ".exe")
    OR posix & Exec.LastPart(code, "")
      )
    & ((tmp[1] = "0")
     & Exec.Add(code, "-i") & Exec.Add(code, "singularity/definition")
     & Exec.Add(code, "-c") & Exec.Add(code, "singularity/bootstrap/singularity")
     & Exec.AddClean(code, " -m source -m library -t")
    OR (tmp[1] # "0") & Exec.AddClean(code, " -infr . -m source -t")
      )
    & Exec.FirstPart(code, "result/") & Exec.LastPart(code, tmp)

    & ((cc[0] = 0X) OR Exec.Add(code, "-cc") & Exec.Add(code, cc))

    & (0 = Execute(code, "Build"))
 RETURN
   ok
 END BuildBy;

 PROCEDURE Build*;
 BEGIN
   ok := BuildBy("bs-ost", "ost", "v0", "to-bin")
 END Build;

 PROCEDURE AddRun(VAR code: Exec.Code; class: BOOLEAN): BOOLEAN;
 VAR ret: BOOLEAN;
 BEGIN
   ret := ~class OR Exec.Add(code, "o7.Translator");
   IF ret THEN
     CASE lang OF
       C   : ret := Exec.Add(code, "run")
     | Java: ret := Exec.Add(code, "run-java")
     | Js  : ret := Exec.Add(code, "run-js")
     END
   END
 RETURN
   ret
 END AddRun;

 PROCEDURE TestBy(srcDir: ARRAY OF CHAR; example: BOOLEAN; ost: ARRAY OF CHAR;
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
            (   (runLang = Java) & Exec.Init(code, "java") & Exec.Add(code, "-cp")
             OR (runLang = Js) & Exec.Init(code, "node")
             OR (runLang = C) & Exec.Init(code, "")
            )
           & Exec.FirstPart(code, "result/") & Exec.LastPart(code, ost)
           & AddRun(code, runLang = Java)
         );
         IF CopyFileName(c, n) THEN
           ASSERT(
             ( example & Exec.Add(code, c)
            OR ~example & Exec.FirstPart(code, c) & Exec.LastPart(code, ".Go")
             )
             & Exec.Add(code, "-infr") & Exec.Add(code, ".")
             & Exec.Add(code, "-m") & Exec.Add(code, "example")
             & Exec.Add(code, "-m") & Exec.Add(code, "test/source")
             & Exec.Add(code, "-cyrillic")
             & ((cc[0] = 0X) OR Exec.Add(code, "-cc") & Exec.Add(code, cc))
           );
           IF Execute(code, n) = 0 THEN
             INC(pass)
           ELSE
             INC(fail)
           END
         END
       END
     END;
     ok := fail <= pass DIV 8;
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
   ok := ok & TestBy("test/source", FALSE, "ost", C)
 END Test;

 PROCEDURE Self*;
 BEGIN
   IF ok THEN
      CASE lang OF
        C:
        ok := BuildBy("ost", "ost-v1", "v1", "to-bin")
            & TestBy("test/source", FALSE, "ost-v1", lang)
      | Java:
        ok := BuildBy("ost", "ost-v1-java", "ost-v1-java", "to-class")
            & TestBy("test/source", FALSE, "ost-v1-java", lang)
      | Js:
        ok := BuildBy("ost", "ost-v1-js", "ost-v1-js", "to-js")
            & TestBy("test/source", FALSE, "ost-v1-js", lang)
      END
   END
 END Self;

 PROCEDURE SelfFull*;
 BEGIN
   ok := ok
       & BuildBy("ost-v1", "ost-v2", "v2", "to-bin")
       & TestBy("test/source", FALSE, "ost-v2", C)
 END SelfFull;

 PROCEDURE Example*;
 BEGIN
   ok := ok & TestBy("example", TRUE, "ost", C)
 END Example;

 PROCEDURE Concat*(VAR dest: ARRAY OF CHAR; a, b: ARRAY OF CHAR): BOOLEAN;
 VAR i, j, k: INTEGER;
 BEGIN
   i := 0; j := 0; k := 0;
 RETURN
   Chars0X.Copy(a, j, TRUE, LEN(a), dest, i)
 & Chars0X.Copy(b, k, TRUE, LEN(b), dest, i)
 END Concat;

 PROCEDURE InstallTo*(dest: ARRAY OF CHAR);

   PROCEDURE Copy(src: ARRAY OF CHAR; dir: BOOLEAN;
                  baseDest, addDest: ARRAY OF CHAR): BOOLEAN;
   VAR dest: ARRAY 1024 OF CHAR;
   RETURN
     Concat(dest, baseDest, addDest)
   & FS.Copy(src, dest, dir)
   END Copy;

   PROCEDURE MakeDir(base, add: ARRAY OF CHAR): BOOLEAN;
   VAR dest: ARRAY 1024 OF CHAR;
   RETURN
     Concat(dest, base, add)
   & FS.MakeDir(dest)
   END MakeDir;

 BEGIN
   ok := Copy("result/ost", FALSE, dest, "/bin/")
       & MakeDir(dest, "/share/vostok")
       & Copy("library", TRUE, dest, "/share/vostok/")
       & Copy("singularity", TRUE, dest, "/share/vostok/");
   IF ~ok THEN
     Msg("Installation is failed")
   END
 END InstallTo;

 PROCEDURE Install*;
 BEGIN
   InstallTo("/usr/local")
 END Install;

 PROCEDURE RemoveFrom*(base: ARRAY OF CHAR);
 VAR dest: ARRAY 1024 OF CHAR;
 BEGIN
   ok := Concat(dest, base, "/share/vostok")
       & FS.RemoveDir(dest)
       & Concat(dest, base, "/bin/ost")
       & FS.RemoveFile(dest);
   IF ~ok THEN
     Msg("Uninstallation is failed");
   END
 END RemoveFrom;

 PROCEDURE Remove*;
 BEGIN
   RemoveFrom("/usr/local")
 END Remove;

 PROCEDURE Help*;
 BEGIN
   Msg("Commands:");
   Msg("  Build         build from source ost translator by bootstrap");
   Msg("  Test          build and run tests from test/source");
   Msg("  Example       build examples");
   Msg("  Self          build itself then run tests");
   Msg("  SelfFull      build translator by 2nd generation translator then tests");
   Msg("  UseJava       turn translation through Java");
   Msg("  UseJs         turn translation through Javascript");
   Msg("  UseC          turn translation through C");
   Msg("  UseCC(cc)     set C compiler from string and turn translation through C");
   Msg("  Install       install files to /usr/local");
   Msg("  InstallTo(d)  install files to target directory");
   Msg("  Remove        remove installed files from /usr/local");
   Msg("  RemoveFrom(d) remove files from target directory");

   Msg(""); Msg("Examples:");
   Msg("  result/bs-ost run 'make.Build; make.Test; make.Self' -infr . -m source");
   Msg("  result/ost run 'make.UseJava; make.Test' -infr . -m source")
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

  cc[0] := 0X;
  ok := TRUE
END make.

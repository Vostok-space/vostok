#!/usr/bin/ost .
(*  Build and test tasks for the translator
 *  Copyright (C) 2018-2020 ComdivByZero
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

 IMPORT Log, Exec := PlatformExec, Dir, CDir, CFiles, Platform, FS := FileSystemUtil, Chars0X, Env := OsEnv;

 CONST
   C = 0; Java = 1; Js = 2;

   BinVer = "0.0.3.dev";
   LibVer = "0.0.2.dev";

 VAR ok*, windows, posix: BOOLEAN;
     lang: INTEGER;
     cc, opt: ARRAY 256 OF CHAR;

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

 PROCEDURE AddOpts(VAR code: Exec.Code): BOOLEAN;
 RETURN
   ((cc [0] = 0X) OR Exec.Add(code, "-cc") & Exec.Add(code, cc))
 & ((opt[0] = 0X) OR Exec.AddClean(code, " ") & Exec.AddClean(code, opt))
 END AddOpts;

 PROCEDURE BuildBy(ost, script, res, tmp, cmd: ARRAY OF CHAR): BOOLEAN;
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
    & Exec.Add(code, cmd) & Exec.Add(code, script)
    & Exec.FirstPart(code, "result/") & Exec.AddPart(code, res)
    & ((lang = Js) & Exec.LastPart(code, ".js")
    OR windows & Exec.LastPart(code, ".exe")
    OR posix & Exec.LastPart(code, "")
      )
    & ((script # "AndroidBuild.Go") OR Exec.AddClean(code, " -m source/blankC -m source/blankJs"))
    & ((tmp[1] = "0")
     & Exec.Add(code, "-i") & Exec.Add(code, "singularity/definition")
     & Exec.Add(code, "-c") & Exec.Add(code, "bootstrap/singularity")
     & Exec.AddClean(code, " -m source -m library -t")
    OR (tmp[1] # "0") & Exec.AddClean(code, " -infr . -m source -t")
      )
    & Exec.FirstPart(code, "result/") & Exec.LastPart(code, tmp)

    & AddOpts(code)

    & (0 = Execute(code, "Build"))
 RETURN
   ok
 END BuildBy;

 PROCEDURE Build*;
 BEGIN
   ok := ok & BuildBy("bs-ost", "Translator.Go", "ost", "v0", "to-bin")
 END Build;

 PROCEDURE BuildAndroid*;
 BEGIN
   ok := ok & BuildBy("ost", "AndroidBuild.Go", "osa", "va", "to-bin")
 END BuildAndroid;

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
             & AddOpts(code)
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
        ok := BuildBy("ost", "Translator.Go", "ost-v1", "v1", "to-bin")
            & TestBy("test/source", FALSE, "ost-v1", lang)
      | Java:
        ok := BuildBy("ost", "Translator.Go", "ost-v1-java", "ost-v1-java", "to-class")
            & TestBy("test/source", FALSE, "ost-v1-java", lang)
      | Js:
        ok := BuildBy("ost", "Translator.Go", "ost-v1-js", "ost-v1-js", "to-js")
            & TestBy("test/source", FALSE, "ost-v1-js", lang)
      END
   END
 END Self;

 PROCEDURE SelfFull*;
 BEGIN
   ok := ok
       & BuildBy("ost-v1", "Translator.Go", "ost-v2", "v2", "to-bin")
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
   Chars0X.Copy(dest, i, a, j)
 & Chars0X.Copy(dest, i, b, k)
 END Concat;

 PROCEDURE Copy(src: ARRAY OF CHAR; dir: BOOLEAN;
                baseDest, addDest: ARRAY OF CHAR): BOOLEAN;
 VAR dest: ARRAY 1024 OF CHAR;
 RETURN
   Concat(dest, baseDest, addDest)
 & FS.Copy(src, dest, dir)
 END Copy;

 PROCEDURE CopyBinTo(dest: ARRAY OF CHAR): BOOLEAN;
 RETURN
   Copy("result/ost", FALSE, dest, "/bin/")
 END CopyBinTo;

 PROCEDURE CopyAndroidTo(dest: ARRAY OF CHAR): BOOLEAN;
 RETURN
   Copy("result/osa", FALSE, dest, "/bin/")
 END CopyAndroidTo;

 PROCEDURE InstallBinTo*(dest: ARRAY OF CHAR);
 BEGIN
   ok := Copy("result/ost", FALSE, dest, "/bin/");
   IF ~ok THEN
     Msg("Failed to install the binary")
   END
 END InstallBinTo;

 PROCEDURE MakeDir(base, add: ARRAY OF CHAR): BOOLEAN;
 VAR dest: ARRAY 1024 OF CHAR;
 RETURN
   Concat(dest, base, add)
 & FS.MakeDir(dest)
 END MakeDir;

 PROCEDURE CopyLibTo(dest: ARRAY OF CHAR): BOOLEAN;
 RETURN
   MakeDir(dest, "/share/vostok")
 & Copy("library", TRUE, dest, "/share/vostok/")
 & Copy("singularity", TRUE, dest, "/share/vostok/")
 END CopyLibTo;

 PROCEDURE InstallLibTo*(dest: ARRAY OF CHAR);
 BEGIN
   ok := CopyLibTo(dest);
   IF ~ok THEN
     Msg("Failed to install the library")
   END
 END InstallLibTo;

 PROCEDURE InstallTo*(dest: ARRAY OF CHAR);
 BEGIN
   ok := CopyBinTo(dest) & CopyLibTo(dest);
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
     Msg("Uninstallation is failed")
   END
 END RemoveFrom;

 PROCEDURE Remove*;
 BEGIN
   RemoveFrom("/usr/local")
 END Remove;

 PROCEDURE Md5Deep(dir: ARRAY OF CHAR; out: ARRAY OF CHAR): BOOLEAN;
 VAR cmd: Exec.Code;
 RETURN
   Exec.Init(cmd, "md5deep")
 & Exec.Add(cmd, "-rl")
 & Exec.Add(cmd, dir)
 & Exec.AddClean(cmd, " > ")
 & Exec.Add(cmd, out)
 & (Exec.Do(cmd) = Exec.Ok)
 END Md5Deep;

 PROCEDURE DpkgDeb(dir: ARRAY OF CHAR): BOOLEAN;
 VAR cmd: Exec.Code;
 RETURN
   Exec.Init(cmd, "fakeroot")
 & Exec.Add(cmd, "dpkg-deb")
 & Exec.Add(cmd, "--build")
 & Exec.Add(cmd, dir)
 & (Exec.Do(cmd) = Exec.Ok)
 END DpkgDeb;

 PROCEDURE CreateDebDir(pname: ARRAY OF CHAR): BOOLEAN;
 VAR ignore: BOOLEAN; name: ARRAY 256 OF CHAR;
 BEGIN
   ASSERT(Concat(name, "result/", pname));
   ignore := FS.RemoveDir(name)
 RETURN
   FS.MakeDir(name)
 & MakeDir(name, "/DEBIAN")
 & MakeDir(name, "/usr")
 & MakeDir(name, "/usr/share")
 & MakeDir(name, "/usr/share/doc")
 & Concat(name, name, "/usr/share/doc/")
 & MakeDir(name, pname)
 END CreateDebDir;

 PROCEDURE HashAndPack(name: ARRAY OF CHAR): BOOLEAN;
 RETURN
   CDir.SetCurrent("result", 0)
 & CDir.SetCurrent(name, 0)
 & Md5Deep("usr", "DEBIAN/md5sums")
 & CDir.SetCurrent("..", 0)
 & DpkgDeb(name)
 & CDir.SetCurrent("..", 0)
 END HashAndPack;

 PROCEDURE Gzip(src, dest: ARRAY OF CHAR): BOOLEAN;
 VAR cmd: Exec.Code;
 RETURN
   Exec.Init(cmd, "gzip")
 & Exec.Add(cmd, "-9cn")
 & Exec.Add(cmd, src)
 & Exec.AddClean(cmd, " > ")
 & Exec.Add(cmd, dest)
 & (Exec.Do(cmd) = Exec.Ok)
 END Gzip;

 PROCEDURE TarBz2(src, dest: ARRAY OF CHAR): BOOLEAN;
 VAR cmd: Exec.Code;
 RETURN
   Exec.Init(cmd, "tar")
 & Exec.Add(cmd, "cvfj")
 & Exec.Add(cmd, dest)
 & Exec.Add(cmd, src)
 & (Exec.Do(cmd) = Exec.Ok)
 END TarBz2;

 PROCEDURE DebLib*;
 BEGIN
   IF ok THEN
      ok := CreateDebDir("vostok-deflib")
          & CopyLibTo("result/vostok-deflib/usr")
          & FS.CopyFile("package/DEBIAN/control-deflib", "result/vostok-deflib/DEBIAN/control")
          & Gzip("package/DEBIAN/changelog-deflib",
                 "result/vostok-deflib/usr/share/doc/vostok-deflib/changelog.gz")
          & FS.CopyFile("package/DEBIAN/copyright-deflib",
                      "result/vostok-deflib/usr/share/doc/vostok-deflib/copyright")
          & HashAndPack("vostok-deflib");
      IF ~ok THEN
        Msg("Failed to pack library to deb")
      END
   END
 END DebLib;

 PROCEDURE DebBin*;
 BEGIN
   IF ok THEN
      ok := CreateDebDir("vostok-bin")
          & FS.MakeDir("result/vostok-bin/usr/bin")
          & CopyBinTo("result/vostok-bin/usr")
          & FS.CopyFile("package/DEBIAN/control-bin", "result/vostok-bin/DEBIAN/control")
          & Gzip("package/DEBIAN/changelog-bin",
                 "result/vostok-bin/usr/share/doc/vostok-bin/changelog.gz")
          & FS.CopyFile("package/DEBIAN/copyright-bin",
                      "result/vostok-bin/usr/share/doc/vostok-bin/copyright")
          & HashAndPack("vostok-bin");
      IF ~ok THEN
        Msg("Failed to pack executable binary to deb")
      END
   END
 END DebBin;

 PROCEDURE DebAndroid*;
 BEGIN
   IF ok THEN
      ok := CreateDebDir("vostok-android")
          & FS.MakeDir("result/vostok-android/usr/bin")
          & CopyAndroidTo("result/vostok-android/usr")
          & FS.CopyFile("package/DEBIAN/control-android", "result/vostok-android/DEBIAN/control")
          & Gzip("package/DEBIAN/changelog-android",
                 "result/vostok-android/usr/share/doc/vostok-android/changelog.gz")
          & FS.CopyFile("package/DEBIAN/copyright-android",
                      "result/vostok-android/usr/share/doc/vostok-android/copyright")
          & HashAndPack("vostok-android");
      IF ~ok THEN
        Msg("Failed to pack android builder to deb")
      END
   END
 END DebAndroid;

 PROCEDURE Deb*;
 BEGIN
   DebLib;
   DebBin;
   DebAndroid
 END Deb;

 PROCEDURE RpmBuild(spec: ARRAY OF CHAR): BOOLEAN;
 VAR cmd: Exec.Code;
 RETURN
   Exec.Init(cmd, "rpmbuild")
 & Exec.Add(cmd, "-ba")
 & Exec.Add(cmd, spec)
 & (Exec.Do(cmd) = Exec.Ok)
 END RpmBuild;

 PROCEDURE GetRpmTarName(VAR tar: ARRAY OF CHAR; name: ARRAY OF CHAR): BOOLEAN;
 VAR ofs: INTEGER; corr: BOOLEAN;
 BEGIN
   ofs := 0;
   corr := Env.Get(tar, ofs, "HOME")
         & Chars0X.CopyString(tar, ofs, "/RPM");
   IF corr & ~CFiles.Exist(tar, 0) THEN
      ofs := 0;
      corr := Env.Get(tar, ofs, "HOME")
            & Chars0X.CopyString(tar, ofs, "/rpmbuild")
            & CFiles.Exist(tar, 0)
   END
 RETURN
   corr
 & Chars0X.CopyString(tar, ofs, "/SOURCES/")
 & Chars0X.CopyString(tar, ofs, name)
 & Chars0X.CopyString(tar, ofs, ".tar.bz2")
 END GetRpmTarName;

 PROCEDURE RpmLib*;
 CONST Prefix = "vostok-deflib-";
 VAR dir, tar: ARRAY 1024 OF CHAR;
 BEGIN
   IF ok THEN
     ok := Concat(dir, Prefix, LibVer)
         & MakeDir("result/", dir)
         & Copy("library", TRUE, "result/", dir)
         & Copy("singularity", TRUE, "result/", dir)
         & FS.ChangeDir("result")
         & GetRpmTarName(tar, dir)
         & TarBz2(dir, tar)
         & FS.RemoveDir(dir)
         & RpmBuild("../package/RPM/vostok-deflib.spec")
         & FS.ChangeDir("..");
     IF ~ok THEN
       Msg("Failed to pack library to rpm")
     END
   END
 END RpmLib;

 PROCEDURE RpmBin*;
 CONST Prefix = "vostok-bin-";
 VAR dir, tar: ARRAY 1024 OF CHAR;
 BEGIN
   IF ok THEN
     ok := Concat(dir, Prefix, BinVer)
         & MakeDir("result/", dir)
         & Copy("library", TRUE, "result/", dir)
         & Copy("singularity", TRUE, "result/", dir)
         & Copy("source", TRUE, "result/", dir)
         & Copy("bootstrap", TRUE, "result/", dir)
         & Copy("init.sh", TRUE, "result/", dir)
         & FS.ChangeDir("result")
         & GetRpmTarName(tar, dir)
         & TarBz2(dir, tar)
         & FS.RemoveDir(dir)
         & RpmBuild("../package/RPM/vostok-bin.spec")
         & FS.ChangeDir("..");
     IF ~ok THEN
       Msg("Failed to pack executable binary to rpm")
     END
   END
 END RpmBin;

 PROCEDURE Rpm*;
 BEGIN
   RpmLib;
   RpmBin
 END Rpm;

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
   Msg("  Opt(content)  string with additional options for the ost-translator");
   Msg("  Install       install translator and libraries to /usr/local");
   Msg("  InstallTo(d)  install translator and libraries files to target directory");
   Msg("  Remove        remove installed files from /usr/local");
   Msg("  RemoveFrom(d) remove files from target directory");
   Msg("  Deb           pack source library and translator to .deb-files");
   Msg("  Rpm           pack source library and translator to .rpm-files");

   Msg(""); Msg("Examples:");
   Msg("  result/bs-ost run 'make.Build; make.Test; make.Self' -infr . -m source");
   Msg("  result/ost run 'make.UseJava; make.Test' -infr . -m source");
   Msg("  /usr/bin/sudo result/ost run make.Install -infr . -m source")
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

 PROCEDURE Opt*(content: ARRAY OF CHAR);
 BEGIN
   (* TODO *)
   opt := content
 END Opt;

BEGIN
  Log.On;
  Exec.AutoCorrectDirSeparator(TRUE);

  windows := Platform.Windows;
  posix   := Platform.Posix;

  lang := C;

  cc[0]  := 0X;
  opt[0] := 0X;

  ok := TRUE
END make.

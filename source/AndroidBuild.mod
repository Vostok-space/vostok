(*  Builder of simple Android applications from Oberon-07
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
MODULE AndroidBuild;

IMPORT
  V, FileSys := FileSystemUtil,
  Out, Cli := CliParser, CLI, Translator, Message, Exec := PlatformExec,
  Files := VFileStream, Stream := VDataStream,
  Dir := CDir, Strings := StringStore;

TYPE
  Listener = RECORD(V.Base)
    args: Cli.Args;
    act: ARRAY 1024 OF CHAR
  END;

  PROCEDURE Sn(str: ARRAY OF CHAR);
  BEGIN
    Out.String(str); Out.Ln;
  END Sn;

  PROCEDURE Help*;
  BEGIN
    Sn("Builder of simple Android applications. 2018");
    Sn("Usage:");
    Sn("  1) o7a run   Script            Options");
    Sn("  2) o7a build Script Result.apk Options");
    Sn("  3) o7a install-tools")
  END Help;

  PROCEDURE W(f: Files.Out; str: ARRAY OF CHAR): BOOLEAN;
  RETURN
    LEN(str) = Stream.WriteChars(f^, str, 0, LEN(str))
  END W;

  PROCEDURE GenerateManifest(): BOOLEAN;
  VAR f: Files.Out; ok: BOOLEAN;
  BEGIN
    f  := Files.OpenOut("AndroidManifest.xml");
    ok := (f # NIL)
        & W(f, "<?xml version='1.0'?>")
        & W(f, "<manifest xmlns:a='http://schemas.android.com/apk/res/android'")
        & W(f, " package='o7.android'")
        & W(f, " a:versionCode='0' a:versionName='0'>")
        & W(f, "<application a:label=''>")
        & W(f, "<activity a:name='o7.android.Activity'>")
        & W(f, "<intent-filter>")
        & W(f, "<category a:name='android.intent.category.LAUNCHER'/>")
        & W(f, "<action a:name='android.intent.action.MAIN'/>")
        & W(f, "</intent-filter>")
        & W(f, "</activity>")
        & W(f, "</application>")
        & W(f, "</manifest>");
    Files.CloseOut(f)
  RETURN
    ok
  END GenerateManifest;

  PROCEDURE GenerateActivity*(path: ARRAY OF CHAR): BOOLEAN;
  VAR f: Files.Out; ok: BOOLEAN;
  BEGIN
    f  := Files.OpenOut(path);
    ok := (f # NIL)
        & W(f, "package o7.android;")
        & W(f, "public final class Activity extends android.app.Activity {")
        & W(f, "public static Activity act;")
        & W(f, "protected void onCreate(android.os.Bundle savedInstanceState) {")
        & W(f, "super.onCreate(savedInstanceState);")
        & W(f, "act = this;")
        & W(f, "o7.script.main(new String[] {});")
        & W(f, "}")
        & W(f, "protected void onDestroy() {")
        & W(f, "o7.AndroidO7Drawable.Destroy();")
        & W(f, "act = null;")
        & W(f, "super.onDestroy();")
        & W(f, "}")
        & W(f, "}");
    Files.CloseOut(f)
  RETURN
    ok
  END GenerateActivity;

  PROCEDURE Android(args: Cli.Args; apk: ARRAY OF CHAR): BOOLEAN;
  VAR cmd: Exec.Code; ok: BOOLEAN;
  BEGIN
    ok := FALSE;
    IF ~(Exec.Init(cmd, "/usr/lib/android-sdk/build-tools/debian/dx")
       & Exec.Add(cmd, "--dex", 0)

       & Exec.AddClean(cmd, " --output=")
       & Exec.AddClean(cmd, args.tmp)
       & Exec.AddClean(cmd, "/classes.dex")

       & Exec.Add(cmd, args.tmp, 0)
       & (Exec.Ok = Exec.Do(cmd))
        )
    THEN
      Sn("Error during call dx tool")
    ELSIF ~Dir.SetCurrent(args.tmp, 0) THEN
      Sn("Error during change current directory")
    ELSIF ~GenerateManifest() THEN
      Sn("Error when create AndroidManifest.xml")
    ELSIF ~(Exec.Init(cmd, "/usr/lib/android-sdk/build-tools/debian/aapt")
          & Exec.Add(cmd, "package", 0)
          & Exec.Add(cmd, "-f", 0)
          & Exec.Add(cmd, "-m", 0)
          & Exec.Add(cmd, "-F", 0)
          & Exec.Add(cmd, "raw.apk", 0)
          & Exec.Add(cmd, "-M", 0)
          & Exec.Add(cmd, "AndroidManifest.xml", 0)
          & Exec.Add(cmd, "-I", 0)
          & Exec.Add(cmd, "/usr/lib/android-sdk/platforms/android-9/android.jar", 0)

          & (Exec.Ok = Exec.Do(cmd))
           )
    THEN
      Sn("Error during call aapt tool for package")
    ELSIF ~(Exec.Init(cmd, "/usr/lib/android-sdk/build-tools/debian/aapt")
          & Exec.Add(cmd, "add", 0)
          & Exec.Add(cmd, "raw.apk", 0)
          & Exec.Add(cmd, "classes.dex", 0)

          & (Exec.Ok = Exec.Do(cmd))
           )
    THEN
      Sn("Error during call aapt tool for adding classes")
    ELSIF ~(Exec.Init(cmd, "keytool")
          & Exec.Add(cmd, "-genkeypair", 0)
          & Exec.Add(cmd, "-validity", 0)
          & Exec.Add(cmd, "32", 0)
          & Exec.Add(cmd, "-keystore", 0)
          & Exec.Add(cmd, "o7.keystore", 0)
          & Exec.Add(cmd, "-keyalg", 0)
          & Exec.Add(cmd, "RSA", 0)
          & Exec.Add(cmd, "-keysize", 0)
          & Exec.Add(cmd, "2048", 0)
          & Exec.Add(cmd, "-dname", 0)
          & Exec.Add(cmd, "cn=Developer, ou=Earth, o=Universe, c=SU", 0)
          & Exec.Add(cmd, "-storepass", 0)
          & Exec.Add(cmd, "oberon", 0)
          & Exec.Add(cmd, "-keypass", 0)
          & Exec.Add(cmd, "oberon", 0)

          & (Exec.Ok = Exec.Do(cmd))
           )
    THEN
      Sn("Error during call keytool for generating keystore")
    ELSIF ~(Exec.Init(cmd, "apksigner")
          & Exec.Add(cmd, "sign", 0)
          & Exec.Add(cmd, "--ks", 0)
          & Exec.Add(cmd, "o7.keystore", 0)
          & Exec.Add(cmd, "--ks-pass", 0)
          & Exec.Add(cmd, "pass:oberon", 0)
          & Exec.Add(cmd, "raw.apk", 0)

          & (Exec.Ok = Exec.Do(cmd))
           )
    THEN
      Sn("Error during call apksigner tool")
    ELSIF ~(Exec.Init(cmd, "/usr/lib/android-sdk/build-tools/debian/zipalign")
          & Exec.Add(cmd, "-f", 0)
          & Exec.Add(cmd, "4", 0)
          & Exec.Add(cmd, "raw.apk", 0)
          & Exec.Add(cmd, apk, 0)
          & (Exec.Ok = Exec.Do(cmd))
           )
    THEN
      Sn("Error during call zipalign tool")
    ELSE
      ok := TRUE
    END
  RETURN
    ok
  END Android;

  PROCEDURE RunApp(apk: ARRAY OF CHAR);
  VAR cmd: Exec.Code; ok: BOOLEAN;
  BEGIN
    ok := Exec.Init(cmd, "/usr/lib/android-sdk/platform-tools/adb")
        & Exec.Add(cmd, "uninstall", 0)
        & Exec.Add(cmd, "o7.android", 0)

        & (Exec.Ok = Exec.Do(cmd));
    IF ~(Exec.Init(cmd, "/usr/lib/android-sdk/platform-tools/adb")
       & Exec.Add(cmd, "install", 0)
       & Exec.Add(cmd, apk, 0)

       & (Exec.Ok = Exec.Do(cmd))
        )
    THEN
      Sn("Can not install application")
    ELSIF ~(Exec.Init(cmd, "/usr/lib/android-sdk/platform-tools/adb")
          & Exec.Add(cmd, "shell", 0)
          & Exec.Add(cmd, "am", 0)
          & Exec.Add(cmd, "start", 0)
          & Exec.Add(cmd, "-n", 0)
          & Exec.Add(cmd, "o7.android/.Activity", 0)

          & (Exec.Ok = Exec.Do(cmd))
           )
    THEN
      Sn("Can not run activity")
    END
  END RunApp;

  PROCEDURE Copy(VAR dest: ARRAY OF CHAR; VAR i: INTEGER; src: ARRAY OF CHAR)
                : BOOLEAN;
  RETURN
    Strings.CopyCharsNull(dest, i, src)
  END Copy;

  PROCEDURE ActivityPath(VAR act: ARRAY OF CHAR; dir: ARRAY OF CHAR);
  VAR i: INTEGER;
  BEGIN
    i := 0;
    ASSERT(((dir[0] = 0X)
        OR Copy(act, i, dir)
         & Copy(act, i, "/")
           )
         & Copy(act, i, "Activity.java")
    )
  END ActivityPath;

  PROCEDURE SetJavac(VAR javac: ARRAY OF CHAR; act: ARRAY OF CHAR);
  VAR i: INTEGER;
  BEGIN
    i := 0;
    ASSERT(Copy(javac, i, "javac -source 1.7 -target 1.7 -bootclasspath ")
         & Copy(javac, i, "/usr/lib/android-sdk/platforms/android-9/android.jar ")
         & Copy(javac, i, act)
    )
  END SetJavac;

  PROCEDURE Temp(VAR this, mes: V.Message): BOOLEAN;
  VAR handled: BOOLEAN;

    PROCEDURE Do(VAR l: Listener);
    BEGIN
      ActivityPath(l.act, l.args.tmp);
      IF GenerateActivity(l.act) THEN
        SetJavac(l.args.javac, l.act)
      ELSE
        Sn("Can not generate Activity.java")
      END
    END Do;
  BEGIN
    handled := mes IS Translator.MsgTempDirCreated;
    IF handled THEN
      Do(this(Listener))
    END
  RETURN
    handled
  END Temp;

  PROCEDURE Build*(run: BOOLEAN; arg: INTEGER);
  VAR err, len: INTEGER;
      apk, res: ARRAY 1024 OF CHAR;
      listener: Listener;
      delTmp, ok: BOOLEAN;
  BEGIN
    V.Init(listener);
    V.SetDo(listener, Temp);
    Cli.ArgsInit(listener.args);

    len := 0;
    listener.args.arg := arg + 1 + ORD(~run);
    IF CLI.count < listener.args.arg THEN
      Help
    ELSIF ~CLI.Get(listener.args.src, listener.args.srcLen, arg)
       OR ~run & ~CLI.Get(res, len, arg + 1)
    THEN
      Help
    ELSE
      listener.args.script := TRUE;
      err := Cli.Options(listener.args, listener.args.arg);
      IF err # Cli.ErrNo THEN
        Help
      ELSE
        len := 0;
        delTmp := listener.args.tmp[0] = 0X;
        err := Translator.Translate(Cli.ResultClass, listener.args, listener);
        ok := FALSE;
        IF err # Translator.ErrNo THEN
          IF err # Translator.ErrParse THEN
            Message.CliError(err)
          END
        ELSIF run THEN
          IF Android(listener.args, "oberon.apk") THEN
            RunApp("oberon.apk")
          END
        ELSIF res[0] = "/" THEN
          ok := Android(listener.args, res)
        ELSIF ~Dir.GetCurrent(apk, len) THEN
          Sn("Can not get current directory")
        ELSIF ~(Copy(apk, len, "/") & Copy(apk, len, res)) THEN
          Sn("Full path to result is too long")
        ELSE
          ok := Android(listener.args, apk)
        END;
        IF delTmp & ~FileSys.RemoveDir(listener.args.tmp) THEN
          Sn("Error when deleting temporary directory")
        END
      END
    END
  END Build;

  PROCEDURE Run*;
  BEGIN
    Build(TRUE, 0)
  END Run;

  PROCEDURE Apk*;
  BEGIN
    Build(FALSE, 0)
  END Apk;

  PROCEDURE InstallTools*;
  BEGIN
    Sn("To install tools for build Android applications in Ubuntu 18.04, run in shell:");
    Out.String("  /usr/bin/sudo apt install default-jdk android-sdk");
    Sn(" google-android-platform-9-installer apksigner")
  END InstallTools;

  PROCEDURE Go*;
  VAR len: INTEGER; cmd: ARRAY 16 OF CHAR;
  BEGIN
    len := 0;
    IF (CLI.count <= 0) OR ~CLI.Get(cmd, len, 0) THEN
      Sn("Not enough parameters. Run 'o7a help' too see available commands")
    ELSIF cmd = "help" THEN
      Help
    ELSIF cmd = "run" THEN
      Build(TRUE, 1)
    ELSIF cmd = "build" THEN
      Build(FALSE, 1)
    ELSIF cmd = "install-tools" THEN
      InstallTools
    ELSE
      Sn("Unknown command. Run 'o7a help' too see available commands")
    END
  END Go;

END AndroidBuild.

(*  Builder of simple Android applications from Oberon-07
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
MODULE AndroidBuild;

IMPORT
  V,
  FileSys := FileSystemUtil,
  Out,
  Cli := CliParser, CLI,
  Translator,
  Message,
  Exec := PlatformExec,
  Files := VFileStream, Stream := VDataStream,
  Dir := CDir,
  Chars0X;

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
    Sn("Builder of simple Android applications. 2019 v0.0.4.dev");
    Sn("Usage:");
    Sn("  1) osa run   Script            Options");
    Sn("  2) osa build Script Result.apk Options");
    Sn("  3) osa install-tools");
    Sn("Options same as for ost, run 'ost help' to see more");
    Sn("");
    Sn("Example:");
    Sn("  osa build 'Star.Go(5, 0.38)' result/star.apk -m example/android");
    Sn("  osa run Rocket.Fly -m example/android")
  END Help;

  PROCEDURE W(f: Files.Out; str: ARRAY OF CHAR): BOOLEAN;
  BEGIN
    ASSERT(str[LEN(str) - 1] = 0X)
  RETURN
    LEN(str) - 1 = Stream.WriteChars(f^, str, 0, LEN(str) - 1)
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
       & Exec.Add(cmd, "--dex")

       & Exec.AddClean(cmd, " --output=")
       & Exec.AddClean(cmd, args.tmp)
       & Exec.AddClean(cmd, "/classes.dex")

       & Exec.Add(cmd, args.tmp)
       & (Exec.Ok = Exec.Do(cmd))
        )
    THEN
      Sn("Error during call dx tool")
    ELSIF ~Dir.SetCurrent(args.tmp, 0) THEN
      Sn("Error during change current directory")
    ELSIF ~GenerateManifest() THEN
      Sn("Error when create AndroidManifest.xml")
    ELSIF ~(Exec.Init(cmd, "/usr/lib/android-sdk/build-tools/debian/aapt")
          & Exec.Add(cmd, "package")
          & Exec.Add(cmd, "-f")
          & Exec.Add(cmd, "-m")
          & Exec.Add(cmd, "-F")
          & Exec.Add(cmd, "raw.apk")
          & Exec.Add(cmd, "-M")
          & Exec.Add(cmd, "AndroidManifest.xml")
          & Exec.Add(cmd, "-I")
          & Exec.Add(cmd, "/usr/lib/android-sdk/platforms/android-9/android.jar")

          & (Exec.Ok = Exec.Do(cmd))
           )
    THEN
      Sn("Error during call aapt tool for package")
    ELSIF ~(Exec.Init(cmd, "/usr/lib/android-sdk/build-tools/debian/aapt")
          & Exec.Add(cmd, "add")
          & Exec.Add(cmd, "raw.apk")
          & Exec.Add(cmd, "classes.dex")

          & (Exec.Ok = Exec.Do(cmd))
           )
    THEN
      Sn("Error during call aapt tool for adding classes")
    ELSIF ~(Exec.Init(cmd, "keytool")
          & Exec.Add(cmd, "-genkeypair")
          & Exec.Add(cmd, "-validity")
          & Exec.Add(cmd, "32")
          & Exec.Add(cmd, "-keystore")
          & Exec.Add(cmd, "o7.keystore")
          & Exec.Add(cmd, "-keyalg")
          & Exec.Add(cmd, "RSA")
          & Exec.Add(cmd, "-keysize")
          & Exec.Add(cmd, "2048")
          & Exec.Add(cmd, "-dname")
          & Exec.Add(cmd, "cn=Developer, ou=Earth, o=Universe, c=SU")
          & Exec.Add(cmd, "-storepass")
          & Exec.Add(cmd, "oberon")
          & Exec.Add(cmd, "-keypass")
          & Exec.Add(cmd, "oberon")

          & (Exec.Ok = Exec.Do(cmd))
           )
    THEN
      Sn("Error during call keytool for generating keystore")
    ELSIF ~(Exec.Init(cmd, "/usr/lib/android-sdk/build-tools/debian/zipalign")
          & Exec.Add(cmd, "-f")
          & Exec.Add(cmd, "4")
          & Exec.Add(cmd, "raw.apk")
          & Exec.Add(cmd, apk)

          & (Exec.Ok = Exec.Do(cmd))
           )
    THEN
      Sn("Error during call zipalign tool")
    ELSIF ~(Exec.Init(cmd, "apksigner")
          & Exec.Add(cmd, "sign")
          & Exec.Add(cmd, "--ks")
          & Exec.Add(cmd, "o7.keystore")
          & Exec.Add(cmd, "--ks-pass")
          & Exec.Add(cmd, "pass:oberon")
          & Exec.Add(cmd, apk)

          & (Exec.Ok = Exec.Do(cmd))
           )
    THEN
      Sn("Error during call apksigner tool")
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
        & Exec.Add(cmd, "uninstall")
        & Exec.Add(cmd, "o7.android")

        & (Exec.Ok = Exec.Do(cmd));
    IF ~(Exec.Init(cmd, "/usr/lib/android-sdk/platform-tools/adb")
       & Exec.Add(cmd, "install")
       & Exec.Add(cmd, apk)

       & (Exec.Ok = Exec.Do(cmd))
        )
    THEN
      Sn("Can not install application")
    ELSIF ~(Exec.Init(cmd, "/usr/lib/android-sdk/platform-tools/adb")
          & Exec.Add(cmd, "shell")
          & Exec.Add(cmd, "am")
          & Exec.Add(cmd, "start")
          & Exec.Add(cmd, "-n")
          & Exec.Add(cmd, "o7.android/.Activity")

          & (Exec.Ok = Exec.Do(cmd))
           )
    THEN
      Sn("Can not run activity")
    END
  END RunApp;

  PROCEDURE Copy(VAR dest: ARRAY OF CHAR; VAR i: INTEGER; src: ARRAY OF CHAR)
                : BOOLEAN;
  RETURN
    Chars0X.CopyString(dest, i, src)
  END Copy;

  PROCEDURE ActivityPath(VAR act: ARRAY OF CHAR; dir: ARRAY OF CHAR): BOOLEAN;
  VAR i: INTEGER;
  BEGIN
    i := 0;
  RETURN
    ((dir[0] = 0X)
  OR Copy(act, i, dir)
   & Copy(act, i, "/")
    )
  & Copy(act, i, "Activity.java")
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
      IF ActivityPath(l.act, l.args.tmp) & GenerateActivity(l.act) THEN
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

  PROCEDURE ListenerInit(VAR l: Listener);
  BEGIN
    V.Init(l);
    V.SetDo(l, Temp);
    Cli.ArgsInit(l.args)
  END ListenerInit;

  PROCEDURE PrepareCliArgs(VAR args: Cli.Args; VAR res: ARRAY OF CHAR;
                           arg: INTEGER; run: BOOLEAN)
                          : BOOLEAN;
  VAR ok: BOOLEAN; len: INTEGER;
  BEGIN
    ok := FALSE;
    len := 0;
    args.arg := arg + 1 + ORD(~run);
    IF CLI.count < args.arg THEN
      Help
    ELSIF ~CLI.Get(args.src, args.srcLen, arg)
       OR ~run & ~CLI.Get(res, len, arg + 1)
    THEN
      Help
    ELSE
      args.script := TRUE;
      IF Cli.Options(args, args.arg) # Cli.ErrNo THEN
        Help
      ELSE
        ok := TRUE
      END
    END
  RETURN
    ok
  END PrepareCliArgs;

  PROCEDURE Build*(run: BOOLEAN; arg: INTEGER);
  VAR err, len: INTEGER;
      apk, res: ARRAY 1024 OF CHAR;
      listener: Listener;
      delTmp, ok: BOOLEAN;
  BEGIN
    ListenerInit(listener);
    IF PrepareCliArgs(listener.args, res, arg, run) THEN
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
    Sn("To install tools for build Android applications in Ubuntu, run in shell:");
    Out.String("  /usr/bin/sudo apt install default-jdk android-sdk");
    Sn(" google-android-platform-9-installer apksigner")
  END InstallTools;

  PROCEDURE Go*;
  VAR len: INTEGER; cmd: ARRAY 16 OF CHAR;
  BEGIN
    len := 0;
    IF (CLI.count <= 0) OR ~CLI.Get(cmd, len, 0) THEN
      Sn("Not enough parameters. Run 'osa help' too see available commands")
    ELSIF cmd = "help" THEN
      Help
    ELSIF cmd = "run" THEN
      Build(TRUE, 1)
    ELSIF cmd = "build" THEN
      Build(FALSE, 1)
    ELSIF cmd = "install-tools" THEN
      InstallTools
    ELSE
      Sn("Unknown command. Run 'osa help' too see available commands")
    END
  END Go;

END AndroidBuild.

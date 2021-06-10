(*  Builder of simple Android applications from Oberon-07
 *
 *  Copyright (C) 2018-2019,2021 ComdivByZero
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
  Translator, TranslatorVersion,
  Message,
  Exec := PlatformExec,
  Files := VFileStream, Stream := VDataStream,
  CFiles,
  Dir := CDir,
  Utf8,
  Chars0X,
  Env := OsEnv, OsUtil;

CONST
  BuildTools    = 11;
  PlatformTools = 12;

TYPE
  Listener = RECORD(V.Base)
    args: Cli.Args;

    act: ARRAY 1024 OF CHAR;
    sdk: ARRAY 128 OF CHAR;
    platform: ARRAY 3 OF CHAR;
    tools: ARRAY 63 OF CHAR;

    ksGen: BOOLEAN;
    key, cert: ARRAY 256 OF CHAR;
    ksPass  : ARRAY 64 OF CHAR
  END;

VAR
  sdkDefault: ARRAY 128 OF CHAR;
  platformDefault: ARRAY 3 OF CHAR;
  toolsDefault: ARRAY 63 OF CHAR;

  PROCEDURE Sn(str: ARRAY OF CHAR);
  BEGIN
    Out.String(str); Out.Ln;
  END Sn;

  PROCEDURE Help*;
    PROCEDURE S(str: ARRAY OF CHAR);
    BEGIN
      Out.String(str)
    END S;
  BEGIN
    S ("Builder of simple Android applications. 2021 "); Sn(TranslatorVersion.Val);
    Sn("Usage:");
    Sn("  1) osa run   Script            [options] [ost options]");
    Sn("  2) osa build Script Result.apk [options] [ost options]");
    Sn("  3) osa install-tools");
    Sn("");
    Sn("Specific options, that must be specified first:");
    S ("  -sdk      path      path to Android SDK base directory("); S(sdkDefault); Sn(")");
    Sn("  -sdk      ''        use SDK tools by name, because they are available in PATH");
    S ("  -platform num       number of android platform("); S(platformDefault); Sn(")");
    S ("  -tools    version   build-tools version in SDK("); S(toolsDefault); Sn(")");
    Sn("");
    Sn("  -keystore path pass keystore path and password for keystore and key for signing");
    Sn("  -key      cert key  pathes to certificate and key for signing");
    Sn("  -key      -         skip signing");
    Sn("");
    Sn("Other options are shared with ost, run 'ost help' to see more.");
    Sn("");
    Sn("Example:");
    Sn("  osa build 'Star.Go(5, 0.38)' result/star.apk -m example/android");
    Sn("  osa run Rocket.Fly -m example/android")
  END Help;

  PROCEDURE W(f: Files.Out; str: ARRAY OF CHAR): BOOLEAN;
  BEGIN
    ASSERT(str[LEN(str) - 1] = 0X)
  RETURN
    (LEN(str) - 1 = Stream.WriteChars(f^, str, 0, LEN(str) - 1))
  & (1 = Stream.WriteChars(f^, Utf8.NewLine, 0, 1))
  END W;

  PROCEDURE GenerateManifest(): BOOLEAN;
  VAR f: Files.Out; ok: BOOLEAN;
  BEGIN
    f  := Files.OpenOut("AndroidManifest.xml");
    ok := (f # NIL)
        & W(f, "<?xml version='1.0' encoding='utf-8'?>")
        & W(f, "<manifest xmlns:android='http://schemas.android.com/apk/res/android'")
        & W(f, " package='o7.android'")
        & W(f, " android:versionCode='1' android:versionName='1.0'>")
        & W(f, "<uses-sdk android:minSdkVersion='9' android:targetSdkVersion='26'/>")
        & W(f, "<application android:label=''>")
        & W(f, "<activity android:name='o7.android.Activity'>")
        & W(f, "<intent-filter>")
        & W(f, "<category android:name='android.intent.category.LAUNCHER'/>")
        & W(f, "<action android:name='android.intent.action.MAIN'/>")
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

  PROCEDURE InitWithSdk(VAR cmd: Exec.Code; args: Listener; opt: SET; name: ARRAY OF CHAR): BOOLEAN;
  VAR ok: BOOLEAN;
  BEGIN
    ASSERT(opt - {BuildTools, PlatformTools} = {});
    IF args.sdk = "" THEN
      ok := Exec.Init(cmd, name)
    ELSE
      ok := Exec.Init(cmd, "")
          & Exec.FirstPart(cmd, args.sdk)
          & Exec.AddDirSep(cmd)
          & (   ~(BuildTools IN opt)
             OR Exec.AddPart(cmd, "build-tools/")
              & Exec.AddPart(cmd, args.tools)
              & Exec.AddDirSep(cmd)
            )
          & (   ~(PlatformTools IN opt)
             OR Exec.AddPart(cmd, "platform-tools/")
            )
          & Exec.LastPart(cmd, name)
    END
  RETURN
    ok
  END InitWithSdk;

  PROCEDURE Android(args: Listener; apk: ARRAY OF CHAR): BOOLEAN;
  VAR cmd: Exec.Code; ok: BOOLEAN;
  BEGIN
    ok := FALSE;
    IF ~(InitWithSdk(cmd, args, {BuildTools}, "dx")
       & Exec.Add(cmd, "--dex")

       & Exec.AddClean(cmd, " --output=")
       & Exec.AddClean(cmd, args.args.tmp)
       & Exec.AddClean(cmd, "/classes.dex")

       & Exec.Add(cmd, args.args.tmp)
       & (Exec.Ok = Exec.Do(cmd))
        )
    THEN
      Sn("Error during call dx tool")
    ELSIF ~Dir.SetCurrent(args.args.tmp, 0) THEN
      Sn("Error during change current directory")
    ELSIF ~GenerateManifest() THEN
      Sn("Error when create AndroidManifest.xml")
    ELSIF ~(InitWithSdk(cmd, args, {BuildTools}, "aapt")
          & Exec.Add(cmd, "package")
          & Exec.Add(cmd, "-f")
          & Exec.Add(cmd, "-m")
          & Exec.Add(cmd, "-F")
          & Exec.Add(cmd, "raw.apk")
          & Exec.Add(cmd, "-M")
          & Exec.Add(cmd, "AndroidManifest.xml")
          & Exec.Add(cmd, "-I")

          & Exec.FirstPart(cmd, args.sdk)
          & Exec.AddPart(cmd, "/platforms/android-")
          & Exec.AddPart(cmd, args.platform)
          & Exec.LastPart(cmd, "/android.jar")

          & (Exec.Ok = Exec.Do(cmd))
           )
    THEN
      Sn("Error during call aapt tool for package")
    ELSIF ~(InitWithSdk(cmd, args, {BuildTools}, "aapt")
          & Exec.Add(cmd, "add")
          & Exec.Add(cmd, "raw.apk")
          & Exec.Add(cmd, "classes.dex")

          & (Exec.Ok = Exec.Do(cmd))
           )
    THEN
      Sn("Error during call aapt tool for adding classes")
    ELSE
      IF ~(InitWithSdk(cmd, args, {BuildTools}, "zipalign")
         & Exec.Add(cmd, "-f")
         & Exec.Add(cmd, "4")
         & Exec.Add(cmd, "raw.apk")
         & Exec.Add(cmd, apk)

         & (Exec.Ok = Exec.Do(cmd))
          )
      THEN
        Sn("Error during call zipalign tool. Not critical.")
      END;

      IF args.ksGen
       & ~(Exec.Init(cmd, "keytool")
         & Exec.Add(cmd, "-genkeypair")
         & Exec.Add(cmd, "-validity")
         & Exec.Add(cmd, "32")
         & Exec.Add(cmd, "-keystore")
         & Exec.Add(cmd, args.key)
         & Exec.Add(cmd, "-keyalg")
         & Exec.Add(cmd, "RSA")
         & Exec.Add(cmd, "-keysize")
         & Exec.Add(cmd, "2048")
         & Exec.Add(cmd, "-dname")
         & Exec.Add(cmd, "cn=Developer, ou=Earth, o=Universe, c=SU")
         & Exec.Add(cmd, "-storepass")
         & Exec.Add(cmd, args.ksPass)
         & Exec.Add(cmd, "-keypass")
         & Exec.Add(cmd, args.ksPass)

         & (Exec.Ok = Exec.Do(cmd))
          )
      THEN
        Sn("Error during call keytool for generating keystore")
      ELSIF (args.key # "-")
          & ~(Exec.Init(cmd, "apksigner")
            & Exec.Add(cmd, "sign")

            & ( (args.ksPass = "")
             OR Exec.Add(cmd, "--ks")
              & Exec.Add(cmd, args.key)

              & Exec.Add(cmd, "--ks-pass")
              & Exec.FirstPart(cmd, "pass:")
              & Exec.LastPart(cmd, args.ksPass)
              )

            & ( (args.cert = "")
             OR Exec.Add(cmd, "--cert")
              & Exec.Add(cmd, args.cert)

              & Exec.Add(cmd, "--key")
              & Exec.Add(cmd, args.key)
              )

            & Exec.Add(cmd, apk)

            & (Exec.Ok = Exec.Do(cmd))
            )
      THEN
        Sn("Error during call apksigner tool")
      ELSE
        ok := TRUE
      END
    END
  RETURN
    ok
  END Android;

  PROCEDURE RunApp(args: Listener; apk: ARRAY OF CHAR);
  VAR cmd: Exec.Code; ok: BOOLEAN;
  BEGIN
    ok := InitWithSdk(cmd, args, {PlatformTools}, "adb")
        & Exec.Add(cmd, "uninstall")
        & Exec.Add(cmd, "o7.android")

        & (Exec.Ok = Exec.Do(cmd));
    IF ~(InitWithSdk(cmd, args, {PlatformTools}, "adb")
       & Exec.Add(cmd, "install")
       & Exec.Add(cmd, apk)

       & (Exec.Ok = Exec.Do(cmd))
        )
    THEN
      Sn("Can not install application")
    ELSIF ~(InitWithSdk(cmd, args, {PlatformTools}, "adb")
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

  PROCEDURE Copy(VAR dest: ARRAY OF CHAR; VAR i: INTEGER; src: ARRAY OF CHAR): BOOLEAN;
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

  PROCEDURE SetJavac(VAR javac: ARRAY OF CHAR; args: Listener);
  VAR i: INTEGER;
  BEGIN
    i := Chars0X.CalcLen(javac, 0);
    ASSERT(((i > 0) OR Copy(javac, i, "javac"))
         & Copy(javac, i, " -source 1.8 -target 1.8 -bootclasspath ")

         & Copy(javac, i, args.sdk)
         & Copy(javac, i, "/platforms/android-")
         & Copy(javac, i, args.platform)
         & Copy(javac, i, "/android.jar ")

         & Copy(javac, i, args.act)
    )
  END SetJavac;

  PROCEDURE Temp(VAR this, mes: V.Message): BOOLEAN;
  VAR handled: BOOLEAN;

    PROCEDURE Do(VAR l: Listener);
    BEGIN
      IF ActivityPath(l.act, l.args.tmp) & GenerateActivity(l.act) THEN
        SetJavac(l.args.javac, l)
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

  PROCEDURE AnOpt(VAR args: Listener; VAR arg: INTEGER): BOOLEAN;
  VAR cont, ok: BOOLEAN; opt: ARRAY 12 OF CHAR; len, l2, l3: INTEGER; path: ARRAY 1024 OF CHAR;
  BEGIN
    ok := TRUE;
    cont := TRUE;
    len := 0;
    WHILE cont & (arg + 1 < CLI.count) & CLI.Get(opt, len, arg) DO
      len := 0;
      l2  := 0;
      l3  := 0;
      IF opt = "-sdk" THEN
        ok := CLI.Get(args.sdk, len, arg + 1);
        INC(arg, 2)
      ELSIF opt = "-platform" THEN
        ok := CLI.Get(args.platform, len, arg + 1);
        INC(arg, 2);
      ELSIF opt = "-tools" THEN
        ok := CLI.Get(args.tools, len, arg + 1);
        INC(arg, 2)
      ELSIF opt = "-keystore" THEN
        ok := (arg + 2 < CLI.count)
            & CLI.Get(path, len, arg + 1) & OsUtil.CopyFullPath(args.key, l2, path)
            & CLI.Get(args.ksPass, l3, arg + 2);
        INC(arg, 3)
      ELSIF opt = "-key" THEN
        ok := CLI.Get(path, len, arg + 1);
        IF path = "-" THEN
          args.key := "-";
          INC(arg, 2)
        ELSE
          len := 0;
          ok := ok & (arg + 2 < CLI.count)
              & OsUtil.CopyFullPath(args.cert, len, path)
              & CLI.Get(path, l2, arg + 2) & OsUtil.CopyFullPath(args.key, l3, path);
          INC(arg, 3)
        END
      ELSIF opt = "-no-sign" THEN
        args.key := "-"
      ELSE
        cont := FALSE
      END;
      len := 0
    END
  RETURN
    ok
  END AnOpt;

  PROCEDURE PrepareCliArgs(VAR args: Listener; VAR res: ARRAY OF CHAR;
                           arg: INTEGER; run: BOOLEAN)
                          : BOOLEAN;
  VAR len: INTEGER; ok: BOOLEAN;

    PROCEDURE IsDebugKeystoreExist(VAR ks: ARRAY OF CHAR): BOOLEAN;
    VAR i: INTEGER;
    BEGIN
      i := 0
    RETURN
      (*TODO*)
      Env.Get(ks, i, "HOME")
    & Chars0X.CopyString(ks, i, "/.android/debug.keystore")

    & CFiles.Exist(ks, 0)
    END IsDebugKeystoreExist;
  BEGIN
    len := 0;

    ASSERT(Chars0X.Set(args.sdk, sdkDefault)
         & Chars0X.Set(args.platform, platformDefault)
         & Chars0X.Set(args.tools, toolsDefault));
    args.key := "";

    args.args.arg := arg + 1 + ORD(~run);
    args.args.script := TRUE;

    ok := (CLI.count >= args.args.arg)
        &
          CLI.Get(args.args.src, args.args.srcLen, arg)
        & (run OR CLI.Get(res, len, arg + 1))

        & AnOpt(args, args.args.arg)

        & (Cli.ErrNo = Cli.Options(args.args, args.args.arg));

    args.ksGen := ok & (args.key = "")
                & ~(IsDebugKeystoreExist(args.key) & Chars0X.Set(args.ksPass, "android"));
    IF args.ksGen THEN
      ok := Chars0X.Set(args.key, "o7.keystore")
          & Chars0X.Set(args.ksPass, "oberon")
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
    IF ~PrepareCliArgs(listener, res, arg, run) THEN
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
        IF Android(listener, "oberon.apk") THEN
          RunApp(listener, "oberon.apk")
        END
      ELSIF res[0] = "/" THEN
        ok := Android(listener, res)
      ELSIF ~Dir.GetCurrent(apk, len) THEN
        Sn("Can not get current directory")
      ELSIF ~(Copy(apk, len, "/") & Copy(apk, len, res)) THEN
        Sn("Full path to result is too long")
      ELSE
        ok := Android(listener, apk)
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

BEGIN
  sdkDefault := "/usr/lib/android-sdk";
  platformDefault := "9";
  toolsDefault := "debian"
END AndroidBuild.

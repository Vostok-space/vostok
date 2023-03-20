(*  Builder of simple Android applications from Oberon-07
 *
 *  Copyright (C) 2018-2019,2021-2023 ComdivByZero
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
  Charz,
  Env := OsEnv, OsUtil;

CONST
  BuildTools    = 11;
  PlatformTools = 12;

  CmdBuild  = 0;
  CmdRun    = 1;
  CmdOpen   = 2;

TYPE
  ActivityName = RECORD
    val: ARRAY 256 OF CHAR;
    name: INTEGER
  END;

  Listener = RECORD(V.Base)
    args: Cli.Args;

    act: ARRAY 1024 OF CHAR;
    sdk: ARRAY 128 OF CHAR;
    platform: ARRAY 3 OF CHAR;
    tools: ARRAY 63 OF CHAR;

    ksGen: BOOLEAN;
    key, cert, baseClasses: ARRAY 256 OF CHAR;
    ksPass: ARRAY 64 OF CHAR;
    activity: ActivityName
  END;

VAR
  sdkDefault, baseClassPathDefault: ARRAY 128 OF CHAR;
  platformDefault: ARRAY 3 OF CHAR;
  toolsDefault: ARRAY 63 OF CHAR;
  keyDefault, certDefault: ARRAY 128 OF CHAR;
  activityDefault: ActivityName;
  javacDefault: ARRAY 256 OF CHAR;

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
    Sn("  2) osa open  Script            [options] [ost options]");
    Sn("  2) osa build Script Result.apk [options] [ost options]");
    Sn("  3) osa install-tools");
    Sn("");
    Sn("Specific options, that must be specified first:");
    S ("  -sdk      path      path to Android SDK base directory("); S(sdkDefault); Sn(")");
    Sn("  -sdk      ''        use SDK tools by name, because they are available in PATH");
    S ("  -platform num       number of android platform("); S(platformDefault); Sn(")");
    S ("  -tools    version   build-tools version in SDK("); S(toolsDefault); Sn(")");
    Sn("  -basecp   jar       base Android classes in jar");
    Sn("");
    Sn("  -keystore path pass keystore path and password for keystore and key for signing");
    Sn("  -key      key cert  pathes to key and certificate for signing");
    Sn("  -key      -         skip signing");
    Sn("");
    S ("  -activity name      set activity name("); S(activityDefault.val); Sn(")");
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

  PROCEDURE W0(f: Files.Out; str: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
  VAR len: INTEGER;
  BEGIN
    len := Charz.CalcLen(str, ofs)
  RETURN
    len = Stream.WriteChars(f^, str, ofs, len)
  END W0;

  PROCEDURE GenerateManifest(act: ActivityName): BOOLEAN;
  VAR f: Files.Out; ok: BOOLEAN;
  BEGIN
    f  := Files.OpenOut("AndroidManifest.xml");
    ok := (f # NIL)
        & W(f, "<?xml version='1.0' encoding='utf-8'?>")
        & W(f, "<manifest xmlns:android='http://schemas.android.com/apk/res/android'")
        & W0(f, " package='", 0) & W0(f, act.val, 0) & W(f, "'")
        & W(f, " android:versionCode='1' android:versionName='1.0'>")
        & W(f, "<uses-sdk android:minSdkVersion='9' android:targetSdkVersion='26'/>")
        & W0(f, "<application android:label='", 0) & W0(f, act.val, act.name) & W(f, "'>")
        & W0(f, "<activity android:name='", 0) & W0(f, act.val, act.name) & W(f, "'>")
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

  PROCEDURE GenerateActivity*(path: ARRAY OF CHAR; act: ActivityName): BOOLEAN;
  VAR f: Files.Out; ok: BOOLEAN;
  BEGIN
    f  := Files.OpenOut(path);
    ok := (f # NIL)
        & W0(f, "package ", 0) & W0(f, act.val, 0) & W(f, ";")

        & W0(f, "public final class ", 0)
        & W0(f, act.val, act.name)
        & W(f, " extends android.app.Activity {")

        & W(f, "protected void onCreate(android.os.Bundle savedInstanceState) {")
        & W(f, "  super.onCreate(savedInstanceState);")
        & W(f, "  this.requestWindowFeature(android.view.Window.FEATURE_NO_TITLE);")
        & W(f, "  o7.AndroidO7Activity.act = this;")
        & W(f, "  o7.script.main(new String[] {});")
        & W(f, "}")
        & W(f, "protected void onDestroy() {")
        & W(f, "  o7.AndroidO7Activity.Destroy();")
        & W(f, "  o7.AndroidO7Activity.act = null;")
        & W(f, "  super.onDestroy();")
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
       & Exec.Key(cmd, "--dex")

       & Exec.AddAsIs(cmd, " --output=")
       & Exec.AddAsIs(cmd, args.args.tmp)
       & Exec.AddAsIs(cmd, "/classes.dex")

       & Exec.Val(cmd, args.args.tmp)
       & (Exec.Ok = Exec.Do(cmd))
        )
    THEN
      Sn("Error during call dx tool")
    ELSIF ~Dir.SetCurrent(args.args.tmp, 0) THEN
      Sn("Error during change current directory")
    ELSIF ~GenerateManifest(args.activity) THEN
      Sn("Error when create AndroidManifest.xml")
    ELSIF ~(InitWithSdk(cmd, args, {BuildTools}, "aapt")
          & Exec.Val(cmd, "package")
          & Exec.Keys(cmd, "-f", "-m")
          & Exec.Par(cmd, "-F", "raw.apk")
          & Exec.Par(cmd, "-M", "AndroidManifest.xml")
          & Exec.Par(cmd, "-I", args.baseClasses)

          & (Exec.Ok = Exec.Do(cmd))
           )
    THEN
      Sn("Error during call aapt tool for package")
    ELSIF ~(InitWithSdk(cmd, args, {BuildTools}, "aapt")
          & Exec.Val(cmd, "add")
          & Exec.Vals(cmd, "raw.apk", "classes.dex")

          & (Exec.Ok = Exec.Do(cmd))
           )
    THEN
      Sn("Error during call aapt tool for adding classes")
    ELSE
      IF ~(InitWithSdk(cmd, args, {BuildTools}, "zipalign")
         & Exec.Par(cmd, "-f", "4")
         & Exec.Vals(cmd, "raw.apk", apk)

         & (Exec.Ok = Exec.Do(cmd))
          )
      THEN
        Sn("Error during call zipalign tool. Not critical.")
      END;

      IF args.ksGen
       & ~(Exec.Init(cmd, "keytool")
         & Exec.Key(cmd, "-genkeypair")
         & Exec.Par(cmd, "-validity" , "32")
         & Exec.Par(cmd, "-keystore" , args.key)
         & Exec.Par(cmd, "-keyalg"   , "RSA")
         & Exec.Par(cmd, "-keysize"  , "2048")
         & Exec.Par(cmd, "-dname"    , "cn=Developer, ou=Earth, o=Universe, c=SU")
         & Exec.Par(cmd, "-storepass", args.ksPass)
         & Exec.Par(cmd, "-keypass"  , args.ksPass)

         & (Exec.Ok = Exec.Do(cmd))
          )
      THEN
        Sn("Error during call keytool for generating keystore")
      ELSIF (args.key # "-")
          & ~(Exec.Init(cmd, "apksigner")
            & Exec.Val(cmd, "sign")

            & ( (args.ksPass = "")
             OR Exec.Par(cmd, "--ks", args.key)

              & Exec.Key(cmd, "--ks-pass")
              & Exec.FirstPart(cmd, "pass:")
              & Exec.LastPart(cmd, args.ksPass)
              )

            & ( (args.cert = "")
             OR   Exec.Par(cmd, "--cert", args.cert)
                & Exec.Par(cmd, "--key", args.key)
              )

            & Exec.Val(cmd, apk)

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

  PROCEDURE RunApp(args: Listener; apk: ARRAY OF CHAR): BOOLEAN;
  VAR cmd: Exec.Code; ok: BOOLEAN;
  BEGIN
    ok := InitWithSdk(cmd, args, {PlatformTools}, "adb")
        & Exec.Vals(cmd, "uninstall", args.activity.val)
        & (Exec.Ok = Exec.Do(cmd));
    ok := FALSE;
    IF ~(InitWithSdk(cmd, args, {PlatformTools}, "adb")
       & Exec.Vals(cmd, "install", apk)
       & (Exec.Ok = Exec.Do(cmd))
        )
    THEN
      Sn("Can not install application")
    ELSIF ~(InitWithSdk(cmd, args, {PlatformTools}, "adb")
          & Exec.Val(cmd, "shell")
          & Exec.Vals(cmd, "am", "start")
          & Exec.Key(cmd, "-n")

          & Exec.FirstPart(cmd, args.activity.val)
          & Exec.AddPart(cmd, "/.")
          & Exec.LastPartByOfs(cmd, args.activity.val, args.activity.name)

          & (Exec.Ok = Exec.Do(cmd))
           )
    THEN
      Sn("Can not run activity")
    ELSE
      ok := TRUE
    END
  RETURN
    ok
  END RunApp;

  PROCEDURE OpenApp(apk: ARRAY OF CHAR): BOOLEAN;
  VAR cmd: Exec.Code;
  RETURN
    Exec.Init(cmd, "xdg-open")
  & Exec.Val(cmd, apk)
  & (Exec.Ok = Exec.Do(cmd))
  END OpenApp;

  PROCEDURE Copy(VAR dest: ARRAY OF CHAR; VAR i: INTEGER; src: ARRAY OF CHAR): BOOLEAN;
  RETURN
    Charz.CopyString(dest, i, src)
  END Copy;

  PROCEDURE ActivityPath(VAR act: ARRAY OF CHAR; dir: ARRAY OF CHAR; name: ActivityName): BOOLEAN;
  VAR i, ni: INTEGER; ok: BOOLEAN;
  BEGIN
    i := 0;
    ni := name.name;
    IF dir = "" THEN
      ok := Copy(act, i, "o7")
    ELSE
      ok := Copy(act, i, dir)
          & Copy(act, i, "/o7")
    END;
    IF ok THEN
      ok := FileSys.MakeDir(act)
    END
  RETURN
    ok
  & Copy(act, i, "/")
  & Charz.Copy(act, i, name.val, ni)
  & Copy(act, i, ".java")
  END ActivityPath;

  PROCEDURE SetJavac(VAR javac: ARRAY OF CHAR; args: Listener): BOOLEAN;
  VAR i: INTEGER;
  BEGIN
    i := Charz.CalcLen(javac, 0);
  RETURN
    ((i > 0) OR Copy(javac, i, javacDefault))
  & Copy(javac, i, " -bootclasspath ")
  & Copy(javac, i, args.baseClasses)
  & Copy(javac, i, " ")
  & Copy(javac, i, args.act)
  END SetJavac;

  PROCEDURE Temp(VAR this, mes: V.Message): BOOLEAN;
  VAR handled: BOOLEAN;

    PROCEDURE Do(VAR l: Listener);
    BEGIN
      IF ~(ActivityPath(l.act, l.args.tmp, l.activity) & GenerateActivity(l.act, l.activity)) THEN
        Sn("Can not generate Activity.java")
      ELSIF ~SetJavac(l.args.javac, l) THEN
        Sn("Too long javac string")
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

  PROCEDURE SetActivityName*(VAR act: ActivityName; value: ARRAY OF CHAR): BOOLEAN;
  VAR i: INTEGER; ok: BOOLEAN;
  BEGIN
    act.name := 0;
    IF Charz.SearchCharLast(value, act.name, ".") THEN
      INC(act.name);
      ok := Charz.Set(act.val, value)
    ELSE
      i := 0;
      ok := Charz.CopyString(act.val, i, "o7.android.");
      act.name := i;
      ok := ok & Charz.CopyString(act.val, i, value)
    END
  RETURN
    ok
  END SetActivityName;

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
      ELSIF opt = "-basecp" THEN
        ok := CLI.Get(path, len, arg + 1) & OsUtil.CopyFullPath(args.baseClasses, l2, path);
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
              & OsUtil.CopyFullPath(args.key, len, path)
              & CLI.Get(path, l2, arg + 2) & OsUtil.CopyFullPath(args.cert, l3, path);
          INC(arg, 3)
        END
      ELSIF opt = "-activity" THEN
        ok := CLI.Get(path, len, arg + 1)
            & SetActivityName(args.activity, path);
        INC(arg, 2)
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
    & Charz.CopyString(ks, i, "/.android/debug.keystore")

    & CFiles.Exist(ks, 0)
    END IsDebugKeystoreExist;
  BEGIN
    len := 0;

    ASSERT(Charz.Set(args.sdk, sdkDefault)
         & Charz.Set(args.platform, platformDefault)
         & Charz.Set(args.tools, toolsDefault));
    args.key := "";
    args.baseClasses := "";

    args.args.arg := arg + 1 + ORD(~run);
    args.args.script := TRUE;

    ok := (CLI.count >= args.args.arg)
        &
          CLI.Get(args.args.src, args.args.srcLen, arg)
        & (run OR CLI.Get(res, len, arg + 1))

        & AnOpt(args, args.args.arg)

        & (Cli.ErrNo = Cli.Options(args.args, args.args.arg));

    IF args.key = "" THEN
      ASSERT(Charz.Set(args.key, keyDefault)
           & Charz.Set(args.cert, certDefault))
    END;

    args.ksGen := ok & (args.key = "")
                & ~(IsDebugKeystoreExist(args.key) & Charz.Set(args.ksPass, "android"));
    IF ~ok OR (args.baseClasses # "") THEN
      ;
    ELSIF baseClassPathDefault # "" THEN
      ASSERT(Charz.Set(args.baseClasses, baseClassPathDefault))
    ELSE
      len := 0;
      ok := Copy(args.baseClasses, len, args.sdk)
          & Copy(args.baseClasses, len, "/platforms/android-")
          & Copy(args.baseClasses, len, args.platform)
          & Copy(args.baseClasses, len, "/android.jar")
    END;
    IF args.ksGen THEN
      ok := Charz.Set(args.key, "o7.keystore")
          & Charz.Set(args.ksPass, "oberon")
    END;
    IF args.activity.val = "" THEN
      args.activity := activityDefault
    END
  RETURN
    ok
  END PrepareCliArgs;

  PROCEDURE Build*(cmd: INTEGER; arg: INTEGER);
  VAR err, len: INTEGER;
      apk, res: ARRAY 1024 OF CHAR;
      listener: Listener;
      delTmp, ok: BOOLEAN;
  BEGIN
    ASSERT(cmd IN {CmdBuild, CmdRun, CmdOpen});

    ListenerInit(listener);
    IF ~PrepareCliArgs(listener, res, arg, cmd # CmdBuild) THEN
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
      ELSIF cmd # CmdBuild THEN
        ok := Android(listener, "oberon.apk")
            & (  (cmd = CmdRun) & RunApp(listener, "oberon.apk")
              OR (cmd = CmdOpen) & OpenApp("oberon.apk")
              )
      ELSIF res[0] = "/" THEN
        ok := Android(listener, res)
      ELSIF ~Dir.GetCurrent(apk, len) THEN
        Sn("Can not get current directory")
      ELSIF ~(Copy(apk, len, "/") & Copy(apk, len, res)) THEN
        Sn("Full path to result is too long")
      ELSE
        ok := Android(listener, apk)
      END;
      IF delTmp & ((cmd # CmdOpen) OR ~ok)
       & ~FileSys.RemoveDir(listener.args.tmp)
      THEN
        Sn("Error when deleting temporary directory")
      END
    END
  END Build;

  PROCEDURE Run*;
  BEGIN
    Build(CmdRun, 0)
  END Run;

  PROCEDURE Open*;
  BEGIN
    Build(CmdOpen, 0)
  END Open;

  PROCEDURE Apk*;
  BEGIN
    Build(CmdBuild, 0)
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
      Build(CmdRun, 1)
    ELSIF cmd = "open" THEN
      Build(CmdOpen, 1)
    ELSIF cmd = "build" THEN
      Build(CmdBuild, 1)
    ELSIF cmd = "install-tools" THEN
      InstallTools
    ELSE
      Sn("Unknown command. Run 'osa help' too see available commands")
    END
  END Go;

  PROCEDURE SetSdkDefault*(sdk: ARRAY OF CHAR);
  BEGIN
    ASSERT(Charz.Set(sdkDefault, sdk))
  END SetSdkDefault;

  PROCEDURE SetPlatformDefault*(pl: ARRAY OF CHAR);
  BEGIN
    ASSERT(Charz.Set(platformDefault, pl))
  END SetPlatformDefault;

  PROCEDURE SetToolsDefault*(tools: ARRAY OF CHAR);
  BEGIN
    ASSERT(Charz.Set(toolsDefault, tools))
  END SetToolsDefault;

  PROCEDURE SetKeyDefault*(key, cert: ARRAY OF CHAR);
  BEGIN
    keyDefault := key;
    certDefault := cert
  END SetKeyDefault;

  PROCEDURE SetActivityNameDefault*(value: ARRAY OF CHAR);
  BEGIN
    ASSERT(SetActivityName(activityDefault, value))
  END SetActivityNameDefault;

  PROCEDURE SetBaseClassPathDefault*(path: ARRAY OF CHAR);
  BEGIN
    baseClassPathDefault := path
  END SetBaseClassPathDefault;

  PROCEDURE SetJavacDefault*(javac: ARRAY OF CHAR);
  BEGIN
    javacDefault := javac
  END SetJavacDefault;

BEGIN
  sdkDefault := "/usr/lib/android-sdk";
  platformDefault := "9";
  toolsDefault := "debian";
  keyDefault := "";
  certDefault := "";
  SetActivityNameDefault("Activity");
  baseClassPathDefault := "";
  javacDefault := "javac -source 1.8 -target 1.8"
END AndroidBuild.

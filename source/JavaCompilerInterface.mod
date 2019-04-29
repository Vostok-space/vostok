(*  Wrapper for CLI of Java Compiler, based on CCompilerInterface
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
MODULE JavaCompilerInterface;

  IMPORT Exec := PlatformExec, Platform, V, Log;

  CONST
    Unknown*  = 0;
    Javac*    = 1;

  TYPE
    Compiler* = RECORD(V.Base)
      cmd: Exec.Code;
      id*: INTEGER;

      destDir, classPath: BOOLEAN
    END;

  PROCEDURE Set*(VAR c: Compiler; cmd: ARRAY OF CHAR): BOOLEAN;
  BEGIN
    V.Init(c);
    ASSERT(Exec.Init(c.cmd, ""));
    (* TODO *)
    c.id := Unknown;
    c.destDir := FALSE;
    c.classPath := FALSE
  RETURN
    Exec.AddClean(c.cmd, cmd)
  END Set;

  PROCEDURE Implicit*(VAR c: Compiler): BOOLEAN;
  RETURN Exec.AddClean(c.cmd, " -implicit:none")
  END Implicit;

  PROCEDURE Debug*(VAR c: Compiler): BOOLEAN;
  RETURN Exec.AddClean(c.cmd, " -g")
  END Debug;

  PROCEDURE Search*(VAR c: Compiler): BOOLEAN;

    PROCEDURE Test(VAR cc: Compiler; id: INTEGER; c, ver: ARRAY OF CHAR): BOOLEAN;
    VAR exec: Exec.Code; ok: BOOLEAN;
    BEGIN
      ok := Exec.Init(exec, c) & Exec.Add(exec, ver, 0)
          & (Platform.Java
          OR (Platform.Posix & Exec.AddClean(exec, " >/dev/null 2>/dev/null"))
          OR (Platform.Windows & Exec.AddClean(exec, ">NUL 2>NUL"))
            )
          & (Exec.Ok = Exec.Do(exec));
      Exec.Log(exec);
      IF ok THEN
        ASSERT(Exec.Init(cc.cmd, c));
        cc.id := id;
        cc.destDir := FALSE;
        cc.classPath := FALSE;
      END
    RETURN
      ok
    END Test;

  BEGIN
    V.Init(c)
  RETURN
    Test(c, Javac, "javac", "-version")
  END Search;

  PROCEDURE AddDestinationDir*(VAR c: Compiler; o: ARRAY OF CHAR): BOOLEAN;
  BEGIN
    ASSERT(~c.destDir);
    c.destDir := TRUE
  RETURN
    Exec.Add(c.cmd, "-d", 0)
  & Exec.Add(c.cmd, o, 0)
  END AddDestinationDir;

  PROCEDURE AddClassPath*(VAR c: Compiler; path: ARRAY OF CHAR; ofs: INTEGER)
                         : BOOLEAN;
  BEGIN
    ASSERT(~c.classPath);
    c.classPath := TRUE
  RETURN
    Exec.Add(c.cmd, "-cp", 0)
  & Exec.Add(c.cmd, path, ofs)
  END AddClassPath;

  PROCEDURE AddJava*(VAR c: Compiler; file: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
  RETURN
    Exec.Add(c.cmd, file, ofs)
  END AddJava;

  PROCEDURE AddOpt*(VAR c: Compiler; opt: ARRAY OF CHAR): BOOLEAN;
  RETURN
    Exec.Add(c.cmd, opt, 0)
  END AddOpt;

  PROCEDURE AddTargetVersion*(VAR c: Compiler; ver: INTEGER): BOOLEAN;
  VAR s: ARRAY 4 OF CHAR;
  BEGIN
    ASSERT((ver > 1) & (ver < 10));
    s := "1.0";
    s[2] := CHR(ORD("0") + ver)
  RETURN
    Exec.Add(c.cmd, "-source", 0) & Exec.Add(c.cmd, s, 0)
  & Exec.Add(c.cmd, "-target", 0) & Exec.Add(c.cmd, s, 0)
  END AddTargetVersion;

  PROCEDURE Do*(VAR c: Compiler): INTEGER;
  BEGIN
  (*
    Log.On;
    Exec.Log(c.cmd);
    Log.Off
  *)
  RETURN
    Exec.Do(c.cmd)
  END Do;

END JavaCompilerInterface.

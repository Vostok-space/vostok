(*  Wrapper for CLI of Java Compiler, based on CCompilerInterface
 *  Copyright (C) 2018-2019,2021-2022,2025 ComdivByZero
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

  IMPORT Exec := PlatformExec, Platform, V, Log := DLog;

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
    Exec.AddAsIs(c.cmd, cmd)
  END Set;

  PROCEDURE Implicit*(VAR c: Compiler): BOOLEAN;
  RETURN Exec.AddAsIs(c.cmd, " -implicit:none")
  END Implicit;

  PROCEDURE Debug*(VAR c: Compiler): BOOLEAN;
  RETURN Exec.AddAsIs(c.cmd, " -g")
  END Debug;

  PROCEDURE Search*(VAR c: Compiler): BOOLEAN;

    PROCEDURE Test(VAR cc: Compiler; id: INTEGER; c, ver: ARRAY OF CHAR): BOOLEAN;
    VAR exec: Exec.Code; ok: BOOLEAN;
    BEGIN
      ok := Exec.Init(exec, c) & Exec.Val(exec, ver)
          & (Platform.Java
          OR (Platform.Posix & Exec.AddAsIs(exec, " >/dev/null 2>/dev/null"))
          OR (Platform.Windows & Exec.AddAsIs(exec, ">NUL 2>NUL"))
            )
          & (Exec.Ok = Exec.Do(exec));
      Exec.Log(exec);
      IF ok THEN
        ASSERT(Exec.Init(cc.cmd, c) & Exec.AddAsIs(cc.cmd, " -Xlint:unchecked"));
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

  PROCEDURE DestinationDir*(VAR c: Compiler; o: ARRAY OF CHAR): BOOLEAN;
  BEGIN
    ASSERT(~c.destDir);
    c.destDir := TRUE
  RETURN
    Exec.Par(c.cmd, "-d", o)
  END DestinationDir;

  PROCEDURE ClassPath*(VAR c: Compiler; path: ARRAY OF CHAR; ofs: INTEGER) : BOOLEAN;
  BEGIN
    ASSERT(~c.classPath);
    c.classPath := TRUE
  RETURN
    Exec.Key(c.cmd, "-cp")
  & Exec.AddByOfs(c.cmd, path, ofs)
  END ClassPath;

  PROCEDURE Java*(VAR c: Compiler; file: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
  RETURN
    Exec.AddByOfs(c.cmd, file, ofs)
  END Java;

  PROCEDURE Opt*(VAR c: Compiler; opt: ARRAY OF CHAR): BOOLEAN;
  RETURN
    Exec.Key(c.cmd, opt)
  END Opt;

  PROCEDURE TargetVersion*(VAR c: Compiler; ver: INTEGER): BOOLEAN;
  VAR s: ARRAY 4 OF CHAR;
  BEGIN
    ASSERT((ver > 1) & (ver < 10));
    s := "1.0";
    s[2] := CHR(ORD("0") + ver)
  RETURN
    Exec.Par(c.cmd, "-source", s)
  & Exec.Par(c.cmd, "-target", s)
  END TargetVersion;

  PROCEDURE SourceEncodingUtf8*(VAR c: Compiler): BOOLEAN;
  RETURN
    Exec.AddAsIs(c.cmd, " -encoding UTF-8")
  END SourceEncodingUtf8;

  PROCEDURE Do*(VAR c: Compiler): INTEGER;
  RETURN
    Exec.Do(c.cmd)
  END Do;

END JavaCompilerInterface.

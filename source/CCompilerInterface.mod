(*  Wrapper for CLI of C Compilers
 *
 *  Copyright (C) 2018-2019,2021-2022 ComdivByZero
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
MODULE CCompilerInterface;

  IMPORT Exec := PlatformExec, Platform, V;

  CONST
    Unknown*  = 0;
    Tiny*     = 1;
    Gnu*      = 2;
    Clang*    = 3;
    CompCert* = 4;
    Msvc*     = 5;
    Zig*      = 6;

  TYPE
    Compiler* = RECORD(V.Base)
      cmd: Exec.Code;
      id*: INTEGER
    END;

  PROCEDURE Set*(VAR c: Compiler; cmd: ARRAY OF CHAR): BOOLEAN;
  BEGIN
    V.Init(c);
    ASSERT(Exec.Init(c.cmd, ""));
    (* TODO *)
    c.id := Unknown
  RETURN
    Exec.AddAsIs(c.cmd, cmd)
  END Set;

  PROCEDURE Search*(VAR c: Compiler; lightweight: BOOLEAN): BOOLEAN;

    PROCEDURE Test(VAR cc: Compiler; id: INTEGER; c, ver: ARRAY OF CHAR): BOOLEAN;
    VAR exec: Exec.Code; ok: BOOLEAN;
    BEGIN
      ok := Exec.Init(exec, c) & ((ver = "") OR Exec.Val(exec, ver))
          & ((Platform.Posix & Exec.AddAsIs(exec, " >/dev/null 2>/dev/null"))
          OR (Platform.Windows & Exec.AddAsIs(exec, ">NUL 2>NUL"))
            )
          & (Exec.Ok = Exec.Do(exec));
      IF ok THEN
        ASSERT(Exec.Init(cc.cmd, c));
        cc.id := id
      END
    RETURN
      ok
    END Test;

  BEGIN
    V.Init(c)
  RETURN
      lightweight
    & (
      Test(c, Tiny, "tcc",    "-dumpversion") & Exec.Keys(c.cmd, "-g", "-w")

   OR Test(c, Zig, "zig",     "version")
    & Exec.AddAsIs(c.cmd, " cc -g -w -UNDEBUG -DO7_DISABLE_ATTR_CONST=1")

   OR Test(c, Gnu, "gcc",     "-dumpversion") & Exec.Keys(c.cmd, "-g", "-w")
   OR Test(c, Clang, "clang", "-dumpversion") & Exec.Keys(c.cmd, "-g", "-w")
      )

   OR ~lightweight
    & (
      Test(c, Zig, "zig",     "version")
    & Exec.AddAsIs(c.cmd, " cc -g -UNDEBUG -DO7_DISABLE_ATTR_CONST=1 -O1")

   OR Test(c, Gnu, "gcc",     "-dumpversion") & Exec.Keys(c.cmd, "-g", "-O1")
   OR Test(c, Clang, "clang", "-dumpversion") & Exec.Keys(c.cmd, "-g", "-O1")
   OR Test(c, Tiny, "tcc",    "-dumpversion") & Exec.Key(c.cmd, "-g")
      )

   OR (
      Test(c, CompCert, "ccomp", "--version") & Exec.Keys(c.cmd, "-g", "-O")
   OR Test(c, Unknown, "cc",  "-dumpversion") & Exec.Keys(c.cmd, "-g", "-O1")
   OR Platform.Windows & Test(c, Msvc, "cl.exe",  "")
      ) & (~lightweight OR Exec.AddAsIs(c.cmd, " -w"))
  END Search;

  PROCEDURE OutputExe*(VAR c: Compiler; o: ARRAY OF CHAR): BOOLEAN;
  VAR ok: BOOLEAN;
  BEGIN
    IF c.id = Msvc THEN
      ok := Exec.AddAsIs(c.cmd, " -Fe")
          & Exec.AddQuote(c.cmd)
          & Exec.AddAsIs(c.cmd, o)
          & Exec.AddQuote(c.cmd)
    ELSE
      ok := Exec.Par(c.cmd, "-o", o)
    END
  RETURN
    ok
  END OutputExe;

  PROCEDURE Include*(VAR c: Compiler; path: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
  RETURN
    Exec.FirstPart(c.cmd, "-I")
  & Exec.LastPartByOfs(c.cmd, path, ofs)
  END Include;

  PROCEDURE Cfile*(VAR c: Compiler; file: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
  RETURN
    Exec.AddByOfs(c.cmd, file, ofs)
  END Cfile;

  PROCEDURE AddOptByOfs*(VAR c: Compiler; opt: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
  RETURN
    Exec.AddByOfs(c.cmd, opt, ofs)
  END AddOptByOfs;

  PROCEDURE AddOpt*(VAR c: Compiler; opt: ARRAY OF CHAR): BOOLEAN;
  RETURN
    AddOptByOfs(c, opt, 0)
  END AddOpt;

  PROCEDURE Do*(VAR c: Compiler): INTEGER;
  BEGIN
    Exec.Log(c.cmd)
  RETURN
    Exec.Do(c.cmd)
  END Do;

END CCompilerInterface.

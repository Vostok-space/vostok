(*  Wrapper for CLI of C Compilers
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
MODULE CCompilerInterface;

  IMPORT Exec := PlatformExec, Platform, V;

  CONST
    Unknown*  = 0;
    Tiny*     = 1;
    Gnu*      = 2;
    Clang*    = 3;
    CompCert* = 4;

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
    Exec.AddClean(c.cmd, cmd)
  END Set;

  PROCEDURE Search*(VAR c: Compiler; forRun: BOOLEAN): BOOLEAN;

    PROCEDURE Test(VAR cc: Compiler; id: INTEGER; c, ver: ARRAY OF CHAR): BOOLEAN;
    VAR exec: Exec.Code; ok: BOOLEAN;
    BEGIN
      ok := Exec.Init(exec, c) & ((ver = "") OR Exec.Add(exec, ver))
          & ((Platform.Posix & Exec.AddClean(exec, " >/dev/null 2>/dev/null"))
          OR (Platform.Windows & Exec.AddClean(exec, ">NUL 2>NUL"))
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
      forRun
    & Test(c, Tiny, "tcc",    "-dumpversion") & Exec.AddClean(c.cmd, " -g -w")

   OR (
      Test(c, Gnu, "gcc",     "-dumpversion") & Exec.AddClean(c.cmd, " -g -O1")
   OR Test(c, Clang, "clang", "-dumpversion") & Exec.AddClean(c.cmd, " -g -O1")

   OR ~forRun
    & Test(c, Tiny, "tcc",    "-dumpversion") & Exec.AddClean(c.cmd, " -g")

   OR Test(c, CompCert, "ccomp", "--version") & Exec.AddClean(c.cmd, " -g -O")

   OR Test(c, Unknown, "cc",  "-dumpversion") & Exec.AddClean(c.cmd, " -g -O1")
   OR Platform.Windows & Test(c, Unknown, "cl.exe",  "")
      ) & (~forRun OR Exec.AddClean(c.cmd, " -w"))
  END Search;

  PROCEDURE AddOutput*(VAR c: Compiler; o: ARRAY OF CHAR): BOOLEAN;
  RETURN
    Exec.Add(c.cmd, "-o")
  & Exec.Add(c.cmd, o)
  END AddOutput;

  PROCEDURE AddInclude*(VAR c: Compiler; path: ARRAY OF CHAR; ofs: INTEGER)
                       : BOOLEAN;
  RETURN
    Exec.Add(c.cmd, "-I")
  & Exec.AddByOfs(c.cmd, path, ofs)
  END AddInclude;

  PROCEDURE AddC*(VAR c: Compiler; file: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
  RETURN
    Exec.AddByOfs(c.cmd, file, ofs)
  END AddC;

  PROCEDURE AddOpt*(VAR c: Compiler; opt: ARRAY OF CHAR): BOOLEAN;
  RETURN
    Exec.AddByOfs(c.cmd, opt, 0)
  END AddOpt;

  PROCEDURE Do*(VAR c: Compiler): INTEGER;
  BEGIN
    Exec.Log(c.cmd)
  RETURN
    Exec.Do(c.cmd)
  END Do;

END CCompilerInterface.

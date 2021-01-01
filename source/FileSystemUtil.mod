(*  Utilities for work with file system
 *  Copyright (C) 2016-2019 ComdivByZero
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
MODULE FileSystemUtil;

  IMPORT Platform, Exec := PlatformExec, Files := CFiles, CDir;

  PROCEDURE MakeDir*(name: ARRAY OF CHAR): BOOLEAN;
  VAR cmd: Exec.Code;
  BEGIN
    IF Platform.Posix THEN
      ASSERT(Exec.Init(cmd, "mkdir")
           & Exec.Add(cmd, name)
           & (Platform.Java OR Exec.AddClean(cmd, " 2>/dev/null")))
    ELSE ASSERT(Platform.Windows);
      ASSERT(Exec.Init(cmd, "mkdir")
           & Exec.Add(cmd, name))
    END
    RETURN Exec.Do(cmd) = Exec.Ok
  END MakeDir;

  PROCEDURE RemoveDir*(name: ARRAY OF CHAR): BOOLEAN;
  VAR cmd: Exec.Code;
  BEGIN
    IF Platform.Posix THEN
      ASSERT(Exec.Init(cmd, "rm")
           & Exec.Add(cmd, "-r")
           & Exec.Add(cmd, name)
           & (Platform.Java OR Exec.AddClean(cmd, " 2>/dev/null")))
    ELSE ASSERT(Platform.Windows);
      ASSERT(Exec.Init(cmd, "rmdir")
           & Exec.AddClean(cmd, " /s/q")
           & Exec.Add(cmd, name))
    END
    RETURN Exec.Do(cmd) = Exec.Ok
  END RemoveDir;

  PROCEDURE ChangeDir*(name: ARRAY OF CHAR): BOOLEAN;
  BEGIN
    RETURN CDir.SetCurrent(name, 0)
  END ChangeDir;

  PROCEDURE Copy*(src, dest: ARRAY OF CHAR; dir: BOOLEAN): BOOLEAN;
  VAR cmd: Exec.Code;
  BEGIN
    IF Platform.Posix THEN
      ASSERT(Exec.Init(cmd, "cp")
           & (~dir OR Exec.Add(cmd, "-r"))
           & Exec.Add(cmd, src)
           & Exec.Add(cmd, dest))
    ELSE ASSERT(FALSE)
    END
    RETURN Exec.Do(cmd) = Exec.Ok
  END Copy;

  PROCEDURE CopyFile*(src, dest: ARRAY OF CHAR): BOOLEAN;
    RETURN Copy(src, dest, FALSE)
  END CopyFile;

  PROCEDURE CopyDir*(src, dest: ARRAY OF CHAR): BOOLEAN;
    RETURN Copy(src, dest, TRUE)
  END CopyDir;

  PROCEDURE RemoveFile*(src: ARRAY OF CHAR): BOOLEAN;
    RETURN Files.Remove(src, 0)
  END RemoveFile;

END FileSystemUtil.

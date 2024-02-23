(*  Utilities for work with file system
 *
 *  Copyright (C) 2016-2023 ComdivByZero
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

  IMPORT Platform, Exec := PlatformExec, Files := CFiles, CDir, WindowsDir, PosixDir, JavaDir, JsDir;

  PROCEDURE MakeDir*(name: ARRAY OF CHAR): BOOLEAN;
  VAR ok: BOOLEAN;
  BEGIN
    IF Platform.Java THEN
      ok := JavaDir.MkdirByCharz(name, 0)
    ELSIF Platform.JavaScript THEN
      ok := JsDir.MkdirByCharz(name, 0, 777H)
    ELSIF Platform.Posix THEN
      ok := PosixDir.Mkdir(name, 0, PosixDir.All * PosixDir.Rwx)
    ELSE
      ok := Platform.Windows & WindowsDir.Mkdir(name, 0)
    END
    RETURN ok
  END MakeDir;

  PROCEDURE RemoveDir*(name: ARRAY OF CHAR): BOOLEAN;
  VAR cmd: Exec.Code;
  BEGIN
    IF Platform.Posix THEN
      ASSERT(Exec.Init(cmd, "rm")
           & Exec.Key(cmd, "-r")
           & Exec.Val(cmd, name)
           & (Platform.Java OR Exec.AddAsIs(cmd, " 2>/dev/null")))
    ELSE ASSERT(Platform.Windows);
      ASSERT(Exec.Init(cmd, "rmdir")
           & Exec.Key(cmd, "/s/q")
           & Exec.Val(cmd, name))
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
           & (~dir OR Exec.Key(cmd, "-r"))
           & Exec.Vals(cmd, src, dest))
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

  PROCEDURE Rename*(src, dest: ARRAY OF CHAR): BOOLEAN;
    RETURN Files.Rename(src, 0, dest, 0)
  END Rename;

END FileSystemUtil.

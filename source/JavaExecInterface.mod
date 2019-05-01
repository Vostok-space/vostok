(*  Executor of Java classes
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
MODULE JavaExecInterface;

  IMPORT V, Exec := PlatformExec;

  PROCEDURE Init*(VAR e: Exec.Code);
  BEGIN
    ASSERT(Exec.Init(e, "java"))
  END Init;

  PROCEDURE AddClassPath*(VAR e: Exec.Code;
                          path: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
  RETURN
    Exec.Add(e, "-cp")
  & Exec.AddByOfs(e, path, ofs)
  END AddClassPath;

  PROCEDURE AddJar*(VAR e: Exec.Code; jar: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
  RETURN
    Exec.Add(e, "-jar")
  & Exec.AddByOfs(e, jar, ofs)
  END AddJar;

END JavaExecInterface.

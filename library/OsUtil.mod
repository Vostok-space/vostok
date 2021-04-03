(* Subroutines for work in OS like GNU/Linux or Windows
 * Copyright 2019-2021 ComdivByZero
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *)
MODULE OsUtil;

  IMPORT Platform, Unistd, Libloader := Wlibloaderapi;

  PROCEDURE PathToSelfExe*(VAR path: ARRAY OF CHAR; VAR len: INTEGER): BOOLEAN;
  VAR ok: BOOLEAN;

    PROCEDURE Posix(VAR path: ARRAY OF CHAR; VAR len: INTEGER): BOOLEAN;
    VAR l: INTEGER; ok: BOOLEAN;
    BEGIN
      l := Unistd.Readlink("/proc/self/exe", path);
      ok := l >= 0;
      IF ok THEN
        len := l;
        IF LEN(path) <= l THEN
          l := LEN(path) - 1;
          ok := FALSE
        END
      ELSE
        l := 0;
        len := 0
      END;
      path[l] := 0X
    RETURN
      ok
    END Posix;

    PROCEDURE Windows(VAR path: ARRAY OF CHAR; VAR len: INTEGER): BOOLEAN;
    BEGIN
      len := Libloader.GetModuleFileNameA(NIL, path);
    RETURN
      (0 < len) & (len < LEN(path))
    END Windows;

  BEGIN
    IF Platform.Posix THEN
      ok := Posix(path, len)
    ELSE ASSERT(Platform.Windows);
      ok := Windows(path, len)
    END
  RETURN
    ok
  END PathToSelfExe;

END OsUtil.

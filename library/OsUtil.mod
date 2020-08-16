(* Subroutines for work in OS like GNU/Linux or Windows
 * Copyright 2019, 2020 ComdivByZero
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

  IMPORT Platform, Unistd;

  PROCEDURE PathToSelfExe*(VAR path: ARRAY OF CHAR; VAR len: INTEGER): BOOLEAN;
  VAR l: INTEGER;
  BEGIN
    IF Platform.Posix THEN
      l := Unistd.Readlink("/proc/self/exe", path);
      IF l >= 0 THEN
        len := l
      ELSE
        len := 0
      END
    ELSE
      (* TODO *)
      ASSERT(FALSE)
    END
  RETURN
    l >= 0
  END PathToSelfExe;

END OsUtil.

(* Getting the base directory for temporary files
 *
 * Copyright 2021 ComdivByZero
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
MODULE DirForTemp;

  IMPORT Platform, OsEnv, Chars0X;

  PROCEDURE Get*(VAR val: ARRAY OF CHAR; VAR ofs: INTEGER): BOOLEAN;
  VAR ok: BOOLEAN; start: INTEGER;
  BEGIN
    IF Platform.Posix THEN
      start := ofs;
      IF OsEnv.Get(val, ofs, "TMPDIR") THEN
        ok := (start = ofs) OR Chars0X.CopyString(val, ofs, "/")
      ELSE
        ok := (start = ofs) & Chars0X.CopyString(val, ofs, "/tmp/")
      END
    ELSIF Platform.Windows THEN
      ok := OsEnv.Get(val, ofs, "TEMP") & Chars0X.CopyString(val, ofs, "\")
    ELSE
      (* TODO *)
      ASSERT(FALSE)
    END
  RETURN
    ok
  END Get;

END DirForTemp.

(* Bindings of some functions from unistd.h
 * Copyright 2019-2020 ComdivByZero
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
MODULE Unistd;

  IMPORT Platform;

  VAR
    pageSize*: INTEGER;

  PROCEDURE Len(str: ARRAY OF CHAR): INTEGER;
  VAR i: INTEGER;
  BEGIN
    i := 0;
    WHILE (i < LEN(str)) & (str[i] # 0X) DO
      INC(i)
    END
  RETURN
    i
  END Len;

  PROCEDURE Readlink*(pathname: ARRAY OF CHAR; VAR buf: ARRAY OF CHAR): INTEGER;
  BEGIN
    ASSERT(Platform.Posix);
    ASSERT(Len(pathname) < LEN(pathname));
  RETURN
    -1
  END Readlink;

  PROCEDURE Sysconf*(name: INTEGER): INTEGER;
  BEGIN
    ASSERT(Platform.Posix);
  RETURN
    -1
  END Sysconf;

END Unistd.

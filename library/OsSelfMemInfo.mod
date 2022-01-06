(* Memory size, used by an application. Implemented through /proc/self/statm
 *
 * Copyright 2020,2022 ComdivByZero
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

(* Данные об использованной памяти. Воплощена только для POSIX через /proc/self/statm *)
MODULE OsSelfMemInfo;

  IMPORT File := CFiles, Arithmetic := CheckIntArithmetic, Unistd, Out;

  PROCEDURE Parse(VAR val: INTEGER; s: ARRAY OF CHAR; len: INTEGER): BOOLEAN;
  VAR i: INTEGER;
  BEGIN
    i := 0;
    WHILE (i < len) & (s[i] # " ") DO
      INC(i)
    END;
    WHILE (i < len) & (s[i] = " ") DO
      INC(i)
    END;
    val := 0;
    WHILE (i < len)
        & ("0" <= s[i]) & (s[i] <= "9")
        & Arithmetic.Mul(val, val, 10) & Arithmetic.Add(val, val, ORD(s[i]) - ORD("0"))
    DO
      INC(i)
    END
  RETURN
    (i < len) & (s[i] = " ")
  END Parse;

  PROCEDURE Read*(VAR pagesCount, pageSize: INTEGER): BOOLEAN;
  VAR f: File.File; ok: BOOLEAN; data: ARRAY 64 OF CHAR; len: INTEGER;
  BEGIN
    f := File.Open("/proc/self/statm", 0, "rb");
    ok := f # NIL;
    IF ok THEN
      len := File.ReadChars(f, data, 0, LEN(data));
      File.Close(f);

      pageSize := Unistd.Sysconf(Unistd.pageSize);
      ok := Parse(pagesCount, data, len)

    END
  RETURN
    ok
  END Read;

  PROCEDURE Get*(): INTEGER;
  VAR kb, pageSize, count: INTEGER;
  BEGIN
    IF ~Read(count, pageSize)
    OR (pageSize MOD 1024 # 0)
    OR ~Arithmetic.Mul(kb, count, pageSize DIV 1024)
    THEN
      kb := -1
    END
  RETURN
    kb
  END Get;

END OsSelfMemInfo.

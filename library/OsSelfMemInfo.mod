(* Memory size, used by an application. Implemented through /proc/self/statm
 *
 * Copyright 2020,2022,2024 ComdivByZero
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

(* Данные об использованной программой памяти. Воплощена только для Linux через /proc/self/statm *)
MODULE OsSelfMemInfo;

  IMPORT File := CFiles, TypesLimits, Unistd;
  
  PROCEDURE Parse(VAR val: INTEGER; s: ARRAY OF CHAR): BOOLEAN;
  CONST Last = TypesLimits.IntegerMax MOD 10;
        Cut  = TypesLimits.IntegerMax DIV 10;
  VAR i: INTEGER;
  BEGIN
    i := 0;
    WHILE s[i] # " " DO INC(i) END;
    WHILE s[i] = " " DO INC(i) END;

    val := 0;
    WHILE ("0" <= s[i]) & (s[i] <= "9")
        & ((val < Cut)  OR  (val = Cut) & (ORD(s[i]) - ORD("0") <= Last))
    DO
      val := val * 10 + (ORD(s[i]) - ORD("0"));
      INC(i)
    END
  RETURN
    (s[i] = " ") & ("0" <= s[i - 1]) & (s[i - 1] <= "9")
  END Parse;

  PROCEDURE Read*(VAR pagesCount, pageSize: INTEGER): BOOLEAN;
  VAR f: File.File; ok: BOOLEAN; data: ARRAY 64 OF CHAR; len: INTEGER;
  BEGIN
    f := File.Open("/proc/self/statm", 0, "rb");
    ok := f # NIL;
    IF ok THEN
      len := File.ReadChars(f, data, 0, LEN(data) - 2);
      File.Close(f);
      data[len] := " ";
      data[len + 1] := 0X;
      ok := Parse(pagesCount, data);
      IF ok THEN
        pageSize := Unistd.Sysconf(Unistd.pageSize)
      END
    END
  RETURN
    ok
  END Read;

  PROCEDURE Get*(): INTEGER;
  VAR kb, pageSize, count: INTEGER;
  BEGIN
    IF Read(count, pageSize)
    & (pageSize MOD 400H = 0)
    & (count <= TypesLimits.IntegerMax DIV (pageSize DIV 400H))
    THEN
      kb := pageSize DIV 400H * count
    ELSE
      kb := -1
    END
  RETURN
    kb
  END Get;

END OsSelfMemInfo.

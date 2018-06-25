(* Copyright 2018 ComdivByZero
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

(* Модуль для работы с цепочками литер, имитирующих строки.
 * Конец строки определяется по концу массива или по положению 0-го символа с 
 * наименьшим индексом
 *)
MODULE Chars0X;

  IMPORT Out; 

  PROCEDURE Set0X*(VAR dest: ARRAY OF CHAR; ofs: INTEGER);
  BEGIN
    IF ofs < LEN(dest) THEN
      dest[ofs] := 0X
    END
  END Set0X;
  
  PROCEDURE CalcLen*(str: ARRAY OF CHAR): INTEGER;
  VAR i: INTEGER;
  BEGIN
    i := 0;
    WHILE (i < LEN(str)) & (str[i] # 0X) DO
      INC(i)
    END
  RETURN
    i
  END CalcLen;

  PROCEDURE Fill*(ch: CHAR; count: INTEGER;
                  VAR dest: ARRAY OF CHAR; VAR ofs: INTEGER): BOOLEAN;
  VAR ok: BOOLEAN;
      i, end: INTEGER;
  BEGIN
    ASSERT(ch # 0X);
    ASSERT((0 <= ofs) & (ofs <= LEN(dest)));

    ok := count <= LEN(dest) - ofs;
    IF ok THEN
      i := ofs;
      end := i + count;
      WHILE i < end DO
        dest[i] := ch;
        INC(i)
      END;
      ofs := i;
      Set0X(dest, ofs)
    ELSE
      dest[ofs] := 0X
    END;
  RETURN
    ok
  END Fill;
  
  PROCEDURE Copy*(src: ARRAY OF CHAR; VAR srcOfs: INTEGER;
                  null: BOOLEAN; len: INTEGER;
                  VAR dest: ARRAY OF CHAR; VAR destOfs: INTEGER)
                 : BOOLEAN;
  VAR ok: BOOLEAN;
      s, d, l: INTEGER;
  BEGIN
    ASSERT((0 <= srcOfs)  & (srcOfs  <= LEN(src)));
    ASSERT((0 <= destOfs) & (destOfs <= LEN(dest)));
    ASSERT(0 < len);

    s := srcOfs;
    d := destOfs;

    l := LEN(dest) - destOfs;
    IF (l < len) & ~null THEN
      ok := FALSE
    ELSE
      IF len < l THEN
        l := len
      END;
      IF LEN(src) - srcOfs < l THEN
        l := LEN(src) - srcOfs
      END;
    
      WHILE (0 < l) & (src[s] # 0X) DO
        dest[d] := src[s];
        INC(d);
        INC(s);
        DEC(l)
      END;

      ok := (s - len = srcOfs)
         OR null & ((s = LEN(src)) OR (src[s] = 0X)) 
    END;
    
    Set0X(dest, d);
    srcOfs  := s;
    destOfs := d;

    ASSERT((destOfs = LEN(dest)) OR (dest[destOfs] = 0X))
  RETURN
    ok
  END Copy;

END Chars0X.

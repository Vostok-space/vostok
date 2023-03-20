(* Legacy wrapper for Charz
 * Copyright 2023 ComdivByZero
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

MODULE Chars0X;

  IMPORT Charz;

  PROCEDURE CalcLen*(str: ARRAY OF CHAR; ofs: INTEGER): INTEGER;
  RETURN
    Charz.CalcLen(str, ofs)
  END CalcLen;

  PROCEDURE Fill*(ch: CHAR; count: INTEGER;
                  VAR dest: ARRAY OF CHAR; VAR ofs: INTEGER): BOOLEAN;
  RETURN
    Charz.Fill(ch, count, dest, ofs)
  END Fill;

  PROCEDURE CopyAtMost*(VAR dest: ARRAY OF CHAR; VAR destOfs: INTEGER;
                        src: ARRAY OF CHAR; VAR srcOfs: INTEGER;
                        atMost: INTEGER): BOOLEAN;
  RETURN
    Charz.CopyAtMost(dest, destOfs, src, srcOfs, atMost)
  END CopyAtMost;

  PROCEDURE Copy*(VAR dest: ARRAY OF CHAR; VAR destOfs: INTEGER;
                  src: ARRAY OF CHAR; VAR srcOfs: INTEGER)
                 : BOOLEAN;
  RETURN
    Charz.Copy(dest, destOfs, src, srcOfs)
  END Copy;

  PROCEDURE CopyChars*(VAR dest: ARRAY OF CHAR; VAR destOfs: INTEGER;
                       src: ARRAY OF CHAR; srcOfs, srcEnd: INTEGER): BOOLEAN;
  RETURN
    Charz.CopyChars(dest, destOfs, src, srcOfs, srcEnd)
  END CopyChars;

  PROCEDURE CopyCharsFromLoop*(VAR dest: ARRAY OF CHAR; VAR destOfs: INTEGER;
                               src: ARRAY OF CHAR; srcOfs, srcEnd: INTEGER): BOOLEAN;
  RETURN
    Charz.CopyCharsFromLoop(dest, destOfs, src, srcOfs, srcEnd)
  END CopyCharsFromLoop;

  PROCEDURE CopyCharsUntil*(VAR dest: ARRAY OF CHAR; VAR destOfs: INTEGER;
                            src: ARRAY OF CHAR; VAR srcOfs: INTEGER; until: CHAR): BOOLEAN;
  RETURN
    Charz.CopyCharsUntil(dest, destOfs, src, srcOfs, until)
  END CopyCharsUntil;

  PROCEDURE CopyString*(VAR dest: ARRAY OF CHAR; VAR ofs: INTEGER;
                        src: ARRAY OF CHAR): BOOLEAN;
  VAR i: INTEGER;
  BEGIN
    i := 0
  RETURN
    Copy(dest, ofs, src, i)
  END CopyString;

  PROCEDURE Set*(VAR dest: ARRAY OF CHAR; src: ARRAY OF CHAR): BOOLEAN;
  VAR i, j: INTEGER;
  BEGIN
    i := 0;
    j := 0;
  RETURN
    Copy(dest, i, src, j)
  END Set;

  PROCEDURE CopyChar*(VAR dest: ARRAY OF CHAR; VAR ofs: INTEGER;
                      ch: CHAR; n: INTEGER): BOOLEAN;
  RETURN
    Charz.CopyChar(dest, ofs, ch, n)
  END CopyChar;

  PROCEDURE PutChar*(VAR dest: ARRAY OF CHAR; VAR ofs: INTEGER;
                     ch: CHAR): BOOLEAN;
  RETURN
    CopyChar(dest, ofs, ch, 1)
  END PutChar;

  PROCEDURE SearchChar*(str: ARRAY OF CHAR; VAR pos: INTEGER; c: CHAR): BOOLEAN;
  RETURN
    Charz.SearchChar(str, pos, c)
  END SearchChar;

  PROCEDURE SearchCharLast*(str: ARRAY OF CHAR; VAR pos: INTEGER; c: CHAR): BOOLEAN;
  RETURN
    Charz.SearchCharLast(str, pos, c)
  END SearchCharLast;

  PROCEDURE Compare*(s1: ARRAY OF CHAR; ofs1: INTEGER; s2: ARRAY OF CHAR; ofs2: INTEGER): INTEGER;
  RETURN
    Charz.Compare(s1, ofs1, s2, ofs2)
  END Compare;

  PROCEDURE Trim*(VAR str: ARRAY OF CHAR; ofs: INTEGER): INTEGER;
  RETURN
    Charz.Trim(str, ofs)
  END Trim;

END Chars0X.

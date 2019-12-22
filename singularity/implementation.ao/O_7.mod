(* Definitions for support Oberon-O7 code translated into Active Oberon
 *
 * Copyright 2019 ComdivByZero
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
MODULE O_7;

IMPORT
  SYSTEM;

VAR
  ch*: ARRAY 100H, 2 OF CHAR;

  PROCEDURE Ord*(s: SET32): SIGNED32;
  BEGIN RETURN
    SYSTEM.VAL(INTEGER, s)
  END Ord;

  PROCEDURE Bti*(b: BOOLEAN): SIGNED32;
  VAR i: SIGNED32;
  BEGIN
    IF b THEN
      i := 1
    ELSE
      i := 0
    END;
  RETURN
    i
  END Bti;

  PROCEDURE InitCh;
  VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO LEN(ch) - 1 DO
      ch[i, 0] := CHR(i);
      ch[i, 1] := 0X
    END
  END InitCh;

BEGIN
  InitCh
END O_7.

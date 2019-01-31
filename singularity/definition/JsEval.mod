(* Copyright 2019 ComdivByZero
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
MODULE JsEval;

  TYPE Code* = POINTER TO RECORD END;

  VAR supported*: BOOLEAN;

  PROCEDURE New*(VAR c: Code): BOOLEAN;
  BEGIN
    ASSERT(supported);
    c := NIL;
  RETURN
    FALSE
  END New;

  PROCEDURE Add*(c: Code; codePart: ARRAY OF CHAR): BOOLEAN;
  BEGIN
    ASSERT(c # NIL)
  RETURN
    FALSE
  END Add;

  PROCEDURE AddBytes*(c: Code; codePart: ARRAY OF BYTE): BOOLEAN;
  BEGIN
    ASSERT(c # NIL)
  RETURN
    FALSE
  END AddBytes;

  PROCEDURE End*(c: Code; startCliArg: INTEGER);
  BEGIN
    ASSERT(c # NIL);
    ASSERT(startCliArg >= 0)
  END End;

  PROCEDURE Do*(c: Code): BOOLEAN;
  BEGIN
    ASSERT(c # NIL)
  RETURN
    FALSE
  END Do;

  PROCEDURE DoStr*(str: ARRAY OF CHAR): BOOLEAN;
  BEGIN
    ASSERT(supported);
    ASSERT(str[0] # 0X)
  RETURN
    FALSE
  END DoStr;

BEGIN
  supported := FALSE
END JsEval.

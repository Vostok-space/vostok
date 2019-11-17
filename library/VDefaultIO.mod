(* Default input and output
 *
 * Copyright (C) 2019 ComdivByZero
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
MODULE VDefaultIO;

  IMPORT Stream := VDataStream, Files := VFileStream;

  VAR
    in : Stream.PInOpener;
    out: Stream.POutOpener;

  PROCEDURE OpenIn*(): Stream.PIn;
  VAR s: Stream.PIn;
  BEGIN
    IF in = NIL THEN
      s := Files.in
    ELSE
      s := Stream.OpenIn(in^)
    END
  RETURN
    s
  END OpenIn;

  PROCEDURE OpenOut*(): Stream.POut;
  VAR s: Stream.POut;
  BEGIN
    IF out = NIL THEN
      s := Files.out
    ELSE
      s := Stream.OpenOut(out^)
    END
  RETURN
    s
  END OpenOut;

  PROCEDURE SetIn*(s: Stream.PInOpener);
  BEGIN
    in := s
  END SetIn;

  PROCEDURE SetOut*(s: Stream.POutOpener);
  BEGIN
    out := s
  END SetOut;

BEGIN
  in  := NIL;
  out := NIL
END VDefaultIO.

(* Copyright 2017-2018 ComdivByZero
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
MODULE OsRand;

 IMPORT File := CFiles, WindowsRand;

 CONST
   FileName* = "/dev/urandom";

 VAR
   file: File.File;
   init: BOOLEAN;

 PROCEDURE Open*(): BOOLEAN;
 BEGIN
   IF ~init THEN
     ASSERT(file = NIL);
     file := NIL; (*File.Open(FileName, 0, "rb");*)
     init := (file # NIL) OR WindowsRand.Open()
   END
   RETURN init
 END Open;

 PROCEDURE Close*;
 BEGIN
   IF ~init THEN
     ASSERT(file = NIL)
   ELSIF file # NIL THEN
     File.Close(file)
   ELSE
     WindowsRand.Close
   END;
   init := FALSE
 END Close;

 PROCEDURE Read*(VAR buf: ARRAY OF BYTE; VAR ofs: INTEGER; count: INTEGER): BOOLEAN;
 VAR ok: BOOLEAN;
 BEGIN
   IF file # NIL THEN
     ok := count = File.Read(file, buf, ofs, count)
   ELSE
     ok := init & WindowsRand.Read(buf, ofs, count);
     IF ok THEN
       ofs := ofs + count
     END
   END
 RETURN
   ok
 END Read;

 PROCEDURE Int*(VAR i: INTEGER): BOOLEAN;
 VAR buf: ARRAY 4 OF BYTE;
     ofs: INTEGER;
     ret: BOOLEAN;
 BEGIN
   ofs := 0;
   ret := Read(buf, ofs, LEN(buf));
   IF ret THEN
     i := (buf[0]
         + buf[1]       * 100H
         + buf[2]       * 10000H
         + buf[3] DIV 2 * 1000000H
          )
        * (buf[3] MOD 2 * 2 - 1)
   END
   RETURN ret
 END Int;

 PROCEDURE Real*(VAR r: REAL): BOOLEAN;
 VAR buf: ARRAY 7 OF BYTE;
     ofs: INTEGER;
     ret: BOOLEAN;
 BEGIN
   ofs := 0;
   ret := Read(buf, ofs, LEN(buf));
   IF ret THEN
     r := (
       FLT(buf[0]
         + buf[1]       * 100H
         + buf[2]       * 10000H
         + buf[3] DIV 8 * 1000000H)
     * 16777216.0
     + FLT(buf[4]
         + buf[5] * 100H
         + buf[6] * 10000H)
          ) / 9007199254740991.0;

     ASSERT((0.0 <= r) & (r <= 1.0))
   END
   RETURN ret
 END Real;

BEGIN
  file := NIL;
  init := FALSE
END OsRand.

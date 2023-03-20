(* Simple module for formatted output based on Oakwood guidelines
 *
 * Copyright 2017-2019,2021,2023 ComdivByZero
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
MODULE Out;

 IMPORT Stream := VDataStream, IO := VDefaultIO, Charz, Platform, IntToCharz, RealToCharz;

 VAR
   success: BOOLEAN;
   ln     : ARRAY 2 OF CHAR;
   lnOfs  : INTEGER;
   out    : Stream.POut;

 PROCEDURE Write(s: ARRAY OF CHAR; ofs, len: INTEGER);
 BEGIN
   success := len = Stream.WriteChars(out^, s, ofs, len)
 END Write;

 PROCEDURE String*(s: ARRAY OF CHAR);
 BEGIN
   Write(s, 0, Charz.CalcLen(s, 0))
 END String;

 PROCEDURE Char*(ch: CHAR);
 VAR s: ARRAY 1 OF CHAR;
 BEGIN
   s[0] := ch;
   Write(s, 0, 1)
 END Char;

 PROCEDURE Int*(x, n: INTEGER);
 VAR s: ARRAY 64 OF CHAR;
     i: INTEGER;
 BEGIN
   i := 0;
   ASSERT(IntToCharz.Dec(s, i, x, n));
   Write(s, 0, i)
 END Int;

 PROCEDURE Ln*;
 BEGIN
   Write(ln, lnOfs, LEN(ln) - lnOfs)
 END Ln;

 PROCEDURE Real*(x: REAL; n: INTEGER);
 VAR s: ARRAY 64 OF CHAR;
     i: INTEGER;
 BEGIN
   i := 0;
   ASSERT(RealToCharz.Exp(s, i, x, n));
   Write(s, 0, i)
 END Real;

 PROCEDURE LongReal*(x: REAL; n: INTEGER);
 BEGIN
   Real(x, n)
 END LongReal;

 PROCEDURE Open*;
 VAR o: Stream.POut;
 BEGIN
   o := IO.OpenOut();
   success := o # NIL;
   IF success THEN
     Stream.CloseOut(out);
     out := o
   END
 END Open;

BEGIN
   ln[0] := 0DX;
   ln[1] := 0AX;
   lnOfs := ORD(Platform.Posix);
   out   := IO.OpenOut()
END Out.

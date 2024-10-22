(* Copyright 2017-2019,2021-2022 ComdivByZero
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
MODULE Platform;

 CONST
   LittleEndian* = 1;
   BigEndian*    = 2;

 VAR
   Posix*,
   Linux*,
   Bsd*,
   Mingw*,
   Dos*,
   Windows*,
   Darwin*,

   Wasm*,
   Wasi*,

   C*,
   Java*,
   JavaScript*: BOOLEAN;

   (* Main or at least preferable integer endianness *)
   ByteOrder*: INTEGER;

BEGIN
  Posix      := FALSE;
  Linux      := FALSE;
  Bsd        := FALSE;
  Dos        := FALSE;
  Windows    := FALSE;
  Darwin     := FALSE;

  Wasm       := FALSE;
  Wasi       := FALSE;

  C          := FALSE;
  Java       := FALSE;
  JavaScript := FALSE;

  ByteOrder := LittleEndian
END Platform.

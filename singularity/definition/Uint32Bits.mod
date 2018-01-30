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
MODULE Uint32Bits;

 IMPORT U := Uint32;

 PROCEDURE And*(VAR and: U.Type; a1, a2: U.Type);
 BEGIN
   ASSERT(FALSE)
 END And;

 PROCEDURE Or*(VAR or: U.Type; a1, a2: U.Type);
 BEGIN
   ASSERT(FALSE)
 END Or;

 PROCEDURE Xor*(VAR xor: U.Type; a1, a2: U.Type);
 BEGIN
   ASSERT(FALSE)
 END Xor;

 PROCEDURE Not*(VAR not: U.Type; a: U.Type);
 BEGIN
   ASSERT(FALSE)
 END Not;

 PROCEDURE Shl*(VAR shl: U.Type; a: U.Type; shift: INTEGER);
 BEGIN
   ASSERT(0 <= shift);
   ASSERT(FALSE)
 END Shl;

 PROCEDURE Shr*(VAR shr: U.Type; a: U.Type; shift: INTEGER);
 BEGIN
   ASSERT(0 <= shift);
   ASSERT(FALSE)
 END Shr;

END Uint32Bits.

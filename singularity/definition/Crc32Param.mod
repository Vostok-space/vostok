Parameter for module Crc32

Copyright 2024 ComdivByZero

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

MODULE Crc32Param;

 CONST
  Poly*   = {5, 8, 9, 15, 19..31} - {22, 25, 28}; (* EDB88320 *)
  Init*   = {0..31};
  XorOut* = {0..31};

BEGIN
 ASSERT(ORD(Poly / {31}) = 6DB88320H)
END Crc32Param.

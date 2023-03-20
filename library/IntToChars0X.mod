Legacy wrapper for IntToCharz

Copyright 2023 ComdivByZero

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

MODULE IntToChars0X;

  IMPORT IntToCharz;

  PROCEDURE DecCount*(i: INTEGER): INTEGER;
  RETURN
    IntToCharz.DecCount(i)
  END DecCount;

  PROCEDURE HexCount*(i: INTEGER): INTEGER;
  RETURN
    IntToCharz.HexCount(i)
  END HexCount;

  PROCEDURE Dec*(VAR str: ARRAY OF CHAR; VAR ofs: INTEGER; value, n: INTEGER): BOOLEAN;
  RETURN
    IntToCharz.Dec(str, ofs, value, n)
  END Dec;

  PROCEDURE Hex*(VAR str: ARRAY OF CHAR; VAR ofs: INTEGER; value, n: INTEGER): BOOLEAN;
  RETURN
    IntToCharz.Hex(str, ofs, value, n)
  END Hex;

END IntToChars0X.

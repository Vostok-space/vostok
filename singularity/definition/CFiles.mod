(* Copyright 2016 ComdivByZero
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
MODULE CFiles;

TYPE
	File* = POINTER TO RECORD
	END;

PROCEDURE Open*(name: ARRAY OF CHAR; ofs: INTEGER; mode: ARRAY OF CHAR): File;
	RETURN NIL
END Open;

PROCEDURE Close*(VAR file: File);
BEGIN
	file := NIL
END Close;

PROCEDURE Read*(file: File; VAR buf: ARRAY OF CHAR; ofs, count: INTEGER): INTEGER;
	RETURN 0
END Read;

PROCEDURE Write*(file: File; buf: ARRAY OF CHAR; ofs, count: INTEGER): INTEGER;
	RETURN 0
END Write;

(* полная позиция = gibi * 1024^3 + ofs; 0 <= pos < 1024^3 *)
PROCEDURE Seek*(file: File; gibi, ofs: INTEGER): BOOLEAN;
	RETURN FALSE
END Seek;

PROCEDURE Remove*(name: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
	RETURN FALSE
END Remove;

END CFiles.

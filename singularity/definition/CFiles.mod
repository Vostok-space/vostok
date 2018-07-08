(* Copyright 2016-2017 ComdivByZero
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

CONST
	KiB* = 1024;
	MiB* = 1024 * KiB;
	GiB* = 1024 * MiB;

TYPE
	File* = POINTER TO RECORD
	END;

VAR
	in*, out*, err*: File;

PROCEDURE Open*(name: ARRAY OF CHAR; ofs: INTEGER; mode: ARRAY OF CHAR): File;
	RETURN NIL
END Open;

PROCEDURE Close*(VAR file: File);
BEGIN
	file := NIL
END Close;

PROCEDURE Read*(file: File; VAR buf: ARRAY OF BYTE; ofs, count: INTEGER): INTEGER;
	RETURN 0
END Read;

PROCEDURE Write*(file: File; buf: ARRAY OF BYTE; ofs, count: INTEGER): INTEGER;
	RETURN 0
END Write;

PROCEDURE ReadChars*(file: File; VAR buf: ARRAY OF CHAR; ofs, count: INTEGER): INTEGER;
	RETURN 0
END ReadChars;

PROCEDURE WriteChars*(file: File; buf: ARRAY OF CHAR; ofs, count: INTEGER): INTEGER;
	RETURN 0
END WriteChars;

PROCEDURE Flush*(file: File): BOOLEAN;
	RETURN FALSE
END Flush;

(* полная позиция = gibs * GiB + bytes; 0 <= bytes < GiB *)
PROCEDURE Seek*(file: File; gibs, bytes: INTEGER): BOOLEAN;
	RETURN FALSE
END Seek;

PROCEDURE Tell*(file: File; VAR gibs, bytes: INTEGER): BOOLEAN;
	RETURN FALSE
END Tell;

PROCEDURE Remove*(name: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
	RETURN FALSE
END Remove;

PROCEDURE Exist*(name: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
	RETURN FALSE
END Exist;

BEGIN
	in  := NIL;
	out := NIL;
	err := NIL
END CFiles.

(* Implementations of Data Stream interfaces by CFiles
 *
 * Copyright (C) 2016, 2019 ComdivByZero
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
MODULE VFileStream;

IMPORT
	V,
	Stream := VDataStream,
	CFiles;

TYPE
	In* = POINTER TO RIn;
	RIn = RECORD(Stream.In)
		file: CFiles.File
	END;

	Out* = POINTER TO ROut;
	ROut = RECORD(Stream.Out)
		file: CFiles.File
	END;

VAR
	out*: Out;
	in* : In;

PROCEDURE Read(VAR i: V.Base; VAR buf: ARRAY OF BYTE; ofs, count: INTEGER): INTEGER;
	RETURN CFiles.Read(i(RIn).file, buf, ofs, count)
END Read;

PROCEDURE ReadChars(VAR i: V.Base; VAR buf: ARRAY OF CHAR; ofs, count: INTEGER): INTEGER;
	RETURN CFiles.ReadChars(i(RIn).file, buf, ofs, count)
END ReadChars;

PROCEDURE CloseRIn(VAR i: V.Base);
BEGIN
	CFiles.Close(i(RIn).file)
END CloseRIn;

PROCEDURE OpenIn*(name: ARRAY OF CHAR): In;
VAR i: In;
	file: CFiles.File;
BEGIN
	NEW(i);
	IF i # NIL THEN
		file := CFiles.Open(name, 0, "rb");
		IF file = NIL THEN
			i := NIL
		ELSE
			Stream.InitIn(i^, Read, ReadChars, CloseRIn);
			i.file := file
		END
	END
	RETURN i
END OpenIn;

PROCEDURE CloseIn*(VAR i: In);
BEGIN
	IF i # NIL THEN
		CFiles.Close(i.file);
		i := NIL
	END
END CloseIn;

PROCEDURE Write(VAR o: V.Base; buf: ARRAY OF BYTE; ofs, count: INTEGER): INTEGER;
	RETURN CFiles.Write(o(ROut).file, buf, ofs, count)
END Write;

PROCEDURE WriteChars(VAR o: V.Base; buf: ARRAY OF CHAR; ofs, count: INTEGER): INTEGER;
	RETURN CFiles.WriteChars(o(ROut).file, buf, ofs, count)
END WriteChars;

PROCEDURE CloseROut(VAR o: V.Base);
BEGIN
	CFiles.Close(o(ROut).file)
END CloseROut;

PROCEDURE OpenOut*(name: ARRAY OF CHAR): Out;
VAR o: Out; file: CFiles.File;
BEGIN
	NEW(o);
	IF o # NIL THEN
		file := CFiles.Open(name, 0, "wb");
		IF file = NIL THEN
			o := NIL
		ELSE
			Stream.InitOut(o^, Write, WriteChars, CloseROut);
			o.file := file
		END
	END
	RETURN o
END OpenOut;

PROCEDURE CloseOut*(VAR o: Out);
BEGIN
	IF o # NIL THEN
		CFiles.Close(o.file);
		o := NIL
	END
END CloseOut;

PROCEDURE WrapOut;
BEGIN
	NEW(out);
	IF out # NIL THEN
		Stream.InitOut(out^, Write, WriteChars, NIL);
		out.file := CFiles.out;
	END
END WrapOut;

PROCEDURE WrapIn;
BEGIN
	NEW(in);
	IF in # NIL THEN
		Stream.InitIn(in^, Read, ReadChars, NIL);
		in.file := CFiles.in;
	END
END WrapIn;

BEGIN
	WrapOut;
	WrapIn
END VFileStream.

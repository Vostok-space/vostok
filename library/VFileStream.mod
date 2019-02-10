(*  Implementations of Data Stream interfaces by CFiles
 *  Copyright (C) 2016, 2019 ComdivByZero
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

PROCEDURE Read(VAR in: V.Base; VAR buf: ARRAY OF BYTE; ofs, count: INTEGER): INTEGER;
	RETURN CFiles.Read(in(RIn).file, buf, ofs, count)
END Read;

PROCEDURE ReadChars(VAR in: V.Base; VAR buf: ARRAY OF CHAR; ofs, count: INTEGER): INTEGER;
	RETURN CFiles.ReadChars(in(RIn).file, buf, ofs, count)
END ReadChars;

PROCEDURE CloseRIn(VAR in: V.Base);
BEGIN
	CFiles.Close(in(RIn).file)
END CloseRIn;

PROCEDURE OpenIn*(name: ARRAY OF CHAR): In;
VAR in: In;
	file: CFiles.File;
BEGIN
	NEW(in);
	IF in # NIL THEN
		file := CFiles.Open(name, 0, "rb");
		IF file = NIL THEN
			in := NIL
		ELSE
			Stream.InitIn(in^, Read, ReadChars, CloseRIn);
			in.file := file
		END
	END
	RETURN in
END OpenIn;

PROCEDURE CloseIn*(VAR in: In);
BEGIN
	IF in # NIL THEN
		CFiles.Close(in.file);
		in := NIL
	END
END CloseIn;

PROCEDURE Write(VAR out: V.Base; buf: ARRAY OF BYTE; ofs, count: INTEGER): INTEGER;
	RETURN CFiles.Write(out(ROut).file, buf, ofs, count)
END Write;

PROCEDURE WriteChars(VAR out: V.Base; buf: ARRAY OF CHAR; ofs, count: INTEGER): INTEGER;
	RETURN CFiles.WriteChars(out(ROut).file, buf, ofs, count)
END WriteChars;

PROCEDURE CloseROut(VAR out: V.Base);
BEGIN
	CFiles.Close(out(ROut).file)
END CloseROut;

PROCEDURE OpenOut*(name: ARRAY OF CHAR): Out;
VAR out: Out;
	file: CFiles.File;
BEGIN
	NEW(out);
	IF out # NIL THEN
		file := CFiles.Open(name, 0, "wb");
		IF file = NIL THEN
			out := NIL
		ELSE
			Stream.InitOut(out^, Write, WriteChars, CloseROut);
			out.file := file
		END
	END
	RETURN out
END OpenOut;

PROCEDURE CloseOut*(VAR out: Out);
BEGIN
	IF out # NIL THEN
		CFiles.Close(out.file);
		out := NIL
	END
END CloseOut;

END VFileStream.

(*  Implementations of VDataStream interfaces by CFiles
 *  Copyright (C) 2016  ComdivByZero
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)
MODULE VFileStream;

IMPORT
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

PROCEDURE Read(VAR in: Stream.In; VAR buf: ARRAY OF CHAR; ofs, count: INTEGER): INTEGER;
	RETURN CFiles.Read(in(RIn).file, buf, ofs, count)
END Read;

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
			Stream.InitIn(in^, Read);
			in.file := file
		END
	END
	RETURN in
END OpenIn;

PROCEDURE CloseIn*(VAR in: In);
BEGIN
	CFiles.Close(in.file);
	in := NIL
END CloseIn;

PROCEDURE Write(VAR out: Stream.Out; buf: ARRAY OF CHAR; ofs, count: INTEGER): INTEGER;
	RETURN CFiles.Write(out(ROut).file, buf, ofs, count)
END Write;

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
			Stream.InitOut(out^, Write);
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

(*  Abstract interfaces for data input and output
 *  Copyright (C) 2016-2019 ComdivByZero
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
MODULE VDataStream;

IMPORT V;

TYPE
	Stream* = POINTER TO RStream;
	RStream* = RECORD(V.Base)
		close: PROCEDURE(VAR stream: V.Base)
	END;

	PIn* = POINTER TO In;
	In* = RECORD(RStream)
		read: PROCEDURE(VAR in: V.Base; VAR buf: ARRAY OF BYTE;
		                ofs, count: INTEGER): INTEGER;
		readChars: PROCEDURE(VAR in: V.Base; VAR buf: ARRAY OF CHAR;
		                     ofs, count: INTEGER): INTEGER
	END;

	PInOpener* = POINTER TO InOpener;
	InOpener* = RECORD(V.Base)
		open: PROCEDURE(VAR opener: V.Base): PIn
	END;

	(* Запись Out также служит сообщением для отладочного вывода*)
	POut* = POINTER TO Out;
	Out* = RECORD(RStream)
		write: PROCEDURE(VAR out: V.Base;
		                 buf: ARRAY OF BYTE; ofs, count: INTEGER): INTEGER;
		writeChars: PROCEDURE(VAR out: V.Base;
		                      buf: ARRAY OF CHAR; ofs, count: INTEGER): INTEGER
	END;

	POutOpener* = POINTER TO OutOpener;
	OutOpener* = RECORD(V.Base)
		open: PROCEDURE(VAR opener: V.Base): POut
	END;

	ReadProc*  = PROCEDURE(VAR in: V.Base;
	                       VAR buf: ARRAY OF BYTE; ofs, count: INTEGER): INTEGER;
	ReadCharsProc* = PROCEDURE(VAR in: V.Base;
	                           VAR buf: ARRAY OF CHAR; ofs, count: INTEGER): INTEGER;
	WriteProc* = PROCEDURE(VAR out: V.Base;
	                       buf: ARRAY OF BYTE; ofs, count: INTEGER): INTEGER;
	WriteCharsProc* = PROCEDURE(VAR out: V.Base;
	                            buf: ARRAY OF CHAR; ofs, count: INTEGER): INTEGER;

	OpenIn*      = PROCEDURE(VAR opener: V.Base): PIn;
	OpenOut*     = PROCEDURE(VAR opener: V.Base): POut;
	CloseStream* = PROCEDURE(VAR stream: V.Base);

PROCEDURE EmptyClose(VAR stream: V.Base);
BEGIN
	ASSERT(stream IS RStream)
END EmptyClose;

PROCEDURE Init(VAR stream: RStream; close: CloseStream);
BEGIN
	V.Init(stream);
	IF close = NIL THEN
		stream.close := EmptyClose
	ELSE
		stream.close := close
	END
END Init;

PROCEDURE Close*(stream: Stream);
BEGIN
	IF stream # NIL THEN
		stream.close(stream^);
	END
END Close;

PROCEDURE InitIn*(VAR in: In;
                  read: ReadProc; readChars: ReadCharsProc; close: CloseStream);
BEGIN
	Init(in, close);
	in.read := read;
	in.readChars := readChars
END InitIn;

PROCEDURE CloseIn*(VAR in: PIn);
BEGIN
	IF in # NIL THEN
		in.close(in^);
		in := NIL
	END
END CloseIn;

PROCEDURE Read*(VAR in: In; VAR buf: ARRAY OF BYTE; ofs, count: INTEGER): INTEGER;
VAR r: INTEGER;
BEGIN
	ASSERT((0 <= ofs) & (0 <= count) & (ofs <= LEN(buf) - count));
	r := in.read(in, buf, ofs, count);
	ASSERT((0 <= r) & (r <= count))
	RETURN r
END Read;

PROCEDURE ReadChars*(VAR in: In; VAR buf: ARRAY OF CHAR; ofs, count: INTEGER): INTEGER;
VAR r: INTEGER;
BEGIN
	ASSERT((0 <= ofs) & (0 <= count) & (ofs <= LEN(buf) - count));
	r := in.readChars(in, buf, ofs, count);
	ASSERT((0 <= r) & (r <= count))
	RETURN r
END ReadChars;

PROCEDURE InitOut*(VAR out: Out;
                   write: WriteProc; writeChars: WriteCharsProc; close: CloseStream);
BEGIN
	Init(out, close);
	out.write := write;
	out.writeChars := writeChars
END InitOut;

PROCEDURE CloseOut*(VAR out: POut);
BEGIN
	IF out # NIL THEN
		out.close(out^);
		out := NIL
	END
END CloseOut;

PROCEDURE Write*(VAR out: Out; buf: ARRAY OF BYTE; ofs, count: INTEGER): INTEGER;
VAR w: INTEGER;
BEGIN
	ASSERT((0 <= ofs) & (0 <= count) & (ofs <= LEN(buf) - count));
	w := out.write(out, buf, ofs, count);
	ASSERT((0 <= w) & (w <= count))
	RETURN w
END Write;

PROCEDURE WriteChars*(VAR out: Out; buf: ARRAY OF CHAR; ofs, count: INTEGER): INTEGER;
VAR w: INTEGER;
BEGIN
	ASSERT((0 <= ofs) & (0 <= count) & (ofs <= LEN(buf) - count));
	w := out.writeChars(out, buf, ofs, count);
	ASSERT((0 <= w) & (w <= count))
	RETURN w
END WriteChars;

PROCEDURE InitInOpener*(VAR opener: InOpener; open: OpenIn);
BEGIN
	V.Init(opener);
	opener.open := open
END InitInOpener;

PROCEDURE InitOutOpener*(VAR opener: OutOpener; open: OpenOut);
BEGIN
	V.Init(opener);
	opener.open := open
END InitOutOpener;

END VDataStream.

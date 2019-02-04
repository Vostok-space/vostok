(*  Abstract interfaces for data input and output
 *  Copyright (C) 2016-2019 ComdivByZero
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published
 *  by the Free Software Foundation, either version 3 of the License, or
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

(*  Abstract interfaces for data input and output
 *  Copyright (C) 2016-2017 ComdivByZero
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
MODULE VDataStream;

IMPORT V;

TYPE
	PIn* = POINTER TO In;
	In* = RECORD(V.Base)
		read: PROCEDURE(VAR in: In; VAR buf: ARRAY OF BYTE;
		                ofs, count: INTEGER): INTEGER;
		readChars: PROCEDURE(VAR in: In; VAR buf: ARRAY OF CHAR;
		                     ofs, count: INTEGER): INTEGER
	END;

	POut* = POINTER TO Out;
	Out* = RECORD(V.Base)
		write: PROCEDURE(VAR out: Out;
		                 buf: ARRAY OF BYTE; ofs, count: INTEGER): INTEGER;
		writeChars: PROCEDURE(VAR out: Out;
		                      buf: ARRAY OF CHAR; ofs, count: INTEGER): INTEGER
	END;
	(* Запись Out также служит сообщением для отладочного вывода*)

	ReadProc*  = PROCEDURE(VAR in: In;
	                       VAR buf: ARRAY OF BYTE; ofs, count: INTEGER): INTEGER;
	ReadCharsProc* = PROCEDURE(VAR in: In;
	                           VAR buf: ARRAY OF CHAR; ofs, count: INTEGER): INTEGER;
	WriteProc* = PROCEDURE(VAR out: Out;
	                       buf: ARRAY OF BYTE; ofs, count: INTEGER): INTEGER;
	WriteCharsProc* = PROCEDURE(VAR out: Out;
	                            buf: ARRAY OF CHAR; ofs, count: INTEGER): INTEGER;

PROCEDURE InitIn*(VAR in: In; read: ReadProc; readChars: ReadCharsProc);
BEGIN
	V.Init(in);
	in.read := read;
	in.readChars := readChars
END InitIn;

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

PROCEDURE InitOut*(VAR out: Out; write: WriteProc; writeChars: WriteCharsProc);
BEGIN
	V.Init(out);
	out.write := write;
	out.writeChars := writeChars
END InitOut;

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

END VDataStream.

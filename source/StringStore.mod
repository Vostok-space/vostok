(*  Strings storage
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
MODULE StringStore;

IMPORT
	Log,
	Utf8,
	V,
	Stream := VDataStream;

CONST
	BlockSize = 256;

TYPE
	Block* = POINTER TO RECORD(V.Base)
		s*: ARRAY BlockSize + 1 OF CHAR;
		next*: Block;
		num: INTEGER
	END;

	String* = RECORD(V.Base)
		block*: Block;
		ofs*: INTEGER
	END;

	Store* = RECORD(V.Base)
		first, last: Block;
		ofs: INTEGER
	END;

PROCEDURE LogLoopStr(s: ARRAY OF CHAR; j, end: INTEGER);
BEGIN
	WHILE j # end DO
		Log.Char(s[j]);
		j := (j + 1) MOD (LEN(s) - 1)
	END 
END LogLoopStr;

PROCEDURE Put*(VAR store: Store; VAR w: String;
			   s: ARRAY OF CHAR; j, end: INTEGER);
VAR
	b: Block;
	i: INTEGER;

	PROCEDURE AddBlock(VAR b: Block; VAR i: INTEGER);
	BEGIN
		ASSERT(b.next = NIL);
		i := 0;
		NEW(b.next); V.Init(b.next^);
		b.next.num := b.num + 1;
		b := b.next;
		b.next := NIL
	END AddBlock;
BEGIN
	ASSERT(ODD(LEN(s)));
	ASSERT((j >= 0) & (j < LEN(s) - 1));
	ASSERT((end >= 0) & (end < LEN(s) - 1));
	b := store.last;
	i := store.ofs;
	w.block := b;
	w.ofs := i;
	
	(*Log.Str("Put "); Log.Int(b.num); Log.Str(":"); Log.Int(i); Log.Ln;*)
	WHILE j # end DO
		IF i = LEN(b.s) - 1 THEN
			ASSERT(i # w.ofs);
			b.s[i] := Utf8.NewPage;
			AddBlock(b, i)
		END;
		b.s[i] := s[j];
		ASSERT(s[j] # Utf8.NewPage);
		INC(i);
		j := (j + 1) MOD (LEN(s) - 1)
	END;
	b.s[i] := Utf8.Null;
	IF i < LEN(b.s) - 2 THEN
		INC(i)
	ELSE
		AddBlock(b, i)
	END;
	store.last := b;
	store.ofs := i
END Put;

PROCEDURE IsEqualToChars*(w: String; s: ARRAY OF CHAR; j, end: INTEGER): BOOLEAN;
VAR i: INTEGER;
	b: Block;
BEGIN
	ASSERT(ODD(LEN(s)));
	ASSERT((j >= 0) & (j < LEN(s) - 1));
	ASSERT((end >= 0) & (end < LEN(s) - 1));
	i := w.ofs;
	b := w.block;
	WHILE b.s[i] = s[j] DO
		INC(i);
		j := (j + 1) MOD (LEN(s) - 1)
	ELSIF b.s[i] = Utf8.NewPage DO
		b := b.next;
		i := 0
	END
	(*Log.Int(ORD(b.s[i])); Log.Ln;
	Log.Int(j); Log.Ln;
	Log.Int(end); Log.Ln;*)
	RETURN (b.s[i] = Utf8.Null) & (j = end)
END IsEqualToChars;

PROCEDURE IsEqualToString*(w: String; s: ARRAY OF CHAR): BOOLEAN;
VAR i, j: INTEGER;
	b: Block;
BEGIN
	j := 0;
	i := w.ofs;
	b := w.block;
	WHILE (b.s[i] = s[j]) & (s[j] # Utf8.Null) DO
		(*Log.Char(b.s[i]); Log.Char(s[j]);*)
		INC(i);
		INC(j)
	ELSIF b.s[i] = Utf8.NewPage DO
		b := b.next;
		i := 0
	END
	(*Log.Int(ORD(b.s[i])); Log.Ln;
	Log.Int(j); Log.Ln*)
	RETURN b.s[i] = s[j]
END IsEqualToString;

PROCEDURE CopyToChars*(VAR d: ARRAY OF CHAR; VAR dofs: INTEGER; w: String);
VAR b: Block;
	i: INTEGER;
BEGIN
	b := w.block;
	i := w.ofs;
	WHILE b.s[i] > Utf8.NewPage DO
		d[dofs] := b.s[i];
		INC(dofs); INC(i)
	ELSIF b.s[i] # 0X DO
		ASSERT(b.s[i] = Utf8.NewPage);
		b := b.next;
		i := 0
	END;
	d[dofs] := 0X
END CopyToChars;

PROCEDURE StoreInit*(VAR s: Store);
BEGIN
	V.Init(s);
	NEW(s.first); V.Init(s.first^);
	s.first.num := 0;
	s.last := s.first;
	s.last.next := NIL;
	s.ofs := 0
END StoreInit;

PROCEDURE StoreDone*(VAR s: Store);
BEGIN
	WHILE s.first # NIL DO
		s.first := s.first.next
	END;
	s.last := NIL
END StoreDone;


PROCEDURE CopyChars*(VAR dest: ARRAY OF CHAR; VAR destOfs: INTEGER;
					 src: ARRAY OF CHAR; srcOfs, srcEnd: INTEGER): BOOLEAN;
VAR ret: BOOLEAN; 
BEGIN
	(*
	Log.Str("CopyChars: "); Log.Int(destOfs);
	Log.Str(", "); Log.Int(srcOfs);
	Log.Str(", "); Log.Int(srcEnd);
	Log.Str(" "); Log.StrLn(src);
	*)
	ASSERT((destOfs >= 0)
		 & (srcOfs >= 0) & (srcEnd >= srcOfs)
		 & (srcEnd <= LEN(src)));

	ret := destOfs + srcEnd - srcOfs < LEN(dest) - 1;
	IF ret THEN
		WHILE srcOfs < srcEnd DO
			dest[destOfs] := src[srcOfs];
			INC(destOfs);
			INC(srcOfs)
		END
	END;
	dest[destOfs] := Utf8.Null
	RETURN ret
END CopyChars;

(*	копирование содержимого строки, не включая завершающего 0 в поток вывода
	TODO учесть возможность ошибки при записи *)
PROCEDURE Write*(VAR out: Stream.Out; str: String): INTEGER;
VAR i, len: INTEGER;
	block: Block;
BEGIN
	block := str.block;
	i := str.ofs;
	len := 0;
	WHILE block.s[i] > Utf8.NewPage DO
		INC(i)
	ELSIF block.s[i] = Utf8.NewPage DO
		ASSERT(len = 0);
		ASSERT(i > str.ofs);
		len := len + Stream.Write(out, block.s, str.ofs, i - str.ofs);
		block := block.next;
		i := 0
	END;
	ASSERT(block.s[i] = Utf8.Null);
	IF len = 0 THEN
		len := Stream.Write(out, block.s, str.ofs, i - str.ofs)
	ELSE
		len := len + Stream.Write(out, block.s, 0, i)
	END
	RETURN len
END Write;

END StringStore.

(*  Strings storage
 *  Copyright (C) 2016-2021 ComdivByZero
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
MODULE StringStore;

IMPORT
	Log := DLog,
	Utf8,
	V,
	Stream := VDataStream;

CONST
	BlockSize = 256;

TYPE
	Block* = POINTER TO RBlock;
	RBlock = RECORD(V.Base)
		s*: ARRAY BlockSize + 1 OF CHAR;
		next*: Block;
		num: INTEGER
	END;

	String* = RECORD(V.Base)
		block*: Block;
		ofs*: INTEGER
	END;

	Iter = RECORD(V.Base)
		b: Block;

		i: INTEGER
	END;

	Iterator* = RECORD(Iter)
		char*: CHAR
	END;

	UtfIterator* = RECORD(Iter)
		code*: INTEGER
	END;

	Store* = RECORD(V.Base)
		first, last: Block;
		ofs: INTEGER
	END;

PROCEDURE Undef*(VAR s: String);
BEGIN
	V.Init(s);
	s.block := NIL;
	s.ofs := -1
END Undef;

PROCEDURE IsDefined*(s: String): BOOLEAN;
	RETURN s.block # NIL
END IsDefined;

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
	ASSERT(ODD(LEN(s)) OR (j <= end));
	ASSERT((0 <= j) & (j < LEN(s) - 1));
	ASSERT((0 <= end) & (end < LEN(s)));
	b := store.last;
	i := store.ofs;
	V.Init(w);
	w.block := b;
	w.ofs := i;

	(*Log.Str("Put "); Log.Int(b.num); Log.Str(":"); Log.Int(i); Log.Ln;*)
	WHILE j # end DO
		IF i = LEN(b.s) - 1 THEN
			(*ASSERT(i # w.ofs);*)
			b.s[i] := Utf8.NewPage;
			AddBlock(b, i)
		END;
		b.s[i] := s[j];
		ASSERT(s[j] # Utf8.NewPage);
		INC(i);

		INC(j);
		IF (j = LEN(s) - 1) & (end < LEN(s) - 1) THEN
			j := 0
		END
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

PROCEDURE IterInit(VAR it: Iter; s: String; VAR ofs: INTEGER): BOOLEAN;
BEGIN
	ASSERT(0 <= ofs);
	IF s.block # NIL THEN
		V.Init(it);
		it.b := s.block;
		it.i := s.ofs
	END
	RETURN s.block # NIL
END IterInit;

PROCEDURE GetIter*(VAR iter: Iterator; s: String; ofs: INTEGER): BOOLEAN;
BEGIN
	IF IterInit(iter, s, ofs) THEN
		WHILE iter.b.s[iter.i] = Utf8.NewPage DO
			iter.b := iter.b.next;
			iter.i := 0
		ELSIF (0 < ofs) & (iter.b.s[iter.i] # Utf8.Null) DO
			DEC(ofs);
			INC(iter.i)
		END;
		iter.char := iter.b.s[iter.i]
	END
	RETURN (s.block # NIL) & (iter.b.s[iter.i] # Utf8.Null)
END GetIter;

PROCEDURE IterNext*(VAR iter: Iterator): BOOLEAN;
BEGIN
	IF iter.char # Utf8.Null THEN
		INC(iter.i);
		IF iter.b.s[iter.i] = Utf8.NewPage THEN
			iter.b := iter.b.next;
			iter.i := 0
		END;
		iter.char := iter.b.s[iter.i]
	END
	RETURN iter.char # Utf8.Null
END IterNext;

PROCEDURE NextUtf*(VAR it: UtfIterator): BOOLEAN;
VAR st: INTEGER; r: Utf8.R;
BEGIN
	st := 0;
	r.val := 0;
	WHILE it.b.s[it.i] = Utf8.NewPage DO
		it.b := it.b.next;
		it.i := 0
	ELSIF (st = 0) & Utf8.Begin(r, it.b.s[it.i]) DO
		INC(it.i);
		st := 1
	ELSIF (st = 1) & Utf8.Next(r, it.b.s[it.i]) DO
		INC(it.i)
	END;
	INC(it.i);
	ASSERT((st = 0) OR (r.len = 0));
	it.code := r.val
	RETURN r.val # 0
END NextUtf;

PROCEDURE BeginUtf*(VAR it: UtfIterator; s: String; ofs: INTEGER): BOOLEAN;
BEGIN
	IF IterInit(it, s, ofs) THEN
		WHILE NextUtf(it) & (ofs > 0) DO
			DEC(ofs)
		END
	ELSE
		it.code := 0
	END
	RETURN it.code # 0
END BeginUtf;

PROCEDURE GetChar*(s: String; i: INTEGER): CHAR;
VAR ofs: INTEGER;
    b: Block;
BEGIN
	ASSERT((0 <= i) & (i < BlockSize * BlockSize));
	ofs := s.ofs + i;
	b   := s.block;
	WHILE BlockSize <= ofs DO
		b := b.next;
		DEC(ofs, BlockSize)
	END
	RETURN b.s[ofs]
END GetChar;

PROCEDURE IsEqualToChars*(w: String; s: ARRAY OF CHAR; j, end: INTEGER): BOOLEAN;
VAR i: INTEGER;
	b: Block;
BEGIN
	(*ASSERT(ODD(LEN(s)));*)
	ASSERT((j >= 0) & (j < LEN(s) - 1));
	ASSERT((0 <= end) & (end < LEN(s) - 1));
	i := w.ofs;
	b := w.block;
	WHILE (b.s[i] = s[j]) & (j # end) DO
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
	WHILE (j < LEN(s)) & (b.s[i] = s[j]) & (s[j] # Utf8.Null) DO
		INC(i);
		INC(j)
	ELSIF b.s[i] = Utf8.NewPage DO
		b := b.next;
		i := 0
	END
	RETURN (b.s[i] = Utf8.Null) & ((j = LEN(s)) OR (s[j] = Utf8.Null))
END IsEqualToString;

(* TODO Учесть регистр за пределами ASCII *)
PROCEDURE IsEqualToStringIgnoreCase*(w: String; s: ARRAY OF CHAR): BOOLEAN;
VAR i, j: INTEGER; b: Block;
BEGIN
	j := 0;
	i := w.ofs;
	b := w.block;
	WHILE (s[j] # Utf8.Null) & Utf8.EqualIgnoreCase(b.s[i], s[j]) DO
		INC(i);
		INC(j)
	ELSIF b.s[i] = Utf8.NewPage DO
		b := b.next;
		i := 0
	END
	RETURN (b.s[i] = Utf8.Null) & (s[j] = Utf8.Null)
END IsEqualToStringIgnoreCase;

PROCEDURE Compare*(w1, w2: String): INTEGER;
VAR i1, i2, res: INTEGER;
	b1, b2: Block;
BEGIN
	i1 := w1.ofs;
	i2 := w2.ofs;
	b1 := w1.block;
	b2 := w2.block;
	WHILE b1.s[i1] = Utf8.NewPage DO
		b1 := b1.next;
		i1 := 0
	ELSIF b2.s[i2] = Utf8.NewPage DO
		b2 := b2.next;
		i2 := 0
	ELSIF (b1.s[i1] = b2.s[i2]) & (b1.s[i1] # Utf8.Null) DO
		INC(i1);
		INC(i2)
	END;
	IF b1.s[i1] = b2.s[i2] THEN
		res := 0
	ELSIF b1.s[i1] < b2.s[i2] THEN
		res := -1
	ELSE
		res := 1
	END
	RETURN res
END Compare;

PROCEDURE SearchSubString*(w: String; s: ARRAY OF CHAR): BOOLEAN;
VAR i, j: INTEGER;
    b: Block;
BEGIN
	i := w.ofs;
	b := w.block;
	REPEAT
		WHILE b.s[i] = Utf8.NewPage DO
			b := b.next;
			i := 0
		ELSIF (b.s[i] # s[0]) & (b.s[i] # Utf8.Null) DO
			INC(i)
		END;
		j := 0;
		WHILE (j < LEN(s)) & (b.s[i] = s[j]) & (s[j] # Utf8.Null) DO
			INC(i);
			INC(j)
		ELSIF b.s[i] = Utf8.NewPage DO
			b := b.next;
			i := 0
		END
	UNTIL (j = LEN(s)) OR (s[j] = Utf8.Null) OR (b.s[i] = Utf8.Null)
	RETURN (j = LEN(s)) OR (s[j] = Utf8.Null)
END SearchSubString;

PROCEDURE CopyToChars*(VAR d: ARRAY OF CHAR; VAR dofs: INTEGER; w: String): BOOLEAN;
VAR b: Block;
	i: INTEGER;
BEGIN
	b := w.block;
	i := w.ofs;
	WHILE (dofs < LEN(d) - 1) & (b.s[i] > Utf8.NewPage) DO
		d[dofs] := b.s[i];
		INC(dofs); INC(i)
	ELSIF b.s[i] # Utf8.Null DO
		ASSERT(b.s[i] = Utf8.NewPage);
		b := b.next;
		i := 0
	END;
	d[dofs] := Utf8.Null
	RETURN b.s[i] = Utf8.Null
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

(*	копирование содержимого строки, не включая завершающего 0 в поток вывода
	TODO учесть возможность ошибки при записи *)
PROCEDURE Write*(VAR out: Stream.Out; str: String): INTEGER;
VAR i, len, ofs: INTEGER; block: Block;
BEGIN
	block := str.block;
	i := str.ofs;
	ofs := i;
	len := 0;
	WHILE block.s[i] = Utf8.NewPage DO
		len := len + Stream.WriteChars(out, block.s, ofs, i - ofs);
		block := block.next;
		ofs := 0;
		i := 0
	ELSIF block.s[i] # Utf8.Null DO
		INC(i)
	END;
	ASSERT(block.s[i] = Utf8.Null);
	len := Stream.WriteChars(out, block.s, ofs, i - ofs)
	RETURN len
END Write;

PROCEDURE IsAscii7*(str: String): BOOLEAN;
VAR b: Block; i: INTEGER;
BEGIN
	b := str.block;
	i := str.ofs;
	WHILE b.s[i] = Utf8.NewPage DO
		b := b.next;
		i := 0
	ELSIF (b.s[i] < 80X) & (b.s[i] # Utf8.Null) DO
		INC(i)
	END
	RETURN b.s[i] < 80X
END IsAscii7;

PROCEDURE IsUtfLess*(str: String; code: INTEGER): BOOLEAN;
VAR it: UtfIterator;
	PROCEDURE AllLess(VAR it: UtfIterator; code: INTEGER): BOOLEAN;
	BEGIN
		WHILE (it.code < code) & NextUtf(it) DO
			;
		END
		RETURN it.code = 0
	END AllLess;
BEGIN
	RETURN ~BeginUtf(it, str, 0) OR AllLess(it, code)
END IsUtfLess;

END StringStore.

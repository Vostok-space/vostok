(*  Generator of C-code by Oberon-07 abstract syntax tree
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
MODULE GeneratorC;

IMPORT
	V,
	Ast,
	Strings := StringStore,
	SpecIdentChecker,
	Scanner,
	SpecIdent := OberonSpecIdent,
	Stream := VDataStream,
	Text := TextGenerator,
	Utf8, Utf8Transform,
	Log,
	Limits := TypesLimits,
	TranLim := TranslatorLimits;

CONST
	Interface = 1;
	Implementation = 0;

	IsoC90* = 0;
	IsoC99* = 1;
	IsoC11* = 2;

	VarInitUndefined*   = 0;
	VarInitZero*        = 1;
	VarInitNo*          = 2;

	MemManagerNoFree*   = 0;
	MemManagerCounter*  = 1;
	MemManagerGC*       = 2;

	IdentEncSame*       = 0;
	IdentEncTranslit*   = 1;
	IdentEncEscUnicode* = 2;

	CheckableArithTypes = Ast.Numbers - {Ast.IdByte};
	CheckableInitTypes  = CheckableArithTypes + {Ast.IdBoolean};

TYPE
	PMemoryOut = POINTER TO MemoryOut;
	MemoryOut = RECORD(Stream.Out)
		mem: ARRAY 2 OF RECORD
				buf: ARRAY 4096 OF CHAR;
				len: INTEGER
			END;
		invert: BOOLEAN;

		next: PMemoryOut
	END;

	Options* = POINTER TO RECORD(V.Base)
		std*: INTEGER;

		gnu*, plan9*,
		procLocal*,
		checkIndex*,
		vla*, vlaMark*,
		checkArith*,
		caseAbort*,
		checkNil*,
		o7Assert*,
		skipUnusedTag*,
		comment*,
		generatorNote*: BOOLEAN;

		varInit*,
		memManager*,
		identEnc*  : INTEGER;

		main: BOOLEAN;

		index: INTEGER;
		records, recordLast: Ast.Record; (* для генерации тэгов *)

		lastSelectorDereference,
		(* TODO для более сложных случаев *)
		expectArray: BOOLEAN;

		memOuts: PMemoryOut
	END;

	Generator* = RECORD(Text.Out)
		module: Ast.Module;

		localDeep: INTEGER;(* Вложенность процедур *)

		fixedLen: INTEGER;

		interface: BOOLEAN;
		opt: Options;

		expressionSemicolon,
		insideSizeOf       : BOOLEAN;

		memout: PMemoryOut
	END;

	MOut = RECORD
		g: ARRAY 2 OF Generator;
		opt: Options
	END;

	Selectors = RECORD
		des: Ast.Designator;
		decl: Ast.Declaration;
		list: ARRAY TranLim.Selectors OF Ast.Selector;
		i: INTEGER
	END;

	RecExt = POINTER TO RECORD(V.Base)
		anonName: Strings.String;
		undef: BOOLEAN;
		next: Ast.Record
	END;

VAR
	type: PROCEDURE(VAR gen: Generator; decl: Ast.Declaration; type: Ast.Type;
	                typeDecl, sameType: BOOLEAN);
	declarator: PROCEDURE(VAR gen: Generator; decl: Ast.Declaration;
	                      typeDecl, sameType, global: BOOLEAN);
	declarations: PROCEDURE(VAR out: MOut; ds: Ast.Declarations);
	statements: PROCEDURE(VAR gen: Generator; stats: Ast.Statement);
	expression: PROCEDURE(VAR gen: Generator; expr: Ast.Expression);

PROCEDURE MemoryWrite(VAR out: MemoryOut; buf: ARRAY OF CHAR; ofs, count: INTEGER);
BEGIN
	ASSERT(Strings.CopyChars(
		out.mem[ORD(out.invert)].buf, out.mem[ORD(out.invert)].len,
		buf, ofs, ofs + count
	))
END MemoryWrite;

PROCEDURE MemWrite(VAR out: V.Base;
                   buf: ARRAY OF CHAR; ofs, count: INTEGER): INTEGER;
BEGIN
	MemoryWrite(out(MemoryOut), buf, ofs, count)
	RETURN count
END MemWrite;

PROCEDURE PMemoryOutGet(opt: Options): PMemoryOut;
VAR m: PMemoryOut;
BEGIN
	IF opt.memOuts = NIL THEN
		NEW(m);
		Stream.InitOut(m^, NIL, MemWrite, NIL)
	ELSE
		m := opt.memOuts;
		opt.memOuts := m.next
	END;
	m.mem[0].len := 0;
	m.mem[1].len := 0;
	m.invert := FALSE;
	m.next := NIL

	RETURN m
END PMemoryOutGet;

PROCEDURE PMemoryOutBack(opt: Options; m: PMemoryOut);
BEGIN
	m.next := opt.memOuts;
	opt.memOuts := m
END PMemoryOutBack;

PROCEDURE MemWriteInvert(VAR mo: MemoryOut);
VAR inv: INTEGER;
BEGIN
	inv := ORD(mo.invert);
	IF mo.mem[inv].len = 0 THEN
		mo.invert := ~mo.invert
	ELSE
		ASSERT(Strings.CopyChars(mo.mem[inv].buf, mo.mem[inv].len,
		                         mo.mem[1 - inv].buf, 0, mo.mem[1 - inv].len));
		mo.mem[1 - inv].len := 0
	END
END MemWriteInvert;

PROCEDURE MemWriteDirect(VAR gen: Generator; VAR mo: MemoryOut);
VAR inv: INTEGER;
BEGIN
	inv := ORD(mo.invert);
	ASSERT(mo.mem[1 - inv].len = 0);
	Text.Data(gen, mo.mem[inv].buf, 0, mo.mem[inv].len);
	mo.mem[inv].len := 0
END MemWriteDirect;

PROCEDURE Ident(VAR gen: Generator; ident: Strings.String);
VAR buf: ARRAY TranLim.LenName * 6 + 2 OF CHAR;
    i: INTEGER;
    it: Strings.Iterator;
BEGIN
	ASSERT(Strings.GetIter(it, ident, 0));
	i := 0;
	IF (gen.opt.identEnc = IdentEncSame) OR (it.char < 80X) THEN
		REPEAT
			buf[i] := it.char;
			INC(i);
			IF it.char = "_" THEN
				buf[i] := "_";
				INC(i)
			END
		UNTIL ~Strings.IterNext(it)
	ELSIF gen.opt.identEnc = IdentEncEscUnicode THEN
		Utf8Transform.Escape(buf, i, it)
	ELSE ASSERT(gen.opt.identEnc = IdentEncTranslit);
		Utf8Transform.Transliterate(buf, i, it)
	END;
	Text.Data(gen, buf, 0, i)
END Ident;

PROCEDURE Name(VAR gen: Generator; decl: Ast.Declaration);
VAR up: Ast.Declarations;
    prs: ARRAY TranLim.DeepProcedures + 1 OF Ast.Declarations;
    i: INTEGER;
BEGIN
	IF (decl IS Ast.Type) & (decl.up # NIL) & (decl.up.d # decl.module.m)
	OR ~gen.opt.procLocal & (decl IS Ast.Procedure)
	THEN
		up := decl.up.d;
		i := 0;
		WHILE up.up # NIL DO
			prs[i] := up;
			INC(i);
			up := up.up.d
		END;
		WHILE i > 0 DO
			DEC(i);
			Ident(gen, prs[i].name);
			Text.Str(gen, "_")
		END
	END;
	Ident(gen, decl.name);
	IF decl IS Ast.Const THEN
		Text.Str(gen, "_cnst")
	ELSIF SpecIdentChecker.IsSpecName(decl.name, {}) THEN
		Text.Str(gen, "_")
	END
END Name;

PROCEDURE GlobalName(VAR gen: Generator; decl: Ast.Declaration);
BEGIN
	IF decl.mark OR (decl.module # NIL) & (gen.module # decl.module.m) THEN
		ASSERT(decl.module # NIL);
		Ident(gen, decl.module.m.name);

		Text.Data(gen, "__", 0,
		    ORD(
		        SpecIdentChecker.IsSpecModuleName(decl.module.m.name)
		      & ~decl.module.m.spec
		     OR SpecIdentChecker.IsO7SpecName(decl.name)
		    ) + 1
		);
		Ident(gen, decl.name);
		IF decl IS Ast.Const THEN
			Text.Str(gen, "_cnst")
		END
	ELSE
		Name(gen, decl)
	END
END GlobalName;

PROCEDURE Import(VAR gen: Generator; decl: Ast.Declaration);
VAR name: Strings.String;
    i: INTEGER;
BEGIN
	Text.Str(gen, "#include "); Text.Str(gen, Utf8.DQuote);
	IF decl IS Ast.Module THEN
		name := decl.name
	ELSE ASSERT(decl IS Ast.Import);
		name := decl.module.m.name
	END;
	Text.String(gen, name);
	i := ORD(~SpecIdentChecker.IsSpecModuleName(name));
	Text.Data(gen, "_.h",  i, 3 - i);
	Text.StrLn(gen, Utf8.DQuote)
END Import;

PROCEDURE Factor(VAR gen: Generator; expr: Ast.Expression);
BEGIN
	IF expr IS Ast.Factor THEN
		(* TODO *)
		expression(gen, expr)
	ELSE
		Text.Str(gen, "(");
		expression(gen, expr);
		Text.Str(gen, ")")
	END
END Factor;

PROCEDURE IsAnonStruct(rec: Ast.Record): BOOLEAN;
BEGIN
	RETURN ~Strings.IsDefined(rec.name)
	    OR Strings.SearchSubString(rec.name, "_anon_")
END IsAnonStruct;

PROCEDURE TypeForTag(rec: Ast.Record): Ast.Type;
BEGIN
	IF IsAnonStruct(rec) THEN
		rec := rec.base
	END
	RETURN rec
END TypeForTag;

PROCEDURE CheckStructName(VAR gen: Generator; rec: Ast.Record): BOOLEAN;
VAR anon: ARRAY TranLim.LenName * 2 + 3 OF CHAR;
	i, j, l: INTEGER;
BEGIN
	IF Strings.IsDefined(rec.name) THEN
		;
	ELSIF (rec.pointer # NIL) & Strings.IsDefined(rec.pointer.name) THEN
		l := 0;
		ASSERT(rec.module # NIL);
		rec.mark := rec.pointer.mark;
		ASSERT(Strings.CopyToChars(anon, l, rec.pointer.name));
		anon[l] := "_";
		anon[l + 1] := "s";
		anon[l + 2] := Utf8.Null;
		Ast.PutChars(rec.pointer.module.m, rec.name, anon, 0, l + 2)
	ELSE
		l := 0;
		ASSERT(Strings.CopyToChars(anon, l, rec.module.m.name));

		Log.StrLn("Record");

		ASSERT(Strings.CopyChars(anon, l, "_anon_0000", 0, 10));
		ASSERT((gen.opt.index >= 0) & (gen.opt.index < 10000));
		i := gen.opt.index;
		(*Log.Int(i); Log.Ln;*)
		j := l - 1;
		WHILE i > 0 DO
			anon[j] := CHR(ORD("0") + i MOD 10);
			i := i DIV 10;
			DEC(j)
		END;
		INC(gen.opt.index);
		Ast.PutChars(rec.module.m, rec.name, anon, 0, l)
	END
	RETURN Strings.IsDefined(rec.name)
END CheckStructName;

PROCEDURE ArrayDeclLen(VAR gen: Generator; arr: Ast.Type;
                       decl: Ast.Declaration; sel: Ast.Selector;
                       i: INTEGER);
BEGIN
	IF arr(Ast.Array).count # NIL THEN
		expression(gen, arr(Ast.Array).count)
	ELSE
		GlobalName(gen, decl);(*TODO*)
		Text.Str(gen, "_len");
		IF i < 0 THEN
			i := 0;
			WHILE sel # NIL DO
				INC(i);
				sel := sel.next
			END
		END;
		Text.Int(gen, i)
	END
END ArrayDeclLen;

PROCEDURE ArrayLen(VAR gen: Generator; e: Ast.Expression);
VAR i: INTEGER;
	des: Ast.Designator;
	t: Ast.Type;
BEGIN
	IF e.type(Ast.Array).count # NIL THEN
		expression(gen, e.type(Ast.Array).count)
	ELSE
		des := e(Ast.Designator);
		GlobalName(gen, des.decl);
		Text.Str(gen, "_len");
		i := 0;
		t := des.type;
		WHILE t # e.type DO
			INC(i);
			t := t.type
		END;
		Text.Int(gen, i)
	END
END ArrayLen;

PROCEDURE Selector(VAR gen: Generator; sels: Selectors; i: INTEGER;
                   VAR typ: Ast.Type; desType: Ast.Type);
VAR sel: Ast.Selector;
	ref: BOOLEAN;

	PROCEDURE Record(VAR gen: Generator; VAR typ: Ast.Type; VAR sel: Ast.Selector);
	VAR var: Ast.Declaration;
		up: Ast.Record;

		PROCEDURE Search(ds: Ast.Record; d: Ast.Declaration): BOOLEAN;
		VAR c: Ast.Declaration;
		BEGIN
			c := ds.vars;
			WHILE (c # NIL) & (c # d) DO
				c := c.next
			END
			RETURN c # NIL
		END Search;
	BEGIN
		var := sel(Ast.SelRecord).var;
		IF typ IS Ast.Pointer THEN
			up := typ(Ast.Pointer).type(Ast.Record)
		ELSE
			up := typ(Ast.Record)
		END;

		IF typ.id = Ast.IdPointer THEN
			Text.Str(gen, "->")
		ELSE
			Text.Str(gen, ".")
		END;

		IF ~gen.opt.plan9 THEN
			WHILE (up # NIL) & ~Search(up, var) DO
				up := up.base;
				Text.Str(gen, "_.")
			END
		END;

		Name(gen, var);

		typ := var.type
	END Record;

	PROCEDURE Declarator(VAR gen: Generator; decl: Ast.Declaration);
	BEGIN
		IF (decl IS Ast.FormalParam)
		   &
		   (  (Ast.ParamOut IN decl(Ast.FormalParam).access)
		    & (decl.type.id # Ast.IdArray)
		   OR (decl.type.id = Ast.IdRecord)
		   )
		THEN
			Text.Str(gen, "(*");
			GlobalName(gen, decl);
			Text.Str(gen, ")")
		ELSE
			GlobalName(gen, decl)
		END
	END Declarator;

	PROCEDURE Array(VAR gen: Generator; VAR typ: Ast.Type;
	                VAR sel: Ast.Selector; decl: Ast.Declaration;
	                isDesignatorArray: BOOLEAN);
	VAR i: INTEGER;

		PROCEDURE Mult(VAR gen: Generator;
		               decl: Ast.Declaration; j: INTEGER; t: Ast.Type);
		BEGIN
			WHILE (t # NIL) & (t IS Ast.Array) DO
				Text.Str(gen, " * ");
				Name(gen, decl);
				Text.Str(gen, "_len");
				Text.Int(gen, j);
				INC(j);
				t := t.type
			END
		END Mult;
	BEGIN
		IF isDesignatorArray & ~gen.opt.vla THEN
			Text.Str(gen, " + ")
		ELSE
			Text.Str(gen, "[")
		END;
		IF (typ.type.id # Ast.IdArray) OR (typ(Ast.Array).count # NIL)
		OR gen.opt.vla
		THEN
			IF gen.opt.checkIndex
			 & (   (sel(Ast.SelArray).index.value = NIL)
			    OR (typ(Ast.Array).count = NIL)
			     & (sel(Ast.SelArray).index.value(Ast.ExprInteger).int # 0)
			   )
			THEN
				Text.Str(gen, "o7_ind(");
				ArrayDeclLen(gen, typ, decl, sel, 0);
				Text.Str(gen, ", ");
				expression(gen, sel(Ast.SelArray).index);
				Text.Str(gen, ")")
			ELSE
				expression(gen, sel(Ast.SelArray).index)
			END;
			typ := typ.type;
			sel := sel.next;
			i := 1;
			WHILE (sel # NIL) & (sel IS Ast.SelArray) DO
				IF gen.opt.checkIndex
				 & (   (sel(Ast.SelArray).index.value = NIL)
				    OR (typ(Ast.Array).count = NIL)
				     & (sel(Ast.SelArray).index.value(Ast.ExprInteger).int # 0)
				   )
				THEN
					Text.Str(gen, "][o7_ind(");
					ArrayDeclLen(gen, typ, decl, sel, i);
					Text.Str(gen, ", ");
					expression(gen, sel(Ast.SelArray).index);
					Text.Str(gen, ")")
				ELSE
					Text.Str(gen, "][");
					expression(gen, sel(Ast.SelArray).index)
				END;
				INC(i);
				sel := sel.next;
				typ := typ.type
			END
		ELSE
			i := 0;
			WHILE (sel.next # NIL) & (sel.next IS Ast.SelArray) DO
				Text.Str(gen, "o7_ind(");
				ArrayDeclLen(gen, typ, decl, NIL, i);
				Text.Str(gen, ", ");
				expression(gen, sel(Ast.SelArray).index);
				Text.Str(gen, ")");
				typ := typ.type;
				Mult(gen, decl, i + 1, typ);
				sel := sel.next;
				INC(i);
				Text.Str(gen, " + ")
			END;
			Text.Str(gen, "o7_ind(");
			ArrayDeclLen(gen, typ, decl, NIL, i);
			Text.Str(gen, ", ");
			expression(gen, sel(Ast.SelArray).index);
			Text.Str(gen, ")");
			Mult(gen, decl, i + 1, typ.type)
		END;
		IF ~isDesignatorArray OR gen.opt.vla THEN
			Text.Str(gen, "]")
		END
	END Array;
BEGIN
	IF i >= 0 THEN
		sel := sels.list[i]
	END;
	IF ~gen.opt.checkNil THEN
		ref := FALSE
	ELSIF i < 0 THEN
		ref := (sels.i >= 0)
		     & (sels.decl.type # NIL) & (sels.decl.type.id = Ast.IdPointer)
	ELSE
		ref := (sel.type.id = Ast.IdPointer)
		     & (sel.next # NIL) & ~(sel.next IS Ast.SelGuard)
		     & ~(sel IS Ast.SelGuard)
	END;
	IF ref THEN
		Text.Str(gen, "O7_REF(")
	END;
	IF i < 0 THEN
		Declarator(gen, sels.decl)
	ELSE
		DEC(i);
		IF sel IS Ast.SelRecord THEN
			Selector(gen, sels, i, typ, desType);
			Record(gen, typ, sel)
		ELSIF sel IS Ast.SelArray THEN
			Log.StrLn("SelArray");
			Selector(gen, sels, i, typ, desType);
			Array(gen, typ, sel, sels.decl,
			      (desType.id = Ast.IdArray) & (desType(Ast.Array).count = NIL))
		ELSIF sel IS Ast.SelPointer THEN
			IF (sel.next = NIL) OR ~(sel.next IS Ast.SelRecord) THEN
				Text.Str(gen, "(*");
				Selector(gen, sels, i, typ, desType);
				Text.Str(gen, ")")
			ELSE
				Selector(gen, sels, i, typ, desType)
			END
		ELSE ASSERT(sel IS Ast.SelGuard);
			IF sel.type.id = Ast.IdPointer THEN
				Text.Str(gen, "O7_GUARD(");
				ASSERT(CheckStructName(gen, sel.type.type(Ast.Record)));
				GlobalName(gen, sel.type.type)
			ELSE
				Text.Str(gen, "O7_GUARD_R(");
				GlobalName(gen, sel.type)
			END;
			Text.Str(gen, ", &");
			IF i < 0 THEN
				Declarator(gen, sels.decl)
			ELSE
				Selector(gen, sels, i, typ, desType)
			END;
			IF sel.type.id = Ast.IdPointer THEN
				Text.Str(gen, ")")
			ELSE
				Text.Str(gen, ", ");
				GlobalName(gen, sels.decl);
				Text.Str(gen, "_tag)")
			END;
			typ := sel(Ast.SelGuard).type
		END;
	END;
	IF ref THEN
		Text.Str(gen, ")")
	END
END Selector;

PROCEDURE IsDesignatorMayNotInited(des: Ast.Designator): BOOLEAN;
	RETURN ({Ast.InitedNo, Ast.InitedCheck} * des.inited # {})
	    OR (des.sel # NIL)
END IsDesignatorMayNotInited;

PROCEDURE IsMayNotInited(e: Ast.Expression): BOOLEAN;
	RETURN (e IS Ast.Designator) & IsDesignatorMayNotInited(e(Ast.Designator))
END IsMayNotInited;

PROCEDURE Designator(VAR gen: Generator; des: Ast.Designator);
VAR sels: Selectors;
    typ: Ast.Type;
    lastSelectorDereference: BOOLEAN;

	PROCEDURE Put(VAR sels: Selectors; sel: Ast.Selector);
	BEGIN
		sels.i := -1;
		WHILE sel # NIL DO
			INC(sels.i);
			sels.list[sels.i] := sel;
			IF sel IS Ast.SelArray THEN
				REPEAT
					sel := sel.next
				UNTIL (sel = NIL) OR ~(sel IS Ast.SelArray)
			ELSE
				sel := sel.next
			END
		END
	END Put;

BEGIN
	typ := des.decl.type;
	Put(sels, des.sel);
	sels.des := des;
	sels.decl := des.decl;(* TODO *)
	lastSelectorDereference := (0 <= sels.i)
	                         & (sels.list[sels.i] IS Ast.SelPointer);
	Selector(gen, sels, sels.i, typ, des.type);
	gen.opt.lastSelectorDereference := lastSelectorDereference
END Designator;

PROCEDURE CheckExpr(VAR gen: Generator; e: Ast.Expression);
BEGIN
	IF (gen.opt.varInit = VarInitUndefined)
	 & (e.value = NIL)
	 & (e.type.id IN CheckableInitTypes)
	 & IsMayNotInited(e)
	THEN
		CASE e.type.id OF
		  Ast.IdBoolean:
			Text.Str(gen, "o7_bl(")
		| Ast.IdInteger:
			Text.Str(gen, "o7_int(")
		| Ast.IdLongInt:
			Text.Str(gen, "o7_long(")
		| Ast.IdReal:
			Text.Str(gen, "o7_dbl(")
		| Ast.IdReal32:
			Text.Str(gen, "o7_fl(")
		END;
		expression(gen, e);
		Text.Str(gen, ")")
	ELSE
		expression(gen, e)
	END
END CheckExpr;

PROCEDURE AssignInitValue(VAR gen: Generator; typ: Ast.Type);
	PROCEDURE Zero(VAR gen: Generator; typ: Ast.Type);
	BEGIN
		CASE typ.id OF
		  Ast.IdInteger, Ast.IdLongInt, Ast.IdByte, Ast.IdReal, Ast.IdReal32,
		  Ast.IdSet, Ast.IdLongSet:
			Text.Str(gen, " = 0")
		| Ast.IdBoolean:
			Text.Str(gen, " = 0 > 1")
		| Ast.IdChar:
			Text.Str(gen, " = '\0'")
		| Ast.IdPointer, Ast.IdProcType:
			Text.Str(gen, " = NULL")
		END
	END Zero;

	PROCEDURE Undef(VAR gen: Generator; typ: Ast.Type);
	BEGIN
		CASE typ.id OF
		  Ast.IdInteger:
			Text.Str(gen, " = O7_INT_UNDEF")
		| Ast.IdLongInt:
			Text.Str(gen, " = O7_LONG_UNDEF")
		| Ast.IdBoolean:
			Text.Str(gen, " = O7_BOOL_UNDEF")
		| Ast.IdByte:
			Text.Str(gen, " = 0")
		| Ast.IdChar:
			Text.Str(gen, " = '\0'")
		| Ast.IdReal:
			Text.Str(gen, " = O7_DBL_UNDEF")
		| Ast.IdReal32:
			Text.Str(gen, " = O7_FLT_UNDEF")
		| Ast.IdSet, Ast.IdLongSet:
			Text.Str(gen, " = 0u")
		| Ast.IdPointer, Ast.IdProcType:
			Text.Str(gen, " = NULL")
		END
	END Undef;
BEGIN
	CASE gen.opt.varInit OF
	  VarInitUndefined:
		Undef(gen, typ)
	| VarInitZero:
		Zero(gen, typ)
	END
END AssignInitValue;

PROCEDURE VarInit(VAR gen: Generator; var: Ast.Declaration; record: BOOLEAN);
BEGIN
	IF (gen.opt.varInit = VarInitNo)
	OR (var.type.id IN {Ast.IdArray, Ast.IdRecord})
	OR (~record & ~var(Ast.Var).checkInit)
	THEN
		IF (var.type.id = Ast.IdPointer)
		 & (gen.opt.memManager = MemManagerCounter)
		THEN
			Text.Str(gen, " = NULL")
		END
	ELSE
		AssignInitValue(gen, var.type)
	END
END VarInit;

PROCEDURE Expression(VAR gen: Generator; expr: Ast.Expression);

	PROCEDURE Call(VAR gen: Generator; call: Ast.ExprCall);
	VAR p: Ast.Parameter;
		fp: Ast.Declaration;

		PROCEDURE Predefined(VAR gen: Generator; call: Ast.ExprCall);
		VAR e1: Ast.Expression;
			p2: Ast.Parameter;

			PROCEDURE LeftShift(VAR gen: Generator; n, s: Ast.Expression);
			BEGIN
				(* TODO *)
				Text.Str(gen, "(o7_int_t)((o7_uint_t)");
				Factor(gen, n);
				Text.Str(gen, " << ");
				Factor(gen, s);
				Text.Str(gen, ")")
			END LeftShift;

			PROCEDURE ArithmeticRightShift(VAR gen: Generator; n, s: Ast.Expression);
			BEGIN
				IF (n.value # NIL) & (s.value # NIL) THEN
					Text.Str(gen, "O7_ASR(");
					Expression(gen, n);
					Text.Str(gen, ", ");
					Expression(gen, s);
					Text.Str(gen, ")")
				ELSIF gen.opt.gnu THEN
					Text.Str(gen, "(");
					Factor(gen, n);
					IF gen.opt.checkArith & (s.value = NIL) THEN
						Text.Str(gen, " >> o7_not_neg(")
					ELSE
						Text.Str(gen, " >> (")
					END;
					Expression(gen, s);
					Text.Str(gen, "))")
				ELSE
					Text.Str(gen, "o7_asr(");
					Expression(gen, n);
					Text.Str(gen, ", ");
					Expression(gen, s);
					Text.Str(gen, ")")
				END
			END ArithmeticRightShift;

			PROCEDURE Rotate(VAR gen: Generator; n, r: Ast.Expression);
			BEGIN
				IF (n.value # NIL) & (r.value # NIL) THEN
					Text.Str(gen, "O7_ROR(")
				ELSE
					Text.Str(gen, "o7_ror(")
				END;
				Expression(gen, n);
				Text.Str(gen, ", ");
				Expression(gen, r);
				Text.Str(gen, ")")
			END Rotate;

			PROCEDURE Len(VAR gen: Generator; e: Ast.Expression);
			VAR sel: Ast.Selector;
				i: INTEGER;
				des: Ast.Designator;
				count: Ast.Expression;
				sizeof: BOOLEAN;
			BEGIN
				count := e.type(Ast.Array).count;
				IF e IS Ast.Designator THEN
					des := e(Ast.Designator);
					sizeof := ~(e(Ast.Designator).decl IS Ast.Const)
					         & ((des.decl.type.id # Ast.IdArray)
					        OR ~(des.decl IS Ast.FormalParam)
					           )
				ELSE
					ASSERT(count # NIL);
					sizeof := FALSE
				END;
				IF (count # NIL) & ~sizeof THEN
					Expression(gen, count)
				ELSIF sizeof THEN
					Text.Str(gen, "O7_LEN(");
					Designator(gen, des);
					Text.Str(gen, ")");
					(*
					Text.Str(gen, "sizeof(");
					Designator(gen, des);
					Text.Str(gen, ") / sizeof (");
					Designator(gen, des);
					Text.Str(gen, "[0])")
					*)
				ELSE
					GlobalName(gen, des.decl);
					Text.Str(gen, "_len");
					i := 0;
					sel := des.sel;
					WHILE sel # NIL DO
						INC(i);
						sel := sel.next
					END;
					Text.Int(gen, i)
				END
			END Len;

			PROCEDURE New(VAR gen: Generator; e: Ast.Expression);
			VAR tagType: Ast.Type;
			BEGIN
				tagType := TypeForTag(e.type.type(Ast.Record));
				IF tagType # NIL THEN
					Text.Str(gen, "O7_NEW(&");
					Designator(gen, e(Ast.Designator));
					Text.Str(gen, ", ");
					GlobalName(gen, tagType);
					Text.Str(gen, ")")
				ELSE
					Text.Str(gen, "O7_NEW2(&");
					Designator(gen, e(Ast.Designator));
					Text.Str(gen, ", o7_base_tag, NULL)")
				END
			END New;

			PROCEDURE Ord(VAR gen: Generator; e: Ast.Expression);
			BEGIN
				CASE e.type.id OF
				  Ast.IdChar, Ast.IdArray:
					Text.Str(gen, "(o7_int_t)");
					Factor(gen, e)
				| Ast.IdBoolean:
					IF (e IS Ast.Designator)
					 & (gen.opt.varInit = VarInitUndefined)
					THEN
						Text.Str(gen, "(o7_int_t)o7_bl(");
						Expression(gen, e);
						Text.Str(gen, ")")
					ELSE
						Text.Str(gen, "(o7_int_t)");
						Factor(gen, e)
					END
				| Ast.IdSet:
					Text.Str(gen, "o7_sti(");
					Expression(gen, e);
					Text.Str(gen, ")")
				END
			END Ord;

			PROCEDURE Inc(VAR gen: Generator;
			              e1: Ast.Expression; p2: Ast.Parameter);
			BEGIN
				Expression(gen, e1);
				IF gen.opt.checkArith THEN
					Text.Str(gen, " = o7_add(");
					Expression(gen, e1);
					IF p2 = NIL THEN
						Text.Str(gen, ", 1)")
					ELSE
						Text.Str(gen, ", ");
						Expression(gen, p2.expr);
						Text.Str(gen, ")")
					END
				ELSIF p2 = NIL THEN
					Text.Str(gen, "++")
				ELSE
					Text.Str(gen, " += ");
					Expression(gen, p2.expr)
				END
			END Inc;

			PROCEDURE Dec(VAR gen: Generator;
			              e1: Ast.Expression; p2: Ast.Parameter);
			BEGIN
				Expression(gen, e1);
				IF gen.opt.checkArith THEN
					Text.Str(gen, " = o7_sub(");
					Expression(gen, e1);
					IF p2 = NIL THEN
						Text.Str(gen, ", 1)")
					ELSE
						Text.Str(gen, ", ");
						Expression(gen, p2.expr);
						Text.Str(gen, ")")
					END
				ELSIF p2 = NIL THEN
					Text.Str(gen, "--")
				ELSE
					Text.Str(gen, " -= ");
					Expression(gen, p2.expr)
				END
			END Dec;

			PROCEDURE Assert(VAR gen: Generator; e: Ast.Expression);
			VAR c11Assert: BOOLEAN;
			    buf: ARRAY 5 OF CHAR;
			BEGIN
				c11Assert := FALSE;
				IF (e.value # NIL) & (e.value # Ast.ExprBooleanGet(FALSE))
				 & ~(Ast.ExprPointerTouch IN e.properties)
				THEN
					IF gen.opt.std >= IsoC11 THEN
						c11Assert := TRUE;
						Text.Str(gen, "static_assert(")
					ELSE
						Text.Str(gen, "O7_STATIC_ASSERT(")
					END
				ELSIF gen.opt.o7Assert THEN
					Text.Str(gen, "O7_ASSERT(")
				ELSE
					Text.Str(gen, "assert(")
				END;
				CheckExpr(gen, e);
				IF c11Assert THEN
					buf[0] := ",";
					buf[1] := " ";
					buf[2] := Utf8.DQuote;
					buf[3] := Utf8.DQuote;
					buf[4] := ")";
					Text.Str(gen, buf)
				ELSE
					Text.Str(gen, ")")
				END
			END Assert;
		BEGIN
			e1 := call.params.expr;
			p2 := call.params.next;
			CASE call.designator.decl.id OF
			  SpecIdent.Abs:
				IF call.type.id = Ast.IdInteger THEN
					Text.Str(gen, "abs(")
				ELSIF call.type.id = Ast.IdLongInt THEN
					Text.Str(gen, "O7_LABS(")
				ELSE
					Text.Str(gen, "fabs(")
				END;
				Expression(gen, e1);
				Text.Str(gen, ")")
			| SpecIdent.Odd:
				Text.Str(gen, "(");
				Factor(gen, e1);
				Text.Str(gen, " % 2 == 1)")
			| SpecIdent.Len:
				Len(gen, e1)
			| SpecIdent.Lsl:
				LeftShift(gen, e1, p2.expr)
			| SpecIdent.Asr:
				ArithmeticRightShift(gen, e1, p2.expr)
			| SpecIdent.Ror:
				Rotate(gen, e1, p2.expr);
			| SpecIdent.Floor:
				Text.Str(gen, "o7_floor(");
				Expression(gen, e1);
				Text.Str(gen, ")")
			| SpecIdent.Flt:
				Text.Str(gen, "o7_flt(");
				Expression(gen, e1);
				Text.Str(gen, ")")
			| SpecIdent.Ord:
				Ord(gen, e1)
			| SpecIdent.Chr:
				IF gen.opt.checkArith & (e1.value = NIL) THEN
					Text.Str(gen, "o7_chr(");
					Expression(gen, e1);
					Text.Str(gen, ")")
				ELSE
					Text.Str(gen, "(o7_char)");
					Factor(gen, e1)
				END
			| SpecIdent.Inc:
				Inc(gen, e1, p2)
			| SpecIdent.Dec:
				Dec(gen, e1, p2)
			| SpecIdent.Incl:
				Expression(gen, e1);
				Text.Str(gen, " |= 1u << ");
				Factor(gen, p2.expr)
			| SpecIdent.Excl:
				Expression(gen, e1);
				Text.Str(gen, " &= ~(1u << ");
				Factor(gen, p2.expr);
				Text.Str(gen, ")")
			| SpecIdent.New:
				New(gen, e1)
			| SpecIdent.Assert:
				Assert(gen, e1)
			| SpecIdent.Pack:
				Text.Str(gen, "o7_ldexp(&");
				Expression(gen, e1);
				Text.Str(gen, ", ");
				Expression(gen, p2.expr);
				Text.Str(gen, ")")
			| SpecIdent.Unpk:
				Text.Str(gen, "o7_frexp(&");
				Expression(gen, e1);
				Text.Str(gen, ", &");
				Expression(gen, p2.expr);
				Text.Str(gen, ")")
			END
		END Predefined;

		PROCEDURE ActualParam(VAR gen: Generator; VAR p: Ast.Parameter;
		                      VAR fp: Ast.Declaration);
		VAR t: Ast.Type;
		    i, j, dist: INTEGER;
		    paramOut: BOOLEAN;

			PROCEDURE ArrayDeep(t: Ast.Type): INTEGER;
			VAR d: INTEGER;
			BEGIN
				d := 0;
				WHILE t.id = Ast.IdArray DO
					t := t.type;
					INC(d)
				END
				RETURN d
			END ArrayDeep;
		BEGIN
			t := fp.type;
			IF (t.id = Ast.IdByte) & (p.expr.type.id IN {Ast.IdInteger, Ast.IdLongInt})
			 & gen.opt.checkArith & (p.expr.value = NIL)
			THEN
				IF p.expr.type.id = Ast.IdInteger THEN
					Text.Str(gen, "o7_byte(")
				ELSE
					Text.Str(gen, "o7_lbyte(")
				END;
				Expression(gen, p.expr);
				Text.Str(gen, ")")
			ELSE
				j := 1;
				IF fp.type.id # Ast.IdChar THEN
					i := -1;
					t := p.expr.type;
					WHILE (t.id = Ast.IdArray)
					    & (fp.type(Ast.Array).count = NIL)
					DO
						IF (i = -1) & (p.expr IS Ast.Designator) THEN
							i := ArrayDeep(p.expr(Ast.Designator).decl.type)
							   - ArrayDeep(fp.type);
							IF ~(p.expr(Ast.Designator).decl IS Ast.FormalParam)
							THEN
								j := ArrayDeep(p.expr(Ast.Designator).type)
							END
						END;
						IF t(Ast.Array).count # NIL THEN
							Expression(gen, t(Ast.Array).count)
						ELSE
							Name(gen, p.expr(Ast.Designator).decl);
							Text.Str(gen, "_len");
							Text.Int(gen, i)
						END;
						Text.Str(gen, ", ");
						INC(i);
						t := t.type
					END;
					t := fp.type
				END;
				dist := p.distance;
				paramOut := Ast.ParamOut IN fp(Ast.FormalParam).access;
				IF (paramOut & ~(t IS Ast.Array))
				OR (t IS Ast.Record)
				OR (t.id = Ast.IdPointer) & (0 < dist) & ~gen.opt.plan9
				THEN
					Text.Str(gen, "&")
				END;
				gen.opt.lastSelectorDereference := FALSE;
				gen.opt.expectArray := fp.type.id = Ast.IdArray;
				IF paramOut THEN
					Expression(gen, p.expr)
				ELSE
					CheckExpr(gen, p.expr)
				END;
				gen.opt.expectArray := FALSE;

				IF ~gen.opt.vla THEN
					WHILE j > 1 DO
						DEC(j);
						Text.Str(gen, "[0]")
					END
				END;

				IF (dist > 0) & ~gen.opt.plan9 THEN
					IF t.id = Ast.IdPointer THEN
						DEC(dist);
						Text.Str(gen, "->_")
					END;
					WHILE dist > 0 DO
						DEC(dist);
						Text.Str(gen, "._")
					END
				END;

				t := p.expr.type;
				IF (t.id = Ast.IdRecord)
				 & (~gen.opt.skipUnusedTag OR Ast.IsNeedTag(fp(Ast.FormalParam)))
				THEN
					IF gen.opt.lastSelectorDereference THEN
						Text.Str(gen, ", NULL")
					ELSE
						IF (p.expr(Ast.Designator).decl IS Ast.FormalParam)
						 & (p.expr(Ast.Designator).sel = NIL)
						THEN
							Text.Str(gen, ", ");
							Name(gen, p.expr(Ast.Designator).decl)
						ELSE
							Text.Str(gen, ", &");
							GlobalName(gen, t)
						END;
						Text.Str(gen, "_tag")
					END
				END
			END;

			p := p.next;
			fp := fp.next
		END ActualParam;
	BEGIN
		IF call.designator.decl IS Ast.PredefinedProcedure THEN
			Predefined(gen, call)
		ELSE
			Designator(gen, call.designator);
			Text.Str(gen, "(");
			p  := call.params;
			fp := call.designator.type(Ast.ProcType).params;
			IF p # NIL THEN
				ActualParam(gen, p, fp);
				WHILE p # NIL DO
					Text.Str(gen, ", ");
					ActualParam(gen, p, fp)
				END
			END;
			Text.Str(gen, ")")
		END
	END Call;

	PROCEDURE Relation(VAR gen: Generator; rel: Ast.ExprRelation);

		PROCEDURE Simple(VAR gen: Generator; rel: Ast.ExprRelation;
		                 str: ARRAY OF CHAR);
		VAR notChar0, notChar1: BOOLEAN;

			PROCEDURE Expr(VAR gen: Generator; e: Ast.Expression; dist: INTEGER);
			VAR brace: BOOLEAN;
			BEGIN
				brace := (e.type.id IN {Ast.IdSet, Ast.IdBoolean})
				      & ~(e IS Ast.Factor);
				IF brace THEN
					Text.Str(gen, "(")
				ELSIF (dist > 0) & (e.type.id = Ast.IdPointer) & ~gen.opt.plan9
				THEN
					Text.Str(gen, "&")
				END;
				Expression(gen, e);
				IF (dist > 0) & ~gen.opt.plan9 THEN
					IF e.type.id = Ast.IdPointer THEN
						DEC(dist);
						Text.Str(gen, "->_")
					END;
					WHILE dist > 0 DO
						DEC(dist);
						Text.Str(gen, "._")
					END
				END;
				IF brace THEN
					Text.Str(gen, ")")
				END
			END Expr;

			PROCEDURE Len(VAR gen: Generator; e: Ast.Expression);
			VAR des: Ast.Designator;
			BEGIN
				IF e.type(Ast.Array).count # NIL THEN
					Expression(gen, e.type(Ast.Array).count)
				ELSE
					des := e(Ast.Designator);
					ArrayDeclLen(gen, des.type, des.decl, des.sel, -1)
				END
			END Len;

			PROCEDURE IsArrayAndNotChar(e: Ast.Expression): BOOLEAN;
				RETURN (e.type.id = Ast.IdArray)
				     & ((e.value = NIL) OR ~e.value(Ast.ExprString).asChar)
			END IsArrayAndNotChar;
		BEGIN
			notChar0 := IsArrayAndNotChar(rel.exprs[0]);
			IF notChar0 OR IsArrayAndNotChar(rel.exprs[1]) THEN
				IF rel.value # NIL THEN
					Expression(gen, rel.value)
				ELSE
					notChar1 := ~notChar0 OR IsArrayAndNotChar(rel.exprs[1]);
					IF notChar0 = notChar1 THEN
						ASSERT(notChar0);
						Text.Str(gen, "o7_strcmp(")
					ELSIF notChar1 THEN
						Text.Str(gen, "o7_chstrcmp(")
					ELSE ASSERT(notChar0);
						Text.Str(gen, "o7_strchcmp(")
					END;
					IF notChar0 THEN
						Len(gen, rel.exprs[0]);
						Text.Str(gen, ", ")
					END;
					Expr(gen, rel.exprs[0], -rel.distance);

					Text.Str(gen, ", ");

					IF notChar1 THEN
						Len(gen, rel.exprs[1]);
						Text.Str(gen, ", ")
					END;
					Expr(gen, rel.exprs[1], rel.distance);

					Text.Str(gen, ")");
					Text.Str(gen, str);
					Text.Str(gen, "0")
				END
			ELSIF (gen.opt.varInit = VarInitUndefined)
			    & (rel.value = NIL)
			    & (rel.exprs[0].type.id IN {Ast.IdInteger, Ast.IdLongInt}) (* TODO *)
			    & (IsMayNotInited(rel.exprs[0]) OR IsMayNotInited(rel.exprs[1]))
			THEN
				IF rel.exprs[0].type.id  = Ast.IdInteger THEN
					Text.Str(gen, "o7_cmp(")
				ELSE
					Text.Str(gen, "o7_lcmp(")
				END;
				Expr(gen, rel.exprs[0], -rel.distance);
				Text.Str(gen, ", ");
				Expr(gen, rel.exprs[1], rel.distance);
				Text.Str(gen, ")");
				Text.Str(gen, str);
				Text.Str(gen, "0")
			ELSE
				Expr(gen, rel.exprs[0], -rel.distance);
				Text.Str(gen, str);
				Expr(gen, rel.exprs[1], rel.distance)
			END
		END Simple;

		PROCEDURE In(VAR gen: Generator; rel: Ast.ExprRelation);
		BEGIN
			IF (rel.value = NIL) (* TODO & option *)
			 & (rel.exprs[0].value # NIL)
			 & (rel.exprs[0].value(Ast.ExprInteger).int IN {0 .. Limits.SetMax})
			THEN
				Text.Str(gen, "!!(");
				Text.Str(gen, " (1u << ");
				Factor(gen, rel.exprs[0]);
				Text.Str(gen, ") & ");
				Factor(gen, rel.exprs[1]);
				Text.Str(gen, ")")
			ELSE
				IF rel.value # NIL THEN
					Text.Str(gen, "O7_IN(")
				ELSE
					Text.Str(gen, "o7_in(")
				END;
				Expression(gen, rel.exprs[0]);
				Text.Str(gen, ", ");
				Expression(gen, rel.exprs[1]);
				Text.Str(gen, ")")
			END
		END In;
	BEGIN
		CASE rel.relation OF
		  Scanner.Equal        : Simple(gen, rel, " == ")
		| Scanner.Inequal      : Simple(gen, rel, " != ")
		| Scanner.Less         : Simple(gen, rel, " < ")
		| Scanner.LessEqual    : Simple(gen, rel, " <= ")
		| Scanner.Greater      : Simple(gen, rel, " > ")
		| Scanner.GreaterEqual : Simple(gen, rel, " >= ")
		| Scanner.In           : In(gen, rel)
		END
	END Relation;

	PROCEDURE Sum(VAR gen: Generator; sum: Ast.ExprSum);
	VAR i: INTEGER;

		PROCEDURE CountSignChanges(sum: Ast.ExprSum): INTEGER;
		VAR i: INTEGER;
		BEGIN
			i := 0;
			IF sum # NIL THEN
				WHILE sum.next # NIL DO
					INC(i, ORD(sum.add # sum.next.add));
					sum := sum.next;
				END
			END
			RETURN i
		END CountSignChanges;
	BEGIN
		IF sum.type.id IN Ast.Sets THEN
			i := CountSignChanges(sum.next);
			Text.CharFill(gen, "(", i);
			IF sum.add = Ast.Minus THEN
				Text.Str(gen, " ~")
			END;
			CheckExpr(gen, sum.term);
			sum := sum.next;
			WHILE sum # NIL DO
				ASSERT(sum.type.id IN Ast.Sets);
				IF sum.add = Ast.Minus THEN
					Text.Str(gen, " & ~")
				ELSE ASSERT(sum.add = Ast.Plus);
					Text.Str(gen, " | ")
				END;
				CheckExpr(gen, sum.term);
				IF (sum.next # NIL) & (sum.next.add # sum.add) THEN
					Text.Char(gen, ")")
				END;
				sum := sum.next
			END;
		ELSIF sum.type.id = Ast.IdBoolean THEN
			CheckExpr(gen, sum.term);
			sum := sum.next;
			WHILE sum # NIL DO
				ASSERT(sum.type.id = Ast.IdBoolean);
				Text.Str(gen, " || ");
				CheckExpr(gen, sum.term);
				sum := sum.next;
			END;
		ELSE
			REPEAT
				ASSERT(sum.type.id IN {Ast.IdInteger, Ast.IdLongInt, Ast.IdReal, Ast.IdReal32});
				IF sum.add = Ast.Minus THEN
					Text.Str(gen, " - ")
				ELSIF sum.add = Ast.Plus THEN
					Text.Str(gen, " + ")
				END;
				CheckExpr(gen, sum.term);
				sum := sum.next;
			UNTIL sum = NIL
		END
	END Sum;

	PROCEDURE SumCheck(VAR gen: Generator; sum: Ast.ExprSum);
	VAR arr: ARRAY TranLim.TermsInSum OF Ast.ExprSum;
		i, last: INTEGER;

		PROCEDURE GenArrOfAddOrSub(VAR gen: Generator;
		                           arr: ARRAY OF Ast.ExprSum; last: INTEGER;
		                           add, sub: ARRAY OF CHAR);
		VAR i: INTEGER;
		BEGIN
			i := last;
			WHILE i > 0 DO
				CASE arr[i].add OF
				  Scanner.Minus:
					Text.Str(gen, sub)
				| Scanner.Plus:
					Text.Str(gen, add)
				END;
				DEC(i)
			END;
			IF arr[0].add = Scanner.Minus THEN
				Text.Str(gen, sub);
				Text.Str(gen, "0, ");
				Expression(gen, arr[0].term);
				Text.Str(gen, ")")
			ELSE
				Expression(gen, arr[0].term)
			END
		END GenArrOfAddOrSub;
	BEGIN
		last := -1;
		REPEAT
			INC(last);
			arr[last] := sum;
			sum := sum.next
		UNTIL sum = NIL;
		CASE arr[0].type.id OF
		  Ast.IdInteger:
			GenArrOfAddOrSub(gen, arr, last, "o7_add("  , "o7_sub(")
		| Ast.IdLongInt:
			GenArrOfAddOrSub(gen, arr, last, "o7_ladd(" , "o7_lsub(")
		| Ast.IdReal:
			GenArrOfAddOrSub(gen, arr, last, "o7_fadd(" , "o7_fsub(")
		| Ast.IdReal32:
			GenArrOfAddOrSub(gen, arr, last, "o7_faddf(", "o7_fsubf(")
		END;
		i := 0;
		WHILE i < last DO
			INC(i);
			Text.Str(gen, ", ");
			Expression(gen, arr[i].term);
			Text.Str(gen, ")")
		END
	END SumCheck;

	PROCEDURE Term(VAR gen: Generator; term: Ast.ExprTerm);
	BEGIN
		REPEAT
			CheckExpr(gen, term.factor);
			CASE term.mult OF
			  Scanner.Asterisk           :
				IF term.type.id IN Ast.Sets THEN
					Text.Str(gen, " & ")
				ELSE
					Text.Str(gen, " * ")
				END
			| Scanner.Slash, Scanner.Div :
				IF term.type.id IN Ast.Sets THEN
					ASSERT(term.mult = Scanner.Slash);
					Text.Str(gen, " ^ ")
				ELSE
					Text.Str(gen, " / ")
				END
			| Scanner.And                : Text.Str(gen, " && ")
			| Scanner.Mod                : Text.Str(gen, " % ")
			END;
			IF term.expr IS Ast.ExprTerm THEN
				term := term.expr(Ast.ExprTerm)
			ELSE
				CheckExpr(gen, term.expr);
				term := NIL
			END
		UNTIL term = NIL
	END Term;

	PROCEDURE TermCheck(VAR gen: Generator; term: Ast.ExprTerm);
	VAR arr: ARRAY TranLim.FactorsInTerm OF Ast.ExprTerm;
		i, last: INTEGER;
	BEGIN
		arr[0] := term;
		i := 0;
		WHILE term.expr IS Ast.ExprTerm DO
			INC(i);
			term := term.expr(Ast.ExprTerm);
			arr[i] := term
		END;
		last := i;
		CASE term.type.id OF
		  Ast.IdInteger:
			WHILE i >= 0 DO
				CASE arr[i].mult OF
				  Scanner.Asterisk : Text.Str(gen, "o7_mul(")
				| Scanner.Div      : Text.Str(gen, "o7_div(")
				| Scanner.Mod      : Text.Str(gen, "o7_mod(")
				END;
				DEC(i)
			END
		| Ast.IdLongInt:
			WHILE i >= 0 DO
				CASE arr[i].mult OF
				  Scanner.Asterisk : Text.Str(gen, "o7_lmul(")
				| Scanner.Div      : Text.Str(gen, "o7_ldiv(")
				| Scanner.Mod      : Text.Str(gen, "o7_lmod(")
				END;
				DEC(i)
			END
		| Ast.IdReal:
			WHILE i >= 0 DO
				CASE arr[i].mult OF
				  Scanner.Asterisk : Text.Str(gen, "o7_fmul(")
				| Scanner.Slash    : Text.Str(gen, "o7_fdiv(")
				END;
				DEC(i)
			END
		| Ast.IdReal32:
			WHILE i >= 0 DO
				CASE arr[i].mult OF
				  Scanner.Asterisk : Text.Str(gen, "o7_fmulf(")
				| Scanner.Slash    : Text.Str(gen, "o7_fdivf(")
				END;
				DEC(i)
			END
		END;
		Expression(gen, arr[0].factor);
		i := 0;
		WHILE i < last DO
			INC(i);
			Text.Str(gen, ", ");
			Expression(gen, arr[i].factor);
			Text.Str(gen, ")")
		END;
		Text.Str(gen, ", ");
		Expression(gen, arr[last].expr);
		Text.Str(gen, ")")
	END TermCheck;

	PROCEDURE Boolean(VAR gen: Generator; e: Ast.ExprBoolean);
	BEGIN
		IF gen.opt.std = IsoC90 THEN
			IF e.bool
			THEN Text.Str(gen, "(0 < 1)")
			ELSE Text.Str(gen, "(0 > 1)")
			END
		ELSE
			IF e.bool
			THEN Text.Str(gen, "true")
			ELSE Text.Str(gen, "false")
			END
		END
	END Boolean;

	PROCEDURE CString(VAR gen: Generator; e: Ast.ExprString);
	VAR s1: ARRAY 6 OF CHAR;
		s2: ARRAY 3 OF CHAR;
		ch: CHAR;
		w: Strings.String;

		PROCEDURE ToHex(d: INTEGER): CHAR;
		BEGIN
			ASSERT(d IN {0 .. 0FH});
			IF d < 10 THEN
				INC(d, ORD("0"))
			ELSE
				INC(d, ORD("A") - 10)
			END
			RETURN CHR(d)
		END ToHex;
	BEGIN
		w := e.string;
		Log.Str("e.asChar = "); Log.Bool(e.asChar);
		Log.Str(" expectArray = "); Log.Bool(gen.opt.expectArray); Log.Ln;
		IF e.asChar & ~gen.opt.expectArray THEN
			ch := CHR(e.int);
			IF ch = "'" THEN
				Text.Str(gen, "(o7_char)'\''")
			ELSIF ch = "\" THEN
				Text.Str(gen, "(o7_char)'\\'")
			ELSIF (ch >= " ") & (ch <= CHR(127)) THEN
				Text.Str(gen, "(o7_char)");
				s2[0] := "'";
				s2[1] := ch;
				s2[2] := "'";
				Text.Str(gen, s2)
			ELSE
				Text.Str(gen, "0x");
				s2[0] := ToHex(e.int DIV 16);
				s2[1] := ToHex(e.int MOD 16);
				s2[2] := "u";
				Text.Str(gen, s2)
			END
		ELSE
			IF ~gen.insideSizeOf THEN
				Text.Str(gen, "(o7_char *)")
			END;
			IF (w.ofs >= 0) & (w.block.s[w.ofs] = Utf8.DQuote) THEN
				Text.ScreeningString(gen, w)
			ELSE
				s1[0] := Utf8.DQuote;
				s1[1] := "\";
				s1[2] := "x";
				s1[3] := ToHex(e.int DIV 16);
				s1[4] := ToHex(e.int MOD 16);
				s1[5] := Utf8.DQuote;
				Text.Str(gen, s1)
			END
		END
	END CString;

	PROCEDURE ExprInt(VAR gen: Generator; int: INTEGER);
	BEGIN
		IF int >= 0 THEN
			Text.Int(gen, int)
		ELSE
			Text.Str(gen, "(-");
			Text.Int(gen, -int);
			Text.Str(gen, ")")
		END
	END ExprInt;

	PROCEDURE ExprLongInt(VAR gen: Generator; int: INTEGER);
	BEGIN
		ASSERT(FALSE);
		IF int >= 0 THEN
			Text.Int(gen, int)
		ELSE
			Text.Str(gen, "(-");
			Text.Int(gen, -int);
			Text.Str(gen, ")")
		END
	END ExprLongInt;

	PROCEDURE SetValue(VAR gen: Generator; set: Ast.ExprSetValue);
	BEGIN
		(* TODO *)
		ASSERT(set.set[1] = {});

		Text.Str(gen, "0x");
		Text.Set(gen, set.set[0]);
		Text.Char(gen, "u")
	END SetValue;

	PROCEDURE Set(VAR gen: Generator; set: Ast.ExprSet);
		PROCEDURE Item(VAR gen: Generator; set: Ast.ExprSet);
		BEGIN
			IF set.exprs[0] = NIL THEN
				Text.Char(gen, "0")
			ELSE
				IF set.exprs[1] = NIL THEN
					Text.Str(gen, "(1u << ");
					Factor(gen, set.exprs[0])
				ELSE
					IF (set.exprs[0].value = NIL) OR (set.exprs[1].value = NIL)
					THEN Text.Str(gen, "o7_set(")
					ELSE Text.Str(gen, "O7_SET(")
					END;
					Expression(gen, set.exprs[0]);
					Text.Str(gen, ", ");
					Expression(gen, set.exprs[1])
				END;
				Text.Str(gen, ")")
			END
		END Item;
	BEGIN
		IF set.next = NIL THEN
			Item(gen, set)
		ELSE
			Text.Str(gen, "(");
			Item(gen, set);
			REPEAT
				Text.Str(gen, " | ");
				set := set.next;
				Item(gen, set)
			UNTIL set.next = NIL;
			Text.Str(gen, ")")
		END
	END Set;

	PROCEDURE IsExtension(VAR gen: Generator; is: Ast.ExprIsExtension);
	VAR decl: Ast.Declaration;
		extType: Ast.Type;
	BEGIN
		decl := is.designator.decl;
		extType := is.extType;
		IF is.designator.type.id = Ast.IdPointer THEN
			extType := extType.type;
			ASSERT(CheckStructName(gen, extType(Ast.Record)));
			Text.Str(gen, "o7_is(");
			Expression(gen, is.designator);
			Text.Str(gen, ", &")
		ELSE
			Text.Str(gen, "o7_is_r(");
			GlobalName(gen, decl);
			Text.Str(gen, "_tag, ");
			GlobalName(gen, decl);
			Text.Str(gen, ", &")
		END;
		GlobalName(gen, extType);
		Text.Str(gen, "_tag)")
	END IsExtension;
BEGIN
	CASE expr.id OF
	  Ast.IdInteger:
		ExprInt(gen, expr(Ast.ExprInteger).int)
	| Ast.IdLongInt:
		ExprLongInt(gen, expr(Ast.ExprInteger).int)
	| Ast.IdBoolean:
		Boolean(gen, expr(Ast.ExprBoolean))
	| Ast.IdReal, Ast.IdReal32:
		IF Strings.IsDefined(expr(Ast.ExprReal).str)
		THEN	Text.String(gen, expr(Ast.ExprReal).str)
		ELSE	Text.Real(gen, expr(Ast.ExprReal).real)
		END
	| Ast.IdString:
		CString(gen, expr(Ast.ExprString))
	| Ast.IdSet, Ast.IdLongSet:
		IF expr IS Ast.ExprSet THEN
			Set(gen, expr(Ast.ExprSet))
		ELSE
			SetValue(gen, expr(Ast.ExprSetValue))
		END
	| Ast.IdCall:
		Call(gen, expr(Ast.ExprCall))
	| Ast.IdDesignator:
		Log.Str("Expr Designator type.id = ");
		Log.Int(expr.type.id);
		Log.Str(" (expr.value # NIL) = ");
		Log.Bool(expr.value # NIL);
		IF expr.value # NIL THEN
			Log.Str(" expr.value.id = ");
			Log.Int(expr.value.id)
		END;
		Log.Ln;
		IF (expr.value # NIL) & (expr.value.id = Ast.IdString)
		THEN	CString(gen, expr.value(Ast.ExprString))
		ELSE	Designator(gen, expr(Ast.Designator))
		END
	| Ast.IdRelation:
		Relation(gen, expr(Ast.ExprRelation))
	| Ast.IdSum:
		IF	  gen.opt.checkArith
			& (expr.type.id IN CheckableArithTypes)
			& (expr.value = NIL)
		THEN	SumCheck(gen, expr(Ast.ExprSum))
		ELSE	Sum(gen, expr(Ast.ExprSum))
		END
	| Ast.IdTerm:
		IF	  gen.opt.checkArith
			& (expr.type.id IN CheckableArithTypes)
			& (expr.value = NIL)
		THEN
			TermCheck(gen, expr(Ast.ExprTerm))
		ELSIF (expr.value # NIL)
		    & (Ast.ExprIntNegativeDividentTouch IN expr.properties)
		THEN
			Expression(gen, expr.value)
		ELSE
			Term(gen, expr(Ast.ExprTerm))
		END
	| Ast.IdNegate:
		IF expr.type.id IN Ast.Sets THEN
			Text.Str(gen, "~");
			Expression(gen, expr(Ast.ExprNegate).expr)
		ELSE
			Text.Str(gen, "!");
			CheckExpr(gen, expr(Ast.ExprNegate).expr)
		END
	| Ast.IdBraces:
		Text.Str(gen, "(");
		Expression(gen, expr(Ast.ExprBraces).expr);
		Text.Str(gen, ")")
	| Ast.IdPointer:
		Text.Str(gen, "NULL")
	| Ast.IdIsExtension:
		IsExtension(gen, expr(Ast.ExprIsExtension))
	END
END Expression;

PROCEDURE Qualifier(VAR gen: Generator; typ: Ast.Type);
BEGIN
	CASE typ.id OF
	  Ast.IdInteger:
		Text.Str(gen, "o7_int_t")
	| Ast.IdLongInt:
		Text.Str(gen, "o7_long_t")
	| Ast.IdSet:
		Text.Str(gen, "o7_set_t")
	| Ast.IdLongSet:
		Text.Str(gen, "o7_set64_t")
	| Ast.IdBoolean:
		IF (gen.opt.std >= IsoC99)
		 & (gen.opt.varInit # VarInitUndefined)
		THEN	Text.Str(gen, "bool")
		ELSE	Text.Str(gen, "o7_bool")
		END
	| Ast.IdByte:
		Text.Str(gen, "char unsigned")
	| Ast.IdChar:
		Text.Str(gen, "o7_char")
	| Ast.IdReal:
		Text.Str(gen, "double")
	| Ast.IdReal32:
		Text.Str(gen, "float")
	| Ast.IdPointer, Ast.IdProcType:
		GlobalName(gen, typ)
	END
END Qualifier;

PROCEDURE Invert(VAR gen: Generator);
BEGIN
	gen.memout.invert := ~gen.memout.invert
END Invert;

PROCEDURE ProcHead(VAR gen: Generator; proc: Ast.ProcType);

	PROCEDURE Parameters(VAR gen: Generator; proc: Ast.ProcType);
	VAR p: Ast.Declaration;

		PROCEDURE Par(VAR gen: Generator; fp: Ast.FormalParam);
		VAR t: Ast.Type;
			i: INTEGER;
		BEGIN
			i := 0;
			t := fp.type;
			WHILE (t.id = Ast.IdArray) & (t(Ast.Array).count = NIL) DO
				Text.Str(gen, "o7_int_t ");
				Name(gen, fp);
				Text.Str(gen, "_len");
				Text.Int(gen, i);
				Text.Str(gen, ", ");
				INC(i);
				t := t.type
			END;
			t := fp.type;
			declarator(gen, fp, FALSE, FALSE(*TODO*), FALSE);
			IF (t.id = Ast.IdRecord)
			 & (~gen.opt.skipUnusedTag OR Ast.IsNeedTag(fp))
			THEN
				Text.Str(gen, ", o7_tag_t *");
				Name(gen, fp);
				Text.Str(gen, "_tag")
			END
		END Par;
	BEGIN
		IF proc.params = NIL THEN
			Text.Str(gen, "(void)")
		ELSE
			Text.Str(gen, "(");
			p := proc.params;
			WHILE p # proc.end DO
				Par(gen, p(Ast.FormalParam));
				Text.Str(gen, ", ");
				p := p.next
			END;
			Par(gen, p(Ast.FormalParam));
			Text.Str(gen, ")")
		END
	END Parameters;
BEGIN
	Parameters(gen, proc);
	Invert(gen);
	type(gen, NIL, proc.type, FALSE, FALSE(* TODO *));
	MemWriteInvert(gen.memout^)
END ProcHead;

PROCEDURE Declarator(VAR gen: Generator; decl: Ast.Declaration;
                     typeDecl, sameType, global: BOOLEAN);
VAR g: Generator;
	mo: PMemoryOut;
BEGIN
	mo := PMemoryOutGet(gen.opt);

	Text.Init(g, mo);
	g.memout := mo;
	Text.SetTabs(g, gen);
	g.module := gen.module;
	g.interface := gen.interface;
	g.opt := gen.opt;

	IF (decl IS Ast.FormalParam) &
	   ((Ast.ParamOut IN decl(Ast.FormalParam).access)
	   & ~(decl.type IS Ast.Array)
	   OR (decl.type IS Ast.Record)
	   )
	THEN
		Text.Str(g, "*")
	ELSIF decl IS Ast.Const THEN
		Text.Str(g, "const ")
	END;
	IF global THEN
		GlobalName(g, decl)
	ELSE
		Name(g, decl)
	END;
	IF decl IS Ast.Procedure THEN
		ProcHead(g, decl(Ast.Procedure).header)
	ELSE
		mo.invert := ~mo.invert;
		IF decl IS Ast.Type THEN
			type(g, decl, decl(Ast.Type), typeDecl, FALSE)
		ELSE
			type(g, decl, decl.type, FALSE, sameType)
		END
	END;

	MemWriteDirect(gen, mo^);

	PMemoryOutBack(gen.opt, mo)
END Declarator;

PROCEDURE RecordUndefHeader(VAR gen: Generator; rec: Ast.Record; interf: BOOLEAN);
BEGIN
	IF rec.mark & ~gen.opt.main THEN
		Text.Str(gen, "extern void ")
	ELSE
		Text.Str(gen, "static void ")
	END;
	GlobalName(gen, rec);
	Text.Str(gen, "_undef(struct ");
	GlobalName(gen, rec);
	IF interf THEN
		Text.StrLn(gen, " *r);")
	ELSE
		Text.StrOpen(gen, " *r) {")
	END
END RecordUndefHeader;

PROCEDURE RecordRetainReleaseHeader(VAR gen: Generator; rec: Ast.Record;
                                    interf: BOOLEAN; retrel: ARRAY OF CHAR);
BEGIN
	IF rec.mark & ~gen.opt.main  THEN
		Text.Str(gen, "extern void ")
	ELSE
		Text.Str(gen, "static void ")
	END;
	GlobalName(gen, rec);
	Text.Str(gen, retrel);
	Text.Str(gen, "(struct ");
	GlobalName(gen, rec);
	IF interf THEN
		Text.StrLn(gen, " *r);")
	ELSE
		Text.StrOpen(gen, " *r) {")
	END
END RecordRetainReleaseHeader;

PROCEDURE RecordReleaseHeader(VAR gen: Generator; rec: Ast.Record; interf: BOOLEAN);
BEGIN
	RecordRetainReleaseHeader(gen, rec, interf, "_release")
END RecordReleaseHeader;

PROCEDURE RecordRetainHeader(VAR gen: Generator; rec: Ast.Record; interf: BOOLEAN);
BEGIN
	RecordRetainReleaseHeader(gen, rec, interf, "_retain")
END RecordRetainHeader;

PROCEDURE IsArrayTypeSimpleUndef(typ: Ast.Type; VAR id, deep: INTEGER): BOOLEAN;
BEGIN
	deep := 0;
	WHILE typ.id = Ast.IdArray DO
		INC(deep);
		typ := typ.type
	END;
	id := typ.id
	RETURN id IN {Ast.IdReal, Ast.IdReal32, Ast.IdInteger, Ast.IdLongInt, Ast.IdBoolean}
END IsArrayTypeSimpleUndef;

PROCEDURE ArraySimpleUndef(VAR gen: Generator; arrTypeId: INTEGER;
                           d: Ast.Declaration; inRec: BOOLEAN);
BEGIN
	CASE arrTypeId OF
	  Ast.IdInteger:
		Text.Str(gen, "O7_INTS_UNDEF(")
	| Ast.IdLongInt:
		Text.Str(gen, "O7_LONGS_UNDEF(")
	| Ast.IdReal:
		Text.Str(gen, "O7_DOUBLES_UNDEF(")
	| Ast.IdReal32:
		Text.Str(gen, "O7_FLOATS_UNDEF(")
	| Ast.IdBoolean:
		Text.Str(gen, "O7_BOOLS_UNDEF(")
	END;
	IF inRec THEN
		Text.Str(gen, "r->")
	END;
	Name(gen, d);
	Text.Str(gen, ");")
END ArraySimpleUndef;

PROCEDURE RecordUndefCall(VAR gen: Generator; var: Ast.Declaration);
BEGIN
	GlobalName(gen, var.type);
	Text.Str(gen, "_undef(&");
	GlobalName(gen, var);
	Text.StrLn(gen, ");")
END RecordUndefCall;

PROCEDURE TypeForUndef(t: Ast.Type): Ast.Type;
BEGIN
	IF (t.id # Ast.IdRecord) OR (t.ext = NIL) OR ~t.ext(RecExt).undef THEN
		t := NIL
	END
	RETURN t
END TypeForUndef;

(* TODO Навести порядок *)
PROCEDURE RecordUndef(VAR gen: Generator; rec: Ast.Record);
VAR var: Ast.Declaration;
	arrTypeId, arrDeep: INTEGER;
	typeUndef: Ast.Type;

	PROCEDURE IteratorIfNeed(VAR gen: Generator; var: Ast.Declaration);
	VAR id, deep: INTEGER;
	BEGIN
		WHILE (var # NIL)
		    & ((var.type.id # Ast.IdArray)
		    OR IsArrayTypeSimpleUndef(var.type, id, deep)
		    OR (TypeForUndef(var.type.type) = NIL))
		DO
			var := var.next
		END;
		IF var # NIL THEN
			Text.StrLn(gen, "o7_int_t i;")
		END
	END IteratorIfNeed;

	PROCEDURE Memset(VAR gen: Generator; var: Ast.Declaration);
	BEGIN
		Text.Str(gen, "memset(&r->");
		Name(gen, var);
		Text.Str(gen, ", 0, sizeof(r->");
		Name(gen, var);
		Text.StrLn(gen, "));")
	END Memset;
BEGIN
	RecordUndefHeader(gen, rec, FALSE);
	IteratorIfNeed(gen, rec.vars);
	IF rec.base # NIL THEN
		GlobalName(gen, rec.base);
		IF ~gen.opt.plan9 THEN
			Text.StrLn(gen, "_undef(&r->_);")
		ELSE
			Text.StrLn(gen, "_undef(r);")
		END
	END;
	rec.ext(RecExt).undef := TRUE;
	var := rec.vars;
	WHILE var # NIL DO
		IF ~(var.type.id IN {Ast.IdArray, Ast.IdRecord}) THEN
			Text.Str(gen, "r->");
			Name(gen, var);
			VarInit(gen, var, TRUE);
			Text.StrLn(gen, ";");
		ELSIF var.type.id = Ast.IdArray THEN
			typeUndef := TypeForUndef(var.type.type);
			IF IsArrayTypeSimpleUndef(var.type, arrTypeId, arrDeep) THEN
				ArraySimpleUndef(gen, arrTypeId, var, TRUE)
			ELSIF typeUndef # NIL THEN (* TODO вложенные циклы *)
				Text.Str(gen, "for (i = 0; i < O7_LEN(r->");
				Name(gen, var);
				Text.StrOpen(gen, "); i += 1) {");
				GlobalName(gen, typeUndef);
				Text.Str(gen, "_undef(r->");
				Name(gen, var);
				Text.StrLn(gen, " + i);");

				Text.StrLnClose(gen, "}")
			ELSE
				Memset(gen, var)
			END
		ELSIF (var.type.id = Ast.IdRecord) & (var.type.ext # NIL) THEN
			GlobalName(gen, var.type);
			Text.Str(gen, "_undef(&r->");
			Name(gen, var);
			Text.StrLn(gen, ");")
		ELSE
			Memset(gen, var)
		END;
		var := var.next
	END;
	Text.StrLnClose(gen, "}")
END RecordUndef;

PROCEDURE RecordRetainRelease(VAR gen: Generator; rec: Ast.Record;
                              retrel, retrelArray, retNull: ARRAY OF CHAR);
VAR var: Ast.Declaration;

	PROCEDURE IteratorIfNeed(VAR gen: Generator; var: Ast.Declaration);
	BEGIN
		WHILE (var # NIL)
		    & ~((var.type.id = Ast.IdArray)
		      & (var.type.type.id = Ast.IdRecord)
		       )
		DO
			var := var.next
		END;
		IF var # NIL THEN
			Text.StrLn(gen, "o7_int_t i;")
		END
	END IteratorIfNeed;
BEGIN
	RecordRetainReleaseHeader(gen, rec, FALSE, retrel);

	IteratorIfNeed(gen, rec.vars);
	IF rec.base # NIL THEN
		GlobalName(gen, rec.base);
		Text.Str(gen, retrel);
		IF ~gen.opt.plan9 THEN
			Text.StrLn(gen, "(&r->_);")
		ELSE
			Text.StrLn(gen, "(r);")
		END
	END;
	var := rec.vars;
	WHILE var # NIL DO
		IF var.type.id = Ast.IdArray THEN
			IF var.type.type.id = Ast.IdPointer THEN (* TODO *)
				Text.Str(gen, retrelArray);
				Name(gen, var);
				Text.StrLn(gen, ");")
			ELSIF (var.type.type.id = Ast.IdRecord)
			   & (var.type.type.ext # NIL) & var.type.type.ext(RecExt).undef
			THEN
				Text.Str(gen, "for (i = 0; i < O7_LEN(r->");
				Name(gen, var);
				Text.StrOpen(gen, "); i += 1) {");
				GlobalName(gen, var.type.type);
				Text.Str(gen, retrel);
				Text.Str(gen, "(r->");
				Name(gen, var);
				Text.StrLn(gen, " + i);");
				Text.StrLnClose(gen, "}")
			END
		ELSIF (var.type.id = Ast.IdRecord) & (var.type.ext # NIL) THEN
			GlobalName(gen, var.type);
			Text.Str(gen, retrel);
			Text.Str(gen, "(&r->");
			Name(gen, var);
			Text.StrLn(gen, ");")
		ELSIF var.type.id = Ast.IdPointer THEN
			Text.Str(gen, retNull);
			Text.Str(gen, "r->");
			Name(gen, var);
			Text.StrLn(gen, ");")
		END;
		var := var.next
	END;
	Text.StrLnClose(gen, "}")
END RecordRetainRelease;

PROCEDURE RecordRelease(VAR gen: Generator; rec: Ast.Record);
BEGIN
	RecordRetainRelease(gen, rec, "_release", "O7_RELEASE_ARRAY(r->", "O7_NULL(&")
END RecordRelease;

PROCEDURE RecordRetain(VAR gen: Generator; rec: Ast.Record);
BEGIN
	RecordRetainRelease(gen, rec, "_retain", "O7_RETAIN_ARRAY(r->", "o7_retain(")
END RecordRetain;

PROCEDURE EmptyLines(VAR gen: Generator; d: Ast.Declaration);
BEGIN
	IF 0 < d.emptyLines THEN
		Text.Ln(gen)
	END
END EmptyLines;

PROCEDURE Type(VAR gen: Generator; decl: Ast.Declaration; typ: Ast.Type;
               typeDecl, sameType: BOOLEAN);

	PROCEDURE Simple(VAR gen: Generator; str: ARRAY OF CHAR);
	BEGIN
		Text.Str(gen, str);
		MemWriteInvert(gen.memout^)
	END Simple;

	PROCEDURE Record(VAR gen: Generator; rec: Ast.Record);
	VAR v: Ast.Declaration;
	BEGIN
		rec.module := gen.module.bag;
		Text.Str(gen, "struct ");
		IF CheckStructName(gen, rec) THEN
			GlobalName(gen, rec)
		END;
		v := rec.vars;
		IF (v = NIL) & (rec.base = NIL) & ~gen.opt.gnu THEN
			Text.Str(gen, " { char nothing; } ")
		ELSE
			Text.StrOpen(gen, " {");

			IF rec.base # NIL THEN
				GlobalName(gen, rec.base);
				IF gen.opt.plan9 THEN
					Text.StrLn(gen, ";")
				ELSE
					Text.StrLn(gen, " _;")
				END
			END;

			WHILE v # NIL DO
				EmptyLines(gen, v);
				Declarator(gen, v, FALSE, FALSE, FALSE);
				Text.StrLn(gen, ";");
				v := v.next
			END;
			Text.StrClose(gen, "} ")
		END;
		MemWriteInvert(gen.memout^)
	END Record;

	PROCEDURE Array(VAR gen: Generator; decl: Ast.Declaration; arr: Ast.Array;
	                sameType: BOOLEAN);
	VAR t: Ast.Type;
		i: INTEGER;
	BEGIN
		t := arr.type;
		MemWriteInvert(gen.memout^);
		IF arr.count # NIL THEN
			Text.Str(gen, "[");
			Expression(gen, arr.count);
			Text.Str(gen, "]")
		ELSIF gen.opt.vla THEN
			i := 0;
			t := arr;
			REPEAT
				Text.Data(gen, "[O7_VLA(", 0, 1 + ORD(gen.opt.vlaMark) * 8);
				Name(gen, decl);
				Text.Str(gen, "_len");
				Text.Int(gen, i);
				Text.Data(gen, ")]", ORD(~gen.opt.vlaMark), 2 - ORD(~gen.opt.vlaMark));
				t := t.type;
				INC(i)
			UNTIL t.id # Ast.IdArray
		ELSE
			Text.Str(gen, "[/*len0");
			i := 0;
			WHILE t.id = Ast.IdArray DO
				INC(i);
				Text.Str(gen, ", len");
				Text.Int(gen, i);
				t := t.type
			END;
			Text.Str(gen, "*/]")
		END;
		Invert(gen);
		Type(gen, decl, t, FALSE, sameType)
	END Array;
BEGIN
	IF typ = NIL THEN
		Text.Str(gen, "void ");
		MemWriteInvert(gen.memout^)
	ELSE
		IF ~typeDecl & Strings.IsDefined(typ.name) THEN
			IF sameType THEN
				IF (typ IS Ast.Pointer) & Strings.IsDefined(typ.type.name)
				THEN	Text.Str(gen, "*")
				END
			ELSE
				IF (typ IS Ast.Pointer) & Strings.IsDefined(typ.type.name)
				THEN
					Text.Str(gen, "struct ");
					GlobalName(gen, typ.type); Text.Str(gen, " *")
				ELSIF typ IS Ast.Record THEN
					Text.Str(gen, "struct ");
					IF CheckStructName(gen, typ(Ast.Record)) THEN
						GlobalName(gen, typ); Text.Str(gen, " ")
					END
				ELSE
					GlobalName(gen, typ); Text.Str(gen, " ")
				END;
				IF gen.memout # NIL THEN
					MemWriteInvert(gen.memout^)
				END
			END
		ELSIF ~sameType OR (typ.id IN {Ast.IdPointer, Ast.IdArray, Ast.IdProcType})
		THEN
			CASE typ.id OF
			  Ast.IdInteger:
				Simple(gen, "o7_int_t ")
			| Ast.IdLongInt:
				Simple(gen, "o7_long_t ")
			| Ast.IdSet:
				Simple(gen, "o7_set_t ")
			| Ast.IdLongSet:
				Simple(gen, "o7_set64_t ")
			| Ast.IdBoolean:
				IF (gen.opt.std >= IsoC99)
				 & (gen.opt.varInit # VarInitUndefined)
				THEN	Simple(gen, "bool ")
				ELSE	Simple(gen, "o7_bool ")
				END
			| Ast.IdByte:
				Simple(gen, "char unsigned ")
			| Ast.IdChar:
				Simple(gen, "o7_char ")
			| Ast.IdReal:
				Simple(gen, "double ")
			| Ast.IdReal32:
				Simple(gen, "float ")
			| Ast.IdPointer:
				Text.Str(gen, "*");
				MemWriteInvert(gen.memout^);
				Invert(gen);
				Type(gen, decl, typ.type, FALSE, sameType)
			| Ast.IdArray:
				Array(gen, decl, typ(Ast.Array), sameType)
			| Ast.IdRecord:
				Record(gen, typ(Ast.Record))
			| Ast.IdProcType:
				Text.Str(gen, "(*");
				MemWriteInvert(gen.memout^);
				Text.Str(gen, ")");
				ProcHead(gen, typ(Ast.ProcType))
			END
		END;
		IF gen.memout # NIL THEN
			MemWriteInvert(gen.memout^)
		END
	END
END Type;

PROCEDURE RecordTag(VAR gen: Generator; rec: Ast.Record);
BEGIN
	IF (gen.opt.memManager # MemManagerCounter) & (rec.base = NIL) THEN
		Text.Str(gen, "#define ");
		GlobalName(gen, rec);
		Text.StrLn(gen, "_tag o7_base_tag");
	ELSIF (gen.opt.memManager # MemManagerCounter)
	    & ~rec.needTag & gen.opt.skipUnusedTag
	THEN
		Text.Str(gen, "#define ");
		GlobalName(gen, rec);
		Text.Str(gen, "_tag ");
		GlobalName(gen, rec.base);
		Text.StrLn(gen, "_tag")
	ELSE
		IF ~rec.mark OR gen.opt.main THEN
			Text.Str(gen, "static o7_tag_t ")
		ELSIF gen.interface THEN
			Text.Str(gen, "extern o7_tag_t ")
		ELSE
			Text.Str(gen, "o7_tag_t ")
		END;
		GlobalName(gen, rec);
		Text.StrLn(gen, "_tag;")
	END;
	IF ~rec.mark OR gen.opt.main OR gen.interface THEN
		Text.Ln(gen)
	END
END RecordTag;

PROCEDURE TypeDecl(VAR out: MOut; typ: Ast.Type);

	PROCEDURE Typedef(VAR gen: Generator; typ: Ast.Type);
	BEGIN
		EmptyLines(gen, typ);
		Text.Str(gen, "typedef ");
		Declarator(gen, typ, TRUE, FALSE, TRUE);
		Text.StrLn(gen, ";")
	END Typedef;

	PROCEDURE LinkRecord(opt: Options; rec: Ast.Record);
	VAR ext: RecExt;
	BEGIN
		ASSERT(rec.ext = NIL);
		NEW(ext); V.Init(ext^);
		Strings.Undef(ext.anonName);
		ext.next := NIL;
		ext.undef := FALSE;
		rec.ext := ext;

		IF opt.records = NIL THEN
			opt.records := rec
		ELSE
			opt.recordLast.ext(RecExt).next := rec
		END;
		opt.recordLast := rec
	END LinkRecord;
BEGIN
	Typedef(out.g[ORD(typ.mark & ~out.opt.main)], typ);
	IF (typ.id = Ast.IdRecord)
	OR (typ.id = Ast.IdPointer) & (typ.type.next = NIL)
	THEN
		IF typ.id = Ast.IdPointer THEN
			typ := typ.type
		END;
		typ.mark := typ.mark
		         OR (typ(Ast.Record).pointer # NIL)
		          & (typ(Ast.Record).pointer.mark);
		LinkRecord(out.opt, typ(Ast.Record));
		IF typ.mark & ~out.opt.main THEN
			RecordTag(out.g[Interface], typ(Ast.Record));
			IF out.opt.varInit = VarInitUndefined THEN
				RecordUndefHeader(out.g[Interface], typ(Ast.Record), TRUE)
			END;
			IF out.opt.memManager = MemManagerCounter THEN
				RecordReleaseHeader(out.g[Interface], typ(Ast.Record), TRUE);
				IF Ast.TypeAssigned IN typ.properties THEN
					RecordRetainHeader(out.g[Interface], typ(Ast.Record), TRUE)
				END
			END
		END;
		IF (~typ.mark OR out.opt.main)
		OR (typ(Ast.Record).base # NIL) OR ~typ(Ast.Record).needTag
		THEN
			RecordTag(out.g[Implementation], typ(Ast.Record))
		END;
		IF out.opt.varInit = VarInitUndefined THEN
			RecordUndef(out.g[Implementation], typ(Ast.Record))
		END;
		IF out.opt.memManager = MemManagerCounter THEN
			RecordRelease(out.g[Implementation], typ(Ast.Record));
			IF Ast.TypeAssigned IN typ.properties THEN
				RecordRetain(out.g[Implementation], typ(Ast.Record))
			END
		END
	END
END TypeDecl;

PROCEDURE Mark(VAR gen: Generator; mark: BOOLEAN);
BEGIN
	IF gen.localDeep = 0 THEN
		IF mark & ~gen.opt.main THEN
			Text.Str(gen, "extern ")
		ELSE
			Text.Str(gen, "static ")
		END
	END
END Mark;

PROCEDURE Comment(VAR gen: Generator; com: Strings.String);
VAR i: Strings.Iterator;
	prev: CHAR;
BEGIN
	IF gen.opt.comment & Strings.GetIter(i, com, 0) THEN
		REPEAT
			prev := i.char
		UNTIL ~Strings.IterNext(i)
		   OR (prev = "/") & (i.char = "*")
		   OR (prev = "*") & (i.char = "/");

		IF i.char = Utf8.Null THEN
			Text.Str(gen, "/*");
			Text.String(gen, com);
			Text.StrLn(gen, "*/")
		END
	END
END Comment;

PROCEDURE Const(VAR gen: Generator; const: Ast.Const);
BEGIN
	Comment(gen, const.comment);
	EmptyLines(gen, const);
	Text.StrIgnoreIndent(gen, "#");
	Text.Str(gen, "define ");
	GlobalName(gen, const);
	Text.Str(gen, " ");
	IF const.mark & (const.expr.value # NIL) THEN
		Factor(gen, const.expr.value)
	ELSE
		Factor(gen, const.expr)
	END;
	Text.Ln(gen)
END Const;

PROCEDURE Var(VAR out: MOut; prev, var: Ast.Declaration; last: BOOLEAN);
VAR same, mark: BOOLEAN;
BEGIN
	mark := var.mark & ~out.opt.main;
	Comment(out.g[ORD(mark)], var.comment);
	EmptyLines(out.g[ORD(mark)], var);
	same := (prev # NIL) & (prev.mark = mark) & (prev.type = var.type);
	IF ~same THEN
		IF prev # NIL THEN
			Text.StrLn(out.g[ORD(mark)], ";")
		END;
		Mark(out.g[ORD(mark)], mark)
	ELSE
		Text.Str(out.g[ORD(mark)], ", ")
	END;
	IF mark THEN
		Declarator(out.g[Interface], var, FALSE, same, TRUE);
		IF last THEN
			Text.StrLn(out.g[Interface], ";")
		END;

		IF same THEN
			Text.Str(out.g[Implementation], ", ")
		ELSIF prev # NIL THEN
			Text.StrLn(out.g[Implementation], ";")
		END
	END;

	Declarator(out.g[Implementation], var, FALSE, same, TRUE);

	VarInit(out.g[Implementation], var, FALSE);

	IF last THEN
		Text.StrLn(out.g[Implementation], ";")
	END
END Var;

PROCEDURE ExprThenStats(VAR gen: Generator; VAR wi: Ast.WhileIf);
BEGIN
	CheckExpr(gen, wi.expr);
	Text.StrOpen(gen, ") {");
	statements(gen, wi.stats);
	wi := wi.elsif
END ExprThenStats;

PROCEDURE IsCaseElementWithRange(elem: Ast.CaseElement): BOOLEAN;
VAR r: Ast.CaseLabel;
BEGIN
	r := elem.labels;
	WHILE (r # NIL) & (r.right = NIL) DO
		r := r.next
	END
	RETURN r # NIL
END IsCaseElementWithRange;

PROCEDURE ExprSameType(VAR gen: Generator;
                       expr: Ast.Expression; expectType: Ast.Type);
VAR reref, brace: BOOLEAN;
    base, extend: Ast.Record;
BEGIN
	base := NIL;
	reref := (expr.type.id = Ast.IdPointer)
	       & (expr.type.type # expectType.type)
	       & (expr.id # Ast.IdPointer);
	brace := reref;
	IF ~reref THEN
		CheckExpr(gen, expr);
		IF expr.type.id = Ast.IdRecord THEN
			base := expectType(Ast.Record);
			extend := expr.type(Ast.Record)
		END
	ELSIF gen.opt.plan9 THEN
		CheckExpr(gen, expr);
		brace := FALSE
	ELSE
		base := expectType.type(Ast.Record);
		extend := expr.type.type(Ast.Record).base;
		Text.Str(gen, "(&(");
		Expression(gen, expr);
		Text.Str(gen, ")->_")
	END;
	IF (base # NIL) & (extend # base) THEN
		(*ASSERT(expectType.id = Ast.IdRecord);*)
		IF gen.opt.plan9 THEN
			Text.Str(gen, ".");
			GlobalName(gen, expectType)
		ELSE
			WHILE extend # base DO
				Text.Str(gen, "._");
				extend := extend.base
			END
		END
	END;
	IF brace THEN
		Text.Str(gen, ")")
	END
END ExprSameType;

PROCEDURE ExprForSize(VAR gen: Generator; e: Ast.Expression);
BEGIN
	gen.insideSizeOf := TRUE;
	Expression(gen, e);
	gen.insideSizeOf := FALSE
END ExprForSize;

PROCEDURE Assign(VAR gen: Generator; st: Ast.Assign);

	PROCEDURE Equal(VAR gen: Generator; st: Ast.Assign);
	VAR retain, toByte: BOOLEAN;

		PROCEDURE AssertArraySize(VAR gen: Generator;
		                          des: Ast.Designator; e: Ast.Expression);
		BEGIN
			IF gen.opt.checkIndex
			 & (  (des.type(Ast.Array).count = NIL)
			   OR (e.type(Ast.Array).count   = NIL)
			   )
			THEN
				Text.Str(gen, "assert(");
				ArrayLen(gen, des);
				Text.Str(gen, " >= ");
				ArrayLen(gen, e);
				Text.StrLn(gen, ");")
			END
		END AssertArraySize;
	BEGIN
		toByte := (st.designator.type.id = Ast.IdByte)
		        & (st.expr.type.id IN {Ast.IdInteger, Ast.IdLongInt})
		        & gen.opt.checkArith & (st.expr.value = NIL);
		retain := (st.designator.type.id = Ast.IdPointer)
		        & (gen.opt.memManager = MemManagerCounter);
		IF retain & (st.expr.id = Ast.IdPointer) THEN
			Text.Str(gen, "O7_NULL(&");
			Designator(gen, st.designator);
		ELSE
			IF retain THEN
				Text.Str(gen, "O7_ASSIGN(&");
				Designator(gen, st.designator);
				Text.Str(gen, ", ")
			ELSIF (st.designator.type.id = Ast.IdArray)
			THEN
				AssertArraySize(gen, st.designator, st.expr);
				Text.Str(gen, "memcpy(");
				Designator(gen, st.designator);
				Text.Str(gen, ", ");
				gen.opt.expectArray := TRUE
			ELSIF toByte THEN
				Designator(gen, st.designator);
				IF st.expr.type.id = Ast.IdInteger THEN
					Text.Str(gen, " = o7_byte(")
				ELSE
					Text.Str(gen, " = o7_lbyte(")
				END
			ELSE
				Designator(gen, st.designator);
				Text.Str(gen, " = ")
			END;
			ExprSameType(gen, st.expr, st.designator.type);
			gen.opt.expectArray := FALSE;
			IF st.designator.type.id # Ast.IdArray THEN
				;
			ELSIF (st.expr.type(Ast.Array).count # NIL)
			    & ~Ast.IsFormalParam(st.expr)
			THEN
				IF (st.expr IS Ast.ExprString) & st.expr(Ast.ExprString).asChar
				THEN
					Text.Str(gen, ", 2")
				ELSE
					Text.Str(gen, ", sizeof(");
					ExprForSize(gen, st.expr);
					Text.Str(gen, ")")
				END
			ELSE
				Text.Str(gen, ", (");
				ArrayLen(gen, st.expr);
				Text.Str(gen, ") * sizeof(");
				ExprForSize(gen, st.expr);
				Text.Str(gen, "[0])")
			END
		END;
		CASE ORD(retain) + ORD(toByte)
		   + ORD(st.designator.type.id = Ast.IdArray)
		OF
		  0: ;
		| 1: Text.Str(gen, ")")
		| 2: Text.Str(gen, "))")
		END;
		IF (gen.opt.memManager = MemManagerCounter)
		 & (st.designator.type.id = Ast.IdRecord)
		 & (~IsAnonStruct(st.designator.type(Ast.Record)))
		THEN
			Text.StrLn(gen, ";");
			GlobalName(gen, st.designator.type);
			Text.Str(gen, "_retain(&");
			Designator(gen, st.designator);
			Text.Str(gen, ")")
		END
	END Equal;
BEGIN
	Equal(gen, st)
END Assign;

PROCEDURE Statement(VAR gen: Generator; st: Ast.Statement);

	PROCEDURE WhileIf(VAR gen: Generator; wi: Ast.WhileIf);

		PROCEDURE Elsif(VAR gen: Generator; VAR wi: Ast.WhileIf);
		BEGIN
			WHILE (wi # NIL) & (wi.expr # NIL) DO
				Text.StrClose(gen, "} else if (");
				ExprThenStats(gen, wi)
			END
		END Elsif;
	BEGIN
		IF wi IS Ast.If THEN
			Text.Str(gen, "if (");
			ExprThenStats(gen, wi);
			Elsif(gen, wi);
			IF wi # NIL THEN
				Text.IndentClose(gen);
				Text.StrOpen(gen, "} else {");
				statements(gen, wi.stats)
			END;
			Text.StrLnClose(gen, "}")
		ELSIF wi.elsif = NIL THEN
			Text.Str(gen, "while (");
			ExprThenStats(gen, wi);
			Text.StrLnClose(gen, "}")
		ELSE
			Text.Str(gen, "while (1) if (");
			ExprThenStats(gen, wi);
			Elsif(gen, wi);
			Text.StrLnClose(gen, "} else break;")
		END
	END WhileIf;

	PROCEDURE Repeat(VAR gen: Generator; st: Ast.Repeat);
	VAR e: Ast.Expression;
	BEGIN
		Text.StrOpen(gen, "do {");
		statements(gen, st.stats);
		IF st.expr.id = Ast.IdNegate THEN
			Text.StrClose(gen, "} while (");
			e := st.expr(Ast.ExprNegate).expr;
			WHILE e.id = Ast.IdBraces DO
				e := e(Ast.ExprBraces).expr
			END;
			Expression(gen, e);
			Text.StrLn(gen, ");")
		ELSE
			Text.StrClose(gen, "} while (!(");
			CheckExpr(gen, st.expr);
			Text.StrLn(gen, "));")
		END
	END Repeat;

	PROCEDURE For(VAR gen: Generator; st: Ast.For);
		PROCEDURE IsEndMinus1(sum: Ast.ExprSum): BOOLEAN;
		RETURN (sum.next # NIL)
		     & (sum.next.next = NIL)
		     & (sum.next.add = Scanner.Minus)
		     & (sum.next.term.value # NIL)
		     & (sum.next.term.value(Ast.ExprInteger).int = 1)
		END IsEndMinus1;
	BEGIN
		Text.Str(gen, "for (");
		GlobalName(gen, st.var);
		Text.Str(gen, " = ");
		Expression(gen, st.expr);
		Text.Str(gen, "; ");
		GlobalName(gen, st.var);
		IF st.by > 0 THEN
			IF (st.to IS Ast.ExprSum) & IsEndMinus1(st.to(Ast.ExprSum)) THEN
				Text.Str(gen, " < ");
				Expression(gen, st.to(Ast.ExprSum).term)
			ELSE
				Text.Str(gen, " <= ");
				Expression(gen, st.to)
			END;
			IF st.by = 1 THEN
				Text.Str(gen, "; ++");
				GlobalName(gen, st.var)
			ELSE
				Text.Str(gen, "; ");
				GlobalName(gen, st.var);
				Text.Str(gen, " += ");
				Text.Int(gen, st.by)
			END
		ELSE
			Text.Str(gen, " >= ");
			Expression(gen, st.to);
			IF st.by = -1 THEN
				Text.Str(gen, "; --");
				GlobalName(gen, st.var)
			ELSE
				Text.Str(gen, "; ");
				GlobalName(gen, st.var);
				Text.Str(gen, " -= ");
				Text.Int(gen, -st.by)
			END
		END;
		Text.StrOpen(gen, ") {");
		statements(gen, st.stats);
		Text.StrLnClose(gen, "}")
	END For;

	PROCEDURE Case(VAR gen: Generator; st: Ast.Case);
	VAR elem, elemWithRange: Ast.CaseElement;
	    caseExpr: Ast.Expression;

		PROCEDURE CaseElement(VAR gen: Generator; elem: Ast.CaseElement);
		VAR r: Ast.CaseLabel;
		BEGIN
			IF gen.opt.gnu OR ~IsCaseElementWithRange(elem) THEN
				r := elem.labels;
				WHILE r # NIL DO
					Text.Str(gen, "case ");
					Text.Int(gen, r.value);
					IF r.right # NIL THEN
						ASSERT(gen.opt.gnu);
						Text.Str(gen, " ... ");
						Text.Int(gen, r.right.value)
					END;
					Text.StrLn(gen, ":");

					r := r.next
				END;
				Text.IndentOpen(gen);
				statements(gen, elem.stats);
				Text.StrLn(gen, "break;");
				Text.IndentClose(gen)
			END
		END CaseElement;

		PROCEDURE CaseElementAsIf(VAR gen: Generator; elem: Ast.CaseElement;
		                          caseExpr: Ast.Expression);
		VAR r: Ast.CaseLabel;

			PROCEDURE CaseRange(VAR gen: Generator; r: Ast.CaseLabel;
			                    caseExpr: Ast.Expression);
			BEGIN
				IF r.right = NIL THEN
					IF caseExpr = NIL THEN
						Text.Str(gen, "(o7_case_expr == ")
					ELSE
						Text.Str(gen, "(");
						Expression(gen, caseExpr);
						Text.Str(gen, " == ")
					END;
					Text.Int(gen, r.value)
				ELSE
					ASSERT(r.value <= r.right.value);
					Text.Str(gen, "(");
					Text.Int(gen, r.value);
					IF caseExpr = NIL THEN
						Text.Str(gen, " <= o7_case_expr && o7_case_expr <= ")
					ELSE
						Text.Str(gen, " <= ");
						Expression(gen, caseExpr);
						Text.Str(gen, " && ");
						Expression(gen, caseExpr);
						Text.Str(gen, " <= ")
					END;
					Text.Int(gen, r.right.value)
				END;
				Text.Str(gen, ")")
			END CaseRange;
		BEGIN
			Text.Str(gen, "if (");
			r := elem.labels;
			ASSERT(r # NIL);
			CaseRange(gen, r, caseExpr);
			WHILE r.next # NIL DO
				r := r.next;
				Text.Str(gen, " || ");
				CaseRange(gen, r, caseExpr)
			END;
			Text.StrOpen(gen, ") {");
			statements(gen, elem.stats);
			Text.StrClose(gen, "}")
		END CaseElementAsIf;
	BEGIN
		IF gen.opt.gnu THEN
			elemWithRange := NIL
		ELSE
			elemWithRange := st.elements;
			WHILE (elemWithRange # NIL) & ~IsCaseElementWithRange(elemWithRange)
			DO
				elemWithRange := elemWithRange.next
			END
		END;
		IF (elemWithRange # NIL)
		 & (st.expr.value = NIL)
		 & (~(st.expr IS Ast.Designator) OR (st.expr(Ast.Designator).sel # NIL))
		THEN
			caseExpr := NIL;
			Text.Str(gen, "{ o7_int_t o7_case_expr = ");
			Expression(gen, st.expr);
			Text.StrOpen(gen, ";");
			Text.StrLn(gen, "switch (o7_case_expr) {")
		ELSE
			caseExpr := st.expr;
			Text.Str(gen, "switch (");
			Expression(gen, caseExpr);
			Text.StrLn(gen, ") {")
		END;
		elem := st.elements;
		REPEAT
			CaseElement(gen, elem);
			elem := elem.next
		UNTIL elem = NIL;
		Text.StrOpen(gen, "default:");
		IF elemWithRange # NIL THEN
			elem := elemWithRange;
			CaseElementAsIf(gen, elem, caseExpr);
			elem := elem.next;
			WHILE elem # NIL DO
				IF IsCaseElementWithRange(elem) THEN
					Text.Str(gen, " else ");
					CaseElementAsIf(gen, elem, caseExpr)
				END;
				elem := elem.next
			END;
			IF ~gen.opt.caseAbort THEN
				;
			ELSIF caseExpr = NIL THEN
				Text.StrLn(gen, " else o7_case_fail(o7_case_expr);")
			ELSE
				Text.Str(gen, " else o7_case_fail(");
				Expression(gen, caseExpr);
				Text.StrLn(gen, ");")
			END
		ELSIF ~gen.opt.caseAbort THEN
			;
		ELSIF caseExpr = NIL THEN
			Text.StrLn(gen, "o7_case_fail(o7_case_expr);")
		ELSE
			Text.Str(gen, "o7_case_fail(");
			Expression(gen, caseExpr);
			Text.StrLn(gen, ");")
		END;
		Text.StrLn(gen, "break;");
		Text.StrLnClose(gen, "}");
		IF caseExpr = NIL THEN
			Text.StrLnClose(gen, "}")
		END
	END Case;
BEGIN
	Comment(gen, st.comment);
	IF 0 < st.emptyLines THEN
		Text.Ln(gen)
	END;
	IF st IS Ast.Assign THEN
		Assign(gen, st(Ast.Assign));
		Text.StrLn(gen, ";")
	ELSIF st IS Ast.Call THEN
		gen.expressionSemicolon := TRUE;
		Expression(gen, st.expr);
		IF gen.expressionSemicolon THEN
			Text.StrLn(gen, ";")
		ELSE
			Text.Ln(gen)
		END
	ELSIF st IS Ast.WhileIf THEN
		WhileIf(gen, st(Ast.WhileIf))
	ELSIF st IS Ast.Repeat THEN
		Repeat(gen, st(Ast.Repeat))
	ELSIF st IS Ast.For THEN
		For(gen, st(Ast.For))
	ELSE ASSERT(st IS Ast.Case);
		Case(gen, st(Ast.Case))
	END
END Statement;

PROCEDURE Statements(VAR gen: Generator; stats: Ast.Statement);
BEGIN
	WHILE stats # NIL DO
		Statement(gen, stats);
		stats := stats.next
	END
END Statements;

PROCEDURE ProcDecl(VAR gen: Generator; proc: Ast.Procedure);
BEGIN
	Mark(gen, proc.mark);
	Declarator(gen, proc, FALSE, FALSE, TRUE);
	Text.StrLn(gen, ";")
END ProcDecl;

PROCEDURE ReleaseVars(VAR gen: Generator; var: Ast.Declaration);
BEGIN
	IF gen.opt.memManager = MemManagerCounter THEN
		WHILE (var # NIL) & (var.id = Ast.IdVar) DO
			IF var.type.id = Ast.IdArray THEN
				IF var.type.type.id = Ast.IdPointer THEN (* TODO *)
					Text.Str(gen, "O7_RELEASE_ARRAY(");
					GlobalName(gen, var);
					Text.StrLn(gen, ");")
				ELSIF (var.type.type.id = Ast.IdRecord)
				    & (var.type.type.ext # NIL) & var.type.type.ext(RecExt).undef
				THEN
					Text.Str(gen, "{int o7_i; for (o7_i = 0; o7_i < O7_LEN(");
					GlobalName(gen, var);
					Text.StrOpen(gen, "); o7_i += 1) {");
					GlobalName(gen, var.type.type);
					Text.Str(gen, "_release(");
					GlobalName(gen, var);
					Text.StrLn(gen, " + o7_i);");
					Text.StrLnClose(gen, "}}")
				END
			ELSIF var.type.id = Ast.IdPointer THEN
				Text.Str(gen, "O7_NULL(&");
				GlobalName(gen, var);
				Text.StrLn(gen, ");");
			ELSIF (var.type.id = Ast.IdRecord) & (var.type.ext # NIL) THEN
				GlobalName(gen, var.type);
				Text.Str(gen, "_release(&");
				GlobalName(gen, var);
				Text.StrLn(gen, ");")
			END;

			var := var.next
		END
	END
END ReleaseVars;

PROCEDURE Procedure(VAR out: MOut; proc: Ast.Procedure);

	PROCEDURE Implement(VAR out: MOut; VAR gen: Generator; proc: Ast.Procedure);
	VAR retainParams: Ast.Declaration;

		PROCEDURE CloseConsts(VAR gen: Generator; consts: Ast.Declaration);
		BEGIN
			WHILE (consts # NIL) & (consts IS Ast.Const) DO
				Text.StrIgnoreIndent(gen, "#");
				Text.Str(gen, "undef ");
				Name(gen, consts);
				Text.Ln(gen);
				consts := consts.next
			END
		END CloseConsts;

		PROCEDURE SearchRetain(gen: Generator; fp: Ast.Declaration): Ast.Declaration;
		BEGIN
			WHILE (fp # NIL)
			    & ((fp.type.id # Ast.IdPointer)
			    OR (Ast.ParamOut IN fp(Ast.FormalParam).access)
			      )
			DO
				fp := fp.next
			END
			RETURN fp
		END SearchRetain;

		PROCEDURE RetainParams(VAR gen: Generator; fp: Ast.Declaration);
		BEGIN
			IF fp # NIL THEN
				Text.Str(gen, "o7_retain(");
				Name(gen, fp);
				fp := fp.next;
				WHILE fp # NIL DO
					IF (fp.type.id = Ast.IdPointer)
					 & ~(Ast.ParamOut IN fp(Ast.FormalParam).access)
					THEN
						Text.Str(gen, "); o7_retain(");
						Name(gen, fp)
					END;
					fp := fp.next
				END;
				Text.StrLn(gen, ");")
			END
		END RetainParams;

		PROCEDURE ReleaseParams(VAR gen: Generator; fp: Ast.Declaration);
		BEGIN
			IF fp # NIL THEN
				Text.Str(gen, "o7_release(");
				Name(gen, fp);
				fp := fp.next;
				WHILE fp # NIL DO
					IF (fp.type.id = Ast.IdPointer)
					 & ~(Ast.ParamOut IN fp(Ast.FormalParam).access)
					THEN
						Text.Str(gen, "); o7_release(");
						Name(gen, fp)
					END;
					fp := fp.next
				END;
				Text.StrLn(gen, ");")
			END
		END ReleaseParams;

	BEGIN
		Comment(gen, proc.comment);
		Mark(gen, proc.mark);
		Declarator(gen, proc, FALSE, FALSE(*TODO*), TRUE);
		Text.StrOpen(gen, " {");

		INC(gen.localDeep);

		gen.fixedLen := gen.len;

		IF gen.opt.memManager # MemManagerCounter THEN
			retainParams := NIL
		ELSE
			retainParams := SearchRetain(gen, proc.header.params);
			IF proc.return # NIL THEN
				Qualifier(gen, proc.return.type);
				IF proc.return.type.id = Ast.IdPointer
				THEN	Text.StrLn(gen, " o7_return = NULL;")
				ELSE	Text.StrLn(gen, " o7_return;")
				END
			END
		END;
		declarations(out, proc);

		RetainParams(gen, retainParams);

		Statements(gen, proc.stats);

		IF proc.return = NIL THEN
			ReleaseVars(gen, proc.vars);
			ReleaseParams(gen, retainParams)
		ELSIF gen.opt.memManager = MemManagerCounter THEN
			IF proc.return.type.id = Ast.IdPointer THEN
				Text.Str(gen, "O7_ASSIGN(&o7_return, ");
				Expression(gen, proc.return);
				Text.StrLn(gen, ");")
			ELSE
				Text.Str(gen, "o7_return = ");
				CheckExpr(gen, proc.return);
				Text.StrLn(gen, ";")
			END;
			ReleaseVars(gen, proc.vars);
			ReleaseParams(gen, retainParams);
			IF proc.return.type.id = Ast.IdPointer THEN
				Text.StrLn(gen, "o7_unhold(o7_return);")
			END;
			Text.StrLn(gen, "return o7_return;")
		ELSE
			Text.Str(gen, "return ");
			ExprSameType(gen, proc.return, proc.header.type);
			Text.StrLn(gen, ";")
		END;

		DEC(gen.localDeep);
		CloseConsts(gen, proc.start);
		Text.StrLnClose(gen, "}");
		Text.Ln(gen)
	END Implement;

	PROCEDURE LocalProcs(VAR out: MOut; proc: Ast.Procedure);
	VAR p, t: Ast.Declaration;
	BEGIN
		t := proc.types;
		WHILE (t # NIL) & (t IS Ast.Type) DO
			TypeDecl(out, t(Ast.Type));
			(*IF t IS Ast.Record THEN
				RecordTag(out.g[Implementation], t(Ast.Record))
			END;*)
			t := t.next
		END;
		p := proc.procedures;
		IF (p # NIL) & ~out.opt.procLocal THEN
			IF ~proc.mark THEN
				(* TODO также проверить наличие рекурсии из локальных процедур*)
				ProcDecl(out.g[Implementation], proc)
			END;
			REPEAT
				Procedure(out, p(Ast.Procedure));
				p := p.next
			UNTIL p = NIL
		END
	END LocalProcs;
BEGIN
	LocalProcs(out, proc);
	IF proc.mark & ~out.opt.main THEN
		ProcDecl(out.g[Interface], proc)
	END;
	Implement(out, out.g[Implementation], proc)
END Procedure;

PROCEDURE LnIfWrote(VAR out: MOut);

	PROCEDURE Write(VAR gen: Generator);
	BEGIN
		IF gen.fixedLen # gen.len THEN
			Text.Ln(gen);
			gen.fixedLen := gen.len
		END
	END Write;
BEGIN
	IF ~out.opt.main THEN
		Write(out.g[Interface])
	END;
	Write(out.g[Implementation])
END LnIfWrote;

PROCEDURE VarsInit(VAR gen: Generator; d: Ast.Declaration);
VAR arrDeep, arrTypeId: INTEGER;
BEGIN
	WHILE (d # NIL) & (d IS Ast.Var) DO
		IF d.type.id IN {Ast.IdArray, Ast.IdRecord} THEN
			IF (gen.opt.varInit = VarInitUndefined)
			 & (d.type.id = Ast.IdRecord) & Strings.IsDefined(d.type.name)
			 & Ast.IsGlobal(d.type)
			THEN
				RecordUndefCall(gen, d)
			ELSIF (gen.opt.varInit = VarInitZero)
			OR (d.type.id = Ast.IdRecord)
			OR    (d.type.id = Ast.IdArray)
			    & ~IsArrayTypeSimpleUndef(d.type, arrTypeId, arrDeep)
			THEN
				Text.Str(gen, "memset(&");
				Name(gen, d);
				Text.Str(gen, ", 0, sizeof(");
				Name(gen, d);
				Text.StrLn(gen, "));")
			ELSE
				ASSERT(gen.opt.varInit = VarInitUndefined);
				ArraySimpleUndef(gen, arrTypeId, d, FALSE)
			END
		END;
		d := d.next
	END
END VarsInit;

PROCEDURE Declarations(VAR out: MOut; ds: Ast.Declarations);
VAR d, prev: Ast.Declaration; inModule: BOOLEAN;
BEGIN
	d := ds.start;
	inModule := ds IS Ast.Module;
	ASSERT((d = NIL) OR ~(d IS Ast.Module));
	WHILE (d # NIL) & (d IS Ast.Import) DO
		Import(out.g[ORD(~out.opt.main)], d);
		d := d.next
	END;
	LnIfWrote(out);

	WHILE (d # NIL) & (d IS Ast.Const) DO
		Const(out.g[ORD(d.mark & ~out.opt.main)], d(Ast.Const));
		d := d.next
	END;
	LnIfWrote(out);

	IF inModule THEN
		WHILE (d # NIL) & (d IS Ast.Type) DO
			TypeDecl(out, d(Ast.Type));
			d := d.next
		END;
		LnIfWrote(out);

		WHILE (d # NIL) & (d IS Ast.Var) DO
			Var(out, NIL, d, TRUE);
			d := d.next
		END
	ELSE
		d := ds.vars;

		prev := NIL;
		WHILE (d # NIL) & (d IS Ast.Var) DO
			Var(out, prev, d, (d.next = NIL) OR ~(d.next IS Ast.Var));
			prev := d;
			d := d.next
		END;
		IF out.opt.varInit # VarInitNo THEN
			VarsInit(out.g[Implementation], ds.vars)
		END;

		d := ds.procedures
	END;
	LnIfWrote(out);

	IF inModule OR out.opt.procLocal THEN
		WHILE d # NIL DO
			Procedure(out, d(Ast.Procedure));
			d := d.next
		END
	END
END Declarations;

PROCEDURE DefaultOptions*(): Options;
VAR o: Options;
BEGIN
	NEW(o);
	IF o # NIL THEN
		V.Init(o^);

		o.std           := IsoC90;
		o.gnu           := FALSE;
		o.plan9         := FALSE;
		o.procLocal     := FALSE;
		o.checkIndex    := TRUE;
		o.vla           := FALSE & (IsoC99 <= o.std);
		o.vlaMark       := TRUE;
		o.checkArith    := TRUE;
		o.caseAbort     := TRUE;
		o.checkNil      := TRUE;
		o.o7Assert      := TRUE;
		o.skipUnusedTag := TRUE;
		o.comment       := TRUE;
		o.generatorNote := TRUE;
		o.varInit       := VarInitUndefined;
		o.memManager    := MemManagerNoFree;
		o.identEnc      := IdentEncEscUnicode;

		o.expectArray := FALSE;

		o.main := FALSE;

		o.memOuts := NIL
	END
	RETURN o
END DefaultOptions;


PROCEDURE MarkExpression(e: Ast.Expression);
BEGIN
	IF e # NIL THEN
		IF e.id = Ast.IdRelation THEN
			MarkExpression(e(Ast.ExprRelation).exprs[0]);
			MarkExpression(e(Ast.ExprRelation).exprs[1])
		ELSIF e.id = Ast.IdTerm THEN
			MarkExpression(e(Ast.ExprTerm).factor);
			MarkExpression(e(Ast.ExprTerm).expr)
		ELSIF e.id = Ast.IdSum THEN
			MarkExpression(e(Ast.ExprSum).term);
			MarkExpression(e(Ast.ExprSum).next)
		ELSIF (e.id = Ast.IdDesignator)
			& ~e(Ast.Designator).decl.mark
		THEN
			e(Ast.Designator).decl.mark := TRUE;
			MarkExpression(e(Ast.Designator).decl(Ast.Const).expr)
		END
	END
END MarkExpression;

PROCEDURE MarkType(t: Ast.Type);
VAR d: Ast.Declaration;
BEGIN
	WHILE (t # NIL) & ~t.mark DO
		t.mark := TRUE;
		IF t.id = Ast.IdArray THEN
			MarkExpression(t(Ast.Array).count);
			t := t.type
		ELSIF t.id IN {Ast.IdRecord, Ast.IdPointer} THEN
			IF t.id = Ast.IdPointer THEN
				t := t.type;
				t.mark := TRUE;
				ASSERT(t.module # NIL)
			END;
			d := t(Ast.Record).vars;
			WHILE d # NIL DO
				MarkType(d.type);
				(*IF Strings.IsDefined(d.name) THEN
					Log.StrLn(d.name.block.s)
				END;*)
				d := d.next
			END;
			t := t(Ast.Record).base
		ELSE
			t := NIL
		END
	END
END MarkType;

PROCEDURE MarkUsedInMarked(m: Ast.Module);
VAR imp: Ast.Declaration;

	PROCEDURE Consts(c: Ast.Declaration);
	BEGIN
		WHILE (c # NIL) & (c IS Ast.Const) DO
			IF c.mark THEN
				MarkExpression(c(Ast.Const).expr)
			END;
			c := c.next
		END
	END Consts;

	PROCEDURE Types(t: Ast.Declaration);
	BEGIN
		WHILE (t # NIL) & (t IS Ast.Type) DO
			IF t.mark THEN
				t.mark := FALSE;
				MarkType(t(Ast.Type))
			END;
			t := t.next
		END
	END Types;

	PROCEDURE Procs(p: Ast.Declaration);
	VAR fp: Ast.Declaration;
	BEGIN
		WHILE (p # NIL) & (p IS Ast.Procedure) DO
			IF p.mark THEN
				fp := p(Ast.Procedure).header.params;
				WHILE fp # NIL DO
					MarkType(fp.type);
					fp := fp.next
				END
			END;
			p := p.next
		END
	END Procs;

BEGIN
	imp := m.import;
	WHILE (imp # NIL) & (imp IS Ast.Import) DO
		MarkUsedInMarked(imp.module.m);
		imp := imp.next
	END;
	Consts(m.consts);
	Types(m.types);
	Procs(m.procedures)
END MarkUsedInMarked;

PROCEDURE ImportInitDone(VAR gen: Generator; imp: Ast.Declaration;
                         initDone: ARRAY OF CHAR);
BEGIN
	IF imp # NIL THEN
		ASSERT(imp IS Ast.Import);

		REPEAT
			Name(gen, imp.module.m);
			Text.StrLn(gen, initDone);

			imp := imp.next
		UNTIL (imp = NIL) OR ~(imp IS Ast.Import);
		Text.Ln(gen)
	END
END ImportInitDone;

PROCEDURE ImportInit(VAR gen: Generator; imp: Ast.Declaration);
BEGIN
	ImportInitDone(gen, imp, "_init();")
END ImportInit;

PROCEDURE ImportDone(VAR gen: Generator; imp: Ast.Declaration);
BEGIN
	ImportInitDone(gen, imp, "_done();")
END ImportDone;

PROCEDURE TagsInit(VAR gen: Generator);
VAR r: Ast.Record;
BEGIN
	r := NIL;
	WHILE gen.opt.records # NIL DO
		r := gen.opt.records;
		gen.opt.records := r.ext(RecExt).next;
		r.ext(RecExt).next := NIL;

		IF (gen.opt.memManager = MemManagerCounter)
		OR (r.base # NIL) & (r.needTag OR ~gen.opt.skipUnusedTag)
		THEN
			Text.Str(gen, "O7_TAG_INIT(");
			GlobalName(gen, r);
			IF r.base # NIL THEN
				Text.Str(gen, ", ");
				GlobalName(gen, r.base);
				Text.StrLn(gen, ");")
			ELSE
				Text.StrLn(gen, ", o7_base);")
			END
		END
	END;
	IF r # NIL THEN
		Text.Ln(gen)
	END
END TagsInit;

PROCEDURE Generate*(interface, implementation: Stream.POut;
                    module: Ast.Module; cmd: Ast.Statement; opt: Options);
VAR out: MOut;

	PROCEDURE Init(VAR gen: Generator; out: Stream.POut;
	               module: Ast.Module; opt: Options; interface: BOOLEAN);
	BEGIN
		Text.Init(gen, out);
		gen.module := module;
		gen.localDeep := 0;

		gen.opt := opt;

		gen.fixedLen := gen.len;

		gen.interface := interface;

		gen.insideSizeOf := FALSE;

		gen.memout := NIL
	END Init;

	PROCEDURE Includes(VAR gen: Generator);
	BEGIN
		IF gen.opt.std >= IsoC99 THEN
			Text.StrLn(gen, "#include <stdbool.h>")
		END;
		Text.StrLn(gen, "#include <o7.h>");
		Text.Ln(gen)
	END Includes;

	PROCEDURE HeaderGuard(VAR gen: Generator);
	BEGIN
		Text.Str(gen, "#if !defined HEADER_GUARD_");
		Text.String(gen, gen.module.name);
		Text.Ln(gen);
		Text.Str(gen, "#    define  HEADER_GUARD_");
		Text.String(gen, gen.module.name);
		Text.StrLn(gen, " 1");
		Text.Ln(gen)
	END HeaderGuard;

	PROCEDURE ModuleInit(VAR interf, impl: Generator; module: Ast.Module;
	                     cmd: Ast.Statement);
	BEGIN
		IF (module.import = NIL)
		 & (module.stats = NIL) & (cmd = NIL)
		 & (impl.opt.records = NIL)
		THEN
			IF impl.opt.std >= IsoC99 THEN
				Text.Str(interf, "static inline void ")
			ELSE
				Text.Str(interf, "O7_INLINE void ")
			END;
			Name(interf, module);
			Text.StrLn(interf, "_init(void) { ; }")
		ELSE
			Text.Str(interf, "extern void ");
			Name(interf, module);
			Text.StrLn(interf, "_init(void);");

			Text.Str(impl, "extern void ");
			Name(impl, module);
			Text.StrOpen(impl, "_init(void) {");
			Text.StrLn(impl, "static unsigned initialized = 0;");
			Text.StrOpen(impl, "if (0 == initialized) {");
			ImportInit(impl, module.import);
			TagsInit(impl);
			Statements(impl, module.stats);
			Statements(impl, cmd);
			Text.StrLnClose(impl, "}");
			Text.StrLn(impl, "++initialized;");
			Text.StrLnClose(impl, "}");
			Text.Ln(impl)
		END
	END ModuleInit;

	PROCEDURE ModuleDone(VAR interf, impl: Generator; module: Ast.Module);
	BEGIN
		IF (impl.opt.memManager # MemManagerCounter) THEN
			;
		ELSIF (module.import = NIL) & (impl.opt.records = NIL) THEN
			IF impl.opt.std >= IsoC99 THEN
				Text.Str(interf, "static inline void ")
			ELSE
				Text.Str(interf, "O7_INLINE void ")
			END;
			Name(interf, module);
			Text.StrLn(interf, "_done(void) { ; }")
		ELSE
			Text.Str(interf, "extern void ");
			Name(interf, module);
			Text.StrLn(interf, "_done(void);");

			Text.Str(impl, "extern void ");
			Name(impl, module);
			Text.StrOpen(impl, "_done(void) {");
			ReleaseVars(impl, module.vars);
			ImportDone(impl, module.import);
			Text.StrLnClose(impl, "}");
			Text.Ln(impl)
		END
	END ModuleDone;

	PROCEDURE Main(VAR gen: Generator; module: Ast.Module; cmd: Ast.Statement);
	BEGIN
		Text.StrOpen(gen, "extern int main(int argc, char *argv[]) {");
		Text.StrLn(gen, "o7_init(argc, argv);");
		ImportInit(gen, module.import);
		TagsInit(gen);
		Statements(gen, module.stats);
		Statements(gen, cmd);
		IF gen.opt.memManager = MemManagerCounter THEN
			ReleaseVars(gen, module.vars);
			ImportDone(gen, module.import)
		END;
		Text.StrLn(gen, "return o7_exit_code;");
		Text.StrLnClose(gen, "}")
	END Main;

	PROCEDURE GeneratorNotify(VAR gen: Generator);
	BEGIN
		IF gen.opt.generatorNote THEN
			Text.StrLn(gen, "/* Generated by Vostok - Oberon-07 translator */");
			Text.Ln(gen)
		END
	END GeneratorNotify;
BEGIN
	ASSERT(~Ast.HasError(module));

	IF opt = NIL THEN
		opt := DefaultOptions()
	END;
	out.opt := opt;

	opt.records := NIL;
	opt.recordLast := NIL;
	opt.index := 0;

	opt.main := interface = NIL;

	IF ~opt.main THEN
		MarkUsedInMarked(module)
	END;

	IF interface # NIL THEN
		Init(out.g[Interface], interface, module, opt, TRUE);
		GeneratorNotify(out.g[Interface])
	END;

	Init(out.g[Implementation], implementation, module, opt, FALSE);
	GeneratorNotify(out.g[Implementation]);

	Comment(out.g[ORD(~opt.main)], module.comment);

	Includes(out.g[Implementation]);

	IF ~opt.main THEN
		HeaderGuard(out.g[Interface]);
		Import(out.g[Implementation], module)
	END;

	Declarations(out, module);

	IF opt.main THEN
		Main(out.g[Implementation], module, cmd)
	ELSE
		ModuleInit(out.g[Interface], out.g[Implementation], module, cmd);
		ModuleDone(out.g[Interface], out.g[Implementation], module);
		Text.StrLn(out.g[Interface], "#endif")
	END
END Generate;

BEGIN
	type := Type;
	declarator := Declarator;
	declarations := Declarations;
	statements := Statements;
	expression := Expression
END GeneratorC.

(*  Generator of C-code by Oberon-07 abstract syntax tree
 *  Copyright (C) 2016-2022 ComdivByZero
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
	Utf8, Hex,
	Strings := StringStore, Chars0X,
	SpecIdentChecker,
	SpecIdent := OberonSpecIdent,
	Stream    := VDataStream,
	Text      := TextGenerator,
	Limits    := TypesLimits,
	TranLim   := TranslatorLimits,
	GenOptions, GenCommon;

CONST
	Supported* = TRUE;

	Interface = 1;
	Implementation = 0;

	IsoC90* = 0;
	IsoC99* = 1;
	IsoC11* = 2;

	MemManagerNoFree*   = 0;
	MemManagerCounter*  = 1;
	MemManagerGC*       = 2;

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

	Options* = POINTER TO RECORD(GenOptions.R)
		std*: INTEGER;

		gnu*, plan9*, e2k*,
		procLocal*,
		vla*, vlaMark*,
		checkNil*,
		skipUnusedTag*,
		escapeHighChars*: BOOLEAN;

		memManager*: INTEGER;

		index: INTEGER;
		records, recordLast: Ast.Record; (* для генерации тэгов *)

		lastSelectorDereference,
		(* TODO для более сложных случаев *)
		expectArray,
		castToBase: BOOLEAN;

		memOuts: PMemoryOut
	END;

	Generator = RECORD(Text.Out)
		module: Ast.Module;

		localDeep: INTEGER;(* Вложенность процедур *)

		fixedLen: INTEGER;

		interface: BOOLEAN;
		opt: Options;

		insideSizeOf: BOOLEAN;

		memout: PMemoryOut
	END;

	MOut = RECORD
		g: ARRAY 2 OF Generator;
		opt: Options
	END;

	Selectors = RECORD
		des: Ast.Designator;
		decl: Ast.Declaration;
		declSimilarToPointer: BOOLEAN;
		list: ARRAY TranLim.Selectors OF Ast.Selector;
		i: INTEGER
	END;

	RecExt = POINTER TO RECORD(V.Base)
		anonName: Strings.String;
		undef: BOOLEAN;
		next: Ast.Record
	END;

	SpecNameMark = POINTER TO RECORD(V.Base) END;

VAR
	type: PROCEDURE(VAR g: Generator; decl: Ast.Declaration; type: Ast.Type;
	                typeDecl, sameType: BOOLEAN);
	declarator: PROCEDURE(VAR g: Generator; decl: Ast.Declaration;
	                      typeDecl, sameType, global: BOOLEAN);
	declarations: PROCEDURE(VAR out: MOut; ds: Ast.Declarations);
	statements: PROCEDURE(VAR g: Generator; stats: Ast.Statement);
	expression: PROCEDURE(VAR g: Generator; expr: Ast.Expression);

	specNameMark: ARRAY 2 OF SpecNameMark;


PROCEDURE Str    (VAR g: Text.Out; s: ARRAY OF CHAR); BEGIN Text.Str    (g, s) END Str;
PROCEDURE StrLn  (VAR g: Text.Out; s: ARRAY OF CHAR); BEGIN Text.StrLn  (g, s) END StrLn;
PROCEDURE StrOpen(VAR g: Text.Out; s: ARRAY OF CHAR); BEGIN Text.StrOpen(g, s) END StrOpen;
PROCEDURE Ln     (VAR g: Text.Out);                   BEGIN Text.Ln     (g)    END Ln;
PROCEDURE Int    (VAR g: Text.Out; i: INTEGER);       BEGIN Text.Int    (g, i) END Int;
PROCEDURE Chr    (VAR g: Text.Out; c: CHAR);          BEGIN Text.Char   (g, c) END Chr;
PROCEDURE StrLnClose(VAR g: Text.Out; s: ARRAY OF CHAR); BEGIN Text.StrLnClose(g, s) END StrLnClose;

PROCEDURE MemoryWrite(VAR out: MemoryOut; buf: ARRAY OF CHAR; ofs, count: INTEGER);
BEGIN
	ASSERT(Chars0X.CopyChars(
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
VAR inv, direct: INTEGER;
BEGIN
	inv := ORD(mo.invert);
	IF mo.mem[inv].len = 0 THEN
		mo.invert := ~mo.invert
	ELSE
		direct := 1 - inv;
		ASSERT(Chars0X.CopyChars(mo.mem[inv].buf, mo.mem[inv].len,
		                         mo.mem[direct].buf, 0, mo.mem[direct].len));
		mo.mem[direct].len := 0
	END
END MemWriteInvert;

PROCEDURE MemWriteDirect(VAR g: Generator; VAR mo: MemoryOut);
VAR inv: INTEGER;
BEGIN
	inv := ORD(mo.invert);
	ASSERT(mo.mem[1 - inv].len = 0);
	Text.Data(g, mo.mem[inv].buf, 0, mo.mem[inv].len);
	mo.mem[inv].len := 0
END MemWriteDirect;

PROCEDURE Ident(VAR g: Generator; ident: Strings.String);
BEGIN
	GenCommon.Ident(g, ident, g.opt.identEnc)
END Ident;

PROCEDURE Name(VAR g: Generator; decl: Ast.Declaration);
VAR up: Ast.Declarations;
    prs: ARRAY TranLim.DeepProcedures + 1 OF Ast.Declarations;
    i: INTEGER;

	PROCEDURE IsSpecName(d: Ast.Declaration): BOOLEAN;
	VAR spec: BOOLEAN;
	BEGIN
		spec := d.ext = specNameMark[ORD(TRUE)];
		IF ~spec & (d.ext # specNameMark[ORD(FALSE)]) THEN
			spec := SpecIdentChecker.IsSpecName(d.name, {});
			IF (d.ext = NIL) & (d.id # Ast.IdRecord) THEN
				d.ext := specNameMark[ORD(spec)]
			END
		END
		RETURN spec
	END IsSpecName;
BEGIN
	IF (decl IS Ast.Type) & (decl.up # NIL) & (decl.up.d # decl.module.m)
	OR ~g.opt.procLocal & (decl.id = Ast.IdProc)
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
			Ident(g, prs[i].name);
			Chr(g, "_")
		END
	END;
	Ident(g, decl.name);
	IF decl.id = Ast.IdConst THEN
		Str(g, "_cnst")
	ELSIF IsSpecName(decl) THEN
		Chr(g, "_")
	END
END Name;

PROCEDURE GlobalName(VAR g: Generator; decl: Ast.Declaration);
BEGIN
	IF decl.mark OR (decl.module # NIL) & (g.module # decl.module.m) THEN
		ASSERT(decl.module # NIL);
		Ident(g, decl.module.m.name);

		Text.Data(g, "__", 0, ORD(SpecIdentChecker.IsO7SpecName(decl.name)) + 1);
		Ident(g, decl.name);
		IF decl.id = Ast.IdConst THEN
			Str(g, "_cnst")
		END
	ELSE
		Name(g, decl)
	END
END GlobalName;

PROCEDURE Include(VAR g: Generator; name: Strings.String);
VAR i: INTEGER;
BEGIN
	Str(g, "#include "); Chr(g, Utf8.DQuote);
	Text.String(g, name);
	i := ORD(~SpecIdentChecker.IsSpecModuleName(name) & ~SpecIdentChecker.IsSpecCHeaderName(name));
	Text.Data(g, "_.h",  i, 3 - i);
	StrLn(g, Utf8.DQuote)
END Include;

PROCEDURE Factor(VAR g: Generator; expr: Ast.Expression);
BEGIN
	IF (expr IS Ast.Factor) & ~(expr.type.id = Ast.IdArray) THEN
		(* TODO *)
		expression(g, expr)
	ELSE
		Chr(g, "(");
		expression(g, expr);
		Chr(g, ")")
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

PROCEDURE CheckStructName(VAR g: Generator; rec: Ast.Record): BOOLEAN;
VAR anon: ARRAY TranLim.LenName * 2 + 3 OF CHAR;
	i, j, l: INTEGER;
BEGIN
	rec.mark := rec.mark OR (rec.pointer # NIL) & rec.pointer.mark;
	IF Strings.IsDefined(rec.name) THEN
		;
	ELSIF (rec.pointer # NIL) & Strings.IsDefined(rec.pointer.name) THEN
		l := 0;
		ASSERT(rec.module # NIL);
		ASSERT(Strings.CopyToChars(anon, l, rec.pointer.name));
		anon[l] := "_";
		anon[l + 1] := "s";
		anon[l + 2] := Utf8.Null;
		Ast.PutChars(rec.pointer.module.m, rec.name, anon, 0, l + 2)
	ELSE
		l := 0;
		ASSERT(Strings.CopyToChars(anon, l, rec.module.m.name));

		ASSERT(Chars0X.CopyString(anon, l, "_anon_0000"));
		ASSERT((g.opt.index >= 0) & (g.opt.index < 10000));
		i := g.opt.index;
		j := l - 1;
		WHILE i > 0 DO
			anon[j] := CHR(ORD("0") + i MOD 10);
			i := i DIV 10;
			DEC(j)
		END;
		INC(g.opt.index);
		Ast.PutChars(rec.module.m, rec.name, anon, 0, l)
	END
	RETURN Strings.IsDefined(rec.name)
END CheckStructName;

PROCEDURE ArrayDeclLen(VAR g: Generator; arr: Ast.Type;
                       decl: Ast.Declaration; sel: Ast.Selector;
                       i: INTEGER);
BEGIN
	IF arr(Ast.Array).count # NIL THEN
		expression(g, arr(Ast.Array).count)
	ELSE
		GlobalName(g, decl);(*TODO*)
		Str(g, "_len");
		IF i < 0 THEN
			i := 0;
			WHILE sel # NIL DO
				INC(i);
				sel := sel.next
			END
		END;
		Int(g, i)
	END
END ArrayDeclLen;

PROCEDURE ArrayLen(VAR g: Generator; e: Ast.Expression);
VAR i: INTEGER;
	des: Ast.Designator;
	t: Ast.Type;
BEGIN
	IF e.type(Ast.Array).count # NIL THEN
		expression(g, e.type(Ast.Array).count)
	ELSE
		des := e(Ast.Designator);
		GlobalName(g, des.decl);
		Str(g, "_len");
		i := 0;
		t := des.type;
		WHILE t # e.type DO
			INC(i);
			t := t.type
		END;
		Int(g, i)
	END
END ArrayLen;

PROCEDURE Selector(VAR g: Generator; sels: Selectors; i: INTEGER;
                   VAR typ: Ast.Type; desType: Ast.Type);
VAR sel: Ast.Selector; ref: BOOLEAN;

	PROCEDURE Record(VAR g: Generator; VAR typ: Ast.Type; VAR sel: Ast.Selector; sels: Selectors);
	VAR var: Ast.Declaration; up: Ast.Record;

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
		IF typ.id = Ast.IdPointer THEN
			up := typ(Ast.Pointer).type(Ast.Record)
		ELSE
			up := typ(Ast.Record)
		END;

		IF (typ.id = Ast.IdPointer)
		OR (sels.list[0] = sel) & sels.declSimilarToPointer
		THEN
			Str(g, "->")
		ELSE
			Chr(g, ".")
		END;

		IF ~g.opt.plan9 THEN
			WHILE (up # NIL) & ~Search(up, var) DO
				up := up.base;
				Str(g, "_.")
			END
		END;

		Name(g, var);

		typ := var.type
	END Record;

	PROCEDURE Declarator(VAR g: Generator; decl: Ast.Declaration; sels: Selectors);
	BEGIN
		IF (decl IS Ast.FormalParam)
		 & (decl.type.id # Ast.IdArray)

		 & ((Ast.ParamOut IN decl(Ast.FormalParam).access) OR (decl.type.id = Ast.IdRecord))
		 & ((sels.i < 0) OR (decl.type.id = Ast.IdPointer))
		THEN
			IF (sels.i < 0) & ~g.opt.castToBase THEN
				Text.CancelDeferedOrWriteChar(g, "*");
				GlobalName(g, decl)
			ELSE
				(*TODO CancelDefered *)
				Str(g, "(*");
				GlobalName(g, decl);
				Chr(g, ")")
			END
		ELSE
			GlobalName(g, decl)
		END
	END Declarator;

	PROCEDURE Array(VAR g: Generator; VAR typ: Ast.Type;
	                VAR sel: Ast.Selector; decl: Ast.Declaration;
	                isDesignatorArray: BOOLEAN);
	VAR i: INTEGER;

		PROCEDURE Mult(VAR g: Generator;
		               decl: Ast.Declaration; j: INTEGER; t: Ast.Type);
		BEGIN
			WHILE (t # NIL) & (t.id = Ast.IdArray) & (t(Ast.Array).count = NIL) DO
				Str(g, " * ");
				Name(g, decl);
				Str(g, "_len");
				Int(g, j);
				INC(j);
				t := t.type
			END
		END Mult;
	BEGIN
		IF isDesignatorArray & ~g.opt.vla THEN
			Str(g, " + ")
		ELSE
			Chr(g, "[")
		END;
		IF (typ.type.id # Ast.IdArray) OR (typ(Ast.Array).count # NIL)
		OR g.opt.vla
		THEN
			IF g.opt.checkIndex
			 & (   (sel(Ast.SelArray).index.value = NIL)
			    OR (typ(Ast.Array).count = NIL)
			     & (sel(Ast.SelArray).index.value(Ast.ExprInteger).int # 0)
			   )
			THEN
				Str(g, "o7_ind(");
				ArrayDeclLen(g, typ, decl, sel, 0);
				Str(g, ", ");
				expression(g, sel(Ast.SelArray).index);
				Chr(g, ")")
			ELSE
				expression(g, sel(Ast.SelArray).index)
			END;
			typ := typ.type;
			sel := sel.next;
			i := 1;
			WHILE (sel # NIL) & (sel IS Ast.SelArray) DO
				IF g.opt.checkIndex
				 & (   (sel(Ast.SelArray).index.value = NIL)
				    OR (typ(Ast.Array).count = NIL)
				     & (sel(Ast.SelArray).index.value(Ast.ExprInteger).int # 0)
				   )
				THEN
					Str(g, "][o7_ind(");
					ArrayDeclLen(g, typ, decl, sel, i);
					Str(g, ", ");
					expression(g, sel(Ast.SelArray).index);
					Chr(g, ")")
				ELSE
					Str(g, "][");
					expression(g, sel(Ast.SelArray).index)
				END;
				INC(i);
				sel := sel.next;
				typ := typ.type
			END
		ELSE
			i := 0;
			WHILE (sel.next # NIL) & (sel.next IS Ast.SelArray) DO
				Str(g, "o7_ind(");
				ArrayDeclLen(g, typ, decl, NIL, i);
				Str(g, ", ");
				expression(g, sel(Ast.SelArray).index);
				Chr(g, ")");
				typ := typ.type;
				Mult(g, decl, i + 1, typ);
				sel := sel.next;
				INC(i);
				Str(g, " + ")
			END;
			Str(g, "o7_ind(");
			ArrayDeclLen(g, typ, decl, NIL, i);
			Str(g, ", ");
			expression(g, sel(Ast.SelArray).index);
			Chr(g, ")");
			Mult(g, decl, i + 1, typ.type)
		END;
		IF ~isDesignatorArray OR g.opt.vla THEN
			Chr(g, "]")
		END
	END Array;
BEGIN
	IF i >= 0 THEN
		sel := sels.list[i]
	END;
	IF ~g.opt.checkNil THEN
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
		Str(g, "O7_REF(")
	END;
	IF i < 0 THEN
		Declarator(g, sels.decl, sels)
	ELSE
		DEC(i);
		IF sel IS Ast.SelRecord THEN
			Selector(g, sels, i, typ, desType);
			Record(g, typ, sel, sels)
		ELSIF sel IS Ast.SelArray THEN
			Selector(g, sels, i, typ, desType);
			Array(g, typ, sel, sels.decl,
			      (desType.id = Ast.IdArray) & (desType(Ast.Array).count = NIL))
		ELSIF sel IS Ast.SelPointer THEN
			IF (sel.next = NIL) OR ~(sel.next IS Ast.SelRecord) THEN
				Str(g, "(*");
				Selector(g, sels, i, typ, desType);
				Chr(g, ")")
			ELSE
				Selector(g, sels, i, typ, desType)
			END
		ELSE ASSERT(sel IS Ast.SelGuard);
			IF sel.type.id = Ast.IdPointer THEN
				Str(g, "O7_GUARD(");
				ASSERT(CheckStructName(g, sel.type.type(Ast.Record)));
				GlobalName(g, sel.type.type)
			ELSE
				ASSERT(i < 0);
				Str(g, "O7_GUARD_R(");
				GlobalName(g, sel.type)
			END;
			Str(g, ", ");
			IF i < 0 THEN
				Declarator(g, sels.decl, sels)
			ELSE
				Selector(g, sels, i, typ, desType)
			END;
			IF sel.type.id = Ast.IdPointer THEN
				Chr(g, ")")
			ELSE
				Str(g, ", ");
				GlobalName(g, sels.decl);
				Str(g, "_tag)")
			END;
			typ := sel(Ast.SelGuard).type
		END;
	END;
	IF ref THEN
		Chr(g, ")")
	END
END Selector;

PROCEDURE IsDesignatorMayNotInited(des: Ast.Designator): BOOLEAN;
	RETURN ({Ast.InitedNo, Ast.InitedCheck} * des.inited # {})
	    OR (des.sel # NIL)
END IsDesignatorMayNotInited;

PROCEDURE IsMayNotInited(e: Ast.Expression): BOOLEAN;
	RETURN (e.id = Ast.IdDesignator) & IsDesignatorMayNotInited(e(Ast.Designator))
END IsMayNotInited;

PROCEDURE Designator(VAR g: Generator; des: Ast.Designator);
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
	sels.declSimilarToPointer :=
	  (sels.decl IS Ast.FormalParam)
	&
	  (  (Ast.ParamOut IN sels.decl(Ast.FormalParam).access)
	   OR
	     (sels.decl.type.id IN Ast.Structures)
	  );
	lastSelectorDereference := (0 <= sels.i)
	                         & (sels.list[sels.i] IS Ast.SelPointer);
	Selector(g, sels, sels.i, typ, des.type);
	g.opt.lastSelectorDereference := lastSelectorDereference
END Designator;

PROCEDURE CheckExpr(VAR g: Generator; e: Ast.Expression);
BEGIN
	IF (g.opt.varInit = GenOptions.VarInitUndefined)
	 & (e.value = NIL)
	 & (e.type.id IN CheckableInitTypes)
	 & IsMayNotInited(e)
	THEN
		CASE e.type.id OF
		  Ast.IdBoolean:
			Str(g, "o7_bl(")
		| Ast.IdInteger:
			Str(g, "o7_int(")
		| Ast.IdLongInt:
			Str(g, "o7_long(")
		| Ast.IdReal:
			Str(g, "o7_dbl(")
		| Ast.IdReal32:
			Str(g, "o7_fl(")
		END;
		expression(g, e);
		Chr(g, ")")
	ELSE
		expression(g, e)
	END
END CheckExpr;

PROCEDURE AssignInitValue(VAR g: Generator; typ: Ast.Type);
	PROCEDURE Zero(VAR g: Generator; typ: Ast.Type);
	BEGIN
		CASE typ.id OF
		  Ast.IdInteger, Ast.IdLongInt, Ast.IdByte, Ast.IdReal, Ast.IdReal32,
		  Ast.IdSet, Ast.IdLongSet:
			Str(g, " = 0")
		| Ast.IdBoolean:
			Str(g, " = 0 > 1")
		| Ast.IdChar:
			Str(g, " = '\0'")
		| Ast.IdPointer, Ast.IdProcType, Ast.IdFuncType:
			Str(g, " = NULL")
		END
	END Zero;

	PROCEDURE Undef(VAR g: Generator; typ: Ast.Type);
	BEGIN
		CASE typ.id OF
		  Ast.IdInteger:
			Str(g, " = O7_INT_UNDEF")
		| Ast.IdLongInt:
			Str(g, " = O7_LONG_UNDEF")
		| Ast.IdBoolean:
			Str(g, " = O7_BOOL_UNDEF")
		| Ast.IdByte:
			Str(g, " = 0")
		| Ast.IdChar:
			Str(g, " = '\0'")
		| Ast.IdReal:
			Str(g, " = O7_DBL_UNDEF")
		| Ast.IdReal32:
			Str(g, " = O7_FLT_UNDEF")
		| Ast.IdSet, Ast.IdLongSet:
			Str(g, " = 0u")
		| Ast.IdPointer, Ast.IdProcType, Ast.IdFuncType:
			Str(g, " = NULL")
		END
	END Undef;
BEGIN
	CASE g.opt.varInit OF
	  GenOptions.VarInitUndefined:
		Undef(g, typ)
	| GenOptions.VarInitZero:
		Zero(g, typ)
	END
END AssignInitValue;

PROCEDURE VarInit(VAR g: Generator; var: Ast.Declaration; record: BOOLEAN);
BEGIN
	IF (g.opt.varInit = GenOptions.VarInitNo)
	OR (var.type.id IN Ast.Structures)
	OR (~record & ~var(Ast.Var).checkInit)
	THEN
		IF (var.type.id = Ast.IdPointer)
		 & (g.opt.memManager = MemManagerCounter)
		THEN
			Str(g, " = NULL")
		END
	ELSIF (g.opt.varInit = GenOptions.VarInitUndefined)
	    & Ast.IsGlobal(var)
	    & (var.type.id IN Ast.Reals)
	THEN
		IF var.type.id = Ast.IdReal THEN
			Str(g, " = O7_DBL_UNDEF_STATIC")
		ELSE
			Str(g, " = O7_FLT_UNDEF_STATIC")
		END
	ELSE
		AssignInitValue(g, var.type)
	END
END VarInit;

PROCEDURE Swap(VAR b1, b2: BOOLEAN);
VAR t: BOOLEAN;
BEGIN
	t  := b1;
	b1 := b2;
	b2 := t
END Swap;

PROCEDURE CastedPointer(VAR g: Generator; expr: Ast.Expression; t: Ast.Type);
BEGIN
	Str(g, "((");
	GlobalName(g, t.type);
	Str(g, " *)");
	expression(g, expr);
	Chr(g, ")")
END CastedPointer;

PROCEDURE Qualifier(VAR g: Generator; typ: Ast.Type);
BEGIN
	CASE typ.id OF
	  Ast.IdInteger:
		Str(g, "o7_int_t")
	| Ast.IdLongInt:
		Str(g, "o7_long_t")
	| Ast.IdSet:
		Str(g, "o7_set_t")
	| Ast.IdLongSet:
		Str(g, "o7_set64_t")
	| Ast.IdBoolean:
		IF (g.opt.std >= IsoC99)
		 & (g.opt.varInit # GenOptions.VarInitUndefined)
		THEN	Str(g, "bool")
		ELSE	Str(g, "o7_bool")
		END
	| Ast.IdByte:
		Str(g, "char unsigned")
	| Ast.IdChar:
		Str(g, "o7_char")
	| Ast.IdReal:
		Str(g, "double")
	| Ast.IdReal32:
		Str(g, "float")
	| Ast.IdRecord, Ast.IdPointer, Ast.IdProcType, Ast.IdFuncType:
		GlobalName(g, typ)
	END
END Qualifier;

PROCEDURE ExprBraced(VAR g: Generator;
                     l: ARRAY OF CHAR; e: Ast.Expression; r: ARRAY OF CHAR);
BEGIN
	Str(g, l);
	expression(g, e);
	Str(g, r)
END ExprBraced;

PROCEDURE TwoExprBraced(VAR g: Generator;
                       l: ARRAY OF CHAR; e1: Ast.Expression;
                       m: ARRAY OF CHAR; e2: Ast.Expression; r: ARRAY OF CHAR);
BEGIN
	Str(g, l);
	expression(g, e1);
	Str(g, m);
	expression(g, e2);
	Str(g, r)
END TwoExprBraced;

PROCEDURE Expression(VAR g: Generator; expr: Ast.Expression);

	PROCEDURE Call(VAR g: Generator; call: Ast.ExprCall);
	VAR p: Ast.Parameter;
		fp: Ast.Declaration;

		PROCEDURE Predefined(VAR g: Generator; call: Ast.ExprCall);
		VAR e1: Ast.Expression;
			p2: Ast.Parameter;

			PROCEDURE LeftShift(VAR g: Generator; n, s: Ast.Expression);
			BEGIN
				(* TODO *)
				Str(g, "(o7_int_t)((o7_uint_t)");
				Factor(g, n);
				Str(g, " << ");
				Factor(g, s);
				Chr(g, ")")
			END LeftShift;

			PROCEDURE ArithmeticRightShift(VAR g: Generator; n, s: Ast.Expression);
			BEGIN
				IF (n.value # NIL) & (s.value # NIL) THEN
					Str(g, "O7_ASR(");
					Expression(g, n);
					Str(g, ", ");
					Expression(g, s);
					Chr(g, ")")
				ELSIF g.opt.gnu THEN
					Chr(g, "(");
					Factor(g, n);
					IF g.opt.checkArith & (s.value = NIL) THEN
						Str(g, " >> o7_not_neg(")
					ELSE
						Str(g, " >> (")
					END;
					Expression(g, s);
					Str(g, "))")
				ELSE
					Str(g, "o7_asr(");
					Expression(g, n);
					Str(g, ", ");
					Expression(g, s);
					Chr(g, ")")
				END
			END ArithmeticRightShift;

			PROCEDURE Rotate(VAR g: Generator; n, r: Ast.Expression);
			BEGIN
				IF (n.value # NIL) & (r.value # NIL) THEN
					Str(g, "O7_ROR(")
				ELSE
					Str(g, "o7_ror(")
				END;
				Expression(g, n);
				Str(g, ", ");
				Expression(g, r);
				Chr(g, ")")
			END Rotate;

			PROCEDURE Len(VAR g: Generator; e: Ast.Expression);
			VAR sel: Ast.Selector;
				i: INTEGER;
				des: Ast.Designator;
				count: Ast.Expression;
				sizeof: BOOLEAN;
			BEGIN
				count := e.type(Ast.Array).count;
				IF e.id = Ast.IdDesignator THEN
					des := e(Ast.Designator);
					sizeof := ~(e(Ast.Designator).decl.id = Ast.IdConst)
					         & (  (des.decl.type.id # Ast.IdArray)
					           OR ~(des.decl IS Ast.FormalParam)
					           OR g.opt.vla & ~g.opt.vlaMark
					           )
				ELSE
					ASSERT(count # NIL);
					sizeof := FALSE
				END;
				IF (count # NIL) & ~sizeof THEN
					Expression(g, count)
				ELSIF sizeof THEN
					Str(g, "O7_LEN(");
					Designator(g, des);
					Chr(g, ")");
					(*
					Str(g, "sizeof(");
					Designator(g, des);
					Str(g, ") / sizeof (");
					Designator(g, des);
					Str(g, "[0])")
					*)
				ELSIF g.opt.e2k & (des.decl.type.type.id # Ast.IdArray) THEN
					Str(g, "O7_E2K_LEN(");
					GlobalName(g, des.decl);
					Chr(g, ")")
				ELSE
					GlobalName(g, des.decl);
					Str(g, "_len");
					i := 0;
					sel := des.sel;
					WHILE sel # NIL DO
						INC(i);
						sel := sel.next
					END;
					Int(g, i)
				END
			END Len;

			PROCEDURE New(VAR g: Generator; e: Ast.Expression);
			VAR tagType: Ast.Type;
			BEGIN
				tagType := TypeForTag(e.type.type(Ast.Record));
				IF tagType # NIL THEN
					Str(g, "O7_NEW(&");
					Designator(g, e(Ast.Designator));
					Str(g, ", ");
					GlobalName(g, tagType);
					Chr(g, ")")
				ELSE
					Str(g, "O7_NEW2(&");
					Designator(g, e(Ast.Designator));
					Str(g, ", o7_base_tag, NULL)")
				END
			END New;

			PROCEDURE Ord(VAR g: Generator; e: Ast.Expression);
			BEGIN
				CASE e.type.id OF
				  Ast.IdChar, Ast.IdArray:
					g.opt.expectArray := FALSE;
					Str(g, "(o7_int_t)");
					Factor(g, e)
				| Ast.IdBoolean:
					IF (e.id = Ast.IdDesignator)
					 & (g.opt.varInit = GenOptions.VarInitUndefined)
					THEN
						Str(g, "(o7_int_t)o7_bl(");
						Expression(g, e);
						Chr(g, ")")
					ELSE
						Str(g, "(o7_int_t)");
						Factor(g, e)
					END
				| Ast.IdSet:
					Str(g, "o7_sti(");
					Expression(g, e);
					Chr(g, ")")
				END
			END Ord;

			PROCEDURE Inc(VAR g: Generator;
			              e1: Ast.Expression; p2: Ast.Parameter);
			BEGIN
				Expression(g, e1);
				IF g.opt.checkArith THEN
					Str(g, " = o7_add(");
					Expression(g, e1);
					IF p2 = NIL THEN
						Str(g, ", 1)")
					ELSE
						Str(g, ", ");
						Expression(g, p2.expr);
						Chr(g, ")")
					END
				ELSIF p2 = NIL THEN
					(* TODO выяснить, где ошибка с ++ *)
					Str(g, " += 1")
				ELSE
					Str(g, " += ");
					Expression(g, p2.expr)
				END
			END Inc;

			PROCEDURE Dec(VAR g: Generator;
			              e1: Ast.Expression; p2: Ast.Parameter);
			BEGIN
				Expression(g, e1);
				IF g.opt.checkArith THEN
					Str(g, " = o7_sub(");
					Expression(g, e1);
					IF p2 = NIL THEN
						Str(g, ", 1)")
					ELSE
						Str(g, ", ");
						Expression(g, p2.expr);
						Chr(g, ")")
					END
				ELSIF p2 = NIL THEN
					Str(g, " -= 1")
				ELSE
					Str(g, " -= ");
					Expression(g, p2.expr)
				END
			END Dec;

			PROCEDURE Assert(VAR g: Generator; e: Ast.Expression);
			VAR c11Assert: BOOLEAN;
			    buf: ARRAY 5 OF CHAR;
			BEGIN
				c11Assert := FALSE;
				IF (e.value # NIL) & (e.value # Ast.ExprBooleanGet(FALSE))
				 & ~(Ast.ExprPointerTouch IN e.properties)
				THEN
					IF g.opt.std >= IsoC11 THEN
						c11Assert := TRUE;
						Str(g, "static_assert(")
					ELSE
						Str(g, "O7_STATIC_ASSERT(")
					END
				ELSIF g.opt.o7Assert THEN
					Str(g, "O7_ASSERT(")
				ELSE
					Str(g, "assert(")
				END;
				CheckExpr(g, e);
				IF c11Assert THEN
					buf[0] := ",";
					buf[1] := " ";
					buf[2] := Utf8.DQuote;
					buf[3] := Utf8.DQuote;
					buf[4] := ")";
					Text.Data(g, buf, 0, 5)
				ELSE
					Chr(g, ")")
				END
			END Assert;

			PROCEDURE SystemPut(VAR g: Generator; addr, val: Ast.Expression);
			BEGIN
				CASE val.type.id OF
				  Ast.IdByte, Ast.IdChar, Ast.IdArray:
					Str(g, "o7_put_char(")
				| Ast.IdBoolean:
					Str(g, "o7_put_bool(")
				| Ast.IdInteger, Ast.IdSet:
					Str(g, "o7_put_uint(")
				| Ast.IdLongInt, Ast.IdLongSet:
					Str(g, "o7_put_ulong(")
				| Ast.IdReal:
					Str(g, "o7_put_double(")
				| Ast.IdReal32:
					Str(g, "o7_put_float(")
				END;
				Expression(g, addr);
				IF val.type.id = Ast.IdArray THEN
					ExprBraced(g, ", ", val, ")")
				ELSE
					ExprBraced(g, ", ", val, ")")
				END
			END SystemPut;

		BEGIN
			e1 := call.params.expr;
			p2 := call.params.next;
			CASE call.designator.decl.id OF
			  SpecIdent.Abs:
				IF call.type.id = Ast.IdInteger THEN
					Str(g, "abs(")
				ELSIF call.type.id = Ast.IdLongInt THEN
					Str(g, "O7_LABS(")
				ELSE
					Str(g, "fabs(")
				END;
				Expression(g, e1);
				Chr(g, ")")
			| SpecIdent.Odd:
				Chr(g, "(");
				Factor(g, e1);
				Str(g, " % 2 != 0)")
			| SpecIdent.Len:
				Len(g, e1)
			| SpecIdent.Lsl:
				LeftShift(g, e1, p2.expr)
			| SpecIdent.Asr:
				ArithmeticRightShift(g, e1, p2.expr)
			| SpecIdent.Ror:
				Rotate(g, e1, p2.expr);
			| SpecIdent.Floor:
				Str(g, "o7_floor(");
				Expression(g, e1);
				Chr(g, ")")
			| SpecIdent.Flt:
				Str(g, "o7_flt(");
				Expression(g, e1);
				Chr(g, ")")
			| SpecIdent.Ord:
				IF e1.value = NIL THEN
					Ord(g, e1)
				ELSE
					Str(g, "((o7_int_t)");
					Expression(g, e1);
					Chr(g, ")");
				END
			| SpecIdent.Chr:
				IF g.opt.checkArith & (e1.value = NIL) THEN
					Str(g, "o7_chr(");
					Expression(g, e1);
					Chr(g, ")")
				ELSE
					Str(g, "(o7_char)");
					Factor(g, e1)
				END
			| SpecIdent.Inc:
				Inc(g, e1, p2)
			| SpecIdent.Dec:
				Dec(g, e1, p2)
			| SpecIdent.Incl:
				Expression(g, e1);
				Str(g, " |= 1u << ");
				Factor(g, p2.expr)
			| SpecIdent.Excl:
				Expression(g, e1);
				Str(g, " &= ~(1u << ");
				Factor(g, p2.expr);
				Chr(g, ")")
			| SpecIdent.New:
				New(g, e1)
			| SpecIdent.Assert:
				Assert(g, e1)
			| SpecIdent.Pack:
				Str(g, "o7_ldexp(&");
				Expression(g, e1);
				Str(g, ", ");
				Expression(g, p2.expr);
				Chr(g, ")")
			| SpecIdent.Unpk:
				Str(g, "o7_frexp(&");
				Expression(g, e1);
				Str(g, ", &");
				Expression(g, p2.expr);
				Chr(g, ")")

			(* SYSTEM *)
			| SpecIdent.Adr:
				ExprBraced(g, "O7_ADR(", e1, ")")
			| SpecIdent.Size:
				ExprBraced(g, "O7_SIZE(", e1, ")")
			| SpecIdent.Bit:
				TwoExprBraced(g, "o7_bit(", e1, ", ", p2.expr, ")")
			| SpecIdent.Get:
				TwoExprBraced(g, "O7_GET(", e1, ", &", p2.expr, ")")
			| SpecIdent.Put:
				SystemPut(g, e1, p2.expr)
			| SpecIdent.Copy:
				TwoExprBraced(g, "o7_copy(", e1, ", ", p2.expr, ", ");
				Expression(g, p2.next.expr);
				Chr(g, ")")
			END
		END Predefined;

		PROCEDURE ActualParam(VAR g: Generator; VAR p: Ast.Parameter;
		                      VAR fp: Ast.Declaration);
		VAR t, fpt: Ast.Type;
		    i, j, dist: INTEGER;
		    paramOut, castToBase: BOOLEAN;

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

			PROCEDURE OpenArrayDeep(t: Ast.Type): INTEGER;
			VAR d: INTEGER;
			BEGIN
				d := 0;
				WHILE (t.id = Ast.IdArray) & (t(Ast.Array).count = NIL) DO
					t := t.type;
					INC(d)
				END
				RETURN d
			END OpenArrayDeep;

		BEGIN
			t := fp.type;
			IF (t.id = Ast.IdByte) & (p.expr.type.id IN {Ast.IdInteger, Ast.IdLongInt})
			 & g.opt.checkArith & (p.expr.value = NIL)
			THEN
				IF p.expr.type.id = Ast.IdInteger THEN
					Str(g, "o7_byte(")
				ELSE
					Str(g, "o7_lbyte(")
				END;
				Expression(g, p.expr);
				Chr(g, ")")
			ELSE
				j := 1;
				IF (fp.type.id # Ast.IdChar)
				& ~(g.opt.e2k & (fp.type.id = Ast.IdArray) & (fp.type.type.id # Ast.IdArray))
				THEN
					i := -1;
					t := p.expr.type;
					fpt := fp.type;
					WHILE (t.id = Ast.IdArray)
					    & (fpt(Ast.Array).count = NIL)
					DO
						IF (i = -1) & (p.expr.id = Ast.IdDesignator) THEN
							i := ArrayDeep(p.expr(Ast.Designator).decl.type)
							   - ArrayDeep(fp.type);
							(* TODO запутано *)
							IF ~(p.expr(Ast.Designator).decl IS Ast.FormalParam) THEN
								j := OpenArrayDeep(fpt)
							END
						END;
						IF t(Ast.Array).count # NIL THEN
							Expression(g, t(Ast.Array).count)
						ELSE
							Name(g, p.expr(Ast.Designator).decl);
							Str(g, "_len");
							Int(g, i)
						END;
						Str(g, ", ");
						INC(i);
						t := t.type;
						fpt := fpt.type
					END;
					t := fp.type
				END;
				dist := p.distance;
				castToBase := FALSE;
				paramOut := Ast.ParamOut IN fp(Ast.FormalParam).access;
				IF paramOut & (t.id # Ast.IdArray)
				OR (t.id = Ast.IdRecord)
				THEN
					castToBase := 0 < dist;
					Text.DeferChar(g, "&")
				END;
				g.opt.lastSelectorDereference := FALSE;
				g.opt.expectArray := fp.type.id = Ast.IdArray;

				Swap(castToBase, g.opt.castToBase);
				IF paramOut OR (t.id = Ast.IdRecord) THEN
					Expression(g, p.expr)
				ELSIF (t.id = Ast.IdPointer) & (dist > 0) THEN
					CastedPointer(g, p.expr, t);
					dist := 0
				ELSE
					CheckExpr(g, p.expr)
				END;
				Swap(castToBase, g.opt.castToBase);
				g.opt.expectArray := FALSE;

				IF ~g.opt.vla THEN
					WHILE j > 1 DO
						DEC(j);
						Str(g, "[0]")
					END
				END;

				IF (dist > 0) & ~g.opt.plan9 THEN
					IF t.id = Ast.IdPointer THEN
						DEC(dist);
						Str(g, "->_")
					END;
					WHILE dist > 0 DO
						DEC(dist);
						Str(g, "._")
					END
				END;

				t := p.expr.type;
				IF (t.id = Ast.IdRecord)
				 & (~g.opt.skipUnusedTag OR Ast.IsNeedTag(fp(Ast.FormalParam)))
				THEN
					IF g.opt.lastSelectorDereference THEN
						Str(g, ", NULL")
					ELSE
						IF (p.expr(Ast.Designator).decl IS Ast.FormalParam)
						 & (p.expr(Ast.Designator).sel = NIL)
						THEN
							Str(g, ", ");
							Name(g, p.expr(Ast.Designator).decl)
						ELSE
							Str(g, ", &");
							GlobalName(g, t)
						END;
						Str(g, "_tag")
					END
				END
			END;

			p := p.next;
			fp := fp.next
		END ActualParam;
	BEGIN
		IF call.designator.decl IS Ast.PredefinedProcedure THEN
			Predefined(g, call)
		ELSE
			Designator(g, call.designator);
			Chr(g, "(");
			p  := call.params;
			fp := call.designator.type(Ast.ProcType).params;
			IF p # NIL THEN
				ActualParam(g, p, fp);
				WHILE p # NIL DO
					Str(g, ", ");
					ActualParam(g, p, fp)
				END
			END;
			Chr(g, ")")
		END
	END Call;

	PROCEDURE Relation(VAR g: Generator; rel: Ast.ExprRelation);

		PROCEDURE Simple(VAR g: Generator; rel: Ast.ExprRelation;
		                 str: ARRAY OF CHAR);
		VAR notChar0, notChar1: BOOLEAN;

			PROCEDURE Expr(VAR g: Generator; e: Ast.Expression; dist: INTEGER; t: Ast.Type);
			VAR brace, castToBase: BOOLEAN;
			BEGIN
				brace := (e.type.id IN {Ast.IdSet, Ast.IdBoolean})
				      & ~(e IS Ast.Factor);
				IF brace THEN
					Chr(g, "(");
					Expression(g, e);
					Chr(g, ")")
				ELSIF (dist > 0) & (e.type.id = Ast.IdPointer) & ~g.opt.plan9 THEN
					CastedPointer(g, e, t);
				ELSE
					castToBase := FALSE;
					Swap(castToBase, g.opt.castToBase);
					Expression(g, e);
					Swap(castToBase, g.opt.castToBase)
				END
			END Expr;

			PROCEDURE Len(VAR g: Generator; e: Ast.Expression);
			VAR des: Ast.Designator;
			BEGIN
				IF e.type(Ast.Array).count # NIL THEN
					Expression(g, e.type(Ast.Array).count)
				ELSE
					des := e(Ast.Designator);
					ArrayDeclLen(g, des.type, des.decl, des.sel, -1)
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
					Expression(g, rel.value)
				ELSE
					notChar1 := ~notChar0 OR IsArrayAndNotChar(rel.exprs[1]);
					IF notChar0 = notChar1 THEN
						ASSERT(notChar0);
						IF g.opt.e2k THEN
							Str(g, "strcmp(")
						ELSE
							Str(g, "o7_strcmp(")
						END
					ELSIF notChar1 THEN
						Str(g, "o7_chstrcmp(")
					ELSE ASSERT(notChar0);
						Str(g, "o7_strchcmp(")
					END;
					IF notChar0 & ~g.opt.e2k THEN
						Len(g, rel.exprs[0]);
						Str(g, ", ")
					END;
					Expr(g, rel.exprs[0], -rel.distance, rel.exprs[1].type);

					Str(g, ", ");

					IF notChar1 & ~g.opt.e2k THEN
						Len(g, rel.exprs[1]);
						Str(g, ", ")
					END;
					Expr(g, rel.exprs[1], rel.distance, rel.exprs[0].type);

					Chr(g, ")");
					Str(g, str);
					Chr(g, "0")
				END
			ELSIF (g.opt.varInit = GenOptions.VarInitUndefined)
			    & (rel.value = NIL)
			    & (rel.exprs[0].type.id IN {Ast.IdInteger, Ast.IdLongInt}) (* TODO *)
			    & (IsMayNotInited(rel.exprs[0]) OR IsMayNotInited(rel.exprs[1]))
			THEN
				IF rel.exprs[0].type.id  = Ast.IdInteger THEN
					Str(g, "o7_cmp(")
				ELSE
					Str(g, "o7_lcmp(")
				END;
				Expr(g, rel.exprs[0], -rel.distance, rel.exprs[1].type);
				Str(g, ", ");
				Expr(g, rel.exprs[1], rel.distance, rel.exprs[0].type);
				Chr(g, ")");
				Str(g, str);
				Chr(g, "0")
			ELSE
				IF rel.exprs[0].id # Ast.IdNegate THEN
					Expr(g, rel.exprs[0], -rel.distance, rel.exprs[1].type)
				ELSE
					(* Предотвращение предупреждения *)
					Chr(g, "(");
					Expr(g, rel.exprs[0], -rel.distance, rel.exprs[1].type);
					Chr(g, ")")
				END;
				Str(g, str);
				Expr(g, rel.exprs[1], rel.distance, rel.exprs[0].type)
			END
		END Simple;

		PROCEDURE In(VAR g: Generator; rel: Ast.ExprRelation);
		BEGIN
			IF (rel.value = NIL) (* TODO & option *)
			 & (rel.exprs[0].value # NIL)
			 & (rel.exprs[0].value(Ast.ExprInteger).int IN {0 .. Limits.SetMax})
			THEN
				Str(g, "!!(");
				Str(g, " (1u << ");
				Factor(g, rel.exprs[0]);
				Str(g, ") & ");
				Factor(g, rel.exprs[1]);
				Chr(g, ")")
			ELSE
				IF rel.value # NIL THEN
					Str(g, "O7_IN(")
				ELSE
					Str(g, "o7_in(")
				END;
				Expression(g, rel.exprs[0]);
				Str(g, ", ");
				Expression(g, rel.exprs[1]);
				Chr(g, ")")
			END
		END In;
	BEGIN
		CASE rel.relation OF
		  Ast.Equal        : Simple(g, rel, " == ")
		| Ast.Inequal      : Simple(g, rel, " != ")
		| Ast.Less         : Simple(g, rel, " < ")
		| Ast.LessEqual    : Simple(g, rel, " <= ")
		| Ast.Greater      : Simple(g, rel, " > ")
		| Ast.GreaterEqual : Simple(g, rel, " >= ")
		| Ast.In           : In(g, rel)
		END
	END Relation;

	PROCEDURE Sum(VAR g: Generator; sum: Ast.ExprSum);
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

		PROCEDURE BoolTerm(VAR g: Generator; term: Ast.Expression);
		BEGIN
			IF term.id # Ast.IdTerm THEN
				CheckExpr(g, term)
			ELSE
				Chr(g, "(");
				CheckExpr(g, term);
				Chr(g, ")");
			END
		END BoolTerm;
	BEGIN
		IF sum.type.id IN Ast.Sets THEN
			i := CountSignChanges(sum.next);
			Text.CharFill(g, "(", i);
			IF sum.add = Ast.Minus THEN
				Str(g, " ~")
			END;
			CheckExpr(g, sum.term);
			sum := sum.next;
			WHILE sum # NIL DO
				ASSERT(sum.type.id IN Ast.Sets);
				IF sum.add = Ast.Minus THEN
					Str(g, " & ~")
				ELSE ASSERT(sum.add = Ast.Plus);
					Str(g, " | ")
				END;
				CheckExpr(g, sum.term);
				IF (sum.next # NIL) & (sum.next.add # sum.add) THEN
					Chr(g, ")")
				END;
				sum := sum.next
			END;
		ELSIF sum.type.id = Ast.IdBoolean THEN
			BoolTerm(g, sum.term);
			sum := sum.next;
			WHILE sum # NIL DO
				ASSERT(sum.type.id = Ast.IdBoolean);
				Str(g, " || ");
				BoolTerm(g, sum.term);
				sum := sum.next
			END;
		ELSE
			IF sum.add = Ast.Minus THEN
				Chr(g, "-")
			ELSIF sum.add = Ast.Plus THEN
				Chr(g, "+")
			END;
			CheckExpr(g, sum.term);
			sum := sum.next;
			WHILE sum # NIL DO
				ASSERT(sum.type.id IN Ast.Numbers);
				CASE sum.add OF
				  Ast.Minus: Str(g, " - ")
				| Ast.Plus:  Str(g, " + ")
				END;
				CheckExpr(g, sum.term);
				sum := sum.next
			END
		END
	END Sum;

	PROCEDURE SumCheck(VAR g: Generator; sum: Ast.ExprSum);
	VAR arr: ARRAY TranLim.TermsInSum OF Ast.ExprSum;
		i, last: INTEGER;

		PROCEDURE GenArrOfAddOrSub(VAR g: Generator;
		                           arr: ARRAY OF Ast.ExprSum; last: INTEGER;
		                           add, sub: ARRAY OF CHAR);
		VAR i: INTEGER;
		BEGIN
			i := last;
			WHILE i > 0 DO
				CASE arr[i].add OF
				  Ast.Minus:
					Str(g, sub)
				| Ast.Plus:
					Str(g, add)
				END;
				DEC(i)
			END;
			IF arr[0].add = Ast.Minus THEN
				Str(g, sub);
				Str(g, "0, ");
				Expression(g, arr[0].term);
				Chr(g, ")")
			ELSE
				Expression(g, arr[0].term)
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
			GenArrOfAddOrSub(g, arr, last, "o7_add("  , "o7_sub(")
		| Ast.IdLongInt:
			GenArrOfAddOrSub(g, arr, last, "o7_ladd(" , "o7_lsub(")
		| Ast.IdReal:
			GenArrOfAddOrSub(g, arr, last, "o7_fadd(" , "o7_fsub(")
		| Ast.IdReal32:
			GenArrOfAddOrSub(g, arr, last, "o7_faddf(", "o7_fsubf(")
		END;
		i := 0;
		WHILE i < last DO
			INC(i);
			Str(g, ", ");
			Expression(g, arr[i].term);
			Chr(g, ")")
		END
	END SumCheck;

	PROCEDURE IsPresentDiv(term: Ast.ExprTerm): BOOLEAN;
	BEGIN
		WHILE ~(term.mult IN {Ast.Div, Ast.Mod})
		    & (term.expr IS Ast.ExprTerm)
		DO
			term := term.expr(Ast.ExprTerm)
		END
		RETURN term.mult IN {Ast.Div, Ast.Mod}
	END IsPresentDiv;

	PROCEDURE Term(VAR g: Generator; term: Ast.ExprTerm);
	BEGIN
		REPEAT
			CheckExpr(g, term.factor);
			CASE term.mult OF
			  Ast.Mult:
				IF term.type.id IN Ast.Sets THEN
					Str(g, " & ")
				ELSE
					Str(g, " * ")
				END
			| Ast.Rdiv, Ast.Div:
				IF term.type.id IN Ast.Sets THEN
					ASSERT(term.mult = Ast.Rdiv);
					Str(g, " ^ ")
				ELSE
					Str(g, " / ")
				END
			| Ast.And: Str(g, " && ")
			| Ast.Mod: Str(g, " % ")
			END;
			IF term.expr IS Ast.ExprTerm THEN
				term := term.expr(Ast.ExprTerm)
			ELSE
				CheckExpr(g, term.expr);
				term := NIL
			END
		UNTIL term = NIL
	END Term;

	(* TODO Убрать разные генерации, использовать преобразования дерева *)
	PROCEDURE TermCheck(VAR g: Generator; term: Ast.ExprTerm);
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
		IF arr[0].value # NIL THEN
			WHILE i >= 0 DO
				CASE arr[i].mult OF
				  Ast.Mult : Str(g, "O7_MUL(")
				| Ast.Div  : Str(g, "O7_DIV(")
				| Ast.Mod  : Str(g, "O7_MOD(")
				END;
				DEC(i)
			END
		ELSE
		CASE term.type.id OF
		  Ast.IdInteger:
			WHILE i >= 0 DO
				CASE arr[i].mult OF
				  Ast.Mult : Str(g, "o7_mul(")
				| Ast.Div  : Str(g, "o7_div(")
				| Ast.Mod  : Str(g, "o7_mod(")
				END;
				DEC(i)
			END
		| Ast.IdLongInt:
			WHILE i >= 0 DO
				CASE arr[i].mult OF
				  Ast.Mult : Str(g, "o7_lmul(")
				| Ast.Div  : Str(g, "o7_ldiv(")
				| Ast.Mod  : Str(g, "o7_lmod(")
				END;
				DEC(i)
			END
		| Ast.IdReal:
			WHILE i >= 0 DO
				CASE arr[i].mult OF
				  Ast.Mult : Str(g, "o7_fmul(")
				| Ast.Rdiv : Str(g, "o7_fdiv(")
				END;
				DEC(i)
			END
		| Ast.IdReal32:
			WHILE i >= 0 DO
				CASE arr[i].mult OF
				  Ast.Mult : Str(g, "o7_fmulf(")
				| Ast.Rdiv : Str(g, "o7_fdivf(")
				END;
				DEC(i)
			END
		END
		END;
		Expression(g, arr[0].factor);
		i := 0;
		WHILE i < last DO
			INC(i);
			Str(g, ", ");
			Expression(g, arr[i].factor);
			Str(g, ")")
		END;
		Str(g, ", ");
		Expression(g, arr[last].expr);
		Chr(g, ")")
	END TermCheck;

	PROCEDURE Boolean(VAR g: Generator; e: Ast.ExprBoolean);
	BEGIN
		IF g.opt.std = IsoC90 THEN
			IF e.bool
			THEN Str(g, "(0 < 1)")
			ELSE Str(g, "(0 > 1)")
			END
		ELSE
			IF e.bool
			THEN Str(g, "true")
			ELSE Str(g, "false")
			END
		END
	END Boolean;

	PROCEDURE CString(VAR g: Generator; e: Ast.ExprString);
	VAR s: ARRAY 6 OF CHAR; ch: CHAR; w: Strings.String;
	BEGIN
		w := e.string;
		IF e.asChar & ~g.opt.expectArray THEN
			ch := CHR(e.int);
			IF ch = "'" THEN
				Str(g, "(o7_char)'\''")
			ELSIF ch = "\" THEN
				Str(g, "(o7_char)'\\'")
			ELSIF (ch >= " ") & (ch <= CHR(127)) THEN
				Str(g, "(o7_char)");
				s[0] := "'";
				s[1] := ch;
				s[2] := "'";
				Text.Data(g, s, 0, 3)
			ELSE
				Str(g, "0x");
				s[0] := Hex.To(e.int DIV 16);
				s[1] := Hex.To(e.int MOD 16);
				s[2] := "u";
				Text.Data(g, s, 0, 3)
			END
		ELSE
			IF ~g.insideSizeOf THEN
				Str(g, "(o7_char *)")
			END;
			IF (w.ofs >= 0) & (w.block.s[w.ofs] = Utf8.DQuote) THEN
				Text.ScreeningString(g, w, g.opt.escapeHighChars)
			ELSE
				s[0] := Utf8.DQuote;
				s[1] := "\";
				s[2] := "x";
				s[3] := Hex.To(e.int DIV 16);
				s[4] := Hex.To(e.int MOD 16);
				s[5] := Utf8.DQuote;
				Text.Data(g, s, 0, 6)
			END
		END
	END CString;

	PROCEDURE ExprInt(VAR g: Generator; int: INTEGER);
	BEGIN
		IF int >= 0 THEN
			Int(g, int)
		ELSE
			Str(g, "(-");
			Int(g, -int);
			Chr(g, ")")
		END
	END ExprInt;

	PROCEDURE ExprLongInt(VAR g: Generator; int: INTEGER);
	BEGIN
		ASSERT(FALSE);
		IF int >= 0 THEN
			Int(g, int)
		ELSE
			Str(g, "(-");
			Int(g, -int);
			Chr(g, ")")
		END
	END ExprLongInt;

	PROCEDURE SetValue(VAR g: Generator; set: Ast.ExprSetValue);
	BEGIN
		(* TODO *)
		ASSERT(set.set[1] = {});

		Str(g, "0x");
		Text.Set(g, set.set[0]);
		Chr(g, "u")
	END SetValue;

	PROCEDURE Set(VAR g: Generator; set: Ast.ExprSet);
		PROCEDURE Item(VAR g: Generator; set: Ast.ExprSet);
		VAR v: INTEGER;
		BEGIN
			IF set.exprs[0] = NIL THEN
				Chr(g, "0")
			ELSE
				IF set.exprs[1] = NIL THEN
					IF set.exprs[0].value # NIL THEN
						v := set.exprs[0].value(Ast.ExprInteger).int
					ELSE
						v := 63
					END;
					IF v <= Limits.SetMax THEN
						Str(g, "(1u << ")
					ELSE
						Str(g, "((o7_ulong_t)1 << ")
					END;
					Factor(g, set.exprs[0])
				ELSE
					IF (set.exprs[0].value = NIL) OR (set.exprs[1].value = NIL)
					THEN Str(g, "o7_set(")
					ELSE Str(g, "O7_SET(")
					END;
					Expression(g, set.exprs[0]);
					Str(g, ", ");
					Expression(g, set.exprs[1])
				END;
				Chr(g, ")")
			END
		END Item;
	BEGIN
		IF set.next = NIL THEN
			Item(g, set)
		ELSE
			Chr(g, "(");
			Item(g, set);
			REPEAT
				Str(g, " | ");
				set := set.next;
				Item(g, set)
			UNTIL set.next = NIL;
			Chr(g, ")")
		END
	END Set;

	PROCEDURE IsExtension(VAR g: Generator; is: Ast.ExprIsExtension);
	VAR decl: Ast.Declaration;
		extType: Ast.Type;
	BEGIN
		decl := is.designator.decl;
		extType := is.extType;
		IF is.designator.type.id = Ast.IdPointer THEN
			extType := extType.type;
			ASSERT(CheckStructName(g, extType(Ast.Record)));
			Str(g, "o7_is(");
			Expression(g, is.designator);
			Str(g, ", &")
		ELSE
			Str(g, "o7_is_r(");
			GlobalName(g, decl);
			Str(g, "_tag, ");
			GlobalName(g, decl);
			Str(g, ", &")
		END;
		GlobalName(g, extType);
		Str(g, "_tag)")
	END IsExtension;
BEGIN
	CASE expr.id OF
	  Ast.IdInteger:
		ExprInt(g, expr(Ast.ExprInteger).int)
	| Ast.IdLongInt:
		ExprLongInt(g, expr(Ast.ExprInteger).int)
	| Ast.IdBoolean:
		Boolean(g, expr(Ast.ExprBoolean))
	| Ast.IdReal, Ast.IdReal32:
		IF Strings.IsDefined(expr(Ast.ExprReal).str)
		THEN	Text.String(g, expr(Ast.ExprReal).str)
		ELSE	Text.Real(g, expr(Ast.ExprReal).real)
		END
	| Ast.IdString:
		CString(g, expr(Ast.ExprString))
	| Ast.IdSet, Ast.IdLongSet:
		IF expr IS Ast.ExprSet THEN
			Set(g, expr(Ast.ExprSet))
		ELSE
			SetValue(g, expr(Ast.ExprSetValue))
		END
	| Ast.IdCall:
		Call(g, expr(Ast.ExprCall))
	| Ast.IdDesignator:
		IF (expr.value # NIL) & (expr.value.id = Ast.IdString)
		THEN	CString(g, expr.value(Ast.ExprString))
		ELSE	Designator(g, expr(Ast.Designator))
		END
	| Ast.IdRelation:
		Relation(g, expr(Ast.ExprRelation))
	| Ast.IdSum:
		IF	g.opt.checkArith
			& (expr.type.id IN CheckableArithTypes)
			& (expr.value = NIL)
		THEN	SumCheck(g, expr(Ast.ExprSum))
		ELSE	Sum(g, expr(Ast.ExprSum))
		END
	| Ast.IdTerm:
		IF    g.opt.checkArith
			& (expr.type.id IN CheckableArithTypes)
			& (expr.value = NIL)
		OR
			  (expr.type.id IN Ast.Integers)
			& IsPresentDiv(expr(Ast.ExprTerm))
		THEN
			TermCheck(g, expr(Ast.ExprTerm))
		ELSIF (expr.value # NIL)
		    & (Ast.ExprIntNegativeDividentTouch IN expr.properties)
		THEN
			Expression(g, expr.value)
		ELSE
			Term(g, expr(Ast.ExprTerm))
		END
	| Ast.IdNegate:
		IF expr.type.id IN Ast.Sets THEN
			Chr(g, "~");
			Expression(g, expr(Ast.ExprNegate).expr)
		ELSE
			Chr(g, "!");
			CheckExpr(g, expr(Ast.ExprNegate).expr)
		END
	| Ast.IdBraces:
		Chr(g, "(");
		Expression(g, expr(Ast.ExprBraces).expr);
		Chr(g, ")")
	| Ast.IdPointer:
		Str(g, "NULL")
	| Ast.IdIsExtension:
		IsExtension(g, expr(Ast.ExprIsExtension))
	| Ast.IdExprType:
		Qualifier(g, expr.type)
	END
END Expression;

PROCEDURE Invert(VAR g: Generator);
BEGIN
	g.memout.invert := ~g.memout.invert
END Invert;

PROCEDURE ProcHead(VAR g: Generator; proc: Ast.ProcType);

	PROCEDURE Parameters(VAR g: Generator; proc: Ast.ProcType);
	VAR p: Ast.Declaration;

		PROCEDURE Par(VAR g: Generator; fp: Ast.FormalParam);
		VAR t: Ast.Type;
			i: INTEGER;
		BEGIN
			i := 0;
			t := fp.type;
			IF ~((t.id = Ast.IdArray) & g.opt.e2k & (t.type.id # Ast.IdArray)) THEN
				WHILE (t.id = Ast.IdArray) & (t(Ast.Array).count = NIL) DO
					Str(g, "o7_int_t ");
					Name(g, fp);
					Str(g, "_len");
					Int(g, i);
					Str(g, ", ");
					INC(i);
					t := t.type
				END
			END;
			t := fp.type;
			declarator(g, fp, FALSE, FALSE(*TODO*), FALSE);
			IF (t.id = Ast.IdRecord)
			 & (~g.opt.skipUnusedTag OR Ast.IsNeedTag(fp))
			THEN
				Str(g, ", o7_tag_t *");
				Name(g, fp);
				Str(g, "_tag")
			END
		END Par;
	BEGIN
		IF proc.params = NIL THEN
			Str(g, "(void)")
		ELSE
			Chr(g, "(");
			p := proc.params;
			WHILE p # proc.end DO
				Par(g, p(Ast.FormalParam));
				Str(g, ", ");
				p := p.next
			END;
			Par(g, p(Ast.FormalParam));
			Chr(g, ")")
		END
	END Parameters;
BEGIN
	Parameters(g, proc);
	Invert(g);
	type(g, NIL, proc.type, FALSE, FALSE(* TODO *));
	MemWriteInvert(g.memout^)
END ProcHead;

PROCEDURE Declarator(VAR gen: Generator; decl: Ast.Declaration;
                     typeDecl, sameType, global: BOOLEAN);
VAR g: Generator; mo: PMemoryOut;
BEGIN
	mo := PMemoryOutGet(gen.opt);

	Text.Init(g, mo);
	g.memout := mo;
	Text.TransiteOptions(g, gen);
	g.module := gen.module;
	g.interface := gen.interface;
	g.opt := gen.opt;

	IF (decl IS Ast.FormalParam)
	 & (   (Ast.ParamOut IN decl(Ast.FormalParam).access)
	     & (decl.type.id # Ast.IdArray)
	    OR (decl.type.id = Ast.IdRecord)
	   )
	THEN
		Chr(g, "*")
	ELSIF decl.id = Ast.IdConst THEN
		Str(g, "const ")
	END;
	IF global THEN
		GlobalName(g, decl)
	ELSE
		Name(g, decl)
	END;
	IF decl.id = Ast.IdProc THEN
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

	PMemoryOutBack(g.opt, mo)
END Declarator;

PROCEDURE RecordUndefHeader(VAR g: Generator; rec: Ast.Record; interf: BOOLEAN);
BEGIN
	IF rec.mark & ~g.opt.main THEN
		Str(g, "extern void ")
	ELSE
		Str(g, "static void ")
	END;
	GlobalName(g, rec);
	Str(g, "_undef(struct ");
	GlobalName(g, rec);
	IF interf THEN
		StrLn(g, " *r);")
	ELSE
		StrOpen(g, " *r) {")
	END
END RecordUndefHeader;

PROCEDURE RecordRetainReleaseHeader(VAR g: Generator; rec: Ast.Record;
                                    interf: BOOLEAN; retrel: ARRAY OF CHAR);
BEGIN
	IF rec.mark & ~g.opt.main  THEN
		Str(g, "extern void ")
	ELSE
		Str(g, "static void ")
	END;
	GlobalName(g, rec);
	Str(g, retrel);
	Str(g, "(struct ");
	GlobalName(g, rec);
	IF interf THEN
		StrLn(g, " *r);")
	ELSE
		StrOpen(g, " *r) {")
	END
END RecordRetainReleaseHeader;

PROCEDURE RecordReleaseHeader(VAR g: Generator; rec: Ast.Record; interf: BOOLEAN);
BEGIN
	RecordRetainReleaseHeader(g, rec, interf, "_release")
END RecordReleaseHeader;

PROCEDURE RecordRetainHeader(VAR g: Generator; rec: Ast.Record; interf: BOOLEAN);
BEGIN
	RecordRetainReleaseHeader(g, rec, interf, "_retain")
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

PROCEDURE ArraySimpleUndef(VAR g: Generator; arrTypeId: INTEGER;
                           d: Ast.Declaration; inRec: BOOLEAN);
BEGIN
	CASE arrTypeId OF
	  Ast.IdInteger:
		Str(g, "O7_INTS_UNDEF(")
	| Ast.IdLongInt:
		Str(g, "O7_LONGS_UNDEF(")
	| Ast.IdReal:
		Str(g, "O7_DOUBLES_UNDEF(")
	| Ast.IdReal32:
		Str(g, "O7_FLOATS_UNDEF(")
	| Ast.IdBoolean:
		Str(g, "O7_BOOLS_UNDEF(")
	END;
	IF inRec THEN
		Str(g, "r->")
	END;
	Name(g, d);
	Str(g, ");")
END ArraySimpleUndef;

PROCEDURE RecordUndefCall(VAR g: Generator; var: Ast.Declaration);
BEGIN
	GlobalName(g, var.type);
	Str(g, "_undef(&");
	GlobalName(g, var);
	StrLn(g, ");")
END RecordUndefCall;

PROCEDURE TypeForUndef(t: Ast.Type): Ast.Type;
BEGIN
	IF (t.id # Ast.IdRecord) OR (t.ext = NIL) OR ~t.ext(RecExt).undef THEN
		t := NIL
	END
	RETURN t
END TypeForUndef;

(* TODO Навести порядок *)
PROCEDURE RecordUndef(VAR g: Generator; rec: Ast.Record);
VAR var: Ast.Declaration;
	arrTypeId, arrDeep: INTEGER;
	typeUndef: Ast.Type;

	PROCEDURE IteratorIfNeed(VAR g: Generator; var: Ast.Declaration);
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
			StrLn(g, "o7_int_t i;")
		END
	END IteratorIfNeed;

	PROCEDURE Memset(VAR g: Generator; var: Ast.Declaration);
	BEGIN
		Str(g, "memset(&r->");
		Name(g, var);
		Str(g, ", 0, sizeof(r->");
		Name(g, var);
		StrLn(g, "));")
	END Memset;
BEGIN
	RecordUndefHeader(g, rec, FALSE);
	IteratorIfNeed(g, rec.vars);
	IF rec.base # NIL THEN
		GlobalName(g, rec.base);
		IF ~g.opt.plan9 THEN
			StrLn(g, "_undef(&r->_);")
		ELSE
			StrLn(g, "_undef(r);")
		END
	END;
	rec.ext(RecExt).undef := TRUE;
	var := rec.vars;
	WHILE var # NIL DO
		IF ~(var.type.id IN {Ast.IdArray, Ast.IdRecord}) THEN
			Str(g, "r->");
			Name(g, var);
			VarInit(g, var, TRUE);
			StrLn(g, ";");
		ELSIF var.type.id = Ast.IdArray THEN
			typeUndef := TypeForUndef(var.type.type);
			IF IsArrayTypeSimpleUndef(var.type, arrTypeId, arrDeep) THEN
				ArraySimpleUndef(g, arrTypeId, var, TRUE)
			ELSIF typeUndef # NIL THEN (* TODO вложенные циклы *)
				Str(g, "for (i = 0; i < O7_LEN(r->");
				Name(g, var);
				StrOpen(g, "); i += 1) {");
				GlobalName(g, typeUndef);
				Str(g, "_undef(r->");
				Name(g, var);
				StrLn(g, " + i);");

				StrLnClose(g, "}")
			ELSE
				Memset(g, var)
			END
		ELSIF (var.type.id = Ast.IdRecord) & (var.type.ext # NIL) THEN
			GlobalName(g, var.type);
			Str(g, "_undef(&r->");
			Name(g, var);
			StrLn(g, ");")
		ELSE
			Memset(g, var)
		END;
		var := var.next
	END;
	StrLnClose(g, "}")
END RecordUndef;

PROCEDURE RecordRetainRelease(VAR g: Generator; rec: Ast.Record;
                              retrel, retrelArray, retNull: ARRAY OF CHAR);
VAR var: Ast.Declaration;

	PROCEDURE IteratorIfNeed(VAR g: Generator; var: Ast.Declaration);
	BEGIN
		WHILE (var # NIL)
		    & ~((var.type.id = Ast.IdArray)
		      & (var.type.type.id = Ast.IdRecord)
		       )
		DO
			var := var.next
		END;
		IF var # NIL THEN
			StrLn(g, "o7_int_t i;")
		END
	END IteratorIfNeed;
BEGIN
	RecordRetainReleaseHeader(g, rec, FALSE, retrel);

	IteratorIfNeed(g, rec.vars);
	IF rec.base # NIL THEN
		GlobalName(g, rec.base);
		Str(g, retrel);
		IF ~g.opt.plan9 THEN
			StrLn(g, "(&r->_);")
		ELSE
			StrLn(g, "(r);")
		END
	END;
	var := rec.vars;
	WHILE var # NIL DO
		IF var.type.id = Ast.IdArray THEN
			IF var.type.type.id = Ast.IdPointer THEN (* TODO *)
				Str(g, retrelArray);
				Name(g, var);
				StrLn(g, ");")
			ELSIF (var.type.type.id = Ast.IdRecord)
			   & (var.type.type.ext # NIL) & var.type.type.ext(RecExt).undef
			THEN
				Str(g, "for (i = 0; i < O7_LEN(r->");
				Name(g, var);
				StrOpen(g, "); i += 1) {");
				GlobalName(g, var.type.type);
				Str(g, retrel);
				Str(g, "(r->");
				Name(g, var);
				StrLn(g, " + i);");
				StrLnClose(g, "}")
			END
		ELSIF (var.type.id = Ast.IdRecord) & (var.type.ext # NIL) THEN
			GlobalName(g, var.type);
			Str(g, retrel);
			Str(g, "(&r->");
			Name(g, var);
			StrLn(g, ");")
		ELSIF var.type.id = Ast.IdPointer THEN
			Str(g, retNull);
			Str(g, "r->");
			Name(g, var);
			StrLn(g, ");")
		END;
		var := var.next
	END;
	StrLnClose(g, "}")
END RecordRetainRelease;

PROCEDURE RecordRelease(VAR g: Generator; rec: Ast.Record);
BEGIN
	RecordRetainRelease(g, rec, "_release", "O7_RELEASE_ARRAY(r->", "O7_NULL(&")
END RecordRelease;

PROCEDURE RecordRetain(VAR g: Generator; rec: Ast.Record);
BEGIN
	RecordRetainRelease(g, rec, "_retain", "O7_RETAIN_ARRAY(r->", "o7_retain(")
END RecordRetain;

PROCEDURE Comment(VAR g: Generator; com: Strings.String);
BEGIN
	GenCommon.CommentC(g, g.opt^, com)
END Comment;

PROCEDURE EmptyLines(VAR g: Generator; d: Ast.PNode);
BEGIN
	IF 0 < d.emptyLines THEN
		Ln(g)
	END
END EmptyLines;

PROCEDURE Type(VAR g: Generator; decl: Ast.Declaration; typ: Ast.Type;
               typeDecl, sameType: BOOLEAN);

	PROCEDURE Simple(VAR g: Generator; str: ARRAY OF CHAR);
	BEGIN
		Str(g, str);
		MemWriteInvert(g.memout^)
	END Simple;

	PROCEDURE Record(VAR g: Generator; rec: Ast.Record);
	VAR v: Ast.Declaration;
	BEGIN
		rec.module := g.module.bag;
		Str(g, "struct ");
		IF CheckStructName(g, rec) THEN
			GlobalName(g, rec)
		END;
		v := rec.vars;
		IF (v = NIL) & (rec.base = NIL) & ~g.opt.gnu THEN
			Str(g, " { char nothing; } ")
		ELSE
			StrOpen(g, " {");

			IF rec.base # NIL THEN
				GlobalName(g, rec.base);
				IF g.opt.plan9 THEN
					StrLn(g, ";")
				ELSE
					StrLn(g, " _;")
				END
			END;

			WHILE v # NIL DO
				EmptyLines(g, v);
				Declarator(g, v, FALSE, FALSE, FALSE);
				StrLn(g, ";");
				v := v.next
			END;
			Text.StrClose(g, "} ")
		END;
		MemWriteInvert(g.memout^)
	END Record;

	PROCEDURE Array(VAR g: Generator; decl: Ast.Declaration; arr: Ast.Array;
	                sameType: BOOLEAN);
	VAR t: Ast.Type;
		i: INTEGER;
	BEGIN
		t := arr.type;
		MemWriteInvert(g.memout^);
		IF arr.count # NIL THEN
			Chr(g, "[");
			Expression(g, arr.count);
			Chr(g, "]")
		ELSIF g.opt.vla THEN
			i := 0;
			t := arr;
			REPEAT
				Text.Data(g, "[O7_VLA(", 0, 1 + ORD(g.opt.vlaMark) * 8);
				Name(g, decl);
				Str(g, "_len");
				Int(g, i);
				Text.Data(g, ")]", ORD(~g.opt.vlaMark), 2 - ORD(~g.opt.vlaMark));
				t := t.type;
				INC(i)
			UNTIL t.id # Ast.IdArray
		ELSE
			Str(g, "[/*len0");
			i := 0;
			WHILE (t.id = Ast.IdArray) & (t(Ast.Array).count = NIL) DO
				INC(i);
				Str(g, ", len");
				Int(g, i);
				t := t.type
			END;
			Str(g, "*/]");
			WHILE t.id = Ast.IdArray DO
				Chr(g, "[");
				Int(g, t(Ast.Array).count.value(Ast.ExprInteger).int);
				Chr(g, "]");
				t := t.type
			END
		END;
		Invert(g);
		Type(g, decl, t, FALSE, sameType)
	END Array;
BEGIN
	IF typ = NIL THEN
		Str(g, "void ");
		MemWriteInvert(g.memout^)
	ELSE
		IF ~typeDecl & Strings.IsDefined(typ.name) THEN
			IF sameType THEN
				IF (typ.id = Ast.IdPointer) & Strings.IsDefined(typ.type.name) THEN
					Chr(g, "*")
				END
			ELSE
				IF (typ.id = Ast.IdPointer) & Strings.IsDefined(typ.type.name) THEN
					Str(g, "struct ");
					GlobalName(g, typ.type); Str(g, " *")
				ELSIF typ.id = Ast.IdRecord THEN
					Str(g, "struct ");
					IF CheckStructName(g, typ(Ast.Record)) THEN
						GlobalName(g, typ); Chr(g, " ")
					END
				ELSE
					GlobalName(g, typ); Chr(g, " ")
				END;
				IF g.memout # NIL THEN
					MemWriteInvert(g.memout^)
				END
			END
		ELSIF ~sameType OR (typ.id IN (Ast.Pointers + {Ast.IdArray})) THEN
			CASE typ.id OF
			  Ast.IdInteger:
				Simple(g, "o7_int_t ")
			| Ast.IdLongInt:
				Simple(g, "o7_long_t ")
			| Ast.IdSet:
				Simple(g, "o7_set_t ")
			| Ast.IdLongSet:
				Simple(g, "o7_set64_t ")
			| Ast.IdBoolean:
				IF (g.opt.std >= IsoC99)
				 & (g.opt.varInit # GenOptions.VarInitUndefined)
				THEN	Simple(g, "bool ")
				ELSE	Simple(g, "o7_bool ")
				END
			| Ast.IdByte:
				Simple(g, "char unsigned ")
			| Ast.IdChar:
				Simple(g, "o7_char ")
			| Ast.IdReal:
				Simple(g, "double ")
			| Ast.IdReal32:
				Simple(g, "float ")
			| Ast.IdPointer:
				Chr(g, "*");
				MemWriteInvert(g.memout^);
				Invert(g);
				Type(g, decl, typ.type, FALSE, sameType)
			| Ast.IdArray:
				Array(g, decl, typ(Ast.Array), sameType)
			| Ast.IdRecord:
				Record(g, typ(Ast.Record))
			| Ast.IdProcType, Ast.IdFuncType:
				Str(g, "(*");
				MemWriteInvert(g.memout^);
				Chr(g, ")");
				ProcHead(g, typ(Ast.ProcType))
			END
		END;
		IF g.memout # NIL THEN
			MemWriteInvert(g.memout^)
		END
	END
END Type;

PROCEDURE RecordTag(VAR g: Generator; rec: Ast.Record);
BEGIN
	IF (g.opt.memManager # MemManagerCounter) & (rec.base = NIL) THEN
		Str(g, "#define ");
		GlobalName(g, rec);
		StrLn(g, "_tag o7_base_tag")
	ELSIF (g.opt.memManager # MemManagerCounter)
	    & ~rec.needTag & g.opt.skipUnusedTag
	THEN
		Str(g, "#define ");
		GlobalName(g, rec);
		Str(g, "_tag ");
		GlobalName(g, rec.base);
		StrLn(g, "_tag")
	ELSE
		IF ~rec.mark OR g.opt.main THEN
			Str(g, "static o7_tag_t ")
		ELSIF g.interface THEN
			Str(g, "extern o7_tag_t ")
		ELSE
			Str(g, "o7_tag_t ")
		END;
		GlobalName(g, rec);
		StrLn(g, "_tag;")
	END;
	IF ~rec.mark OR g.opt.main OR g.interface THEN
		Ln(g)
	END
END RecordTag;

PROCEDURE TypeDecl(VAR out: MOut; typ: Ast.Type);

	PROCEDURE Typedef(VAR g: Generator; typ: Ast.Type);
	BEGIN
		EmptyLines(g, typ);
		Str(g, "typedef ");
		Declarator(g, typ, TRUE, FALSE, TRUE);
		StrLn(g, ";")
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
			IF out.opt.varInit = GenOptions.VarInitUndefined THEN
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
		IF out.opt.varInit = GenOptions.VarInitUndefined THEN
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

PROCEDURE Mark(VAR g: Generator; mark: BOOLEAN);
BEGIN
	IF g.localDeep = 0 THEN
		IF mark & ~g.opt.main THEN
			Str(g, "extern ")
		ELSE
			Str(g, "static ")
		END
	END
END Mark;

PROCEDURE Const(VAR g: Generator; const: Ast.Const);
BEGIN
	Comment(g, const.comment);
	EmptyLines(g, const);
	Text.StrIgnoreIndent(g, "#");
	Str(g, "define ");
	GlobalName(g, const);
	Chr(g, " ");
	IF const.mark & (const.expr.value # NIL) THEN
		Factor(g, const.expr.value)
	ELSE
		Factor(g, const.expr)
	END;
	Ln(g)
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
			StrLn(out.g[ORD(mark)], ";")
		END;
		Mark(out.g[ORD(mark)], mark)
	ELSE
		Str(out.g[ORD(mark)], ", ")
	END;
	IF mark THEN
		Declarator(out.g[Interface], var, FALSE, same, TRUE);
		IF last THEN
			StrLn(out.g[Interface], ";")
		END;

		IF same THEN
			Str(out.g[Implementation], ", ")
		ELSIF prev # NIL THEN
			StrLn(out.g[Implementation], ";")
		END
	END;

	Declarator(out.g[Implementation], var, FALSE, same, TRUE);

	VarInit(out.g[Implementation], var, FALSE);

	IF last THEN
		StrLn(out.g[Implementation], ";")
	END
END Var;

PROCEDURE ExprThenStats(VAR g: Generator; VAR wi: Ast.WhileIf);
BEGIN
	CheckExpr(g, wi.expr);
	StrOpen(g, ") {");
	statements(g, wi.stats);
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

PROCEDURE ExprSameType(VAR g: Generator;
                       expr: Ast.Expression; expectType: Ast.Type);
VAR reref, brace: BOOLEAN;
    base, extend: Ast.Record;
BEGIN
	base   := NIL;
	extend := NIL;

	reref := (expr.type.id = Ast.IdPointer)
	       & (expr.type.type # expectType.type)
	       & (expr.id # Ast.IdPointer);
	brace := reref;
	IF ~reref THEN
		CheckExpr(g, expr);
		IF expr.type.id = Ast.IdRecord THEN
			base   := expectType(Ast.Record);
			extend := expr.type(Ast.Record)
		END
	ELSIF g.opt.plan9 THEN
		CheckExpr(g, expr);
		brace := FALSE
	ELSE
		CastedPointer(g, expr, expectType);
		brace := FALSE
	END;
	IF extend # base THEN
		(*ASSERT(expectType.id = Ast.IdRecord);*)
		IF g.opt.plan9 THEN
			Chr(g, ".");
			GlobalName(g, expectType)
		ELSE
			WHILE extend # base DO
				Str(g, "._");
				extend := extend.base
			END
		END
	END;
	IF brace THEN
		Chr(g, ")")
	END
END ExprSameType;

PROCEDURE ExprForSize(VAR g: Generator; e: Ast.Expression);
BEGIN
	g.insideSizeOf := TRUE;
	Expression(g, e);
	g.insideSizeOf := FALSE
END ExprForSize;

PROCEDURE Assign(VAR g: Generator; st: Ast.Assign);

	PROCEDURE Equal(VAR g: Generator; st: Ast.Assign);
	VAR retain, toByte: BOOLEAN;

		PROCEDURE AssertArraySize(VAR g: Generator;
		                          des: Ast.Designator; e: Ast.Expression);
		BEGIN
			IF g.opt.checkIndex
			 & (  (des.type(Ast.Array).count = NIL)
			   OR (e.type(Ast.Array).count   = NIL)
			   )
			THEN
				Str(g, "assert(");
				ArrayLen(g, des);
				Str(g, " >= ");
				ArrayLen(g, e);
				StrLn(g, ");")
			END
		END AssertArraySize;
	BEGIN
		toByte := (st.designator.type.id = Ast.IdByte)
		        & (st.expr.type.id IN {Ast.IdInteger, Ast.IdLongInt})
		        & g.opt.checkArith & (st.expr.value = NIL);
		retain := (st.designator.type.id = Ast.IdPointer)
		        & (g.opt.memManager = MemManagerCounter);
		IF retain & (st.expr.id = Ast.IdPointer) THEN
			Str(g, "O7_NULL(&");
			Designator(g, st.designator);
		ELSE
			IF retain THEN
				Str(g, "O7_ASSIGN(&");
				Designator(g, st.designator);
				Str(g, ", ")
			ELSIF st.designator.type.id = Ast.IdArray THEN
				AssertArraySize(g, st.designator, st.expr);
				Str(g, "memcpy(");
				Designator(g, st.designator);
				Str(g, ", ");
				g.opt.expectArray := TRUE
			ELSIF toByte THEN
				Designator(g, st.designator);
				IF st.expr.type.id = Ast.IdInteger THEN
					Str(g, " = o7_byte(")
				ELSE
					Str(g, " = o7_lbyte(")
				END
			ELSE
				Designator(g, st.designator);
				Str(g, " = ")
			END;
			ExprSameType(g, st.expr, st.designator.type);
			g.opt.expectArray := FALSE;
			IF st.designator.type.id # Ast.IdArray THEN
				;
			ELSIF (st.expr.type(Ast.Array).count # NIL)
			    & ~Ast.IsFormalParam(st.expr)
			THEN
				IF (st.expr.id = Ast.IdString) & st.expr(Ast.ExprString).asChar THEN
					Str(g, ", 2")
				ELSE
					Str(g, ", sizeof(");
					ExprForSize(g, st.expr);
					Chr(g, ")")
				END
			ELSIF g.opt.e2k THEN
				Str(g, ", O7_E2K_SIZE(");
				GlobalName(g, st.expr(Ast.Designator).decl);
				Chr(g, ")")
			ELSE
				Str(g, ", (");
				ArrayLen(g, st.expr);
				Str(g, ") * sizeof(");
				ExprForSize(g, st.expr);
				Str(g, "[0])")
			END
		END;
		Text.CharFill(g, ")", ORD(retain) + ORD(toByte) + ORD(st.designator.type.id = Ast.IdArray));
		IF (g.opt.memManager = MemManagerCounter)
		 & (st.designator.type.id = Ast.IdRecord)
		 & (~IsAnonStruct(st.designator.type(Ast.Record)))
		THEN
			StrLn(g, ";");
			GlobalName(g, st.designator.type);
			Str(g, "_retain(&");
			Designator(g, st.designator);
			Chr(g, ")")
		END
	END Equal;
BEGIN
	Equal(g, st)
END Assign;

PROCEDURE Statement(VAR g: Generator; st: Ast.Statement);

	PROCEDURE WhileIf(VAR g: Generator; wi: Ast.WhileIf);

		PROCEDURE Elsif(VAR g: Generator; VAR wi: Ast.WhileIf);
		BEGIN
			WHILE (wi # NIL) & (wi.expr # NIL) DO
				Text.StrClose(g, "} else if (");
				ExprThenStats(g, wi)
			END
		END Elsif;
	BEGIN
		IF wi IS Ast.If THEN
			Str(g, "if (");
			ExprThenStats(g, wi);
			Elsif(g, wi);
			IF wi # NIL THEN
				Text.IndentClose(g);
				StrOpen(g, "} else {");
				statements(g, wi.stats)
			END;
			StrLnClose(g, "}")
		ELSIF wi.elsif = NIL THEN
			Str(g, "while (");
			ExprThenStats(g, wi);
			StrLnClose(g, "}")
		ELSE
			Str(g, "while (1) if (");
			ExprThenStats(g, wi);
			Elsif(g, wi);
			StrLnClose(g, "} else break;")
		END
	END WhileIf;

	PROCEDURE Repeat(VAR g: Generator; st: Ast.Repeat);
	VAR e: Ast.Expression;
	BEGIN
		StrOpen(g, "do {");
		statements(g, st.stats);
		IF st.expr.id = Ast.IdNegate THEN
			Text.StrClose(g, "} while (");
			e := st.expr(Ast.ExprNegate).expr;
			WHILE e.id = Ast.IdBraces DO
				e := e(Ast.ExprBraces).expr
			END;
			Expression(g, e);
			StrLn(g, ");")
		ELSE
			Text.StrClose(g, "} while (!(");
			CheckExpr(g, st.expr);
			StrLn(g, "));")
		END
	END Repeat;

	PROCEDURE For(VAR g: Generator; st: Ast.For);
		PROCEDURE IsMinus1(next: Ast.ExprSum): BOOLEAN;
		RETURN (next # NIL)
		     & (next.next = NIL)
		     & (next.add = Ast.Minus)
		     & (next.term.value # NIL)
		     & (next.term.value(Ast.ExprInteger).int = 1)
		END IsMinus1;
	BEGIN
		Str(g, "for (");
		GlobalName(g, st.var);
		Str(g, " = ");
		Expression(g, st.expr);
		Str(g, "; ");
		GlobalName(g, st.var);
		IF st.by > 0 THEN
			IF (st.to IS Ast.ExprSum) & IsMinus1(st.to(Ast.ExprSum).next) THEN
				Str(g, " < ");
				Expression(g, st.to(Ast.ExprSum).term)
			ELSE
				Str(g, " <= ");
				Expression(g, st.to)
			END;
			IF st.by = 1 THEN
				Str(g, "; ++");
				GlobalName(g, st.var)
			ELSE
				Str(g, "; ");
				GlobalName(g, st.var);
				Str(g, " += ");
				Int(g, st.by)
			END
		ELSE
			Str(g, " >= ");
			Expression(g, st.to);
			IF st.by = -1 THEN
				Str(g, "; --");
				GlobalName(g, st.var)
			ELSE
				Str(g, "; ");
				GlobalName(g, st.var);
				Str(g, " -= ");
				Int(g, -st.by)
			END
		END;
		StrOpen(g, ") {");
		statements(g, st.stats);
		StrLnClose(g, "}")
	END For;

	PROCEDURE Case(VAR g: Generator; st: Ast.Case);
	VAR elem, elemWithRange: Ast.CaseElement;
	    caseExpr: Ast.Expression;

		PROCEDURE CaseElement(VAR g: Generator; elem: Ast.CaseElement);
		VAR r: Ast.CaseLabel;
		BEGIN
			IF g.opt.gnu OR ~IsCaseElementWithRange(elem) THEN
				r := elem.labels;
				WHILE r # NIL DO
					Str(g, "case ");
					Int(g, r.value);
					IF r.right # NIL THEN
						ASSERT(g.opt.gnu);
						Str(g, " ... ");
						Int(g, r.right.value)
					END;
					StrLn(g, ":");

					r := r.next
				END;
				Text.IndentOpen(g);
				statements(g, elem.stats);
				StrLn(g, "break;");
				Text.IndentClose(g)
			END
		END CaseElement;

		PROCEDURE CaseElementAsIf(VAR g: Generator; elem: Ast.CaseElement;
		                          caseExpr: Ast.Expression);
		VAR r: Ast.CaseLabel;

			PROCEDURE CaseRange(VAR g: Generator; r: Ast.CaseLabel;
			                    caseExpr: Ast.Expression);
			BEGIN
				IF r.right = NIL THEN
					IF caseExpr = NIL THEN
						Str(g, "(o7_case_expr == ")
					ELSE
						Chr(g, "(");
						Expression(g, caseExpr);
						Str(g, " == ")
					END;
					Int(g, r.value)
				ELSE
					ASSERT(r.value <= r.right.value);
					Chr(g, "(");
					Int(g, r.value);
					IF caseExpr = NIL THEN
						Str(g, " <= o7_case_expr && o7_case_expr <= ")
					ELSE
						Str(g, " <= ");
						Expression(g, caseExpr);
						Str(g, " && ");
						Expression(g, caseExpr);
						Str(g, " <= ")
					END;
					Int(g, r.right.value)
				END;
				Chr(g, ")")
			END CaseRange;
		BEGIN
			Str(g, "if (");
			r := elem.labels;
			ASSERT(r # NIL);
			CaseRange(g, r, caseExpr);
			WHILE r.next # NIL DO
				r := r.next;
				Str(g, " || ");
				CaseRange(g, r, caseExpr)
			END;
			StrOpen(g, ") {");
			statements(g, elem.stats);
			Text.StrClose(g, "}")
		END CaseElementAsIf;
	BEGIN
		IF g.opt.gnu THEN
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
		 & ((st.expr.id # Ast.IdDesignator) OR (st.expr(Ast.Designator).sel # NIL))
		THEN
			caseExpr := NIL;
			Str(g, "{ o7_int_t o7_case_expr = ");
			Expression(g, st.expr);
			StrOpen(g, ";");
			StrLn(g, "switch (o7_case_expr) {")
		ELSE
			caseExpr := st.expr;
			Str(g, "switch (");
			Expression(g, caseExpr);
			StrLn(g, ") {")
		END;
		elem := st.elements;
		REPEAT
			CaseElement(g, elem);
			elem := elem.next
		UNTIL elem = NIL;
		StrOpen(g, "default:");
		IF elemWithRange # NIL THEN
			elem := elemWithRange;
			CaseElementAsIf(g, elem, caseExpr);
			elem := elem.next;
			WHILE elem # NIL DO
				IF IsCaseElementWithRange(elem) THEN
					Str(g, " else ");
					CaseElementAsIf(g, elem, caseExpr)
				END;
				elem := elem.next
			END;
			IF ~g.opt.caseAbort THEN
				;
			ELSIF caseExpr = NIL THEN
				StrLn(g, " else o7_case_fail(o7_case_expr);")
			ELSE
				Str(g, " else o7_case_fail(");
				Expression(g, caseExpr);
				StrLn(g, ");")
			END
		ELSIF ~g.opt.caseAbort THEN
			;
		ELSIF caseExpr = NIL THEN
			StrLn(g, "o7_case_fail(o7_case_expr);")
		ELSE
			Str(g, "o7_case_fail(");
			Expression(g, caseExpr);
			StrLn(g, ");")
		END;
		StrLn(g, "break;");
		StrLnClose(g, "}");
		IF caseExpr = NIL THEN
			StrLnClose(g, "}")
		END
	END Case;
BEGIN
	Comment(g, st.comment);
	EmptyLines(g, st);
	IF st IS Ast.Assign THEN
		Assign(g, st(Ast.Assign));
		StrLn(g, ";")
	ELSIF st IS Ast.Call THEN
		Expression(g, st.expr);
		StrLn(g, ";")
	ELSIF st IS Ast.WhileIf THEN
		WhileIf(g, st(Ast.WhileIf))
	ELSIF st IS Ast.Repeat THEN
		Repeat(g, st(Ast.Repeat))
	ELSIF st IS Ast.For THEN
		For(g, st(Ast.For))
	ELSE ASSERT(st IS Ast.Case);
		Case(g, st(Ast.Case))
	END
END Statement;

PROCEDURE Statements(VAR g: Generator; stats: Ast.Statement);
BEGIN
	WHILE stats # NIL DO
		Statement(g, stats);
		stats := stats.next
	END
END Statements;

PROCEDURE ProcDecl(VAR g: Generator; proc: Ast.Procedure);
BEGIN
	Mark(g, proc.mark);
	Declarator(g, proc, FALSE, FALSE, TRUE);
	StrLn(g, ";")
END ProcDecl;

PROCEDURE ReleaseVars(VAR g: Generator; var: Ast.Declaration);
BEGIN
	IF g.opt.memManager = MemManagerCounter THEN
		WHILE (var # NIL) & (var.id = Ast.IdVar) DO
			IF var.type.id = Ast.IdArray THEN
				IF var.type.type.id = Ast.IdPointer THEN (* TODO *)
					Str(g, "O7_RELEASE_ARRAY(");
					GlobalName(g, var);
					StrLn(g, ");")
				ELSIF (var.type.type.id = Ast.IdRecord)
				    & (var.type.type.ext # NIL) & var.type.type.ext(RecExt).undef
				THEN
					Str(g, "{int o7_i; for (o7_i = 0; o7_i < O7_LEN(");
					GlobalName(g, var);
					StrOpen(g, "); o7_i += 1) {");
					GlobalName(g, var.type.type);
					Str(g, "_release(");
					GlobalName(g, var);
					StrLn(g, " + o7_i);");
					StrLnClose(g, "}}")
				END
			ELSIF var.type.id = Ast.IdPointer THEN
				Str(g, "O7_NULL(&");
				GlobalName(g, var);
				StrLn(g, ");")
			ELSIF (var.type.id = Ast.IdRecord) & (var.type.ext # NIL) THEN
				GlobalName(g, var.type);
				Str(g, "_release(&");
				GlobalName(g, var);
				StrLn(g, ");")
			END;

			var := var.next
		END
	END
END ReleaseVars;

PROCEDURE Procedure(VAR out: MOut; proc: Ast.Procedure);

	PROCEDURE Implement(VAR out: MOut; VAR g: Generator; proc: Ast.Procedure);
	VAR retainParams: Ast.Declaration;

		PROCEDURE CloseConsts(VAR g: Generator; consts: Ast.Declaration);
		BEGIN
			WHILE (consts # NIL) & (consts.id = Ast.IdConst) DO
				Text.StrIgnoreIndent(g, "#");
				Str(g, "undef ");
				Name(g, consts);
				Ln(g);
				consts := consts.next
			END
		END CloseConsts;

		PROCEDURE SearchRetain(g: Generator; fp: Ast.Declaration): Ast.Declaration;
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

		PROCEDURE RetainParams(VAR g: Generator; fp: Ast.Declaration);
		BEGIN
			IF fp # NIL THEN
				Str(g, "o7_retain(");
				Name(g, fp);
				fp := fp.next;
				WHILE fp # NIL DO
					IF (fp.type.id = Ast.IdPointer)
					 & ~(Ast.ParamOut IN fp(Ast.FormalParam).access)
					THEN
						Str(g, "); o7_retain(");
						Name(g, fp)
					END;
					fp := fp.next
				END;
				StrLn(g, ");")
			END
		END RetainParams;

		PROCEDURE ReleaseParams(VAR g: Generator; fp: Ast.Declaration);
		BEGIN
			IF fp # NIL THEN
				Str(g, "o7_release(");
				Name(g, fp);
				fp := fp.next;
				WHILE fp # NIL DO
					IF (fp.type.id = Ast.IdPointer)
					 & ~(Ast.ParamOut IN fp(Ast.FormalParam).access)
					THEN
						Str(g, "); o7_release(");
						Name(g, fp)
					END;
					fp := fp.next
				END;
				StrLn(g, ");")
			END
		END ReleaseParams;

	BEGIN
		Comment(g, proc.comment);
		Mark(g, proc.mark);
		Declarator(g, proc, FALSE, FALSE(*TODO*), TRUE);
		StrOpen(g, " {");

		INC(g.localDeep);

		g.fixedLen := g.len;

		IF g.opt.memManager # MemManagerCounter THEN
			retainParams := NIL
		ELSE
			retainParams := SearchRetain(g, proc.header.params);
			IF proc.header.type # NIL THEN
				Qualifier(g, proc.header.type);
				IF proc.header.type.id = Ast.IdPointer
				THEN	StrLn(g, " o7_return = NULL;")
				ELSE	StrLn(g, " o7_return;")
				END
			END
		END;
		declarations(out, proc);

		RetainParams(g, retainParams);

		Statements(g, proc.stats);

		IF proc.return = NIL THEN
			ReleaseVars(g, proc.vars);
			ReleaseParams(g, retainParams)
		ELSIF g.opt.memManager = MemManagerCounter THEN
			IF proc.header.type.id = Ast.IdPointer THEN
				Str(g, "O7_ASSIGN(&o7_return, ");
				Expression(g, proc.return);
				StrLn(g, ");")
			ELSE
				Str(g, "o7_return = ");
				CheckExpr(g, proc.return);
				StrLn(g, ";")
			END;
			ReleaseVars(g, proc.vars);
			ReleaseParams(g, retainParams);
			IF proc.header.type.id = Ast.IdPointer THEN
				StrLn(g, "o7_unhold(o7_return);")
			END;
			StrLn(g, "return o7_return;")
		ELSE
			Str(g, "return ");
			ExprSameType(g, proc.return, proc.header.type);
			StrLn(g, ";")
		END;

		DEC(g.localDeep);
		CloseConsts(g, proc.start);
		StrLnClose(g, "}");
		Ln(g)
	END Implement;

	PROCEDURE LocalProcs(VAR out: MOut; proc: Ast.Procedure);
	VAR p, t: Ast.Declaration;
	BEGIN
		t := proc.types;
		WHILE (t # NIL) & (t IS Ast.Type) DO
			TypeDecl(out, t(Ast.Type));
			(*IF t.id = Ast.IdRecord THEN
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

	PROCEDURE Write(VAR g: Generator);
	BEGIN
		IF g.fixedLen # g.len THEN
			Ln(g);
			g.fixedLen := g.len
		END
	END Write;
BEGIN
	IF ~out.opt.main THEN
		Write(out.g[Interface])
	END;
	Write(out.g[Implementation])
END LnIfWrote;

PROCEDURE VarsInit(VAR g: Generator; d: Ast.Declaration);
VAR arrDeep, arrTypeId: INTEGER;
BEGIN
	WHILE (d # NIL) & (d.id = Ast.IdVar) DO
		IF d.type.id IN Ast.Structures THEN
			IF (g.opt.varInit = GenOptions.VarInitUndefined)
			 & (d.type.id = Ast.IdRecord) & Strings.IsDefined(d.type.name)
			 & Ast.IsGlobal(d.type)
			THEN
				RecordUndefCall(g, d)
			ELSIF (g.opt.varInit = GenOptions.VarInitZero)
			OR (d.type.id = Ast.IdRecord)
			OR    (d.type.id = Ast.IdArray)
			    & ~IsArrayTypeSimpleUndef(d.type, arrTypeId, arrDeep)
			THEN
				Str(g, "memset(&");
				Name(g, d);
				Str(g, ", 0, sizeof(");
				Name(g, d);
				StrLn(g, "));")
			ELSE
				ASSERT(g.opt.varInit = GenOptions.VarInitUndefined);
				ArraySimpleUndef(g, arrTypeId, d, FALSE)
			END
		END;
		d := d.next
	END
END VarsInit;

PROCEDURE Declarations(VAR out: MOut; ds: Ast.Declarations);
VAR d, prev: Ast.Declaration; inModule: BOOLEAN;
BEGIN
	d := ds.start;
	inModule := ds.id = Ast.IdModule;
	ASSERT((d = NIL) OR (d.id # Ast.IdModule));
	WHILE (d # NIL) & (d.id = Ast.IdImport) DO
		IF ~d.module.m.spec THEN
			Include(out.g[ORD(~out.opt.main)], d.module.m.name)
		END;
		d := d.next
	END;
	LnIfWrote(out);

	WHILE (d # NIL) & (d.id = Ast.IdConst) DO
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

		WHILE (d # NIL) & (d.id = Ast.IdVar) DO
			Var(out, NIL, d, TRUE);
			d := d.next
		END
	ELSE
		d := ds.vars;

		prev := NIL;
		WHILE (d # NIL) & (d.id = Ast.IdVar) DO
			Var(out, prev, d, (d.next = NIL) OR (d.next.id # Ast.IdVar));
			prev := d;
			d := d.next
		END;
		IF out.opt.varInit # GenOptions.VarInitNo THEN
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

		GenOptions.Default(o^);

		o.std           := IsoC90;
		o.gnu           := FALSE;
		o.plan9         := FALSE;

		(* Особая генерация для режима 128-битных указателей в Эльбрус. В текущем виде
		   работает неправильно из-за того, что размер массива определяется по размеру
		   динамической памяти, частью которого он является *)
		o.e2k           := FALSE;

		o.procLocal     := FALSE;
		o.vla           := FALSE & (IsoC99 <= o.std);
		o.vlaMark       := TRUE;
		o.checkNil      := TRUE;
		o.skipUnusedTag := TRUE;
		o.escapeHighChars
		                := o.std < IsoC99;
		o.memManager    := MemManagerNoFree;

		o.expectArray := FALSE;
		o.castToBase  := FALSE;

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
		WHILE (c # NIL) & (c.id = Ast.IdConst) DO
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
		WHILE (p # NIL) & (p.id = Ast.IdProc) DO
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
	WHILE (imp # NIL) & (imp.id = Ast.IdImport) DO
		MarkUsedInMarked(imp.module.m);
		imp := imp.next
	END;
	Consts(m.consts);
	Types(m.types);
	Procs(m.procedures)
END MarkUsedInMarked;

PROCEDURE ImportInitDone(VAR g: Generator; imp: Ast.Declaration;
                         initDone: ARRAY OF CHAR);
BEGIN
	IF imp # NIL THEN
		ASSERT(imp.id = Ast.IdImport);

		REPEAT
			IF ~imp.module.m.spec THEN
				Name(g, imp.module.m);
				StrLn(g, initDone);
			END;
			imp := imp.next
		UNTIL (imp = NIL) OR ~(imp.id = Ast.IdImport);
		Ln(g)
	END
END ImportInitDone;

PROCEDURE ImportInit(VAR g: Generator; imp: Ast.Declaration);
BEGIN
	ImportInitDone(g, imp, "_init();")
END ImportInit;

PROCEDURE ImportDone(VAR g: Generator; imp: Ast.Declaration);
BEGIN
	ImportInitDone(g, imp, "_done();")
END ImportDone;

PROCEDURE TagsInit(VAR g: Generator);
VAR r: Ast.Record;
BEGIN
	r := NIL;
	WHILE g.opt.records # NIL DO
		r := g.opt.records;
		g.opt.records := r.ext(RecExt).next;
		r.ext(RecExt).next := NIL;

		IF (g.opt.memManager = MemManagerCounter)
		OR (r.base # NIL) & (r.needTag OR ~g.opt.skipUnusedTag)
		THEN
			Str(g, "O7_TAG_INIT(");
			GlobalName(g, r);
			IF r.base # NIL THEN
				Str(g, ", ");
				GlobalName(g, r.base);
				StrLn(g, ");")
			ELSE
				StrLn(g, ", o7_base);")
			END
		END
	END;
	IF r # NIL THEN
		Ln(g)
	END
END TagsInit;

PROCEDURE Generate*(interface, implementation: Stream.POut;
                    module: Ast.Module; cmd: Ast.Statement; opt: Options);
VAR out: MOut;

	PROCEDURE Init(VAR g: Generator; out: Stream.POut;
	               module: Ast.Module; opt: Options; interface: BOOLEAN);
	BEGIN
		Text.Init(g, out);
		g.module := module;
		g.localDeep := 0;

		g.opt := opt;

		g.fixedLen := g.len;

		g.interface := interface;

		g.insideSizeOf := FALSE;

		g.memout := NIL
	END Init;

	PROCEDURE InitModel(VAR g: Generator);
	BEGIN
		IF g.opt.varInit # GenOptions.VarInitUndefined THEN
			StrLn(g, "#if !defined(O7_INIT_MODEL)");
			IF g.opt.varInit = GenOptions.VarInitNo THEN
				StrLn(g, "#   define   O7_INIT_MODEL O7_INIT_NO")
			ELSE ASSERT(g.opt.varInit = GenOptions.VarInitZero);
				StrLn(g, "#   define   O7_INIT_MODEL O7_INIT_ZERO")
			END;
			StrLn(g, "#endif");
			Ln(g)
		END
	END InitModel;

	PROCEDURE UseE2kLen(VAR g: Generator);
	BEGIN
		IF g.opt.e2k THEN
			StrLn(g, "#define O7_USE_E2K_LEN 1");
			Ln(g)
		END
	END UseE2kLen;

	PROCEDURE Includes(VAR g: Generator);
	BEGIN
		IF g.opt.std >= IsoC99 THEN
			StrLn(g, "#include <stdbool.h>")
		END;
		StrLn(g, "#include <o7.h>");
		Ln(g)
	END Includes;

	PROCEDURE HeaderGuard(VAR g: Generator);
	BEGIN
		Str(g, "#if !defined HEADER_GUARD_");
		Text.String(g, g.module.name);
		Ln(g);
		Str(g, "#    define  HEADER_GUARD_");
		Text.String(g, g.module.name);
		StrLn(g, " 1");
		Ln(g)
	END HeaderGuard;

	PROCEDURE ModuleInit(VAR interf, impl: Generator; module: Ast.Module;
	                     cmd: Ast.Statement);
	BEGIN
		IF (module.import = NIL)
		 & (module.stats = NIL) & (cmd = NIL)
		 & (impl.opt.records = NIL)
		THEN
			IF impl.opt.std >= IsoC99 THEN
				Str(interf, "static inline void ")
			ELSE
				Str(interf, "O7_INLINE void ")
			END;
			Name(interf, module);
			StrLn(interf, "_init(void) { ; }")
		ELSE
			Str(interf, "extern void ");
			Name(interf, module);
			StrLn(interf, "_init(void);");

			Str(impl, "extern void ");
			Name(impl, module);
			StrOpen(impl, "_init(void) {");
			StrLn(impl, "static unsigned initialized = 0;");
			StrOpen(impl, "if (0 == initialized) {");
			ImportInit(impl, module.import);
			TagsInit(impl);
			Statements(impl, module.stats);
			Statements(impl, cmd);
			StrLnClose(impl, "}");
			StrLn(impl, "++initialized;");
			StrLnClose(impl, "}");
			Ln(impl)
		END
	END ModuleInit;

	PROCEDURE ModuleDone(VAR interf, impl: Generator; module: Ast.Module);
	BEGIN
		IF impl.opt.memManager # MemManagerCounter THEN
			;
		ELSIF (module.import = NIL) & (impl.opt.records = NIL) THEN
			IF impl.opt.std >= IsoC99 THEN
				Str(interf, "static inline void ")
			ELSE
				Str(interf, "O7_INLINE void ")
			END;
			Name(interf, module);
			StrLn(interf, "_done(void) { ; }")
		ELSE
			Str(interf, "extern void ");
			Name(interf, module);
			StrLn(interf, "_done(void);");

			Str(impl, "extern void ");
			Name(impl, module);
			StrOpen(impl, "_done(void) {");
			ReleaseVars(impl, module.vars);
			ImportDone(impl, module.import);
			StrLnClose(impl, "}");
			Ln(impl)
		END
	END ModuleDone;

	PROCEDURE Main(VAR g: Generator; module: Ast.Module; cmd: Ast.Statement);
	BEGIN
		StrOpen(g, "extern int main(int argc, char *argv[]) {");
		StrLn(g, "o7_init(argc, argv);");
		ImportInit(g, module.import);
		TagsInit(g);
		Statements(g, module.stats);
		Statements(g, cmd);
		IF g.opt.memManager = MemManagerCounter THEN
			ReleaseVars(g, module.vars);
			ImportDone(g, module.import)
		END;
		StrLn(g, "return o7_exit_code;");
		StrLnClose(g, "}")
	END Main;

	PROCEDURE GeneratorNotify(VAR g: Generator);
	BEGIN
		IF g.opt.generatorNote THEN
			StrLn(g, "/* Generated by Vostok - Oberon-07 translator */");
			Ln(g)
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

	InitModel(out.g[Implementation]);
	UseE2kLen(out.g[Implementation]);

	Includes(out.g[Implementation]);

	IF ~opt.main THEN
		HeaderGuard(out.g[Interface]);
		Include(out.g[Implementation], module.name)
	END;

	Declarations(out, module);

	IF opt.main THEN
		Main(out.g[Implementation], module, cmd)
	ELSE
		ModuleInit(out.g[Interface], out.g[Implementation], module, cmd);
		ModuleDone(out.g[Interface], out.g[Implementation], module);
		StrLn(out.g[Interface], "#endif")
	END
END Generate;

BEGIN
	type := Type;
	declarator := Declarator;
	declarations := Declarations;
	statements := Statements;
	expression := Expression;
	NEW(specNameMark[0]); V.Init(specNameMark[0]^);
	NEW(specNameMark[1]); V.Init(specNameMark[1]^)
END GeneratorC.

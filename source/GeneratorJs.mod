(*  Generator of JavaScript-code by Oberon-07 abstract syntax tree. Based on GeneratorJava
 *
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
MODULE GeneratorJs;

IMPORT
	V,
	Ast, AstTransform,
	Utf8, Hex,
	Strings := StringStore, Chars0X,
	SpecIdentChecker,
	SpecIdent  := OberonSpecIdent,
	Stream     := VDataStream,
	FileStream := VFileStream,
	Text       := TextGenerator,
	Limits     := TypesLimits,
	TranLim    := TranslatorLimits,
	GenOptions, GenCommon;

CONST
	Supported* = TRUE;

	EcmaScript5*    = 0;
	EcmaScript2015* = 1;

	ForSameType = 0;
	ForCall     = 1;
	ForAssign   = 2;

TYPE
	Options* = POINTER TO RECORD(GenOptions.R)
		std*: INTEGER;

		index: INTEGER;

		(* TODO для более сложных случаев *)
		expectArray: BOOLEAN
	END;

	Generator = RECORD(Text.Out)
		module: Ast.Module;

		localDeep: INTEGER;(* Вложенность процедур *)

		fixedLen: INTEGER;

		opt: Options;

		expressionSemicolon, forAssign: BOOLEAN
	END;

	Selectors = RECORD
		des: Ast.Designator;
		decl: Ast.Declaration;
		list: ARRAY TranLim.Selectors OF Ast.Selector;
		i: INTEGER
	END;

VAR
	type: PROCEDURE(VAR g: Generator; decl: Ast.Declaration; type: Ast.Type;
	                typeDecl, sameType: BOOLEAN);
	declarations: PROCEDURE(VAR g: Generator; ds: Ast.Declarations);
	statements: PROCEDURE(VAR g: Generator; stats: Ast.Statement);
	expression: PROCEDURE(VAR g: Generator; expr: Ast.Expression; set: SET);
	pvar: PROCEDURE (VAR g: Generator; prev, var: Ast.Declaration; last: BOOLEAN);

PROCEDURE Ident(VAR g: Generator; ident: Strings.String);
BEGIN
	GenCommon.Ident(g, ident, g.opt.identEnc)
END Ident;

PROCEDURE Name(VAR g: Generator; decl: Ast.Declaration);
BEGIN
	Ident(g, decl.name);
	IF SpecIdentChecker.IsSpecName(decl.name, {SpecIdentChecker.MathC}) THEN
		Text.Char(g, "_")
	END
END Name;

PROCEDURE IsSpecModuleName(name: Strings.String): BOOLEAN;
VAR c: CHAR;
BEGIN
	c := name.block.s[name.ofs];
	RETURN ("a" <= c) & (c <= "z")
	     & (   Strings.IsEqualToString(name, "module")
	        OR SpecIdentChecker.IsJsKeyWord(name)
	       )
END IsSpecModuleName;

PROCEDURE GlobalName(VAR g: Generator; decl: Ast.Declaration);
BEGIN
	IF (decl.module # NIL) & (g.module # decl.module.m)
	OR (decl.id = Ast.IdVar) & decl.mark
	THEN
		IF ~decl.mark & (decl IS Ast.Const) THEN
			(* TODO предварительно пометить экспортом *)
			expression(g, decl(Ast.Const).expr.value, {})
		ELSE
			IF (decl.id = Ast.IdVar) & (g.module = decl.module.m) THEN
				Text.Str(g, "module")
			ELSE
				Ident(g, decl.module.m.ext(Ast.Import).name)
			END;
			IF IsSpecModuleName(decl.module.m.name)
			 & ~decl.module.m.spec
			THEN
				Text.Str(g, "_.")
			ELSE
				Text.Char(g, ".")
			END;
			Name(g, decl)
		END
	ELSE
		Name(g, decl)
	END
END GlobalName;

PROCEDURE Factor(VAR g: Generator; expr: Ast.Expression; set: SET);
BEGIN
	IF expr IS Ast.Factor THEN
		expression(g, expr, set)
	ELSE
		Text.Str(g, "(");
		expression(g, expr, set);
		Text.Str(g, ")")
	END
END Factor;

PROCEDURE CheckStructName(VAR g: Generator; rec: Ast.Record): BOOLEAN;
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
		Ast.PutChars(rec.pointer.module.m, rec.name, anon, 0, l)
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

PROCEDURE GlobalNamePointer(VAR g: Generator; t: Ast.Type);
BEGIN
	ASSERT(t.id IN {Ast.IdPointer, Ast.IdRecord});

	IF (t.id = Ast.IdPointer) & Strings.IsDefined(t.type.name) THEN
		t := t.type
	END;
	GlobalName(g, t)
END GlobalNamePointer;

PROCEDURE ExpressionBraced(VAR g: Generator;
                           l: ARRAY OF CHAR; e: Ast.Expression; r: ARRAY OF CHAR;
                           set: SET);
BEGIN
	Text.Str(g, l);
	expression(g, e, set);
	Text.Str(g, r)
END ExpressionBraced;

PROCEDURE NeedCheckIndex(array: Ast.Array; index: Ast.Expression): BOOLEAN;
BEGIN
	RETURN (index.value = NIL)
		OR   (index.value(Ast.ExprInteger).int # 0)
		   & (array.count = NIL)
END NeedCheckIndex;

PROCEDURE Selector(VAR g: Generator; sels: Selectors; i: INTEGER;
                   VAR typ: Ast.Type; desType: Ast.Type; set: SET);
VAR sel: Ast.Selector;

	PROCEDURE Record(VAR g: Generator; VAR typ: Ast.Type; VAR sel: Ast.Selector);
	VAR var: Ast.Declaration;
	BEGIN
		var := sel(Ast.SelRecord).var;
		Text.Str(g, ".");
		Name(g, var);
		typ := var.type
	END Record;

	PROCEDURE Declarator(VAR g: Generator; decl: Ast.Declaration);
	BEGIN
		GlobalName(g, decl);
	END Declarator;

	PROCEDURE Array(VAR g: Generator; VAR typ: Ast.Type;
	                VAR sel: Ast.Selector; decl: Ast.Declaration;
	                forAssign: BOOLEAN);
	VAR i: INTEGER;

		PROCEDURE Index(VAR g: Generator; array: Ast.Array; index: Ast.Expression);
		BEGIN
			IF g.opt.checkIndex & NeedCheckIndex(array, index) THEN
				ExpressionBraced(g, ".at(", index, ")", {})
			ELSE
				ExpressionBraced(g, "[", index, "]", {})
			END
		END Index;
	BEGIN
		IF ~forAssign OR (sel.next # NIL) THEN
			Index(g, typ(Ast.Array), sel(Ast.SelArray).index);
			typ := typ.type;
			sel := sel.next;
			i := 1;
			WHILE (sel # NIL) & (sel IS Ast.SelArray) & (~forAssign OR (sel.next # NIL)) DO
				Index(g, typ(Ast.Array), sel(Ast.SelArray).index);
				INC(i);
				sel := sel.next;
				typ := typ.type
			END
		END
	END Array;
BEGIN
	IF i >= 0 THEN
		sel := sels.list[i]
	END;
	IF i < 0 THEN
		Declarator(g, sels.decl)
	ELSE
		DEC(i);
		IF sel IS Ast.SelRecord THEN
			Selector(g, sels, i, typ, desType, set);
			Record(g, typ, sel)
		ELSIF sel IS Ast.SelArray THEN
			Selector(g, sels, i, typ, desType, set);
			Array(g, typ, sel, sels.decl,
			      ForAssign IN set)
		ELSIF sel IS Ast.SelPointer THEN
			Selector(g, sels, i, typ, desType, set)
		ELSE ASSERT(sel IS Ast.SelGuard);
			Selector(g, sels, i, typ, desType, set)
			(*
			Text.Str(g, "((");
			GlobalNamePointer(g, sel.type);
			Text.Str(g, ")");
			IF i < 0 THEN
				Declarator(g, sels.decl)
			ELSE
				Selector(g, sels, i, typ, desType, set)
			END;
			Text.Str(g, ")");
			typ := sel(Ast.SelGuard).type
			*)
		END;
	END
END Selector;

PROCEDURE Designator(VAR g: Generator; des: Ast.Designator; set: SET);
VAR sels: Selectors;
    typ: Ast.Type;

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

	Selector(g, sels, sels.i, typ, des.type, set)
END Designator;

PROCEDURE IsMayNotInited(e: Ast.Expression): BOOLEAN;
VAR des: Ast.Designator; var: Ast.Var;
BEGIN
	var := NIL;
	IF e IS Ast.Designator THEN
		des := e(Ast.Designator);
		IF des.decl IS Ast.Var THEN
			var := des.decl(Ast.Var)
		ELSE
			des := NIL
		END
	ELSE
		des := NIL
	END
	RETURN (des # NIL)
	     & ((des.inited # {Ast.InitedValue}) OR (des.sel # NIL) OR var.checkInit)
END IsMayNotInited;

PROCEDURE CheckExpr(VAR g: Generator; e: Ast.Expression; set: SET);
BEGIN
	IF (g.opt.varInit = GenOptions.VarInitUndefined)
	 & (e.value = NIL)
	 & ~(e.type.id IN (Ast.Structures + Ast.Pointers))
	 & IsMayNotInited(e)
	THEN
		Text.Str(g, "o7.inited(");
		expression(g, e, set);
		Text.Str(g, ")")
	ELSE
		expression(g, e, set)
	END
END CheckExpr;

PROCEDURE AssignInitValueArray(VAR g: Generator; typ: Ast.Type);
VAR sizes: ARRAY TranLim.ArrayDimension OF Ast.Expression;
	i, l: INTEGER;
BEGIN
	l := -1;
	REPEAT
		INC(l);
		sizes[l] := typ(Ast.Array).count;
		typ := typ.type
	UNTIL typ.id # Ast.IdArray;

	Text.Str(g, " = o7.array(");
	expression(g, sizes[0], {});
	FOR i := 1 TO l DO
		Text.Str(g, ", ");
		expression(g, sizes[i], {})
	END;
	Text.Str(g, ")")
END AssignInitValueArray;

PROCEDURE AssignInitValue(VAR g: Generator; typ: Ast.Type);
	PROCEDURE Zero(VAR g: Generator; typ: Ast.Type);
		PROCEDURE Array(VAR g: Generator; typ: Ast.Type);
		BEGIN
			(* TODO *)
			AssignInitValueArray(g, typ)
		END Array;
	BEGIN
		CASE typ.id OF
		  Ast.IdInteger, Ast.IdLongInt, Ast.IdByte, Ast.IdReal, Ast.IdReal32,
		  Ast.IdSet, Ast.IdLongSet:
			Text.Str(g, " = 0")
		| Ast.IdBoolean:
			Text.Str(g, " = false")
		| Ast.IdChar:
			Text.Str(g, " = '\0'")
		| Ast.IdPointer, Ast.IdProcType, Ast.IdFuncType:
			Text.Str(g, " = null")
		| Ast.IdArray:
			Array(g, typ)
		| Ast.IdRecord:
			Text.Str(g, " = new ");
			type(g, NIL, typ, FALSE, FALSE);
			Text.Str(g, "()")
		END
	END Zero;

	PROCEDURE Undef(VAR g: Generator; typ: Ast.Type);
	BEGIN
		IF typ.id IN Ast.Numbers THEN
			Text.Str(g, " = NaN")
		ELSIF typ.id = Ast.IdArray THEN
			AssignInitValueArray(g, typ)
		ELSIF typ.id = Ast.IdRecord THEN
			Text.Str(g, " = new ");
			type(g, NIL, typ, FALSE, FALSE);
			Text.Str(g, "()")
		ELSE
			(*TODO*)
			Text.Str(g, " = undefined")
		END
	END Undef;
BEGIN
	CASE g.opt.varInit OF
	  GenOptions.VarInitUndefined:
		Undef(g, typ)
	| GenOptions.VarInitZero:
		Zero(g, typ)
	| GenOptions.VarInitNo:
		;
	END
END AssignInitValue;

PROCEDURE VarInit(VAR g: Generator; var: Ast.Declaration; record: BOOLEAN);
BEGIN
	IF ~record & ~(var.type.id IN {Ast.IdArray, Ast.IdRecord})
	 & ~var(Ast.Var).checkInit
	 & Ast.IsGlobal(var)
	THEN
		IF var.type.id = Ast.IdPointer THEN
			Text.Str(g, " = null")
		END
	ELSE
		AssignInitValue(g, var.type)
	END
END VarInit;

PROCEDURE FindLastSel(d: Ast.Designator; VAR t: Ast.Type): Ast.Selector;
VAR s: Ast.Selector;
BEGIN
	s := d.sel;
	IF s # NIL THEN
		t := d.decl.type;
		WHILE s.next # NIL DO
			t := s.type;
			s := s.next;
			IF s IS Ast.SelArray THEN
				ASSERT(t.id = Ast.IdArray)
			END
		END
	END
	RETURN s
END FindLastSel;

PROCEDURE Expression(VAR g: Generator; expr: Ast.Expression; set: SET);

	PROCEDURE Call(VAR g: Generator; call: Ast.ExprCall; set: SET);
	VAR p: Ast.Parameter;
		fp: Ast.Declaration;

		PROCEDURE Predefined(VAR g: Generator; call: Ast.ExprCall);
		VAR e1: Ast.Expression;
			p2: Ast.Parameter;

			PROCEDURE Shift(VAR g: Generator; shift: ARRAY OF CHAR;
			                e1, e2: Ast.Expression);
			BEGIN
				Text.Str(g, "(");
				Factor(g, e1, {});
				Text.Str(g, shift);
				Factor(g, e2, {});
				Text.Str(g, ")")
			END Shift;

			PROCEDURE Len(VAR g: Generator; e: Ast.Expression);
			VAR sel: Ast.Selector;
				des: Ast.Designator;
				count: Ast.Expression;
			BEGIN
				count := e.type(Ast.Array).count;
				IF count # NIL THEN
					Expression(g, count, {})
				ELSE
					des := e(Ast.Designator);
					GlobalName(g, des.decl);
					sel := des.sel;
					WHILE sel # NIL DO
						Text.Str(g, "[0]");
						sel := sel.next
					END;
					Text.Str(g, ".length")
				END
			END Len;

			PROCEDURE New(VAR g: Generator; e: Ast.Expression);
			VAR lastSel: Ast.Selector; t: Ast.Type;
			BEGIN
				Designator(g, e(Ast.Designator), {ForSameType, ForAssign});
				lastSel := FindLastSel(e(Ast.Designator), t);
				IF (lastSel # NIL) & (lastSel IS Ast.SelArray)
				 & g.opt.checkIndex & NeedCheckIndex(t(Ast.Array), lastSel(Ast.SelArray).index)
				THEN
					Text.Str(g, ".put(");
					expression(g, lastSel(Ast.SelArray).index, {});
					Text.Str(g, ", new ");
					GlobalNamePointer(g, e.type);
					Text.Str(g, "())")
				ELSE
					IF (lastSel # NIL) & (lastSel IS Ast.SelArray) THEN
						ExpressionBraced(g, "[", lastSel(Ast.SelArray).index, "]", {})
					END;
					Text.Str(g, " = new ");
					GlobalNamePointer(g, e.type);
					Text.Str(g, "()")
				END;
			END New;

			PROCEDURE Ord(VAR g: Generator; e: Ast.Expression);
			BEGIN
				CASE e.type.id OF
				  Ast.IdChar, Ast.IdArray:
					g.opt.expectArray := FALSE;
					Expression(g, e, {});
					(*
					ExpressionBraced(g, "o7.cti(", e, ")", {});
					*)
				| Ast.IdBoolean:
					ExpressionBraced(g, "o7.bti(", e, ")", {});
				| Ast.IdSet, Ast.IdLongSet:
					ExpressionBraced(g, "o7.sti(", e, ")", {})
				END
			END Ord;

			PROCEDURE Inc(VAR g: Generator;
			              e1: Ast.Designator; p2: Ast.Parameter;
			              mul: INTEGER);
			VAR sel: Ast.Selector; t: Ast.Type;
			BEGIN
				ASSERT((mul = -1) OR (mul = 1));

				Designator(g, e1, {ForSameType, ForAssign});
				sel := FindLastSel(e1, t);
				IF g.opt.checkIndex & (sel # NIL) & (sel IS Ast.SelArray) THEN
					ExpressionBraced(g, ".inc(", sel(Ast.SelArray).index, ", ", {});
					IF p2 = NIL THEN
						IF mul = -1 THEN
							Text.Str(g, "-1)")
						ELSE
							Text.Str(g, "1)")
						END
					ELSIF mul = -1 THEN
						ExpressionBraced(g, "-(", p2.expr, "))", {})
					ELSE
						ExpressionBraced(g, "", p2.expr, ")", {})
					END
				ELSE
					IF ~g.opt.checkIndex & (sel # NIL) & (sel IS Ast.SelArray) THEN
						ExpressionBraced(g, "[", sel(Ast.SelArray).index, "]", {})
					END;
					IF g.opt.checkArith THEN
						IF mul = 1 THEN
							Text.Str(g, " = o7.add(")
						ELSE
							Text.Str(g, " = o7.sub(")
						END;
						Designator(g, e1, {});
						IF p2 = NIL THEN
							Text.Str(g, ", 1)")
						ELSE
							ExpressionBraced(g, ", ", p2.expr, ")", {})
						END
					ELSIF p2 # NIL THEN
						IF mul = 1 THEN
							Text.Str(g, " += ")
						ELSE
							Text.Str(g, " -= ")
						END;
						Expression(g, p2.expr, {})
					ELSIF mul = 1 THEN
						Text.Str(g, "++")
					ELSE
						Text.Str(g, "--")
					END
				END
			END Inc;

			PROCEDURE Incl(VAR g: Generator; e1, e2: Ast.Expression);
			VAR sel: Ast.Selector; t: Ast.Type;
			BEGIN
				Expression(g, e1, {ForSameType, ForAssign});

				sel := FindLastSel(e1(Ast.Designator), t);
				IF g.opt.checkIndex & (sel # NIL) & (sel IS Ast.SelArray) THEN
					ExpressionBraced(g, ".incl(", sel(Ast.SelArray).index, ", ", {});
					Expression(g, e2, {});
					Text.Char(g, ")")
				ELSE
					IF ~g.opt.checkIndex & (sel # NIL) & (sel IS Ast.SelArray) THEN
						ExpressionBraced(g, "[", sel(Ast.SelArray).index, "]", {});
					END;
					IF g.opt.checkArith THEN
						ExpressionBraced(g, " |= o7.incl(", e2, ")", {})
					ELSE
						Text.Str(g, " |= 1 << ");
						Factor(g, e2, {})
					END
				END
			END Incl;

			PROCEDURE Excl(VAR g: Generator; e1, e2: Ast.Expression);
			VAR sel: Ast.Selector; t: Ast.Type;
			BEGIN
				Expression(g, e1, {ForSameType, ForAssign});

				sel := FindLastSel(e1(Ast.Designator), t);
				IF g.opt.checkIndex & (sel # NIL) & (sel IS Ast.SelArray) THEN
					ExpressionBraced(g, ".excl(", sel(Ast.SelArray).index, ", ", {});
					Expression(g, e2, {});
					Text.Char(g, ")")
				ELSE
					IF ~g.opt.checkIndex & (sel # NIL) & (sel IS Ast.SelArray) THEN
						ExpressionBraced(g, "[", sel(Ast.SelArray).index, "]", {});
					END;

					IF g.opt.checkArith THEN
						ExpressionBraced(g, " &= o7.excl(", e2, ")", {})
					ELSE
						Text.Str(g, " &= ~(1 << ");
						Factor(g, e2, {});
						Text.Str(g, ")")
					END
				END
			END Excl;

			PROCEDURE Assert(VAR g: Generator; e: Ast.Expression);
			BEGIN
				IF g.opt.o7Assert THEN
					Text.Str(g, "o7.assert(");
				ELSE
					Text.Str(g, "o7_assert(");
				END;
				CheckExpr(g, e, {});
				Text.Str(g, ")")
			END Assert;

			PROCEDURE Pack(VAR g: Generator; e1: Ast.Designator; e2: Ast.Expression);
			VAR sel: Ast.Selector; arr: BOOLEAN; t: Ast.Type;
			BEGIN
				sel := FindLastSel(e1, t);
				arr := (sel # NIL) & (sel IS Ast.SelArray);
				IF arr THEN
					Text.Str(g, "var _d = ");
					Designator(g, e1, {ForSameType, ForAssign});
					IF g.opt.checkIndex THEN
						ExpressionBraced(g, ", _i = ", sel(Ast.SelArray).index,
						                 "; _d[_i] = o7.scalb(_d.at(_i), ", {})
					ELSE
						ExpressionBraced(g, ", _i = ", sel(Ast.SelArray).index,
						                 "; _d[_i] = o7.scalb(_d[_i], ", {})
					END
				ELSE
					Designator(g, e1, {ForSameType, ForAssign});
					ExpressionBraced(g, " = o7.scalb(", e1, ", ", {})
				END;
				Expression(g, e2, {});
				Text.Char(g, ")")
			END Pack;

			PROCEDURE Unpack(VAR g: Generator; e1, e2: Ast.Designator);
			VAR index: Ast.Expression; sel: Ast.Selector; arr: BOOLEAN; t: Ast.Type;
			BEGIN
				sel := FindLastSel(e1, t);
				arr := (sel # NIL) & (sel IS Ast.SelArray);
				IF arr THEN
					(* TODO *)
					Text.Str(g, "var _d = ");
					Designator(g, e1, {ForSameType, ForAssign});
					IF g.opt.checkIndex THEN
						ExpressionBraced(g, ", _i = ", sel(Ast.SelArray).index,
					                     "; _d[_i] = o7.frexp(_d.at(_i), ", {})
					ELSE
						ExpressionBraced(g, ", _i = ", sel(Ast.SelArray).index,
					                     "; _d[_i] = o7.frexp(_d[_i], ", {})
					END
				ELSE
					Designator(g, e1, {ForSameType, ForAssign});
					ExpressionBraced(g, " = o7.frexp(", e1, ", ", {})
				END;
				index := AstTransform.CutIndex(AstTransform.OutParamToArrayAndIndex, e2);
				Expression(g, e2, {ForSameType});
				ExpressionBraced(g, ", ", index, ")", {})
			END Unpack;
		BEGIN
			e1 := call.params.expr;
			p2 := call.params.next;
			CASE call.designator.decl.id OF
			  SpecIdent.Abs:
				ExpressionBraced(g, "Math.abs(", e1, ")", {})
			| SpecIdent.Odd:
				Text.Char(g, "(");
				Factor(g, e1, {});
				Text.Str(g, " % 2 != 0)")
			| SpecIdent.Len:
				Len(g, e1)
			| SpecIdent.Lsl:
				Shift(g, " << ", e1, p2.expr)
			| SpecIdent.Asr:
				Shift(g, " >> ", e1, p2.expr)
			| SpecIdent.Ror:
				ExpressionBraced(g, "o7.ror(", e1, ", ", {});
				Expression(g, p2.expr, {});
				Text.Char(g, ")")
			| SpecIdent.Floor:
				ExpressionBraced(g, "o7.floor(", e1, ")", {})
			| SpecIdent.Flt:
				ExpressionBraced(g, "o7.flt(", e1, ")", {})
			| SpecIdent.Ord:
				Ord(g, e1)
			| SpecIdent.Chr:
				ExpressionBraced(g, "o7.itc(", e1, ")", {})
			| SpecIdent.Inc:
				Inc(g, e1(Ast.Designator), p2, +1)
			| SpecIdent.Dec:
				Inc(g, e1(Ast.Designator), p2, -1)
			| SpecIdent.Incl:
				Incl(g, e1, p2.expr)
			| SpecIdent.Excl:
				Excl(g, e1, p2.expr)
			| SpecIdent.New:
				New(g, e1)
			| SpecIdent.Assert:
				Assert(g, e1)
			| SpecIdent.Pack:
				Pack(g, e1(Ast.Designator), p2.expr)
			| SpecIdent.Unpk:
				Unpack(g, e1(Ast.Designator), p2.expr(Ast.Designator))
			END
		END Predefined;

		PROCEDURE ActualParam(VAR g: Generator; VAR p: Ast.Parameter;
		                      VAR fp: Ast.Declaration);
		VAR t: Ast.Type;
		BEGIN
			t := fp.type;
			IF (t.id = Ast.IdByte) & (p.expr.type.id IN {Ast.IdInteger, Ast.IdLongInt})
			THEN
				ExpressionBraced(g, "o7.itb(", p.expr, ")", {ForSameType})
			ELSIF (p.expr.type.id = Ast.IdByte) & (t.id = Ast.IdByte) THEN
				Designator(g, p.expr(Ast.Designator), {ForSameType})
			ELSE
				IF fp.type.id # Ast.IdChar THEN
					t := fp.type
				END;
				g.opt.expectArray := fp.type.id = Ast.IdArray;
				IF ~g.opt.expectArray & (p.expr IS Ast.Designator) THEN
					Designator(g, p.expr(Ast.Designator), {})
				ELSE
					Expression(g, p.expr, {})
				END;
				g.opt.expectArray := FALSE;

				t := p.expr.type
			END;

			p := p.next;
			fp := fp.next
		END ActualParam;
	BEGIN
		IF call.designator.decl IS Ast.PredefinedProcedure THEN
			Predefined(g, call)
		ELSE
			Designator(g, call.designator, {ForCall});
			Text.Str(g, "(");
			p  := call.params;
			fp := call.designator.type(Ast.ProcType).params;
			IF p # NIL THEN
				ActualParam(g, p, fp);
				WHILE p # NIL DO
					Text.Str(g, ", ");
					ActualParam(g, p, fp)
				END
			END;
			Text.Str(g, ")")
		END
	END Call;

	PROCEDURE Relation(VAR g: Generator; rel: Ast.ExprRelation);

		PROCEDURE Simple(VAR g: Generator; rel: Ast.ExprRelation;
		                 str: ARRAY OF CHAR);
		VAR notChar0, notChar1: BOOLEAN;

			PROCEDURE Expr(VAR g: Generator; e: Ast.Expression);
			BEGIN
				IF (e.type.id IN (Ast.Sets + {Ast.IdBoolean}))
				 & ~(e IS Ast.Factor)
				THEN
					ExpressionBraced(g, "(", e, ")", {})
				ELSE
					Expression(g, e, {})
				END
			END Expr;

			PROCEDURE IsArrayAndNotChar(e: Ast.Expression): BOOLEAN;
				RETURN (e.type.id = Ast.IdArray)
				     & ((e.value = NIL) OR ~e.value(Ast.ExprString).asChar)
			END IsArrayAndNotChar;
		BEGIN
			notChar0 := IsArrayAndNotChar(rel.exprs[0]);
			IF notChar0 OR IsArrayAndNotChar(rel.exprs[1]) THEN
				IF rel.value # NIL THEN
					Expression(g, rel.value, {})
				ELSE
					notChar1 := ~notChar0 OR IsArrayAndNotChar(rel.exprs[1]);
					IF notChar0 = notChar1 THEN
						ASSERT(notChar0);
						Text.Str(g, "o7.strcmp(")
					ELSIF notChar1 THEN
						Text.Str(g, "o7.chstrcmp(")
					ELSE ASSERT(notChar0);
						Text.Str(g, "o7.strchcmp(")
					END;
					Expr(g, rel.exprs[0]);
					Text.Str(g, ", ");
					Expr(g, rel.exprs[1]);
					Text.Str(g, ")");
					Text.Str(g, str);
					Text.Str(g, "0")
				END
			ELSIF (g.opt.varInit = GenOptions.VarInitUndefined)
			    & (rel.value = NIL)
			    & (rel.exprs[0].type.id IN {Ast.IdInteger, Ast.IdLongInt}) (* TODO *)
			    & (IsMayNotInited(rel.exprs[0]) OR IsMayNotInited(rel.exprs[1]))
			THEN
				Text.Str(g, "o7.cmp(");
				Expr(g, rel.exprs[0]);
				Text.Str(g, ", ");
				Expr(g, rel.exprs[1]);
				Text.Str(g, ")");
				Text.Str(g, str);
				Text.Str(g, "0")
			ELSIF (   (rel.exprs[0].type.id = Ast.IdChar)
			       OR (rel.exprs[1].type.id = Ast.IdChar))
			    & (rel.relation # Ast.Equal)
			THEN
				Text.Str(g, "(0xFF & ");
				Expr(g, rel.exprs[0]);
				Text.Str(g, ")");
				Text.Str(g, str);
				Text.Str(g, "(0xFF & ");
				Expr(g, rel.exprs[1]);
				Text.Str(g, ")")
			ELSE
				Expr(g, rel.exprs[0]);
				Text.Str(g, str);
				Expr(g, rel.exprs[1])
			END
		END Simple;

		PROCEDURE In(VAR g: Generator; rel: Ast.ExprRelation);
		BEGIN
			IF (rel.exprs[0].value # NIL)
			 & (rel.exprs[0].value(Ast.ExprInteger).int IN {0 .. Limits.SetMax})
			THEN
				Text.Str(g, "0 != (");
				Text.Str(g, " (1 << ");
				Factor(g, rel.exprs[0], {});
				Text.Str(g, ") & ");
				Factor(g, rel.exprs[1], {});
				Text.Str(g, ")")
			ELSE
				Text.Str(g, "o7.in(");
				Expression(g, rel.exprs[0], {ForSameType});
				ExpressionBraced(g, ", ", rel.exprs[1], ")", {})
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
	VAR first: BOOLEAN;
	BEGIN
		first := TRUE;
		REPEAT
			IF sum.add = Ast.Minus THEN
				IF ~(sum.type.id IN Ast.Sets) THEN
					Text.Str(g, " - ")
				ELSIF first THEN
					Text.Str(g, " ~")
				ELSE
					Text.Str(g, " & ~")
				END
			ELSIF sum.add = Ast.Plus THEN
				IF sum.type.id IN Ast.Sets THEN
					Text.Str(g, " | ")
				ELSE
					Text.Str(g, " + ")
				END
			ELSIF sum.add = Ast.Or THEN
				Text.Str(g, " || ")
			END;
			CheckExpr(g, sum.term, {});
			sum := sum.next;
			first := FALSE
		UNTIL sum = NIL
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
				  Ast.Minus: Text.Str(g, sub)
				| Ast.Plus : Text.Str(g, add)
				END;
				DEC(i)
			END;
			IF arr[0].add = Ast.Minus THEN
				Text.Str(g, sub);
				ExpressionBraced(g, "0, ", arr[0].term, ")", {})
			ELSE
				Expression(g, arr[0].term, {})
			END
		END GenArrOfAddOrSub;
	BEGIN
		last := -1;
		REPEAT
			INC(last);
			arr[last] := sum;
			sum := sum.next
		UNTIL sum = NIL;
		IF arr[0].type.id IN Ast.Reals THEN
			GenArrOfAddOrSub(g, arr, last, "o7.fadd(", "o7.fsub(")
		ELSE
			GenArrOfAddOrSub(g, arr, last, "o7.add(" , "o7.sub(")
		END;
		i := 0;
		WHILE i < last DO
			INC(i);
			ExpressionBraced(g, ", ", arr[i].term, ")", {})
		END
	END SumCheck;

	PROCEDURE Term(VAR g: Generator; term: Ast.ExprTerm);
	VAR toInt: BOOLEAN;
	BEGIN
		REPEAT
			toInt := FALSE;
			CheckExpr(g, term.factor, {});
			CASE term.mult OF
			  Ast.Mult:
				IF term.type.id IN Ast.Sets THEN
					Text.Str(g, " & ")
				ELSE
					Text.Str(g, " * ")
				END
			| Ast.Rdiv, Ast.Div:
				IF term.type.id IN Ast.Sets THEN
					ASSERT(term.mult = Ast.Rdiv);
					Text.Str(g, " ^ ")
				ELSE
					Text.Str(g, " / ");
					toInt := term.mult = Ast.Div
				END
			| Ast.And: Text.Str(g, " && ")
			| Ast.Mod: Text.Str(g, " % ")
			END;
			IF term.expr IS Ast.ExprTerm THEN
				term := term.expr(Ast.ExprTerm)
			ELSE
				CheckExpr(g, term.expr, {});
				term := NIL
			END;
			IF toInt THEN
				Text.Str(g, " | 0")
			END
		UNTIL term = NIL
	END Term;

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
		IF arr[i].type.id IN Ast.Integers THEN
			WHILE i >= 0 DO
				CASE arr[i].mult OF
				  Ast.Mult : Text.Str(g, "o7.mul(")
				| Ast.Div  : Text.Str(g, "o7.div(")
				| Ast.Mod  : Text.Str(g, "o7.mod(")
				END;
				DEC(i)
			END
		ELSE
			WHILE i >= 0 DO
				CASE arr[i].mult OF
				  Ast.Mult : Text.Str(g, "o7.fmul(")
				| Ast.Rdiv : Text.Str(g, "o7.fdiv(")
				END;
				DEC(i)
			END
		END;
		Expression(g, arr[0].factor, {});
		i := 0;
		WHILE i < last DO
			INC(i);
			ExpressionBraced(g, ", ", arr[i].factor, ")", {})
		END;
		ExpressionBraced(g, ", ", arr[last].expr, ")", {})
	END TermCheck;

	PROCEDURE Boolean(VAR g: Generator; e: Ast.ExprBoolean);
	BEGIN
		IF e.bool
		THEN Text.Str(g, "true")
		ELSE Text.Str(g, "false")
		END
	END Boolean;

	PROCEDURE CString(VAR g: Generator; e: Ast.ExprString);
	VAR s: ARRAY 8 OF CHAR; ch: CHAR; w: Strings.String; len: INTEGER;
	BEGIN
		w := e.string;
		IF e.asChar & ~g.opt.expectArray THEN
			ch := CHR(e.int);
			Text.Str(g, "0x");
			Text.Char(g, Hex.To(e.int DIV 16));
			Text.Char(g, Hex.To(e.int MOD 16))
		ELSE
			Text.Str(g, "o7.toUtf8(");
			IF (w.ofs >= 0) & (w.block.s[w.ofs] = Utf8.DQuote) THEN
				Text.ScreeningString(g, w, FALSE)
			ELSE
				s[0] := Utf8.DQuote;
				s[1] := "\";
				len := 4;
				IF e.int = ORD("\") THEN
					s[2] := "\"
				ELSIF e.int = 0AH THEN
					s[2] := "n"
				ELSIF e.int = ORD(Utf8.DQuote) THEN
					s[2] := Utf8.DQuote
				ELSE
					s[2] := "u";
					s[3] := "0";
					s[4] := "0";
					s[5] := Hex.To(e.int DIV 16);
					s[6] := Hex.To(e.int MOD 16);
					len := 8
				END;
				s[len - 1] := Utf8.DQuote;
				Text.Data(g, s, 0, len)
			END;
			Text.Str(g, ")")
		END
	END CString;

	PROCEDURE ExprInt(VAR g: Generator; int: INTEGER);
	BEGIN
		IF int >= 0 THEN
			Text.Int(g, int)
		ELSE
			Text.Str(g, "(-");
			Text.Int(g, -int);
			Text.Str(g, ")")
		END
	END ExprInt;

	PROCEDURE ExprLongInt(VAR g: Generator; int: INTEGER);
	BEGIN
		ASSERT(FALSE);
		IF int >= 0 THEN
			Text.Int(g, int)
		ELSE
			Text.Str(g, "(-");
			Text.Int(g, -int);
			Text.Str(g, ")")
		END
	END ExprLongInt;

	PROCEDURE SetValue(VAR g: Generator; set: Ast.ExprSetValue);
	BEGIN
		Text.Int(g, ORD(set.set[0]));
		Text.Char(g, "u")
	END SetValue;

	PROCEDURE Set(VAR g: Generator; set: Ast.ExprSet);
		PROCEDURE Item(VAR g: Generator; set: Ast.ExprSet);
		BEGIN
			IF set.exprs[0] = NIL THEN
				Text.Str(g, "0")
			ELSE
				IF set.exprs[1] = NIL THEN
					Text.Str(g, "(1 << ");
					Factor(g, set.exprs[0], {})
				ELSE
					ExpressionBraced(g, "o7.set(", set.exprs[0], ", ", {});
					Expression(g, set.exprs[1], {})
				END;
				Text.Str(g, ")")
			END
		END Item;
	BEGIN
		IF set.next = NIL THEN
			Item(g, set)
		ELSE
			Text.Str(g, "(");
			Item(g, set);
			REPEAT
				Text.Str(g, " | ");
				set := set.next;
				Item(g, set)
			UNTIL set.next = NIL;
			Text.Str(g, ")")
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
			Expression(g, is.designator, {});
		ELSE
			GlobalName(g, decl);
		END;
		Text.Str(g, " instanceof ");
		GlobalName(g, extType);
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
		Call(g, expr(Ast.ExprCall), {})
	| Ast.IdDesignator:
		IF (expr.value # NIL) & (expr.value.id = Ast.IdString)
		THEN	CString(g, expr.value(Ast.ExprString))
		ELSE	Designator(g, expr(Ast.Designator), set)
		END
	| Ast.IdRelation:
		Relation(g, expr(Ast.ExprRelation))
	| Ast.IdSum:
		IF	  g.opt.checkArith
			& (expr.type.id IN {Ast.IdInteger, Ast.IdLongInt, Ast.IdReal, Ast.IdReal32})
			& (expr.value = NIL)
		THEN	SumCheck(g, expr(Ast.ExprSum))
		ELSE	Sum(g, expr(Ast.ExprSum))
		END
	| Ast.IdTerm:
		IF	  (g.opt.checkArith OR (expr.type.id IN {Ast.IdInteger, Ast.IdLongInt}))
			& (expr.type.id IN {Ast.IdInteger, Ast.IdLongInt, Ast.IdReal, Ast.IdReal32})
			& ((expr.value = NIL) OR TRUE (*TODO*))
		THEN	TermCheck(g, expr(Ast.ExprTerm))
		ELSIF (expr.value # NIL)
		    & (Ast.ExprIntNegativeDividentTouch IN expr.properties)
		THEN	Expression(g, expr.value, {})
		ELSE	Term(g, expr(Ast.ExprTerm))
		END
	| Ast.IdNegate:
		IF expr.type.id IN Ast.Sets THEN
			Text.Str(g, "~");
			Expression(g, expr(Ast.ExprNegate).expr, {})
		ELSE
			Text.Str(g, "!");
			CheckExpr(g, expr(Ast.ExprNegate).expr, {})
		END
	| Ast.IdBraces:
		ExpressionBraced(g, "(", expr(Ast.ExprBraces).expr, ")", set)
	| Ast.IdPointer:
		Text.Str(g, "null")
	| Ast.IdIsExtension:
		IsExtension(g, expr(Ast.ExprIsExtension))
	END
END Expression;

PROCEDURE ProcParams(VAR g: Generator; proc: Ast.ProcType);
VAR p: Ast.Declaration;
BEGIN
	IF proc.params = NIL THEN
		Text.Str(g, "()")
	ELSE
		Text.Str(g, "(");
		p := proc.params;
		WHILE p # proc.end DO
			Name(g, p);
			Text.Str(g, ", ");
			p := p.next
		END;
		Name(g, p(Ast.FormalParam));
		Text.Str(g, ")")
	END
END ProcParams;

PROCEDURE Declarator(VAR g: Generator; decl: Ast.Declaration;
                     typeDecl, sameType, global: BOOLEAN);
BEGIN
	ASSERT(~(decl IS Ast.Procedure));

	IF decl IS Ast.Type THEN
		type(g, decl, decl(Ast.Type), typeDecl, FALSE)
	ELSE
		type(g, decl, decl.type, FALSE, sameType)
	END;

	IF typeDecl THEN
		;
	ELSIF global THEN
		GlobalName(g, decl)
	ELSE
		Name(g, decl)
	END
END Declarator;
(* TODO Применить для массивов рода Int32Array
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
		Text.Str(g, "O7.INTS_UNDEF(")
	| Ast.IdLongInt:
		Text.Str(g, "O7.LONGS_UNDEF(")
	| Ast.IdReal:
		Text.Str(g, "O7.DOUBLES_UNDEF(")
	| Ast.IdReal32:
		Text.Str(g, "O7.FLOATS_UNDEF(")
	| Ast.IdBoolean:
		Text.Str(g, "O7.BOOLS_UNDEF(")
	END;
	IF inRec THEN
		Text.Str(g, "r.")
	END;
	Name(g, d);
	Text.Str(g, ");")
END ArraySimpleUndef;
*)

PROCEDURE RecordAssign(VAR g: Generator; rec: Ast.Record);
VAR var: Ast.Declaration;

	PROCEDURE RecordAssignHeader(VAR g: Generator; rec: Ast.Record);
	BEGIN
		Name(g, rec);
		Text.StrOpen(g, ".prototype.assign = function(r) {");
	END RecordAssignHeader;

	PROCEDURE IsNeedBase(rec: Ast.Record): BOOLEAN;
	BEGIN
		REPEAT
			rec := rec.base
		UNTIL (rec = NIL) OR (rec.vars # NIL)
		RETURN rec # NIL
	END IsNeedBase;
BEGIN
	RecordAssignHeader(g, rec);
	IF IsNeedBase(rec) THEN
		GlobalName(g, rec.base);
		Text.StrLn(g, ".prototype.assign.call(this, r);")
	END;
	var := rec.vars;
	WHILE var # NIL DO
		IF var.type.id = Ast.IdArray THEN
			(* TODO вложенные циклы *)
			Text.Str(g, "for (var i = 0; i < r.");
			Name(g, var);
			Text.StrOpen(g, ".length; i += 1) {");
			Text.Str(g, "this.");
			Name(g, var);
			IF var.type.type.id # Ast.IdRecord THEN
				Text.Str(g, "[i] = r.");
				Name(g, var);
				Text.StrLn(g, "[i];");
			ELSE
				Text.Str(g, "[i].assign(r.");
				Name(g, var);
				Text.StrLn(g, "[i]);")
			END;
			Text.StrLnClose(g, "}")
		ELSE
			Text.Str(g, "this.");
			Name(g, var);
			IF var.type.id = Ast.IdRecord THEN
				Text.Str(g, ".assign(r.");
				Name(g, var);
				Text.StrLn(g, ");")
			ELSE
				Text.Str(g, " = r.");
				Name(g, var);
				Text.StrLn(g, ";")
			END
		END;
		var := var.next
	END;
	Text.StrLnClose(g, "}")
END RecordAssign;

PROCEDURE EmptyLines(VAR g: Generator; d: Ast.Declaration);
BEGIN
	IF 0 < d.emptyLines THEN
		Text.Ln(g)
	END
END EmptyLines;

PROCEDURE GenInit(VAR g: Generator; out: Stream.POut;
                  module: Ast.Module;
                  opt: Options);
BEGIN
	Text.Init(g, out);
	g.module := module;
	g.localDeep := 0;

	g.opt := opt;

	g.fixedLen := g.len
END GenInit;

PROCEDURE GeneratorNotify(VAR g: Generator);
BEGIN
	IF g.opt.generatorNote THEN
		Text.StrLn(g, "/* Generated by Vostok - Oberon-07 translator */");
		Text.Ln(g)
	END
END GeneratorNotify;

PROCEDURE AllocArrayOfRecord(VAR g: Generator; v: Ast.Declaration;
                             inRecord: BOOLEAN);
VAR
BEGIN
	(* TODO многомерные массивы *)
	ASSERT(v.type.type.id = Ast.IdRecord);

	IF inRecord THEN
		Text.Str(g, "for (var i_ = 0; i_ < this.")
	ELSE
		Text.Str(g, "for (var i_ = 0; i_ < ")
	END;
	Name(g, v);
	Text.StrOpen(g, ".length; i_++) {");
	IF inRecord THEN
		Text.Str(g, "this.")
	END;
	Name(g, v);
	Text.Str(g, "[i_] = new ");
	type(g, NIL, v.type.type, FALSE, FALSE);
	Text.StrLn(g, "();");
	Text.StrLnClose(g, "}")
END AllocArrayOfRecord;

PROCEDURE SearchArrayOfRecord(v: Ast.Declaration): Ast.Declaration;
VAR subt: Ast.Type;
BEGIN
	WHILE (v # NIL) & (v.id = Ast.IdVar)
	    & (   (v.type.id # Ast.IdArray)
	       OR (Ast.ArrayGetSubtype(v.type(Ast.Array), subt) > 0)
	        & (subt.id = Ast.IdRecord)
	      )
	DO
		v := v.next
	END;
	IF (v # NIL) & (v.id # Ast.IdVar) THEN
		v := NIL
	END
	RETURN v
END SearchArrayOfRecord;

PROCEDURE InitAllVarsWichArrayOfRecord(VAR g: Generator; v: Ast.Declaration;
                                       inRecord: BOOLEAN);
VAR subt: Ast.Type;
BEGIN
	WHILE (v # NIL) & (v.id = Ast.IdVar) DO
		IF (v.type.id = Ast.IdArray)
		 & (Ast.ArrayGetSubtype(v.type(Ast.Array), subt) > 0)
		 & (subt.id = Ast.IdRecord)
		THEN
			AllocArrayOfRecord(g, v, inRecord)
		END;
		v := v.next
	END
END InitAllVarsWichArrayOfRecord;

PROCEDURE MarkWithDonor(VAR g: Generator; decl, donor: Ast.Declaration);
BEGIN
	IF decl.mark & (donor.up # NIL) THEN
		Text.Str(g, "module.");
		Name(g, decl);
		Text.Str(g, " = ");
		Name(g, decl);
		Text.StrLn(g, ";")
	END
END MarkWithDonor;

PROCEDURE Mark(VAR g: Generator; decl: Ast.Declaration);
BEGIN
	MarkWithDonor(g, decl, decl)
END Mark;

PROCEDURE Type(VAR g: Generator; decl: Ast.Declaration; typ: Ast.Type;
               typeDecl, sameType: BOOLEAN);

	PROCEDURE Record(VAR g: Generator; rec: Ast.Record);
	VAR v: Ast.Declaration;
	BEGIN
		rec.module := g.module.bag;
		Text.Str(g, "function ");
		IF CheckStructName(g, rec) THEN
			GlobalName(g, rec)
		END;

		v := rec.vars;
		IF (v = NIL) & (rec.base = NIL) THEN
			Text.StrLn(g, "() {}")
		ELSE
			Text.StrOpen(g, "() {");
			IF rec.base # NIL THEN
				GlobalName(g, rec.base);
				Text.StrLn(g, ".call(this);")
			END;
			WHILE v # NIL DO
				EmptyLines(g, v);

				pvar(g, NIL, v, TRUE);

				v := v.next
			END;
			InitAllVarsWichArrayOfRecord(g, rec.vars, TRUE);
			Text.StrLnClose(g, "}")
		END;
		IF rec.base # NIL THEN
			Text.Str(g, "o7.extend(");
			Name(g, rec);
			Text.Str(g, ", ");
			GlobalName(g, rec.base);
			Text.StrLn(g, ");")
		END;
		IF rec.inAssign THEN
			RecordAssign(g, rec)
		END;
		Mark(g, rec)
	END Record;

	PROCEDURE Array(VAR g: Generator; decl: Ast.Declaration; arr: Ast.Array;
	                sameType: BOOLEAN);
	BEGIN
		Type(g, decl, arr.type, FALSE, sameType);
		Text.Str(g, "[]")
	END Array;
BEGIN
	IF typ = NIL THEN
		Text.Str(g, "Object ")
	ELSE
		IF ~typeDecl & Strings.IsDefined(typ.name) & (typ.id # Ast.IdArray) THEN
			IF ~sameType THEN
				IF typ.id IN Ast.ProcTypes THEN
					;
				ELSIF (typ.id = Ast.IdPointer) & Strings.IsDefined(typ.type.name) THEN
					GlobalName(g, typ.type)
				ELSE
					IF typ.id = Ast.IdRecord THEN
						ASSERT(CheckStructName(g, typ(Ast.Record)))
					END;
					GlobalName(g, typ)
				END;
				Text.Str(g, " ")
			END
		ELSIF ~sameType THEN
			CASE typ.id OF
			  Ast.IdInteger, Ast.IdSet:
				Text.Str(g, "int ")
			| Ast.IdLongInt, Ast.IdLongSet:
				Text.Str(g, "long ")
			| Ast.IdBoolean:
				IF g.opt.varInit # GenOptions.VarInitUndefined
				THEN	Text.Str(g, "boolean ")
				ELSE	Text.Str(g, "byte ")
				END
			| Ast.IdByte, Ast.IdChar:
				Text.Str(g, "byte ")
			| Ast.IdReal:
				Text.Str(g, "double ")
			| Ast.IdReal32:
				Text.Str(g, "float ")
			| Ast.IdPointer:
				Type(g, decl, typ.type, FALSE, sameType)
			| Ast.IdArray:
				Array(g, decl, typ(Ast.Array), sameType)
			| Ast.IdRecord:
				Record(g, typ(Ast.Record))
			| Ast.IdProcType, Ast.IdFuncType:
				(* TODO *)
				ASSERT(~typeDecl);
			END
		END
	END
END Type;

PROCEDURE TypeDecl(VAR g: Generator; typ: Ast.Type);
VAR mark: BOOLEAN; donor: Ast.Type;

	PROCEDURE Typedef(VAR g: Generator; typ: Ast.Type);
	BEGIN
		EmptyLines(g, typ);
		Declarator(g, typ, TRUE, FALSE, TRUE);
		(*Text.StrLn(g, ";")*)
	END Typedef;
BEGIN
	IF ~(typ.id IN (Ast.ProcTypes + {Ast.IdArray}))
	 & ((typ.id # Ast.IdPointer) OR ~Strings.IsDefined(typ.type.name))
	THEN
		Typedef(g, typ);
		donor := typ;
		IF (typ.id = Ast.IdRecord)
		OR (typ.id = Ast.IdPointer) & (typ.type.next = NIL)
		THEN
			mark := typ.mark;
			IF typ.id = Ast.IdPointer THEN
				typ := typ.type
			END;
			typ.mark := mark
			         OR (typ(Ast.Record).pointer # NIL)
			          & (typ(Ast.Record).pointer.mark)
		END;
		MarkWithDonor(g, typ, donor)
	END
END TypeDecl;

PROCEDURE Comment(VAR g: Generator; com: Strings.String);
BEGIN
	GenCommon.CommentC(g, g.opt^, com)
END Comment;

PROCEDURE Const(VAR g: Generator; const: Ast.Const; inModule: BOOLEAN);
BEGIN
	Comment(g, const.comment);
	EmptyLines(g, const);
	IF g.opt.std >= EcmaScript2015 THEN
		Text.Str(g, "const ")
	ELSE
		Text.Str(g, "var ")
	END;
	Name(g, const);
	Text.Str(g, " = ");
	Expression(g, const.expr, {});
	Text.StrLn(g, ";");

	Mark(g, const)
END Const;

PROCEDURE Var(VAR g: Generator; prev, var: Ast.Declaration; last: BOOLEAN);
VAR mark: BOOLEAN;
BEGIN
	mark := var.mark & ~g.opt.main;
	Comment(g, var.comment);
	EmptyLines(g, var);
	IF ~mark OR (g.opt.varInit # GenOptions.VarInitNo) & (var.type.id IN Ast.Structures) THEN
		IF var.up = NIL THEN
			Text.Str(g, "this.")
		ELSE
			Text.Str(g, "var ")
		END;

		(* TODO
		Declarator(g, var, FALSE, same, TRUE);
		*) Name(g, var);

		VarInit(g, var, FALSE);

		Text.StrLn(g, ";");

		Mark(g, var)
	END
END Var;

PROCEDURE ExprThenStats(VAR g: Generator; VAR wi: Ast.WhileIf);
BEGIN
	CheckExpr(g, wi.expr, {});
	Text.StrOpen(g, ") {");
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

PROCEDURE IsForSameType(dest, src: Ast.Type): SET;
VAR set: SET;
BEGIN
	IF (dest.id = Ast.IdByte) & (src.id = Ast.IdByte) THEN
		set := {ForSameType}
	ELSE
		set := {}
	END
	RETURN set
END IsForSameType;

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
			Text.Str(g, "if (");
			ExprThenStats(g, wi);
			Elsif(g, wi);
			IF wi # NIL THEN
				Text.IndentClose(g);
				Text.StrOpen(g, "} else {");
				statements(g, wi.stats)
			END;
			Text.StrLnClose(g, "}")
		ELSIF wi.elsif = NIL THEN
			Text.Str(g, "while (");
			ExprThenStats(g, wi);
			Text.StrLnClose(g, "}")
		ELSE
			Text.Str(g, "while (true) if (");
			ExprThenStats(g, wi);
			Elsif(g, wi);
			Text.StrLnClose(g, "} else break;")
		END
	END WhileIf;

	PROCEDURE Repeat(VAR g: Generator; st: Ast.Repeat);
	VAR e: Ast.Expression;
	BEGIN
		Text.StrOpen(g, "do {");
		statements(g, st.stats);
		IF st.expr.id = Ast.IdNegate THEN
			Text.StrClose(g, "} while (");
			e := st.expr(Ast.ExprNegate).expr;
			WHILE e.id = Ast.IdBraces DO
				e := e(Ast.ExprBraces).expr
			END;
			Expression(g, e, {});
			Text.StrLn(g, ");")
		ELSE
			Text.StrClose(g, "} while (!(");
			CheckExpr(g, st.expr, {});
			Text.StrLn(g, "));")
		END
	END Repeat;

	PROCEDURE For(VAR g: Generator; st: Ast.For);
		PROCEDURE IsEndMinus1(sum: Ast.ExprSum): BOOLEAN;
		RETURN (sum.next # NIL)
		     & (sum.next.next = NIL)
		     & (sum.next.add = Ast.Minus)
		     & (sum.next.term.value # NIL)
		     & (sum.next.term.value(Ast.ExprInteger).int = 1)
		END IsEndMinus1;
	BEGIN
		Text.Str(g, "for (");
		GlobalName(g, st.var);
		ExpressionBraced(g, " = ", st.expr, "; ", {});
		GlobalName(g, st.var);
		IF st.by > 0 THEN
			IF (st.to IS Ast.ExprSum) & IsEndMinus1(st.to(Ast.ExprSum)) THEN
				Text.Str(g, " < ");
				Expression(g, st.to(Ast.ExprSum).term, {})
			ELSE
				Text.Str(g, " <= ");
				Expression(g, st.to, {})
			END;
			IF st.by = 1 THEN
				Text.Str(g, "; ++");
				GlobalName(g, st.var)
			ELSE
				Text.Str(g, "; ");
				GlobalName(g, st.var);
				Text.Str(g, " += ");
				Text.Int(g, st.by)
			END
		ELSE
			Text.Str(g, " >= ");
			Expression(g, st.to, {});
			IF st.by = -1 THEN
				Text.Str(g, "; --");
				GlobalName(g, st.var)
			ELSE
				Text.Str(g, "; ");
				GlobalName(g, st.var);
				Text.Str(g, " -= ");
				Text.Int(g, -st.by)
			END
		END;
		Text.StrOpen(g, ") {");
		statements(g, st.stats);
		Text.StrLnClose(g, "}")
	END For;

	PROCEDURE Assign(VAR g: Generator; st: Ast.Assign);
	VAR toByte: BOOLEAN; lastSel: Ast.Selector; t: Ast.Type; braces: INTEGER;
	BEGIN
		toByte := (st.designator.type.id = Ast.IdByte)
		        & (st.expr.type.id IN {Ast.IdInteger, Ast.IdLongInt})
		        & (st.expr.value = NIL);
		braces := ORD(toByte);
		IF st.designator.type.id = Ast.IdArray THEN
			INC(braces);
			IF st.expr.id = Ast.IdString THEN
				Text.Str(g, "o7.strcpy(")
			ELSE
				Text.Str(g, "o7.copy(")
			END;
			Designator(g, st.designator, {ForSameType});
			Text.Str(g, ", ");
			g.opt.expectArray := TRUE
		ELSIF st.designator.type.id = Ast.IdRecord THEN
			INC(braces);
			Designator(g, st.designator, {ForSameType});
			Text.Str(g, ".assign(")
		ELSE
			Designator(g, st.designator, {ForSameType, ForAssign});
			lastSel := FindLastSel(st.designator, t);
			IF (lastSel = NIL) OR ~(lastSel IS Ast.SelArray) THEN
				Text.Str(g, " = ")
			ELSIF g.opt.checkIndex
			    & NeedCheckIndex(t(Ast.Array), lastSel(Ast.SelArray).index)
			THEN
				INC(braces);
				ExpressionBraced(g, ".put(", lastSel(Ast.SelArray).index, ", ", {})
			ELSE
				ExpressionBraced(g, "[", lastSel(Ast.SelArray).index, "] = ", {})
			END;
			IF toByte THEN
				Text.Str(g, "o7.itb(")
			END
		END;
		CheckExpr(g, st.expr, IsForSameType(st.designator.type, st.expr.type));
		g.opt.expectArray := FALSE;
		CASE braces OF
		  0: Text.StrLn(g, ";")
		| 1: Text.StrLn(g, ");")
		| 2: Text.StrLn(g, "));")
		END
	END Assign;

	PROCEDURE Case(VAR g: Generator; st: Ast.Case);
	VAR elem, elemWithRange: Ast.CaseElement;
	    caseExpr: Ast.Expression;

		PROCEDURE CaseElement(VAR g: Generator; elem: Ast.CaseElement);
		VAR r: Ast.CaseLabel;
		BEGIN
			IF ~IsCaseElementWithRange(elem) THEN
				r := elem.labels;
				WHILE r # NIL DO
					Text.Str(g, "case ");
					IF r.id = Ast.IdInteger THEN
						Text.Int(g, r.value)
					ELSE
						Text.Str(g, "0x");
						Text.Char(g, Hex.To(r.value DIV 10H));
						Text.Char(g, Hex.To(r.value MOD 10H))
					END;
					ASSERT(r.right = NIL);
					Text.StrLn(g, ":");

					r := r.next
				END;
				Text.IndentOpen(g);
				statements(g, elem.stats);
				Text.StrLn(g, "break;");
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
						Text.Str(g, "(o7_case_expr == ")
					ELSE
						ExpressionBraced(g, "(", caseExpr, " == ", {})
					END;
					Text.Int(g, r.value)
				ELSE
					ASSERT(r.value <= r.right.value);
					Text.Str(g, "(");
					Text.Int(g, r.value);
					IF caseExpr = NIL THEN
						Text.Str(g, " <= o7_case_expr && o7_case_expr <= ")
					ELSE
						ExpressionBraced(g, " <= ", caseExpr, " && ", {});
						Expression(g, caseExpr, {});
						Text.Str(g, " <= ")
					END;
					Text.Int(g, r.right.value)
				END;
				Text.Str(g, ")")
			END CaseRange;
		BEGIN
			Text.Str(g, "if (");
			r := elem.labels;
			ASSERT(r # NIL);
			CaseRange(g, r, caseExpr);
			WHILE r.next # NIL DO
				r := r.next;
				Text.Str(g, " || ");
				CaseRange(g, r, caseExpr)
			END;
			Text.StrOpen(g, ") {");
			statements(g, elem.stats);
			Text.StrClose(g, "}")
		END CaseElementAsIf;
	BEGIN
		elemWithRange := st.elements;
		WHILE (elemWithRange # NIL) & ~IsCaseElementWithRange(elemWithRange) DO
			elemWithRange := elemWithRange.next
		END;
		IF (elemWithRange # NIL)
		 & (st.expr.value = NIL)
		 & (~(st.expr IS Ast.Designator) OR (st.expr(Ast.Designator).sel # NIL))
		THEN
			caseExpr := NIL;
			Text.Str(g, "(function() { var o7_case_expr = ");
			Expression(g, st.expr, {});
			Text.StrOpen(g, ";");
			Text.StrLn(g, "switch (o7_case_expr) {")
		ELSE
			caseExpr := st.expr;
			Text.Str(g, "switch (");
			Expression(g, caseExpr, {});
			Text.StrLn(g, ") {")
		END;
		elem := st.elements;
		REPEAT
			CaseElement(g, elem);
			elem := elem.next
		UNTIL elem = NIL;
		Text.StrOpen(g, "default:");
		IF elemWithRange # NIL THEN
			elem := elemWithRange;
			CaseElementAsIf(g, elem, caseExpr);
			elem := elem.next;
			WHILE elem # NIL DO
				IF IsCaseElementWithRange(elem) THEN
					Text.Str(g, " else ");
					CaseElementAsIf(g, elem, caseExpr)
				END;
				elem := elem.next
			END;
			IF ~g.opt.caseAbort THEN
				;
			ELSIF caseExpr = NIL THEN
				Text.StrLn(g, " else o7.caseFail(o7_case_expr);")
			ELSE
				Text.Str(g, " else o7.caseFail(");
				Expression(g, caseExpr, {});
				Text.StrLn(g, ");")
			END
		ELSIF ~g.opt.caseAbort THEN
			;
		ELSIF caseExpr = NIL THEN
			Text.StrLn(g, "o7.caseFail(o7_case_expr);")
		ELSE
			Text.Str(g, "o7.caseFail(");
			Expression(g, caseExpr, {});
			Text.StrLn(g, ");")
		END;
		Text.StrLn(g, "break;");
		Text.StrLnClose(g, "}");
		IF caseExpr = NIL THEN
			Text.StrLnClose(g, "})();")
		END
	END Case;
BEGIN
	Comment(g, st.comment);
	IF 0 < st.emptyLines THEN
		Text.Ln(g)
	END;
	IF st IS Ast.Assign THEN
		Assign(g, st(Ast.Assign))
	ELSIF st IS Ast.Call THEN
		g.expressionSemicolon := TRUE;
		Expression(g, st.expr, {});
		IF g.expressionSemicolon THEN
			Text.StrLn(g, ";")
		ELSE
			Text.Ln(g)
		END
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

PROCEDURE ProcHeader(VAR g: Generator; decl: Ast.Procedure);
BEGIN
	Text.Str(g, "function ");
	Name(g, decl);
	ProcParams(g, decl.header)
END ProcHeader;

PROCEDURE Procedure(VAR g: Generator; proc: Ast.Procedure);
BEGIN
	Comment(g, proc.comment);

	ProcHeader(g, proc);
	Text.StrOpen(g, " {");

	INC(g.localDeep);

	g.fixedLen := g.len;

	declarations(g, proc);

	InitAllVarsWichArrayOfRecord(g, proc.vars, FALSE);

	Statements(g, proc.stats);

	IF proc.return # NIL THEN
		Text.Str(g, "return ");
		CheckExpr(g, proc.return,
		          IsForSameType(proc.header.type, proc.return.type));
		Text.StrLn(g, ";")
	END;

	DEC(g.localDeep);
	Text.StrLnClose(g, "}");
	Mark(g, proc);
	Text.Ln(g)
END Procedure;

PROCEDURE LnIfWrote(VAR g: Generator);
BEGIN
	IF g.fixedLen # g.len THEN
		Text.Ln(g);
		g.fixedLen := g.len
	END
END LnIfWrote;

PROCEDURE Declarations(VAR g: Generator; ds: Ast.Declarations);
VAR d: Ast.Declaration; inModule: BOOLEAN;
BEGIN
	inModule := ds IS Ast.Module;

	d := ds.start;

	WHILE (d # NIL) & (d IS Ast.Import) DO
		d := d.next
	END;

	WHILE (d # NIL) & (d IS Ast.Const) DO
		Const(g, d(Ast.Const), inModule);
		d := d.next
	END;
	LnIfWrote(g);

	WHILE (d # NIL) & (d IS Ast.Type) DO
		TypeDecl(g, d(Ast.Type));
		d := d.next
	END;
	LnIfWrote(g);

	WHILE (d # NIL) & (d IS Ast.Var) DO
		Var(g, NIL, d, TRUE);
		d := d.next
	END;
	LnIfWrote(g);

	WHILE d # NIL DO
		Procedure(g, d(Ast.Procedure));
		d := d.next
	END
END Declarations;

PROCEDURE DefaultOptions*(): Options;
VAR o: Options;
BEGIN
	NEW(o);
	IF o # NIL THEN
		V.Init(o^);
		GenOptions.Default(o^);
		o.std     := EcmaScript5;

		o.expectArray := FALSE
	END
	RETURN o
END DefaultOptions;

PROCEDURE Imports(VAR g: Generator; m: Ast.Module);
VAR d: Ast.Declaration;

	PROCEDURE Import(VAR g: Generator; decl: Ast.Declaration);
	VAR ofs: INTEGER;
	BEGIN
		Text.Str(g, "var ");
		Ident(g, decl.name);
		ofs := ORD(~IsSpecModuleName(decl.module.m.name));
		Text.Data(g, "_ = o7.import.", ofs, 14 - ofs);
		Ident(g, decl.module.m.name);
		Text.StrLn(g, ";");
		ASSERT(decl.module.m.ext = NIL);
		decl.module.m.ext := decl
	END Import;
BEGIN
	d := m.import;
	WHILE (d # NIL) & (d IS Ast.Import) DO
		Import(g, d);
		d := d.next
	END;
	Text.Ln(g)
END Imports;

PROCEDURE UnlinkImports(VAR g: Generator; m: Ast.Module);
VAR d: Ast.Declaration;
BEGIN
	d := m.import;
	WHILE (d # NIL) & (d IS Ast.Import) DO
		d.module.m.ext := NIL;
		d := d.next;
	END;
	Text.Ln(g)
END UnlinkImports;

PROCEDURE Generate*(out: Stream.POut;
                    module: Ast.Module; cmd: Ast.Statement;
                    opt: Options);
VAR g: Generator;

	PROCEDURE ModuleInit(VAR g: Generator; module: Ast.Module; cmd: Ast.Statement);
	VAR v: Ast.Declaration;
	BEGIN
		v := SearchArrayOfRecord(module.vars);
		IF (module.stats # NIL) OR (v # NIL) THEN
			InitAllVarsWichArrayOfRecord(g, v, FALSE);
			Statements(g, module.stats);
			Statements(g, cmd);
			Text.Ln(g)
		END
	END ModuleInit;

	PROCEDURE Main(VAR g: Generator; module: Ast.Module; cmd: Ast.Statement);
	BEGIN
		Text.StrOpen(g, "o7.main(function() {");
		InitAllVarsWichArrayOfRecord(g, module.vars, FALSE);
		Statements(g, module.stats);
		Statements(g, cmd);
		Text.StrLnClose(g, "});")
	END Main;
BEGIN
	ASSERT(~Ast.HasError(module));

	IF opt = NIL THEN
		opt := DefaultOptions()
	END;
	g.opt := opt;

	opt.index := 0;
	opt.main := (cmd # NIL) OR Strings.IsEqualToString(module.name, "script");

	GenInit(g, out, module, opt);
	GeneratorNotify(g);

	Comment(g, module.comment);

	Text.StrLn(g, "(function() { 'use strict';");

	Imports(g, module);

	Text.StrLn(g, "var module = {};");
	Text.Str(g, "o7.export.");
	Name(g, module);
	Text.StrLn(g, " = module;");
	Text.Ln(g);

	Declarations(g, module);

	IF opt.main THEN
		Main(g, module, cmd)
	ELSE
		ModuleInit(g, module, cmd)
	END;

	Text.StrLn(g, "return module;");
	Text.StrLn(g, "})();");

	UnlinkImports(g, module)
END Generate;

PROCEDURE GenerateOptions*(out: Stream.POut; opt: Options);
CONST Opt = "var o7 = {options : {checkIndex: false}};";
VAR ignore: INTEGER;
BEGIN
	IF ~opt.checkIndex THEN
		ignore := Stream.WriteChars(out^, Opt, 0, LEN(Opt) - 1)
	END
END GenerateOptions;

BEGIN
	type         := Type;
	declarations := Declarations;
	statements   := Statements;
	expression   := Expression;
	pvar         := Var
END GeneratorJs.

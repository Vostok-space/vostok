(*  Generator of Javascript-code by Oberon-07 abstract syntax tree. Based on GeneratorJava
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
MODULE GeneratorJs;

IMPORT
	V,
	Ast, AstTransform,
	Strings := StringStore, Chars0X,
	SpecIdentChecker,
	Scanner,
	SpecIdent := OberonSpecIdent,
	Stream     := VDataStream,
	FileStream := VFileStream,
	Text := TextGenerator,
	Utf8, Utf8Transform,
	Limits := TypesLimits,
	TranLim := TranslatorLimits;

CONST
	EcmaScript5*     = 0;
	EcmaScript2015* = 1;

	VarInitUndefined*   = 0;
	VarInitZero*        = 1;
	VarInitNo*          = 2;

	IdentEncSame*       = 0;
	IdentEncTranslit*   = 1;
	IdentEncEscUnicode* = 2;

	ForSameType = 0;
	ForCall     = 0;

TYPE
	Options* = POINTER TO RECORD(V.Base)
		std*: INTEGER;

		checkArith*,
		checkIndex*,
		caseAbort*,
		o7Assert*,
		comment*,
		generatorNote*: BOOLEAN;

		varInit*,
		identEnc*  : INTEGER;

		main*: BOOLEAN;

		index: INTEGER;

		(* TODO для более сложных случаев *)
		expectArray: BOOLEAN
	END;

	Generator* = RECORD(Text.Out)
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
	declarations: PROCEDURE(VAR gen: Generator; ds: Ast.Declarations);
	statements: PROCEDURE(VAR gen: Generator; stats: Ast.Statement);
	expression: PROCEDURE(VAR gen: Generator; expr: Ast.Expression; set: SET);
	pvar: PROCEDURE (VAR gen: Generator; prev, var: Ast.Declaration; last: BOOLEAN);

PROCEDURE Ident(VAR gen: Generator; ident: Strings.String);
VAR buf: ARRAY TranLim.LenName * 6 + 2 OF CHAR;
    i: INTEGER;
    it: Strings.Iterator;
BEGIN
	IF (gen.opt.identEnc = IdentEncSame) OR (Strings.GetChar(ident, 0) < 80X)
	THEN
		Text.String(gen, ident)
	ELSE
		ASSERT(Strings.GetIter(it, ident, 0));
		i := 0;
		IF gen.opt.identEnc = IdentEncEscUnicode THEN
			Utf8Transform.Escape(buf, i, it)
		ELSE ASSERT(gen.opt.identEnc = IdentEncTranslit);
			Utf8Transform.Transliterate(buf, i, it)
		END;
		Text.Data(gen, buf, 0, i)
	END
END Ident;

PROCEDURE Name(VAR gen: Generator; decl: Ast.Declaration);
VAR up: Ast.Declarations;
    prs: ARRAY TranLim.DeepProcedures + 1 OF Ast.Declarations;
    i: INTEGER;
BEGIN
	IF (decl IS Ast.Type) & (decl.up # NIL) & (decl.up.d # decl.module.m)
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
	IF SpecIdentChecker.IsSpecName(decl.name, {SpecIdentChecker.MathC}) THEN
		Text.Char(gen, "_")
	END
END Name;

PROCEDURE GlobalName(VAR gen: Generator; decl: Ast.Declaration);
BEGIN
	IF (decl.module # NIL) & (gen.module # decl.module.m)
	OR (decl.id = Ast.IdVar) & decl.mark
	THEN
		IF ~decl.mark & (decl IS Ast.Const) THEN
			(* TODO предварительно пометить экспортом *)
			expression(gen, decl(Ast.Const).expr.value, {})
		ELSE
			IF (decl.id = Ast.IdVar) & (gen.module = decl.module.m) THEN
				Text.Str(gen, "module")
			ELSE
				Ident(gen, decl.module.m.ext(Ast.Import).name)
			END;
			IF SpecIdentChecker.IsSpecModuleName(decl.module.m.name)
			 & ~decl.module.m.spec
			THEN
				Text.Str(gen, "_.")
			ELSE
				Text.Char(gen, ".")
			END;
			Name(gen, decl)
		END
	ELSE
		Name(gen, decl)
	END
END GlobalName;

PROCEDURE Factor(VAR gen: Generator; expr: Ast.Expression; set: SET);
BEGIN
	IF expr IS Ast.Factor THEN
		expression(gen, expr, set)
	ELSE
		Text.Str(gen, "(");
		expression(gen, expr, set);
		Text.Str(gen, ")")
	END
END Factor;

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
		Ast.PutChars(rec.pointer.module.m, rec.name, anon, 0, l)
	ELSE
		l := 0;
		ASSERT(Strings.CopyToChars(anon, l, rec.module.m.name));

		ASSERT(Chars0X.CopyString(anon, l, "_anon_0000"));
		ASSERT((gen.opt.index >= 0) & (gen.opt.index < 10000));
		i := gen.opt.index;
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

PROCEDURE GlobalNamePointer(VAR gen: Generator; t: Ast.Type);
BEGIN
	ASSERT(t.id IN {Ast.IdPointer, Ast.IdRecord});

	IF (t.id = Ast.IdPointer) & Strings.IsDefined(t.type.name) THEN
		t := t.type
	END;
	GlobalName(gen, t)
END GlobalNamePointer;

PROCEDURE Selector(VAR gen: Generator; sels: Selectors; i: INTEGER;
                   VAR typ: Ast.Type; desType: Ast.Type; set: SET);
VAR sel: Ast.Selector;

	PROCEDURE Record(VAR gen: Generator; VAR typ: Ast.Type; VAR sel: Ast.Selector);
	VAR var: Ast.Declaration;
	BEGIN
		var := sel(Ast.SelRecord).var;
		Text.Str(gen, ".");
		Name(gen, var);
		typ := var.type
	END Record;

	PROCEDURE Declarator(VAR gen: Generator; decl: Ast.Declaration);
	BEGIN
		GlobalName(gen, decl);
	END Declarator;

	PROCEDURE Array(VAR gen: Generator; VAR typ: Ast.Type;
	                VAR sel: Ast.Selector; decl: Ast.Declaration;
	                isDesignatorArray: BOOLEAN);
	VAR i: INTEGER;
	BEGIN
		Text.Str(gen, "[");
		expression(gen, sel(Ast.SelArray).index, {});
		typ := typ.type;
		sel := sel.next;
		i := 1;
		WHILE (sel # NIL) & (sel IS Ast.SelArray) DO
			Text.Str(gen, "][");
			expression(gen, sel(Ast.SelArray).index, {});
			INC(i);
			sel := sel.next;
			typ := typ.type
		END;
		Text.Str(gen, "]")
	END Array;
BEGIN
	IF i >= 0 THEN
		sel := sels.list[i]
	END;
	IF i < 0 THEN
		Declarator(gen, sels.decl)
	ELSE
		DEC(i);
		IF sel IS Ast.SelRecord THEN
			Selector(gen, sels, i, typ, desType, set);
			Record(gen, typ, sel)
		ELSIF sel IS Ast.SelArray THEN
			Selector(gen, sels, i, typ, desType, set);
			Array(gen, typ, sel, sels.decl,
			      (desType.id = Ast.IdArray) & (desType(Ast.Array).count = NIL))
		ELSIF sel IS Ast.SelPointer THEN
			Selector(gen, sels, i, typ, desType, set)
		ELSE ASSERT(sel IS Ast.SelGuard);
			Selector(gen, sels, i, typ, desType, set)
			(*
			Text.Str(gen, "((");
			GlobalNamePointer(gen, sel.type);
			Text.Str(gen, ")");
			IF i < 0 THEN
				Declarator(gen, sels.decl)
			ELSE
				Selector(gen, sels, i, typ, desType, set)
			END;
			Text.Str(gen, ")");
			typ := sel(Ast.SelGuard).type
			*)
		END;
	END
END Selector;

PROCEDURE Designator(VAR gen: Generator; des: Ast.Designator; set: SET);
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

	Selector(gen, sels, sels.i, typ, des.type, set)
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

PROCEDURE CheckExpr(VAR gen: Generator; e: Ast.Expression; set: SET);
BEGIN
	IF (gen.opt.varInit = VarInitUndefined)
	 & (e.value = NIL)
	 & (e.type.id IN {Ast.IdBoolean, Ast.IdInteger, Ast.IdLongInt, Ast.IdReal, Ast.IdReal32})
	 & IsMayNotInited(e)
	THEN
		Text.Str(gen, "O7.inited(");
		expression(gen, e, set);
		Text.Str(gen, ")")
	ELSE
		expression(gen, e, set)
	END
END CheckExpr;

PROCEDURE AssignInitValue(VAR gen: Generator; typ: Ast.Type);
	PROCEDURE Zero(VAR gen: Generator; typ: Ast.Type);
		PROCEDURE Array(VAR gen: Generator; typ: Ast.Type);
		VAR sizes: ARRAY TranLim.ArrayDimension OF Ast.Expression;
		    i, l: INTEGER;
		BEGIN
			l := -1;
			REPEAT
				INC(l);
				sizes[l] := typ(Ast.Array).count;
				typ := typ.type
			UNTIL typ.id # Ast.IdArray;

			Text.Str(gen, " = o7.array(");
			(*type(gen, NIL, typ, FALSE, FALSE);*)
			expression(gen, sizes[0], {});
			FOR i := 1 TO l DO
				Text.Str(gen, ", ");
				expression(gen, sizes[i], {})
			END;
			Text.Str(gen, ")")
		END Array;
	BEGIN
		CASE typ.id OF
		  Ast.IdInteger, Ast.IdLongInt, Ast.IdByte, Ast.IdReal, Ast.IdReal32,
		  Ast.IdSet, Ast.IdLongSet:
			Text.Str(gen, " = 0")
		| Ast.IdBoolean:
			Text.Str(gen, " = false")
		| Ast.IdChar:
			Text.Str(gen, " = '\0'")
		| Ast.IdPointer, Ast.IdProcType:
			Text.Str(gen, " = null")
		| Ast.IdArray:
			Array(gen, typ)
		| Ast.IdRecord:
			Text.Str(gen, " = new ");
			type(gen, NIL, typ, FALSE, FALSE);
			Text.Str(gen, "()")
		END
	END Zero;

	PROCEDURE Undef(VAR gen: Generator; typ: Ast.Type);
	BEGIN
		CASE typ.id OF
		  Ast.IdInteger:
			Text.Str(gen, " = O7.INT_UNDEF")
		| Ast.IdLongInt:
			Text.Str(gen, " = O7.LONG_UNDEF")
		| Ast.IdBoolean:
			Text.Str(gen, " = O7.BOOL_UNDEF")
		| Ast.IdByte:
			Text.Str(gen, " = 0")
		| Ast.IdChar:
			Text.Str(gen, " = '\0'")
		| Ast.IdReal:
			Text.Str(gen, " = O7.DBL_UNDEF")
		| Ast.IdReal32:
			Text.Str(gen, " = O7.FLT_UNDEF")
		| Ast.IdSet, Ast.IdLongSet:
			Text.Str(gen, " = 0")
		| Ast.IdPointer, Ast.IdProcType:
			Text.Str(gen, " = null")
		END
	END Undef;
BEGIN
	CASE gen.opt.varInit OF
	  VarInitUndefined:
		Undef(gen, typ)
	| VarInitZero:
		Zero(gen, typ)
	| VarInitNo:
		;
	END
END AssignInitValue;

PROCEDURE VarInit(VAR gen: Generator; var: Ast.Declaration; record: BOOLEAN);
BEGIN
	IF ~record & ~(var.type.id IN {Ast.IdArray, Ast.IdRecord})
	 & ~var(Ast.Var).checkInit
	 & Ast.IsGlobal(var)
	THEN
		IF var.type.id = Ast.IdPointer THEN
			Text.Str(gen, " = null")
		END
	ELSE
		AssignInitValue(gen, var.type)
	END
END VarInit;

PROCEDURE ExpressionBraced(VAR gen: Generator;
                           l: ARRAY OF CHAR; e: Ast.Expression; r: ARRAY OF CHAR;
                           set: SET);
BEGIN
	Text.Str(gen, l);
	expression(gen, e, set);
	Text.Str(gen, r)
END ExpressionBraced;

(* TODO Вынести в модуль *)
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

PROCEDURE Expression(VAR gen: Generator; expr: Ast.Expression; set: SET);

	PROCEDURE Call(VAR gen: Generator; call: Ast.ExprCall; set: SET);
	VAR p: Ast.Parameter;
		fp: Ast.Declaration;

		PROCEDURE Predefined(VAR gen: Generator; call: Ast.ExprCall);
		VAR e1: Ast.Expression;
			p2: Ast.Parameter;

			PROCEDURE Shift(VAR gen: Generator; shift: ARRAY OF CHAR;
			                e1, e2: Ast.Expression);
			BEGIN
				Text.Str(gen, "(");
				Factor(gen, e1, {});
				Text.Str(gen, shift);
				Factor(gen, e2, {});
				Text.Str(gen, ")")
			END Shift;

			PROCEDURE Len(VAR gen: Generator; e: Ast.Expression);
			VAR sel: Ast.Selector;
				des: Ast.Designator;
				count: Ast.Expression;
			BEGIN
				count := e.type(Ast.Array).count;
				IF count # NIL THEN
					Expression(gen, count, {})
				ELSE
					des := e(Ast.Designator);
					GlobalName(gen, des.decl);
					sel := des.sel;
					WHILE sel # NIL DO
						Text.Str(gen, "[0]");
						sel := sel.next
					END;
					Text.Str(gen, ".length")
				END
			END Len;

			PROCEDURE New(VAR gen: Generator; e: Ast.Expression);
			BEGIN
				Designator(gen, e(Ast.Designator), {ForSameType});
				Text.Str(gen, " = new ");
				GlobalNamePointer(gen, e.type);
				Text.Str(gen, "()")
			END New;

			PROCEDURE Ord(VAR gen: Generator; e: Ast.Expression);
			BEGIN
				CASE e.type.id OF
				  Ast.IdChar, Ast.IdArray:
					Expression(gen, e, {});
					(*
					ExpressionBraced(gen, "o7.cti(", e, ")", {});
					*)
				| Ast.IdBoolean:
					ExpressionBraced(gen, "o7.bti(", e, ")", {});
				| Ast.IdSet, Ast.IdLongSet:
					ExpressionBraced(gen, "o7.sti(", e, ")", {})
				END
			END Ord;

			PROCEDURE Inc(VAR gen: Generator;
			              e1: Ast.Designator; p2: Ast.Parameter);
			BEGIN
				Designator(gen, e1, {ForSameType});
				IF gen.opt.checkArith THEN
					Text.Str(gen, " = o7.add(");
					Designator(gen, e1, {});
					IF p2 = NIL THEN
						Text.Str(gen, ", 1)")
					ELSE
						ExpressionBraced(gen, ", ", p2.expr, ")", {})
					END
				ELSIF p2 = NIL THEN
					Text.Str(gen, "++")
				ELSE
					Text.Str(gen, " += ");
					Expression(gen, p2.expr, {})
				END
			END Inc;

			PROCEDURE Dec(VAR gen: Generator;
			              e1: Ast.Designator; p2: Ast.Parameter);
			BEGIN
				Designator(gen, e1, {ForSameType});
				IF gen.opt.checkArith THEN
					Text.Str(gen, " = o7.sub(");
					Designator(gen, e1, {});
					IF p2 = NIL THEN
						Text.Str(gen, ", 1)")
					ELSE
						ExpressionBraced(gen, ", ", p2.expr, ")", {})
					END
				ELSIF p2 = NIL THEN
					Text.Str(gen, "--")
				ELSE
					Text.Str(gen, " -= ");
					Expression(gen, p2.expr, {})
				END
			END Dec;

			PROCEDURE Assert(VAR gen: Generator; e: Ast.Expression);
			BEGIN
				IF gen.opt.o7Assert THEN
					Text.Str(gen, "o7.assert(");
				ELSE
					Text.Str(gen, "o7_assert(");
				END;
				CheckExpr(gen, e, {});
				Text.Str(gen, ")")
			END Assert;

			PROCEDURE Unpack(VAR gen: Generator; e1, e2: Ast.Designator);
			VAR index: Ast.Expression;
			BEGIN
				Designator(gen, e1, {ForSameType});
				ExpressionBraced(gen, " = o7.frexp(", e1, ", ", {});
				index := AstTransform.CutIndex(e2);
				Expression(gen, e2, {ForSameType});
				Text.Str(gen, ", ");
				Expression(gen, index, {});
				Text.Str(gen, ")")
			END Unpack;
		BEGIN
			e1 := call.params.expr;
			p2 := call.params.next;
			CASE call.designator.decl.id OF
			  SpecIdent.Abs:
				IF call.type.id = Ast.IdInteger THEN
					Text.Str(gen, "Math.abs(")
				ELSIF call.type.id = Ast.IdLongInt THEN
					Text.Str(gen, "Math.abs(")
				ELSE
					Text.Str(gen, "Math.abs(")
				END;
				Expression(gen, e1, {});
				Text.Str(gen, ")")
			| SpecIdent.Odd:
				Text.Str(gen, "(");
				Factor(gen, e1, {});
				Text.Str(gen, " % 2 == 1)")
			| SpecIdent.Len:
				Len(gen, e1)
			| SpecIdent.Lsl:
				Shift(gen, " << ", e1, p2.expr)
			| SpecIdent.Asr:
				Shift(gen, " >> ", e1, p2.expr)
			| SpecIdent.Ror:
				ExpressionBraced(gen, "o7.ror(", e1, ", ", {});
				Expression(gen, p2.expr, {});
				Text.Str(gen, ")")
			| SpecIdent.Floor:
				ExpressionBraced(gen, "o7.floor(", e1, ")", {})
			| SpecIdent.Flt:
				ExpressionBraced(gen, "o7.flt(", e1, ")", {})
			| SpecIdent.Ord:
				Ord(gen, e1)
			| SpecIdent.Chr:
				ExpressionBraced(gen, "o7.itc(", e1, ")", {})
			| SpecIdent.Inc:
				Inc(gen, e1(Ast.Designator), p2)
			| SpecIdent.Dec:
				Dec(gen, e1(Ast.Designator), p2)
			| SpecIdent.Incl:
				Expression(gen, e1, {ForSameType});
				Text.Str(gen, " |= 1 << ");
				Factor(gen, p2.expr, {})
			| SpecIdent.Excl:
				Expression(gen, e1, {ForSameType});
				Text.Str(gen, " &= ~(1 << ");
				Factor(gen, p2.expr, {});
				Text.Str(gen, ")")
			| SpecIdent.New:
				New(gen, e1)
			| SpecIdent.Assert:
				Assert(gen, e1)
			| SpecIdent.Pack:
				Designator(gen, e1(Ast.Designator), {ForSameType});
				ExpressionBraced(gen, " = o7.scalb(", e1, ", ", {});
				Expression(gen, p2.expr, {});
				Text.Str(gen, ")")
			| SpecIdent.Unpk:
				Unpack(gen, e1(Ast.Designator), p2.expr(Ast.Designator))
			END
		END Predefined;

		PROCEDURE ActualParam(VAR gen: Generator; VAR p: Ast.Parameter;
		                      VAR fp: Ast.Declaration);
		VAR t: Ast.Type;
		BEGIN
			t := fp.type;
			IF (t.id = Ast.IdByte) & (p.expr.type.id IN {Ast.IdInteger, Ast.IdLongInt})
			THEN
				ExpressionBraced(gen, "o7.itb(", p.expr, ")", {ForSameType})
			ELSIF (p.expr.type.id = Ast.IdByte) & (t.id = Ast.IdByte) THEN
				Designator(gen, p.expr(Ast.Designator), {ForSameType})
			ELSE
				IF fp.type.id # Ast.IdChar THEN
					t := fp.type
				END;
				gen.opt.expectArray := fp.type.id = Ast.IdArray;
				IF ~gen.opt.expectArray & (p.expr IS Ast.Designator) THEN
					Designator(gen, p.expr(Ast.Designator), {})
				ELSE
					Expression(gen, p.expr, {})
				END;
				gen.opt.expectArray := FALSE;

				t := p.expr.type
			END;

			p := p.next;
			fp := fp.next
		END ActualParam;
	BEGIN
		IF call.designator.decl IS Ast.PredefinedProcedure THEN
			Predefined(gen, call)
		ELSE
			Designator(gen, call.designator, {ForCall});
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

			PROCEDURE Expr(VAR gen: Generator; e: Ast.Expression);
			BEGIN
				IF (e.type.id IN (Ast.Sets + {Ast.IdBoolean}))
				 & ~(e IS Ast.Factor)
				THEN
					ExpressionBraced(gen, "(", e, ")", {})
				ELSE
					Expression(gen, e, {})
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
					Expression(gen, rel.value, {})
				ELSE
					notChar1 := ~notChar0 OR IsArrayAndNotChar(rel.exprs[1]);
					IF notChar0 = notChar1 THEN
						ASSERT(notChar0);
						Text.Str(gen, "o7.strcmp(")
					ELSIF notChar1 THEN
						Text.Str(gen, "o7.chstrcmp(")
					ELSE ASSERT(notChar0);
						Text.Str(gen, "o7.strchcmp(")
					END;
					Expr(gen, rel.exprs[0]);
					Text.Str(gen, ", ");
					Expr(gen, rel.exprs[1]);
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
					Text.Str(gen, "O7.icmp(")
				ELSE
					Text.Str(gen, "O7.lcmp(")
				END;
				Expr(gen, rel.exprs[0]);
				Text.Str(gen, ", ");
				Expr(gen, rel.exprs[1]);
				Text.Str(gen, ")");
				Text.Str(gen, str);
				Text.Str(gen, "0")
			ELSIF (   (rel.exprs[0].type.id = Ast.IdChar)
			       OR (rel.exprs[1].type.id = Ast.IdChar))
			    & (rel.relation # Scanner.Equal)
			THEN
				Text.Str(gen, "(0xFF & ");
				Expr(gen, rel.exprs[0]);
				Text.Str(gen, ")");
				Text.Str(gen, str);
				Text.Str(gen, "(0xFF & ");
				Expr(gen, rel.exprs[1]);
				Text.Str(gen, ")")
			ELSE
				Expr(gen, rel.exprs[0]);
				Text.Str(gen, str);
				Expr(gen, rel.exprs[1])
			END
		END Simple;

		PROCEDURE In(VAR gen: Generator; rel: Ast.ExprRelation);
		BEGIN
			IF (rel.exprs[0].value # NIL)
			 & (rel.exprs[0].value(Ast.ExprInteger).int IN {0 .. Limits.SetMax})
			THEN
				Text.Str(gen, "0 != (");
				Text.Str(gen, " (1 << ");
				Factor(gen, rel.exprs[0], {});
				Text.Str(gen, ") & ");
				Factor(gen, rel.exprs[1], {});
				Text.Str(gen, ")")
			ELSE
				Text.Str(gen, "o7.in(");
				Expression(gen, rel.exprs[0], {ForSameType});
				ExpressionBraced(gen, ", ", rel.exprs[1], ")", {})
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
	VAR first: BOOLEAN;
	BEGIN
		first := TRUE;
		REPEAT
			IF sum.add = Scanner.Minus THEN
				IF ~(sum.type.id IN Ast.Sets) THEN
					Text.Str(gen, " - ")
				ELSIF first THEN
					Text.Str(gen, " ~")
				ELSE
					Text.Str(gen, " & ~")
				END
			ELSIF sum.add = Scanner.Plus THEN
				IF sum.type.id IN Ast.Sets THEN
					Text.Str(gen, " | ")
				ELSE
					Text.Str(gen, " + ")
				END
			ELSIF sum.add = Scanner.Or THEN
				Text.Str(gen, " || ")
			END;
			CheckExpr(gen, sum.term, {});
			sum := sum.next;
			first := FALSE
		UNTIL sum = NIL
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
				ExpressionBraced(gen, "0, ", arr[0].term, ")", {})
			ELSE
				Expression(gen, arr[0].term, {})
			END
		END GenArrOfAddOrSub;
	BEGIN
		last := -1;
		REPEAT
			INC(last);
			arr[last] := sum;
			sum := sum.next
		UNTIL sum = NIL;
		GenArrOfAddOrSub(gen, arr, last, "o7.add("  , "o7.sub(");
		i := 0;
		WHILE i < last DO
			INC(i);
			ExpressionBraced(gen, ", ", arr[i].term, ")", {})
		END
	END SumCheck;

	PROCEDURE Term(VAR gen: Generator; term: Ast.ExprTerm);
	VAR toInt: BOOLEAN;
	BEGIN
		REPEAT
			toInt := FALSE;
			CheckExpr(gen, term.factor, {});
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
					Text.Str(gen, " / ");
					toInt := term.mult = Scanner.Div
				END
			| Scanner.And                : Text.Str(gen, " && ")
			| Scanner.Mod                : Text.Str(gen, " % ")
			END;
			IF term.expr IS Ast.ExprTerm THEN
				term := term.expr(Ast.ExprTerm)
			ELSE
				CheckExpr(gen, term.expr, {});
				term := NIL
			END;
			IF toInt THEN
				Text.Str(gen, " | 0")
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
		WHILE i >= 0 DO
			CASE arr[i].mult OF
			  Scanner.Asterisk : Text.Str(gen, "o7.mul(")
			| Scanner.Div, Scanner.Slash
			                   : Text.Str(gen, "o7.div(")
			| Scanner.Mod      : Text.Str(gen, "o7.mod(")
			END;
			DEC(i)
		END;
		Expression(gen, arr[0].factor, {});
		i := 0;
		WHILE i < last DO
			INC(i);
			ExpressionBraced(gen, ", ", arr[i].factor, ")", {})
		END;
		ExpressionBraced(gen, ", ", arr[last].expr, ")", {})
	END TermCheck;

	PROCEDURE Boolean(VAR gen: Generator; e: Ast.ExprBoolean);
	BEGIN
		IF e.bool
		THEN Text.Str(gen, "true")
		ELSE Text.Str(gen, "false")
		END
	END Boolean;

	PROCEDURE CString(VAR gen: Generator; e: Ast.ExprString);
	VAR s: ARRAY 8 OF CHAR; ch: CHAR; w: Strings.String; len: INTEGER;
	BEGIN
		w := e.string;
		IF e.asChar & ~gen.opt.expectArray THEN
			ch := CHR(e.int);
			Text.Str(gen, "0x");
			Text.Char(gen, ToHex(e.int DIV 16));
			Text.Char(gen, ToHex(e.int MOD 16))
		ELSE
			Text.Str(gen, "o7.toUtf8(");
			IF (w.ofs >= 0) & (w.block.s[w.ofs] = Utf8.DQuote) THEN
				Text.ScreeningString(gen, w)
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
					s[5] := ToHex(e.int DIV 16);
					s[6] := ToHex(e.int MOD 16);
					len := 8
				END;
				s[len - 1] := Utf8.DQuote;
				Text.Data(gen, s, 0, len)
			END;
			Text.Str(gen, ")")
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
		Text.Int(gen, ORD(set.set[0]));
		Text.Char(gen, "u")
	END SetValue;

	PROCEDURE Set(VAR gen: Generator; set: Ast.ExprSet);
		PROCEDURE Item(VAR gen: Generator; set: Ast.ExprSet);
		BEGIN
			IF set.exprs[0] = NIL THEN
				Text.Str(gen, "0")
			ELSE
				IF set.exprs[1] = NIL THEN
					Text.Str(gen, "(1 << ");
					Factor(gen, set.exprs[0], {})
				ELSE
					ExpressionBraced(gen, "o7.set(", set.exprs[0], ", ", {});
					Expression(gen, set.exprs[1], {})
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
			Expression(gen, is.designator, {});
		ELSE
			GlobalName(gen, decl);
		END;
		Text.Str(gen, " instanceof ");
		GlobalName(gen, extType);
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
		Call(gen, expr(Ast.ExprCall), {})
	| Ast.IdDesignator:
		IF (expr.value # NIL) & (expr.value.id = Ast.IdString)
		THEN	CString(gen, expr.value(Ast.ExprString))
		ELSE	Designator(gen, expr(Ast.Designator), set)
		END
	| Ast.IdRelation:
		Relation(gen, expr(Ast.ExprRelation))
	| Ast.IdSum:
		IF	  gen.opt.checkArith
			& (expr.type.id IN {Ast.IdInteger, Ast.IdLongInt, Ast.IdReal, Ast.IdReal32})
			& (expr.value = NIL)
		THEN	SumCheck(gen, expr(Ast.ExprSum))
		ELSE	Sum(gen, expr(Ast.ExprSum))
		END
	| Ast.IdTerm:
		IF	  (gen.opt.checkArith OR (expr.type.id IN {Ast.IdInteger, Ast.IdLongInt}))
			& (expr.type.id IN {Ast.IdInteger, Ast.IdLongInt, Ast.IdReal, Ast.IdReal32})
			& ((expr.value = NIL) OR TRUE (*TODO*))
		THEN	TermCheck(gen, expr(Ast.ExprTerm))
		ELSIF (expr.value # NIL)
		    & (Ast.ExprIntNegativeDividentTouch IN expr.properties)
		THEN	Expression(gen, expr.value, {})
		ELSE	Term(gen, expr(Ast.ExprTerm))
		END
	| Ast.IdNegate:
		IF expr.type.id IN Ast.Sets THEN
			Text.Str(gen, "~");
			Expression(gen, expr(Ast.ExprNegate).expr, {})
		ELSE
			Text.Str(gen, "!");
			CheckExpr(gen, expr(Ast.ExprNegate).expr, {})
		END
	| Ast.IdBraces:
		ExpressionBraced(gen, "(", expr(Ast.ExprBraces).expr, ")", set)
	| Ast.IdPointer:
		Text.Str(gen, "null")
	| Ast.IdIsExtension:
		IsExtension(gen, expr(Ast.ExprIsExtension))
	END
END Expression;

PROCEDURE ProcParams(VAR gen: Generator; proc: Ast.ProcType);
VAR p: Ast.Declaration;
BEGIN
	IF proc.params = NIL THEN
		Text.Str(gen, "()")
	ELSE
		Text.Str(gen, "(");
		p := proc.params;
		WHILE p # proc.end DO
			Name(gen, p);
			Text.Str(gen, ", ");
			p := p.next
		END;
		Name(gen, p(Ast.FormalParam));
		Text.Str(gen, ")")
	END
END ProcParams;

PROCEDURE Declarator(VAR gen: Generator; decl: Ast.Declaration;
                     typeDecl, sameType, global: BOOLEAN);
BEGIN
	ASSERT(~(decl IS Ast.Procedure));

	IF decl IS Ast.Type THEN
		type(gen, decl, decl(Ast.Type), typeDecl, FALSE)
	ELSE
		type(gen, decl, decl.type, FALSE, sameType)
	END;

	IF typeDecl THEN
		;
	ELSIF global THEN
		GlobalName(gen, decl)
	ELSE
		Name(gen, decl)
	END
END Declarator;

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
		Text.Str(gen, "O7.INTS_UNDEF(")
	| Ast.IdLongInt:
		Text.Str(gen, "O7.LONGS_UNDEF(")
	| Ast.IdReal:
		Text.Str(gen, "O7.DOUBLES_UNDEF(")
	| Ast.IdReal32:
		Text.Str(gen, "O7.FLOATS_UNDEF(")
	| Ast.IdBoolean:
		Text.Str(gen, "O7.BOOLS_UNDEF(")
	END;
	IF inRec THEN
		Text.Str(gen, "r.")
	END;
	Name(gen, d);
	Text.Str(gen, ");")
END ArraySimpleUndef;

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
			Text.StrLn(gen, "int i;")
		END
	END IteratorIfNeed;
BEGIN
	Text.StrOpen(gen, "void undef() {");
	IteratorIfNeed(gen, rec.vars);
	IF rec.base # NIL THEN
		GlobalName(gen, rec.base);
		Text.StrLn(gen, "_undef(r);")
	END;
	rec.ext(RecExt).undef := TRUE;
	var := rec.vars;
	WHILE var # NIL DO
		IF ~(var.type.id IN {Ast.IdRecord}) THEN
			Text.Str(gen, "r.");
			Name(gen, var);
			VarInit(gen, var, TRUE);
			Text.StrLn(gen, ";");
		ELSIF var.type.id = Ast.IdArray THEN
			typeUndef := TypeForUndef(var.type.type);
			IF IsArrayTypeSimpleUndef(var.type, arrTypeId, arrDeep) THEN
				ArraySimpleUndef(gen, arrTypeId, var, TRUE)
			ELSIF typeUndef # NIL THEN (* TODO вложенные циклы *)
				Text.Str(gen, "for (i = 0; i < r.");
				Name(gen, var);
				Text.StrOpen(gen, ".length; i += 1) {");
				GlobalName(gen, typeUndef);
				Text.Str(gen, "_undef(r.");
				Name(gen, var);
				Text.StrLn(gen, " + i);");

				Text.StrLnClose(gen, "}")
			END
		ELSIF (var.type.id = Ast.IdRecord) & (var.type.ext # NIL) THEN
			GlobalName(gen, var.type);
			Text.Str(gen, "_undef(r.");
			Name(gen, var);
			Text.StrLn(gen, ");")
		END;
		var := var.next
	END;
	Text.StrLnClose(gen, "}")
END RecordUndef;

PROCEDURE RecordAssign(VAR gen: Generator; rec: Ast.Record);
VAR var: Ast.Declaration;

	PROCEDURE RecordAssignHeader(VAR gen: Generator; rec: Ast.Record);
	BEGIN
		Name(gen, rec);
		Text.StrOpen(gen, ".prototype.assign = function(r) {");
	END RecordAssignHeader;

	PROCEDURE IsNeedBase(rec: Ast.Record): BOOLEAN;
	BEGIN
		REPEAT
			rec := rec.base
		UNTIL (rec = NIL) OR (rec.vars # NIL)
		RETURN rec # NIL
	END IsNeedBase;
BEGIN
	RecordAssignHeader(gen, rec);
	IF IsNeedBase(rec) THEN
		GlobalName(gen, rec.base);
		Text.StrLn(gen, ".prototype.assign.call(this, r);")
	END;
	var := rec.vars;
	WHILE var # NIL DO
		IF var.type.id = Ast.IdArray THEN
			(* TODO вложенные циклы *)
			Text.Str(gen, "for (var i = 0; i < r.");
			Name(gen, var);
			Text.StrOpen(gen, ".length; i += 1) {");
			Text.Str(gen, "this.");
			Name(gen, var);
			IF var.type.type.id # Ast.IdRecord THEN
				Text.Str(gen, "[i] = r.");
				Name(gen, var);
				Text.StrLn(gen, "[i];");
			ELSE
				Text.Str(gen, "[i].assign(r.");
				Name(gen, var);
				Text.StrLn(gen, "[i]);")
			END;
			Text.StrLnClose(gen, "}")
		ELSE
			Text.Str(gen, "this.");
			Name(gen, var);
			IF var.type.id = Ast.IdRecord THEN
				Text.Str(gen, ".assign(r.");
				Name(gen, var);
				Text.StrLn(gen, ");")
			ELSE
				Text.Str(gen, " = r.");
				Name(gen, var);
				Text.StrLn(gen, ";")
			END
		END;
		var := var.next
	END;
	Text.StrLnClose(gen, "}")
END RecordAssign;

PROCEDURE EmptyLines(VAR gen: Generator; d: Ast.Declaration);
BEGIN
	IF 0 < d.emptyLines THEN
		Text.Ln(gen)
	END
END EmptyLines;

PROCEDURE GenInit(VAR gen: Generator; out: Stream.POut;
                  module: Ast.Module;
                  opt: Options);
BEGIN
	Text.Init(gen, out);
	gen.module := module;
	gen.localDeep := 0;

	gen.opt := opt;

	gen.fixedLen := gen.len
END GenInit;

PROCEDURE GeneratorNotify(VAR gen: Generator);
BEGIN
	IF gen.opt.generatorNote THEN
		Text.StrLn(gen, "/* Generated by Vostok - Oberon-07 translator */");
		Text.Ln(gen)
	END
END GeneratorNotify;

PROCEDURE AllocArrayOfRecord(VAR gen: Generator; v: Ast.Declaration;
                             inRecord: BOOLEAN);
VAR
BEGIN
	(* TODO многомерные массивы *)
	ASSERT(v.type.type.id = Ast.IdRecord);

	IF inRecord THEN
		Text.Str(gen, "for (var i_ = 0; i_ < this.")
	ELSE
		Text.Str(gen, "for (var i_ = 0; i_ < ")
	END;
	Name(gen, v);
	Text.StrOpen(gen, ".length; i_++) {");
	IF inRecord THEN
		Text.Str(gen, "this.")
	END;
	Name(gen, v);
	Text.Str(gen, "[i_] = new ");
	type(gen, NIL, v.type.type, FALSE, FALSE);
	Text.StrLn(gen, "();");
	Text.StrLnClose(gen, "}")
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

PROCEDURE InitAllVarsWichArrayOfRecord(VAR gen: Generator; v: Ast.Declaration;
                                       inRecord: BOOLEAN);
VAR subt: Ast.Type;
BEGIN
	WHILE (v # NIL) & (v.id = Ast.IdVar) DO
		IF (v.type.id = Ast.IdArray)
		 & (Ast.ArrayGetSubtype(v.type(Ast.Array), subt) > 0)
		 & (subt.id = Ast.IdRecord)
		THEN
			AllocArrayOfRecord(gen, v, inRecord)
		END;
		v := v.next
	END
END InitAllVarsWichArrayOfRecord;

PROCEDURE MarkWithDonor(VAR gen: Generator; decl, donor: Ast.Declaration);
BEGIN
	IF decl.mark & (donor.up # NIL) THEN
		Text.Str(gen, "module.");
		Name(gen, decl);
		Text.Str(gen, " = ");
		Name(gen, decl);
		Text.StrLn(gen, ";")
	END
END MarkWithDonor;

PROCEDURE Mark(VAR gen: Generator; decl: Ast.Declaration);
BEGIN
	MarkWithDonor(gen, decl, decl)
END Mark;

PROCEDURE Type(VAR gen: Generator; decl: Ast.Declaration; typ: Ast.Type;
               typeDecl, sameType: BOOLEAN);

	PROCEDURE Record(VAR gen: Generator; rec: Ast.Record);
	VAR v: Ast.Declaration;
	BEGIN
		rec.module := gen.module.bag;
		Text.Str(gen, "function ");
		IF CheckStructName(gen, rec) THEN
			GlobalName(gen, rec)
		END;

		v := rec.vars;
		IF (v = NIL) & (rec.base = NIL) THEN
			Text.StrLn(gen, "() {}")
		ELSE
			Text.StrOpen(gen, "() {");
			IF rec.base # NIL THEN
				GlobalName(gen, rec.base);
				Text.StrLn(gen, ".call(this);")
			END;
			WHILE v # NIL DO
				EmptyLines(gen, v);

				pvar(gen, NIL, v, TRUE);

				v := v.next
			END;
			InitAllVarsWichArrayOfRecord(gen, rec.vars, TRUE);
			Text.StrLnClose(gen, "}")
		END;
		IF rec.base # NIL THEN
			Text.Str(gen, "o7.extend(");
			Name(gen, rec);
			Text.Str(gen, ", ");
			GlobalName(gen, rec.base);
			Text.StrLn(gen, ");")
		END;
		IF rec.inAssign THEN
			RecordAssign(gen, rec)
		END;
		Mark(gen, rec)
	END Record;

	PROCEDURE Array(VAR gen: Generator; decl: Ast.Declaration; arr: Ast.Array;
	                sameType: BOOLEAN);
	BEGIN
		Type(gen, decl, arr.type, FALSE, sameType);
		Text.Str(gen, "[]")
	END Array;
BEGIN
	IF typ = NIL THEN
		Text.Str(gen, "Object ")
	ELSE
		IF ~typeDecl & Strings.IsDefined(typ.name) & (typ.id # Ast.IdArray) THEN
			IF ~sameType THEN
				IF typ.id = Ast.IdProcType THEN
					;
				ELSIF (typ.id = Ast.IdPointer) & Strings.IsDefined(typ.type.name) THEN
					GlobalName(gen, typ.type)
				ELSE
					IF typ.id = Ast.IdRecord THEN
						ASSERT(CheckStructName(gen, typ(Ast.Record)))
					END;
					GlobalName(gen, typ)
				END;
				Text.Str(gen, " ")
			END
		ELSIF ~sameType THEN
			CASE typ.id OF
			  Ast.IdInteger, Ast.IdSet:
				Text.Str(gen, "int ")
			| Ast.IdLongInt, Ast.IdLongSet:
				Text.Str(gen, "long ")
			| Ast.IdBoolean:
				IF gen.opt.varInit # VarInitUndefined
				THEN	Text.Str(gen, "boolean ")
				ELSE	Text.Str(gen, "byte ")
				END
			| Ast.IdByte, Ast.IdChar:
				Text.Str(gen, "byte ")
			| Ast.IdReal:
				Text.Str(gen, "double ")
			| Ast.IdReal32:
				Text.Str(gen, "float ")
			| Ast.IdPointer:
				Type(gen, decl, typ.type, FALSE, sameType)
			| Ast.IdArray:
				Array(gen, decl, typ(Ast.Array), sameType)
			| Ast.IdRecord:
				Record(gen, typ(Ast.Record))
			| Ast.IdProcType:
				(* TODO *)
				ASSERT(~typeDecl);
			END
		END
	END
END Type;

PROCEDURE TypeDecl(VAR gen: Generator; typ: Ast.Type);
VAR mark: BOOLEAN; donor: Ast.Type;

	PROCEDURE Typedef(VAR gen: Generator; typ: Ast.Type);
	BEGIN
		EmptyLines(gen, typ);
		Declarator(gen, typ, TRUE, FALSE, TRUE);
		(*Text.StrLn(gen, ";")*)
	END Typedef;
BEGIN
	IF ~(typ.id IN {Ast.IdProcType, Ast.IdArray})
	 & ((typ.id # Ast.IdPointer) OR ~Strings.IsDefined(typ.type.name))
	THEN
		Typedef(gen, typ);
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
			          & (typ(Ast.Record).pointer.mark);
			IF gen.opt.varInit = VarInitUndefined THEN
				RecordUndef(gen, typ(Ast.Record))
			END
		END;
		MarkWithDonor(gen, typ, donor)
	END
END TypeDecl;

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

PROCEDURE Const(VAR gen: Generator; const: Ast.Const; inModule: BOOLEAN);
BEGIN
	Comment(gen, const.comment);
	EmptyLines(gen, const);
	IF gen.opt.std >= EcmaScript2015 THEN
		Text.Str(gen, "const ")
	ELSE
		Text.Str(gen, "var ")
	END;
	Name(gen, const);
	Text.Str(gen, " = ");
	Expression(gen, const.expr, {});
	Text.StrLn(gen, ";");

	Mark(gen, const);
END Const;

PROCEDURE Var(VAR gen: Generator; prev, var: Ast.Declaration; last: BOOLEAN);
VAR mark: BOOLEAN;
BEGIN
	mark := var.mark & ~gen.opt.main;
	Comment(gen, var.comment);
	EmptyLines(gen, var);
	IF ~mark OR (gen.opt.varInit # VarInitNo) & (var.type.id IN {Ast.IdRecord, Ast.IdArray}) THEN
		IF var.up = NIL THEN
			Text.Str(gen, "this.")
		ELSE
			Text.Str(gen, "var ")
		END;

		(* TODO
		Declarator(gen, var, FALSE, same, TRUE);
		*) Name(gen, var);

		VarInit(gen, var, FALSE);

		Text.StrLn(gen, ";");

		Mark(gen, var)
	END
END Var;

PROCEDURE ExprThenStats(VAR gen: Generator; VAR wi: Ast.WhileIf);
BEGIN
	CheckExpr(gen, wi.expr, {});
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
			Text.Str(gen, "while (true) if (");
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
			Expression(gen, e, {});
			Text.StrLn(gen, ");")
		ELSE
			Text.StrClose(gen, "} while (!(");
			CheckExpr(gen, st.expr, {});
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
		ExpressionBraced(gen, " = ", st.expr, "; ", {});
		GlobalName(gen, st.var);
		IF st.by > 0 THEN
			IF (st.to IS Ast.ExprSum) & IsEndMinus1(st.to(Ast.ExprSum)) THEN
				Text.Str(gen, " < ");
				Expression(gen, st.to(Ast.ExprSum).term, {})
			ELSE
				Text.Str(gen, " <= ");
				Expression(gen, st.to, {})
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
			Expression(gen, st.to, {});
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

	PROCEDURE Assign(VAR gen: Generator; st: Ast.Assign);
	VAR toByte: BOOLEAN;
	BEGIN
		toByte := (st.designator.type.id = Ast.IdByte)
		        & (st.expr.type.id IN {Ast.IdInteger, Ast.IdLongInt})
		        & (st.expr.value = NIL);
		IF st.designator.type.id = Ast.IdArray THEN
			IF st.expr.id = Ast.IdString THEN
				Text.Str(gen, "o7.strcpy(")
			ELSE
				Text.Str(gen, "o7.copy(")
			END;
			Designator(gen, st.designator, {ForSameType});
			Text.Str(gen, ", ");
			gen.opt.expectArray := TRUE
		ELSIF st.designator.type.id = Ast.IdRecord THEN
			Designator(gen, st.designator, {ForSameType});
			Text.Str(gen, ".assign(")
		ELSIF toByte THEN
			Designator(gen, st.designator, {ForSameType});
			Text.Str(gen, " = o7.itb(")
		ELSE
			Designator(gen, st.designator, {ForSameType});
			Text.Str(gen, " = ")
		END;
		CheckExpr(gen, st.expr, IsForSameType(st.designator.type, st.expr.type));
		gen.opt.expectArray := FALSE;
		CASE ORD(toByte)
		   + ORD(st.designator.type.id IN {Ast.IdArray, Ast.IdRecord})
		OF
		  0: Text.StrLn(gen, ";")
		| 1: Text.StrLn(gen, ");")
		| 2: Text.StrLn(gen, "));")
		END
	END Assign;

	PROCEDURE Case(VAR gen: Generator; st: Ast.Case);
	VAR elem, elemWithRange: Ast.CaseElement;
	    caseExpr: Ast.Expression;

		PROCEDURE CaseElement(VAR gen: Generator; elem: Ast.CaseElement);
		VAR r: Ast.CaseLabel;
		BEGIN
			IF ~IsCaseElementWithRange(elem) THEN
				r := elem.labels;
				WHILE r # NIL DO
					Text.Str(gen, "case ");
					IF r.id = Ast.IdInteger THEN
						Text.Int(gen, r.value)
					ELSE
						Text.Str(gen, "0x");
						Text.Char(gen, ToHex(r.value DIV 10H));
						Text.Char(gen, ToHex(r.value MOD 10H))
					END;
					ASSERT(r.right = NIL);
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
						ExpressionBraced(gen, "(", caseExpr, " == ", {})
					END;
					Text.Int(gen, r.value)
				ELSE
					ASSERT(r.value <= r.right.value);
					Text.Str(gen, "(");
					Text.Int(gen, r.value);
					IF caseExpr = NIL THEN
						Text.Str(gen, " <= o7_case_expr && o7_case_expr <= ")
					ELSE
						ExpressionBraced(gen, " <= ", caseExpr, " && ", {});
						Expression(gen, caseExpr, {});
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
		elemWithRange := st.elements;
		WHILE (elemWithRange # NIL) & ~IsCaseElementWithRange(elemWithRange) DO
			elemWithRange := elemWithRange.next
		END;
		IF (elemWithRange # NIL)
		 & (st.expr.value = NIL)
		 & (~(st.expr IS Ast.Designator) OR (st.expr(Ast.Designator).sel # NIL))
		THEN
			caseExpr := NIL;
			Text.Str(gen, "(function() { var o7_case_expr = ");
			Expression(gen, st.expr, {});
			Text.StrOpen(gen, ";");
			Text.StrLn(gen, "switch (o7_case_expr) {")
		ELSE
			caseExpr := st.expr;
			Text.Str(gen, "switch (");
			Expression(gen, caseExpr, {});
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
				Text.StrLn(gen, " else o7.caseFail(o7_case_expr);")
			ELSE
				Text.Str(gen, " else o7.caseFail(");
				Expression(gen, caseExpr, {});
				Text.StrLn(gen, ");")
			END
		ELSIF ~gen.opt.caseAbort THEN
			;
		ELSIF caseExpr = NIL THEN
			Text.StrLn(gen, "o7.caseFail(o7_case_expr);")
		ELSE
			Text.Str(gen, "o7.caseFail(");
			Expression(gen, caseExpr, {});
			Text.StrLn(gen, ");")
		END;
		Text.StrLn(gen, "break;");
		Text.StrLnClose(gen, "}");
		IF caseExpr = NIL THEN
			Text.StrLnClose(gen, "})();")
		END
	END Case;
BEGIN
	Comment(gen, st.comment);
	IF 0 < st.emptyLines THEN
		Text.Ln(gen)
	END;
	IF st IS Ast.Assign THEN
		Assign(gen, st(Ast.Assign))
	ELSIF st IS Ast.Call THEN
		gen.expressionSemicolon := TRUE;
		Expression(gen, st.expr, {});
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

PROCEDURE ProcHeader(VAR gen: Generator; decl: Ast.Procedure);
BEGIN
	Text.Str(gen, "function ");
	Name(gen, decl);
	ProcParams(gen, decl.header)
END ProcHeader;

PROCEDURE Procedure(VAR gen: Generator; proc: Ast.Procedure);
BEGIN
	Comment(gen, proc.comment);

	ProcHeader(gen, proc);
	Text.StrOpen(gen, " {");

	INC(gen.localDeep);

	gen.fixedLen := gen.len;

	declarations(gen, proc);

	InitAllVarsWichArrayOfRecord(gen, proc.vars, FALSE);

	Statements(gen, proc.stats);

	IF proc.return # NIL THEN
		Text.Str(gen, "return ");
		CheckExpr(gen, proc.return,
		          IsForSameType(proc.header.type, proc.return.type));
		Text.StrLn(gen, ";")
	END;

	DEC(gen.localDeep);
	Text.StrLnClose(gen, "}");
	Mark(gen, proc);
	Text.Ln(gen)
END Procedure;

PROCEDURE LnIfWrote(VAR gen: Generator);
BEGIN
	IF gen.fixedLen # gen.len THEN
		Text.Ln(gen);
		gen.fixedLen := gen.len
	END
END LnIfWrote;

PROCEDURE Declarations(VAR gen: Generator; ds: Ast.Declarations);
VAR d: Ast.Declaration; inModule: BOOLEAN;
BEGIN
	inModule := ds IS Ast.Module;

	d := ds.start;

	WHILE (d # NIL) & (d IS Ast.Import) DO
		d := d.next
	END;

	WHILE (d # NIL) & (d IS Ast.Const) DO
		Const(gen, d(Ast.Const), inModule);
		d := d.next
	END;
	LnIfWrote(gen);

	WHILE (d # NIL) & (d IS Ast.Type) DO
		TypeDecl(gen, d(Ast.Type));
		d := d.next
	END;
	LnIfWrote(gen);

	WHILE (d # NIL) & (d IS Ast.Var) DO
		Var(gen, NIL, d, TRUE);
		d := d.next
	END;
	LnIfWrote(gen);

	WHILE d # NIL DO
		Procedure(gen, d(Ast.Procedure));
		d := d.next
	END
END Declarations;

PROCEDURE DefaultOptions*(): Options;
VAR o: Options;
BEGIN
	NEW(o);
	IF o # NIL THEN
		V.Init(o^);

		o.std           := EcmaScript5;
		o.checkArith    := TRUE & FALSE;
		o.checkIndex    := TRUE;
		o.caseAbort     := TRUE;
		o.o7Assert      := TRUE;
		o.comment       := TRUE;
		o.generatorNote := TRUE;
		o.varInit       := VarInitZero;
		o.identEnc      := IdentEncSame;

		o.expectArray := FALSE;

		o.main := FALSE
	END
	RETURN o
END DefaultOptions;

PROCEDURE Imports(VAR gen: Generator; m: Ast.Module);
VAR d: Ast.Declaration;

	PROCEDURE Import(VAR gen: Generator; decl: Ast.Declaration);
	BEGIN
		Text.Str(gen, "var ");
		Ident(gen, decl.name);
		Text.Str(gen, " = o7.import.");
		Ident(gen, decl.module.m.name);
		Text.StrLn(gen, ";");
		ASSERT(decl.module.m.ext = NIL);
		decl.module.m.ext := decl
	END Import;
BEGIN
	d := m.import;
	WHILE (d # NIL) & (d IS Ast.Import) DO
		Import(gen, d);
		d := d.next
	END;
	Text.Ln(gen)
END Imports;

PROCEDURE UnlinkImports(VAR gen: Generator; m: Ast.Module);
VAR d: Ast.Declaration;
BEGIN
	d := m.import;
	WHILE (d # NIL) & (d IS Ast.Import) DO
		d.module.m.ext := NIL;
		d := d.next;
	END;
	Text.Ln(gen)
END UnlinkImports;

PROCEDURE Generate*(out: Stream.POut;
                    module: Ast.Module; cmd: Ast.Statement;
                    opt: Options);
VAR gen: Generator;

	PROCEDURE ModuleInit(VAR gen: Generator; module: Ast.Module; cmd: Ast.Statement);
	VAR v: Ast.Declaration;
	BEGIN
		v := SearchArrayOfRecord(module.vars);
		IF (module.stats # NIL) OR (v # NIL) THEN
			InitAllVarsWichArrayOfRecord(gen, v, FALSE);
			Statements(gen, module.stats);
			Statements(gen, cmd);
			Text.Ln(gen)
		END
	END ModuleInit;

	PROCEDURE Main(VAR gen: Generator; module: Ast.Module; cmd: Ast.Statement);
	BEGIN
		Text.StrOpen(gen, "o7.main(function() {");
		InitAllVarsWichArrayOfRecord(gen, module.vars, FALSE);
		Statements(gen, module.stats);
		Statements(gen, cmd);
		Text.StrLnClose(gen, "});");
	END Main;
BEGIN
	ASSERT(~Ast.HasError(module));

	IF opt = NIL THEN
		opt := DefaultOptions()
	END;
	gen.opt := opt;

	opt.index := 0;
	opt.main := (cmd # NIL) OR Strings.IsEqualToString(module.name, "script");

	GenInit(gen, out, module, opt);
	GeneratorNotify(gen);

	Comment(gen, module.comment);

	Text.StrLn(gen, "var o7;");
	Text.StrLn(gen, "(function(o7) { 'use strict';");

	Imports(gen, module);

	Text.StrLn(gen, "var module = {};");
	Text.Str(gen, "o7.export.");
	Name(gen, module);
	IF SpecIdentChecker.IsSpecModuleName(module.name) & ~module.spec THEN
		Text.Str(gen, "_")
	END;
	Text.StrLn(gen, " = module;");
	Text.Ln(gen);

	Declarations(gen, module);

	IF opt.main THEN
		Main(gen, module, cmd)
	ELSE
		ModuleInit(gen, module, cmd)
	END;

	Text.StrLn(gen, "return module;");
	Text.StrLn(gen, "})(o7 || (o7 = {}));");

	UnlinkImports(gen, module)
END Generate;

BEGIN
	type         := Type;
	declarator   := Declarator;
	declarations := Declarations;
	statements   := Statements;
	expression   := Expression;
	pvar         := Var
END GeneratorJs.

(*  Generator of Java-code by Oberon-07 abstract syntax tree. Based on GeneratorC
 *  Copyright (C) 2016-2018 ComdivByZero
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
MODULE GeneratorJava;

IMPORT
	V,
	Ast, AstTransform,
	Strings := StringStore,
	SpecIdentChecker,
	Scanner,
	SpecIdent := OberonSpecIdent,
	Stream     := VDataStream,
	FileStream := VFileStream,
	Text := TextGenerator,
	Utf8, Utf8Transform,
	Log,
	Limits := TypesLimits,
	TranLim := TranslatorLimits;

CONST
	VarInitUndefined*   = 0;
	VarInitZero*        = 1;

	IdentEncSame*       = 0;
	IdentEncTranslit*   = 1;
	IdentEncEscUnicode* = 2;

	ForSameType = 0;
	ForCall     = 0;

TYPE
	ProviderProcTypeName* = POINTER TO RProviderProcTypeName;
	ProvideProcTypeName* =
		PROCEDURE(prov: ProviderProcTypeName; typ: Ast.ProcType;
		          VAR name: Strings.String): FileStream.Out;
	RProviderProcTypeName* = RECORD(V.Base)
		gen: ProvideProcTypeName
	END;

	Options* = POINTER TO RECORD(V.Base)
		checkArith*,
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

		procTypeNamer: ProviderProcTypeName;
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
	OR (decl IS Ast.Procedure)
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
	IF SpecIdentChecker.IsSpecName(decl.name, {SpecIdentChecker.MathC})
	OR (decl IS Ast.Type) & (decl.id IN {Ast.IdRecord, Ast.IdPointer})
	 & (decl.up # NIL)
	 & (decl.up.d = decl.module.m)
	 & (Strings.Compare(decl.name, decl.module.m.name) = 0)
	THEN
		Text.Char(gen, "_")
	END
END Name;

PROCEDURE SpecNameForTypeNamedAsModule(VAR gen: Generator;
                                       decl: Ast.Declaration): BOOLEAN;
VAR specName: BOOLEAN;
BEGIN
	specName := (decl IS Ast.Type)
	          & (Strings.Compare(decl.name, decl.module.m.name) = 0);
	IF specName THEN
		Text.Str(gen, "Class")
	END
	RETURN specName
END SpecNameForTypeNamedAsModule;

PROCEDURE GlobalName(VAR gen: Generator; decl: Ast.Declaration);
BEGIN
	IF (gen.procTypeNamer = NIL)
	OR (decl.module # NIL) & (gen.module # decl.module.m)
	THEN
		IF ~decl.mark & (decl IS Ast.Const) THEN
			(* TODO предварительно пометить экспортом *)
			expression(gen, decl(Ast.Const).expr.value, {})
		ELSE
			Ident(gen, decl.module.m.name);

			IF SpecIdentChecker.IsSpecModuleName(decl.module.m.name)
			 & ~decl.module.m.spec
			THEN
				Text.Str(gen, "_.")
			ELSE
				Text.Char(gen, ".")
			END;
			IF ~SpecNameForTypeNamedAsModule(gen, decl) THEN
				Ident(gen, decl.name)
			END
(*
			OR SpecIdentChecker.IsO7SpecName(decl.name)
*)
		END
	ELSIF ~SpecNameForTypeNamedAsModule(gen, decl) THEN
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

	PROCEDURE Declarator(VAR gen: Generator; decl: Ast.Declaration; set: SET);
	BEGIN
		GlobalName(gen, decl);
		IF ~(ForCall IN set) & (decl.id = Ast.IdProc) THEN
			Text.Str(gen, "_proc")
		END
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
		Declarator(gen, sels.decl, set)
	ELSE
		DEC(i);
		IF sel IS Ast.SelRecord THEN
			Selector(gen, sels, i, typ, desType, set);
			Record(gen, typ, sel)
		ELSIF sel IS Ast.SelArray THEN
			Log.StrLn("SelArray");
			Selector(gen, sels, i, typ, desType, set);
			Array(gen, typ, sel, sels.decl,
			      (desType.id = Ast.IdArray) & (desType(Ast.Array).count = NIL))
		ELSIF sel IS Ast.SelPointer THEN
			Selector(gen, sels, i, typ, desType, set)
		ELSE ASSERT(sel IS Ast.SelGuard);
			Text.Str(gen, "((");
			GlobalNamePointer(gen, sel.type);
			Text.Str(gen, ")");
			IF i < 0 THEN
				Declarator(gen, sels.decl, set)
			ELSE
				Selector(gen, sels, i, typ, desType, set)
			END;
			Text.Str(gen, ")");
			typ := sel(Ast.SelGuard).type
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

	IF ~(ForSameType IN set) & (des.type.id = Ast.IdByte) THEN
		Text.Str(gen, "O7.toInt(");
		Selector(gen, sels, sels.i, typ, des.type, set);
		Text.Str(gen, ")")
	ELSE
		Selector(gen, sels, sels.i, typ, des.type, set);
	END
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

			Text.Str(gen, " = new ");
			type(gen, NIL, typ, FALSE, FALSE);
			FOR i := 0 TO l DO
				Text.Str(gen, "[");
				expression(gen, sizes[i], {});
				Text.Str(gen, "]");
			END
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
	END
END AssignInitValue;

PROCEDURE VarInit(VAR gen: Generator; var: Ast.Declaration; record: BOOLEAN);
BEGIN
	IF ~record & ~(var.type.id IN {Ast.IdArray, Ast.IdRecord})
	 & ~var(Ast.Var).checkInit
	 & (var.up # NIL) & (var.up.d.up = NIL) (* TODO *)
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
					IF e.id = Ast.IdDesignator THEN
						ExpressionBraced(gen, "O7.toInt(", e, ")", {});
					ELSE
						Text.Str(gen, "(int)");
						Factor(gen, e, {})
					END
				| Ast.IdBoolean, Ast.IdSet:
					ExpressionBraced(gen, "O7.ord(", e, ")", {})
				END
			END Ord;

			PROCEDURE Inc(VAR gen: Generator;
			              e1: Ast.Designator; p2: Ast.Parameter);
			BEGIN
				Designator(gen, e1, {ForSameType});
				IF gen.opt.checkArith THEN
					Text.Str(gen, " = O7.add(");
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
					Text.Str(gen, " = O7.sub(");
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
					Text.Str(gen, "O7.asrt(");
					CheckExpr(gen, e, {});
					Text.Str(gen, ")")
				ELSE
					Text.Str(gen, "assert ");
					CheckExpr(gen, e, {});
				END
			END Assert;

			PROCEDURE Unpack(VAR gen: Generator; e1, e2: Ast.Designator);
			VAR index: Ast.Expression;
			BEGIN
				Designator(gen, e1, {ForSameType});
				ExpressionBraced(gen, " = O7.frexp(", e1, ", ", {});
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
					Text.Str(gen, "java.lang.Math.abs(")
				ELSIF call.type.id = Ast.IdLongInt THEN
					Text.Str(gen, "java.lang.Math.abs(")
				ELSE
					Text.Str(gen, "java.lang.Math.abs(")
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
				ExpressionBraced(gen, "O7.ror(", e1, ", ", {});
				Expression(gen, p2.expr, {});
				Text.Str(gen, ")")
			| SpecIdent.Floor:
				ExpressionBraced(gen, "O7.floor(", e1, ")", {})
			| SpecIdent.Flt:
				ExpressionBraced(gen, "O7.flt(", e1, ")", {})
			| SpecIdent.Ord:
				Ord(gen, e1)
			| SpecIdent.Chr:
				IF gen.opt.checkArith
				 & (e1.type.id # Ast.IdByte) &(e1.value = NIL)
				THEN
					ExpressionBraced(gen, "O7.chr(", e1, ")", {})
				ELSE
					Text.Str(gen, "(byte)");
					Factor(gen, e1, {ForSameType})
				END
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
				ExpressionBraced(gen, " = O7.scalb(", e1, ", ", {});
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
				ExpressionBraced(gen, "O7.toByte(", p.expr, ")", {ForSameType})
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
			IF (call.designator.sel # NIL)
			OR (call.designator.decl.id = Ast.IdVar)
			THEN
				Text.Str(gen, ".run(")
			ELSE
				Text.Str(gen, "(")
			END;
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

			PROCEDURE Expr(VAR gen: Generator; e: Ast.Expression);
			BEGIN
				IF (e.type.id IN {Ast.IdSet, Ast.IdBoolean})
				 & ~(e IS Ast.Factor)
				THEN
					ExpressionBraced(gen, "(", e, ")", {})
				ELSE
					Expression(gen, e, {})
				END
			END Expr;
		BEGIN
			IF (rel.exprs[0].type.id = Ast.IdArray)
			 & (  (rel.exprs[0].value = NIL)
			   OR ~rel.exprs[0].value(Ast.ExprString).asChar
			   )
			THEN
				IF rel.value # NIL THEN
					Expression(gen, rel.value, {})
				ELSE
					Text.Str(gen, "O7.strcmp(");
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
				IF rel.value # NIL THEN
					Text.Str(gen, "O7.IN(")
				ELSE
					Text.Str(gen, "O7.in(")
				END;
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
				IF sum.type.id # Ast.IdSet THEN
					Text.Str(gen, " - ")
				ELSIF first THEN
					Text.Str(gen, " ~")
				ELSE
					Text.Str(gen, " & ~")
				END
			ELSIF sum.add = Scanner.Plus THEN
				IF sum.type.id = Ast.IdSet THEN
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
		GenArrOfAddOrSub(gen, arr, last, "O7.add("  , "O7.sub(");
		i := 0;
		WHILE i < last DO
			INC(i);
			ExpressionBraced(gen, ", ", arr[i].term, ")", {})
		END
	END SumCheck;

	PROCEDURE Term(VAR gen: Generator; term: Ast.ExprTerm);
	BEGIN
		REPEAT
			CheckExpr(gen, term.factor, {});
			CASE term.mult OF
			  Scanner.Asterisk           :
				IF term.type.id = Ast.IdSet THEN
					Text.Str(gen, " & ")
				ELSE
					Text.Str(gen, " * ")
				END
			| Scanner.Slash, Scanner.Div :
				IF term.type.id = Ast.IdSet THEN
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
				CheckExpr(gen, term.expr, {});
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
		WHILE i >= 0 DO
			CASE arr[i].mult OF
			  Scanner.Asterisk : Text.Str(gen, "O7.mul(")
			| Scanner.Div, Scanner.Slash
			                   : Text.Str(gen, "O7.div(")
			| Scanner.Mod      : Text.Str(gen, "O7.mod(")
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
	VAR s: ARRAY 8 OF CHAR;
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
				Text.Str(gen, "((byte)'\'')")
			ELSIF ch = "\" THEN
				Text.Str(gen, "((byte)'\\')")
			ELSIF (ch >= " ") & (ch <= CHR(127)) THEN
				Text.Str(gen, "((byte)'");
				Text.Char(gen, ch);
				Text.Str(gen, "')")
			ELSE
				Text.Str(gen, "((byte)0x");
				Text.Char(gen, ToHex(e.int DIV 16));
				Text.Char(gen, ToHex(e.int MOD 16));
				Text.Str(gen, ")")
			END
		ELSE
			Text.Str(gen, "O7.bytes(");
			IF (w.ofs >= 0) & (w.block.s[w.ofs] = Utf8.DQuote) THEN
				Text.ScreeningString(gen, w)
			ELSE
				s[0] := Utf8.DQuote;
				s[1] := "\";
				IF e.int = ORD("\") THEN
					s[2] := "\";
					s[3] := Utf8.DQuote;
					s[4] := Utf8.Null
				ELSIF e.int = 0AH THEN
					s[2] := "n";
					s[3] := Utf8.DQuote;
					s[4] := Utf8.Null
				ELSIF e.int = ORD(Utf8.DQuote) THEN
					s[2] := Utf8.DQuote;
					s[3] := Utf8.DQuote;
					s[4] := Utf8.Null
				ELSE
					s[2] := "u";
					s[3] := "0";
					s[4] := "0";
					s[5] := ToHex(e.int DIV 16);
					s[6] := ToHex(e.int MOD 16);
					s[7] := Utf8.DQuote
				END;
				Text.Str(gen, s)
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
					ExpressionBraced(gen, "O7.set(", set.exprs[0], ", ", {});
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
	| Ast.IdSet:
		Set(gen, expr(Ast.ExprSet))
	| Ast.IdCall:
		Call(gen, expr(Ast.ExprCall), {})
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
			& (expr.value = NIL)
		THEN	TermCheck(gen, expr(Ast.ExprTerm))
		ELSE	Term(gen, expr(Ast.ExprTerm))
		END
	| Ast.IdNegate:
		IF expr.type.id IN { Ast.IdSet, Ast.IdLongSet } THEN
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

PROCEDURE Qualifier*(VAR gen: Generator; typ: Ast.Type);
BEGIN
	CASE typ.id OF
	  Ast.IdInteger:
		Text.Str(gen, "int")
	| Ast.IdLongInt:
		Text.Str(gen, "long")
	| Ast.IdSet:
		Text.Str(gen, "int")
	| Ast.IdLongSet:
		Text.Str(gen, "long")
	| Ast.IdBoolean:
		IF gen.opt.varInit # VarInitUndefined
		THEN	Text.Str(gen, "boolean")
		ELSE	Text.Str(gen, "byte")
		END
	| Ast.IdByte, Ast.IdChar:
		Text.Str(gen, "byte")
	| Ast.IdReal:
		Text.Str(gen, "double")
	| Ast.IdReal32:
		Text.Str(gen, "float")
	| Ast.IdPointer, Ast.IdProcType:
		GlobalName(gen, typ)
	END
END Qualifier;

PROCEDURE ProcParams(VAR gen: Generator; proc: Ast.ProcType);
VAR p: Ast.Declaration;

	PROCEDURE Par(VAR gen: Generator; fp: Ast.FormalParam);
	BEGIN
		declarator(gen, fp, FALSE, FALSE(*TODO*), FALSE)
	END Par;
BEGIN
	IF proc.params = NIL THEN
		Text.Str(gen, "()")
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

PROCEDURE RecordAssignHeader(VAR gen: Generator; rec: Ast.Record);
BEGIN
	IF rec.mark & ~gen.opt.main THEN
		Text.Str(gen, "public void assign(")
	ELSE
		Text.Str(gen, "private void assign(")
	END;
	GlobalName(gen, rec);
	Text.StrOpen(gen, " r) {")
END RecordAssignHeader;

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
	(*
	FOR i := 2 TO arrDeep DO
		Text.Str(gen, "[0]")
	END;
	Text.Str(gen, "), ");
	Name(gen, d);
	FOR i := 2 TO arrDeep DO
		Text.Str(gen, "[0]")
	END;
	*)
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

PROCEDURE IsRecordNeedAssign(rec: Ast.Record): BOOLEAN;
BEGIN
	WHILE (rec # NIL) & (rec.vars = NIL) DO
		rec := rec.base
	END
	RETURN rec # NIL
END IsRecordNeedAssign;

PROCEDURE RecordAssign(VAR gen: Generator; rec: Ast.Record);
VAR var: Ast.Declaration;
BEGIN
	RecordAssignHeader(gen, rec);
	IF IsRecordNeedAssign(rec.base) THEN
		Text.StrLn(gen, "super.assign(r);")
	END;
	var := rec.vars;
	WHILE var # NIL DO
		IF var.type.id = Ast.IdArray THEN
			(* TODO вложенные циклы *)
			Text.Str(gen, "for (int i = 0; i < r.");
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
		ELSIF (var.type.id # Ast.IdRecord)
		   OR IsRecordNeedAssign(var.type(Ast.Record))
		THEN
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
                  prov: ProviderProcTypeName; opt: Options);
BEGIN
	Text.Init(gen, out);
	gen.module := module;
	gen.localDeep := 0;

	gen.procTypeNamer := prov;
	gen.opt := opt;

	gen.fixedLen := gen.len;
END GenInit;

PROCEDURE GeneratorNotify(VAR gen: Generator);
BEGIN
	IF gen.opt.generatorNote THEN
		Text.StrLn(gen, "/* Generated by Vostok - Oberon-07 translator */");
		Text.Ln(gen)
	END
END GeneratorNotify;

PROCEDURE ClassForProcType(VAR gen: Generator;
                           name: Strings.String; typ: Ast.ProcType);
BEGIN
	GeneratorNotify(gen);
	Text.StrLn(gen, "package o7;");
	Text.Ln(gen);
	Text.Str(gen, "public abstract class ");
	Text.String(gen, name);
	Text.StrLn(gen, " {");
	Text.Ln(gen);
	IF typ.type = NIL THEN
		Text.Str(gen, "public abstract void run")
	ELSE
		Text.Str(gen, "public abstract ");
		type(gen, NIL, typ.type, FALSE, FALSE);
		Text.Str(gen, "run")
	END;
	ProcParams(gen, typ);
	Text.StrLn(gen, ";");
	Text.Ln(gen);
	Text.StrLn(gen, "}")
END ClassForProcType;

PROCEDURE ProcTypeNameGenAndArray(VAR gen: Generator; VAR name: Strings.String;
                                  proc: Ast.ProcType);
VAR out: FileStream.Out;
    ng: Generator;
BEGIN
	out := gen.procTypeNamer.gen(gen.procTypeNamer, proc, name);
	Text.Str(gen, "o7.");
	Text.String(gen, name);
	Text.Str(gen, " ");
	IF out # NIL THEN
		GenInit(ng, out, gen.module, NIL, gen.opt);
		ClassForProcType(ng, name, proc);
		FileStream.CloseOut(out)
	END
END ProcTypeNameGenAndArray;

PROCEDURE ProcTypeName(VAR gen: Generator; proc: Ast.ProcType);
VAR name: Strings.String;
BEGIN
	ProcTypeNameGenAndArray(gen, name, proc)
END ProcTypeName;

PROCEDURE AllocArrayOfRecord(VAR gen: Generator; v: Ast.Declaration);
VAR
BEGIN
	(* TODO многомерные массивы *)
	ASSERT(v.type.type.id = Ast.IdRecord);

	Text.Str(gen, "for (int i_ = 0; i_ < ");
	Name(gen, v);
	Text.StrOpen(gen, ".length; i_++) {");
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

PROCEDURE InitAllVarsWichArrayOfRecord(VAR gen: Generator; v: Ast.Declaration);
VAR subt: Ast.Type;
BEGIN
	WHILE (v # NIL) & (v.id = Ast.IdVar) DO
		IF (v.type.id = Ast.IdArray)
		 & (Ast.ArrayGetSubtype(v.type(Ast.Array), subt) > 0)
		 & (subt.id = Ast.IdRecord)
		THEN
			AllocArrayOfRecord(gen, v)
		END;
		v := v.next
	END
END InitAllVarsWichArrayOfRecord;

PROCEDURE Type(VAR gen: Generator; decl: Ast.Declaration; typ: Ast.Type;
               typeDecl, sameType: BOOLEAN);

	PROCEDURE Record(VAR gen: Generator; rec: Ast.Record);
	VAR v: Ast.Declaration; needConstructor: BOOLEAN;

		PROCEDURE Constructor(VAR gen: Generator; rec: Ast.Record);
		BEGIN
			Text.Ln(gen);
			Text.Str(gen, "public ");
			GlobalName(gen, rec);
			Text.StrOpen(gen, "() {");

			InitAllVarsWichArrayOfRecord(gen, rec.vars);

			Text.StrLnClose(gen, "}")
		END Constructor;
	BEGIN
		rec.module := gen.module.bag;
		Text.Str(gen, "static class ");
		IF CheckStructName(gen, rec) THEN
			GlobalName(gen, rec)
		END;
		IF rec.base # NIL THEN
			Text.Str(gen, " extends ");
			GlobalName(gen, rec.base)
		END;
		v := rec.vars;
		IF v = NIL THEN
			Text.StrLn(gen, " { }")
		ELSE
			Text.StrOpen(gen, " {");
			needConstructor := FALSE;
			WHILE v # NIL DO
				EmptyLines(gen, v);

				pvar(gen, NIL, v, TRUE);

				needConstructor := needConstructor
				                OR (v.type.id IN {Ast.IdArray});
				v := v.next
			END;
			IF needConstructor THEN
				Constructor(gen, rec)
			END;
			IF rec.inAssign THEN
				RecordAssign(gen, rec)
			END;
			Text.StrLnClose(gen, "}")
		END
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
					ProcTypeName(gen, typ(Ast.ProcType))
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
		ELSIF ~sameType
		THEN
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
				ProcTypeName(gen, typ(Ast.ProcType))
			END
		END
	END
END Type;

PROCEDURE Mark(VAR gen: Generator; mark: BOOLEAN);
BEGIN
	IF gen.localDeep = 0 THEN
		IF mark & ~gen.opt.main THEN
			Text.Str(gen, "public ")
		ELSE
			Text.Str(gen, "private ")
		END
	END
END Mark;

PROCEDURE TypeDecl(VAR gen: Generator; typ: Ast.Type);

	PROCEDURE Typedef(VAR gen: Generator; typ: Ast.Type);
	BEGIN
		EmptyLines(gen, typ);
		(* TODO *)
		IF typ.mark THEN
			Mark(gen, typ.mark)
		END;
		Declarator(gen, typ, TRUE, FALSE, TRUE);
		(*Text.StrLn(gen, ";")*)
	END Typedef;

BEGIN
	IF ~(typ.id IN {Ast.IdProcType, Ast.IdArray})
	 & ((typ.id # Ast.IdPointer) OR ~Strings.IsDefined(typ.type.name))
	THEN
		Typedef(gen, typ);
		IF (typ.id = Ast.IdRecord)
		OR (typ.id = Ast.IdPointer) & (typ.type.next = NIL)
		THEN
			IF typ.id = Ast.IdPointer THEN
				typ := typ.type
			END;
			typ.mark := typ.mark
			         OR (typ(Ast.Record).pointer # NIL)
			          & (typ(Ast.Record).pointer.mark);
			IF gen.opt.varInit = VarInitUndefined THEN
				RecordUndef(gen, typ(Ast.Record))
			END
		END
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
VAR value: Ast.Factor;
BEGIN
	Comment(gen, const.comment);
	EmptyLines(gen, const);
	Mark(gen, const.mark);
	IF inModule THEN
		Text.Str(gen, "static final ")
	ELSE
		Text.Str(gen, "final ")
	END;
	value := const.expr.value;
	IF (value.id = Ast.IdString) & (value(Ast.ExprString).asChar) THEN
		Text.Str(gen, "byte ");
		GlobalName(gen, const);
		Text.Str(gen, " = (byte)");
		Text.Int(gen, value(Ast.ExprString).int)
	ELSE
		Type(gen, NIL, const.type, FALSE, FALSE);
		Text.Str(gen, " ");
		GlobalName(gen, const);
		Text.Str(gen, " = ");
		Expression(gen, const.expr, {})
	END;
	Text.StrLn(gen, ";")
END Const;

PROCEDURE Var(VAR gen: Generator; prev, var: Ast.Declaration; last: BOOLEAN);
VAR same, mark: BOOLEAN;
BEGIN
	mark := var.mark & ~gen.opt.main;
	Comment(gen, var.comment);
	EmptyLines(gen, var);
	same := (prev # NIL) & (prev.mark = mark) & (prev.type = var.type);
	IF ~same THEN
		IF prev # NIL THEN
			Text.StrLn(gen, ";")
		END;
		IF var.up # NIL THEN
			Mark(gen, mark)
		END;
		IF (var.up # NIL) & (var.up.d IS Ast.Module) THEN
			Text.Str(gen, "static ")
		END
	ELSE
		Text.Str(gen, ", ")
	END;
	Declarator(gen, var, FALSE, same, TRUE);

	VarInit(gen, var, FALSE);

	IF last THEN
		Text.StrLn(gen, ";")
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
		IF (st.designator.type.id # Ast.IdRecord)
		OR IsRecordNeedAssign(st.designator.type(Ast.Record))
		THEN
			toByte := (st.designator.type.id = Ast.IdByte)
			        & (st.expr.type.id IN {Ast.IdInteger, Ast.IdLongInt});
			IF st.designator.type.id = Ast.IdArray THEN
				IF st.expr.id = Ast.IdString THEN
					Text.Str(gen, "O7.strcpy(")
				ELSE
					Text.Str(gen, "O7.copy(")
				END;
				Designator(gen, st.designator, {ForSameType});
				Text.Str(gen, ", ");
				gen.opt.expectArray := TRUE
			ELSIF st.designator.type.id = Ast.IdRecord THEN
				Designator(gen, st.designator, {ForSameType});
				Text.Str(gen, ".assign(")
			ELSIF toByte THEN
				Designator(gen, st.designator, {ForSameType});
				Text.Str(gen, " = O7.toByte(")
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
					Text.Int(gen, r.value);
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
			Text.Str(gen, "{ int o7_case_expr = ");
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
				Text.StrLn(gen, " else O7.caseFail(o7_case_expr);")
			ELSE
				Text.Str(gen, " else O7.caseFail(");
				Expression(gen, caseExpr, {});
				Text.StrLn(gen, ");")
			END
		ELSIF ~gen.opt.caseAbort THEN
			;
		ELSIF caseExpr = NIL THEN
			Text.StrLn(gen, "O7.caseFail(o7_case_expr);")
		ELSE
			Text.Str(gen, "O7.caseFail(");
			Expression(gen, caseExpr, {});
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
	IF decl.header.type = NIL THEN
		Text.Str(gen, "void ")
	ELSE
		Type(gen, decl, decl.header.type, FALSE, FALSE)
	END;
	Name(gen, decl);
	ProcParams(gen, decl.header)
END ProcHeader;

PROCEDURE Procedure(VAR gen: Generator; proc: Ast.Procedure);

	PROCEDURE Implement(VAR gen: Generator; proc: Ast.Procedure);
	BEGIN
		Comment(gen, proc.comment);
		Mark(gen, proc.mark);
		Text.Str(gen, "static ");

		ProcHeader(gen, proc);
		Text.StrOpen(gen, " {");

		INC(gen.localDeep);

		gen.fixedLen := gen.len;

		declarations(gen, proc);

		InitAllVarsWichArrayOfRecord(gen, proc.vars);

		Statements(gen, proc.stats);

		IF proc.return # NIL THEN
			Text.Str(gen, "return ");
			CheckExpr(gen, proc.return,
			          IsForSameType(proc.header.type, proc.return.type));
			Text.StrLn(gen, ";")
		END;

		DEC(gen.localDeep);
		Text.StrLnClose(gen, "}");
		Text.Ln(gen)
	END Implement;

	PROCEDURE LocalProcs(VAR gen: Generator; proc: Ast.Procedure);
	VAR p, t: Ast.Declaration;
	BEGIN
		t := proc.types;
		WHILE (t # NIL) & (t IS Ast.Type) DO
			TypeDecl(gen, t(Ast.Type));
			t := t.next
		END;
		p := proc.procedures;
		IF p # NIL THEN
			REPEAT
				Procedure(gen, p(Ast.Procedure));
				p := p.next
			UNTIL p = NIL
		END
	END LocalProcs;

	PROCEDURE Reference(VAR gen: Generator; proc: Ast.Procedure);
	VAR name: Strings.String;

		PROCEDURE Body(VAR gen: Generator; proc: Ast.Procedure);
		VAR fp: Ast.Declaration;
		BEGIN
			Text.StrOpen(gen, " {");
			IF proc.header.type # NIL THEN
				Text.Str(gen, "return ")
			END;
			Name(gen, proc);
			fp := proc.header.params;
			Text.Str(gen, "(");
			IF fp # NIL THEN
				Name(gen, fp);
				WHILE fp.next # NIL DO
					fp := fp.next;
					Text.Str(gen, ", ");
					Name(gen, fp)
				END
			END;
			Text.StrLn(gen, ");");
			Text.StrLnClose(gen, "}")
		END Body;
	BEGIN
		Mark(gen, proc.mark);
		Text.Str(gen, "static final ");
		ProcTypeNameGenAndArray(gen, name, proc.header);
		Text.Str(gen, " ");
		Name(gen, proc);
		Text.Str(gen, "_proc = new ");
		Text.String(gen, name);
		Text.StrOpen(gen, "() {");
		IF proc.header.type = NIL THEN
			Text.Str(gen, "public void ")
		ELSE
			Text.Str(gen, "public ");
			Type(gen, proc, proc.header.type, FALSE, FALSE)
		END;
		Text.Str(gen, "run");
		ProcParams(gen, proc.header);
		Body(gen, proc);

		Text.StrLnClose(gen, "};");
		Text.Ln(gen)
	END Reference;
BEGIN
	LocalProcs(gen, proc);
	Implement(gen, proc);
	IF proc.usedAsValue THEN
		Reference(gen, proc)
	END
END Procedure;

PROCEDURE LnIfWrote(VAR gen: Generator);
BEGIN
	IF gen.fixedLen # gen.len THEN
		Text.Ln(gen);
		gen.fixedLen := gen.len
	END
END LnIfWrote;

PROCEDURE Declarations(VAR gen: Generator; ds: Ast.Declarations);
VAR d, prev: Ast.Declaration; inModule: BOOLEAN;
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

	IF inModule THEN
		WHILE (d # NIL) & (d IS Ast.Type) DO
			TypeDecl(gen, d(Ast.Type));
			d := d.next
		END;
		LnIfWrote(gen);

		WHILE (d # NIL) & (d IS Ast.Var) DO
			Var(gen, NIL, d, TRUE);
			d := d.next
		END
	ELSE
		d := ds.vars;

		prev := NIL;
		WHILE (d # NIL) & (d IS Ast.Var) DO
			Var(gen, prev, d, (d.next = NIL) OR ~(d.next IS Ast.Var));
			prev := d;
			d := d.next
		END;

		d := ds.procedures
	END;
	LnIfWrote(gen);

	IF inModule THEN
		WHILE d # NIL DO
			Procedure(gen, d(Ast.Procedure));
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

		o.checkArith    := TRUE & FALSE;
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
	VAR name: Strings.String;
	BEGIN
		Text.Str(gen, "import o7.");
		name := decl.module.m.name;
		Text.String(gen, name);
		IF SpecIdentChecker.IsSpecModuleName(name) THEN
			Text.StrLn(gen, "_;")
		ELSE
			Text.StrLn(gen, ";")
		END
	END Import;
BEGIN
	d := m.import;
	WHILE (d # NIL) & (d IS Ast.Import) DO
		Import(gen, d);
		d := d.next
	END;
	Text.Ln(gen)
END Imports;

PROCEDURE ProviderProcTypeNameInit*(p: ProviderProcTypeName;
                                    gen: ProvideProcTypeName);
BEGIN
	V.Init(p^);
	p.gen := gen
END ProviderProcTypeNameInit;

PROCEDURE Generate*(out: Stream.POut;
                    module: Ast.Module; cmd: Ast.Statement;
                    provider: ProviderProcTypeName; opt: Options);
VAR gen: Generator;

	PROCEDURE ModuleInit(VAR gen: Generator; module: Ast.Module);
	VAR v: Ast.Declaration;
	BEGIN
		v := SearchArrayOfRecord(module.vars);
		IF (module.stats # NIL) OR (v # NIL) THEN
			Text.StrOpen(gen, "static {");
			IF v # NIL THEN
				InitAllVarsWichArrayOfRecord(gen, v)
			END;
			IF module.stats # NIL THEN
				Statements(gen, module.stats)
			END;
			Text.StrLnClose(gen, "}");
			Text.Ln(gen)
		END
	END ModuleInit;

	PROCEDURE Main(VAR gen: Generator; module: Ast.Module; cmd: Ast.Statement);
	BEGIN
		Text.StrOpen(gen, "public static void main(java.lang.String[] argv) {");
		Text.StrLn(gen, "O7.init(argv);");
		InitAllVarsWichArrayOfRecord(gen, module.vars);
		Statements(gen, module.stats);
		IF ~(cmd IS Ast.Nop) THEN
			Statements(gen, cmd)
		END;
		Text.StrLn(gen, "O7.exit();");
		Text.StrLnClose(gen, "}")
	END Main;
BEGIN
	ASSERT(~Ast.HasError(module));

	IF opt = NIL THEN
		opt := DefaultOptions()
	END;
	gen.opt := opt;

	opt.index := 0;
	opt.main := (cmd # NIL) OR Strings.IsEqualToString(module.name, "script");

	GenInit(gen, out, module, provider, opt);
	GeneratorNotify(gen);

	Comment(gen, module.comment);

	Text.StrLn(gen, "package o7;");
	Text.Ln(gen);
	Text.StrLn(gen, "import o7.O7;");
	Imports(gen, module);

	Text.Str(gen, "public final class ");
	Name(gen, module);
	IF SpecIdentChecker.IsSpecModuleName(module.name) & ~module.spec THEN
		Text.Str(gen, "_")
	END;
	Text.StrLn(gen, " {");
	Text.Ln(gen);

	Declarations(gen, module);

	IF opt.main THEN
		Main(gen, module, cmd)
	ELSE
		ModuleInit(gen, module)
	END;

	Text.StrLn(gen, "}")
END Generate;

BEGIN
	type         := Type;
	declarator   := Declarator;
	declarations := Declarations;
	statements   := Statements;
	expression   := Expression;
	pvar         := Var
END GeneratorJava.

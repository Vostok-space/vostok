(*  Generator of Java-code by Oberon-07 abstract syntax tree. Based on GeneratorC
 *  Copyright (C) 2016-2019,2021-2022 ComdivByZero
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

	ForSameType = 0;
	ForCall     = 1;
	SkipLastSel = 2;

TYPE
	ProviderProcTypeName* = POINTER TO RProviderProcTypeName;
	ProvideProcTypeName* =
		PROCEDURE(prov: ProviderProcTypeName; typ: Ast.ProcType;
		          VAR name: Strings.String): Stream.POut;
	RProviderProcTypeName* = RECORD(V.Base)
		g: ProvideProcTypeName
	END;

	Options* = POINTER TO RECORD(GenOptions.R)
		index: INTEGER
	END;

	Generator = RECORD(Text.Out)
		module: Ast.Module;

		localDeep: INTEGER;(* Вложенность процедур *)

		fixedLen: INTEGER;

		procTypeNamer: ProviderProcTypeName;
		opt: Options;

		forAssign, unreached, expectArray: BOOLEAN;

		guardDecl: Ast.Declaration
	END;

	Selectors = RECORD
		des: Ast.Designator;
		decl: Ast.Declaration;
		list: ARRAY TranLim.Selectors + 1 OF Ast.Selector;
		end: Ast.Selector;
		typeBeforeEnd: Ast.Type;
		i: INTEGER
	END;

	RecExt = POINTER TO RECORD(V.Base)
		anonName: Strings.String;
		undef: BOOLEAN;
		next: Ast.Record
	END;

VAR
	type: PROCEDURE(VAR g: Generator; decl: Ast.Declaration; type: Ast.Type;
	                typeDecl, sameType: BOOLEAN);
	declarations: PROCEDURE(VAR g: Generator; ds: Ast.Declarations);
	statements: PROCEDURE(VAR g: Generator; stats: Ast.Statement): BOOLEAN;
	expression: PROCEDURE(VAR g: Generator; expr: Ast.Expression; set: SET);
	pvar: PROCEDURE (VAR g: Generator; prev, var: Ast.Declaration; last: BOOLEAN);

PROCEDURE Str    (VAR g: Text.Out; s: ARRAY OF CHAR); BEGIN Text.Str    (g, s) END Str;
PROCEDURE StrLn  (VAR g: Text.Out; s: ARRAY OF CHAR); BEGIN Text.StrLn  (g, s) END StrLn;
PROCEDURE StrOpen(VAR g: Text.Out; s: ARRAY OF CHAR); BEGIN Text.StrOpen(g, s) END StrOpen;
PROCEDURE Ln     (VAR g: Text.Out);                   BEGIN Text.Ln     (g)    END Ln;
PROCEDURE Int    (VAR g: Text.Out; i: INTEGER);       BEGIN Text.Int    (g, i) END Int;
PROCEDURE Chr    (VAR g: Text.Out; c: CHAR);          BEGIN Text.Char   (g, c) END Chr;
PROCEDURE StrLnClose(VAR g: Text.Out; s: ARRAY OF CHAR); BEGIN Text.StrLnClose (g, s) END StrLnClose;

PROCEDURE Ident(VAR g: Generator; ident: Strings.String);
BEGIN
	GenCommon.Ident(g, ident, g.opt.identEnc)
END Ident;

PROCEDURE Name(VAR g: Generator; decl: Ast.Declaration);
VAR up: Ast.Declarations;
    prs: ARRAY TranLim.DeepProcedures + 1 OF Ast.Declarations;
    i: INTEGER;

	PROCEDURE IsGlobalRecordWithSameNameAsModule(decl: Ast.Declaration): BOOLEAN;
	RETURN (decl IS Ast.Type) & (decl.id IN {Ast.IdRecord, Ast.IdPointer})
	     & Ast.IsGlobal(decl)
	     & (Strings.Compare(decl.name, decl.module.m.name) = 0)
	END IsGlobalRecordWithSameNameAsModule;
BEGIN
	IF (decl.id = Ast.IdProc)
	OR (decl IS Ast.Type) & (decl.up # NIL) & (decl.up.d # decl.module.m)
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
	IF g.guardDecl = decl THEN
		Str(g, "__")
	ELSIF SpecIdentChecker.IsSpecName(decl.name, {SpecIdentChecker.MathC})
	OR IsGlobalRecordWithSameNameAsModule(decl)
	THEN
		Chr(g, "_")
	END
END Name;

PROCEDURE SpecNameForTypeNamedAsModule(VAR g: Generator;
                                       decl: Ast.Declaration): BOOLEAN;
VAR specName: BOOLEAN;
BEGIN
	specName := (decl IS Ast.Type)
	          & (Strings.Compare(decl.name, decl.module.m.name) = 0);
	IF specName THEN
		Str(g, "Class")
	END
	RETURN specName
END SpecNameForTypeNamedAsModule;

PROCEDURE GlobalName(VAR g: Generator; decl: Ast.Declaration);
BEGIN
	IF (g.procTypeNamer = NIL)
	OR (decl.module # NIL) & (g.module # decl.module.m)
	THEN
		IF ~decl.mark & (decl.id = Ast.IdConst) THEN
			(* TODO предварительно пометить экспортом *)
			expression(g, decl(Ast.Const).expr.value, {})
		ELSE
			Ident(g, decl.module.m.name);

			IF SpecIdentChecker.IsSpecModuleName(decl.module.m.name)
			 & ~decl.module.m.spec
			THEN
				Str(g, "_.")
			ELSE
				Chr(g, ".")
			END;
			IF ~SpecNameForTypeNamedAsModule(g, decl) THEN
				Name(g, decl)
			END
		END
	ELSIF ~SpecNameForTypeNamedAsModule(g, decl) THEN
		Name(g, decl)
	END
END GlobalName;

PROCEDURE Factor(VAR g: Generator; expr: Ast.Expression; set: SET);
BEGIN
	IF expr IS Ast.Factor THEN
		expression(g, expr, set)
	ELSE
		Chr(g, "(");
		expression(g, expr, set);
		Chr(g, ")")
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

PROCEDURE Selector(VAR g: Generator; VAR sels: Selectors;
                   VAR typ: Ast.Type; desType: Ast.Type; set: SET);
VAR sel: Ast.Selector;

	PROCEDURE Record(VAR g: Generator; VAR typ: Ast.Type; sel: Ast.Selector);
	VAR var: Ast.Declaration;
	BEGIN
		var := sel(Ast.SelRecord).var;
		Chr(g, ".");
		Name(g, var);
		typ := var.type
	END Record;

	PROCEDURE Declarator(VAR g: Generator; decl: Ast.Declaration; set: SET);
	BEGIN
		GlobalName(g, decl);
		IF ~(ForCall IN set) & (decl.id = Ast.IdProc) THEN
			Str(g, "_proc")
		END
	END Declarator;

	PROCEDURE Array(VAR g: Generator; VAR typ: Ast.Type;
	                sel, end: Ast.Selector; decl: Ast.Declaration);
	VAR i: INTEGER;
	BEGIN
		Chr(g, "[");
		expression(g, sel(Ast.SelArray).index, {});
		typ := typ.type;
		sel := sel.next;
		i := 1;
		WHILE (sel # end) & (sel IS Ast.SelArray) DO
			Str(g, "][");
			expression(g, sel(Ast.SelArray).index, {});
			INC(i);
			sel := sel.next;
			typ := typ.type
		END;
		Chr(g, "]")
	END Array;
BEGIN
	sel := sels.list[sels.i];
	IF sel = sels.end THEN
		IF ~(SkipLastSel IN set) THEN
			Declarator(g, sels.decl, set)
		END
	ELSE
		DEC(sels.i);
		IF sel IS Ast.SelRecord THEN
			Selector(g, sels, typ, desType, set);
			Record(g, typ, sel)
		ELSIF sel IS Ast.SelArray THEN
			Selector(g, sels, typ, desType, set);
			Array(g, typ, sel, sels.end, sels.decl)
		ELSE ASSERT(sel IS Ast.SelGuard);
			Str(g, "((");
			GlobalNamePointer(g, sel.type);
			Chr(g, ")");
			IF sel = sels.end THEN
				IF ~(SkipLastSel IN set) THEN
					Declarator(g, sels.decl, set)
				END
			ELSE
				Selector(g, sels, typ, desType, set)
			END;
			Chr(g, ")");
			typ := sel(Ast.SelGuard).type
		END;
	END
END Selector;

PROCEDURE SelectorsPut(des: Ast.Designator; VAR sels: Selectors; set: SET);
	PROCEDURE Put(VAR sels: Selectors; sel: Ast.Selector);
	BEGIN
		sels.i := 0;
		sels.list[0] := NIL;
		WHILE sel # NIL DO
			INC(sels.i);
			sels.list[sels.i] := sel;
			IF sel IS Ast.SelArray THEN
				REPEAT
					sel := sel.next;
					IF sel # NIL THEN
						sels.typeBeforeEnd := sels.typeBeforeEnd.type
					END
				UNTIL (sel = NIL) OR ~(sel IS Ast.SelArray)
			ELSE
				IF sel IS Ast.SelPointer THEN
					DEC(sels.i)
				END;
				IF sel.next # NIL THEN
					IF sel IS Ast.SelGuard THEN
						sels.typeBeforeEnd := sel(Ast.SelGuard).type
					ELSIF sel IS Ast.SelRecord THEN
						sels.typeBeforeEnd := sel(Ast.SelRecord).var.type
					ELSE
						sels.typeBeforeEnd := sels.typeBeforeEnd.type
					END
				END;
				sel := sel.next;
			END
		END
	END Put;
BEGIN
	sels.typeBeforeEnd := des.decl.type;
	Put(sels, des.sel);
	sels.des := des;
	sels.decl := des.decl;(* TODO *)
	IF SkipLastSel IN set THEN
		sels.end := sels.list[1]
	ELSE
		sels.end := NIL
	END
END SelectorsPut;

PROCEDURE DesignatorSels(VAR g: Generator; des: Ast.Designator; set: SET; VAR sels: Selectors);
VAR typ: Ast.Type;
BEGIN
	typ := des.decl.type;
	IF ~(ForSameType IN set) & (des.type.id = Ast.IdByte) THEN
		Str(g, "O7.toInt(");
		Selector(g, sels, typ, des.type, set);
		Chr(g, ")")
	ELSE
		Selector(g, sels, typ, des.type, set)
	END;
	sels.end := NIL
END DesignatorSels;

PROCEDURE Designator(VAR g: Generator; des: Ast.Designator; set: SET);
VAR sels: Selectors;
BEGIN
	SelectorsPut(des, sels, set);
	DesignatorSels(g, des, set, sels)
END Designator;

PROCEDURE IsMayNotInited(e: Ast.Expression): BOOLEAN;
VAR des: Ast.Designator; var: Ast.Var;
BEGIN
	var := NIL;
	IF e IS Ast.Designator THEN
		des := e(Ast.Designator);
		IF des.decl.id = Ast.IdVar THEN
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
	 & (e.type.id IN {Ast.IdBoolean, Ast.IdInteger, Ast.IdLongInt, Ast.IdReal, Ast.IdReal32})
	 & IsMayNotInited(e)
	THEN
		Str(g, "O7.inited(");
		expression(g, e, set);
		Chr(g, ")")
	ELSE
		expression(g, e, set)
	END
END CheckExpr;

PROCEDURE AssignInitValue(VAR g: Generator; typ: Ast.Type);
	PROCEDURE Zero(VAR g: Generator; typ: Ast.Type);
		PROCEDURE Array(VAR g: Generator; typ: Ast.Type);
		VAR sizes: ARRAY TranLim.ArrayDimension OF Ast.Expression;
		    i, l: INTEGER;
		BEGIN
			l := -1;
			REPEAT
				INC(l);
				sizes[l] := typ(Ast.Array).count;
				typ := typ.type
			UNTIL typ.id # Ast.IdArray;

			Str(g, " = new ");
			type(g, NIL, typ, FALSE, FALSE);
			FOR i := 0 TO l DO
				Chr(g, "[");
				expression(g, sizes[i], {});
				Chr(g, "]");
			END
		END Array;
	BEGIN
		CASE typ.id OF
		  Ast.IdInteger, Ast.IdLongInt, Ast.IdByte, Ast.IdReal, Ast.IdReal32,
		  Ast.IdSet, Ast.IdLongSet:
			Str(g, " = 0")
		| Ast.IdBoolean:
			Str(g, " = false")
		| Ast.IdChar:
			Str(g, " = '\0'")
		| Ast.IdPointer, Ast.IdProcType, Ast.IdFuncType:
			Str(g, " = null")
		| Ast.IdArray:
			Array(g, typ)
		| Ast.IdRecord:
			Str(g, " = new ");
			type(g, NIL, typ, FALSE, FALSE);
			Str(g, "()")
		END
	END Zero;

	PROCEDURE Undef(VAR g: Generator; typ: Ast.Type);
	BEGIN
		CASE typ.id OF
		  Ast.IdInteger:
			Str(g, " = O7.INT_UNDEF")
		| Ast.IdLongInt:
			Str(g, " = O7.LONG_UNDEF")
		| Ast.IdBoolean:
			Str(g, " = O7.BOOL_UNDEF")
		| Ast.IdByte:
			Str(g, " = 0")
		| Ast.IdChar:
			Str(g, " = '\0'")
		| Ast.IdReal:
			Str(g, " = O7.DBL_UNDEF")
		| Ast.IdReal32:
			Str(g, " = O7.FLT_UNDEF")
		| Ast.IdSet, Ast.IdLongSet:
			Str(g, " = 0")
		| Ast.IdPointer, Ast.IdProcType, Ast.IdFuncType:
			Str(g, " = null")
		END
	END Undef;
BEGIN
	CASE g.opt.varInit OF
	  GenOptions.VarInitUndefined:
		Undef(g, typ)
	| GenOptions.VarInitNo, GenOptions.VarInitZero:
		Zero(g, typ)
	END
END AssignInitValue;

PROCEDURE VarInit(VAR g: Generator; var: Ast.Declaration; record: BOOLEAN);
BEGIN
	IF record
	OR (var.type.id IN Ast.Structures)
	OR   var(Ast.Var).checkInit
	   & (~Ast.IsGlobal(var) OR (g.opt.varInit = GenOptions.VarInitUndefined))
	THEN
		AssignInitValue(g, var.type)
	END
END VarInit;

PROCEDURE ExpressionBraced(VAR g: Generator;
                    l: ARRAY OF CHAR; e: Ast.Expression; r: ARRAY OF CHAR;
                    set: SET);
BEGIN
	Str(g, l);
	expression(g, e, set);
	Str(g, r)
END ExpressionBraced;

PROCEDURE TwoExprBraced(VAR g: Generator;
                        l: ARRAY OF CHAR; e1: Ast.Expression; m: ARRAY OF CHAR;
                        e2: Ast.Expression; r: ARRAY OF CHAR; set: SET);
BEGIN
	Str(g, l);
	expression(g, e1, set);
	Str(g, m);
	expression(g, e2, set);
	Str(g, r)
END TwoExprBraced;

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
				Chr(g, "(");
				Factor(g, e1, {});
				Str(g, shift);
				Factor(g, e2, {});
				Chr(g, ")")
			END Shift;

			PROCEDURE Len(VAR g: Generator; e: Ast.Expression);
			VAR sel: Ast.Selector;
				des: Ast.Designator;
				count: Ast.Expression;
			BEGIN
				count := e.type(Ast.Array).count;
				IF count # NIL THEN
					Expression(g, count.value, {})
				ELSE
					des := e(Ast.Designator);
					GlobalName(g, des.decl);
					sel := des.sel;
					WHILE sel # NIL DO
						Str(g, "[0]");
						sel := sel.next
					END;
					Str(g, ".length")
				END
			END Len;

			PROCEDURE New(VAR g: Generator; e: Ast.Expression);
			BEGIN
				Designator(g, e(Ast.Designator), {ForSameType});
				Str(g, " = new ");
				GlobalNamePointer(g, e.type);
				Str(g, "()")
			END New;

			PROCEDURE Ord(VAR g: Generator; e: Ast.Expression);
			BEGIN
				CASE e.type.id OF
				  Ast.IdChar, Ast.IdArray:
					g.expectArray := FALSE;
					IF e.id = Ast.IdDesignator THEN
						ExpressionBraced(g, "O7.toInt(", e, ")", {});
					ELSE
						Str(g, "(int)");
						Factor(g, e, {})
					END
				| Ast.IdBoolean, Ast.IdSet, Ast.IdLongSet:
					ExpressionBraced(g, "O7.ord(", e, ")", {})
				END
			END Ord;

			PROCEDURE Inc(VAR g: Generator;
			              e1: Ast.Designator; p2: Ast.Parameter);
			BEGIN
				Designator(g, e1, {ForSameType});
				IF g.opt.checkArith THEN
					Str(g, " = O7.add(");
					Designator(g, e1, {});
					IF p2 = NIL THEN
						Str(g, ", 1)")
					ELSE
						ExpressionBraced(g, ", ", p2.expr, ")", {})
					END
				ELSIF p2 = NIL THEN
					Str(g, "++")
				ELSE
					Str(g, " += ");
					Expression(g, p2.expr, {})
				END
			END Inc;

			PROCEDURE Dec(VAR g: Generator;
			              e1: Ast.Designator; p2: Ast.Parameter);
			BEGIN
				Designator(g, e1, {ForSameType});
				IF g.opt.checkArith THEN
					Str(g, " = O7.sub(");
					Designator(g, e1, {});
					IF p2 = NIL THEN
						Str(g, ", 1)")
					ELSE
						ExpressionBraced(g, ", ", p2.expr, ")", {})
					END
				ELSIF p2 = NIL THEN
					Str(g, "--")
				ELSE
					Str(g, " -= ");
					Expression(g, p2.expr, {})
				END
			END Dec;

			PROCEDURE Assert(VAR g: Generator; e: Ast.Expression);
			BEGIN
				IF (e.value # NIL) & ~e.value(Ast.ExprBoolean).bool THEN
					Str(g, "throw null");
					g.unreached := TRUE
				ELSIF g.opt.o7Assert THEN
					Str(g, "O7.asrt(");
					CheckExpr(g, e, {});
					Chr(g, ")")
				ELSE
					Str(g, "assert ");
					CheckExpr(g, e, {})
				END
			END Assert;

			PROCEDURE Pack(VAR g: Generator; e1: Ast.Designator; e2: Ast.Expression);
			VAR sels: Selectors; last: Ast.Selector;
			BEGIN
				IF e1.sel = NIL THEN
					Designator(g, e1, {ForSameType});
					ExpressionBraced(g, " = O7.scalb(", e1, ", ", {});
					Expression(g, e2, {});
					Chr(g, ")")
				ELSE
					SelectorsPut(e1, sels, {SkipLastSel});
					last := sels.end;
					Chr(g, "{");
					type(g, NIL, sels.typeBeforeEnd, FALSE, FALSE);
					Str(g, " _d = ");
					DesignatorSels(g, e1, {ForSameType}, sels);
					IF last IS Ast.SelArray THEN
						ExpressionBraced(g, "; int _i = ", last(Ast.SelArray).index,
						                 "; _d[_i] = O7.scalb(_d[_i], ", {})
					ELSE
						Str(g, "; _d");
						Selector(g, sels, sels.typeBeforeEnd, e1.type, {SkipLastSel});
						INC(sels.i);
						Str(g, " = O7.scalb(_d");
						Selector(g, sels, sels.typeBeforeEnd, e1.type, {SkipLastSel});
						Str(g, ", ")
					END;
					Expression(g, e2, {});
					Str(g, ");}")
				END
			END Pack;

			PROCEDURE Unpack(VAR g: Generator; e1, e2: Ast.Designator);
			VAR index: Ast.Expression; sels: Selectors; last: Ast.Selector;
			BEGIN
				IF e1.sel = NIL THEN
					Designator(g, e1, {ForSameType});
					ExpressionBraced(g, " = O7.frexp(", e1, ", ", {});
				ELSE
					SelectorsPut(e1, sels, {SkipLastSel});
					last := sels.end;
					Chr(g, "{");
					type(g, NIL, sels.typeBeforeEnd, FALSE, FALSE);
					Str(g, " _d = ");
					DesignatorSels(g, e1, {ForSameType}, sels);
					IF last IS Ast.SelArray THEN
						ExpressionBraced(g, "; int _i = ", last(Ast.SelArray).index,
						                 "; _d[_i] = O7.frexp(_d[_i], ", {})
					ELSE
						Str(g, "; _d");
						Selector(g, sels, sels.typeBeforeEnd, e1.type, {SkipLastSel});
						INC(sels.i);
						Str(g, " = O7.frexp(_d");
						Selector(g, sels, sels.typeBeforeEnd, e1.type, {SkipLastSel});
						Str(g, ", ")
					END
				END;
				index := AstTransform.CutIndex(AstTransform.OutParamToArrayAndIndex, e2);
				Expression(g, e2, {ForSameType});
				IF (index.value = NIL) OR (index.value(Ast.ExprInteger).int # 0) THEN
					Str(g, ", ");
					Expression(g, index, {});
				END;
				Text.Data(g, ");}", 0, 1 + ORD(e1.sel # NIL) * 2)
			END Unpack;

			PROCEDURE Size(VAR g: Generator; t: Ast.Type);
			BEGIN
				Chr(g, "(");
				WHILE t.id = Ast.IdArray DO
					Int(g, t(Ast.Array).count.value(Ast.ExprInteger).int);
					Str(g, " * ");
					t := t.type
				END;
				CASE t.id OF
				  Ast.IdByte, Ast.IdChar, Ast.IdBoolean:
					Str(g, "1")
				| Ast.IdInteger, Ast.IdReal32, Ast.IdSet,
				  Ast.IdPointer, Ast.IdProcType, Ast.IdFuncType:
					Str(g, "4")
				| Ast.IdLongInt, Ast.IdReal, Ast.IdLongSet:
					Str(g, "8")
				| Ast.IdRecord:
					Str(g, "0x7FFFFFFF")
				END;
				Chr(g, ")");
			END Size;
		BEGIN
			e1 := call.params.expr;
			p2 := call.params.next;
			CASE call.designator.decl.id OF
			  SpecIdent.Abs:
				ExpressionBraced(g, "java.lang.Math.abs(", e1, ")", {});
			| SpecIdent.Odd:
				Chr(g, "(");
				Factor(g, e1, {});
				Str(g, " % 2 != 0)")
			| SpecIdent.Len:
				Len(g, e1)
			| SpecIdent.Lsl:
				Shift(g, " << ", e1, p2.expr)
			| SpecIdent.Asr:
				Shift(g, " >> ", e1, p2.expr)
			| SpecIdent.Ror:
				ExpressionBraced(g, "O7.ror(", e1, ", ", {});
				Expression(g, p2.expr, {});
				Chr(g, ")")
			| SpecIdent.Floor:
				ExpressionBraced(g, "O7.floor(", e1, ")", {})
			| SpecIdent.Flt:
				ExpressionBraced(g, "O7.flt(", e1, ")", {})
			| SpecIdent.Ord:
				Ord(g, e1)
			| SpecIdent.Chr:
				IF g.opt.checkArith
				 & (e1.type.id # Ast.IdByte) &(e1.value = NIL)
				THEN
					ExpressionBraced(g, "O7.chr(", e1, ")", {})
				ELSE
					Str(g, "(byte)");
					Factor(g, e1, {ForSameType})
				END
			| SpecIdent.Inc:
				Inc(g, e1(Ast.Designator), p2)
			| SpecIdent.Dec:
				Dec(g, e1(Ast.Designator), p2)
			| SpecIdent.Incl:
				Expression(g, e1, {ForSameType});
				Str(g, " |= 1 << ");
				Factor(g, p2.expr, {})
			| SpecIdent.Excl:
				Expression(g, e1, {ForSameType});
				Str(g, " &= ~(1 << ");
				Factor(g, p2.expr, {});
				Chr(g, ")")
			| SpecIdent.New:
				New(g, e1)
			| SpecIdent.Assert:
				Assert(g, e1)
			| SpecIdent.Pack:
				Pack(g, e1(Ast.Designator), p2.expr)
			| SpecIdent.Unpk:
				Unpack(g, e1(Ast.Designator), p2.expr(Ast.Designator))

			(* SYSTEM *)
			| SpecIdent.Adr:
				Str(g, "/*SYSTEM.ADR*/0")
			| SpecIdent.Size:
				Size(g, e1.type)
			| SpecIdent.Bit:
				TwoExprBraced(g, "O7.bit(", e1, ", ", p2.expr, ")", {});
			| SpecIdent.Get:
				Str(g, "/*SYSTEM.GET*/O7.asrt(false)")
			| SpecIdent.Put:
				Str(g, "/*SYSTEM.PUT*/O7.asrt(false)")
			| SpecIdent.Copy:
				Str(g, "/*SYSTEM.COPY*/O7.asrt(false)")
			END
		END Predefined;

		PROCEDURE ActualParam(VAR g: Generator; VAR p: Ast.Parameter;
		                      VAR fp: Ast.Declaration);
		VAR t: Ast.Type;
		BEGIN
			t := fp.type;
			IF (t.id = Ast.IdByte) & (p.expr.type.id IN {Ast.IdInteger, Ast.IdLongInt})
			THEN
				ExpressionBraced(g, "O7.toByte(", p.expr, ")", {ForSameType})
			ELSIF (p.expr.type.id = Ast.IdByte) & (t.id = Ast.IdByte) THEN
				Designator(g, p.expr(Ast.Designator), {ForSameType})
			ELSE
				IF fp.type.id # Ast.IdChar THEN
					t := fp.type
				END;
				g.expectArray := fp.type.id = Ast.IdArray;
				IF ~g.expectArray & (p.expr.id = Ast.IdDesignator) THEN
					Designator(g, p.expr(Ast.Designator), {})
				ELSE
					Expression(g, p.expr, {})
				END;
				g.expectArray := FALSE;

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
			IF (call.designator.sel # NIL)
			OR (call.designator.decl.id = Ast.IdVar)
			THEN
				Str(g, ".run(")
			ELSE
				Chr(g, "(")
			END;
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
			IF IsArrayAndNotChar(rel.exprs[0])
			OR IsArrayAndNotChar(rel.exprs[1])
			THEN
				IF rel.value # NIL THEN
					(* TODO Нужно ли это в Java? *)
					Expression(g, rel.value, {})
				ELSE
					Str(g, "O7.strcmp(");
					Expr(g, rel.exprs[0]);
					Str(g, ", ");
					Expr(g, rel.exprs[1]);
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
					Str(g, "O7.icmp(")
				ELSE
					Str(g, "O7.lcmp(")
				END;
				Expr(g, rel.exprs[0]);
				Str(g, ", ");
				Expr(g, rel.exprs[1]);
				Chr(g, ")");
				Str(g, str);
				Chr(g, "0")
			ELSIF (   (rel.exprs[0].type.id = Ast.IdChar)
			       OR (rel.exprs[1].type.id = Ast.IdChar))
			    & (rel.relation # Ast.Equal)
			THEN
				Str(g, "(0xFF & ");
				Expr(g, rel.exprs[0]);
				Chr(g, ")");
				Str(g, str);
				Str(g, "(0xFF & ");
				Expr(g, rel.exprs[1]);
				Chr(g, ")")
			ELSE
				Expr(g, rel.exprs[0]);
				Str(g, str);
				Expr(g, rel.exprs[1])
			END
		END Simple;

		PROCEDURE In(VAR g: Generator; rel: Ast.ExprRelation);
		BEGIN
			IF (rel.exprs[0].value # NIL)
			 & (rel.exprs[0].value(Ast.ExprInteger).int IN {0 .. Limits.SetMax})
			THEN
				Str(g, "0 != (");
				Str(g, " (1 << ");
				Factor(g, rel.exprs[0], {});
				Str(g, ") & ");
				Factor(g, rel.exprs[1], {});
				Chr(g, ")")
			ELSE
				Str(g, "O7.in(");
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
					Str(g, " - ")
				ELSIF first THEN
					Str(g, " ~")
				ELSE
					Str(g, " & ~")
				END
			ELSIF sum.add = Ast.Plus THEN
				IF sum.type.id IN Ast.Sets THEN
					Str(g, " | ")
				ELSE
					Str(g, " + ")
				END
			ELSIF sum.add = Ast.Or THEN
				Str(g, " || ")
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
				  Ast.Minus:
					Str(g, sub)
				| Ast.Plus:
					Str(g, add)
				END;
				DEC(i)
			END;
			IF arr[0].add = Ast.Minus THEN
				Str(g, sub);
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
		GenArrOfAddOrSub(g, arr, last, "O7.add("  , "O7.sub(");
		i := 0;
		WHILE i < last DO
			INC(i);
			ExpressionBraced(g, ", ", arr[i].term, ")", {})
		END
	END SumCheck;

	PROCEDURE Term(VAR g: Generator; term: Ast.ExprTerm);
	BEGIN
		REPEAT
			CheckExpr(g, term.factor, {});
			CASE term.mult OF
			  Ast.Mult:
				IF term.type.id IN Ast.Sets THEN
					Str(g, " & ")
				ELSE
					Str(g, " * ")
				END
			| Ast.Rdiv, Ast.Div :
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
				CheckExpr(g, term.expr, {});
				term := NIL
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
		WHILE i >= 0 DO
			CASE arr[i].mult OF
			  Ast.Mult          : Str(g, "O7.mul(")
			| Ast.Div, Ast.Rdiv : Str(g, "O7.div(")
			| Ast.Mod           : Str(g, "O7.mod(")
			END;
			DEC(i)
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
		THEN Str(g, "true")
		ELSE Str(g, "false")
		END
	END Boolean;

	PROCEDURE CString(VAR g: Generator; e: Ast.ExprString);
	VAR s: ARRAY 8 OF CHAR; ch: CHAR; w: Strings.String; len: INTEGER;
	BEGIN
		w := e.string;
		IF e.asChar & ~g.expectArray THEN
			ch := CHR(e.int);
			IF ch = "'" THEN
				Str(g, "((byte)'\'')")
			ELSIF ch = "\" THEN
				Str(g, "((byte)'\\')")
			ELSIF (ch >= " ") & (ch <= CHR(127)) THEN
				Str(g, "((byte)'");
				Chr(g, ch);
				Str(g, "')")
			ELSE
				Str(g, "((byte)0x");
				Chr(g, Hex.To(e.int DIV 16));
				Chr(g, Hex.To(e.int MOD 16));
				Chr(g, ")")
			END
		ELSE
			Str(g, "O7.bytes(");
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
			Chr(g, ")")
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
		Int(g, ORD(set.set[0]));
		Chr(g, "u")
	END SetValue;

	PROCEDURE Set(VAR g: Generator; set: Ast.ExprSet);
		PROCEDURE Item(VAR g: Generator; set: Ast.ExprSet);
		BEGIN
			IF set.exprs[0] = NIL THEN
				Chr(g, "0")
			ELSE
				IF set.exprs[1] = NIL THEN
					Str(g, "(1 << ");
					Factor(g, set.exprs[0], {})
				ELSE
					ExpressionBraced(g, "O7.set(", set.exprs[0], ", ", {});
					Expression(g, set.exprs[1], {})
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
			Expression(g, is.designator, {});
		ELSE
			GlobalName(g, decl);
		END;
		Str(g, " instanceof ");
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
			& (expr.value = NIL)
		THEN	TermCheck(g, expr(Ast.ExprTerm))
		ELSIF (expr.value # NIL)
		    & (Ast.ExprIntNegativeDividentTouch IN expr.properties)
		THEN	Expression(g, expr.value, {})
		ELSE	Term(g, expr(Ast.ExprTerm))
		END
	| Ast.IdNegate:
		IF expr.type.id IN Ast.Sets THEN
			Chr(g, "~");
			Expression(g, expr(Ast.ExprNegate).expr, {})
		ELSE
			Chr(g, "!");
			CheckExpr(g, expr(Ast.ExprNegate).expr, {})
		END
	| Ast.IdBraces:
		ExpressionBraced(g, "(", expr(Ast.ExprBraces).expr, ")", set)
	| Ast.IdPointer:
		Str(g, "null")
	| Ast.IdIsExtension:
		IsExtension(g, expr(Ast.ExprIsExtension))
	END
END Expression;

PROCEDURE Declarator(VAR g: Generator; decl: Ast.Declaration;
                     typeDecl, sameType, global: BOOLEAN);
BEGIN
	ASSERT(decl.id # Ast.IdProc);

	IF decl IS Ast.Type THEN
		type(g, decl, decl(Ast.Type), typeDecl, FALSE)
	ELSE
		type(g, decl, decl.type, FALSE, sameType)
	END;

	IF ~typeDecl THEN
		Chr(g, " ");
		IF global THEN
			GlobalName(g, decl)
		ELSE
			Name(g, decl)
		END
	END
END Declarator;

PROCEDURE ProcParams(VAR g: Generator; proc: Ast.ProcType);
VAR p: Ast.Declaration;

	PROCEDURE Par(VAR g: Generator; fp: Ast.FormalParam);
	BEGIN
		Declarator(g, fp, FALSE, FALSE(*TODO*), FALSE)
	END Par;
BEGIN
	IF proc.params = NIL THEN
		Str(g, "()")
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
END ProcParams;

PROCEDURE RecordAssignHeader(VAR g: Generator; rec: Ast.Record);
BEGIN
	IF rec.mark & ~g.opt.main THEN
		Str(g, "public void assign(")
	ELSE
		Str(g, "private void assign(")
	END;
	GlobalName(g, rec);
	StrOpen(g, " r) {")
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

PROCEDURE ArraySimpleUndef(VAR g: Generator; arrTypeId: INTEGER;
                           d: Ast.Declaration; inRec: BOOLEAN);
BEGIN
	CASE arrTypeId OF
	  Ast.IdInteger:
		Str(g, "O7.INTS_UNDEF(")
	| Ast.IdLongInt:
		Str(g, "O7.LONGS_UNDEF(")
	| Ast.IdReal:
		Str(g, "O7.DOUBLES_UNDEF(")
	| Ast.IdReal32:
		Str(g, "O7.FLOATS_UNDEF(")
	| Ast.IdBoolean:
		Str(g, "O7.BOOLS_UNDEF(")
	END;
	IF inRec THEN
		Str(g, "r.")
	END;
	Name(g, d);
	Str(g, ");")
END ArraySimpleUndef;

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
			StrLn(g, "int i;")
		END
	END IteratorIfNeed;
BEGIN
	StrOpen(g, "void undef() {");
	IteratorIfNeed(g, rec.vars);
	IF rec.base # NIL THEN
		GlobalName(g, rec.base);
		StrLn(g, "_undef(r);")
	END;
	rec.ext(RecExt).undef := TRUE;
	var := rec.vars;
	WHILE var # NIL DO
		IF ~(var.type.id IN {Ast.IdRecord}) THEN
			Str(g, "r.");
			Name(g, var);
			VarInit(g, var, TRUE);
			StrLn(g, ";");
		ELSIF var.type.id = Ast.IdArray THEN
			typeUndef := TypeForUndef(var.type.type);
			IF IsArrayTypeSimpleUndef(var.type, arrTypeId, arrDeep) THEN
				ArraySimpleUndef(g, arrTypeId, var, TRUE)
			ELSIF typeUndef # NIL THEN (* TODO вложенные циклы *)
				Str(g, "for (i = 0; i < r.");
				Name(g, var);
				StrOpen(g, ".length; i += 1) {");
				GlobalName(g, typeUndef);
				Str(g, "_undef(r.");
				Name(g, var);
				StrLn(g, " + i);");

				StrLnClose(g, "}")
			END
		ELSIF (var.type.id = Ast.IdRecord) & (var.type.ext # NIL) THEN
			GlobalName(g, var.type);
			Str(g, "_undef(r.");
			Name(g, var);
			StrLn(g, ");")
		END;
		var := var.next
	END;
	StrLnClose(g, "}")
END RecordUndef;

PROCEDURE IsRecordNeedAssign(rec: Ast.Record): BOOLEAN;
BEGIN
	WHILE (rec # NIL) & (rec.vars = NIL) DO
		rec := rec.base
	END
	RETURN rec # NIL
END IsRecordNeedAssign;

PROCEDURE RecordAssign(VAR g: Generator; rec: Ast.Record);
VAR var: Ast.Declaration;
BEGIN
	RecordAssignHeader(g, rec);
	IF IsRecordNeedAssign(rec.base) THEN
		StrLn(g, "super.assign(r);")
	END;
	var := rec.vars;
	WHILE var # NIL DO
		IF var.type.id = Ast.IdArray THEN
			(* TODO вложенные циклы *)
			Str(g, "for (int i = 0; i < r.");
			Name(g, var);
			StrOpen(g, ".length; i += 1) {");
			Str(g, "this.");
			Name(g, var);
			IF var.type.type.id # Ast.IdRecord THEN
				Str(g, "[i] = r.");
				Name(g, var);
				StrLn(g, "[i];");
			ELSE
				Str(g, "[i].assign(r.");
				Name(g, var);
				StrLn(g, "[i]);")
			END;
			StrLnClose(g, "}")
		ELSIF (var.type.id # Ast.IdRecord)
		   OR IsRecordNeedAssign(var.type(Ast.Record))
		THEN
			Str(g, "this.");
			Name(g, var);
			IF var.type.id = Ast.IdRecord THEN
				Str(g, ".assign(r.");
				Name(g, var);
				StrLn(g, ");")
			ELSE
				Str(g, " = r.");
				Name(g, var);
				StrLn(g, ";")
			END
		END;
		var := var.next
	END;
	StrLnClose(g, "}")
END RecordAssign;

PROCEDURE EmptyLines(VAR g: Generator; d: Ast.Declaration);
BEGIN
	IF 0 < d.emptyLines THEN
		Ln(g)
	END
END EmptyLines;

PROCEDURE GenInit(VAR g: Generator; out: Stream.POut;
                  module: Ast.Module;
                  prov: ProviderProcTypeName; opt: Options);
BEGIN
	Text.Init(g, out);
	g.module := module;
	g.localDeep := 0;

	g.procTypeNamer := prov;
	g.opt := opt;

	g.fixedLen := g.len;
	g.unreached := FALSE;
	g.expectArray := FALSE;

	g.guardDecl := NIL
END GenInit;

PROCEDURE GeneratorNotify(VAR g: Generator);
BEGIN
	IF g.opt.generatorNote THEN
		StrLn(g, "/* Generated by Vostok - Oberon-07 translator */");
		Ln(g)
	END
END GeneratorNotify;

PROCEDURE ClassForProcType(VAR g: Generator;
                           name: Strings.String; typ: Ast.ProcType);
BEGIN
	GeneratorNotify(g);
	StrLn(g, "package o7;");
	Ln(g);
	Str(g, "public abstract class ");
	Text.String(g, name);
	StrLn(g, " {");
	Ln(g);
	IF typ.type = NIL THEN
		Str(g, "public abstract void run")
	ELSE
		Str(g, "public abstract ");
		type(g, NIL, typ.type, FALSE, FALSE);
		Str(g, " run")
	END;
	ProcParams(g, typ);
	StrLn(g, ";");
	Ln(g);
	StrLn(g, "}")
END ClassForProcType;

PROCEDURE ProcTypeNameGenAndArray(VAR g: Generator; VAR name: Strings.String;
                                  proc: Ast.ProcType);
VAR out: Stream.POut;
    ng: Generator;
BEGIN
	out := g.procTypeNamer.g(g.procTypeNamer, proc, name);
	Str(g, "o7.");
	Text.String(g, name);
	Chr(g, " ");
	IF out # NIL THEN
		GenInit(ng, out, g.module, NIL, g.opt);
		ng.expectArray := g.expectArray;
		ClassForProcType(ng, name, proc);
		Stream.CloseOut(out)
	END
END ProcTypeNameGenAndArray;

PROCEDURE ProcTypeName(VAR g: Generator; proc: Ast.ProcType);
VAR name: Strings.String;
BEGIN
	ProcTypeNameGenAndArray(g, name, proc)
END ProcTypeName;

PROCEDURE AllocArrayOfRecord(VAR g: Generator; v: Ast.Declaration);
VAR
BEGIN
	(* TODO многомерные массивы *)
	ASSERT(v.type.type.id = Ast.IdRecord);

	Str(g, "for (int i_ = 0; i_ < ");
	Name(g, v);
	StrOpen(g, ".length; i_++) {");
	Name(g, v);
	Str(g, "[i_] = new ");
	type(g, NIL, v.type.type, FALSE, FALSE);
	StrLn(g, "();");
	StrLnClose(g, "}")
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

PROCEDURE InitAllVarsWhichArrayOfRecord(VAR g: Generator; v: Ast.Declaration);
VAR subt: Ast.Type;
BEGIN
	WHILE (v # NIL) & (v.id = Ast.IdVar) DO
		IF (v.type.id = Ast.IdArray)
		 & (Ast.ArrayGetSubtype(v.type(Ast.Array), subt) > 0)
		 & (subt.id = Ast.IdRecord)
		THEN
			AllocArrayOfRecord(g, v)
		END;
		v := v.next
	END
END InitAllVarsWhichArrayOfRecord;

PROCEDURE Type(VAR g: Generator; decl: Ast.Declaration; typ: Ast.Type;
               typeDecl, sameType: BOOLEAN);

	PROCEDURE Record(VAR g: Generator; rec: Ast.Record);
	VAR v: Ast.Declaration; needConstructor: BOOLEAN;

		PROCEDURE Constructor(VAR g: Generator; rec: Ast.Record);
		BEGIN
			Ln(g);
			Str(g, "public ");
			GlobalName(g, rec);
			StrOpen(g, "() {");

			InitAllVarsWhichArrayOfRecord(g, rec.vars);

			StrLnClose(g, "}")
		END Constructor;
	BEGIN
		rec.module := g.module.bag;
		Str(g, "static class ");
		IF CheckStructName(g, rec) THEN
			GlobalName(g, rec)
		END;
		IF rec.base # NIL THEN
			Str(g, " extends ");
			GlobalName(g, rec.base)
		END;
		v := rec.vars;
		IF v = NIL THEN
			StrLn(g, " { }")
		ELSE
			StrOpen(g, " {");
			needConstructor := FALSE;
			WHILE v # NIL DO
				EmptyLines(g, v);

				pvar(g, NIL, v, TRUE);

				needConstructor := needConstructor
				                OR (v.type.id IN {Ast.IdArray});
				v := v.next
			END;
			IF needConstructor THEN
				Constructor(g, rec)
			END;
			IF rec.inAssign THEN
				RecordAssign(g, rec)
			END;
			StrLnClose(g, "}")
		END
	END Record;

	PROCEDURE Array(VAR g: Generator; decl: Ast.Declaration; arr: Ast.Array;
	                sameType: BOOLEAN);
	BEGIN
		Type(g, decl, arr.type, FALSE, sameType);
		Str(g, "[]")
	END Array;
BEGIN
	IF typ = NIL THEN
		Str(g, "Object ")
	ELSE
		IF ~typeDecl & Strings.IsDefined(typ.name) & (typ.id # Ast.IdArray) THEN
			IF ~sameType THEN
				IF typ.id IN Ast.ProcTypes THEN
					ProcTypeName(g, typ(Ast.ProcType))
				ELSIF (typ.id = Ast.IdPointer) & Strings.IsDefined(typ.type.name) THEN
					GlobalName(g, typ.type)
				ELSE
					IF typ.id = Ast.IdRecord THEN
						ASSERT(CheckStructName(g, typ(Ast.Record)))
					END;
					GlobalName(g, typ)
				END
			END
		ELSIF ~sameType THEN
			CASE typ.id OF
			  Ast.IdInteger, Ast.IdSet:
				Str(g, "int")
			| Ast.IdLongInt, Ast.IdLongSet:
				Str(g, "long")
			| Ast.IdBoolean:
				IF g.opt.varInit # GenOptions.VarInitUndefined
				THEN	Str(g, "boolean")
				ELSE	Str(g, "byte")
				END
			| Ast.IdByte, Ast.IdChar:
				Str(g, "byte")
			| Ast.IdReal:
				Str(g, "double")
			| Ast.IdReal32:
				Str(g, "float")
			| Ast.IdPointer:
				Type(g, decl, typ.type, FALSE, sameType)
			| Ast.IdArray:
				Array(g, decl, typ(Ast.Array), sameType)
			| Ast.IdRecord:
				Record(g, typ(Ast.Record))
			| Ast.IdProcType, Ast.IdFuncType:
				(* TODO *)
				ASSERT(~typeDecl);
				ProcTypeName(g, typ(Ast.ProcType))
			END
		END
	END
END Type;

PROCEDURE Mark(VAR g: Generator; mark: BOOLEAN);
BEGIN
	IF g.localDeep = 0 THEN
		IF mark & ~g.opt.main THEN
			Str(g, "public ")
		ELSE
			Str(g, "private ")
		END
	END
END Mark;

PROCEDURE TypeDecl(VAR g: Generator; typ: Ast.Type);

	PROCEDURE Typedef(VAR g: Generator; typ: Ast.Type);
	BEGIN
		EmptyLines(g, typ);
		(* TODO *)
		IF typ.mark THEN
			Mark(g, typ.mark)
		END;
		Declarator(g, typ, TRUE, FALSE, TRUE)
	END Typedef;

BEGIN
	IF ~(typ.id IN (Ast.ProcTypes + {Ast.IdArray}))
	 & ((typ.id # Ast.IdPointer) OR ~Strings.IsDefined(typ.type.name))
	THEN
		Typedef(g, typ);
		IF (typ.id = Ast.IdRecord)
		OR (typ.id = Ast.IdPointer) & (typ.type.next = NIL)
		THEN
			IF typ.id = Ast.IdPointer THEN
				typ := typ.type
			END;
			typ.mark := typ.mark
			         OR (typ(Ast.Record).pointer # NIL)
			          & (typ(Ast.Record).pointer.mark);
			IF g.opt.varInit = GenOptions.VarInitUndefined THEN
				RecordUndef(g, typ(Ast.Record))
			END
		END
	END
END TypeDecl;

PROCEDURE Comment(VAR g: Generator; com: Strings.String);
BEGIN
	GenCommon.CommentC(g, g.opt^, com)
END Comment;

PROCEDURE Const(VAR g: Generator; const: Ast.Const; inModule: BOOLEAN);
VAR value: Ast.Factor;
BEGIN
	Comment(g, const.comment);
	EmptyLines(g, const);
	Mark(g, const.mark);
	IF inModule THEN
		Str(g, "static final ")
	ELSE
		Str(g, "final ")
	END;
	value := const.expr.value;
	IF (value.id = Ast.IdString) & (value(Ast.ExprString).asChar) THEN
		Str(g, "byte ");
		GlobalName(g, const);
		Str(g, " = (byte)");
		Int(g, value(Ast.ExprString).int)
	ELSE
		Type(g, NIL, const.type, FALSE, FALSE);
		Str(g, " ");
		GlobalName(g, const);
		Str(g, " = ");
		Expression(g, const.expr, {})
	END;
	StrLn(g, ";")
END Const;

PROCEDURE Var(VAR g: Generator; prev, var: Ast.Declaration; last: BOOLEAN);
VAR same, mark: BOOLEAN;
BEGIN
	mark := var.mark & ~g.opt.main;
	Comment(g, var.comment);
	EmptyLines(g, var);
	same := (prev # NIL) & (prev.mark = mark) & (prev.type = var.type);
	IF ~same THEN
		IF prev # NIL THEN
			StrLn(g, ";")
		END;
		IF var.up # NIL THEN
			Mark(g, mark);
			IF var.up.d.id = Ast.IdModule THEN
				Str(g, "static ")
			END
		END;
	ELSE
		Chr(g, ",")
	END;
	Declarator(g, var, FALSE, same, TRUE);

	VarInit(g, var, FALSE);

	IF last THEN
		StrLn(g, ";")
	END
END Var;

PROCEDURE ExprThenStats(VAR g: Generator; VAR wi: Ast.WhileIf);
VAR ignore: BOOLEAN;
BEGIN
	CheckExpr(g, wi.expr, {});
	StrOpen(g, ") {");
	ignore := statements(g, wi.stats);
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
	VAR ignore: BOOLEAN;

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
				ignore := statements(g, wi.stats)
			END;
			StrLnClose(g, "}")
		ELSIF wi.elsif = NIL THEN
			Str(g, "while (");
			ExprThenStats(g, wi);
			StrLnClose(g, "}")
		ELSE
			Str(g, "while (true) if (");
			ExprThenStats(g, wi);
			Elsif(g, wi);
			StrLnClose(g, "} else break;")
		END
	END WhileIf;

	PROCEDURE Repeat(VAR g: Generator; st: Ast.Repeat);
	VAR e: Ast.Expression; ignore: BOOLEAN;
	BEGIN
		StrOpen(g, "do {");
		ignore := statements(g, st.stats);
		IF st.expr.id = Ast.IdNegate THEN
			Text.StrClose(g, "} while (");
			e := st.expr(Ast.ExprNegate).expr;
			WHILE e.id = Ast.IdBraces DO
				e := e(Ast.ExprBraces).expr
			END;
			Expression(g, e, {});
			StrLn(g, ");")
		ELSE
			Text.StrClose(g, "} while (!(");
			CheckExpr(g, st.expr, {});
			StrLn(g, "));")
		END
	END Repeat;

	PROCEDURE For(VAR g: Generator; st: Ast.For);
	VAR ignore: BOOLEAN;
		PROCEDURE IsEndMinus1(sum: Ast.ExprSum): BOOLEAN;
		RETURN (sum.next # NIL)
		     & (sum.next.next = NIL)
		     & (sum.next.add = Ast.Minus)
		     & (sum.next.term.value # NIL)
		     & (sum.next.term.value(Ast.ExprInteger).int = 1)
		END IsEndMinus1;
	BEGIN
		Str(g, "for (");
		GlobalName(g, st.var);
		ExpressionBraced(g, " = ", st.expr, "; ", {});
		GlobalName(g, st.var);
		IF st.by > 0 THEN
			IF (st.to IS Ast.ExprSum) & IsEndMinus1(st.to(Ast.ExprSum)) THEN
				Str(g, " < ");
				Expression(g, st.to(Ast.ExprSum).term, {})
			ELSE
				Str(g, " <= ");
				Expression(g, st.to, {})
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
			Expression(g, st.to, {});
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
		ignore := statements(g, st.stats);
		StrLnClose(g, "}")
	END For;

	PROCEDURE Assign(VAR g: Generator; st: Ast.Assign);
	VAR toByte: BOOLEAN;
	BEGIN
		IF (st.designator.type.id # Ast.IdRecord)
		OR IsRecordNeedAssign(st.designator.type(Ast.Record))
		THEN
			toByte := (st.designator.type.id = Ast.IdByte)
			        & (st.expr.type.id IN {Ast.IdInteger, Ast.IdLongInt});
			g.expectArray := st.designator.type.id = Ast.IdArray;
			IF g.expectArray THEN
				IF Ast.IsString(st.expr) THEN
					Str(g, "O7.strcpy(")
				ELSE
					Str(g, "O7.copy(")
				END;
				Designator(g, st.designator, {ForSameType});
				Str(g, ", ")
			ELSIF st.designator.type.id = Ast.IdRecord THEN
				Designator(g, st.designator, {ForSameType});
				Str(g, ".assign(")
			ELSIF toByte THEN
				Designator(g, st.designator, {ForSameType});
				Str(g, " = O7.toByte(")
			ELSE
				Designator(g, st.designator, {ForSameType});
				Str(g, " = ")
			END;
			CheckExpr(g, st.expr, IsForSameType(st.designator.type, st.expr.type));
			g.expectArray := FALSE;
			CASE ORD(toByte)
			   + ORD(st.designator.type.id IN {Ast.IdArray, Ast.IdRecord})
			OF
			  0: StrLn(g, ";")
			| 1: StrLn(g, ");")
			| 2: StrLn(g, "));")
			END
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
					Str(g, "case ");
					Int(g, r.value);
					ASSERT(r.right = NIL);
					StrLn(g, ":");

					r := r.next
				END;
				Text.IndentOpen(g);
				IF statements(g, elem.stats) THEN
					StrLn(g, "break;")
				END;
				Text.IndentClose(g)
			END
		END CaseElement;

		PROCEDURE CaseElementAsIf(VAR g: Generator; elem: Ast.CaseElement;
		                          caseExpr: Ast.Expression);
		VAR r: Ast.CaseLabel; ignore: BOOLEAN;

			PROCEDURE CaseRange(VAR g: Generator; r: Ast.CaseLabel;
			                    caseExpr: Ast.Expression);
			BEGIN
				IF r.right = NIL THEN
					IF caseExpr = NIL THEN
						Str(g, "(o7_case_expr == ")
					ELSE
						ExpressionBraced(g, "(", caseExpr, " == ", {})
					END;
					Int(g, r.value)
				ELSE
					ASSERT(r.value <= r.right.value);
					Chr(g, "(");
					Int(g, r.value);
					IF caseExpr = NIL THEN
						Str(g, " <= o7_case_expr && o7_case_expr <= ")
					ELSE
						ExpressionBraced(g, " <= ", caseExpr, " && ", {});
						Expression(g, caseExpr, {});
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
			ignore := statements(g, elem.stats);
			Text.StrClose(g, "}")
		END CaseElementAsIf;
	BEGIN
		elemWithRange := st.elements;
		WHILE (elemWithRange # NIL) & ~IsCaseElementWithRange(elemWithRange) DO
			elemWithRange := elemWithRange.next
		END;
		IF (elemWithRange # NIL)
		 & (st.expr.value = NIL)
		 & ((st.expr.id # Ast.IdDesignator) OR (st.expr(Ast.Designator).sel # NIL))
		THEN
			caseExpr := NIL;
			Str(g, "{ int o7_case_expr = ");
			Expression(g, st.expr, {});
			StrOpen(g, ";");
			StrLn(g, "switch (o7_case_expr) {")
		ELSE
			caseExpr := st.expr;
			Str(g, "switch (");
			Expression(g, caseExpr, {});
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
				StrLn(g, " else throw O7.caseFail(o7_case_expr);")
			ELSE
				Str(g, " else O7.caseFail(");
				Expression(g, caseExpr, {});
				StrLn(g, ");")
			END
		ELSIF ~g.opt.caseAbort & (g.opt.varInit # GenOptions.VarInitNo) THEN
			StrLn(g, "break;")
		ELSIF caseExpr = NIL THEN
			StrLn(g, "throw O7.caseFail(o7_case_expr);")
		ELSE
			Str(g, "throw O7.caseFail(");
			Expression(g, caseExpr, {});
			StrLn(g, ");")
		END;
		StrLnClose(g, "}");
		IF caseExpr = NIL THEN
			StrLnClose(g, "}")
		END
	END Case;

	PROCEDURE CaseRecord(VAR g: Generator; st: Ast.Case);
	VAR elem: Ast.CaseElement; decl, guard: Ast.Declaration; save: Ast.Type; ignore, ptr: BOOLEAN;
	BEGIN
		decl := st.expr(Ast.Designator).decl;
		ptr := st.expr.type.id = Ast.IdPointer;
		elem := st.elements;
		REPEAT
			guard := elem.labels.qual;
			IF ptr THEN
				guard := guard.type
			END;
			Str(g, "if (");
			GlobalName(g, decl);
			Str(g, " instanceof ");
			GlobalName(g, guard);
			StrOpen(g, ") {");
			GlobalName(g, guard);
			Str(g, " ");
			GlobalName(g, decl);
			Str(g, "__ = (");
			GlobalName(g, guard);
			Str(g, ")");
			GlobalName(g, decl);
			StrLn(g, ";");

			g.guardDecl := decl;
			save := decl.type;
			decl.type := elem.labels.qual(Ast.Type);
			ignore := statements(g, elem.stats);
			decl.type := save;
			g.guardDecl := NIL;

			Text.IndentClose(g);
			Str(g, "} else ");

			elem := elem.next
		UNTIL elem = NIL;
		StrLn(g, "throw O7.caseFail(0);")
	END CaseRecord;
BEGIN
	Comment(g, st.comment);
	IF 0 < st.emptyLines THEN
		Ln(g)
	END;
	IF st IS Ast.Assign THEN
		Assign(g, st(Ast.Assign))
	ELSIF st IS Ast.Call THEN
		Expression(g, st.expr, {});
		StrLn(g, ";")
	ELSIF st IS Ast.WhileIf THEN
		WhileIf(g, st(Ast.WhileIf))
	ELSIF st IS Ast.Repeat THEN
		Repeat(g, st(Ast.Repeat))
	ELSIF st IS Ast.For THEN
		For(g, st(Ast.For))
	ELSE ASSERT(st IS Ast.Case);
		IF st.expr.type.id IN {Ast.IdRecord, Ast.IdPointer} THEN
			CaseRecord(g, st(Ast.Case))
		ELSE
			Case(g, st(Ast.Case))
		END
	END
END Statement;

PROCEDURE Statements(VAR g: Generator; stats: Ast.Statement): BOOLEAN;
VAR continue: BOOLEAN;
BEGIN
	WHILE (stats # NIL) & ~g.unreached DO
		Statement(g, stats);
		stats := stats.next
	END;
	continue := ~g.unreached;
	g.unreached := FALSE
	RETURN continue
END Statements;

PROCEDURE ProcHeader(VAR g: Generator; decl: Ast.Procedure);
BEGIN
	IF decl.header.type = NIL THEN
		Str(g, "void ")
	ELSE
		Type(g, decl, decl.header.type, FALSE, FALSE);
		Chr(g, " ");
	END;
	Name(g, decl);
	ProcParams(g, decl.header)
END ProcHeader;

PROCEDURE Procedure(VAR g: Generator; proc: Ast.Procedure);

	PROCEDURE Implement(VAR g: Generator; proc: Ast.Procedure);
	BEGIN
		Comment(g, proc.comment);
		Mark(g, proc.mark);
		Str(g, "static ");

		ProcHeader(g, proc);
		StrOpen(g, " {");

		INC(g.localDeep);

		g.fixedLen := g.len;

		declarations(g, proc);

		InitAllVarsWhichArrayOfRecord(g, proc.vars);

		IF Statements(g, proc.stats) & (proc.return # NIL) THEN
			Str(g, "return ");
			CheckExpr(g, proc.return,
			          IsForSameType(proc.header.type, proc.return.type));
			StrLn(g, ";")
		END;

		DEC(g.localDeep);
		StrLnClose(g, "}");
		Ln(g)
	END Implement;

	PROCEDURE LocalProcs(VAR g: Generator; proc: Ast.Procedure);
	VAR p, t: Ast.Declaration;
	BEGIN
		t := proc.types;
		WHILE (t # NIL) & (t IS Ast.Type) DO
			TypeDecl(g, t(Ast.Type));
			t := t.next
		END;
		p := proc.procedures;
		IF p # NIL THEN
			REPEAT
				Procedure(g, p(Ast.Procedure));
				p := p.next
			UNTIL p = NIL
		END
	END LocalProcs;

	PROCEDURE Reference(VAR g: Generator; proc: Ast.Procedure);
	VAR name: Strings.String;

		PROCEDURE Body(VAR g: Generator; proc: Ast.Procedure);
		VAR fp: Ast.Declaration;
		BEGIN
			StrOpen(g, " {");
			IF proc.header.type # NIL THEN
				Str(g, "return ")
			END;
			Name(g, proc);
			fp := proc.header.params;
			Chr(g, "(");
			IF fp # NIL THEN
				Name(g, fp);
				WHILE fp.next # NIL DO
					fp := fp.next;
					Str(g, ", ");
					Name(g, fp)
				END
			END;
			StrLn(g, ");");
			StrLnClose(g, "}")
		END Body;
	BEGIN
		Mark(g, proc.mark);
		Str(g, "static final ");
		ProcTypeNameGenAndArray(g, name, proc.header);
		Chr(g, " ");
		Name(g, proc);
		Str(g, "_proc = new ");
		Text.String(g, name);
		StrOpen(g, "() {");
		IF proc.header.type = NIL THEN
			Str(g, "public void")
		ELSE
			Str(g, "public ");
			Type(g, proc, proc.header.type, FALSE, FALSE)
		END;
		Str(g, " run");
		ProcParams(g, proc.header);
		Body(g, proc);

		StrLnClose(g, "};");
		Ln(g)
	END Reference;
BEGIN
	LocalProcs(g, proc);
	Implement(g, proc);
	IF proc.usedAsValue THEN
		Reference(g, proc)
	END
END Procedure;

PROCEDURE LnIfWrote(VAR g: Generator);
BEGIN
	IF g.fixedLen # g.len THEN
		Ln(g);
		g.fixedLen := g.len
	END
END LnIfWrote;

PROCEDURE Declarations(VAR g: Generator; ds: Ast.Declarations);
VAR d, prev: Ast.Declaration; inModule: BOOLEAN;
BEGIN
	inModule := ds IS Ast.Module;

	d := ds.start;

	WHILE (d # NIL) & (d.id = Ast.IdImport) DO
		d := d.next
	END;

	WHILE (d # NIL) & (d.id = Ast.IdConst) DO
		Const(g, d(Ast.Const), inModule);
		d := d.next
	END;
	LnIfWrote(g);

	IF inModule THEN
		WHILE (d # NIL) & (d IS Ast.Type) DO
			TypeDecl(g, d(Ast.Type));
			d := d.next
		END;
		LnIfWrote(g);

		WHILE (d # NIL) & (d.id = Ast.IdVar) DO
			Var(g, NIL, d, TRUE);
			d := d.next
		END
	ELSE
		d := ds.vars;

		prev := NIL;
		WHILE (d # NIL) & (d.id = Ast.IdVar) DO
			Var(g, prev, d, (d.next = NIL) OR (d.next.id # Ast.IdVar));
			prev := d;
			d := d.next
		END;

		d := ds.procedures
	END;
	LnIfWrote(g);

	IF inModule THEN
		WHILE d # NIL DO
			Procedure(g, d(Ast.Procedure));
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
		o.varInit    := GenOptions.VarInitZero;
		o.checkArith := TRUE & FALSE
	END
	RETURN o
END DefaultOptions;

PROCEDURE Imports(VAR g: Generator; m: Ast.Module);
VAR d: Ast.Declaration;

	PROCEDURE Import(VAR g: Generator; decl: Ast.Declaration);
	VAR name: Strings.String;
	BEGIN
		Str(g, "import o7.");
		name := decl.module.m.name;
		Text.String(g, name);
		IF SpecIdentChecker.IsSpecModuleName(name) THEN
			StrLn(g, "_;")
		ELSE
			StrLn(g, ";")
		END
	END Import;
BEGIN
	d := m.import;
	WHILE (d # NIL) & (d.id = Ast.IdImport) DO
		IF ~d.module.m.spec THEN
			Import(g, d)
		END;
		d := d.next
	END;
	Ln(g)
END Imports;

PROCEDURE ProviderProcTypeNameInit*(p: ProviderProcTypeName;
                                    g: ProvideProcTypeName);
BEGIN
	V.Init(p^);
	p.g := g
END ProviderProcTypeNameInit;

PROCEDURE Generate*(out: Stream.POut;
                    module: Ast.Module; cmd: Ast.Statement;
                    provider: ProviderProcTypeName; opt: Options);
VAR g: Generator;

	PROCEDURE ModuleInit(VAR g: Generator; module: Ast.Module; cmd: Ast.Statement);
	VAR v: Ast.Declaration; ignore: BOOLEAN;
	BEGIN
		v := SearchArrayOfRecord(module.vars);
		IF (module.stats # NIL) OR (cmd # NIL) OR (v # NIL) THEN
			StrOpen(g, "static {");
			InitAllVarsWhichArrayOfRecord(g, v);
			ignore := Statements(g, module.stats)
			        & Statements(g, cmd);
			StrLnClose(g, "}");
			Ln(g)
		END
	END ModuleInit;

	PROCEDURE Main(VAR g: Generator; module: Ast.Module; cmd: Ast.Statement);
	VAR ignore: BOOLEAN;
	BEGIN
		StrOpen(g, "public static void main(java.lang.String[] argv) {");
		StrLn(g, "O7.init(argv);");
		InitAllVarsWhichArrayOfRecord(g, module.vars);
		ignore := Statements(g, module.stats)
		        & Statements(g, cmd);
		StrLn(g, "O7.exit();");
		StrLnClose(g, "}")
	END Main;
BEGIN
	ASSERT(~Ast.HasError(module));

	IF opt = NIL THEN
		opt := DefaultOptions()
	END;

	opt.index := 0;
	opt.main := (cmd # NIL) OR Strings.IsEqualToString(module.name, "script");

	GenInit(g, out, module, provider, opt);
	GeneratorNotify(g);

	Comment(g, module.comment);

	StrLn(g, "package o7;");
	Ln(g);
	StrLn(g, "import o7.O7;");
	Imports(g, module);

	Str(g, "public final class ");
	Name(g, module);
	IF SpecIdentChecker.IsSpecModuleName(module.name) & ~module.spec THEN
		Chr(g, "_")
	END;
	StrLn(g, " {");
	Ln(g);

	Declarations(g, module);

	IF opt.main THEN
		Main(g, module, cmd)
	ELSE
		ModuleInit(g, module, cmd)
	END;

	StrLn(g, "}")
END Generate;

BEGIN
	type         := Type;
	declarations := Declarations;
	statements   := Statements;
	expression   := Expression;
	pvar         := Var
END GeneratorJava.

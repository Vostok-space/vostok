(*  Parser of Oberon-07 modules
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
MODULE Parser;

IMPORT
	V,
	Log,
	Utf8,
	Scanner,
	SpecIdent := OberonSpecIdent,
	Strings := StringStore,
	Ast,
	Stream := VDataStream,
	TranLim := TranslatorLimits;

CONST
	ErrNo = 0;
	Err = Scanner.ErrMin;

	ErrExpectModule*                = Err - 01;
	ErrExpectIdent*                 = Err - 02;
	ErrExpectColon*                 = Err - 03;
	ErrExpectSemicolon*             = Err - 04;
	ErrExpectEnd*                   = Err - 05;
	ErrExpectDot*                   = Err - 06;
	ErrExpectModuleName*            = Err - 07;
	ErrExpectEqual*                 = Err - 08;
	ErrExpectBrace1Open*            = Err - 09;
	ErrExpectBrace1Close*           = Err - 10;
	ErrExpectBrace2Open*            = Err - 11;
	ErrExpectBrace2Close*           = Err - 12;
	ErrExpectBrace3Open*            = Err - 13;
	ErrExpectBrace3Close*           = Err - 14;

	ErrExpectOf*                    = Err - 15;
	ErrExpectTo*                    = Err - 16;
	ErrExpectStructuredType*        = Err - 17;
	ErrExpectRecord*                = Err - 18;
	ErrExpectStatement*             = Err - 19;
	ErrExpectThen*                  = Err - 20;
	ErrExpectAssign*                = Err - 21;
	ErrExpectVarRecordOrPointer*    = Err - 22;
	ErrExpectType*                  = Err - 24;
	ErrExpectUntil*                 = Err - 25;
	ErrExpectDo*                    = Err - 26;
	ErrExpectDesignator*            = Err - 28;
	ErrExpectProcedure*             = Err - 30;
	ErrExpectConstName*             = Err - 31;
	ErrExpectProcedureName*         = Err - 32;
	ErrExpectExpression*            = Err - 33;
	ErrExpectIntOrStrOrQualident*   = Err - 34;
	ErrExcessSemicolon*             = Err - 35;
	ErrMaybeAssignInsteadEqual*     = Err - 36;
	ErrUnexpectStringInCaseLabel*   = Err - 37;

	ErrEndModuleNameNotMatch*       = Err - 50;
	ErrExpectAnotherModuleName*     = Err - 51;
	ErrArrayDimensionsTooMany*      = Err - 52;
	ErrEndProcedureNameNotMatch*    = Err - 53;
	ErrFunctionWithoutBraces*       = Err - 54;

	ErrAstBegin* = Err - 100;
	ErrAstEnd* = ErrAstBegin + Ast.ErrMin;

	ErrMin* = ErrAstEnd;

TYPE
	PrintError* = PROCEDURE(code: INTEGER);
	Options* = RECORD(V.Base)
		strictSemicolon*,
		strictReturn*,
		saveComments*,
		multiErrors*,
		cyrillic*       : BOOLEAN;
		printError*: PrintError;

		provider*: Ast.Provider
	END;
	Parser = RECORD(V.Base) (* короткие названия из-за частого использования *)
		opt: Options;
		err: BOOLEAN;
		errorsCount: INTEGER;
		callId: INTEGER;
		s: Scanner.Scanner;
		l: INTEGER;(* lexem *)

		comment: RECORD
			ofs, end: INTEGER
		END;

		inLoops: INTEGER;

		module: Ast.Module
	END;

VAR
	declarations: PROCEDURE(VAR p: Parser; ds: Ast.Declarations);
	type: PROCEDURE(VAR p: Parser; ds: Ast.Declarations;
	                nameBegin, nameEnd: INTEGER): Ast.Type;
	statements: PROCEDURE(VAR p: Parser; ds: Ast.Declarations): Ast.Statement;
	expression: PROCEDURE(VAR p: Parser; ds: Ast.Declarations; varParm: BOOLEAN): Ast.Expression;

PROCEDURE AddError(VAR p: Parser; err: INTEGER);
BEGIN
	IF p.module # NIL THEN
		Log.Str("AddError "); Log.Int(err); Log.Str(" at ");
		Log.Int(p.s.line); Log.Str(":");
		Log.Int(p.s.column); Log.Ln;
		p.err := err > ErrAstBegin;

		INC(p.errorsCount);
		Ast.AddError(p.module, err, p.s.line, p.s.column);
		ASSERT(p.module.errors # NIL)
	END;
	IF p.opt.multiErrors THEN
		p.opt.printError(err);
		Log.Str(". ");
		Log.Int(p.s.line + 1);
		Log.Str(":");
		Log.Int(p.s.column);
		Log.Ln
	END
END AddError;

PROCEDURE CheckAst(VAR p: Parser; err: INTEGER);
BEGIN
	IF err # Ast.ErrNo THEN
		ASSERT((Ast.ErrMin <= err) & (err < ErrNo));
		AddError(p, ErrAstBegin + err)
	END
END CheckAst;

PROCEDURE Scan(VAR p: Parser);
VAR si: INTEGER;
BEGIN
	IF (p.errorsCount = 0) OR p.opt.multiErrors THEN
		p.l := Scanner.Next(p.s);
		IF p.l = Scanner.Ident THEN
			IF SpecIdent.IsKeyWord(si, p.s.buf, p.s.lexStart, p.s.lexEnd) THEN
				CASE si OF
				  SpecIdent.Div: p.l := Scanner.Div
				| SpecIdent.In:  p.l := Scanner.In
				| SpecIdent.Is:  p.l := Scanner.Is
				| SpecIdent.Mod: p.l := Scanner.Mod
				| SpecIdent.Or:  p.l := Scanner.Or

				| SpecIdent.Array   .. SpecIdent.Const
				, SpecIdent.Do      .. SpecIdent.Import
				, SpecIdent.Module  .. SpecIdent.Of
				, SpecIdent.Pointer .. SpecIdent.While:
					p.l := si
				END
			END
		ELSIF p.l = Scanner.Semicolon THEN
			Scanner.ResetComment(p.s)
		ELSIF p.l < ErrNo THEN
			AddError(p, p.l);
			IF p.l = Scanner.ErrNumberTooBig THEN
				p.l := Scanner.Number
			END
		END
	ELSE
		p.l := Scanner.EndOfFile
	END
END Scan;

PROCEDURE Expect(VAR p: Parser; expect, error: INTEGER);
BEGIN
	IF p.l = expect THEN
		Scan(p)
	ELSE
		AddError(p, error)
	END
END Expect;

PROCEDURE ScanIfEqual(VAR p: Parser; lex: INTEGER): BOOLEAN;
BEGIN
	IF p.l = lex THEN
		Scan(p);
		lex := p.l
	END
	RETURN p.l = lex
END ScanIfEqual;

PROCEDURE ExpectIdent(VAR p: Parser; VAR begin, end: INTEGER; error: INTEGER);
BEGIN
	IF p.l = Scanner.Ident THEN
		begin := p.s.lexStart;
		end := p.s.lexEnd;
		Scan(p)
	ELSE (* p.l > ErrNo THEN *)
		AddError(p, error);
		begin := -1;
		end := -1
	END
END ExpectIdent;

PROCEDURE Set(VAR p: Parser; ds: Ast.Declarations): Ast.ExprSet;
VAR e, next: Ast.ExprSet;
	err: INTEGER;

	PROCEDURE Element(VAR base, e: Ast.ExprSet; VAR p: Parser; ds: Ast.Declarations)
	                 : INTEGER;
	VAR left: Ast.Expression;
		err: INTEGER;
	BEGIN
		left := expression(p, ds, FALSE);
		IF p.l = Scanner.Range THEN
			Scan(p);
			err := Ast.ExprSetNew(base, e, left, expression(p, ds, FALSE))
		ELSE
			err := Ast.ExprSetNew(base, e, left, NIL)
		END
		RETURN err
	END Element;
BEGIN
	ASSERT(p.l = Scanner.Brace3Open);
	Scan(p);
	IF p.l # Scanner.Brace3Close THEN
		e := NIL;
		err := Element(e, e, p, ds);
		CheckAst(p, err);
		next := e;
		WHILE ScanIfEqual(p, Scanner.Comma) DO
			err := Element(e, next.next, p, ds);
			CheckAst(p, err);

			next := next.next
		END;
		Expect(p, Scanner.Brace3Close, ErrExpectBrace3Close)
	ELSE (* Пустое множество *)
		CheckAst(p, Ast.ExprSetNew(e, e, NIL, NIL));
		Scan(p)
	END
	RETURN e
END Set;

PROCEDURE DeclarationGet(ds: Ast.Declarations; VAR p: Parser): Ast.Declaration;
VAR d: Ast.Declaration;
BEGIN
	Log.StrLn("DeclarationGet");
	CheckAst(p, Ast.DeclarationGet(d, p.opt.provider, ds, p.s.buf, p.s.lexStart, p.s.lexEnd))
	RETURN d
END DeclarationGet;

PROCEDURE ExpectDecl(VAR p: Parser; ds: Ast.Declarations): Ast.Declaration;
VAR d: Ast.Declaration;
BEGIN
	IF p.l # Scanner.Ident THEN
		d := Ast.DeclErrorNew(ds, p.s.buf, -1, -1);
		AddError(p, ErrExpectIdent)
	ELSE
		d := DeclarationGet(ds, p);
		Scan(p)
	END
	RETURN d
END ExpectDecl;

PROCEDURE Qualident(VAR p: Parser; ds: Ast.Declarations): Ast.Declaration;
VAR d: Ast.Declaration;
BEGIN
	Log.StrLn("Qualident");

	d := ExpectDecl(p, ds);
	IF d IS Ast.Import THEN
		Expect(p, Scanner.Dot, ErrExpectDot);
		d := ExpectDecl(p, d(Ast.Import).module.m)
	END
	RETURN d
END Qualident;

PROCEDURE ExpectRecordExtend(VAR p: Parser; ds: Ast.Declarations;
                             base: Ast.Construct): Ast.Declaration;
VAR d: Ast.Declaration;
BEGIN (*TODO*)
	d := Qualident(p, ds)
	RETURN d
END ExpectRecordExtend;

PROCEDURE Designator(VAR p: Parser; ds: Ast.Declarations): Ast.Designator;
VAR des: Ast.Designator;
	decl, var: Ast.Declaration;
	prev, sel: Ast.Selector;
	nameBegin, nameEnd, ind, val: INTEGER;
	str: Strings.String;

	PROCEDURE SetSel(VAR prev: Ast.Selector; sel: Ast.Selector;
	                 des: Ast.Designator);
	BEGIN
		IF prev = NIL THEN
			des.sel := sel
		ELSE
			prev.next := sel
		END;
		prev := sel
	END SetSel;
BEGIN
	Log.StrLn("Designator");

	ASSERT(p.l = Scanner.Ident);
	decl := Qualident(p, ds);
	CheckAst(p, Ast.DesignatorNew(des, decl));
	IF decl # NIL THEN
		IF (decl IS Ast.Var) OR (decl IS Ast.Const) THEN
			prev := NIL;

			REPEAT
				sel := NIL;
				IF p.l = Scanner.Dot THEN
					Scan(p);
					ExpectIdent(p, nameBegin, nameEnd, ErrExpectIdent);
					IF nameBegin >= 0 THEN
						CheckAst(p,
							Ast.SelRecordNew(sel, des.type,
							                 p.s.buf, nameBegin, nameEnd)
						)
					END
				ELSIF p.l = Scanner.Brace1Open THEN
					IF des.type.id IN {Ast.IdRecord, Ast.IdPointer} THEN
						Scan(p);
						var := ExpectRecordExtend(p, ds, des.type(Ast.Construct));
						CheckAst(p, Ast.SelGuardNew(sel, des, var));
						Expect(p, Scanner.Brace1Close, ErrExpectBrace1Close)
					ELSIF ~(des.type IS Ast.ProcType) THEN
						AddError(p, ErrExpectVarRecordOrPointer)
					END
				ELSIF p.l = Scanner.Brace2Open THEN
					Scan(p);
					CheckAst(p, Ast.SelArrayNew(sel, des.type, expression(p, ds, FALSE)));
					IF des.value = NIL THEN
						;
					ELSIF (des.value IS Ast.ExprString)
					    & (sel(Ast.SelArray).index.value # NIL)
					THEN
						val := des.value(Ast.ExprString).int;
						ind := sel(Ast.SelArray).index.value(Ast.ExprInteger).int;
						IF val < 0 THEN
							str := des.value(Ast.ExprString).string;
							val := ORD(Strings.GetChar(str, ind + 1))
						ELSE
							ASSERT(ind = 0)
						END;
						des.value := Ast.ExprCharNew(val)
					ELSE
						des.value := NIL
					END;
					WHILE ScanIfEqual(p, Scanner.Comma) DO
						SetSel(prev, sel, des);
						CheckAst(p, Ast.SelArrayNew(sel, des.type, expression(p, ds, FALSE)))
					END;
					Expect(p, Scanner.Brace2Close, ErrExpectBrace2Close)
				ELSIF p.l = Scanner.Dereference THEN
					CheckAst(p, Ast.SelPointerNew(sel, des.type));
					Scan(p)
				END;
				SetSel(prev, sel, des)
			UNTIL sel = NIL

		ELSIF ~((decl IS Ast.Const) OR (decl IS Ast.GeneralProcedure)
		     OR (decl.id = Ast.IdError)
		       )
		THEN
			AddError(p, ErrExpectDesignator)
		END
	END
	RETURN des
END Designator;

PROCEDURE CallParams(VAR p: Parser; ds: Ast.Declarations; e: Ast.ExprCall);
VAR par: Ast.Parameter;
    fp: Ast.FormalParam;
    varParam: BOOLEAN;
BEGIN
	ASSERT(p.l = Scanner.Brace1Open);
	Scan(p);
	IF (e.designator.type # NIL) & (e.designator.type IS Ast.ProcType) THEN
		fp := e.designator.type(Ast.ProcType).params
	ELSE
		fp := NIL
	END;
	IF ~ScanIfEqual(p, Scanner.Brace1Close) THEN
		par := NIL;
		(* TODO несовершенная логика *)
		varParam := (fp = NIL) OR (Ast.ParamOut IN fp.access)
		            & (   ~(e.designator.decl IS Ast.PredefinedProcedure)
		               OR (e.designator.decl.id = SpecIdent.New)
		              );
		p.callId := e.designator.decl.id;
		CheckAst(p, Ast.CallParamNew(e, par, expression(p, ds, varParam), fp));
		p.callId := 0;
		e.params := par;
		WHILE ScanIfEqual(p, Scanner.Comma) DO
			varParam := (fp = NIL) OR (Ast.ParamOut IN fp.access);
			CheckAst(p, Ast.CallParamNew(e, par, expression(p, ds, varParam), fp));
		END;
		Expect(p, Scanner.Brace1Close, ErrExpectBrace1Close)
	END;
	CheckAst(p, Ast.CallParamsEnd(e, fp, ds))
END CallParams;

PROCEDURE ExprCall(VAR p: Parser; ds: Ast.Declarations; des: Ast.Designator)
                  : Ast.ExprCall;
VAR e: Ast.ExprCall;
BEGIN
	CheckAst(p, Ast.ExprCallNew(e, des));
	CallParams(p, ds, e)
	RETURN e
END ExprCall;

PROCEDURE Factor(VAR p: Parser; ds: Ast.Declarations; varParam: BOOLEAN): Ast.Expression;
VAR e: Ast.Expression;

	PROCEDURE Ident(VAR p: Parser; ds: Ast.Declarations; varParam: BOOLEAN; VAR e: Ast.Expression);
	VAR des: Ast.Designator;
	BEGIN
		des := Designator(p, ds);
		IF p.callId # SpecIdent.Len THEN
			CheckAst(p, Ast.DesignatorUsed(des, varParam, 0 < p.inLoops))
		END;
		IF p.l # Scanner.Brace1Open THEN
			e := des
		ELSE
			e := ExprCall(p, ds, des)
		END
	END Ident;

	PROCEDURE Negate(VAR p: Parser; ds: Ast.Declarations): Ast.ExprNegate;
	VAR neg: Ast.ExprNegate;
	BEGIN
		ASSERT(p.l = Scanner.Negate);
		Scan(p);
		CheckAst(p, Ast.ExprNegateNew(neg, Factor(p, ds, FALSE)))
		RETURN neg
	END Negate;
BEGIN
	Log.StrLn("Factor");

	IF p.l = Scanner.Number THEN
		IF p.s.isReal THEN
			e := Ast.ExprRealNew(p.s.real, p.module,
			                     p.s.buf, p.s.lexStart, p.s.lexEnd)
		ELSE
			e := Ast.ExprIntegerNew(p.s.integer)
		END;
		Scan(p)
	ELSIF (p.l = SpecIdent.True) OR (p.l = SpecIdent.False) THEN
		e := Ast.ExprBooleanGet(p.l = SpecIdent.True);
		Scan(p)
	ELSIF p.l = SpecIdent.Nil THEN
		e := Ast.ExprNilGet();
		Scan(p)
	ELSIF p.l = Scanner.String THEN
		IF p.s.isChar THEN
			e := Ast.ExprCharNew(p.s.integer)
		ELSE
			e := Ast.ExprStringNew(p.module, p.s.buf, p.s.lexStart, p.s.lexEnd);
		END;
		Scan(p)
	ELSIF p.l = Scanner.Brace1Open THEN
		Scan(p);
		e := Ast.ExprBracesNew(expression(p, ds, FALSE));
		Expect(p, Scanner.Brace1Close, ErrExpectBrace1Close)
	ELSIF p.l = Scanner.Ident THEN
		Ident(p, ds, varParam, e)
	ELSIF p.l = Scanner.Brace3Open THEN
		e := Set(p, ds)
	ELSIF p.l = Scanner.Negate THEN
		e := Negate(p, ds)
	ELSE
		AddError(p, ErrExpectExpression);
		e := Ast.ExprErrNew()
	END
	RETURN e
END Factor;

PROCEDURE Term(VAR p: Parser; ds: Ast.Declarations; varParam: BOOLEAN): Ast.Expression;
VAR e: Ast.Expression;
	term: Ast.ExprTerm;
	l: INTEGER;
	turnIf: BOOLEAN;
BEGIN
	Log.StrLn("Term");
	e := Factor(p, ds, varParam);
	IF (Scanner.MultFirst <= p.l) & (p.l <= Scanner.MultLast) THEN
		l := p.l;

		turnIf := (l = Scanner.And);
		IF turnIf THEN
			Ast.TurnIf(ds)
		END;

		Scan(p);
		term := NIL;
		CheckAst(p, Ast.ExprTermNew(term, e(Ast.Factor), l, Factor(p, ds, FALSE)));
		ASSERT((term.expr # NIL) & (term.factor # NIL));
		e := term;
		WHILE (Scanner.MultFirst <= p.l) & (p.l <= Scanner.MultLast) DO
			l := p.l;
			Scan(p);
			CheckAst(p, Ast.ExprTermAdd(e, term, l, Factor(p, ds, FALSE)))
		END;

		IF turnIf THEN
			Ast.BackFromBranch(ds)
		END
	END
	RETURN e
END Term;

PROCEDURE Sum(VAR p: Parser; ds: Ast.Declarations; varParam: BOOLEAN): Ast.Expression;
VAR e: Ast.Expression;
	sum: Ast.ExprSum;
	l: INTEGER;
BEGIN
	Log.StrLn("Sum");
	l := p.l;

	IF l IN {Scanner.Plus, Scanner.Minus} THEN
		Scan(p);
		CheckAst(p, Ast.ExprSumNew(sum, l, Term(p, ds, FALSE)));
		e := sum
	ELSE
		e := Term(p, ds, varParam);
		IF p.l IN {Scanner.Plus, Scanner.Minus, Scanner.Or} THEN
			IF p.l # Scanner.Or THEN
				CheckAst(p, Ast.ExprSumNew(sum, -1, e))
			ELSE
				Ast.TurnIf(ds);
				CheckAst(p, Ast.ExprSumNew(sum, -1, e));
				(* TODO Выход в другом месте, но пока будет здесь *)
				Ast.BackFromBranch(ds)
			END;
			e := sum
		END
	END;
	WHILE p.l IN {Scanner.Plus, Scanner.Minus, Scanner.Or} DO
		l := p.l;
		Scan(p);
		IF l # Scanner.Or THEN
			CheckAst(p, Ast.ExprSumAdd(e, sum, l, Term(p, ds, FALSE)))
		ELSE
			Ast.TurnIf(ds);
			CheckAst(p, Ast.ExprSumAdd(e, sum, l, Term(p, ds, FALSE)));
			Ast.BackFromBranch(ds)
		END
	END
	RETURN e
END Sum;

PROCEDURE Expression(VAR p: Parser; ds: Ast.Declarations; varParam: BOOLEAN): Ast.Expression;
VAR expr: Ast.Expression;
	e: Ast.ExprRelation;
	isExt: Ast.ExprIsExtension;
	rel: INTEGER;
BEGIN
	expr := Sum(p, ds, varParam);
	IF (Scanner.RelationFirst <= p.l) & (p.l < Scanner.RelationLast) THEN
		rel := p.l;
		Scan(p);
		CheckAst(p, Ast.ExprRelationNew(e, expr, rel, Sum(p, ds, FALSE)));
		expr := e
	ELSIF ScanIfEqual(p, Scanner.Is) THEN
		CheckAst(p, Ast.ExprIsExtensionNew(isExt, expr, type(p, ds, -1, -1)));
		expr := isExt
	END
	RETURN expr
END Expression;

PROCEDURE DeclComment(VAR p: Parser; d: Ast.Declaration);
VAR comOfs, comEnd: INTEGER;
BEGIN
	IF p.opt.saveComments & Scanner.TakeCommentPos(p.s, comOfs, comEnd) THEN
		Ast.DeclSetComment(d, p.s.buf, comOfs, comEnd)
	END
END DeclComment;

PROCEDURE Mark(VAR p: Parser; d: Ast.Declaration);
BEGIN
	DeclComment(p, d);
	d.mark := ScanIfEqual(p, Scanner.Asterisk)
END Mark;

PROCEDURE Consts(VAR p: Parser; ds: Ast.Declarations);
VAR begin, end, emptyLines: INTEGER;
    const: Ast.Const;
BEGIN
	Scan(p);
	WHILE p.l = Scanner.Ident DO
		IF ~p.err THEN
			emptyLines := p.s.emptyLines;
			ExpectIdent(p, begin, end, ErrExpectConstName);
			CheckAst(p, Ast.ConstAdd(ds, p.s.buf, begin, end));
			const := ds.end(Ast.Const);
			const.emptyLines := emptyLines;
			Mark(p, const);
			Expect(p, Scanner.Equal, ErrExpectEqual);
			CheckAst(p, Ast.ConstSetExpression(const, Expression(p, ds, FALSE)));
			Expect(p, Scanner.Semicolon, ErrExpectSemicolon)
		END;
		IF p.err THEN
			WHILE (Scanner.EndOfFile < p.l)
			    & (p.l < SpecIdent.Import (* TODO *))
			    & (p.l # Scanner.Semicolon)
			DO
				Scan(p)
			END;
			p.err := FALSE
		END
	END
END Consts;

PROCEDURE Array(VAR p: Parser; ds: Ast.Declarations;
                nameBegin, nameEnd: INTEGER): Ast.Array;
VAR a: Ast.Array;
	t: Ast.Type;
	exprLen: Ast.Expression;
	lens: ARRAY TranLim.ArrayDimension OF Ast.Expression;
	i, size: INTEGER;
BEGIN
	Log.StrLn("Array");
	ASSERT(p.l = SpecIdent.Array);
	Scan(p);
	a := Ast.ArrayGet(NIL, Expression(p, ds, FALSE));
	IF nameBegin >= 0 THEN
		t := a;
		CheckAst(p, Ast.TypeAdd(ds, p.s.buf, nameBegin, nameEnd, t))
	END;
	size := 1;
	CheckAst(p, Ast.MultArrayLenByExpr(size, a.count));
	i := 0;
	WHILE ScanIfEqual(p, Scanner.Comma) DO
		exprLen := Expression(p, ds, FALSE);
		CheckAst(p, Ast.MultArrayLenByExpr(size, exprLen));
		IF i < LEN(lens) THEN
			lens[i] := exprLen
		END;
		INC(i)
	END;
	IF LEN(lens) < i THEN
		AddError(p, ErrArrayDimensionsTooMany)
	END;
	Expect(p, SpecIdent.Of, ErrExpectOf);
	CheckAst(p, Ast.ArraySetType(a, type(p, ds, -1, -1)));
	WHILE 0 < i DO
		DEC(i);
		(* TODO сделать нормально *)
		a.type := Ast.ArrayGet(a.type, lens[i])
	END
	RETURN a
END Array;

PROCEDURE TypeNamed(VAR p: Parser; ds: Ast.Declarations): Ast.Type;
VAR d: Ast.Declaration;
	t: Ast.Type;
BEGIN
	t := NIL;
	d := Qualident(p, ds);
	IF d # NIL THEN
		IF d IS Ast.Type THEN
			t := d(Ast.Type)
		ELSIF d.id # Ast.IdError THEN
			AddError(p, ErrExpectType)
		END
	END;
	IF t = NIL THEN
		t := Ast.TypeErrorNew()
	END
	RETURN t
END TypeNamed;

PROCEDURE VarDeclaration(VAR p: Parser; dsAdd, dsTypes: Ast.Declarations);
VAR var: Ast.Declaration;
	typ: Ast.Type;

	PROCEDURE Name(VAR p: Parser; ds: Ast.Declarations);
	VAR begin, end, emptyLines: INTEGER; v: Ast.Var;
	BEGIN
		emptyLines := p.s.emptyLines;
		ExpectIdent(p, begin, end, ErrExpectIdent);
		CheckAst(p, Ast.VarAdd(v, ds, p.s.buf, begin, end));
		v.emptyLines := emptyLines;
		DeclComment(p, v);
		Mark(p, v)
	END Name;
BEGIN
	Name(p, dsAdd);
	var := dsAdd.end(Ast.Var);
	WHILE ScanIfEqual(p, Scanner.Comma) DO
		Name(p, dsAdd)
	END;
	Expect(p, Scanner.Colon, ErrExpectColon);
	typ := type(p, dsTypes, -1, -1);
	WHILE var # NIL DO
		var.type := typ;
		var := var.next
	END;
	CheckAst(p, Ast.CheckUndefRecordForward(dsAdd))
END VarDeclaration;

PROCEDURE Vars(VAR p: Parser; ds: Ast.Declarations);
BEGIN
	WHILE p.l = Scanner.Ident DO
		VarDeclaration(p, ds, ds);
		Expect(p, Scanner.Semicolon, ErrExpectSemicolon)
	END
END Vars;

PROCEDURE Record(VAR p: Parser; ds: Ast.Declarations; ptr: Ast.Pointer;
                 nameBegin, nameEnd: INTEGER): Ast.Record;
VAR rec, base: Ast.Record;
	t: Ast.Type;
	decl: Ast.Declaration;

	PROCEDURE RecVars(VAR p: Parser; dsAdd: Ast.Record; dsTypes: Ast.Declarations);

		PROCEDURE Declaration(VAR p: Parser; dsAdd: Ast.Record;
		                      dsTypes: Ast.Declarations);
		VAR var: Ast.Var;
			d: Ast.Declaration;
			typ: Ast.Type;

			PROCEDURE Name(VAR v: Ast.Var; VAR p: Parser; ds: Ast.Record);
			VAR begin, end, emptyLines: INTEGER;
			BEGIN
				emptyLines := p.s.emptyLines;
				ExpectIdent(p, begin, end, ErrExpectIdent);
				CheckAst(p, Ast.RecordVarAdd(v, ds, p.s.buf, begin, end));
				v.emptyLines := emptyLines;
				Mark(p, v)
			END Name;
		BEGIN
			Name(var, p, dsAdd);
			d := var;
			WHILE ScanIfEqual(p, Scanner.Comma) DO
				Name(var, p, dsAdd)
			END;
			Expect(p, Scanner.Colon, ErrExpectColon);
			typ := type(p, dsTypes, -1, -1);
			CheckAst(p, Ast.VarListSetType(d, typ))
		END Declaration;
	BEGIN
		IF p.l = Scanner.Ident THEN
			Declaration(p, dsAdd, dsTypes);
			WHILE ScanIfEqual(p, Scanner.Semicolon) DO
				IF p.l # SpecIdent.End THEN
					Declaration(p, dsAdd, dsTypes)
				ELSIF p.opt.strictSemicolon THEN
					AddError(p, ErrExcessSemicolon);
					p.err := FALSE
				END
			END
		END
	END RecVars;
BEGIN
	ASSERT(p.l = SpecIdent.Record);
	Scan(p);
	base := NIL;
	IF ScanIfEqual(p, Scanner.Brace1Open) THEN
		decl := Qualident(p, ds);
		IF (decl # NIL) & (decl.id = Ast.IdRecord) THEN
			base := decl(Ast.Record)
		ELSE
			AddError(p, ErrExpectRecord)
		END;
		Expect(p, Scanner.Brace1Close, ErrExpectBrace1Close)
	END;
	rec := Ast.RecordNew(ds, base);
	IF ptr # NIL THEN
		Ast.PointerSetRecord(ptr, rec)
	END;
	IF nameBegin >= 0 THEN
		t := rec;
		CheckAst(p, Ast.TypeAdd(ds, p.s.buf, nameBegin, nameEnd, t));
		IF rec # t THEN
			rec := t(Ast.Record);
			Ast.RecordSetBase(rec, base)
		END
	ELSE
		Strings.Undef(rec.name);
		rec.module := p.module.bag
	END;
	RecVars(p, rec, ds);
	Expect(p, SpecIdent.End, ErrExpectEnd);
	CheckAst(p, Ast.RecordEnd(rec))
	RETURN rec
END Record;

PROCEDURE Pointer(VAR p: Parser; ds: Ast.Declarations;
                  nameBegin, nameEnd: INTEGER): Ast.Pointer;
VAR tp: Ast.Pointer;
	t: Ast.Type;
	decl: Ast.Declaration;
	typeDecl: Ast.Record;
BEGIN
	ASSERT(p.l = SpecIdent.Pointer);
	Scan(p);
	tp := Ast.PointerGet(NIL);
	IF nameBegin >= 0 THEN
		t := tp;
		ASSERT(t # NIL);
		CheckAst(p, Ast.TypeAdd(ds, p.s.buf, nameBegin, nameEnd, t))
	END;
	Expect(p, SpecIdent.To, ErrExpectTo);
	IF p.l = SpecIdent.Record THEN
		typeDecl := Record(p, ds, tp, -1, -1);
		ASSERT(typeDecl.pointer = tp)
	ELSIF p.l = Scanner.Ident THEN
		decl := Ast.DeclarationSearch(ds, p.s.buf, p.s.lexStart, p.s.lexEnd);
		IF decl = NIL THEN (* опережающее объявление ссылка на запись *)
			typeDecl := Ast.RecordForwardNew(ds, p.s.buf, p.s.lexStart, p.s.lexEnd);
			ASSERT((tp.next = typeDecl) OR (nameBegin < 0));
			Ast.PointerSetRecord(tp, typeDecl);

			Scan(p)
		ELSIF decl IS Ast.Record THEN
			Ast.PointerSetRecord(tp, decl(Ast.Record));
			Scan(p)
		ELSE
			CheckAst(p, Ast.PointerSetType(tp, TypeNamed(p, ds)))
		END
	ELSE
		AddError(p, ErrExpectRecord)
	END
	RETURN tp
END Pointer;

PROCEDURE FormalParameters(VAR p: Parser; ds: Ast.Declarations; proc: Ast.ProcType);
VAR braces: BOOLEAN;

	PROCEDURE Section(VAR p: Parser; ds: Ast.Declarations; proc: Ast.ProcType);
	VAR access: SET;
		param: Ast.Declaration;

		PROCEDURE Name(VAR p: Parser; proc: Ast.ProcType; access: SET);
		BEGIN
			IF p.l # Scanner.Ident THEN
				AddError(p, ErrExpectIdent)
			ELSE
				CheckAst(p,
					Ast.ParamAdd(p.module, proc,
					             p.s.buf, p.s.lexStart, p.s.lexEnd,
					             access)
				);
				Scan(p)
			END
		END Name;

		PROCEDURE Type(VAR p: Parser; ds: Ast.Declarations): Ast.Type;
		VAR t: Ast.Type;
			arrs: INTEGER;
		BEGIN
			arrs := 0;
			WHILE ScanIfEqual(p, SpecIdent.Array) DO
				Expect(p, SpecIdent.Of, ErrExpectOf);
				INC(arrs)
			END;
			t := TypeNamed(p, ds);
			WHILE (t # NIL) & (arrs > 0) DO
				t := Ast.ArrayGet(t, NIL);
				DEC(arrs)
			END
			RETURN t
		END Type;
	BEGIN
		IF ScanIfEqual(p, SpecIdent.Var) THEN
			access := {Ast.ParamIn, Ast.ParamOut}
		ELSE
			access := {}
		END;
		Name(p, proc, access);
		param := proc.end;
		WHILE ScanIfEqual(p, Scanner.Comma) DO
			Name(p, proc, access)
		END;
		Expect(p, Scanner.Colon, ErrExpectColon);
		CheckAst(p, Ast.VarListSetType(param, Type(p, ds)))
	END Section;
BEGIN
	braces := ScanIfEqual(p, Scanner.Brace1Open);
	IF braces & ~ScanIfEqual(p, Scanner.Brace1Close) THEN
		Section(p, ds, proc);
		WHILE ScanIfEqual(p, Scanner.Semicolon) DO
			Section(p, ds, proc)
		END;
		Expect(p, Scanner.Brace1Close, ErrExpectBrace1Close)
	END;
	IF ScanIfEqual(p, Scanner.Colon) THEN
		IF ~braces THEN
			AddError(p, ErrFunctionWithoutBraces);
			p.err := FALSE
		END;
		CheckAst(p, Ast.ProcTypeSetReturn(proc, TypeNamed(p, ds)))
	END
END FormalParameters;

PROCEDURE TypeProcedure(VAR p: Parser; ds: Ast.Declarations;
                        nameBegin, nameEnd: INTEGER): Ast.ProcType;
VAR proc: Ast.ProcType;
	t: Ast.Type;
BEGIN
	ASSERT(p.l = SpecIdent.Procedure);
	Scan(p);
	proc := Ast.ProcTypeNew(TRUE);
	IF 0 <= nameBegin THEN
		t := proc;
		CheckAst(p, Ast.TypeAdd(ds, p.s.buf, nameBegin, nameEnd, t))
	END;
	FormalParameters(p, ds, proc)
	RETURN proc
END TypeProcedure;

PROCEDURE Type(VAR p: Parser; ds: Ast.Declarations;
               nameBegin, nameEnd: INTEGER): Ast.Type;
VAR t: Ast.Type;
BEGIN
	IF p.l = SpecIdent.Array THEN
		t := Array(p, ds, nameBegin, nameEnd)
	ELSIF p.l = SpecIdent.Pointer THEN
		t := Pointer(p, ds, nameBegin, nameEnd)
	ELSIF p.l = SpecIdent.Procedure THEN
		t := TypeProcedure(p, ds, nameBegin, nameEnd)
	ELSIF p.l = SpecIdent.Record THEN
		t := Record(p, ds, NIL, nameBegin, nameEnd)
	ELSIF p.l = Scanner.Ident THEN
		t := TypeNamed(p, ds)
	ELSE
		t := Ast.TypeErrorNew();
		AddError(p, ErrExpectType)
	END
	RETURN t
END Type;

PROCEDURE Types(VAR p: Parser; ds: Ast.Declarations);
VAR typ: Ast.Type;
    begin, end, emptyLines: INTEGER;
    mark: BOOLEAN;
BEGIN
	Scan(p);
	WHILE p.l = Scanner.Ident DO
		emptyLines := p.s.emptyLines;
		begin := p.s.lexStart;
		end := p.s.lexEnd;
		Scan(p);
		mark := ScanIfEqual(p, Scanner.Asterisk);
		Expect(p, Scanner.Equal, ErrExpectEqual);
		typ := Type(p, ds, begin, end);
		IF typ # NIL THEN
			typ.emptyLines := emptyLines;
			typ.mark := mark;
			IF ~(typ IS Ast.Construct) THEN
				AddError(p, ErrExpectStructuredType)
			(*
			ELSIF typ.next = NIL THEN
				CheckAst(p, Ast.TypeAdd(ds, p.s.buf, begin, end, typ))
			*)
			END
		END;
		Expect(p, Scanner.Semicolon, ErrExpectSemicolon)
	END;
	CheckAst(p, Ast.CheckUndefRecordForward(ds))
END Types;

PROCEDURE If(VAR p: Parser; ds: Ast.Declarations): Ast.If;
VAR if, else: Ast.If;
    elsif: Ast.WhileIf;
    i: INTEGER;

	PROCEDURE Branch(VAR p: Parser; ds: Ast.Declarations): Ast.If;
	VAR if: Ast.If;
	BEGIN
		Scan(p);
		CheckAst(p, Ast.IfNew(if, Expression(p, ds, FALSE), NIL));
		Ast.TurnIf(ds);
		Expect(p, SpecIdent.Then, ErrExpectThen);
		if.stats := statements(p, ds)
		RETURN if
	END Branch;
BEGIN
	ASSERT(p.l = SpecIdent.If);
	if := Branch(p, ds);
	elsif := if;
	i := 1;
	WHILE p.l = SpecIdent.Elsif DO
		INC(i);
		Ast.TurnElse(ds);
		elsif.elsif := Branch(p, ds);
		elsif := elsif.elsif
	END;
	IF ScanIfEqual(p, SpecIdent.Else) THEN
		Ast.TurnElse(ds);
		CheckAst(p, Ast.IfNew(else, NIL, statements(p, ds)));
		elsif.elsif := else
	END;
	REPEAT
		DEC(i);
		Ast.BackFromBranch(ds)
	UNTIL i = 0;
	Expect(p, SpecIdent.End, ErrExpectEnd)
	RETURN if
END If;

PROCEDURE Case(VAR p: Parser; ds: Ast.Declarations): Ast.Case;
VAR case: Ast.Case;
    i: INTEGER;

	PROCEDURE Element(VAR p: Parser; ds: Ast.Declarations; case: Ast.Case);
	VAR elem: Ast.CaseElement;

		PROCEDURE LabelList(VAR p: Parser; case: Ast.Case;
		                    ds: Ast.Declarations): Ast.CaseLabel;
		VAR first, last: Ast.CaseLabel;

			PROCEDURE LabelRange(VAR p: Parser; ds: Ast.Declarations): Ast.CaseLabel;
			VAR r: Ast.CaseLabel;

				PROCEDURE Label(VAR p: Parser; ds: Ast.Declarations): Ast.CaseLabel;
				VAR l: Ast.CaseLabel;
				    i: INTEGER;
				BEGIN
					IF (p.l = Scanner.Number) & ~p.s.isReal THEN
						CheckAst(p, Ast.CaseLabelNew(l, Ast.IdInteger, p.s.integer));
						Scan(p)
					ELSIF p.l = Scanner.String THEN
						IF p.s.isChar THEN
							i := p.s.integer
						ELSE
							AddError(p, ErrUnexpectStringInCaseLabel);
							i := -1
						END;
						CheckAst(p, Ast.CaseLabelNew(l, Ast.IdChar, i));
						Scan(p)
					ELSIF p.l = Scanner.Ident THEN
						CheckAst(p, Ast.CaseLabelQualNew(l, Qualident(p, ds)))
					ELSE
						CheckAst(p, Ast.CaseLabelNew(l, Ast.IdInteger, 0));
						AddError(p, ErrExpectIntOrStrOrQualident)
					END
					RETURN l
				END Label;
			BEGIN
				r := Label(p, ds);
				IF p.l = Scanner.Range THEN
					Scan(p);
					CheckAst(p, Ast.CaseRangeNew(r, Label(p, ds)))
				END
				RETURN r
			END LabelRange;
		BEGIN
			first := LabelRange(p, ds);
			(* проверка 1-го диапазона *)
			CheckAst(p, Ast.CaseRangeListAdd(case, NIL, first));
			WHILE p.l = Scanner.Comma DO
				Scan(p);
				last := LabelRange(p, ds);
				CheckAst(p, Ast.CaseRangeListAdd(case, first, last))
			END
			RETURN first
		END LabelList;
	BEGIN
		Ast.TurnIf(ds);
		elem := Ast.CaseElementNew(LabelList(p, case, ds));
		(*ASSERT(elem.labels # NIL); TODO *)
		Expect(p, Scanner.Colon, ErrExpectColon);
		elem.stats := statements(p, ds);

		CheckAst(p, Ast.CaseElementAdd(case, elem))
	END Element;
BEGIN
	ASSERT(p.l = SpecIdent.Case);
	Scan(p);
	CheckAst(p, Ast.CaseNew(case, Expression(p, ds, FALSE)));
	Expect(p, SpecIdent.Of, ErrExpectOf);
	i := 1;
	WHILE ScanIfEqual(p, Scanner.Alternative) DO ; END;
	Element(p, ds, case);
	WHILE ScanIfEqual(p, Scanner.Alternative) DO
		WHILE ScanIfEqual(p, Scanner.Alternative) DO ; END;
		INC(i);
		Ast.TurnElse(ds);
		Element(p, ds, case)
	END;
	Ast.TurnElse(ds);
	Ast.TurnFail(ds);
	REPEAT
		DEC(i);
		Ast.BackFromBranch(ds)
	UNTIL i = 0;
	Expect(p, SpecIdent.End, ErrExpectEnd)
	RETURN case
END Case;

PROCEDURE DecInLoops(VAR p: Parser; ds: Ast.Declarations);
BEGIN
	DEC(p.inLoops);
	ASSERT(0 <= p.inLoops);
	IF (p.inLoops = 0) & (ds.up # NIL) THEN
		CheckAst(p, Ast.CheckInited(ds))
	END
END DecInLoops;

PROCEDURE Repeat(VAR p: Parser; ds: Ast.Declarations): Ast.Repeat;
VAR r: Ast.Repeat;
BEGIN
	ASSERT(p.l = SpecIdent.Repeat);
	INC(p.inLoops);
		Scan(p);
		CheckAst(p, Ast.RepeatNew(r, statements(p, ds)));
		Expect(p, SpecIdent.Until, ErrExpectUntil);
	DecInLoops(p, ds);
	CheckAst(p, Ast.RepeatSetUntil(r, Expression(p, ds, FALSE)))
	RETURN r
END Repeat;

PROCEDURE For(VAR p: Parser; ds: Ast.Declarations): Ast.For;
VAR f: Ast.For;
	v: Ast.Var;
	errName: ARRAY 12 OF CHAR;
BEGIN
	ASSERT(p.l = SpecIdent.For);
	Scan(p);
	IF p.l # Scanner.Ident THEN
		errName := "FORITERATOR";
		AddError(p, ErrExpectIdent
		          + Ast.ForIteratorGet(v, ds, errName, 0, 10) * 0
		)
	ELSE
		CheckAst(p, Ast.ForIteratorGet(v, ds, p.s.buf, p.s.lexStart, p.s.lexEnd))
	END;
	Scan(p);
	Expect(p, Scanner.Assign, ErrExpectAssign);
	CheckAst(p, Ast.ForNew(f, v, Expression(p, ds, FALSE), NIL, 1, NIL));
	Expect(p, SpecIdent.To, ErrExpectTo);
	CheckAst(p, Ast.ForSetTo(f, Expression(p, ds, FALSE)));
	IF p.l # SpecIdent.By THEN
		CheckAst(p, Ast.ForSetBy(f, NIL))
	ELSE
		Scan(p);
		CheckAst(p, Ast.ForSetBy(f, Expression(p, ds, FALSE)))
	END;
	INC(p.inLoops);
		Expect(p, SpecIdent.Do, ErrExpectDo);
		f.stats := statements(p, ds);
		Expect(p, SpecIdent.End, ErrExpectEnd);
	DecInLoops(p, ds)
	RETURN f
END For;

PROCEDURE While(VAR p: Parser; ds: Ast.Declarations): Ast.While;
VAR w, br: Ast.While;
    elsif: Ast.WhileIf;
BEGIN
	ASSERT(p.l = SpecIdent.While);
	INC(p.inLoops);
		Scan(p);
		CheckAst(p, Ast.WhileNew(w, Expression(p, ds, FALSE), NIL));
		elsif := w;
		Expect(p, SpecIdent.Do, ErrExpectDo);
		w.stats := statements(p, ds);

		WHILE ScanIfEqual(p, SpecIdent.Elsif) DO
			CheckAst(p, Ast.WhileNew(br, Expression(p, ds, FALSE), NIL));
			elsif.elsif := br;
			elsif := br;
			Expect(p, SpecIdent.Do, ErrExpectDo);
			elsif.stats := statements(p, ds)
		END;
		Expect(p, SpecIdent.End, ErrExpectEnd);
	DecInLoops(p, ds)
	RETURN w
END While;

PROCEDURE Assign(VAR p: Parser; ds: Ast.Declarations; des: Ast.Designator)
                : Ast.Assign;
VAR st: Ast.Assign;
BEGIN
	ASSERT(p.l = Scanner.Assign);
	Scan(p);
	CheckAst(p, Ast.AssignNew(st, 0 < p.inLoops, des, Expression(p, ds, FALSE)))
	RETURN st
END Assign;

PROCEDURE Call(VAR p: Parser; ds: Ast.Declarations; des: Ast.Designator): Ast.Call;
VAR st: Ast.Call;
BEGIN
	CheckAst(p, Ast.CallNew(st, des));
	IF p.l = Scanner.Brace1Open THEN
		CallParams(p, ds, st.expr(Ast.ExprCall))
	ELSIF (des # NIL) & (des.type # NIL) & (des.type IS Ast.ProcType) THEN
		CheckAst(p, Ast.CallParamsEnd(st.expr(Ast.ExprCall),
		                              des.type(Ast.ProcType).params,
		                              ds)
		)
	END
	RETURN st
END Call;

PROCEDURE NotEnd(l: INTEGER): BOOLEAN;
RETURN (l # SpecIdent.End)
     & (l # SpecIdent.Return)
     & (l # SpecIdent.Else)
     & (l # SpecIdent.Elsif)
     & (l # SpecIdent.Until)
     & (l # Scanner.Alternative)
     & (l # Scanner.EndOfFile)
END NotEnd;

PROCEDURE Statements(VAR p: Parser; ds: Ast.Declarations): Ast.Statement;
VAR stats, last: Ast.Statement;

	PROCEDURE Statement(VAR p: Parser; ds: Ast.Declarations): Ast.Statement;
	VAR des: Ast.Designator;
		st: Ast.Statement;
		commentOfs, commentEnd, emptyLines: INTEGER;
	BEGIN
		(* Log.StrLn("Statement"); *)
		IF ~p.opt.saveComments
		OR ~Scanner.TakeCommentPos(p.s, commentOfs, commentEnd)
		THEN
			commentOfs := -1
		END;
		emptyLines := p.s.emptyLines;
		IF p.l = Scanner.Ident      THEN
			des := Designator(p, ds);
			IF p.l = Scanner.Assign THEN
				st := Assign(p, ds, des)
			ELSIF p.l = Scanner.Equal THEN
				AddError(p, ErrMaybeAssignInsteadEqual);
				st := Ast.StatementErrorNew()
			ELSE
				st := Call(p, ds, des)
			END
		ELSIF p.l = SpecIdent.If      THEN
			st := If(p, ds)
		ELSIF p.l = SpecIdent.Case    THEN
			st := Case(p, ds)
		ELSIF p.l = SpecIdent.Repeat  THEN
			st := Repeat(p, ds)
		ELSIF p.l = SpecIdent.For     THEN
			st := For(p, ds)
		ELSIF p.l = SpecIdent.While   THEN
			st := While(p, ds)
		ELSE
			st := NIL
		END;
		IF st # NIL THEN
			IF commentOfs >= 0 THEN
				Ast.NodeSetComment(st^, p.module, p.s.buf, commentOfs, commentEnd)
			END;
			IF emptyLines > 0 THEN
				st.emptyLines := emptyLines
			END
		END;
		IF p.err THEN
			Log.StrLn("Error");
			WHILE (p.l # Scanner.Semicolon) & NotEnd(p.l) DO
				Scan(p)
			END;
			p.err := FALSE
		END
		RETURN st
	END Statement;
BEGIN
	stats := Statement(p, ds);
	last := stats;

	WHILE ScanIfEqual(p, Scanner.Semicolon) DO
		IF stats = NIL THEN
			stats := Statement(p, ds);
			last := stats
		ELSE
			last.next := Statement(p, ds);
			IF last.next # NIL THEN
				last := last.next
			END
		END
	ELSIF NotEnd(p.l) & ~p.module.script DO
		AddError(p, ErrExpectSemicolon);
		p.err := FALSE;
		WHILE (p.l # Scanner.Semicolon) & NotEnd(p.l) DO
			Scan(p)
		END
	END
	RETURN stats
END Statements;

PROCEDURE Return(VAR p: Parser; proc: Ast.Procedure);
BEGIN
	IF p.l = SpecIdent.Return THEN
		Log.StrLn("Return");

		Scan(p);
		CheckAst(p, Ast.ProcedureSetReturn(proc, Expression(p, proc, FALSE)));
		IF p.l = Scanner.Semicolon THEN
			IF p.opt.strictSemicolon THEN
				AddError(p, ErrExcessSemicolon);
				p.err := FALSE
			END;
			Scan(p)
		END
	ELSE
		CheckAst(p, Ast.ProcedureEnd(proc))
	END
END Return;

PROCEDURE ProcBody(VAR p: Parser; proc: Ast.Procedure);
BEGIN
	declarations(p, proc);
	IF ScanIfEqual(p, SpecIdent.Begin) THEN
		proc.stats := Statements(p, proc)
	END;
	Return(p, proc);
	Expect(p, SpecIdent.End, ErrExpectEnd);
	IF p.l = Scanner.Ident THEN
		IF ~Strings.IsEqualToChars(proc.name, p.s.buf, p.s.lexStart, p.s.lexEnd)
		THEN
			AddError(p, ErrEndProcedureNameNotMatch)
		END;
		Scan(p)
	ELSE
		AddError(p, ErrExpectProcedureName)
	END
END ProcBody;

PROCEDURE TakeComment(VAR p: Parser): BOOLEAN;
	RETURN p.opt.saveComments
	     & Scanner.TakeCommentPos(p.s, p.comment.ofs, p.comment.end)
END TakeComment;

PROCEDURE Procedure(VAR p: Parser; ds: Ast.Declarations);
VAR proc: Ast.Procedure;
	nameStart, nameEnd: INTEGER;
BEGIN
	ASSERT(p.l = SpecIdent.Procedure);
	Scan(p);
	ExpectIdent(p, nameStart, nameEnd, ErrExpectIdent);
	CheckAst(p, Ast.ProcedureAdd(ds, proc, p.s.buf, nameStart, nameEnd));
	Mark(p, proc);
	FormalParameters(p, ds, proc.header);
	Expect(p, Scanner.Semicolon, ErrExpectSemicolon);
	ProcBody(p, proc)
END Procedure;

PROCEDURE Declarations(VAR p: Parser; ds: Ast.Declarations);
BEGIN
	IF p.l = SpecIdent.Const THEN
		Consts(p, ds)
	END;
	IF p.l = SpecIdent.Type THEN
		Types(p, ds)
	END;
	IF p.l = SpecIdent.Var THEN
		Scan(p);
		Vars(p, ds)
	END;
	WHILE p.l = SpecIdent.Procedure DO
		Procedure(p, ds);
		Expect(p, Scanner.Semicolon, ErrExpectSemicolon)
	END
END Declarations;

PROCEDURE Imports(VAR p: Parser);
VAR nameOfs, nameEnd, realOfs, realEnd: INTEGER;
BEGIN
	Ast.ImportHandle(p.module);
	REPEAT
		Scan(p);
		ExpectIdent(p, nameOfs, nameEnd, ErrExpectModuleName);
		IF ScanIfEqual(p, Scanner.Assign) THEN
			ExpectIdent(p, realOfs, realEnd, ErrExpectModuleName)
		ELSE
			realOfs := nameOfs;
			realEnd := nameEnd
		END;
		IF ~p.err & (realOfs >= 0) THEN
			CheckAst(p, Ast.ImportAdd(p.opt.provider, p.module, p.s.buf,
			                          nameOfs, nameEnd, realOfs, realEnd)
			)
		ELSIF p.err THEN
			p.err := FALSE;
			WHILE (p.l < SpecIdent.Import)
			    & (p.l # Scanner.Comma)
			    & (p.l # Scanner.Semicolon)
			    & (p.l # Scanner.EndOfFile)
			DO
				Scan(p)
			END
		END
	UNTIL p.l # Scanner.Comma;
	Expect(p, Scanner.Semicolon, ErrExpectSemicolon);
	Ast.ImportEnd(p.module)
END Imports;

PROCEDURE Module(VAR p: Parser);
VAR expectedName: BOOLEAN;

	PROCEDURE SearchModule(VAR p: Parser);
	VAR limit: INTEGER;
	BEGIN
		limit := TranLim.MaxLexemsToModule;
		REPEAT
			Scan(p);
			DEC(limit)
		UNTIL (p.l = SpecIdent.Module) OR (p.l = Scanner.EndOfFile)
		   OR (limit <= 0);
	END SearchModule;
BEGIN
	SearchModule(p);
	IF p.l # SpecIdent.Module THEN
		p.module := Ast.ModuleNew("  ", 0, 0);
		AddError(p, ErrExpectModule);
		ASSERT((p.module = NIL) OR (p.module.errors # NIL))
	ELSE
		Scan(p);
		IF p.l # Scanner.Ident THEN
			p.module := Ast.ModuleNew("  ", 0, 0);
			AddError(p, ErrExpectIdent);
			expectedName := TRUE
		ELSE
			p.module := Ast.ModuleNew(p.s.buf, p.s.lexStart, p.s.lexEnd);
			expectedName := Ast.RegModule(p.opt.provider, p.module);
			IF expectedName THEN
				IF TakeComment(p) THEN
					Ast.ModuleSetComment(p.module, p.s.buf,
					                     p.comment.ofs, p.comment.end)
				END;
				Scan(p)
			ELSE
				AddError(p, ErrExpectAnotherModuleName)
			END
		END;
		IF expectedName THEN
			Expect(p, Scanner.Semicolon, ErrExpectSemicolon);
			IF p.l = SpecIdent.Import THEN
				Imports(p)
			END;
			Declarations(p, p.module);
			IF ScanIfEqual(p, SpecIdent.Begin) THEN
				p.module.stats := Statements(p, p.module)
			END;
			Expect(p, SpecIdent.End, ErrExpectEnd);
			IF p.l = Scanner.Ident THEN
				IF ~Strings.IsEqualToChars(p.module.name, p.s.buf,
				                           p.s.lexStart, p.s.lexEnd)
				THEN
					AddError(p, ErrEndModuleNameNotMatch)
				END;
				Scan(p)
			ELSE
				AddError(p, ErrExpectModuleName)
			END;
			IF p.l # Scanner.Dot THEN
				AddError(p, ErrExpectDot)
			END;
			CheckAst(p, Ast.ModuleEnd(p.module))
		END
	END
END Module;

PROCEDURE Blank(code: INTEGER);
END Blank;

PROCEDURE DefaultOptions*(VAR opt: Options);
BEGIN
	V.Init(opt);

	opt.strictSemicolon := TRUE;
	opt.strictReturn    := TRUE;
	opt.saveComments    := TRUE;
	opt.multiErrors     := FALSE;
	opt.cyrillic        := FALSE;
	opt.printError      := Blank;

	opt.provider        := NIL
END DefaultOptions;

PROCEDURE ParserInit(VAR p: Parser; in: Stream.PIn; src: ARRAY OF CHAR; opt: Options);
BEGIN
	V.Init(p);
	p.opt           := opt;
	p.err           := FALSE;
	p.errorsCount   := 0;
	p.module        := NIL;
	p.callId        := 0;
	p.inLoops       := 0;
	IF in # NIL THEN
		Scanner.Init(p.s, in)
	ELSE
		ASSERT(Scanner.InitByString(p.s, src))
	END;
	p.s.opt.cyrillic := opt.cyrillic
END ParserInit;

PROCEDURE Parse*(in: Stream.PIn; opt: Options): Ast.Module;
VAR p: Parser;
BEGIN
	ASSERT(in # NIL);
	ParserInit(p, in, "", opt);
	Module(p)
	RETURN p.module
END Parse;

PROCEDURE Script*(in: ARRAY OF CHAR; opt: Options): Ast.Module;
VAR p: Parser;
BEGIN
	ParserInit(p, NIL, in, opt);
	p.module := Ast.ScriptNew();
	Scan(p);
	p.module.stats := Statements(p, p.module);
	ASSERT((p.module.stats # NIL) OR (p.module.errors # NIL));
	CheckAst(p, Ast.ModuleEnd(p.module))
	RETURN p.module
END Script;

BEGIN
	declarations := Declarations;
	type         := Type;
	statements   := Statements;
	expression   := Expression
END Parser.

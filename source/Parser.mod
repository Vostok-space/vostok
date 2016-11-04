(*  Parser of Oberon-07 modules
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

(* Исправить генерацию массивов *)
MODULE Parser;

IMPORT
	V,
	Log, Out,
	Utf8,
	Scanner,
	Strings := StringStore,
	Ast,
	Stream := VDataStream;

CONST
	ErrNo = 0;
	Err = Scanner.ErrMin;
	
	ErrExpectModule*				= Err - 01;
	ErrExpectIdent*					= Err - 02;
	ErrExpectColon*					= Err - 03;
	ErrExpectSemicolon*				= Err - 04;
	ErrExpectEnd*					= Err - 05;
	ErrExpectDot*					= Err - 06;
	ErrExpectModuleName*			= Err - 07;
	ErrExpectEqual*					= Err - 08;
	ErrExpectBrace1Close*			= Err - 09;
	ErrExpectBrace2Close*			= Err - 10;
	ErrExpectBrace3Close*			= Err - 11;
	ErrExpectOf*					= Err - 12;
	ErrExpectConstIntExpr*			= Err - 14;
	ErrExpectTo*					= Err - 15;
	ErrExpectNamedType*				= Err - 16;
	ErrExpectRecord*				= Err - 17;
	ErrExpectStatement*				= Err - 18;
	ErrExpectThen*					= Err - 19;
	ErrExpectAssign*				= Err - 20;
	ErrExpectAssignOrBrace1Open*	= Err - 21;
	ErrExpectVarRecordOrPointer*	= Err - 22;
	ErrExpectType*					= Err - 24;
	ErrExpectUntil*					= Err - 25;
	ErrExpectDo*					= Err - 26;
	ErrExpectDesignator*			= Err - 28;
	ErrExpectVar*					= Err - 29;
	ErrExpectProcedure*				= Err - 30;
	ErrExpectConstName*				= Err - 31;
	ErrExpectProcedureName*			= Err - 32;
	ErrExpectExpression*			= Err - 33;
	ErrExpectIntOrStrOrQualident*	= Err - 34;
	ErrExcessSemicolon*				= Err - 35;

	ErrEndModuleNameNotMatch*		= Err - 50;
	ErrArrayDimensionsTooMany*		= Err - 51;
	ErrEndProcedureNameNotMatch*	= Err - 52;
	ErrFunctionWithoutBraces*		= Err - 53;
	ErrArrayLenLess1*				= Err - 54;

	ErrNotImplemented* = Err - 70;

	ErrAstBegin* = Err - 100;
	ErrAstEnd* = ErrAstBegin + Ast.ErrMin;

	ErrMin = ErrAstEnd;

TYPE
	Options* = RECORD(V.Base)
		strictSemicolon*,
		strictReturn*	: BOOLEAN;
		printError*: PROCEDURE(code: INTEGER) 
	END;
	Parser = RECORD(V.Base) (* короткие названия из-за частого использования *)
		settings: Options;
		err: BOOLEAN;
		s: Scanner.Scanner; 
		l: INTEGER;(* lexem *)
		module: Ast.Module;
		provider: Ast.Provider
	END;

VAR
	declarations: PROCEDURE(VAR p: Parser; ds: Ast.Declarations);
	type: PROCEDURE(VAR p: Parser; ds: Ast.Declarations;
					nameBegin, nameEnd: INTEGER): Ast.Type;
	statements: PROCEDURE(VAR p: Parser; ds: Ast.Declarations): Ast.Statement;
	expression: PROCEDURE(VAR p: Parser; ds: Ast.Declarations): Ast.Expression;

PROCEDURE AddError(VAR p: Parser; err: INTEGER);
BEGIN
	Log.Str("AddError "); Log.Int(err); Log.Str(" at ");
	Log.Int(p.s.line); Log.Str(":");
	Log.Int(p.s.column + p.s.tabs * 3); Log.Ln;
	p.err := err > ErrAstBegin;
	IF p.module # NIL THEN
		Ast.AddError(p.module, err, p.s.line, p.s.column, p.s.tabs)
	END;
	p.settings.printError(err);
	Out.Ln
END AddError;

PROCEDURE CheckAst(VAR p: Parser; err: INTEGER);
BEGIN
	IF err # Ast.ErrNo THEN
		ASSERT((err < ErrNo) & (err >= Ast.ErrMin));
		AddError(p, ErrAstBegin + err)
	END
END CheckAst;

PROCEDURE Scan(VAR p: Parser);
BEGIN
	p.l := Scanner.Next(p.s);
	IF p.l < ErrNo THEN
		AddError(p, p.l);
		IF p.l = Scanner.ErrNumberTooBig THEN
			p.l := Scanner.Number
		END
	END
END Scan;

PROCEDURE Expect(VAR p: Parser; expect, error: INTEGER)(*: BOOLEAN*);
BEGIN
	IF p.l = expect THEN
		Scan(p)
	ELSE
		AddError(p, error)
	END(*;
	RETURN p.l = expect*)
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

	PROCEDURE Element(VAR e: Ast.ExprSet; VAR p: Parser; ds: Ast.Declarations): INTEGER;
	VAR left: Ast.Expression;
		err: INTEGER;
	BEGIN
		left := expression(p, ds);
		IF p.l = Scanner.Range THEN
			Scan(p);
			err := Ast.ExprSetNew(e, left, expression(p, ds))
		ELSE
			err := Ast.ExprSetNew(e, left, NIL)
		END
		RETURN err
	END Element;
BEGIN
	ASSERT(p.l = Scanner.Brace3Open);
	Scan(p);
	IF p.l # Scanner.Brace3Close THEN
		err := Element(e, p, ds);
		CheckAst(p, err);
		next := e;
		WHILE ScanIfEqual(p, Scanner.Comma) DO
			err := Element(next.next, p, ds);
			CheckAst(p, err);

			next := next.next
		END;
		Expect(p, Scanner.Brace3Close, ErrExpectBrace3Close)
	ELSE (* Пустое множество *)
		CheckAst(p, Ast.ExprSetNew(e, NIL, NIL));
		Scan(p)
	END
	RETURN e
END Set;

PROCEDURE Negate(VAR p: Parser; ds: Ast.Declarations): Ast.ExprNegate;
BEGIN
	ASSERT(p.l = Scanner.Negate);
	Scan(p)
	RETURN Ast.ExprNegateNew(expression(p, ds))
END Negate;

PROCEDURE DeclarationGet(ds: Ast.Declarations; VAR p: Parser): Ast.Declaration;
VAR d: Ast.Declaration;
BEGIN
	Log.StrLn("DeclarationGet");
	CheckAst(p, Ast.DeclarationGet(d, ds, p.s.buf, p.s.lexStart, p.s.lexEnd))
	RETURN d
END DeclarationGet;

PROCEDURE ExpectDecl(VAR p: Parser; ds: Ast.Declarations): Ast.Declaration;
VAR d: Ast.Declaration;
BEGIN
	IF p.l # Scanner.Ident THEN
		d := NIL;
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
	IF (d # NIL) & (d IS Ast.Import) THEN
		Expect(p, Scanner.Dot, ErrExpectDot);
		d := ExpectDecl(p, d(Ast.Import).module)
	END
	RETURN d
END Qualident;

PROCEDURE ExpectRecordExtend(VAR p: Parser; ds: Ast.Declarations;
							 base: Ast.Construct): Ast.Declaration;
VAR d: Ast.Declaration;
BEGIN
	d := Qualident(p, ds)
	RETURN d
END ExpectRecordExtend;

PROCEDURE Designator(VAR p: Parser; ds: Ast.Declarations): Ast.Designator;
VAR des: Ast.Designator;
	decl, var: Ast.Declaration;
	prev, sel: Ast.Selector;
	type: Ast.Type;
	nameBegin, nameEnd: INTEGER; 

	PROCEDURE SetSel(VAR prev: Ast.Selector; sel: Ast.Selector; des: Ast.Designator);
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
	des := NIL;
	IF decl # NIL THEN
		IF decl IS Ast.Var THEN
			type := decl.type;
			prev := NIL;
			des := Ast.DesignatorNew(decl);
			REPEAT
				sel := NIL;
				IF p.l = Scanner.Dot THEN
					Scan(p);
					ExpectIdent(p, nameBegin, nameEnd, ErrExpectIdent);
					IF nameBegin >= 0 THEN
						CheckAst(p,
							Ast.SelRecordNew(sel, type, p.s.buf, nameBegin, nameEnd)
						)
					END
				ELSIF p.l = Scanner.Brace1Open THEN
					IF type.id IN {Ast.IdRecord, Ast.IdPointer} THEN
						Scan(p);
						var := ExpectRecordExtend(p, ds, type(Ast.Construct));
						CheckAst(p, Ast.SelGuardNew(sel, type, var));
						Expect(p, Scanner.Brace1Close, ErrExpectBrace1Close)
					ELSIF ~(type IS Ast.ProcType) THEN
						AddError(p, ErrExpectVarRecordOrPointer)
					END
				ELSIF p.l = Scanner.Brace2Open THEN
					Scan(p);
					CheckAst(p, Ast.SelArrayNew(sel, type, expression(p, ds)));
					WHILE ScanIfEqual(p, Scanner.Comma) DO
						SetSel(prev, sel, des);
						CheckAst(p, Ast.SelArrayNew(sel, type, expression(p, ds)))
					END;
					Expect(p, Scanner.Brace2Close, ErrExpectBrace2Close)
				ELSIF p.l = Scanner.Dereference THEN
					CheckAst(p, Ast.SelPointerNew(sel, type));
					Scan(p)
				END;
				SetSel(prev, sel, des)
			UNTIL sel = NIL;

			des.type := type
		ELSIF (decl IS Ast.Const) OR (decl IS Ast.GeneralProcedure)
		   OR (decl.id = Ast.IdError)
		THEN
			des := Ast.DesignatorNew(decl)
		ELSE
			AddError(p, ErrExpectDesignator)
		END
	END
	RETURN des
END Designator;

PROCEDURE CallParams(VAR p: Parser; ds: Ast.Declarations; e: Ast.ExprCall);
VAR par: Ast.Parameter;
	fp: Ast.FormalParam;
BEGIN
	ASSERT(p.l = Scanner.Brace1Open);
	Scan(p);
	IF ~ScanIfEqual(p, Scanner.Brace1Close) THEN
		par := NIL;
		fp := e.designator.type(Ast.ProcType).params;
		CheckAst(p, Ast.CallParamNew(e, par, expression(p, ds), fp));
		e.params := par;
		WHILE ScanIfEqual(p, Scanner.Comma) DO
			CheckAst(p, Ast.CallParamNew(e, par, expression(p, ds), fp))
		END;
		CheckAst(p, Ast.CallParamsEnd(e, fp));
		Expect(p, Scanner.Brace1Close, ErrExpectBrace1Close)
	END
END CallParams;

PROCEDURE ExprCall(VAR p: Parser; ds: Ast.Declarations; des: Ast.Designator): Ast.ExprCall;
VAR e: Ast.ExprCall;
BEGIN
	CheckAst(p, Ast.ExprCallNew(e, des));
	CallParams(p, ds, e)
	RETURN e
END ExprCall;

PROCEDURE Factor(VAR p: Parser; ds: Ast.Declarations): Ast.Expression;
VAR e: Ast.Expression;

	PROCEDURE Ident(VAR p: Parser; ds: Ast.Declarations; VAR e: Ast.Expression);
	VAR des: Ast.Designator;
	BEGIN
		des := Designator(p, ds);
		IF p.l # Scanner.Brace1Open THEN
			e := des
		ELSE
			e := ExprCall(p, ds, des)
		END
	END Ident;
BEGIN
	Log.StrLn("Factor");

	IF p.l = Scanner.Number THEN
		IF p.s.isReal THEN
			e := Ast.ExprRealNew(p.s.real, p.module, p.s.buf, p.s.lexStart, p.s.lexEnd)
		ELSE
			e := Ast.ExprIntegerNew(p.s.integer)
		END;
		Scan(p)
	ELSIF (p.l = Scanner.True) OR (p.l = Scanner.False) THEN
		e := Ast.ExprBooleanNew(p.l = Scanner.True);
		Scan(p)
	ELSIF p.l = Scanner.Nil THEN
		e := Ast.ExprNilNew();
		Scan(p)
	ELSIF p.l = Scanner.String THEN
		e := Ast.ExprStringNew(p.module, p.s.buf, p.s.lexStart, p.s.lexEnd);
		IF (e # NIL) & p.s.isChar THEN
			e(Ast.ExprString).int := p.s.integer
		END;
		Scan(p)
	ELSIF p.l = Scanner.Brace1Open THEN
		Scan(p);
		e := Ast.ExprBracesNew(expression(p, ds));
		Expect(p, Scanner.Brace1Close, ErrExpectBrace1Close)
	ELSIF p.l = Scanner.Ident THEN
		Ident(p, ds, e)
	ELSIF p.l = Scanner.Brace3Open THEN
		e := Set(p, ds)
	ELSIF p.l = Scanner.Negate THEN
		e := Negate(p, ds)
	ELSE
		AddError(p, ErrExpectExpression);
		e := NIL
	END
	RETURN e
END Factor;

PROCEDURE Term(VAR p: Parser; ds: Ast.Declarations): Ast.Expression;
VAR e: Ast.Expression;
	term: Ast.ExprTerm;
	l: INTEGER;
BEGIN
	Log.StrLn("Term");
	e := Factor(p, ds);
	IF (p.l >= Scanner.MultFirst) & (p.l <= Scanner.MultLast) THEN
		l := p.l;
		Scan(p);
		term := NIL;
		CheckAst(p, Ast.ExprTermNew(term, e(Ast.Factor), l, Factor(p, ds)));
		ASSERT((term.expr # NIL) & (term.factor # NIL));
		e := term;
		WHILE (p.l >= Scanner.MultFirst) & (p.l <= Scanner.MultLast) DO
			l := p.l;
			Scan(p);
			CheckAst(p, Ast.ExprTermAdd(e, term, l, Factor(p, ds)))
		END
	END
	RETURN e
END Term;

PROCEDURE Sum(VAR p: Parser; ds: Ast.Declarations): Ast.Expression;
VAR e: Ast.Expression;
	sum: Ast.ExprSum;
	l: INTEGER;
BEGIN
	Log.StrLn("Sum");
	l := p.l;

	IF (l = Scanner.Minus) OR (l = Scanner.Plus) THEN
		Scan(p);
		CheckAst(p, Ast.ExprSumNew(sum, l, Term(p, ds)));
		e := sum
	ELSE
		e := Term(p, ds);
		IF (p.l = Scanner.Minus) OR (p.l = Scanner.Plus) OR (p.l = Scanner.Or)
		THEN
			CheckAst(p, Ast.ExprSumNew(sum, -1, e));
			e := sum
		END
	END;
	WHILE (p.l = Scanner.Minus) OR (p.l = Scanner.Plus) OR (p.l = Scanner.Or) DO
		l := p.l;
		Scan(p);
		CheckAst(p, Ast.ExprSumAdd(e, sum, l, Term(p, ds)))
	END
	RETURN e
END Sum;

PROCEDURE Expression(VAR p: Parser; ds: Ast.Declarations): Ast.Expression;
VAR expr: Ast.Expression;
	e: Ast.ExprRelation;
	isExt: Ast.ExprIsExtension;
	rel: INTEGER;
BEGIN
	Log.StrLn("Expression");

	expr := Sum(p, ds);
	IF (p.l >= Scanner.RelationFirst) & (p.l < Scanner.RelationLast) THEN
		rel := p.l;
		Scan(p);
		CheckAst(p, Ast.ExprRelationNew(e, expr, rel, Sum(p, ds)));
		expr := e
	ELSIF ScanIfEqual(p, Scanner.Is) THEN
		CheckAst(p, Ast.ExprIsExtensionNew(isExt, expr, type(p, ds, -1, -1)));
		expr := isExt
	END
	RETURN expr
END Expression;

PROCEDURE Mark(VAR p: Parser): BOOLEAN;
VAR m: BOOLEAN;
BEGIN
	m := ScanIfEqual(p, Scanner.Asterisk);
	IF m THEN
		Log.StrLn("Mark")
	END
	RETURN m
END Mark;

PROCEDURE Consts(VAR p: Parser; ds: Ast.Declarations);
VAR begin, end: INTEGER;
	const: Ast.Const;
BEGIN
	Scan(p);
	WHILE p.l = Scanner.Ident DO
		IF ~p.err THEN
			ExpectIdent(p, begin, end, ErrExpectConstName);
			CheckAst(p, Ast.ConstAdd(ds, p.s.buf, begin, end));
			const := ds.end(Ast.Const);
			const.mark := Mark(p);
			Expect(p, Scanner.Equal, ErrExpectEqual);
			CheckAst(p, Ast.ConstSetExpression(const, Expression(p, ds)));
			Expect(p, Scanner.Semicolon, ErrExpectSemicolon)
		END;
		IF p.err THEN
			WHILE (p.l < Scanner.Import (* TODO *)) & (p.l # Scanner.Semicolon) DO
				Scan(p)
			END;
			p.err := FALSE
		END
	END
END Consts;

PROCEDURE ExprToArrayLen(VAR p: Parser; e: Ast.Expression): INTEGER;
VAR i: INTEGER;
BEGIN
	IF (e # NIL) & (e.value # NIL) & (e.value IS Ast.ExprInteger) THEN
		i := e.value(Ast.ExprInteger).int;
		IF i <= 0 THEN
			AddError(p, ErrArrayLenLess1)
		ELSE
			Log.Str("Array Len "); Log.Int(i); Log.Ln
		END
	ELSE 
		i := -1;
		IF e # NIL THEN
			AddError(p, ErrExpectConstIntExpr)
		END
	END
	RETURN i
END ExprToArrayLen;

PROCEDURE ExprToInteger(VAR p:Parser; e: Ast.Expression): INTEGER;
VAR i: INTEGER;
BEGIN
	IF (e # NIL) & (e.type.id = Ast.IdInteger) THEN
		i := e(Ast.ExprInteger).int
	ELSE 
		i := 0;
		IF e # NIL THEN
			AddError(p, ErrExpectConstIntExpr)
		END
	END
	RETURN i
END ExprToInteger;

PROCEDURE Array(VAR p: Parser; ds: Ast.Declarations;
				nameBegin, nameEnd: INTEGER): Ast.Array;
VAR a: Ast.Array;
	t: Ast.Type;
	exprLen: Ast.Expression;
	lens: ARRAY 16 OF Ast.Expression;
	i, size: INTEGER;
BEGIN
	Log.StrLn("Array");
	ASSERT(p.l = Scanner.Array);
	Scan(p);
	a := Ast.ArrayGet(NIL, Expression(p, ds));
	IF nameBegin >= 0 THEN
		t := a;
		CheckAst(p, Ast.TypeAdd(ds, p.s.buf, nameBegin, nameEnd, t))
	END;
	size := ExprToArrayLen(p, a.count);
	i := 0;
	WHILE ScanIfEqual(p, Scanner.Comma) DO
		exprLen := Expression(p, ds);
		size := size * ExprToArrayLen(p, exprLen);
		IF i < LEN(lens) THEN
			lens[i] := exprLen
		END;
		INC(i)
	END;
	IF i > LEN(lens) THEN
		AddError(p, ErrArrayDimensionsTooMany)
	END;
	Expect(p, Scanner.Of, ErrExpectOf);
	a.type := type(p, ds, -1, -1);
	WHILE i > 0 DO
		DEC(i);
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
	END
	RETURN t
END TypeNamed;

PROCEDURE VarDeclaration(VAR p: Parser; dsAdd, dsTypes: Ast.Declarations);
VAR var: Ast.Declaration;
	typ: Ast.Type;

	PROCEDURE Name(VAR p: Parser; ds: Ast.Declarations);
	VAR begin, end: INTEGER;
	BEGIN
		ExpectIdent(p, begin, end, ErrExpectIdent);
		CheckAst(p, Ast.VarAdd(ds, p.s.buf, begin, end));
		ds.end.mark := Mark(p)
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
	END
END VarDeclaration;

PROCEDURE Vars(VAR p: Parser; ds: Ast.Declarations);
BEGIN
	WHILE p.l = Scanner.Ident DO
		VarDeclaration(p, ds, ds);
		Expect(p, Scanner.Semicolon, ErrExpectSemicolon)
	END
END Vars;

PROCEDURE Record(VAR p: Parser; ds: Ast.Declarations;
				 nameBegin, nameEnd: INTEGER): Ast.Record;
VAR rec, base: Ast.Record;
	t: Ast.Type;
	decl: Ast.Declaration;

	PROCEDURE Vars(VAR p: Parser; dsAdd, dsTypes: Ast.Declarations);
	BEGIN
		IF p.l = Scanner.Ident THEN
			VarDeclaration(p, dsAdd, dsTypes);
			WHILE ScanIfEqual(p, Scanner.Semicolon) DO
				IF p.l # Scanner.End THEN
					VarDeclaration(p, dsAdd, dsTypes)
				ELSIF p.settings.strictSemicolon THEN
					AddError(p, ErrExcessSemicolon);
					p.err := FALSE
				END
			END
		END
	END Vars;
BEGIN
	ASSERT(p.l = Scanner.Record);
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
	IF nameBegin >= 0 THEN
		t := rec;
		CheckAst(p, Ast.TypeAdd(ds, p.s.buf, nameBegin, nameEnd, t));
		rec := t(Ast.Record);
		Ast.RecordSetBase(rec, base)
	ELSE
		rec.name.block := NIL;
		rec.module := p.module
	END;
	Vars(p, rec.vars, ds);
	Expect(p, Scanner.End, ErrExpectEnd)
	RETURN rec
END Record;

PROCEDURE Pointer(VAR p: Parser; ds: Ast.Declarations;
				  nameBegin, nameEnd: INTEGER): Ast.Pointer;
VAR tp: Ast.Pointer;
	t: Ast.Type;
	decl: Ast.Declaration;
	typeDecl: Ast.Type;
BEGIN
	ASSERT(p.l = Scanner.Pointer);
	Scan(p);
	tp := Ast.PointerGet(NIL);
	IF nameBegin >= 0 THEN
		t := tp;
		ASSERT(t # NIL);
		CheckAst(p, Ast.TypeAdd(ds, p.s.buf, nameBegin, nameEnd, t))
	END;
	Expect(p, Scanner.To, ErrExpectTo);
	IF p.l = Scanner.Record THEN
		tp.type := Record(p, ds, -1, -1);
		IF tp.type # NIL THEN
			tp.type(Ast.Record).pointer := tp
		END
	ELSIF p.l = Scanner.Ident THEN
		decl := Ast.DeclarationSearch(ds, p.s.buf, p.s.lexStart, p.s.lexEnd);
		IF decl = NIL THEN (* опережающее объявление записи *)
			typeDecl := Ast.RecordNew(ds, NIL);
			CheckAst(p,
				Ast.TypeAdd(ds, p.s.buf, p.s.lexStart, p.s.lexEnd, typeDecl)
			);
			ASSERT(tp.next = typeDecl);
			typeDecl.id := Ast.IdRecordForward; 
			tp.type := typeDecl;
			typeDecl(Ast.Record).pointer := tp
		ELSIF decl IS Ast.Record THEN
			tp.type := decl(Ast.Record);
			decl(Ast.Record).pointer := tp
		ELSE
			tp.type := TypeNamed(p, ds);

			IF tp.type # NIL THEN
				IF tp.type IS Ast.Record THEN
					tp.type(Ast.Record).pointer := tp
				ELSE
					AddError(p, ErrExpectRecord)
				END
			END
		END;
		Scan(p)
	ELSE
		AddError(p, ErrExpectRecord)
	END
	RETURN tp
END Pointer;


PROCEDURE FormalParameters(VAR p: Parser; ds: Ast.Declarations; proc: Ast.ProcType);
VAR braces: BOOLEAN;

	PROCEDURE Section(VAR p: Parser; ds: Ast.Declarations; proc: Ast.ProcType);
	VAR isVar: BOOLEAN;
		param: Ast.FormalParam;
		type: Ast.Type;

		PROCEDURE Name(VAR p: Parser; proc: Ast.ProcType);
		BEGIN
			IF p.l # Scanner.Ident THEN
				AddError(p, ErrExpectIdent)
			ELSE
				CheckAst(p,
					Ast.ParamAdd(p.module, proc, p.s.buf, p.s.lexStart, p.s.lexEnd)
				);
				Scan(p)
			END
		END Name;

		PROCEDURE Type(VAR p: Parser; ds: Ast.Declarations): Ast.Type;
		VAR t: Ast.Type;
			arrs: INTEGER;
		BEGIN
			arrs := 0;
			WHILE ScanIfEqual(p, Scanner.Array) DO
				Expect(p, Scanner.Of, ErrExpectOf);
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
		isVar := ScanIfEqual(p, Scanner.Var);
		Name(p, proc);
		param := proc.end;
		WHILE ScanIfEqual(p, Scanner.Comma) DO
			Name(p, proc)
		END;
		Expect(p, Scanner.Colon, ErrExpectColon);
		type := Type(p, ds);
		WHILE param # NIL DO
			param.isVar := isVar;
			param.type := type;
			param := param.next(Ast.FormalParam)
		END
	END Section;
BEGIN
	braces := ScanIfEqual(p, Scanner.Brace1Open);
	IF braces THEN
		IF ~ScanIfEqual(p, Scanner.Brace1Close) THEN
			Section(p, ds, proc);
			WHILE ScanIfEqual(p, Scanner.Semicolon) DO
				Section(p, ds, proc)
			END;
			Expect(p, Scanner.Brace1Close, ErrExpectBrace1Close)
		END
	END;
	IF ScanIfEqual(p, Scanner.Colon) THEN
		IF ~braces THEN
			AddError(p, ErrFunctionWithoutBraces);
			p.err := FALSE
		END;
		proc.type := TypeNamed(p, ds)
	END
END FormalParameters;

PROCEDURE TypeProcedure(VAR p: Parser; ds: Ast.Declarations;
						nameBegin, nameEnd: INTEGER): Ast.ProcType;
VAR proc: Ast.ProcType;
	t: Ast.Type;
BEGIN
	ASSERT(p.l = Scanner.Procedure);
	Scan(p);
	proc := Ast.ProcTypeNew();
	IF nameBegin >= 0 THEN
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
	IF p.l = Scanner.Array			THEN
		t := Array(p, ds, nameBegin, nameEnd)
	ELSIF p.l = Scanner.Pointer		THEN
		t := Pointer(p, ds, nameBegin, nameEnd)
	ELSIF p.l = Scanner.Procedure	THEN
		t := TypeProcedure(p, ds, nameBegin, nameEnd)
	ELSIF p.l = Scanner.Record		THEN
		t := Record(p, ds, nameBegin, nameEnd)
	ELSIF p.l = Scanner.Ident		THEN
		t := TypeNamed(p, ds)
	ELSE
		t := Ast.TypeGet(Ast.IdInteger);
		AddError(p, ErrExpectType)
	END
	RETURN t
END Type;

PROCEDURE Types(VAR p: Parser; ds: Ast.Declarations);
VAR type: Ast.Type;
	begin, end: INTEGER;
	mark: BOOLEAN;
BEGIN
	Scan(p);
	WHILE p.l = Scanner.Ident DO
		begin := p.s.lexStart;
		end := p.s.lexEnd;
		Scan(p);
		mark := ScanIfEqual(p, Scanner.Asterisk);
		Expect(p, Scanner.Equal, ErrExpectEqual);
		type := Type(p, ds, begin, end);
		IF type # NIL THEN
			type.mark := mark;
			IF ~(type IS Ast.Construct) THEN
				AddError(p, ErrExpectNamedType)
			(*
			ELSIF type.next = NIL THEN
				CheckAst(p, Ast.TypeAdd(ds, p.s.buf, begin, end, type))
			*)
			END
		END;
		Expect(p, Scanner.Semicolon, ErrExpectSemicolon)
	END
END Types;

PROCEDURE If(VAR p: Parser; ds: Ast.Declarations): Ast.If;
VAR if: Ast.If;
	elsif: Ast.WhileIf;

	PROCEDURE Branch(VAR p: Parser; ds: Ast.Declarations): Ast.If;
	VAR if: Ast.If;
	BEGIN
		Scan(p);
		if := Ast.IfNew(Expression(p, ds), NIL);
		Expect(p, Scanner.Then, ErrExpectThen);
		if.stats := statements(p, ds)
		RETURN if
	END Branch;
BEGIN
	ASSERT(p.l = Scanner.If);
	if := Branch(p, ds);
	elsif := if;
	WHILE p.l = Scanner.Elsif DO
		elsif.elsif := Branch(p, ds);
		elsif := elsif.elsif
	END;
	IF ScanIfEqual(p, Scanner.Else) THEN
		elsif.elsif := Ast.IfNew(NIL, statements(p, ds))
	END;
	Expect(p, Scanner.End, ErrExpectEnd)
	RETURN if
END If;

PROCEDURE Case(VAR p: Parser; ds: Ast.Declarations): Ast.Case;
VAR case: Ast.Case;

	PROCEDURE Element(VAR p: Parser; ds: Ast.Declarations; case: Ast.Case);
	VAR elem: Ast.CaseElement;

		PROCEDURE LabelList(VAR p: Parser; case: Ast.Case;
							ds: Ast.Declarations): Ast.CaseLabel;
		VAR first, last: Ast.CaseLabel;
		
			PROCEDURE LabelRange(VAR p: Parser; ds: Ast.Declarations): Ast.CaseLabel;
			VAR r: Ast.CaseLabel;
			
				PROCEDURE Label(VAR p: Parser; ds: Ast.Declarations): Ast.CaseLabel;
				VAR err: INTEGER;
					l: Ast.CaseLabel;
					qual: BOOLEAN;
				BEGIN
					qual := FALSE;
					IF (p.l = Scanner.Number) & ~p.s.isReal THEN
						err := Ast.CaseLabelNew(l, Ast.IdInteger, p.s.integer)
					ELSIF p.l = Scanner.String THEN
						ASSERT(p.s.isChar);
						err := Ast.CaseLabelNew(l, Ast.IdChar, p.s.integer)
					ELSIF p.l = Scanner.Ident THEN
						qual := TRUE;
						err := Ast.CaseLabelQualNew(l, Qualident(p, ds))
					ELSE
						err := ErrExpectIntOrStrOrQualident
					END;
					CheckAst(p, err);
					IF ~qual & (err # ErrExpectIntOrStrOrQualident) THEN
						Scan(p)
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
			WHILE p.l = Scanner.Comma DO
				Scan(p);
				last := LabelRange(p, ds);
				CheckAst(p, Ast.CaseRangeListAdd(case, first, last))
			END
			RETURN first 
		END LabelList;
	BEGIN
		elem := Ast.CaseElementNew(LabelList(p, case, ds));
		ASSERT(elem.labels # NIL);
		Expect(p, Scanner.Colon, ErrExpectColon);
		elem.stats := statements(p, ds);

		CheckAst(p, Ast.CaseElementAdd(case, elem))
	END Element;
BEGIN
	ASSERT(p.l = Scanner.Case);
	Scan(p);
	CheckAst(p, Ast.CaseNew(case, Expression(p, ds)));
	Expect(p, Scanner.Of, ErrExpectOf);
	Element(p, ds, case);
	WHILE ScanIfEqual(p, Scanner.Alternative) DO
		Element(p, ds, case)
	END;
	Expect(p, Scanner.End, ErrExpectEnd)
	RETURN case
END Case;

PROCEDURE Repeat(VAR p: Parser; ds: Ast.Declarations): Ast.Repeat;
VAR r: Ast.Repeat;
BEGIN
	ASSERT(p.l = Scanner.Repeat);
	Scan(p);
	r := Ast.RepeatNew(NIL, statements(p, ds));
	Expect(p, Scanner.Until, ErrExpectUntil);
	r.expr := Expression(p, ds)
	RETURN r
END Repeat;

PROCEDURE For(VAR p: Parser; ds: Ast.Declarations): Ast.For;
VAR f: Ast.For;
	v: Ast.Var;
BEGIN
	ASSERT(p.l = Scanner.For);
	Scan(p);
	IF p.l # Scanner.Ident THEN
		AddError(p, ErrExpectIdent +
			Ast.ForIteratorGet(v, ds, "FORITERATOR", 0, 10) * 0
		)
	ELSE
		CheckAst(p, Ast.ForIteratorGet(v, ds, p.s.buf, p.s.lexStart, p.s.lexEnd))
	END;
	Scan(p);
	Expect(p, Scanner.Assign, ErrExpectAssign);
	f := Ast.ForNew(v, Expression(p, ds), NIL, 1, NIL);
	Expect(p, Scanner.To, ErrExpectTo);
	f.to := Expression(p, ds);
	IF ScanIfEqual(p, Scanner.By) THEN
		f.by := ExprToInteger(p, Expression(p, ds))
	END;
	Expect(p, Scanner.Do, ErrExpectDo);
	f.stats := statements(p, ds);
	Expect(p, Scanner.End, ErrExpectEnd)
	RETURN f
END For;

PROCEDURE While(VAR p: Parser; ds: Ast.Declarations): Ast.While;
VAR w: Ast.While;
	elsif: Ast.WhileIf;
BEGIN
	ASSERT(p.l = Scanner.While);
	Scan(p);
	w := Ast.WhileNew(Expression(p, ds), NIL);
	elsif := w;
	Expect(p, Scanner.Do, ErrExpectDo);
	w.stats := statements(p, ds);

	WHILE ScanIfEqual(p, Scanner.Elsif) DO
		elsif.elsif := Ast.WhileNew(Expression(p, ds), NIL);
		elsif := elsif.elsif;
		Expect(p, Scanner.Do, ErrExpectDo);
		elsif.stats := statements(p, ds)
	END;
	Expect(p, Scanner.End, ErrExpectEnd)
	RETURN w
END While;

PROCEDURE Assign(VAR p: Parser; ds: Ast.Declarations; des: Ast.Designator): Ast.Assign;
VAR st: Ast.Assign;
BEGIN
	ASSERT(p.l = Scanner.Assign);
	Scan(p);
	CheckAst(p, Ast.AssignNew(st, des, Expression(p, ds)))
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
					  des.type(Ast.ProcType).params))
	END
	RETURN st
END Call;

PROCEDURE Statements(VAR p: Parser; ds: Ast.Declarations): Ast.Statement;
VAR stats, last: Ast.Statement;

	PROCEDURE Statement(VAR p: Parser; ds: Ast.Declarations): Ast.Statement;
	VAR des: Ast.Designator;
		st: Ast.Statement;
	BEGIN
		Log.StrLn("Statement");

		IF p.l = Scanner.Ident THEN
			des := Designator(p, ds);
			IF p.l = Scanner.Assign THEN
				st := Assign(p, ds, des)
			ELSE
				st := Call(p, ds, des)
			END
		ELSIF p.l = Scanner.If		THEN
			st := If(p, ds)
		ELSIF p.l = Scanner.Case	THEN
			st := Case(p, ds)
		ELSIF p.l = Scanner.Repeat	THEN
			st := Repeat(p, ds)
		ELSIF p.l = Scanner.For		THEN
			st := For(p, ds)
		ELSIF p.l = Scanner.While	THEN
			st := While(p, ds)
		ELSE
			st := Ast.StatementErrorNew();
			AddError(p, ErrExpectStatement)
		END;
		IF p.err THEN
			Log.StrLn("Error");
			WHILE (p.l # Scanner.Semicolon)
				& (p.l # Scanner.Until)
				& (p.l # Scanner.Elsif)
				& (p.l # Scanner.Else)
				& (p.l # Scanner.End)
				& (p.l # Scanner.Return)
			DO
				Scan(p)
			END;
			p.err := FALSE
		END
		RETURN st
	END Statement;
BEGIN
	Log.StrLn("Statements");

	stats := Statement(p, ds);
	last := stats;
	WHILE ScanIfEqual(p, Scanner.Semicolon) DO
		IF (p.l # Scanner.End)
		 & (p.l # Scanner.Return)
		 & (p.l # Scanner.Else)
		 & (p.l # Scanner.Elsif)
		 & (p.l # Scanner.Until)
		THEN
			last.next := Statement(p, ds);
			last := last.next
		ELSIF p.settings.strictSemicolon THEN
			AddError(p, ErrExcessSemicolon);
			p.err := FALSE
		END
	END
	RETURN stats
END Statements;

PROCEDURE Return(VAR p: Parser; proc: Ast.Procedure);
BEGIN
	IF p.l = Scanner.Return THEN
		Log.StrLn("Return");

		Scan(p);
		CheckAst(p, Ast.ProcedureSetReturn(proc, Expression(p, proc)));
		IF p.l = Scanner.Semicolon THEN
			IF p.settings.strictSemicolon THEN
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
	Log.StrLn("ProcBody");
	declarations(p, proc);
	IF ScanIfEqual(p, Scanner.Begin) THEN
		proc.stats := Statements(p, proc)
	END;
	Return(p, proc);
	Expect(p, Scanner.End, ErrExpectEnd);
	IF p.l = Scanner.Ident THEN
		Log.StrLn("End Ident");
		IF ~Strings.IsEqualToChars(proc.name, p.s.buf, p.s.lexStart, p.s.lexEnd)
		THEN
			AddError(p, ErrEndProcedureNameNotMatch)
		END;
		Scan(p)
	ELSE
		AddError(p, ErrExpectProcedureName)
	END
END ProcBody;

PROCEDURE Procedure(VAR p: Parser; ds: Ast.Declarations);
VAR proc: Ast.Procedure;
	nameStart, nameEnd: INTEGER; 
BEGIN
	Log.StrLn("Procedure");

	Scan(p);
	ExpectIdent(p, nameStart, nameEnd, ErrExpectIdent);
	CheckAst(p,
		Ast.ProcedureAdd(ds, proc, p.s.buf, nameStart, nameEnd)
	);
	proc.mark := Mark(p);
	FormalParameters(p, ds, proc.header);
	Expect(p, Scanner.Semicolon, ErrExpectSemicolon);
	ProcBody(p, proc)
END Procedure;

PROCEDURE Declarations(VAR p: Parser; ds: Ast.Declarations);
BEGIN
	IF p.l = Scanner.Const THEN
		Consts(p, ds)
	END;
	IF p.l = Scanner.Type THEN
		Types(p, ds)
	END;
	IF p.l = Scanner.Var THEN
		Scan(p);
		Vars(p, ds)
	END;
	WHILE p.l = Scanner.Procedure DO
		Procedure(p, ds);
		Expect(p, Scanner.Semicolon, ErrExpectSemicolon)
	END
END Declarations;

PROCEDURE Imports(VAR p: Parser);
VAR nameOfs, nameEnd, realOfs, realEnd: INTEGER;
BEGIN
	REPEAT
		Scan(p);
		ExpectIdent(p, nameOfs, nameEnd, ErrExpectModuleName);
		IF ScanIfEqual(p, Scanner.Assign) THEN
			ExpectIdent(p, realOfs, realEnd, ErrExpectModuleName)
		ELSE
			realOfs := nameOfs;
			realEnd := nameEnd
		END;
		IF ~p.err THEN
			CheckAst(p, Ast.ImportAdd(p.module, p.s.buf,
				nameOfs, nameEnd, realOfs, realEnd, p.provider))
		ELSE
			p.err := FALSE;
			WHILE (p.l < Scanner.Import)
				& (p.l # Scanner.Comma)
				& (p.l # Scanner.Semicolon)
			DO
				Scan(p)
			END
		END
	UNTIL p.l # Scanner.Comma;
	Expect(p, Scanner.Semicolon, ErrExpectSemicolon)
END Imports;

PROCEDURE Module(VAR p: Parser);
BEGIN
	Log.StrLn("Module");

	Scan(p);
	IF p.l # Scanner.Module THEN
		p.l := ErrExpectModule
	ELSE
		Scan(p);
		IF p.l # Scanner.Ident THEN
			p.module := Ast.ModuleNew(" ", 0, 0);
			AddError(p, ErrExpectIdent)
		ELSE
			p.module := Ast.ModuleNew(p.s.buf, p.s.lexStart, p.s.lexEnd);
			Scan(p)
		END;
		Expect(p, Scanner.Semicolon, ErrExpectSemicolon);
		IF p.l = Scanner.Import THEN
			Imports(p)
		END;
		Declarations(p, p.module);
		IF ScanIfEqual(p, Scanner.Begin) THEN
			p.module.stats := Statements(p, p.module)
		END;
		Expect(p, Scanner.End, ErrExpectEnd);
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
		END
	END
END Module;

PROCEDURE PrintError(code: INTEGER);
END PrintError;

PROCEDURE DefaultOptions*(VAR opt: Options);
BEGIN
	V.Init(opt);
	opt.strictSemicolon := TRUE;
	opt.strictReturn := TRUE;
	opt.printError := PrintError
END DefaultOptions;

PROCEDURE Parse*(in: Stream.PIn; prov: Ast.Provider; opt: Options): Ast.Module;
VAR p: Parser;
BEGIN
	ASSERT(in # NIL);
	ASSERT(prov # NIL);
	V.Init(p);
	p.settings := opt;
	p.err := FALSE;
	p.module := NIL;
	p.provider := prov;
	Scanner.Init(p.s, in);

	Module(p)
	RETURN p.module
END Parse;

BEGIN
	declarations := Declarations;
	type := Type;
	statements := Statements;
	expression := Expression
END Parser.

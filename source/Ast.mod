(*  Abstract syntax tree support for Oberon-07
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
MODULE Ast;

IMPORT
	Log,
	Utf8,
	Limits,
	V,
	Scanner,
	Strings := StringStore,
	TranLim := TranslatorLimits,
	Arithmetic;

CONST
	ErrNo*                          = 0;
	ErrImportNameDuplicate*         = -1;
	ErrDeclarationNameDuplicate*    = -2;
	ErrMultExprDifferentTypes*      = -3;
	ErrDivExprDifferentTypes*       = -4;
	ErrNotBoolInLogicExpr*          = -5;
	ErrNotIntInDivOrMod*            = -6;
	ErrNotRealTypeForRealDiv*       = -7;
	ErrNotIntSetElem*               = -9;(*TODO*)
	ErrSetElemOutOfRange*           = -10;
	ErrSetLeftElemBiggerRightElem*  = -11;
	ErrAddExprDifferenTypes*        = -12;
	ErrNotNumberAndNotSetInMult*    = -13;
	ErrNotNumberAndNotSetInAdd*     = -14;
	ErrSignForBool*                 = -15;
	ErrRelationExprDifferenTypes*   = -17;
	ErrExprInWrongTypes*            = -18;
	ErrExprInRightNotSet*           = ErrExprInWrongTypes - 1;
	ErrExprInLeftNotInteger*        = ErrExprInWrongTypes - 2;
	ErrRelIncompatibleType*         = -21;
	ErrIsExtTypeNotRecord*          = -22;
	ErrIsExtVarNotRecord*           = -23;
	ErrConstDeclExprNotConst*       = -24;
	ErrAssignIncompatibleType*      = -25;
	ErrAssignExpectVarParam*        = -84;(*TODO*)
	ErrCallNotProc*                 = -26;
	ErrCallExprWithoutReturn*       = -27;
	ErrCallIgnoredReturn*           = ErrCallExprWithoutReturn - 1;
	ErrCallExcessParam*             = -29;
	ErrCallIncompatibleParamType*   = -30;
	ErrCallExpectVarParam*          = -31;
	ErrCallParamsNotEnough*         = -32;
	ErrCallVarPointerTypeNotSame*   = -58;(*TODO*)
	ErrCaseExprNotIntOrChar*        = -33;
	ErrCaseLabelNotIntOrChar*       = -68;(*TODO*)
	ErrCaseElemExprTypeMismatch*    = -34;
	ErrCaseElemDuplicate*           = -36;
	ErrCaseRangeLabelsTypeMismatch* = -37;
	ErrCaseLabelLeftNotLessRight*   = -38;
	ErrCaseLabelNotConst*           = -39;
	ErrProcHasNoReturn*             = -40;
	ErrReturnIncompatibleType*      = -41;
	ErrExpectReturn*                = -42;
	ErrDeclarationNotFound*         = -43;
	ErrDeclarationIsPrivate*        = -66;(*TODO*)
	ErrConstRecursive*              = -44;
	ErrImportModuleNotFound*        = -45;
	ErrImportModuleWithError*       = -46;
	ErrDerefToNotPointer*           = -47;
	ErrArrayItemToNotArray*         = -48;
	ErrArrayIndexNotInt*            = -49;
	ErrArrayIndexNegative*          = -50;
	ErrArrayIndexOutOfRange*        = -51;
	ErrGuardExpectRecordExt*        = -52;
	ErrGuardExpectPointerExt*       = -53;
	ErrGuardedTypeNotExtensible*    = -54;
	ErrDotSelectorToNotRecord*      = -55;
	ErrDeclarationNotVar*           = -56;
	ErrForIteratorNotInteger*       = -57;
	                                (*-58*)
	ErrNotBoolInIfCondition*        = -59;
	ErrNotBoolInWhileCondition*     = -60;
	ErrWhileConditionAlwaysFalse*   = -61;
	ErrWhileConditionAlwaysTrue*    = -62;
	ErrNotBoolInUntil*              = -63;
	ErrUntilAlwaysFalse*            = -64;
	ErrUntilAlwaysTrue*             = -65;
	                                (*-66*)
	ErrNegateNotBool*               = -67;
	                                (*-68*)
	ErrConstAddOverflow*            = -69;
	ErrConstSubOverflow*            = -ErrConstAddOverflow - 1;
	ErrConstMultOverflow*           = -71;
	ErrConstDivByZero*              = -72;

	ErrValueOutOfRangeOfByte*       = -73;
	ErrValueOutOfRangeOfChar*       = -74;

	ErrExpectIntExpr*               = -75;
	ErrExpectConstIntExpr*          = -76;
	ErrForByZero*                   = -77;
	ErrByShouldBePositive*          = -78;
	ErrByShouldBeNegative*          = -79;
	ErrForPossibleOverflow*         = -80;

	ErrVarUninitialized*            = -81;

	ErrDeclarationNotProc*          = -82;
	ErrProcNotCommandHaveParams*    = -83;
	                                (*-84*)

	ErrMin*                         = -100;

	NoId*                 =-1;
	IdInteger*            = 0;
	IdBoolean*            = 1;
	IdByte*               = 2;
	IdChar*               = 3;
	IdReal*               = 4;
	IdSet*                = 5;
	IdPointer*            = 6;
	PredefinedTypesCount* = 7;

	IdArray*            = 7;
	IdRecord*           = 8;
	IdRecordForward*    = 9;
	IdProcType*         = 10;
	IdNamed*            = 11;
	IdString*           = 12;

	IdDesignator*       = 20;
	IdRelation*         = 21;
	IdSum*              = 22;
	IdTerm*             = 23;
	IdNegate*           = 24;
	IdCall*             = 25;
	IdBraces*           = 26;
	IdIsExtension*      = 27;

	IdError*            = 31;

	IdImport*           = 32;
	IdConst*            = 33;
	IdVar*              = 34;

TYPE
	Module* = POINTER TO RModule;

	Provider* = POINTER TO RProvider;

	Provide* = PROCEDURE(p: Provider; host: Module;
	                     name: ARRAY OF CHAR; ofs, end: INTEGER): Module;

	RProvider* = RECORD(V.Base)
		get: Provide
	END;

	Node* = RECORD(V.Base)
		id*: INTEGER;
		comment*: Strings.String;
		ext*: V.PBase
	END;

	Error* = POINTER TO RECORD(Node)
		code*: INTEGER;
		line*, column*, tabs*, bytes*: INTEGER;
		next*: Error
	END;

	Type* = POINTER TO RType;
	Declaration* = POINTER TO RDeclaration;
	Declarations* = POINTER TO RDeclarations;
	RDeclaration* = RECORD(Node)
		module*: Module;
		up*: Declarations;

		name*: Strings.String;
		mark*: BOOLEAN;
		type*: Type;
		next*: Declaration
	END;

	Array* = POINTER TO RArray;
	RType* = RECORD(RDeclaration)
		array*: Array
	END;

	Byte* = POINTER TO RECORD(RType)
	END;

	Expression* = POINTER TO RExpression;

	Const* = POINTER TO RECORD(RDeclaration)
		expr*: Expression;
		finished*: BOOLEAN
	END;

	Construct* = POINTER TO RConstruct;
	RConstruct* = RECORD(RType) END;

	RArray* = RECORD(RConstruct)
		count*: Expression
	END;

	Pointer* = POINTER TO RPointer;

	Var* = POINTER TO RVar;
	RVar* = RECORD(RDeclaration)
		inited*: BOOLEAN
	END;

	Record* = POINTER TO RECORD(RConstruct)
		base*: Record;
		vars*: Var;
		pointer*: Pointer
	END;

	RPointer* = RECORD(RConstruct)
		(* type - ссылка на record *)
	END;

	FormalParam* = POINTER TO RECORD(RVar)
		isVar*: BOOLEAN
	END;

	ProcType* = POINTER TO RECORD(RConstruct)
		params*, end*: FormalParam
		(* type - возвращаемый тип *)
	END;

	Statement* = POINTER TO RStatement;
	Procedure* = POINTER TO RProcedure;
	RDeclarations* = RECORD(RDeclaration)
		start*, end*: Declaration;

		consts*: Const;
		types*: Type;
		vars*: Var;
		procedures*: Procedure;

		stats*: Statement
	END;

	Import* = POINTER TO RECORD(RDeclaration)
		(* Псевдо Declaration для организации единообразного поиска *)
	END;

	RModule* = RECORD(RDeclarations)
		store: Strings.Store;

		import*: Import;

		fixed: BOOLEAN;

		errors*, errLast: Error
	END;

	GeneralProcedure* = POINTER TO RGeneralProcedure;
	RGeneralProcedure* = RECORD(RDeclarations)
		header*: ProcType;
		return*: Expression
	END;

	RProcedure* = RECORD(RGeneralProcedure)
		distance*: INTEGER (* TODO заменить все distance на deep в записях *)
	END;

	PredefinedProcedure* = POINTER TO RECORD(RGeneralProcedure)
	END;

	Factor* = POINTER TO RFactor;

	RExpression* = RECORD(Node)
		type*: Type;

		value*: Factor
	END;

	Selector* = POINTER TO RSelector;
	RSelector* = RECORD(Node)
		next*: Selector
	END;

	SelPointer* = POINTER TO RECORD(RSelector) END;

	SelGuard* = POINTER TO RECORD(RSelector)
		type*: Type
	END;

	SelArray* = POINTER TO RECORD(RSelector)
		index*: Expression
	END;

	SelRecord* = POINTER TO RECORD(RSelector)
		var*: Var
	END;

	RFactor = RECORD(RExpression) END;

	Designator* = POINTER TO RECORD(RFactor)
		decl*: Declaration;
		sel*: Selector
	END;

	ExprNumber* = RECORD(RFactor)
	END;

	RExprInteger* = RECORD(ExprNumber)
		int*: INTEGER
	END;
	ExprInteger* = POINTER TO RExprInteger;

	ExprReal* = POINTER TO RECORD(ExprNumber)
		real*: REAL;
		str*: Strings.String (* Для генераторов обратно в текст *)
	END;

	ExprBoolean* = POINTER TO RECORD(RFactor)
		bool*: BOOLEAN
	END;

	ExprString* = POINTER TO RECORD(RExprInteger)
		string*: Strings.String;
		asChar*: BOOLEAN
	END;

	ExprNil* = POINTER TO RECORD(RFactor) END;

	ExprSet* = POINTER TO RECORD(RFactor)
		set*: SET;
		exprs*: ARRAY 2 OF Expression;

		next*: ExprSet
	END;

	ExprNegate* = POINTER TO RECORD(RFactor)
		expr*: Expression
	END;

	ExprBraces* = POINTER TO RECORD(RFactor)
		expr*: Expression
	END;

	ExprRelation* = POINTER TO RECORD(RExpression)
		relation*, distance*: INTEGER;
		exprs*: ARRAY 2 OF Expression
	END;

	ExprIsExtension* = POINTER TO RECORD(RExpression)
		designator*: Designator;
		extType*: Type
	END;

	ExprSum* = POINTER TO RECORD(RExpression)
		add*: INTEGER;
		term*: Expression;

		next*: ExprSum
	END;

	ExprTerm* = POINTER TO RECORD(RExpression)
		factor*: Factor;
		mult*: INTEGER;
		expr*: Expression (* Factor or ExprTerm *)
	END;

	Parameter* = POINTER TO RECORD(Node)
		expr*: Expression;
		next*: Parameter;
		distance*: INTEGER
	END;

	ExprCall* = POINTER TO RECORD(RFactor)
		designator*: Designator;
		params*: Parameter
	END;

	RStatement* = RECORD(Node)
		expr*: Expression;

		next*: Statement
	END;

	WhileIf* = POINTER TO RWhileIf;
	RWhileIf* = RECORD(RStatement)
		stats*: Statement;

		elsif*: WhileIf (* elsif with NIL expr mean else branch *)
	END;

	If* = POINTER TO RECORD(RWhileIf)
	END;

	CaseLabel* = POINTER TO RECORD(Node)
		value*: INTEGER;
		qual*: Declaration;

		right*, (* правая часть диапазона *)
		next*: CaseLabel (* следующий элемент списка меток *)
	END;
	CaseElement* = POINTER TO RECORD(Node)
		labels*: CaseLabel;
		stats*: Statement;
		next*: CaseElement
	END;
	Case* = POINTER TO RECORD(RStatement)
		elements*: CaseElement
	END;

	Repeat* = POINTER TO RECORD(RStatement)
		stats*: Statement
	END;

	For* = POINTER TO RECORD(RStatement)
		to*: Expression;
		var*: Var;
		by*: INTEGER;
		stats*: Statement
	END;

	While* = POINTER TO RECORD(RWhileIf)
	END;

	Assign* = POINTER TO RECORD(RStatement)
		designator*: Designator;(* *)
		distance*: INTEGER
	END;

	Call* = POINTER TO RECORD(RStatement)
	END;

	StatementError* = POINTER TO RECORD(RStatement)
	END;

VAR
	types: ARRAY PredefinedTypesCount OF Type;
	predefined: ARRAY Scanner.PredefinedLast - Scanner.PredefinedFirst + 1
	            OF Declaration;

PROCEDURE PutChars*(m: Module; VAR w: Strings.String;
                    s: ARRAY OF CHAR; begin, end: INTEGER);
BEGIN
	IF begin >= 0 THEN
		Strings.Put(m.store, w, s, begin, end)
	ELSE
		Strings.Put(m.store, w, "#error", 0, 5)
	END
END PutChars;

PROCEDURE NodeInit(VAR n: Node);
BEGIN
	V.Init(n);
	n.id := -1;
	Strings.Undef(n.comment);
	n.ext := NIL
END NodeInit;

PROCEDURE NodeSetComment*(VAR n: Node; m: Module;
                          com: ARRAY OF CHAR; ofs, end: INTEGER);
BEGIN
	ASSERT(~Strings.IsDefined(n.comment));
	PutChars(m, n.comment, com, ofs, end)
END NodeSetComment;

PROCEDURE DeclSetComment*(d: Declaration; com: ARRAY OF CHAR; ofs, end: INTEGER);
BEGIN
	NodeSetComment(d^, d.module, com, ofs, end)
END DeclSetComment;

PROCEDURE ModuleSetComment*(m: Module; com: ARRAY OF CHAR; ofs, end: INTEGER);
BEGIN
	NodeSetComment(m^, m, com, ofs, end)
END ModuleSetComment;

PROCEDURE DeclInit(d: Declaration; ds: Declarations);
BEGIN
	IF ds = NIL THEN
		d.module := NIL
	ELSIF (ds.module = NIL) & (ds IS Module) THEN
		d.module := ds(Module)
	ELSE
		d.module := ds.module
	END;
	d.up := ds;
	d.mark := FALSE;
	Strings.Undef(d.name);
	d.type := NIL;
	d.next := NIL
END DeclInit;

PROCEDURE DeclConnect(d: Declaration; ds: Declarations;
                      name: ARRAY OF CHAR; start, end: INTEGER);
BEGIN
	ASSERT(d # NIL);
	ASSERT(name[0] # 0X);
	ASSERT(~(d IS Module));
	ASSERT((ds.start = NIL) OR ~(ds.start IS Module));
	DeclInit(d, ds);
	IF ds.end # NIL THEN
		ASSERT(ds.end.next = NIL);
		ds.end.next := d
	ELSE
		ASSERT(ds.start = NIL);
		ds.start := d
	END;
	ASSERT(~(ds.start IS Module));
	ds.end := d;
	PutChars(d.module, d.name, name, start, end)
END DeclConnect;

PROCEDURE DeclarationsInit(d, up: Declarations);
BEGIN
	DeclInit(d, NIL);
	d.up := NIL;
	d.start := NIL;
	d.end := NIL;

	d.consts := NIL;
	d.types := NIL;
	d.vars := NIL;
	d.procedures := NIL;
	d.up := up;
	d.stats := NIL
END DeclarationsInit;

PROCEDURE DeclarationsConnect(d, up: Declarations;
                              name: ARRAY OF CHAR; start, end: INTEGER);
BEGIN
	DeclarationsInit(d, up);
	IF name[0] # 0X THEN
		DeclConnect(d, up, name, start, end)
	ELSE
		(* Record *)
		DeclInit(d, up)
	END;
	d.up := up
END DeclarationsConnect;

PROCEDURE ModuleNew*(name: ARRAY OF CHAR; begin, end: INTEGER): Module;
VAR m: Module;
BEGIN
	NEW(m);
	NodeInit(m^);
	DeclarationsInit(m, NIL);
	m.fixed := FALSE;
	m.import := NIL;
	m.errors := NIL; m.errLast := NIL;
	Strings.StoreInit(m.store);

	PutChars(m, m.name, name, begin, end);
	m.module := m;
	Log.Str("Module "); Log.Str(m.name.block.s); Log.StrLn(" ")
	RETURN m
END ModuleNew;

PROCEDURE GetModuleByName*(p: Provider; host: Module;
                           name: ARRAY OF CHAR; ofs, end: INTEGER): Module;
	RETURN p.get(p, host, name, ofs, end)
END GetModuleByName;

PROCEDURE ModuleEnd*(m: Module): INTEGER;
BEGIN
	ASSERT(~m.fixed);
	m.fixed := TRUE
	RETURN ErrNo
END ModuleEnd;

PROCEDURE ImportAdd*(m: Module; buf: ARRAY OF CHAR;
                     nameOfs, nameEnd, realOfs, realEnd: INTEGER;
                     p: Provider): INTEGER;
VAR imp: Import;
	i: Declaration;
	err: INTEGER;

	PROCEDURE Load(VAR res: Module; host: Module;
	               buf: ARRAY OF CHAR; realOfs, realEnd: INTEGER;
	               p: Provider): INTEGER;
	VAR n: ARRAY TranLim.MaxLenName OF CHAR;
		l, err: INTEGER;
		ret: BOOLEAN;
	BEGIN
		l := 0;
		ret := Strings.CopyChars(n, l, buf, realOfs, realEnd);
		ASSERT(ret);
		(* TODO сделать загрузку модуля из символьного файла *)
		Log.Str("Модуль '"); Log.Str(n); Log.StrLn("' загружается");
		res := GetModuleByName(p, host, buf, realOfs, realEnd);
		IF res = NIL THEN
			res := ModuleNew(buf, realOfs, realEnd);
			err := ErrImportModuleNotFound
		ELSIF res.errors # NIL THEN
			err := ErrImportModuleWithError
		ELSE
			err := ErrNo
		END;
		Log.Str("Модуль получен: "); Log.Int(ORD(res # NIL)); Log.Ln
		RETURN err
	END Load;

	PROCEDURE IsDup(i: Import; buf: ARRAY OF CHAR;
	                nameOfs, nameEnd, realOfs, realEnd: INTEGER): BOOLEAN;
		RETURN Strings.IsEqualToChars(i.name, buf, nameOfs, nameEnd)
			OR (realOfs # nameOfs) & (
			   (i.name.ofs # i.module.name.ofs)
			    OR (i.name.block # i.module.name.block)
			   )
			  & Strings.IsEqualToChars(i.module.name, buf, realOfs, realEnd)
	END IsDup;
BEGIN
	ASSERT(~m.fixed);

	i := m.import;
	ASSERT((i = NIL) OR (m.end IS Import));
	WHILE (i # NIL) & ~IsDup(i(Import), buf, nameOfs, nameEnd, realOfs, realEnd)
	DO    i := i.next
	END;
	IF i # NIL THEN
		err := ErrImportNameDuplicate
	ELSE
		NEW(imp); imp.id := IdImport;
		DeclConnect(imp, m, buf, nameOfs, nameEnd);
		imp.mark := TRUE;
		IF m.import = NIL THEN
			m.import := imp
		END;
		err := Load(imp.module, m, buf, realOfs, realEnd, p)
	END
	RETURN err
END ImportAdd;

PROCEDURE SearchName(d: Declaration;
                     buf: ARRAY OF CHAR; begin, end: INTEGER): Declaration;
BEGIN
	IF begin < 0 THEN
		d := NIL
	ELSE
		WHILE (d # NIL) & ~Strings.IsEqualToChars(d.name, buf, begin, end) DO
			ASSERT(~(d IS Module));
			d := d.next
		END
	END;
	IF (d # NIL) & FALSE THEN
		Log.Str("Найдено объявление ");
		WHILE begin # end DO
			Log.Char(buf[begin]);
			begin := (begin + 1) MOD (LEN(buf) - 1)
		END;
		Log.Str(" id = "); Log.Int(d.id); Log.Ln
	END
	RETURN d
END SearchName;

PROCEDURE ConstAdd*(ds: Declarations; buf: ARRAY OF CHAR; begin, end: INTEGER)
                   : INTEGER;
VAR c: Const;
	err: INTEGER;
BEGIN
	ASSERT(~ds.module.fixed);

	IF SearchName(ds.start, buf, begin, end) # NIL THEN
		err := ErrDeclarationNameDuplicate
	ELSE
		err := ErrNo
	END;
	NEW(c); c.id := IdConst;
	DeclConnect(c, ds, buf, begin, end);
	c.expr := NIL;
	c.finished := FALSE;
	IF ds.consts = NIL THEN
		ds.consts := c
	END
	RETURN err
END ConstAdd;

PROCEDURE ConstSetExpression*(const: Const; expr: Expression): INTEGER;
VAR err: INTEGER;
BEGIN
	const.finished := TRUE;
	err := ErrNo;
	IF expr # NIL THEN
		const.expr := expr;
		const.type := expr.type;
		IF (expr.type # NIL) & (expr.value = NIL) THEN
			err := ErrConstDeclExprNotConst
		END
	END
	RETURN err
END ConstSetExpression;

PROCEDURE TypeAdd*(ds: Declarations;
                   buf: ARRAY OF CHAR; begin, end: INTEGER;
                   VAR td: Type): INTEGER;
VAR d: Declaration;
	err: INTEGER;

	PROCEDURE MoveForwardDeclToLast(ds: Declarations; rec: Record);
	BEGIN
		(* TODO это может быть и не так *)
		ASSERT(rec.pointer.next = rec);
		rec.id := IdRecord;
		IF rec.next # NIL THEN
			rec.pointer.next := rec.next;
			rec.next := NIL;

			ds.end.next := rec;
			ds.end := rec
		END
	END MoveForwardDeclToLast;
BEGIN
	ASSERT(~ds.module.fixed);

	d := SearchName(ds.start, buf, begin, end);
	IF (d = NIL) OR (d.id = IdRecordForward) THEN
		err := ErrNo
	ELSE
		err := ErrDeclarationNameDuplicate
	END;
	IF (d = NIL) OR (err = ErrDeclarationNameDuplicate) THEN
		ASSERT(td # NIL);
		DeclConnect(td, ds, buf, begin, end);
		IF ds.types = NIL THEN
			ds.types := td
		END
	ELSE
		td := d(Type);
		MoveForwardDeclToLast(ds, d(Record))
	END
	RETURN err
END TypeAdd;

PROCEDURE ChecklessVarAdd(VAR v: Var; ds: Declarations;
                          buf: ARRAY OF CHAR; begin, end: INTEGER);
BEGIN
	NEW(v); v.id := IdVar;
	DeclConnect(v, ds, buf, begin, end);
	v.type := NIL;
	v.inited := FALSE;
	IF ds.vars = NIL THEN
		ds.vars := v
	END
END ChecklessVarAdd;

PROCEDURE VarAdd*(ds: Declarations;
                  buf: ARRAY OF CHAR; begin, end: INTEGER): INTEGER;
VAR v: Var;
	err: INTEGER;
BEGIN
	ASSERT((ds.module = NIL) OR ~ds.module.fixed);
	IF SearchName(ds.start, buf, begin, end) = NIL THEN
		err := ErrNo
	ELSE
		err := ErrDeclarationNameDuplicate
	END;
	ChecklessVarAdd(v, ds, buf, begin, end)
	RETURN err
END VarAdd;

PROCEDURE TInit(t: Type; id: INTEGER);
BEGIN
	NodeInit(t^);
	DeclInit(t, NIL);
	t.id := id;
	t.array := NIL
END TInit;

PROCEDURE ProcTypeNew*(): ProcType;
VAR p: ProcType;
BEGIN
	NEW(p); TInit(p, IdProcType);
	p.params := NIL;
	p.end := NIL
	RETURN p
END ProcTypeNew;

PROCEDURE ParamAddPredefined(proc: ProcType; type: Type; isVar: BOOLEAN);
VAR v: FormalParam;
BEGIN
	NEW(v); NodeInit(v^);
	IF proc.end = NIL THEN
		proc.params := v
	ELSE
		proc.end.next := v
	END;
	proc.end := v;

	v.module := NIL;
	v.mark := FALSE;
	v.next := NIL;

	v.type := type;
	v.isVar := isVar;
	v.inited := TRUE
END ParamAddPredefined;

PROCEDURE ParamAdd*(module: Module; proc: ProcType;
                    buf: ARRAY OF CHAR; begin, end: INTEGER): INTEGER;
VAR err: INTEGER;
BEGIN
	IF SearchName(proc.params, buf, begin, end) = NIL THEN
		err := ErrNo
	ELSE
		err := ErrDeclarationNameDuplicate
	END;
	ParamAddPredefined(proc, NIL, FALSE);
	PutChars(module, proc.end.name, buf, begin, end)
	RETURN err
END ParamAdd;

PROCEDURE AddError*(m: Module; error, line, column, tabs: INTEGER);
VAR e: Error;
BEGIN
	NEW(e); NodeInit(e^);
	e.next := NIL;
	e.code := error;
	e.line := line;
	e.column := column;
	e.tabs := tabs;
	IF m.errLast = NIL THEN
		m.errors := e
	ELSE
		m.errLast.next := e
	END;
	m.errLast := e
END AddError;

PROCEDURE TypeGet*(id: INTEGER): Type;
BEGIN
	(*Log.Str("TypeGet "); Log.Int(id); Log.Ln;*)
	ASSERT(types[id] # NIL)
	RETURN types[id]
END TypeGet;

PROCEDURE ArrayGet*(t: Type; count: Expression): Array;
VAR a: Array;
BEGIN
	IF (count # NIL) OR (t = NIL) OR (t.array = NIL) THEN
		NEW(a); TInit(a, IdArray);
		a.count := count;
		IF (t # NIL) & (count = NIL) THEN
			t.array := a
		END;
		a.type := t
	ELSE
		a := t.array
	END
	RETURN a
END ArrayGet;

PROCEDURE PointerGet*(t: Record): Pointer;
VAR p: Pointer;
BEGIN
	IF (t = NIL) OR (t.pointer = NIL) THEN
		NEW(p); TInit(p, IdPointer);
		p.type := t;
		IF t # NIL THEN
			t.pointer := p
		END
	ELSE
		p := t.pointer
	END
	RETURN p
END PointerGet;

PROCEDURE RecordSetBase*(r, base: Record);
BEGIN
	ASSERT(r.base = NIL);
	ASSERT(r.vars = NIL);
	r.base := base
END RecordSetBase;

PROCEDURE RecordNew*(ds: Declarations; base: Record): Record;
VAR r: Record;
BEGIN
	NEW(r); TInit(r, IdRecord);
	r.pointer := NIL;
	r.vars := NIL;
	r.base := NIL;
	RecordSetBase(r, base)
	RETURN r
END RecordNew;

PROCEDURE SearchPredefined(VAR buf: ARRAY OF CHAR; begin, end: INTEGER): Declaration;
VAR d: Declaration;
	l: INTEGER;
BEGIN
	l := Scanner.CheckPredefined(buf, begin, end);
	Log.Str("SearchPredefined "); Log.Int(l); Log.Ln;
	IF (l >= Scanner.PredefinedFirst) & (l <= Scanner.PredefinedLast) THEN
		d := predefined[l - Scanner.PredefinedFirst];
		ASSERT(d # NIL)
	ELSE
		d := NIL
	END
	RETURN d
END SearchPredefined;

PROCEDURE DeclarationSearch*(ds: Declarations; VAR buf: ARRAY OF CHAR;
                             begin, end: INTEGER): Declaration;
VAR d: Declaration;
BEGIN
	IF ds IS Procedure THEN
		d := SearchName(ds(Procedure).header.params, buf, begin, end)
	ELSE
		d := NIL
	END;
	IF d = NIL THEN
		d := SearchName(ds.start, buf, begin, end);
		IF ds IS Procedure THEN
			IF d = NIL THEN
				REPEAT
					ds := ds.up
				UNTIL (ds = NIL) OR (ds IS Module);
				IF ds # NIL THEN
					d := SearchName(ds.start, buf, begin, end)
				END
			END
		ELSE
			WHILE (d = NIL) & (ds.up # NIL) DO
				ds := ds.up;
				d := SearchName(ds.start, buf, begin, end)
			END
		END;
		IF d = NIL THEN
			d := SearchPredefined(buf, begin, end)
		END
	END
	RETURN d
END DeclarationSearch;

PROCEDURE DeclErrorNew*(ds: Declarations): Declaration;
VAR d: Declaration;
BEGIN
	NEW(d); d.id := IdError;
	DeclInit(d, ds);
	NEW(d.type); DeclInit(d.type, NIL); d.type.id := IdError
	RETURN d
END DeclErrorNew;

PROCEDURE DeclarationGet*(VAR d: Declaration; ds: Declarations;
                          VAR buf: ARRAY OF CHAR; begin, end: INTEGER): INTEGER;
VAR err: INTEGER;
BEGIN
	d := DeclarationSearch(ds, buf, begin, end);
	IF d = NIL THEN
		err := ErrDeclarationNotFound;
		d := DeclErrorNew(ds);
		DeclConnect(d, ds, buf, begin, end)
	ELSIF ~d.mark & (d.module # NIL) & d.module.fixed THEN
		err := ErrDeclarationIsPrivate
	ELSIF (d IS Const) & ~d(Const).finished THEN
		err := ErrConstRecursive;
		d(Const).finished := TRUE
	ELSE
		err := ErrNo
	END
	RETURN err
END DeclarationGet;

PROCEDURE VarGet*(VAR v: Var; ds: Declarations;
                  VAR buf: ARRAY OF CHAR; begin, end: INTEGER): INTEGER;
VAR err: INTEGER;
	d: Declaration;
BEGIN
	d := DeclarationSearch(ds, buf, begin, end);
	IF d = NIL THEN
		err := ErrDeclarationNotFound
	ELSIF d.id # IdVar THEN
		err := ErrDeclarationNotVar
	ELSE
		err := ErrNo
	END;
	IF err = ErrNo THEN
		v := d(Var);
		IF ~d.mark & d.module.fixed THEN
			err := ErrDeclarationIsPrivate
		END
	ELSE
		ChecklessVarAdd(v, ds, buf, begin, end)
	END
	RETURN err
END VarGet;

(* TODO итератор должен быть только локальным? *)
PROCEDURE ForIteratorGet*(VAR v: Var; ds: Declarations;
                          VAR buf: ARRAY OF CHAR; begin, end: INTEGER): INTEGER;
VAR err: INTEGER;
BEGIN
	err := VarGet(v, ds, buf, begin, end);
	IF v # NIL THEN
		IF v.type = NIL THEN
			v.type := TypeGet(IdInteger)
		ELSIF v.type.id # IdInteger THEN
			err := ErrForIteratorNotInteger
		END
	END
	RETURN err
END ForIteratorGet;

PROCEDURE ExprInit(e: Expression; id: INTEGER; t: Type);
BEGIN
	NodeInit(e^);
	e.id := id;
	e.type := t;
	e.value := NIL
END ExprInit;

PROCEDURE ExprIntegerNew*(int: INTEGER): ExprInteger;
VAR e: ExprInteger;
BEGIN
	NEW(e); ExprInit(e, IdInteger, TypeGet(IdInteger));
	e.int := int;
	e.value := e
	RETURN e
END ExprIntegerNew;

PROCEDURE ExprRealNew*(real: REAL; m: Module;
                       buf: ARRAY OF CHAR; begin, end: INTEGER): ExprReal;
VAR e: ExprReal;
BEGIN
	ASSERT(m # NIL);
	NEW(e); ExprInit(e, IdReal, TypeGet(IdReal));
	e.real := real;
	e.value := e;
	PutChars(m, e.str, buf, begin, end)
	RETURN e
END ExprRealNew;

PROCEDURE ExprRealNewByValue*(real: REAL): ExprReal;
VAR e: ExprReal;
BEGIN
	NEW(e); ExprInit(e, IdReal, TypeGet(IdReal));
	e.real := real;
	e.value := e;
	Strings.Undef(e.str)
	RETURN e
END ExprRealNewByValue;

PROCEDURE ExprBooleanNew*(bool: BOOLEAN): ExprBoolean;
VAR e: ExprBoolean;
BEGIN
	NEW(e); ExprInit(e, IdBoolean, TypeGet(IdBoolean));
	e.bool := bool;
	e.value := e
	RETURN e
END ExprBooleanNew;

PROCEDURE ExprStringNew*(m: Module; buf: ARRAY OF CHAR; begin, end: INTEGER): ExprString;
VAR e: ExprString;
	len: INTEGER;
BEGIN
	len := end - begin;
	IF len < 0 THEN
		len := len + LEN(buf) - 1
	END;
	DEC(len, 2);
	NEW(e); ExprInit(e, IdString, ArrayGet(TypeGet(IdChar), ExprIntegerNew(len + 1)));
	e.int := -1;
	e.asChar := FALSE;
	PutChars(m, e.string, buf, begin, end);
	e.value := e
	RETURN e
END ExprStringNew;

PROCEDURE ExprCharNew*(int: INTEGER): ExprString;
VAR e: ExprString;
BEGIN
	NEW(e); ExprInit(e, IdString, ArrayGet(TypeGet(IdChar), ExprIntegerNew(2)));
	Strings.Undef(e.string);
	e.int := int;
	e.asChar := TRUE;
	e.value := e
	RETURN e
END ExprCharNew;

PROCEDURE ExprNilNew*(): ExprNil;
VAR e: ExprNil;
BEGIN
	NEW(e); ExprInit(e, IdPointer, TypeGet(IdPointer));
	ASSERT(e.type.type = NIL);
	e.value := e
	RETURN e
END ExprNilNew;

PROCEDURE ExprErrNew*(): Expression;
	RETURN ExprNilNew() (* TODO *)
END ExprErrNew;

PROCEDURE ExprBracesNew*(expr: Expression): ExprBraces;
VAR e: ExprBraces;
BEGIN
	NEW(e); ExprInit(e, IdBraces, expr.type);
	e.expr := expr;
	e.value := expr.value
	RETURN e
END ExprBracesNew;

PROCEDURE ExprSetByValue*(set: SET): ExprSet;
VAR e: ExprSet;
BEGIN
	NEW(e); ExprInit(e, IdSet, TypeGet(IdSet));
	e.exprs[0] := NIL;
	e.exprs[1] := NIL;
	e.set := set;
	e.next := NIL
	RETURN e
END ExprSetByValue;

PROCEDURE ExprSetNew*(VAR e: ExprSet; expr1, expr2: Expression): INTEGER;
VAR err: INTEGER;

	PROCEDURE CheckRange(int: INTEGER): BOOLEAN;
		RETURN (int >= 0) & (int <= Limits.SetMax)
	END CheckRange;
BEGIN
	NEW(e); ExprInit(e, IdSet, TypeGet(IdSet));
	e.exprs[0] := expr1;
	e.exprs[1] := expr2;
	e.next := NIL;
	err := ErrNo;
	IF (expr1 = NIL) & (expr2 = NIL) THEN
		e.set := {}
	ELSIF (expr1 # NIL) & (expr1.type # NIL)
		& ((expr2 = NIL) OR (expr2.type # NIL))
	THEN
		IF (expr1.type.id # IdInteger)
		OR (expr2 # NIL) & (expr2.type.id # IdInteger)
		THEN
			err := ErrNotIntSetElem
		ELSIF (expr1.value # NIL) & ((expr2 = NIL) OR (expr2.value # NIL)) THEN
			IF ~CheckRange(expr1.value(ExprInteger).int)
			OR ((expr2 # NIL) & ~CheckRange(expr2.value(ExprInteger).int))
			THEN
				err := ErrSetElemOutOfRange
			ELSIF expr2 = NIL THEN
				e.set := {expr1.value(ExprInteger).int};
				e.value := e
			ELSIF expr1.value(ExprInteger).int > expr2.value(ExprInteger).int THEN
				err := ErrSetLeftElemBiggerRightElem
			ELSE
				e.set := {expr1.value(ExprInteger).int .. expr2.value(ExprInteger).int};
				e.value := e
			END
		END
	END
	RETURN err
END ExprSetNew;

PROCEDURE ExprNegateNew*(VAR neg: ExprNegate; expr: Expression): INTEGER;
VAR err: INTEGER;
BEGIN
	NEW(neg); ExprInit(neg, IdNegate, TypeGet(IdBoolean));
	neg.expr := expr;
	IF (expr.type # NIL) & (expr.type.id # IdBoolean) THEN
		err := ErrNegateNotBool
	ELSE
		err := ErrNo;
		IF expr.value # NIL THEN
			neg.value := ExprBooleanNew(~expr.value(ExprBoolean).bool)
		END
	END
	RETURN err
END ExprNegateNew;

PROCEDURE DesignatorNew*(VAR d: Designator; decl: Declaration): INTEGER;
BEGIN
	NEW(d); ExprInit(d, IdDesignator, NIL);
	d.decl := decl;
	d.sel := NIL;
	IF decl # NIL THEN
		d.type := decl.type;
		IF decl IS Const THEN
			d.value := decl(Const).expr.value
		ELSIF decl IS GeneralProcedure THEN
			d.type := decl(GeneralProcedure).header
		END
	END
	RETURN ErrNo
END DesignatorNew;

PROCEDURE CheckDesignatorAsValue*(d: Designator): INTEGER;
VAR err: INTEGER;
BEGIN
	IF (d.decl.up # NIL) & (d.decl.up.up # NIL)
	 & (d.decl IS Var)
	 & ~d.decl(Var).inited
	THEN
		err := ErrVarUninitialized;
		d.decl(Var).inited := TRUE
	ELSE
		err := ErrNo
	END
	RETURN err
END CheckDesignatorAsValue;

PROCEDURE IsRecordExtension*(VAR distance: INTEGER; t0, t1: Record): BOOLEAN;
VAR dist: INTEGER;
BEGIN
	IF (t0 # NIL) & (t1 # NIL) THEN
		dist := 0;
		REPEAT
			t1 := t1.base;
			INC(dist)
		UNTIL (t0 = t1) OR (t1 = NIL);
		IF t0 = t1 THEN
			distance := dist
		END
	ELSE
		t0 := NIL; t1 := NIL
	END;
	Log.Int(ORD(t0 = t1));
	Log.Ln
	RETURN t0 = t1
END IsRecordExtension;

PROCEDURE SelInit(s: Selector);
BEGIN
	NodeInit(s^);
	s.next := NIL
END SelInit;

PROCEDURE SelPointerNew*(VAR sel: Selector; VAR type: Type): INTEGER;
VAR sp: SelPointer;
	err: INTEGER;
BEGIN
	NEW(sp); SelInit(sp);
	sel := sp;
	IF type IS Pointer THEN
		err := ErrNo;
		type := type.type
	ELSE
		err := ErrDerefToNotPointer
	END
	RETURN err
END SelPointerNew;

PROCEDURE SelArrayNew*(VAR sel: Selector; VAR type: Type; index: Expression)
                      : INTEGER;
VAR sa: SelArray;
	err: INTEGER;
BEGIN
	NEW(sa); SelInit(sa);
	sa.index := index;
	sel := sa;
	IF ~(type IS Array) THEN
		err := ErrArrayItemToNotArray
	ELSIF index.type.id # IdInteger THEN
		err := ErrArrayIndexNotInt
	ELSIF (index.value # NIL) & (index.value(ExprInteger).int < 0) THEN
		err := ErrArrayIndexNegative
	ELSIF (index.value # NIL)
	    & (type(Array).count # NIL) & (type(Array).count.value # NIL)
	    & (index.value(ExprInteger).int >= type(Array).count.value(ExprInteger).int)
	THEN
		err := ErrArrayIndexOutOfRange
	ELSE
		err := ErrNo
	END;
	type := type.type
	RETURN err
END SelArrayNew;

PROCEDURE RecordVarSearch(r: Record; name: ARRAY OF CHAR; begin, end: INTEGER): Var;
VAR d: Declaration;
	v: Var;
BEGIN
	d := SearchName(r.vars, name, begin, end);
	WHILE (d = NIL) & (r.base # NIL) DO
		r := r.base;
		d := SearchName(r.vars, name, begin, end)
	END;
	IF d # NIL
	THEN v := d(Var)
	ELSE v := NIL
	END
	RETURN v
END RecordVarSearch;

PROCEDURE RecordChecklessVarAdd(r: Record; name: ARRAY OF CHAR;
                                begin, end: INTEGER): Var;
VAR v: Var;
	last: Declaration;
BEGIN
	NEW(v); DeclInit(v, NIL);
	v.module := r.module;
	PutChars(v.module, v.name, name, begin, end);
	IF r.vars = NIL THEN
		r.vars := v
	ELSE
		last := r.vars;
		WHILE last.next # NIL DO
			last := last.next
		END;
		last.next := v
	END
	RETURN v
END RecordChecklessVarAdd;

PROCEDURE RecordVarAdd*(VAR v: Var; r: Record;
                        name: ARRAY OF CHAR; begin, end: INTEGER): INTEGER;
VAR err: INTEGER;
BEGIN
	v := RecordVarSearch(r, name, begin, end);
	IF v = NIL
	THEN err := ErrNo
	ELSE err := ErrDeclarationNameDuplicate (* TODO *)
	END;
	v := RecordChecklessVarAdd(r, name, begin, end)
	RETURN err
END RecordVarAdd;

PROCEDURE RecordVarGet*(VAR v: Var; r: Record;
                        name: ARRAY OF CHAR; begin, end: INTEGER): INTEGER;
VAR err: INTEGER;
BEGIN
	v := RecordVarSearch(r, name, begin, end);
	IF v = NIL THEN
		err := ErrDeclarationNotFound; (* TODO *)
		v := RecordChecklessVarAdd(r, name, begin, end);
		v.type := TypeGet(IdInteger)
	ELSIF ~v.mark & v.module.fixed THEN
		err := ErrDeclarationIsPrivate;
		v.mark := TRUE
	ELSE
		err := ErrNo
	END
	RETURN err
END RecordVarGet;

PROCEDURE SelRecordNew*(VAR sel: Selector; VAR type: Type;
                        name: ARRAY OF CHAR; begin, end: INTEGER): INTEGER;
VAR sr: SelRecord;
	err: INTEGER;
	record: Record;
	var: Var;
BEGIN
	NEW(sr); SelInit(sr);
	var := NIL;
	err := ErrNo;
	IF type # NIL THEN
		IF ~(type.id IN {IdRecord, IdPointer}) THEN
			err := ErrDotSelectorToNotRecord
		ELSE
			IF type.id = IdRecord THEN
				record := type(Record)
			ELSIF type.type = NIL THEN
				record := NIL
			ELSE
				record := type.type(Record)
			END;
			IF record # NIL THEN
				err := RecordVarGet(var, record, name, begin, end);
				IF var # NIL THEN
					type := var.type
				ELSE
					type := NIL
				END
			END
		END
	END;
	sr.var := var;
	sel := sr
	RETURN err
END SelRecordNew;

PROCEDURE SelGuardNew*(VAR sel: Selector; VAR type: Type; guard: Declaration): INTEGER;
VAR sg: SelGuard;
	err, dist: INTEGER;
BEGIN
	NEW(sg); SelInit(sg);
	err := ErrNo;
	IF ~(type.id IN {IdRecord, IdPointer}) THEN
		err := ErrGuardedTypeNotExtensible
	ELSIF type.id = IdRecord THEN
		IF (guard = NIL)
		OR ~(guard IS Record)
		OR ~IsRecordExtension(dist, type(Record), guard(Record))
		THEN
			err := ErrGuardExpectRecordExt
		ELSE
			type := guard(Record)
		END
	ELSE
		IF (guard = NIL)
		OR ~(guard IS Pointer)
		OR ~IsRecordExtension(dist, type(Pointer).type(Record), guard(Pointer).type(Record))
		THEN
			err := ErrGuardExpectPointerExt
		ELSE
			type := guard(Pointer)
		END
	END;
	sg.type := type;
	sel := sg
	RETURN err
END SelGuardNew;

PROCEDURE CompatibleTypes*(VAR distance: INTEGER; t1, t2: Type): BOOLEAN;
VAR comp: BOOLEAN;

	PROCEDURE EqualProcTypes(t1, t2: ProcType): BOOLEAN;
	VAR comp: BOOLEAN;
		fp1, fp2: Declaration;
	BEGIN
		comp := t1.type = t2.type;
		IF comp THEN
			fp1 := t1.params;
			fp2 := t2.params;
			WHILE (fp1 # NIL) & (fp2 # NIL)
			    & (fp1 IS FormalParam) & (fp2 IS FormalParam)
			    & (fp1.type = fp2.type)
			    & (fp1(FormalParam).isVar = fp2(FormalParam).isVar)
			DO
				fp1 := fp1.next;
				fp2 := fp2.next
			END;
			comp := ((fp1 = NIL) OR ~(fp1 IS FormalParam))
			      & ((fp2 = NIL) OR ~(fp2 IS FormalParam))
		END
		RETURN comp
	END EqualProcTypes;
BEGIN
	distance := 0;
	(* совместимы, если ошибка в разборе *)
	comp := (t1 = NIL) OR (t2 = NIL);
	IF ~comp THEN
		comp := t1 = t2;
		Log.Str("Идентификаторы типов : ");
		Log.Int(t1.id); Log.Str(" : ");
		Log.Int(t2.id); Log.Ln;
		IF ~comp & (t1.id = t2.id)
		 & (t1.id IN {IdArray, IdPointer, IdRecord, IdProcType})
		THEN
			CASE t1.id OF
			  IdArray	: comp := CompatibleTypes(distance, t1.type, t2.type)
			| IdPointer	: comp := (t1.type = NIL) OR (t2.type = NIL)
			                   OR IsRecordExtension(distance, t1.type(Record),
			                                                  t2.type(Record))
			| IdRecord	: comp := IsRecordExtension(distance, t1(Record), t2(Record))
			| IdProcType: comp := EqualProcTypes(t1(ProcType), t2(ProcType))
			END
		END
	END
	RETURN comp
END CompatibleTypes;

PROCEDURE ExprIsExtensionNew*(VAR e: ExprIsExtension; VAR des: Expression;
                              type: Type): INTEGER;
VAR err: INTEGER;
BEGIN
	NEW(e); ExprInit(e, IdIsExtension, TypeGet(IdBoolean));
	e.designator := NIL;
	e.extType := type;
	err := ErrNo;
	IF (type # NIL) & ~(type.id IN {IdPointer, IdRecord}) THEN
		err := ErrIsExtTypeNotRecord
	ELSIF des # NIL THEN
		IF des IS Designator THEN
			e.designator := des(Designator);
			(* TODO проверка возможности проверки *)
			IF (des.type # NIL) & ~(des.type.id IN {IdPointer, IdRecord}) THEN
				err := ErrIsExtVarNotRecord
			END
		ELSE
			err := ErrIsExtVarNotRecord
		END
	END
	RETURN err
END ExprIsExtensionNew;

PROCEDURE CompatibleAsCharAndString(t1: Type; VAR e2: Expression): BOOLEAN;
VAR ret: BOOLEAN;
BEGIN
	Log.Str("1 CompatibleAsCharAndString ");
	Log.Int(ORD((e2.value # NIL)));
	Log.Ln;
	ret := (t1.id = IdChar)
	     & (e2.value # NIL)
	     & (e2.value IS ExprString)
	     & (e2.value(ExprString).int >= 0);
	IF ret & ~e2.value(ExprString).asChar THEN
		IF e2 IS ExprString THEN
			e2 := ExprCharNew(e2.value(ExprString).int)
		ELSE
			e2.value := ExprCharNew(e2.value(ExprString).int)
		END;
		ASSERT(e2.value(ExprString).asChar)
	END
	RETURN ret
END CompatibleAsCharAndString;

PROCEDURE CompatibleAsIntAndByte(t1, t2: Type): BOOLEAN;
	RETURN (t1.id IN {IdInteger, IdByte}) & (t2.id IN {IdInteger, IdByte})
END CompatibleAsIntAndByte;

PROCEDURE ExprRelationNew*(VAR e: ExprRelation; expr1: Expression;
                           relation: INTEGER; expr2: Expression): INTEGER;
VAR err: INTEGER;
	res: BOOLEAN;
	v1, v2: Expression;

	PROCEDURE CheckType(t1, t2: Type; VAR e1, e2: Expression; relation: INTEGER;
	                    VAR distance, err: INTEGER): BOOLEAN;
	VAR continue: BOOLEAN;
		dist1, dist2: INTEGER;
	BEGIN
		dist1 := 0;
		dist2 := 0;
		IF (t1 = NIL) OR (t2 = NIL) THEN
			continue := FALSE
		ELSIF relation = Scanner.In THEN
			continue := (t1.id = IdInteger) & (t2.id = IdSet);
			IF ~continue THEN
				err := ErrExprInWrongTypes - 3 + ORD(t1.id # IdInteger)
				                               + ORD(t2.id # IdSet) * 2
			END
		ELSIF ~CompatibleTypes(dist1, t1, t2)
		    & ~CompatibleTypes(dist2, t2, t1)
		    & ~CompatibleAsCharAndString(t1, e2)
		    & ~CompatibleAsCharAndString(t2, e1)
		    & ~CompatibleAsIntAndByte(t1, t2)
		THEN
			err := ErrRelationExprDifferenTypes;
			continue := FALSE
		ELSIF (t1.id IN {IdInteger, IdReal, IdChar})
		   OR (t1.id = IdArray) & (t1.type.id = IdChar)
		THEN
			continue := TRUE
		ELSIF t1.id IN {IdRecord, IdArray} THEN
			continue := FALSE;
			err := ErrRelIncompatibleType
		ELSE
			continue := (relation = Scanner.Equal) OR (relation = Scanner.Inequal)
			         OR (t1.id = IdSet) & (
			                (relation = Scanner.LessEqual)
			                OR
			                (relation = Scanner.GreaterEqual)
			            );
			IF ~continue THEN
				err := ErrRelIncompatibleType
			END
		END;
		distance := dist1 - dist2
		RETURN continue
	END CheckType;
BEGIN
	ASSERT((relation >= Scanner.RelationFirst) & (relation < Scanner.RelationLast));

	NEW(e); ExprInit(e, IdRelation, TypeGet(IdBoolean));
	e.exprs[0] := expr1;
	e.exprs[1] := expr2;
	e.relation := relation;
	err := ErrNo;
	IF (expr1 # NIL) & (expr2 # NIL)
	 & CheckType(expr1.type, expr2.type, e.exprs[0], e.exprs[1], relation, e.distance, err)
	 & (expr1.value # NIL) & (expr2.value # NIL) & (relation # Scanner.Is)
	THEN
		v1 := e.exprs[0].value;
		v2 := e.exprs[1].value;
		CASE relation OF
		  Scanner.Equal:
			CASE expr1.type.id OF
			  IdInteger, IdChar : res := v1(ExprInteger).int = v2(ExprInteger).int
			| IdBoolean  : res := v1(ExprBoolean).bool = v2(ExprBoolean).bool
			| IdReal     : res := v1(ExprReal).real = v2(ExprReal).real
			| IdSet      : res := v1(ExprSet).set = v2(ExprSet).set
			| IdPointer  : (* TODO *) res := FALSE
			| IdArray    : (* TODO *) res := FALSE
			| IdProcType : (* TODO *) res := FALSE
			END
		| Scanner.Inequal:
			CASE expr1.type.id OF
			  IdInteger, IdChar : res := v1(ExprInteger).int # v2(ExprInteger).int
			| IdBoolean         : res := v1(ExprBoolean).bool # v2(ExprBoolean).bool
			| IdReal            : res := v1(ExprReal).real # v2(ExprReal).real
			| IdSet             : res := v1(ExprSet).set # v2(ExprSet).set
			| IdPointer         : (* TODO *) res := FALSE
			| IdArray           : (* TODO *) res := FALSE
			| IdProcType        : (* TODO *) res := FALSE
			END
		| Scanner.Less:
			CASE expr1.type.id OF
			  IdInteger, IdChar : res := v1(ExprInteger).int < v2(ExprInteger).int
			| IdReal            : res := v1(ExprReal).real < v2(ExprReal).real
			| IdArray           : (* TODO *) res := FALSE
			END
		| Scanner.LessEqual:
			CASE expr1.type.id OF
			  IdInteger, IdChar : res := v1(ExprInteger).int <= v2(ExprInteger).int
			| IdReal            : res := v1(ExprReal).real <= v2(ExprReal).real
			| IdSet             : res := v1(ExprSet).set <= v2(ExprSet).set
			| IdArray           : (* TODO *) res := FALSE
			END
		| Scanner.Greater:
			CASE expr1.type.id OF
			  IdInteger, IdChar : res := v1(ExprInteger).int > v2(ExprInteger).int
			| IdReal            : res := v1(ExprReal).real > v2(ExprReal).real
			| IdArray           : (* TODO *) res := FALSE
			END
		| Scanner.GreaterEqual:
			CASE expr1.type.id OF
			  IdInteger, IdChar : res := v1(ExprInteger).int >= v2(ExprInteger).int
			| IdReal            : res := v1(ExprReal).real >= v2(ExprReal).real
			| IdSet             : res := v1(ExprSet).set >= v2(ExprSet).set
			| IdArray           : (* TODO *) res := FALSE
			END
		| Scanner.In:
			res := v1(ExprInteger).int IN v2(ExprSet).set
		END;
		e.value := ExprBooleanNew(res)
	END
	RETURN err
END ExprRelationNew;

PROCEDURE LexToSign(lex: INTEGER): INTEGER;
VAR s: INTEGER;
BEGIN
	IF (lex = -1) OR (lex = Scanner.Plus) THEN
		s := +1
	ELSE
		ASSERT(lex = Scanner.Minus);
		s := -1
	END
	RETURN s
END LexToSign;

PROCEDURE ExprSumCreate(VAR e: ExprSum; add: INTEGER; sum, term: Expression);
VAR t: Type;
BEGIN
	NEW(e);
	IF (sum # NIL) & (sum.type # NIL)
	 & (sum.type.id IN {IdReal, IdInteger, IdByte})
	THEN
		t := sum.type
	ELSIF term # NIL THEN
		t := term.type
	ELSE
		t := NIL
	END;
	IF (t # NIL) & (t.id = IdByte) THEN
		t := TypeGet(IdInteger)
	END;
	ExprInit(e, IdSum, t);
	e.next := NIL;
	e.add := add;
	e.term := term
END ExprSumCreate;

PROCEDURE ExprSumNew*(VAR e: ExprSum; add: INTEGER; term: Expression): INTEGER;
VAR err: INTEGER;
BEGIN
	ASSERT((add = -1) OR (add = Scanner.Plus) OR (add = Scanner.Minus));
	ExprSumCreate(e, add, NIL, term);
	err := ErrNo;
	IF e.type # NIL THEN
		IF ~(e.type.id IN {IdByte, IdInteger, IdReal, IdSet}) & (add # -1) THEN
			IF e.type.id # IdBoolean THEN
				err := ErrNotNumberAndNotSetInAdd
			ELSE
				err := ErrSignForBool
			END
		ELSIF term.value # NIL THEN
			CASE e.type.id OF
			  IdInteger:
				e.value := ExprIntegerNew(
					term.value(ExprInteger).int * LexToSign(add)
				)
			| IdReal:
				e.value := ExprRealNewByValue(
					term.value(ExprReal).real * FLT(LexToSign(add))
				)
			| IdSet:
				IF add # Scanner.Minus THEN
					e.value := ExprSetByValue(term.value(ExprSet).set)
				ELSE
					e.value := ExprSetByValue(-term.value(ExprSet).set)
				END
			| IdBoolean:
				e.value := ExprBooleanNew(term.value(ExprBoolean).bool)
			END
		END
	END
	RETURN err
END ExprSumNew;

PROCEDURE ExprSumAdd*(fullSum: Expression; VAR lastAdder: ExprSum;
                      add: INTEGER; term: Expression): INTEGER;
VAR e: ExprSum;
	err: INTEGER;

	PROCEDURE CheckType(e1, e2: Expression; add: INTEGER; VAR err: INTEGER): BOOLEAN;
	VAR continue: BOOLEAN;
	BEGIN
		IF (e1.type = NIL) OR (e2.type = NIL) THEN
			continue := FALSE
		ELSIF (e1.type.id # e2.type.id) &
		     ~CompatibleAsIntAndByte(e1.type, e2.type)
		THEN
			err := ErrAddExprDifferenTypes;
			continue := FALSE
		ELSIF add = Scanner.Or THEN
			continue := e1.type.id = IdBoolean;
			IF ~continue THEN
				err := ErrNotBoolInLogicExpr
			END
		ELSE
			continue := e1.type.id IN {IdInteger, IdReal, IdSet};
			IF ~continue THEN
				err := ErrNotNumberAndNotSetInAdd
			END
		END
		RETURN continue
	END CheckType;
BEGIN
	ASSERT((add = Scanner.Plus) OR (add = Scanner.Minus) OR (add = Scanner.Or));

	ExprSumCreate(e, add, fullSum, term);
	err := ErrNo;
	IF (fullSum # NIL) & (term # NIL)
	 & CheckType(fullSum, term, add, err)
	 & (fullSum.value # NIL) & (term.value # NIL)
	THEN
		IF add = Scanner.Or THEN
			IF term.value(ExprBoolean).bool THEN
				fullSum.value(ExprBoolean).bool := TRUE
			END
		ELSE
			CASE term.type.id OF
			  IdInteger:
				IF ~Arithmetic.Add(fullSum.value(ExprInteger).int,
						fullSum.value(ExprInteger).int,
						term.value(ExprInteger).int * LexToSign(add))
				THEN
					err := ErrConstAddOverflow + ORD(add = Scanner.Minus)
				END
			| IdReal:
				fullSum.value(ExprReal).real :=
				    fullSum.value(ExprReal).real
				  + term.value(ExprReal).real * FLT(LexToSign(add))
			| IdSet:
				IF add = Scanner.Plus THEN
					fullSum.value(ExprSet).set :=
						fullSum.value(ExprSet).set + term.value(ExprSet).set
				ELSE
					fullSum.value(ExprSet).set :=
						fullSum.value(ExprSet).set - term.value(ExprSet).set
				END
			END
		END
	ELSIF fullSum # NIL THEN
		fullSum.value := NIL
	END;

	IF lastAdder # NIL THEN
		lastAdder.next := e
	END;
	lastAdder := e

	RETURN err
END ExprSumAdd;

PROCEDURE MultCalc(res: Expression; mult: INTEGER; b: Expression): INTEGER;
VAR err: INTEGER;
	bool: BOOLEAN;

	PROCEDURE CheckType(e1, e2: Expression; mult: INTEGER; VAR err: INTEGER): BOOLEAN;
	VAR continue: BOOLEAN;
	BEGIN
		IF (e1.type = NIL) OR (e2.type = NIL) THEN
			continue := FALSE
		ELSIF (e1.type.id # e2.type.id)
		    & ~CompatibleAsIntAndByte(e1.type, e2.type)
		THEN
			continue := FALSE;
			IF mult = Scanner.And THEN
				err := ErrNotBoolInLogicExpr
			ELSIF mult = Scanner.Asterisk THEN
				err := ErrMultExprDifferentTypes
			ELSE
				err := ErrDivExprDifferentTypes
			END
		ELSIF mult = Scanner.And THEN
			continue := e1.type.id = IdBoolean;
			IF ~continue THEN
				err := ErrNotBoolInLogicExpr
			END
		ELSIF ~(e1.type.id IN {IdInteger, IdReal, IdSet}) THEN
			continue := FALSE;
			err := ErrNotNumberAndNotSetInMult
		ELSIF (mult = Scanner.Div) OR (mult = Scanner.Mod) THEN
			continue := e1.type.id = IdInteger;
			IF ~continue THEN
				err := ErrNotIntInDivOrMod
			END
		ELSIF (mult = Scanner.Slash) & (e1.type.id = IdInteger) THEN
			continue := FALSE;
			err := ErrNotRealTypeForRealDiv
		ELSE
			continue := TRUE
		END
		RETURN continue
	END CheckType;

	PROCEDURE Int(res: Expression; mult: INTEGER; b: Expression; VAR err: INTEGER);
	VAR i, i1, i2: INTEGER;
	BEGIN
		i1 := res.value(ExprInteger).int;
		i2 := b.value(ExprInteger).int;
		IF mult = Scanner.Asterisk THEN
			IF ~Arithmetic.Mul(i, i1, i2) THEN
				err := ErrConstMultOverflow
			END
		ELSIF i2 = 0 THEN
			err := ErrConstDivByZero
		ELSIF mult = Scanner.Div THEN
			i := i1 DIV i2
		ELSE
			i := i1 MOD i2
		END;
		IF err = ErrNo THEN
			res.value := ExprIntegerNew(i)
		ELSE
			res.value := NIL
		END
	END Int;

	PROCEDURE Rl(res: Expression; mult: INTEGER; b: Expression);
	VAR r, r1, r2: REAL;
	BEGIN
		r1 := res.value(ExprReal).real;
		r2 := b.value(ExprReal).real;
		IF mult = Scanner.Asterisk THEN
			r := r1 * r2
		ELSE
			r := r1 / r2
		END;
		IF res.value = NIL THEN
			res.value := ExprRealNewByValue(r)
		ELSE
			res.value(ExprReal).real := r
		END
	END Rl;

	PROCEDURE St(res: Expression; mult: INTEGER; b: Expression);
	VAR s, s1, s2: SET;
	BEGIN
		s1 := res.value(ExprSet).set;
		s2 := b.value(ExprSet).set;
		IF mult = Scanner.Asterisk THEN
			s := s1 * s2
		ELSE
			s := s1 / s2
		END;
		IF res.value = NIL THEN
			res.value := ExprSetByValue(s)
		ELSE
			res.value(ExprSet).set := s
		END
	END St;
BEGIN
	err := ErrNo;
	IF CheckType(res, b, mult, err) & (res.value # NIL) & (b.value # NIL) THEN
		CASE res.type.id OF
		  IdInteger:
			Int(res, mult, b, err)
		| IdReal:
			Rl(res, mult, b)
		| IdBoolean:
			bool := res.value(ExprBoolean).bool & b.value(ExprBoolean).bool;
			IF res.value = NIL THEN
				res.value := ExprBooleanNew(bool)
			ELSE
				res.value(ExprBoolean).bool := bool
			END
		| IdSet:
			St(res, mult, b)
		END
	ELSE
		res.value := NIL;
		IF ((mult - Scanner.Div) IN {0, 1})
		 & (b.value # NIL) & (b.value.type.id = IdInteger)
		 & (b.value(ExprInteger).int = 0)
		THEN
			err := ErrConstDivByZero
		END
	END
	RETURN err
END MultCalc;

PROCEDURE ExprTermGeneral(VAR e: ExprTerm; result: Expression; factor: Factor;
                          mult: INTEGER; factorOrTerm: Expression): INTEGER;
VAR t: Type;
BEGIN
	ASSERT((mult >= Scanner.MultFirst) & (mult <= Scanner.MultLast));
	ASSERT((factorOrTerm IS Factor) OR (factorOrTerm IS ExprTerm));

	t := factorOrTerm.type;
	IF (t # NIL) & (t.id = IdByte) THEN
		t := TypeGet(IdInteger)
	END;

	NEW(e); ExprInit(e, IdTerm, t (* TODO *));
	IF result = NIL THEN
		result := e;
		IF factor # NIL THEN
			e.value := factor.value
		END
	END;
	e.factor := factor;
	e.mult := mult;
	e.expr := factorOrTerm;
	e.factor := factor
	RETURN MultCalc(result, mult, factorOrTerm)
END ExprTermGeneral;

PROCEDURE ExprTermNew*(VAR e: ExprTerm; factor: Factor; mult: INTEGER;
                       factorOrTerm: Expression): INTEGER;
	RETURN ExprTermGeneral(e, NIL, factor, mult, factorOrTerm)
END ExprTermNew;

PROCEDURE ExprTermAdd*(fullTerm: Expression; VAR lastTerm: ExprTerm;
                       mult: INTEGER; factorOrTerm: Expression): INTEGER;
VAR e: ExprTerm;
	err: INTEGER;
BEGIN
	IF lastTerm # NIL THEN
		ASSERT(lastTerm.expr # NIL);
		err := ExprTermGeneral(e, fullTerm, lastTerm.expr(Factor),
		                       mult, factorOrTerm);
		lastTerm.expr := e;
		lastTerm := e
	ELSE
		err := ExprTermGeneral(lastTerm, fullTerm, NIL, mult, factorOrTerm)
	END
	RETURN err
END ExprTermAdd;

PROCEDURE ExprCallCreate(VAR e: ExprCall; des: Designator; func: BOOLEAN): INTEGER;
VAR err: INTEGER;
	t: Type;
	pt: ProcType;
BEGIN
	t := NIL;
	err := ErrNo;
	IF des # NIL THEN
		Log.Str("ExprCallCreate des.decl.id = "); Log.Int(des.decl.id);
		Log.Ln;
		IF des.decl.id = IdError THEN
			pt := ProcTypeNew();
			des.decl.type := pt;
			des.type := pt
		ELSIF des.type # NIL THEN
			IF des.type IS ProcType THEN
				t := des.type.type;
				IF (t # NIL) # func THEN
					err := ErrCallIgnoredReturn + ORD(func)
				END
			ELSE
				err := ErrCallNotProc
			END
		END
	END;
	NEW(e); ExprInit(e, IdCall, t);
	e.designator := des;
	e.params := NIL
	RETURN err
END ExprCallCreate;

PROCEDURE ExprCallNew*(VAR e: ExprCall; des: Designator): INTEGER;
	RETURN ExprCallCreate(e, des, TRUE)
END ExprCallNew;

PROCEDURE IsChangeable*(cur: Module; v: Var): BOOLEAN;
BEGIN
	Log.StrLn("IsChangeable")
	RETURN (*(v.module = cur) &*)
		(~(v IS FormalParam)
	 OR (v(FormalParam).isVar)
	 OR ~((v.type IS Array)
	 OR (v.type IS Record)))
END IsChangeable;

PROCEDURE IsVar*(e: Expression): BOOLEAN;
BEGIN
	Log.Str("IsVar: e.id = "); Log.Int(e.id); Log.Ln
	RETURN (e IS Designator) & (e(Designator).decl IS Var)
END IsVar;

PROCEDURE ProcedureAdd*(ds: Declarations; VAR p: Procedure;
                        buf: ARRAY OF CHAR; begin, end: INTEGER): INTEGER;
VAR err: INTEGER;
BEGIN
	IF SearchName(ds.start, buf, begin, end) = NIL THEN
		err := ErrNo
	ELSE
		err := ErrDeclarationNameDuplicate
	END;
	NEW(p); NodeInit(p^);
	DeclarationsConnect(p, ds, buf, begin, end);
	p.header := ProcTypeNew();
	p.id := IdProcType;
	p.return := NIL;
	IF ds.procedures = NIL THEN
		ds.procedures := p
	END
	RETURN err
END ProcedureAdd;

PROCEDURE ProcedureSetReturn*(p: Procedure; e: Expression): INTEGER;
VAR err: INTEGER;
BEGIN
	ASSERT(p.return = NIL);
	err := ErrNo;
	IF p.header.type = NIL THEN
		err := ErrProcHasNoReturn
	ELSIF e # NIL THEN
		p.return := e;
		IF ~CompatibleTypes(p.distance, p.header.type, e.type)
		 & ~CompatibleAsCharAndString(p.header.type, p.return)
		THEN
			IF ~CompatibleAsIntAndByte(p.header.type, p.return.type) THEN
				err := ErrReturnIncompatibleType
			ELSIF (p.return.type.id = IdByte)
			    & (e.value # NIL)
			    & ~Limits.InByteRange(e.value(ExprInteger).int)
			THEN
				err := ErrValueOutOfRangeOfByte
			END
		END
	END
	RETURN err
END ProcedureSetReturn;

PROCEDURE ProcedureEnd*(p: Procedure): INTEGER;
VAR err: INTEGER;
BEGIN
	IF (p.header.type # NIL) & (p.return = NIL) THEN
		err := ErrExpectReturn
	ELSE
		err := ErrNo
	END
	RETURN err
END ProcedureEnd;

PROCEDURE CallParamNew*(call: ExprCall; VAR lastParam: Parameter; e: Expression;
                        VAR currentFormalParam: FormalParam): INTEGER;
VAR err, distance: INTEGER;

	PROCEDURE TypeVariation(call: ExprCall; tp: Type; fp: FormalParam): BOOLEAN;
	VAR comp: BOOLEAN;
		id: INTEGER;
	BEGIN
		comp := call.designator.decl IS PredefinedProcedure;
		IF comp THEN
			id := call.designator.decl.id;
			IF id = Scanner.New THEN
				comp := tp.id = IdPointer
			ELSIF id = Scanner.Abs THEN
				comp := tp.id IN {IdInteger, IdReal};
				call.type := tp
			ELSIF id = Scanner.Len THEN
				comp := tp.id = IdArray
			ELSE
				comp := (id = Scanner.Ord)
				      & (tp.id IN {IdInteger, IdChar, IdSet, IdBoolean})
			END
		END
		RETURN comp
	END TypeVariation;

	PROCEDURE ParamsVariation(call: ExprCall; e: Expression; VAR err: INTEGER);
	VAR id: INTEGER;
	BEGIN
		id := call.designator.decl.id;
		IF id # IdError THEN
			IF (id # Scanner.Inc) & (id # Scanner.Dec)
			OR (call.params.next # NIL)
			THEN
				err := ErrCallExcessParam
			ELSIF e.type.id # IdInteger THEN
				err := ErrCallIncompatibleParamType
			END
		END
	END ParamsVariation;
BEGIN
	err := ErrNo;
	IF currentFormalParam # NIL THEN
		IF ~CompatibleTypes(distance, currentFormalParam.type, e.type)
		 & ~CompatibleAsCharAndString(currentFormalParam.type, e)
		 &     (currentFormalParam.isVar
		    OR ~CompatibleAsIntAndByte(currentFormalParam.type, e.type)
		       )
		 & ~TypeVariation(call, e.type, currentFormalParam)
		THEN
			err := ErrCallIncompatibleParamType
		ELSIF currentFormalParam.isVar THEN
			IF ~(IsVar(e)
			   & IsChangeable(call.designator.decl.module, e(Designator).decl(Var))
			    )
			THEN
				err := ErrCallExpectVarParam
			ELSIF (e.type # NIL) & (e.type.id = IdPointer)
			    & (e.type # currentFormalParam.type)
			    & (currentFormalParam.type # NIL)
			    & (currentFormalParam.type.type # NIL)
			    & (e.type.type # NIL)
			THEN
				err := ErrCallVarPointerTypeNotSame
			END
		ELSIF (currentFormalParam.type.id = IdByte) & (e.type.id = IdInteger)
		    & (e.value # NIL) & ~Limits.InByteRange(e.value(ExprInteger).int)
		THEN
			err := ErrValueOutOfRangeOfByte
		END;
		IF (currentFormalParam.next # NIL)
		 & (currentFormalParam.next IS FormalParam)
		THEN
			currentFormalParam := currentFormalParam.next(FormalParam)
		ELSE
			currentFormalParam := NIL
		END
	ELSE
		distance := 0;
		ParamsVariation(call, e, err)
	END;

	IF lastParam = NIL THEN
		NEW(lastParam)
	ELSE
		ASSERT(lastParam.next = NIL);
		NEW(lastParam.next);
		lastParam := lastParam.next
	END;
	NodeInit(lastParam^);
	lastParam.expr := e;
	lastParam.distance := distance;
	lastParam.next := NIL
	RETURN err
END CallParamNew;

PROCEDURE CallParamsEnd*(call: ExprCall; currentFormalParam: FormalParam): INTEGER;
VAR v: Factor;
	err: INTEGER;
BEGIN
	err := ErrNo;
	IF (currentFormalParam = NIL)
	 & (call.designator.decl IS PredefinedProcedure)
	 (* TODO заменить на общую проверку корректности выбора параметра *)
	 & (call.designator.decl.type.type # NIL)
	THEN
		v := call.params.expr.value;
		IF (v # NIL) & (call.designator.decl.id # Scanner.Len) THEN
			CASE call.designator.decl.id OF
			  Scanner.Abs:
				IF v.type.id = IdReal THEN
					IF v(ExprReal).real < 0.0 THEN
						call.value := ExprRealNewByValue(-v(ExprReal).real)
					ELSE
						call.value := v
					END
				ELSE ASSERT(v.type.id = IdInteger);
					call.value := ExprIntegerNew(ABS(v(ExprInteger).int))
				END
			| Scanner.Odd:
				call.value := ExprBooleanNew(ODD(v(ExprInteger).int))
			| Scanner.Lsl:
				IF call.params.next.expr.value # NIL THEN
					call.value := ExprIntegerNew(LSL(
						v(ExprInteger).int,
						call.params.next.expr.value(ExprInteger).int
					))
				END
			| Scanner.Asr:
				IF call.params.next.expr.value # NIL THEN
					call.value := ExprIntegerNew(ASR(
						v(ExprInteger).int,
						call.params.next.expr.value(ExprInteger).int
					))
				END
			| Scanner.Ror:
				IF call.params.next.expr.value # NIL THEN
					call.value := ExprIntegerNew(ASR(
						v(ExprInteger).int,
						call.params.next.expr.value(ExprInteger).int
					))
				END
			| Scanner.Floor:
				call.value := ExprIntegerNew(FLOOR(v(ExprReal).real))
			| Scanner.Flt:
				call.value := ExprRealNewByValue(FLT(v(ExprInteger).int))
			| Scanner.Ord:
				IF v.type.id = IdChar THEN
					call.value := v
				ELSIF v IS ExprString THEN
					IF v(ExprString).int > -1 THEN
						call.value := ExprIntegerNew(v(ExprString).int)
					ELSE
						(* TODO *) ASSERT(FALSE)
					END
				ELSIF v.type.id = IdBoolean THEN
					call.value := ExprIntegerNew(ORD(v(ExprBoolean).bool))
				ELSIF v.type.id = IdSet THEN
					call.value := ExprIntegerNew(ORD(v(ExprSet).set))
				ELSE
					Log.Str("Неправильный id типа = ");
					Log.Int(v.type.id); Log.Ln;
					ASSERT(FALSE)
				END
			| Scanner.Chr:
				IF ~Limits.InCharRange(v(ExprInteger).int) THEN
					err := ErrValueOutOfRangeOfChar
				END;
				call.value := v
			END
		ELSIF (call.designator.decl.id = Scanner.Len)
		     & (call.params.expr.type IS Array) (* TODO заменить на общую проверку корректности выбора параметра *)
		     & (call.params.expr.type(Array).count # NIL)
		THEN
			call.value := call.params.expr.type(Array).count.value
		END
	END;
	IF currentFormalParam # NIL THEN
		err := ErrCallParamsNotEnough
	END
	RETURN err
END CallParamsEnd;

PROCEDURE StatInit(s: Statement; e: Expression);
BEGIN
	NodeInit(s^);
	s.expr := e;
	s.next := NIL
END StatInit;

PROCEDURE CallNew*(VAR c: Call; des: Designator): INTEGER;
VAR err: INTEGER;
	e: ExprCall;
BEGIN
	err := ExprCallCreate(e, des, FALSE);
	NEW(c); StatInit(c, e)
	RETURN err
END CallNew;

PROCEDURE CommandGet*(VAR call: Call; m: Module;
                      name: ARRAY OF CHAR; begin, end: INTEGER): INTEGER;
VAR d: Declaration;
	des: Designator;
	err: INTEGER;
BEGIN
	d := SearchName(m.start, name, begin, end);
	IF d = NIL THEN
		err := ErrDeclarationNotFound
	ELSIF ~d.mark THEN
		err := ErrDeclarationIsPrivate
	ELSIF ~(d IS Procedure) THEN
		err := ErrDeclarationNotProc
	ELSIF (d(Procedure).header.params # NIL) OR (d(Procedure).header.type # NIL)
	THEN
		err := ErrProcNotCommandHaveParams
	ELSE
		err := DesignatorNew(des, d);
		IF err = ErrNo THEN
			err := CallNew(call, des);
		END
	END
	RETURN err
END CommandGet;

PROCEDURE IfNew*(VAR if: If; expr: Expression; stats: Statement): INTEGER;
VAR err: INTEGER;
BEGIN
	NEW(if); StatInit(if, expr);
	if.stats := stats;
	if.elsif := NIL;
	IF (expr # NIL) & (expr.type.id # IdBoolean) THEN
		err := ErrNotBoolInIfCondition
	ELSE
		err := ErrNo
	END
	RETURN err
END IfNew;

PROCEDURE CheckCondition(VAR err: INTEGER; expr: Expression; adder: INTEGER);
BEGIN
	err := ErrNo;
	IF expr # NIL THEN
		IF expr.type.id # IdBoolean THEN
			err := ErrNotBoolInWhileCondition + adder
		ELSIF expr.value # NIL THEN
			err := ErrWhileConditionAlwaysFalse + adder
				 - ORD(expr.value(ExprBoolean).bool)
		END
	END
END CheckCondition;

PROCEDURE WhileNew*(VAR w: While; expr: Expression; stats: Statement): INTEGER;
VAR err: INTEGER;
BEGIN
	NEW(w); StatInit(w, expr);
	w.stats := stats;
	w.elsif := NIL;
	CheckCondition(err, expr, 0)
	RETURN err
END WhileNew;

PROCEDURE RepeatNew*(VAR r: Repeat; stats: Statement): INTEGER;
BEGIN
	NEW(r); StatInit(r, NIL);
	r.stats := stats
	RETURN ErrNo
END RepeatNew;

PROCEDURE RepeatSetUntil*(r: Repeat; e: Expression): INTEGER;
VAR err: INTEGER;
BEGIN
	ASSERT(r.expr = NIL);
	r.expr := e;
	CheckCondition(err, e, ErrNotBoolInUntil - ErrNotBoolInWhileCondition)
	RETURN err
END RepeatSetUntil;

PROCEDURE ForSetBy*(for: For; by: Expression): INTEGER;
VAR err, init, to: INTEGER;
BEGIN
	err := ErrNo;
	IF (by # NIL) & (by.value # NIL) & (by.type.id = IdInteger) THEN
		for.by := by.value(ExprInteger).int;
		IF for.by = 0 THEN
			err := ErrForByZero
		END
	ELSE
		for.by := 1;
		IF by # NIL THEN
			err := ErrExpectConstIntExpr
		END
	END;
	IF (err = ErrNo)
	 & (for.expr # NIL) & (for.expr.value # NIL)
	 & (for.expr.value IS ExprInteger)
	 & (for.to # NIL) & (for.to.value # NIL)
	 & (for.to.value IS ExprInteger)
	THEN
		init := for.expr.value(ExprInteger).int;
		to := for.to.value(ExprInteger).int;
		IF (init < to) & (for.by < 0) THEN
			err := ErrByShouldBePositive
		ELSIF (init > to) & (for.by > 0) THEN
			err := ErrByShouldBeNegative
		ELSIF (for.by > 0) & (Limits.IntegerMax - for.by < to)
		   OR (for.by < 0) & (Limits.IntegerMin - for.by > to)
		THEN (* TODO уточнить условие *)
			err := ErrForPossibleOverflow
		END
	END
	RETURN err
END ForSetBy;

PROCEDURE ForSetTo*(for: For; to: Expression): INTEGER;
VAR err: INTEGER;
BEGIN
	IF (to # NIL) & (to.type.id # IdInteger) THEN
		err := ErrExpectIntExpr
	ELSE
		err := ErrNo
	END;
	for.to := to
	RETURN err
END ForSetTo;

PROCEDURE ForNew*(VAR f: For; var: Var; init, to: Expression; by: INTEGER;
                  stats: Statement): INTEGER;
VAR err: INTEGER;
BEGIN
	NEW(f); StatInit(f, init);
	f.var := var;
	var.inited := TRUE;
	err := ForSetTo(f, to);
	f.by := by;
	f.stats := stats
	RETURN err
END ForNew;

PROCEDURE CaseNew*(VAR case: Case; expr: Expression): INTEGER;
VAR err: INTEGER;
BEGIN
	NEW(case); StatInit(case, expr);
	case.elements := NIL;
	IF (expr.type # NIL) & ~(expr.type.id IN {IdInteger, IdChar}) THEN
		err := ErrCaseExprNotIntOrChar
	ELSE
		err := ErrNo
	END
	RETURN err
END CaseNew;

PROCEDURE CaseRangeSearch*(case: Case; int: INTEGER): INTEGER;
VAR e: CaseElement;
BEGIN
	ASSERT(FALSE);
	e := case.elements;
	IF e # NIL THEN
		WHILE e.next # NIL DO
			e := e.next
		END;
		IF e.stats # NIL THEN
			e := NIL
		END
	END
	RETURN 0
END CaseRangeSearch;

PROCEDURE CaseLabelNew*(VAR label: CaseLabel; id, value: INTEGER): INTEGER;
BEGIN
	ASSERT(id IN {IdInteger, IdChar});

	NEW(label); NodeInit(label^);
	label.qual := NIL;
	label.id := id;
	label.value := value;
	label.right := NIL;
	label.next := NIL
	RETURN ErrNo
END CaseLabelNew;

PROCEDURE CaseLabelQualNew*(VAR label: CaseLabel; decl: Declaration): INTEGER;
VAR err, i: INTEGER;
BEGIN
	label := NIL;
	IF decl.id = IdError THEN
		err := ErrNo
	ELSIF ~(decl IS Const) THEN
		err := ErrCaseLabelNotConst
	ELSIF ~(decl(Const).expr.type.id IN {IdInteger, IdChar})
	    & ~((decl(Const).expr IS ExprString)
	    & (decl(Const).expr(ExprString).int > -1)
	       )
	THEN
		(*Log.Str("Label type id "); Log.Int(decl(Const).expr.type.id); Log.Ln;*)
		err := ErrCaseLabelNotIntOrChar
	ELSE
		IF decl(Const).expr.type.id = IdInteger THEN
			err := CaseLabelNew(label, IdInteger, decl(Const).expr.value(ExprInteger).int)
		ELSE
			i := decl(Const).expr.value(ExprString).int;
			IF i < 0 THEN
				(* TODO *) ASSERT(FALSE);
				i := ORD(decl(Const).expr.value(ExprString).string.block.s[0])
			END;
			err := CaseLabelNew(label, IdChar, i)
		END
	END;
	IF label = NIL THEN
		err := err + CaseLabelNew(label, IdInteger, 0) * 0
	END
	RETURN err
END CaseLabelQualNew;

PROCEDURE CaseRangeNew*(left, right: CaseLabel): INTEGER;
VAR err: INTEGER;
BEGIN
	ASSERT((left.right = NIL) & (left.next = NIL));
	ASSERT((right = NIL) OR (right.right = NIL) & (right.next = NIL));

	left.right := right;

	err := ErrNo;
	IF right # NIL THEN
		IF left.id # right.id THEN
			err := ErrCaseRangeLabelsTypeMismatch
		ELSIF left.value >= right.value THEN
			err := ErrCaseLabelLeftNotLessRight
		END
	END
	RETURN err
END CaseRangeNew;

PROCEDURE IsRangesCross(l1, l2: CaseLabel): BOOLEAN;
VAR cross: BOOLEAN;
BEGIN
	IF l1.value < l2.value THEN
		cross := (l1.right # NIL) & (l1.right.value >= l2.value)
	ELSE
		cross := (l1.value = l2.value)
			  OR (l2.right # NIL) & (l2.right.value >= l1.value)
	END;
	Log.Str("IsRangesCross "); Log.Bool(cross); Log.Ln
	RETURN cross
END IsRangesCross;

PROCEDURE IsListCrossRange(list, range: CaseLabel): BOOLEAN;
BEGIN
	WHILE (list # NIL) & ~IsRangesCross(list, range) DO
		list := list.next
	END;
	Log.Str("IsListCrossRange "); Log.Bool(list # NIL); Log.Ln
	RETURN list # NIL
END IsListCrossRange;

PROCEDURE IsElementsCrossRange(elem: CaseElement; range: CaseLabel): BOOLEAN;
BEGIN
	WHILE (elem # NIL) & ~IsListCrossRange(elem.labels, range) DO
		elem := elem.next
	END;
	Log.Str("IsElementsCrossRange "); Log.Bool(elem # NIL); Log.Ln
	RETURN elem # NIL
END IsElementsCrossRange;

PROCEDURE CaseRangeListAdd*(case: Case; first, new: CaseLabel): INTEGER;
VAR err: INTEGER;
BEGIN
	ASSERT(new.next = NIL);
	IF (case.expr.type.id # new.id)
	 & ~((case.expr.type.id IN {IdInteger, IdByte})
	   & (new.id IN {IdInteger, IdByte})
	    )
	THEN
		err := ErrCaseRangeLabelsTypeMismatch
	ELSE
		IF IsElementsCrossRange(case.elements, new)
		THEN err := ErrCaseElemDuplicate
		ELSE err := ErrNo
		END;

		IF first # NIL THEN
			WHILE first.next # NIL DO
				IF IsListCrossRange(first, new) THEN
					err := ErrCaseElemDuplicate
				END;
				first := first.next
			END;
			IF IsListCrossRange(first, new) THEN
				err := ErrCaseElemDuplicate
			END;
			first.next := new
		END
	END
	RETURN err
END CaseRangeListAdd;

PROCEDURE CaseElementNew*(labels: CaseLabel): CaseElement;
VAR elem: CaseElement;
BEGIN
	NEW(elem); NodeInit(elem^);
	elem.next := NIL;
	elem.labels := labels;
	elem.stats := NIL
	RETURN elem
END CaseElementNew;

PROCEDURE CaseElementAdd*(case: Case; elem: CaseElement): INTEGER;
VAR err: INTEGER;
	last: CaseElement;
BEGIN
	IF case.elements = NIL THEN
		case.elements := elem
	ELSE
		last := case.elements;
		WHILE last.next # NIL DO
			last := last.next
		END;
		last.next := elem
	END;
	err := ErrNo
	RETURN err
END CaseElementAdd;

PROCEDURE AssignNew*(VAR a: Assign; des: Designator; expr: Expression): INTEGER;
VAR err: INTEGER;
BEGIN
	NEW(a); StatInit(a, expr);
	a.designator := des;
	err := ErrNo;
	IF des # NIL THEN
		IF (des.decl IS Var) & IsChangeable(des.decl.module, des.decl(Var)) THEN
			des.decl(Var).inited := TRUE;
		ELSE
			err := ErrAssignExpectVarParam
		END;
		IF (expr # NIL)
		 & ~CompatibleTypes(a.distance, des.type, expr.type)
		 & ~CompatibleAsCharAndString(des.type, a.expr)
		THEN
			IF ~CompatibleAsIntAndByte(des.type, expr.type) THEN
				err := ErrAssignIncompatibleType
			ELSIF (des.type.id = IdByte)
			    & (expr.value # NIL)
			    & ~Limits.InByteRange(expr.value(ExprInteger).int)
			THEN
				err := ErrValueOutOfRangeOfByte
			END
		END
	END
	RETURN err
END AssignNew;

PROCEDURE StatementErrorNew*(): StatementError;
VAR s: StatementError;
BEGIN
	NEW(s); StatInit(s, NIL)
	RETURN s
END StatementErrorNew;

PROCEDURE PredefinedDeclarationsInit;
VAR tp: ProcType;
	typeInt, typeReal: Type;

	PROCEDURE TypeNew(s, t: INTEGER);
	VAR td: Type;
		tb: Byte;
	BEGIN
		IF TRUE (* TODO *) OR (s # Scanner.Byte) THEN
			NEW(td)
		ELSE
			NEW(tb);
			td := tb
		END;
		TInit(td, t);

		predefined[s - Scanner.PredefinedFirst] := td;
		types[t] := td
	END TypeNew;

	PROCEDURE ProcNew(s, t: INTEGER): ProcType;
	VAR td: PredefinedProcedure;
	BEGIN
		NEW(td); NodeInit(td^); DeclInit(td, NIL);
		predefined[s - Scanner.PredefinedFirst] := td;
		td.header := ProcTypeNew();
		td.type := td.header;
		td.id := s;
		IF t > NoId THEN
			td.header.type := TypeGet(t)
		END
		RETURN td.header
	END ProcNew;
BEGIN
	TypeNew(Scanner.Byte, IdByte);
	TypeNew(Scanner.Integer, IdInteger);
	TypeNew(Scanner.Char, IdChar);
	TypeNew(Scanner.Set, IdSet);
	TypeNew(Scanner.Boolean, IdBoolean);
	TypeNew(Scanner.Real, IdReal);
	NEW(types[IdPointer]); NodeInit(types[IdPointer]^);
	DeclInit(types[IdPointer], NIL);
	types[IdPointer].id := IdPointer;

	typeInt := TypeGet(IdInteger);
	tp := ProcNew(Scanner.Abs, IdInteger);
	ParamAddPredefined(tp, typeInt, FALSE);

	tp := ProcNew(Scanner.Asr, IdInteger);
	ParamAddPredefined(tp, typeInt, FALSE);
	ParamAddPredefined(tp, typeInt, FALSE);

	tp := ProcNew(Scanner.Assert, NoId);
	ParamAddPredefined(tp, TypeGet(IdBoolean), FALSE);

	tp := ProcNew(Scanner.Chr, IdChar);
	ParamAddPredefined(tp, typeInt, FALSE);

	tp := ProcNew(Scanner.Dec, NoId);
	ParamAddPredefined(tp, typeInt, FALSE);

	tp := ProcNew(Scanner.Excl, NoId);
	ParamAddPredefined(tp, TypeGet(IdSet), TRUE);
	ParamAddPredefined(tp, typeInt, FALSE);

	typeReal := TypeGet(IdReal);
	tp := ProcNew(Scanner.Floor, IdInteger);
	ParamAddPredefined(tp, typeReal, FALSE);

	tp := ProcNew(Scanner.Flt, IdReal);
	ParamAddPredefined(tp, typeInt, FALSE);

	tp := ProcNew(Scanner.Inc, NoId);
	ParamAddPredefined(tp, typeInt, TRUE);

	tp := ProcNew(Scanner.Incl, NoId);
	ParamAddPredefined(tp, TypeGet(IdSet), TRUE);
	ParamAddPredefined(tp, typeInt, FALSE);

	tp := ProcNew(Scanner.Len, IdInteger);
	ParamAddPredefined(tp, ArrayGet(typeInt, NIL), FALSE);

	tp := ProcNew(Scanner.Lsl, IdInteger);
	ParamAddPredefined(tp, typeInt, FALSE);
	ParamAddPredefined(tp, typeInt, FALSE);

	tp := ProcNew(Scanner.New, NoId);
	ParamAddPredefined(tp, TypeGet(IdPointer), TRUE);

	tp := ProcNew(Scanner.Odd, IdBoolean);
	ParamAddPredefined(tp, typeInt, FALSE);

	tp := ProcNew(Scanner.Ord, IdInteger);
	ParamAddPredefined(tp, TypeGet(IdChar), FALSE);

	tp := ProcNew(Scanner.Pack, IdReal);
	ParamAddPredefined(tp, typeReal, TRUE);

	tp := ProcNew(Scanner.Ror, IdInteger);
	ParamAddPredefined(tp, typeInt, FALSE);
	ParamAddPredefined(tp, typeInt, FALSE);

	tp := ProcNew(Scanner.Unpk, IdReal);
	ParamAddPredefined(tp, typeReal, TRUE)
END PredefinedDeclarationsInit;

PROCEDURE HasError*(m: Module): BOOLEAN;
	RETURN m.errLast # NIL
END HasError;

PROCEDURE ProviderInit*(p: Provider; get: Provide);
BEGIN
	V.Init(p^);
	p.get := get
END ProviderInit;

BEGIN
	PredefinedDeclarationsInit
END Ast.

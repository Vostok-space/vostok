(*  Abstract syntax tree support for Oberon-07
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
MODULE Ast;

IMPORT
	Log := DLog, Out,
	Utf8,
	Limits := TypesLimits,
	V,
	Scanner,
	SpecIdent := OberonSpecIdent,
	Strings := StringStore, Chars0X,
	TranLim := TranslatorLimits,
	Arithmetic := CheckIntArithmetic,
	LongSet;

CONST
	ErrNo*                          =  0;
	ErrImportNameDuplicate*         = -1;
	ErrImportSelf*                  = -2;
	ErrImportLoop*                  = -3;
	ErrDeclarationNameDuplicate*    = -4;
	ErrDeclarationNameHide*         = -5;
	ErrPredefinedNameHide*          = -6;
	ErrMultExprDifferentTypes*      = -7;
	ErrDivExprDifferentTypes*       = -8;
	ErrNotBoolInLogicExpr*          = -9;
	ErrNotIntInDivOrMod*            = -10;
	ErrNotRealTypeForRealDiv*       = -11;
	ErrNotIntSetElem*               = -12;
	ErrSetElemOutOfRange*           = -13;
	ErrSetElemOutOfLongRange*       = -106;(*TODO*)
	ErrSetLeftElemBiggerRightElem*  = -14;
	ErrSetElemMaxNotConvertToInt*   = -15;
	ErrSetFromLongSet*              = -107;(*TODO*)
	ErrAddExprDifferenTypes*        = -16;
	ErrNotNumberAndNotSetInMult*    = -17;
	ErrNotNumberAndNotSetInAdd*     = -18;
	ErrSignForBool*                 = -19;
	ErrRelationExprDifferenTypes*   = -20;
	ErrExprInWrongTypes*            = -21;
	ErrExprInRightNotSet*           = ErrExprInWrongTypes - 1;
	ErrExprInLeftNotInteger*        = ErrExprInWrongTypes - 2;
	ErrRelIncompatibleType*         = -24;
	ErrIsEqualProc*                 = -109;(*TODO*)
	ErrIsExtTypeNotRecord*          = -25;
	ErrIsExtVarNotRecord*           = -26;
	ErrIsExtMeshupPtrAndRecord*     = -27;
	ErrIsExtExpectRecordExt*        = -28;
	ErrConstDeclExprNotConst*       = -29;
	ErrAssignIncompatibleType*      = -30;
	ErrAssignExpectVarParam*        = -31;
	ErrAssignStringToNotEnoughArray*= -108;(* TODO *)
	ErrCallNotProc*                 = -32;
	ErrCallExprWithoutReturn*       = -33;
	ErrCallIgnoredReturn*           = ErrCallExprWithoutReturn - 1;
	ErrCallExcessParam*             = -35;
	ErrCallIncompatibleParamType*   = -36;
	ErrCallExpectVarParam*          = -37;
	ErrCallExpectAddressableParam*  = -112;(* TODO *)
	ErrCallParamsNotEnough*         = -38;
	ErrCallVarPointerTypeNotSame*   = -39;
	ErrCaseExprNotIntOrChar*        = -40;
	ErrCaseLabelNotIntOrChar*       = -41;
	ErrCaseElemExprTypeMismatch*    = -42;
	ErrCaseElemDuplicate*           = -43;
	ErrCaseRangeLabelsTypeMismatch* = -44;
	ErrCaseLabelLeftNotLessRight*   = -45;
	ErrCaseLabelNotConst*           = -46;
	ErrCaseElseAlreadyExist*        = -47;
	ErrProcHasNoReturn*             = -48;
	ErrReturnIncompatibleType*      = -49;
	ErrExpectReturn*                = -50;
	ErrDeclarationNotFound*         = -51;
	ErrDeclarationIsPrivate*        = -52;
	ErrConstRecursive*              = -53;
	ErrImportModuleNotFound*        = -54;
	ErrImportModuleWithError*       = -55;
	ErrDerefToNotPointer*           = -56;
	ErrArrayLenLess1*               = -57;
	ErrArrayLenTooBig*              = -58;
	ErrArrayItemToNotArray*         = -59;
	ErrArrayIndexNotInt*            = -60;
	ErrArrayIndexNegative*          = -61;
	ErrArrayIndexOutOfRange*        = -62;
	ErrStringIndexing*              = -110; (* TODO *)
	ErrGuardExpectRecordExt*        = -63;
	ErrGuardExpectPointerExt*       = -64;
	ErrGuardedTypeNotExtensible*    = -65;
	ErrDotSelectorToNotRecord*      = -66;
	ErrDeclarationNotVar*           = -67;
	ErrForIteratorNotInteger*       = -68;
	ErrNotBoolInIfCondition*        = -69;
	ErrNotBoolInWhileCondition*     = -70;
	ErrWhileConditionAlwaysFalse*   = -71;
	ErrWhileConditionAlwaysTrue*    = -72;
	ErrNotBoolInUntil*              = -73;
	ErrUntilAlwaysFalse*            = -74;
	ErrUntilAlwaysTrue*             = -75;
	ErrNegateNotBool*               = -76;
	ErrConstAddOverflow*            = -77;
	ErrConstSubOverflow*            = -78;
	ErrConstMultOverflow*           = -79;
	ErrComDivByZero*                = -80;
	ErrNegativeDivisor*             = -81;

	ErrValueOutOfRangeOfByte*       = -82;
	ErrValueOutOfRangeOfChar*       = -83;

	ErrExpectIntExpr*               = -84;
	ErrExpectConstIntExpr*          = -85;
	ErrForByZero*                   = -86;
	ErrByShouldBePositive*          = -87;
	ErrByShouldBeNegative*          = -88;
	ErrForPossibleOverflow*         = -89;

	ErrVarUninitialized*            = -90;
	ErrVarMayUninitialized*         = ErrVarUninitialized - 1;

	ErrDeclarationNotProc*          = -92;
	ErrProcNotCommandHaveReturn*    = -93;
	ErrProcNotCommandHaveParams*    = -94;

	ErrReturnTypeArrayOrRecord*     = -95;
	ErrRecordForwardUndefined*      = -96;
	ErrPointerToNotRecord*          = -97;
	ErrVarOfRecordForward*          = -98;
	ErrVarOfPointerToRecordForward* = -99;
	ErrArrayTypeOfRecordForward*    = -100;
	ErrArrayTypeOfPointerToRecordForward*
	                                = -101;
	ErrAssertConstFalse*            = -102;
	ErrDeclarationUnused*           = -103;
	ErrProcNestedTooDeep*           = -104;

	ErrExpectProcNameWithoutParams* = -105;
	                                (*-106-110*)
	ErrParamOutInFunc*              = -111;
	                                (*-112*)
	ErrMin*                         = -200;

	ParamIn*     = 0;
	ParamOut*    = 1;

	ParamOfPredefined*  = 2;
	ParamOutReturnable* = 3;
	ParamForAddress*    = 4;
	InLoop*             = 5;
	InBranch*           = 6;

	NoId*                 =-1;
	IdInteger*            = 0;
	IdLongInt*            = 1;
	IdBoolean*            = 2;
	IdByte*               = 3;
	IdChar*               = 4;
	IdReal*               = 5;
	IdReal32*             = 6;
	IdSet*                = 7;
	IdLongSet*            = 8;
	IdPointer*            = 9;
	PredefinedTypesCount* = 10;

	IdVarAny*             = 17;(*TODO*)
	IdBasic*              = 18;
	IdAny*                = 19;
	IdTypeAny*            = 20;

	IdArray*            = 10;
	IdRecord*           = 11;
	IdRecordForward*    = 12;
	IdProcType*         = 13;
	IdFuncType*         = 14;
	IdNamed*            = 15;
	IdString*           = 16;

	IdDesignator*       = 20;
	IdRelation*         = 21;
	IdSum*              = 22;
	IdTerm*             = 23;
	IdNegate*           = 24;
	IdCall*             = 25;
	IdBraces*           = 26;
	IdIsExtension*      = 27;
	IdExprType*         = 28;

	IdError*            = 31;

	IdImport*           = 32;
	IdConst*            = 33;
	IdVar*              = 34;
	IdProc*             = 35;
	LastId              = 35;

	InitedNo*     = 0;
	InitedNil*    = 1;
	InitedValue*  = 2;
	InitedFail*   = 3;
	(* Означает, что несмотря на формалистическое InitedValue, нужно проверять
	   инициализированность во время работы. Нужно из-за VAR
	   TODO систематизировать совместно с RVar.checkInit  *)
	InitedCheck*  = 4;
	Used*         = 5;
	Dereferenced* = 6;

	Integers*   = {IdByte, IdInteger, IdLongInt};
	Reals*      = {IdReal32, IdReal};
	Numbers*    = Integers + Reals;
	Sets*       = {IdSet, IdLongSet};
	Structures* = {IdRecord, IdArray};
	ProcTypes*  = {IdProcType, IdFuncType};
	Pointers*   = {IdPointer} + ProcTypes;
	BasicTypes* = Numbers + Sets + Pointers + {IdBoolean, IdChar};
	DeclarableTypes* = Structures + Pointers;

	(* в RExpression.properties для учёта того, что сравнение с NIL не может
	   быть константным в clang *)
	ExprPointerTouch* = 0;
	(* в RExpression.properties для учёта того, что в вычислении константного
	   выражения присутствовало отрицательное делимое *)
	ExprIntNegativeDividentTouch* = 1;

	(* в RType для индикации того, что переменная этого типа была присвоена,
	   что важно при подсчёте ссылок *)
	TypeAssigned* = 0;

	Plus *        = Scanner.Plus;
	Minus*        = Scanner.Minus;
	Or*           = Scanner.Or;
	And*          = Scanner.And;
	Equal*        = Scanner.Equal;
	Inequal*      = Scanner.Inequal;
	Less*         = Scanner.Less;
	LessEqual*    = Scanner.LessEqual;
	Greater*      = Scanner.Greater;
	GreaterEqual* = Scanner.GreaterEqual;
	In*           = Scanner.In;
	Is*           = Scanner.Is;
	Mult*         = Scanner.Asterisk;
	Div*          = Scanner.Div;
	Rdiv*         = Scanner.Slash;
	Mod*          = Scanner.Mod;
	NoSign* = 0;
	RelationFirst = Scanner.RelationFirst;
	RelationLast  = Scanner.RelationLast;
	MultFirst     = Scanner.MultFirst;
	MultLast      = Scanner.MultLast;

	StrUsedAsChar*  = 0;
	StrUsedUndef*   = 1;
	StrUsedAsArray* = 2;

	IsAllowCmpProc = FALSE;
	IsAllowStrIndex = FALSE;

TYPE
	Module* = POINTER TO RModule;
	ModuleBag* = POINTER TO RECORD
		m*: Module
	END;

	Provider* = POINTER TO RProvider;

	Provide* = PROCEDURE(p: Provider; host: Module; name: ARRAY OF CHAR): Module;

	Register* = PROCEDURE(p: Provider; m: Module): BOOLEAN;

	RProvider* = RECORD(V.Base)
		get: Provide;
		reg: Register
	END;

	PNode* = POINTER TO Node;
	Node = RECORD(V.Base)
		id*: INTEGER;
		comment*: Strings.String;
		emptyLines*: INTEGER;
		ext*: V.PBase
	END;

	Error* = POINTER TO RError;
	RError = RECORD(Node)
		code*: INTEGER;
		line*, column*, bytes*: INTEGER;
		str*: Strings.String;
		next*: Error
	END;

	Type* = POINTER TO RType;
	Declaration* = POINTER TO RDeclaration;
	Declarations* = POINTER TO RDeclarations;
	DeclarationsBag = POINTER TO RECORD
		d*: Declarations
	END;
	RDeclaration* = RECORD(Node)
		module*: ModuleBag;
		up*: DeclarationsBag;

		name*: Strings.String;
		mark*,
		used*: BOOLEAN;
		type*: Type;
		next*: Declaration
	END;

	Array* = POINTER TO RArray;
	RType* = RECORD(RDeclaration)
		array*: Array;

		properties*: SET
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

	VarState = POINTER TO RVarState;
	RVarState = RECORD
		inited*: SET;
		inCondition: BOOLEAN;

		root, if, else: VarState
	END;

	Var* = POINTER TO RVar;
	RVar* = RECORD(RDeclaration)
		state: VarState;

		checkInit*,
		inVarParam*: BOOLEAN
	END;

	Record* = POINTER TO RRecord;
	RRecord = RECORD(RConstruct)
		base*   : Record;
		vars*   : Var;
		pointer*: Pointer;

		needTag*,
		inAssign*,
		hasExt*,
		complete: BOOLEAN
	END;

	RPointer* = RECORD(RConstruct)
		(* type - ссылка на record *)
	END;

	NeedTagList = POINTER TO RNeedTagList;
	FormalParam* = POINTER TO RFormalParam;
	RFormalParam = RECORD(RVar)
		access*: SET;

		needTag*: NeedTagList;
		link: FormalParam
	END;
	RNeedTagList = RECORD(V.Base)
		next: NeedTagList;
		value: BOOLEAN;

		count: INTEGER;
		first, last: FormalParam
	END;

	RProcType = RECORD(RConstruct)
		params*, end*: FormalParam
		(* type - возвращаемый тип *)
	END;

	ProcType* = POINTER TO RProcType;

	FormalProcType = POINTER TO RECORD(RProcType)

	END;

	Statement* = POINTER TO RStatement;
	Procedure* = POINTER TO RProcedure;
	RDeclarations* = RECORD(RDeclaration)
		dag*: DeclarationsBag;

		start*, end*: Declaration;

		consts*: Const;
		types*: Type;
		vars*, varsEnd*: Var;
		procedures*: Procedure;

		recordForwardCount: INTEGER;

		stats*: Statement
	END;

	Import* = POINTER TO RECORD(RDeclaration)
		(* Псевдо Declaration для организации единообразного поиска *)
	END;

	RModule* = RECORD(RDeclarations)
		bag*: ModuleBag;
		store: Strings.Store;

		script*, errorHide*: BOOLEAN;

		handleImport: BOOLEAN;
		import*: Import;

		fixed,
		spec*: BOOLEAN;

		(* TODO переделать *)
		unusedDecl: Declaration;

		errors*, errLast*: Error
	END;

	GeneralProcedure* = POINTER TO RGeneralProcedure;
	RGeneralProcedure* = RECORD(RDeclarations)
		header*: ProcType;
		return*: Expression
	END;

	RProcedure* = RECORD(RGeneralProcedure)
		deep*: INTEGER;

		usedAsValue*: BOOLEAN
	END;

	PredefinedProcedure* = POINTER TO RECORD(RGeneralProcedure)
	END;

	Factor* = POINTER TO RFactor;

	RExpression* = RECORD(Node)
		type*: Type;

		properties*: SET;
		value*: Factor
	END;

	Selector* = POINTER TO RSelector;
	RSelector* = RECORD(Node)
		type*: Type;
		next*: Selector
	END;

	SelPointer* = POINTER TO RECORD(RSelector) END;

	SelGuard* = POINTER TO RECORD(RSelector)
	END;

	SelArray* = POINTER TO RECORD(RSelector)
		index*: Expression
	END;

	SelRecord* = POINTER TO RECORD(RSelector)
		var*: Var
	END;

	RFactor = RECORD(RExpression)
		nextValue: Factor
	END;

	Designator* = POINTER TO RECORD(RFactor)
		decl*: Declaration;
		inited*: SET;
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
		asChar*: BOOLEAN;
		usedAs*: INTEGER
	END;

	ExprNil* = POINTER TO RECORD(RFactor) END;

	ExprSet* = POINTER TO RExprSet;
	RExprSet = RECORD(RFactor)
		exprs*: ARRAY 2 OF Expression;

		next*: ExprSet
	END;

	(* TODO ввести тип Value как основы вместо RFactor *)
	ExprSetValue* = POINTER TO RECORD(RFactor)
		set *: LongSet.Type;
		long*: BOOLEAN
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

	ExprSum* = POINTER TO RExprSum;
	RExprSum = RECORD(RExpression)
		add*: INTEGER;
		term*: Expression;

		next*: ExprSum
	END;

	ExprTerm* = POINTER TO RECORD(RExpression)
		factor*: Factor;
		mult*: INTEGER;
		expr*: Expression (* Factor or ExprTerm *)
	END;

	ExprType* = POINTER TO RECORD(RExpression)
	END;

	Parameter* = POINTER TO RParameter;
	RParameter = RECORD(Node)
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

	If* = POINTER TO RECORD(RWhileIf)END;

	CaseLabel* = POINTER TO RCaseLabel;
	RCaseLabel = RECORD(Node)
		value*: INTEGER;
		qual*: Declaration;

		right*, (* правая часть диапазона *)
		next*: CaseLabel (* следующий элемент списка меток *)
	END;
	CaseElement* = POINTER TO RCaseElement;
	RCaseElement = RECORD(Node)
		labels*: CaseLabel;
		stats*: Statement;
		next*: CaseElement
	END;
	Case* = POINTER TO RECORD(RStatement)
		elements*: CaseElement;

		else*: Statement
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
	predefined: ARRAY SpecIdent.PredefinedLast - SpecIdent.PredefinedFirst + 1
	            OF Declaration;
	booleans: ARRAY 2 OF ExprBoolean;
	nil: ExprNil;

	values: Factor;
	needTags: NeedTagList;

	system: Module;

PROCEDURE PutChars*(m: Module; VAR w: Strings.String;
                    s: ARRAY OF CHAR; begin, end: INTEGER);
BEGIN
	IF 0 <= begin THEN
		Strings.Put(m.store, w, s, begin, end)
	ELSE
		Strings.Put(m.store, w, "#error", 0, 5)
	END
END PutChars;

PROCEDURE NodeInit(VAR n: Node; id: INTEGER);
BEGIN
	ASSERT((NoId <= id) & (id <= LastId)
	    OR (SpecIdent.PredefinedFirst <= id) & (id <= SpecIdent.PredefinedLast));
	V.Init(n);
	n.id := id;
	n.emptyLines := 0;
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
	NodeSetComment(d^, d.module.m, com, ofs, end)
END DeclSetComment;

PROCEDURE ModuleSetComment*(m: Module; com: ARRAY OF CHAR; ofs, end: INTEGER);
BEGIN
	NodeSetComment(m^, m, com, ofs, end)
END ModuleSetComment;

PROCEDURE DeclInit(d: Declaration; ds: Declarations);
BEGIN
	IF ds = NIL THEN
		d.module := NIL;
		d.up := NIL
	ELSE
		IF (ds.module = NIL) & (ds IS Module) THEN
			d.module := ds(Module).bag
		ELSE
			d.module := ds.module
		END;
		d.up := ds.dag
	END;
	d.mark := FALSE;
	d.used := FALSE;
	Strings.Undef(d.name);
	d.type := NIL;
	d.next := NIL
END DeclInit;

PROCEDURE DeclConnect(d: Declaration; ds: Declarations;
                      name: ARRAY OF CHAR; start, end: INTEGER);
VAR p: Declaration;
BEGIN
	ASSERT(d # NIL);
	ASSERT(name # "");
	ASSERT(~(d IS Module));
	ASSERT((ds.start = NIL) OR ~(ds.start IS Module));

	DeclInit(d, ds);
	IF (ds.end # NIL) & (ds.procedures # NIL) & (d IS Var) THEN
		IF ds.vars = NIL THEN
			IF ds.start = ds.procedures THEN
				ds.start := d
			ELSE
				p := ds.start;
				WHILE ~(p.next IS Procedure) DO
					p := p.next
				END;
				p.next := d
			END;
			d.next := ds.procedures
		ELSE
			d.next := ds.varsEnd.next;
			ds.varsEnd.next := d;
			ds.varsEnd := d(Var)
		END
	ELSE
		IF ds.end # NIL THEN
			ASSERT(ds.end.next = NIL);
			ds.end.next := d
		ELSE
			ASSERT(ds.start = NIL);
			ds.start := d
		END;
		ASSERT(~(ds.start IS Module));
		ds.end := d;
	END;
	IF start >= 0 THEN
		PutChars(d.module.m, d.name, name, start, end)
	ELSE
		PutChars(d.module.m, d.name, "#ERROR ", 0, 5)
	END
END DeclConnect;

PROCEDURE DeclarationsInit(d, up: Declarations);
BEGIN
	DeclInit(d, NIL);
	NEW(d.dag);
	d.dag.d := d;
	d.start := NIL;
	d.end := NIL;

	d.consts     := NIL;
	d.types      := NIL;
	d.vars       := NIL;
	d.varsEnd    := NIL;
	d.procedures := NIL;
	IF up = NIL THEN
		d.up := NIL
	ELSE
		d.up := up.dag
	END;
	d.stats := NIL;

	d.recordForwardCount := 0
END DeclarationsInit;

PROCEDURE DeclarationsConnect(d, up: Declarations;
                              name: ARRAY OF CHAR; start, end: INTEGER);
BEGIN
	DeclarationsInit(d, up);
	IF name # "" THEN
		DeclConnect(d, up, name, start, end)
	ELSE
		(* Record *)
		DeclInit(d, up)
	END;
	d.up := up.dag
END DeclarationsConnect;

PROCEDURE ModuleNew*(name: ARRAY OF CHAR): Module;
VAR m: Module;
BEGIN
	NEW(m);
	NodeInit(m^, NoId);
	DeclarationsInit(m, NIL);
	NEW(m.bag);
	m.bag.m := m;
	m.fixed := FALSE;
	m.spec := FALSE;
	m.import := NIL;
	m.errors := NIL; m.errLast := NIL;
	Strings.StoreInit(m.store);

	PutChars(m, m.name, name, 0, Chars0X.CalcLen(name, 0));
	m.module := m.bag;
	m.errorHide := TRUE;
	m.handleImport := FALSE;
	m.script := FALSE
	RETURN m
END ModuleNew;

PROCEDURE ScriptNew*(): Module;
VAR m: Module;
BEGIN
	m := ModuleNew("script");
	m.script := TRUE
	RETURN m
END ScriptNew;

PROCEDURE ProvideModule*(prov: Provider; host: Module;
                         name: ARRAY OF CHAR): Module;
BEGIN
	ASSERT(prov # NIL);
	(* TODO *)
	ASSERT(name # "")

	RETURN prov.get(prov, host, name)
END ProvideModule;

PROCEDURE GetModuleByName*(prov: Provider; host: Module; name: ARRAY OF CHAR): ModuleBag;
VAR m: Module; b: ModuleBag;
BEGIN
	m := ProvideModule(prov, host, name);
	IF m # NIL THEN
		b := m.bag
	ELSE
		b := NIL
	END
	RETURN b
END GetModuleByName;

(* Возвращает истину, если имя модуля совпадает с ожидаемым *)
PROCEDURE RegModule*(provider: Provider; m: Module): BOOLEAN;
RETURN provider.reg(provider, m)
END RegModule;

PROCEDURE CheckUnusedDeclarations(ds: Declarations): INTEGER;
VAR d: Declaration;
    err: INTEGER;
BEGIN
	d := ds.start;
	WHILE (d # NIL) & (d IS Import) DO
		d := d.next
	END;
	WHILE (d # NIL)
	    & (d.mark OR d.used
	    OR (d IS Var) & ({} # {InitedValue, InitedNil} * d(Var).state.inited)
	      )
	DO
		d := d.next
	END;
	IF d = NIL THEN
		err := ErrNo
	ELSE
		ds.module.m.unusedDecl := d;
		err := ErrDeclarationUnused
	END
	RETURN err
END CheckUnusedDeclarations;

PROCEDURE ModuleEnd*(m: Module): INTEGER;
VAR err: INTEGER;
BEGIN
	ASSERT(~m.fixed);
	m.fixed := TRUE;
	IF m.script THEN
		err := ErrNo
	ELSE
		err := CheckUnusedDeclarations(m)
		(* TODO проверять наличие используемых не инициализировавшихся
		   глобальных переменных *)
	END
	RETURN err
END ModuleEnd;

PROCEDURE ModuleReopen*(m: Module);
BEGIN
	ASSERT(m.fixed);
	ASSERT(m # system);
	m.fixed := FALSE
END ModuleReopen;

PROCEDURE ImportHandle*(m: Module);
BEGIN
	ASSERT(~m.handleImport);
	m.handleImport := TRUE
END ImportHandle;

PROCEDURE ImportEnd*(m: Module);
BEGIN
	ASSERT(m.handleImport);
	m.handleImport := FALSE
END ImportEnd;

PROCEDURE ImportAdd*(prov: Provider; m: Module; buf: ARRAY OF CHAR;
                     nameOfs, nameEnd, realOfs, realEnd: INTEGER;
                     allowSystem: BOOLEAN): INTEGER;
VAR imp: Import;
	i: Declaration;
	err, ofs: INTEGER;
	name: ARRAY TranLim.LenName + 1 OF CHAR;

	PROCEDURE Load(VAR res: ModuleBag; prov: Provider; host: Module; name: ARRAY OF CHAR): INTEGER;
	VAR err, i: INTEGER; m: Module;
	BEGIN
		i := 0;
		res := GetModuleByName(prov, host, name);
		IF res = NIL THEN
			m := ModuleNew(name);
			res := m.bag;
			err := ErrImportModuleNotFound
		ELSIF res.m.errors # NIL THEN
			err := ErrImportModuleWithError
		ELSIF res.m.handleImport THEN
			err := ErrImportLoop
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
		          (i.name.ofs # i.module.m.name.ofs)
		       OR (i.name.block # i.module.m.name.block)
		       )
		       & Strings.IsEqualToChars(i.module.m.name, buf, realOfs, realEnd)
	END IsDup;
BEGIN
	ASSERT(~m.fixed);

	i := m.import;
	ASSERT((i = NIL) OR (m.end IS Import));
	IF Strings.IsEqualToChars(m.name, buf, realOfs, realEnd) THEN
		err := ErrImportSelf
	ELSE
		WHILE (i # NIL)
		    & ~IsDup(i(Import), buf, nameOfs, nameEnd, realOfs, realEnd)
		DO
			i := i.next
		END;
		IF i # NIL THEN
			err := ErrImportNameDuplicate
		ELSE
			NEW(imp); NodeInit(imp^, IdImport);
			DeclConnect(imp, m, buf, nameOfs, nameEnd);
			imp.mark := TRUE;
			IF m.import = NIL THEN
				m.import := imp
			END;
			ofs := 0;
			ASSERT(Chars0X.CopyChars(name, ofs, buf, realOfs, realEnd));
			IF allowSystem & (name = "SYSTEM") THEN
				imp.module := system.bag;
				err := ErrNo
			ELSE
				err := Load(imp.module, prov, m, name)
			END
		END
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
	END
	RETURN d
END SearchName;

PROCEDURE DeclarationLineSearch(ds: Declarations; buf: ARRAY OF CHAR;
                             begin, end: INTEGER): Declaration;
VAR d: Declaration;
BEGIN
	d := SearchName(ds.start, buf, begin, end);
	IF (d = NIL) & (ds IS Procedure) THEN
		d := SearchName(ds(Procedure).header.params, buf, begin, end)
	END
	RETURN d
END DeclarationLineSearch;

PROCEDURE CheckNameDuplicate(ds: Declarations;
                             VAR buf: ARRAY OF CHAR; begin, end: INTEGER): INTEGER;
VAR err: INTEGER;
BEGIN
	IF begin < 0 THEN
		err := ErrNo
	ELSIF DeclarationLineSearch(ds, buf, begin, end) # NIL THEN
		err := ErrDeclarationNameDuplicate
	ELSIF ds.module.m.errorHide & (ds.up # NIL)
	    & (DeclarationLineSearch(ds.module.m, buf, begin, end) # NIL)
	THEN
		err := ErrDeclarationNameHide
	ELSIF ds.module.m.errorHide
	    & SpecIdent.IsPredefined(err, buf, begin, end)
	THEN
		err := ErrPredefinedNameHide
	ELSE
		err := ErrNo
	END
	RETURN err
END CheckNameDuplicate;

PROCEDURE ConstAdd*(ds: Declarations; VAR buf: ARRAY OF CHAR; begin, end: INTEGER;
                    VAR c: Const): INTEGER;
VAR err: INTEGER;
BEGIN
	ASSERT(~ds.module.m.fixed);

	NEW(c); NodeInit(c^, IdConst);
	err := CheckNameDuplicate(ds, buf, begin, end);
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
                   VAR buf: ARRAY OF CHAR; begin, end: INTEGER;
                   VAR td: Type): INTEGER;
VAR d: Declaration;
	err: INTEGER;

	(* Нужен для правильной генерации в Си опережающих объявлений.
	   Отказаться от переноса и изменить генерацию? *)
	PROCEDURE MoveForwardDeclToLast(ds: Declarations; rec: Record);
	VAR t: Declaration;
	BEGIN
		IF rec.next # NIL THEN
			IF rec.pointer.next = rec THEN
				t := rec.pointer
			ELSE
				t := ds.types;
				WHILE t.next # rec DO
					t := t.next
				END
			END;
			t.next := rec.next;
			rec.next := NIL;

			ds.end.next := rec;
			ds.end := rec
		END;
		DEC(ds.recordForwardCount);
		ASSERT(0 <= ds.recordForwardCount)
	END MoveForwardDeclToLast;
BEGIN
	ASSERT(~ds.module.m.fixed);

	d := DeclarationLineSearch(ds, buf, begin, end);
	IF ((d = NIL) OR (d.id = IdRecordForward))
	OR (d = NIL) & ((ds.up = NIL)
	             OR (DeclarationLineSearch(ds.module.m, buf, begin, end) = NIL))
	THEN
		IF SpecIdent.IsPredefined(err, buf, begin, end) THEN
			err := ErrPredefinedNameHide
		ELSE
			err := ErrNo
		END
	ELSIF d = NIL THEN
		err := ErrDeclarationNameHide
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

PROCEDURE CheckUndefRecordForward*(ds: Declarations): INTEGER;
VAR err: INTEGER;
BEGIN
	IF ds.recordForwardCount = 0 THEN
		err := ErrNo
	ELSE
		err := ErrRecordForwardUndefined;
		ds.recordForwardCount := 0
	END
	RETURN err
END CheckUndefRecordForward;

PROCEDURE VarStateInit(vs, root: VarState);
BEGIN
	ASSERT(root.else = NIL);

	vs.inited := root.inited - {Used, Dereferenced};
	vs.inCondition := root.inited # {InitedValue};
	vs.root := root;
	IF root.if = NIL THEN
		root.if   := vs
	ELSE
		root.else := vs
	END
END VarStateInit;

PROCEDURE VarStateRootInit(vs: VarState);
BEGIN
	vs.inited      := {InitedNo};
	vs.inCondition := FALSE;
	vs.if   := NIL;
	vs.else := NIL;
	vs.root := NIL
END VarStateRootInit;

PROCEDURE VarStateNew(root: VarState): VarState;
VAR vs: VarState;
BEGIN
	NEW(vs); VarStateInit(vs, root)
	RETURN vs
END VarStateNew;

PROCEDURE VarStateUp(VAR vs: VarState);
CONST MayNotInited = {InitedNo, InitedValue};
VAR if, else, both: SET;
BEGIN
	ASSERT((vs.root.if = vs) OR (vs.root.else = vs));

	vs := vs.root;
	if := vs.if.inited;
	vs.if := NIL;
	IF vs.else # NIL THEN
		else := vs.else.inited;
		vs.else := NIL
	ELSE
		else := vs.inited
	END;
	IF if * {InitedFail} = else * {InitedFail} THEN
		;
	ELSIF InitedFail IN if THEN
		if := else
	ELSE ASSERT(InitedFail IN else);
		else := if
	END;
	both := if + else;
	IF (vs.inited * MayNotInited = MayNotInited)
	 & (   (if   * MayNotInited = {InitedValue})
	    OR (else * MayNotInited = {InitedValue})
	   )
	THEN
		vs.inited := both - {InitedNo} + {InitedCheck}
	ELSE
		vs.inited := both
	END
END VarStateUp;

PROCEDURE TurnIf*(ds: Declarations);

	PROCEDURE Handle(d: Declaration);
	VAR v: Var; vs: VarState;
	BEGIN
		WHILE (d # NIL) & (d.id = IdVar) DO
			v := d(Var);
			ASSERT(v.state.if = NIL);
			vs := VarStateNew(v.state);
			ASSERT(v.state.if = vs);
			v.state := vs;
			d := d.next
		END
	END Handle;
BEGIN
	IF ds.id = IdProc THEN
		Handle(ds(Procedure).header.params);
		Handle(ds.vars)
	END
END TurnIf;

PROCEDURE TurnElse*(ds: Declarations);

	PROCEDURE Handle(d: Declaration);
	VAR v: Var; vs: VarState;
	BEGIN
		WHILE (d # NIL) & (d.id = IdVar) DO
			v := d(Var);
			ASSERT(v.state.root.if = v.state);
			vs := VarStateNew(v.state.root);
			ASSERT(v.state.root.else = vs);
			ASSERT(v.state.root.if = v.state);
			v.state := vs;
			d := d.next
		END
	END Handle;
BEGIN
	IF ds.id = IdProc THEN
		Handle(ds(Procedure).header.params);
		Handle(ds.vars)
	END
END TurnElse;

PROCEDURE TurnFail*(ds: Declarations);
	PROCEDURE Handle(d: Declaration);
	BEGIN
		WHILE (d # NIL) & (d.id = IdVar) DO
			INCL(d(Var).state.inited, InitedFail);
			d := d.next
		END
	END Handle;
BEGIN
	IF ds.id = IdProc THEN
		Handle(ds(Procedure).header.params);
		Handle(ds.vars)
	END
END TurnFail;

PROCEDURE BackFromBranch*(ds: Declarations);
	PROCEDURE Handle(d: Declaration);
	VAR v: Var;
	BEGIN
		WHILE (d # NIL) & (d.id = IdVar) DO
			v := d(Var);
			VarStateUp(v.state);
			IF InitedCheck IN v.state.inited THEN
				v.checkInit := TRUE
			END;
			d := d.next
		END
	END Handle;
BEGIN
	IF ds.id = IdProc THEN
		Handle(ds(Procedure).header.params);
		Handle(ds.vars)
	END
END BackFromBranch;

PROCEDURE ChecklessVarAdd(VAR v: Var; ds: Declarations;
                          buf: ARRAY OF CHAR; begin, end: INTEGER);
BEGIN
	NEW(v); NodeInit(v^, IdVar);
	DeclConnect(v, ds, buf, begin, end);
	v.type := NIL;

	NEW(v.state); VarStateRootInit(v.state);
	v.checkInit  := FALSE;
	v.inVarParam := FALSE;

	IF ds.vars = NIL THEN
		ds.vars := v
	END;
	ds.varsEnd := v
END ChecklessVarAdd;

PROCEDURE VarAdd*(VAR v: Var; ds: Declarations;
                  VAR buf: ARRAY OF CHAR; begin, end: INTEGER): INTEGER;
VAR err: INTEGER;
BEGIN
	ASSERT((ds.module = NIL) OR ~ds.module.m.fixed);
	err := CheckNameDuplicate(ds, buf, begin, end);
	ChecklessVarAdd(v, ds, buf, begin, end)
	RETURN err
END VarAdd;

PROCEDURE TypeInit(t: Type; id: INTEGER);
BEGIN
	NodeInit(t^, id);
	DeclInit(t, NIL);
	t.properties := { };
	t.array := NIL
END TypeInit;

PROCEDURE ProcTypeNew*(forType: BOOLEAN; id: INTEGER): ProcType;
VAR p: ProcType;
    fp: FormalProcType;
BEGIN
	ASSERT(id IN ProcTypes);
	IF forType THEN
		NEW(fp);
		p := fp
	ELSE
		NEW(p)
	END;
	TypeInit(p, id);
	p.params := NIL;
	p.end := NIL
	RETURN p
END ProcTypeNew;

PROCEDURE ParamAddPredefined(proc: ProcType; type: Type; access: SET);
VAR v: FormalParam;
BEGIN
	ASSERT({} = access - {ParamIn, ParamOut});
	ASSERT((proc.id = IdProcType) OR ~(ParamOut IN access));

	NEW(v); NodeInit(v^, IdVar);
	IF proc.end = NIL THEN
		proc.params := v
	ELSE
		proc.end.next := v
	END;
	proc.end := v;

	v.module := NIL;
	v.up := NIL;

	v.mark := FALSE;
	v.next := NIL;
	v.link := NIL;

	v.type := type;
	IF access = {} THEN
		v.access := {ParamIn}
	ELSE
		v.access := access
	END;
	v.needTag := NIL;

	NEW(v.state); VarStateRootInit(v.state);
	v.checkInit  := FALSE;
	v.inVarParam := FALSE;
	IF ParamIn IN v.access THEN
		v.state.inited := {InitedValue}
	ELSE
		v.state.inited := {InitedNo}
	END
END ParamAddPredefined;

PROCEDURE ParamAdd*(module: Module; proc: ProcType;
                    VAR buf: ARRAY OF CHAR; begin, end: INTEGER;
                    access: SET): INTEGER;
VAR err: INTEGER;
BEGIN
	IF SearchName(proc.params, buf, begin, end) # NIL THEN
		err := ErrDeclarationNameDuplicate
	ELSIF ~(proc IS FormalProcType)
	    & (DeclarationLineSearch(module, buf, begin, end) # NIL)
	THEN
		err := ErrDeclarationNameHide
	ELSIF module.errorHide
	    & SpecIdent.IsPredefined(err, buf, begin, end)
	THEN
		err := ErrPredefinedNameHide
	ELSIF (proc.id = IdFuncType) & (ParamOut IN access) THEN
		err := ErrParamOutInFunc;
		proc.id := IdProcType
	ELSE
		err := ErrNo
	END;
	ParamAddPredefined(proc, NIL, access);
	PutChars(module, proc.end.name, buf, begin, end)
	RETURN err
END ParamAdd;

PROCEDURE ParamInsert*(VAR new: FormalParam;
                       prev: FormalParam;
                       module: Module; proc: ProcType;
                       VAR buf: ARRAY OF CHAR; begin, end: INTEGER;
                       type: Type; access: SET): INTEGER;
VAR err: INTEGER;
    fpEnd: FormalParam;
BEGIN
	ASSERT(proc.end # NIL);
	fpEnd := proc.end;
	err := ParamAdd(module, proc, buf, begin, end, access);
	new := proc.end;
	new.type := type;
	IF prev.next # new THEN
		new.next := prev.next;
		prev.next := new;
		proc.end := fpEnd;
		fpEnd.next := NIL
	END
	RETURN err
END ParamInsert;

PROCEDURE IsNeedTag*(p: FormalParam): BOOLEAN;
	RETURN (p.needTag # NIL) & (p.needTag.value)
END IsNeedTag;

PROCEDURE NewNeedTag(p: FormalParam; need: BOOLEAN);
BEGIN
	ASSERT(p.needTag = NIL);
	ASSERT(p.link = NIL);

	NEW(p.needTag);
	p.needTag.count := 1;
	p.needTag.first := p;
	p.needTag.last := p;

	p.needTag.value := need;

	p.needTag.next := needTags;
	needTags := p.needTag
END NewNeedTag;

PROCEDURE SetNeedTag(p: FormalParam);
BEGIN
	IF p.needTag = NIL THEN
		NewNeedTag(p, TRUE)
	ELSE
		p.needTag.value := TRUE
	END
END SetNeedTag;

PROCEDURE ExchangeParamsNeedTag(p1, p2: FormalParam);

	PROCEDURE Merge(list, del: NeedTagList);
	BEGIN
		ASSERT(list # del);
		ASSERT(list.last.link = NIL);
		ASSERT(del.last # NIL);

		IF del.value THEN
			list.value := TRUE
		END;
		list.count := list.count + del.count;
		list.last.link := del.first;
		list.last := del.last;
		ASSERT(list.last.link = NIL);
		del.last := NIL;
		WHILE del.first # NIL DO
			del.first.needTag := list;
			del.last := del.first.link;
			del.first := del.last
		END;
		ASSERT(list.last # NIL);
	END Merge;

	PROCEDURE Add(list: NeedTagList; p: FormalParam);
	BEGIN
		ASSERT(p.link = NIL);
		ASSERT(p.needTag = NIL);

		list.last.link := p;
		list.last := p;
		ASSERT(list.last # NIL);
		p.needTag := list
	END Add;
BEGIN
	IF p1 = p2 THEN
		;
	ELSIF p1.needTag = NIL THEN
		IF p2.needTag = NIL THEN
			NewNeedTag(p2, FALSE);
		END;
		Add(p2.needTag, p1)
	ELSE
		IF p2.needTag = NIL THEN
			Add(p1.needTag, p2)
		ELSIF p2.needTag.count > p1.needTag.count THEN
			Merge(p2.needTag, p1.needTag)
		ELSIF p1.needTag # p2.needTag THEN
			Merge(p1.needTag, p2.needTag)
		END
	END
END ExchangeParamsNeedTag;

PROCEDURE ProcTypeSetReturn*(proc: ProcType; type: Type): INTEGER;
VAR err: INTEGER;
BEGIN
	proc.type := type;
	IF ~(type.id IN {IdArray, IdRecord}) THEN
		err := ErrNo
	ELSE
		err := ErrReturnTypeArrayOrRecord
	END
	RETURN err
END ProcTypeSetReturn;

PROCEDURE AddError*(m: Module; error, line, column: INTEGER);
VAR e: Error;
BEGIN
	NEW(e); NodeInit(e^, NoId);
	e.next := NIL;
	e.code := error;
	e.line := line;
	e.column := column;
	IF m.unusedDecl = NIL THEN
		Strings.Undef(e.str)
	ELSE
		e.str := m.unusedDecl.name;
		m.unusedDecl := NIL
	END;
	IF m.errLast = NIL THEN
		m.errors := e
	ELSE
		m.errLast.next := e
	END;
	m.errLast := e
END AddError;

PROCEDURE TypeGet*(id: INTEGER): Type;
BEGIN
	ASSERT(types[id] # NIL)
	RETURN types[id]
END TypeGet;

(* if count is NIL then return open array *)
PROCEDURE ArrayGet*(t: Type; count: Expression): Array;
VAR a: Array;
BEGIN
	IF (count # NIL) OR (t = NIL) OR (t.array = NIL) THEN
		NEW(a); TypeInit(a, IdArray);
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

PROCEDURE MultArrayLenByExpr*(VAR size: INTEGER; e: Expression): INTEGER;
VAR i, err: INTEGER;
BEGIN
	err := ErrNo;
	IF e = NIL THEN
		(* TODO стоит избавиться от такой возможности *)
	ELSIF (e.value # NIL) & (e.value IS ExprInteger) THEN
		i := e.value(ExprInteger).int;
		IF i <= 0 THEN
			err := ErrArrayLenLess1
		ELSIF ~Arithmetic.Mul(size, size, i) THEN
			size := 0;
			err := ErrArrayLenTooBig
		END
	ELSIF e.id # IdError THEN
		err := ErrExpectConstIntExpr
	END
	RETURN err
END MultArrayLenByExpr;

PROCEDURE PointerGet*(t: Record): Pointer;
VAR p: Pointer;
BEGIN
	IF (t = NIL) OR (t.pointer = NIL) THEN
		NEW(p); TypeInit(p, IdPointer);
		p.type := t;
		IF t # NIL THEN
			t.pointer := p
		END
	ELSE
		p := t.pointer
	END
	RETURN p
END PointerGet;

PROCEDURE PointerSetRecord*(tp: Pointer; subtype: Record);
BEGIN
	tp.type := subtype;
	subtype.pointer := tp
END PointerSetRecord;

PROCEDURE PointerSetType*(tp: Pointer; subtype: Type): INTEGER;
VAR err: INTEGER;
BEGIN
	IF subtype.id IN {IdRecord, IdRecordForward} THEN
		PointerSetRecord(tp, subtype(Record));
		err := ErrNo
	ELSE
		(* TODO Установить ошибочную запись *)
		tp.type := subtype;
		err := ErrPointerToNotRecord
	END
	RETURN err
END PointerSetType;

PROCEDURE RecordSetBase*(r, base: Record);
BEGIN
	ASSERT(r.base = NIL);
	ASSERT(r.vars = NIL);
	IF base # NIL THEN
		base.hasExt := TRUE;
		r.base := base
	END
END RecordSetBase;

PROCEDURE RecNew(VAR r: Record; id: INTEGER);
BEGIN
	ASSERT(id IN {IdRecord, IdRecordForward});

	NEW(r); TypeInit(r, id);
	r.pointer := NIL;
	r.vars := NIL;
	r.base := NIL;
	r.needTag  := FALSE;
	(* TODO *)
	r.inAssign := TRUE;
	r.hasExt := FALSE;
	r.complete := FALSE
END RecNew;

PROCEDURE RecordNew*(ds: Declarations; base: Record): Record;
VAR r: Record;
BEGIN
	RecNew(r, IdRecord);
	RecordSetBase(r, base)
	RETURN r
END RecordNew;

PROCEDURE RecordForwardNew*(ds: Declarations;
                            name: ARRAY OF CHAR; begin, end: INTEGER): Record;
VAR r: Record;
BEGIN
	RecNew(r, IdRecordForward);
	DeclConnect(r, ds, name, begin, end);
	INC(ds.recordForwardCount)
	RETURN r
END RecordForwardNew;

PROCEDURE RecordEnd*(r: Record): INTEGER;
BEGIN
	ASSERT(r.id IN {IdRecord, IdRecordForward});
	r.id := IdRecord;
	r.used := TRUE;
	r.complete := TRUE
	RETURN ErrNo
END RecordEnd;

PROCEDURE PredefinedGet*(id: INTEGER): Declaration;
	RETURN predefined[id - SpecIdent.PredefinedFirst]
END PredefinedGet;

PROCEDURE SearchPredefined(VAR buf: ARRAY OF CHAR; begin, end: INTEGER): Declaration;
VAR d: Declaration;
	l: INTEGER;
BEGIN
	IF SpecIdent.IsPredefined(l, buf, begin, end) THEN
		d := PredefinedGet(l);
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
					ds := ds.up.d
				UNTIL (ds = NIL) OR (ds IS Module);
				IF ds # NIL THEN
					d := SearchName(ds.start, buf, begin, end)
				END
			END
		ELSE (* TODO Нужно ли это ?*)
			WHILE (d = NIL) & (ds.up # NIL) DO
				ds := ds.up.d;
				d := SearchName(ds.start, buf, begin, end)
			END
		END;
		IF (d = NIL) & (ds IS Module) & ~ds(Module).fixed THEN
			d := SearchPredefined(buf, begin, end)
		END
	END;
	IF (d # NIL) & (d IS Type) THEN
		d.used := TRUE
	END
	RETURN d
END DeclarationSearch;

PROCEDURE TypeErrorNew*(): Type;
VAR type: Type;
BEGIN
	NEW(type); NodeInit(type^, IdError); DeclInit(type, NIL)
	RETURN type
END TypeErrorNew;

PROCEDURE DeclErrorNew*(ds: Declarations;
                        VAR buf: ARRAY OF CHAR; begin, end: INTEGER): Declaration;
VAR d: Declaration;
BEGIN
	NEW(d); NodeInit(d^, IdError);
	DeclConnect(d, ds, buf, begin, end);
	d.type := TypeErrorNew();
	d.used := TRUE;
	d.mark := TRUE
	RETURN d
END DeclErrorNew;

PROCEDURE RegularDeclGet(VAR d: Declaration; prov: Provider; ds: Declarations;
                         VAR buf: ARRAY OF CHAR; begin, end: INTEGER): INTEGER;
VAR err: INTEGER;
BEGIN
	d := DeclarationSearch(ds, buf, begin, end);
	IF d = NIL THEN
		IF (ds.module # NIL) & ds.module.m.script THEN
			err := ImportAdd(prov, ds.module.m, buf, begin, end, begin, end, FALSE);
			d := ds.end
		ELSE
			err := ErrNo
		END;
		IF (d = NIL) & (err = ErrNo) THEN
			err := ErrDeclarationNotFound;
			d := DeclErrorNew(ds, buf, begin, end);
			ASSERT(d.type # NIL)
		END
	ELSIF ~d.mark & (d.module # NIL) & d.module.m.fixed THEN
		err := ErrDeclarationIsPrivate
	ELSIF (d IS Const) & ~d(Const).finished THEN
		err := ErrConstRecursive;
		d(Const).finished := TRUE
	ELSE
		err := ErrNo
	END
	RETURN err
END RegularDeclGet;

PROCEDURE DeclarationGet*(VAR d: Declaration; prov: Provider; ds: Declarations;
                          VAR buf: ARRAY OF CHAR; begin, end: INTEGER): INTEGER;
VAR err, id: INTEGER;
BEGIN
	IF ds # system THEN
		err := RegularDeclGet(d, prov, ds, buf, begin, end)
	ELSIF SpecIdent.IsSystemProc(id, buf, begin, end) THEN
		d := predefined[id - SpecIdent.PredefinedFirst];
		err := ErrNo
	ELSE
		err := ErrDeclarationNotFound
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
		IF ~d.mark & d.module.m.fixed THEN
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
	NodeInit(e^, id);
	IF t # NIL THEN
		t.used := TRUE
	END;
	e.type := t;
	e.properties := {};
	e.value := NIL
END ExprInit;

PROCEDURE ValueInit(f: Factor; id: INTEGER; t: Type);
BEGIN
	ExprInit(f, id, t);
	f.value := f;
	f.nextValue := values;
	values := f
END ValueInit;

PROCEDURE ExprIntegerNew*(int: INTEGER): ExprInteger;
VAR e: ExprInteger;
BEGIN
	NEW(e); ValueInit(e, IdInteger, TypeGet(IdInteger));
	e.int := int
	RETURN e
END ExprIntegerNew;

PROCEDURE ExprRealNew*(real: REAL; m: Module;
                       buf: ARRAY OF CHAR; begin, end: INTEGER): ExprReal;
VAR e: ExprReal;
BEGIN
	ASSERT(m # NIL);
	NEW(e); ValueInit(e, IdReal, TypeGet(IdReal));
	e.real := real;
	PutChars(m, e.str, buf, begin, end)
	RETURN e
END ExprRealNew;

PROCEDURE ExprRealNewByValue*(real: REAL): ExprReal;
VAR e: ExprReal;
BEGIN
	NEW(e); ValueInit(e, IdReal, TypeGet(IdReal));
	e.real := real;
	Strings.Undef(e.str)
	RETURN e
END ExprRealNewByValue;

PROCEDURE ExprBooleanGet*(bool: BOOLEAN): ExprBoolean;
VAR e: ExprBoolean;
BEGIN
	e := booleans[ORD(bool)];
	IF e = NIL THEN
		NEW(e); ValueInit(e, IdBoolean, TypeGet(IdBoolean));
		e.bool := bool;
		booleans[ORD(bool)] := e
	END
	RETURN e
END ExprBooleanGet;

PROCEDURE ExprStringNewPre(s: Strings.String; typ: Array): ExprString;
VAR e: ExprString;
BEGIN
	NEW(e); ValueInit(e, IdString, typ);
	e.usedAs := StrUsedUndef;
	e.int := -1;
	e.asChar := FALSE;
	e.string := s
	RETURN e
END ExprStringNewPre;

PROCEDURE ExprStringNew*(m: Module; buf: ARRAY OF CHAR; begin, end: INTEGER): ExprString;
VAR e: ExprString; s: Strings.String; len: INTEGER;
BEGIN
	ASSERT(buf[begin] = Utf8.DQuote);
	len := end - begin;
	(* поправка на циклический буфер *)
	IF len < 0 THEN
		len := len + LEN(buf) - 1
	END;
	DEC(len, 1);
	PutChars(m, s, buf, begin, end);
	e := ExprStringNewPre(s, ArrayGet(TypeGet(IdChar), ExprIntegerNew(len)));
	ASSERT(StrUsedUndef + 1 = StrUsedAsArray);
	e.usedAs := StrUsedUndef + ORD(len # 3)
	RETURN e
END ExprStringNew;

PROCEDURE ExprCharNew*(int: INTEGER): ExprString;
VAR e: ExprString;
BEGIN
	NEW(e); ValueInit(e, IdString, ArrayGet(TypeGet(IdChar), ExprIntegerNew(2)));
	Strings.Undef(e.string);
	e.usedAs := StrUsedUndef;
	e.int := int;
	e.asChar := TRUE
	RETURN e
END ExprCharNew;

PROCEDURE ExprStringCopy(str: ExprString): ExprString;
VAR e: ExprString;
BEGIN
	IF str.asChar THEN
		e := ExprCharNew(str.int)
	ELSE
		e := ExprStringNewPre(str.string, str.type(Array))
	END
	RETURN e
END ExprStringCopy;

PROCEDURE StringUsedAs(e: ExprString; as: INTEGER);
BEGIN
	ASSERT(as IN {StrUsedAsChar, StrUsedAsArray});
	ASSERT((e.usedAs = StrUsedUndef)
	    OR (as = StrUsedAsArray) & (e.usedAs = StrUsedAsArray));
	e.usedAs := as
END StringUsedAs;

PROCEDURE StringUsedWithType(e: ExprString; donor: Type);
BEGIN
	IF donor.id = IdArray THEN
		StringUsedAs(e, StrUsedAsArray)
	ELSE ASSERT(donor.id IN {IdChar, IdBasic});
		StringUsedAs(e, StrUsedAsChar)
	END
END StringUsedWithType;

PROCEDURE StringUsedWithExpr(e: ExprString; donor: Expression);
BEGIN
	IF donor.id # IdString THEN
		StringUsedWithType(e, donor.type)
	ELSIF donor(ExprString).usedAs # StrUsedUndef THEN
		StringUsedAs(e, donor(ExprString).usedAs)
	END
END StringUsedWithExpr;

PROCEDURE ExprNilGet*(): ExprNil;
BEGIN
	IF nil = NIL THEN
		NEW(nil); ValueInit(nil, IdPointer, TypeGet(IdPointer));
		nil.properties := { ExprPointerTouch };
		ASSERT(nil.type.type = NIL)
	END
	RETURN nil
END ExprNilGet;

PROCEDURE ExprErrNew*(): Expression;
VAR e: Factor;
BEGIN
	NEW(e); ExprInit(e, IdError, TypeErrorNew());
	RETURN e
END ExprErrNew;

PROCEDURE Prop(e: Expression): SET;
VAR p: SET;
BEGIN
	IF e = NIL THEN
		p := {}
	ELSE
		p := e.properties
	END
	RETURN p
END Prop;

PROCEDURE PropTouch(e: Expression; prop: SET);
BEGIN
	e.properties := e.properties
	              + prop * { ExprPointerTouch, ExprIntNegativeDividentTouch }
END PropTouch;

PROCEDURE ExprBracesNew*(expr: Expression): ExprBraces;
VAR e: ExprBraces;
BEGIN
	NEW(e); ExprInit(e, IdBraces, expr.type);
	e.expr := expr;
	e.value := expr.value;
	PropTouch(e, Prop(expr))
	RETURN e
END ExprBracesNew;

PROCEDURE ExprSetByValue*(set: LongSet.Type): ExprSetValue;
VAR e: ExprSetValue;
BEGIN
	NEW(e); ValueInit(e, IdSet, TypeGet(IdSet));
	e.set := set;
	RETURN e
END ExprSetByValue;

(* TODO сделать дизайн получше *)
PROCEDURE ExprSetNew*(VAR base, e: ExprSet; expr1, expr2: Expression): INTEGER;
VAR err, left, right: INTEGER; set: LongSet.Type;
BEGIN
	NEW(e); ExprInit(e, IdSet, TypeGet(IdSet));
	e.exprs[0] := expr1;
	e.exprs[1] := expr2;
	e.next := NIL;
	err := ErrNo;
	IF (expr1 = NIL) & (expr2 = NIL) THEN
		;
	ELSIF (expr1 # NIL) & (expr1.type # NIL)
		& ((expr2 = NIL) OR (expr2.type # NIL))
	THEN
		IF (expr1.type.id # IdInteger)
		OR (expr2 # NIL) & (expr2.type.id # IdInteger)
		THEN
			err := ErrNotIntSetElem
		ELSIF (expr1.value # NIL) & ((expr2 = NIL) OR (expr2.value # NIL)) THEN
			LongSet.Empty(set);

			left := expr1.value(ExprInteger).int;
			IF expr2 # NIL THEN
				right := expr2.value(ExprInteger).int
			END;
			IF ~LongSet.InRange(left)
			OR (expr2 # NIL) & ~LongSet.InRange(right)
			THEN
				err := ErrSetElemOutOfLongRange
			ELSIF expr2 = NIL THEN
				IF left <= Limits.SetMax THEN
					set[0] := {left};
				ELSE
					set[1] := {left MOD (Limits.SetMax + 1)}
				END
			ELSIF left > right THEN
				err := ErrSetLeftElemBiggerRightElem
			ELSIF right <= Limits.SetMax THEN
				set[0] := {left .. right}
			ELSIF left > Limits.SetMax THEN
				set[1] := {left MOD (Limits.SetMax + 1) .. right MOD (Limits.SetMax + 1)}
			ELSE
				set[0] := {left .. Limits.SetMax};
				set[1] := {0, right MOD (Limits.SetMax + 1)}
			END;
			IF err = ErrNo THEN
				e.value := ExprSetByValue(set);

				e.nextValue := values;
				values := e
			END
		END
	END;
	IF base = NIL THEN
		base := e
	ELSIF (base.value # NIL) & (e.value # NIL) THEN
		LongSet.Union(base.value(ExprSetValue).set, set)
	END;
	PropTouch(base, Prop(expr1) + Prop(expr2))

	RETURN err
END ExprSetNew;

PROCEDURE ExprNegateNew*(VAR neg: ExprNegate; expr: Expression): INTEGER;
VAR err: INTEGER;
BEGIN
	NEW(neg); ExprInit(neg, IdNegate, TypeGet(IdBoolean));
	neg.expr := expr;
	PropTouch(neg, Prop(expr));
	IF (expr.type # NIL) & (expr.type.id # IdBoolean) THEN
		err := ErrNegateNotBool
	ELSE
		err := ErrNo;
		IF expr.value # NIL THEN
			neg.value := ExprBooleanGet(~expr.value(ExprBoolean).bool)
		END
	END
	RETURN err
END ExprNegateNew;

PROCEDURE DesignatorNew*(VAR d: Designator; decl: Declaration): INTEGER;
BEGIN
	NEW(d); ExprInit(d, IdDesignator, NIL);
	d.decl := decl;
	d.sel := NIL;
	d.type := decl.type;
	IF decl IS Var THEN
		d.inited := decl(Var).state.inited
	ELSE
		d.inited := {InitedValue};
		IF decl IS Const THEN
			d.value := decl(Const).expr.value;
			ASSERT(d.value # NIL)
		ELSIF decl IS GeneralProcedure THEN
			d.type := decl(GeneralProcedure).header
		END
	END
	RETURN ErrNo
END DesignatorNew;

PROCEDURE IsGlobal*(d: Declaration): BOOLEAN;
	RETURN (d.up # NIL) & (d.up.d.up = NIL)
END IsGlobal;

PROCEDURE DesignatorUsed*(d: Designator; context: SET): INTEGER;
VAR err: INTEGER; v: Var;

	PROCEDURE InVarParam(v: Var; sel: Selector);
	BEGIN
		IF sel = NIL THEN
			v.inVarParam := TRUE
		ELSE
			WHILE sel.next # NIL DO
				sel := sel.next
			END;
			IF (sel IS SelRecord) & (sel(SelRecord).var # NIL) THEN
				(* TODO NIL возникает при разборе ошибочной программы. Заменить NIL на заглушку *)
				sel(SelRecord).var.inVarParam := TRUE
			END
		END
	END InVarParam;
BEGIN
	err := ErrNo;
	IF d.decl IS Var THEN
		v := d.decl(Var);

		IF (ParamForAddress IN context) & (v.state.inited * {InitedValue, InitedCheck} = {}) THEN
			v.state.inited := v.state.inited - {InitedNo} + {InitedValue(*TODO remove*), InitedCheck};
			v.checkInit := TRUE
		ELSIF (ParamOut IN context) & ({ParamOfPredefined, ParamIn} + context # context) THEN
			IF context # (context + {ParamOutReturnable, ParamOfPredefined}) THEN
				InVarParam(v, d.sel)
			END;
			IF ~(ParamOfPredefined IN context) & ~(InitedValue IN v.state.inited) THEN
				v.checkInit := TRUE;
				INCL(v.state.inited, InitedCheck)
			END;
			v.state.inited := v.state.inited - {InitedNo} + {InitedValue}
		ELSIF (v.type.id = IdPointer)
		    & (d.sel # NIL) & ~IsGlobal(v)
		    & ( ~(InitedValue IN v.state.inited)
		      & ~(v.state.inCondition & (InLoop IN context))
		    OR  ~v.state.inCondition
		      & ({} # (v.state.inited * {InitedNo, InitedNil}))
		      )
		THEN
			err := ErrVarUninitialized (* TODO *)
		ELSIF ~(~(InitedNo IN v.state.inited)
		    OR v.state.inCondition & ({} # v.state.inited - {InitedNo})
		       )
		   & ~(InLoop IN context) (* TODO *)
		   & ((v.up # NIL) & (v.up.d.up # NIL) OR (v IS FormalParam))
		THEN
			err := ErrVarUninitialized - ORD(InitedValue IN v.state.inited);
			v.state.inited := { InitedValue }
		ELSIF InitedNo IN v.state.inited THEN
			INCL(v.state.inited, InitedCheck);
			v.checkInit := TRUE
		END;
		INCL(v.state.inited, Used)
	END;
	d.decl.used := TRUE
	RETURN err
END DesignatorUsed;

PROCEDURE CheckInited*(ds: Declarations): INTEGER;
VAR err: INTEGER;
    d: Declaration;
    name: ARRAY 128 OF CHAR;
    len: INTEGER;
BEGIN
	d := ds.vars;
	WHILE (d # NIL) & (d IS Var)
	    & (~(Used IN d(Var).state.inited) OR (InitedValue IN d(Var).state.inited))
	DO
		d := d.next
	END;
	IF (d # NIL) & (d IS Var) THEN
		len := 0;
		IF Strings.CopyToChars(name, len, d.name) THEN
			Log.StrLn(name)
		END;
		err := ErrVarMayUninitialized
	ELSE
		err := ErrNo
	END
	RETURN err
END CheckInited;

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
	END
	RETURN t0 = t1
END IsRecordExtension;

PROCEDURE SelInit(s: Selector);
BEGIN
	NodeInit(s^, NoId);
	s.type := NIL;
	s.next := NIL
END SelInit;

PROCEDURE SelPointerNew*(VAR sel: Selector; VAR type: Type): INTEGER;
VAR sp: SelPointer;
	err: INTEGER;
BEGIN
	NEW(sp); SelInit(sp);
	sel := sp;
	type.used := TRUE;
	IF type IS Pointer THEN
		err := ErrNo;
		type := type.type
	ELSE
		err := ErrDerefToNotPointer
	END;
	sel.type := type
	RETURN err
END SelPointerNew;

PROCEDURE SelArrayNew*(VAR sel: Selector; VAR type: Type; value, index: Expression)
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
	ELSIF ~IsAllowStrIndex & (value # NIL) & (value IS ExprString) THEN
		err := ErrStringIndexing
	ELSE
		err := ErrNo
	END;
	type := type.type;
	sel.type := type
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
	NEW(v); NodeInit(v^, IdVar); DeclInit(v, NIL);
	v.module     := r.module;
	v.inVarParam := FALSE;
	v.checkInit  := FALSE;
	PutChars(v.module.m, v.name, name, begin, end);
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
	ELSIF ~v.mark & v.module.m.fixed THEN
		err := ErrDeclarationIsPrivate;
		v.mark := TRUE
	ELSE
		err := ErrNo
	END
	RETURN err
END RecordVarGet;

PROCEDURE VarListSetType*(first: Declaration; t: Type): INTEGER;
VAR d: Declaration;
    err: INTEGER;
BEGIN
	d := first;
	t.used := TRUE;
	WHILE d # NIL DO
		d.type := t;
		d := d.next
	END;

	err := ErrNo;
	IF t.id = IdPointer THEN
		IF (t.type.id = IdRecord) & ~t.type(Record).complete THEN
			err := ErrVarOfPointerToRecordForward
		END
	ELSIF (t.id = IdRecordForward)
	   OR (t.id = IdRecord) & ~t(Record).complete
	THEN
		err := ErrVarOfRecordForward
	END
	RETURN err
END VarListSetType;

PROCEDURE ArraySetType*(a: Array; t: Type): INTEGER;
VAR err: INTEGER;
BEGIN
	ASSERT(a.type = NIL);
	a.type := t;

	err := ErrNo;
	IF t.id = IdPointer THEN
		IF (t.type.id = IdRecord) & ~t.type(Record).complete THEN
			err := ErrArrayTypeOfPointerToRecordForward
		END
	ELSIF (t.id = IdRecordForward)
	   OR (t.id = IdRecord) & ~t(Record).complete
	THEN
		err := ErrArrayTypeOfRecordForward
	END
	RETURN err
END ArraySetType;

PROCEDURE ArrayGetSubtype*(a: Array; VAR subtype: Type): INTEGER;
VAR t: Type; i: INTEGER;
BEGIN
	t := a.type;
	i := 1;
	WHILE t.id = IdArray DO
		INC(i);
		t := t.type
	END;
	subtype := t
	RETURN i
END ArrayGetSubtype;

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
	sel := sr;
	sel.type := type
	RETURN err
END SelRecordNew;

PROCEDURE SelGuardNew*(VAR sel: Selector; des: Designator; guard: Declaration): INTEGER;
VAR sg: SelGuard;
	err, dist: INTEGER;
BEGIN
	NEW(sg); SelInit(sg);
	err := ErrNo;
	IF ~(des.type.id IN {IdRecord, IdPointer}) THEN
		err := ErrGuardedTypeNotExtensible
	ELSIF des.type.id = IdRecord THEN
		IF (guard = NIL)
		OR ~(guard IS Record)
		OR ~IsRecordExtension(dist, des.type(Record), guard(Record))
		THEN
			err := ErrGuardExpectRecordExt
		ELSE
			des.type := guard(Record);
			guard(Record).needTag := TRUE;
			IF (des.sel = NIL) & (des.decl IS FormalParam) THEN
				SetNeedTag(des.decl(FormalParam))
			END
		END
	ELSE
		IF (guard = NIL)
		OR ~(guard IS Pointer)
		OR ~IsRecordExtension(dist, des.type(Pointer).type(Record), guard(Pointer).type(Record))
		THEN
			err := ErrGuardExpectPointerExt
		ELSE
			des.type := guard(Pointer);
			guard.type(Record).needTag := TRUE
		END
	END;
	sg.type := des.type;
	sel := sg
	RETURN err
END SelGuardNew;

PROCEDURE EqualProcTypes*(t1, t2: ProcType): BOOLEAN;
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
		    & (fp1(FormalParam).access = fp2(FormalParam).access)
		DO
			ExchangeParamsNeedTag(fp1(FormalParam), fp2(FormalParam));
			fp1 := fp1.next;
			fp2 := fp2.next
		END;
		comp := ((fp1 = NIL) OR ~(fp1 IS FormalParam))
		      & ((fp2 = NIL) OR ~(fp2 IS FormalParam))
	END
	RETURN comp
END EqualProcTypes;

PROCEDURE CompatibleTypes*(VAR distance: INTEGER; t1, t2: Type; param: BOOLEAN): BOOLEAN;
VAR comp: BOOLEAN;
BEGIN
	distance := 0;
	(* совместимы, если ошибка в разборе *)
	comp := (t1 = t2) OR (t1 = NIL) OR (t2 = NIL);
	IF comp THEN
		;
	ELSIF (t1.id = t2.id)
		& (t1.id IN (Structures + Pointers))
	THEN
		CASE t1.id OF
		  IdArray   : comp := ((param & (t1(Array).count = NIL))
			                OR (~param & (t2(Array).count = NIL)))
			                & CompatibleTypes(distance, t1.type, t2.type, param)
		| IdPointer : comp := (t1.type = t2.type)
			               OR (t1.type = NIL) OR (t2.type = NIL) (* TODO *)
			               OR IsRecordExtension(distance, t1.type(Record),
			                                              t2.type(Record))
		| IdRecord  : comp := IsRecordExtension(distance, t1(Record), t2(Record))
		| IdProcType, IdFuncType
			        : comp := EqualProcTypes(t1(ProcType), t2(ProcType))
		END
	ELSIF t1.id IN ProcTypes THEN
		comp := (t2.id = IdPointer) & (t2.type = NIL)
	ELSIF t2.id IN ProcTypes THEN
		comp := (t1.id = IdPointer) & (t1.type = NIL)
	ELSIF t1.id = IdTypeAny THEN
		comp := TRUE
	END
	RETURN comp
END CompatibleTypes;

PROCEDURE ExprIsExtensionNew*(VAR e: ExprIsExtension; des: Expression;
                              type: Type): INTEGER;
VAR err, dist: INTEGER;
    desType: Type;
BEGIN
	NEW(e); ExprInit(e, IdIsExtension, TypeGet(IdBoolean));
	e.designator := NIL;
	e.extType := type;
	err := ErrNo;
	IF (type # NIL) & ~(type.id IN {IdPointer, IdRecord}) THEN
		err := ErrIsExtTypeNotRecord
	ELSIF des = NIL THEN
		;
	ELSIF des IS Designator THEN
		e.designator := des(Designator);
		desType := des.type;
		IF desType = NIL THEN
			;
		ELSIF ~(des.type.id IN {IdPointer, IdRecord}) THEN
			err := ErrIsExtVarNotRecord
		ELSIF type.id # des.type.id THEN
			err := ErrIsExtMeshupPtrAndRecord
		ELSE
			IF type.id = IdPointer THEN
				type := type.type;
				desType := desType.type
			ELSIF (e.designator.sel = NIL) & (e.designator.decl IS FormalParam)
			THEN
				SetNeedTag(e.designator.decl(FormalParam))
			END;
			IF IsRecordExtension(dist, desType(Record), type(Record)) THEN
				type(Record).needTag := TRUE;
			ELSE
				err := ErrIsExtExpectRecordExt
			END
		END
	ELSE
		err := ErrIsExtVarNotRecord
	END
	RETURN err
END ExprIsExtensionNew;

PROCEDURE CompatibleAsCharAndString(t1: Type; VAR e2: Expression): BOOLEAN;
VAR ret: BOOLEAN;
BEGIN
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

PROCEDURE CompatibleAsStrings(t: Type; e: Expression): BOOLEAN;
	RETURN (t.id = IdArray) & (t.type.id = IdChar) & (e.value # NIL) & (e.value IS ExprString)
END CompatibleAsStrings;

PROCEDURE IsChars(t: Type): BOOLEAN;
BEGIN
	RETURN (t.id = IdArray) & (t.type.id = IdChar)
END IsChars;

PROCEDURE ExprRelationNew*(VAR e: ExprRelation; expr1: Expression;
                           relation: INTEGER; expr2: Expression): INTEGER;
CONST
	AcceptableRelations = {RelationFirst .. RelationLast} - {Is};
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
		ELSIF relation = In THEN
			continue := (t1.id = IdInteger) & (t2.id IN Sets);
			IF ~continue THEN
				err := ErrExprInWrongTypes - 3 + ORD(t1.id # IdInteger)
				                               + ORD(~(t2.id IN Sets)) * 2
			END
		ELSIF ~CompatibleTypes(dist1, t1, t2, FALSE)
		    & ~CompatibleTypes(dist2, t2, t1, FALSE)
		    & ~(IsChars(t1) & IsChars(t2))
		    & ~CompatibleAsStrings(t1, e2)
		    & ~CompatibleAsStrings(t2, e1)
		    & ~CompatibleAsCharAndString(t1, e2)
		    & ~CompatibleAsCharAndString(t2, e1)
		    & ~CompatibleAsIntAndByte(t1, t2)
		THEN
			err := ErrRelationExprDifferenTypes;
			continue := FALSE
		ELSIF (t1.id IN (Numbers + {IdChar}))
		   OR (t1.id = IdArray) & (t1.type.id = IdChar)
		THEN
			continue := TRUE
		ELSIF t1.id IN {IdRecord, IdArray} THEN
			continue := FALSE;
			err := ErrRelIncompatibleType
		ELSE
			continue := (relation = Equal)
			         OR (relation = Inequal);
			IF ~continue THEN
				err := ErrRelIncompatibleType
			END
		END;
		distance := dist1 - dist2
		RETURN continue
	END CheckType;

	PROCEDURE IsNotProc(e1, e2: Expression; VAR err: INTEGER): BOOLEAN;
		PROCEDURE IsProc(e: Expression): BOOLEAN;
			RETURN (e IS Designator) & (e(Designator).decl IS GeneralProcedure)
		END IsProc;
	BEGIN
		ASSERT(err = ErrNo);
		IF (e1.type.id IN ProcTypes)
		 & (IsProc(e1) OR IsProc(e2))
		THEN
			err := ErrIsEqualProc
		END
		RETURN err = ErrNo
	END IsNotProc;

	PROCEDURE IsEqualChars(v1, v2: ExprInteger): BOOLEAN;
	BEGIN
		ASSERT(Limits.InCharRange(v1.int));
		ASSERT(Limits.InCharRange(v2.int))

		RETURN v1.int = v2.int
	END IsEqualChars;

	PROCEDURE IsEqualStrings(v1, v2: ExprInteger): BOOLEAN;
	VAR ret: BOOLEAN;
	BEGIN
		ret := (v1.int = v2.int);
		IF ret & (v1.int = -1) THEN
			ret := Strings.Compare(v1(ExprString).string, v2(ExprString).string) = 0
		END
		RETURN ret
	END IsEqualStrings;
BEGIN
	ASSERT(relation IN AcceptableRelations);

	NEW(e); ExprInit(e, IdRelation, TypeGet(IdBoolean));
	e.exprs[0] := expr1;
	e.exprs[1] := expr2;
	e.relation := relation;
	PropTouch(e, Prop(expr1) + Prop(expr2));
	err := ErrNo;
	IF (expr1 # NIL) & (expr2 # NIL)
	 & CheckType(expr1.type, expr2.type, e.exprs[0], e.exprs[1], relation, e.distance, err)
	 & (IsAllowCmpProc OR IsNotProc(expr1, expr2, err))
	 & (expr1.value # NIL) & (expr2.value # NIL) & (relation # Is)
	THEN
		v1 := e.exprs[0].value;
		v2 := e.exprs[1].value;
		CASE relation OF
		  Equal:
			CASE expr1.type.id OF
			  IdInteger  : res := v1(ExprInteger).int = v2(ExprInteger).int
			| IdChar     : res := IsEqualStrings(v1(ExprInteger), v2(ExprInteger))
			| IdBoolean  : res := v1(ExprBoolean).bool = v2(ExprBoolean).bool
			| IdReal     :
				(* TODO правильная обработка *)
				res := (v1(ExprReal).real = v2(ExprReal).real) OR TRUE
			| IdSet, IdLongSet
			             : res := LongSet.Equal(v1(ExprSetValue).set, v2(ExprSetValue).set)
			| IdPointer  : ASSERT(v1 = v2); res := TRUE
			| IdArray    :
				res := IsEqualStrings(v1(ExprInteger), v2(ExprInteger))
			| IdProcType, IdFuncType
			             : (* TODO *) res := FALSE
			END
		| Inequal:
			CASE expr1.type.id OF
			  IdInteger         : res := v1(ExprInteger).int # v2(ExprInteger).int
			| IdChar            : res := ~IsEqualChars(v1(ExprInteger), v2(ExprInteger))
			| IdBoolean         : res := v1(ExprBoolean).bool # v2(ExprBoolean).bool
			| IdReal            : res := v1(ExprReal).real # v2(ExprReal).real
			| IdSet, IdLongSet  : res := ~LongSet.Equal(v1(ExprSetValue).set, v2(ExprSetValue).set)
			| IdPointer         : ASSERT(v1 = v2); res := FALSE
			| IdArray           : res := ~IsEqualStrings(v1(ExprInteger), v2(ExprInteger))
			| IdProcType, IdFuncType
			                    : (* TODO *) res := FALSE
			END
		| Less:
			CASE expr1.type.id OF
			  IdInteger, IdChar : res := v1(ExprInteger).int < v2(ExprInteger).int
			| IdReal            : res := v1(ExprReal).real < v2(ExprReal).real
			| IdArray           : (* TODO *) res := FALSE
			END
		| LessEqual:
			CASE expr1.type.id OF
			  IdInteger, IdChar : res := v1(ExprInteger).int <= v2(ExprInteger).int
			| IdReal            : res := v1(ExprReal).real <= v2(ExprReal).real
			| IdArray           : (* TODO *) res := FALSE
			END
		| Greater:
			CASE expr1.type.id OF
			  IdInteger, IdChar : res := v1(ExprInteger).int > v2(ExprInteger).int
			| IdReal            : res := v1(ExprReal).real > v2(ExprReal).real
			| IdArray           : (* TODO *) res := FALSE
			END
		| GreaterEqual:
			CASE expr1.type.id OF
			  IdInteger, IdChar : res := v1(ExprInteger).int >= v2(ExprInteger).int
			| IdReal            : res := v1(ExprReal).real >= v2(ExprReal).real
			| IdArray           : (* TODO *) res := FALSE
			END
		| In:
			res := LongSet.In(v1(ExprInteger).int, v2(ExprSetValue).set)
		END;
		IF expr1.type.id # IdReal THEN
			e.value := ExprBooleanGet(res);

			IF expr1.id = IdString THEN
				StringUsedWithExpr(expr1(ExprString), expr2)
			END;
			IF expr2.id = IdString THEN
				StringUsedWithExpr(expr2(ExprString), expr1)
			END
		END
	END
	RETURN err
END ExprRelationNew;

PROCEDURE LexToSign(sign: INTEGER): INTEGER;
VAR s: INTEGER;
BEGIN
	IF sign IN {NoSign, Plus} THEN
		s := +1
	ELSE ASSERT(sign = Minus);
		s := -1
	END
	RETURN s
END LexToSign;

PROCEDURE ExprSumCreate(VAR e: ExprSum; add: INTEGER; sum, term: Expression);
VAR t: Type;
BEGIN
	NEW(e);
	IF (sum # NIL) & (sum.type # NIL)
	 & (sum.type.id IN Numbers)
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
	e.term := term;
	PropTouch(e, Prop(sum) + Prop(term))
END ExprSumCreate;

PROCEDURE ExprSumNew*(VAR e: ExprSum; add: INTEGER; term: Expression): INTEGER;
VAR err: INTEGER;
BEGIN
	ASSERT(add IN {NoSign, Plus, Minus});

	ExprSumCreate(e, add, NIL, term);
	err := ErrNo;
	IF e.type # NIL THEN
		IF ~(e.type.id IN (Numbers + Sets)) & (add # NoSign) THEN
			IF e.type.id # IdBoolean THEN
				err := ErrNotNumberAndNotSetInAdd
			ELSE
				err := ErrSignForBool
			END
		ELSIF (term.value # NIL) & (e.type.id IN (Numbers + Sets)) THEN
			CASE e.type.id OF
			  IdInteger, IdLongInt:
				e.value := ExprIntegerNew(
					term.value(ExprInteger).int * LexToSign(add)
				)
			| IdReal, IdReal32:
				(* из-за отсутствия точности в вычислениях
				e.value := ExprRealNewByValue(
					term.value(ExprReal).real * FLT(LexToSign(add))
				)
				*)
				e.value := NIL
			| IdSet, IdLongSet:
				e.value := ExprSetByValue(term.value(ExprSetValue).set);
				IF add = Minus THEN
					LongSet.Not(e.value(ExprSetValue).set)
				END
			| IdBoolean:
				e.value := ExprBooleanGet(term.value(ExprBoolean).bool)
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
		ELSIF add = Or THEN
			continue := e1.type.id = IdBoolean;
			IF ~continue THEN
				err := ErrNotBoolInLogicExpr
			END
		ELSE
			continue := e1.type.id IN (Numbers + Sets);
			IF ~continue THEN
				err := ErrNotNumberAndNotSetInAdd
			END
		END
		RETURN continue
	END CheckType;
BEGIN
	ASSERT(add IN {Plus, Minus, Or});

	ExprSumCreate(e, add, fullSum, term);
	err := ErrNo;
	IF (fullSum # NIL) & (term # NIL)
	 & CheckType(fullSum, term, add, err)
	 & (fullSum.value # NIL) & (term.value # NIL)
	THEN
		IF add = Or THEN
			IF term.value(ExprBoolean).bool THEN
				fullSum.value := term.value
			END
		ELSE
			CASE term.type.id OF
			  IdInteger:
				IF Arithmetic.Add(fullSum.value(ExprInteger).int,
						fullSum.value(ExprInteger).int,
						term.value(ExprInteger).int * LexToSign(add))
				THEN
					;
				ELSIF add = Minus THEN
					err := ErrConstSubOverflow
				ELSE
					err := ErrConstAddOverflow
				END
			| IdReal:
				(* из-за отсутствия точности в вычислениях
				fullSum.value(ExprReal).real :=
				    fullSum.value(ExprReal).real
				  + term.value(ExprReal).real * FLT(LexToSign(add))
				*)
			| IdSet:
				IF add = Plus THEN
					LongSet.Union(fullSum.value(ExprSetValue).set, term.value(ExprSetValue).set)
				ELSE ASSERT(add = Minus);
					LongSet.Diff(fullSum.value(ExprSetValue).set, term.value(ExprSetValue).set)
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

	PROCEDURE CheckType(e1, e2: Expression; mult: INTEGER; VAR err: INTEGER): BOOLEAN;
	VAR continue: BOOLEAN;
	BEGIN
		IF (e1.type = NIL) OR (e2.type = NIL) THEN
			continue := FALSE
		ELSIF (e1.type.id # e2.type.id)
		    & ~CompatibleAsIntAndByte(e1.type, e2.type)
		THEN
			continue := FALSE;
			IF mult = And THEN
				err := ErrNotBoolInLogicExpr
			ELSIF mult = Mult THEN
				err := ErrMultExprDifferentTypes
			ELSE
				err := ErrDivExprDifferentTypes
			END
		ELSIF mult = And THEN
			continue := e1.type.id = IdBoolean;
			IF ~continue THEN
				err := ErrNotBoolInLogicExpr
			END
		ELSIF ~(e1.type.id IN (Numbers + Sets)) THEN
			continue := FALSE;
			err := ErrNotNumberAndNotSetInMult
		ELSIF (mult = Div) OR (mult = Mod) THEN
			continue := e1.type.id = IdInteger;
			IF ~continue THEN
				err := ErrNotIntInDivOrMod
			END
		ELSIF (mult = Rdiv) & (e1.type.id = IdInteger) THEN
			continue := FALSE;
			err := ErrNotRealTypeForRealDiv
		ELSE
			continue := TRUE
		END
		RETURN continue
	END CheckType;

	PROCEDURE Int(res: Expression; mult: INTEGER; b: Expression; VAR err: INTEGER);
	VAR i, i1, i2: INTEGER;
	    val: ExprInteger;
	BEGIN
		i1 := res.value(ExprInteger).int;
		i2 := b.value(ExprInteger).int;
		IF mult = Mult THEN
			IF ~Arithmetic.Mul(i, i1, i2) THEN
				err := ErrConstMultOverflow
			END
		ELSIF i2 = 0 THEN
			err := ErrComDivByZero
		ELSIF i2 < 0 THEN
			err := ErrNegativeDivisor
		ELSIF mult = Div THEN
			i := i1 DIV i2
		ELSE ASSERT(mult = Mod);
			i := i1 MOD i2
		END;
		IF err = ErrNo THEN
			val := ExprIntegerNew(i);
			IF (mult IN {Div, Mod}) & (i1 < 0) THEN
				val.properties := {ExprIntNegativeDividentTouch}
			ELSE
				val.properties := {ExprIntNegativeDividentTouch}
				                * (res.value.properties + b.value.properties)
			END;
			res.value := val;
			res.properties := res.properties + val.properties
		ELSE
			res.value := NIL
		END
	END Int;

	PROCEDURE Rl(res: Expression; mult: INTEGER; b: Expression);
	VAR r, r1, r2: REAL;
	BEGIN
		r1 := res.value(ExprReal).real;
		r2 := b.value(ExprReal).real;
		IF mult = Mult THEN
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
	VAR s, s1, s2: LongSet.Type;
	BEGIN
		s1 := res.value(ExprSetValue).set;
		s2 := b.value(ExprSetValue).set;
		IF mult = Mult THEN
			s[0] := s1[0] * s2[0];
			s[1] := s1[1] * s2[1]
		ELSE
			s[0] := s1[0] / s2[0];
			s[1] := s1[1] / s2[1]
		END;
		IF res.value = NIL THEN
			res.value := ExprSetByValue(s)
		ELSE
			res.value(ExprSetValue).set := s
		END
	END St;

	PROCEDURE CheckDivisor(VAR err: INTEGER; d: INTEGER);
	BEGIN
		IF d = 0 THEN
			err := ErrComDivByZero
		ELSIF d < 0 THEN
			err := ErrNegativeDivisor
		END
	END CheckDivisor;
BEGIN
	err := ErrNo;
	IF CheckType(res, b, mult, err) & (res.value # NIL) & (b.value # NIL) THEN
		CASE res.type.id OF
		  IdInteger:
			Int(res, mult, b, err)
		| IdReal:
			(* из-за отсутствия точности в вычислениях *)
			IF FALSE THEN
				Rl(res, mult, b)
			END;
			res.value := NIL
		| IdBoolean:
			IF res.value(ExprBoolean).bool & ~b.value(ExprBoolean).bool THEN
				res.value := b.value
			END
		| IdSet:
			St(res, mult, b)
		END
	ELSE
		res.value := NIL;
		IF ((mult - Div) IN {0, 1})
		 & (b.value # NIL) & (b.value.type.id = IdInteger)
		THEN
			CheckDivisor(err, b.value(ExprInteger).int)
		END
	END
	RETURN err
END MultCalc;

PROCEDURE ExprTermGeneral(VAR e: ExprTerm; result: Expression; factor: Factor;
                          mult: INTEGER; factorOrTerm: Expression): INTEGER;
VAR t: Type;
    val: Factor;
    err: INTEGER;
BEGIN
	ASSERT((MultFirst <= mult) & (mult <= MultLast));

	ASSERT((factorOrTerm.id = IdError)
	    OR (factorOrTerm IS Factor)
	    OR (factorOrTerm IS ExprTerm));

	IF factor # NIL THEN
		t := factor.type;
		val := factor.value;
		IF (t # NIL) & (t.id = IdByte) THEN
			t := TypeGet(IdInteger)
		END;
	ELSE
		t := NIL;
		val := NIL
	END;

	NEW(e); ExprInit(e, IdTerm, t (* TODO *));
	IF result = NIL THEN
		result := e;
		IF e.type.id # IdReal THEN
			e.value := val
		END
	END;
	PropTouch(e, Prop(factor) + Prop(factorOrTerm));
	e.factor := factor;
	e.mult := mult;
	e.expr := factorOrTerm;
	e.factor := factor;

	IF factorOrTerm.id # IdError THEN
		err := MultCalc(result, mult, factorOrTerm)
	ELSE
		err := ErrNo
	END
	RETURN err
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

PROCEDURE ExprTypeNew*(VAR e: ExprType; t: Type): INTEGER;
BEGIN
	NEW(e); ExprInit(e, IdExprType, t)
	RETURN ErrNo
END ExprTypeNew;

PROCEDURE ExprCallCreate(VAR e: ExprCall; des: Designator; func: BOOLEAN): INTEGER;
VAR err: INTEGER;
	t: Type;
	pt: ProcType;
BEGIN
	t := NIL;
	err := ErrNo;
	IF des # NIL THEN
		IF des.decl.id = IdError THEN
			pt := ProcTypeNew(FALSE, IdProcType);
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
	IF (t = NIL) & func THEN
		t := TypeErrorNew()
	END;
	NEW(e); ExprInit(e, IdCall, t);
	e.designator := des;
	e.params := NIL
	RETURN err
END ExprCallCreate;

PROCEDURE ExprCallNew*(VAR e: ExprCall; des: Designator): INTEGER;
	RETURN ExprCallCreate(e, des, TRUE)
END ExprCallNew;

PROCEDURE IsChangeable*(des: Designator): BOOLEAN;
VAR v: Var;
    sel: Selector;
    tid: INTEGER;
    able: BOOLEAN;
BEGIN
	v := des.decl(Var);
	IF IsGlobal(v) THEN
		able := ~v.module.m.fixed
	ELSE
		able := ~(v IS FormalParam)
		     OR (ParamOut IN v(FormalParam).access)
		     OR ~(v.type.id IN {IdArray, IdRecord})
	END;
	IF ~able THEN
		tid := des.decl.type.id;
		sel := des.sel;
		WHILE (sel # NIL) & (tid # IdPointer) DO
			tid := sel.type.id;
			sel := sel.next
		END;
		able := sel # NIL
	END
	RETURN able
END IsChangeable;

PROCEDURE IsVar*(e: Expression): BOOLEAN;
	RETURN (e IS Designator) & (e(Designator).decl IS Var)
END IsVar;

PROCEDURE IsFormalParam*(e: Expression): BOOLEAN;
RETURN (e IS Designator)
     & (e(Designator).sel = NIL)
     & (e(Designator).decl IS FormalParam)
END IsFormalParam;

PROCEDURE IsConstOrLocalVar*(e: Expression): BOOLEAN;
RETURN (e.value # NIL)
    OR   (e IS Designator)
       & (e(Designator).sel = NIL)
       & ~IsGlobal(e(Designator).decl)
END IsConstOrLocalVar;

PROCEDURE ProcedureAdd*(ds: Declarations; VAR p: Procedure; typeId: INTEGER;
                        VAR buf: ARRAY OF CHAR; begin, end: INTEGER): INTEGER;
VAR err: INTEGER;
BEGIN
	err := CheckNameDuplicate(ds, buf, begin, end);
	NEW(p); NodeInit(p^, IdProc);
	DeclarationsConnect(p, ds, buf, begin, end);
	p.header := ProcTypeNew(FALSE, typeId);
	p.return := NIL;
	p.usedAsValue := FALSE;
	IF ds.up = NIL THEN
		p.deep := 0
	ELSE
		p.deep := ds(Procedure).deep + 1;
		IF (err = ErrNo) & (TranLim.DeepProcedures <= p.deep) THEN
			err := ErrProcNestedTooDeep
		END
	END;
	IF ds.procedures = NIL THEN
		ds.procedures := p
	END
	RETURN err
END ProcedureAdd;

PROCEDURE ProcedureSetReturn*(p: Procedure; e: Expression): INTEGER;
VAR err, distance: INTEGER;
BEGIN
	ASSERT(p.return = NIL);
	err := ErrNo;
	IF p.header.type = NIL THEN
		err := ErrProcHasNoReturn
	ELSIF e # NIL THEN
		p.return := e;
		IF ~CompatibleTypes(distance, p.header.type, e.type, FALSE)
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
		END;
		IF (err = ErrNo)
		 & (e.value # NIL)
		 & (p.return.type.id = IdSet)
		 & (e.value(ExprSetValue).set[1] # {})
		THEN
			err := ErrSetFromLongSet
		END;
		IF err = ErrNo THEN
			err := CheckUnusedDeclarations(p)
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
		err := CheckUnusedDeclarations(p)
	END
	RETURN err
END ProcedureEnd;

PROCEDURE IsExprChar*(e: Expression): BOOLEAN;
BEGIN
	RETURN (e IS ExprString) & e(ExprString).asChar
END IsExprChar;

PROCEDURE CallParamNew*(call: ExprCall; VAR lastParam: Parameter; e: Expression;
                        VAR currentFormalParam: FormalParam): INTEGER;
VAR err, distance: INTEGER; fp: FormalParam; str: ExprString;

	PROCEDURE TypeVariation(call: ExprCall; e: Expression; fp: FormalParam): BOOLEAN;
	VAR comp: BOOLEAN; id: INTEGER; tp: Type;
	BEGIN
		tp := e.type;
		comp := (call.designator.decl IS PredefinedProcedure) OR (tp.id = IdError);
		IF comp
		& ~((fp.type.id = IdBasic) & ((tp.id IN BasicTypes) OR IsExprChar(e)))
		THEN
			id := call.designator.decl.id;
			IF id = SpecIdent.New THEN
				comp := tp.id = IdPointer
			ELSIF id = SpecIdent.Abs THEN
				comp := tp.id IN Numbers;
				call.type := tp
			ELSIF id = SpecIdent.Len THEN
				comp := tp.id = IdArray
			ELSIF id = SpecIdent.Ord THEN
				comp := tp.id IN (Sets + {IdChar, IdBoolean})
			ELSE
				comp := id = SpecIdent.Adr
			END
		END
		RETURN comp
	END TypeVariation;

	PROCEDURE ParamsVariation(call: ExprCall; e: Expression; VAR err: INTEGER);
	VAR id: INTEGER;
	BEGIN
		id := call.designator.decl.id;
		IF (id # IdError) & (e.type.id # IdError) THEN
			IF (id # SpecIdent.Inc) & (id # SpecIdent.Dec)
			OR (call.params.next # NIL)
			THEN
				err := ErrCallExcessParam
			ELSIF e.type.id # IdInteger THEN
				err := ErrCallIncompatibleParamType
			END
		END
	END ParamsVariation;

	PROCEDURE CheckNeedTag(fp: FormalParam; e: Expression);
	BEGIN
		IF (fp.type.id = IdRecord) & IsFormalParam(e) THEN
			ExchangeParamsNeedTag(fp, e(Designator).decl(FormalParam))
		END
	END CheckNeedTag;
BEGIN
	err := ErrNo;
	fp := currentFormalParam;
	IF fp # NIL THEN
		IF ~CompatibleTypes(distance, fp.type, e.type, TRUE)
		 & ~CompatibleAsCharAndString(currentFormalParam.type, e)
		 &     ((ParamOut IN fp.access)
		    OR ~CompatibleAsIntAndByte(fp.type, e.type)
		       )
		 & ~TypeVariation(call, e, fp)
		THEN
			err := ErrCallIncompatibleParamType
		ELSIF ParamOut IN fp.access THEN
			IF ~(IsVar(e) & IsChangeable(e(Designator))) THEN
				err := ErrCallExpectVarParam
			ELSIF (e.type # NIL) & (e.type.id = IdPointer)
			    & (e.type # fp.type)
			    & (fp.type # NIL)
			    & (fp.type.type # NIL)
			    & (e.type.type # NIL)
			THEN
				err := ErrCallVarPointerTypeNotSame
			END
		ELSIF (fp.type.id = IdByte) & (e.type.id = IdInteger)
		    & (e.value # NIL) & ~Limits.InByteRange(e.value(ExprInteger).int)
		THEN
			err := ErrValueOutOfRangeOfByte
		ELSIF (call.designator.decl.id = SpecIdent.Adr) & ~IsVar(e) THEN
			err := ErrCallExpectAddressableParam
		END;
		IF (fp.next # NIL)
		 & (fp.next IS FormalParam)
		THEN
			currentFormalParam := fp.next(FormalParam)
		ELSE
			currentFormalParam := NIL
		END;
		IF (err = ErrNo) & (fp.type.id IN ProcTypes)
		 & (e # NIL) & (e IS Designator) & (e(Designator).decl.id = IdProc)
		THEN
			e(Designator).decl(Procedure).usedAsValue := TRUE
		END;
		IF (e = NIL) OR (err # ErrNo) THEN
			;
		ELSIF e.id = IdString THEN
			StringUsedWithType(e(ExprString), fp.type)
		ELSIF (e.value # NIL) & (e.value.id = IdString) THEN
			str := ExprStringCopy(e.value(ExprString));
			StringUsedWithType(str, fp.type);
			IF str.usedAs # e.value(ExprString).usedAs THEN
				e.value := str
			END
		END;
		IF (err = ErrNo)
		 & (e # NIL)
		 & (e.value # NIL)
		 & (fp.type.id = IdSet)
		 & (e.value(ExprSetValue).set[1] # {})
		THEN
			err := ErrSetFromLongSet
		END;
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
	IF (err = ErrNo) & (fp # NIL) THEN
		CheckNeedTag(fp, e)
	END;
	NodeInit(lastParam^, NoId);
	lastParam.expr := e;
	lastParam.distance := distance;
	lastParam.next := NIL
	RETURN err
END CallParamNew;

PROCEDURE CallParamInsert*(par: Parameter; VAR fp: FormalParam; expr: Expression;
                           VAR np: Parameter);
BEGIN
	NEW(np); NodeInit(np^, NoId);
	np.distance := 0;
	np.expr := expr;
	np.next := par.next;
	par.next := np
END CallParamInsert;

PROCEDURE CallParamsEnd*(call: ExprCall; currentFormalParam: FormalParam;
                         ds: Declarations): INTEGER;
VAR err: INTEGER;

	PROCEDURE CalcPredefined(call: ExprCall; v: Factor; VAR err: INTEGER);
	BEGIN
		CASE call.designator.decl.id OF
		  SpecIdent.Abs:
			IF v.type.id = IdReal THEN
				call.value := NIL
				(* Из-за -0.0 NaN
				IF v(ExprReal).real < 0.0 THEN
					call.value := ExprRealNewByValue(-v(ExprReal).real)
				ELSE
					call.value := v
				END
				*)
			ELSE ASSERT(v.type.id = IdInteger);
				call.value := ExprIntegerNew(ABS(v(ExprInteger).int))
			END
		| SpecIdent.Odd:
			call.value := ExprBooleanGet(ODD(v(ExprInteger).int))
		| SpecIdent.Lsl:
			IF call.params.next.expr.value # NIL THEN
				call.value := ExprIntegerNew(LSL(
					v(ExprInteger).int,
					call.params.next.expr.value(ExprInteger).int
				))
			END
		| SpecIdent.Asr:
			IF call.params.next.expr.value # NIL THEN
				call.value := ExprIntegerNew(ASR(
					v(ExprInteger).int,
					call.params.next.expr.value(ExprInteger).int
				))
			END
		| SpecIdent.Ror:
			IF call.params.next.expr.value # NIL THEN
				call.value := ExprIntegerNew(ROR(
					v(ExprInteger).int,
					call.params.next.expr.value(ExprInteger).int
				))
			END
		| SpecIdent.Floor:
			IF FALSE THEN
				call.value := ExprIntegerNew(FLOOR(v(ExprReal).real))
			END
		| SpecIdent.Flt:
			call.value := ExprRealNewByValue(FLT(v(ExprInteger).int))
		| SpecIdent.Ord:
			IF v.type.id = IdChar THEN
				call.value := v
			ELSIF v IS ExprString THEN
				IF v(ExprString).int > -1 THEN
					call.value := ExprIntegerNew(v(ExprString).int)
				END
			ELSIF v.type.id = IdBoolean THEN
				call.value := ExprIntegerNew(ORD(v(ExprBoolean).bool))
			ELSIF v.type.id IN Sets THEN
				IF LongSet.ConvertableToInt(v(ExprSetValue).set) THEN
					call.value := ExprIntegerNew(LongSet.Ord(v(ExprSetValue).set))
				ELSE
					err := ErrSetElemMaxNotConvertToInt
				END
			ELSIF v.type.id # IdError THEN
				Log.Str("Неправильный id типа = ");
				Log.Int(v.type.id); Log.Ln;
				Log.Int(v.id); Log.Ln
			END
		| SpecIdent.Chr:
			IF ~Limits.InCharRange(v(ExprInteger).int) THEN
				err := ErrValueOutOfRangeOfChar
			END;
			call.value := v
		| SpecIdent.Size, SpecIdent.Bit, SpecIdent.Adr:
			;
		END
	END CalcPredefined;
BEGIN
	err := ErrNo;
	IF currentFormalParam # NIL THEN
		err := ErrCallParamsNotEnough
	ELSIF call.designator.decl.id = SpecIdent.Len THEN
		(* TODO заменить на общую проверку корректности выбора параметра *)
		IF (call.params.expr.type IS Array)
		 & (call.params.expr.type(Array).count # NIL)
		THEN
			call.value := call.params.expr.type(Array).count.value
		END
	ELSIF call.designator.decl.id = SpecIdent.Assert THEN
		IF (call.params.expr.value # NIL)
		 & (call.params.expr.value IS ExprBoolean)
		 & ~call.params.expr.value(ExprBoolean).bool
		THEN
			IF call.params.expr = ExprBooleanGet(FALSE) THEN
				TurnFail(ds)
			ELSE
				err := ErrAssertConstFalse
			END
		END
	ELSIF (call.designator.decl IS PredefinedProcedure)
	 (* TODO заменить на общую проверку корректности выбора параметра *)
	    & (call.designator.decl.type.type # NIL)
	    & (call.params.expr.value # NIL)
	THEN
		CalcPredefined(call, call.params.expr.value, err)
	END
	RETURN err
END CallParamsEnd;

PROCEDURE StatInit(s: Statement; e: Expression);
BEGIN
	NodeInit(s^, NoId);
	s.expr := e;
	s.next := NIL
END StatInit;

PROCEDURE CallNew*(VAR c: Call; des: Designator): INTEGER;
VAR err: INTEGER;
	e: ExprCall;
BEGIN
	err := ExprCallCreate(e, des, FALSE);
	IF err = ErrNo THEN
		err := DesignatorUsed(des, {})
	END;
	NEW(c); StatInit(c, e)
	RETURN err
END CallNew;

PROCEDURE CallBeginGet*(VAR call: Call; m: Module; acceptParams: BOOLEAN;
                        name: ARRAY OF CHAR; begin, end: INTEGER): INTEGER;
VAR d: Declaration;
	des: Designator;
	err: INTEGER;
BEGIN
	d := SearchName(m.start, name, begin, end);
	IF begin = end THEN
		ASSERT(d = NIL);
		err := ErrExpectProcNameWithoutParams
	ELSIF d = NIL THEN
		err := ErrDeclarationNotFound
	ELSIF ~d.mark THEN
		err := ErrDeclarationIsPrivate
	ELSIF ~(d IS Procedure) THEN
		err := ErrDeclarationNotProc
	ELSIF d(Procedure).header.type # NIL THEN
		err := ErrProcNotCommandHaveReturn
	ELSIF d(Procedure).header.params # NIL THEN
		err := ErrProcNotCommandHaveParams
	ELSE
		err := DesignatorNew(des, d);
		IF err = ErrNo THEN
			err := CallNew(call, des);
		END
	END
	RETURN err
END CallBeginGet;

PROCEDURE CommandGet*(VAR call: Call; m: Module;
                      name: ARRAY OF CHAR; begin, end: INTEGER): INTEGER;
BEGIN
	RETURN CallBeginGet(call, m, FALSE, name, begin, end)
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

	var.state.inited := { InitedValue, Used };

	var.used := TRUE;
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
	case.else := NIL;
	IF (expr.type # NIL) & ~(expr.type.id IN {IdInteger, IdChar}) THEN
		err := ErrCaseExprNotIntOrChar
	ELSE
		err := ErrNo
	END
	RETURN err
END CaseNew;

PROCEDURE CaseElseSet*(case: Case; else: Statement): INTEGER;
VAR err: INTEGER;
BEGIN
	IF case.else # NIL THEN
		err := ErrCaseElseAlreadyExist
	ELSE
		case.else := else;
		err := ErrNo
	END
	RETURN err
END CaseElseSet;

PROCEDURE CaseRangeSearch*(case: Case; int: INTEGER): INTEGER;
VAR e: CaseElement;
BEGIN
	ASSERT(FALSE); (* TODO *)
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

	NEW(label); NodeInit(label^, id);
	label.qual := NIL;
	label.value := value;
	label.right := NIL;
	label.next := NIL
	RETURN ErrNo
END CaseLabelNew;

PROCEDURE CaseLabelQualNew*(VAR label: CaseLabel; decl: Declaration): INTEGER;
VAR err, i: INTEGER;
BEGIN
	label := NIL;
	decl.used := TRUE;
	IF decl.id = IdError THEN
		err := ErrNo
	ELSIF ~(decl IS Const) THEN
		err := ErrCaseLabelNotConst
	ELSIF ~(decl(Const).expr.type.id IN {IdInteger, IdChar})
	    & ~((decl(Const).expr IS ExprString)
	    & (decl(Const).expr(ExprString).int > -1)
	       )
	THEN
		err := ErrCaseLabelNotIntOrChar
	ELSIF decl(Const).expr.type.id = IdInteger THEN
		err := CaseLabelNew(label, IdInteger, decl(Const).expr.value(ExprInteger).int)
	ELSE
		i := decl(Const).expr.value(ExprInteger).int;
		IF i < 0 THEN
			(* TODO *) ASSERT(FALSE);
			i := ORD(decl(Const).expr.value(ExprString).string.block.s[0])
		END;
		err := CaseLabelNew(label, IdChar, i)
	END;
	IF label = NIL THEN
		err := err + CaseLabelNew(label, IdInteger, 0) * 0
	ELSE
		label.qual := decl
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
	IF right = NIL THEN
		;
	ELSIF left.id # right.id THEN
		err := ErrCaseRangeLabelsTypeMismatch
	ELSIF left.value >= right.value THEN
		err := ErrCaseLabelLeftNotLessRight
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
	END
	RETURN cross
END IsRangesCross;

PROCEDURE IsListCrossRange(list, range: CaseLabel): BOOLEAN;
BEGIN
	WHILE (list # NIL) & ~IsRangesCross(list, range) DO
		list := list.next
	END
	RETURN list # NIL
END IsListCrossRange;

PROCEDURE IsElementsCrossRange(elem: CaseElement; range: CaseLabel): BOOLEAN;
BEGIN
	WHILE (elem # NIL) & ~IsListCrossRange(elem.labels, range) DO
		elem := elem.next
	END
	RETURN elem # NIL
END IsElementsCrossRange;

PROCEDURE CaseRangeListAdd*(case: Case; first, new: CaseLabel): INTEGER;
VAR err: INTEGER;
BEGIN
	ASSERT(new.next = NIL);
	ASSERT(case.else = NIL);
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
	NEW(elem); NodeInit(elem^, NoId);
	elem.next := NIL;
	elem.labels := labels;
	elem.stats := NIL
	RETURN elem
END CaseElementNew;

PROCEDURE CaseElementAdd*(case: Case; elem: CaseElement): INTEGER;
VAR err: INTEGER;
	last: CaseElement;
BEGIN
	ASSERT(case.else = NIL);
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

PROCEDURE TypeInclAssigned(t: Type);
VAR v: Declaration;
    rec: Record;
BEGIN
	INCL(t.properties, TypeAssigned);
	IF t.id = IdRecord THEN
		rec := t(Record);
		IF rec.base # NIL THEN
			TypeInclAssigned(rec.base)
		END;
		v := rec.vars;
		WHILE v # NIL DO
			IF v.type.id = IdRecord THEN
				TypeInclAssigned(v.type)
			END;
			v := v.next
		END
	END
END TypeInclAssigned;

PROCEDURE AssignNew*(VAR a: Assign; inLoops: BOOLEAN; des: Designator;
                     expr: Expression): INTEGER;
VAR err: INTEGER;
    var: Var;
BEGIN
	NEW(a); StatInit(a, expr);
	a.designator := des;
	err := ErrNo;
	IF des # NIL THEN
		IF (des.decl IS Var) & IsChangeable(des) THEN
			var := des.decl(Var);
			TypeInclAssigned(des.type);
			IF var.type.id = IdPointer THEN
				IF (des.sel # NIL)
				 & (~(InitedValue IN var.state.inited)
				 OR ~var.state.inCondition
				  & ({} # (var.state.inited * {InitedNo, InitedNil}))
				   ) & ~inLoops
				THEN
					err := ErrVarUninitialized (* TODO *)
				END;
				var.used := TRUE
			END;

			var.state.inited := var.state.inited - {InitedNo, InitedValue, InitedCheck, InitedNil};
			IF (des.sel = NIL)
			 & (~IsGlobal(var) OR (var IS FormalParam))
			 & (expr # NIL) & (expr.value # NIL) & (expr.value = ExprNilGet())
			THEN
				INCL(var.state.inited, InitedNil)
			ELSE
				INCL(var.state.inited, InitedValue)
			END;
			des.inited := var.state.inited
		ELSE
			err := ErrAssignExpectVarParam
		END;

		IF (err = ErrNo) & (expr # NIL)
		 & ~CompatibleTypes(a.distance, des.type, expr.type, FALSE)
		 & ~CompatibleAsCharAndString(des.type, expr)
		 & ~CompatibleAsStrings(des.type, expr)
		THEN
			IF ~CompatibleAsIntAndByte(des.type, expr.type) THEN
				Log.Str("ErrAssignIncompatibleType because of " );
				Log.Int(des.type.id); Log.Str(" "); Log.Int(expr.type.id);
				Log.Ln;
				err := ErrAssignIncompatibleType
			ELSIF (des.type.id = IdByte)
			    & (expr.value # NIL)
			    & ~Limits.InByteRange(expr.value(ExprInteger).int)
			THEN
				err := ErrValueOutOfRangeOfByte
			END
		END;

		IF ~((err = ErrNo) & (expr.value # NIL)) THEN
			;
		ELSIF expr.value IS ExprString THEN
			IF (des.type.id = IdArray) & (des.type(Array).count # NIL)
			 & (   des.type(Array).count.value(ExprInteger).int
			     < expr.value.type(Array).count.value(ExprInteger).int)
			THEN
				err := ErrAssignStringToNotEnoughArray
			END
		ELSIF expr.value.type.id = IdSet THEN
			IF (expr.value(ExprSetValue).set[1] # {})
			 & (des.type.id = IdSet)
			THEN
				err := ErrSetFromLongSet
			END
		END;

		IF (des.type.id IN ProcTypes) & (err = ErrNo)
		 & (expr # nil) & (expr(Designator).decl.id = IdProc)
		THEN
			expr(Designator).decl(Procedure).usedAsValue := TRUE
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

PROCEDURE StatementAdd*(VAR stats, nearLast: Statement; add: Statement);
VAR l: Statement;
BEGIN
	ASSERT((add = NIL) OR (add.next = NIL));
	ASSERT((stats # NIL) OR (nearLast = NIL));

	(* Если не пустой оператор *)
	IF add # NIL THEN
		l := nearLast;
		IF l = NIL THEN
			l := stats;
			IF l = NIL THEN
				stats := add
			END
		END;
		WHILE l.next # NIL DO
			l := l.next
		END;
		l.next := add;
		nearLast := add
	END
END StatementAdd;

PROCEDURE StatementReplace*(VAR stats: Statement; orig, repl: Statement);
VAR p: Statement;
BEGIN
	ASSERT(orig # repl);
	ASSERT(repl.next = NIL);

	p := stats;
	IF p = orig THEN
		stats := repl
	ELSE
		WHILE p.next # orig DO
			p := p.next
		END;
		p.next := repl;
		repl.next := orig.next;
	END
END StatementReplace;

PROCEDURE PredefinedProcNew(s, t, procId: INTEGER): ProcType;
VAR td: PredefinedProcedure;
BEGIN
	NEW(td); NodeInit(td^, s); DeclInit(td, NIL);
	predefined[s - SpecIdent.PredefinedFirst] := td;
	td.header := ProcTypeNew(FALSE, procId);
	td.type := td.header;
	IF NoId < t THEN
		td.header.type := TypeGet(t)
	END
	RETURN td.header
END PredefinedProcNew;

PROCEDURE PredefinedDeclarationsInit;
VAR tp: ProcType;
	typeInt, typeReal, typeAny, typeVarAny, typeBasic, typeTypeAny: Type;

	PROCEDURE SpecTypeNew(VAR td: Type; t: INTEGER);
	BEGIN
		NEW(td); TypeInit(td, t)
	END SpecTypeNew;

	PROCEDURE TypeNew(s, t: INTEGER);
	VAR td: Type;
	BEGIN
		NEW(td); TypeInit(td, t);

		predefined[s - SpecIdent.PredefinedFirst] := td;
		types[t] := td
	END TypeNew;

	PROCEDURE ProcNew(s, t: INTEGER): ProcType;
		RETURN PredefinedProcNew(s, t, IdProcType)
	END ProcNew;

	PROCEDURE FuncNew(s, t: INTEGER): ProcType;
		RETURN PredefinedProcNew(s, t, IdFuncType)
	END FuncNew;
BEGIN
	TypeNew(SpecIdent.Byte, IdByte);
	TypeNew(SpecIdent.Integer, IdInteger);
	TypeNew(SpecIdent.LongInt, IdLongInt);
	TypeNew(SpecIdent.Char, IdChar);
	TypeNew(SpecIdent.Set, IdSet);
	TypeNew(SpecIdent.LongSet, IdLongSet);
	TypeNew(SpecIdent.Boolean, IdBoolean);
	TypeNew(SpecIdent.Real, IdReal);
	TypeNew(SpecIdent.Real32, IdReal32);
	SpecTypeNew(types[IdPointer], IdPointer);
	SpecTypeNew(typeAny, IdAny);
	SpecTypeNew(typeBasic, IdBasic);
	SpecTypeNew(typeVarAny, IdVarAny);
	SpecTypeNew(typeTypeAny, IdTypeAny);

	typeInt := TypeGet(IdInteger);
	tp := FuncNew(SpecIdent.Abs, IdInteger);
	ParamAddPredefined(tp, typeInt, {ParamIn});

	tp := FuncNew(SpecIdent.Asr, IdInteger);
	ParamAddPredefined(tp, typeInt, {ParamIn});
	ParamAddPredefined(tp, typeInt, {ParamIn});

	tp := ProcNew(SpecIdent.Assert, NoId);
	ParamAddPredefined(tp, TypeGet(IdBoolean), {ParamIn});

	tp := FuncNew(SpecIdent.Chr, IdChar);
	ParamAddPredefined(tp, typeInt, {ParamIn});

	tp := ProcNew(SpecIdent.Dec, NoId);
	ParamAddPredefined(tp, typeInt, {ParamIn, ParamOut});

	tp := ProcNew(SpecIdent.Excl, NoId);
	ParamAddPredefined(tp, TypeGet(IdSet), {ParamIn, ParamOut});
	ParamAddPredefined(tp, typeInt, {ParamIn});

	typeReal := TypeGet(IdReal);
	tp := FuncNew(SpecIdent.Floor, IdInteger);
	ParamAddPredefined(tp, typeReal, {ParamIn});

	tp := FuncNew(SpecIdent.Flt, IdReal);
	ParamAddPredefined(tp, typeInt, {ParamIn});

	tp := ProcNew(SpecIdent.Inc, NoId);
	ParamAddPredefined(tp, typeInt, {ParamIn, ParamOut});

	tp := ProcNew(SpecIdent.Incl, NoId);
	ParamAddPredefined(tp, TypeGet(IdSet), {ParamIn, ParamOut});
	ParamAddPredefined(tp, typeInt, {ParamIn});

	tp := FuncNew(SpecIdent.Len, IdInteger);
	ParamAddPredefined(tp, ArrayGet(typeInt, NIL), {ParamIn});

	tp := FuncNew(SpecIdent.Lsl, IdInteger);
	ParamAddPredefined(tp, typeInt, {ParamIn});
	ParamAddPredefined(tp, typeInt, {ParamIn});

	tp := ProcNew(SpecIdent.New, NoId);
	ParamAddPredefined(tp, TypeGet(IdPointer), {ParamOut});

	tp := FuncNew(SpecIdent.Odd, IdBoolean);
	ParamAddPredefined(tp, typeInt, {ParamIn});

	tp := FuncNew(SpecIdent.Ord, IdInteger);
	ParamAddPredefined(tp, TypeGet(IdChar), {ParamIn});

	tp := ProcNew(SpecIdent.Pack, NoId);
	ParamAddPredefined(tp, typeReal, {ParamIn, ParamOut});
	ParamAddPredefined(tp, typeInt, {ParamIn});

	tp := FuncNew(SpecIdent.Ror, IdInteger);
	ParamAddPredefined(tp, typeInt, {ParamIn});
	ParamAddPredefined(tp, typeInt, {ParamIn});

	tp := ProcNew(SpecIdent.Unpk, NoId);
	ParamAddPredefined(tp, typeReal, {ParamIn, ParamOut});
	ParamAddPredefined(tp, typeInt, {ParamOut});


	system := ModuleNew("SYSTEM");
	tp := ProcNew(SpecIdent.Adr, IdInteger);
	ParamAddPredefined(tp, typeVarAny, {ParamIn});

	tp := ProcNew(SpecIdent.Size, IdInteger);
	ParamAddPredefined(tp, typeTypeAny, {ParamIn});

	tp := ProcNew(SpecIdent.Bit, IdBoolean);
	ParamAddPredefined(tp, typeInt, {ParamIn});
	ParamAddPredefined(tp, typeInt, {ParamIn});

	tp := ProcNew(SpecIdent.Get, NoId);
	ParamAddPredefined(tp, typeInt, {ParamIn});
	ParamAddPredefined(tp, typeBasic, {ParamOut});

	tp := ProcNew(SpecIdent.Put, NoId);
	ParamAddPredefined(tp, typeInt, {ParamIn});
	ParamAddPredefined(tp, typeBasic, {ParamIn});

	tp := ProcNew(SpecIdent.Copy, NoId);
	ParamAddPredefined(tp, typeInt, {ParamIn});
	ParamAddPredefined(tp, typeInt, {ParamIn});
	ParamAddPredefined(tp, typeInt, {ParamIn});

	system.fixed := TRUE;
	system.spec  := TRUE
END PredefinedDeclarationsInit;

PROCEDURE HasError*(m: Module): BOOLEAN;
	RETURN m.errLast # NIL
END HasError;

PROCEDURE ProviderInit*(p: Provider; get: Provide; reg: Register);
BEGIN
	ASSERT(get # NIL);
	ASSERT(reg # NIL);

	V.Init(p^);
	p.get := get;
	p.reg := reg
END ProviderInit;

PROCEDURE UnlinkVar(v: Var);
BEGIN
	v.type := NIL;
	IF v.state # NIL THEN
		v.state.if := NIL;
		v.state.else := NIL;
		v.state.root := NIL;
		v.state := NIL
	END
END UnlinkVar;

PROCEDURE DeclarationsUnlink(ds: Declarations);
VAR p, d: Declaration;
    st, tst: Statement;

	PROCEDURE UnlinkRecord(r: Record);
	VAR d: Declaration; v: Var;
	BEGIN
		d := r.vars;
		r.pointer := NIL;
		r.base := NIL;
		r.vars := NIL;
		WHILE d # NIL DO
			v := d(Var);
			d := d.next;
			v.next := NIL;
			UnlinkVar(v)
		END
	END UnlinkRecord;
BEGIN
	ds.dag.d := NIL;
	ds.dag := NIL;
	ds.module := NIL;
	ds.consts := NIL;
	ds.types := NIL;
	ds.vars := NIL;
	ds.ext := NIL;
	p := ds.procedures;
	ds.procedures := NIL;
	st := ds.stats;
	ds.stats := NIL;

	d := ds.start;
	ds.start := NIL;
	ds.end := NIL;

	WHILE d # NIL DO
		p := d;
		d := d.next;
		CASE p.id OF
		  IdPointer:
			IF p.type # NIL THEN
				UnlinkRecord(p.type(Record))
			END
		| IdRecord:
		| IdRecordForward:
			UnlinkRecord(p(Record));
		| IdArray:
			p(Array).count := NIL
		| IdProcType, IdFuncType, IdImport, IdError: ;
		| IdConst: p(Const).expr := NIL
		| IdProc:
			p(Procedure).header := NIL;
			p(Procedure).return := NIL;
			DeclarationsUnlink(p(Procedure))
		| IdVar:
			UnlinkVar(p(Var))
		END;
		p.type := NIL;
		p.next := NIL;
		p.ext := NIL
	END;

	WHILE st # NIL DO
		tst := st;
		st := st.next;
		tst.expr := NIL;
		tst.next := NIL;
		tst.ext := NIL
	END
END DeclarationsUnlink;

(* Отцепляет лишнее в предопределениях *)
PROCEDURE Unlinks*(m: Module);
VAR fp: FormalParam;
BEGIN
	m.bag.m := NIL;
	m.bag := NIL;

	m.up := NIL;
	DeclarationsUnlink(m);

	WHILE values # NIL DO
		values.value := NIL;
		values := values.nextValue
	END;

	WHILE needTags # NIL DO
		WHILE needTags.first # NIL DO
			fp := needTags.first.link;
			needTags.first.link := NIL;
			needTags.first := fp
		END;

		needTags.last := NIL;

		needTags := needTags.next
	END
END Unlinks;

BEGIN
	ASSERT(~(NoSign IN {Plus, Minus, Or}));

	PredefinedDeclarationsInit;
	booleans[0] := NIL;
	booleans[1] := NIL;
	nil := NIL;
	values := NIL;
	needTags := NIL
END Ast.

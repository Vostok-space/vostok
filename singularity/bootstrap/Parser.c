#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#include <o7c.h>

#include "Parser.h"

#define ErrNo_cnst 0
#define ErrMin_cnst Parser_ErrAstEnd_cnst

o7c_tag_t Parser_Options_tag;
typedef struct Parser {
	struct V_Base _;
	struct Parser_Options settings;
	bool err;
	struct Scanner_Scanner s;
	int l;
	struct Ast_RModule *module;
	struct Ast_RProvider *provider;
} Parser;
static o7c_tag_t Parser_tag;


static void (*declarations)(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) = NULL;
static struct Ast_RType *(*type)(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, int nameBegin, int nameEnd) = NULL;
static struct Ast_RStatement *(*statements)(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) = NULL;
static struct Ast_RExpression *(*expression)(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) = NULL;

static void AddError(struct Parser *p, o7c_tag_t p_tag, int err) {
	Log_Str("AddError ", 10);
	Log_Int(err);
	Log_Str(" at ", 5);
	Log_Int((*p).s.line);
	Log_Str(":", 2);
	Log_Int(o7c_add((*p).s.column, o7c_mul((*p).s.tabs, 3)));
	Log_Ln();
	(*p).err = err > Parser_ErrAstBegin_cnst;
	if ((*p).module != NULL) {
		Ast_AddError((*p).module, err, (*p).s.line, (*p).s.column, (*p).s.tabs);
	}
	(*p).settings.printError(err);
	Out_Ln();
}

static void CheckAst(struct Parser *p, o7c_tag_t p_tag, int err) {
	if (err != Ast_ErrNo_cnst) {
		assert((err < ErrNo_cnst) && (err >= Ast_ErrMin_cnst));
		AddError(&(*p), p_tag, o7c_add(Parser_ErrAstBegin_cnst, err));
	}
}

static void Scan(struct Parser *p, o7c_tag_t p_tag) {
	(*p).l = Scanner_Next(&(*p).s, Scanner_Scanner_tag);
	if ((*p).l < ErrNo_cnst) {
		AddError(&(*p), p_tag, (*p).l);
		if ((*p).l == Scanner_ErrNumberTooBig_cnst) {
			(*p).l = Scanner_Number_cnst;
		}
	}
}

static void Expect(struct Parser *p, o7c_tag_t p_tag, int expect, int error) {
	if ((*p).l == expect) {
		Scan(&(*p), p_tag);
	} else {
		AddError(&(*p), p_tag, error);
	}
}

static bool ScanIfEqual(struct Parser *p, o7c_tag_t p_tag, int lex) {
	if ((*p).l == lex) {
		Scan(&(*p), p_tag);
		lex = (*p).l;
	}
	return (*p).l == lex;
}

static void ExpectIdent(struct Parser *p, o7c_tag_t p_tag, int *begin, int *end, int error) {
	if ((*p).l == Scanner_Ident_cnst) {
		(*begin) = (*p).s.lexStart;
		(*end) = (*p).s.lexEnd;
		Scan(&(*p), p_tag);
	} else {
		AddError(&(*p), p_tag, error);
		(*begin) =  - 1;
		(*end) =  - 1;
	}
}

static Ast_ExprSet Set(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds);
static int Set_Element(Ast_ExprSet *e, struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	struct Ast_RExpression *left = NULL;
	int err = O7C_INT_UNDEFINED;

	left = expression(&(*p), p_tag, ds);
	if ((*p).l == Scanner_Range_cnst) {
		Scan(&(*p), p_tag);
		err = Ast_ExprSetNew(&(*e), left, expression(&(*p), p_tag, ds));
	} else {
		err = Ast_ExprSetNew(&(*e), left, NULL);
	}
	return err;
}

static Ast_ExprSet Set(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_ExprSet e = NULL, next = NULL;
	int err = O7C_INT_UNDEFINED;

	assert((*p).l == Scanner_Brace3Open_cnst);
	Scan(&(*p), p_tag);
	if ((*p).l != Scanner_Brace3Close_cnst) {
		err = Set_Element(&e, &(*p), p_tag, ds);
		CheckAst(&(*p), p_tag, err);
		next = e;
		while (ScanIfEqual(&(*p), p_tag, Scanner_Comma_cnst)) {
			err = Set_Element(&next->next, &(*p), p_tag, ds);
			CheckAst(&(*p), p_tag, err);
			next = next->next;
		}
		Expect(&(*p), p_tag, Scanner_Brace3Close_cnst, Parser_ErrExpectBrace3Close_cnst);
	} else {
		CheckAst(&(*p), p_tag, Ast_ExprSetNew(&e, NULL, NULL));
		Scan(&(*p), p_tag);
	}
	return e;
}

static Ast_ExprNegate Negate(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	assert((*p).l == Scanner_Negate_cnst);
	Scan(&(*p), p_tag);
	return Ast_ExprNegateNew(expression(&(*p), p_tag, ds));
}

static struct Ast_RDeclaration *DeclarationGet(struct Ast_RDeclarations *ds, struct Parser *p, o7c_tag_t p_tag) {
	struct Ast_RDeclaration *d = NULL;

	Log_StrLn("DeclarationGet", 15);
	CheckAst(&(*p), p_tag, Ast_DeclarationGet(&d, ds, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd));
	return d;
}

static struct Ast_RDeclaration *ExpectDecl(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	struct Ast_RDeclaration *d = NULL;

	if ((*p).l != Scanner_Ident_cnst) {
		d = NULL;
		AddError(&(*p), p_tag, Parser_ErrExpectIdent_cnst);
	} else {
		d = DeclarationGet(ds, &(*p), p_tag);
		Scan(&(*p), p_tag);
	}
	return d;
}

static struct Ast_RDeclaration *Qualident(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	struct Ast_RDeclaration *d = NULL;

	Log_StrLn("Qualident", 10);
	d = ExpectDecl(&(*p), p_tag, ds);
	if ((d != NULL) && (o7c_is(NULL, d, Ast_Import_s_tag))) {
		Expect(&(*p), p_tag, Scanner_Dot_cnst, Parser_ErrExpectDot_cnst);
		d = ExpectDecl(&(*p), p_tag, &(&O7C_GUARD(Ast_Import_s, d, NULL))->_.module->_);
	}
	return d;
}

static struct Ast_RDeclaration *ExpectRecordExtend(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, struct Ast_RConstruct *base) {
	struct Ast_RDeclaration *d = NULL;

	d = Qualident(&(*p), p_tag, ds);
	return d;
}

static Ast_Designator Designator(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds);
static void Designator_SetSel(struct Ast_RSelector **prev, struct Ast_RSelector *sel, Ast_Designator des) {
	if ((*prev) == NULL) {
		des->sel = sel;
	} else {
		(*prev)->next = sel;
	}
	(*prev) = sel;
}

static Ast_Designator Designator(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_Designator des = NULL;
	struct Ast_RDeclaration *decl = NULL, *var_ = NULL;
	struct Ast_RSelector *prev = NULL, *sel = NULL;
	struct Ast_RType *type = NULL;
	int nameBegin = O7C_INT_UNDEFINED, nameEnd = O7C_INT_UNDEFINED;

	Log_StrLn("Designator", 11);
	assert((*p).l == Scanner_Ident_cnst);
	decl = Qualident(&(*p), p_tag, ds);
	des = NULL;
	if (decl != NULL) {
		if (o7c_is(NULL, decl, Ast_RVar_tag)) {
			type = decl->type;
			prev = NULL;
			des = Ast_DesignatorNew(decl);
			do {
				sel = NULL;
				if ((*p).l == Scanner_Dot_cnst) {
					Scan(&(*p), p_tag);
					ExpectIdent(&(*p), p_tag, &nameBegin, &nameEnd, Parser_ErrExpectIdent_cnst);
					if (nameBegin >= 0) {
						CheckAst(&(*p), p_tag, Ast_SelRecordNew(&sel, &type, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, nameBegin, nameEnd));
					}
				} else if ((*p).l == Scanner_Brace1Open_cnst) {
					if (( (1u << type->_._.id) & ((1 << Ast_IdRecord_cnst) | (1 << Ast_IdPointer_cnst)))) {
						Scan(&(*p), p_tag);
						var_ = ExpectRecordExtend(&(*p), p_tag, ds, (&O7C_GUARD(Ast_RConstruct, type, NULL)));
						CheckAst(&(*p), p_tag, Ast_SelGuardNew(&sel, &type, var_));
						Expect(&(*p), p_tag, Scanner_Brace1Close_cnst, Parser_ErrExpectBrace1Close_cnst);
					} else if (!(o7c_is(NULL, type, Ast_ProcType_s_tag))) {
						AddError(&(*p), p_tag, Parser_ErrExpectVarRecordOrPointer_cnst);
					}
				} else if ((*p).l == Scanner_Brace2Open_cnst) {
					Scan(&(*p), p_tag);
					CheckAst(&(*p), p_tag, Ast_SelArrayNew(&sel, &type, expression(&(*p), p_tag, ds)));
					while (ScanIfEqual(&(*p), p_tag, Scanner_Comma_cnst)) {
						Designator_SetSel(&prev, sel, des);
						CheckAst(&(*p), p_tag, Ast_SelArrayNew(&sel, &type, expression(&(*p), p_tag, ds)));
					}
					Expect(&(*p), p_tag, Scanner_Brace2Close_cnst, Parser_ErrExpectBrace2Close_cnst);
				} else if ((*p).l == Scanner_Dereference_cnst) {
					CheckAst(&(*p), p_tag, Ast_SelPointerNew(&sel, &type));
					Scan(&(*p), p_tag);
				}
				Designator_SetSel(&prev, sel, des);
			} while (!(sel == NULL));
			des->_._.type = type;
		} else if ((o7c_is(NULL, decl, Ast_Const_s_tag)) || (o7c_is(NULL, decl, Ast_RGeneralProcedure_tag)) || (decl->_.id == Ast_IdError_cnst)) {
			des = Ast_DesignatorNew(decl);
		} else {
			AddError(&(*p), p_tag, Parser_ErrExpectDesignator_cnst);
		}
	}
	return des;
}

static void CallParams(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, Ast_ExprCall e) {
	Ast_Parameter par = NULL;
	Ast_FormalParam fp = NULL;

	assert((*p).l == Scanner_Brace1Open_cnst);
	Scan(&(*p), p_tag);
	if (!ScanIfEqual(&(*p), p_tag, Scanner_Brace1Close_cnst)) {
		par = NULL;
		fp = (&O7C_GUARD(Ast_ProcType_s, e->designator->_._.type, NULL))->params;
		CheckAst(&(*p), p_tag, Ast_CallParamNew(e, &par, expression(&(*p), p_tag, ds), &fp));
		e->params = par;
		while (ScanIfEqual(&(*p), p_tag, Scanner_Comma_cnst)) {
			CheckAst(&(*p), p_tag, Ast_CallParamNew(e, &par, expression(&(*p), p_tag, ds), &fp));
		}
		CheckAst(&(*p), p_tag, Ast_CallParamsEnd(e, fp));
		Expect(&(*p), p_tag, Scanner_Brace1Close_cnst, Parser_ErrExpectBrace1Close_cnst);
	}
}

static Ast_ExprCall ExprCall(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, Ast_Designator des) {
	Ast_ExprCall e = NULL;

	CheckAst(&(*p), p_tag, Ast_ExprCallNew(&e, des));
	CallParams(&(*p), p_tag, ds, e);
	return e;
}

static struct Ast_RExpression *Factor(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds);
static void Factor_Ident(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, struct Ast_RExpression **e) {
	Ast_Designator des = NULL;

	des = Designator(&(*p), p_tag, ds);
	if ((*p).l != Scanner_Brace1Open_cnst) {
		(*e) = (&(des)->_._);
	} else {
		(*e) = (&(ExprCall(&(*p), p_tag, ds, des))->_._);
	}
}

static struct Ast_RExpression *Factor(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	struct Ast_RExpression *e = NULL;

	Log_StrLn("Factor", 7);
	if ((*p).l == Scanner_Number_cnst) {
		if ((*p).s.isReal) {
			e = (&(Ast_ExprRealNew((*p).s.real, (*p).module, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd))->_._._);
		} else {
			e = (&(Ast_ExprIntegerNew((*p).s.integer))->_._._);
		}
		Scan(&(*p), p_tag);
	} else if (((*p).l == Scanner_True_cnst) || ((*p).l == Scanner_False_cnst)) {
		e = (&(Ast_ExprBooleanNew((*p).l == Scanner_True_cnst))->_._);
		Scan(&(*p), p_tag);
	} else if ((*p).l == Scanner_Nil_cnst) {
		e = (&(Ast_ExprNilNew())->_._);
		Scan(&(*p), p_tag);
	} else if ((*p).l == Scanner_String_cnst) {
		e = (&(Ast_ExprStringNew((*p).module, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd))->_._._._);
		if ((e != NULL) && (*p).s.isChar) {
			(&O7C_GUARD(Ast_ExprString_s, e, NULL))->_.int_ = (*p).s.integer;
		}
		Scan(&(*p), p_tag);
	} else if ((*p).l == Scanner_Brace1Open_cnst) {
		Scan(&(*p), p_tag);
		e = (&(Ast_ExprBracesNew(expression(&(*p), p_tag, ds)))->_._);
		Expect(&(*p), p_tag, Scanner_Brace1Close_cnst, Parser_ErrExpectBrace1Close_cnst);
	} else if ((*p).l == Scanner_Ident_cnst) {
		Factor_Ident(&(*p), p_tag, ds, &e);
	} else if ((*p).l == Scanner_Brace3Open_cnst) {
		e = (&(Set(&(*p), p_tag, ds))->_._);
	} else if ((*p).l == Scanner_Negate_cnst) {
		e = (&(Negate(&(*p), p_tag, ds))->_._);
	} else {
		AddError(&(*p), p_tag, Parser_ErrExpectExpression_cnst);
		e = NULL;
	}
	return e;
}

static struct Ast_RExpression *Term(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	struct Ast_RExpression *e = NULL;
	Ast_ExprTerm term = NULL;
	int l = O7C_INT_UNDEFINED;

	Log_StrLn("Term", 5);
	e = Factor(&(*p), p_tag, ds);
	if (((*p).l >= Scanner_MultFirst_cnst) && ((*p).l <= Scanner_MultLast_cnst)) {
		l = (*p).l;
		Scan(&(*p), p_tag);
		term = NULL;
		CheckAst(&(*p), p_tag, Ast_ExprTermNew(&term, (&O7C_GUARD(Ast_RFactor, e, NULL)), l, Factor(&(*p), p_tag, ds)));
		assert((term->expr != NULL) && (term->factor != NULL));
		e = (&(term)->_);
		while (((*p).l >= Scanner_MultFirst_cnst) && ((*p).l <= Scanner_MultLast_cnst)) {
			l = (*p).l;
			Scan(&(*p), p_tag);
			CheckAst(&(*p), p_tag, Ast_ExprTermAdd(e, &term, l, Factor(&(*p), p_tag, ds)));
		}
	}
	return e;
}

static struct Ast_RExpression *Sum(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	struct Ast_RExpression *e = NULL;
	Ast_ExprSum sum = NULL;
	int l = O7C_INT_UNDEFINED;

	Log_StrLn("Sum", 4);
	l = (*p).l;
	if ((l == Scanner_Minus_cnst) || (l == Scanner_Plus_cnst)) {
		Scan(&(*p), p_tag);
		CheckAst(&(*p), p_tag, Ast_ExprSumNew(&sum, l, Term(&(*p), p_tag, ds)));
		e = (&(sum)->_);
	} else {
		e = Term(&(*p), p_tag, ds);
		if (((*p).l == Scanner_Minus_cnst) || ((*p).l == Scanner_Plus_cnst) || ((*p).l == Scanner_Or_cnst)) {
			CheckAst(&(*p), p_tag, Ast_ExprSumNew(&sum,  - 1, e));
			e = (&(sum)->_);
		}
	}
	while (((*p).l == Scanner_Minus_cnst) || ((*p).l == Scanner_Plus_cnst) || ((*p).l == Scanner_Or_cnst)) {
		l = (*p).l;
		Scan(&(*p), p_tag);
		CheckAst(&(*p), p_tag, Ast_ExprSumAdd(e, &sum, l, Term(&(*p), p_tag, ds)));
	}
	return e;
}

static struct Ast_RExpression *Expression(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	struct Ast_RExpression *expr = NULL;
	Ast_ExprRelation e = NULL;
	Ast_ExprIsExtension isExt = NULL;
	int rel = O7C_INT_UNDEFINED;

	Log_StrLn("Expression", 11);
	expr = Sum(&(*p), p_tag, ds);
	if (((*p).l >= Scanner_RelationFirst_cnst) && ((*p).l < Scanner_RelationLast_cnst)) {
		rel = (*p).l;
		Scan(&(*p), p_tag);
		CheckAst(&(*p), p_tag, Ast_ExprRelationNew(&e, expr, rel, Sum(&(*p), p_tag, ds)));
		expr = (&(e)->_);
	} else if (ScanIfEqual(&(*p), p_tag, Scanner_Is_cnst)) {
		CheckAst(&(*p), p_tag, Ast_ExprIsExtensionNew(&isExt, &expr, type(&(*p), p_tag, ds,  - 1,  - 1)));
		expr = (&(isExt)->_);
	}
	return expr;
}

static bool Mark(struct Parser *p, o7c_tag_t p_tag) {
	bool m = 0 > 1;

	m = ScanIfEqual(&(*p), p_tag, Scanner_Asterisk_cnst);
	if (m) {
		Log_StrLn("Mark", 5);
	}
	return m;
}

static void Consts(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	int begin = O7C_INT_UNDEFINED, end = O7C_INT_UNDEFINED;
	struct Ast_Const_s *const_ = NULL;

	Scan(&(*p), p_tag);
	while ((*p).l == Scanner_Ident_cnst) {
		if (!(*p).err) {
			ExpectIdent(&(*p), p_tag, &begin, &end, Parser_ErrExpectConstName_cnst);
			CheckAst(&(*p), p_tag, Ast_ConstAdd(ds, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, begin, end));
			const_ = (&O7C_GUARD(Ast_Const_s, ds->end, NULL));
			const_->_.mark = Mark(&(*p), p_tag);
			Expect(&(*p), p_tag, Scanner_Equal_cnst, Parser_ErrExpectEqual_cnst);
			CheckAst(&(*p), p_tag, Ast_ConstSetExpression(const_, Expression(&(*p), p_tag, ds)));
			Expect(&(*p), p_tag, Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
		}
		if ((*p).err) {
			while (((*p).l < Scanner_Import_cnst) && ((*p).l != Scanner_Semicolon_cnst)) {
				Scan(&(*p), p_tag);
			}
			(*p).err = false;
		}
	}
}

static int ExprToArrayLen(struct Parser *p, o7c_tag_t p_tag, struct Ast_RExpression *e) {
	int i = O7C_INT_UNDEFINED;

	if ((e != NULL) && (e->value_ != NULL) && (o7c_is(NULL, e->value_, Ast_RExprInteger_tag))) {
		i = (&O7C_GUARD(Ast_RExprInteger, e->value_, NULL))->int_;
		if (i <= 0) {
			AddError(&(*p), p_tag, Parser_ErrArrayLenLess1_cnst);
		} else {
			Log_Str("Array Len ", 11);
			Log_Int(i);
			Log_Ln();
		}
	} else {
		i =  - 1;
		if (e != NULL) {
			AddError(&(*p), p_tag, Parser_ErrExpectConstIntExpr_cnst);
		}
	}
	return i;
}

static int ExprToInteger(struct Parser *p, o7c_tag_t p_tag, struct Ast_RExpression *e) {
	int i = O7C_INT_UNDEFINED;

	if ((e != NULL) && (e->type->_._.id == Ast_IdInteger_cnst)) {
		i = (&O7C_GUARD(Ast_RExprInteger, e, NULL))->int_;
	} else {
		i = 0;
		if (e != NULL) {
			AddError(&(*p), p_tag, Parser_ErrExpectConstIntExpr_cnst);
		}
	}
	return i;
}

static struct Ast_RArray *Array(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, int nameBegin, int nameEnd) {
	struct Ast_RArray *a = NULL;
	struct Ast_RType *t = NULL;
	struct Ast_RExpression *exprLen = NULL;
	struct Ast_RExpression *lens[16] /* init array */;
	int i = O7C_INT_UNDEFINED, size = O7C_INT_UNDEFINED;

	Log_StrLn("Array", 6);
	assert((*p).l == Scanner_Array_cnst);
	Scan(&(*p), p_tag);
	a = Ast_ArrayGet(NULL, Expression(&(*p), p_tag, ds));
	if (nameBegin >= 0) {
		t = (&(a)->_._);
		CheckAst(&(*p), p_tag, Ast_TypeAdd(ds, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, nameBegin, nameEnd, &t));
	}
	size = ExprToArrayLen(&(*p), p_tag, a->count);
	i = 0;
	while (ScanIfEqual(&(*p), p_tag, Scanner_Comma_cnst)) {
		exprLen = Expression(&(*p), p_tag, ds);
		size = o7c_mul(size, ExprToArrayLen(&(*p), p_tag, exprLen));
		if (i < sizeof(lens) / sizeof (lens[0])) {
			lens[o7c_ind(16, i)] = exprLen;
		}
		i++;
	}
	if (i > sizeof(lens) / sizeof (lens[0])) {
		AddError(&(*p), p_tag, Parser_ErrArrayDimensionsTooMany_cnst);
	}
	Expect(&(*p), p_tag, Scanner_Of_cnst, Parser_ErrExpectOf_cnst);
	a->_._._.type = type(&(*p), p_tag, ds,  - 1,  - 1);
	while (i > 0) {
		i--;
		a->_._._.type = (&(Ast_ArrayGet(a->_._._.type, lens[o7c_ind(16, i)]))->_._);
	}
	return a;
}

static struct Ast_RType *TypeNamed(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	struct Ast_RDeclaration *d = NULL;
	struct Ast_RType *t = NULL;

	t = NULL;
	d = Qualident(&(*p), p_tag, ds);
	if (d != NULL) {
		if (o7c_is(NULL, d, Ast_RType_tag)) {
			t = (&O7C_GUARD(Ast_RType, d, NULL));
		} else if (d->_.id != Ast_IdError_cnst) {
			AddError(&(*p), p_tag, Parser_ErrExpectType_cnst);
		}
	}
	return t;
}

static void VarDeclaration(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *dsAdd, struct Ast_RDeclarations *dsTypes);
static void VarDeclaration_Name(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	int begin = O7C_INT_UNDEFINED, end = O7C_INT_UNDEFINED;

	ExpectIdent(&(*p), p_tag, &begin, &end, Parser_ErrExpectIdent_cnst);
	CheckAst(&(*p), p_tag, Ast_VarAdd(ds, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, begin, end));
	ds->end->mark = Mark(&(*p), p_tag);
}

static void VarDeclaration(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *dsAdd, struct Ast_RDeclarations *dsTypes) {
	struct Ast_RDeclaration *var_ = NULL;
	struct Ast_RType *typ = NULL;

	VarDeclaration_Name(&(*p), p_tag, dsAdd);
	var_ = (&((&O7C_GUARD(Ast_RVar, dsAdd->end, NULL)))->_);
	while (ScanIfEqual(&(*p), p_tag, Scanner_Comma_cnst)) {
		VarDeclaration_Name(&(*p), p_tag, dsAdd);
	}
	Expect(&(*p), p_tag, Scanner_Colon_cnst, Parser_ErrExpectColon_cnst);
	typ = type(&(*p), p_tag, dsTypes,  - 1,  - 1);
	while (var_ != NULL) {
		var_->type = typ;
		var_ = var_->next;
	}
}

static void Vars(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	while ((*p).l == Scanner_Ident_cnst) {
		VarDeclaration(&(*p), p_tag, ds, ds);
		Expect(&(*p), p_tag, Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
	}
}

static Ast_Record Record(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, int nameBegin, int nameEnd);
static void Record_Vars(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *dsAdd, struct Ast_RDeclarations *dsTypes) {
	if ((*p).l == Scanner_Ident_cnst) {
		VarDeclaration(&(*p), p_tag, dsAdd, dsTypes);
		while (ScanIfEqual(&(*p), p_tag, Scanner_Semicolon_cnst)) {
			if ((*p).l != Scanner_End_cnst) {
				VarDeclaration(&(*p), p_tag, dsAdd, dsTypes);
			} else if ((*p).settings.strictSemicolon) {
				AddError(&(*p), p_tag, Parser_ErrExcessSemicolon_cnst);
				(*p).err = false;
			}
		}
	}
}

static Ast_Record Record(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, int nameBegin, int nameEnd) {
	Ast_Record rec = NULL, base = NULL;
	struct Ast_RType *t = NULL;
	struct Ast_RDeclaration *decl = NULL;

	assert((*p).l == Scanner_Record_cnst);
	Scan(&(*p), p_tag);
	base = NULL;
	if (ScanIfEqual(&(*p), p_tag, Scanner_Brace1Open_cnst)) {
		decl = Qualident(&(*p), p_tag, ds);
		if ((decl != NULL) && (decl->_.id == Ast_IdRecord_cnst)) {
			base = (&O7C_GUARD(Ast_Record_s, decl, NULL));
		} else {
			AddError(&(*p), p_tag, Parser_ErrExpectRecord_cnst);
		}
		Expect(&(*p), p_tag, Scanner_Brace1Close_cnst, Parser_ErrExpectBrace1Close_cnst);
	}
	rec = Ast_RecordNew(ds, base);
	if (nameBegin >= 0) {
		t = (&(rec)->_._);
		CheckAst(&(*p), p_tag, Ast_TypeAdd(ds, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, nameBegin, nameEnd, &t));
		rec = (&O7C_GUARD(Ast_Record_s, t, NULL));
		Ast_RecordSetBase(rec, base);
	} else {
		rec->_._._.name.block = NULL;
		rec->_._._.module = (*p).module;
	}
	Record_Vars(&(*p), p_tag, rec->vars, ds);
	Expect(&(*p), p_tag, Scanner_End_cnst, Parser_ErrExpectEnd_cnst);
	return rec;
}

static struct Ast_RPointer *Pointer(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, int nameBegin, int nameEnd) {
	struct Ast_RPointer *tp = NULL;
	struct Ast_RType *t = NULL;
	struct Ast_RDeclaration *decl = NULL;
	struct Ast_RType *typeDecl = NULL;

	assert((*p).l == Scanner_Pointer_cnst);
	Scan(&(*p), p_tag);
	tp = Ast_PointerGet(NULL);
	if (nameBegin >= 0) {
		t = (&(tp)->_._);
		assert(t != NULL);
		CheckAst(&(*p), p_tag, Ast_TypeAdd(ds, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, nameBegin, nameEnd, &t));
	}
	Expect(&(*p), p_tag, Scanner_To_cnst, Parser_ErrExpectTo_cnst);
	if ((*p).l == Scanner_Record_cnst) {
		tp->_._._.type = (&(Record(&(*p), p_tag, ds,  - 1,  - 1))->_._);
		if (tp->_._._.type != NULL) {
			(&O7C_GUARD(Ast_Record_s, tp->_._._.type, NULL))->pointer = tp;
		}
	} else if ((*p).l == Scanner_Ident_cnst) {
		decl = Ast_DeclarationSearch(ds, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd);
		if (decl == NULL) {
			typeDecl = (&(Ast_RecordNew(ds, NULL))->_._);
			CheckAst(&(*p), p_tag, Ast_TypeAdd(ds, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd, &typeDecl));
			assert(tp->_._._.next == &typeDecl->_);
			typeDecl->_._.id = Ast_IdRecordForward_cnst;
			tp->_._._.type = typeDecl;
			(&O7C_GUARD(Ast_Record_s, typeDecl, NULL))->pointer = tp;
		} else if (o7c_is(NULL, decl, Ast_Record_s_tag)) {
			tp->_._._.type = (&((&O7C_GUARD(Ast_Record_s, decl, NULL)))->_._);
			(&O7C_GUARD(Ast_Record_s, decl, NULL))->pointer = tp;
		} else {
			tp->_._._.type = TypeNamed(&(*p), p_tag, ds);
			if (tp->_._._.type != NULL) {
				if (o7c_is(NULL, tp->_._._.type, Ast_Record_s_tag)) {
					(&O7C_GUARD(Ast_Record_s, tp->_._._.type, NULL))->pointer = tp;
				} else {
					AddError(&(*p), p_tag, Parser_ErrExpectRecord_cnst);
				}
			}
		}
		Scan(&(*p), p_tag);
	} else {
		AddError(&(*p), p_tag, Parser_ErrExpectRecord_cnst);
	}
	return tp;
}

static void FormalParameters(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, struct Ast_ProcType_s *proc);
static void FormalParameters_Section(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, struct Ast_ProcType_s *proc);
static void Section_FormalParameters_Name(struct Parser *p, o7c_tag_t p_tag, struct Ast_ProcType_s *proc) {
	if ((*p).l != Scanner_Ident_cnst) {
		AddError(&(*p), p_tag, Parser_ErrExpectIdent_cnst);
	} else {
		CheckAst(&(*p), p_tag, Ast_ParamAdd((*p).module, proc, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd));
		Scan(&(*p), p_tag);
	}
}

static struct Ast_RType *Section_FormalParameters_Type(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	struct Ast_RType *t = NULL;
	int arrs = O7C_INT_UNDEFINED;

	arrs = 0;
	while (ScanIfEqual(&(*p), p_tag, Scanner_Array_cnst)) {
		Expect(&(*p), p_tag, Scanner_Of_cnst, Parser_ErrExpectOf_cnst);
		arrs++;
	}
	t = TypeNamed(&(*p), p_tag, ds);
	while ((t != NULL) && (arrs > 0)) {
		t = (&(Ast_ArrayGet(t, NULL))->_._);
		arrs--;
	}
	return t;
}

static void FormalParameters_Section(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, struct Ast_ProcType_s *proc) {
	bool isVar = 0 > 1;
	Ast_FormalParam param = NULL;
	struct Ast_RType *type = NULL;

	isVar = ScanIfEqual(&(*p), p_tag, Scanner_Var_cnst);
	Section_FormalParameters_Name(&(*p), p_tag, proc);
	param = proc->end;
	while (ScanIfEqual(&(*p), p_tag, Scanner_Comma_cnst)) {
		Section_FormalParameters_Name(&(*p), p_tag, proc);
	}
	Expect(&(*p), p_tag, Scanner_Colon_cnst, Parser_ErrExpectColon_cnst);
	type = Section_FormalParameters_Type(&(*p), p_tag, ds);
	while (param != NULL) {
		param->isVar = isVar;
		param->_._.type = type;
		param = (&O7C_GUARD(Ast_FormalParam_s, param->_._.next, NULL));
	}
}

static void FormalParameters(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, struct Ast_ProcType_s *proc) {
	bool braces = 0 > 1;

	braces = ScanIfEqual(&(*p), p_tag, Scanner_Brace1Open_cnst);
	if (braces) {
		if (!ScanIfEqual(&(*p), p_tag, Scanner_Brace1Close_cnst)) {
			FormalParameters_Section(&(*p), p_tag, ds, proc);
			while (ScanIfEqual(&(*p), p_tag, Scanner_Semicolon_cnst)) {
				FormalParameters_Section(&(*p), p_tag, ds, proc);
			}
			Expect(&(*p), p_tag, Scanner_Brace1Close_cnst, Parser_ErrExpectBrace1Close_cnst);
		}
	}
	if (ScanIfEqual(&(*p), p_tag, Scanner_Colon_cnst)) {
		if (!braces) {
			AddError(&(*p), p_tag, Parser_ErrFunctionWithoutBraces_cnst);
			(*p).err = false;
		}
		proc->_._._.type = TypeNamed(&(*p), p_tag, ds);
	}
}

static struct Ast_ProcType_s *TypeProcedure(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, int nameBegin, int nameEnd) {
	struct Ast_ProcType_s *proc = NULL;
	struct Ast_RType *t = NULL;

	assert((*p).l == Scanner_Procedure_cnst);
	Scan(&(*p), p_tag);
	proc = Ast_ProcTypeNew();
	if (nameBegin >= 0) {
		t = (&(proc)->_._);
		CheckAst(&(*p), p_tag, Ast_TypeAdd(ds, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, nameBegin, nameEnd, &t));
	}
	FormalParameters(&(*p), p_tag, ds, proc);
	return proc;
}

static struct Ast_RType *Type(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, int nameBegin, int nameEnd) {
	struct Ast_RType *t = NULL;

	if ((*p).l == Scanner_Array_cnst) {
		t = (&(Array(&(*p), p_tag, ds, nameBegin, nameEnd))->_._);
	} else if ((*p).l == Scanner_Pointer_cnst) {
		t = (&(Pointer(&(*p), p_tag, ds, nameBegin, nameEnd))->_._);
	} else if ((*p).l == Scanner_Procedure_cnst) {
		t = (&(TypeProcedure(&(*p), p_tag, ds, nameBegin, nameEnd))->_._);
	} else if ((*p).l == Scanner_Record_cnst) {
		t = (&(Record(&(*p), p_tag, ds, nameBegin, nameEnd))->_._);
	} else if ((*p).l == Scanner_Ident_cnst) {
		t = TypeNamed(&(*p), p_tag, ds);
	} else {
		t = Ast_TypeGet(Ast_IdInteger_cnst);
		AddError(&(*p), p_tag, Parser_ErrExpectType_cnst);
	}
	return t;
}

static void Types(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	struct Ast_RType *type = NULL;
	int begin = O7C_INT_UNDEFINED, end = O7C_INT_UNDEFINED;
	bool mark = 0 > 1;

	Scan(&(*p), p_tag);
	while ((*p).l == Scanner_Ident_cnst) {
		begin = (*p).s.lexStart;
		end = (*p).s.lexEnd;
		Scan(&(*p), p_tag);
		mark = ScanIfEqual(&(*p), p_tag, Scanner_Asterisk_cnst);
		Expect(&(*p), p_tag, Scanner_Equal_cnst, Parser_ErrExpectEqual_cnst);
		type = Type(&(*p), p_tag, ds, begin, end);
		if (type != NULL) {
			type->_.mark = mark;
			if (!(o7c_is(NULL, type, Ast_RConstruct_tag))) {
				AddError(&(*p), p_tag, Parser_ErrExpectNamedType_cnst);
			}
		}
		Expect(&(*p), p_tag, Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
	}
}

static Ast_If If(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds);
static Ast_If If_Branch(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_If if_ = NULL;

	Scan(&(*p), p_tag);
	if_ = Ast_IfNew(Expression(&(*p), p_tag, ds), NULL);
	Expect(&(*p), p_tag, Scanner_Then_cnst, Parser_ErrExpectThen_cnst);
	if_->_.stats = statements(&(*p), p_tag, ds);
	return if_;
}

static Ast_If If(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_If if_ = NULL;
	struct Ast_RWhileIf *elsif = NULL;

	assert((*p).l == Scanner_If_cnst);
	if_ = If_Branch(&(*p), p_tag, ds);
	elsif = (&(if_)->_);
	while ((*p).l == Scanner_Elsif_cnst) {
		elsif->elsif = (&(If_Branch(&(*p), p_tag, ds))->_);
		elsif = elsif->elsif;
	}
	if (ScanIfEqual(&(*p), p_tag, Scanner_Else_cnst)) {
		elsif->elsif = (&(Ast_IfNew(NULL, statements(&(*p), p_tag, ds)))->_);
	}
	Expect(&(*p), p_tag, Scanner_End_cnst, Parser_ErrExpectEnd_cnst);
	return if_;
}

static Ast_Case Case(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds);
static void Case_Element(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, Ast_Case case_);
static Ast_CaseLabel Element_Case_LabelList(struct Parser *p, o7c_tag_t p_tag, Ast_Case case_, struct Ast_RDeclarations *ds);
static Ast_CaseLabel LabelList_Element_Case_LabelRange(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds);
static Ast_CaseLabel LabelRange_LabelList_Element_Case_Label(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	int err = O7C_INT_UNDEFINED;
	Ast_CaseLabel l = NULL;
	bool qual = 0 > 1;

	qual = false;
	if (((*p).l == Scanner_Number_cnst) && !(*p).s.isReal) {
		err = Ast_CaseLabelNew(&l, Ast_IdInteger_cnst, (*p).s.integer);
	} else if ((*p).l == Scanner_String_cnst) {
		assert((*p).s.isChar);
		err = Ast_CaseLabelNew(&l, Ast_IdChar_cnst, (*p).s.integer);
	} else if ((*p).l == Scanner_Ident_cnst) {
		qual = true;
		err = Ast_CaseLabelQualNew(&l, Qualident(&(*p), p_tag, ds));
	} else {
		err = Parser_ErrExpectIntOrStrOrQualident_cnst;
	}
	CheckAst(&(*p), p_tag, err);
	if (!qual && (err != Parser_ErrExpectIntOrStrOrQualident_cnst)) {
		Scan(&(*p), p_tag);
	}
	return l;
}

static Ast_CaseLabel LabelList_Element_Case_LabelRange(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_CaseLabel r = NULL;

	r = LabelRange_LabelList_Element_Case_Label(&(*p), p_tag, ds);
	if ((*p).l == Scanner_Range_cnst) {
		Scan(&(*p), p_tag);
		CheckAst(&(*p), p_tag, Ast_CaseRangeNew(r, LabelRange_LabelList_Element_Case_Label(&(*p), p_tag, ds)));
	}
	return r;
}

static Ast_CaseLabel Element_Case_LabelList(struct Parser *p, o7c_tag_t p_tag, Ast_Case case_, struct Ast_RDeclarations *ds) {
	Ast_CaseLabel first = NULL, last = NULL;

	first = LabelList_Element_Case_LabelRange(&(*p), p_tag, ds);
	while ((*p).l == Scanner_Comma_cnst) {
		Scan(&(*p), p_tag);
		last = LabelList_Element_Case_LabelRange(&(*p), p_tag, ds);
		CheckAst(&(*p), p_tag, Ast_CaseRangeListAdd(case_, first, last));
	}
	return first;
}

static void Case_Element(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, Ast_Case case_) {
	Ast_CaseElement elem = NULL;

	elem = Ast_CaseElementNew(Element_Case_LabelList(&(*p), p_tag, case_, ds));
	assert(elem->labels != NULL);
	Expect(&(*p), p_tag, Scanner_Colon_cnst, Parser_ErrExpectColon_cnst);
	elem->stats = statements(&(*p), p_tag, ds);
	CheckAst(&(*p), p_tag, Ast_CaseElementAdd(case_, elem));
}

static Ast_Case Case(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_Case case_ = NULL;

	assert((*p).l == Scanner_Case_cnst);
	Scan(&(*p), p_tag);
	CheckAst(&(*p), p_tag, Ast_CaseNew(&case_, Expression(&(*p), p_tag, ds)));
	Expect(&(*p), p_tag, Scanner_Of_cnst, Parser_ErrExpectOf_cnst);
	Case_Element(&(*p), p_tag, ds, case_);
	while (ScanIfEqual(&(*p), p_tag, Scanner_Alternative_cnst)) {
		Case_Element(&(*p), p_tag, ds, case_);
	}
	Expect(&(*p), p_tag, Scanner_End_cnst, Parser_ErrExpectEnd_cnst);
	return case_;
}

static Ast_Repeat Repeat(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_Repeat r = NULL;

	assert((*p).l == Scanner_Repeat_cnst);
	Scan(&(*p), p_tag);
	r = Ast_RepeatNew(NULL, statements(&(*p), p_tag, ds));
	Expect(&(*p), p_tag, Scanner_Until_cnst, Parser_ErrExpectUntil_cnst);
	r->_.expr = Expression(&(*p), p_tag, ds);
	return r;
}

static Ast_For For(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_For f = NULL;
	struct Ast_RVar *v = NULL;

	assert((*p).l == Scanner_For_cnst);
	Scan(&(*p), p_tag);
	if ((*p).l != Scanner_Ident_cnst) {
		AddError(&(*p), p_tag, o7c_add(Parser_ErrExpectIdent_cnst, o7c_mul(Ast_ForIteratorGet(&v, ds, "FORITERATOR", 12, 0, 10), 0)));
	} else {
		CheckAst(&(*p), p_tag, Ast_ForIteratorGet(&v, ds, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd));
	}
	Scan(&(*p), p_tag);
	Expect(&(*p), p_tag, Scanner_Assign_cnst, Parser_ErrExpectAssign_cnst);
	f = Ast_ForNew(v, Expression(&(*p), p_tag, ds), NULL, 1, NULL);
	Expect(&(*p), p_tag, Scanner_To_cnst, Parser_ErrExpectTo_cnst);
	f->to = Expression(&(*p), p_tag, ds);
	if (ScanIfEqual(&(*p), p_tag, Scanner_By_cnst)) {
		f->by = ExprToInteger(&(*p), p_tag, Expression(&(*p), p_tag, ds));
	}
	Expect(&(*p), p_tag, Scanner_Do_cnst, Parser_ErrExpectDo_cnst);
	f->stats = statements(&(*p), p_tag, ds);
	Expect(&(*p), p_tag, Scanner_End_cnst, Parser_ErrExpectEnd_cnst);
	return f;
}

static Ast_While While(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_While w = NULL;
	struct Ast_RWhileIf *elsif = NULL;

	assert((*p).l == Scanner_While_cnst);
	Scan(&(*p), p_tag);
	w = Ast_WhileNew(Expression(&(*p), p_tag, ds), NULL);
	elsif = (&(w)->_);
	Expect(&(*p), p_tag, Scanner_Do_cnst, Parser_ErrExpectDo_cnst);
	w->_.stats = statements(&(*p), p_tag, ds);
	while (ScanIfEqual(&(*p), p_tag, Scanner_Elsif_cnst)) {
		elsif->elsif = (&(Ast_WhileNew(Expression(&(*p), p_tag, ds), NULL))->_);
		elsif = elsif->elsif;
		Expect(&(*p), p_tag, Scanner_Do_cnst, Parser_ErrExpectDo_cnst);
		elsif->stats = statements(&(*p), p_tag, ds);
	}
	Expect(&(*p), p_tag, Scanner_End_cnst, Parser_ErrExpectEnd_cnst);
	return w;
}

static Ast_Assign Assign(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, Ast_Designator des) {
	Ast_Assign st = NULL;

	assert((*p).l == Scanner_Assign_cnst);
	Scan(&(*p), p_tag);
	CheckAst(&(*p), p_tag, Ast_AssignNew(&st, des, Expression(&(*p), p_tag, ds)));
	return st;
}

static Ast_Call Call(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, Ast_Designator des) {
	Ast_Call st = NULL;

	CheckAst(&(*p), p_tag, Ast_CallNew(&st, des));
	if ((*p).l == Scanner_Brace1Open_cnst) {
		CallParams(&(*p), p_tag, ds, (&O7C_GUARD(Ast_ExprCall_s, st->_.expr, NULL)));
	} else if ((des != NULL) && (des->_._.type != NULL) && (o7c_is(NULL, des->_._.type, Ast_ProcType_s_tag))) {
		CheckAst(&(*p), p_tag, Ast_CallParamsEnd((&O7C_GUARD(Ast_ExprCall_s, st->_.expr, NULL)), (&O7C_GUARD(Ast_ProcType_s, des->_._.type, NULL))->params));
	}
	return st;
}

static struct Ast_RStatement *Statements(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds);
static struct Ast_RStatement *Statements_Statement(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_Designator des = NULL;
	struct Ast_RStatement *st = NULL;

	Log_StrLn("Statement", 10);
	if ((*p).l == Scanner_Ident_cnst) {
		des = Designator(&(*p), p_tag, ds);
		if ((*p).l == Scanner_Assign_cnst) {
			st = (&(Assign(&(*p), p_tag, ds, des))->_);
		} else {
			st = (&(Call(&(*p), p_tag, ds, des))->_);
		}
	} else if ((*p).l == Scanner_If_cnst) {
		st = (&(If(&(*p), p_tag, ds))->_._);
	} else if ((*p).l == Scanner_Case_cnst) {
		st = (&(Case(&(*p), p_tag, ds))->_);
	} else if ((*p).l == Scanner_Repeat_cnst) {
		st = (&(Repeat(&(*p), p_tag, ds))->_);
	} else if ((*p).l == Scanner_For_cnst) {
		st = (&(For(&(*p), p_tag, ds))->_);
	} else if ((*p).l == Scanner_While_cnst) {
		st = (&(While(&(*p), p_tag, ds))->_._);
	} else {
		st = (&(Ast_StatementErrorNew())->_);
		AddError(&(*p), p_tag, Parser_ErrExpectStatement_cnst);
	}
	if ((*p).err) {
		Log_StrLn("Error", 6);
		while (((*p).l != Scanner_Semicolon_cnst) && ((*p).l != Scanner_Until_cnst) && ((*p).l != Scanner_Elsif_cnst) && ((*p).l != Scanner_Else_cnst) && ((*p).l != Scanner_End_cnst) && ((*p).l != Scanner_Return_cnst)) {
			Scan(&(*p), p_tag);
		}
		(*p).err = false;
	}
	return st;
}

static struct Ast_RStatement *Statements(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	struct Ast_RStatement *stats = NULL, *last = NULL;

	Log_StrLn("Statements", 11);
	stats = Statements_Statement(&(*p), p_tag, ds);
	last = stats;
	while (ScanIfEqual(&(*p), p_tag, Scanner_Semicolon_cnst)) {
		if (((*p).l != Scanner_End_cnst) && ((*p).l != Scanner_Return_cnst) && ((*p).l != Scanner_Else_cnst) && ((*p).l != Scanner_Elsif_cnst) && ((*p).l != Scanner_Until_cnst)) {
			last->next = Statements_Statement(&(*p), p_tag, ds);
			last = last->next;
		} else if ((*p).settings.strictSemicolon) {
			AddError(&(*p), p_tag, Parser_ErrExcessSemicolon_cnst);
			(*p).err = false;
		}
	}
	return stats;
}

static void Return(struct Parser *p, o7c_tag_t p_tag, struct Ast_RProcedure *proc) {
	if ((*p).l == Scanner_Return_cnst) {
		Log_StrLn("Return", 7);
		Scan(&(*p), p_tag);
		CheckAst(&(*p), p_tag, Ast_ProcedureSetReturn(proc, Expression(&(*p), p_tag, &proc->_._)));
		if ((*p).l == Scanner_Semicolon_cnst) {
			if ((*p).settings.strictSemicolon) {
				AddError(&(*p), p_tag, Parser_ErrExcessSemicolon_cnst);
				(*p).err = false;
			}
			Scan(&(*p), p_tag);
		}
	} else {
		CheckAst(&(*p), p_tag, Ast_ProcedureEnd(proc));
	}
}

static void ProcBody(struct Parser *p, o7c_tag_t p_tag, struct Ast_RProcedure *proc) {
	Log_StrLn("ProcBody", 9);
	declarations(&(*p), p_tag, &proc->_._);
	if (ScanIfEqual(&(*p), p_tag, Scanner_Begin_cnst)) {
		proc->_._.stats = Statements(&(*p), p_tag, &proc->_._);
	}
	Return(&(*p), p_tag, proc);
	Expect(&(*p), p_tag, Scanner_End_cnst, Parser_ErrExpectEnd_cnst);
	if ((*p).l == Scanner_Ident_cnst) {
		Log_StrLn("End Ident", 10);
		if (!StringStore_IsEqualToChars(&proc->_._._.name, StringStore_String_tag, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd)) {
			AddError(&(*p), p_tag, Parser_ErrEndProcedureNameNotMatch_cnst);
		}
		Scan(&(*p), p_tag);
	} else {
		AddError(&(*p), p_tag, Parser_ErrExpectProcedureName_cnst);
	}
}

static void Procedure(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	struct Ast_RProcedure *proc = NULL;
	int nameStart = O7C_INT_UNDEFINED, nameEnd = O7C_INT_UNDEFINED;

	Log_StrLn("Procedure", 10);
	Scan(&(*p), p_tag);
	ExpectIdent(&(*p), p_tag, &nameStart, &nameEnd, Parser_ErrExpectIdent_cnst);
	CheckAst(&(*p), p_tag, Ast_ProcedureAdd(ds, &proc, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, nameStart, nameEnd));
	proc->_._._.mark = Mark(&(*p), p_tag);
	FormalParameters(&(*p), p_tag, ds, proc->_.header);
	Expect(&(*p), p_tag, Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
	ProcBody(&(*p), p_tag, proc);
}

static void Declarations(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	if ((*p).l == Scanner_Const_cnst) {
		Consts(&(*p), p_tag, ds);
	}
	if ((*p).l == Scanner_Type_cnst) {
		Types(&(*p), p_tag, ds);
	}
	if ((*p).l == Scanner_Var_cnst) {
		Scan(&(*p), p_tag);
		Vars(&(*p), p_tag, ds);
	}
	while ((*p).l == Scanner_Procedure_cnst) {
		Procedure(&(*p), p_tag, ds);
		Expect(&(*p), p_tag, Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
	}
}

static void Imports(struct Parser *p, o7c_tag_t p_tag) {
	int nameOfs = O7C_INT_UNDEFINED, nameEnd = O7C_INT_UNDEFINED, realOfs = O7C_INT_UNDEFINED, realEnd = O7C_INT_UNDEFINED;

	do {
		Scan(&(*p), p_tag);
		ExpectIdent(&(*p), p_tag, &nameOfs, &nameEnd, Parser_ErrExpectModuleName_cnst);
		if (ScanIfEqual(&(*p), p_tag, Scanner_Assign_cnst)) {
			ExpectIdent(&(*p), p_tag, &realOfs, &realEnd, Parser_ErrExpectModuleName_cnst);
		} else {
			realOfs = nameOfs;
			realEnd = nameEnd;
		}
		if (!(*p).err) {
			CheckAst(&(*p), p_tag, Ast_ImportAdd((*p).module, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, nameOfs, nameEnd, realOfs, realEnd, (*p).provider));
		} else {
			(*p).err = false;
			while (((*p).l < Scanner_Import_cnst) && ((*p).l != Scanner_Comma_cnst) && ((*p).l != Scanner_Semicolon_cnst)) {
				Scan(&(*p), p_tag);
			}
		}
	} while (!((*p).l != Scanner_Comma_cnst));
	Expect(&(*p), p_tag, Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
}

static void Module(struct Parser *p, o7c_tag_t p_tag) {
	Log_StrLn("Module", 7);
	Scan(&(*p), p_tag);
	if ((*p).l != Scanner_Module_cnst) {
		(*p).l = Parser_ErrExpectModule_cnst;
	} else {
		Scan(&(*p), p_tag);
		if ((*p).l != Scanner_Ident_cnst) {
			(*p).module = Ast_ModuleNew(" ", 2, 0, 0);
			AddError(&(*p), p_tag, Parser_ErrExpectIdent_cnst);
		} else {
			(*p).module = Ast_ModuleNew((*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd);
			Scan(&(*p), p_tag);
		}
		Expect(&(*p), p_tag, Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
		if ((*p).l == Scanner_Import_cnst) {
			Imports(&(*p), p_tag);
		}
		Declarations(&(*p), p_tag, &(*p).module->_);
		if (ScanIfEqual(&(*p), p_tag, Scanner_Begin_cnst)) {
			(*p).module->_.stats = Statements(&(*p), p_tag, &(*p).module->_);
		}
		Expect(&(*p), p_tag, Scanner_End_cnst, Parser_ErrExpectEnd_cnst);
		if ((*p).l == Scanner_Ident_cnst) {
			if (!StringStore_IsEqualToChars(&(*p).module->_._.name, StringStore_String_tag, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd)) {
				AddError(&(*p), p_tag, Parser_ErrEndModuleNameNotMatch_cnst);
			}
			Scan(&(*p), p_tag);
		} else {
			AddError(&(*p), p_tag, Parser_ErrExpectModuleName_cnst);
		}
		if ((*p).l != Scanner_Dot_cnst) {
			AddError(&(*p), p_tag, Parser_ErrExpectDot_cnst);
		}
	}
}

static void PrintError(int code) {
}

extern void Parser_DefaultOptions(struct Parser_Options *opt, o7c_tag_t opt_tag) {
	V_Init(&(*opt)._, opt_tag);
	(*opt).strictSemicolon = true;
	(*opt).strictReturn = true;
	(*opt).printError = PrintError;
}

extern struct Ast_RModule *Parser_Parse(struct VDataStream_In *in_, struct Ast_RProvider *prov, struct Parser_Options *opt, o7c_tag_t opt_tag) {
	struct Parser p /* record init */;

	assert(in_ != NULL);
	assert(prov != NULL);
	V_Init(&p._, Parser_tag);
	p.settings = (*opt);
	p.err = false;
	p.module = NULL;
	p.provider = prov;
	Scanner_Init(&p.s, Scanner_Scanner_tag, in_);
	Module(&p, Parser_tag);
	return p.module;
}

extern void Parser_init_(void) {
	static int initialized__ = 0;
	if (0 == initialized__) {
		V_init_();
		Log_init_();
		Out_init_();
		Utf8_init_();
		Scanner_init_();
		StringStore_init_();
		Ast_init_();
		VDataStream_init_();

		o7c_tag_init(Parser_Options_tag, V_Base_tag);
		o7c_tag_init(Parser_tag, V_Base_tag);

		declarations = Declarations;
		type = Type;
		statements = Statements;
		expression = Expression;
	}
	++initialized__;
}


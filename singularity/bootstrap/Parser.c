#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#define O7C_BOOL_UNDEFINED
#include <o7c.h>

#include "Parser.h"

#define ErrNo_cnst 0
#define ErrMin_cnst Parser_ErrAstEnd_cnst

o7c_tag_t Parser_Options_tag;
typedef struct Parser {
	struct V_Base _;
	struct Parser_Options settings;
	o7c_bool err;
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
	(*p).err = o7c_cmp(err, Parser_ErrAstBegin_cnst) >  0;
	if ((*p).module != NULL) {
		Ast_AddError((*p).module, err, (*p).s.line, (*p).s.column, (*p).s.tabs);
	}
	(*p).settings.printError(err);
	Out_Ln();
}

static void CheckAst(struct Parser *p, o7c_tag_t p_tag, int err) {
	if (o7c_cmp(err, Ast_ErrNo_cnst) !=  0) {
		assert((o7c_cmp(err, ErrNo_cnst) <  0) && (o7c_cmp(err, Ast_ErrMin_cnst) >=  0));
		AddError(&(*p), p_tag, o7c_add(Parser_ErrAstBegin_cnst, err));
	}
}

static void Scan(struct Parser *p, o7c_tag_t p_tag) {
	(*p).l = Scanner_Next(&(*p).s, Scanner_Scanner_tag);
	if (o7c_cmp((*p).l, ErrNo_cnst) <  0) {
		AddError(&(*p), p_tag, (*p).l);
		if (o7c_cmp((*p).l, Scanner_ErrNumberTooBig_cnst) ==  0) {
			(*p).l = Scanner_Number_cnst;
		}
	}
}

static void Expect(struct Parser *p, o7c_tag_t p_tag, int expect, int error) {
	if (o7c_cmp((*p).l, expect) ==  0) {
		Scan(&(*p), p_tag);
	} else {
		AddError(&(*p), p_tag, error);
	}
}

static o7c_bool ScanIfEqual(struct Parser *p, o7c_tag_t p_tag, int lex) {
	o7c_bool o7c_return;

	if (o7c_cmp((*p).l, lex) ==  0) {
		Scan(&(*p), p_tag);
		lex = (*p).l;
	}
	o7c_return = o7c_cmp((*p).l, lex) ==  0;
	return o7c_return;
}

static void ExpectIdent(struct Parser *p, o7c_tag_t p_tag, int *begin, int *end, int error) {
	if (o7c_cmp((*p).l, Scanner_Ident_cnst) ==  0) {
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
	int o7c_return;

	struct Ast_RExpression *left = NULL;
	int err = O7C_INT_UNDEF;

	o7c_retain(ds);
	O7C_ASSIGN(&(left), expression(&(*p), p_tag, ds));
	if (o7c_cmp((*p).l, Scanner_Range_cnst) ==  0) {
		Scan(&(*p), p_tag);
		err = Ast_ExprSetNew(&(*e), left, expression(&(*p), p_tag, ds));
	} else {
		err = Ast_ExprSetNew(&(*e), left, NULL);
	}
	o7c_return = err;
	o7c_release(left);
	o7c_release(ds);
	return o7c_return;
}

static Ast_ExprSet Set(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_ExprSet o7c_return = NULL;

	Ast_ExprSet e = NULL, next = NULL;
	int err = O7C_INT_UNDEF;

	o7c_retain(ds);
	assert(o7c_cmp((*p).l, Scanner_Brace3Open_cnst) ==  0);
	Scan(&(*p), p_tag);
	if (o7c_cmp((*p).l, Scanner_Brace3Close_cnst) !=  0) {
		err = Set_Element(&e, &(*p), p_tag, ds);
		CheckAst(&(*p), p_tag, err);
		O7C_ASSIGN(&(next), e);
		while (ScanIfEqual(&(*p), p_tag, Scanner_Comma_cnst)) {
			err = Set_Element(&next->next, &(*p), p_tag, ds);
			CheckAst(&(*p), p_tag, err);
			O7C_ASSIGN(&(next), next->next);
		}
		Expect(&(*p), p_tag, Scanner_Brace3Close_cnst, Parser_ErrExpectBrace3Close_cnst);
	} else {
		CheckAst(&(*p), p_tag, Ast_ExprSetNew(&e, NULL, NULL));
		Scan(&(*p), p_tag);
	}
	O7C_ASSIGN(&o7c_return, e);
	o7c_release(e); o7c_release(next);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static Ast_ExprNegate Negate(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_ExprNegate o7c_return = NULL;

	Ast_ExprNegate neg = NULL;

	o7c_retain(ds);
	assert(o7c_cmp((*p).l, Scanner_Negate_cnst) ==  0);
	Scan(&(*p), p_tag);
	CheckAst(&(*p), p_tag, Ast_ExprNegateNew(&neg, expression(&(*p), p_tag, ds)));
	O7C_ASSIGN(&o7c_return, neg);
	o7c_release(neg);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static struct Ast_RDeclaration *DeclarationGet(struct Ast_RDeclarations *ds, struct Parser *p, o7c_tag_t p_tag) {
	Ast_Declaration o7c_return = NULL;

	struct Ast_RDeclaration *d = NULL;

	o7c_retain(ds);
	Log_StrLn("DeclarationGet", 15);
	CheckAst(&(*p), p_tag, Ast_DeclarationGet(&d, ds, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd));
	O7C_ASSIGN(&o7c_return, d);
	o7c_release(d);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static struct Ast_RDeclaration *ExpectDecl(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_Declaration o7c_return = NULL;

	struct Ast_RDeclaration *d = NULL;

	o7c_retain(ds);
	if (o7c_cmp((*p).l, Scanner_Ident_cnst) !=  0) {
		O7C_ASSIGN(&(d), NULL);
		AddError(&(*p), p_tag, Parser_ErrExpectIdent_cnst);
	} else {
		O7C_ASSIGN(&(d), DeclarationGet(ds, &(*p), p_tag));
		Scan(&(*p), p_tag);
	}
	O7C_ASSIGN(&o7c_return, d);
	o7c_release(d);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static struct Ast_RDeclaration *Qualident(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_Declaration o7c_return = NULL;

	struct Ast_RDeclaration *d = NULL;

	o7c_retain(ds);
	Log_StrLn("Qualident", 10);
	O7C_ASSIGN(&(d), ExpectDecl(&(*p), p_tag, ds));
	if ((d != NULL) && (o7c_is(NULL, d, Ast_Import_s_tag))) {
		Expect(&(*p), p_tag, Scanner_Dot_cnst, Parser_ErrExpectDot_cnst);
		O7C_ASSIGN(&(d), ExpectDecl(&(*p), p_tag, &O7C_GUARD(Ast_Import_s, &d)->_.module->_));
	}
	O7C_ASSIGN(&o7c_return, d);
	o7c_release(d);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static struct Ast_RDeclaration *ExpectRecordExtend(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, struct Ast_RConstruct *base) {
	Ast_Declaration o7c_return = NULL;

	struct Ast_RDeclaration *d = NULL;

	o7c_retain(ds); o7c_retain(base);
	O7C_ASSIGN(&(d), Qualident(&(*p), p_tag, ds));
	O7C_ASSIGN(&o7c_return, d);
	o7c_release(d);
	o7c_release(ds); o7c_release(base);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static Ast_Designator Designator(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds);
static void Designator_SetSel(struct Ast_RSelector **prev, struct Ast_RSelector *sel, Ast_Designator des) {
	o7c_retain(sel); o7c_retain(des);
	if ((*prev) == NULL) {
		O7C_ASSIGN(&(des->sel), sel);
	} else {
		O7C_ASSIGN(&((*prev)->next), sel);
	}
	O7C_ASSIGN(&((*prev)), sel);
	o7c_release(sel); o7c_release(des);
}

static Ast_Designator Designator(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_Designator o7c_return = NULL;

	Ast_Designator des = NULL;
	struct Ast_RDeclaration *decl = NULL, *var_ = NULL;
	struct Ast_RSelector *prev = NULL, *sel = NULL;
	struct Ast_RType *type = NULL;
	int nameBegin = O7C_INT_UNDEF, nameEnd = O7C_INT_UNDEF;

	o7c_retain(ds);
	Log_StrLn("Designator", 11);
	assert(o7c_cmp((*p).l, Scanner_Ident_cnst) ==  0);
	O7C_ASSIGN(&(decl), Qualident(&(*p), p_tag, ds));
	O7C_ASSIGN(&(des), NULL);
	if (decl != NULL) {
		if (o7c_is(NULL, decl, Ast_RVar_tag)) {
			O7C_ASSIGN(&(type), decl->type);
			O7C_ASSIGN(&(prev), NULL);
			O7C_ASSIGN(&(des), Ast_DesignatorNew(decl));
			do {
				O7C_ASSIGN(&(sel), NULL);
				if (o7c_cmp((*p).l, Scanner_Dot_cnst) ==  0) {
					Scan(&(*p), p_tag);
					ExpectIdent(&(*p), p_tag, &nameBegin, &nameEnd, Parser_ErrExpectIdent_cnst);
					if (o7c_cmp(nameBegin, 0) >=  0) {
						CheckAst(&(*p), p_tag, Ast_SelRecordNew(&sel, &type, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, nameBegin, nameEnd));
					}
				} else if (o7c_cmp((*p).l, Scanner_Brace1Open_cnst) ==  0) {
					if (!!( (1u << type->_._.id) & ((1 << Ast_IdRecord_cnst) | (1 << Ast_IdPointer_cnst)))) {
						Scan(&(*p), p_tag);
						O7C_ASSIGN(&(var_), ExpectRecordExtend(&(*p), p_tag, ds, O7C_GUARD(Ast_RConstruct, &type)));
						CheckAst(&(*p), p_tag, Ast_SelGuardNew(&sel, &type, var_));
						Expect(&(*p), p_tag, Scanner_Brace1Close_cnst, Parser_ErrExpectBrace1Close_cnst);
					} else if (!(o7c_is(NULL, type, Ast_ProcType_s_tag))) {
						AddError(&(*p), p_tag, Parser_ErrExpectVarRecordOrPointer_cnst);
					}
				} else if (o7c_cmp((*p).l, Scanner_Brace2Open_cnst) ==  0) {
					Scan(&(*p), p_tag);
					CheckAst(&(*p), p_tag, Ast_SelArrayNew(&sel, &type, expression(&(*p), p_tag, ds)));
					while (ScanIfEqual(&(*p), p_tag, Scanner_Comma_cnst)) {
						Designator_SetSel(&prev, sel, des);
						CheckAst(&(*p), p_tag, Ast_SelArrayNew(&sel, &type, expression(&(*p), p_tag, ds)));
					}
					Expect(&(*p), p_tag, Scanner_Brace2Close_cnst, Parser_ErrExpectBrace2Close_cnst);
				} else if (o7c_cmp((*p).l, Scanner_Dereference_cnst) ==  0) {
					CheckAst(&(*p), p_tag, Ast_SelPointerNew(&sel, &type));
					Scan(&(*p), p_tag);
				}
				Designator_SetSel(&prev, sel, des);
			} while (!(sel == NULL));
			O7C_ASSIGN(&(des->_._.type), type);
		} else if ((o7c_is(NULL, decl, Ast_Const_s_tag)) || (o7c_is(NULL, decl, Ast_RGeneralProcedure_tag)) || (o7c_cmp(decl->_.id, Ast_IdError_cnst) ==  0)) {
			O7C_ASSIGN(&(des), Ast_DesignatorNew(decl));
		} else {
			AddError(&(*p), p_tag, Parser_ErrExpectDesignator_cnst);
		}
	}
	O7C_ASSIGN(&o7c_return, des);
	o7c_release(des); o7c_release(decl); o7c_release(var_); o7c_release(prev); o7c_release(sel); o7c_release(type);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static void CallParams(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, Ast_ExprCall e) {
	Ast_Parameter par = NULL;
	Ast_FormalParam fp = NULL;

	o7c_retain(ds); o7c_retain(e);
	assert(o7c_cmp((*p).l, Scanner_Brace1Open_cnst) ==  0);
	Scan(&(*p), p_tag);
	if (!ScanIfEqual(&(*p), p_tag, Scanner_Brace1Close_cnst)) {
		O7C_ASSIGN(&(par), NULL);
		O7C_ASSIGN(&(fp), O7C_GUARD(Ast_ProcType_s, &e->designator->_._.type)->params);
		CheckAst(&(*p), p_tag, Ast_CallParamNew(e, &par, expression(&(*p), p_tag, ds), &fp));
		O7C_ASSIGN(&(e->params), par);
		while (ScanIfEqual(&(*p), p_tag, Scanner_Comma_cnst)) {
			CheckAst(&(*p), p_tag, Ast_CallParamNew(e, &par, expression(&(*p), p_tag, ds), &fp));
		}
		CheckAst(&(*p), p_tag, Ast_CallParamsEnd(e, fp));
		Expect(&(*p), p_tag, Scanner_Brace1Close_cnst, Parser_ErrExpectBrace1Close_cnst);
	}
	o7c_release(par); o7c_release(fp);
	o7c_release(ds); o7c_release(e);
}

static Ast_ExprCall ExprCall(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, Ast_Designator des) {
	Ast_ExprCall o7c_return = NULL;

	Ast_ExprCall e = NULL;

	o7c_retain(ds); o7c_retain(des);
	CheckAst(&(*p), p_tag, Ast_ExprCallNew(&e, des));
	CallParams(&(*p), p_tag, ds, e);
	O7C_ASSIGN(&o7c_return, e);
	o7c_release(e);
	o7c_release(ds); o7c_release(des);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static struct Ast_RExpression *Factor(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds);
static void Factor_Ident(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, struct Ast_RExpression **e) {
	Ast_Designator des = NULL;

	o7c_retain(ds);
	O7C_ASSIGN(&(des), Designator(&(*p), p_tag, ds));
	if (o7c_cmp((*p).l, Scanner_Brace1Open_cnst) !=  0) {
		O7C_ASSIGN(&((*e)), (&(des)->_._));
	} else {
		O7C_ASSIGN(&((*e)), (&(ExprCall(&(*p), p_tag, ds, des))->_._));
	}
	o7c_release(des);
	o7c_release(ds);
}

static struct Ast_RExpression *Factor(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_Expression o7c_return = NULL;

	struct Ast_RExpression *e = NULL;

	o7c_retain(ds);
	Log_StrLn("Factor", 7);
	if (o7c_cmp((*p).l, Scanner_Number_cnst) ==  0) {
		if ((*p).s.isReal) {
			O7C_ASSIGN(&(e), (&(Ast_ExprRealNew((*p).s.real, (*p).module, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd))->_._._));
		} else {
			O7C_ASSIGN(&(e), (&(Ast_ExprIntegerNew((*p).s.integer))->_._._));
		}
		Scan(&(*p), p_tag);
	} else if ((o7c_cmp((*p).l, Scanner_True_cnst) ==  0) || (o7c_cmp((*p).l, Scanner_False_cnst) ==  0)) {
		O7C_ASSIGN(&(e), (&(Ast_ExprBooleanNew(o7c_cmp((*p).l, Scanner_True_cnst) ==  0))->_._));
		Scan(&(*p), p_tag);
	} else if (o7c_cmp((*p).l, Scanner_Nil_cnst) ==  0) {
		O7C_ASSIGN(&(e), (&(Ast_ExprNilNew())->_._));
		Scan(&(*p), p_tag);
	} else if (o7c_cmp((*p).l, Scanner_String_cnst) ==  0) {
		O7C_ASSIGN(&(e), (&(Ast_ExprStringNew((*p).module, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd))->_._._._));
		if ((e != NULL) && o7c_bl((*p).s.isChar)) {
			O7C_GUARD(Ast_ExprString_s, &e)->_.int_ = (*p).s.integer;
		}
		Scan(&(*p), p_tag);
	} else if (o7c_cmp((*p).l, Scanner_Brace1Open_cnst) ==  0) {
		Scan(&(*p), p_tag);
		O7C_ASSIGN(&(e), (&(Ast_ExprBracesNew(expression(&(*p), p_tag, ds)))->_._));
		Expect(&(*p), p_tag, Scanner_Brace1Close_cnst, Parser_ErrExpectBrace1Close_cnst);
	} else if (o7c_cmp((*p).l, Scanner_Ident_cnst) ==  0) {
		Factor_Ident(&(*p), p_tag, ds, &e);
	} else if (o7c_cmp((*p).l, Scanner_Brace3Open_cnst) ==  0) {
		O7C_ASSIGN(&(e), (&(Set(&(*p), p_tag, ds))->_._));
	} else if (o7c_cmp((*p).l, Scanner_Negate_cnst) ==  0) {
		O7C_ASSIGN(&(e), (&(Negate(&(*p), p_tag, ds))->_._));
	} else {
		AddError(&(*p), p_tag, Parser_ErrExpectExpression_cnst);
		O7C_ASSIGN(&(e), NULL);
	}
	O7C_ASSIGN(&o7c_return, e);
	o7c_release(e);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static struct Ast_RExpression *Term(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_Expression o7c_return = NULL;

	struct Ast_RExpression *e = NULL;
	Ast_ExprTerm term = NULL;
	int l = O7C_INT_UNDEF;

	o7c_retain(ds);
	Log_StrLn("Term", 5);
	O7C_ASSIGN(&(e), Factor(&(*p), p_tag, ds));
	if ((o7c_cmp((*p).l, Scanner_MultFirst_cnst) >=  0) && (o7c_cmp((*p).l, Scanner_MultLast_cnst) <=  0)) {
		l = (*p).l;
		Scan(&(*p), p_tag);
		O7C_ASSIGN(&(term), NULL);
		CheckAst(&(*p), p_tag, Ast_ExprTermNew(&term, O7C_GUARD(Ast_RFactor, &e), l, Factor(&(*p), p_tag, ds)));
		assert((term->expr != NULL) && (term->factor != NULL));
		O7C_ASSIGN(&(e), (&(term)->_));
		while ((o7c_cmp((*p).l, Scanner_MultFirst_cnst) >=  0) && (o7c_cmp((*p).l, Scanner_MultLast_cnst) <=  0)) {
			l = (*p).l;
			Scan(&(*p), p_tag);
			CheckAst(&(*p), p_tag, Ast_ExprTermAdd(e, &term, l, Factor(&(*p), p_tag, ds)));
		}
	}
	O7C_ASSIGN(&o7c_return, e);
	o7c_release(e); o7c_release(term);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static struct Ast_RExpression *Sum(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_Expression o7c_return = NULL;

	struct Ast_RExpression *e = NULL;
	Ast_ExprSum sum = NULL;
	int l = O7C_INT_UNDEF;

	o7c_retain(ds);
	Log_StrLn("Sum", 4);
	l = (*p).l;
	if ((o7c_cmp(l, Scanner_Minus_cnst) ==  0) || (o7c_cmp(l, Scanner_Plus_cnst) ==  0)) {
		Scan(&(*p), p_tag);
		CheckAst(&(*p), p_tag, Ast_ExprSumNew(&sum, l, Term(&(*p), p_tag, ds)));
		O7C_ASSIGN(&(e), (&(sum)->_));
	} else {
		O7C_ASSIGN(&(e), Term(&(*p), p_tag, ds));
		if ((o7c_cmp((*p).l, Scanner_Minus_cnst) ==  0) || (o7c_cmp((*p).l, Scanner_Plus_cnst) ==  0) || (o7c_cmp((*p).l, Scanner_Or_cnst) ==  0)) {
			CheckAst(&(*p), p_tag, Ast_ExprSumNew(&sum,  - 1, e));
			O7C_ASSIGN(&(e), (&(sum)->_));
		}
	}
	while ((o7c_cmp((*p).l, Scanner_Minus_cnst) ==  0) || (o7c_cmp((*p).l, Scanner_Plus_cnst) ==  0) || (o7c_cmp((*p).l, Scanner_Or_cnst) ==  0)) {
		l = (*p).l;
		Scan(&(*p), p_tag);
		CheckAst(&(*p), p_tag, Ast_ExprSumAdd(e, &sum, l, Term(&(*p), p_tag, ds)));
	}
	O7C_ASSIGN(&o7c_return, e);
	o7c_release(e); o7c_release(sum);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static struct Ast_RExpression *Expression(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_Expression o7c_return = NULL;

	struct Ast_RExpression *expr = NULL;
	Ast_ExprRelation e = NULL;
	Ast_ExprIsExtension isExt = NULL;
	int rel = O7C_INT_UNDEF;

	o7c_retain(ds);
	Log_StrLn("Expression", 11);
	O7C_ASSIGN(&(expr), Sum(&(*p), p_tag, ds));
	if ((o7c_cmp((*p).l, Scanner_RelationFirst_cnst) >=  0) && (o7c_cmp((*p).l, Scanner_RelationLast_cnst) <  0)) {
		rel = (*p).l;
		Scan(&(*p), p_tag);
		CheckAst(&(*p), p_tag, Ast_ExprRelationNew(&e, expr, rel, Sum(&(*p), p_tag, ds)));
		O7C_ASSIGN(&(expr), (&(e)->_));
	} else if (ScanIfEqual(&(*p), p_tag, Scanner_Is_cnst)) {
		CheckAst(&(*p), p_tag, Ast_ExprIsExtensionNew(&isExt, &expr, type(&(*p), p_tag, ds,  - 1,  - 1)));
		O7C_ASSIGN(&(expr), (&(isExt)->_));
	}
	O7C_ASSIGN(&o7c_return, expr);
	o7c_release(expr); o7c_release(e); o7c_release(isExt);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static void Mark(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclaration *d) {
	o7c_retain(d);
	d->mark = ScanIfEqual(&(*p), p_tag, Scanner_Asterisk_cnst);
	o7c_release(d);
}

static void Consts(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	int begin = O7C_INT_UNDEF, end = O7C_INT_UNDEF;
	struct Ast_Const_s *const_ = NULL;

	o7c_retain(ds);
	Scan(&(*p), p_tag);
	while (o7c_cmp((*p).l, Scanner_Ident_cnst) ==  0) {
		if (!(*p).err) {
			ExpectIdent(&(*p), p_tag, &begin, &end, Parser_ErrExpectConstName_cnst);
			CheckAst(&(*p), p_tag, Ast_ConstAdd(ds, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, begin, end));
			O7C_ASSIGN(&(const_), O7C_GUARD(Ast_Const_s, &ds->end));
			Mark(&(*p), p_tag, &const_->_);
			Expect(&(*p), p_tag, Scanner_Equal_cnst, Parser_ErrExpectEqual_cnst);
			CheckAst(&(*p), p_tag, Ast_ConstSetExpression(const_, Expression(&(*p), p_tag, ds)));
			Expect(&(*p), p_tag, Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
		}
		if ((*p).err) {
			while ((o7c_cmp((*p).l, Scanner_Import_cnst) <  0) && (o7c_cmp((*p).l, Scanner_Semicolon_cnst) !=  0)) {
				Scan(&(*p), p_tag);
			}
			(*p).err = false;
		}
	}
	o7c_release(const_);
	o7c_release(ds);
}

static int ExprToArrayLen(struct Parser *p, o7c_tag_t p_tag, struct Ast_RExpression *e) {
	int o7c_return;

	int i = O7C_INT_UNDEF;

	o7c_retain(e);
	if ((e != NULL) && (e->value_ != NULL) && (o7c_is(NULL, e->value_, Ast_RExprInteger_tag))) {
		i = O7C_GUARD(Ast_RExprInteger, &e->value_)->int_;
		if (o7c_cmp(i, 0) <=  0) {
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
	o7c_return = i;
	o7c_release(e);
	return o7c_return;
}

static int ExprToInteger(struct Parser *p, o7c_tag_t p_tag, struct Ast_RExpression *e) {
	int o7c_return;

	int i = O7C_INT_UNDEF;

	o7c_retain(e);
	if ((e != NULL) && (o7c_cmp(e->type->_._.id, Ast_IdInteger_cnst) ==  0)) {
		i = O7C_GUARD(Ast_RExprInteger, &e)->int_;
	} else {
		i = 0;
		if (e != NULL) {
			AddError(&(*p), p_tag, Parser_ErrExpectConstIntExpr_cnst);
		}
	}
	o7c_return = i;
	o7c_release(e);
	return o7c_return;
}

static struct Ast_RArray *Array(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, int nameBegin, int nameEnd) {
	Ast_Array o7c_return = NULL;

	struct Ast_RArray *a = NULL;
	struct Ast_RType *t = NULL;
	struct Ast_RExpression *exprLen = NULL;
	struct Ast_RExpression *lens[16] /* init array */;
	int i = O7C_INT_UNDEF, size = O7C_INT_UNDEF;
	memset(&lens, 0, sizeof(lens));

	o7c_retain(ds);
	Log_StrLn("Array", 6);
	assert(o7c_cmp((*p).l, Scanner_Array_cnst) ==  0);
	Scan(&(*p), p_tag);
	O7C_ASSIGN(&(a), Ast_ArrayGet(NULL, Expression(&(*p), p_tag, ds)));
	if (o7c_cmp(nameBegin, 0) >=  0) {
		O7C_ASSIGN(&(t), (&(a)->_._));
		CheckAst(&(*p), p_tag, Ast_TypeAdd(ds, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, nameBegin, nameEnd, &t));
	}
	size = ExprToArrayLen(&(*p), p_tag, a->count);
	i = 0;
	while (ScanIfEqual(&(*p), p_tag, Scanner_Comma_cnst)) {
		O7C_ASSIGN(&(exprLen), Expression(&(*p), p_tag, ds));
		size = o7c_mul(size, ExprToArrayLen(&(*p), p_tag, exprLen));
		if (o7c_cmp(i, sizeof(lens) / sizeof (lens[0])) <  0) {
			O7C_ASSIGN(&(lens[o7c_ind(16, i)]), exprLen);
		}
		i = o7c_add(i, 1);;
	}
	if (o7c_cmp(i, sizeof(lens) / sizeof (lens[0])) >  0) {
		AddError(&(*p), p_tag, Parser_ErrArrayDimensionsTooMany_cnst);
	}
	Expect(&(*p), p_tag, Scanner_Of_cnst, Parser_ErrExpectOf_cnst);
	O7C_ASSIGN(&(a->_._._.type), type(&(*p), p_tag, ds,  - 1,  - 1));
	while (o7c_cmp(i, 0) >  0) {
		i = o7c_sub(i, 1);;
		O7C_ASSIGN(&(a->_._._.type), (&(Ast_ArrayGet(a->_._._.type, lens[o7c_ind(16, i)]))->_._));
	}
	O7C_ASSIGN(&o7c_return, a);
	o7c_release(a); o7c_release(t); o7c_release(exprLen);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static struct Ast_RType *TypeNamed(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_Type o7c_return = NULL;

	struct Ast_RDeclaration *d = NULL;
	struct Ast_RType *t = NULL;

	o7c_retain(ds);
	O7C_ASSIGN(&(t), NULL);
	O7C_ASSIGN(&(d), Qualident(&(*p), p_tag, ds));
	if (d != NULL) {
		if (o7c_is(NULL, d, Ast_RType_tag)) {
			O7C_ASSIGN(&(t), O7C_GUARD(Ast_RType, &d));
		} else if (o7c_cmp(d->_.id, Ast_IdError_cnst) !=  0) {
			AddError(&(*p), p_tag, Parser_ErrExpectType_cnst);
		}
	}
	O7C_ASSIGN(&o7c_return, t);
	o7c_release(d); o7c_release(t);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static void VarDeclaration(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *dsAdd, struct Ast_RDeclarations *dsTypes);
static void VarDeclaration_Name(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	int begin = O7C_INT_UNDEF, end = O7C_INT_UNDEF;

	o7c_retain(ds);
	ExpectIdent(&(*p), p_tag, &begin, &end, Parser_ErrExpectIdent_cnst);
	CheckAst(&(*p), p_tag, Ast_VarAdd(ds, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, begin, end));
	Mark(&(*p), p_tag, ds->end);
	o7c_release(ds);
}

static void VarDeclaration(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *dsAdd, struct Ast_RDeclarations *dsTypes) {
	struct Ast_RDeclaration *var_ = NULL;
	struct Ast_RType *typ = NULL;

	o7c_retain(dsAdd); o7c_retain(dsTypes);
	VarDeclaration_Name(&(*p), p_tag, dsAdd);
	O7C_ASSIGN(&(var_), (&(O7C_GUARD(Ast_RVar, &dsAdd->end))->_));
	while (ScanIfEqual(&(*p), p_tag, Scanner_Comma_cnst)) {
		VarDeclaration_Name(&(*p), p_tag, dsAdd);
	}
	Expect(&(*p), p_tag, Scanner_Colon_cnst, Parser_ErrExpectColon_cnst);
	O7C_ASSIGN(&(typ), type(&(*p), p_tag, dsTypes,  - 1,  - 1));
	while (var_ != NULL) {
		O7C_ASSIGN(&(var_->type), typ);
		O7C_ASSIGN(&(var_), var_->next);
	}
	o7c_release(var_); o7c_release(typ);
	o7c_release(dsAdd); o7c_release(dsTypes);
}

static void Vars(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	o7c_retain(ds);
	while (o7c_cmp((*p).l, Scanner_Ident_cnst) ==  0) {
		VarDeclaration(&(*p), p_tag, ds, ds);
		Expect(&(*p), p_tag, Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
	}
	o7c_release(ds);
}

static Ast_Record Record(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, int nameBegin, int nameEnd);
static void Record_Vars(struct Parser *p, o7c_tag_t p_tag, Ast_Record dsAdd, struct Ast_RDeclarations *dsTypes);
static void Vars_Record_Declaration(struct Parser *p, o7c_tag_t p_tag, Ast_Record dsAdd, struct Ast_RDeclarations *dsTypes);
static void Declaration_Vars_Record_Name(struct Ast_RVar **v, struct Parser *p, o7c_tag_t p_tag, Ast_Record ds) {
	int begin = O7C_INT_UNDEF, end = O7C_INT_UNDEF;

	o7c_retain(ds);
	ExpectIdent(&(*p), p_tag, &begin, &end, Parser_ErrExpectIdent_cnst);
	CheckAst(&(*p), p_tag, Ast_RecordVarAdd(&(*v), ds, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, begin, end));
	Mark(&(*p), p_tag, &(*v)->_);
	o7c_release(ds);
}

static void Vars_Record_Declaration(struct Parser *p, o7c_tag_t p_tag, Ast_Record dsAdd, struct Ast_RDeclarations *dsTypes) {
	struct Ast_RVar *var_ = NULL;
	struct Ast_RDeclaration *d = NULL;
	struct Ast_RType *typ = NULL;

	o7c_retain(dsAdd); o7c_retain(dsTypes);
	Declaration_Vars_Record_Name(&var_, &(*p), p_tag, dsAdd);
	O7C_ASSIGN(&(d), (&(var_)->_));
	while (ScanIfEqual(&(*p), p_tag, Scanner_Comma_cnst)) {
		Declaration_Vars_Record_Name(&var_, &(*p), p_tag, dsAdd);
	}
	Expect(&(*p), p_tag, Scanner_Colon_cnst, Parser_ErrExpectColon_cnst);
	O7C_ASSIGN(&(typ), type(&(*p), p_tag, dsTypes,  - 1,  - 1));
	while (d != NULL) {
		O7C_ASSIGN(&(d->type), typ);
		O7C_ASSIGN(&(d), d->next);
	}
	o7c_release(var_); o7c_release(d); o7c_release(typ);
	o7c_release(dsAdd); o7c_release(dsTypes);
}

static void Record_Vars(struct Parser *p, o7c_tag_t p_tag, Ast_Record dsAdd, struct Ast_RDeclarations *dsTypes) {
	o7c_retain(dsAdd); o7c_retain(dsTypes);
	if (o7c_cmp((*p).l, Scanner_Ident_cnst) ==  0) {
		Vars_Record_Declaration(&(*p), p_tag, dsAdd, dsTypes);
		while (ScanIfEqual(&(*p), p_tag, Scanner_Semicolon_cnst)) {
			if (o7c_cmp((*p).l, Scanner_End_cnst) !=  0) {
				Vars_Record_Declaration(&(*p), p_tag, dsAdd, dsTypes);
			} else if ((*p).settings.strictSemicolon) {
				AddError(&(*p), p_tag, Parser_ErrExcessSemicolon_cnst);
				(*p).err = false;
			}
		}
	}
	o7c_release(dsAdd); o7c_release(dsTypes);
}

static Ast_Record Record(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, int nameBegin, int nameEnd) {
	Ast_Record o7c_return = NULL;

	Ast_Record rec = NULL, base = NULL;
	struct Ast_RType *t = NULL;
	struct Ast_RDeclaration *decl = NULL;

	o7c_retain(ds);
	assert(o7c_cmp((*p).l, Scanner_Record_cnst) ==  0);
	Scan(&(*p), p_tag);
	O7C_ASSIGN(&(base), NULL);
	if (ScanIfEqual(&(*p), p_tag, Scanner_Brace1Open_cnst)) {
		O7C_ASSIGN(&(decl), Qualident(&(*p), p_tag, ds));
		if ((decl != NULL) && (o7c_cmp(decl->_.id, Ast_IdRecord_cnst) ==  0)) {
			O7C_ASSIGN(&(base), O7C_GUARD(Ast_Record_s, &decl));
		} else {
			AddError(&(*p), p_tag, Parser_ErrExpectRecord_cnst);
		}
		Expect(&(*p), p_tag, Scanner_Brace1Close_cnst, Parser_ErrExpectBrace1Close_cnst);
	}
	O7C_ASSIGN(&(rec), Ast_RecordNew(ds, base));
	if (o7c_cmp(nameBegin, 0) >=  0) {
		O7C_ASSIGN(&(t), (&(rec)->_._));
		CheckAst(&(*p), p_tag, Ast_TypeAdd(ds, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, nameBegin, nameEnd, &t));
		if (&rec->_._ != t) {
			O7C_ASSIGN(&(rec), O7C_GUARD(Ast_Record_s, &t));
			Ast_RecordSetBase(rec, base);
		}
	} else {
		O7C_ASSIGN(&(rec->_._._.name.block), NULL);
		O7C_ASSIGN(&(rec->_._._.module), (*p).module);
	}
	Record_Vars(&(*p), p_tag, rec, ds);
	Expect(&(*p), p_tag, Scanner_End_cnst, Parser_ErrExpectEnd_cnst);
	O7C_ASSIGN(&o7c_return, rec);
	o7c_release(rec); o7c_release(base); o7c_release(t); o7c_release(decl);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static struct Ast_RPointer *Pointer(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, int nameBegin, int nameEnd) {
	Ast_Pointer o7c_return = NULL;

	struct Ast_RPointer *tp = NULL;
	struct Ast_RType *t = NULL;
	struct Ast_RDeclaration *decl = NULL;
	struct Ast_RType *typeDecl = NULL;

	o7c_retain(ds);
	assert(o7c_cmp((*p).l, Scanner_Pointer_cnst) ==  0);
	Scan(&(*p), p_tag);
	O7C_ASSIGN(&(tp), Ast_PointerGet(NULL));
	if (o7c_cmp(nameBegin, 0) >=  0) {
		O7C_ASSIGN(&(t), (&(tp)->_._));
		assert(t != NULL);
		CheckAst(&(*p), p_tag, Ast_TypeAdd(ds, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, nameBegin, nameEnd, &t));
	}
	Expect(&(*p), p_tag, Scanner_To_cnst, Parser_ErrExpectTo_cnst);
	if (o7c_cmp((*p).l, Scanner_Record_cnst) ==  0) {
		O7C_ASSIGN(&(tp->_._._.type), (&(Record(&(*p), p_tag, ds,  - 1,  - 1))->_._));
		if (tp->_._._.type != NULL) {
			O7C_ASSIGN(&(O7C_GUARD(Ast_Record_s, &tp->_._._.type)->pointer), tp);
		}
	} else if (o7c_cmp((*p).l, Scanner_Ident_cnst) ==  0) {
		O7C_ASSIGN(&(decl), Ast_DeclarationSearch(ds, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd));
		if (decl == NULL) {
			O7C_ASSIGN(&(typeDecl), (&(Ast_RecordNew(ds, NULL))->_._));
			CheckAst(&(*p), p_tag, Ast_TypeAdd(ds, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd, &typeDecl));
			assert(tp->_._._.next == &typeDecl->_);
			typeDecl->_._.id = Ast_IdRecordForward_cnst;
			O7C_ASSIGN(&(tp->_._._.type), typeDecl);
			O7C_ASSIGN(&(O7C_GUARD(Ast_Record_s, &typeDecl)->pointer), tp);
		} else if (o7c_is(NULL, decl, Ast_Record_s_tag)) {
			O7C_ASSIGN(&(tp->_._._.type), (&(O7C_GUARD(Ast_Record_s, &decl))->_._));
			O7C_ASSIGN(&(O7C_GUARD(Ast_Record_s, &decl)->pointer), tp);
		} else {
			O7C_ASSIGN(&(tp->_._._.type), TypeNamed(&(*p), p_tag, ds));
			if (tp->_._._.type != NULL) {
				if (o7c_is(NULL, tp->_._._.type, Ast_Record_s_tag)) {
					O7C_ASSIGN(&(O7C_GUARD(Ast_Record_s, &tp->_._._.type)->pointer), tp);
				} else {
					AddError(&(*p), p_tag, Parser_ErrExpectRecord_cnst);
				}
			}
		}
		Scan(&(*p), p_tag);
	} else {
		AddError(&(*p), p_tag, Parser_ErrExpectRecord_cnst);
	}
	O7C_ASSIGN(&o7c_return, tp);
	o7c_release(tp); o7c_release(t); o7c_release(decl); o7c_release(typeDecl);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static void FormalParameters(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, struct Ast_ProcType_s *proc);
static void FormalParameters_Section(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, struct Ast_ProcType_s *proc);
static void Section_FormalParameters_Name(struct Parser *p, o7c_tag_t p_tag, struct Ast_ProcType_s *proc) {
	o7c_retain(proc);
	if (o7c_cmp((*p).l, Scanner_Ident_cnst) !=  0) {
		AddError(&(*p), p_tag, Parser_ErrExpectIdent_cnst);
	} else {
		CheckAst(&(*p), p_tag, Ast_ParamAdd((*p).module, proc, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd));
		Scan(&(*p), p_tag);
	}
	o7c_release(proc);
}

static struct Ast_RType *Section_FormalParameters_Type(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_Type o7c_return = NULL;

	struct Ast_RType *t = NULL;
	int arrs = O7C_INT_UNDEF;

	o7c_retain(ds);
	arrs = 0;
	while (ScanIfEqual(&(*p), p_tag, Scanner_Array_cnst)) {
		Expect(&(*p), p_tag, Scanner_Of_cnst, Parser_ErrExpectOf_cnst);
		arrs = o7c_add(arrs, 1);;
	}
	O7C_ASSIGN(&(t), TypeNamed(&(*p), p_tag, ds));
	while ((t != NULL) && (o7c_cmp(arrs, 0) >  0)) {
		O7C_ASSIGN(&(t), (&(Ast_ArrayGet(t, NULL))->_._));
		arrs = o7c_sub(arrs, 1);;
	}
	O7C_ASSIGN(&o7c_return, t);
	o7c_release(t);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static void FormalParameters_Section(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, struct Ast_ProcType_s *proc) {
	o7c_bool isVar = O7C_BOOL_UNDEF;
	struct Ast_RDeclaration *param = NULL;
	struct Ast_RType *type = NULL;

	o7c_retain(ds); o7c_retain(proc);
	isVar = ScanIfEqual(&(*p), p_tag, Scanner_Var_cnst);
	Section_FormalParameters_Name(&(*p), p_tag, proc);
	O7C_ASSIGN(&(param), (&(proc->end)->_._));
	while (ScanIfEqual(&(*p), p_tag, Scanner_Comma_cnst)) {
		Section_FormalParameters_Name(&(*p), p_tag, proc);
	}
	Expect(&(*p), p_tag, Scanner_Colon_cnst, Parser_ErrExpectColon_cnst);
	O7C_ASSIGN(&(type), Section_FormalParameters_Type(&(*p), p_tag, ds));
	while (param != NULL) {
		O7C_GUARD(Ast_FormalParam_s, &param)->isVar = isVar;
		O7C_ASSIGN(&(param->type), type);
		O7C_ASSIGN(&(param), param->next);
	}
	o7c_release(param); o7c_release(type);
	o7c_release(ds); o7c_release(proc);
}

static void FormalParameters(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, struct Ast_ProcType_s *proc) {
	o7c_bool braces = O7C_BOOL_UNDEF;

	o7c_retain(ds); o7c_retain(proc);
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
		O7C_ASSIGN(&(proc->_._._.type), TypeNamed(&(*p), p_tag, ds));
	}
	o7c_release(ds); o7c_release(proc);
}

static struct Ast_ProcType_s *TypeProcedure(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, int nameBegin, int nameEnd) {
	Ast_ProcType o7c_return = NULL;

	struct Ast_ProcType_s *proc = NULL;
	struct Ast_RType *t = NULL;

	o7c_retain(ds);
	assert(o7c_cmp((*p).l, Scanner_Procedure_cnst) ==  0);
	Scan(&(*p), p_tag);
	O7C_ASSIGN(&(proc), Ast_ProcTypeNew());
	if (o7c_cmp(nameBegin, 0) >=  0) {
		O7C_ASSIGN(&(t), (&(proc)->_._));
		CheckAst(&(*p), p_tag, Ast_TypeAdd(ds, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, nameBegin, nameEnd, &t));
	}
	FormalParameters(&(*p), p_tag, ds, proc);
	O7C_ASSIGN(&o7c_return, proc);
	o7c_release(proc); o7c_release(t);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static struct Ast_RType *Type(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, int nameBegin, int nameEnd) {
	Ast_Type o7c_return = NULL;

	struct Ast_RType *t = NULL;

	o7c_retain(ds);
	if (o7c_cmp((*p).l, Scanner_Array_cnst) ==  0) {
		O7C_ASSIGN(&(t), (&(Array(&(*p), p_tag, ds, nameBegin, nameEnd))->_._));
	} else if (o7c_cmp((*p).l, Scanner_Pointer_cnst) ==  0) {
		O7C_ASSIGN(&(t), (&(Pointer(&(*p), p_tag, ds, nameBegin, nameEnd))->_._));
	} else if (o7c_cmp((*p).l, Scanner_Procedure_cnst) ==  0) {
		O7C_ASSIGN(&(t), (&(TypeProcedure(&(*p), p_tag, ds, nameBegin, nameEnd))->_._));
	} else if (o7c_cmp((*p).l, Scanner_Record_cnst) ==  0) {
		O7C_ASSIGN(&(t), (&(Record(&(*p), p_tag, ds, nameBegin, nameEnd))->_._));
	} else if (o7c_cmp((*p).l, Scanner_Ident_cnst) ==  0) {
		O7C_ASSIGN(&(t), TypeNamed(&(*p), p_tag, ds));
	} else {
		O7C_ASSIGN(&(t), Ast_TypeGet(Ast_IdInteger_cnst));
		AddError(&(*p), p_tag, Parser_ErrExpectType_cnst);
	}
	O7C_ASSIGN(&o7c_return, t);
	o7c_release(t);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static void Types(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	struct Ast_RType *type = NULL;
	int begin = O7C_INT_UNDEF, end = O7C_INT_UNDEF;
	o7c_bool mark = O7C_BOOL_UNDEF;

	o7c_retain(ds);
	Scan(&(*p), p_tag);
	while (o7c_cmp((*p).l, Scanner_Ident_cnst) ==  0) {
		begin = (*p).s.lexStart;
		end = (*p).s.lexEnd;
		Scan(&(*p), p_tag);
		mark = ScanIfEqual(&(*p), p_tag, Scanner_Asterisk_cnst);
		Expect(&(*p), p_tag, Scanner_Equal_cnst, Parser_ErrExpectEqual_cnst);
		O7C_ASSIGN(&(type), Type(&(*p), p_tag, ds, begin, end));
		if (type != NULL) {
			type->_.mark = mark;
			if (!(o7c_is(NULL, type, Ast_RConstruct_tag))) {
				AddError(&(*p), p_tag, Parser_ErrExpectStructuredType_cnst);
			}
		}
		Expect(&(*p), p_tag, Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
	}
	o7c_release(type);
	o7c_release(ds);
}

static Ast_If If(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds);
static Ast_If If_Branch(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_If o7c_return = NULL;

	Ast_If if_ = NULL;

	o7c_retain(ds);
	Scan(&(*p), p_tag);
	CheckAst(&(*p), p_tag, Ast_IfNew(&if_, Expression(&(*p), p_tag, ds), NULL));
	Expect(&(*p), p_tag, Scanner_Then_cnst, Parser_ErrExpectThen_cnst);
	O7C_ASSIGN(&(if_->_.stats), statements(&(*p), p_tag, ds));
	O7C_ASSIGN(&o7c_return, if_);
	o7c_release(if_);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static Ast_If If(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_If o7c_return = NULL;

	Ast_If if_ = NULL, else_ = NULL;
	struct Ast_RWhileIf *elsif = NULL;

	o7c_retain(ds);
	assert(o7c_cmp((*p).l, Scanner_If_cnst) ==  0);
	O7C_ASSIGN(&(if_), If_Branch(&(*p), p_tag, ds));
	O7C_ASSIGN(&(elsif), (&(if_)->_));
	while (o7c_cmp((*p).l, Scanner_Elsif_cnst) ==  0) {
		O7C_ASSIGN(&(elsif->elsif), (&(If_Branch(&(*p), p_tag, ds))->_));
		O7C_ASSIGN(&(elsif), elsif->elsif);
	}
	if (ScanIfEqual(&(*p), p_tag, Scanner_Else_cnst)) {
		CheckAst(&(*p), p_tag, Ast_IfNew(&else_, NULL, statements(&(*p), p_tag, ds)));
		O7C_ASSIGN(&(elsif->elsif), (&(else_)->_));
	}
	Expect(&(*p), p_tag, Scanner_End_cnst, Parser_ErrExpectEnd_cnst);
	O7C_ASSIGN(&o7c_return, if_);
	o7c_release(if_); o7c_release(else_); o7c_release(elsif);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static Ast_Case Case(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds);
static void Case_Element(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, Ast_Case case_);
static Ast_CaseLabel Element_Case_LabelList(struct Parser *p, o7c_tag_t p_tag, Ast_Case case_, struct Ast_RDeclarations *ds);
static Ast_CaseLabel LabelList_Element_Case_LabelRange(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds);
static Ast_CaseLabel LabelRange_LabelList_Element_Case_Label(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_CaseLabel o7c_return = NULL;

	int err = O7C_INT_UNDEF;
	Ast_CaseLabel l = NULL;
	o7c_bool qual = O7C_BOOL_UNDEF;

	o7c_retain(ds);
	qual = false;
	if ((o7c_cmp((*p).l, Scanner_Number_cnst) ==  0) && !(*p).s.isReal) {
		err = Ast_CaseLabelNew(&l, Ast_IdInteger_cnst, (*p).s.integer);
	} else if (o7c_cmp((*p).l, Scanner_String_cnst) ==  0) {
		assert(o7c_bl((*p).s.isChar));
		err = Ast_CaseLabelNew(&l, Ast_IdChar_cnst, (*p).s.integer);
	} else if (o7c_cmp((*p).l, Scanner_Ident_cnst) ==  0) {
		qual = true;
		err = Ast_CaseLabelQualNew(&l, Qualident(&(*p), p_tag, ds));
	} else {
		err = Parser_ErrExpectIntOrStrOrQualident_cnst;
	}
	CheckAst(&(*p), p_tag, err);
	if (!o7c_bl(qual) && (o7c_cmp(err, Parser_ErrExpectIntOrStrOrQualident_cnst) !=  0)) {
		Scan(&(*p), p_tag);
	}
	O7C_ASSIGN(&o7c_return, l);
	o7c_release(l);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static Ast_CaseLabel LabelList_Element_Case_LabelRange(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_CaseLabel o7c_return = NULL;

	Ast_CaseLabel r = NULL;

	o7c_retain(ds);
	O7C_ASSIGN(&(r), LabelRange_LabelList_Element_Case_Label(&(*p), p_tag, ds));
	if (o7c_cmp((*p).l, Scanner_Range_cnst) ==  0) {
		Scan(&(*p), p_tag);
		CheckAst(&(*p), p_tag, Ast_CaseRangeNew(r, LabelRange_LabelList_Element_Case_Label(&(*p), p_tag, ds)));
	}
	O7C_ASSIGN(&o7c_return, r);
	o7c_release(r);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static Ast_CaseLabel Element_Case_LabelList(struct Parser *p, o7c_tag_t p_tag, Ast_Case case_, struct Ast_RDeclarations *ds) {
	Ast_CaseLabel o7c_return = NULL;

	Ast_CaseLabel first = NULL, last = NULL;

	o7c_retain(case_); o7c_retain(ds);
	O7C_ASSIGN(&(first), LabelList_Element_Case_LabelRange(&(*p), p_tag, ds));
	while (o7c_cmp((*p).l, Scanner_Comma_cnst) ==  0) {
		Scan(&(*p), p_tag);
		O7C_ASSIGN(&(last), LabelList_Element_Case_LabelRange(&(*p), p_tag, ds));
		CheckAst(&(*p), p_tag, Ast_CaseRangeListAdd(case_, first, last));
	}
	O7C_ASSIGN(&o7c_return, first);
	o7c_release(first); o7c_release(last);
	o7c_release(case_); o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static void Case_Element(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, Ast_Case case_) {
	Ast_CaseElement elem = NULL;

	o7c_retain(ds); o7c_retain(case_);
	O7C_ASSIGN(&(elem), Ast_CaseElementNew(Element_Case_LabelList(&(*p), p_tag, case_, ds)));
	Expect(&(*p), p_tag, Scanner_Colon_cnst, Parser_ErrExpectColon_cnst);
	O7C_ASSIGN(&(elem->stats), statements(&(*p), p_tag, ds));
	CheckAst(&(*p), p_tag, Ast_CaseElementAdd(case_, elem));
	o7c_release(elem);
	o7c_release(ds); o7c_release(case_);
}

static Ast_Case Case(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_Case o7c_return = NULL;

	Ast_Case case_ = NULL;

	o7c_retain(ds);
	assert(o7c_cmp((*p).l, Scanner_Case_cnst) ==  0);
	Scan(&(*p), p_tag);
	CheckAst(&(*p), p_tag, Ast_CaseNew(&case_, Expression(&(*p), p_tag, ds)));
	Expect(&(*p), p_tag, Scanner_Of_cnst, Parser_ErrExpectOf_cnst);
	Case_Element(&(*p), p_tag, ds, case_);
	while (ScanIfEqual(&(*p), p_tag, Scanner_Alternative_cnst)) {
		Case_Element(&(*p), p_tag, ds, case_);
	}
	Expect(&(*p), p_tag, Scanner_End_cnst, Parser_ErrExpectEnd_cnst);
	O7C_ASSIGN(&o7c_return, case_);
	o7c_release(case_);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static Ast_Repeat Repeat(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_Repeat o7c_return = NULL;

	Ast_Repeat r = NULL;

	o7c_retain(ds);
	assert(o7c_cmp((*p).l, Scanner_Repeat_cnst) ==  0);
	Scan(&(*p), p_tag);
	CheckAst(&(*p), p_tag, Ast_RepeatNew(&r, statements(&(*p), p_tag, ds)));
	Expect(&(*p), p_tag, Scanner_Until_cnst, Parser_ErrExpectUntil_cnst);
	CheckAst(&(*p), p_tag, Ast_RepeatSetUntil(r, Expression(&(*p), p_tag, ds)));
	O7C_ASSIGN(&o7c_return, r);
	o7c_release(r);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static Ast_For For(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_For o7c_return = NULL;

	Ast_For f = NULL;
	struct Ast_RVar *v = NULL;

	o7c_retain(ds);
	assert(o7c_cmp((*p).l, Scanner_For_cnst) ==  0);
	Scan(&(*p), p_tag);
	if (o7c_cmp((*p).l, Scanner_Ident_cnst) !=  0) {
		AddError(&(*p), p_tag, o7c_add(Parser_ErrExpectIdent_cnst, o7c_mul(Ast_ForIteratorGet(&v, ds, "FORITERATOR", 12, 0, 10), 0)));
	} else {
		CheckAst(&(*p), p_tag, Ast_ForIteratorGet(&v, ds, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd));
	}
	Scan(&(*p), p_tag);
	Expect(&(*p), p_tag, Scanner_Assign_cnst, Parser_ErrExpectAssign_cnst);
	O7C_ASSIGN(&(f), Ast_ForNew(v, Expression(&(*p), p_tag, ds), NULL, 1, NULL));
	Expect(&(*p), p_tag, Scanner_To_cnst, Parser_ErrExpectTo_cnst);
	O7C_ASSIGN(&(f->to), Expression(&(*p), p_tag, ds));
	if (ScanIfEqual(&(*p), p_tag, Scanner_By_cnst)) {
		f->by = ExprToInteger(&(*p), p_tag, Expression(&(*p), p_tag, ds));
	}
	Expect(&(*p), p_tag, Scanner_Do_cnst, Parser_ErrExpectDo_cnst);
	O7C_ASSIGN(&(f->stats), statements(&(*p), p_tag, ds));
	Expect(&(*p), p_tag, Scanner_End_cnst, Parser_ErrExpectEnd_cnst);
	O7C_ASSIGN(&o7c_return, f);
	o7c_release(f); o7c_release(v);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static Ast_While While(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_While o7c_return = NULL;

	Ast_While w = NULL, br = NULL;
	struct Ast_RWhileIf *elsif = NULL;

	o7c_retain(ds);
	assert(o7c_cmp((*p).l, Scanner_While_cnst) ==  0);
	Scan(&(*p), p_tag);
	CheckAst(&(*p), p_tag, Ast_WhileNew(&w, Expression(&(*p), p_tag, ds), NULL));
	O7C_ASSIGN(&(elsif), (&(w)->_));
	Expect(&(*p), p_tag, Scanner_Do_cnst, Parser_ErrExpectDo_cnst);
	O7C_ASSIGN(&(w->_.stats), statements(&(*p), p_tag, ds));
	while (ScanIfEqual(&(*p), p_tag, Scanner_Elsif_cnst)) {
		CheckAst(&(*p), p_tag, Ast_WhileNew(&br, Expression(&(*p), p_tag, ds), NULL));
		O7C_ASSIGN(&(elsif->elsif), (&(br)->_));
		O7C_ASSIGN(&(elsif), (&(br)->_));
		Expect(&(*p), p_tag, Scanner_Do_cnst, Parser_ErrExpectDo_cnst);
		O7C_ASSIGN(&(elsif->stats), statements(&(*p), p_tag, ds));
	}
	Expect(&(*p), p_tag, Scanner_End_cnst, Parser_ErrExpectEnd_cnst);
	O7C_ASSIGN(&o7c_return, w);
	o7c_release(w); o7c_release(br); o7c_release(elsif);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static Ast_Assign Assign(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, Ast_Designator des) {
	Ast_Assign o7c_return = NULL;

	Ast_Assign st = NULL;

	o7c_retain(ds); o7c_retain(des);
	assert(o7c_cmp((*p).l, Scanner_Assign_cnst) ==  0);
	Scan(&(*p), p_tag);
	CheckAst(&(*p), p_tag, Ast_AssignNew(&st, des, Expression(&(*p), p_tag, ds)));
	O7C_ASSIGN(&o7c_return, st);
	o7c_release(st);
	o7c_release(ds); o7c_release(des);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static Ast_Call Call(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, Ast_Designator des) {
	Ast_Call o7c_return = NULL;

	Ast_Call st = NULL;

	o7c_retain(ds); o7c_retain(des);
	CheckAst(&(*p), p_tag, Ast_CallNew(&st, des));
	if (o7c_cmp((*p).l, Scanner_Brace1Open_cnst) ==  0) {
		CallParams(&(*p), p_tag, ds, O7C_GUARD(Ast_ExprCall_s, &st->_.expr));
	} else if ((des != NULL) && (des->_._.type != NULL) && (o7c_is(NULL, des->_._.type, Ast_ProcType_s_tag))) {
		CheckAst(&(*p), p_tag, Ast_CallParamsEnd(O7C_GUARD(Ast_ExprCall_s, &st->_.expr), O7C_GUARD(Ast_ProcType_s, &des->_._.type)->params));
	}
	O7C_ASSIGN(&o7c_return, st);
	o7c_release(st);
	o7c_release(ds); o7c_release(des);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static o7c_bool NotEnd(int l) {
	o7c_bool o7c_return;

	o7c_return = (o7c_cmp(l, Scanner_End_cnst) !=  0) && (o7c_cmp(l, Scanner_Return_cnst) !=  0) && (o7c_cmp(l, Scanner_Else_cnst) !=  0) && (o7c_cmp(l, Scanner_Elsif_cnst) !=  0) && (o7c_cmp(l, Scanner_Until_cnst) !=  0) && (o7c_cmp(l, Scanner_Alternative_cnst) !=  0);
	return o7c_return;
}

static struct Ast_RStatement *Statements(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds);
static struct Ast_RStatement *Statements_Statement(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_Statement o7c_return = NULL;

	Ast_Designator des = NULL;
	struct Ast_RStatement *st = NULL;

	o7c_retain(ds);
	Log_StrLn("Statement", 10);
	if (o7c_cmp((*p).l, Scanner_Ident_cnst) ==  0) {
		O7C_ASSIGN(&(des), Designator(&(*p), p_tag, ds));
		if (o7c_cmp((*p).l, Scanner_Assign_cnst) ==  0) {
			O7C_ASSIGN(&(st), (&(Assign(&(*p), p_tag, ds, des))->_));
		} else {
			O7C_ASSIGN(&(st), (&(Call(&(*p), p_tag, ds, des))->_));
		}
	} else if (o7c_cmp((*p).l, Scanner_If_cnst) ==  0) {
		O7C_ASSIGN(&(st), (&(If(&(*p), p_tag, ds))->_._));
	} else if (o7c_cmp((*p).l, Scanner_Case_cnst) ==  0) {
		O7C_ASSIGN(&(st), (&(Case(&(*p), p_tag, ds))->_));
	} else if (o7c_cmp((*p).l, Scanner_Repeat_cnst) ==  0) {
		O7C_ASSIGN(&(st), (&(Repeat(&(*p), p_tag, ds))->_));
	} else if (o7c_cmp((*p).l, Scanner_For_cnst) ==  0) {
		O7C_ASSIGN(&(st), (&(For(&(*p), p_tag, ds))->_));
	} else if (o7c_cmp((*p).l, Scanner_While_cnst) ==  0) {
		O7C_ASSIGN(&(st), (&(While(&(*p), p_tag, ds))->_._));
	} else {
		O7C_ASSIGN(&(st), NULL);
		AddError(&(*p), p_tag, Parser_ErrExpectStatement_cnst);
	}
	if (st == NULL) {
		O7C_ASSIGN(&(st), (&(Ast_StatementErrorNew())->_));
	}
	if ((*p).err) {
		Log_StrLn("Error", 6);
		while ((o7c_cmp((*p).l, Scanner_Semicolon_cnst) !=  0) && NotEnd((*p).l)) {
			Scan(&(*p), p_tag);
		}
		(*p).err = false;
	}
	O7C_ASSIGN(&o7c_return, st);
	o7c_release(des); o7c_release(st);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static struct Ast_RStatement *Statements(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	Ast_Statement o7c_return = NULL;

	struct Ast_RStatement *stats = NULL, *last = NULL;

	o7c_retain(ds);
	Log_StrLn("Statements", 11);
	O7C_ASSIGN(&(stats), Statements_Statement(&(*p), p_tag, ds));
	O7C_ASSIGN(&(last), stats);
	while (1) if (ScanIfEqual(&(*p), p_tag, Scanner_Semicolon_cnst)) {
		if (NotEnd((*p).l)) {
			O7C_ASSIGN(&(last->next), Statements_Statement(&(*p), p_tag, ds));
			O7C_ASSIGN(&(last), last->next);
		} else if ((*p).settings.strictSemicolon) {
			AddError(&(*p), p_tag, Parser_ErrExcessSemicolon_cnst);
			(*p).err = false;
		}
	} else if (NotEnd((*p).l)) {
		AddError(&(*p), p_tag, Parser_ErrExpectSemicolon_cnst);
		(*p).err = false;
		O7C_ASSIGN(&(last->next), Statements_Statement(&(*p), p_tag, ds));
		O7C_ASSIGN(&(last), last->next);
	} else break;
	O7C_ASSIGN(&o7c_return, stats);
	o7c_release(stats); o7c_release(last);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static void Return(struct Parser *p, o7c_tag_t p_tag, struct Ast_RProcedure *proc) {
	o7c_retain(proc);
	if (o7c_cmp((*p).l, Scanner_Return_cnst) ==  0) {
		Log_StrLn("Return", 7);
		Scan(&(*p), p_tag);
		CheckAst(&(*p), p_tag, Ast_ProcedureSetReturn(proc, Expression(&(*p), p_tag, &proc->_._)));
		if (o7c_cmp((*p).l, Scanner_Semicolon_cnst) ==  0) {
			if ((*p).settings.strictSemicolon) {
				AddError(&(*p), p_tag, Parser_ErrExcessSemicolon_cnst);
				(*p).err = false;
			}
			Scan(&(*p), p_tag);
		}
	} else {
		CheckAst(&(*p), p_tag, Ast_ProcedureEnd(proc));
	}
	o7c_release(proc);
}

static void ProcBody(struct Parser *p, o7c_tag_t p_tag, struct Ast_RProcedure *proc) {
	o7c_retain(proc);
	Log_StrLn("ProcBody", 9);
	declarations(&(*p), p_tag, &proc->_._);
	if (ScanIfEqual(&(*p), p_tag, Scanner_Begin_cnst)) {
		O7C_ASSIGN(&(proc->_._.stats), Statements(&(*p), p_tag, &proc->_._));
	}
	Return(&(*p), p_tag, proc);
	Expect(&(*p), p_tag, Scanner_End_cnst, Parser_ErrExpectEnd_cnst);
	if (o7c_cmp((*p).l, Scanner_Ident_cnst) ==  0) {
		Log_StrLn("End Ident", 10);
		if (!StringStore_IsEqualToChars(&proc->_._._.name, StringStore_String_tag, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd)) {
			AddError(&(*p), p_tag, Parser_ErrEndProcedureNameNotMatch_cnst);
		}
		Scan(&(*p), p_tag);
	} else {
		AddError(&(*p), p_tag, Parser_ErrExpectProcedureName_cnst);
	}
	o7c_release(proc);
}

static void Procedure(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	struct Ast_RProcedure *proc = NULL;
	int nameStart = O7C_INT_UNDEF, nameEnd = O7C_INT_UNDEF;

	o7c_retain(ds);
	Log_StrLn("Procedure", 10);
	Scan(&(*p), p_tag);
	ExpectIdent(&(*p), p_tag, &nameStart, &nameEnd, Parser_ErrExpectIdent_cnst);
	CheckAst(&(*p), p_tag, Ast_ProcedureAdd(ds, &proc, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, nameStart, nameEnd));
	Mark(&(*p), p_tag, &proc->_._._);
	FormalParameters(&(*p), p_tag, ds, proc->_.header);
	Expect(&(*p), p_tag, Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
	ProcBody(&(*p), p_tag, proc);
	o7c_release(proc);
	o7c_release(ds);
}

static void Declarations(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds) {
	o7c_retain(ds);
	if (o7c_cmp((*p).l, Scanner_Const_cnst) ==  0) {
		Consts(&(*p), p_tag, ds);
	}
	if (o7c_cmp((*p).l, Scanner_Type_cnst) ==  0) {
		Types(&(*p), p_tag, ds);
	}
	if (o7c_cmp((*p).l, Scanner_Var_cnst) ==  0) {
		Scan(&(*p), p_tag);
		Vars(&(*p), p_tag, ds);
	}
	while (o7c_cmp((*p).l, Scanner_Procedure_cnst) ==  0) {
		Procedure(&(*p), p_tag, ds);
		Expect(&(*p), p_tag, Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
	}
	o7c_release(ds);
}

static void Imports(struct Parser *p, o7c_tag_t p_tag) {
	int nameOfs = O7C_INT_UNDEF, nameEnd = O7C_INT_UNDEF, realOfs = O7C_INT_UNDEF, realEnd = O7C_INT_UNDEF;

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
			while ((o7c_cmp((*p).l, Scanner_Import_cnst) <  0) && (o7c_cmp((*p).l, Scanner_Comma_cnst) !=  0) && (o7c_cmp((*p).l, Scanner_Semicolon_cnst) !=  0)) {
				Scan(&(*p), p_tag);
			}
		}
	} while (!(o7c_cmp((*p).l, Scanner_Comma_cnst) !=  0));
	Expect(&(*p), p_tag, Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
}

static void Module(struct Parser *p, o7c_tag_t p_tag) {
	Log_StrLn("Module", 7);
	Scan(&(*p), p_tag);
	if (o7c_cmp((*p).l, Scanner_Module_cnst) !=  0) {
		(*p).l = Parser_ErrExpectModule_cnst;
	} else {
		Scan(&(*p), p_tag);
		if (o7c_cmp((*p).l, Scanner_Ident_cnst) !=  0) {
			O7C_ASSIGN(&((*p).module), Ast_ModuleNew(" ", 2, 0, 0));
			AddError(&(*p), p_tag, Parser_ErrExpectIdent_cnst);
		} else {
			O7C_ASSIGN(&((*p).module), Ast_ModuleNew((*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd));
			Scan(&(*p), p_tag);
		}
		Expect(&(*p), p_tag, Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
		if (o7c_cmp((*p).l, Scanner_Import_cnst) ==  0) {
			Imports(&(*p), p_tag);
		}
		Declarations(&(*p), p_tag, &(*p).module->_);
		if (ScanIfEqual(&(*p), p_tag, Scanner_Begin_cnst)) {
			O7C_ASSIGN(&((*p).module->_.stats), Statements(&(*p), p_tag, &(*p).module->_));
		}
		Expect(&(*p), p_tag, Scanner_End_cnst, Parser_ErrExpectEnd_cnst);
		if (o7c_cmp((*p).l, Scanner_Ident_cnst) ==  0) {
			if (!StringStore_IsEqualToChars(&(*p).module->_._.name, StringStore_String_tag, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd)) {
				AddError(&(*p), p_tag, Parser_ErrEndModuleNameNotMatch_cnst);
			}
			Scan(&(*p), p_tag);
		} else {
			AddError(&(*p), p_tag, Parser_ErrExpectModuleName_cnst);
		}
		if (o7c_cmp((*p).l, Scanner_Dot_cnst) !=  0) {
			AddError(&(*p), p_tag, Parser_ErrExpectDot_cnst);
		}
		CheckAst(&(*p), p_tag, Ast_ModuleEnd((*p).module));
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
	Ast_Module o7c_return = NULL;

	struct Parser p /* record init */;
	memset(&p, 0, sizeof(p));

	o7c_retain(in_); o7c_retain(prov);
	assert(in_ != NULL);
	assert(prov != NULL);
	V_Init(&p._, Parser_tag);
	p.settings = (*opt);
	p.err = false;
	O7C_ASSIGN(&(p.module), NULL);
	O7C_ASSIGN(&(p.provider), prov);
	Scanner_Init(&p.s, Scanner_Scanner_tag, in_);
	Module(&p, Parser_tag);
	O7C_ASSIGN(&o7c_return, p.module);
	o7c_release(in_); o7c_release(prov);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern void Parser_init(void) {
	static int initialized = 0;
	if (0 == initialized) {
		V_init();
		Log_init();
		Out_init();
		Utf8_init();
		Scanner_init();
		StringStore_init();
		Ast_init();
		VDataStream_init();

		o7c_tag_init(Parser_Options_tag, V_Base_tag);
		o7c_tag_init(Parser_tag, V_Base_tag);

		declarations = Declarations;
		type = Type;
		statements = Statements;
		expression = Expression;
	}
	++initialized;
}


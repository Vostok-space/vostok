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

static void (*declarations)(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag);
static struct Ast_RType *(*type)(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, int nameBegin, int nameEnd);
static struct Ast_RStatement *(*statements)(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag);
static struct Ast_RExpression *(*expression)(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag);

static void AddError(struct Parser *p, o7c_tag_t p_tag, int err) {
	Log_Str("AddError ", 10);
	Log_Int(err);
	Log_Str(" at ", 5);
	Log_Int((*p).s.line);
	Log_Str(":", 2);
	Log_Int((*p).s.column + (*p).s.tabs * 3);
	Log_Ln();
	(*p).err = err > Parser_ErrAstBegin_cnst;
	if ((*p).module != NULL) {
		Ast_AddError((*p).module, NULL, err, (*p).s.line, (*p).s.column, (*p).s.tabs);
	}
	(*p).settings.printError(err);
	Out_Ln();
}

static void CheckAst(struct Parser *p, o7c_tag_t p_tag, int err) {
	if (err != Ast_ErrNo_cnst) {
		assert((err < ErrNo_cnst) && (err >= Ast_ErrMin_cnst));
		AddError(&(*p), p_tag, Parser_ErrAstBegin_cnst + err);
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

static Ast_ExprSet Set(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag);
static int Set_Element(Ast_ExprSet *e, o7c_tag_t e_tag, struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	struct Ast_RExpression *left;
	int err;

	left = expression(&(*p), p_tag, ds, NULL);
	if ((*p).l == Scanner_Range_cnst) {
		Scan(&(*p), p_tag);
		err = Ast_ExprSetNew(&(*e), NULL, left, NULL, expression(&(*p), p_tag, ds, NULL), NULL);
	} else {
		err = Ast_ExprSetNew(&(*e), NULL, left, NULL, NULL, NULL);
	}
	return err;
}

static Ast_ExprSet Set(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	Ast_ExprSet e;
	Ast_ExprSet next;
	int err;

	assert((*p).l == Scanner_Brace3Open_cnst);
	Scan(&(*p), p_tag);
	if ((*p).l != Scanner_Brace3Close_cnst) {
		err = Set_Element(&e, NULL, &(*p), p_tag, ds, NULL);
		CheckAst(&(*p), p_tag, err);
		next = e;
		while (ScanIfEqual(&(*p), p_tag, Scanner_Comma_cnst)) {
			err = Set_Element(&next->next, NULL, &(*p), p_tag, ds, NULL);
			CheckAst(&(*p), p_tag, err);
			next = next->next;
		}
		Expect(&(*p), p_tag, Scanner_Brace3Close_cnst, Parser_ErrExpectBrace3Close_cnst);
	} else {
		CheckAst(&(*p), p_tag, Ast_ExprSetNew(&e, NULL, NULL, NULL, NULL, NULL));
		Scan(&(*p), p_tag);
	}
	return e;
}

static Ast_ExprNegate Negate(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	assert((*p).l == Scanner_Negate_cnst);
	Scan(&(*p), p_tag);
	return Ast_ExprNegateNew(expression(&(*p), p_tag, ds, NULL), NULL);
}

static struct Ast_RDeclaration *DeclarationGet(struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, struct Parser *p, o7c_tag_t p_tag) {
	struct Ast_RDeclaration *d;

	Log_StrLn("DeclarationGet", 15);
	CheckAst(&(*p), p_tag, Ast_DeclarationGet(&d, NULL, ds, NULL, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd));
	return d;
}

static struct Ast_RDeclaration *ExpectDecl(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	struct Ast_RDeclaration *d;

	if ((*p).l != Scanner_Ident_cnst) {
		d = NULL;
		AddError(&(*p), p_tag, Parser_ErrExpectIdent_cnst);
	} else {
		d = DeclarationGet(ds, NULL, &(*p), p_tag);
		Scan(&(*p), p_tag);
	}
	return d;
}

static struct Ast_RDeclaration *Qualident(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	struct Ast_RDeclaration *d;

	Log_StrLn("Qualident", 10);
	d = ExpectDecl(&(*p), p_tag, ds, NULL);
	if ((d != NULL) && (o7c_is(NULL, d, Ast_Import_s_tag))) {
		Expect(&(*p), p_tag, Scanner_Dot_cnst, Parser_ErrExpectDot_cnst);
		d = ExpectDecl(&(*p), p_tag, &(&O7C_GUARD(Ast_Import_s, d, NULL))->_.module->_, NULL);
	}
	return d;
}

static struct Ast_RDeclaration *ExpectRecordExtend(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, struct Ast_RConstruct *base, o7c_tag_t base_tag) {
	struct Ast_RDeclaration *d;

	d = Qualident(&(*p), p_tag, ds, NULL);
	return d;
}

static struct Ast_RVar *ExpectVar(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	struct Ast_RDeclaration *d;
	struct Ast_RVar *v;

	v = NULL;
	d = Qualident(&(*p), p_tag, ds, NULL);
	if (d != NULL) {
		if (o7c_is(NULL, d, Ast_RVar_tag)) {
			v = (&O7C_GUARD(Ast_RVar, d, NULL));
		} else {
			AddError(&(*p), p_tag, Parser_ErrExpectVar_cnst);
		}
	}
	return v;
}

static Ast_Designator Designator(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag);
static void Designator_SetSel(struct Ast_RSelector **prev, o7c_tag_t prev_tag, struct Ast_RSelector *sel, o7c_tag_t sel_tag, Ast_Designator des, o7c_tag_t des_tag) {
	if ((*prev) == NULL) {
		des->sel = sel;
	} else {
		(*prev)->next = sel;
	}
	(*prev) = sel;
}

static Ast_Designator Designator(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	Ast_Designator des;
	struct Ast_RDeclaration *decl;
	struct Ast_RDeclaration *var_;
	struct Ast_RSelector *prev;
	struct Ast_RSelector *sel;
	struct Ast_RType *type;

	Log_StrLn("Designator", 11);
	assert((*p).l == Scanner_Ident_cnst);
	decl = Qualident(&(*p), p_tag, ds, NULL);
	des = NULL;
	if (decl != NULL) {
		if (o7c_is(NULL, decl, Ast_RVar_tag)) {
			type = decl->type;
			prev = NULL;
			des = Ast_DesignatorNew(decl, NULL);
			do {
				sel = NULL;
				if ((*p).l == Scanner_Dot_cnst) {
					if ((type != NULL) && (type->_._.id == Ast_IdPointer_cnst)) {
						type = type->_.type;
					}
					Scan(&(*p), p_tag);
					var_ = NULL;
					if (type != NULL) {
						if (type->_._.id == Ast_IdRecord_cnst) {
							var_ = (&(ExpectVar(&(*p), p_tag, (&O7C_GUARD(Ast_Record_s, type, NULL))->vars, NULL))->_);
						} else {
							AddError(&(*p), p_tag, Parser_ErrExpectVarRecordOrPointer_cnst);
							Scan(&(*p), p_tag);
						}
					}
					if (var_ != NULL) {
						sel = (&(Ast_SelRecordNew((&O7C_GUARD(Ast_RVar, var_, NULL)), NULL))->_);
						type = var_->type;
					} else {
						type = NULL;
					}
				} else if ((*p).l == Scanner_Brace1Open_cnst) {
					if ((o7c_is(NULL, type, Ast_Record_s_tag)) || (o7c_is(NULL, type, Ast_RPointer_tag))) {
						Scan(&(*p), p_tag);
						var_ = ExpectRecordExtend(&(*p), p_tag, ds, NULL, (&O7C_GUARD(Ast_RConstruct, type, NULL)), NULL);
						CheckAst(&(*p), p_tag, Ast_SelGuardNew(&sel, NULL, &type, NULL, var_, NULL));
						Expect(&(*p), p_tag, Scanner_Brace1Close_cnst, Parser_ErrExpectBrace1Close_cnst);
					} else if (!(o7c_is(NULL, type, Ast_ProcType_s_tag))) {
						AddError(&(*p), p_tag, Parser_ErrExpectVarRecordOrPointer_cnst);
					}
				} else if ((*p).l == Scanner_Brace2Open_cnst) {
					Scan(&(*p), p_tag);
					CheckAst(&(*p), p_tag, Ast_SelArrayNew(&sel, NULL, &type, NULL, expression(&(*p), p_tag, ds, NULL), NULL));
					while (ScanIfEqual(&(*p), p_tag, Scanner_Comma_cnst)) {
						Designator_SetSel(&prev, NULL, sel, NULL, des, NULL);
						CheckAst(&(*p), p_tag, Ast_SelArrayNew(&sel, NULL, &type, NULL, expression(&(*p), p_tag, ds, NULL), NULL));
					}
					Expect(&(*p), p_tag, Scanner_Brace2Close_cnst, Parser_ErrExpectBrace2Close_cnst);
				} else if ((*p).l == Scanner_Dereference_cnst) {
					CheckAst(&(*p), p_tag, Ast_SelPointerNew(&sel, NULL, &type, NULL));
					Scan(&(*p), p_tag);
				} else {
					sel = NULL;
				}
				Designator_SetSel(&prev, NULL, sel, NULL, des, NULL);
			} while (!(sel == NULL));
			des->_._.type = type;
		} else if ((o7c_is(NULL, decl, Ast_Const_s_tag)) || (o7c_is(NULL, decl, Ast_RGeneralProcedure_tag)) || (decl->_.id == Ast_IdError_cnst)) {
			des = Ast_DesignatorNew(decl, NULL);
		} else {
			AddError(&(*p), p_tag, Parser_ErrExpectDesignator_cnst);
		}
	}
	return des;
}

static void CallParams(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, Ast_ExprCall e, o7c_tag_t e_tag) {
	Ast_Parameter par;
	Ast_FormalParam fp;

	assert((*p).l == Scanner_Brace1Open_cnst);
	Scan(&(*p), p_tag);
	if (!ScanIfEqual(&(*p), p_tag, Scanner_Brace1Close_cnst)) {
		par = NULL;
		fp = (&O7C_GUARD(Ast_ProcType_s, e->designator->_._.type, NULL))->params;
		CheckAst(&(*p), p_tag, Ast_CallParamNew(e, NULL, &par, NULL, expression(&(*p), p_tag, ds, NULL), NULL, &fp, NULL));
		e->params = par;
		while (ScanIfEqual(&(*p), p_tag, Scanner_Comma_cnst)) {
			CheckAst(&(*p), p_tag, Ast_CallParamNew(e, NULL, &par, NULL, expression(&(*p), p_tag, ds, NULL), NULL, &fp, NULL));
		}
		CheckAst(&(*p), p_tag, Ast_CallParamsEnd(e, NULL, fp, NULL));
		Expect(&(*p), p_tag, Scanner_Brace1Close_cnst, Parser_ErrExpectBrace1Close_cnst);
	}
}

static Ast_ExprCall ExprCall(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, Ast_Designator des, o7c_tag_t des_tag) {
	Ast_ExprCall e;

	CheckAst(&(*p), p_tag, Ast_ExprCallNew(&e, NULL, des, NULL));
	CallParams(&(*p), p_tag, ds, NULL, e, NULL);
	return e;
}

static struct Ast_RExpression *Factor(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag);
static void Factor_Ident(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, struct Ast_RExpression **e, o7c_tag_t e_tag) {
	Ast_Designator des;

	des = Designator(&(*p), p_tag, ds, NULL);
	if ((*p).l != Scanner_Brace1Open_cnst) {
		(*e) = (&(des)->_._);
	} else {
		(*e) = (&(ExprCall(&(*p), p_tag, ds, NULL, des, NULL))->_._);
	}
}

static struct Ast_RExpression *Factor(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	struct Ast_RExpression *e;

	Log_StrLn("Factor", 7);
	if ((*p).l == Scanner_Number_cnst) {
		if ((*p).s.isReal) {
			e = (&(Ast_ExprRealNew((*p).s.real, (*p).module, NULL, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd))->_._._);
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
		e = (&(Ast_ExprStringNew((*p).module, NULL, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd))->_._._._);
		if ((e != NULL) && (*p).s.isChar) {
			(&O7C_GUARD(Ast_ExprString_s, e, NULL))->_.int_ = (*p).s.integer;
		}
		Scan(&(*p), p_tag);
	} else if ((*p).l == Scanner_Brace1Open_cnst) {
		Scan(&(*p), p_tag);
		e = (&(Ast_ExprBracesNew(expression(&(*p), p_tag, ds, NULL), NULL))->_._);
		Expect(&(*p), p_tag, Scanner_Brace1Close_cnst, Parser_ErrExpectBrace1Close_cnst);
	} else if ((*p).l == Scanner_Ident_cnst) {
		Factor_Ident(&(*p), p_tag, ds, NULL, &e, NULL);
	} else if ((*p).l == Scanner_Brace3Open_cnst) {
		e = (&(Set(&(*p), p_tag, ds, NULL))->_._);
	} else if ((*p).l == Scanner_Negate_cnst) {
		e = (&(Negate(&(*p), p_tag, ds, NULL))->_._);
	} else {
		AddError(&(*p), p_tag, Parser_ErrExpectExpression_cnst);
		e = NULL;
	}
	return e;
}

static struct Ast_RExpression *Term(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	struct Ast_RExpression *e;
	Ast_ExprTerm term;
	int l;

	Log_StrLn("Term", 5);
	e = Factor(&(*p), p_tag, ds, NULL);
	if (((*p).l >= Scanner_MultFirst_cnst) && ((*p).l <= Scanner_MultLast_cnst)) {
		l = (*p).l;
		Scan(&(*p), p_tag);
		term = NULL;
		CheckAst(&(*p), p_tag, Ast_ExprTermNew(&term, NULL, (&O7C_GUARD(Ast_RFactor, e, NULL)), NULL, l, Factor(&(*p), p_tag, ds, NULL), NULL));
		assert((term->expr != NULL) && (term->factor != NULL));
		e = (&(term)->_);
		while (((*p).l >= Scanner_MultFirst_cnst) && ((*p).l <= Scanner_MultLast_cnst)) {
			l = (*p).l;
			Scan(&(*p), p_tag);
			CheckAst(&(*p), p_tag, Ast_ExprTermAdd(e, NULL, &term, NULL, l, Factor(&(*p), p_tag, ds, NULL), NULL));
		}
	}
	return e;
}

static struct Ast_RExpression *Sum(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	struct Ast_RExpression *e;
	Ast_ExprSum sum;
	int l;

	Log_StrLn("Sum", 4);
	l = (*p).l;
	if ((l == Scanner_Minus_cnst) || (l == Scanner_Plus_cnst)) {
		Scan(&(*p), p_tag);
		CheckAst(&(*p), p_tag, Ast_ExprSumNew(&sum, NULL, l, Term(&(*p), p_tag, ds, NULL), NULL));
		e = (&(sum)->_);
	} else {
		e = Term(&(*p), p_tag, ds, NULL);
		if (((*p).l == Scanner_Minus_cnst) || ((*p).l == Scanner_Plus_cnst) || ((*p).l == Scanner_Or_cnst)) {
			CheckAst(&(*p), p_tag, Ast_ExprSumNew(&sum, NULL,  - 1, e, NULL));
			e = (&(sum)->_);
		}
	}
	while (((*p).l == Scanner_Minus_cnst) || ((*p).l == Scanner_Plus_cnst) || ((*p).l == Scanner_Or_cnst)) {
		l = (*p).l;
		Scan(&(*p), p_tag);
		CheckAst(&(*p), p_tag, Ast_ExprSumAdd(e, NULL, &sum, NULL, l, Term(&(*p), p_tag, ds, NULL), NULL));
	}
	return e;
}

static struct Ast_RExpression *Expression(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	struct Ast_RExpression *expr;
	Ast_ExprRelation e;
	Ast_ExprIsExtension isExt;
	int rel;

	Log_StrLn("Expression", 11);
	expr = Sum(&(*p), p_tag, ds, NULL);
	if (((*p).l >= Scanner_RelationFirst_cnst) && ((*p).l < Scanner_RelationLast_cnst)) {
		rel = (*p).l;
		Scan(&(*p), p_tag);
		CheckAst(&(*p), p_tag, Ast_ExprRelationNew(&e, NULL, expr, NULL, rel, Sum(&(*p), p_tag, ds, NULL), NULL));
		expr = (&(e)->_);
	} else if (ScanIfEqual(&(*p), p_tag, Scanner_Is_cnst)) {
		CheckAst(&(*p), p_tag, Ast_ExprIsExtensionNew(&isExt, NULL, &expr, NULL, type(&(*p), p_tag, ds, NULL,  - 1,  - 1), NULL));
		expr = (&(isExt)->_);
	}
	return expr;
}

static bool Mark(struct Parser *p, o7c_tag_t p_tag) {
	bool m;

	m = ScanIfEqual(&(*p), p_tag, Scanner_Asterisk_cnst);
	if (m) {
		Log_StrLn("Mark", 5);
	}
	return m;
}

static void Consts(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	int begin;
	int end;
	struct Ast_Const_s *const_;

	Scan(&(*p), p_tag);
	while ((*p).l == Scanner_Ident_cnst) {
		if (!(*p).err) {
			ExpectIdent(&(*p), p_tag, &begin, &end, Parser_ErrExpectConstName_cnst);
			CheckAst(&(*p), p_tag, Ast_ConstAdd(ds, NULL, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, begin, end));
			const_ = (&O7C_GUARD(Ast_Const_s, ds->end, NULL));
			const_->_.mark = Mark(&(*p), p_tag);
			Expect(&(*p), p_tag, Scanner_Equal_cnst, Parser_ErrExpectEqual_cnst);
			CheckAst(&(*p), p_tag, Ast_ConstSetExpression(const_, NULL, Expression(&(*p), p_tag, ds, NULL), NULL));
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

static int ExprToArrayLen(struct Parser *p, o7c_tag_t p_tag, struct Ast_RExpression *e, o7c_tag_t e_tag) {
	int i;

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

static int ExprToInteger(struct Parser *p, o7c_tag_t p_tag, struct Ast_RExpression *e, o7c_tag_t e_tag) {
	int i;

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

static struct Ast_RArray *Array(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, int nameBegin, int nameEnd) {
	struct Ast_RArray *a;
	struct Ast_RType *t;
	struct Ast_RExpression *exprLen;
	struct Ast_RExpression *lens[16];
	int i;
	int size;

	Log_StrLn("Array", 6);
	assert((*p).l == Scanner_Array_cnst);
	Scan(&(*p), p_tag);
	a = Ast_ArrayGet(NULL, NULL, Expression(&(*p), p_tag, ds, NULL), NULL);
	if (nameBegin >= 0) {
		t = (&(a)->_._);
		CheckAst(&(*p), p_tag, Ast_TypeAdd(ds, NULL, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, nameBegin, nameEnd, &t, NULL));
	}
	size = ExprToArrayLen(&(*p), p_tag, a->count, NULL);
	i = 0;
	while (ScanIfEqual(&(*p), p_tag, Scanner_Comma_cnst)) {
		exprLen = Expression(&(*p), p_tag, ds, NULL);
		size = size * ExprToArrayLen(&(*p), p_tag, exprLen, NULL);
		if (i < sizeof(lens) / sizeof (lens[0])) {
			lens[i] = exprLen;
		}
		i++;
	}
	if (i > sizeof(lens) / sizeof (lens[0])) {
		AddError(&(*p), p_tag, Parser_ErrArrayDimensionsTooMany_cnst);
	}
	Expect(&(*p), p_tag, Scanner_Of_cnst, Parser_ErrExpectOf_cnst);
	a->_._._.type = type(&(*p), p_tag, ds, NULL,  - 1,  - 1);
	while (i > 0) {
		i--;
		a->_._._.type = (&(Ast_ArrayGet(a->_._._.type, NULL, lens[i], NULL))->_._);
	}
	return a;
}

static struct Ast_RType *TypeNamed(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	struct Ast_RDeclaration *d;
	struct Ast_RType *t;

	t = NULL;
	d = Qualident(&(*p), p_tag, ds, NULL);
	if (d != NULL) {
		if (o7c_is(NULL, d, Ast_RType_tag)) {
			t = (&O7C_GUARD(Ast_RType, d, NULL));
		} else {
			AddError(&(*p), p_tag, Parser_ErrExpectType_cnst);
		}
	}
	return t;
}

static void VarDeclaration(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *dsAdd, o7c_tag_t dsAdd_tag, struct Ast_RDeclarations *dsTypes, o7c_tag_t dsTypes_tag);
static void VarDeclaration_Name(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	int begin;
	int end;

	ExpectIdent(&(*p), p_tag, &begin, &end, Parser_ErrExpectIdent_cnst);
	CheckAst(&(*p), p_tag, Ast_VarAdd(ds, NULL, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, begin, end));
	ds->end->mark = Mark(&(*p), p_tag);
}

static void VarDeclaration(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *dsAdd, o7c_tag_t dsAdd_tag, struct Ast_RDeclarations *dsTypes, o7c_tag_t dsTypes_tag) {
	struct Ast_RDeclaration *var_;
	struct Ast_RType *typ;

	VarDeclaration_Name(&(*p), p_tag, dsAdd, NULL);
	var_ = (&((&O7C_GUARD(Ast_RVar, dsAdd->end, NULL)))->_);
	while (ScanIfEqual(&(*p), p_tag, Scanner_Comma_cnst)) {
		VarDeclaration_Name(&(*p), p_tag, dsAdd, NULL);
	}
	Expect(&(*p), p_tag, Scanner_Colon_cnst, Parser_ErrExpectColon_cnst);
	typ = type(&(*p), p_tag, dsTypes, NULL,  - 1,  - 1);
	while (var_ != NULL) {
		var_->type = typ;
		var_ = var_->next;
	}
}

static void Vars(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	while ((*p).l == Scanner_Ident_cnst) {
		VarDeclaration(&(*p), p_tag, ds, NULL, ds, NULL);
		Expect(&(*p), p_tag, Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
	}
}

static struct Ast_Record_s *Record(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, int nameBegin, int nameEnd);
static void Record_Vars(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *dsAdd, o7c_tag_t dsAdd_tag, struct Ast_RDeclarations *dsTypes, o7c_tag_t dsTypes_tag) {
	if ((*p).l == Scanner_Ident_cnst) {
		VarDeclaration(&(*p), p_tag, dsAdd, NULL, dsTypes, NULL);
		while (ScanIfEqual(&(*p), p_tag, Scanner_Semicolon_cnst)) {
			if ((*p).l != Scanner_End_cnst) {
				VarDeclaration(&(*p), p_tag, dsAdd, NULL, dsTypes, NULL);
			} else if ((*p).settings.strictSemicolon) {
				AddError(&(*p), p_tag, Parser_ErrExcessSemicolon_cnst);
				(*p).err = false;
			}
		}
	}
}

static struct Ast_Record_s *Record(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, int nameBegin, int nameEnd) {
	struct Ast_Record_s *rec;
	struct Ast_Record_s *base;
	struct Ast_RType *t;
	struct Ast_RDeclaration *decl;

	assert((*p).l == Scanner_Record_cnst);
	Scan(&(*p), p_tag);
	base = NULL;
	if (ScanIfEqual(&(*p), p_tag, Scanner_Brace1Open_cnst)) {
		decl = Qualident(&(*p), p_tag, ds, NULL);
		if ((decl != NULL) && (decl->_.id == Ast_IdRecord_cnst)) {
			base = (&O7C_GUARD(Ast_Record_s, decl, NULL));
		} else {
			AddError(&(*p), p_tag, Parser_ErrExpectRecord_cnst);
		}
		Expect(&(*p), p_tag, Scanner_Brace1Close_cnst, Parser_ErrExpectBrace1Close_cnst);
	}
	rec = Ast_RecordNew(ds, NULL, base, NULL);
	if (nameBegin >= 0) {
		t = (&(rec)->_._);
		CheckAst(&(*p), p_tag, Ast_TypeAdd(ds, NULL, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, nameBegin, nameEnd, &t, NULL));
		rec = (&O7C_GUARD(Ast_Record_s, t, NULL));
		Ast_RecordSetBase(rec, NULL, base, NULL);
	} else {
		rec->_._._.name.block = NULL;
		rec->_._._.module = (*p).module;
	}
	Record_Vars(&(*p), p_tag, rec->vars, NULL, ds, NULL);
	Expect(&(*p), p_tag, Scanner_End_cnst, Parser_ErrExpectEnd_cnst);
	return rec;
}

static struct Ast_RPointer *Pointer(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, int nameBegin, int nameEnd) {
	struct Ast_RPointer *tp;
	struct Ast_RType *t;
	struct Ast_RDeclaration *decl;
	struct Ast_RType *typeDecl;

	assert((*p).l == Scanner_Pointer_cnst);
	Scan(&(*p), p_tag);
	tp = Ast_PointerGet(NULL, NULL);
	if (nameBegin >= 0) {
		t = (&(tp)->_._);
		assert(t != NULL);
		CheckAst(&(*p), p_tag, Ast_TypeAdd(ds, NULL, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, nameBegin, nameEnd, &t, NULL));
	}
	Expect(&(*p), p_tag, Scanner_To_cnst, Parser_ErrExpectTo_cnst);
	if ((*p).l == Scanner_Record_cnst) {
		tp->_._._.type = (&(Record(&(*p), p_tag, ds, NULL,  - 1,  - 1))->_._);
		if (tp->_._._.type != NULL) {
			(&O7C_GUARD(Ast_Record_s, tp->_._._.type, NULL))->pointer = tp;
		}
	} else if ((*p).l == Scanner_Ident_cnst) {
		decl = Ast_DeclarationSearch(ds, NULL, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd);
		if (decl == NULL) {
			typeDecl = (&(Ast_RecordNew(ds, NULL, NULL, NULL))->_._);
			CheckAst(&(*p), p_tag, Ast_TypeAdd(ds, NULL, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd, &typeDecl, NULL));
			assert(tp->_._._.next == &typeDecl->_);
			typeDecl->_._.id = Ast_IdRecordForward_cnst;
			tp->_._._.type = typeDecl;
			(&O7C_GUARD(Ast_Record_s, typeDecl, NULL))->pointer = tp;
		} else if (o7c_is(NULL, decl, Ast_Record_s_tag)) {
			tp->_._._.type = (&((&O7C_GUARD(Ast_Record_s, decl, NULL)))->_._);
			(&O7C_GUARD(Ast_Record_s, decl, NULL))->pointer = tp;
		} else {
			tp->_._._.type = TypeNamed(&(*p), p_tag, ds, NULL);
			if ((tp->_._._.type != NULL)) {
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

static void FormalParameters(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, struct Ast_ProcType_s *proc, o7c_tag_t proc_tag);
static void FormalParameters_Section(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, struct Ast_ProcType_s *proc, o7c_tag_t proc_tag);
static void Section_FormalParameters_Name(struct Parser *p, o7c_tag_t p_tag, struct Ast_ProcType_s *proc, o7c_tag_t proc_tag) {
	if ((*p).l != Scanner_Ident_cnst) {
		AddError(&(*p), p_tag, Parser_ErrExpectIdent_cnst);
	} else {
		CheckAst(&(*p), p_tag, Ast_ParamAdd((*p).module, NULL, proc, NULL, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd));
		Scan(&(*p), p_tag);
	}
}

static struct Ast_RType *Section_FormalParameters_Type(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	struct Ast_RType *t;
	int arrs;

	arrs = 0;
	while (ScanIfEqual(&(*p), p_tag, Scanner_Array_cnst)) {
		Expect(&(*p), p_tag, Scanner_Of_cnst, Parser_ErrExpectOf_cnst);
		arrs++;
	}
	t = TypeNamed(&(*p), p_tag, ds, NULL);
	while ((t != NULL) && (arrs > 0)) {
		t = (&(Ast_ArrayGet(t, NULL, NULL, NULL))->_._);
		arrs--;
	}
	return t;
}

static void FormalParameters_Section(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, struct Ast_ProcType_s *proc, o7c_tag_t proc_tag) {
	bool isVar;
	Ast_FormalParam param;
	struct Ast_RType *type;

	isVar = ScanIfEqual(&(*p), p_tag, Scanner_Var_cnst);
	Section_FormalParameters_Name(&(*p), p_tag, proc, NULL);
	param = proc->end;
	while (ScanIfEqual(&(*p), p_tag, Scanner_Comma_cnst)) {
		Section_FormalParameters_Name(&(*p), p_tag, proc, NULL);
	}
	Expect(&(*p), p_tag, Scanner_Colon_cnst, Parser_ErrExpectColon_cnst);
	type = Section_FormalParameters_Type(&(*p), p_tag, ds, NULL);
	while (param != NULL) {
		param->isVar = isVar;
		param->_._.type = type;
		param = (&O7C_GUARD(Ast_FormalParam_s, param->_._.next, NULL));
	}
}

static void FormalParameters(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, struct Ast_ProcType_s *proc, o7c_tag_t proc_tag) {
	bool braces;

	braces = ScanIfEqual(&(*p), p_tag, Scanner_Brace1Open_cnst);
	if (braces) {
		if (!ScanIfEqual(&(*p), p_tag, Scanner_Brace1Close_cnst)) {
			FormalParameters_Section(&(*p), p_tag, ds, NULL, proc, NULL);
			while (ScanIfEqual(&(*p), p_tag, Scanner_Semicolon_cnst)) {
				FormalParameters_Section(&(*p), p_tag, ds, NULL, proc, NULL);
			}
			Expect(&(*p), p_tag, Scanner_Brace1Close_cnst, Parser_ErrExpectBrace1Close_cnst);
		}
	}
	if (ScanIfEqual(&(*p), p_tag, Scanner_Colon_cnst)) {
		if (!braces) {
			AddError(&(*p), p_tag, Parser_ErrFunctionWithoutBraces_cnst);
			(*p).err = false;
		}
		proc->_._._.type = TypeNamed(&(*p), p_tag, ds, NULL);
	}
}

static struct Ast_ProcType_s *TypeProcedure(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, int nameBegin, int nameEnd) {
	struct Ast_ProcType_s *proc;
	struct Ast_RType *t;

	assert((*p).l == Scanner_Procedure_cnst);
	Scan(&(*p), p_tag);
	proc = Ast_ProcTypeNew();
	if (nameBegin >= 0) {
		t = (&(proc)->_._);
		CheckAst(&(*p), p_tag, Ast_TypeAdd(ds, NULL, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, nameBegin, nameEnd, &t, NULL));
	}
	FormalParameters(&(*p), p_tag, ds, NULL, proc, NULL);
	return proc;
}

static struct Ast_RType *Type(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, int nameBegin, int nameEnd) {
	struct Ast_RType *t;

	if ((*p).l == Scanner_Array_cnst) {
		t = (&(Array(&(*p), p_tag, ds, NULL, nameBegin, nameEnd))->_._);
	} else if ((*p).l == Scanner_Pointer_cnst) {
		t = (&(Pointer(&(*p), p_tag, ds, NULL, nameBegin, nameEnd))->_._);
	} else if ((*p).l == Scanner_Procedure_cnst) {
		t = (&(TypeProcedure(&(*p), p_tag, ds, NULL, nameBegin, nameEnd))->_._);
	} else if ((*p).l == Scanner_Record_cnst) {
		t = (&(Record(&(*p), p_tag, ds, NULL, nameBegin, nameEnd))->_._);
	} else if ((*p).l == Scanner_Ident_cnst) {
		t = TypeNamed(&(*p), p_tag, ds, NULL);
	} else {
		AddError(&(*p), p_tag, Parser_ErrExpectType_cnst);
	}
	return t;
}

static void Types(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	struct Ast_RType *type;
	int begin;
	int end;
	bool mark;

	Scan(&(*p), p_tag);
	while ((*p).l == Scanner_Ident_cnst) {
		begin = (*p).s.lexStart;
		end = (*p).s.lexEnd;
		Scan(&(*p), p_tag);
		mark = ScanIfEqual(&(*p), p_tag, Scanner_Asterisk_cnst);
		Expect(&(*p), p_tag, Scanner_Equal_cnst, Parser_ErrExpectEqual_cnst);
		type = Type(&(*p), p_tag, ds, NULL, begin, end);
		if (type != NULL) {
			type->_.mark = mark;
			if (!(o7c_is(NULL, type, Ast_RConstruct_tag))) {
				AddError(&(*p), p_tag, Parser_ErrExpectNamedType_cnst);
			}
		}
		Expect(&(*p), p_tag, Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
	}
}

static Ast_If If(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag);
static Ast_If If_Branch(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	Ast_If if_;

	Scan(&(*p), p_tag);
	if_ = Ast_IfNew(Expression(&(*p), p_tag, ds, NULL), NULL, NULL, NULL);
	Expect(&(*p), p_tag, Scanner_Then_cnst, Parser_ErrExpectThen_cnst);
	if_->_.stats = statements(&(*p), p_tag, ds, NULL);
	return if_;
}

static Ast_If If(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	Ast_If if_;
	struct Ast_RWhileIf *elsif;

	assert((*p).l == Scanner_If_cnst);
	if_ = If_Branch(&(*p), p_tag, ds, NULL);
	elsif = (&(if_)->_);
	while ((*p).l == Scanner_Elsif_cnst) {
		elsif->elsif = (&(If_Branch(&(*p), p_tag, ds, NULL))->_);
		elsif = elsif->elsif;
	}
	if (ScanIfEqual(&(*p), p_tag, Scanner_Else_cnst)) {
		elsif->elsif = (&(Ast_IfNew(NULL, NULL, statements(&(*p), p_tag, ds, NULL), NULL))->_);
	}
	Expect(&(*p), p_tag, Scanner_End_cnst, Parser_ErrExpectEnd_cnst);
	return if_;
}

static Ast_Case Case(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag);
static Ast_CaseLabel Case_Label(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	int err;
	Ast_CaseLabel l;
	bool qual;

	qual = false;
	if (((*p).l == Scanner_Number_cnst) && !(*p).s.isReal) {
		err = Ast_CaseLabelNew(&l, NULL, Ast_IdInteger_cnst, (*p).s.integer);
	} else if ((*p).l == Scanner_String_cnst) {
		assert((*p).s.isChar);
		err = Ast_CaseLabelNew(&l, NULL, Ast_IdChar_cnst, (*p).s.integer);
	} else if ((*p).l == Scanner_Ident_cnst) {
		qual = true;
		err = Ast_CaseLabelQualNew(&l, NULL, Qualident(&(*p), p_tag, ds, NULL), NULL);
	} else {
		err = Parser_ErrExpectIntOrStrOrQualident_cnst;
	}
	CheckAst(&(*p), p_tag, err);
	if (!qual && (err != Parser_ErrExpectIntOrStrOrQualident_cnst)) {
		Scan(&(*p), p_tag);
	}
	return l;
}

static Ast_CaseLabelRange Case_LabelRange(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	Ast_CaseLabel l1;
	Ast_CaseLabel l2;
	Ast_CaseLabelRange r;

	l1 = Case_Label(&(*p), p_tag, ds, NULL);
	if ((*p).l == Scanner_Range_cnst) {
		Scan(&(*p), p_tag);
		l2 = Case_Label(&(*p), p_tag, ds, NULL);
	} else {
		l2 = NULL;
	}
	CheckAst(&(*p), p_tag, Ast_CaseRangeNew(&r, NULL, l1, NULL, l2, NULL));
	return r;
}

static Ast_CaseLabelRange Case_LabelList(struct Parser *p, o7c_tag_t p_tag, Ast_Case case_, o7c_tag_t case__tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	Ast_CaseLabelRange first;
	Ast_CaseLabelRange last;

	first = Case_LabelRange(&(*p), p_tag, ds, NULL);
	while ((*p).l == Scanner_Comma_cnst) {
		Scan(&(*p), p_tag);
		last = Case_LabelRange(&(*p), p_tag, ds, NULL);
		CheckAst(&(*p), p_tag, Ast_CaseRangeListAdd(case_, NULL, first, NULL, last, NULL));
	}
	return first;
}

static void Case_Element(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, Ast_Case case_, o7c_tag_t case__tag) {
	Ast_CaseElement elem;

	elem = Ast_CaseElementNew();
	elem->range = Case_LabelList(&(*p), p_tag, case_, NULL, ds, NULL);
	assert(elem->range != NULL);
	assert(elem->range->left != NULL);
	Expect(&(*p), p_tag, Scanner_Colon_cnst, Parser_ErrExpectColon_cnst);
	elem->stats = statements(&(*p), p_tag, ds, NULL);
	CheckAst(&(*p), p_tag, Ast_CaseElementAdd(case_, NULL, elem, NULL));
}

static Ast_Case Case(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	Ast_Case case_;

	assert((*p).l == Scanner_Case_cnst);
	Scan(&(*p), p_tag);
	CheckAst(&(*p), p_tag, Ast_CaseNew(&case_, NULL, Expression(&(*p), p_tag, ds, NULL), NULL));
	Expect(&(*p), p_tag, Scanner_Of_cnst, Parser_ErrExpectOf_cnst);
	Case_Element(&(*p), p_tag, ds, NULL, case_, NULL);
	while (ScanIfEqual(&(*p), p_tag, Scanner_Alternative_cnst)) {
		Case_Element(&(*p), p_tag, ds, NULL, case_, NULL);
	}
	Expect(&(*p), p_tag, Scanner_End_cnst, Parser_ErrExpectEnd_cnst);
	return case_;
}

static Ast_Repeat Repeat(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	Ast_Repeat r;

	assert((*p).l == Scanner_Repeat_cnst);
	Scan(&(*p), p_tag);
	r = Ast_RepeatNew(NULL, NULL, statements(&(*p), p_tag, ds, NULL), NULL);
	Expect(&(*p), p_tag, Scanner_Until_cnst, Parser_ErrExpectUntil_cnst);
	r->_.expr = Expression(&(*p), p_tag, ds, NULL);
	return r;
}

static Ast_For For(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	Ast_For f;
	struct Ast_RDeclaration *d;

	assert((*p).l == Scanner_For_cnst);
	Scan(&(*p), p_tag);
	if ((*p).l != Scanner_Ident_cnst) {
		AddError(&(*p), p_tag, Parser_ErrExpectIdent_cnst);
	} else {
		CheckAst(&(*p), p_tag, Ast_DeclarationGet(&d, NULL, ds, NULL, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, (*p).s.lexStart, (*p).s.lexEnd));
		if (!(o7c_is(NULL, d, Ast_RVar_tag))) {
			AddError(&(*p), p_tag, Parser_ErrDeclarationNotVar_cnst);
		} else {
			Scan(&(*p), p_tag);
			Expect(&(*p), p_tag, Scanner_Assign_cnst, Parser_ErrExpectAssign_cnst);
			f = Ast_ForNew((&O7C_GUARD(Ast_RVar, d, NULL)), NULL, Expression(&(*p), p_tag, ds, NULL), NULL, NULL, NULL, 1, NULL, NULL);
			Expect(&(*p), p_tag, Scanner_To_cnst, Parser_ErrExpectTo_cnst);
			f->to = Expression(&(*p), p_tag, ds, NULL);
			if (ScanIfEqual(&(*p), p_tag, Scanner_By_cnst)) {
				f->by = ExprToInteger(&(*p), p_tag, Expression(&(*p), p_tag, ds, NULL), NULL);
			}
			Expect(&(*p), p_tag, Scanner_Do_cnst, Parser_ErrExpectDo_cnst);
			f->stats = statements(&(*p), p_tag, ds, NULL);
			Expect(&(*p), p_tag, Scanner_End_cnst, Parser_ErrExpectEnd_cnst);
		}
	}
	return f;
}

static Ast_While While(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	Ast_While w;
	struct Ast_RWhileIf *elsif;

	assert((*p).l == Scanner_While_cnst);
	Scan(&(*p), p_tag);
	w = Ast_WhileNew(Expression(&(*p), p_tag, ds, NULL), NULL, NULL, NULL);
	elsif = (&(w)->_);
	Expect(&(*p), p_tag, Scanner_Do_cnst, Parser_ErrExpectDo_cnst);
	w->_.stats = statements(&(*p), p_tag, ds, NULL);
	while (ScanIfEqual(&(*p), p_tag, Scanner_Elsif_cnst)) {
		elsif->elsif = (&(Ast_WhileNew(Expression(&(*p), p_tag, ds, NULL), NULL, NULL, NULL))->_);
		elsif = elsif->elsif;
		Expect(&(*p), p_tag, Scanner_Do_cnst, Parser_ErrExpectDo_cnst);
		elsif->stats = statements(&(*p), p_tag, ds, NULL);
	}
	Expect(&(*p), p_tag, Scanner_End_cnst, Parser_ErrExpectEnd_cnst);
	return w;
}

static Ast_Assign Assign(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, Ast_Designator des, o7c_tag_t des_tag) {
	Ast_Assign st;

	assert((*p).l == Scanner_Assign_cnst);
	Scan(&(*p), p_tag);
	CheckAst(&(*p), p_tag, Ast_AssignNew(&st, NULL, des, NULL, Expression(&(*p), p_tag, ds, NULL), NULL));
	return st;
}

static Ast_Call Call(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, Ast_Designator des, o7c_tag_t des_tag) {
	Ast_Call st;

	CheckAst(&(*p), p_tag, Ast_CallNew(&st, NULL, des, NULL));
	if ((*p).l == Scanner_Brace1Open_cnst) {
		CallParams(&(*p), p_tag, ds, NULL, (&O7C_GUARD(Ast_ExprCall_s, st->_.expr, NULL)), NULL);
	} else if ((des != NULL) && (des->_._.type != NULL) && (o7c_is(NULL, des->_._.type, Ast_ProcType_s_tag))) {
		CheckAst(&(*p), p_tag, Ast_CallParamsEnd((&O7C_GUARD(Ast_ExprCall_s, st->_.expr, NULL)), NULL, (&O7C_GUARD(Ast_ProcType_s, des->_._.type, NULL))->params, NULL));
	}
	return st;
}

static struct Ast_RStatement *Statements(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag);
static struct Ast_RStatement *Statements_Statement(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	Ast_Designator des;
	struct Ast_RStatement *st;

	Log_StrLn("Statement", 10);
	if ((*p).l == Scanner_Ident_cnst) {
		des = Designator(&(*p), p_tag, ds, NULL);
		if ((*p).l == Scanner_Assign_cnst) {
			st = (&(Assign(&(*p), p_tag, ds, NULL, des, NULL))->_);
		} else {
			st = (&(Call(&(*p), p_tag, ds, NULL, des, NULL))->_);
		}
	} else if ((*p).l == Scanner_If_cnst) {
		st = (&(If(&(*p), p_tag, ds, NULL))->_._);
	} else if ((*p).l == Scanner_Case_cnst) {
		st = (&(Case(&(*p), p_tag, ds, NULL))->_);
	} else if ((*p).l == Scanner_Repeat_cnst) {
		st = (&(Repeat(&(*p), p_tag, ds, NULL))->_);
	} else if ((*p).l == Scanner_For_cnst) {
		st = (&(For(&(*p), p_tag, ds, NULL))->_);
	} else if ((*p).l == Scanner_While_cnst) {
		st = (&(While(&(*p), p_tag, ds, NULL))->_._);
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

static struct Ast_RStatement *Statements(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	struct Ast_RStatement *stats;
	struct Ast_RStatement *last;

	Log_StrLn("Statements", 11);
	stats = Statements_Statement(&(*p), p_tag, ds, NULL);
	last = stats;
	while (ScanIfEqual(&(*p), p_tag, Scanner_Semicolon_cnst)) {
		if (((*p).l != Scanner_End_cnst) && ((*p).l != Scanner_Return_cnst) && ((*p).l != Scanner_Else_cnst) && ((*p).l != Scanner_Elsif_cnst) && ((*p).l != Scanner_Until_cnst)) {
			last->next = Statements_Statement(&(*p), p_tag, ds, NULL);
			last = last->next;
		} else if ((*p).settings.strictSemicolon) {
			AddError(&(*p), p_tag, Parser_ErrExcessSemicolon_cnst);
			(*p).err = false;
		}
	}
	return stats;
}

static void Return(struct Parser *p, o7c_tag_t p_tag, struct Ast_RProcedure *proc, o7c_tag_t proc_tag) {
	if ((*p).l == Scanner_Return_cnst) {
		Log_StrLn("Return", 7);
		Scan(&(*p), p_tag);
		CheckAst(&(*p), p_tag, Ast_ProcedureSetReturn(proc, NULL, Expression(&(*p), p_tag, &proc->_._, NULL), NULL));
		if ((*p).l == Scanner_Semicolon_cnst) {
			if ((*p).settings.strictSemicolon) {
				AddError(&(*p), p_tag, Parser_ErrExcessSemicolon_cnst);
				(*p).err = false;
			}
			Scan(&(*p), p_tag);
		}
	} else {
		CheckAst(&(*p), p_tag, Ast_ProcedureEnd(proc, NULL));
	}
}

static void ProcBody(struct Parser *p, o7c_tag_t p_tag, struct Ast_RProcedure *proc, o7c_tag_t proc_tag) {
	Log_StrLn("ProcBody", 9);
	declarations(&(*p), p_tag, &proc->_._, NULL);
	if (ScanIfEqual(&(*p), p_tag, Scanner_Begin_cnst)) {
		proc->_._.stats = Statements(&(*p), p_tag, &proc->_._, NULL);
	}
	Return(&(*p), p_tag, proc, NULL);
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

static void Procedure(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	struct Ast_RProcedure *proc;
	int nameStart;
	int nameEnd;

	Log_StrLn("Procedure", 10);
	Scan(&(*p), p_tag);
	ExpectIdent(&(*p), p_tag, &nameStart, &nameEnd, Parser_ErrExpectIdent_cnst);
	CheckAst(&(*p), p_tag, Ast_ProcedureAdd(ds, NULL, &proc, NULL, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, nameStart, nameEnd));
	proc->_._._.mark = Mark(&(*p), p_tag);
	FormalParameters(&(*p), p_tag, ds, NULL, proc->_.header, NULL);
	Expect(&(*p), p_tag, Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
	ProcBody(&(*p), p_tag, proc, NULL);
}

static void Declarations(struct Parser *p, o7c_tag_t p_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	if ((*p).l == Scanner_Const_cnst) {
		Consts(&(*p), p_tag, ds, NULL);
	}
	if ((*p).l == Scanner_Type_cnst) {
		Types(&(*p), p_tag, ds, NULL);
	}
	if ((*p).l == Scanner_Var_cnst) {
		Scan(&(*p), p_tag);
		Vars(&(*p), p_tag, ds, NULL);
	}
	while ((*p).l == Scanner_Procedure_cnst) {
		Procedure(&(*p), p_tag, ds, NULL);
		Expect(&(*p), p_tag, Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
	}
}

static void Imports(struct Parser *p, o7c_tag_t p_tag) {
	int nameOfs;
	int nameEnd;
	int realOfs;
	int realEnd;

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
			CheckAst(&(*p), p_tag, Ast_ImportAdd((*p).module, NULL, (*p).s.buf, Scanner_BlockSize_cnst * 2 + 1, nameOfs, nameEnd, realOfs, realEnd, (*p).provider, NULL));
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
		Declarations(&(*p), p_tag, &(*p).module->_, NULL);
		if (ScanIfEqual(&(*p), p_tag, Scanner_Begin_cnst)) {
			(*p).module->_.stats = Statements(&(*p), p_tag, &(*p).module->_, NULL);
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

extern struct Ast_RModule *Parser_Parse(struct VDataStream_In *in_, o7c_tag_t in__tag, struct Ast_RProvider *prov, o7c_tag_t prov_tag, struct Parser_Options *opt, o7c_tag_t opt_tag) {
	struct Parser p;

	assert(in_ != NULL);
	assert(prov != NULL);
	V_Init(&p._, Parser_tag);
	p.settings = (*opt);
	p.err = false;
	p.module = NULL;
	p.provider = prov;
	Scanner_Init(&p.s, Scanner_Scanner_tag, in_, NULL);
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


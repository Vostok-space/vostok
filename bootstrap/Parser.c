#define O7_BOOL_UNDEFINED
#include <o7.h>

#include "Parser.h"

#define ErrNo_cnst 0

#define Parser_Options_tag V_Base_tag
extern void Parser_Options_undef(struct Parser_Options *r) {
	V_Base_undef(&r->_);
	r->strictSemicolon = O7_BOOL_UNDEF;
	r->strictReturn = O7_BOOL_UNDEF;
	r->saveComments = O7_BOOL_UNDEF;
	r->multiErrors = O7_BOOL_UNDEF;
	r->cyrillic = O7_BOOL_UNDEF;
	r->printError = NULL;
	r->provider = NULL;
}
typedef struct Parser {
	V_Base _;
	struct Parser_Options opt;
	o7_bool err;
	o7_int_t errorsCount;
	o7_int_t callId;
	struct Scanner_Scanner s;
	o7_int_t l;

	struct Parser__anon__0000 {
		o7_int_t ofs;
		o7_int_t end;
	} comment;

	o7_int_t inLoops;

	struct Ast_RModule *module_;
} Parser;
#define Parser_tag V_Base_tag

static void Parser_undef(struct Parser *r) {
	V_Base_undef(&r->_);
	Parser_Options_undef(&r->opt);
	r->err = O7_BOOL_UNDEF;
	r->errorsCount = O7_INT_UNDEF;
	r->callId = O7_INT_UNDEF;
	Scanner_Scanner_undef(&r->s);
	r->l = O7_INT_UNDEF;
	memset(&r->comment, 0, sizeof(r->comment));
	r->inLoops = O7_INT_UNDEF;
	r->module_ = NULL;
}

static void (*declarations)(struct Parser *p, struct Ast_RDeclarations *ds) = NULL;
static struct Ast_RType *(*type)(struct Parser *p, struct Ast_RDeclarations *ds, o7_int_t nameBegin, o7_int_t nameEnd) = NULL;
static struct Ast_RStatement *(*statements)(struct Parser *p, struct Ast_RDeclarations *ds) = NULL;
static struct Ast_RExpression *(*expression)(struct Parser *p, struct Ast_RDeclarations *ds, o7_bool varParm) = NULL;

static void AddError(struct Parser *p, o7_int_t err) {
	if ((*p).module_ != NULL) {
		Log_Str(9, (o7_char *)"AddError ");
		Log_Int(err);
		Log_Str(4, (o7_char *)" at ");
		Log_Int(o7_int((*p).s.line));
		Log_Str(1, (o7_char *)"\x3A");
		Log_Int(o7_int((*p).s.column));
		Log_Ln();
		(*p).err = err > Parser_ErrAstBegin_cnst;

		(*p).errorsCount = o7_add((*p).errorsCount, 1);
		Ast_AddError((*p).module_, err, o7_int((*p).s.line), o7_int((*p).s.column));
		O7_ASSERT(O7_REF((*p).module_)->errors != NULL);
	}
	if (o7_bl((*p).opt.multiErrors)) {
		(*p).opt.printError(err);
		Log_Str(2, (o7_char *)". ");
		Log_Int(o7_add((*p).s.line, 1));
		Log_Str(1, (o7_char *)"\x3A");
		Log_Int(o7_int((*p).s.column));
		Log_Ln();
	}
}

static void CheckAst(struct Parser *p, o7_int_t err) {
	if (err != Ast_ErrNo_cnst) {
		O7_ASSERT((Ast_ErrMin_cnst <= err) && (err < ErrNo_cnst));
		AddError(&(*p), o7_add(Parser_ErrAstBegin_cnst, err));
	}
}

static void Scan(struct Parser *p) {
	o7_int_t si = O7_INT_UNDEF;

	if ((o7_cmp((*p).errorsCount, 0) == 0) || o7_bl((*p).opt.multiErrors)) {
		(*p).l = Scanner_Next(&(*p).s);
		if (o7_cmp((*p).l, Scanner_Ident_cnst) == 0) {
			if (OberonSpecIdent_IsKeyWord(&si, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, o7_int((*p).s.lexStart), o7_int((*p).s.lexEnd))) {
				switch (si) {
				case 105:
					(*p).l = Scanner_Div_cnst;
					break;
				case 114:
					(*p).l = Scanner_In_cnst;
					break;
				case 115:
					(*p).l = Scanner_Is_cnst;
					break;
				case 116:
					(*p).l = Scanner_Mod_cnst;
					break;
				case 120:
					(*p).l = Scanner_Or_cnst;
					break;
				default:
					if ((100 <= si && si <= 104) || (106 <= si && si <= 113) || (117 <= si && si <= 119) || (121 <= si && si <= 132)) {
						(*p).l = o7_int(si);
					} else o7_case_fail(si);
					break;
				}
			}
		} else if (o7_cmp((*p).l, Scanner_Semicolon_cnst) == 0) {
			Scanner_ResetComment(&(*p).s);
		} else if (o7_cmp((*p).l, ErrNo_cnst) < 0) {
			AddError(&(*p), o7_int((*p).l));
			if (o7_cmp((*p).l, Scanner_ErrNumberTooBig_cnst) == 0) {
				(*p).l = Scanner_Number_cnst;
			}
		}
	} else {
		(*p).l = Scanner_EndOfFile_cnst;
	}
}

static void Expect(struct Parser *p, o7_int_t expect, o7_int_t error) {
	if (o7_cmp((*p).l, expect) == 0) {
		Scan(&(*p));
	} else {
		AddError(&(*p), error);
	}
}

static o7_bool ScanIfEqual(struct Parser *p, o7_int_t lex) {
	if (o7_cmp((*p).l, lex) == 0) {
		Scan(&(*p));
		lex = o7_int((*p).l);
	}
	return o7_cmp((*p).l, lex) == 0;
}

static void ExpectIdent(struct Parser *p, o7_int_t *begin, o7_int_t *end, o7_int_t error) {
	if (o7_cmp((*p).l, Scanner_Ident_cnst) == 0) {
		(*begin) = o7_int((*p).s.lexStart);
		(*end) = o7_int((*p).s.lexEnd);
		Scan(&(*p));
	} else {
		AddError(&(*p), error);
		(*begin) =  - 1;
		(*end) =  - 1;
	}
}

static struct Ast_RExprSet *Set(struct Parser *p, struct Ast_RDeclarations *ds);
static o7_int_t Set_Element(struct Ast_RExprSet **base, struct Ast_RExprSet **e, struct Parser *p, struct Ast_RDeclarations *ds) {
	struct Ast_RExpression *left;
	o7_int_t err;

	left = expression(&(*p), ds, (0 > 1));
	if (o7_cmp((*p).l, Scanner_Range_cnst) == 0) {
		Scan(&(*p));
		err = Ast_ExprSetNew(&(*base), &(*e), left, expression(&(*p), ds, (0 > 1)));
	} else {
		err = Ast_ExprSetNew(&(*base), &(*e), left, NULL);
	}
	return err;
}

static struct Ast_RExprSet *Set(struct Parser *p, struct Ast_RDeclarations *ds) {
	struct Ast_RExprSet *e = NULL, *next;
	o7_int_t err;

	O7_ASSERT(o7_cmp((*p).l, Scanner_Brace3Open_cnst) == 0);
	Scan(&(*p));
	if (o7_cmp((*p).l, Scanner_Brace3Close_cnst) != 0) {
		e = NULL;
		err = Set_Element(&e, &e, &(*p), ds);
		CheckAst(&(*p), err);
		next = e;
		while (ScanIfEqual(&(*p), Scanner_Comma_cnst)) {
			err = Set_Element(&e, &O7_REF(next)->next, &(*p), ds);
			CheckAst(&(*p), err);

			next = O7_REF(next)->next;
		}
		Expect(&(*p), Scanner_Brace3Close_cnst, Parser_ErrExpectBrace3Close_cnst);
	} else {
		CheckAst(&(*p), Ast_ExprSetNew(&e, &e, NULL, NULL));
		Scan(&(*p));
	}
	return e;
}

static struct Ast_RDeclaration *DeclarationGet(struct Ast_RDeclarations *ds, struct Parser *p) {
	struct Ast_RDeclaration *d = NULL;

	Log_StrLn(14, (o7_char *)"DeclarationGet");
	CheckAst(&(*p), Ast_DeclarationGet(&d, (*p).opt.provider, ds, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, o7_int((*p).s.lexStart), o7_int((*p).s.lexEnd)));
	return d;
}

static struct Ast_RDeclaration *ExpectDecl(struct Parser *p, struct Ast_RDeclarations *ds) {
	struct Ast_RDeclaration *d;

	if (o7_cmp((*p).l, Scanner_Ident_cnst) != 0) {
		d = Ast_DeclErrorNew(ds, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf,  - 1,  - 1);
		AddError(&(*p), Parser_ErrExpectIdent_cnst);
	} else {
		d = DeclarationGet(ds, &(*p));
		Scan(&(*p));
	}
	return d;
}

static struct Ast_RDeclaration *Qualident(struct Parser *p, struct Ast_RDeclarations *ds) {
	struct Ast_RDeclaration *d;

	Log_StrLn(9, (o7_char *)"Qualident");

	d = ExpectDecl(&(*p), ds);
	if (o7_is(d, &Ast_Import__s_tag)) {
		Expect(&(*p), Scanner_Dot_cnst, Parser_ErrExpectDot_cnst);
		d = ExpectDecl(&(*p), &O7_REF(O7_GUARD(Ast_Import__s, &d)->_.module_)->m->_);
	}
	return d;
}

static struct Ast_RDeclaration *ExpectRecordExtend(struct Parser *p, struct Ast_RDeclarations *ds, struct Ast_RConstruct *base) {
	struct Ast_RDeclaration *d;

	d = Qualident(&(*p), ds);
	return d;
}

static struct Ast_Designator__s *Designator(struct Parser *p, struct Ast_RDeclarations *ds);
static void Designator_SetSel(struct Ast_RSelector **prev, struct Ast_RSelector *sel, struct Ast_Designator__s *des) {
	if ((*prev) == NULL) {
		O7_REF(des)->sel = sel;
	} else {
		O7_REF((*prev))->next = sel;
	}
	(*prev) = sel;
}

static struct Ast_Designator__s *Designator(struct Parser *p, struct Ast_RDeclarations *ds) {
	struct Ast_Designator__s *des = NULL;
	struct Ast_RDeclaration *decl, *var_;
	struct Ast_RSelector *prev = NULL, *sel = NULL;
	o7_int_t nameBegin = O7_INT_UNDEF, nameEnd = O7_INT_UNDEF, ind, val;
	struct StringStore_String str;
	StringStore_String_undef(&str);

	Log_StrLn(10, (o7_char *)"Designator");

	O7_ASSERT(o7_cmp((*p).l, Scanner_Ident_cnst) == 0);
	decl = Qualident(&(*p), ds);
	CheckAst(&(*p), Ast_DesignatorNew(&des, decl));
	if (decl != NULL) {
		if ((o7_is(decl, &Ast_RVar_tag)) || (o7_is(decl, &Ast_Const__s_tag))) {
			prev = NULL;

			do {
				sel = NULL;
				if (o7_cmp((*p).l, Scanner_Dot_cnst) == 0) {
					Scan(&(*p));
					ExpectIdent(&(*p), &nameBegin, &nameEnd, Parser_ErrExpectIdent_cnst);
					if (o7_cmp(nameBegin, 0) >= 0) {
						CheckAst(&(*p), Ast_SelRecordNew(&sel, &O7_REF(des)->_._.type, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, o7_int(nameBegin), o7_int(nameEnd)));
					}
				} else if (o7_cmp((*p).l, Scanner_Brace1Open_cnst) == 0) {
					if (o7_in(O7_REF(O7_REF(des)->_._.type)->_._.id, ((1u << Ast_IdRecord_cnst) | (1u << Ast_IdPointer_cnst)))) {
						Scan(&(*p));
						var_ = ExpectRecordExtend(&(*p), ds, O7_GUARD(Ast_RConstruct, &O7_REF(des)->_._.type));
						CheckAst(&(*p), Ast_SelGuardNew(&sel, des, var_));
						Expect(&(*p), Scanner_Brace1Close_cnst, Parser_ErrExpectBrace1Close_cnst);
					} else if (!(o7_is(O7_REF(des)->_._.type, &Ast_RProcType_tag))) {
						AddError(&(*p), Parser_ErrExpectVarRecordOrPointer_cnst);
					}
				} else if (o7_cmp((*p).l, Scanner_Brace2Open_cnst) == 0) {
					Scan(&(*p));
					CheckAst(&(*p), Ast_SelArrayNew(&sel, &O7_REF(des)->_._.type, expression(&(*p), ds, (0 > 1))));
					if (O7_REF(des)->_._.value_ == NULL) {
					} else if ((o7_is(O7_REF(des)->_._.value_, &Ast_ExprString__s_tag)) && (O7_REF(O7_GUARD(Ast_SelArray__s, &sel)->index)->value_ != NULL)) {
						val = o7_int(O7_GUARD(Ast_ExprString__s, &O7_REF(des)->_._.value_)->_.int_);
						ind = o7_int(O7_GUARD(Ast_RExprInteger, &O7_REF(O7_GUARD(Ast_SelArray__s, &sel)->index)->value_)->int_);
						if (val < 0) {
							str = O7_GUARD(Ast_ExprString__s, &O7_REF(des)->_._.value_)->string;
							val = (o7_int_t)StringStore_GetChar(&str, o7_add(ind, 1));
						} else {
							O7_ASSERT(ind == 0);
						}
						O7_REF(des)->_._.value_ = (&(Ast_ExprCharNew(val))->_._._);
					} else {
						O7_REF(des)->_._.value_ = NULL;
					}
					while (ScanIfEqual(&(*p), Scanner_Comma_cnst)) {
						Designator_SetSel(&prev, sel, des);
						CheckAst(&(*p), Ast_SelArrayNew(&sel, &O7_REF(des)->_._.type, expression(&(*p), ds, (0 > 1))));
					}
					Expect(&(*p), Scanner_Brace2Close_cnst, Parser_ErrExpectBrace2Close_cnst);
				} else if (o7_cmp((*p).l, Scanner_Dereference_cnst) == 0) {
					CheckAst(&(*p), Ast_SelPointerNew(&sel, &O7_REF(des)->_._.type));
					Scan(&(*p));
				}
				Designator_SetSel(&prev, sel, des);
			} while (!(sel == NULL));
		} else if (!((o7_is(decl, &Ast_Const__s_tag)) || (o7_is(decl, &Ast_RGeneralProcedure_tag)) || (o7_cmp(O7_REF(decl)->_.id, Ast_IdError_cnst) == 0))) {
			AddError(&(*p), Parser_ErrExpectDesignator_cnst);
		}
	}
	return des;
}

static void CallParams(struct Parser *p, struct Ast_RDeclarations *ds, struct Ast_ExprCall__s *e) {
	struct Ast_RParameter *par = NULL;
	struct Ast_RFormalParam *fp;
	o7_bool varParam;

	O7_ASSERT(o7_cmp((*p).l, Scanner_Brace1Open_cnst) == 0);
	Scan(&(*p));
	if ((O7_REF(O7_REF(e)->designator)->_._.type != NULL) && (o7_is(O7_REF(O7_REF(e)->designator)->_._.type, &Ast_RProcType_tag))) {
		fp = O7_GUARD(Ast_RProcType, &O7_REF(O7_REF(e)->designator)->_._.type)->params;
	} else {
		fp = NULL;
	}
	if (!ScanIfEqual(&(*p), Scanner_Brace1Close_cnst)) {
		par = NULL;
		varParam = (fp == NULL) || (!!( (1u << Ast_ParamOut_cnst) & O7_REF(fp)->access)) && (!(o7_is(O7_REF(O7_REF(e)->designator)->decl, &Ast_PredefinedProcedure__s_tag)) || (o7_cmp(O7_REF(O7_REF(O7_REF(e)->designator)->decl)->_.id, OberonSpecIdent_New_cnst) == 0));
		(*p).callId = o7_int(O7_REF(O7_REF(O7_REF(e)->designator)->decl)->_.id);
		CheckAst(&(*p), Ast_CallParamNew(e, &par, expression(&(*p), ds, varParam), &fp));
		(*p).callId = 0;
		O7_REF(e)->params = par;
		while (ScanIfEqual(&(*p), Scanner_Comma_cnst)) {
			varParam = (fp == NULL) || (!!( (1u << Ast_ParamOut_cnst) & O7_REF(fp)->access));
			CheckAst(&(*p), Ast_CallParamNew(e, &par, expression(&(*p), ds, varParam), &fp));
		}
		Expect(&(*p), Scanner_Brace1Close_cnst, Parser_ErrExpectBrace1Close_cnst);
	}
	CheckAst(&(*p), Ast_CallParamsEnd(e, fp, ds));
}

static struct Ast_ExprCall__s *ExprCall(struct Parser *p, struct Ast_RDeclarations *ds, struct Ast_Designator__s *des) {
	struct Ast_ExprCall__s *e = NULL;

	CheckAst(&(*p), Ast_ExprCallNew(&e, des));
	CallParams(&(*p), ds, e);
	return e;
}

static struct Ast_RExpression *Factor(struct Parser *p, struct Ast_RDeclarations *ds, o7_bool varParam);
static void Factor_Ident(struct Parser *p, struct Ast_RDeclarations *ds, o7_bool varParam, struct Ast_RExpression **e) {
	struct Ast_Designator__s *des;

	des = Designator(&(*p), ds);
	if (o7_cmp((*p).callId, OberonSpecIdent_Len_cnst) != 0) {
		CheckAst(&(*p), Ast_DesignatorUsed(des, varParam, o7_cmp(0, (*p).inLoops) < 0));
	}
	if (o7_cmp((*p).l, Scanner_Brace1Open_cnst) != 0) {
		(*e) = (&(des)->_._);
	} else {
		(*e) = (&(ExprCall(&(*p), ds, des))->_._);
	}
}

static struct Ast_ExprNegate__s *Factor_Negate(struct Parser *p, struct Ast_RDeclarations *ds) {
	struct Ast_ExprNegate__s *neg = NULL;

	O7_ASSERT(o7_cmp((*p).l, Scanner_Negate_cnst) == 0);
	Scan(&(*p));
	CheckAst(&(*p), Ast_ExprNegateNew(&neg, Factor(&(*p), ds, (0 > 1))));
	return neg;
}

static struct Ast_RExpression *Factor(struct Parser *p, struct Ast_RDeclarations *ds, o7_bool varParam) {
	struct Ast_RExpression *e = NULL;

	Log_StrLn(6, (o7_char *)"Factor");

	if (o7_cmp((*p).l, Scanner_Number_cnst) == 0) {
		if (o7_bl((*p).s.isReal)) {
			e = (&(Ast_ExprRealNew(o7_dbl((*p).s.real), (*p).module_, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, o7_int((*p).s.lexStart), o7_int((*p).s.lexEnd)))->_._._);
		} else {
			e = (&(Ast_ExprIntegerNew(o7_int((*p).s.integer)))->_._._);
		}
		Scan(&(*p));
	} else if ((o7_cmp((*p).l, OberonSpecIdent_True_cnst) == 0) || (o7_cmp((*p).l, OberonSpecIdent_False_cnst) == 0)) {
		e = (&(Ast_ExprBooleanGet(o7_cmp((*p).l, OberonSpecIdent_True_cnst) == 0))->_._);
		Scan(&(*p));
	} else if (o7_cmp((*p).l, OberonSpecIdent_Nil_cnst) == 0) {
		e = (&(Ast_ExprNilGet())->_._);
		Scan(&(*p));
	} else if (o7_cmp((*p).l, Scanner_String_cnst) == 0) {
		if (o7_bl((*p).s.isChar)) {
			e = (&(Ast_ExprCharNew(o7_int((*p).s.integer)))->_._._._);
		} else {
			e = (&(Ast_ExprStringNew((*p).module_, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, o7_int((*p).s.lexStart), o7_int((*p).s.lexEnd)))->_._._._);
		}
		Scan(&(*p));
	} else if (o7_cmp((*p).l, Scanner_Brace1Open_cnst) == 0) {
		Scan(&(*p));
		e = (&(Ast_ExprBracesNew(expression(&(*p), ds, (0 > 1))))->_._);
		Expect(&(*p), Scanner_Brace1Close_cnst, Parser_ErrExpectBrace1Close_cnst);
	} else if (o7_cmp((*p).l, Scanner_Ident_cnst) == 0) {
		Factor_Ident(&(*p), ds, varParam, &e);
	} else if (o7_cmp((*p).l, Scanner_Brace3Open_cnst) == 0) {
		e = (&(Set(&(*p), ds))->_._);
	} else if (o7_cmp((*p).l, Scanner_Negate_cnst) == 0) {
		e = (&(Factor_Negate(&(*p), ds))->_._);
	} else {
		AddError(&(*p), Parser_ErrExpectExpression_cnst);
		e = Ast_ExprErrNew();
	}
	return e;
}

static struct Ast_RExpression *Term(struct Parser *p, struct Ast_RDeclarations *ds, o7_bool varParam) {
	struct Ast_RExpression *e;
	struct Ast_ExprTerm__s *term = NULL;
	o7_int_t l;
	o7_bool turnIf;

	Log_StrLn(4, (o7_char *)"Term");
	e = Factor(&(*p), ds, varParam);
	if ((o7_cmp(Scanner_MultFirst_cnst, (*p).l) <= 0) && (o7_cmp((*p).l, Scanner_MultLast_cnst) <= 0)) {
		l = o7_int((*p).l);

		turnIf = (l == Scanner_And_cnst);
		if (turnIf) {
			Ast_TurnIf(ds);
		}

		Scan(&(*p));
		term = NULL;
		CheckAst(&(*p), Ast_ExprTermNew(&term, O7_GUARD(Ast_RFactor, &e), l, Factor(&(*p), ds, (0 > 1))));
		O7_ASSERT((O7_REF(term)->expr != NULL) && (O7_REF(term)->factor != NULL));
		e = (&(term)->_);
		while ((o7_cmp(Scanner_MultFirst_cnst, (*p).l) <= 0) && (o7_cmp((*p).l, Scanner_MultLast_cnst) <= 0)) {
			l = o7_int((*p).l);
			Scan(&(*p));
			CheckAst(&(*p), Ast_ExprTermAdd(e, &term, l, Factor(&(*p), ds, (0 > 1))));
		}

		if (turnIf) {
			Ast_BackFromBranch(ds);
		}
	}
	return e;
}

static struct Ast_RExpression *Sum(struct Parser *p, struct Ast_RDeclarations *ds, o7_bool varParam) {
	struct Ast_RExpression *e;
	struct Ast_RExprSum *sum = NULL;
	o7_int_t l;

	Log_StrLn(3, (o7_char *)"Sum");
	l = o7_int((*p).l);

	if (o7_in(l, ((1u << Scanner_Plus_cnst) | (1u << Scanner_Minus_cnst)))) {
		Scan(&(*p));
		CheckAst(&(*p), Ast_ExprSumNew(&sum, l, Term(&(*p), ds, (0 > 1))));
		e = (&(sum)->_);
	} else {
		e = Term(&(*p), ds, varParam);
		if (o7_in((*p).l, ((1u << Scanner_Plus_cnst) | (1u << Scanner_Minus_cnst) | (1u << Scanner_Or_cnst)))) {
			if (o7_cmp((*p).l, Scanner_Or_cnst) != 0) {
				CheckAst(&(*p), Ast_ExprSumNew(&sum, Ast_NoSign_cnst, e));
			} else {
				Ast_TurnIf(ds);
				CheckAst(&(*p), Ast_ExprSumNew(&sum, Ast_NoSign_cnst, e));
				Ast_BackFromBranch(ds);
			}
			e = (&(sum)->_);
		}
	}
	while (o7_in((*p).l, ((1u << Scanner_Plus_cnst) | (1u << Scanner_Minus_cnst) | (1u << Scanner_Or_cnst)))) {
		l = o7_int((*p).l);
		Scan(&(*p));
		if (l != Scanner_Or_cnst) {
			CheckAst(&(*p), Ast_ExprSumAdd(e, &sum, l, Term(&(*p), ds, (0 > 1))));
		} else {
			Ast_TurnIf(ds);
			CheckAst(&(*p), Ast_ExprSumAdd(e, &sum, l, Term(&(*p), ds, (0 > 1))));
			Ast_BackFromBranch(ds);
		}
	}
	return e;
}

static struct Ast_RExpression *Expression(struct Parser *p, struct Ast_RDeclarations *ds, o7_bool varParam) {
	struct Ast_RExpression *expr;
	struct Ast_ExprRelation__s *e = NULL;
	struct Ast_ExprIsExtension__s *isExt = NULL;
	o7_int_t rel;

	expr = Sum(&(*p), ds, varParam);
	if ((o7_cmp(Scanner_RelationFirst_cnst, (*p).l) <= 0) && (o7_cmp((*p).l, Scanner_RelationLast_cnst) < 0)) {
		rel = o7_int((*p).l);
		Scan(&(*p));
		CheckAst(&(*p), Ast_ExprRelationNew(&e, expr, rel, Sum(&(*p), ds, (0 > 1))));
		expr = (&(e)->_);
	} else if (ScanIfEqual(&(*p), Scanner_Is_cnst)) {
		CheckAst(&(*p), Ast_ExprIsExtensionNew(&isExt, expr, type(&(*p), ds,  - 1,  - 1)));
		expr = (&(isExt)->_);
	}
	return expr;
}

static void DeclComment(struct Parser *p, struct Ast_RDeclaration *d) {
	o7_int_t comOfs = O7_INT_UNDEF, comEnd = O7_INT_UNDEF;

	if (o7_bl((*p).opt.saveComments) && Scanner_TakeCommentPos(&(*p).s, &comOfs, &comEnd)) {
		Ast_DeclSetComment(d, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, o7_int(comOfs), o7_int(comEnd));
	}
}

static void Mark(struct Parser *p, struct Ast_RDeclaration *d) {
	DeclComment(&(*p), d);
	O7_REF(d)->mark = ScanIfEqual(&(*p), Scanner_Asterisk_cnst);
}

static void Consts(struct Parser *p, struct Ast_RDeclarations *ds) {
	o7_int_t begin = O7_INT_UNDEF, end = O7_INT_UNDEF, emptyLines;
	struct Ast_Const__s *const_;

	Scan(&(*p));
	while (o7_cmp((*p).l, Scanner_Ident_cnst) == 0) {
		if (!o7_bl((*p).err)) {
			emptyLines = o7_int((*p).s.emptyLines);
			ExpectIdent(&(*p), &begin, &end, Parser_ErrExpectConstName_cnst);
			CheckAst(&(*p), Ast_ConstAdd(ds, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, o7_int(begin), o7_int(end)));
			const_ = O7_GUARD(Ast_Const__s, &O7_REF(ds)->end);
			O7_REF(const_)->_._.emptyLines = emptyLines;
			Mark(&(*p), &const_->_);
			Expect(&(*p), Scanner_Equal_cnst, Parser_ErrExpectEqual_cnst);
			CheckAst(&(*p), Ast_ConstSetExpression(const_, Expression(&(*p), ds, (0 > 1))));
			Expect(&(*p), Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
		}
		if (o7_bl((*p).err)) {
			while ((o7_cmp(Scanner_EndOfFile_cnst, (*p).l) < 0) && (o7_cmp((*p).l, OberonSpecIdent_Import_cnst) < 0) && (o7_cmp((*p).l, Scanner_Semicolon_cnst) != 0)) {
				Scan(&(*p));
			}
			(*p).err = (0 > 1);
		}
	}
}

static struct Ast_RArray *Array(struct Parser *p, struct Ast_RDeclarations *ds, o7_int_t nameBegin, o7_int_t nameEnd) {
	struct Ast_RArray *a;
	struct Ast_RType *t;
	struct Ast_RExpression *exprLen;
	struct Ast_RExpression *lens[TranslatorLimits_ArrayDimension_cnst];
	o7_int_t i, size;
	memset(&lens, 0, sizeof(lens));

	Log_StrLn(5, (o7_char *)"Array");
	O7_ASSERT(o7_cmp((*p).l, OberonSpecIdent_Array_cnst) == 0);
	Scan(&(*p));
	a = Ast_ArrayGet(NULL, Expression(&(*p), ds, (0 > 1)));
	if (nameBegin >= 0) {
		t = (&(a)->_._);
		CheckAst(&(*p), Ast_TypeAdd(ds, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, nameBegin, nameEnd, &t));
	}
	size = 1;
	CheckAst(&(*p), Ast_MultArrayLenByExpr(&size, O7_REF(a)->count));
	i = 0;
	while (ScanIfEqual(&(*p), Scanner_Comma_cnst)) {
		exprLen = Expression(&(*p), ds, (0 > 1));
		CheckAst(&(*p), Ast_MultArrayLenByExpr(&size, exprLen));
		if (i < O7_LEN(lens)) {
			lens[o7_ind(TranslatorLimits_ArrayDimension_cnst, i)] = exprLen;
		}
		i = o7_add(i, 1);
	}
	if (O7_LEN(lens) < i) {
		AddError(&(*p), Parser_ErrArrayDimensionsTooMany_cnst);
	}
	Expect(&(*p), OberonSpecIdent_Of_cnst, Parser_ErrExpectOf_cnst);
	CheckAst(&(*p), Ast_ArraySetType(a, type(&(*p), ds,  - 1,  - 1)));
	while (0 < i) {
		i = o7_sub(i, 1);
		O7_REF(a)->_._._.type = (&(Ast_ArrayGet(O7_REF(a)->_._._.type, lens[o7_ind(TranslatorLimits_ArrayDimension_cnst, i)]))->_._);
	}
	return a;
}

static struct Ast_RType *TypeNamed(struct Parser *p, struct Ast_RDeclarations *ds) {
	struct Ast_RDeclaration *d;
	struct Ast_RType *t;

	t = NULL;
	d = Qualident(&(*p), ds);
	if (d != NULL) {
		if (o7_is(d, &Ast_RType_tag)) {
			t = O7_GUARD(Ast_RType, &d);
		} else if (o7_cmp(O7_REF(d)->_.id, Ast_IdError_cnst) != 0) {
			AddError(&(*p), Parser_ErrExpectType_cnst);
		}
	}
	if (t == NULL) {
		t = Ast_TypeErrorNew();
	}
	return t;
}

static void VarDeclaration(struct Parser *p, struct Ast_RDeclarations *dsAdd, struct Ast_RDeclarations *dsTypes);
static void VarDeclaration_Name(struct Parser *p, struct Ast_RDeclarations *ds) {
	o7_int_t begin = O7_INT_UNDEF, end = O7_INT_UNDEF, emptyLines;
	struct Ast_RVar *v = NULL;

	emptyLines = o7_int((*p).s.emptyLines);
	ExpectIdent(&(*p), &begin, &end, Parser_ErrExpectIdent_cnst);
	CheckAst(&(*p), Ast_VarAdd(&v, ds, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, o7_int(begin), o7_int(end)));
	O7_REF(v)->_._.emptyLines = emptyLines;
	DeclComment(&(*p), &v->_);
	Mark(&(*p), &v->_);
}

static void VarDeclaration(struct Parser *p, struct Ast_RDeclarations *dsAdd, struct Ast_RDeclarations *dsTypes) {
	struct Ast_RDeclaration *var_;
	struct Ast_RType *typ;

	VarDeclaration_Name(&(*p), dsAdd);
	var_ = (&(O7_GUARD(Ast_RVar, &O7_REF(dsAdd)->end))->_);
	while (ScanIfEqual(&(*p), Scanner_Comma_cnst)) {
		VarDeclaration_Name(&(*p), dsAdd);
	}
	Expect(&(*p), Scanner_Colon_cnst, Parser_ErrExpectColon_cnst);
	typ = type(&(*p), dsTypes,  - 1,  - 1);
	while (var_ != NULL) {
		O7_REF(var_)->type = typ;
		var_ = O7_REF(var_)->next;
	}
	CheckAst(&(*p), Ast_CheckUndefRecordForward(dsAdd));
}

static void Vars(struct Parser *p, struct Ast_RDeclarations *ds) {
	while (o7_cmp((*p).l, Scanner_Ident_cnst) == 0) {
		VarDeclaration(&(*p), ds, ds);
		Expect(&(*p), Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
	}
}

static struct Ast_RRecord *Record(struct Parser *p, struct Ast_RDeclarations *ds, struct Ast_RPointer *ptr, o7_int_t nameBegin, o7_int_t nameEnd);
static void Record_RecVars(struct Parser *p, struct Ast_RRecord *dsAdd, struct Ast_RDeclarations *dsTypes);
static void Record_RecVars_Declaration(struct Parser *p, struct Ast_RRecord *dsAdd, struct Ast_RDeclarations *dsTypes);
static void Record_RecVars_Declaration_Name(struct Ast_RVar **v, struct Parser *p, struct Ast_RRecord *ds) {
	o7_int_t begin = O7_INT_UNDEF, end = O7_INT_UNDEF, emptyLines;

	emptyLines = o7_int((*p).s.emptyLines);
	ExpectIdent(&(*p), &begin, &end, Parser_ErrExpectIdent_cnst);
	CheckAst(&(*p), Ast_RecordVarAdd(&(*v), ds, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, o7_int(begin), o7_int(end)));
	O7_REF((*v))->_._.emptyLines = emptyLines;
	Mark(&(*p), &(*v)->_);
}

static void Record_RecVars_Declaration(struct Parser *p, struct Ast_RRecord *dsAdd, struct Ast_RDeclarations *dsTypes) {
	struct Ast_RVar *var_ = NULL;
	struct Ast_RDeclaration *d;
	struct Ast_RType *typ;

	Record_RecVars_Declaration_Name(&var_, &(*p), dsAdd);
	d = (&(var_)->_);
	while (ScanIfEqual(&(*p), Scanner_Comma_cnst)) {
		Record_RecVars_Declaration_Name(&var_, &(*p), dsAdd);
	}
	Expect(&(*p), Scanner_Colon_cnst, Parser_ErrExpectColon_cnst);
	typ = type(&(*p), dsTypes,  - 1,  - 1);
	CheckAst(&(*p), Ast_VarListSetType(d, typ));
}

static void Record_RecVars(struct Parser *p, struct Ast_RRecord *dsAdd, struct Ast_RDeclarations *dsTypes) {
	if (o7_cmp((*p).l, Scanner_Ident_cnst) == 0) {
		Record_RecVars_Declaration(&(*p), dsAdd, dsTypes);
		while (ScanIfEqual(&(*p), Scanner_Semicolon_cnst)) {
			if (o7_cmp((*p).l, OberonSpecIdent_End_cnst) != 0) {
				Record_RecVars_Declaration(&(*p), dsAdd, dsTypes);
			} else if (o7_bl((*p).opt.strictSemicolon)) {
				AddError(&(*p), Parser_ErrExcessSemicolon_cnst);
				(*p).err = (0 > 1);
			}
		}
	}
}

static struct Ast_RRecord *Record(struct Parser *p, struct Ast_RDeclarations *ds, struct Ast_RPointer *ptr, o7_int_t nameBegin, o7_int_t nameEnd) {
	struct Ast_RRecord *rec, *base;
	struct Ast_RType *t;
	struct Ast_RDeclaration *decl;

	O7_ASSERT(o7_cmp((*p).l, OberonSpecIdent_Record_cnst) == 0);
	Scan(&(*p));
	base = NULL;
	if (ScanIfEqual(&(*p), Scanner_Brace1Open_cnst)) {
		decl = Qualident(&(*p), ds);
		if ((decl != NULL) && (o7_cmp(O7_REF(decl)->_.id, Ast_IdRecord_cnst) == 0)) {
			base = O7_GUARD(Ast_RRecord, &decl);
		} else {
			AddError(&(*p), Parser_ErrExpectRecord_cnst);
		}
		Expect(&(*p), Scanner_Brace1Close_cnst, Parser_ErrExpectBrace1Close_cnst);
	}
	rec = Ast_RecordNew(ds, base);
	if (ptr != NULL) {
		Ast_PointerSetRecord(ptr, rec);
	}
	if (nameBegin >= 0) {
		t = (&(rec)->_._);
		CheckAst(&(*p), Ast_TypeAdd(ds, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, nameBegin, nameEnd, &t));
		if (&rec->_._ != t) {
			rec = O7_GUARD(Ast_RRecord, &t);
			Ast_RecordSetBase(rec, base);
		}
	} else {
		StringStore_Undef(&O7_REF(rec)->_._._.name);
		O7_REF(rec)->_._._.module_ = O7_REF((*p).module_)->bag;
	}
	Record_RecVars(&(*p), rec, ds);
	Expect(&(*p), OberonSpecIdent_End_cnst, Parser_ErrExpectEnd_cnst);
	CheckAst(&(*p), Ast_RecordEnd(rec));
	return rec;
}

static struct Ast_RPointer *Pointer(struct Parser *p, struct Ast_RDeclarations *ds, o7_int_t nameBegin, o7_int_t nameEnd) {
	struct Ast_RPointer *tp;
	struct Ast_RType *t;
	struct Ast_RDeclaration *decl;
	struct Ast_RRecord *typeDecl;

	O7_ASSERT(o7_cmp((*p).l, OberonSpecIdent_Pointer_cnst) == 0);
	Scan(&(*p));
	tp = Ast_PointerGet(NULL);
	if (nameBegin >= 0) {
		t = (&(tp)->_._);
		O7_ASSERT(t != NULL);
		CheckAst(&(*p), Ast_TypeAdd(ds, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, nameBegin, nameEnd, &t));
	}
	Expect(&(*p), OberonSpecIdent_To_cnst, Parser_ErrExpectTo_cnst);
	if (o7_cmp((*p).l, OberonSpecIdent_Record_cnst) == 0) {
		typeDecl = Record(&(*p), ds, tp,  - 1,  - 1);
		O7_ASSERT(O7_REF(typeDecl)->pointer == tp);
	} else if (o7_cmp((*p).l, Scanner_Ident_cnst) == 0) {
		decl = Ast_DeclarationSearch(ds, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, o7_int((*p).s.lexStart), o7_int((*p).s.lexEnd));
		if (decl == NULL) {
			typeDecl = Ast_RecordForwardNew(ds, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, o7_int((*p).s.lexStart), o7_int((*p).s.lexEnd));
			O7_ASSERT((O7_REF(tp)->_._._.next == &typeDecl->_._._) || (nameBegin < 0));
			Ast_PointerSetRecord(tp, typeDecl);

			Scan(&(*p));
		} else if (o7_is(decl, &Ast_RRecord_tag)) {
			Ast_PointerSetRecord(tp, O7_GUARD(Ast_RRecord, &decl));
			Scan(&(*p));
		} else {
			CheckAst(&(*p), Ast_PointerSetType(tp, TypeNamed(&(*p), ds)));
		}
	} else {
		AddError(&(*p), Parser_ErrExpectRecord_cnst);
	}
	return tp;
}

static void FormalParameters(struct Parser *p, struct Ast_RDeclarations *ds, struct Ast_RProcType *proc);
static void FormalParameters_Section(struct Parser *p, struct Ast_RDeclarations *ds, struct Ast_RProcType *proc);
static void FormalParameters_Section_Name(struct Parser *p, struct Ast_RProcType *proc, o7_set_t access) {
	if (o7_cmp((*p).l, Scanner_Ident_cnst) != 0) {
		AddError(&(*p), Parser_ErrExpectIdent_cnst);
	} else {
		CheckAst(&(*p), Ast_ParamAdd((*p).module_, proc, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, o7_int((*p).s.lexStart), o7_int((*p).s.lexEnd), access));
		Scan(&(*p));
	}
}

static struct Ast_RType *FormalParameters_Section_Type(struct Parser *p, struct Ast_RDeclarations *ds) {
	struct Ast_RType *t;
	o7_int_t arrs;

	arrs = 0;
	while (ScanIfEqual(&(*p), OberonSpecIdent_Array_cnst)) {
		Expect(&(*p), OberonSpecIdent_Of_cnst, Parser_ErrExpectOf_cnst);
		arrs = o7_add(arrs, 1);
	}
	t = TypeNamed(&(*p), ds);
	while ((t != NULL) && (arrs > 0)) {
		t = (&(Ast_ArrayGet(t, NULL))->_._);
		arrs = o7_sub(arrs, 1);
	}
	return t;
}

static void FormalParameters_Section(struct Parser *p, struct Ast_RDeclarations *ds, struct Ast_RProcType *proc) {
	o7_set_t access;
	struct Ast_RDeclaration *param;

	if (ScanIfEqual(&(*p), OberonSpecIdent_Var_cnst)) {
		access = ((1u << Ast_ParamIn_cnst) | (1u << Ast_ParamOut_cnst));
	} else {
		access = 0;
	}
	FormalParameters_Section_Name(&(*p), proc, access);
	param = (&(O7_REF(proc)->end)->_._);
	while (ScanIfEqual(&(*p), Scanner_Comma_cnst)) {
		FormalParameters_Section_Name(&(*p), proc, access);
	}
	Expect(&(*p), Scanner_Colon_cnst, Parser_ErrExpectColon_cnst);
	CheckAst(&(*p), Ast_VarListSetType(param, FormalParameters_Section_Type(&(*p), ds)));
}

static void FormalParameters(struct Parser *p, struct Ast_RDeclarations *ds, struct Ast_RProcType *proc) {
	o7_bool braces;

	braces = ScanIfEqual(&(*p), Scanner_Brace1Open_cnst);
	if (braces && !ScanIfEqual(&(*p), Scanner_Brace1Close_cnst)) {
		FormalParameters_Section(&(*p), ds, proc);
		while (ScanIfEqual(&(*p), Scanner_Semicolon_cnst)) {
			FormalParameters_Section(&(*p), ds, proc);
		}
		Expect(&(*p), Scanner_Brace1Close_cnst, Parser_ErrExpectBrace1Close_cnst);
	}
	if (ScanIfEqual(&(*p), Scanner_Colon_cnst)) {
		if (!braces) {
			AddError(&(*p), Parser_ErrFunctionWithoutBraces_cnst);
			(*p).err = (0 > 1);
		}
		CheckAst(&(*p), Ast_ProcTypeSetReturn(proc, TypeNamed(&(*p), ds)));
	}
}

static struct Ast_RProcType *TypeProcedure(struct Parser *p, struct Ast_RDeclarations *ds, o7_int_t nameBegin, o7_int_t nameEnd) {
	struct Ast_RProcType *proc;
	struct Ast_RType *t;

	O7_ASSERT(o7_cmp((*p).l, OberonSpecIdent_Procedure_cnst) == 0);
	Scan(&(*p));
	proc = Ast_ProcTypeNew((0 < 1));
	if (0 <= nameBegin) {
		t = (&(proc)->_._);
		CheckAst(&(*p), Ast_TypeAdd(ds, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, nameBegin, nameEnd, &t));
	}
	FormalParameters(&(*p), ds, proc);
	return proc;
}

static struct Ast_RType *Type(struct Parser *p, struct Ast_RDeclarations *ds, o7_int_t nameBegin, o7_int_t nameEnd) {
	struct Ast_RType *t;

	if (o7_cmp((*p).l, OberonSpecIdent_Array_cnst) == 0) {
		t = (&(Array(&(*p), ds, nameBegin, nameEnd))->_._);
	} else if (o7_cmp((*p).l, OberonSpecIdent_Pointer_cnst) == 0) {
		t = (&(Pointer(&(*p), ds, nameBegin, nameEnd))->_._);
	} else if (o7_cmp((*p).l, OberonSpecIdent_Procedure_cnst) == 0) {
		t = (&(TypeProcedure(&(*p), ds, nameBegin, nameEnd))->_._);
	} else if (o7_cmp((*p).l, OberonSpecIdent_Record_cnst) == 0) {
		t = (&(Record(&(*p), ds, NULL, nameBegin, nameEnd))->_._);
	} else if (o7_cmp((*p).l, Scanner_Ident_cnst) == 0) {
		t = TypeNamed(&(*p), ds);
	} else {
		t = Ast_TypeErrorNew();
		AddError(&(*p), Parser_ErrExpectType_cnst);
	}
	return t;
}

static void Types(struct Parser *p, struct Ast_RDeclarations *ds) {
	struct Ast_RType *typ;
	o7_int_t begin, end, emptyLines;
	o7_bool mark;

	Scan(&(*p));
	while (o7_cmp((*p).l, Scanner_Ident_cnst) == 0) {
		emptyLines = o7_int((*p).s.emptyLines);
		begin = o7_int((*p).s.lexStart);
		end = o7_int((*p).s.lexEnd);
		Scan(&(*p));
		mark = ScanIfEqual(&(*p), Scanner_Asterisk_cnst);
		Expect(&(*p), Scanner_Equal_cnst, Parser_ErrExpectEqual_cnst);
		typ = Type(&(*p), ds, begin, end);
		if (typ != NULL) {
			O7_REF(typ)->_._.emptyLines = emptyLines;
			O7_REF(typ)->_.mark = mark;
			if (!(o7_is(typ, &Ast_RConstruct_tag))) {
				AddError(&(*p), Parser_ErrExpectStructuredType_cnst);
			}
		}
		Expect(&(*p), Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
	}
	CheckAst(&(*p), Ast_CheckUndefRecordForward(ds));
}

static struct Ast_If__s *If(struct Parser *p, struct Ast_RDeclarations *ds);
static struct Ast_If__s *If_Branch(struct Parser *p, struct Ast_RDeclarations *ds) {
	struct Ast_If__s *if_ = NULL;

	Scan(&(*p));
	CheckAst(&(*p), Ast_IfNew(&if_, Expression(&(*p), ds, (0 > 1)), NULL));
	Ast_TurnIf(ds);
	Expect(&(*p), OberonSpecIdent_Then_cnst, Parser_ErrExpectThen_cnst);
	O7_REF(if_)->_.stats = statements(&(*p), ds);
	return if_;
}

static struct Ast_If__s *If(struct Parser *p, struct Ast_RDeclarations *ds) {
	struct Ast_If__s *if_, *else_ = NULL;
	struct Ast_RWhileIf *elsif;
	o7_int_t i;

	O7_ASSERT(o7_cmp((*p).l, OberonSpecIdent_If_cnst) == 0);
	if_ = If_Branch(&(*p), ds);
	elsif = (&(if_)->_);
	i = 1;
	while (o7_cmp((*p).l, OberonSpecIdent_Elsif_cnst) == 0) {
		i = o7_add(i, 1);
		Ast_TurnElse(ds);
		O7_REF(elsif)->elsif = (&(If_Branch(&(*p), ds))->_);
		elsif = O7_REF(elsif)->elsif;
	}
	if (ScanIfEqual(&(*p), OberonSpecIdent_Else_cnst)) {
		Ast_TurnElse(ds);
		CheckAst(&(*p), Ast_IfNew(&else_, NULL, statements(&(*p), ds)));
		O7_REF(elsif)->elsif = (&(else_)->_);
	}
	do {
		i = o7_sub(i, 1);
		Ast_BackFromBranch(ds);
	} while (!(i == 0));
	Expect(&(*p), OberonSpecIdent_End_cnst, Parser_ErrExpectEnd_cnst);
	return if_;
}

static struct Ast_Case__s *Case(struct Parser *p, struct Ast_RDeclarations *ds);
static void Case_Element(struct Parser *p, struct Ast_RDeclarations *ds, struct Ast_Case__s *case_);
static struct Ast_RCaseLabel *Case_Element_LabelList(struct Parser *p, struct Ast_Case__s *case_, struct Ast_RDeclarations *ds);
static struct Ast_RCaseLabel *Case_Element_LabelList_LabelRange(struct Parser *p, struct Ast_RDeclarations *ds);
static struct Ast_RCaseLabel *Case_Element_LabelList_LabelRange_Label(struct Parser *p, struct Ast_RDeclarations *ds) {
	struct Ast_RCaseLabel *l = NULL;
	o7_int_t i;

	if ((o7_cmp((*p).l, Scanner_Number_cnst) == 0) && !o7_bl((*p).s.isReal)) {
		CheckAst(&(*p), Ast_CaseLabelNew(&l, Ast_IdInteger_cnst, o7_int((*p).s.integer)));
		Scan(&(*p));
	} else if (o7_cmp((*p).l, Scanner_String_cnst) == 0) {
		if (o7_bl((*p).s.isChar)) {
			i = o7_int((*p).s.integer);
		} else {
			AddError(&(*p), Parser_ErrUnexpectStringInCaseLabel_cnst);
			i =  - 1;
		}
		CheckAst(&(*p), Ast_CaseLabelNew(&l, Ast_IdChar_cnst, i));
		Scan(&(*p));
	} else if (o7_cmp((*p).l, Scanner_Ident_cnst) == 0) {
		CheckAst(&(*p), Ast_CaseLabelQualNew(&l, Qualident(&(*p), ds)));
	} else {
		CheckAst(&(*p), Ast_CaseLabelNew(&l, Ast_IdInteger_cnst, 0));
		AddError(&(*p), Parser_ErrExpectIntOrStrOrQualident_cnst);
	}
	return l;
}

static struct Ast_RCaseLabel *Case_Element_LabelList_LabelRange(struct Parser *p, struct Ast_RDeclarations *ds) {
	struct Ast_RCaseLabel *r;

	r = Case_Element_LabelList_LabelRange_Label(&(*p), ds);
	if (o7_cmp((*p).l, Scanner_Range_cnst) == 0) {
		Scan(&(*p));
		CheckAst(&(*p), Ast_CaseRangeNew(r, Case_Element_LabelList_LabelRange_Label(&(*p), ds)));
	}
	return r;
}

static struct Ast_RCaseLabel *Case_Element_LabelList(struct Parser *p, struct Ast_Case__s *case_, struct Ast_RDeclarations *ds) {
	struct Ast_RCaseLabel *first, *last;

	first = Case_Element_LabelList_LabelRange(&(*p), ds);
	CheckAst(&(*p), Ast_CaseRangeListAdd(case_, NULL, first));
	while (o7_cmp((*p).l, Scanner_Comma_cnst) == 0) {
		Scan(&(*p));
		last = Case_Element_LabelList_LabelRange(&(*p), ds);
		CheckAst(&(*p), Ast_CaseRangeListAdd(case_, first, last));
	}
	return first;
}

static void Case_Element(struct Parser *p, struct Ast_RDeclarations *ds, struct Ast_Case__s *case_) {
	struct Ast_RCaseElement *elem;

	Ast_TurnIf(ds);
	elem = Ast_CaseElementNew(Case_Element_LabelList(&(*p), case_, ds));
	Expect(&(*p), Scanner_Colon_cnst, Parser_ErrExpectColon_cnst);
	O7_REF(elem)->stats = statements(&(*p), ds);

	CheckAst(&(*p), Ast_CaseElementAdd(case_, elem));
}

static struct Ast_Case__s *Case(struct Parser *p, struct Ast_RDeclarations *ds) {
	struct Ast_Case__s *case_ = NULL;
	o7_int_t i;

	O7_ASSERT(o7_cmp((*p).l, OberonSpecIdent_Case_cnst) == 0);
	Scan(&(*p));
	CheckAst(&(*p), Ast_CaseNew(&case_, Expression(&(*p), ds, (0 > 1))));
	Expect(&(*p), OberonSpecIdent_Of_cnst, Parser_ErrExpectOf_cnst);
	i = 1;
	while (ScanIfEqual(&(*p), Scanner_Alternative_cnst)) {
	}
	Case_Element(&(*p), ds, case_);
	while (ScanIfEqual(&(*p), Scanner_Alternative_cnst)) {
		while (ScanIfEqual(&(*p), Scanner_Alternative_cnst)) {
		}
		i = o7_add(i, 1);
		Ast_TurnElse(ds);
		Case_Element(&(*p), ds, case_);
	}
	Ast_TurnElse(ds);
	Ast_TurnFail(ds);
	do {
		i = o7_sub(i, 1);
		Ast_BackFromBranch(ds);
	} while (!(i == 0));
	Expect(&(*p), OberonSpecIdent_End_cnst, Parser_ErrExpectEnd_cnst);
	return case_;
}

static void DecInLoops(struct Parser *p, struct Ast_RDeclarations *ds) {
	(*p).inLoops = o7_sub((*p).inLoops, 1);
	O7_ASSERT(o7_cmp(0, (*p).inLoops) <= 0);
	if ((o7_cmp((*p).inLoops, 0) == 0) && (O7_REF(ds)->_.up != NULL)) {
		CheckAst(&(*p), Ast_CheckInited(ds));
	}
}

static struct Ast_Repeat__s *Repeat(struct Parser *p, struct Ast_RDeclarations *ds) {
	struct Ast_Repeat__s *r = NULL;

	O7_ASSERT(o7_cmp((*p).l, OberonSpecIdent_Repeat_cnst) == 0);
	(*p).inLoops = o7_add((*p).inLoops, 1);
	Scan(&(*p));
	CheckAst(&(*p), Ast_RepeatNew(&r, statements(&(*p), ds)));
	Expect(&(*p), OberonSpecIdent_Until_cnst, Parser_ErrExpectUntil_cnst);
	DecInLoops(&(*p), ds);
	CheckAst(&(*p), Ast_RepeatSetUntil(r, Expression(&(*p), ds, (0 > 1))));
	return r;
}

static struct Ast_For__s *For(struct Parser *p, struct Ast_RDeclarations *ds) {
	struct Ast_For__s *f = NULL;
	struct Ast_RVar *v = NULL;
	o7_char errName[12];
	memset(&errName, 0, sizeof(errName));

	O7_ASSERT(o7_cmp((*p).l, OberonSpecIdent_For_cnst) == 0);
	Scan(&(*p));
	if (o7_cmp((*p).l, Scanner_Ident_cnst) != 0) {
		memcpy(errName, (o7_char *)"FORITERATOR", sizeof("FORITERATOR"));
		AddError(&(*p), o7_add(Parser_ErrExpectIdent_cnst, o7_mul(Ast_ForIteratorGet(&v, ds, 12, errName, 0, 10), 0)));
	} else {
		CheckAst(&(*p), Ast_ForIteratorGet(&v, ds, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, o7_int((*p).s.lexStart), o7_int((*p).s.lexEnd)));
	}
	Scan(&(*p));
	Expect(&(*p), Scanner_Assign_cnst, Parser_ErrExpectAssign_cnst);
	CheckAst(&(*p), Ast_ForNew(&f, v, Expression(&(*p), ds, (0 > 1)), NULL, 1, NULL));
	Expect(&(*p), OberonSpecIdent_To_cnst, Parser_ErrExpectTo_cnst);
	CheckAst(&(*p), Ast_ForSetTo(f, Expression(&(*p), ds, (0 > 1))));
	if (o7_cmp((*p).l, OberonSpecIdent_By_cnst) != 0) {
		CheckAst(&(*p), Ast_ForSetBy(f, NULL));
	} else {
		Scan(&(*p));
		CheckAst(&(*p), Ast_ForSetBy(f, Expression(&(*p), ds, (0 > 1))));
	}
	(*p).inLoops = o7_add((*p).inLoops, 1);
	Expect(&(*p), OberonSpecIdent_Do_cnst, Parser_ErrExpectDo_cnst);
	O7_REF(f)->stats = statements(&(*p), ds);
	Expect(&(*p), OberonSpecIdent_End_cnst, Parser_ErrExpectEnd_cnst);
	DecInLoops(&(*p), ds);
	return f;
}

static struct Ast_While__s *While(struct Parser *p, struct Ast_RDeclarations *ds) {
	struct Ast_While__s *w = NULL, *br = NULL;
	struct Ast_RWhileIf *elsif;

	O7_ASSERT(o7_cmp((*p).l, OberonSpecIdent_While_cnst) == 0);
	(*p).inLoops = o7_add((*p).inLoops, 1);
	Scan(&(*p));
	CheckAst(&(*p), Ast_WhileNew(&w, Expression(&(*p), ds, (0 > 1)), NULL));
	elsif = (&(w)->_);
	Expect(&(*p), OberonSpecIdent_Do_cnst, Parser_ErrExpectDo_cnst);
	O7_REF(w)->_.stats = statements(&(*p), ds);

	while (ScanIfEqual(&(*p), OberonSpecIdent_Elsif_cnst)) {
		CheckAst(&(*p), Ast_WhileNew(&br, Expression(&(*p), ds, (0 > 1)), NULL));
		O7_REF(elsif)->elsif = (&(br)->_);
		elsif = (&(br)->_);
		Expect(&(*p), OberonSpecIdent_Do_cnst, Parser_ErrExpectDo_cnst);
		O7_REF(elsif)->stats = statements(&(*p), ds);
	}
	Expect(&(*p), OberonSpecIdent_End_cnst, Parser_ErrExpectEnd_cnst);
	DecInLoops(&(*p), ds);
	return w;
}

static struct Ast_Assign__s *Assign(struct Parser *p, struct Ast_RDeclarations *ds, struct Ast_Designator__s *des) {
	struct Ast_Assign__s *st = NULL;

	O7_ASSERT(o7_cmp((*p).l, Scanner_Assign_cnst) == 0);
	Scan(&(*p));
	CheckAst(&(*p), Ast_AssignNew(&st, o7_cmp(0, (*p).inLoops) < 0, des, Expression(&(*p), ds, (0 > 1))));
	return st;
}

static struct Ast_Call__s *Call(struct Parser *p, struct Ast_RDeclarations *ds, struct Ast_Designator__s *des) {
	struct Ast_Call__s *st = NULL;

	CheckAst(&(*p), Ast_CallNew(&st, des));
	if (o7_cmp((*p).l, Scanner_Brace1Open_cnst) == 0) {
		CallParams(&(*p), ds, O7_GUARD(Ast_ExprCall__s, &O7_REF(st)->_.expr));
	} else if ((des != NULL) && (O7_REF(des)->_._.type != NULL) && (o7_is(O7_REF(des)->_._.type, &Ast_RProcType_tag))) {
		CheckAst(&(*p), Ast_CallParamsEnd(O7_GUARD(Ast_ExprCall__s, &O7_REF(st)->_.expr), O7_GUARD(Ast_RProcType, &O7_REF(des)->_._.type)->params, ds));
	}
	return st;
}

static o7_bool NotEnd(o7_int_t l) {
	return (l != OberonSpecIdent_End_cnst) && (l != OberonSpecIdent_Return_cnst) && (l != OberonSpecIdent_Else_cnst) && (l != OberonSpecIdent_Elsif_cnst) && (l != OberonSpecIdent_Until_cnst) && (l != Scanner_Alternative_cnst) && (l != Scanner_EndOfFile_cnst);
}

static struct Ast_RStatement *Statements(struct Parser *p, struct Ast_RDeclarations *ds);
static struct Ast_RStatement *Statements_Statement(struct Parser *p, struct Ast_RDeclarations *ds) {
	struct Ast_Designator__s *des;
	struct Ast_RStatement *st;
	o7_int_t commentOfs = O7_INT_UNDEF, commentEnd = O7_INT_UNDEF, emptyLines;

	if (!o7_bl((*p).opt.saveComments) || !Scanner_TakeCommentPos(&(*p).s, &commentOfs, &commentEnd)) {
		commentOfs =  - 1;
	}
	emptyLines = o7_int((*p).s.emptyLines);
	if (o7_cmp((*p).l, Scanner_Ident_cnst) == 0) {
		des = Designator(&(*p), ds);
		if (o7_cmp((*p).l, Scanner_Assign_cnst) == 0) {
			st = (&(Assign(&(*p), ds, des))->_);
		} else if (o7_cmp((*p).l, Scanner_Equal_cnst) == 0) {
			AddError(&(*p), Parser_ErrMaybeAssignInsteadEqual_cnst);
			st = (&(Ast_StatementErrorNew())->_);
		} else {
			st = (&(Call(&(*p), ds, des))->_);
		}
	} else if (o7_cmp((*p).l, OberonSpecIdent_If_cnst) == 0) {
		st = (&(If(&(*p), ds))->_._);
	} else if (o7_cmp((*p).l, OberonSpecIdent_Case_cnst) == 0) {
		st = (&(Case(&(*p), ds))->_);
	} else if (o7_cmp((*p).l, OberonSpecIdent_Repeat_cnst) == 0) {
		st = (&(Repeat(&(*p), ds))->_);
	} else if (o7_cmp((*p).l, OberonSpecIdent_For_cnst) == 0) {
		st = (&(For(&(*p), ds))->_);
	} else if (o7_cmp((*p).l, OberonSpecIdent_While_cnst) == 0) {
		st = (&(While(&(*p), ds))->_._);
	} else {
		st = NULL;
	}
	if (st != NULL) {
		if (o7_cmp(commentOfs, 0) >= 0) {
			Ast_NodeSetComment(&(*O7_REF(st))._, (*p).module_, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, o7_int(commentOfs), o7_int(commentEnd));
		}
		if (emptyLines > 0) {
			O7_REF(st)->_.emptyLines = emptyLines;
		}
	}
	if (o7_bl((*p).err)) {
		Log_StrLn(5, (o7_char *)"Error");
		while ((o7_cmp((*p).l, Scanner_Semicolon_cnst) != 0) && NotEnd(o7_int((*p).l))) {
			Scan(&(*p));
		}
		(*p).err = (0 > 1);
	}
	return st;
}

static struct Ast_RStatement *Statements(struct Parser *p, struct Ast_RDeclarations *ds) {
	struct Ast_RStatement *stats, *last;

	stats = Statements_Statement(&(*p), ds);
	last = stats;

	while (1) if (ScanIfEqual(&(*p), Scanner_Semicolon_cnst)) {
		if (stats == NULL) {
			stats = Statements_Statement(&(*p), ds);
			last = stats;
		} else {
			O7_REF(last)->next = Statements_Statement(&(*p), ds);
			if (O7_REF(last)->next != NULL) {
				last = O7_REF(last)->next;
			}
		}
	} else if (NotEnd(o7_int((*p).l)) && !o7_bl(O7_REF((*p).module_)->script)) {
		AddError(&(*p), Parser_ErrExpectSemicolon_cnst);
		(*p).err = (0 > 1);
		while ((o7_cmp((*p).l, Scanner_Semicolon_cnst) != 0) && NotEnd(o7_int((*p).l))) {
			Scan(&(*p));
		}
	} else break;
	return stats;
}

static void Return(struct Parser *p, struct Ast_RProcedure *proc) {
	if (o7_cmp((*p).l, OberonSpecIdent_Return_cnst) == 0) {
		Log_StrLn(6, (o7_char *)"Return");

		Scan(&(*p));
		CheckAst(&(*p), Ast_ProcedureSetReturn(proc, Expression(&(*p), &proc->_._, (0 > 1))));
		if (o7_cmp((*p).l, Scanner_Semicolon_cnst) == 0) {
			if (o7_bl((*p).opt.strictSemicolon)) {
				AddError(&(*p), Parser_ErrExcessSemicolon_cnst);
				(*p).err = (0 > 1);
			}
			Scan(&(*p));
		}
	} else {
		CheckAst(&(*p), Ast_ProcedureEnd(proc));
	}
}

static void ProcBody(struct Parser *p, struct Ast_RProcedure *proc) {
	declarations(&(*p), &proc->_._);
	if (ScanIfEqual(&(*p), OberonSpecIdent_Begin_cnst)) {
		O7_REF(proc)->_._.stats = Statements(&(*p), &proc->_._);
	}
	Return(&(*p), proc);
	Expect(&(*p), OberonSpecIdent_End_cnst, Parser_ErrExpectEnd_cnst);
	if (o7_cmp((*p).l, Scanner_Ident_cnst) == 0) {
		if (!StringStore_IsEqualToChars(&O7_REF(proc)->_._._.name, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, o7_int((*p).s.lexStart), o7_int((*p).s.lexEnd))) {
			AddError(&(*p), Parser_ErrEndProcedureNameNotMatch_cnst);
		}
		Scan(&(*p));
	} else {
		AddError(&(*p), Parser_ErrExpectProcedureName_cnst);
	}
}

static o7_bool TakeComment(struct Parser *p) {
	return o7_bl((*p).opt.saveComments) && Scanner_TakeCommentPos(&(*p).s, &(*p).comment.ofs, &(*p).comment.end);
}

static void Procedure(struct Parser *p, struct Ast_RDeclarations *ds) {
	struct Ast_RProcedure *proc = NULL;
	o7_int_t nameStart = O7_INT_UNDEF, nameEnd = O7_INT_UNDEF;

	O7_ASSERT(o7_cmp((*p).l, OberonSpecIdent_Procedure_cnst) == 0);
	Scan(&(*p));
	ExpectIdent(&(*p), &nameStart, &nameEnd, Parser_ErrExpectIdent_cnst);
	CheckAst(&(*p), Ast_ProcedureAdd(ds, &proc, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, o7_int(nameStart), o7_int(nameEnd)));
	Mark(&(*p), &proc->_._._);
	FormalParameters(&(*p), ds, O7_REF(proc)->_.header);
	Expect(&(*p), Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
	ProcBody(&(*p), proc);
}

static void Declarations(struct Parser *p, struct Ast_RDeclarations *ds) {
	if (o7_cmp((*p).l, OberonSpecIdent_Const_cnst) == 0) {
		Consts(&(*p), ds);
	}
	if (o7_cmp((*p).l, OberonSpecIdent_Type_cnst) == 0) {
		Types(&(*p), ds);
	}
	if (o7_cmp((*p).l, OberonSpecIdent_Var_cnst) == 0) {
		Scan(&(*p));
		Vars(&(*p), ds);
	}
	while (o7_cmp((*p).l, OberonSpecIdent_Procedure_cnst) == 0) {
		Procedure(&(*p), ds);
		Expect(&(*p), Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
	}
}

static void Imports(struct Parser *p) {
	o7_int_t nameOfs = O7_INT_UNDEF, nameEnd = O7_INT_UNDEF, realOfs = O7_INT_UNDEF, realEnd = O7_INT_UNDEF;

	Ast_ImportHandle((*p).module_);
	do {
		Scan(&(*p));
		ExpectIdent(&(*p), &nameOfs, &nameEnd, Parser_ErrExpectModuleName_cnst);
		if (ScanIfEqual(&(*p), Scanner_Assign_cnst)) {
			ExpectIdent(&(*p), &realOfs, &realEnd, Parser_ErrExpectModuleName_cnst);
		} else {
			realOfs = o7_int(nameOfs);
			realEnd = o7_int(nameEnd);
		}
		if (!o7_bl((*p).err) && (o7_cmp(realOfs, 0) >= 0)) {
			CheckAst(&(*p), Ast_ImportAdd((*p).opt.provider, (*p).module_, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, o7_int(nameOfs), o7_int(nameEnd), o7_int(realOfs), o7_int(realEnd)));
		} else if (o7_bl((*p).err)) {
			(*p).err = (0 > 1);
			while ((o7_cmp((*p).l, OberonSpecIdent_Import_cnst) < 0) && (o7_cmp((*p).l, Scanner_Comma_cnst) != 0) && (o7_cmp((*p).l, Scanner_Semicolon_cnst) != 0) && (o7_cmp((*p).l, Scanner_EndOfFile_cnst) != 0)) {
				Scan(&(*p));
			}
		}
	} while (!(o7_cmp((*p).l, Scanner_Comma_cnst) != 0));
	Expect(&(*p), Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
	Ast_ImportEnd((*p).module_);
}

static void Module(struct Parser *p);
static void Module_SearchModule(struct Parser *p) {
	o7_int_t limit;

	limit = TranslatorLimits_MaxLexemsToModule_cnst;
	do {
		Scan(&(*p));
		limit = o7_sub(limit, 1);
	} while (!((o7_cmp((*p).l, OberonSpecIdent_Module_cnst) == 0) || (o7_cmp((*p).l, Scanner_EndOfFile_cnst) == 0) || (limit <= 0)));
}

static void Module(struct Parser *p) {
	o7_bool expectedName;

	Module_SearchModule(&(*p));
	if (o7_cmp((*p).l, OberonSpecIdent_Module_cnst) != 0) {
		(*p).module_ = Ast_ModuleNew(2, (o7_char *)"  ", 0, 0);
		AddError(&(*p), Parser_ErrExpectModule_cnst);
		O7_ASSERT(((*p).module_ == NULL) || (O7_REF((*p).module_)->errors != NULL));
	} else {
		Scan(&(*p));
		if (o7_cmp((*p).l, Scanner_Ident_cnst) != 0) {
			(*p).module_ = Ast_ModuleNew(2, (o7_char *)"  ", 0, 0);
			AddError(&(*p), Parser_ErrExpectIdent_cnst);
			expectedName = (0 < 1);
		} else {
			(*p).module_ = Ast_ModuleNew(Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, o7_int((*p).s.lexStart), o7_int((*p).s.lexEnd));
			expectedName = Ast_RegModule((*p).opt.provider, (*p).module_);
			if (expectedName) {
				if (TakeComment(&(*p))) {
					Ast_ModuleSetComment((*p).module_, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, o7_int((*p).comment.ofs), o7_int((*p).comment.end));
				}
				Scan(&(*p));
			} else {
				AddError(&(*p), Parser_ErrExpectAnotherModuleName_cnst);
			}
		}
		if (expectedName) {
			Expect(&(*p), Scanner_Semicolon_cnst, Parser_ErrExpectSemicolon_cnst);
			if (o7_cmp((*p).l, OberonSpecIdent_Import_cnst) == 0) {
				Imports(&(*p));
			}
			Declarations(&(*p), &(*p).module_->_);
			if (ScanIfEqual(&(*p), OberonSpecIdent_Begin_cnst)) {
				O7_REF((*p).module_)->_.stats = Statements(&(*p), &(*p).module_->_);
			}
			Expect(&(*p), OberonSpecIdent_End_cnst, Parser_ErrExpectEnd_cnst);
			if (o7_cmp((*p).l, Scanner_Ident_cnst) == 0) {
				if (!StringStore_IsEqualToChars(&O7_REF((*p).module_)->_._.name, Scanner_BlockSize_cnst * 2 + 1, (*p).s.buf, o7_int((*p).s.lexStart), o7_int((*p).s.lexEnd))) {
					AddError(&(*p), Parser_ErrEndModuleNameNotMatch_cnst);
				}
				Scan(&(*p));
			} else {
				AddError(&(*p), Parser_ErrExpectModuleName_cnst);
			}
			if (o7_cmp((*p).l, Scanner_Dot_cnst) != 0) {
				AddError(&(*p), Parser_ErrExpectDot_cnst);
			}
			CheckAst(&(*p), Ast_ModuleEnd((*p).module_));
		}
	}
}

static void Blank(o7_int_t code) {
}

extern void Parser_DefaultOptions(struct Parser_Options *opt) {
	V_Init(&(*opt)._);

	(*opt).strictSemicolon = (0 < 1);
	(*opt).strictReturn = (0 < 1);
	(*opt).saveComments = (0 < 1);
	(*opt).multiErrors = (0 > 1);
	(*opt).cyrillic = (0 > 1);
	(*opt).printError = Blank;

	(*opt).provider = NULL;
}

static void ParserInit(struct Parser *p, struct VDataStream_In *in_, o7_int_t src_len0, o7_char src[/*len0*/], struct Parser_Options *opt) {
	V_Init(&(*p)._);
	(*p).opt = (*opt);
	(*p).err = (0 > 1);
	(*p).errorsCount = 0;
	(*p).module_ = NULL;
	(*p).callId = 0;
	(*p).inLoops = 0;
	if (in_ != NULL) {
		Scanner_Init(&(*p).s, in_);
	} else {
		O7_ASSERT(Scanner_InitByString(&(*p).s, src_len0, src));
	}
	(*p).s.opt.cyrillic = o7_bl((*opt).cyrillic);
}

extern struct Ast_RModule *Parser_Parse(struct VDataStream_In *in_, struct Parser_Options *opt) {
	struct Parser p;
	Parser_undef(&p);

	O7_ASSERT(in_ != NULL);
	ParserInit(&p, in_, 0, (o7_char *)"", &(*opt));
	Module(&p);
	return p.module_;
}

extern struct Ast_RModule *Parser_Script(o7_int_t in__len0, o7_char in_[/*len0*/], struct Parser_Options *opt) {
	struct Parser p;
	Parser_undef(&p);

	ParserInit(&p, NULL, in__len0, in_, &(*opt));
	p.module_ = Ast_ScriptNew();
	Scan(&p);
	O7_REF(p.module_)->_.stats = Statements(&p, &p.module_->_);
	if ((O7_REF(p.module_)->_.stats == NULL) && (O7_REF(p.module_)->errors == NULL)) {
		AddError(&p, Parser_ErrUnexpectedContentInScript_cnst);
	}
	CheckAst(&p, Ast_ModuleEnd(p.module_));
	return p.module_;
}

extern void Parser_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		Log_init();
		Scanner_init();
		StringStore_init();
		Ast_init();
		VDataStream_init();

		declarations = Declarations;
		type = Type;
		statements = Statements;
		expression = Expression;
	}
	++initialized;
}


#if !defined(O7_INIT_MODEL)
#   define   O7_INIT_MODEL O7_INIT_ZERO
#endif

#include <o7.h>

#include "GeneratorC.h"


#define Interface_cnst 1
#define Implementation_cnst 0

#define CheckableArithTypes_cnst (Ast_Numbers_cnst & ~(1u << Ast_IdByte_cnst))
#define CheckableInitTypes_cnst (CheckableArithTypes_cnst | (1u << Ast_IdBoolean_cnst))

o7_tag_t GeneratorC_MemoryOut_tag;
#define GeneratorC_Options__s_tag GenOptions_R_tag

typedef struct Generator {
	TextGenerator_Out _;
	struct Ast_RModule *module_;

	o7_int_t localDeep;

	o7_int_t fixedLen;

	o7_bool interface_;
	struct GeneratorC_Options__s *opt;

	o7_bool expressionSemicolon;
	o7_bool insideSizeOf;

	struct GeneratorC_MemoryOut *memout;
} Generator;
#define Generator_tag TextGenerator_Out_tag


typedef struct MOut {
	struct Generator g[2];
	struct GeneratorC_Options__s *opt;
} MOut;
#define MOut_tag o7_base_tag


typedef struct Selectors {
	struct Ast_Designator__s *des;
	struct Ast_RDeclaration *decl;
	o7_bool declSimilarToPointer;
	struct Ast_RSelector *list[TranslatorLimits_Selectors_cnst];
	o7_int_t i;
} Selectors;
#define Selectors_tag o7_base_tag


typedef struct RecExt__s {
	V_Base _;
	struct StringStore_String anonName;
	o7_bool undef;
	struct Ast_RRecord *next;
} *RecExt;
static o7_tag_t RecExt__s_tag;


static void (*type)(struct Generator *gen, struct Ast_RDeclaration *decl, struct Ast_RType *type, o7_bool typeDecl, o7_bool sameType) = NULL;
static void (*declarator)(struct Generator *gen, struct Ast_RDeclaration *decl, o7_bool typeDecl, o7_bool sameType, o7_bool global) = NULL;
static void (*declarations)(struct MOut *out, struct Ast_RDeclarations *ds) = NULL;
static void (*statements)(struct Generator *gen, struct Ast_RStatement *stats) = NULL;
static void (*expression)(struct Generator *gen, struct Ast_RExpression *expr) = NULL;

static void MemoryWrite(struct GeneratorC_MemoryOut *out, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t ofs, o7_int_t count) {
	O7_ASSERT(Chars0X_CopyChars(4096, out->mem[o7_ind(2, (o7_int_t)out->invert)].buf, &out->mem[o7_ind(2, (o7_int_t)out->invert)].len, buf_len0, buf, ofs, o7_add(ofs, count)));
}

static o7_int_t MemWrite(struct V_Base *out, o7_tag_t *out_tag, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t ofs, o7_int_t count) {
	MemoryWrite(&O7_GUARD_R(GeneratorC_MemoryOut, out, out_tag), buf_len0, buf, ofs, count);
	return count;
}

static struct GeneratorC_MemoryOut *PMemoryOutGet(struct GeneratorC_Options__s *opt) {
	struct GeneratorC_MemoryOut *m = NULL;

	if (opt->memOuts == NULL) {
		O7_NEW(&m, GeneratorC_MemoryOut);
		VDataStream_InitOut(&(*m)._, NULL, MemWrite, NULL);
	} else {
		m = opt->memOuts;
		opt->memOuts = m->next;
	}
	m->mem[0].len = 0;
	m->mem[1].len = 0;
	m->invert = (0 > 1);
	m->next = NULL;
	return m;
}

static void PMemoryOutBack(struct GeneratorC_Options__s *opt, struct GeneratorC_MemoryOut *m) {
	m->next = opt->memOuts;
	opt->memOuts = m;
}

static void MemWriteInvert(struct GeneratorC_MemoryOut *mo) {
	o7_int_t inv, direct;

	inv = (o7_int_t)mo->invert;
	if (mo->mem[o7_ind(2, inv)].len == 0) {
		mo->invert = !mo->invert;
	} else {
		direct = o7_sub(1, inv);
		O7_ASSERT(Chars0X_CopyChars(4096, mo->mem[o7_ind(2, inv)].buf, &mo->mem[o7_ind(2, inv)].len, 4096, mo->mem[o7_ind(2, direct)].buf, 0, mo->mem[o7_ind(2, direct)].len));
		mo->mem[o7_ind(2, direct)].len = 0;
	}
}

static void MemWriteDirect(struct Generator *gen, struct GeneratorC_MemoryOut *mo) {
	o7_int_t inv;

	inv = (o7_int_t)mo->invert;
	O7_ASSERT(mo->mem[o7_ind(2, o7_sub(1, inv))].len == 0);
	TextGenerator_Data(&(*gen)._, 4096, mo->mem[o7_ind(2, inv)].buf, 0, mo->mem[o7_ind(2, inv)].len);
	mo->mem[o7_ind(2, inv)].len = 0;
}

static void Ident(struct Generator *gen, struct StringStore_String *ident) {
	GenCommon_Ident(&(*gen)._, ident, gen->opt->_.identEnc);
}

static void Name(struct Generator *gen, struct Ast_RDeclaration *decl) {
	struct Ast_RDeclarations *up;
	struct Ast_RDeclarations *prs[TranslatorLimits_DeepProcedures_cnst + 1];
	o7_int_t i;
	memset(&prs, 0, sizeof(prs));

	if ((o7_is(decl, &Ast_RType_tag)) && (decl->up != NULL) && (decl->up->d != &decl->module_->m->_) || !gen->opt->procLocal && (o7_is(decl, &Ast_RProcedure_tag))) {
		up = decl->up->d;
		i = 0;
		while (up->_.up != NULL) {
			prs[o7_ind(TranslatorLimits_DeepProcedures_cnst + 1, i)] = up;
			i = o7_add(i, 1);
			up = up->_.up->d;
		}
		while (i > 0) {
			i = o7_sub(i, 1);
			Ident(gen, &prs[o7_ind(TranslatorLimits_DeepProcedures_cnst + 1, i)]->_.name);
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x5F");
		}
	}
	Ident(gen, &decl->name);
	if (o7_is(decl, &Ast_Const__s_tag)) {
		TextGenerator_Str(&(*gen)._, 6, (o7_char *)"_cnst");
	} else if (SpecIdentChecker_IsSpecName(&decl->name, 0)) {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x5F");
	}
}

static void GlobalName(struct Generator *gen, struct Ast_RDeclaration *decl) {
	if (decl->mark || (decl->module_ != NULL) && (gen->module_ != decl->module_->m)) {
		O7_ASSERT(decl->module_ != NULL);
		Ident(gen, &decl->module_->m->_._.name);

		TextGenerator_Data(&(*gen)._, 3, (o7_char *)"__", 0, o7_add((o7_int_t)SpecIdentChecker_IsO7SpecName(&decl->name), 1));
		Ident(gen, &decl->name);
		if (o7_is(decl, &Ast_Const__s_tag)) {
			TextGenerator_Str(&(*gen)._, 6, (o7_char *)"_cnst");
		}
	} else {
		Name(gen, decl);
	}
}

static void Import(struct Generator *gen, struct Ast_RDeclaration *decl) {
	struct StringStore_String name;
	o7_int_t i;
	memset(&name, 0, sizeof(name));

	TextGenerator_Str(&(*gen)._, 10, (o7_char *)"#include ");
	TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x22");
	if (o7_is(decl, &Ast_RModule_tag)) {
		name = decl->name;
	} else {
		O7_ASSERT(o7_is(decl, &Ast_Import__s_tag));
		name = decl->module_->m->_._.name;
	}
	TextGenerator_String(&(*gen)._, &name);
	i = (o7_int_t)(!SpecIdentChecker_IsSpecModuleName(&name) && !SpecIdentChecker_IsSpecCHeaderName(&name));
	TextGenerator_Data(&(*gen)._, 4, (o7_char *)"_.h", i, o7_sub(3, i));
	TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x22");
}

static void Factor(struct Generator *gen, struct Ast_RExpression *expr) {
	if ((o7_is(expr, &Ast_RFactor_tag)) && !(expr->type->_._.id == Ast_IdArray_cnst)) {
		expression(gen, expr);
	} else {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x28");
		expression(gen, expr);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static o7_bool IsAnonStruct(struct Ast_RRecord *rec) {
	return !StringStore_IsDefined(&rec->_._._.name) || StringStore_SearchSubString(&rec->_._._.name, 7, (o7_char *)"_anon_");
}

static struct Ast_RType *TypeForTag(struct Ast_RRecord *rec) {
	if (IsAnonStruct(rec)) {
		rec = rec->base;
	}
	return (&(rec)->_._);
}

static o7_bool CheckStructName(struct Generator *gen, struct Ast_RRecord *rec) {
	o7_char anon[O7_MUL(TranslatorLimits_LenName_cnst, 2) + 3];
	o7_int_t i, j, l;
	memset(&anon, 0, sizeof(anon));

	if (StringStore_IsDefined(&rec->_._._.name)) {
	} else if ((rec->pointer != NULL) && StringStore_IsDefined(&rec->pointer->_._._.name)) {
		l = 0;
		O7_ASSERT(rec->_._._.module_ != NULL);
		rec->_._._.mark = rec->pointer->_._._.mark;
		O7_ASSERT(StringStore_CopyToChars(O7_MUL(TranslatorLimits_LenName_cnst, 2) + 3, anon, &l, &rec->pointer->_._._.name));
		anon[o7_ind(O7_MUL(TranslatorLimits_LenName_cnst, 2) + 3, l)] = (o7_char)'_';
		anon[o7_ind(O7_MUL(TranslatorLimits_LenName_cnst, 2) + 3, o7_add(l, 1))] = (o7_char)'s';
		anon[o7_ind(O7_MUL(TranslatorLimits_LenName_cnst, 2) + 3, o7_add(l, 2))] = 0x00u;
		Ast_PutChars(rec->pointer->_._._.module_->m, &rec->_._._.name, O7_MUL(TranslatorLimits_LenName_cnst, 2) + 3, anon, 0, o7_add(l, 2));
	} else {
		l = 0;
		O7_ASSERT(StringStore_CopyToChars(O7_MUL(TranslatorLimits_LenName_cnst, 2) + 3, anon, &l, &rec->_._._.module_->m->_._.name));

		O7_ASSERT(Chars0X_CopyString(O7_MUL(TranslatorLimits_LenName_cnst, 2) + 3, anon, &l, 11, (o7_char *)"_anon_0000"));
		O7_ASSERT((gen->opt->index >= 0) && (gen->opt->index < 10000));
		i = gen->opt->index;
		j = o7_sub(l, 1);
		while (i > 0) {
			anon[o7_ind(O7_MUL(TranslatorLimits_LenName_cnst, 2) + 3, j)] = o7_chr(o7_add(((o7_int_t)(o7_char)'0'), o7_mod(i, 10)));
			i = o7_div(i, 10);
			j = o7_sub(j, 1);
		}
		gen->opt->index = o7_add(gen->opt->index, 1);
		Ast_PutChars(rec->_._._.module_->m, &rec->_._._.name, O7_MUL(TranslatorLimits_LenName_cnst, 2) + 3, anon, 0, l);
	}
	return StringStore_IsDefined(&rec->_._._.name);
}

static void ArrayDeclLen(struct Generator *gen, struct Ast_RType *arr, struct Ast_RDeclaration *decl, struct Ast_RSelector *sel, o7_int_t i) {
	if (O7_GUARD(Ast_RArray, arr)->count != NULL) {
		expression(gen, O7_GUARD(Ast_RArray, arr)->count);
	} else {
		GlobalName(gen, decl);
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)"_len");
		if (i < 0) {
			i = 0;
			while (sel != NULL) {
				i = o7_add(i, 1);
				sel = sel->next;
			}
		}
		TextGenerator_Int(&(*gen)._, i);
	}
}

static void ArrayLen(struct Generator *gen, struct Ast_RExpression *e) {
	o7_int_t i;
	struct Ast_Designator__s *des;
	struct Ast_RType *t;

	if (O7_GUARD(Ast_RArray, e->type)->count != NULL) {
		expression(gen, O7_GUARD(Ast_RArray, e->type)->count);
	} else {
		des = O7_GUARD(Ast_Designator__s, e);
		GlobalName(gen, des->decl);
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)"_len");
		i = 0;
		t = des->_._.type;
		while (t != e->type) {
			i = o7_add(i, 1);
			t = t->_.type;
		}
		TextGenerator_Int(&(*gen)._, i);
	}
}

static void Selector(struct Generator *gen, struct Selectors *sels, o7_int_t i, struct Ast_RType **typ, struct Ast_RType *desType);
static void Selector_Record(struct Generator *gen, struct Ast_RType **typ, struct Ast_RSelector **sel, struct Selectors *sels);
static o7_bool Selector_Record_Search(struct Ast_RRecord *ds, struct Ast_RDeclaration *d) {
	struct Ast_RDeclaration *c;

	c = (&(ds->vars)->_);
	while ((c != NULL) && (c != d)) {
		c = c->next;
	}
	return c != NULL;
}

static void Selector_Record(struct Generator *gen, struct Ast_RType **typ, struct Ast_RSelector **sel, struct Selectors *sels) {
	struct Ast_RDeclaration *var_;
	struct Ast_RRecord *up;

	var_ = (&(O7_GUARD(Ast_SelRecord__s, (*sel))->var_)->_);
	if (o7_is(*typ, &Ast_RPointer_tag)) {
		up = O7_GUARD(Ast_RRecord, O7_GUARD(Ast_RPointer, (*typ))->_._._.type);
	} else {
		up = O7_GUARD(Ast_RRecord, (*typ));
	}

	if (((*typ)->_._.id == Ast_IdPointer_cnst) || (sels->list[0] == *sel) && sels->declSimilarToPointer) {
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)"->");
	} else {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x2E");
	}

	if (!gen->opt->plan9) {
		while ((up != NULL) && !Selector_Record_Search(up, var_)) {
			up = up->base;
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)"_.");
		}
	}

	Name(gen, var_);

	*typ = var_->type;
}

static void Selector_Declarator(struct Generator *gen, struct Ast_RDeclaration *decl, struct Selectors *sels) {
	if ((o7_is(decl, &Ast_RFormalParam_tag)) && (decl->type->_._.id != Ast_IdArray_cnst) && ((!!( (1u << Ast_ParamOut_cnst) & O7_GUARD(Ast_RFormalParam, decl)->access)) || (decl->type->_._.id == Ast_IdRecord_cnst)) && ((sels->i < 0) || (decl->type->_._.id == Ast_IdPointer_cnst))) {
		if ((sels->i < 0) && !gen->opt->castToBase) {
			TextGenerator_CancelDeferedOrWriteChar(&(*gen)._, (o7_char)'*');
			GlobalName(gen, decl);
		} else {
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)"(*");
			GlobalName(gen, decl);
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		}
	} else {
		GlobalName(gen, decl);
	}
}

static void Selector_Array(struct Generator *gen, struct Ast_RType **typ, struct Ast_RSelector **sel, struct Ast_RDeclaration *decl, o7_bool isDesignatorArray);
static void Selector_Array_Mult(struct Generator *gen, struct Ast_RDeclaration *decl, o7_int_t j, struct Ast_RType *t) {
	while ((t != NULL) && (o7_is(t, &Ast_RArray_tag))) {
		TextGenerator_Str(&(*gen)._, 4, (o7_char *)" * ");
		Name(gen, decl);
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)"_len");
		TextGenerator_Int(&(*gen)._, j);
		j = o7_add(j, 1);
		t = t->_.type;
	}
}

static void Selector_Array(struct Generator *gen, struct Ast_RType **typ, struct Ast_RSelector **sel, struct Ast_RDeclaration *decl, o7_bool isDesignatorArray) {
	o7_int_t i;

	if (isDesignatorArray && !gen->opt->vla) {
		TextGenerator_Str(&(*gen)._, 4, (o7_char *)" + ");
	} else {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x5B");
	}
	if (((*typ)->_.type->_._.id != Ast_IdArray_cnst) || (O7_GUARD(Ast_RArray, (*typ))->count != NULL) || gen->opt->vla) {
		if (gen->opt->_.checkIndex && ((O7_GUARD(Ast_SelArray__s, (*sel))->index->value_ == NULL) || (O7_GUARD(Ast_RArray, (*typ))->count == NULL) && (O7_GUARD(Ast_RExprInteger, O7_GUARD(Ast_SelArray__s, (*sel))->index->value_)->int_ != 0))) {
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_ind(");
			ArrayDeclLen(gen, *typ, decl, *sel, 0);
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
			expression(gen, O7_GUARD(Ast_SelArray__s, (*sel))->index);
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		} else {
			expression(gen, O7_GUARD(Ast_SelArray__s, (*sel))->index);
		}
		*typ = (*typ)->_.type;
		*sel = (*sel)->next;
		i = 1;
		while ((*sel != NULL) && (o7_is(*sel, &Ast_SelArray__s_tag))) {
			if (gen->opt->_.checkIndex && ((O7_GUARD(Ast_SelArray__s, (*sel))->index->value_ == NULL) || (O7_GUARD(Ast_RArray, (*typ))->count == NULL) && (O7_GUARD(Ast_RExprInteger, O7_GUARD(Ast_SelArray__s, (*sel))->index->value_)->int_ != 0))) {
				TextGenerator_Str(&(*gen)._, 10, (o7_char *)"][o7_ind(");
				ArrayDeclLen(gen, *typ, decl, *sel, i);
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
				expression(gen, O7_GUARD(Ast_SelArray__s, (*sel))->index);
				TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
			} else {
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)"][");
				expression(gen, O7_GUARD(Ast_SelArray__s, (*sel))->index);
			}
			i = o7_add(i, 1);
			*sel = (*sel)->next;
			*typ = (*typ)->_.type;
		}
	} else {
		i = 0;
		while (((*sel)->next != NULL) && (o7_is((*sel)->next, &Ast_SelArray__s_tag))) {
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_ind(");
			ArrayDeclLen(gen, *typ, decl, NULL, i);
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
			expression(gen, O7_GUARD(Ast_SelArray__s, (*sel))->index);
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
			*typ = (*typ)->_.type;
			Selector_Array_Mult(gen, decl, o7_add(i, 1), *typ);
			*sel = (*sel)->next;
			i = o7_add(i, 1);
			TextGenerator_Str(&(*gen)._, 4, (o7_char *)" + ");
		}
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_ind(");
		ArrayDeclLen(gen, *typ, decl, NULL, i);
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
		expression(gen, O7_GUARD(Ast_SelArray__s, (*sel))->index);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		Selector_Array_Mult(gen, decl, o7_add(i, 1), (*typ)->_.type);
	}
	if (!isDesignatorArray || gen->opt->vla) {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x5D");
	}
}

static void Selector(struct Generator *gen, struct Selectors *sels, o7_int_t i, struct Ast_RType **typ, struct Ast_RType *desType) {
	struct Ast_RSelector *sel = NULL;
	o7_bool ref_;

	if (i >= 0) {
		sel = sels->list[o7_ind(TranslatorLimits_Selectors_cnst, i)];
	}
	if (!gen->opt->checkNil) {
		ref_ = (0 > 1);
	} else if (i < 0) {
		ref_ = (sels->i >= 0) && (sels->decl->type != NULL) && (sels->decl->type->_._.id == Ast_IdPointer_cnst);
	} else {
		ref_ = (sel->type->_._.id == Ast_IdPointer_cnst) && (sel->next != NULL) && !(o7_is(sel->next, &Ast_SelGuard__s_tag)) && !(o7_is(sel, &Ast_SelGuard__s_tag));
	}
	if (ref_) {
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"O7_REF(");
	}
	if (i < 0) {
		Selector_Declarator(gen, sels->decl, sels);
	} else {
		i = o7_sub(i, 1);
		if (o7_is(sel, &Ast_SelRecord__s_tag)) {
			Selector(gen, sels, i, typ, desType);
			Selector_Record(gen, typ, &sel, sels);
		} else if (o7_is(sel, &Ast_SelArray__s_tag)) {
			Selector(gen, sels, i, typ, desType);
			Selector_Array(gen, typ, &sel, sels->decl, (desType->_._.id == Ast_IdArray_cnst) && (O7_GUARD(Ast_RArray, desType)->count == NULL));
		} else if (o7_is(sel, &Ast_SelPointer__s_tag)) {
			if ((sel->next == NULL) || !(o7_is(sel->next, &Ast_SelRecord__s_tag))) {
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)"(*");
				Selector(gen, sels, i, typ, desType);
				TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
			} else {
				Selector(gen, sels, i, typ, desType);
			}
		} else {
			O7_ASSERT(o7_is(sel, &Ast_SelGuard__s_tag));
			if (sel->type->_._.id == Ast_IdPointer_cnst) {
				TextGenerator_Str(&(*gen)._, 10, (o7_char *)"O7_GUARD(");
				O7_ASSERT(CheckStructName(gen, O7_GUARD(Ast_RRecord, sel->type->_.type)));
				GlobalName(gen, &sel->type->_.type->_);
			} else {
				O7_ASSERT(i < 0);
				TextGenerator_Str(&(*gen)._, 12, (o7_char *)"O7_GUARD_R(");
				GlobalName(gen, &sel->type->_);
			}
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
			if (i < 0) {
				Selector_Declarator(gen, sels->decl, sels);
			} else {
				Selector(gen, sels, i, typ, desType);
			}
			if (sel->type->_._.id == Ast_IdPointer_cnst) {
				TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
			} else {
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
				GlobalName(gen, sels->decl);
				TextGenerator_Str(&(*gen)._, 6, (o7_char *)"_tag)");
			}
			*typ = O7_GUARD(Ast_SelGuard__s, sel)->_.type;
		}
	}
	if (ref_) {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static o7_bool IsDesignatorMayNotInited(struct Ast_Designator__s *des) {
	return ((((1u << Ast_InitedNo_cnst) | (1u << Ast_InitedCheck_cnst)) & des->inited) != 0) || (des->sel != NULL);
}

static o7_bool IsMayNotInited(struct Ast_RExpression *e) {
	return (o7_is(e, &Ast_Designator__s_tag)) && IsDesignatorMayNotInited(O7_GUARD(Ast_Designator__s, e));
}

static void Designator(struct Generator *gen, struct Ast_Designator__s *des);
static void Designator_Put(struct Selectors *sels, struct Ast_RSelector *sel) {
	sels->i =  - 1;
	while (sel != NULL) {
		sels->i = o7_add(sels->i, 1);
		sels->list[o7_ind(TranslatorLimits_Selectors_cnst, sels->i)] = sel;
		if (o7_is(sel, &Ast_SelArray__s_tag)) {
			do {
				sel = sel->next;
			} while (!((sel == NULL) || !(o7_is(sel, &Ast_SelArray__s_tag))));
		} else {
			sel = sel->next;
		}
	}
}

static void Designator(struct Generator *gen, struct Ast_Designator__s *des) {
	struct Selectors sels;
	struct Ast_RType *typ;
	o7_bool lastSelectorDereference;
	memset(&sels, 0, sizeof(sels));

	typ = des->decl->type;
	Designator_Put(&sels, des->sel);
	sels.des = des;
	sels.decl = des->decl;
	sels.declSimilarToPointer = (o7_is(sels.decl, &Ast_RFormalParam_tag)) && ((!!( (1u << Ast_ParamOut_cnst) & O7_GUARD(Ast_RFormalParam, sels.decl)->access)) || (o7_in(sels.decl->type->_._.id, ((1u << Ast_IdArray_cnst) | (1u << Ast_IdRecord_cnst)))));
	lastSelectorDereference = (0 <= sels.i) && (o7_is(sels.list[o7_ind(TranslatorLimits_Selectors_cnst, sels.i)], &Ast_SelPointer__s_tag));
	Selector(gen, &sels, sels.i, &typ, des->_._.type);
	gen->opt->lastSelectorDereference = lastSelectorDereference;
}

static void CheckExpr(struct Generator *gen, struct Ast_RExpression *e) {
	if ((gen->opt->_.varInit == GenOptions_VarInitUndefined_cnst) && (e->value_ == NULL) && (o7_in(e->type->_._.id, CheckableInitTypes_cnst)) && IsMayNotInited(e)) {
		switch (e->type->_._.id) {
		case 2:
			TextGenerator_Str(&(*gen)._, 7, (o7_char *)"o7_bl(");
			break;
		case 0:
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_int(");
			break;
		case 1:
			TextGenerator_Str(&(*gen)._, 9, (o7_char *)"o7_long(");
			break;
		case 5:
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_dbl(");
			break;
		case 6:
			TextGenerator_Str(&(*gen)._, 7, (o7_char *)"o7_fl(");
			break;
		default:
			o7_case_fail(e->type->_._.id);
			break;
		}
		expression(gen, e);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	} else {
		expression(gen, e);
	}
}

static void AssignInitValue(struct Generator *gen, struct Ast_RType *typ);
static void AssignInitValue_Zero(struct Generator *gen, struct Ast_RType *typ) {
	switch (typ->_._.id) {
	case 0:
	case 1:
	case 3:
	case 5:
	case 6:
	case 7:
	case 8:
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)" = 0");
		break;
	case 2:
		TextGenerator_Str(&(*gen)._, 9, (o7_char *)" = 0 > 1");
		break;
	case 4:
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)" = '\\0'");
		break;
	case 9:
	case 13:
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)" = NULL");
		break;
	default:
		o7_case_fail(typ->_._.id);
		break;
	}
}

static void AssignInitValue_Undef(struct Generator *gen, struct Ast_RType *typ) {
	switch (typ->_._.id) {
	case 0:
		TextGenerator_Str(&(*gen)._, 16, (o7_char *)" = O7_INT_UNDEF");
		break;
	case 1:
		TextGenerator_Str(&(*gen)._, 17, (o7_char *)" = O7_LONG_UNDEF");
		break;
	case 2:
		TextGenerator_Str(&(*gen)._, 17, (o7_char *)" = O7_BOOL_UNDEF");
		break;
	case 3:
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)" = 0");
		break;
	case 4:
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)" = '\\0'");
		break;
	case 5:
		TextGenerator_Str(&(*gen)._, 16, (o7_char *)" = O7_DBL_UNDEF");
		break;
	case 6:
		TextGenerator_Str(&(*gen)._, 16, (o7_char *)" = O7_FLT_UNDEF");
		break;
	case 7:
	case 8:
		TextGenerator_Str(&(*gen)._, 6, (o7_char *)" = 0u");
		break;
	case 9:
	case 13:
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)" = NULL");
		break;
	default:
		o7_case_fail(typ->_._.id);
		break;
	}
}

static void AssignInitValue(struct Generator *gen, struct Ast_RType *typ) {
	switch (gen->opt->_.varInit) {
	case 0:
		AssignInitValue_Undef(gen, typ);
		break;
	case 1:
		AssignInitValue_Zero(gen, typ);
		break;
	default:
		o7_case_fail(gen->opt->_.varInit);
		break;
	}
}

static void VarInit(struct Generator *gen, struct Ast_RDeclaration *var_, o7_bool record) {
	if ((gen->opt->_.varInit == GenOptions_VarInitNo_cnst) || (o7_in(var_->type->_._.id, ((1u << Ast_IdArray_cnst) | (1u << Ast_IdRecord_cnst)))) || (!record && !O7_GUARD(Ast_RVar, var_)->checkInit)) {
		if ((var_->type->_._.id == Ast_IdPointer_cnst) && (gen->opt->memManager == GeneratorC_MemManagerCounter_cnst)) {
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)" = NULL");
		}
	} else {
		AssignInitValue(gen, var_->type);
	}
}

static void Swap(o7_bool *b1, o7_bool *b2) {
	o7_bool t;

	t = *b1;
	*b1 = *b2;
	*b2 = t;
}

static void Expression(struct Generator *gen, struct Ast_RExpression *expr);
static void Expression_Call(struct Generator *gen, struct Ast_ExprCall__s *call);
static void Expression_Call_Predefined(struct Generator *gen, struct Ast_ExprCall__s *call);
static void Expression_Call_Predefined_LeftShift(struct Generator *gen, struct Ast_RExpression *n, struct Ast_RExpression *s) {
	TextGenerator_Str(&(*gen)._, 23, (o7_char *)"(o7_int_t)((o7_uint_t)");
	Factor(gen, n);
	TextGenerator_Str(&(*gen)._, 5, (o7_char *)" << ");
	Factor(gen, s);
	TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
}

static void Expression_Call_Predefined_ArithmeticRightShift(struct Generator *gen, struct Ast_RExpression *n, struct Ast_RExpression *s) {
	if ((n->value_ != NULL) && (s->value_ != NULL)) {
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"O7_ASR(");
		Expression(gen, n);
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
		Expression(gen, s);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	} else if (gen->opt->gnu) {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x28");
		Factor(gen, n);
		if (gen->opt->_.checkArith && (s->value_ == NULL)) {
			TextGenerator_Str(&(*gen)._, 16, (o7_char *)" >> o7_not_neg(");
		} else {
			TextGenerator_Str(&(*gen)._, 6, (o7_char *)" >> (");
		}
		Expression(gen, s);
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)"))");
	} else {
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_asr(");
		Expression(gen, n);
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
		Expression(gen, s);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void Expression_Call_Predefined_Rotate(struct Generator *gen, struct Ast_RExpression *n, struct Ast_RExpression *r) {
	if ((n->value_ != NULL) && (r->value_ != NULL)) {
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"O7_ROR(");
	} else {
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_ror(");
	}
	Expression(gen, n);
	TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
	Expression(gen, r);
	TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
}

static void Expression_Call_Predefined_Len(struct Generator *gen, struct Ast_RExpression *e) {
	struct Ast_RSelector *sel;
	o7_int_t i;
	struct Ast_Designator__s *des = NULL;
	struct Ast_RExpression *count;
	o7_bool sizeof_;

	count = O7_GUARD(Ast_RArray, e->type)->count;
	if (o7_is(e, &Ast_Designator__s_tag)) {
		des = O7_GUARD(Ast_Designator__s, e);
		sizeof_ = !(o7_is(O7_GUARD(Ast_Designator__s, e)->decl, &Ast_Const__s_tag)) && ((des->decl->type->_._.id != Ast_IdArray_cnst) || !(o7_is(des->decl, &Ast_RFormalParam_tag)) || gen->opt->vla && !gen->opt->vlaMark);
	} else {
		O7_ASSERT(count != NULL);
		sizeof_ = (0 > 1);
	}
	if ((count != NULL) && !sizeof_) {
		Expression(gen, count);
	} else if (sizeof_) {
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"O7_LEN(");
		Designator(gen, des);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	} else if (gen->opt->e2k && (des->decl->type->_.type->_._.id != Ast_IdArray_cnst)) {
		TextGenerator_Str(&(*gen)._, 12, (o7_char *)"O7_E2K_LEN(");
		GlobalName(gen, des->decl);
		TextGenerator_Char(&(*gen)._, (o7_char)')');
	} else {
		GlobalName(gen, des->decl);
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)"_len");
		i = 0;
		sel = des->sel;
		while (sel != NULL) {
			i = o7_add(i, 1);
			sel = sel->next;
		}
		TextGenerator_Int(&(*gen)._, i);
	}
}

static void Expression_Call_Predefined_New(struct Generator *gen, struct Ast_RExpression *e) {
	struct Ast_RType *tagType;

	tagType = TypeForTag(O7_GUARD(Ast_RRecord, e->type->_.type));
	if (tagType != NULL) {
		TextGenerator_Str(&(*gen)._, 9, (o7_char *)"O7_NEW(&");
		Designator(gen, O7_GUARD(Ast_Designator__s, e));
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
		GlobalName(gen, &tagType->_);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	} else {
		TextGenerator_Str(&(*gen)._, 10, (o7_char *)"O7_NEW2(&");
		Designator(gen, O7_GUARD(Ast_Designator__s, e));
		TextGenerator_Str(&(*gen)._, 21, (o7_char *)", o7_base_tag, NULL)");
	}
}

static void Expression_Call_Predefined_Ord(struct Generator *gen, struct Ast_RExpression *e) {
	switch (e->type->_._.id) {
	case 4:
	case 10:
		TextGenerator_Str(&(*gen)._, 11, (o7_char *)"(o7_int_t)");
		Factor(gen, e);
		break;
	case 2:
		if ((o7_is(e, &Ast_Designator__s_tag)) && (gen->opt->_.varInit == GenOptions_VarInitUndefined_cnst)) {
			TextGenerator_Str(&(*gen)._, 17, (o7_char *)"(o7_int_t)o7_bl(");
			Expression(gen, e);
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		} else {
			TextGenerator_Str(&(*gen)._, 11, (o7_char *)"(o7_int_t)");
			Factor(gen, e);
		}
		break;
	case 7:
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_sti(");
		Expression(gen, e);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		break;
	default:
		o7_case_fail(e->type->_._.id);
		break;
	}
}

static void Expression_Call_Predefined_Inc(struct Generator *gen, struct Ast_RExpression *e1, struct Ast_RParameter *p2) {
	Expression(gen, e1);
	if (gen->opt->_.checkArith) {
		TextGenerator_Str(&(*gen)._, 11, (o7_char *)" = o7_add(");
		Expression(gen, e1);
		if (p2 == NULL) {
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)", 1)");
		} else {
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
			Expression(gen, p2->expr);
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		}
	} else if (p2 == NULL) {
		TextGenerator_Str(&(*gen)._, 6, (o7_char *)" += 1");
	} else {
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)" += ");
		Expression(gen, p2->expr);
	}
}

static void Expression_Call_Predefined_Dec(struct Generator *gen, struct Ast_RExpression *e1, struct Ast_RParameter *p2) {
	Expression(gen, e1);
	if (gen->opt->_.checkArith) {
		TextGenerator_Str(&(*gen)._, 11, (o7_char *)" = o7_sub(");
		Expression(gen, e1);
		if (p2 == NULL) {
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)", 1)");
		} else {
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
			Expression(gen, p2->expr);
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		}
	} else if (p2 == NULL) {
		TextGenerator_Str(&(*gen)._, 6, (o7_char *)" -= 1");
	} else {
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)" -= ");
		Expression(gen, p2->expr);
	}
}

static void Expression_Call_Predefined_Assert(struct Generator *gen, struct Ast_RExpression *e) {
	o7_bool c11Assert;
	o7_char buf[5];
	memset(&buf, 0, sizeof(buf));

	c11Assert = (0 > 1);
	if ((e->value_ != NULL) && (e->value_ != &Ast_ExprBooleanGet((0 > 1))->_) && !(!!( (1u << Ast_ExprPointerTouch_cnst) & e->properties))) {
		if (gen->opt->std >= GeneratorC_IsoC11_cnst) {
			c11Assert = (0 < 1);
			TextGenerator_Str(&(*gen)._, 15, (o7_char *)"static_assert(");
		} else {
			TextGenerator_Str(&(*gen)._, 18, (o7_char *)"O7_STATIC_ASSERT(");
		}
	} else if (gen->opt->_.o7Assert) {
		TextGenerator_Str(&(*gen)._, 11, (o7_char *)"O7_ASSERT(");
	} else {
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"assert(");
	}
	CheckExpr(gen, e);
	if (c11Assert) {
		buf[0] = (o7_char)',';
		buf[1] = (o7_char)' ';
		buf[2] = (o7_char)'"';
		buf[3] = (o7_char)'"';
		buf[4] = (o7_char)')';
		TextGenerator_Data(&(*gen)._, 5, buf, 0, 5);
	} else {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void Expression_Call_Predefined(struct Generator *gen, struct Ast_ExprCall__s *call) {
	struct Ast_RExpression *e1;
	struct Ast_RParameter *p2;

	e1 = call->params->expr;
	p2 = call->params->next;
	switch (call->designator->decl->_.id) {
	case 200:
		if (call->_._.type->_._.id == Ast_IdInteger_cnst) {
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)"abs(");
		} else if (call->_._.type->_._.id == Ast_IdLongInt_cnst) {
			TextGenerator_Str(&(*gen)._, 9, (o7_char *)"O7_LABS(");
		} else {
			TextGenerator_Str(&(*gen)._, 6, (o7_char *)"fabs(");
		}
		Expression(gen, e1);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		break;
	case 219:
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x28");
		Factor(gen, e1);
		TextGenerator_Str(&(*gen)._, 11, (o7_char *)" % 2 == 1)");
		break;
	case 214:
		Expression_Call_Predefined_Len(gen, e1);
		break;
	case 217:
		Expression_Call_Predefined_LeftShift(gen, e1, p2->expr);
		break;
	case 201:
		Expression_Call_Predefined_ArithmeticRightShift(gen, e1, p2->expr);
		break;
	case 224:
		Expression_Call_Predefined_Rotate(gen, e1, p2->expr);
		break;
	case 209:
		TextGenerator_Str(&(*gen)._, 10, (o7_char *)"o7_floor(");
		Expression(gen, e1);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		break;
	case 210:
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_flt(");
		Expression(gen, e1);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		break;
	case 220:
		if (e1->value_ == NULL) {
			Expression_Call_Predefined_Ord(gen, e1);
		} else {
			TextGenerator_Str(&(*gen)._, 12, (o7_char *)"((o7_int_t)");
			Expression(gen, e1);
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		}
		break;
	case 206:
		if (gen->opt->_.checkArith && (e1->value_ == NULL)) {
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_chr(");
			Expression(gen, e1);
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		} else {
			TextGenerator_Str(&(*gen)._, 10, (o7_char *)"(o7_char)");
			Factor(gen, e1);
		}
		break;
	case 211:
		Expression_Call_Predefined_Inc(gen, e1, p2);
		break;
	case 207:
		Expression_Call_Predefined_Dec(gen, e1, p2);
		break;
	case 212:
		Expression(gen, e1);
		TextGenerator_Str(&(*gen)._, 11, (o7_char *)" |= 1u << ");
		Factor(gen, p2->expr);
		break;
	case 208:
		Expression(gen, e1);
		TextGenerator_Str(&(*gen)._, 13, (o7_char *)" &= ~(1u << ");
		Factor(gen, p2->expr);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		break;
	case 218:
		Expression_Call_Predefined_New(gen, e1);
		break;
	case 202:
		Expression_Call_Predefined_Assert(gen, e1);
		break;
	case 221:
		TextGenerator_Str(&(*gen)._, 11, (o7_char *)"o7_ldexp(&");
		Expression(gen, e1);
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
		Expression(gen, p2->expr);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		break;
	case 226:
		TextGenerator_Str(&(*gen)._, 11, (o7_char *)"o7_frexp(&");
		Expression(gen, e1);
		TextGenerator_Str(&(*gen)._, 4, (o7_char *)", &");
		Expression(gen, p2->expr);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		break;
	default:
		o7_case_fail(call->designator->decl->_.id);
		break;
	}
}

static void Expression_Call_ActualParam(struct Generator *gen, struct Ast_RParameter **p, struct Ast_RDeclaration **fp);
static o7_int_t Expression_Call_ActualParam_ArrayDeep(struct Ast_RType *t) {
	o7_int_t d;

	d = 0;
	while (t->_._.id == Ast_IdArray_cnst) {
		t = t->_.type;
		d = o7_add(d, 1);
	}
	return d;
}

static void Expression_Call_ActualParam(struct Generator *gen, struct Ast_RParameter **p, struct Ast_RDeclaration **fp) {
	struct Ast_RType *t;
	o7_int_t i, j, dist;
	o7_bool paramOut, castToBase;

	t = (*fp)->type;
	if ((t->_._.id == Ast_IdByte_cnst) && (o7_in((*p)->expr->type->_._.id, ((1u << Ast_IdInteger_cnst) | (1u << Ast_IdLongInt_cnst)))) && gen->opt->_.checkArith && ((*p)->expr->value_ == NULL)) {
		if ((*p)->expr->type->_._.id == Ast_IdInteger_cnst) {
			TextGenerator_Str(&(*gen)._, 9, (o7_char *)"o7_byte(");
		} else {
			TextGenerator_Str(&(*gen)._, 10, (o7_char *)"o7_lbyte(");
		}
		Expression(gen, (*p)->expr);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	} else {
		j = 1;
		if (((*fp)->type->_._.id != Ast_IdChar_cnst) && !(gen->opt->e2k && ((*fp)->type->_._.id == Ast_IdArray_cnst) && ((*fp)->type->_.type->_._.id != Ast_IdArray_cnst))) {
			i =  - 1;
			t = (*p)->expr->type;
			while ((t->_._.id == Ast_IdArray_cnst) && (O7_GUARD(Ast_RArray, (*fp)->type)->count == NULL)) {
				if ((i ==  - 1) && (o7_is((*p)->expr, &Ast_Designator__s_tag))) {
					i = o7_sub(Expression_Call_ActualParam_ArrayDeep(O7_GUARD(Ast_Designator__s, (*p)->expr)->decl->type), Expression_Call_ActualParam_ArrayDeep((*fp)->type));
					if (!(o7_is(O7_GUARD(Ast_Designator__s, (*p)->expr)->decl, &Ast_RFormalParam_tag))) {
						j = Expression_Call_ActualParam_ArrayDeep(O7_GUARD(Ast_Designator__s, (*p)->expr)->_._.type);
					}
				}
				if (O7_GUARD(Ast_RArray, t)->count != NULL) {
					Expression(gen, O7_GUARD(Ast_RArray, t)->count);
				} else {
					Name(gen, O7_GUARD(Ast_Designator__s, (*p)->expr)->decl);
					TextGenerator_Str(&(*gen)._, 5, (o7_char *)"_len");
					TextGenerator_Int(&(*gen)._, i);
				}
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
				i = o7_add(i, 1);
				t = t->_.type;
			}
			t = (*fp)->type;
		}
		dist = (*p)->distance;
		castToBase = (0 > 1);
		paramOut = !!( (1u << Ast_ParamOut_cnst) & O7_GUARD(Ast_RFormalParam, (*fp))->access);
		if (paramOut && (t->_._.id != Ast_IdArray_cnst) || (t->_._.id == Ast_IdRecord_cnst) || (t->_._.id == Ast_IdPointer_cnst) && (0 < dist) && !gen->opt->plan9) {
			castToBase = 0 < dist;
			TextGenerator_DeferChar(&(*gen)._, (o7_char)'&');
		}
		gen->opt->lastSelectorDereference = (0 > 1);
		gen->opt->expectArray = (*fp)->type->_._.id == Ast_IdArray_cnst;

		Swap(&castToBase, &gen->opt->castToBase);
		if (paramOut || (t->_._.id == Ast_IdRecord_cnst)) {
			Expression(gen, (*p)->expr);
		} else {
			CheckExpr(gen, (*p)->expr);
		}
		Swap(&castToBase, &gen->opt->castToBase);
		gen->opt->expectArray = (0 > 1);

		if (!gen->opt->vla) {
			while (j > 1) {
				j = o7_sub(j, 1);
				TextGenerator_Str(&(*gen)._, 4, (o7_char *)"[0]");
			}
		}

		if ((dist > 0) && !gen->opt->plan9) {
			if (t->_._.id == Ast_IdPointer_cnst) {
				dist = o7_sub(dist, 1);
				TextGenerator_Str(&(*gen)._, 4, (o7_char *)"->_");
			}
			while (dist > 0) {
				dist = o7_sub(dist, 1);
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)"._");
			}
		}

		t = (*p)->expr->type;
		if ((t->_._.id == Ast_IdRecord_cnst) && (!gen->opt->skipUnusedTag || Ast_IsNeedTag(O7_GUARD(Ast_RFormalParam, (*fp))))) {
			if (gen->opt->lastSelectorDereference) {
				TextGenerator_Str(&(*gen)._, 7, (o7_char *)", NULL");
			} else {
				if ((o7_is(O7_GUARD(Ast_Designator__s, (*p)->expr)->decl, &Ast_RFormalParam_tag)) && (O7_GUARD(Ast_Designator__s, (*p)->expr)->sel == NULL)) {
					TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
					Name(gen, O7_GUARD(Ast_Designator__s, (*p)->expr)->decl);
				} else {
					TextGenerator_Str(&(*gen)._, 4, (o7_char *)", &");
					GlobalName(gen, &t->_);
				}
				TextGenerator_Str(&(*gen)._, 5, (o7_char *)"_tag");
			}
		}
	}

	*p = (*p)->next;
	*fp = (*fp)->next;
}

static void Expression_Call(struct Generator *gen, struct Ast_ExprCall__s *call) {
	struct Ast_RParameter *p;
	struct Ast_RDeclaration *fp;

	if (o7_is(call->designator->decl, &Ast_PredefinedProcedure__s_tag)) {
		Expression_Call_Predefined(gen, call);
	} else {
		Designator(gen, call->designator);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x28");
		p = call->params;
		fp = (&(O7_GUARD(Ast_RProcType, call->designator->_._.type)->params)->_._);
		if (p != NULL) {
			Expression_Call_ActualParam(gen, &p, &fp);
			while (p != NULL) {
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
				Expression_Call_ActualParam(gen, &p, &fp);
			}
		}
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void Expression_Relation(struct Generator *gen, struct Ast_ExprRelation__s *rel);
static void Expression_Relation_Simple(struct Generator *gen, struct Ast_ExprRelation__s *rel, o7_int_t str_len0, o7_char str[/*len0*/]);
static void Expression_Relation_Simple_Expr(struct Generator *gen, struct Ast_RExpression *e, o7_int_t dist) {
	o7_bool brace, castToBase;

	brace = (o7_in(e->type->_._.id, ((1u << Ast_IdSet_cnst) | (1u << Ast_IdBoolean_cnst)))) && !(o7_is(e, &Ast_RFactor_tag));
	castToBase = (0 > 1);
	if (brace) {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x28");
	} else if ((dist > 0) && (e->type->_._.id == Ast_IdPointer_cnst) && !gen->opt->plan9) {
		castToBase = (0 < 1);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x26");
	}
	Swap(&castToBase, &gen->opt->castToBase);
	Expression(gen, e);
	Swap(&castToBase, &gen->opt->castToBase);
	if ((dist > 0) && !gen->opt->plan9) {
		if (e->type->_._.id == Ast_IdPointer_cnst) {
			dist = o7_sub(dist, 1);
			TextGenerator_Str(&(*gen)._, 4, (o7_char *)"->_");
		}
		while (dist > 0) {
			dist = o7_sub(dist, 1);
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)"._");
		}
	}
	if (brace) {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void Expression_Relation_Simple_Len(struct Generator *gen, struct Ast_RExpression *e) {
	struct Ast_Designator__s *des;

	if (O7_GUARD(Ast_RArray, e->type)->count != NULL) {
		Expression(gen, O7_GUARD(Ast_RArray, e->type)->count);
	} else {
		des = O7_GUARD(Ast_Designator__s, e);
		ArrayDeclLen(gen, des->_._.type, des->decl, des->sel,  - 1);
	}
}

static o7_bool Expression_Relation_Simple_IsArrayAndNotChar(struct Ast_RExpression *e) {
	return (e->type->_._.id == Ast_IdArray_cnst) && ((e->value_ == NULL) || !O7_GUARD(Ast_ExprString__s, e->value_)->asChar);
}

static void Expression_Relation_Simple(struct Generator *gen, struct Ast_ExprRelation__s *rel, o7_int_t str_len0, o7_char str[/*len0*/]) {
	o7_bool notChar0, notChar1;

	notChar0 = Expression_Relation_Simple_IsArrayAndNotChar(rel->exprs[0]);
	if (notChar0 || Expression_Relation_Simple_IsArrayAndNotChar(rel->exprs[1])) {
		if (rel->_.value_ != NULL) {
			Expression(gen, &rel->_.value_->_);
		} else {
			notChar1 = !notChar0 || Expression_Relation_Simple_IsArrayAndNotChar(rel->exprs[1]);
			if (notChar0 == notChar1) {
				O7_ASSERT(notChar0);
				if (gen->opt->e2k) {
					TextGenerator_Str(&(*gen)._, 8, (o7_char *)"strcmp(");
				} else {
					TextGenerator_Str(&(*gen)._, 11, (o7_char *)"o7_strcmp(");
				}
			} else if (notChar1) {
				TextGenerator_Str(&(*gen)._, 13, (o7_char *)"o7_chstrcmp(");
			} else {
				O7_ASSERT(notChar0);
				TextGenerator_Str(&(*gen)._, 13, (o7_char *)"o7_strchcmp(");
			}
			if (notChar0 && !gen->opt->e2k) {
				Expression_Relation_Simple_Len(gen, rel->exprs[0]);
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
			}
			Expression_Relation_Simple_Expr(gen, rel->exprs[0], o7_sub(0, rel->distance));

			TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");

			if (notChar1 && !gen->opt->e2k) {
				Expression_Relation_Simple_Len(gen, rel->exprs[1]);
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
			}
			Expression_Relation_Simple_Expr(gen, rel->exprs[1], rel->distance);

			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
			TextGenerator_Str(&(*gen)._, str_len0, str);
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x30");
		}
	} else if ((gen->opt->_.varInit == GenOptions_VarInitUndefined_cnst) && (rel->_.value_ == NULL) && (o7_in(rel->exprs[0]->type->_._.id, ((1u << Ast_IdInteger_cnst) | (1u << Ast_IdLongInt_cnst)))) && (IsMayNotInited(rel->exprs[0]) || IsMayNotInited(rel->exprs[1]))) {
		if (rel->exprs[0]->type->_._.id == Ast_IdInteger_cnst) {
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_cmp(");
		} else {
			TextGenerator_Str(&(*gen)._, 9, (o7_char *)"o7_lcmp(");
		}
		Expression_Relation_Simple_Expr(gen, rel->exprs[0], o7_sub(0, rel->distance));
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
		Expression_Relation_Simple_Expr(gen, rel->exprs[1], rel->distance);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		TextGenerator_Str(&(*gen)._, str_len0, str);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x30");
	} else {
		Expression_Relation_Simple_Expr(gen, rel->exprs[0], o7_sub(0, rel->distance));
		TextGenerator_Str(&(*gen)._, str_len0, str);
		Expression_Relation_Simple_Expr(gen, rel->exprs[1], rel->distance);
	}
}

static void Expression_Relation_In(struct Generator *gen, struct Ast_ExprRelation__s *rel) {
	if ((rel->_.value_ == NULL) && (rel->exprs[0]->value_ != NULL) && (o7_in(O7_GUARD(Ast_RExprInteger, rel->exprs[0]->value_)->int_, O7_SET(0, TypesLimits_SetMax_cnst)))) {
		TextGenerator_Str(&(*gen)._, 4, (o7_char *)"!!(");
		TextGenerator_Str(&(*gen)._, 9, (o7_char *)" (1u << ");
		Factor(gen, rel->exprs[0]);
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)") & ");
		Factor(gen, rel->exprs[1]);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	} else {
		if (rel->_.value_ != NULL) {
			TextGenerator_Str(&(*gen)._, 7, (o7_char *)"O7_IN(");
		} else {
			TextGenerator_Str(&(*gen)._, 7, (o7_char *)"o7_in(");
		}
		Expression(gen, rel->exprs[0]);
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
		Expression(gen, rel->exprs[1]);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void Expression_Relation(struct Generator *gen, struct Ast_ExprRelation__s *rel) {
	switch (rel->relation) {
	case 11:
		Expression_Relation_Simple(gen, rel, 5, (o7_char *)" == ");
		break;
	case 12:
		Expression_Relation_Simple(gen, rel, 5, (o7_char *)" != ");
		break;
	case 13:
		Expression_Relation_Simple(gen, rel, 4, (o7_char *)" < ");
		break;
	case 14:
		Expression_Relation_Simple(gen, rel, 5, (o7_char *)" <= ");
		break;
	case 15:
		Expression_Relation_Simple(gen, rel, 4, (o7_char *)" > ");
		break;
	case 16:
		Expression_Relation_Simple(gen, rel, 5, (o7_char *)" >= ");
		break;
	case 17:
		Expression_Relation_In(gen, rel);
		break;
	default:
		o7_case_fail(rel->relation);
		break;
	}
}

static void Expression_Sum(struct Generator *gen, struct Ast_RExprSum *sum);
static o7_int_t Expression_Sum_CountSignChanges(struct Ast_RExprSum *sum) {
	o7_int_t i;

	i = 0;
	if (sum != NULL) {
		while (sum->next != NULL) {
			i = o7_add(i, (o7_int_t)(sum->add != sum->next->add));
			sum = sum->next;
		}
	}
	return i;
}

static void Expression_Sum(struct Generator *gen, struct Ast_RExprSum *sum) {
	o7_int_t i;

	if (o7_in(sum->_.type->_._.id, Ast_Sets_cnst)) {
		i = Expression_Sum_CountSignChanges(sum->next);
		TextGenerator_CharFill(&(*gen)._, (o7_char)'(', i);
		if (sum->add == Ast_Minus_cnst) {
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)" ~");
		}
		CheckExpr(gen, sum->term);
		sum = sum->next;
		while (sum != NULL) {
			O7_ASSERT(o7_in(sum->_.type->_._.id, Ast_Sets_cnst));
			if (sum->add == Ast_Minus_cnst) {
				TextGenerator_Str(&(*gen)._, 5, (o7_char *)" & ~");
			} else {
				O7_ASSERT(sum->add == Ast_Plus_cnst);
				TextGenerator_Str(&(*gen)._, 4, (o7_char *)" | ");
			}
			CheckExpr(gen, sum->term);
			if ((sum->next != NULL) && (sum->next->add != sum->add)) {
				TextGenerator_Char(&(*gen)._, (o7_char)')');
			}
			sum = sum->next;
		}
	} else if (sum->_.type->_._.id == Ast_IdBoolean_cnst) {
		CheckExpr(gen, sum->term);
		sum = sum->next;
		while (sum != NULL) {
			O7_ASSERT(sum->_.type->_._.id == Ast_IdBoolean_cnst);
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)" || ");
			CheckExpr(gen, sum->term);
			sum = sum->next;
		}
	} else {
		do {
			O7_ASSERT(o7_in(sum->_.type->_._.id, ((1u << Ast_IdInteger_cnst) | (1u << Ast_IdLongInt_cnst) | (1u << Ast_IdReal_cnst) | (1u << Ast_IdReal32_cnst))));
			if (sum->add == Ast_Minus_cnst) {
				TextGenerator_Str(&(*gen)._, 4, (o7_char *)" - ");
			} else if (sum->add == Ast_Plus_cnst) {
				TextGenerator_Str(&(*gen)._, 4, (o7_char *)" + ");
			}
			CheckExpr(gen, sum->term);
			sum = sum->next;
		} while (!(sum == NULL));
	}
}

static void Expression_SumCheck(struct Generator *gen, struct Ast_RExprSum *sum);
static void Expression_SumCheck_GenArrOfAddOrSub(struct Generator *gen, o7_int_t arr_len0, struct Ast_RExprSum *arr[/*len0*/], o7_int_t last, o7_int_t add_len0, o7_char add[/*len0*/], o7_int_t sub_len0, o7_char sub[/*len0*/]) {
	o7_int_t i;

	i = last;
	while (i > 0) {
		switch (arr[o7_ind(arr_len0, i)]->add) {
		case 2:
			TextGenerator_Str(&(*gen)._, sub_len0, sub);
			break;
		case 1:
			TextGenerator_Str(&(*gen)._, add_len0, add);
			break;
		default:
			o7_case_fail(arr[o7_ind(arr_len0, i)]->add);
			break;
		}
		i = o7_sub(i, 1);
	}
	if (arr[0]->add == Scanner_Minus_cnst) {
		TextGenerator_Str(&(*gen)._, sub_len0, sub);
		TextGenerator_Str(&(*gen)._, 4, (o7_char *)"0, ");
		Expression(gen, arr[0]->term);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	} else {
		Expression(gen, arr[0]->term);
	}
}

static void Expression_SumCheck(struct Generator *gen, struct Ast_RExprSum *sum) {
	struct Ast_RExprSum *arr[TranslatorLimits_TermsInSum_cnst];
	o7_int_t i, last;
	memset(&arr, 0, sizeof(arr));

	last =  - 1;
	do {
		last = o7_add(last, 1);
		arr[o7_ind(TranslatorLimits_TermsInSum_cnst, last)] = sum;
		sum = sum->next;
	} while (!(sum == NULL));
	switch (arr[0]->_.type->_._.id) {
	case 0:
		Expression_SumCheck_GenArrOfAddOrSub(gen, TranslatorLimits_TermsInSum_cnst, arr, last, 8, (o7_char *)"o7_add(", 8, (o7_char *)"o7_sub(");
		break;
	case 1:
		Expression_SumCheck_GenArrOfAddOrSub(gen, TranslatorLimits_TermsInSum_cnst, arr, last, 9, (o7_char *)"o7_ladd(", 9, (o7_char *)"o7_lsub(");
		break;
	case 5:
		Expression_SumCheck_GenArrOfAddOrSub(gen, TranslatorLimits_TermsInSum_cnst, arr, last, 9, (o7_char *)"o7_fadd(", 9, (o7_char *)"o7_fsub(");
		break;
	case 6:
		Expression_SumCheck_GenArrOfAddOrSub(gen, TranslatorLimits_TermsInSum_cnst, arr, last, 10, (o7_char *)"o7_faddf(", 10, (o7_char *)"o7_fsubf(");
		break;
	default:
		o7_case_fail(arr[0]->_.type->_._.id);
		break;
	}
	i = 0;
	while (i < last) {
		i = o7_add(i, 1);
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
		Expression(gen, arr[o7_ind(TranslatorLimits_TermsInSum_cnst, i)]->term);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static o7_bool Expression_IsPresentDiv(struct Ast_ExprTerm__s *term) {
	while (!(o7_in(term->mult, ((1u << Scanner_Div_cnst) | (1u << Scanner_Mod_cnst)))) && (o7_is(term->expr, &Ast_ExprTerm__s_tag))) {
		term = O7_GUARD(Ast_ExprTerm__s, term->expr);
	}
	return o7_in(term->mult, ((1u << Scanner_Div_cnst) | (1u << Scanner_Mod_cnst)));
}

static void Expression_Term(struct Generator *gen, struct Ast_ExprTerm__s *term) {
	do {
		CheckExpr(gen, &term->factor->_);
		switch (term->mult) {
		case 19:
			if (o7_in(term->_.type->_._.id, Ast_Sets_cnst)) {
				TextGenerator_Str(&(*gen)._, 4, (o7_char *)" & ");
			} else {
				TextGenerator_Str(&(*gen)._, 4, (o7_char *)" * ");
			}
			break;
		case 20:
		case 22:
			if (o7_in(term->_.type->_._.id, Ast_Sets_cnst)) {
				O7_ASSERT(term->mult == Scanner_Slash_cnst);
				TextGenerator_Str(&(*gen)._, 4, (o7_char *)" ^ ");
			} else {
				TextGenerator_Str(&(*gen)._, 4, (o7_char *)" / ");
			}
			break;
		case 21:
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)" && ");
			break;
		case 23:
			TextGenerator_Str(&(*gen)._, 4, (o7_char *)" % ");
			break;
		default:
			o7_case_fail(term->mult);
			break;
		}
		if (o7_is(term->expr, &Ast_ExprTerm__s_tag)) {
			term = O7_GUARD(Ast_ExprTerm__s, term->expr);
		} else {
			CheckExpr(gen, term->expr);
			term = NULL;
		}
	} while (!(term == NULL));
}

static void Expression_TermCheck(struct Generator *gen, struct Ast_ExprTerm__s *term) {
	struct Ast_ExprTerm__s *arr[TranslatorLimits_FactorsInTerm_cnst];
	o7_int_t i, last;
	memset(&arr, 0, sizeof(arr));

	arr[0] = term;
	i = 0;
	while (o7_is(term->expr, &Ast_ExprTerm__s_tag)) {
		i = o7_add(i, 1);
		term = O7_GUARD(Ast_ExprTerm__s, term->expr);
		arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, i)] = term;
	}
	last = i;
	if (arr[0]->_.value_ != NULL) {
		while (i >= 0) {
			switch (arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, i)]->mult) {
			case 19:
				TextGenerator_Str(&(*gen)._, 8, (o7_char *)"O7_MUL(");
				break;
			case 22:
				TextGenerator_Str(&(*gen)._, 8, (o7_char *)"O7_DIV(");
				break;
			case 23:
				TextGenerator_Str(&(*gen)._, 8, (o7_char *)"O7_MOD(");
				break;
			default:
				o7_case_fail(arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, i)]->mult);
				break;
			}
			i = o7_sub(i, 1);
		}
	} else {
		switch (term->_.type->_._.id) {
		case 0:
			while (i >= 0) {
				switch (arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, i)]->mult) {
				case 19:
					TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_mul(");
					break;
				case 22:
					TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_div(");
					break;
				case 23:
					TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_mod(");
					break;
				default:
					o7_case_fail(arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, i)]->mult);
					break;
				}
				i = o7_sub(i, 1);
			}
			break;
		case 1:
			while (i >= 0) {
				switch (arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, i)]->mult) {
				case 19:
					TextGenerator_Str(&(*gen)._, 9, (o7_char *)"o7_lmul(");
					break;
				case 22:
					TextGenerator_Str(&(*gen)._, 9, (o7_char *)"o7_ldiv(");
					break;
				case 23:
					TextGenerator_Str(&(*gen)._, 9, (o7_char *)"o7_lmod(");
					break;
				default:
					o7_case_fail(arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, i)]->mult);
					break;
				}
				i = o7_sub(i, 1);
			}
			break;
		case 5:
			while (i >= 0) {
				switch (arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, i)]->mult) {
				case 19:
					TextGenerator_Str(&(*gen)._, 9, (o7_char *)"o7_fmul(");
					break;
				case 20:
					TextGenerator_Str(&(*gen)._, 9, (o7_char *)"o7_fdiv(");
					break;
				default:
					o7_case_fail(arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, i)]->mult);
					break;
				}
				i = o7_sub(i, 1);
			}
			break;
		case 6:
			while (i >= 0) {
				switch (arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, i)]->mult) {
				case 19:
					TextGenerator_Str(&(*gen)._, 10, (o7_char *)"o7_fmulf(");
					break;
				case 20:
					TextGenerator_Str(&(*gen)._, 10, (o7_char *)"o7_fdivf(");
					break;
				default:
					o7_case_fail(arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, i)]->mult);
					break;
				}
				i = o7_sub(i, 1);
			}
			break;
		default:
			o7_case_fail(term->_.type->_._.id);
			break;
		}
	}
	Expression(gen, &arr[0]->factor->_);
	i = 0;
	while (i < last) {
		i = o7_add(i, 1);
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
		Expression(gen, &arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, i)]->factor->_);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
	TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
	Expression(gen, arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, last)]->expr);
	TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
}

static void Expression_Boolean(struct Generator *gen, struct Ast_ExprBoolean__s *e) {
	if (gen->opt->std == GeneratorC_IsoC90_cnst) {
		if (e->bool_) {
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)"(0 < 1)");
		} else {
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)"(0 > 1)");
		}
	} else {
		if (e->bool_) {
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)"true");
		} else {
			TextGenerator_Str(&(*gen)._, 6, (o7_char *)"false");
		}
	}
}

static void Expression_CString(struct Generator *gen, struct Ast_ExprString__s *e) {
	o7_char s[6];
	o7_char ch;
	struct StringStore_String w;
	memset(&s, 0, sizeof(s));
	memset(&w, 0, sizeof(w));

	w = e->string;
	if (e->asChar && !gen->opt->expectArray) {
		ch = o7_chr(e->_.int_);
		if (ch == (o7_char)'\'') {
			TextGenerator_Str(&(*gen)._, 14, (o7_char *)"(o7_char)'\\''");
		} else if (ch == (o7_char)'\\') {
			TextGenerator_Str(&(*gen)._, 14, (o7_char *)"(o7_char)'\\\\'");
		} else if ((ch >= (o7_char)' ') && (ch <= (o7_char)127)) {
			TextGenerator_Str(&(*gen)._, 10, (o7_char *)"(o7_char)");
			s[0] = (o7_char)'\'';
			s[1] = ch;
			s[2] = (o7_char)'\'';
			TextGenerator_Data(&(*gen)._, 6, s, 0, 3);
		} else {
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)"0x");
			s[0] = Hex_To(o7_div(e->_.int_, 16));
			s[1] = Hex_To(o7_mod(e->_.int_, 16));
			s[2] = (o7_char)'u';
			TextGenerator_Data(&(*gen)._, 6, s, 0, 3);
		}
	} else {
		if (!gen->insideSizeOf) {
			TextGenerator_Str(&(*gen)._, 12, (o7_char *)"(o7_char *)");
		}
		if ((w.ofs >= 0) && (w.block->s[o7_ind(StringStore_BlockSize_cnst + 1, w.ofs)] == (o7_char)'"')) {
			TextGenerator_ScreeningString(&(*gen)._, &w);
		} else {
			s[0] = (o7_char)'"';
			s[1] = (o7_char)'\\';
			s[2] = (o7_char)'x';
			s[3] = Hex_To(o7_div(e->_.int_, 16));
			s[4] = Hex_To(o7_mod(e->_.int_, 16));
			s[5] = (o7_char)'"';
			TextGenerator_Data(&(*gen)._, 6, s, 0, 6);
		}
	}
}

static void Expression_ExprInt(struct Generator *gen, o7_int_t int_) {
	if (int_ >= 0) {
		TextGenerator_Int(&(*gen)._, int_);
	} else {
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)"(-");
		TextGenerator_Int(&(*gen)._, o7_sub(0, int_));
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void Expression_ExprLongInt(struct Generator *gen, o7_int_t int_) {
	O7_ASSERT((0 > 1));
	if (int_ >= 0) {
		TextGenerator_Int(&(*gen)._, int_);
	} else {
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)"(-");
		TextGenerator_Int(&(*gen)._, o7_sub(0, int_));
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void Expression_SetValue(struct Generator *gen, struct Ast_ExprSetValue__s *set) {
	O7_ASSERT(set->set[1] == 0);

	TextGenerator_Str(&(*gen)._, 3, (o7_char *)"0x");
	TextGenerator_Set(&(*gen)._, &set->set[0]);
	TextGenerator_Char(&(*gen)._, (o7_char)'u');
}

static void Expression_Set(struct Generator *gen, struct Ast_RExprSet *set);
static void Expression_Set_Item(struct Generator *gen, struct Ast_RExprSet *set) {
	if (set->exprs[0] == NULL) {
		TextGenerator_Char(&(*gen)._, (o7_char)'0');
	} else {
		if (set->exprs[1] == NULL) {
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)"(1u << ");
			Factor(gen, set->exprs[0]);
		} else {
			if ((set->exprs[0]->value_ == NULL) || (set->exprs[1]->value_ == NULL)) {
				TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_set(");
			} else {
				TextGenerator_Str(&(*gen)._, 8, (o7_char *)"O7_SET(");
			}
			Expression(gen, set->exprs[0]);
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
			Expression(gen, set->exprs[1]);
		}
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void Expression_Set(struct Generator *gen, struct Ast_RExprSet *set) {
	if (set->next == NULL) {
		Expression_Set_Item(gen, set);
	} else {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x28");
		Expression_Set_Item(gen, set);
		do {
			TextGenerator_Str(&(*gen)._, 4, (o7_char *)" | ");
			set = set->next;
			Expression_Set_Item(gen, set);
		} while (!(set->next == NULL));
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void Expression_IsExtension(struct Generator *gen, struct Ast_ExprIsExtension__s *is) {
	struct Ast_RDeclaration *decl;
	struct Ast_RType *extType;

	decl = is->designator->decl;
	extType = is->extType;
	if (is->designator->_._.type->_._.id == Ast_IdPointer_cnst) {
		extType = extType->_.type;
		O7_ASSERT(CheckStructName(gen, O7_GUARD(Ast_RRecord, extType)));
		TextGenerator_Str(&(*gen)._, 7, (o7_char *)"o7_is(");
		Expression(gen, &is->designator->_._);
		TextGenerator_Str(&(*gen)._, 4, (o7_char *)", &");
	} else {
		TextGenerator_Str(&(*gen)._, 9, (o7_char *)"o7_is_r(");
		GlobalName(gen, decl);
		TextGenerator_Str(&(*gen)._, 7, (o7_char *)"_tag, ");
		GlobalName(gen, decl);
		TextGenerator_Str(&(*gen)._, 4, (o7_char *)", &");
	}
	GlobalName(gen, &extType->_);
	TextGenerator_Str(&(*gen)._, 6, (o7_char *)"_tag)");
}

static void Expression(struct Generator *gen, struct Ast_RExpression *expr) {
	switch (expr->_.id) {
	case 0:
		Expression_ExprInt(gen, O7_GUARD(Ast_RExprInteger, expr)->int_);
		break;
	case 1:
		Expression_ExprLongInt(gen, O7_GUARD(Ast_RExprInteger, expr)->int_);
		break;
	case 2:
		Expression_Boolean(gen, O7_GUARD(Ast_ExprBoolean__s, expr));
		break;
	case 5:
	case 6:
		if (StringStore_IsDefined(&O7_GUARD(Ast_ExprReal__s, expr)->str)) {
			TextGenerator_String(&(*gen)._, &O7_GUARD(Ast_ExprReal__s, expr)->str);
		} else {
			TextGenerator_Real(&(*gen)._, O7_GUARD(Ast_ExprReal__s, expr)->real);
		}
		break;
	case 15:
		Expression_CString(gen, O7_GUARD(Ast_ExprString__s, expr));
		break;
	case 7:
	case 8:
		if (o7_is(expr, &Ast_RExprSet_tag)) {
			Expression_Set(gen, O7_GUARD(Ast_RExprSet, expr));
		} else {
			Expression_SetValue(gen, O7_GUARD(Ast_ExprSetValue__s, expr));
		}
		break;
	case 25:
		Expression_Call(gen, O7_GUARD(Ast_ExprCall__s, expr));
		break;
	case 20:
		if ((expr->value_ != NULL) && (expr->value_->_._.id == Ast_IdString_cnst)) {
			Expression_CString(gen, O7_GUARD(Ast_ExprString__s, expr->value_));
		} else {
			Designator(gen, O7_GUARD(Ast_Designator__s, expr));
		}
		break;
	case 21:
		Expression_Relation(gen, O7_GUARD(Ast_ExprRelation__s, expr));
		break;
	case 22:
		if (gen->opt->_.checkArith && (o7_in(expr->type->_._.id, CheckableArithTypes_cnst)) && (expr->value_ == NULL)) {
			Expression_SumCheck(gen, O7_GUARD(Ast_RExprSum, expr));
		} else {
			Expression_Sum(gen, O7_GUARD(Ast_RExprSum, expr));
		}
		break;
	case 23:
		if (gen->opt->_.checkArith && (o7_in(expr->type->_._.id, CheckableArithTypes_cnst)) || (o7_in(expr->type->_._.id, Ast_Integers_cnst)) && Expression_IsPresentDiv(O7_GUARD(Ast_ExprTerm__s, expr))) {
			Expression_TermCheck(gen, O7_GUARD(Ast_ExprTerm__s, expr));
		} else if ((expr->value_ != NULL) && (!!( (1u << Ast_ExprIntNegativeDividentTouch_cnst) & expr->properties))) {
			Expression(gen, &expr->value_->_);
		} else {
			Expression_Term(gen, O7_GUARD(Ast_ExprTerm__s, expr));
		}
		break;
	case 24:
		if (o7_in(expr->type->_._.id, Ast_Sets_cnst)) {
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x7E");
			Expression(gen, O7_GUARD(Ast_ExprNegate__s, expr)->expr);
		} else {
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x21");
			CheckExpr(gen, O7_GUARD(Ast_ExprNegate__s, expr)->expr);
		}
		break;
	case 26:
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x28");
		Expression(gen, O7_GUARD(Ast_ExprBraces__s, expr)->expr);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		break;
	case 9:
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)"NULL");
		break;
	case 27:
		Expression_IsExtension(gen, O7_GUARD(Ast_ExprIsExtension__s, expr));
		break;
	default:
		o7_case_fail(expr->_.id);
		break;
	}
}

static void Qualifier(struct Generator *gen, struct Ast_RType *typ) {
	switch (typ->_._.id) {
	case 0:
		TextGenerator_Str(&(*gen)._, 9, (o7_char *)"o7_int_t");
		break;
	case 1:
		TextGenerator_Str(&(*gen)._, 10, (o7_char *)"o7_long_t");
		break;
	case 7:
		TextGenerator_Str(&(*gen)._, 9, (o7_char *)"o7_set_t");
		break;
	case 8:
		TextGenerator_Str(&(*gen)._, 11, (o7_char *)"o7_set64_t");
		break;
	case 2:
		if ((gen->opt->std >= GeneratorC_IsoC99_cnst) && (gen->opt->_.varInit != GenOptions_VarInitUndefined_cnst)) {
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)"bool");
		} else {
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_bool");
		}
		break;
	case 3:
		TextGenerator_Str(&(*gen)._, 14, (o7_char *)"char unsigned");
		break;
	case 4:
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_char");
		break;
	case 5:
		TextGenerator_Str(&(*gen)._, 7, (o7_char *)"double");
		break;
	case 6:
		TextGenerator_Str(&(*gen)._, 6, (o7_char *)"float");
		break;
	case 9:
	case 13:
		GlobalName(gen, &typ->_);
		break;
	default:
		o7_case_fail(typ->_._.id);
		break;
	}
}

static void Invert(struct Generator *gen) {
	gen->memout->invert = !gen->memout->invert;
}

static void ProcHead(struct Generator *gen, struct Ast_RProcType *proc);
static void ProcHead_Parameters(struct Generator *gen, struct Ast_RProcType *proc);
static void ProcHead_Parameters_Par(struct Generator *gen, struct Ast_RFormalParam *fp) {
	struct Ast_RType *t;
	o7_int_t i;

	i = 0;
	t = fp->_._.type;
	if (!((t->_._.id == Ast_IdArray_cnst) && gen->opt->e2k && (t->_.type->_._.id != Ast_IdArray_cnst))) {
		while ((t->_._.id == Ast_IdArray_cnst) && (O7_GUARD(Ast_RArray, t)->count == NULL)) {
			TextGenerator_Str(&(*gen)._, 10, (o7_char *)"o7_int_t ");
			Name(gen, &fp->_._);
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)"_len");
			TextGenerator_Int(&(*gen)._, i);
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
			i = o7_add(i, 1);
			t = t->_.type;
		}
	}
	t = fp->_._.type;
	declarator(gen, &fp->_._, (0 > 1), (0 > 1), (0 > 1));
	if ((t->_._.id == Ast_IdRecord_cnst) && (!gen->opt->skipUnusedTag || Ast_IsNeedTag(fp))) {
		TextGenerator_Str(&(*gen)._, 13, (o7_char *)", o7_tag_t *");
		Name(gen, &fp->_._);
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)"_tag");
	}
}

static void ProcHead_Parameters(struct Generator *gen, struct Ast_RProcType *proc) {
	struct Ast_RDeclaration *p;

	if (proc->params == NULL) {
		TextGenerator_Str(&(*gen)._, 7, (o7_char *)"(void)");
	} else {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x28");
		p = (&(proc->params)->_._);
		while (p != &proc->end->_._) {
			ProcHead_Parameters_Par(gen, O7_GUARD(Ast_RFormalParam, p));
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
			p = p->next;
		}
		ProcHead_Parameters_Par(gen, O7_GUARD(Ast_RFormalParam, p));
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void ProcHead(struct Generator *gen, struct Ast_RProcType *proc) {
	ProcHead_Parameters(gen, proc);
	Invert(gen);
	type(gen, NULL, proc->_._._.type, (0 > 1), (0 > 1));
	MemWriteInvert(&(*gen->memout));
}

static void Declarator(struct Generator *gen, struct Ast_RDeclaration *decl, o7_bool typeDecl, o7_bool sameType, o7_bool global) {
	struct Generator g;
	struct GeneratorC_MemoryOut *mo;
	memset(&g, 0, sizeof(g));

	mo = PMemoryOutGet(gen->opt);

	TextGenerator_Init(&g._, &mo->_);
	g.memout = mo;
	TextGenerator_SetTabs(&g._, &(*gen)._);
	g.module_ = gen->module_;
	g.interface_ = gen->interface_;
	g.opt = gen->opt;

	if ((o7_is(decl, &Ast_RFormalParam_tag)) && ((!!( (1u << Ast_ParamOut_cnst) & O7_GUARD(Ast_RFormalParam, decl)->access)) && !(o7_is(decl->type, &Ast_RArray_tag)) || (o7_is(decl->type, &Ast_RRecord_tag)))) {
		TextGenerator_Str(&g._, 2, (o7_char *)"\x2A");
	} else if (o7_is(decl, &Ast_Const__s_tag)) {
		TextGenerator_Str(&g._, 7, (o7_char *)"const ");
	}
	if (global) {
		GlobalName(&g, decl);
	} else {
		Name(&g, decl);
	}
	if (o7_is(decl, &Ast_RProcedure_tag)) {
		ProcHead(&g, O7_GUARD(Ast_RProcedure, decl)->_.header);
	} else {
		mo->invert = !mo->invert;
		if (o7_is(decl, &Ast_RType_tag)) {
			type(&g, decl, O7_GUARD(Ast_RType, decl), typeDecl, (0 > 1));
		} else {
			type(&g, decl, decl->type, (0 > 1), sameType);
		}
	}

	MemWriteDirect(gen, &(*mo));

	PMemoryOutBack(gen->opt, mo);
}

static void RecordUndefHeader(struct Generator *gen, struct Ast_RRecord *rec, o7_bool interf) {
	if (rec->_._._.mark && !gen->opt->_.main_) {
		TextGenerator_Str(&(*gen)._, 13, (o7_char *)"extern void ");
	} else {
		TextGenerator_Str(&(*gen)._, 13, (o7_char *)"static void ");
	}
	GlobalName(gen, &rec->_._._);
	TextGenerator_Str(&(*gen)._, 15, (o7_char *)"_undef(struct ");
	GlobalName(gen, &rec->_._._);
	if (interf) {
		TextGenerator_StrLn(&(*gen)._, 6, (o7_char *)" *r);");
	} else {
		TextGenerator_StrOpen(&(*gen)._, 7, (o7_char *)" *r) {");
	}
}

static void RecordRetainReleaseHeader(struct Generator *gen, struct Ast_RRecord *rec, o7_bool interf, o7_int_t retrel_len0, o7_char retrel[/*len0*/]) {
	if (rec->_._._.mark && !gen->opt->_.main_) {
		TextGenerator_Str(&(*gen)._, 13, (o7_char *)"extern void ");
	} else {
		TextGenerator_Str(&(*gen)._, 13, (o7_char *)"static void ");
	}
	GlobalName(gen, &rec->_._._);
	TextGenerator_Str(&(*gen)._, retrel_len0, retrel);
	TextGenerator_Str(&(*gen)._, 9, (o7_char *)"(struct ");
	GlobalName(gen, &rec->_._._);
	if (interf) {
		TextGenerator_StrLn(&(*gen)._, 6, (o7_char *)" *r);");
	} else {
		TextGenerator_StrOpen(&(*gen)._, 7, (o7_char *)" *r) {");
	}
}

static void RecordReleaseHeader(struct Generator *gen, struct Ast_RRecord *rec, o7_bool interf) {
	RecordRetainReleaseHeader(gen, rec, interf, 9, (o7_char *)"_release");
}

static void RecordRetainHeader(struct Generator *gen, struct Ast_RRecord *rec, o7_bool interf) {
	RecordRetainReleaseHeader(gen, rec, interf, 8, (o7_char *)"_retain");
}

static o7_bool IsArrayTypeSimpleUndef(struct Ast_RType *typ, o7_int_t *id, o7_int_t *deep) {
	*deep = 0;
	while (typ->_._.id == Ast_IdArray_cnst) {
		*deep = o7_add(*deep, 1);
		typ = typ->_.type;
	}
	*id = typ->_._.id;
	return o7_in(*id, ((1u << Ast_IdReal_cnst) | (1u << Ast_IdReal32_cnst) | (1u << Ast_IdInteger_cnst) | (1u << Ast_IdLongInt_cnst) | (1u << Ast_IdBoolean_cnst)));
}

static void ArraySimpleUndef(struct Generator *gen, o7_int_t arrTypeId, struct Ast_RDeclaration *d, o7_bool inRec) {
	switch (arrTypeId) {
	case 0:
		TextGenerator_Str(&(*gen)._, 15, (o7_char *)"O7_INTS_UNDEF(");
		break;
	case 1:
		TextGenerator_Str(&(*gen)._, 16, (o7_char *)"O7_LONGS_UNDEF(");
		break;
	case 5:
		TextGenerator_Str(&(*gen)._, 18, (o7_char *)"O7_DOUBLES_UNDEF(");
		break;
	case 6:
		TextGenerator_Str(&(*gen)._, 17, (o7_char *)"O7_FLOATS_UNDEF(");
		break;
	case 2:
		TextGenerator_Str(&(*gen)._, 16, (o7_char *)"O7_BOOLS_UNDEF(");
		break;
	default:
		o7_case_fail(arrTypeId);
		break;
	}
	if (inRec) {
		TextGenerator_Str(&(*gen)._, 4, (o7_char *)"r->");
	}
	Name(gen, d);
	TextGenerator_Str(&(*gen)._, 3, (o7_char *)");");
}

static void RecordUndefCall(struct Generator *gen, struct Ast_RDeclaration *var_) {
	GlobalName(gen, &var_->type->_);
	TextGenerator_Str(&(*gen)._, 9, (o7_char *)"_undef(&");
	GlobalName(gen, var_);
	TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
}

static struct Ast_RType *TypeForUndef(struct Ast_RType *t) {
	if ((t->_._.id != Ast_IdRecord_cnst) || (t->_._.ext == NULL) || !O7_GUARD(RecExt__s, t->_._.ext)->undef) {
		t = NULL;
	}
	return t;
}

static void RecordUndef(struct Generator *gen, struct Ast_RRecord *rec);
static void RecordUndef_IteratorIfNeed(struct Generator *gen, struct Ast_RDeclaration *var_) {
	o7_int_t id = 0, deep = 0;

	while ((var_ != NULL) && ((var_->type->_._.id != Ast_IdArray_cnst) || IsArrayTypeSimpleUndef(var_->type, &id, &deep) || (TypeForUndef(var_->type->_.type) == NULL))) {
		var_ = var_->next;
	}
	if (var_ != NULL) {
		TextGenerator_StrLn(&(*gen)._, 12, (o7_char *)"o7_int_t i;");
	}
}

static void RecordUndef_Memset(struct Generator *gen, struct Ast_RDeclaration *var_) {
	TextGenerator_Str(&(*gen)._, 12, (o7_char *)"memset(&r->");
	Name(gen, var_);
	TextGenerator_Str(&(*gen)._, 16, (o7_char *)", 0, sizeof(r->");
	Name(gen, var_);
	TextGenerator_StrLn(&(*gen)._, 4, (o7_char *)"));");
}

static void RecordUndef(struct Generator *gen, struct Ast_RRecord *rec) {
	struct Ast_RDeclaration *var_;
	o7_int_t arrTypeId = 0, arrDeep = 0;
	struct Ast_RType *typeUndef;

	RecordUndefHeader(gen, rec, (0 > 1));
	RecordUndef_IteratorIfNeed(gen, &rec->vars->_);
	if (rec->base != NULL) {
		GlobalName(gen, &rec->base->_._._);
		if (!gen->opt->plan9) {
			TextGenerator_StrLn(&(*gen)._, 15, (o7_char *)"_undef(&r->_);");
		} else {
			TextGenerator_StrLn(&(*gen)._, 11, (o7_char *)"_undef(r);");
		}
	}
	O7_GUARD(RecExt__s, rec->_._._._.ext)->undef = (0 < 1);
	var_ = (&(rec->vars)->_);
	while (var_ != NULL) {
		if (!(o7_in(var_->type->_._.id, ((1u << Ast_IdArray_cnst) | (1u << Ast_IdRecord_cnst))))) {
			TextGenerator_Str(&(*gen)._, 4, (o7_char *)"r->");
			Name(gen, var_);
			VarInit(gen, var_, (0 < 1));
			TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x3B");
		} else if (var_->type->_._.id == Ast_IdArray_cnst) {
			typeUndef = TypeForUndef(var_->type->_.type);
			if (IsArrayTypeSimpleUndef(var_->type, &arrTypeId, &arrDeep)) {
				ArraySimpleUndef(gen, arrTypeId, var_, (0 < 1));
			} else if (typeUndef != NULL) {
				TextGenerator_Str(&(*gen)._, 27, (o7_char *)"for (i = 0; i < O7_LEN(r->");
				Name(gen, var_);
				TextGenerator_StrOpen(&(*gen)._, 13, (o7_char *)"); i += 1) {");
				GlobalName(gen, &typeUndef->_);
				TextGenerator_Str(&(*gen)._, 11, (o7_char *)"_undef(r->");
				Name(gen, var_);
				TextGenerator_StrLn(&(*gen)._, 7, (o7_char *)" + i);");

				TextGenerator_StrLnClose(&(*gen)._, 2, (o7_char *)"\x7D");
			} else {
				RecordUndef_Memset(gen, var_);
			}
		} else if ((var_->type->_._.id == Ast_IdRecord_cnst) && (var_->type->_._.ext != NULL)) {
			GlobalName(gen, &var_->type->_);
			TextGenerator_Str(&(*gen)._, 12, (o7_char *)"_undef(&r->");
			Name(gen, var_);
			TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
		} else {
			RecordUndef_Memset(gen, var_);
		}
		var_ = var_->next;
	}
	TextGenerator_StrLnClose(&(*gen)._, 2, (o7_char *)"\x7D");
}

static void RecordRetainRelease(struct Generator *gen, struct Ast_RRecord *rec, o7_int_t retrel_len0, o7_char retrel[/*len0*/], o7_int_t retrelArray_len0, o7_char retrelArray[/*len0*/], o7_int_t retNull_len0, o7_char retNull[/*len0*/]);
static void RecordRetainRelease_IteratorIfNeed(struct Generator *gen, struct Ast_RDeclaration *var_) {
	while ((var_ != NULL) && !((var_->type->_._.id == Ast_IdArray_cnst) && (var_->type->_.type->_._.id == Ast_IdRecord_cnst))) {
		var_ = var_->next;
	}
	if (var_ != NULL) {
		TextGenerator_StrLn(&(*gen)._, 12, (o7_char *)"o7_int_t i;");
	}
}

static void RecordRetainRelease(struct Generator *gen, struct Ast_RRecord *rec, o7_int_t retrel_len0, o7_char retrel[/*len0*/], o7_int_t retrelArray_len0, o7_char retrelArray[/*len0*/], o7_int_t retNull_len0, o7_char retNull[/*len0*/]) {
	struct Ast_RDeclaration *var_;

	RecordRetainReleaseHeader(gen, rec, (0 > 1), retrel_len0, retrel);

	RecordRetainRelease_IteratorIfNeed(gen, &rec->vars->_);
	if (rec->base != NULL) {
		GlobalName(gen, &rec->base->_._._);
		TextGenerator_Str(&(*gen)._, retrel_len0, retrel);
		if (!gen->opt->plan9) {
			TextGenerator_StrLn(&(*gen)._, 9, (o7_char *)"(&r->_);");
		} else {
			TextGenerator_StrLn(&(*gen)._, 5, (o7_char *)"(r);");
		}
	}
	var_ = (&(rec->vars)->_);
	while (var_ != NULL) {
		if (var_->type->_._.id == Ast_IdArray_cnst) {
			if (var_->type->_.type->_._.id == Ast_IdPointer_cnst) {
				TextGenerator_Str(&(*gen)._, retrelArray_len0, retrelArray);
				Name(gen, var_);
				TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
			} else if ((var_->type->_.type->_._.id == Ast_IdRecord_cnst) && (var_->type->_.type->_._.ext != NULL) && O7_GUARD(RecExt__s, var_->type->_.type->_._.ext)->undef) {
				TextGenerator_Str(&(*gen)._, 27, (o7_char *)"for (i = 0; i < O7_LEN(r->");
				Name(gen, var_);
				TextGenerator_StrOpen(&(*gen)._, 13, (o7_char *)"); i += 1) {");
				GlobalName(gen, &var_->type->_.type->_);
				TextGenerator_Str(&(*gen)._, retrel_len0, retrel);
				TextGenerator_Str(&(*gen)._, 5, (o7_char *)"(r->");
				Name(gen, var_);
				TextGenerator_StrLn(&(*gen)._, 7, (o7_char *)" + i);");
				TextGenerator_StrLnClose(&(*gen)._, 2, (o7_char *)"\x7D");
			}
		} else if ((var_->type->_._.id == Ast_IdRecord_cnst) && (var_->type->_._.ext != NULL)) {
			GlobalName(gen, &var_->type->_);
			TextGenerator_Str(&(*gen)._, retrel_len0, retrel);
			TextGenerator_Str(&(*gen)._, 6, (o7_char *)"(&r->");
			Name(gen, var_);
			TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
		} else if (var_->type->_._.id == Ast_IdPointer_cnst) {
			TextGenerator_Str(&(*gen)._, retNull_len0, retNull);
			TextGenerator_Str(&(*gen)._, 4, (o7_char *)"r->");
			Name(gen, var_);
			TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
		}
		var_ = var_->next;
	}
	TextGenerator_StrLnClose(&(*gen)._, 2, (o7_char *)"\x7D");
}

static void RecordRelease(struct Generator *gen, struct Ast_RRecord *rec) {
	RecordRetainRelease(gen, rec, 9, (o7_char *)"_release", 21, (o7_char *)"O7_RELEASE_ARRAY(r->", 10, (o7_char *)"O7_NULL(&");
}

static void RecordRetain(struct Generator *gen, struct Ast_RRecord *rec) {
	RecordRetainRelease(gen, rec, 8, (o7_char *)"_retain", 20, (o7_char *)"O7_RETAIN_ARRAY(r->", 11, (o7_char *)"o7_retain(");
}

static void Comment(struct Generator *gen, struct StringStore_String *com) {
	GenCommon_CommentC(&(*gen)._, &(*gen->opt)._, com);
}

static void EmptyLines(struct Generator *gen, struct Ast_Node *d) {
	if (0 < d->emptyLines) {
		TextGenerator_Ln(&(*gen)._);
	}
}

static void Type(struct Generator *gen, struct Ast_RDeclaration *decl, struct Ast_RType *typ, o7_bool typeDecl, o7_bool sameType);
static void Type_Simple(struct Generator *gen, o7_int_t str_len0, o7_char str[/*len0*/]) {
	TextGenerator_Str(&(*gen)._, str_len0, str);
	MemWriteInvert(&(*gen->memout));
}

static void Type_Record(struct Generator *gen, struct Ast_RRecord *rec) {
	struct Ast_RDeclaration *v;

	rec->_._._.module_ = gen->module_->bag;
	TextGenerator_Str(&(*gen)._, 8, (o7_char *)"struct ");
	if (CheckStructName(gen, rec)) {
		GlobalName(gen, &rec->_._._);
	}
	v = (&(rec->vars)->_);
	if ((v == NULL) && (rec->base == NULL) && !gen->opt->gnu) {
		TextGenerator_Str(&(*gen)._, 20, (o7_char *)" { char nothing; } ");
	} else {
		TextGenerator_StrOpen(&(*gen)._, 3, (o7_char *)" {");

		if (rec->base != NULL) {
			GlobalName(gen, &rec->base->_._._);
			if (gen->opt->plan9) {
				TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x3B");
			} else {
				TextGenerator_StrLn(&(*gen)._, 4, (o7_char *)" _;");
			}
		}

		while (v != NULL) {
			EmptyLines(gen, &v->_);
			Declarator(gen, v, (0 > 1), (0 > 1), (0 > 1));
			TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x3B");
			v = v->next;
		}
		TextGenerator_StrClose(&(*gen)._, 3, (o7_char *)"} ");
	}
	MemWriteInvert(&(*gen->memout));
}

static void Type_Array(struct Generator *gen, struct Ast_RDeclaration *decl, struct Ast_RArray *arr, o7_bool sameType) {
	struct Ast_RType *t;
	o7_int_t i;

	t = arr->_._._.type;
	MemWriteInvert(&(*gen->memout));
	if (arr->count != NULL) {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x5B");
		Expression(gen, arr->count);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x5D");
	} else if (gen->opt->vla) {
		i = 0;
		t = (&(arr)->_._);
		do {
			TextGenerator_Data(&(*gen)._, 9, (o7_char *)"[O7_VLA(", 0, o7_add(1, o7_mul((o7_int_t)gen->opt->vlaMark, 8)));
			Name(gen, decl);
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)"_len");
			TextGenerator_Int(&(*gen)._, i);
			TextGenerator_Data(&(*gen)._, 3, (o7_char *)")]", (o7_int_t)!gen->opt->vlaMark, o7_sub(2, (o7_int_t)!gen->opt->vlaMark));
			t = t->_.type;
			i = o7_add(i, 1);
		} while (!(t->_._.id != Ast_IdArray_cnst));
	} else {
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"[/*len0");
		i = 0;
		while (t->_._.id == Ast_IdArray_cnst) {
			i = o7_add(i, 1);
			TextGenerator_Str(&(*gen)._, 6, (o7_char *)", len");
			TextGenerator_Int(&(*gen)._, i);
			t = t->_.type;
		}
		TextGenerator_Str(&(*gen)._, 4, (o7_char *)"*/]");
	}
	Invert(gen);
	Type(gen, decl, t, (0 > 1), sameType);
}

static void Type(struct Generator *gen, struct Ast_RDeclaration *decl, struct Ast_RType *typ, o7_bool typeDecl, o7_bool sameType) {
	if (typ == NULL) {
		TextGenerator_Str(&(*gen)._, 6, (o7_char *)"void ");
		MemWriteInvert(&(*gen->memout));
	} else {
		if (!typeDecl && StringStore_IsDefined(&typ->_.name)) {
			if (sameType) {
				if ((o7_is(typ, &Ast_RPointer_tag)) && StringStore_IsDefined(&typ->_.type->_.name)) {
					TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x2A");
				}
			} else {
				if ((o7_is(typ, &Ast_RPointer_tag)) && StringStore_IsDefined(&typ->_.type->_.name)) {
					TextGenerator_Str(&(*gen)._, 8, (o7_char *)"struct ");
					GlobalName(gen, &typ->_.type->_);
					TextGenerator_Str(&(*gen)._, 3, (o7_char *)" *");
				} else if (o7_is(typ, &Ast_RRecord_tag)) {
					TextGenerator_Str(&(*gen)._, 8, (o7_char *)"struct ");
					if (CheckStructName(gen, O7_GUARD(Ast_RRecord, typ))) {
						GlobalName(gen, &typ->_);
						TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x20");
					}
				} else {
					GlobalName(gen, &typ->_);
					TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x20");
				}
				if (gen->memout != NULL) {
					MemWriteInvert(&(*gen->memout));
				}
			}
		} else if (!sameType || (o7_in(typ->_._.id, ((1u << Ast_IdPointer_cnst) | (1u << Ast_IdArray_cnst) | (1u << Ast_IdProcType_cnst))))) {
			switch (typ->_._.id) {
			case 0:
				Type_Simple(gen, 10, (o7_char *)"o7_int_t ");
				break;
			case 1:
				Type_Simple(gen, 11, (o7_char *)"o7_long_t ");
				break;
			case 7:
				Type_Simple(gen, 10, (o7_char *)"o7_set_t ");
				break;
			case 8:
				Type_Simple(gen, 12, (o7_char *)"o7_set64_t ");
				break;
			case 2:
				if ((gen->opt->std >= GeneratorC_IsoC99_cnst) && (gen->opt->_.varInit != GenOptions_VarInitUndefined_cnst)) {
					Type_Simple(gen, 6, (o7_char *)"bool ");
				} else {
					Type_Simple(gen, 9, (o7_char *)"o7_bool ");
				}
				break;
			case 3:
				Type_Simple(gen, 15, (o7_char *)"char unsigned ");
				break;
			case 4:
				Type_Simple(gen, 9, (o7_char *)"o7_char ");
				break;
			case 5:
				Type_Simple(gen, 8, (o7_char *)"double ");
				break;
			case 6:
				Type_Simple(gen, 7, (o7_char *)"float ");
				break;
			case 9:
				TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x2A");
				MemWriteInvert(&(*gen->memout));
				Invert(gen);
				Type(gen, decl, typ->_.type, (0 > 1), sameType);
				break;
			case 10:
				Type_Array(gen, decl, O7_GUARD(Ast_RArray, typ), sameType);
				break;
			case 11:
				Type_Record(gen, O7_GUARD(Ast_RRecord, typ));
				break;
			case 13:
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)"(*");
				MemWriteInvert(&(*gen->memout));
				TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
				ProcHead(gen, O7_GUARD(Ast_RProcType, typ));
				break;
			default:
				o7_case_fail(typ->_._.id);
				break;
			}
		}
		if (gen->memout != NULL) {
			MemWriteInvert(&(*gen->memout));
		}
	}
}

static void RecordTag(struct Generator *gen, struct Ast_RRecord *rec) {
	if ((gen->opt->memManager != GeneratorC_MemManagerCounter_cnst) && (rec->base == NULL)) {
		TextGenerator_Str(&(*gen)._, 9, (o7_char *)"#define ");
		GlobalName(gen, &rec->_._._);
		TextGenerator_StrLn(&(*gen)._, 17, (o7_char *)"_tag o7_base_tag");
	} else if ((gen->opt->memManager != GeneratorC_MemManagerCounter_cnst) && !rec->needTag && gen->opt->skipUnusedTag) {
		TextGenerator_Str(&(*gen)._, 9, (o7_char *)"#define ");
		GlobalName(gen, &rec->_._._);
		TextGenerator_Str(&(*gen)._, 6, (o7_char *)"_tag ");
		GlobalName(gen, &rec->base->_._._);
		TextGenerator_StrLn(&(*gen)._, 5, (o7_char *)"_tag");
	} else {
		if (!rec->_._._.mark || gen->opt->_.main_) {
			TextGenerator_Str(&(*gen)._, 17, (o7_char *)"static o7_tag_t ");
		} else if (gen->interface_) {
			TextGenerator_Str(&(*gen)._, 17, (o7_char *)"extern o7_tag_t ");
		} else {
			TextGenerator_Str(&(*gen)._, 10, (o7_char *)"o7_tag_t ");
		}
		GlobalName(gen, &rec->_._._);
		TextGenerator_StrLn(&(*gen)._, 6, (o7_char *)"_tag;");
	}
	if (!rec->_._._.mark || gen->opt->_.main_ || gen->interface_) {
		TextGenerator_Ln(&(*gen)._);
	}
}

static void TypeDecl(struct MOut *out, struct Ast_RType *typ);
static void TypeDecl_Typedef(struct Generator *gen, struct Ast_RType *typ) {
	EmptyLines(gen, &typ->_._);
	TextGenerator_Str(&(*gen)._, 9, (o7_char *)"typedef ");
	Declarator(gen, &typ->_, (0 < 1), (0 > 1), (0 < 1));
	TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x3B");
}

static void TypeDecl_LinkRecord(struct GeneratorC_Options__s *opt, struct Ast_RRecord *rec) {
	struct RecExt__s *ext = NULL;

	O7_ASSERT(rec->_._._._.ext == NULL);
	O7_NEW(&ext, RecExt__s);
	V_Init(&(*ext)._);
	StringStore_Undef(&ext->anonName);
	ext->next = NULL;
	ext->undef = (0 > 1);
	rec->_._._._.ext = (&(ext)->_);

	if (opt->records == NULL) {
		opt->records = rec;
	} else {
		O7_GUARD(RecExt__s, opt->recordLast->_._._._.ext)->next = rec;
	}
	opt->recordLast = rec;
}

static void TypeDecl(struct MOut *out, struct Ast_RType *typ) {
	TypeDecl_Typedef(&out->g[o7_ind(2, (o7_int_t)(typ->_.mark && !out->opt->_.main_))], typ);
	if ((typ->_._.id == Ast_IdRecord_cnst) || (typ->_._.id == Ast_IdPointer_cnst) && (typ->_.type->_.next == NULL)) {
		if (typ->_._.id == Ast_IdPointer_cnst) {
			typ = typ->_.type;
		}
		typ->_.mark = typ->_.mark || (O7_GUARD(Ast_RRecord, typ)->pointer != NULL) && (O7_GUARD(Ast_RRecord, typ)->pointer->_._._.mark);
		TypeDecl_LinkRecord(out->opt, O7_GUARD(Ast_RRecord, typ));
		if (typ->_.mark && !out->opt->_.main_) {
			RecordTag(&out->g[Interface_cnst], O7_GUARD(Ast_RRecord, typ));
			if (out->opt->_.varInit == GenOptions_VarInitUndefined_cnst) {
				RecordUndefHeader(&out->g[Interface_cnst], O7_GUARD(Ast_RRecord, typ), (0 < 1));
			}
			if (out->opt->memManager == GeneratorC_MemManagerCounter_cnst) {
				RecordReleaseHeader(&out->g[Interface_cnst], O7_GUARD(Ast_RRecord, typ), (0 < 1));
				if (!!( (1u << Ast_TypeAssigned_cnst) & typ->properties)) {
					RecordRetainHeader(&out->g[Interface_cnst], O7_GUARD(Ast_RRecord, typ), (0 < 1));
				}
			}
		}
		if ((!typ->_.mark || out->opt->_.main_) || (O7_GUARD(Ast_RRecord, typ)->base != NULL) || !O7_GUARD(Ast_RRecord, typ)->needTag) {
			RecordTag(&out->g[Implementation_cnst], O7_GUARD(Ast_RRecord, typ));
		}
		if (out->opt->_.varInit == GenOptions_VarInitUndefined_cnst) {
			RecordUndef(&out->g[Implementation_cnst], O7_GUARD(Ast_RRecord, typ));
		}
		if (out->opt->memManager == GeneratorC_MemManagerCounter_cnst) {
			RecordRelease(&out->g[Implementation_cnst], O7_GUARD(Ast_RRecord, typ));
			if (!!( (1u << Ast_TypeAssigned_cnst) & typ->properties)) {
				RecordRetain(&out->g[Implementation_cnst], O7_GUARD(Ast_RRecord, typ));
			}
		}
	}
}

static void Mark(struct Generator *gen, o7_bool mark) {
	if (gen->localDeep == 0) {
		if (mark && !gen->opt->_.main_) {
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)"extern ");
		} else {
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)"static ");
		}
	}
}

static void Const(struct Generator *gen, struct Ast_Const__s *const_) {
	Comment(gen, &const_->_._.comment);
	EmptyLines(gen, &const_->_._);
	TextGenerator_StrIgnoreIndent(&(*gen)._, 2, (o7_char *)"\x23");
	TextGenerator_Str(&(*gen)._, 8, (o7_char *)"define ");
	GlobalName(gen, &const_->_);
	TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x20");
	if (const_->_.mark && (const_->expr->value_ != NULL)) {
		Factor(gen, &const_->expr->value_->_);
	} else {
		Factor(gen, const_->expr);
	}
	TextGenerator_Ln(&(*gen)._);
}

static void Var(struct MOut *out, struct Ast_RDeclaration *prev, struct Ast_RDeclaration *var_, o7_bool last) {
	o7_bool same, mark;

	mark = var_->mark && !out->opt->_.main_;
	Comment(&out->g[o7_ind(2, (o7_int_t)mark)], &var_->_.comment);
	EmptyLines(&out->g[o7_ind(2, (o7_int_t)mark)], &var_->_);
	same = (prev != NULL) && (prev->mark == mark) && (prev->type == var_->type);
	if (!same) {
		if (prev != NULL) {
			TextGenerator_StrLn(&out->g[o7_ind(2, (o7_int_t)mark)]._, 2, (o7_char *)"\x3B");
		}
		Mark(&out->g[o7_ind(2, (o7_int_t)mark)], mark);
	} else {
		TextGenerator_Str(&out->g[o7_ind(2, (o7_int_t)mark)]._, 3, (o7_char *)", ");
	}
	if (mark) {
		Declarator(&out->g[Interface_cnst], var_, (0 > 1), same, (0 < 1));
		if (last) {
			TextGenerator_StrLn(&out->g[Interface_cnst]._, 2, (o7_char *)"\x3B");
		}

		if (same) {
			TextGenerator_Str(&out->g[Implementation_cnst]._, 3, (o7_char *)", ");
		} else if (prev != NULL) {
			TextGenerator_StrLn(&out->g[Implementation_cnst]._, 2, (o7_char *)"\x3B");
		}
	}

	Declarator(&out->g[Implementation_cnst], var_, (0 > 1), same, (0 < 1));

	VarInit(&out->g[Implementation_cnst], var_, (0 > 1));

	if (last) {
		TextGenerator_StrLn(&out->g[Implementation_cnst]._, 2, (o7_char *)"\x3B");
	}
}

static void ExprThenStats(struct Generator *gen, struct Ast_RWhileIf **wi) {
	CheckExpr(gen, (*wi)->_.expr);
	TextGenerator_StrOpen(&(*gen)._, 4, (o7_char *)") {");
	statements(gen, (*wi)->stats);
	*wi = (*wi)->elsif;
}

static o7_bool IsCaseElementWithRange(struct Ast_RCaseElement *elem) {
	struct Ast_RCaseLabel *r;

	r = elem->labels;
	while ((r != NULL) && (r->right == NULL)) {
		r = r->next;
	}
	return r != NULL;
}

static void ExprSameType(struct Generator *gen, struct Ast_RExpression *expr, struct Ast_RType *expectType) {
	o7_bool reref, brace;
	struct Ast_RRecord *base, *extend = NULL;

	base = NULL;
	reref = (expr->type->_._.id == Ast_IdPointer_cnst) && (expr->type->_.type != expectType->_.type) && (expr->_.id != Ast_IdPointer_cnst);
	brace = reref;
	if (!reref) {
		CheckExpr(gen, expr);
		if (expr->type->_._.id == Ast_IdRecord_cnst) {
			base = O7_GUARD(Ast_RRecord, expectType);
			extend = O7_GUARD(Ast_RRecord, expr->type);
		}
	} else if (gen->opt->plan9) {
		CheckExpr(gen, expr);
		brace = (0 > 1);
	} else {
		base = O7_GUARD(Ast_RRecord, expectType->_.type);
		extend = O7_GUARD(Ast_RRecord, expr->type->_.type)->base;
		TextGenerator_Str(&(*gen)._, 4, (o7_char *)"(&(");
		Expression(gen, expr);
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)")->_");
	}
	if ((base != NULL) && (extend != base)) {
		if (gen->opt->plan9) {
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x2E");
			GlobalName(gen, &expectType->_);
		} else {
			while (extend != base) {
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)"._");
				extend = extend->base;
			}
		}
	}
	if (brace) {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void ExprForSize(struct Generator *gen, struct Ast_RExpression *e) {
	gen->insideSizeOf = (0 < 1);
	Expression(gen, e);
	gen->insideSizeOf = (0 > 1);
}

static void Assign(struct Generator *gen, struct Ast_Assign__s *st);
static void Assign_Equal(struct Generator *gen, struct Ast_Assign__s *st);
static void Assign_Equal_AssertArraySize(struct Generator *gen, struct Ast_Designator__s *des, struct Ast_RExpression *e) {
	if (gen->opt->_.checkIndex && ((O7_GUARD(Ast_RArray, des->_._.type)->count == NULL) || (O7_GUARD(Ast_RArray, e->type)->count == NULL))) {
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"assert(");
		ArrayLen(gen, &des->_._);
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)" >= ");
		ArrayLen(gen, e);
		TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
	}
}

static void Assign_Equal(struct Generator *gen, struct Ast_Assign__s *st) {
	o7_bool retain, toByte;

	toByte = (st->designator->_._.type->_._.id == Ast_IdByte_cnst) && (o7_in(st->_.expr->type->_._.id, ((1u << Ast_IdInteger_cnst) | (1u << Ast_IdLongInt_cnst)))) && gen->opt->_.checkArith && (st->_.expr->value_ == NULL);
	retain = (st->designator->_._.type->_._.id == Ast_IdPointer_cnst) && (gen->opt->memManager == GeneratorC_MemManagerCounter_cnst);
	if (retain && (st->_.expr->_.id == Ast_IdPointer_cnst)) {
		TextGenerator_Str(&(*gen)._, 10, (o7_char *)"O7_NULL(&");
		Designator(gen, st->designator);
	} else {
		if (retain) {
			TextGenerator_Str(&(*gen)._, 12, (o7_char *)"O7_ASSIGN(&");
			Designator(gen, st->designator);
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
		} else if ((st->designator->_._.type->_._.id == Ast_IdArray_cnst)) {
			Assign_Equal_AssertArraySize(gen, st->designator, st->_.expr);
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)"memcpy(");
			Designator(gen, st->designator);
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
			gen->opt->expectArray = (0 < 1);
		} else if (toByte) {
			Designator(gen, st->designator);
			if (st->_.expr->type->_._.id == Ast_IdInteger_cnst) {
				TextGenerator_Str(&(*gen)._, 12, (o7_char *)" = o7_byte(");
			} else {
				TextGenerator_Str(&(*gen)._, 13, (o7_char *)" = o7_lbyte(");
			}
		} else {
			Designator(gen, st->designator);
			TextGenerator_Str(&(*gen)._, 4, (o7_char *)" = ");
		}
		ExprSameType(gen, st->_.expr, st->designator->_._.type);
		gen->opt->expectArray = (0 > 1);
		if (st->designator->_._.type->_._.id != Ast_IdArray_cnst) {
		} else if ((O7_GUARD(Ast_RArray, st->_.expr->type)->count != NULL) && !Ast_IsFormalParam(st->_.expr)) {
			if ((o7_is(st->_.expr, &Ast_ExprString__s_tag)) && O7_GUARD(Ast_ExprString__s, st->_.expr)->asChar) {
				TextGenerator_Str(&(*gen)._, 4, (o7_char *)", 2");
			} else {
				TextGenerator_Str(&(*gen)._, 10, (o7_char *)", sizeof(");
				ExprForSize(gen, st->_.expr);
				TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
			}
		} else if (gen->opt->e2k) {
			TextGenerator_Str(&(*gen)._, 15, (o7_char *)", O7_E2K_SIZE(");
			GlobalName(gen, O7_GUARD(Ast_Designator__s, st->_.expr)->decl);
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		} else {
			TextGenerator_Str(&(*gen)._, 4, (o7_char *)", (");
			ArrayLen(gen, st->_.expr);
			TextGenerator_Str(&(*gen)._, 12, (o7_char *)") * sizeof(");
			ExprForSize(gen, st->_.expr);
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)"[0])");
		}
	}
	switch (o7_add(o7_add((o7_int_t)retain, (o7_int_t)toByte), (o7_int_t)(st->designator->_._.type->_._.id == Ast_IdArray_cnst))) {
	case 0:
		break;
	case 1:
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		break;
	case 2:
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)"))");
		break;
	default:
		o7_case_fail(o7_add(o7_add((o7_int_t)retain, (o7_int_t)toByte), (o7_int_t)(st->designator->_._.type->_._.id == Ast_IdArray_cnst)));
		break;
	}
	if ((gen->opt->memManager == GeneratorC_MemManagerCounter_cnst) && (st->designator->_._.type->_._.id == Ast_IdRecord_cnst) && (!IsAnonStruct(O7_GUARD(Ast_RRecord, st->designator->_._.type)))) {
		TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x3B");
		GlobalName(gen, &st->designator->_._.type->_);
		TextGenerator_Str(&(*gen)._, 10, (o7_char *)"_retain(&");
		Designator(gen, st->designator);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void Assign(struct Generator *gen, struct Ast_Assign__s *st) {
	Assign_Equal(gen, st);
}

static void Statement(struct Generator *gen, struct Ast_RStatement *st);
static void Statement_WhileIf(struct Generator *gen, struct Ast_RWhileIf *wi);
static void Statement_WhileIf_Elsif(struct Generator *gen, struct Ast_RWhileIf **wi) {
	while ((*wi != NULL) && ((*wi)->_.expr != NULL)) {
		TextGenerator_StrClose(&(*gen)._, 12, (o7_char *)"} else if (");
		ExprThenStats(gen, wi);
	}
}

static void Statement_WhileIf(struct Generator *gen, struct Ast_RWhileIf *wi) {
	if (o7_is(wi, &Ast_If__s_tag)) {
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)"if (");
		ExprThenStats(gen, &wi);
		Statement_WhileIf_Elsif(gen, &wi);
		if (wi != NULL) {
			TextGenerator_IndentClose(&(*gen)._);
			TextGenerator_StrOpen(&(*gen)._, 9, (o7_char *)"} else {");
			statements(gen, wi->stats);
		}
		TextGenerator_StrLnClose(&(*gen)._, 2, (o7_char *)"\x7D");
	} else if (wi->elsif == NULL) {
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"while (");
		ExprThenStats(gen, &wi);
		TextGenerator_StrLnClose(&(*gen)._, 2, (o7_char *)"\x7D");
	} else {
		TextGenerator_Str(&(*gen)._, 15, (o7_char *)"while (1) if (");
		ExprThenStats(gen, &wi);
		Statement_WhileIf_Elsif(gen, &wi);
		TextGenerator_StrLnClose(&(*gen)._, 14, (o7_char *)"} else break;");
	}
}

static void Statement_Repeat(struct Generator *gen, struct Ast_Repeat__s *st) {
	struct Ast_RExpression *e;

	TextGenerator_StrOpen(&(*gen)._, 5, (o7_char *)"do {");
	statements(gen, st->stats);
	if (st->_.expr->_.id == Ast_IdNegate_cnst) {
		TextGenerator_StrClose(&(*gen)._, 10, (o7_char *)"} while (");
		e = O7_GUARD(Ast_ExprNegate__s, st->_.expr)->expr;
		while (e->_.id == Ast_IdBraces_cnst) {
			e = O7_GUARD(Ast_ExprBraces__s, e)->expr;
		}
		Expression(gen, e);
		TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
	} else {
		TextGenerator_StrClose(&(*gen)._, 12, (o7_char *)"} while (!(");
		CheckExpr(gen, st->_.expr);
		TextGenerator_StrLn(&(*gen)._, 4, (o7_char *)"));");
	}
}

static void Statement_For(struct Generator *gen, struct Ast_For__s *st);
static o7_bool Statement_For_IsEndMinus1(struct Ast_RExprSum *sum) {
	return (sum->next != NULL) && (sum->next->next == NULL) && (sum->next->add == Scanner_Minus_cnst) && (sum->next->term->value_ != NULL) && (O7_GUARD(Ast_RExprInteger, sum->next->term->value_)->int_ == 1);
}

static void Statement_For(struct Generator *gen, struct Ast_For__s *st) {
	TextGenerator_Str(&(*gen)._, 6, (o7_char *)"for (");
	GlobalName(gen, &st->var_->_);
	TextGenerator_Str(&(*gen)._, 4, (o7_char *)" = ");
	Expression(gen, st->_.expr);
	TextGenerator_Str(&(*gen)._, 3, (o7_char *)"; ");
	GlobalName(gen, &st->var_->_);
	if (st->by > 0) {
		if ((o7_is(st->to, &Ast_RExprSum_tag)) && Statement_For_IsEndMinus1(O7_GUARD(Ast_RExprSum, st->to))) {
			TextGenerator_Str(&(*gen)._, 4, (o7_char *)" < ");
			Expression(gen, O7_GUARD(Ast_RExprSum, st->to)->term);
		} else {
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)" <= ");
			Expression(gen, st->to);
		}
		if (st->by == 1) {
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)"; ++");
			GlobalName(gen, &st->var_->_);
		} else {
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)"; ");
			GlobalName(gen, &st->var_->_);
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)" += ");
			TextGenerator_Int(&(*gen)._, st->by);
		}
	} else {
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)" >= ");
		Expression(gen, st->to);
		if (st->by ==  - 1) {
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)"; --");
			GlobalName(gen, &st->var_->_);
		} else {
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)"; ");
			GlobalName(gen, &st->var_->_);
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)" -= ");
			TextGenerator_Int(&(*gen)._, o7_sub(0, st->by));
		}
	}
	TextGenerator_StrOpen(&(*gen)._, 4, (o7_char *)") {");
	statements(gen, st->stats);
	TextGenerator_StrLnClose(&(*gen)._, 2, (o7_char *)"\x7D");
}

static void Statement_Case(struct Generator *gen, struct Ast_Case__s *st);
static void Statement_Case_CaseElement(struct Generator *gen, struct Ast_RCaseElement *elem) {
	struct Ast_RCaseLabel *r;

	if (gen->opt->gnu || !IsCaseElementWithRange(elem)) {
		r = elem->labels;
		while (r != NULL) {
			TextGenerator_Str(&(*gen)._, 6, (o7_char *)"case ");
			TextGenerator_Int(&(*gen)._, r->value_);
			if (r->right != NULL) {
				O7_ASSERT(gen->opt->gnu);
				TextGenerator_Str(&(*gen)._, 6, (o7_char *)" ... ");
				TextGenerator_Int(&(*gen)._, r->right->value_);
			}
			TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x3A");

			r = r->next;
		}
		TextGenerator_IndentOpen(&(*gen)._);
		statements(gen, elem->stats);
		TextGenerator_StrLn(&(*gen)._, 7, (o7_char *)"break;");
		TextGenerator_IndentClose(&(*gen)._);
	}
}

static void Statement_Case_CaseElementAsIf(struct Generator *gen, struct Ast_RCaseElement *elem, struct Ast_RExpression *caseExpr);
static void Statement_Case_CaseElementAsIf_CaseRange(struct Generator *gen, struct Ast_RCaseLabel *r, struct Ast_RExpression *caseExpr) {
	if (r->right == NULL) {
		if (caseExpr == NULL) {
			TextGenerator_Str(&(*gen)._, 18, (o7_char *)"(o7_case_expr == ");
		} else {
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x28");
			Expression(gen, caseExpr);
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)" == ");
		}
		TextGenerator_Int(&(*gen)._, r->value_);
	} else {
		O7_ASSERT(r->value_ <= r->right->value_);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x28");
		TextGenerator_Int(&(*gen)._, r->value_);
		if (caseExpr == NULL) {
			TextGenerator_Str(&(*gen)._, 37, (o7_char *)" <= o7_case_expr && o7_case_expr <= ");
		} else {
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)" <= ");
			Expression(gen, caseExpr);
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)" && ");
			Expression(gen, caseExpr);
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)" <= ");
		}
		TextGenerator_Int(&(*gen)._, r->right->value_);
	}
	TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
}

static void Statement_Case_CaseElementAsIf(struct Generator *gen, struct Ast_RCaseElement *elem, struct Ast_RExpression *caseExpr) {
	struct Ast_RCaseLabel *r;

	TextGenerator_Str(&(*gen)._, 5, (o7_char *)"if (");
	r = elem->labels;
	O7_ASSERT(r != NULL);
	Statement_Case_CaseElementAsIf_CaseRange(gen, r, caseExpr);
	while (r->next != NULL) {
		r = r->next;
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)" || ");
		Statement_Case_CaseElementAsIf_CaseRange(gen, r, caseExpr);
	}
	TextGenerator_StrOpen(&(*gen)._, 4, (o7_char *)") {");
	statements(gen, elem->stats);
	TextGenerator_StrClose(&(*gen)._, 2, (o7_char *)"\x7D");
}

static void Statement_Case(struct Generator *gen, struct Ast_Case__s *st) {
	struct Ast_RCaseElement *elem, *elemWithRange;
	struct Ast_RExpression *caseExpr;

	if (gen->opt->gnu) {
		elemWithRange = NULL;
	} else {
		elemWithRange = st->elements;
		while ((elemWithRange != NULL) && !IsCaseElementWithRange(elemWithRange)) {
			elemWithRange = elemWithRange->next;
		}
	}
	if ((elemWithRange != NULL) && (st->_.expr->value_ == NULL) && (!(o7_is(st->_.expr, &Ast_Designator__s_tag)) || (O7_GUARD(Ast_Designator__s, st->_.expr)->sel != NULL))) {
		caseExpr = NULL;
		TextGenerator_Str(&(*gen)._, 27, (o7_char *)"{ o7_int_t o7_case_expr = ");
		Expression(gen, st->_.expr);
		TextGenerator_StrOpen(&(*gen)._, 2, (o7_char *)"\x3B");
		TextGenerator_StrLn(&(*gen)._, 24, (o7_char *)"switch (o7_case_expr) {");
	} else {
		caseExpr = st->_.expr;
		TextGenerator_Str(&(*gen)._, 9, (o7_char *)"switch (");
		Expression(gen, caseExpr);
		TextGenerator_StrLn(&(*gen)._, 4, (o7_char *)") {");
	}
	elem = st->elements;
	do {
		Statement_Case_CaseElement(gen, elem);
		elem = elem->next;
	} while (!(elem == NULL));
	TextGenerator_StrOpen(&(*gen)._, 9, (o7_char *)"default:");
	if (elemWithRange != NULL) {
		elem = elemWithRange;
		Statement_Case_CaseElementAsIf(gen, elem, caseExpr);
		elem = elem->next;
		while (elem != NULL) {
			if (IsCaseElementWithRange(elem)) {
				TextGenerator_Str(&(*gen)._, 7, (o7_char *)" else ");
				Statement_Case_CaseElementAsIf(gen, elem, caseExpr);
			}
			elem = elem->next;
		}
		if (!gen->opt->_.caseAbort) {
		} else if (caseExpr == NULL) {
			TextGenerator_StrLn(&(*gen)._, 34, (o7_char *)" else o7_case_fail(o7_case_expr);");
		} else {
			TextGenerator_Str(&(*gen)._, 20, (o7_char *)" else o7_case_fail(");
			Expression(gen, caseExpr);
			TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
		}
	} else if (!gen->opt->_.caseAbort) {
	} else if (caseExpr == NULL) {
		TextGenerator_StrLn(&(*gen)._, 28, (o7_char *)"o7_case_fail(o7_case_expr);");
	} else {
		TextGenerator_Str(&(*gen)._, 14, (o7_char *)"o7_case_fail(");
		Expression(gen, caseExpr);
		TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
	}
	TextGenerator_StrLn(&(*gen)._, 7, (o7_char *)"break;");
	TextGenerator_StrLnClose(&(*gen)._, 2, (o7_char *)"\x7D");
	if (caseExpr == NULL) {
		TextGenerator_StrLnClose(&(*gen)._, 2, (o7_char *)"\x7D");
	}
}

static void Statement(struct Generator *gen, struct Ast_RStatement *st) {
	Comment(gen, &st->_.comment);
	EmptyLines(gen, &st->_);
	if (o7_is(st, &Ast_Assign__s_tag)) {
		Assign(gen, O7_GUARD(Ast_Assign__s, st));
		TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x3B");
	} else if (o7_is(st, &Ast_Call__s_tag)) {
		gen->expressionSemicolon = (0 < 1);
		Expression(gen, st->expr);
		if (gen->expressionSemicolon) {
			TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x3B");
		} else {
			TextGenerator_Ln(&(*gen)._);
		}
	} else if (o7_is(st, &Ast_RWhileIf_tag)) {
		Statement_WhileIf(gen, O7_GUARD(Ast_RWhileIf, st));
	} else if (o7_is(st, &Ast_Repeat__s_tag)) {
		Statement_Repeat(gen, O7_GUARD(Ast_Repeat__s, st));
	} else if (o7_is(st, &Ast_For__s_tag)) {
		Statement_For(gen, O7_GUARD(Ast_For__s, st));
	} else {
		O7_ASSERT(o7_is(st, &Ast_Case__s_tag));
		Statement_Case(gen, O7_GUARD(Ast_Case__s, st));
	}
}

static void Statements(struct Generator *gen, struct Ast_RStatement *stats) {
	while (stats != NULL) {
		Statement(gen, stats);
		stats = stats->next;
	}
}

static void ProcDecl(struct Generator *gen, struct Ast_RProcedure *proc) {
	Mark(gen, proc->_._._.mark);
	Declarator(gen, &proc->_._._, (0 > 1), (0 > 1), (0 < 1));
	TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x3B");
}

static void ReleaseVars(struct Generator *gen, struct Ast_RDeclaration *var_) {
	if (gen->opt->memManager == GeneratorC_MemManagerCounter_cnst) {
		while ((var_ != NULL) && (var_->_.id == Ast_IdVar_cnst)) {
			if (var_->type->_._.id == Ast_IdArray_cnst) {
				if (var_->type->_.type->_._.id == Ast_IdPointer_cnst) {
					TextGenerator_Str(&(*gen)._, 18, (o7_char *)"O7_RELEASE_ARRAY(");
					GlobalName(gen, var_);
					TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
				} else if ((var_->type->_.type->_._.id == Ast_IdRecord_cnst) && (var_->type->_.type->_._.ext != NULL) && O7_GUARD(RecExt__s, var_->type->_.type->_._.ext)->undef) {
					TextGenerator_Str(&(*gen)._, 41, (o7_char *)"{int o7_i; for (o7_i = 0; o7_i < O7_LEN(");
					GlobalName(gen, var_);
					TextGenerator_StrOpen(&(*gen)._, 16, (o7_char *)"); o7_i += 1) {");
					GlobalName(gen, &var_->type->_.type->_);
					TextGenerator_Str(&(*gen)._, 10, (o7_char *)"_release(");
					GlobalName(gen, var_);
					TextGenerator_StrLn(&(*gen)._, 10, (o7_char *)" + o7_i);");
					TextGenerator_StrLnClose(&(*gen)._, 3, (o7_char *)"}}");
				}
			} else if (var_->type->_._.id == Ast_IdPointer_cnst) {
				TextGenerator_Str(&(*gen)._, 10, (o7_char *)"O7_NULL(&");
				GlobalName(gen, var_);
				TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
			} else if ((var_->type->_._.id == Ast_IdRecord_cnst) && (var_->type->_._.ext != NULL)) {
				GlobalName(gen, &var_->type->_);
				TextGenerator_Str(&(*gen)._, 11, (o7_char *)"_release(&");
				GlobalName(gen, var_);
				TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
			}

			var_ = var_->next;
		}
	}
}

static void Procedure(struct MOut *out, struct Ast_RProcedure *proc);
static void Procedure_Implement(struct MOut *out, struct Generator *gen, struct Ast_RProcedure *proc);
static void Procedure_Implement_CloseConsts(struct Generator *gen, struct Ast_RDeclaration *consts) {
	while ((consts != NULL) && (o7_is(consts, &Ast_Const__s_tag))) {
		TextGenerator_StrIgnoreIndent(&(*gen)._, 2, (o7_char *)"\x23");
		TextGenerator_Str(&(*gen)._, 7, (o7_char *)"undef ");
		Name(gen, consts);
		TextGenerator_Ln(&(*gen)._);
		consts = consts->next;
	}
}

static struct Ast_RDeclaration *Procedure_Implement_SearchRetain(struct Generator *gen, struct Ast_RDeclaration *fp) {
	while ((fp != NULL) && ((fp->type->_._.id != Ast_IdPointer_cnst) || (!!( (1u << Ast_ParamOut_cnst) & O7_GUARD(Ast_RFormalParam, fp)->access)))) {
		fp = fp->next;
	}
	return fp;
}

static void Procedure_Implement_RetainParams(struct Generator *gen, struct Ast_RDeclaration *fp) {
	if (fp != NULL) {
		TextGenerator_Str(&(*gen)._, 11, (o7_char *)"o7_retain(");
		Name(gen, fp);
		fp = fp->next;
		while (fp != NULL) {
			if ((fp->type->_._.id == Ast_IdPointer_cnst) && !(!!( (1u << Ast_ParamOut_cnst) & O7_GUARD(Ast_RFormalParam, fp)->access))) {
				TextGenerator_Str(&(*gen)._, 14, (o7_char *)"); o7_retain(");
				Name(gen, fp);
			}
			fp = fp->next;
		}
		TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
	}
}

static void Procedure_Implement_ReleaseParams(struct Generator *gen, struct Ast_RDeclaration *fp) {
	if (fp != NULL) {
		TextGenerator_Str(&(*gen)._, 12, (o7_char *)"o7_release(");
		Name(gen, fp);
		fp = fp->next;
		while (fp != NULL) {
			if ((fp->type->_._.id == Ast_IdPointer_cnst) && !(!!( (1u << Ast_ParamOut_cnst) & O7_GUARD(Ast_RFormalParam, fp)->access))) {
				TextGenerator_Str(&(*gen)._, 15, (o7_char *)"); o7_release(");
				Name(gen, fp);
			}
			fp = fp->next;
		}
		TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
	}
}

static void Procedure_Implement(struct MOut *out, struct Generator *gen, struct Ast_RProcedure *proc) {
	struct Ast_RDeclaration *retainParams;

	Comment(gen, &proc->_._._._.comment);
	Mark(gen, proc->_._._.mark);
	Declarator(gen, &proc->_._._, (0 > 1), (0 > 1), (0 < 1));
	TextGenerator_StrOpen(&(*gen)._, 3, (o7_char *)" {");

	gen->localDeep = o7_add(gen->localDeep, 1);

	gen->fixedLen = gen->_.len;

	if (gen->opt->memManager != GeneratorC_MemManagerCounter_cnst) {
		retainParams = NULL;
	} else {
		retainParams = Procedure_Implement_SearchRetain(gen, &proc->_.header->params->_._);
		if (proc->_.return_ != NULL) {
			Qualifier(gen, proc->_.return_->type);
			if (proc->_.return_->type->_._.id == Ast_IdPointer_cnst) {
				TextGenerator_StrLn(&(*gen)._, 19, (o7_char *)" o7_return = NULL;");
			} else {
				TextGenerator_StrLn(&(*gen)._, 12, (o7_char *)" o7_return;");
			}
		}
	}
	declarations(out, &proc->_._);

	Procedure_Implement_RetainParams(gen, retainParams);

	Statements(gen, proc->_._.stats);

	if (proc->_.return_ == NULL) {
		ReleaseVars(gen, &proc->_._.vars->_);
		Procedure_Implement_ReleaseParams(gen, retainParams);
	} else if (gen->opt->memManager == GeneratorC_MemManagerCounter_cnst) {
		if (proc->_.return_->type->_._.id == Ast_IdPointer_cnst) {
			TextGenerator_Str(&(*gen)._, 23, (o7_char *)"O7_ASSIGN(&o7_return, ");
			Expression(gen, proc->_.return_);
			TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
		} else {
			TextGenerator_Str(&(*gen)._, 13, (o7_char *)"o7_return = ");
			CheckExpr(gen, proc->_.return_);
			TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x3B");
		}
		ReleaseVars(gen, &proc->_._.vars->_);
		Procedure_Implement_ReleaseParams(gen, retainParams);
		if (proc->_.return_->type->_._.id == Ast_IdPointer_cnst) {
			TextGenerator_StrLn(&(*gen)._, 22, (o7_char *)"o7_unhold(o7_return);");
		}
		TextGenerator_StrLn(&(*gen)._, 18, (o7_char *)"return o7_return;");
	} else {
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"return ");
		ExprSameType(gen, proc->_.return_, proc->_.header->_._._.type);
		TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x3B");
	}

	gen->localDeep = o7_sub(gen->localDeep, 1);
	Procedure_Implement_CloseConsts(gen, proc->_._.start);
	TextGenerator_StrLnClose(&(*gen)._, 2, (o7_char *)"\x7D");
	TextGenerator_Ln(&(*gen)._);
}

static void Procedure_LocalProcs(struct MOut *out, struct Ast_RProcedure *proc) {
	struct Ast_RDeclaration *p, *t;

	t = (&(proc->_._.types)->_);
	while ((t != NULL) && (o7_is(t, &Ast_RType_tag))) {
		TypeDecl(out, O7_GUARD(Ast_RType, t));
		t = t->next;
	}
	p = (&(proc->_._.procedures)->_._._);
	if ((p != NULL) && !out->opt->procLocal) {
		if (!proc->_._._.mark) {
			ProcDecl(&out->g[Implementation_cnst], proc);
		}
		do {
			Procedure(out, O7_GUARD(Ast_RProcedure, p));
			p = p->next;
		} while (!(p == NULL));
	}
}

static void Procedure(struct MOut *out, struct Ast_RProcedure *proc) {
	Procedure_LocalProcs(out, proc);
	if (proc->_._._.mark && !out->opt->_.main_) {
		ProcDecl(&out->g[Interface_cnst], proc);
	}
	Procedure_Implement(out, &out->g[Implementation_cnst], proc);
}

static void LnIfWrote(struct MOut *out);
static void LnIfWrote_Write(struct Generator *gen) {
	if (gen->fixedLen != gen->_.len) {
		TextGenerator_Ln(&(*gen)._);
		gen->fixedLen = gen->_.len;
	}
}

static void LnIfWrote(struct MOut *out) {
	if (!out->opt->_.main_) {
		LnIfWrote_Write(&out->g[Interface_cnst]);
	}
	LnIfWrote_Write(&out->g[Implementation_cnst]);
}

static void VarsInit(struct Generator *gen, struct Ast_RDeclaration *d) {
	o7_int_t arrDeep = 0, arrTypeId = 0;

	while ((d != NULL) && (o7_is(d, &Ast_RVar_tag))) {
		if (o7_in(d->type->_._.id, ((1u << Ast_IdArray_cnst) | (1u << Ast_IdRecord_cnst)))) {
			if ((gen->opt->_.varInit == GenOptions_VarInitUndefined_cnst) && (d->type->_._.id == Ast_IdRecord_cnst) && StringStore_IsDefined(&d->type->_.name) && Ast_IsGlobal(&d->type->_)) {
				RecordUndefCall(gen, d);
			} else if ((gen->opt->_.varInit == GenOptions_VarInitZero_cnst) || (d->type->_._.id == Ast_IdRecord_cnst) || (d->type->_._.id == Ast_IdArray_cnst) && !IsArrayTypeSimpleUndef(d->type, &arrTypeId, &arrDeep)) {
				TextGenerator_Str(&(*gen)._, 9, (o7_char *)"memset(&");
				Name(gen, d);
				TextGenerator_Str(&(*gen)._, 13, (o7_char *)", 0, sizeof(");
				Name(gen, d);
				TextGenerator_StrLn(&(*gen)._, 4, (o7_char *)"));");
			} else {
				O7_ASSERT(gen->opt->_.varInit == GenOptions_VarInitUndefined_cnst);
				ArraySimpleUndef(gen, arrTypeId, d, (0 > 1));
			}
		}
		d = d->next;
	}
}

static void Declarations(struct MOut *out, struct Ast_RDeclarations *ds) {
	struct Ast_RDeclaration *d, *prev;
	o7_bool inModule;

	d = ds->start;
	inModule = o7_is(ds, &Ast_RModule_tag);
	O7_ASSERT((d == NULL) || !(o7_is(d, &Ast_RModule_tag)));
	while ((d != NULL) && (o7_is(d, &Ast_Import__s_tag))) {
		Import(&out->g[o7_ind(2, (o7_int_t)!out->opt->_.main_)], d);
		d = d->next;
	}
	LnIfWrote(out);

	while ((d != NULL) && (o7_is(d, &Ast_Const__s_tag))) {
		Const(&out->g[o7_ind(2, (o7_int_t)(d->mark && !out->opt->_.main_))], O7_GUARD(Ast_Const__s, d));
		d = d->next;
	}
	LnIfWrote(out);

	if (inModule) {
		while ((d != NULL) && (o7_is(d, &Ast_RType_tag))) {
			TypeDecl(out, O7_GUARD(Ast_RType, d));
			d = d->next;
		}
		LnIfWrote(out);

		while ((d != NULL) && (o7_is(d, &Ast_RVar_tag))) {
			Var(out, NULL, d, (0 < 1));
			d = d->next;
		}
	} else {
		d = (&(ds->vars)->_);

		prev = NULL;
		while ((d != NULL) && (o7_is(d, &Ast_RVar_tag))) {
			Var(out, prev, d, (d->next == NULL) || !(o7_is(d->next, &Ast_RVar_tag)));
			prev = d;
			d = d->next;
		}
		if (out->opt->_.varInit != GenOptions_VarInitNo_cnst) {
			VarsInit(&out->g[Implementation_cnst], &ds->vars->_);
		}

		d = (&(ds->procedures)->_._._);
	}
	LnIfWrote(out);

	if (inModule || out->opt->procLocal) {
		while (d != NULL) {
			Procedure(out, O7_GUARD(Ast_RProcedure, d));
			d = d->next;
		}
	}
}

extern struct GeneratorC_Options__s *GeneratorC_DefaultOptions(void) {
	struct GeneratorC_Options__s *o = NULL;

	O7_NEW(&o, GeneratorC_Options__s);
	if (o != NULL) {
		V_Init(&(*o)._._);

		GenOptions_Default(&(*o)._);

		o->std = GeneratorC_IsoC90_cnst;
		o->gnu = (0 > 1);
		o->plan9 = (0 > 1);
		o->e2k = (0 > 1);

		o->procLocal = (0 > 1);
		o->vla = (0 > 1) && (GeneratorC_IsoC99_cnst <= o->std);
		o->vlaMark = (0 < 1);
		o->checkNil = (0 < 1);
		o->skipUnusedTag = (0 < 1);
		o->memManager = GeneratorC_MemManagerNoFree_cnst;

		o->expectArray = (0 > 1);
		o->castToBase = (0 > 1);

		o->memOuts = NULL;
	}
	return o;
}

static void MarkExpression(struct Ast_RExpression *e) {
	if (e != NULL) {
		if (e->_.id == Ast_IdRelation_cnst) {
			MarkExpression(O7_GUARD(Ast_ExprRelation__s, e)->exprs[0]);
			MarkExpression(O7_GUARD(Ast_ExprRelation__s, e)->exprs[1]);
		} else if (e->_.id == Ast_IdTerm_cnst) {
			MarkExpression(&O7_GUARD(Ast_ExprTerm__s, e)->factor->_);
			MarkExpression(O7_GUARD(Ast_ExprTerm__s, e)->expr);
		} else if (e->_.id == Ast_IdSum_cnst) {
			MarkExpression(O7_GUARD(Ast_RExprSum, e)->term);
			MarkExpression(&O7_GUARD(Ast_RExprSum, e)->next->_);
		} else if ((e->_.id == Ast_IdDesignator_cnst) && !O7_GUARD(Ast_Designator__s, e)->decl->mark) {
			O7_GUARD(Ast_Designator__s, e)->decl->mark = (0 < 1);
			MarkExpression(O7_GUARD(Ast_Const__s, O7_GUARD(Ast_Designator__s, e)->decl)->expr);
		}
	}
}

static void MarkType(struct Ast_RType *t) {
	struct Ast_RDeclaration *d;

	while ((t != NULL) && !t->_.mark) {
		t->_.mark = (0 < 1);
		if (t->_._.id == Ast_IdArray_cnst) {
			MarkExpression(O7_GUARD(Ast_RArray, t)->count);
			t = t->_.type;
		} else if (o7_in(t->_._.id, ((1u << Ast_IdRecord_cnst) | (1u << Ast_IdPointer_cnst)))) {
			if (t->_._.id == Ast_IdPointer_cnst) {
				t = t->_.type;
				t->_.mark = (0 < 1);
				O7_ASSERT(t->_.module_ != NULL);
			}
			d = (&(O7_GUARD(Ast_RRecord, t)->vars)->_);
			while (d != NULL) {
				MarkType(d->type);
				d = d->next;
			}
			t = (&(O7_GUARD(Ast_RRecord, t)->base)->_._);
		} else {
			t = NULL;
		}
	}
}

static void MarkUsedInMarked(struct Ast_RModule *m);
static void MarkUsedInMarked_Consts(struct Ast_RDeclaration *c) {
	while ((c != NULL) && (o7_is(c, &Ast_Const__s_tag))) {
		if (c->mark) {
			MarkExpression(O7_GUARD(Ast_Const__s, c)->expr);
		}
		c = c->next;
	}
}

static void MarkUsedInMarked_Types(struct Ast_RDeclaration *t) {
	while ((t != NULL) && (o7_is(t, &Ast_RType_tag))) {
		if (t->mark) {
			t->mark = (0 > 1);
			MarkType(O7_GUARD(Ast_RType, t));
		}
		t = t->next;
	}
}

static void MarkUsedInMarked_Procs(struct Ast_RDeclaration *p) {
	struct Ast_RDeclaration *fp;

	while ((p != NULL) && (o7_is(p, &Ast_RProcedure_tag))) {
		if (p->mark) {
			fp = (&(O7_GUARD(Ast_RProcedure, p)->_.header->params)->_._);
			while (fp != NULL) {
				MarkType(fp->type);
				fp = fp->next;
			}
		}
		p = p->next;
	}
}

static void MarkUsedInMarked(struct Ast_RModule *m) {
	struct Ast_RDeclaration *imp;

	imp = (&(m->import_)->_);
	while ((imp != NULL) && (o7_is(imp, &Ast_Import__s_tag))) {
		MarkUsedInMarked(imp->module_->m);
		imp = imp->next;
	}
	MarkUsedInMarked_Consts(&m->_.consts->_);
	MarkUsedInMarked_Types(&m->_.types->_);
	MarkUsedInMarked_Procs(&m->_.procedures->_._._);
}

static void ImportInitDone(struct Generator *gen, struct Ast_RDeclaration *imp, o7_int_t initDone_len0, o7_char initDone[/*len0*/]) {
	if (imp != NULL) {
		O7_ASSERT(o7_is(imp, &Ast_Import__s_tag));

		do {
			Name(gen, &imp->module_->m->_._);
			TextGenerator_StrLn(&(*gen)._, initDone_len0, initDone);

			imp = imp->next;
		} while (!((imp == NULL) || !(o7_is(imp, &Ast_Import__s_tag))));
		TextGenerator_Ln(&(*gen)._);
	}
}

static void ImportInit(struct Generator *gen, struct Ast_RDeclaration *imp) {
	ImportInitDone(gen, imp, 9, (o7_char *)"_init();");
}

static void ImportDone(struct Generator *gen, struct Ast_RDeclaration *imp) {
	ImportInitDone(gen, imp, 9, (o7_char *)"_done();");
}

static void TagsInit(struct Generator *gen) {
	struct Ast_RRecord *r;

	r = NULL;
	while (gen->opt->records != NULL) {
		r = gen->opt->records;
		gen->opt->records = O7_GUARD(RecExt__s, r->_._._._.ext)->next;
		O7_GUARD(RecExt__s, r->_._._._.ext)->next = NULL;

		if ((gen->opt->memManager == GeneratorC_MemManagerCounter_cnst) || (r->base != NULL) && (r->needTag || !gen->opt->skipUnusedTag)) {
			TextGenerator_Str(&(*gen)._, 13, (o7_char *)"O7_TAG_INIT(");
			GlobalName(gen, &r->_._._);
			if (r->base != NULL) {
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
				GlobalName(gen, &r->base->_._._);
				TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
			} else {
				TextGenerator_StrLn(&(*gen)._, 12, (o7_char *)", o7_base);");
			}
		}
	}
	if (r != NULL) {
		TextGenerator_Ln(&(*gen)._);
	}
}

static void Generate_Init(struct Generator *gen, struct VDataStream_Out *out, struct Ast_RModule *module_, struct GeneratorC_Options__s *opt, o7_bool interface_) {
	TextGenerator_Init(&(*gen)._, out);
	gen->module_ = module_;
	gen->localDeep = 0;

	gen->opt = opt;

	gen->fixedLen = gen->_.len;

	gen->interface_ = interface_;

	gen->insideSizeOf = (0 > 1);

	gen->memout = NULL;
}

static void Generate_InitModel(struct Generator *gen) {
	if (gen->opt->_.varInit != GenOptions_VarInitUndefined_cnst) {
		TextGenerator_StrLn(&(*gen)._, 28, (o7_char *)"#if !defined(O7_INIT_MODEL)");
		if (gen->opt->_.varInit == GenOptions_VarInitNo_cnst) {
			TextGenerator_StrLn(&(*gen)._, 38, (o7_char *)"#   define   O7_INIT_MODEL O7_INIT_NO");
		} else {
			O7_ASSERT(gen->opt->_.varInit == GenOptions_VarInitZero_cnst);
			TextGenerator_StrLn(&(*gen)._, 40, (o7_char *)"#   define   O7_INIT_MODEL O7_INIT_ZERO");
		}
		TextGenerator_StrLn(&(*gen)._, 7, (o7_char *)"#endif");
		TextGenerator_Ln(&(*gen)._);
	}
}

static void Generate_UseE2kLen(struct Generator *gen) {
	if (gen->opt->e2k) {
		TextGenerator_StrLn(&(*gen)._, 25, (o7_char *)"#define O7_USE_E2K_LEN 1");
		TextGenerator_Ln(&(*gen)._);
	}
}

static void Generate_Includes(struct Generator *gen) {
	if (gen->opt->std >= GeneratorC_IsoC99_cnst) {
		TextGenerator_StrLn(&(*gen)._, 21, (o7_char *)"#include <stdbool.h>");
	}
	TextGenerator_StrLn(&(*gen)._, 16, (o7_char *)"#include <o7.h>");
	TextGenerator_Ln(&(*gen)._);
}

static void Generate_HeaderGuard(struct Generator *gen) {
	TextGenerator_Str(&(*gen)._, 27, (o7_char *)"#if !defined HEADER_GUARD_");
	TextGenerator_String(&(*gen)._, &gen->module_->_._.name);
	TextGenerator_Ln(&(*gen)._);
	TextGenerator_Str(&(*gen)._, 27, (o7_char *)"#    define  HEADER_GUARD_");
	TextGenerator_String(&(*gen)._, &gen->module_->_._.name);
	TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)" 1");
	TextGenerator_Ln(&(*gen)._);
}

static void Generate_ModuleInit(struct Generator *interf, struct Generator *impl, struct Ast_RModule *module_, struct Ast_RStatement *cmd) {
	if ((module_->import_ == NULL) && (module_->_.stats == NULL) && (cmd == NULL) && (impl->opt->records == NULL)) {
		if (impl->opt->std >= GeneratorC_IsoC99_cnst) {
			TextGenerator_Str(&(*interf)._, 20, (o7_char *)"static inline void ");
		} else {
			TextGenerator_Str(&(*interf)._, 16, (o7_char *)"O7_INLINE void ");
		}
		Name(interf, &module_->_._);
		TextGenerator_StrLn(&(*interf)._, 18, (o7_char *)"_init(void) { ; }");
	} else {
		TextGenerator_Str(&(*interf)._, 13, (o7_char *)"extern void ");
		Name(interf, &module_->_._);
		TextGenerator_StrLn(&(*interf)._, 13, (o7_char *)"_init(void);");

		TextGenerator_Str(&(*impl)._, 13, (o7_char *)"extern void ");
		Name(impl, &module_->_._);
		TextGenerator_StrOpen(&(*impl)._, 14, (o7_char *)"_init(void) {");
		TextGenerator_StrLn(&(*impl)._, 33, (o7_char *)"static unsigned initialized = 0;");
		TextGenerator_StrOpen(&(*impl)._, 24, (o7_char *)"if (0 == initialized) {");
		ImportInit(impl, &module_->import_->_);
		TagsInit(impl);
		Statements(impl, module_->_.stats);
		Statements(impl, cmd);
		TextGenerator_StrLnClose(&(*impl)._, 2, (o7_char *)"\x7D");
		TextGenerator_StrLn(&(*impl)._, 15, (o7_char *)"++initialized;");
		TextGenerator_StrLnClose(&(*impl)._, 2, (o7_char *)"\x7D");
		TextGenerator_Ln(&(*impl)._);
	}
}

static void Generate_ModuleDone(struct Generator *interf, struct Generator *impl, struct Ast_RModule *module_) {
	if (impl->opt->memManager != GeneratorC_MemManagerCounter_cnst) {
	} else if ((module_->import_ == NULL) && (impl->opt->records == NULL)) {
		if (impl->opt->std >= GeneratorC_IsoC99_cnst) {
			TextGenerator_Str(&(*interf)._, 20, (o7_char *)"static inline void ");
		} else {
			TextGenerator_Str(&(*interf)._, 16, (o7_char *)"O7_INLINE void ");
		}
		Name(interf, &module_->_._);
		TextGenerator_StrLn(&(*interf)._, 18, (o7_char *)"_done(void) { ; }");
	} else {
		TextGenerator_Str(&(*interf)._, 13, (o7_char *)"extern void ");
		Name(interf, &module_->_._);
		TextGenerator_StrLn(&(*interf)._, 13, (o7_char *)"_done(void);");

		TextGenerator_Str(&(*impl)._, 13, (o7_char *)"extern void ");
		Name(impl, &module_->_._);
		TextGenerator_StrOpen(&(*impl)._, 14, (o7_char *)"_done(void) {");
		ReleaseVars(impl, &module_->_.vars->_);
		ImportDone(impl, &module_->import_->_);
		TextGenerator_StrLnClose(&(*impl)._, 2, (o7_char *)"\x7D");
		TextGenerator_Ln(&(*impl)._);
	}
}

static void Generate_Main(struct Generator *gen, struct Ast_RModule *module_, struct Ast_RStatement *cmd) {
	TextGenerator_StrOpen(&(*gen)._, 42, (o7_char *)"extern int main(int argc, char *argv[]) {");
	TextGenerator_StrLn(&(*gen)._, 21, (o7_char *)"o7_init(argc, argv);");
	ImportInit(gen, &module_->import_->_);
	TagsInit(gen);
	Statements(gen, module_->_.stats);
	Statements(gen, cmd);
	if (gen->opt->memManager == GeneratorC_MemManagerCounter_cnst) {
		ReleaseVars(gen, &module_->_.vars->_);
		ImportDone(gen, &module_->import_->_);
	}
	TextGenerator_StrLn(&(*gen)._, 21, (o7_char *)"return o7_exit_code;");
	TextGenerator_StrLnClose(&(*gen)._, 2, (o7_char *)"\x7D");
}

static void Generate_GeneratorNotify(struct Generator *gen) {
	if (gen->opt->_.generatorNote) {
		TextGenerator_StrLn(&(*gen)._, 49, (o7_char *)"/* Generated by Vostok - Oberon-07 translator */");
		TextGenerator_Ln(&(*gen)._);
	}
}

extern void GeneratorC_Generate(struct VDataStream_Out *interface_, struct VDataStream_Out *implementation, struct Ast_RModule *module_, struct Ast_RStatement *cmd, struct GeneratorC_Options__s *opt) {
	struct MOut out;
	memset(&out, 0, sizeof(out));

	O7_ASSERT(!Ast_HasError(module_));

	if (opt == NULL) {
		opt = GeneratorC_DefaultOptions();
	}
	out.opt = opt;

	opt->records = NULL;
	opt->recordLast = NULL;
	opt->index = 0;

	opt->_.main_ = interface_ == NULL;

	if (!opt->_.main_) {
		MarkUsedInMarked(module_);
	}

	if (interface_ != NULL) {
		Generate_Init(&out.g[Interface_cnst], interface_, module_, opt, (0 < 1));
		Generate_GeneratorNotify(&out.g[Interface_cnst]);
	}

	Generate_Init(&out.g[Implementation_cnst], implementation, module_, opt, (0 > 1));
	Generate_GeneratorNotify(&out.g[Implementation_cnst]);

	Comment(&out.g[o7_ind(2, (o7_int_t)!opt->_.main_)], &module_->_._._.comment);

	Generate_InitModel(&out.g[Implementation_cnst]);
	Generate_UseE2kLen(&out.g[Implementation_cnst]);

	Generate_Includes(&out.g[Implementation_cnst]);

	if (!opt->_.main_) {
		Generate_HeaderGuard(&out.g[Interface_cnst]);
		Import(&out.g[Implementation_cnst], &module_->_._);
	}

	Declarations(&out, &module_->_);

	if (opt->_.main_) {
		Generate_Main(&out.g[Implementation_cnst], module_, cmd);
	} else {
		Generate_ModuleInit(&out.g[Interface_cnst], &out.g[Implementation_cnst], module_, cmd);
		Generate_ModuleDone(&out.g[Interface_cnst], &out.g[Implementation_cnst], module_);
		TextGenerator_StrLn(&out.g[Interface_cnst]._, 7, (o7_char *)"#endif");
	}
}

extern void GeneratorC_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		Ast_init();
		StringStore_init();
		SpecIdentChecker_init();
		Scanner_init();
		OberonSpecIdent_init();
		VDataStream_init();
		TextGenerator_init();
		GenCommon_init();

		O7_TAG_INIT(GeneratorC_MemoryOut, VDataStream_Out);
		O7_TAG_INIT(RecExt__s, V_Base);

		type = Type;
		declarator = Declarator;
		declarations = Declarations;
		statements = Statements;
		expression = Expression;
	}
	++initialized;
}

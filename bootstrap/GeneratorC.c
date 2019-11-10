#include <o7.h>

#include "GeneratorC.h"

#define Interface_cnst 1
#define Implementation_cnst 0

#define CheckableArithTypes_cnst (Ast_Numbers_cnst & ~(1u << Ast_IdByte_cnst))
#define CheckableInitTypes_cnst (CheckableArithTypes_cnst | (1u << Ast_IdBoolean_cnst))

o7_tag_t GeneratorC_MemoryOut_tag;
extern void GeneratorC_MemoryOut_undef(struct GeneratorC_MemoryOut *r) {
	VDataStream_Out_undef(&r->_);
	memset(&r->mem, 0, sizeof(r->mem));
	r->invert = O7_BOOL_UNDEF;
	r->next = NULL;
}
#define GeneratorC_Options__s_tag V_Base_tag
extern void GeneratorC_Options__s_undef(struct GeneratorC_Options__s *r) {
	V_Base_undef(&r->_);
	r->std = O7_INT_UNDEF;
	r->gnu = O7_BOOL_UNDEF;
	r->plan9 = O7_BOOL_UNDEF;
	r->procLocal = O7_BOOL_UNDEF;
	r->checkIndex = O7_BOOL_UNDEF;
	r->vla = O7_BOOL_UNDEF;
	r->vlaMark = O7_BOOL_UNDEF;
	r->checkArith = O7_BOOL_UNDEF;
	r->caseAbort = O7_BOOL_UNDEF;
	r->checkNil = O7_BOOL_UNDEF;
	r->o7Assert = O7_BOOL_UNDEF;
	r->skipUnusedTag = O7_BOOL_UNDEF;
	r->comment = O7_BOOL_UNDEF;
	r->generatorNote = O7_BOOL_UNDEF;
	r->varInit = O7_INT_UNDEF;
	r->memManager = O7_INT_UNDEF;
	r->main_ = O7_BOOL_UNDEF;
	r->index = O7_INT_UNDEF;
	r->records = NULL;
	r->recordLast = NULL;
	r->lastSelectorDereference = O7_BOOL_UNDEF;
	r->expectArray = O7_BOOL_UNDEF;
	r->memOuts = NULL;
}
#define GeneratorC_Generator_tag TextGenerator_Out_tag
extern void GeneratorC_Generator_undef(struct GeneratorC_Generator *r) {
	TextGenerator_Out_undef(&r->_);
	r->module_ = NULL;
	r->localDeep = O7_INT_UNDEF;
	r->fixedLen = O7_INT_UNDEF;
	r->interface_ = O7_BOOL_UNDEF;
	r->opt = NULL;
	r->expressionSemicolon = O7_BOOL_UNDEF;
	r->insideSizeOf = O7_BOOL_UNDEF;
	r->memout = NULL;
}

typedef struct MOut {
	struct GeneratorC_Generator g[2];
	struct GeneratorC_Options__s *opt;
} MOut;
#define MOut_tag o7_base_tag

static void MOut_undef(struct MOut *r) {
	o7_int_t i;
	for (i = 0; i < O7_LEN(r->g); i += 1) {
		GeneratorC_Generator_undef(r->g + i);
	}
	r->opt = NULL;
}

typedef struct Selectors {
	struct Ast_Designator__s *des;
	struct Ast_RDeclaration *decl;
	struct Ast_RSelector *list[TranslatorLimits_Selectors_cnst];
	o7_int_t i;
} Selectors;
#define Selectors_tag o7_base_tag

static void Selectors_undef(struct Selectors *r) {
	r->des = NULL;
	r->decl = NULL;
	memset(&r->list, 0, sizeof(r->list));
	r->i = O7_INT_UNDEF;
}

typedef struct RecExt__s {
	V_Base _;
	struct StringStore_String anonName;
	o7_bool undef;
	struct Ast_RRecord *next;
} *RecExt;
static o7_tag_t RecExt__s_tag;

static void (*type)(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *decl, struct Ast_RType *type, o7_bool typeDecl, o7_bool sameType) = NULL;
static void (*declarator)(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *decl, o7_bool typeDecl, o7_bool sameType, o7_bool global) = NULL;
static void (*declarations)(struct MOut *out, struct Ast_RDeclarations *ds) = NULL;
static void (*statements)(struct GeneratorC_Generator *gen, struct Ast_RStatement *stats) = NULL;
static void (*expression)(struct GeneratorC_Generator *gen, struct Ast_RExpression *expr) = NULL;

static void MemoryWrite(struct GeneratorC_MemoryOut *out, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t ofs, o7_int_t count) {
	O7_ASSERT(Chars0X_CopyChars(4096, (*out).mem[o7_ind(2, (o7_int_t)o7_bl((*out).invert))].buf, &(*out).mem[o7_ind(2, (o7_int_t)o7_bl((*out).invert))].len, buf_len0, buf, ofs, o7_add(ofs, count)));
}

static o7_int_t MemWrite(struct V_Base *out, o7_tag_t *out_tag, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t ofs, o7_int_t count) {
	MemoryWrite(&O7_GUARD_R(GeneratorC_MemoryOut, &(*out), out_tag), buf_len0, buf, ofs, count);
	return count;
}

static struct GeneratorC_MemoryOut *PMemoryOutGet(struct GeneratorC_Options__s *opt) {
	struct GeneratorC_MemoryOut *m = NULL;

	if (O7_REF(opt)->memOuts == NULL) {
		O7_NEW(&m, GeneratorC_MemoryOut);
		VDataStream_InitOut(&(*O7_REF(m))._, NULL, MemWrite, NULL);
	} else {
		m = O7_REF(opt)->memOuts;
		O7_REF(opt)->memOuts = O7_REF(m)->next;
	}
	O7_REF(m)->mem[0].len = 0;
	O7_REF(m)->mem[1].len = 0;
	O7_REF(m)->invert = (0 > 1);
	O7_REF(m)->next = NULL;
	return m;
}

static void PMemoryOutBack(struct GeneratorC_Options__s *opt, struct GeneratorC_MemoryOut *m) {
	O7_REF(m)->next = O7_REF(opt)->memOuts;
	O7_REF(opt)->memOuts = m;
}

static void MemWriteInvert(struct GeneratorC_MemoryOut *mo) {
	o7_int_t inv, direct;

	inv = (o7_int_t)o7_bl((*mo).invert);
	if (o7_cmp((*mo).mem[o7_ind(2, inv)].len, 0) == 0) {
		(*mo).invert = !o7_bl((*mo).invert);
	} else {
		direct = o7_sub(1, inv);
		O7_ASSERT(Chars0X_CopyChars(4096, (*mo).mem[o7_ind(2, inv)].buf, &(*mo).mem[o7_ind(2, inv)].len, 4096, (*mo).mem[o7_ind(2, direct)].buf, 0, o7_int((*mo).mem[o7_ind(2, direct)].len)));
		(*mo).mem[o7_ind(2, direct)].len = 0;
	}
}

static void MemWriteDirect(struct GeneratorC_Generator *gen, struct GeneratorC_MemoryOut *mo) {
	o7_int_t inv;

	inv = (o7_int_t)o7_bl((*mo).invert);
	O7_ASSERT(o7_cmp((*mo).mem[o7_ind(2, o7_sub(1, inv))].len, 0) == 0);
	TextGenerator_Data(&(*gen)._, 4096, (*mo).mem[o7_ind(2, inv)].buf, 0, o7_int((*mo).mem[o7_ind(2, inv)].len));
	(*mo).mem[o7_ind(2, inv)].len = 0;
}

static void Ident(struct GeneratorC_Generator *gen, struct StringStore_String *ident) {
	o7_char buf[TranslatorLimits_LenName_cnst * 6 + 2];
	o7_int_t i;
	struct StringStore_Iterator it;
	memset(&buf, 0, sizeof(buf));
	StringStore_Iterator_undef(&it);

	O7_ASSERT(StringStore_GetIter(&it, &(*ident), 0));
	i = 0;
	do {
		buf[o7_ind(TranslatorLimits_LenName_cnst * 6 + 2, i)] = it.char_;
		i = o7_add(i, 1);
		if (it.char_ == (o7_char)'_') {
			buf[o7_ind(TranslatorLimits_LenName_cnst * 6 + 2, i)] = (o7_char)'_';
			i = o7_add(i, 1);
		}
	} while (StringStore_IterNext(&it));
	TextGenerator_Data(&(*gen)._, TranslatorLimits_LenName_cnst * 6 + 2, buf, 0, i);
}

static void Name(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *decl) {
	struct Ast_RDeclarations *up;
	struct Ast_RDeclarations *prs[TranslatorLimits_DeepProcedures_cnst + 1];
	o7_int_t i;
	memset(&prs, 0, sizeof(prs));

	if ((o7_is(decl, &Ast_RType_tag)) && (O7_REF(decl)->up != NULL) && (O7_REF(O7_REF(decl)->up)->d != &O7_REF(O7_REF(decl)->module_)->m->_) || !o7_bl(O7_REF((*gen).opt)->procLocal) && (o7_is(decl, &Ast_RProcedure_tag))) {
		up = O7_REF(O7_REF(decl)->up)->d;
		i = 0;
		while (O7_REF(up)->_.up != NULL) {
			prs[o7_ind(TranslatorLimits_DeepProcedures_cnst + 1, i)] = up;
			i = o7_add(i, 1);
			up = O7_REF(O7_REF(up)->_.up)->d;
		}
		while (i > 0) {
			i = o7_sub(i, 1);
			Ident(&(*gen), &O7_REF(prs[o7_ind(TranslatorLimits_DeepProcedures_cnst + 1, i)])->_.name);
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x5F");
		}
	}
	Ident(&(*gen), &O7_REF(decl)->name);
	if (o7_is(decl, &Ast_Const__s_tag)) {
		TextGenerator_Str(&(*gen)._, 6, (o7_char *)"_cnst");
	} else if (SpecIdentChecker_IsSpecName(&O7_REF(decl)->name, 0)) {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x5F");
	}
}

static void GlobalName(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *decl) {
	if (o7_bl(O7_REF(decl)->mark) || (O7_REF(decl)->module_ != NULL) && ((*gen).module_ != O7_REF(O7_REF(decl)->module_)->m)) {
		O7_ASSERT(O7_REF(decl)->module_ != NULL);
		Ident(&(*gen), &O7_REF(O7_REF(O7_REF(decl)->module_)->m)->_._.name);

		TextGenerator_Data(&(*gen)._, 3, (o7_char *)"__", 0, o7_add((o7_int_t)(SpecIdentChecker_IsSpecModuleName(&O7_REF(O7_REF(O7_REF(decl)->module_)->m)->_._.name) && !o7_bl(O7_REF(O7_REF(O7_REF(decl)->module_)->m)->spec) || SpecIdentChecker_IsO7SpecName(&O7_REF(decl)->name)), 1));
		Ident(&(*gen), &O7_REF(decl)->name);
		if (o7_is(decl, &Ast_Const__s_tag)) {
			TextGenerator_Str(&(*gen)._, 6, (o7_char *)"_cnst");
		}
	} else {
		Name(&(*gen), decl);
	}
}

static void Import(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *decl) {
	struct StringStore_String name;
	o7_int_t i;
	StringStore_String_undef(&name);

	TextGenerator_Str(&(*gen)._, 10, (o7_char *)"#include ");
	TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x22");
	if (o7_is(decl, &Ast_RModule_tag)) {
		name = O7_REF(decl)->name;
	} else {
		O7_ASSERT(o7_is(decl, &Ast_Import__s_tag));
		name = O7_REF(O7_REF(O7_REF(decl)->module_)->m)->_._.name;
	}
	TextGenerator_String(&(*gen)._, &name);
	i = (o7_int_t)!SpecIdentChecker_IsSpecModuleName(&name);
	TextGenerator_Data(&(*gen)._, 4, (o7_char *)"_.h", i, o7_sub(3, i));
	TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x22");
}

static void Factor(struct GeneratorC_Generator *gen, struct Ast_RExpression *expr) {
	if (o7_is(expr, &Ast_RFactor_tag)) {
		expression(&(*gen), expr);
	} else {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x28");
		expression(&(*gen), expr);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static o7_bool IsAnonStruct(struct Ast_RRecord *rec) {
	return !StringStore_IsDefined(&O7_REF(rec)->_._._.name) || StringStore_SearchSubString(&O7_REF(rec)->_._._.name, 7, (o7_char *)"_anon_");
}

static struct Ast_RType *TypeForTag(struct Ast_RRecord *rec) {
	if (IsAnonStruct(rec)) {
		rec = O7_REF(rec)->base;
	}
	return (&(rec)->_._);
}

static o7_bool CheckStructName(struct GeneratorC_Generator *gen, struct Ast_RRecord *rec) {
	o7_char anon[TranslatorLimits_LenName_cnst * 2 + 3];
	o7_int_t i, j, l;
	memset(&anon, 0, sizeof(anon));

	if (StringStore_IsDefined(&O7_REF(rec)->_._._.name)) {
	} else if ((O7_REF(rec)->pointer != NULL) && StringStore_IsDefined(&O7_REF(O7_REF(rec)->pointer)->_._._.name)) {
		l = 0;
		O7_ASSERT(O7_REF(rec)->_._._.module_ != NULL);
		O7_REF(rec)->_._._.mark = o7_bl(O7_REF(O7_REF(rec)->pointer)->_._._.mark);
		O7_ASSERT(StringStore_CopyToChars(TranslatorLimits_LenName_cnst * 2 + 3, anon, &l, &O7_REF(O7_REF(rec)->pointer)->_._._.name));
		anon[o7_ind(TranslatorLimits_LenName_cnst * 2 + 3, l)] = (o7_char)'_';
		anon[o7_ind(TranslatorLimits_LenName_cnst * 2 + 3, o7_add(l, 1))] = (o7_char)'s';
		anon[o7_ind(TranslatorLimits_LenName_cnst * 2 + 3, o7_add(l, 2))] = 0x00u;
		Ast_PutChars(O7_REF(O7_REF(O7_REF(rec)->pointer)->_._._.module_)->m, &O7_REF(rec)->_._._.name, TranslatorLimits_LenName_cnst * 2 + 3, anon, 0, o7_add(l, 2));
	} else {
		l = 0;
		O7_ASSERT(StringStore_CopyToChars(TranslatorLimits_LenName_cnst * 2 + 3, anon, &l, &O7_REF(O7_REF(O7_REF(rec)->_._._.module_)->m)->_._.name));

		O7_ASSERT(Chars0X_CopyString(TranslatorLimits_LenName_cnst * 2 + 3, anon, &l, 11, (o7_char *)"_anon_0000"));
		O7_ASSERT((o7_cmp(O7_REF((*gen).opt)->index, 0) >= 0) && (o7_cmp(O7_REF((*gen).opt)->index, 10000) < 0));
		i = o7_int(O7_REF((*gen).opt)->index);
		j = o7_sub(l, 1);
		while (i > 0) {
			anon[o7_ind(TranslatorLimits_LenName_cnst * 2 + 3, j)] = o7_chr(o7_add((o7_int_t)(o7_char)'0', o7_mod(i, 10)));
			i = o7_div(i, 10);
			j = o7_sub(j, 1);
		}
		O7_REF((*gen).opt)->index = o7_add(O7_REF((*gen).opt)->index, 1);
		Ast_PutChars(O7_REF(O7_REF(rec)->_._._.module_)->m, &O7_REF(rec)->_._._.name, TranslatorLimits_LenName_cnst * 2 + 3, anon, 0, l);
	}
	return StringStore_IsDefined(&O7_REF(rec)->_._._.name);
}

static void ArrayDeclLen(struct GeneratorC_Generator *gen, struct Ast_RType *arr, struct Ast_RDeclaration *decl, struct Ast_RSelector *sel, o7_int_t i) {
	if (O7_GUARD(Ast_RArray, &arr)->count != NULL) {
		expression(&(*gen), O7_GUARD(Ast_RArray, &arr)->count);
	} else {
		GlobalName(&(*gen), decl);
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)"_len");
		if (i < 0) {
			i = 0;
			while (sel != NULL) {
				i = o7_add(i, 1);
				sel = O7_REF(sel)->next;
			}
		}
		TextGenerator_Int(&(*gen)._, i);
	}
}

static void ArrayLen(struct GeneratorC_Generator *gen, struct Ast_RExpression *e) {
	o7_int_t i;
	struct Ast_Designator__s *des;
	struct Ast_RType *t;

	if (O7_GUARD(Ast_RArray, &O7_REF(e)->type)->count != NULL) {
		expression(&(*gen), O7_GUARD(Ast_RArray, &O7_REF(e)->type)->count);
	} else {
		des = O7_GUARD(Ast_Designator__s, &e);
		GlobalName(&(*gen), O7_REF(des)->decl);
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)"_len");
		i = 0;
		t = O7_REF(des)->_._.type;
		while (t != O7_REF(e)->type) {
			i = o7_add(i, 1);
			t = O7_REF(t)->_.type;
		}
		TextGenerator_Int(&(*gen)._, i);
	}
}

static void Selector(struct GeneratorC_Generator *gen, struct Selectors *sels, o7_int_t i, struct Ast_RType **typ, struct Ast_RType *desType);
static void Selector_Record(struct GeneratorC_Generator *gen, struct Ast_RType **typ, struct Ast_RSelector **sel);
static o7_bool Selector_Record_Search(struct Ast_RRecord *ds, struct Ast_RDeclaration *d) {
	struct Ast_RDeclaration *c;

	c = (&(O7_REF(ds)->vars)->_);
	while ((c != NULL) && (c != d)) {
		c = O7_REF(c)->next;
	}
	return c != NULL;
}

static void Selector_Record(struct GeneratorC_Generator *gen, struct Ast_RType **typ, struct Ast_RSelector **sel) {
	struct Ast_RDeclaration *var_;
	struct Ast_RRecord *up;

	var_ = (&(O7_GUARD(Ast_SelRecord__s, &(*sel))->var_)->_);
	if (o7_is((*typ), &Ast_RPointer_tag)) {
		up = O7_GUARD(Ast_RRecord, &O7_GUARD(Ast_RPointer, &(*typ))->_._._.type);
	} else {
		up = O7_GUARD(Ast_RRecord, &(*typ));
	}

	if (o7_cmp(O7_REF((*typ))->_._.id, Ast_IdPointer_cnst) == 0) {
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)"->");
	} else {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x2E");
	}

	if (!o7_bl(O7_REF((*gen).opt)->plan9)) {
		while ((up != NULL) && !Selector_Record_Search(up, var_)) {
			up = O7_REF(up)->base;
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)"_.");
		}
	}

	Name(&(*gen), var_);

	(*typ) = O7_REF(var_)->type;
}

static void Selector_Declarator(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *decl) {
	if ((o7_is(decl, &Ast_RFormalParam_tag)) && ((!!( (1u << Ast_ParamOut_cnst) & O7_GUARD(Ast_RFormalParam, &decl)->access)) && (o7_cmp(O7_REF(O7_REF(decl)->type)->_._.id, Ast_IdArray_cnst) != 0) || (o7_cmp(O7_REF(O7_REF(decl)->type)->_._.id, Ast_IdRecord_cnst) == 0))) {
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)"(*");
		GlobalName(&(*gen), decl);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	} else {
		GlobalName(&(*gen), decl);
	}
}

static void Selector_Array(struct GeneratorC_Generator *gen, struct Ast_RType **typ, struct Ast_RSelector **sel, struct Ast_RDeclaration *decl, o7_bool isDesignatorArray);
static void Selector_Array_Mult(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *decl, o7_int_t j, struct Ast_RType *t) {
	while ((t != NULL) && (o7_is(t, &Ast_RArray_tag))) {
		TextGenerator_Str(&(*gen)._, 4, (o7_char *)" * ");
		Name(&(*gen), decl);
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)"_len");
		TextGenerator_Int(&(*gen)._, j);
		j = o7_add(j, 1);
		t = O7_REF(t)->_.type;
	}
}

static void Selector_Array(struct GeneratorC_Generator *gen, struct Ast_RType **typ, struct Ast_RSelector **sel, struct Ast_RDeclaration *decl, o7_bool isDesignatorArray) {
	o7_int_t i;

	if (isDesignatorArray && !o7_bl(O7_REF((*gen).opt)->vla)) {
		TextGenerator_Str(&(*gen)._, 4, (o7_char *)" + ");
	} else {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x5B");
	}
	if ((o7_cmp(O7_REF(O7_REF((*typ))->_.type)->_._.id, Ast_IdArray_cnst) != 0) || (O7_GUARD(Ast_RArray, &(*typ))->count != NULL) || o7_bl(O7_REF((*gen).opt)->vla)) {
		if (o7_bl(O7_REF((*gen).opt)->checkIndex) && ((O7_REF(O7_GUARD(Ast_SelArray__s, &(*sel))->index)->value_ == NULL) || (O7_GUARD(Ast_RArray, &(*typ))->count == NULL) && (o7_cmp(O7_GUARD(Ast_RExprInteger, &O7_REF(O7_GUARD(Ast_SelArray__s, &(*sel))->index)->value_)->int_, 0) != 0))) {
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_ind(");
			ArrayDeclLen(&(*gen), (*typ), decl, (*sel), 0);
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
			expression(&(*gen), O7_GUARD(Ast_SelArray__s, &(*sel))->index);
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		} else {
			expression(&(*gen), O7_GUARD(Ast_SelArray__s, &(*sel))->index);
		}
		(*typ) = O7_REF((*typ))->_.type;
		(*sel) = O7_REF((*sel))->next;
		i = 1;
		while (((*sel) != NULL) && (o7_is((*sel), &Ast_SelArray__s_tag))) {
			if (o7_bl(O7_REF((*gen).opt)->checkIndex) && ((O7_REF(O7_GUARD(Ast_SelArray__s, &(*sel))->index)->value_ == NULL) || (O7_GUARD(Ast_RArray, &(*typ))->count == NULL) && (o7_cmp(O7_GUARD(Ast_RExprInteger, &O7_REF(O7_GUARD(Ast_SelArray__s, &(*sel))->index)->value_)->int_, 0) != 0))) {
				TextGenerator_Str(&(*gen)._, 10, (o7_char *)"][o7_ind(");
				ArrayDeclLen(&(*gen), (*typ), decl, (*sel), i);
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
				expression(&(*gen), O7_GUARD(Ast_SelArray__s, &(*sel))->index);
				TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
			} else {
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)"][");
				expression(&(*gen), O7_GUARD(Ast_SelArray__s, &(*sel))->index);
			}
			i = o7_add(i, 1);
			(*sel) = O7_REF((*sel))->next;
			(*typ) = O7_REF((*typ))->_.type;
		}
	} else {
		i = 0;
		while ((O7_REF((*sel))->next != NULL) && (o7_is(O7_REF((*sel))->next, &Ast_SelArray__s_tag))) {
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_ind(");
			ArrayDeclLen(&(*gen), (*typ), decl, NULL, i);
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
			expression(&(*gen), O7_GUARD(Ast_SelArray__s, &(*sel))->index);
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
			(*typ) = O7_REF((*typ))->_.type;
			Selector_Array_Mult(&(*gen), decl, o7_add(i, 1), (*typ));
			(*sel) = O7_REF((*sel))->next;
			i = o7_add(i, 1);
			TextGenerator_Str(&(*gen)._, 4, (o7_char *)" + ");
		}
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_ind(");
		ArrayDeclLen(&(*gen), (*typ), decl, NULL, i);
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
		expression(&(*gen), O7_GUARD(Ast_SelArray__s, &(*sel))->index);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		Selector_Array_Mult(&(*gen), decl, o7_add(i, 1), O7_REF((*typ))->_.type);
	}
	if (!isDesignatorArray || o7_bl(O7_REF((*gen).opt)->vla)) {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x5D");
	}
}

static void Selector(struct GeneratorC_Generator *gen, struct Selectors *sels, o7_int_t i, struct Ast_RType **typ, struct Ast_RType *desType) {
	struct Ast_RSelector *sel = NULL;
	o7_bool ref_;

	if (i >= 0) {
		sel = (*sels).list[o7_ind(TranslatorLimits_Selectors_cnst, i)];
	}
	if (!o7_bl(O7_REF((*gen).opt)->checkNil)) {
		ref_ = (0 > 1);
	} else if (i < 0) {
		ref_ = (o7_cmp((*sels).i, 0) >= 0) && (O7_REF((*sels).decl)->type != NULL) && (o7_cmp(O7_REF(O7_REF((*sels).decl)->type)->_._.id, Ast_IdPointer_cnst) == 0);
	} else {
		ref_ = (o7_cmp(O7_REF(O7_REF(sel)->type)->_._.id, Ast_IdPointer_cnst) == 0) && (O7_REF(sel)->next != NULL) && !(o7_is(O7_REF(sel)->next, &Ast_SelGuard__s_tag)) && !(o7_is(sel, &Ast_SelGuard__s_tag));
	}
	if (ref_) {
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"O7_REF(");
	}
	if (i < 0) {
		Selector_Declarator(&(*gen), (*sels).decl);
	} else {
		i = o7_sub(i, 1);
		if (o7_is(sel, &Ast_SelRecord__s_tag)) {
			Selector(&(*gen), &(*sels), i, &(*typ), desType);
			Selector_Record(&(*gen), &(*typ), &sel);
		} else if (o7_is(sel, &Ast_SelArray__s_tag)) {
			Selector(&(*gen), &(*sels), i, &(*typ), desType);
			Selector_Array(&(*gen), &(*typ), &sel, (*sels).decl, (o7_cmp(O7_REF(desType)->_._.id, Ast_IdArray_cnst) == 0) && (O7_GUARD(Ast_RArray, &desType)->count == NULL));
		} else if (o7_is(sel, &Ast_SelPointer__s_tag)) {
			if ((O7_REF(sel)->next == NULL) || !(o7_is(O7_REF(sel)->next, &Ast_SelRecord__s_tag))) {
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)"(*");
				Selector(&(*gen), &(*sels), i, &(*typ), desType);
				TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
			} else {
				Selector(&(*gen), &(*sels), i, &(*typ), desType);
			}
		} else {
			O7_ASSERT(o7_is(sel, &Ast_SelGuard__s_tag));
			if (o7_cmp(O7_REF(O7_REF(sel)->type)->_._.id, Ast_IdPointer_cnst) == 0) {
				TextGenerator_Str(&(*gen)._, 10, (o7_char *)"O7_GUARD(");
				O7_ASSERT(CheckStructName(&(*gen), O7_GUARD(Ast_RRecord, &O7_REF(O7_REF(sel)->type)->_.type)));
				GlobalName(&(*gen), &O7_REF(O7_REF(sel)->type)->_.type->_);
			} else {
				TextGenerator_Str(&(*gen)._, 12, (o7_char *)"O7_GUARD_R(");
				GlobalName(&(*gen), &O7_REF(sel)->type->_);
			}
			TextGenerator_Str(&(*gen)._, 4, (o7_char *)", &");
			if (i < 0) {
				Selector_Declarator(&(*gen), (*sels).decl);
			} else {
				Selector(&(*gen), &(*sels), i, &(*typ), desType);
			}
			if (o7_cmp(O7_REF(O7_REF(sel)->type)->_._.id, Ast_IdPointer_cnst) == 0) {
				TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
			} else {
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
				GlobalName(&(*gen), (*sels).decl);
				TextGenerator_Str(&(*gen)._, 6, (o7_char *)"_tag)");
			}
			(*typ) = O7_GUARD(Ast_SelGuard__s, &sel)->_.type;
		}
	}
	if (ref_) {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static o7_bool IsDesignatorMayNotInited(struct Ast_Designator__s *des) {
	return ((((1u << Ast_InitedNo_cnst) | (1u << Ast_InitedCheck_cnst)) & O7_REF(des)->inited) != 0) || (O7_REF(des)->sel != NULL);
}

static o7_bool IsMayNotInited(struct Ast_RExpression *e) {
	return (o7_is(e, &Ast_Designator__s_tag)) && IsDesignatorMayNotInited(O7_GUARD(Ast_Designator__s, &e));
}

static void Designator(struct GeneratorC_Generator *gen, struct Ast_Designator__s *des);
static void Designator_Put(struct Selectors *sels, struct Ast_RSelector *sel) {
	(*sels).i =  - 1;
	while (sel != NULL) {
		(*sels).i = o7_add((*sels).i, 1);
		(*sels).list[o7_ind(TranslatorLimits_Selectors_cnst, (*sels).i)] = sel;
		if (o7_is(sel, &Ast_SelArray__s_tag)) {
			do {
				sel = O7_REF(sel)->next;
			} while (!((sel == NULL) || !(o7_is(sel, &Ast_SelArray__s_tag))));
		} else {
			sel = O7_REF(sel)->next;
		}
	}
}

static void Designator(struct GeneratorC_Generator *gen, struct Ast_Designator__s *des) {
	struct Selectors sels;
	struct Ast_RType *typ;
	o7_bool lastSelectorDereference;
	Selectors_undef(&sels);

	typ = O7_REF(O7_REF(des)->decl)->type;
	Designator_Put(&sels, O7_REF(des)->sel);
	sels.des = des;
	sels.decl = O7_REF(des)->decl;
	/* TODO */
	lastSelectorDereference = (o7_cmp(0, sels.i) <= 0) && (o7_is(sels.list[o7_ind(TranslatorLimits_Selectors_cnst, sels.i)], &Ast_SelPointer__s_tag));
	Selector(&(*gen), &sels, o7_int(sels.i), &typ, O7_REF(des)->_._.type);
	O7_REF((*gen).opt)->lastSelectorDereference = lastSelectorDereference;
}

static void CheckExpr(struct GeneratorC_Generator *gen, struct Ast_RExpression *e) {
	if ((o7_cmp(O7_REF((*gen).opt)->varInit, GeneratorC_VarInitUndefined_cnst) == 0) && (O7_REF(e)->value_ == NULL) && (o7_in(O7_REF(O7_REF(e)->type)->_._.id, CheckableInitTypes_cnst)) && IsMayNotInited(e)) {
		switch (O7_REF(O7_REF(e)->type)->_._.id) {
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
			o7_case_fail(O7_REF(O7_REF(e)->type)->_._.id);
			break;
		}
		expression(&(*gen), e);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	} else {
		expression(&(*gen), e);
	}
}

static void AssignInitValue(struct GeneratorC_Generator *gen, struct Ast_RType *typ);
static void AssignInitValue_Zero(struct GeneratorC_Generator *gen, struct Ast_RType *typ) {
	switch (O7_REF(typ)->_._.id) {
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
		o7_case_fail(O7_REF(typ)->_._.id);
		break;
	}
}

static void AssignInitValue_Undef(struct GeneratorC_Generator *gen, struct Ast_RType *typ) {
	switch (O7_REF(typ)->_._.id) {
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
		o7_case_fail(O7_REF(typ)->_._.id);
		break;
	}
}

static void AssignInitValue(struct GeneratorC_Generator *gen, struct Ast_RType *typ) {
	switch (O7_REF((*gen).opt)->varInit) {
	case 0:
		AssignInitValue_Undef(&(*gen), typ);
		break;
	case 1:
		AssignInitValue_Zero(&(*gen), typ);
		break;
	default:
		o7_case_fail(O7_REF((*gen).opt)->varInit);
		break;
	}
}

static void VarInit(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *var_, o7_bool record) {
	if ((o7_cmp(O7_REF((*gen).opt)->varInit, GeneratorC_VarInitNo_cnst) == 0) || (o7_in(O7_REF(O7_REF(var_)->type)->_._.id, ((1u << Ast_IdArray_cnst) | (1u << Ast_IdRecord_cnst)))) || (!record && !o7_bl(O7_GUARD(Ast_RVar, &var_)->checkInit))) {
		if ((o7_cmp(O7_REF(O7_REF(var_)->type)->_._.id, Ast_IdPointer_cnst) == 0) && (o7_cmp(O7_REF((*gen).opt)->memManager, GeneratorC_MemManagerCounter_cnst) == 0)) {
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)" = NULL");
		}
	} else {
		AssignInitValue(&(*gen), O7_REF(var_)->type);
	}
}

static void Expression(struct GeneratorC_Generator *gen, struct Ast_RExpression *expr);
static void Expression_Call(struct GeneratorC_Generator *gen, struct Ast_ExprCall__s *call);
static void Expression_Call_Predefined(struct GeneratorC_Generator *gen, struct Ast_ExprCall__s *call);
static void Expression_Call_Predefined_LeftShift(struct GeneratorC_Generator *gen, struct Ast_RExpression *n, struct Ast_RExpression *s) {
	TextGenerator_Str(&(*gen)._, 23, (o7_char *)"(o7_int_t)((o7_uint_t)");
	Factor(&(*gen), n);
	TextGenerator_Str(&(*gen)._, 5, (o7_char *)" << ");
	Factor(&(*gen), s);
	TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
}

static void Expression_Call_Predefined_ArithmeticRightShift(struct GeneratorC_Generator *gen, struct Ast_RExpression *n, struct Ast_RExpression *s) {
	if ((O7_REF(n)->value_ != NULL) && (O7_REF(s)->value_ != NULL)) {
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"O7_ASR(");
		Expression(&(*gen), n);
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
		Expression(&(*gen), s);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	} else if (o7_bl(O7_REF((*gen).opt)->gnu)) {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x28");
		Factor(&(*gen), n);
		if (o7_bl(O7_REF((*gen).opt)->checkArith) && (O7_REF(s)->value_ == NULL)) {
			TextGenerator_Str(&(*gen)._, 16, (o7_char *)" >> o7_not_neg(");
		} else {
			TextGenerator_Str(&(*gen)._, 6, (o7_char *)" >> (");
		}
		Expression(&(*gen), s);
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)"))");
	} else {
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_asr(");
		Expression(&(*gen), n);
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
		Expression(&(*gen), s);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void Expression_Call_Predefined_Rotate(struct GeneratorC_Generator *gen, struct Ast_RExpression *n, struct Ast_RExpression *r) {
	if ((O7_REF(n)->value_ != NULL) && (O7_REF(r)->value_ != NULL)) {
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"O7_ROR(");
	} else {
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_ror(");
	}
	Expression(&(*gen), n);
	TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
	Expression(&(*gen), r);
	TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
}

static void Expression_Call_Predefined_Len(struct GeneratorC_Generator *gen, struct Ast_RExpression *e) {
	struct Ast_RSelector *sel;
	o7_int_t i;
	struct Ast_Designator__s *des = NULL;
	struct Ast_RExpression *count;
	o7_bool sizeof_;

	count = O7_GUARD(Ast_RArray, &O7_REF(e)->type)->count;
	if (o7_is(e, &Ast_Designator__s_tag)) {
		des = O7_GUARD(Ast_Designator__s, &e);
		sizeof_ = !(o7_is(O7_GUARD(Ast_Designator__s, &e)->decl, &Ast_Const__s_tag)) && ((o7_cmp(O7_REF(O7_REF(O7_REF(des)->decl)->type)->_._.id, Ast_IdArray_cnst) != 0) || !(o7_is(O7_REF(des)->decl, &Ast_RFormalParam_tag)));
	} else {
		O7_ASSERT(count != NULL);
		sizeof_ = (0 > 1);
	}
	if ((count != NULL) && !sizeof_) {
		Expression(&(*gen), count);
	} else if (sizeof_) {
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"O7_LEN(");
		Designator(&(*gen), des);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	} else {
		GlobalName(&(*gen), O7_REF(des)->decl);
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)"_len");
		i = 0;
		sel = O7_REF(des)->sel;
		while (sel != NULL) {
			i = o7_add(i, 1);
			sel = O7_REF(sel)->next;
		}
		TextGenerator_Int(&(*gen)._, i);
	}
}

static void Expression_Call_Predefined_New(struct GeneratorC_Generator *gen, struct Ast_RExpression *e) {
	struct Ast_RType *tagType;

	tagType = TypeForTag(O7_GUARD(Ast_RRecord, &O7_REF(O7_REF(e)->type)->_.type));
	if (tagType != NULL) {
		TextGenerator_Str(&(*gen)._, 9, (o7_char *)"O7_NEW(&");
		Designator(&(*gen), O7_GUARD(Ast_Designator__s, &e));
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
		GlobalName(&(*gen), &tagType->_);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	} else {
		TextGenerator_Str(&(*gen)._, 10, (o7_char *)"O7_NEW2(&");
		Designator(&(*gen), O7_GUARD(Ast_Designator__s, &e));
		TextGenerator_Str(&(*gen)._, 21, (o7_char *)", o7_base_tag, NULL)");
	}
}

static void Expression_Call_Predefined_Ord(struct GeneratorC_Generator *gen, struct Ast_RExpression *e) {
	switch (O7_REF(O7_REF(e)->type)->_._.id) {
	case 4:
	case 10:
		TextGenerator_Str(&(*gen)._, 11, (o7_char *)"(o7_int_t)");
		Factor(&(*gen), e);
		break;
	case 2:
		if ((o7_is(e, &Ast_Designator__s_tag)) && (o7_cmp(O7_REF((*gen).opt)->varInit, GeneratorC_VarInitUndefined_cnst) == 0)) {
			TextGenerator_Str(&(*gen)._, 17, (o7_char *)"(o7_int_t)o7_bl(");
			Expression(&(*gen), e);
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		} else {
			TextGenerator_Str(&(*gen)._, 11, (o7_char *)"(o7_int_t)");
			Factor(&(*gen), e);
		}
		break;
	case 7:
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_sti(");
		Expression(&(*gen), e);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		break;
	default:
		o7_case_fail(O7_REF(O7_REF(e)->type)->_._.id);
		break;
	}
}

static void Expression_Call_Predefined_Inc(struct GeneratorC_Generator *gen, struct Ast_RExpression *e1, struct Ast_RParameter *p2) {
	Expression(&(*gen), e1);
	if (o7_bl(O7_REF((*gen).opt)->checkArith)) {
		TextGenerator_Str(&(*gen)._, 11, (o7_char *)" = o7_add(");
		Expression(&(*gen), e1);
		if (p2 == NULL) {
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)", 1)");
		} else {
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
			Expression(&(*gen), O7_REF(p2)->expr);
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		}
	} else if (p2 == NULL) {
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)"++");
	} else {
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)" += ");
		Expression(&(*gen), O7_REF(p2)->expr);
	}
}

static void Expression_Call_Predefined_Dec(struct GeneratorC_Generator *gen, struct Ast_RExpression *e1, struct Ast_RParameter *p2) {
	Expression(&(*gen), e1);
	if (o7_bl(O7_REF((*gen).opt)->checkArith)) {
		TextGenerator_Str(&(*gen)._, 11, (o7_char *)" = o7_sub(");
		Expression(&(*gen), e1);
		if (p2 == NULL) {
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)", 1)");
		} else {
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
			Expression(&(*gen), O7_REF(p2)->expr);
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		}
	} else if (p2 == NULL) {
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)"--");
	} else {
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)" -= ");
		Expression(&(*gen), O7_REF(p2)->expr);
	}
}

static void Expression_Call_Predefined_Assert(struct GeneratorC_Generator *gen, struct Ast_RExpression *e) {
	o7_bool c11Assert;
	o7_char buf[5];
	memset(&buf, 0, sizeof(buf));

	c11Assert = (0 > 1);
	if ((O7_REF(e)->value_ != NULL) && (O7_REF(e)->value_ != &Ast_ExprBooleanGet((0 > 1))->_) && !(!!( (1u << Ast_ExprPointerTouch_cnst) & O7_REF(e)->properties))) {
		if (o7_cmp(O7_REF((*gen).opt)->std, GeneratorC_IsoC11_cnst) >= 0) {
			c11Assert = (0 < 1);
			TextGenerator_Str(&(*gen)._, 15, (o7_char *)"static_assert(");
		} else {
			TextGenerator_Str(&(*gen)._, 18, (o7_char *)"O7_STATIC_ASSERT(");
		}
	} else if (o7_bl(O7_REF((*gen).opt)->o7Assert)) {
		TextGenerator_Str(&(*gen)._, 11, (o7_char *)"O7_ASSERT(");
	} else {
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"assert(");
	}
	CheckExpr(&(*gen), e);
	if (c11Assert) {
		buf[0] = (o7_char)',';
		buf[1] = (o7_char)' ';
		buf[2] = (o7_char)'"';
		buf[3] = (o7_char)'"';
		buf[4] = (o7_char)')';
		TextGenerator_Str(&(*gen)._, 5, buf);
	} else {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void Expression_Call_Predefined(struct GeneratorC_Generator *gen, struct Ast_ExprCall__s *call) {
	struct Ast_RExpression *e1;
	struct Ast_RParameter *p2;

	e1 = O7_REF(O7_REF(call)->params)->expr;
	p2 = O7_REF(O7_REF(call)->params)->next;
	switch (O7_REF(O7_REF(O7_REF(call)->designator)->decl)->_.id) {
	case 200:
		if (o7_cmp(O7_REF(O7_REF(call)->_._.type)->_._.id, Ast_IdInteger_cnst) == 0) {
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)"abs(");
		} else if (o7_cmp(O7_REF(O7_REF(call)->_._.type)->_._.id, Ast_IdLongInt_cnst) == 0) {
			TextGenerator_Str(&(*gen)._, 9, (o7_char *)"O7_LABS(");
		} else {
			TextGenerator_Str(&(*gen)._, 6, (o7_char *)"fabs(");
		}
		Expression(&(*gen), e1);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		break;
	case 219:
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x28");
		Factor(&(*gen), e1);
		TextGenerator_Str(&(*gen)._, 11, (o7_char *)" % 2 == 1)");
		break;
	case 214:
		Expression_Call_Predefined_Len(&(*gen), e1);
		break;
	case 217:
		Expression_Call_Predefined_LeftShift(&(*gen), e1, O7_REF(p2)->expr);
		break;
	case 201:
		Expression_Call_Predefined_ArithmeticRightShift(&(*gen), e1, O7_REF(p2)->expr);
		break;
	case 224:
		Expression_Call_Predefined_Rotate(&(*gen), e1, O7_REF(p2)->expr);
		break;
	case 209:
		TextGenerator_Str(&(*gen)._, 10, (o7_char *)"o7_floor(");
		Expression(&(*gen), e1);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		break;
	case 210:
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_flt(");
		Expression(&(*gen), e1);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		break;
	case 220:
		Expression_Call_Predefined_Ord(&(*gen), e1);
		break;
	case 206:
		if (o7_bl(O7_REF((*gen).opt)->checkArith) && (O7_REF(e1)->value_ == NULL)) {
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_chr(");
			Expression(&(*gen), e1);
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		} else {
			TextGenerator_Str(&(*gen)._, 10, (o7_char *)"(o7_char)");
			Factor(&(*gen), e1);
		}
		break;
	case 211:
		Expression_Call_Predefined_Inc(&(*gen), e1, p2);
		break;
	case 207:
		Expression_Call_Predefined_Dec(&(*gen), e1, p2);
		break;
	case 212:
		Expression(&(*gen), e1);
		TextGenerator_Str(&(*gen)._, 11, (o7_char *)" |= 1u << ");
		Factor(&(*gen), O7_REF(p2)->expr);
		break;
	case 208:
		Expression(&(*gen), e1);
		TextGenerator_Str(&(*gen)._, 13, (o7_char *)" &= ~(1u << ");
		Factor(&(*gen), O7_REF(p2)->expr);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		break;
	case 218:
		Expression_Call_Predefined_New(&(*gen), e1);
		break;
	case 202:
		Expression_Call_Predefined_Assert(&(*gen), e1);
		break;
	case 221:
		TextGenerator_Str(&(*gen)._, 11, (o7_char *)"o7_ldexp(&");
		Expression(&(*gen), e1);
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
		Expression(&(*gen), O7_REF(p2)->expr);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		break;
	case 226:
		TextGenerator_Str(&(*gen)._, 11, (o7_char *)"o7_frexp(&");
		Expression(&(*gen), e1);
		TextGenerator_Str(&(*gen)._, 4, (o7_char *)", &");
		Expression(&(*gen), O7_REF(p2)->expr);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		break;
	default:
		o7_case_fail(O7_REF(O7_REF(O7_REF(call)->designator)->decl)->_.id);
		break;
	}
}

static void Expression_Call_ActualParam(struct GeneratorC_Generator *gen, struct Ast_RParameter **p, struct Ast_RDeclaration **fp);
static o7_int_t Expression_Call_ActualParam_ArrayDeep(struct Ast_RType *t) {
	o7_int_t d;

	d = 0;
	while (o7_cmp(O7_REF(t)->_._.id, Ast_IdArray_cnst) == 0) {
		t = O7_REF(t)->_.type;
		d = o7_add(d, 1);
	}
	return d;
}

static void Expression_Call_ActualParam(struct GeneratorC_Generator *gen, struct Ast_RParameter **p, struct Ast_RDeclaration **fp) {
	struct Ast_RType *t;
	o7_int_t i, j, dist;
	o7_bool paramOut;

	t = O7_REF((*fp))->type;
	if ((o7_cmp(O7_REF(t)->_._.id, Ast_IdByte_cnst) == 0) && (o7_in(O7_REF(O7_REF(O7_REF((*p))->expr)->type)->_._.id, ((1u << Ast_IdInteger_cnst) | (1u << Ast_IdLongInt_cnst)))) && o7_bl(O7_REF((*gen).opt)->checkArith) && (O7_REF(O7_REF((*p))->expr)->value_ == NULL)) {
		if (o7_cmp(O7_REF(O7_REF(O7_REF((*p))->expr)->type)->_._.id, Ast_IdInteger_cnst) == 0) {
			TextGenerator_Str(&(*gen)._, 9, (o7_char *)"o7_byte(");
		} else {
			TextGenerator_Str(&(*gen)._, 10, (o7_char *)"o7_lbyte(");
		}
		Expression(&(*gen), O7_REF((*p))->expr);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	} else {
		j = 1;
		if (o7_cmp(O7_REF(O7_REF((*fp))->type)->_._.id, Ast_IdChar_cnst) != 0) {
			i =  - 1;
			t = O7_REF(O7_REF((*p))->expr)->type;
			while ((o7_cmp(O7_REF(t)->_._.id, Ast_IdArray_cnst) == 0) && (O7_GUARD(Ast_RArray, &O7_REF((*fp))->type)->count == NULL)) {
				if ((i ==  - 1) && (o7_is(O7_REF((*p))->expr, &Ast_Designator__s_tag))) {
					i = o7_sub(Expression_Call_ActualParam_ArrayDeep(O7_REF(O7_GUARD(Ast_Designator__s, &O7_REF((*p))->expr)->decl)->type), Expression_Call_ActualParam_ArrayDeep(O7_REF((*fp))->type));
					if (!(o7_is(O7_GUARD(Ast_Designator__s, &O7_REF((*p))->expr)->decl, &Ast_RFormalParam_tag))) {
						j = Expression_Call_ActualParam_ArrayDeep(O7_GUARD(Ast_Designator__s, &O7_REF((*p))->expr)->_._.type);
					}
				}
				if (O7_GUARD(Ast_RArray, &t)->count != NULL) {
					Expression(&(*gen), O7_GUARD(Ast_RArray, &t)->count);
				} else {
					Name(&(*gen), O7_GUARD(Ast_Designator__s, &O7_REF((*p))->expr)->decl);
					TextGenerator_Str(&(*gen)._, 5, (o7_char *)"_len");
					TextGenerator_Int(&(*gen)._, i);
				}
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
				i = o7_add(i, 1);
				t = O7_REF(t)->_.type;
			}
			t = O7_REF((*fp))->type;
		}
		dist = o7_int(O7_REF((*p))->distance);
		paramOut = !!( (1u << Ast_ParamOut_cnst) & O7_GUARD(Ast_RFormalParam, &(*fp))->access);
		if ((paramOut && !(o7_is(t, &Ast_RArray_tag))) || (o7_is(t, &Ast_RRecord_tag)) || (o7_cmp(O7_REF(t)->_._.id, Ast_IdPointer_cnst) == 0) && (0 < dist) && !o7_bl(O7_REF((*gen).opt)->plan9)) {
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x26");
		}
		O7_REF((*gen).opt)->lastSelectorDereference = (0 > 1);
		O7_REF((*gen).opt)->expectArray = o7_cmp(O7_REF(O7_REF((*fp))->type)->_._.id, Ast_IdArray_cnst) == 0;
		if (paramOut) {
			Expression(&(*gen), O7_REF((*p))->expr);
		} else {
			CheckExpr(&(*gen), O7_REF((*p))->expr);
		}
		O7_REF((*gen).opt)->expectArray = (0 > 1);

		if (!o7_bl(O7_REF((*gen).opt)->vla)) {
			while (j > 1) {
				j = o7_sub(j, 1);
				TextGenerator_Str(&(*gen)._, 4, (o7_char *)"[0]");
			}
		}

		if ((dist > 0) && !o7_bl(O7_REF((*gen).opt)->plan9)) {
			if (o7_cmp(O7_REF(t)->_._.id, Ast_IdPointer_cnst) == 0) {
				dist = o7_sub(dist, 1);
				TextGenerator_Str(&(*gen)._, 4, (o7_char *)"->_");
			}
			while (dist > 0) {
				dist = o7_sub(dist, 1);
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)"._");
			}
		}

		t = O7_REF(O7_REF((*p))->expr)->type;
		if ((o7_cmp(O7_REF(t)->_._.id, Ast_IdRecord_cnst) == 0) && (!o7_bl(O7_REF((*gen).opt)->skipUnusedTag) || Ast_IsNeedTag(O7_GUARD(Ast_RFormalParam, &(*fp))))) {
			if (o7_bl(O7_REF((*gen).opt)->lastSelectorDereference)) {
				TextGenerator_Str(&(*gen)._, 7, (o7_char *)", NULL");
			} else {
				if ((o7_is(O7_GUARD(Ast_Designator__s, &O7_REF((*p))->expr)->decl, &Ast_RFormalParam_tag)) && (O7_GUARD(Ast_Designator__s, &O7_REF((*p))->expr)->sel == NULL)) {
					TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
					Name(&(*gen), O7_GUARD(Ast_Designator__s, &O7_REF((*p))->expr)->decl);
				} else {
					TextGenerator_Str(&(*gen)._, 4, (o7_char *)", &");
					GlobalName(&(*gen), &t->_);
				}
				TextGenerator_Str(&(*gen)._, 5, (o7_char *)"_tag");
			}
		}
	}

	(*p) = O7_REF((*p))->next;
	(*fp) = O7_REF((*fp))->next;
}

static void Expression_Call(struct GeneratorC_Generator *gen, struct Ast_ExprCall__s *call) {
	struct Ast_RParameter *p;
	struct Ast_RDeclaration *fp;

	if (o7_is(O7_REF(O7_REF(call)->designator)->decl, &Ast_PredefinedProcedure__s_tag)) {
		Expression_Call_Predefined(&(*gen), call);
	} else {
		Designator(&(*gen), O7_REF(call)->designator);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x28");
		p = O7_REF(call)->params;
		fp = (&(O7_GUARD(Ast_RProcType, &O7_REF(O7_REF(call)->designator)->_._.type)->params)->_._);
		if (p != NULL) {
			Expression_Call_ActualParam(&(*gen), &p, &fp);
			while (p != NULL) {
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
				Expression_Call_ActualParam(&(*gen), &p, &fp);
			}
		}
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void Expression_Relation(struct GeneratorC_Generator *gen, struct Ast_ExprRelation__s *rel);
static void Expression_Relation_Simple(struct GeneratorC_Generator *gen, struct Ast_ExprRelation__s *rel, o7_int_t str_len0, o7_char str[/*len0*/]);
static void Expression_Relation_Simple_Expr(struct GeneratorC_Generator *gen, struct Ast_RExpression *e, o7_int_t dist) {
	o7_bool brace;

	brace = (o7_in(O7_REF(O7_REF(e)->type)->_._.id, ((1u << Ast_IdSet_cnst) | (1u << Ast_IdBoolean_cnst)))) && !(o7_is(e, &Ast_RFactor_tag));
	if (brace) {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x28");
	} else if ((dist > 0) && (o7_cmp(O7_REF(O7_REF(e)->type)->_._.id, Ast_IdPointer_cnst) == 0) && !o7_bl(O7_REF((*gen).opt)->plan9)) {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x26");
	}
	Expression(&(*gen), e);
	if ((dist > 0) && !o7_bl(O7_REF((*gen).opt)->plan9)) {
		if (o7_cmp(O7_REF(O7_REF(e)->type)->_._.id, Ast_IdPointer_cnst) == 0) {
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

static void Expression_Relation_Simple_Len(struct GeneratorC_Generator *gen, struct Ast_RExpression *e) {
	struct Ast_Designator__s *des;

	if (O7_GUARD(Ast_RArray, &O7_REF(e)->type)->count != NULL) {
		Expression(&(*gen), O7_GUARD(Ast_RArray, &O7_REF(e)->type)->count);
	} else {
		des = O7_GUARD(Ast_Designator__s, &e);
		ArrayDeclLen(&(*gen), O7_REF(des)->_._.type, O7_REF(des)->decl, O7_REF(des)->sel,  - 1);
	}
}

static o7_bool Expression_Relation_Simple_IsArrayAndNotChar(struct Ast_RExpression *e) {
	return (o7_cmp(O7_REF(O7_REF(e)->type)->_._.id, Ast_IdArray_cnst) == 0) && ((O7_REF(e)->value_ == NULL) || !o7_bl(O7_GUARD(Ast_ExprString__s, &O7_REF(e)->value_)->asChar));
}

static void Expression_Relation_Simple(struct GeneratorC_Generator *gen, struct Ast_ExprRelation__s *rel, o7_int_t str_len0, o7_char str[/*len0*/]) {
	o7_bool notChar0, notChar1;

	notChar0 = Expression_Relation_Simple_IsArrayAndNotChar(O7_REF(rel)->exprs[0]);
	if (notChar0 || Expression_Relation_Simple_IsArrayAndNotChar(O7_REF(rel)->exprs[1])) {
		if (O7_REF(rel)->_.value_ != NULL) {
			Expression(&(*gen), &O7_REF(rel)->_.value_->_);
		} else {
			notChar1 = !notChar0 || Expression_Relation_Simple_IsArrayAndNotChar(O7_REF(rel)->exprs[1]);
			if (notChar0 == notChar1) {
				O7_ASSERT(notChar0);
				TextGenerator_Str(&(*gen)._, 11, (o7_char *)"o7_strcmp(");
			} else if (notChar1) {
				TextGenerator_Str(&(*gen)._, 13, (o7_char *)"o7_chstrcmp(");
			} else {
				O7_ASSERT(notChar0);
				TextGenerator_Str(&(*gen)._, 13, (o7_char *)"o7_strchcmp(");
			}
			if (notChar0) {
				Expression_Relation_Simple_Len(&(*gen), O7_REF(rel)->exprs[0]);
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
			}
			Expression_Relation_Simple_Expr(&(*gen), O7_REF(rel)->exprs[0], o7_sub(0, O7_REF(rel)->distance));

			TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");

			if (notChar1) {
				Expression_Relation_Simple_Len(&(*gen), O7_REF(rel)->exprs[1]);
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
			}
			Expression_Relation_Simple_Expr(&(*gen), O7_REF(rel)->exprs[1], o7_int(O7_REF(rel)->distance));

			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
			TextGenerator_Str(&(*gen)._, str_len0, str);
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x30");
		}
	} else if ((o7_cmp(O7_REF((*gen).opt)->varInit, GeneratorC_VarInitUndefined_cnst) == 0) && (O7_REF(rel)->_.value_ == NULL) && (o7_in(O7_REF(O7_REF(O7_REF(rel)->exprs[0])->type)->_._.id, ((1u << Ast_IdInteger_cnst) | (1u << Ast_IdLongInt_cnst)))) && (IsMayNotInited(O7_REF(rel)->exprs[0]) || IsMayNotInited(O7_REF(rel)->exprs[1]))) {
		if (o7_cmp(O7_REF(O7_REF(O7_REF(rel)->exprs[0])->type)->_._.id, Ast_IdInteger_cnst) == 0) {
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_cmp(");
		} else {
			TextGenerator_Str(&(*gen)._, 9, (o7_char *)"o7_lcmp(");
		}
		Expression_Relation_Simple_Expr(&(*gen), O7_REF(rel)->exprs[0], o7_sub(0, O7_REF(rel)->distance));
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
		Expression_Relation_Simple_Expr(&(*gen), O7_REF(rel)->exprs[1], o7_int(O7_REF(rel)->distance));
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		TextGenerator_Str(&(*gen)._, str_len0, str);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x30");
	} else {
		Expression_Relation_Simple_Expr(&(*gen), O7_REF(rel)->exprs[0], o7_sub(0, O7_REF(rel)->distance));
		TextGenerator_Str(&(*gen)._, str_len0, str);
		Expression_Relation_Simple_Expr(&(*gen), O7_REF(rel)->exprs[1], o7_int(O7_REF(rel)->distance));
	}
}

static void Expression_Relation_In(struct GeneratorC_Generator *gen, struct Ast_ExprRelation__s *rel) {
	if ((O7_REF(rel)->_.value_ == NULL) && (O7_REF(O7_REF(rel)->exprs[0])->value_ != NULL) && (o7_in(O7_GUARD(Ast_RExprInteger, &O7_REF(O7_REF(rel)->exprs[0])->value_)->int_, O7_SET(0, TypesLimits_SetMax_cnst)))) {
		TextGenerator_Str(&(*gen)._, 4, (o7_char *)"!!(");
		TextGenerator_Str(&(*gen)._, 9, (o7_char *)" (1u << ");
		Factor(&(*gen), O7_REF(rel)->exprs[0]);
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)") & ");
		Factor(&(*gen), O7_REF(rel)->exprs[1]);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	} else {
		if (O7_REF(rel)->_.value_ != NULL) {
			TextGenerator_Str(&(*gen)._, 7, (o7_char *)"O7_IN(");
		} else {
			TextGenerator_Str(&(*gen)._, 7, (o7_char *)"o7_in(");
		}
		Expression(&(*gen), O7_REF(rel)->exprs[0]);
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
		Expression(&(*gen), O7_REF(rel)->exprs[1]);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void Expression_Relation(struct GeneratorC_Generator *gen, struct Ast_ExprRelation__s *rel) {
	switch (O7_REF(rel)->relation) {
	case 11:
		Expression_Relation_Simple(&(*gen), rel, 5, (o7_char *)" == ");
		break;
	case 12:
		Expression_Relation_Simple(&(*gen), rel, 5, (o7_char *)" != ");
		break;
	case 13:
		Expression_Relation_Simple(&(*gen), rel, 4, (o7_char *)" < ");
		break;
	case 14:
		Expression_Relation_Simple(&(*gen), rel, 5, (o7_char *)" <= ");
		break;
	case 15:
		Expression_Relation_Simple(&(*gen), rel, 4, (o7_char *)" > ");
		break;
	case 16:
		Expression_Relation_Simple(&(*gen), rel, 5, (o7_char *)" >= ");
		break;
	case 17:
		Expression_Relation_In(&(*gen), rel);
		break;
	default:
		o7_case_fail(O7_REF(rel)->relation);
		break;
	}
}

static void Expression_Sum(struct GeneratorC_Generator *gen, struct Ast_RExprSum *sum);
static o7_int_t Expression_Sum_CountSignChanges(struct Ast_RExprSum *sum) {
	o7_int_t i;

	i = 0;
	if (sum != NULL) {
		while (O7_REF(sum)->next != NULL) {
			i = o7_add(i, (o7_int_t)(o7_cmp(O7_REF(sum)->add, O7_REF(O7_REF(sum)->next)->add) != 0));
			sum = O7_REF(sum)->next;
		}
	}
	return i;
}

static void Expression_Sum(struct GeneratorC_Generator *gen, struct Ast_RExprSum *sum) {
	o7_int_t i;

	if (o7_in(O7_REF(O7_REF(sum)->_.type)->_._.id, Ast_Sets_cnst)) {
		i = Expression_Sum_CountSignChanges(O7_REF(sum)->next);
		TextGenerator_CharFill(&(*gen)._, (o7_char)'(', i);
		if (o7_cmp(O7_REF(sum)->add, Ast_Minus_cnst) == 0) {
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)" ~");
		}
		CheckExpr(&(*gen), O7_REF(sum)->term);
		sum = O7_REF(sum)->next;
		while (sum != NULL) {
			O7_ASSERT(o7_in(O7_REF(O7_REF(sum)->_.type)->_._.id, Ast_Sets_cnst));
			if (o7_cmp(O7_REF(sum)->add, Ast_Minus_cnst) == 0) {
				TextGenerator_Str(&(*gen)._, 5, (o7_char *)" & ~");
			} else {
				O7_ASSERT(o7_cmp(O7_REF(sum)->add, Ast_Plus_cnst) == 0);
				TextGenerator_Str(&(*gen)._, 4, (o7_char *)" | ");
			}
			CheckExpr(&(*gen), O7_REF(sum)->term);
			if ((O7_REF(sum)->next != NULL) && (o7_cmp(O7_REF(O7_REF(sum)->next)->add, O7_REF(sum)->add) != 0)) {
				TextGenerator_Char(&(*gen)._, (o7_char)')');
			}
			sum = O7_REF(sum)->next;
		}
	} else if (o7_cmp(O7_REF(O7_REF(sum)->_.type)->_._.id, Ast_IdBoolean_cnst) == 0) {
		CheckExpr(&(*gen), O7_REF(sum)->term);
		sum = O7_REF(sum)->next;
		while (sum != NULL) {
			O7_ASSERT(o7_cmp(O7_REF(O7_REF(sum)->_.type)->_._.id, Ast_IdBoolean_cnst) == 0);
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)" || ");
			CheckExpr(&(*gen), O7_REF(sum)->term);
			sum = O7_REF(sum)->next;
		}
	} else {
		do {
			O7_ASSERT(o7_in(O7_REF(O7_REF(sum)->_.type)->_._.id, ((1u << Ast_IdInteger_cnst) | (1u << Ast_IdLongInt_cnst) | (1u << Ast_IdReal_cnst) | (1u << Ast_IdReal32_cnst))));
			if (o7_cmp(O7_REF(sum)->add, Ast_Minus_cnst) == 0) {
				TextGenerator_Str(&(*gen)._, 4, (o7_char *)" - ");
			} else if (o7_cmp(O7_REF(sum)->add, Ast_Plus_cnst) == 0) {
				TextGenerator_Str(&(*gen)._, 4, (o7_char *)" + ");
			}
			CheckExpr(&(*gen), O7_REF(sum)->term);
			sum = O7_REF(sum)->next;
		} while (!(sum == NULL));
	}
}

static void Expression_SumCheck(struct GeneratorC_Generator *gen, struct Ast_RExprSum *sum);
static void Expression_SumCheck_GenArrOfAddOrSub(struct GeneratorC_Generator *gen, o7_int_t arr_len0, struct Ast_RExprSum *arr[/*len0*/], o7_int_t last, o7_int_t add_len0, o7_char add[/*len0*/], o7_int_t sub_len0, o7_char sub[/*len0*/]) {
	o7_int_t i;

	i = last;
	while (i > 0) {
		switch (O7_REF(arr[o7_ind(arr_len0, i)])->add) {
		case 2:
			TextGenerator_Str(&(*gen)._, sub_len0, sub);
			break;
		case 1:
			TextGenerator_Str(&(*gen)._, add_len0, add);
			break;
		default:
			o7_case_fail(O7_REF(arr[o7_ind(arr_len0, i)])->add);
			break;
		}
		i = o7_sub(i, 1);
	}
	if (o7_cmp(O7_REF(arr[0])->add, Scanner_Minus_cnst) == 0) {
		TextGenerator_Str(&(*gen)._, sub_len0, sub);
		TextGenerator_Str(&(*gen)._, 4, (o7_char *)"0, ");
		Expression(&(*gen), O7_REF(arr[0])->term);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	} else {
		Expression(&(*gen), O7_REF(arr[0])->term);
	}
}

static void Expression_SumCheck(struct GeneratorC_Generator *gen, struct Ast_RExprSum *sum) {
	struct Ast_RExprSum *arr[TranslatorLimits_TermsInSum_cnst];
	o7_int_t i, last;
	memset(&arr, 0, sizeof(arr));

	last =  - 1;
	do {
		last = o7_add(last, 1);
		arr[o7_ind(TranslatorLimits_TermsInSum_cnst, last)] = sum;
		sum = O7_REF(sum)->next;
	} while (!(sum == NULL));
	switch (O7_REF(O7_REF(arr[0])->_.type)->_._.id) {
	case 0:
		Expression_SumCheck_GenArrOfAddOrSub(&(*gen), TranslatorLimits_TermsInSum_cnst, arr, last, 8, (o7_char *)"o7_add(", 8, (o7_char *)"o7_sub(");
		break;
	case 1:
		Expression_SumCheck_GenArrOfAddOrSub(&(*gen), TranslatorLimits_TermsInSum_cnst, arr, last, 9, (o7_char *)"o7_ladd(", 9, (o7_char *)"o7_lsub(");
		break;
	case 5:
		Expression_SumCheck_GenArrOfAddOrSub(&(*gen), TranslatorLimits_TermsInSum_cnst, arr, last, 9, (o7_char *)"o7_fadd(", 9, (o7_char *)"o7_fsub(");
		break;
	case 6:
		Expression_SumCheck_GenArrOfAddOrSub(&(*gen), TranslatorLimits_TermsInSum_cnst, arr, last, 10, (o7_char *)"o7_faddf(", 10, (o7_char *)"o7_fsubf(");
		break;
	default:
		o7_case_fail(O7_REF(O7_REF(arr[0])->_.type)->_._.id);
		break;
	}
	i = 0;
	while (i < last) {
		i = o7_add(i, 1);
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
		Expression(&(*gen), O7_REF(arr[o7_ind(TranslatorLimits_TermsInSum_cnst, i)])->term);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void Expression_Term(struct GeneratorC_Generator *gen, struct Ast_ExprTerm__s *term) {
	do {
		CheckExpr(&(*gen), &O7_REF(term)->factor->_);
		switch (O7_REF(term)->mult) {
		case 19:
			if (o7_in(O7_REF(O7_REF(term)->_.type)->_._.id, Ast_Sets_cnst)) {
				TextGenerator_Str(&(*gen)._, 4, (o7_char *)" & ");
			} else {
				TextGenerator_Str(&(*gen)._, 4, (o7_char *)" * ");
			}
			break;
		case 20:
		case 22:
			if (o7_in(O7_REF(O7_REF(term)->_.type)->_._.id, Ast_Sets_cnst)) {
				O7_ASSERT(o7_cmp(O7_REF(term)->mult, Scanner_Slash_cnst) == 0);
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
			o7_case_fail(O7_REF(term)->mult);
			break;
		}
		if (o7_is(O7_REF(term)->expr, &Ast_ExprTerm__s_tag)) {
			term = O7_GUARD(Ast_ExprTerm__s, &O7_REF(term)->expr);
		} else {
			CheckExpr(&(*gen), O7_REF(term)->expr);
			term = NULL;
		}
	} while (!(term == NULL));
}

static void Expression_TermCheck(struct GeneratorC_Generator *gen, struct Ast_ExprTerm__s *term) {
	struct Ast_ExprTerm__s *arr[TranslatorLimits_FactorsInTerm_cnst];
	o7_int_t i, last;
	memset(&arr, 0, sizeof(arr));

	arr[0] = term;
	i = 0;
	while (o7_is(O7_REF(term)->expr, &Ast_ExprTerm__s_tag)) {
		i = o7_add(i, 1);
		term = O7_GUARD(Ast_ExprTerm__s, &O7_REF(term)->expr);
		arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, i)] = term;
	}
	last = i;
	switch (O7_REF(O7_REF(term)->_.type)->_._.id) {
	case 0:
		while (i >= 0) {
			switch (O7_REF(arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, i)])->mult) {
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
				o7_case_fail(O7_REF(arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, i)])->mult);
				break;
			}
			i = o7_sub(i, 1);
		}
		break;
	case 1:
		while (i >= 0) {
			switch (O7_REF(arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, i)])->mult) {
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
				o7_case_fail(O7_REF(arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, i)])->mult);
				break;
			}
			i = o7_sub(i, 1);
		}
		break;
	case 5:
		while (i >= 0) {
			switch (O7_REF(arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, i)])->mult) {
			case 19:
				TextGenerator_Str(&(*gen)._, 9, (o7_char *)"o7_fmul(");
				break;
			case 20:
				TextGenerator_Str(&(*gen)._, 9, (o7_char *)"o7_fdiv(");
				break;
			default:
				o7_case_fail(O7_REF(arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, i)])->mult);
				break;
			}
			i = o7_sub(i, 1);
		}
		break;
	case 6:
		while (i >= 0) {
			switch (O7_REF(arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, i)])->mult) {
			case 19:
				TextGenerator_Str(&(*gen)._, 10, (o7_char *)"o7_fmulf(");
				break;
			case 20:
				TextGenerator_Str(&(*gen)._, 10, (o7_char *)"o7_fdivf(");
				break;
			default:
				o7_case_fail(O7_REF(arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, i)])->mult);
				break;
			}
			i = o7_sub(i, 1);
		}
		break;
	default:
		o7_case_fail(O7_REF(O7_REF(term)->_.type)->_._.id);
		break;
	}
	Expression(&(*gen), &O7_REF(arr[0])->factor->_);
	i = 0;
	while (i < last) {
		i = o7_add(i, 1);
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
		Expression(&(*gen), &O7_REF(arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, i)])->factor->_);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
	TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
	Expression(&(*gen), O7_REF(arr[o7_ind(TranslatorLimits_FactorsInTerm_cnst, last)])->expr);
	TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
}

static void Expression_Boolean(struct GeneratorC_Generator *gen, struct Ast_ExprBoolean__s *e) {
	if (o7_cmp(O7_REF((*gen).opt)->std, GeneratorC_IsoC90_cnst) == 0) {
		if (o7_bl(O7_REF(e)->bool_)) {
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)"(0 < 1)");
		} else {
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)"(0 > 1)");
		}
	} else {
		if (o7_bl(O7_REF(e)->bool_)) {
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)"true");
		} else {
			TextGenerator_Str(&(*gen)._, 6, (o7_char *)"false");
		}
	}
}

static void Expression_CString(struct GeneratorC_Generator *gen, struct Ast_ExprString__s *e);
static o7_char Expression_CString_ToHex(o7_int_t d) {
	O7_ASSERT(o7_in(d, O7_SET(0, 15)));
	if (d < 10) {
		d = o7_add(d, (o7_int_t)(o7_char)'0');
	} else {
		d = o7_add(d, (o7_int_t)(o7_char)'A' - 10);
	}
	return o7_chr(d);
}

static void Expression_CString(struct GeneratorC_Generator *gen, struct Ast_ExprString__s *e) {
	o7_char s[6];
	o7_char ch;
	struct StringStore_String w;
	memset(&s, 0, sizeof(s));
	StringStore_String_undef(&w);

	w = O7_REF(e)->string;
	if (o7_bl(O7_REF(e)->asChar) && !o7_bl(O7_REF((*gen).opt)->expectArray)) {
		ch = o7_chr(O7_REF(e)->_.int_);
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
			s[0] = Expression_CString_ToHex(o7_div(O7_REF(e)->_.int_, 16));
			s[1] = Expression_CString_ToHex(o7_mod(O7_REF(e)->_.int_, 16));
			s[2] = (o7_char)'u';
			TextGenerator_Data(&(*gen)._, 6, s, 0, 3);
		}
	} else {
		if (!o7_bl((*gen).insideSizeOf)) {
			TextGenerator_Str(&(*gen)._, 12, (o7_char *)"(o7_char *)");
		}
		if ((o7_cmp(w.ofs, 0) >= 0) && (O7_REF(w.block)->s[o7_ind(StringStore_BlockSize_cnst + 1, w.ofs)] == (o7_char)'"')) {
			TextGenerator_ScreeningString(&(*gen)._, &w);
		} else {
			s[0] = (o7_char)'"';
			s[1] = (o7_char)'\\';
			s[2] = (o7_char)'x';
			s[3] = Expression_CString_ToHex(o7_div(O7_REF(e)->_.int_, 16));
			s[4] = Expression_CString_ToHex(o7_mod(O7_REF(e)->_.int_, 16));
			s[5] = (o7_char)'"';
			TextGenerator_Data(&(*gen)._, 6, s, 0, 6);
		}
	}
}

static void Expression_ExprInt(struct GeneratorC_Generator *gen, o7_int_t int_) {
	if (int_ >= 0) {
		TextGenerator_Int(&(*gen)._, int_);
	} else {
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)"(-");
		TextGenerator_Int(&(*gen)._, o7_sub(0, int_));
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void Expression_ExprLongInt(struct GeneratorC_Generator *gen, o7_int_t int_) {
	O7_ASSERT((0 > 1));
	if (int_ >= 0) {
		TextGenerator_Int(&(*gen)._, int_);
	} else {
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)"(-");
		TextGenerator_Int(&(*gen)._, o7_sub(0, int_));
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void Expression_SetValue(struct GeneratorC_Generator *gen, struct Ast_ExprSetValue__s *set) {
	O7_ASSERT(O7_REF(set)->set[1] == 0);

	TextGenerator_Str(&(*gen)._, 3, (o7_char *)"0x");
	TextGenerator_Set(&(*gen)._, &O7_REF(set)->set[0]);
	TextGenerator_Char(&(*gen)._, (o7_char)'u');
}

static void Expression_Set(struct GeneratorC_Generator *gen, struct Ast_RExprSet *set);
static void Expression_Set_Item(struct GeneratorC_Generator *gen, struct Ast_RExprSet *set) {
	if (O7_REF(set)->exprs[0] == NULL) {
		TextGenerator_Char(&(*gen)._, (o7_char)'0');
	} else {
		if (O7_REF(set)->exprs[1] == NULL) {
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)"(1u << ");
			Factor(&(*gen), O7_REF(set)->exprs[0]);
		} else {
			if ((O7_REF(O7_REF(set)->exprs[0])->value_ == NULL) || (O7_REF(O7_REF(set)->exprs[1])->value_ == NULL)) {
				TextGenerator_Str(&(*gen)._, 8, (o7_char *)"o7_set(");
			} else {
				TextGenerator_Str(&(*gen)._, 8, (o7_char *)"O7_SET(");
			}
			Expression(&(*gen), O7_REF(set)->exprs[0]);
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
			Expression(&(*gen), O7_REF(set)->exprs[1]);
		}
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void Expression_Set(struct GeneratorC_Generator *gen, struct Ast_RExprSet *set) {
	if (O7_REF(set)->next == NULL) {
		Expression_Set_Item(&(*gen), set);
	} else {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x28");
		Expression_Set_Item(&(*gen), set);
		do {
			TextGenerator_Str(&(*gen)._, 4, (o7_char *)" | ");
			set = O7_REF(set)->next;
			Expression_Set_Item(&(*gen), set);
		} while (!(O7_REF(set)->next == NULL));
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void Expression_IsExtension(struct GeneratorC_Generator *gen, struct Ast_ExprIsExtension__s *is) {
	struct Ast_RDeclaration *decl;
	struct Ast_RType *extType;

	decl = O7_REF(O7_REF(is)->designator)->decl;
	extType = O7_REF(is)->extType;
	if (o7_cmp(O7_REF(O7_REF(O7_REF(is)->designator)->_._.type)->_._.id, Ast_IdPointer_cnst) == 0) {
		extType = O7_REF(extType)->_.type;
		O7_ASSERT(CheckStructName(&(*gen), O7_GUARD(Ast_RRecord, &extType)));
		TextGenerator_Str(&(*gen)._, 7, (o7_char *)"o7_is(");
		Expression(&(*gen), &O7_REF(is)->designator->_._);
		TextGenerator_Str(&(*gen)._, 4, (o7_char *)", &");
	} else {
		TextGenerator_Str(&(*gen)._, 9, (o7_char *)"o7_is_r(");
		GlobalName(&(*gen), decl);
		TextGenerator_Str(&(*gen)._, 7, (o7_char *)"_tag, ");
		GlobalName(&(*gen), decl);
		TextGenerator_Str(&(*gen)._, 4, (o7_char *)", &");
	}
	GlobalName(&(*gen), &extType->_);
	TextGenerator_Str(&(*gen)._, 6, (o7_char *)"_tag)");
}

static void Expression(struct GeneratorC_Generator *gen, struct Ast_RExpression *expr) {
	switch (O7_REF(expr)->_.id) {
	case 0:
		Expression_ExprInt(&(*gen), o7_int(O7_GUARD(Ast_RExprInteger, &expr)->int_));
		break;
	case 1:
		Expression_ExprLongInt(&(*gen), o7_int(O7_GUARD(Ast_RExprInteger, &expr)->int_));
		break;
	case 2:
		Expression_Boolean(&(*gen), O7_GUARD(Ast_ExprBoolean__s, &expr));
		break;
	case 5:
	case 6:
		if (StringStore_IsDefined(&O7_GUARD(Ast_ExprReal__s, &expr)->str)) {
			TextGenerator_String(&(*gen)._, &O7_GUARD(Ast_ExprReal__s, &expr)->str);
		} else {
			TextGenerator_Real(&(*gen)._, o7_dbl(O7_GUARD(Ast_ExprReal__s, &expr)->real));
		}
		break;
	case 15:
		Expression_CString(&(*gen), O7_GUARD(Ast_ExprString__s, &expr));
		break;
	case 7:
	case 8:
		if (o7_is(expr, &Ast_RExprSet_tag)) {
			Expression_Set(&(*gen), O7_GUARD(Ast_RExprSet, &expr));
		} else {
			Expression_SetValue(&(*gen), O7_GUARD(Ast_ExprSetValue__s, &expr));
		}
		break;
	case 25:
		Expression_Call(&(*gen), O7_GUARD(Ast_ExprCall__s, &expr));
		break;
	case 20:
		if ((O7_REF(expr)->value_ != NULL) && (o7_cmp(O7_REF(O7_REF(expr)->value_)->_._.id, Ast_IdString_cnst) == 0)) {
			Expression_CString(&(*gen), O7_GUARD(Ast_ExprString__s, &O7_REF(expr)->value_));
		} else {
			Designator(&(*gen), O7_GUARD(Ast_Designator__s, &expr));
		}
		break;
	case 21:
		Expression_Relation(&(*gen), O7_GUARD(Ast_ExprRelation__s, &expr));
		break;
	case 22:
		if (o7_bl(O7_REF((*gen).opt)->checkArith) && (o7_in(O7_REF(O7_REF(expr)->type)->_._.id, CheckableArithTypes_cnst)) && (O7_REF(expr)->value_ == NULL)) {
			Expression_SumCheck(&(*gen), O7_GUARD(Ast_RExprSum, &expr));
		} else {
			Expression_Sum(&(*gen), O7_GUARD(Ast_RExprSum, &expr));
		}
		break;
	case 23:
		if (o7_bl(O7_REF((*gen).opt)->checkArith) && (o7_in(O7_REF(O7_REF(expr)->type)->_._.id, CheckableArithTypes_cnst)) && (O7_REF(expr)->value_ == NULL)) {
			Expression_TermCheck(&(*gen), O7_GUARD(Ast_ExprTerm__s, &expr));
		} else if ((O7_REF(expr)->value_ != NULL) && (!!( (1u << Ast_ExprIntNegativeDividentTouch_cnst) & O7_REF(expr)->properties))) {
			Expression(&(*gen), &O7_REF(expr)->value_->_);
		} else {
			Expression_Term(&(*gen), O7_GUARD(Ast_ExprTerm__s, &expr));
		}
		break;
	case 24:
		if (o7_in(O7_REF(O7_REF(expr)->type)->_._.id, Ast_Sets_cnst)) {
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x7E");
			Expression(&(*gen), O7_GUARD(Ast_ExprNegate__s, &expr)->expr);
		} else {
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x21");
			CheckExpr(&(*gen), O7_GUARD(Ast_ExprNegate__s, &expr)->expr);
		}
		break;
	case 26:
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x28");
		Expression(&(*gen), O7_GUARD(Ast_ExprBraces__s, &expr)->expr);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		break;
	case 9:
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)"NULL");
		break;
	case 27:
		Expression_IsExtension(&(*gen), O7_GUARD(Ast_ExprIsExtension__s, &expr));
		break;
	default:
		o7_case_fail(O7_REF(expr)->_.id);
		break;
	}
}

static void Qualifier(struct GeneratorC_Generator *gen, struct Ast_RType *typ) {
	switch (O7_REF(typ)->_._.id) {
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
		if ((o7_cmp(O7_REF((*gen).opt)->std, GeneratorC_IsoC99_cnst) >= 0) && (o7_cmp(O7_REF((*gen).opt)->varInit, GeneratorC_VarInitUndefined_cnst) != 0)) {
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
		GlobalName(&(*gen), &typ->_);
		break;
	default:
		o7_case_fail(O7_REF(typ)->_._.id);
		break;
	}
}

static void Invert(struct GeneratorC_Generator *gen) {
	O7_REF((*gen).memout)->invert = !o7_bl(O7_REF((*gen).memout)->invert);
}

static void ProcHead(struct GeneratorC_Generator *gen, struct Ast_RProcType *proc);
static void ProcHead_Parameters(struct GeneratorC_Generator *gen, struct Ast_RProcType *proc);
static void ProcHead_Parameters_Par(struct GeneratorC_Generator *gen, struct Ast_RFormalParam *fp) {
	struct Ast_RType *t;
	o7_int_t i;

	i = 0;
	t = O7_REF(fp)->_._.type;
	while ((o7_cmp(O7_REF(t)->_._.id, Ast_IdArray_cnst) == 0) && (O7_GUARD(Ast_RArray, &t)->count == NULL)) {
		TextGenerator_Str(&(*gen)._, 10, (o7_char *)"o7_int_t ");
		Name(&(*gen), &fp->_._);
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)"_len");
		TextGenerator_Int(&(*gen)._, i);
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
		i = o7_add(i, 1);
		t = O7_REF(t)->_.type;
	}
	t = O7_REF(fp)->_._.type;
	declarator(&(*gen), &fp->_._, (0 > 1), (0 > 1), (0 > 1));
	if ((o7_cmp(O7_REF(t)->_._.id, Ast_IdRecord_cnst) == 0) && (!o7_bl(O7_REF((*gen).opt)->skipUnusedTag) || Ast_IsNeedTag(fp))) {
		TextGenerator_Str(&(*gen)._, 13, (o7_char *)", o7_tag_t *");
		Name(&(*gen), &fp->_._);
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)"_tag");
	}
}

static void ProcHead_Parameters(struct GeneratorC_Generator *gen, struct Ast_RProcType *proc) {
	struct Ast_RDeclaration *p;

	if (O7_REF(proc)->params == NULL) {
		TextGenerator_Str(&(*gen)._, 7, (o7_char *)"(void)");
	} else {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x28");
		p = (&(O7_REF(proc)->params)->_._);
		while (p != &O7_REF(proc)->end->_._) {
			ProcHead_Parameters_Par(&(*gen), O7_GUARD(Ast_RFormalParam, &p));
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
			p = O7_REF(p)->next;
		}
		ProcHead_Parameters_Par(&(*gen), O7_GUARD(Ast_RFormalParam, &p));
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void ProcHead(struct GeneratorC_Generator *gen, struct Ast_RProcType *proc) {
	ProcHead_Parameters(&(*gen), proc);
	Invert(&(*gen));
	type(&(*gen), NULL, O7_REF(proc)->_._._.type, (0 > 1), (0 > 1));
	MemWriteInvert(&(*O7_REF((*gen).memout)));
}

static void Declarator(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *decl, o7_bool typeDecl, o7_bool sameType, o7_bool global) {
	struct GeneratorC_Generator g;
	struct GeneratorC_MemoryOut *mo;
	GeneratorC_Generator_undef(&g);

	mo = PMemoryOutGet((*gen).opt);

	TextGenerator_Init(&g._, &mo->_);
	g.memout = mo;
	TextGenerator_SetTabs(&g._, &(*gen)._);
	g.module_ = (*gen).module_;
	g.interface_ = o7_bl((*gen).interface_);
	g.opt = (*gen).opt;

	if ((o7_is(decl, &Ast_RFormalParam_tag)) && ((!!( (1u << Ast_ParamOut_cnst) & O7_GUARD(Ast_RFormalParam, &decl)->access)) && !(o7_is(O7_REF(decl)->type, &Ast_RArray_tag)) || (o7_is(O7_REF(decl)->type, &Ast_RRecord_tag)))) {
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
		ProcHead(&g, O7_GUARD(Ast_RProcedure, &decl)->_.header);
	} else {
		O7_REF(mo)->invert = !o7_bl(O7_REF(mo)->invert);
		if (o7_is(decl, &Ast_RType_tag)) {
			type(&g, decl, O7_GUARD(Ast_RType, &decl), typeDecl, (0 > 1));
		} else {
			type(&g, decl, O7_REF(decl)->type, (0 > 1), sameType);
		}
	}

	MemWriteDirect(&(*gen), &(*O7_REF(mo)));

	PMemoryOutBack((*gen).opt, mo);
}

static void RecordUndefHeader(struct GeneratorC_Generator *gen, struct Ast_RRecord *rec, o7_bool interf) {
	if (o7_bl(O7_REF(rec)->_._._.mark) && !o7_bl(O7_REF((*gen).opt)->main_)) {
		TextGenerator_Str(&(*gen)._, 13, (o7_char *)"extern void ");
	} else {
		TextGenerator_Str(&(*gen)._, 13, (o7_char *)"static void ");
	}
	GlobalName(&(*gen), &rec->_._._);
	TextGenerator_Str(&(*gen)._, 15, (o7_char *)"_undef(struct ");
	GlobalName(&(*gen), &rec->_._._);
	if (interf) {
		TextGenerator_StrLn(&(*gen)._, 6, (o7_char *)" *r);");
	} else {
		TextGenerator_StrOpen(&(*gen)._, 7, (o7_char *)" *r) {");
	}
}

static void RecordRetainReleaseHeader(struct GeneratorC_Generator *gen, struct Ast_RRecord *rec, o7_bool interf, o7_int_t retrel_len0, o7_char retrel[/*len0*/]) {
	if (o7_bl(O7_REF(rec)->_._._.mark) && !o7_bl(O7_REF((*gen).opt)->main_)) {
		TextGenerator_Str(&(*gen)._, 13, (o7_char *)"extern void ");
	} else {
		TextGenerator_Str(&(*gen)._, 13, (o7_char *)"static void ");
	}
	GlobalName(&(*gen), &rec->_._._);
	TextGenerator_Str(&(*gen)._, retrel_len0, retrel);
	TextGenerator_Str(&(*gen)._, 9, (o7_char *)"(struct ");
	GlobalName(&(*gen), &rec->_._._);
	if (interf) {
		TextGenerator_StrLn(&(*gen)._, 6, (o7_char *)" *r);");
	} else {
		TextGenerator_StrOpen(&(*gen)._, 7, (o7_char *)" *r) {");
	}
}

static void RecordReleaseHeader(struct GeneratorC_Generator *gen, struct Ast_RRecord *rec, o7_bool interf) {
	RecordRetainReleaseHeader(&(*gen), rec, interf, 9, (o7_char *)"_release");
}

static void RecordRetainHeader(struct GeneratorC_Generator *gen, struct Ast_RRecord *rec, o7_bool interf) {
	RecordRetainReleaseHeader(&(*gen), rec, interf, 8, (o7_char *)"_retain");
}

static o7_bool IsArrayTypeSimpleUndef(struct Ast_RType *typ, o7_int_t *id, o7_int_t *deep) {
	(*deep) = 0;
	while (o7_cmp(O7_REF(typ)->_._.id, Ast_IdArray_cnst) == 0) {
		(*deep) = o7_add((*deep), 1);
		typ = O7_REF(typ)->_.type;
	}
	(*id) = o7_int(O7_REF(typ)->_._.id);
	return o7_in((*id), ((1u << Ast_IdReal_cnst) | (1u << Ast_IdReal32_cnst) | (1u << Ast_IdInteger_cnst) | (1u << Ast_IdLongInt_cnst) | (1u << Ast_IdBoolean_cnst)));
}

static void ArraySimpleUndef(struct GeneratorC_Generator *gen, o7_int_t arrTypeId, struct Ast_RDeclaration *d, o7_bool inRec) {
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
	Name(&(*gen), d);
	TextGenerator_Str(&(*gen)._, 3, (o7_char *)");");
}

static void RecordUndefCall(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *var_) {
	GlobalName(&(*gen), &O7_REF(var_)->type->_);
	TextGenerator_Str(&(*gen)._, 9, (o7_char *)"_undef(&");
	GlobalName(&(*gen), var_);
	TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
}

static struct Ast_RType *TypeForUndef(struct Ast_RType *t) {
	if ((o7_cmp(O7_REF(t)->_._.id, Ast_IdRecord_cnst) != 0) || (O7_REF(t)->_._.ext == NULL) || !o7_bl(O7_GUARD(RecExt__s, &O7_REF(t)->_._.ext)->undef)) {
		t = NULL;
	}
	return t;
}

static void RecordUndef(struct GeneratorC_Generator *gen, struct Ast_RRecord *rec);
static void RecordUndef_IteratorIfNeed(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *var_) {
	o7_int_t id = O7_INT_UNDEF, deep = O7_INT_UNDEF;

	while ((var_ != NULL) && ((o7_cmp(O7_REF(O7_REF(var_)->type)->_._.id, Ast_IdArray_cnst) != 0) || IsArrayTypeSimpleUndef(O7_REF(var_)->type, &id, &deep) || (TypeForUndef(O7_REF(O7_REF(var_)->type)->_.type) == NULL))) {
		var_ = O7_REF(var_)->next;
	}
	if (var_ != NULL) {
		TextGenerator_StrLn(&(*gen)._, 12, (o7_char *)"o7_int_t i;");
	}
}

static void RecordUndef_Memset(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *var_) {
	TextGenerator_Str(&(*gen)._, 12, (o7_char *)"memset(&r->");
	Name(&(*gen), var_);
	TextGenerator_Str(&(*gen)._, 16, (o7_char *)", 0, sizeof(r->");
	Name(&(*gen), var_);
	TextGenerator_StrLn(&(*gen)._, 4, (o7_char *)"));");
}

static void RecordUndef(struct GeneratorC_Generator *gen, struct Ast_RRecord *rec) {
	struct Ast_RDeclaration *var_;
	o7_int_t arrTypeId = O7_INT_UNDEF, arrDeep = O7_INT_UNDEF;
	struct Ast_RType *typeUndef;

	RecordUndefHeader(&(*gen), rec, (0 > 1));
	RecordUndef_IteratorIfNeed(&(*gen), &O7_REF(rec)->vars->_);
	if (O7_REF(rec)->base != NULL) {
		GlobalName(&(*gen), &O7_REF(rec)->base->_._._);
		if (!o7_bl(O7_REF((*gen).opt)->plan9)) {
			TextGenerator_StrLn(&(*gen)._, 15, (o7_char *)"_undef(&r->_);");
		} else {
			TextGenerator_StrLn(&(*gen)._, 11, (o7_char *)"_undef(r);");
		}
	}
	O7_GUARD(RecExt__s, &O7_REF(rec)->_._._._.ext)->undef = (0 < 1);
	var_ = (&(O7_REF(rec)->vars)->_);
	while (var_ != NULL) {
		if (!(o7_in(O7_REF(O7_REF(var_)->type)->_._.id, ((1u << Ast_IdArray_cnst) | (1u << Ast_IdRecord_cnst))))) {
			TextGenerator_Str(&(*gen)._, 4, (o7_char *)"r->");
			Name(&(*gen), var_);
			VarInit(&(*gen), var_, (0 < 1));
			TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x3B");
		} else if (o7_cmp(O7_REF(O7_REF(var_)->type)->_._.id, Ast_IdArray_cnst) == 0) {
			typeUndef = TypeForUndef(O7_REF(O7_REF(var_)->type)->_.type);
			if (IsArrayTypeSimpleUndef(O7_REF(var_)->type, &arrTypeId, &arrDeep)) {
				ArraySimpleUndef(&(*gen), o7_int(arrTypeId), var_, (0 < 1));
			} else if (typeUndef != NULL) {
				TextGenerator_Str(&(*gen)._, 27, (o7_char *)"for (i = 0; i < O7_LEN(r->");
				Name(&(*gen), var_);
				TextGenerator_StrOpen(&(*gen)._, 13, (o7_char *)"); i += 1) {");
				GlobalName(&(*gen), &typeUndef->_);
				TextGenerator_Str(&(*gen)._, 11, (o7_char *)"_undef(r->");
				Name(&(*gen), var_);
				TextGenerator_StrLn(&(*gen)._, 7, (o7_char *)" + i);");

				TextGenerator_StrLnClose(&(*gen)._, 2, (o7_char *)"\x7D");
			} else {
				RecordUndef_Memset(&(*gen), var_);
			}
		} else if ((o7_cmp(O7_REF(O7_REF(var_)->type)->_._.id, Ast_IdRecord_cnst) == 0) && (O7_REF(O7_REF(var_)->type)->_._.ext != NULL)) {
			GlobalName(&(*gen), &O7_REF(var_)->type->_);
			TextGenerator_Str(&(*gen)._, 12, (o7_char *)"_undef(&r->");
			Name(&(*gen), var_);
			TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
		} else {
			RecordUndef_Memset(&(*gen), var_);
		}
		var_ = O7_REF(var_)->next;
	}
	TextGenerator_StrLnClose(&(*gen)._, 2, (o7_char *)"\x7D");
}

static void RecordRetainRelease(struct GeneratorC_Generator *gen, struct Ast_RRecord *rec, o7_int_t retrel_len0, o7_char retrel[/*len0*/], o7_int_t retrelArray_len0, o7_char retrelArray[/*len0*/], o7_int_t retNull_len0, o7_char retNull[/*len0*/]);
static void RecordRetainRelease_IteratorIfNeed(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *var_) {
	while ((var_ != NULL) && !((o7_cmp(O7_REF(O7_REF(var_)->type)->_._.id, Ast_IdArray_cnst) == 0) && (o7_cmp(O7_REF(O7_REF(O7_REF(var_)->type)->_.type)->_._.id, Ast_IdRecord_cnst) == 0))) {
		var_ = O7_REF(var_)->next;
	}
	if (var_ != NULL) {
		TextGenerator_StrLn(&(*gen)._, 12, (o7_char *)"o7_int_t i;");
	}
}

static void RecordRetainRelease(struct GeneratorC_Generator *gen, struct Ast_RRecord *rec, o7_int_t retrel_len0, o7_char retrel[/*len0*/], o7_int_t retrelArray_len0, o7_char retrelArray[/*len0*/], o7_int_t retNull_len0, o7_char retNull[/*len0*/]) {
	struct Ast_RDeclaration *var_;

	RecordRetainReleaseHeader(&(*gen), rec, (0 > 1), retrel_len0, retrel);

	RecordRetainRelease_IteratorIfNeed(&(*gen), &O7_REF(rec)->vars->_);
	if (O7_REF(rec)->base != NULL) {
		GlobalName(&(*gen), &O7_REF(rec)->base->_._._);
		TextGenerator_Str(&(*gen)._, retrel_len0, retrel);
		if (!o7_bl(O7_REF((*gen).opt)->plan9)) {
			TextGenerator_StrLn(&(*gen)._, 9, (o7_char *)"(&r->_);");
		} else {
			TextGenerator_StrLn(&(*gen)._, 5, (o7_char *)"(r);");
		}
	}
	var_ = (&(O7_REF(rec)->vars)->_);
	while (var_ != NULL) {
		if (o7_cmp(O7_REF(O7_REF(var_)->type)->_._.id, Ast_IdArray_cnst) == 0) {
			if (o7_cmp(O7_REF(O7_REF(O7_REF(var_)->type)->_.type)->_._.id, Ast_IdPointer_cnst) == 0) {
				TextGenerator_Str(&(*gen)._, retrelArray_len0, retrelArray);
				Name(&(*gen), var_);
				TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
			} else if ((o7_cmp(O7_REF(O7_REF(O7_REF(var_)->type)->_.type)->_._.id, Ast_IdRecord_cnst) == 0) && (O7_REF(O7_REF(O7_REF(var_)->type)->_.type)->_._.ext != NULL) && o7_bl(O7_GUARD(RecExt__s, &O7_REF(O7_REF(O7_REF(var_)->type)->_.type)->_._.ext)->undef)) {
				TextGenerator_Str(&(*gen)._, 27, (o7_char *)"for (i = 0; i < O7_LEN(r->");
				Name(&(*gen), var_);
				TextGenerator_StrOpen(&(*gen)._, 13, (o7_char *)"); i += 1) {");
				GlobalName(&(*gen), &O7_REF(O7_REF(var_)->type)->_.type->_);
				TextGenerator_Str(&(*gen)._, retrel_len0, retrel);
				TextGenerator_Str(&(*gen)._, 5, (o7_char *)"(r->");
				Name(&(*gen), var_);
				TextGenerator_StrLn(&(*gen)._, 7, (o7_char *)" + i);");
				TextGenerator_StrLnClose(&(*gen)._, 2, (o7_char *)"\x7D");
			}
		} else if ((o7_cmp(O7_REF(O7_REF(var_)->type)->_._.id, Ast_IdRecord_cnst) == 0) && (O7_REF(O7_REF(var_)->type)->_._.ext != NULL)) {
			GlobalName(&(*gen), &O7_REF(var_)->type->_);
			TextGenerator_Str(&(*gen)._, retrel_len0, retrel);
			TextGenerator_Str(&(*gen)._, 6, (o7_char *)"(&r->");
			Name(&(*gen), var_);
			TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
		} else if (o7_cmp(O7_REF(O7_REF(var_)->type)->_._.id, Ast_IdPointer_cnst) == 0) {
			TextGenerator_Str(&(*gen)._, retNull_len0, retNull);
			TextGenerator_Str(&(*gen)._, 4, (o7_char *)"r->");
			Name(&(*gen), var_);
			TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
		}
		var_ = O7_REF(var_)->next;
	}
	TextGenerator_StrLnClose(&(*gen)._, 2, (o7_char *)"\x7D");
}

static void RecordRelease(struct GeneratorC_Generator *gen, struct Ast_RRecord *rec) {
	RecordRetainRelease(&(*gen), rec, 9, (o7_char *)"_release", 21, (o7_char *)"O7_RELEASE_ARRAY(r->", 10, (o7_char *)"O7_NULL(&");
}

static void RecordRetain(struct GeneratorC_Generator *gen, struct Ast_RRecord *rec) {
	RecordRetainRelease(&(*gen), rec, 8, (o7_char *)"_retain", 20, (o7_char *)"O7_RETAIN_ARRAY(r->", 11, (o7_char *)"o7_retain(");
}

static void EmptyLines(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *d) {
	if (o7_cmp(0, O7_REF(d)->_.emptyLines) < 0) {
		TextGenerator_Ln(&(*gen)._);
	}
}

static void Type(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *decl, struct Ast_RType *typ, o7_bool typeDecl, o7_bool sameType);
static void Type_Simple(struct GeneratorC_Generator *gen, o7_int_t str_len0, o7_char str[/*len0*/]) {
	TextGenerator_Str(&(*gen)._, str_len0, str);
	MemWriteInvert(&(*O7_REF((*gen).memout)));
}

static void Type_Record(struct GeneratorC_Generator *gen, struct Ast_RRecord *rec) {
	struct Ast_RDeclaration *v;

	O7_REF(rec)->_._._.module_ = O7_REF((*gen).module_)->bag;
	TextGenerator_Str(&(*gen)._, 8, (o7_char *)"struct ");
	if (CheckStructName(&(*gen), rec)) {
		GlobalName(&(*gen), &rec->_._._);
	}
	v = (&(O7_REF(rec)->vars)->_);
	if ((v == NULL) && (O7_REF(rec)->base == NULL) && !o7_bl(O7_REF((*gen).opt)->gnu)) {
		TextGenerator_Str(&(*gen)._, 20, (o7_char *)" { char nothing; } ");
	} else {
		TextGenerator_StrOpen(&(*gen)._, 3, (o7_char *)" {");

		if (O7_REF(rec)->base != NULL) {
			GlobalName(&(*gen), &O7_REF(rec)->base->_._._);
			if (o7_bl(O7_REF((*gen).opt)->plan9)) {
				TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x3B");
			} else {
				TextGenerator_StrLn(&(*gen)._, 4, (o7_char *)" _;");
			}
		}

		while (v != NULL) {
			EmptyLines(&(*gen), v);
			Declarator(&(*gen), v, (0 > 1), (0 > 1), (0 > 1));
			TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x3B");
			v = O7_REF(v)->next;
		}
		TextGenerator_StrClose(&(*gen)._, 3, (o7_char *)"} ");
	}
	MemWriteInvert(&(*O7_REF((*gen).memout)));
}

static void Type_Array(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *decl, struct Ast_RArray *arr, o7_bool sameType) {
	struct Ast_RType *t;
	o7_int_t i;

	t = O7_REF(arr)->_._._.type;
	MemWriteInvert(&(*O7_REF((*gen).memout)));
	if (O7_REF(arr)->count != NULL) {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x5B");
		Expression(&(*gen), O7_REF(arr)->count);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x5D");
	} else if (o7_bl(O7_REF((*gen).opt)->vla)) {
		i = 0;
		t = (&(arr)->_._);
		do {
			TextGenerator_Data(&(*gen)._, 9, (o7_char *)"[O7_VLA(", 0, o7_add(1, o7_mul((o7_int_t)o7_bl(O7_REF((*gen).opt)->vlaMark), 8)));
			Name(&(*gen), decl);
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)"_len");
			TextGenerator_Int(&(*gen)._, i);
			TextGenerator_Data(&(*gen)._, 3, (o7_char *)")]", (o7_int_t)!o7_bl(O7_REF((*gen).opt)->vlaMark), o7_sub(2, (o7_int_t)!o7_bl(O7_REF((*gen).opt)->vlaMark)));
			t = O7_REF(t)->_.type;
			i = o7_add(i, 1);
		} while (!(o7_cmp(O7_REF(t)->_._.id, Ast_IdArray_cnst) != 0));
	} else {
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"[/*len0");
		i = 0;
		while (o7_cmp(O7_REF(t)->_._.id, Ast_IdArray_cnst) == 0) {
			i = o7_add(i, 1);
			TextGenerator_Str(&(*gen)._, 6, (o7_char *)", len");
			TextGenerator_Int(&(*gen)._, i);
			t = O7_REF(t)->_.type;
		}
		TextGenerator_Str(&(*gen)._, 4, (o7_char *)"*/]");
	}
	Invert(&(*gen));
	Type(&(*gen), decl, t, (0 > 1), sameType);
}

static void Type(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *decl, struct Ast_RType *typ, o7_bool typeDecl, o7_bool sameType) {
	if (typ == NULL) {
		TextGenerator_Str(&(*gen)._, 6, (o7_char *)"void ");
		MemWriteInvert(&(*O7_REF((*gen).memout)));
	} else {
		if (!typeDecl && StringStore_IsDefined(&O7_REF(typ)->_.name)) {
			if (sameType) {
				if ((o7_is(typ, &Ast_RPointer_tag)) && StringStore_IsDefined(&O7_REF(O7_REF(typ)->_.type)->_.name)) {
					TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x2A");
				}
			} else {
				if ((o7_is(typ, &Ast_RPointer_tag)) && StringStore_IsDefined(&O7_REF(O7_REF(typ)->_.type)->_.name)) {
					TextGenerator_Str(&(*gen)._, 8, (o7_char *)"struct ");
					GlobalName(&(*gen), &O7_REF(typ)->_.type->_);
					TextGenerator_Str(&(*gen)._, 3, (o7_char *)" *");
				} else if (o7_is(typ, &Ast_RRecord_tag)) {
					TextGenerator_Str(&(*gen)._, 8, (o7_char *)"struct ");
					if (CheckStructName(&(*gen), O7_GUARD(Ast_RRecord, &typ))) {
						GlobalName(&(*gen), &typ->_);
						TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x20");
					}
				} else {
					GlobalName(&(*gen), &typ->_);
					TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x20");
				}
				if ((*gen).memout != NULL) {
					MemWriteInvert(&(*O7_REF((*gen).memout)));
				}
			}
		} else if (!sameType || (o7_in(O7_REF(typ)->_._.id, ((1u << Ast_IdPointer_cnst) | (1u << Ast_IdArray_cnst) | (1u << Ast_IdProcType_cnst))))) {
			switch (O7_REF(typ)->_._.id) {
			case 0:
				Type_Simple(&(*gen), 10, (o7_char *)"o7_int_t ");
				break;
			case 1:
				Type_Simple(&(*gen), 11, (o7_char *)"o7_long_t ");
				break;
			case 7:
				Type_Simple(&(*gen), 10, (o7_char *)"o7_set_t ");
				break;
			case 8:
				Type_Simple(&(*gen), 12, (o7_char *)"o7_set64_t ");
				break;
			case 2:
				if ((o7_cmp(O7_REF((*gen).opt)->std, GeneratorC_IsoC99_cnst) >= 0) && (o7_cmp(O7_REF((*gen).opt)->varInit, GeneratorC_VarInitUndefined_cnst) != 0)) {
					Type_Simple(&(*gen), 6, (o7_char *)"bool ");
				} else {
					Type_Simple(&(*gen), 9, (o7_char *)"o7_bool ");
				}
				break;
			case 3:
				Type_Simple(&(*gen), 15, (o7_char *)"char unsigned ");
				break;
			case 4:
				Type_Simple(&(*gen), 9, (o7_char *)"o7_char ");
				break;
			case 5:
				Type_Simple(&(*gen), 8, (o7_char *)"double ");
				break;
			case 6:
				Type_Simple(&(*gen), 7, (o7_char *)"float ");
				break;
			case 9:
				TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x2A");
				MemWriteInvert(&(*O7_REF((*gen).memout)));
				Invert(&(*gen));
				Type(&(*gen), decl, O7_REF(typ)->_.type, (0 > 1), sameType);
				break;
			case 10:
				Type_Array(&(*gen), decl, O7_GUARD(Ast_RArray, &typ), sameType);
				break;
			case 11:
				Type_Record(&(*gen), O7_GUARD(Ast_RRecord, &typ));
				break;
			case 13:
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)"(*");
				MemWriteInvert(&(*O7_REF((*gen).memout)));
				TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
				ProcHead(&(*gen), O7_GUARD(Ast_RProcType, &typ));
				break;
			default:
				o7_case_fail(O7_REF(typ)->_._.id);
				break;
			}
		}
		if ((*gen).memout != NULL) {
			MemWriteInvert(&(*O7_REF((*gen).memout)));
		}
	}
}

static void RecordTag(struct GeneratorC_Generator *gen, struct Ast_RRecord *rec) {
	if ((o7_cmp(O7_REF((*gen).opt)->memManager, GeneratorC_MemManagerCounter_cnst) != 0) && (O7_REF(rec)->base == NULL)) {
		TextGenerator_Str(&(*gen)._, 9, (o7_char *)"#define ");
		GlobalName(&(*gen), &rec->_._._);
		TextGenerator_StrLn(&(*gen)._, 17, (o7_char *)"_tag o7_base_tag");
	} else if ((o7_cmp(O7_REF((*gen).opt)->memManager, GeneratorC_MemManagerCounter_cnst) != 0) && !o7_bl(O7_REF(rec)->needTag) && o7_bl(O7_REF((*gen).opt)->skipUnusedTag)) {
		TextGenerator_Str(&(*gen)._, 9, (o7_char *)"#define ");
		GlobalName(&(*gen), &rec->_._._);
		TextGenerator_Str(&(*gen)._, 6, (o7_char *)"_tag ");
		GlobalName(&(*gen), &O7_REF(rec)->base->_._._);
		TextGenerator_StrLn(&(*gen)._, 5, (o7_char *)"_tag");
	} else {
		if (!o7_bl(O7_REF(rec)->_._._.mark) || o7_bl(O7_REF((*gen).opt)->main_)) {
			TextGenerator_Str(&(*gen)._, 17, (o7_char *)"static o7_tag_t ");
		} else if (o7_bl((*gen).interface_)) {
			TextGenerator_Str(&(*gen)._, 17, (o7_char *)"extern o7_tag_t ");
		} else {
			TextGenerator_Str(&(*gen)._, 10, (o7_char *)"o7_tag_t ");
		}
		GlobalName(&(*gen), &rec->_._._);
		TextGenerator_StrLn(&(*gen)._, 6, (o7_char *)"_tag;");
	}
	if (!o7_bl(O7_REF(rec)->_._._.mark) || o7_bl(O7_REF((*gen).opt)->main_) || o7_bl((*gen).interface_)) {
		TextGenerator_Ln(&(*gen)._);
	}
}

static void TypeDecl(struct MOut *out, struct Ast_RType *typ);
static void TypeDecl_Typedef(struct GeneratorC_Generator *gen, struct Ast_RType *typ) {
	EmptyLines(&(*gen), &typ->_);
	TextGenerator_Str(&(*gen)._, 9, (o7_char *)"typedef ");
	Declarator(&(*gen), &typ->_, (0 < 1), (0 > 1), (0 < 1));
	TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x3B");
}

static void TypeDecl_LinkRecord(struct GeneratorC_Options__s *opt, struct Ast_RRecord *rec) {
	struct RecExt__s *ext = NULL;

	O7_ASSERT(O7_REF(rec)->_._._._.ext == NULL);
	O7_NEW(&ext, RecExt__s);
	V_Init(&(*O7_REF(ext))._);
	StringStore_Undef(&O7_REF(ext)->anonName);
	O7_REF(ext)->next = NULL;
	O7_REF(ext)->undef = (0 > 1);
	O7_REF(rec)->_._._._.ext = (&(ext)->_);

	if (O7_REF(opt)->records == NULL) {
		O7_REF(opt)->records = rec;
	} else {
		O7_GUARD(RecExt__s, &O7_REF(O7_REF(opt)->recordLast)->_._._._.ext)->next = rec;
	}
	O7_REF(opt)->recordLast = rec;
}

static void TypeDecl(struct MOut *out, struct Ast_RType *typ) {
	TypeDecl_Typedef(&(*out).g[o7_ind(2, (o7_int_t)(o7_bl(O7_REF(typ)->_.mark) && !o7_bl(O7_REF((*out).opt)->main_)))], typ);
	if ((o7_cmp(O7_REF(typ)->_._.id, Ast_IdRecord_cnst) == 0) || (o7_cmp(O7_REF(typ)->_._.id, Ast_IdPointer_cnst) == 0) && (O7_REF(O7_REF(typ)->_.type)->_.next == NULL)) {
		if (o7_cmp(O7_REF(typ)->_._.id, Ast_IdPointer_cnst) == 0) {
			typ = O7_REF(typ)->_.type;
		}
		O7_REF(typ)->_.mark = o7_bl(O7_REF(typ)->_.mark) || (O7_GUARD(Ast_RRecord, &typ)->pointer != NULL) && (O7_REF(O7_GUARD(Ast_RRecord, &typ)->pointer)->_._._.mark);
		TypeDecl_LinkRecord((*out).opt, O7_GUARD(Ast_RRecord, &typ));
		if (o7_bl(O7_REF(typ)->_.mark) && !o7_bl(O7_REF((*out).opt)->main_)) {
			RecordTag(&(*out).g[Interface_cnst], O7_GUARD(Ast_RRecord, &typ));
			if (o7_cmp(O7_REF((*out).opt)->varInit, GeneratorC_VarInitUndefined_cnst) == 0) {
				RecordUndefHeader(&(*out).g[Interface_cnst], O7_GUARD(Ast_RRecord, &typ), (0 < 1));
			}
			if (o7_cmp(O7_REF((*out).opt)->memManager, GeneratorC_MemManagerCounter_cnst) == 0) {
				RecordReleaseHeader(&(*out).g[Interface_cnst], O7_GUARD(Ast_RRecord, &typ), (0 < 1));
				if (!!( (1u << Ast_TypeAssigned_cnst) & O7_REF(typ)->properties)) {
					RecordRetainHeader(&(*out).g[Interface_cnst], O7_GUARD(Ast_RRecord, &typ), (0 < 1));
				}
			}
		}
		if ((!o7_bl(O7_REF(typ)->_.mark) || o7_bl(O7_REF((*out).opt)->main_)) || (O7_GUARD(Ast_RRecord, &typ)->base != NULL) || !o7_bl(O7_GUARD(Ast_RRecord, &typ)->needTag)) {
			RecordTag(&(*out).g[Implementation_cnst], O7_GUARD(Ast_RRecord, &typ));
		}
		if (o7_cmp(O7_REF((*out).opt)->varInit, GeneratorC_VarInitUndefined_cnst) == 0) {
			RecordUndef(&(*out).g[Implementation_cnst], O7_GUARD(Ast_RRecord, &typ));
		}
		if (o7_cmp(O7_REF((*out).opt)->memManager, GeneratorC_MemManagerCounter_cnst) == 0) {
			RecordRelease(&(*out).g[Implementation_cnst], O7_GUARD(Ast_RRecord, &typ));
			if (!!( (1u << Ast_TypeAssigned_cnst) & O7_REF(typ)->properties)) {
				RecordRetain(&(*out).g[Implementation_cnst], O7_GUARD(Ast_RRecord, &typ));
			}
		}
	}
}

static void Mark(struct GeneratorC_Generator *gen, o7_bool mark) {
	if (o7_cmp((*gen).localDeep, 0) == 0) {
		if (mark && !o7_bl(O7_REF((*gen).opt)->main_)) {
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)"extern ");
		} else {
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)"static ");
		}
	}
}

static void Comment(struct GeneratorC_Generator *gen, struct StringStore_String *com) {
	struct StringStore_Iterator i;
	o7_char prev;
	StringStore_Iterator_undef(&i);

	if (o7_bl(O7_REF((*gen).opt)->comment) && StringStore_GetIter(&i, &(*com), 0)) {
		do {
			prev = i.char_;
		} while (!(!StringStore_IterNext(&i) || (prev == (o7_char)'/') && (i.char_ == (o7_char)'*') || (prev == (o7_char)'*') && (i.char_ == (o7_char)'/')));

		if (i.char_ == 0x00u) {
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)"/*");
			TextGenerator_String(&(*gen)._, &(*com));
			TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)"*/");
		}
	}
}

static void Const(struct GeneratorC_Generator *gen, struct Ast_Const__s *const_) {
	Comment(&(*gen), &O7_REF(const_)->_._.comment);
	EmptyLines(&(*gen), &const_->_);
	TextGenerator_StrIgnoreIndent(&(*gen)._, 2, (o7_char *)"\x23");
	TextGenerator_Str(&(*gen)._, 8, (o7_char *)"define ");
	GlobalName(&(*gen), &const_->_);
	TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x20");
	if (o7_bl(O7_REF(const_)->_.mark) && (O7_REF(O7_REF(const_)->expr)->value_ != NULL)) {
		Factor(&(*gen), &O7_REF(O7_REF(const_)->expr)->value_->_);
	} else {
		Factor(&(*gen), O7_REF(const_)->expr);
	}
	TextGenerator_Ln(&(*gen)._);
}

static void Var(struct MOut *out, struct Ast_RDeclaration *prev, struct Ast_RDeclaration *var_, o7_bool last) {
	o7_bool same, mark;

	mark = o7_bl(O7_REF(var_)->mark) && !o7_bl(O7_REF((*out).opt)->main_);
	Comment(&(*out).g[o7_ind(2, (o7_int_t)o7_bl(mark))], &O7_REF(var_)->_.comment);
	EmptyLines(&(*out).g[o7_ind(2, (o7_int_t)o7_bl(mark))], var_);
	same = (prev != NULL) && (O7_REF(prev)->mark == mark) && (O7_REF(prev)->type == O7_REF(var_)->type);
	if (!same) {
		if (prev != NULL) {
			TextGenerator_StrLn(&(*out).g[o7_ind(2, (o7_int_t)o7_bl(mark))]._, 2, (o7_char *)"\x3B");
		}
		Mark(&(*out).g[o7_ind(2, (o7_int_t)o7_bl(mark))], mark);
	} else {
		TextGenerator_Str(&(*out).g[o7_ind(2, (o7_int_t)o7_bl(mark))]._, 3, (o7_char *)", ");
	}
	if (mark) {
		Declarator(&(*out).g[Interface_cnst], var_, (0 > 1), same, (0 < 1));
		if (last) {
			TextGenerator_StrLn(&(*out).g[Interface_cnst]._, 2, (o7_char *)"\x3B");
		}

		if (same) {
			TextGenerator_Str(&(*out).g[Implementation_cnst]._, 3, (o7_char *)", ");
		} else if (prev != NULL) {
			TextGenerator_StrLn(&(*out).g[Implementation_cnst]._, 2, (o7_char *)"\x3B");
		}
	}

	Declarator(&(*out).g[Implementation_cnst], var_, (0 > 1), same, (0 < 1));

	VarInit(&(*out).g[Implementation_cnst], var_, (0 > 1));

	if (last) {
		TextGenerator_StrLn(&(*out).g[Implementation_cnst]._, 2, (o7_char *)"\x3B");
	}
}

static void ExprThenStats(struct GeneratorC_Generator *gen, struct Ast_RWhileIf **wi) {
	CheckExpr(&(*gen), O7_REF((*wi))->_.expr);
	TextGenerator_StrOpen(&(*gen)._, 4, (o7_char *)") {");
	statements(&(*gen), O7_REF((*wi))->stats);
	(*wi) = O7_REF((*wi))->elsif;
}

static o7_bool IsCaseElementWithRange(struct Ast_RCaseElement *elem) {
	struct Ast_RCaseLabel *r;

	r = O7_REF(elem)->labels;
	while ((r != NULL) && (O7_REF(r)->right == NULL)) {
		r = O7_REF(r)->next;
	}
	return r != NULL;
}

static void ExprSameType(struct GeneratorC_Generator *gen, struct Ast_RExpression *expr, struct Ast_RType *expectType) {
	o7_bool reref, brace;
	struct Ast_RRecord *base, *extend = NULL;

	base = NULL;
	reref = (o7_cmp(O7_REF(O7_REF(expr)->type)->_._.id, Ast_IdPointer_cnst) == 0) && (O7_REF(O7_REF(expr)->type)->_.type != O7_REF(expectType)->_.type) && (o7_cmp(O7_REF(expr)->_.id, Ast_IdPointer_cnst) != 0);
	brace = reref;
	if (!reref) {
		CheckExpr(&(*gen), expr);
		if (o7_cmp(O7_REF(O7_REF(expr)->type)->_._.id, Ast_IdRecord_cnst) == 0) {
			base = O7_GUARD(Ast_RRecord, &expectType);
			extend = O7_GUARD(Ast_RRecord, &O7_REF(expr)->type);
		}
	} else if (o7_bl(O7_REF((*gen).opt)->plan9)) {
		CheckExpr(&(*gen), expr);
		brace = (0 > 1);
	} else {
		base = O7_GUARD(Ast_RRecord, &O7_REF(expectType)->_.type);
		extend = O7_GUARD(Ast_RRecord, &O7_REF(O7_REF(expr)->type)->_.type)->base;
		TextGenerator_Str(&(*gen)._, 4, (o7_char *)"(&(");
		Expression(&(*gen), expr);
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)")->_");
	}
	if ((base != NULL) && (extend != base)) {
		if (o7_bl(O7_REF((*gen).opt)->plan9)) {
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x2E");
			GlobalName(&(*gen), &expectType->_);
		} else {
			while (extend != base) {
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)"._");
				extend = O7_REF(extend)->base;
			}
		}
	}
	if (brace) {
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void ExprForSize(struct GeneratorC_Generator *gen, struct Ast_RExpression *e) {
	(*gen).insideSizeOf = (0 < 1);
	Expression(&(*gen), e);
	(*gen).insideSizeOf = (0 > 1);
}

static void Assign(struct GeneratorC_Generator *gen, struct Ast_Assign__s *st);
static void Assign_Equal(struct GeneratorC_Generator *gen, struct Ast_Assign__s *st);
static void Assign_Equal_AssertArraySize(struct GeneratorC_Generator *gen, struct Ast_Designator__s *des, struct Ast_RExpression *e) {
	if (o7_bl(O7_REF((*gen).opt)->checkIndex) && ((O7_GUARD(Ast_RArray, &O7_REF(des)->_._.type)->count == NULL) || (O7_GUARD(Ast_RArray, &O7_REF(e)->type)->count == NULL))) {
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"assert(");
		ArrayLen(&(*gen), &des->_._);
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)" >= ");
		ArrayLen(&(*gen), e);
		TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
	}
}

static void Assign_Equal(struct GeneratorC_Generator *gen, struct Ast_Assign__s *st) {
	o7_bool retain, toByte;

	toByte = (o7_cmp(O7_REF(O7_REF(O7_REF(st)->designator)->_._.type)->_._.id, Ast_IdByte_cnst) == 0) && (o7_in(O7_REF(O7_REF(O7_REF(st)->_.expr)->type)->_._.id, ((1u << Ast_IdInteger_cnst) | (1u << Ast_IdLongInt_cnst)))) && o7_bl(O7_REF((*gen).opt)->checkArith) && (O7_REF(O7_REF(st)->_.expr)->value_ == NULL);
	retain = (o7_cmp(O7_REF(O7_REF(O7_REF(st)->designator)->_._.type)->_._.id, Ast_IdPointer_cnst) == 0) && (o7_cmp(O7_REF((*gen).opt)->memManager, GeneratorC_MemManagerCounter_cnst) == 0);
	if (retain && (o7_cmp(O7_REF(O7_REF(st)->_.expr)->_.id, Ast_IdPointer_cnst) == 0)) {
		TextGenerator_Str(&(*gen)._, 10, (o7_char *)"O7_NULL(&");
		Designator(&(*gen), O7_REF(st)->designator);
	} else {
		if (retain) {
			TextGenerator_Str(&(*gen)._, 12, (o7_char *)"O7_ASSIGN(&");
			Designator(&(*gen), O7_REF(st)->designator);
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
		} else if ((o7_cmp(O7_REF(O7_REF(O7_REF(st)->designator)->_._.type)->_._.id, Ast_IdArray_cnst) == 0)) {
			Assign_Equal_AssertArraySize(&(*gen), O7_REF(st)->designator, O7_REF(st)->_.expr);
			TextGenerator_Str(&(*gen)._, 8, (o7_char *)"memcpy(");
			Designator(&(*gen), O7_REF(st)->designator);
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
			O7_REF((*gen).opt)->expectArray = (0 < 1);
		} else if (toByte) {
			Designator(&(*gen), O7_REF(st)->designator);
			if (o7_cmp(O7_REF(O7_REF(O7_REF(st)->_.expr)->type)->_._.id, Ast_IdInteger_cnst) == 0) {
				TextGenerator_Str(&(*gen)._, 12, (o7_char *)" = o7_byte(");
			} else {
				TextGenerator_Str(&(*gen)._, 13, (o7_char *)" = o7_lbyte(");
			}
		} else {
			Designator(&(*gen), O7_REF(st)->designator);
			TextGenerator_Str(&(*gen)._, 4, (o7_char *)" = ");
		}
		ExprSameType(&(*gen), O7_REF(st)->_.expr, O7_REF(O7_REF(st)->designator)->_._.type);
		O7_REF((*gen).opt)->expectArray = (0 > 1);
		if (o7_cmp(O7_REF(O7_REF(O7_REF(st)->designator)->_._.type)->_._.id, Ast_IdArray_cnst) != 0) {
		} else if ((O7_GUARD(Ast_RArray, &O7_REF(O7_REF(st)->_.expr)->type)->count != NULL) && !Ast_IsFormalParam(O7_REF(st)->_.expr)) {
			if ((o7_is(O7_REF(st)->_.expr, &Ast_ExprString__s_tag)) && o7_bl(O7_GUARD(Ast_ExprString__s, &O7_REF(st)->_.expr)->asChar)) {
				TextGenerator_Str(&(*gen)._, 4, (o7_char *)", 2");
			} else {
				TextGenerator_Str(&(*gen)._, 10, (o7_char *)", sizeof(");
				ExprForSize(&(*gen), O7_REF(st)->_.expr);
				TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
			}
		} else {
			TextGenerator_Str(&(*gen)._, 4, (o7_char *)", (");
			ArrayLen(&(*gen), O7_REF(st)->_.expr);
			TextGenerator_Str(&(*gen)._, 12, (o7_char *)") * sizeof(");
			ExprForSize(&(*gen), O7_REF(st)->_.expr);
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)"[0])");
		}
	}
	switch (o7_add(o7_add((o7_int_t)o7_bl(retain), (o7_int_t)o7_bl(toByte)), (o7_int_t)(o7_cmp(O7_REF(O7_REF(O7_REF(st)->designator)->_._.type)->_._.id, Ast_IdArray_cnst) == 0))) {
	case 0:
		break;
	case 1:
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
		break;
	case 2:
		TextGenerator_Str(&(*gen)._, 3, (o7_char *)"))");
		break;
	default:
		o7_case_fail(o7_add(o7_add((o7_int_t)o7_bl(retain), (o7_int_t)o7_bl(toByte)), (o7_int_t)(o7_cmp(O7_REF(O7_REF(O7_REF(st)->designator)->_._.type)->_._.id, Ast_IdArray_cnst) == 0)));
		break;
	}
	if ((o7_cmp(O7_REF((*gen).opt)->memManager, GeneratorC_MemManagerCounter_cnst) == 0) && (o7_cmp(O7_REF(O7_REF(O7_REF(st)->designator)->_._.type)->_._.id, Ast_IdRecord_cnst) == 0) && (!IsAnonStruct(O7_GUARD(Ast_RRecord, &O7_REF(O7_REF(st)->designator)->_._.type)))) {
		TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x3B");
		GlobalName(&(*gen), &O7_REF(O7_REF(st)->designator)->_._.type->_);
		TextGenerator_Str(&(*gen)._, 10, (o7_char *)"_retain(&");
		Designator(&(*gen), O7_REF(st)->designator);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
	}
}

static void Assign(struct GeneratorC_Generator *gen, struct Ast_Assign__s *st) {
	Assign_Equal(&(*gen), st);
}

static void Statement(struct GeneratorC_Generator *gen, struct Ast_RStatement *st);
static void Statement_WhileIf(struct GeneratorC_Generator *gen, struct Ast_RWhileIf *wi);
static void Statement_WhileIf_Elsif(struct GeneratorC_Generator *gen, struct Ast_RWhileIf **wi) {
	while (((*wi) != NULL) && (O7_REF((*wi))->_.expr != NULL)) {
		TextGenerator_StrClose(&(*gen)._, 12, (o7_char *)"} else if (");
		ExprThenStats(&(*gen), &(*wi));
	}
}

static void Statement_WhileIf(struct GeneratorC_Generator *gen, struct Ast_RWhileIf *wi) {
	if (o7_is(wi, &Ast_If__s_tag)) {
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)"if (");
		ExprThenStats(&(*gen), &wi);
		Statement_WhileIf_Elsif(&(*gen), &wi);
		if (wi != NULL) {
			TextGenerator_IndentClose(&(*gen)._);
			TextGenerator_StrOpen(&(*gen)._, 9, (o7_char *)"} else {");
			statements(&(*gen), O7_REF(wi)->stats);
		}
		TextGenerator_StrLnClose(&(*gen)._, 2, (o7_char *)"\x7D");
	} else if (O7_REF(wi)->elsif == NULL) {
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"while (");
		ExprThenStats(&(*gen), &wi);
		TextGenerator_StrLnClose(&(*gen)._, 2, (o7_char *)"\x7D");
	} else {
		TextGenerator_Str(&(*gen)._, 15, (o7_char *)"while (1) if (");
		ExprThenStats(&(*gen), &wi);
		Statement_WhileIf_Elsif(&(*gen), &wi);
		TextGenerator_StrLnClose(&(*gen)._, 14, (o7_char *)"} else break;");
	}
}

static void Statement_Repeat(struct GeneratorC_Generator *gen, struct Ast_Repeat__s *st) {
	struct Ast_RExpression *e;

	TextGenerator_StrOpen(&(*gen)._, 5, (o7_char *)"do {");
	statements(&(*gen), O7_REF(st)->stats);
	if (o7_cmp(O7_REF(O7_REF(st)->_.expr)->_.id, Ast_IdNegate_cnst) == 0) {
		TextGenerator_StrClose(&(*gen)._, 10, (o7_char *)"} while (");
		e = O7_GUARD(Ast_ExprNegate__s, &O7_REF(st)->_.expr)->expr;
		while (o7_cmp(O7_REF(e)->_.id, Ast_IdBraces_cnst) == 0) {
			e = O7_GUARD(Ast_ExprBraces__s, &e)->expr;
		}
		Expression(&(*gen), e);
		TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
	} else {
		TextGenerator_StrClose(&(*gen)._, 12, (o7_char *)"} while (!(");
		CheckExpr(&(*gen), O7_REF(st)->_.expr);
		TextGenerator_StrLn(&(*gen)._, 4, (o7_char *)"));");
	}
}

static void Statement_For(struct GeneratorC_Generator *gen, struct Ast_For__s *st);
static o7_bool Statement_For_IsEndMinus1(struct Ast_RExprSum *sum) {
	return (O7_REF(sum)->next != NULL) && (O7_REF(O7_REF(sum)->next)->next == NULL) && (o7_cmp(O7_REF(O7_REF(sum)->next)->add, Scanner_Minus_cnst) == 0) && (O7_REF(O7_REF(O7_REF(sum)->next)->term)->value_ != NULL) && (o7_cmp(O7_GUARD(Ast_RExprInteger, &O7_REF(O7_REF(O7_REF(sum)->next)->term)->value_)->int_, 1) == 0);
}

static void Statement_For(struct GeneratorC_Generator *gen, struct Ast_For__s *st) {
	TextGenerator_Str(&(*gen)._, 6, (o7_char *)"for (");
	GlobalName(&(*gen), &O7_REF(st)->var_->_);
	TextGenerator_Str(&(*gen)._, 4, (o7_char *)" = ");
	Expression(&(*gen), O7_REF(st)->_.expr);
	TextGenerator_Str(&(*gen)._, 3, (o7_char *)"; ");
	GlobalName(&(*gen), &O7_REF(st)->var_->_);
	if (o7_cmp(O7_REF(st)->by, 0) > 0) {
		if ((o7_is(O7_REF(st)->to, &Ast_RExprSum_tag)) && Statement_For_IsEndMinus1(O7_GUARD(Ast_RExprSum, &O7_REF(st)->to))) {
			TextGenerator_Str(&(*gen)._, 4, (o7_char *)" < ");
			Expression(&(*gen), O7_GUARD(Ast_RExprSum, &O7_REF(st)->to)->term);
		} else {
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)" <= ");
			Expression(&(*gen), O7_REF(st)->to);
		}
		if (o7_cmp(O7_REF(st)->by, 1) == 0) {
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)"; ++");
			GlobalName(&(*gen), &O7_REF(st)->var_->_);
		} else {
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)"; ");
			GlobalName(&(*gen), &O7_REF(st)->var_->_);
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)" += ");
			TextGenerator_Int(&(*gen)._, o7_int(O7_REF(st)->by));
		}
	} else {
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)" >= ");
		Expression(&(*gen), O7_REF(st)->to);
		if (o7_cmp(O7_REF(st)->by,  - 1) == 0) {
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)"; --");
			GlobalName(&(*gen), &O7_REF(st)->var_->_);
		} else {
			TextGenerator_Str(&(*gen)._, 3, (o7_char *)"; ");
			GlobalName(&(*gen), &O7_REF(st)->var_->_);
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)" -= ");
			TextGenerator_Int(&(*gen)._, o7_sub(0, O7_REF(st)->by));
		}
	}
	TextGenerator_StrOpen(&(*gen)._, 4, (o7_char *)") {");
	statements(&(*gen), O7_REF(st)->stats);
	TextGenerator_StrLnClose(&(*gen)._, 2, (o7_char *)"\x7D");
}

static void Statement_Case(struct GeneratorC_Generator *gen, struct Ast_Case__s *st);
static void Statement_Case_CaseElement(struct GeneratorC_Generator *gen, struct Ast_RCaseElement *elem) {
	struct Ast_RCaseLabel *r;

	if (o7_bl(O7_REF((*gen).opt)->gnu) || !IsCaseElementWithRange(elem)) {
		r = O7_REF(elem)->labels;
		while (r != NULL) {
			TextGenerator_Str(&(*gen)._, 6, (o7_char *)"case ");
			TextGenerator_Int(&(*gen)._, o7_int(O7_REF(r)->value_));
			if (O7_REF(r)->right != NULL) {
				O7_ASSERT(o7_bl(O7_REF((*gen).opt)->gnu));
				TextGenerator_Str(&(*gen)._, 6, (o7_char *)" ... ");
				TextGenerator_Int(&(*gen)._, o7_int(O7_REF(O7_REF(r)->right)->value_));
			}
			TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x3A");

			r = O7_REF(r)->next;
		}
		TextGenerator_IndentOpen(&(*gen)._);
		statements(&(*gen), O7_REF(elem)->stats);
		TextGenerator_StrLn(&(*gen)._, 7, (o7_char *)"break;");
		TextGenerator_IndentClose(&(*gen)._);
	}
}

static void Statement_Case_CaseElementAsIf(struct GeneratorC_Generator *gen, struct Ast_RCaseElement *elem, struct Ast_RExpression *caseExpr);
static void Statement_Case_CaseElementAsIf_CaseRange(struct GeneratorC_Generator *gen, struct Ast_RCaseLabel *r, struct Ast_RExpression *caseExpr) {
	if (O7_REF(r)->right == NULL) {
		if (caseExpr == NULL) {
			TextGenerator_Str(&(*gen)._, 18, (o7_char *)"(o7_case_expr == ");
		} else {
			TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x28");
			Expression(&(*gen), caseExpr);
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)" == ");
		}
		TextGenerator_Int(&(*gen)._, o7_int(O7_REF(r)->value_));
	} else {
		O7_ASSERT(o7_cmp(O7_REF(r)->value_, O7_REF(O7_REF(r)->right)->value_) <= 0);
		TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x28");
		TextGenerator_Int(&(*gen)._, o7_int(O7_REF(r)->value_));
		if (caseExpr == NULL) {
			TextGenerator_Str(&(*gen)._, 37, (o7_char *)" <= o7_case_expr && o7_case_expr <= ");
		} else {
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)" <= ");
			Expression(&(*gen), caseExpr);
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)" && ");
			Expression(&(*gen), caseExpr);
			TextGenerator_Str(&(*gen)._, 5, (o7_char *)" <= ");
		}
		TextGenerator_Int(&(*gen)._, o7_int(O7_REF(O7_REF(r)->right)->value_));
	}
	TextGenerator_Str(&(*gen)._, 2, (o7_char *)"\x29");
}

static void Statement_Case_CaseElementAsIf(struct GeneratorC_Generator *gen, struct Ast_RCaseElement *elem, struct Ast_RExpression *caseExpr) {
	struct Ast_RCaseLabel *r;

	TextGenerator_Str(&(*gen)._, 5, (o7_char *)"if (");
	r = O7_REF(elem)->labels;
	O7_ASSERT(r != NULL);
	Statement_Case_CaseElementAsIf_CaseRange(&(*gen), r, caseExpr);
	while (O7_REF(r)->next != NULL) {
		r = O7_REF(r)->next;
		TextGenerator_Str(&(*gen)._, 5, (o7_char *)" || ");
		Statement_Case_CaseElementAsIf_CaseRange(&(*gen), r, caseExpr);
	}
	TextGenerator_StrOpen(&(*gen)._, 4, (o7_char *)") {");
	statements(&(*gen), O7_REF(elem)->stats);
	TextGenerator_StrClose(&(*gen)._, 2, (o7_char *)"\x7D");
}

static void Statement_Case(struct GeneratorC_Generator *gen, struct Ast_Case__s *st) {
	struct Ast_RCaseElement *elem, *elemWithRange;
	struct Ast_RExpression *caseExpr;

	if (o7_bl(O7_REF((*gen).opt)->gnu)) {
		elemWithRange = NULL;
	} else {
		elemWithRange = O7_REF(st)->elements;
		while ((elemWithRange != NULL) && !IsCaseElementWithRange(elemWithRange)) {
			elemWithRange = O7_REF(elemWithRange)->next;
		}
	}
	if ((elemWithRange != NULL) && (O7_REF(O7_REF(st)->_.expr)->value_ == NULL) && (!(o7_is(O7_REF(st)->_.expr, &Ast_Designator__s_tag)) || (O7_GUARD(Ast_Designator__s, &O7_REF(st)->_.expr)->sel != NULL))) {
		caseExpr = NULL;
		TextGenerator_Str(&(*gen)._, 27, (o7_char *)"{ o7_int_t o7_case_expr = ");
		Expression(&(*gen), O7_REF(st)->_.expr);
		TextGenerator_StrOpen(&(*gen)._, 2, (o7_char *)"\x3B");
		TextGenerator_StrLn(&(*gen)._, 24, (o7_char *)"switch (o7_case_expr) {");
	} else {
		caseExpr = O7_REF(st)->_.expr;
		TextGenerator_Str(&(*gen)._, 9, (o7_char *)"switch (");
		Expression(&(*gen), caseExpr);
		TextGenerator_StrLn(&(*gen)._, 4, (o7_char *)") {");
	}
	elem = O7_REF(st)->elements;
	do {
		Statement_Case_CaseElement(&(*gen), elem);
		elem = O7_REF(elem)->next;
	} while (!(elem == NULL));
	TextGenerator_StrOpen(&(*gen)._, 9, (o7_char *)"default:");
	if (elemWithRange != NULL) {
		elem = elemWithRange;
		Statement_Case_CaseElementAsIf(&(*gen), elem, caseExpr);
		elem = O7_REF(elem)->next;
		while (elem != NULL) {
			if (IsCaseElementWithRange(elem)) {
				TextGenerator_Str(&(*gen)._, 7, (o7_char *)" else ");
				Statement_Case_CaseElementAsIf(&(*gen), elem, caseExpr);
			}
			elem = O7_REF(elem)->next;
		}
		if (!o7_bl(O7_REF((*gen).opt)->caseAbort)) {
		} else if (caseExpr == NULL) {
			TextGenerator_StrLn(&(*gen)._, 34, (o7_char *)" else o7_case_fail(o7_case_expr);");
		} else {
			TextGenerator_Str(&(*gen)._, 20, (o7_char *)" else o7_case_fail(");
			Expression(&(*gen), caseExpr);
			TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
		}
	} else if (!o7_bl(O7_REF((*gen).opt)->caseAbort)) {
	} else if (caseExpr == NULL) {
		TextGenerator_StrLn(&(*gen)._, 28, (o7_char *)"o7_case_fail(o7_case_expr);");
	} else {
		TextGenerator_Str(&(*gen)._, 14, (o7_char *)"o7_case_fail(");
		Expression(&(*gen), caseExpr);
		TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
	}
	TextGenerator_StrLn(&(*gen)._, 7, (o7_char *)"break;");
	TextGenerator_StrLnClose(&(*gen)._, 2, (o7_char *)"\x7D");
	if (caseExpr == NULL) {
		TextGenerator_StrLnClose(&(*gen)._, 2, (o7_char *)"\x7D");
	}
}

static void Statement(struct GeneratorC_Generator *gen, struct Ast_RStatement *st) {
	Comment(&(*gen), &O7_REF(st)->_.comment);
	if (o7_cmp(0, O7_REF(st)->_.emptyLines) < 0) {
		TextGenerator_Ln(&(*gen)._);
	}
	if (o7_is(st, &Ast_Assign__s_tag)) {
		Assign(&(*gen), O7_GUARD(Ast_Assign__s, &st));
		TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x3B");
	} else if (o7_is(st, &Ast_Call__s_tag)) {
		(*gen).expressionSemicolon = (0 < 1);
		Expression(&(*gen), O7_REF(st)->expr);
		if (o7_bl((*gen).expressionSemicolon)) {
			TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x3B");
		} else {
			TextGenerator_Ln(&(*gen)._);
		}
	} else if (o7_is(st, &Ast_RWhileIf_tag)) {
		Statement_WhileIf(&(*gen), O7_GUARD(Ast_RWhileIf, &st));
	} else if (o7_is(st, &Ast_Repeat__s_tag)) {
		Statement_Repeat(&(*gen), O7_GUARD(Ast_Repeat__s, &st));
	} else if (o7_is(st, &Ast_For__s_tag)) {
		Statement_For(&(*gen), O7_GUARD(Ast_For__s, &st));
	} else {
		O7_ASSERT(o7_is(st, &Ast_Case__s_tag));
		Statement_Case(&(*gen), O7_GUARD(Ast_Case__s, &st));
	}
}

static void Statements(struct GeneratorC_Generator *gen, struct Ast_RStatement *stats) {
	while (stats != NULL) {
		Statement(&(*gen), stats);
		stats = O7_REF(stats)->next;
	}
}

static void ProcDecl(struct GeneratorC_Generator *gen, struct Ast_RProcedure *proc) {
	Mark(&(*gen), o7_bl(O7_REF(proc)->_._._.mark));
	Declarator(&(*gen), &proc->_._._, (0 > 1), (0 > 1), (0 < 1));
	TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x3B");
}

static void ReleaseVars(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *var_) {
	if (o7_cmp(O7_REF((*gen).opt)->memManager, GeneratorC_MemManagerCounter_cnst) == 0) {
		while ((var_ != NULL) && (o7_cmp(O7_REF(var_)->_.id, Ast_IdVar_cnst) == 0)) {
			if (o7_cmp(O7_REF(O7_REF(var_)->type)->_._.id, Ast_IdArray_cnst) == 0) {
				if (o7_cmp(O7_REF(O7_REF(O7_REF(var_)->type)->_.type)->_._.id, Ast_IdPointer_cnst) == 0) {
					TextGenerator_Str(&(*gen)._, 18, (o7_char *)"O7_RELEASE_ARRAY(");
					GlobalName(&(*gen), var_);
					TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
				} else if ((o7_cmp(O7_REF(O7_REF(O7_REF(var_)->type)->_.type)->_._.id, Ast_IdRecord_cnst) == 0) && (O7_REF(O7_REF(O7_REF(var_)->type)->_.type)->_._.ext != NULL) && o7_bl(O7_GUARD(RecExt__s, &O7_REF(O7_REF(O7_REF(var_)->type)->_.type)->_._.ext)->undef)) {
					TextGenerator_Str(&(*gen)._, 41, (o7_char *)"{int o7_i; for (o7_i = 0; o7_i < O7_LEN(");
					GlobalName(&(*gen), var_);
					TextGenerator_StrOpen(&(*gen)._, 16, (o7_char *)"); o7_i += 1) {");
					GlobalName(&(*gen), &O7_REF(O7_REF(var_)->type)->_.type->_);
					TextGenerator_Str(&(*gen)._, 10, (o7_char *)"_release(");
					GlobalName(&(*gen), var_);
					TextGenerator_StrLn(&(*gen)._, 10, (o7_char *)" + o7_i);");
					TextGenerator_StrLnClose(&(*gen)._, 3, (o7_char *)"}}");
				}
			} else if (o7_cmp(O7_REF(O7_REF(var_)->type)->_._.id, Ast_IdPointer_cnst) == 0) {
				TextGenerator_Str(&(*gen)._, 10, (o7_char *)"O7_NULL(&");
				GlobalName(&(*gen), var_);
				TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
			} else if ((o7_cmp(O7_REF(O7_REF(var_)->type)->_._.id, Ast_IdRecord_cnst) == 0) && (O7_REF(O7_REF(var_)->type)->_._.ext != NULL)) {
				GlobalName(&(*gen), &O7_REF(var_)->type->_);
				TextGenerator_Str(&(*gen)._, 11, (o7_char *)"_release(&");
				GlobalName(&(*gen), var_);
				TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
			}

			var_ = O7_REF(var_)->next;
		}
	}
}

static void Procedure(struct MOut *out, struct Ast_RProcedure *proc);
static void Procedure_Implement(struct MOut *out, struct GeneratorC_Generator *gen, struct Ast_RProcedure *proc);
static void Procedure_Implement_CloseConsts(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *consts) {
	while ((consts != NULL) && (o7_is(consts, &Ast_Const__s_tag))) {
		TextGenerator_StrIgnoreIndent(&(*gen)._, 2, (o7_char *)"\x23");
		TextGenerator_Str(&(*gen)._, 7, (o7_char *)"undef ");
		Name(&(*gen), consts);
		TextGenerator_Ln(&(*gen)._);
		consts = O7_REF(consts)->next;
	}
}

static struct Ast_RDeclaration *Procedure_Implement_SearchRetain(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *fp) {
	while ((fp != NULL) && ((o7_cmp(O7_REF(O7_REF(fp)->type)->_._.id, Ast_IdPointer_cnst) != 0) || (!!( (1u << Ast_ParamOut_cnst) & O7_GUARD(Ast_RFormalParam, &fp)->access)))) {
		fp = O7_REF(fp)->next;
	}
	return fp;
}

static void Procedure_Implement_RetainParams(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *fp) {
	if (fp != NULL) {
		TextGenerator_Str(&(*gen)._, 11, (o7_char *)"o7_retain(");
		Name(&(*gen), fp);
		fp = O7_REF(fp)->next;
		while (fp != NULL) {
			if ((o7_cmp(O7_REF(O7_REF(fp)->type)->_._.id, Ast_IdPointer_cnst) == 0) && !(!!( (1u << Ast_ParamOut_cnst) & O7_GUARD(Ast_RFormalParam, &fp)->access))) {
				TextGenerator_Str(&(*gen)._, 14, (o7_char *)"); o7_retain(");
				Name(&(*gen), fp);
			}
			fp = O7_REF(fp)->next;
		}
		TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
	}
}

static void Procedure_Implement_ReleaseParams(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *fp) {
	if (fp != NULL) {
		TextGenerator_Str(&(*gen)._, 12, (o7_char *)"o7_release(");
		Name(&(*gen), fp);
		fp = O7_REF(fp)->next;
		while (fp != NULL) {
			if ((o7_cmp(O7_REF(O7_REF(fp)->type)->_._.id, Ast_IdPointer_cnst) == 0) && !(!!( (1u << Ast_ParamOut_cnst) & O7_GUARD(Ast_RFormalParam, &fp)->access))) {
				TextGenerator_Str(&(*gen)._, 15, (o7_char *)"); o7_release(");
				Name(&(*gen), fp);
			}
			fp = O7_REF(fp)->next;
		}
		TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
	}
}

static void Procedure_Implement(struct MOut *out, struct GeneratorC_Generator *gen, struct Ast_RProcedure *proc) {
	struct Ast_RDeclaration *retainParams;

	Comment(&(*gen), &O7_REF(proc)->_._._._.comment);
	Mark(&(*gen), o7_bl(O7_REF(proc)->_._._.mark));
	Declarator(&(*gen), &proc->_._._, (0 > 1), (0 > 1), (0 < 1));
	TextGenerator_StrOpen(&(*gen)._, 3, (o7_char *)" {");

	(*gen).localDeep = o7_add((*gen).localDeep, 1);

	(*gen).fixedLen = o7_int((*gen)._.len);

	if (o7_cmp(O7_REF((*gen).opt)->memManager, GeneratorC_MemManagerCounter_cnst) != 0) {
		retainParams = NULL;
	} else {
		retainParams = Procedure_Implement_SearchRetain(&(*gen), &O7_REF(O7_REF(proc)->_.header)->params->_._);
		if (O7_REF(proc)->_.return_ != NULL) {
			Qualifier(&(*gen), O7_REF(O7_REF(proc)->_.return_)->type);
			if (o7_cmp(O7_REF(O7_REF(O7_REF(proc)->_.return_)->type)->_._.id, Ast_IdPointer_cnst) == 0) {
				TextGenerator_StrLn(&(*gen)._, 19, (o7_char *)" o7_return = NULL;");
			} else {
				TextGenerator_StrLn(&(*gen)._, 12, (o7_char *)" o7_return;");
			}
		}
	}
	declarations(&(*out), &proc->_._);

	Procedure_Implement_RetainParams(&(*gen), retainParams);

	Statements(&(*gen), O7_REF(proc)->_._.stats);

	if (O7_REF(proc)->_.return_ == NULL) {
		ReleaseVars(&(*gen), &O7_REF(proc)->_._.vars->_);
		Procedure_Implement_ReleaseParams(&(*gen), retainParams);
	} else if (o7_cmp(O7_REF((*gen).opt)->memManager, GeneratorC_MemManagerCounter_cnst) == 0) {
		if (o7_cmp(O7_REF(O7_REF(O7_REF(proc)->_.return_)->type)->_._.id, Ast_IdPointer_cnst) == 0) {
			TextGenerator_Str(&(*gen)._, 23, (o7_char *)"O7_ASSIGN(&o7_return, ");
			Expression(&(*gen), O7_REF(proc)->_.return_);
			TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)");");
		} else {
			TextGenerator_Str(&(*gen)._, 13, (o7_char *)"o7_return = ");
			CheckExpr(&(*gen), O7_REF(proc)->_.return_);
			TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x3B");
		}
		ReleaseVars(&(*gen), &O7_REF(proc)->_._.vars->_);
		Procedure_Implement_ReleaseParams(&(*gen), retainParams);
		if (o7_cmp(O7_REF(O7_REF(O7_REF(proc)->_.return_)->type)->_._.id, Ast_IdPointer_cnst) == 0) {
			TextGenerator_StrLn(&(*gen)._, 22, (o7_char *)"o7_unhold(o7_return);");
		}
		TextGenerator_StrLn(&(*gen)._, 18, (o7_char *)"return o7_return;");
	} else {
		TextGenerator_Str(&(*gen)._, 8, (o7_char *)"return ");
		ExprSameType(&(*gen), O7_REF(proc)->_.return_, O7_REF(O7_REF(proc)->_.header)->_._._.type);
		TextGenerator_StrLn(&(*gen)._, 2, (o7_char *)"\x3B");
	}

	(*gen).localDeep = o7_sub((*gen).localDeep, 1);
	Procedure_Implement_CloseConsts(&(*gen), O7_REF(proc)->_._.start);
	TextGenerator_StrLnClose(&(*gen)._, 2, (o7_char *)"\x7D");
	TextGenerator_Ln(&(*gen)._);
}

static void Procedure_LocalProcs(struct MOut *out, struct Ast_RProcedure *proc) {
	struct Ast_RDeclaration *p, *t;

	t = (&(O7_REF(proc)->_._.types)->_);
	while ((t != NULL) && (o7_is(t, &Ast_RType_tag))) {
		TypeDecl(&(*out), O7_GUARD(Ast_RType, &t));
		t = O7_REF(t)->next;
	}
	p = (&(O7_REF(proc)->_._.procedures)->_._._);
	if ((p != NULL) && !o7_bl(O7_REF((*out).opt)->procLocal)) {
		if (!o7_bl(O7_REF(proc)->_._._.mark)) {
			ProcDecl(&(*out).g[Implementation_cnst], proc);
		}
		do {
			Procedure(&(*out), O7_GUARD(Ast_RProcedure, &p));
			p = O7_REF(p)->next;
		} while (!(p == NULL));
	}
}

static void Procedure(struct MOut *out, struct Ast_RProcedure *proc) {
	Procedure_LocalProcs(&(*out), proc);
	if (o7_bl(O7_REF(proc)->_._._.mark) && !o7_bl(O7_REF((*out).opt)->main_)) {
		ProcDecl(&(*out).g[Interface_cnst], proc);
	}
	Procedure_Implement(&(*out), &(*out).g[Implementation_cnst], proc);
}

static void LnIfWrote(struct MOut *out);
static void LnIfWrote_Write(struct GeneratorC_Generator *gen) {
	if (o7_cmp((*gen).fixedLen, (*gen)._.len) != 0) {
		TextGenerator_Ln(&(*gen)._);
		(*gen).fixedLen = o7_int((*gen)._.len);
	}
}

static void LnIfWrote(struct MOut *out) {
	if (!o7_bl(O7_REF((*out).opt)->main_)) {
		LnIfWrote_Write(&(*out).g[Interface_cnst]);
	}
	LnIfWrote_Write(&(*out).g[Implementation_cnst]);
}

static void VarsInit(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *d) {
	o7_int_t arrDeep = O7_INT_UNDEF, arrTypeId = O7_INT_UNDEF;

	while ((d != NULL) && (o7_is(d, &Ast_RVar_tag))) {
		if (o7_in(O7_REF(O7_REF(d)->type)->_._.id, ((1u << Ast_IdArray_cnst) | (1u << Ast_IdRecord_cnst)))) {
			if ((o7_cmp(O7_REF((*gen).opt)->varInit, GeneratorC_VarInitUndefined_cnst) == 0) && (o7_cmp(O7_REF(O7_REF(d)->type)->_._.id, Ast_IdRecord_cnst) == 0) && StringStore_IsDefined(&O7_REF(O7_REF(d)->type)->_.name) && Ast_IsGlobal(&O7_REF(d)->type->_)) {
				RecordUndefCall(&(*gen), d);
			} else if ((o7_cmp(O7_REF((*gen).opt)->varInit, GeneratorC_VarInitZero_cnst) == 0) || (o7_cmp(O7_REF(O7_REF(d)->type)->_._.id, Ast_IdRecord_cnst) == 0) || (o7_cmp(O7_REF(O7_REF(d)->type)->_._.id, Ast_IdArray_cnst) == 0) && !IsArrayTypeSimpleUndef(O7_REF(d)->type, &arrTypeId, &arrDeep)) {
				TextGenerator_Str(&(*gen)._, 9, (o7_char *)"memset(&");
				Name(&(*gen), d);
				TextGenerator_Str(&(*gen)._, 13, (o7_char *)", 0, sizeof(");
				Name(&(*gen), d);
				TextGenerator_StrLn(&(*gen)._, 4, (o7_char *)"));");
			} else {
				O7_ASSERT(o7_cmp(O7_REF((*gen).opt)->varInit, GeneratorC_VarInitUndefined_cnst) == 0);
				ArraySimpleUndef(&(*gen), o7_int(arrTypeId), d, (0 > 1));
			}
		}
		d = O7_REF(d)->next;
	}
}

static void Declarations(struct MOut *out, struct Ast_RDeclarations *ds) {
	struct Ast_RDeclaration *d, *prev;
	o7_bool inModule;

	d = O7_REF(ds)->start;
	inModule = o7_is(ds, &Ast_RModule_tag);
	O7_ASSERT((d == NULL) || !(o7_is(d, &Ast_RModule_tag)));
	while ((d != NULL) && (o7_is(d, &Ast_Import__s_tag))) {
		Import(&(*out).g[o7_ind(2, (o7_int_t)!o7_bl(O7_REF((*out).opt)->main_))], d);
		d = O7_REF(d)->next;
	}
	LnIfWrote(&(*out));

	while ((d != NULL) && (o7_is(d, &Ast_Const__s_tag))) {
		Const(&(*out).g[o7_ind(2, (o7_int_t)(o7_bl(O7_REF(d)->mark) && !o7_bl(O7_REF((*out).opt)->main_)))], O7_GUARD(Ast_Const__s, &d));
		d = O7_REF(d)->next;
	}
	LnIfWrote(&(*out));

	if (inModule) {
		while ((d != NULL) && (o7_is(d, &Ast_RType_tag))) {
			TypeDecl(&(*out), O7_GUARD(Ast_RType, &d));
			d = O7_REF(d)->next;
		}
		LnIfWrote(&(*out));

		while ((d != NULL) && (o7_is(d, &Ast_RVar_tag))) {
			Var(&(*out), NULL, d, (0 < 1));
			d = O7_REF(d)->next;
		}
	} else {
		d = (&(O7_REF(ds)->vars)->_);

		prev = NULL;
		while ((d != NULL) && (o7_is(d, &Ast_RVar_tag))) {
			Var(&(*out), prev, d, (O7_REF(d)->next == NULL) || !(o7_is(O7_REF(d)->next, &Ast_RVar_tag)));
			prev = d;
			d = O7_REF(d)->next;
		}
		if (o7_cmp(O7_REF((*out).opt)->varInit, GeneratorC_VarInitNo_cnst) != 0) {
			VarsInit(&(*out).g[Implementation_cnst], &O7_REF(ds)->vars->_);
		}

		d = (&(O7_REF(ds)->procedures)->_._._);
	}
	LnIfWrote(&(*out));

	if (inModule || o7_bl(O7_REF((*out).opt)->procLocal)) {
		while (d != NULL) {
			Procedure(&(*out), O7_GUARD(Ast_RProcedure, &d));
			d = O7_REF(d)->next;
		}
	}
}

extern struct GeneratorC_Options__s *GeneratorC_DefaultOptions(void) {
	struct GeneratorC_Options__s *o = NULL;

	O7_NEW(&o, GeneratorC_Options__s);
	if (o != NULL) {
		V_Init(&(*O7_REF(o))._);

		O7_REF(o)->std = GeneratorC_IsoC90_cnst;
		O7_REF(o)->gnu = (0 > 1);
		O7_REF(o)->plan9 = (0 > 1);
		O7_REF(o)->procLocal = (0 > 1);
		O7_REF(o)->checkIndex = (0 < 1);
		O7_REF(o)->vla = (0 > 1) && (o7_cmp(GeneratorC_IsoC99_cnst, O7_REF(o)->std) <= 0);
		O7_REF(o)->vlaMark = (0 < 1);
		O7_REF(o)->checkArith = (0 < 1);
		O7_REF(o)->caseAbort = (0 < 1);
		O7_REF(o)->checkNil = (0 < 1);
		O7_REF(o)->o7Assert = (0 < 1);
		O7_REF(o)->skipUnusedTag = (0 < 1);
		O7_REF(o)->comment = (0 < 1);
		O7_REF(o)->generatorNote = (0 < 1);
		O7_REF(o)->varInit = GeneratorC_VarInitUndefined_cnst;
		O7_REF(o)->memManager = GeneratorC_MemManagerNoFree_cnst;

		O7_REF(o)->expectArray = (0 > 1);

		O7_REF(o)->main_ = (0 > 1);

		O7_REF(o)->memOuts = NULL;
	}
	return o;
}

static void MarkExpression(struct Ast_RExpression *e) {
	if (e != NULL) {
		if (o7_cmp(O7_REF(e)->_.id, Ast_IdRelation_cnst) == 0) {
			MarkExpression(O7_GUARD(Ast_ExprRelation__s, &e)->exprs[0]);
			MarkExpression(O7_GUARD(Ast_ExprRelation__s, &e)->exprs[1]);
		} else if (o7_cmp(O7_REF(e)->_.id, Ast_IdTerm_cnst) == 0) {
			MarkExpression(&O7_GUARD(Ast_ExprTerm__s, &e)->factor->_);
			MarkExpression(O7_GUARD(Ast_ExprTerm__s, &e)->expr);
		} else if (o7_cmp(O7_REF(e)->_.id, Ast_IdSum_cnst) == 0) {
			MarkExpression(O7_GUARD(Ast_RExprSum, &e)->term);
			MarkExpression(&O7_GUARD(Ast_RExprSum, &e)->next->_);
		} else if ((o7_cmp(O7_REF(e)->_.id, Ast_IdDesignator_cnst) == 0) && !o7_bl(O7_REF(O7_GUARD(Ast_Designator__s, &e)->decl)->mark)) {
			O7_REF(O7_GUARD(Ast_Designator__s, &e)->decl)->mark = (0 < 1);
			MarkExpression(O7_GUARD(Ast_Const__s, &O7_GUARD(Ast_Designator__s, &e)->decl)->expr);
		}
	}
}

static void MarkType(struct Ast_RType *t) {
	struct Ast_RDeclaration *d;

	while ((t != NULL) && !o7_bl(O7_REF(t)->_.mark)) {
		O7_REF(t)->_.mark = (0 < 1);
		if (o7_cmp(O7_REF(t)->_._.id, Ast_IdArray_cnst) == 0) {
			MarkExpression(O7_GUARD(Ast_RArray, &t)->count);
			t = O7_REF(t)->_.type;
		} else if (o7_in(O7_REF(t)->_._.id, ((1u << Ast_IdRecord_cnst) | (1u << Ast_IdPointer_cnst)))) {
			if (o7_cmp(O7_REF(t)->_._.id, Ast_IdPointer_cnst) == 0) {
				t = O7_REF(t)->_.type;
				O7_REF(t)->_.mark = (0 < 1);
				O7_ASSERT(O7_REF(t)->_.module_ != NULL);
			}
			d = (&(O7_GUARD(Ast_RRecord, &t)->vars)->_);
			while (d != NULL) {
				MarkType(O7_REF(d)->type);
				d = O7_REF(d)->next;
			}
			t = (&(O7_GUARD(Ast_RRecord, &t)->base)->_._);
		} else {
			t = NULL;
		}
	}
}

static void MarkUsedInMarked(struct Ast_RModule *m);
static void MarkUsedInMarked_Consts(struct Ast_RDeclaration *c) {
	while ((c != NULL) && (o7_is(c, &Ast_Const__s_tag))) {
		if (o7_bl(O7_REF(c)->mark)) {
			MarkExpression(O7_GUARD(Ast_Const__s, &c)->expr);
		}
		c = O7_REF(c)->next;
	}
}

static void MarkUsedInMarked_Types(struct Ast_RDeclaration *t) {
	while ((t != NULL) && (o7_is(t, &Ast_RType_tag))) {
		if (o7_bl(O7_REF(t)->mark)) {
			O7_REF(t)->mark = (0 > 1);
			MarkType(O7_GUARD(Ast_RType, &t));
		}
		t = O7_REF(t)->next;
	}
}

static void MarkUsedInMarked_Procs(struct Ast_RDeclaration *p) {
	struct Ast_RDeclaration *fp;

	while ((p != NULL) && (o7_is(p, &Ast_RProcedure_tag))) {
		if (o7_bl(O7_REF(p)->mark)) {
			fp = (&(O7_REF(O7_GUARD(Ast_RProcedure, &p)->_.header)->params)->_._);
			while (fp != NULL) {
				MarkType(O7_REF(fp)->type);
				fp = O7_REF(fp)->next;
			}
		}
		p = O7_REF(p)->next;
	}
}

static void MarkUsedInMarked(struct Ast_RModule *m) {
	struct Ast_RDeclaration *imp;

	imp = (&(O7_REF(m)->import_)->_);
	while ((imp != NULL) && (o7_is(imp, &Ast_Import__s_tag))) {
		MarkUsedInMarked(O7_REF(O7_REF(imp)->module_)->m);
		imp = O7_REF(imp)->next;
	}
	MarkUsedInMarked_Consts(&O7_REF(m)->_.consts->_);
	MarkUsedInMarked_Types(&O7_REF(m)->_.types->_);
	MarkUsedInMarked_Procs(&O7_REF(m)->_.procedures->_._._);
}

static void ImportInitDone(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *imp, o7_int_t initDone_len0, o7_char initDone[/*len0*/]) {
	if (imp != NULL) {
		O7_ASSERT(o7_is(imp, &Ast_Import__s_tag));

		do {
			Name(&(*gen), &O7_REF(O7_REF(imp)->module_)->m->_._);
			TextGenerator_StrLn(&(*gen)._, initDone_len0, initDone);

			imp = O7_REF(imp)->next;
		} while (!((imp == NULL) || !(o7_is(imp, &Ast_Import__s_tag))));
		TextGenerator_Ln(&(*gen)._);
	}
}

static void ImportInit(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *imp) {
	ImportInitDone(&(*gen), imp, 9, (o7_char *)"_init();");
}

static void ImportDone(struct GeneratorC_Generator *gen, struct Ast_RDeclaration *imp) {
	ImportInitDone(&(*gen), imp, 9, (o7_char *)"_done();");
}

static void TagsInit(struct GeneratorC_Generator *gen) {
	struct Ast_RRecord *r;

	r = NULL;
	while (O7_REF((*gen).opt)->records != NULL) {
		r = O7_REF((*gen).opt)->records;
		O7_REF((*gen).opt)->records = O7_GUARD(RecExt__s, &O7_REF(r)->_._._._.ext)->next;
		O7_GUARD(RecExt__s, &O7_REF(r)->_._._._.ext)->next = NULL;

		if ((o7_cmp(O7_REF((*gen).opt)->memManager, GeneratorC_MemManagerCounter_cnst) == 0) || (O7_REF(r)->base != NULL) && (o7_bl(O7_REF(r)->needTag) || !o7_bl(O7_REF((*gen).opt)->skipUnusedTag))) {
			TextGenerator_Str(&(*gen)._, 13, (o7_char *)"O7_TAG_INIT(");
			GlobalName(&(*gen), &r->_._._);
			if (O7_REF(r)->base != NULL) {
				TextGenerator_Str(&(*gen)._, 3, (o7_char *)", ");
				GlobalName(&(*gen), &O7_REF(r)->base->_._._);
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

static void Generate_Init(struct GeneratorC_Generator *gen, struct VDataStream_Out *out, struct Ast_RModule *module_, struct GeneratorC_Options__s *opt, o7_bool interface_) {
	TextGenerator_Init(&(*gen)._, out);
	(*gen).module_ = module_;
	(*gen).localDeep = 0;

	(*gen).opt = opt;

	(*gen).fixedLen = o7_int((*gen)._.len);

	(*gen).interface_ = interface_;

	(*gen).insideSizeOf = (0 > 1);

	(*gen).memout = NULL;
}

static void Generate_Includes(struct GeneratorC_Generator *gen) {
	if (o7_cmp(O7_REF((*gen).opt)->std, GeneratorC_IsoC99_cnst) >= 0) {
		TextGenerator_StrLn(&(*gen)._, 21, (o7_char *)"#include <stdbool.h>");
	}
	TextGenerator_StrLn(&(*gen)._, 16, (o7_char *)"#include <o7.h>");
	TextGenerator_Ln(&(*gen)._);
}

static void Generate_HeaderGuard(struct GeneratorC_Generator *gen) {
	TextGenerator_Str(&(*gen)._, 27, (o7_char *)"#if !defined HEADER_GUARD_");
	TextGenerator_String(&(*gen)._, &O7_REF((*gen).module_)->_._.name);
	TextGenerator_Ln(&(*gen)._);
	TextGenerator_Str(&(*gen)._, 27, (o7_char *)"#    define  HEADER_GUARD_");
	TextGenerator_String(&(*gen)._, &O7_REF((*gen).module_)->_._.name);
	TextGenerator_StrLn(&(*gen)._, 3, (o7_char *)" 1");
	TextGenerator_Ln(&(*gen)._);
}

static void Generate_ModuleInit(struct GeneratorC_Generator *interf, struct GeneratorC_Generator *impl, struct Ast_RModule *module_, struct Ast_RStatement *cmd) {
	if ((O7_REF(module_)->import_ == NULL) && (O7_REF(module_)->_.stats == NULL) && (cmd == NULL) && (O7_REF((*impl).opt)->records == NULL)) {
		if (o7_cmp(O7_REF((*impl).opt)->std, GeneratorC_IsoC99_cnst) >= 0) {
			TextGenerator_Str(&(*interf)._, 20, (o7_char *)"static inline void ");
		} else {
			TextGenerator_Str(&(*interf)._, 16, (o7_char *)"O7_INLINE void ");
		}
		Name(&(*interf), &module_->_._);
		TextGenerator_StrLn(&(*interf)._, 18, (o7_char *)"_init(void) { ; }");
	} else {
		TextGenerator_Str(&(*interf)._, 13, (o7_char *)"extern void ");
		Name(&(*interf), &module_->_._);
		TextGenerator_StrLn(&(*interf)._, 13, (o7_char *)"_init(void);");

		TextGenerator_Str(&(*impl)._, 13, (o7_char *)"extern void ");
		Name(&(*impl), &module_->_._);
		TextGenerator_StrOpen(&(*impl)._, 14, (o7_char *)"_init(void) {");
		TextGenerator_StrLn(&(*impl)._, 33, (o7_char *)"static unsigned initialized = 0;");
		TextGenerator_StrOpen(&(*impl)._, 24, (o7_char *)"if (0 == initialized) {");
		ImportInit(&(*impl), &O7_REF(module_)->import_->_);
		TagsInit(&(*impl));
		Statements(&(*impl), O7_REF(module_)->_.stats);
		Statements(&(*impl), cmd);
		TextGenerator_StrLnClose(&(*impl)._, 2, (o7_char *)"\x7D");
		TextGenerator_StrLn(&(*impl)._, 15, (o7_char *)"++initialized;");
		TextGenerator_StrLnClose(&(*impl)._, 2, (o7_char *)"\x7D");
		TextGenerator_Ln(&(*impl)._);
	}
}

static void Generate_ModuleDone(struct GeneratorC_Generator *interf, struct GeneratorC_Generator *impl, struct Ast_RModule *module_) {
	if ((o7_cmp(O7_REF((*impl).opt)->memManager, GeneratorC_MemManagerCounter_cnst) != 0)) {
	} else if ((O7_REF(module_)->import_ == NULL) && (O7_REF((*impl).opt)->records == NULL)) {
		if (o7_cmp(O7_REF((*impl).opt)->std, GeneratorC_IsoC99_cnst) >= 0) {
			TextGenerator_Str(&(*interf)._, 20, (o7_char *)"static inline void ");
		} else {
			TextGenerator_Str(&(*interf)._, 16, (o7_char *)"O7_INLINE void ");
		}
		Name(&(*interf), &module_->_._);
		TextGenerator_StrLn(&(*interf)._, 18, (o7_char *)"_done(void) { ; }");
	} else {
		TextGenerator_Str(&(*interf)._, 13, (o7_char *)"extern void ");
		Name(&(*interf), &module_->_._);
		TextGenerator_StrLn(&(*interf)._, 13, (o7_char *)"_done(void);");

		TextGenerator_Str(&(*impl)._, 13, (o7_char *)"extern void ");
		Name(&(*impl), &module_->_._);
		TextGenerator_StrOpen(&(*impl)._, 14, (o7_char *)"_done(void) {");
		ReleaseVars(&(*impl), &O7_REF(module_)->_.vars->_);
		ImportDone(&(*impl), &O7_REF(module_)->import_->_);
		TextGenerator_StrLnClose(&(*impl)._, 2, (o7_char *)"\x7D");
		TextGenerator_Ln(&(*impl)._);
	}
}

static void Generate_Main(struct GeneratorC_Generator *gen, struct Ast_RModule *module_, struct Ast_RStatement *cmd) {
	TextGenerator_StrOpen(&(*gen)._, 42, (o7_char *)"extern int main(int argc, char *argv[]) {");
	TextGenerator_StrLn(&(*gen)._, 21, (o7_char *)"o7_init(argc, argv);");
	ImportInit(&(*gen), &O7_REF(module_)->import_->_);
	TagsInit(&(*gen));
	Statements(&(*gen), O7_REF(module_)->_.stats);
	Statements(&(*gen), cmd);
	if (o7_cmp(O7_REF((*gen).opt)->memManager, GeneratorC_MemManagerCounter_cnst) == 0) {
		ReleaseVars(&(*gen), &O7_REF(module_)->_.vars->_);
		ImportDone(&(*gen), &O7_REF(module_)->import_->_);
	}
	TextGenerator_StrLn(&(*gen)._, 21, (o7_char *)"return o7_exit_code;");
	TextGenerator_StrLnClose(&(*gen)._, 2, (o7_char *)"\x7D");
}

static void Generate_GeneratorNotify(struct GeneratorC_Generator *gen) {
	if (o7_bl(O7_REF((*gen).opt)->generatorNote)) {
		TextGenerator_StrLn(&(*gen)._, 49, (o7_char *)"/* Generated by Vostok - Oberon-07 translator */");
		TextGenerator_Ln(&(*gen)._);
	}
}

extern void GeneratorC_Generate(struct VDataStream_Out *interface_, struct VDataStream_Out *implementation, struct Ast_RModule *module_, struct Ast_RStatement *cmd, struct GeneratorC_Options__s *opt) {
	struct MOut out;
	MOut_undef(&out);

	O7_ASSERT(!Ast_HasError(module_));

	if (opt == NULL) {
		opt = GeneratorC_DefaultOptions();
	}
	out.opt = opt;

	O7_REF(opt)->records = NULL;
	O7_REF(opt)->recordLast = NULL;
	O7_REF(opt)->index = 0;

	O7_REF(opt)->main_ = interface_ == NULL;

	if (!o7_bl(O7_REF(opt)->main_)) {
		MarkUsedInMarked(module_);
	}

	if (interface_ != NULL) {
		Generate_Init(&out.g[Interface_cnst], interface_, module_, opt, (0 < 1));
		Generate_GeneratorNotify(&out.g[Interface_cnst]);
	}

	Generate_Init(&out.g[Implementation_cnst], implementation, module_, opt, (0 > 1));
	Generate_GeneratorNotify(&out.g[Implementation_cnst]);

	Comment(&out.g[o7_ind(2, (o7_int_t)!o7_bl(O7_REF(opt)->main_))], &O7_REF(module_)->_._._.comment);

	Generate_Includes(&out.g[Implementation_cnst]);

	if (!o7_bl(O7_REF(opt)->main_)) {
		Generate_HeaderGuard(&out.g[Interface_cnst]);
		Import(&out.g[Implementation_cnst], &module_->_._);
	}

	Declarations(&out, &module_->_);

	if (o7_bl(O7_REF(opt)->main_)) {
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
		VDataStream_init();
		TextGenerator_init();

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


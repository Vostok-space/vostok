#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#define O7C_BOOL_UNDEFINED
#include <o7c.h>

#include "GeneratorC.h"

#define Interface_cnst 1
#define Implementation_cnst 0

o7c_tag_t GeneratorC_Options_s_tag;
o7c_tag_t GeneratorC_Generator_tag;
typedef struct MemoryOut {
	VDataStream_Out _;
	struct GeneratorC_anon_0000 {
		o7c_char buf[4096];
		int len;
	} mem[2];
	o7c_bool invert;
} MemoryOut;
static o7c_tag_t MemoryOut_tag;

typedef struct MemoryOut *PMemoryOut;
typedef struct MOut {
	struct GeneratorC_Generator g[2];
	struct GeneratorC_Options_s *opt;
} MOut;
static o7c_tag_t MOut_tag;

typedef struct Selectors {
	struct Ast_Designator_s *des;
	struct Ast_RDeclaration *decl;
	struct Ast_RSelector *list[TranslatorLimits_MaxSelectors_cnst];
	int i;
} Selectors;
static o7c_tag_t Selectors_tag;


static void (*type)(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RType *type, o7c_bool typeDecl, o7c_bool sameType) = NULL;
static void (*declarator)(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *decl, o7c_bool typeDecl, o7c_bool sameType, o7c_bool global) = NULL;
static void (*declarations)(struct MOut *out, o7c_tag_t out_tag, struct Ast_RDeclarations *ds) = NULL;
static void (*statements)(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RStatement *stats) = NULL;
static void (*expression)(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *expr) = NULL;

static void MemoryWrite(struct MemoryOut *out, o7c_tag_t out_tag, o7c_char buf[/*len0*/], int buf_len0, int ofs, int count) {
	o7c_bool ret = O7C_BOOL_UNDEF;

	ret = StringStore_CopyChars((*out).mem[o7c_ind(2, (int)(*out).invert)].buf, 4096, &(*out).mem[o7c_ind(2, (int)(*out).invert)].len, buf, buf_len0, ofs, o7c_add(ofs, count));
	assert(o7c_bl(ret));
}

static int MemWrite(struct VDataStream_Out *out, o7c_tag_t out_tag, o7c_char buf[/*len0*/], int buf_len0, int ofs, int count) {
	MemoryWrite(&O7C_GUARD_R(MemoryOut, &(*out), out_tag), MemoryOut_tag, buf, buf_len0, ofs, count);
	return count;
}

static void MemoryOutInit(struct MemoryOut *mo, o7c_tag_t mo_tag) {
	VDataStream_InitOut(&(*mo)._, mo_tag, MemWrite);
	(*mo).mem[0].len = 0;
	(*mo).mem[1].len = 0;
	(*mo).invert = false;
}

static void MemWriteInvert(struct MemoryOut *mo, o7c_tag_t mo_tag) {
	int inv = O7C_INT_UNDEF;
	o7c_bool ret = O7C_BOOL_UNDEF;

	inv = (int)(*mo).invert;
	if (o7c_cmp((*mo).mem[o7c_ind(2, inv)].len, 0) ==  0) {
		(*mo).invert = !(*mo).invert;
	} else {
		ret = StringStore_CopyChars((*mo).mem[o7c_ind(2, inv)].buf, 4096, &(*mo).mem[o7c_ind(2, inv)].len, (*mo).mem[o7c_ind(2, o7c_sub(1, inv))].buf, 4096, 0, (*mo).mem[o7c_ind(2, o7c_sub(1, inv))].len);
		assert(o7c_bl(ret));
		(*mo).mem[o7c_ind(2, o7c_sub(1, inv))].len = 0;
	}
}

static void MemWriteDirect(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct MemoryOut *mo, o7c_tag_t mo_tag) {
	int inv = O7C_INT_UNDEF;

	inv = (int)(*mo).invert;
	assert(o7c_cmp((*mo).mem[o7c_ind(2, o7c_sub(1, inv))].len, 0) ==  0);
	TextGenerator_Data(&(*gen)._, gen_tag, (*mo).mem[o7c_ind(2, inv)].buf, 4096, 0, (*mo).mem[o7c_ind(2, inv)].len);
	(*mo).mem[o7c_ind(2, inv)].len = 0;
}

static o7c_bool IsNameOccupied(struct StringStore_String *n, o7c_tag_t n_tag);
static o7c_bool IsNameOccupied_Eq(struct StringStore_String *name, o7c_tag_t name_tag, o7c_char str[/*len0*/], int str_len0) {
	return StringStore_IsEqualToString(&(*name), name_tag, str, str_len0);
}

static o7c_bool IsNameOccupied(struct StringStore_String *n, o7c_tag_t n_tag) {
	return IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"auto", 5) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"break", 6) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"case", 5) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"char", 5) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"const", 6) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"continue", 9) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"default", 8) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"do", 3) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"double", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"else", 5) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"enum", 5) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"extern", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"float", 6) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"for", 4) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"goto", 5) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"if", 3) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"inline", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"int", 4) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"long", 5) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"register", 9) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"return", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"short", 6) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"signed", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"sizeof", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"static", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"struct", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"switch", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"typedef", 8) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"union", 6) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"unsigned", 9) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"void", 5) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"volatile", 9) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"while", 6) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"asm", 4) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"typeof", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"abort", 6) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"assert", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"bool", 5) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"calloc", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"free", 5) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"main", 5) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"malloc", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"memcmp", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"memcpy", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"memset", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"NULL", 5) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"strcmp", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"strcpy", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"realloc", 8) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"array", 6) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"catch", 6) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"class", 6) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"decltype", 9) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"delegate", 9) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"delete", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"deprecated", 11) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"dllexport", 10) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"dllimport", 10) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"dllexport", 10) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"event", 6) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"explicit", 9) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"finally", 8) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"each", 5) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"in", 3) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"friend", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"gcnew", 6) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"generic", 8) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"initonly", 9) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"interface", 10) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"literal", 8) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"mutable", 8) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"naked", 6) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"namespace", 10) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"new", 4) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"noinline", 9) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"noreturn", 9) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"nothrow", 8) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"novtable", 9) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"nullptr", 8) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"operator", 9) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"private", 8) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"property", 9) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"protected", 10) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"public", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"ref", 4) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"safecast", 9) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"sealed", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"selectany", 10) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"super", 6) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"template", 9) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"this", 5) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"thread", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"throw", 6) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"try", 4) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"typeid", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"typename", 9) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"uuid", 5) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"value", 6) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"virtual", 8) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"abstract", 9) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"arguments", 10) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"boolean", 8) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"byte", 5) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"debugger", 9) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"eval", 5) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"export", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"extends", 8) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"final", 6) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"function", 9) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"implements", 11) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"import", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"instanceof", 11) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"interface", 10) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"let", 4) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"native", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"null", 5) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"package", 8) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"private", 8) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"protected", 10) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"synchronized", 13) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"throws", 7) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"transient", 10) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"var", 4) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"func", 5) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"o7c", 4) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"O7C", 4) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"initialized", 12) || IsNameOccupied_Eq(&(*n), n_tag, (o7c_char *)"init", 5);
}

static void Name(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *decl) {
	struct Ast_RDeclarations *up = NULL;

	if ((o7c_is(decl, Ast_RType_tag)) && (decl->up != &decl->module->_) && (decl->up != NULL) || !(*gen).opt->procLocal && (o7c_is(decl, Ast_RProcedure_tag))) {
		up = decl->up;
		while (!(o7c_is(up, Ast_RModule_tag))) {
			TextGenerator_String(&(*gen)._, gen_tag, &up->_.name, StringStore_String_tag);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"_", 2);
			up = up->_.up;
		}
	}
	TextGenerator_String(&(*gen)._, gen_tag, &decl->name, StringStore_String_tag);
	if (o7c_is(decl, Ast_Const_s_tag)) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"_cnst", 6);
	} else if (IsNameOccupied(&decl->name, StringStore_String_tag)) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"_", 2);
	}
}

static void GlobalName(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *decl) {
	if (o7c_bl(decl->mark) || (decl->module != NULL) && ((*gen).module != decl->module)) {
		assert(decl->module != NULL);
		TextGenerator_String(&(*gen)._, gen_tag, &decl->module->_._.name, StringStore_String_tag);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"_", 2);
		TextGenerator_String(&(*gen)._, gen_tag, &decl->name, StringStore_String_tag);
		if (o7c_is(decl, Ast_Const_s_tag)) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"_cnst", 6);
		}
	} else {
		Name(&(*gen), gen_tag, decl);
	}
}

static void Import(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *decl) {
	TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"#include ", 10);
	TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"\x22", 2);
	if (o7c_is(decl, Ast_RModule_tag)) {
		TextGenerator_String(&(*gen)._, gen_tag, &decl->name, StringStore_String_tag);
	} else {
		assert(o7c_is(decl, Ast_Import_s_tag));
		TextGenerator_String(&(*gen)._, gen_tag, &decl->module->_._.name, StringStore_String_tag);
	}
	TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)".h", 3);
	TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"\x22", 2);
}

static void Factor(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *expr) {
	if (o7c_is(expr, Ast_RFactor_tag)) {
		expression(&(*gen), gen_tag, expr);
	} else {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(", 2);
		expression(&(*gen), gen_tag, expr);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
	}
}

static o7c_bool CheckStructName(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_Record_s *rec) {
	o7c_char anon[TranslatorLimits_MaxLenName_cnst * 2 + 3] ;
	int i = O7C_INT_UNDEF, j = O7C_INT_UNDEF, l = O7C_INT_UNDEF;
	o7c_bool ret = O7C_BOOL_UNDEF, corr = O7C_BOOL_UNDEF;
	memset(&anon, 0, sizeof(anon));

	if (!StringStore_IsDefined(&rec->_._._.name, StringStore_String_tag)) {
		if ((rec->pointer != NULL) && StringStore_IsDefined(&rec->pointer->_._._.name, StringStore_String_tag)) {
			l = 0;
			assert(rec->_._._.module != NULL);
			rec->_._._.mark = true;
			corr = StringStore_CopyToChars(anon, TranslatorLimits_MaxLenName_cnst * 2 + 3, &l, &rec->pointer->_._._.name, StringStore_String_tag);
			anon[o7c_ind(TranslatorLimits_MaxLenName_cnst * 2 + 3, l)] = (char unsigned)'_';
			anon[o7c_ind(TranslatorLimits_MaxLenName_cnst * 2 + 3, o7c_add(l, 1))] = (char unsigned)'s';
			anon[o7c_ind(TranslatorLimits_MaxLenName_cnst * 2 + 3, o7c_add(l, 2))] = 0x00u;
			Ast_PutChars(rec->pointer->_._._.module, &rec->_._._.name, StringStore_String_tag, anon, TranslatorLimits_MaxLenName_cnst * 2 + 3, 0, o7c_add(l, 2));
		} else {
			l = 0;
			corr = StringStore_CopyToChars(anon, TranslatorLimits_MaxLenName_cnst * 2 + 3, &l, &rec->_._._.module->_._.name, StringStore_String_tag);
			anon[o7c_ind(TranslatorLimits_MaxLenName_cnst * 2 + 3, l)] = (char unsigned)'_';
			l = o7c_add(l, 1);
			Log_StrLn((o7c_char *)"Record", 7);
			ret = StringStore_CopyChars(anon, TranslatorLimits_MaxLenName_cnst * 2 + 3, &l, (o7c_char *)"anon_0000", 10, 0, 9);
			assert(o7c_bl(ret));
			assert((o7c_cmp((*gen).opt->index, 0) >=  0) && (o7c_cmp((*gen).opt->index, 10000) <  0));
			i = (*gen).opt->index;
			/*Log.Int(i); Log.Ln;*/
			j = o7c_sub(l, 1);
			while (o7c_cmp(i, 0) >  0) {
				anon[o7c_ind(TranslatorLimits_MaxLenName_cnst * 2 + 3, j)] = o7c_chr(o7c_add((int)(char unsigned)'0', o7c_mod(i, 10)));
				i = o7c_div(i, 10);
				j = o7c_sub(j, 1);
			}
			(*gen).opt->index = o7c_add((*gen).opt->index, 1);
			Ast_PutChars(rec->_._._.module, &rec->_._._.name, StringStore_String_tag, anon, TranslatorLimits_MaxLenName_cnst * 2 + 3, 0, l);
		}
		assert(o7c_bl(corr));
	}
	return StringStore_IsDefined(&rec->_._._.name, StringStore_String_tag);
}

static void ArrayDeclLen(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RType *type, struct Ast_RDeclaration *decl, struct Ast_RSelector *sel) {
	int i = O7C_INT_UNDEF;

	if (O7C_GUARD(Ast_RArray, &type)->count != NULL) {
		expression(&(*gen), gen_tag, O7C_GUARD(Ast_RArray, &type)->count);
	} else {
		GlobalName(&(*gen), gen_tag, decl);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"_len", 5);
		i =  - 1;
		while (sel != NULL) {
			i = o7c_add(i, 1);
			sel = sel->next;
		}
		TextGenerator_Int(&(*gen)._, gen_tag, i);
	}
}

static void ArrayLen(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *e) {
	int i = O7C_INT_UNDEF;
	struct Ast_Designator_s *des = NULL;
	struct Ast_RType *t = NULL;

	if (O7C_GUARD(Ast_RArray, &e->type)->count != NULL) {
		expression(&(*gen), gen_tag, O7C_GUARD(Ast_RArray, &e->type)->count);
	} else {
		des = O7C_GUARD(Ast_Designator_s, &e);
		GlobalName(&(*gen), gen_tag, des->decl);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"_len", 5);
		i = 0;
		t = des->_._.type;
		while (t != e->type) {
			i = o7c_add(i, 1);
			t = t->_.type;
		}
		TextGenerator_Int(&(*gen)._, gen_tag, i);
	}
}

static void Selector(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Selectors *sels, o7c_tag_t sels_tag, int i, struct Ast_RType **typ, struct Ast_RType *desType);
static void Selector_Record(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RType **type, struct Ast_RSelector **sel);
static o7c_bool Record_Selector_Search(struct Ast_Record_s *ds, struct Ast_RDeclaration *d) {
	struct Ast_RDeclaration *c = NULL;

	c = (&(ds->vars)->_);
	while ((c != NULL) && (c != d)) {
		c = c->next;
	}
	return c != NULL;
}

static void Selector_Record(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RType **type, struct Ast_RSelector **sel) {
	struct Ast_RDeclaration *var_ = NULL;
	struct Ast_Record_s *up = NULL;

	var_ = (&(O7C_GUARD(Ast_SelRecord_s, &(*sel))->var_)->_);
	if (o7c_is((*type), Ast_RPointer_tag)) {
		up = O7C_GUARD(Ast_Record_s, &O7C_GUARD(Ast_RPointer, &(*type))->_._._.type);
	} else {
		up = O7C_GUARD(Ast_Record_s, &(*type));
	}
	if (o7c_cmp((*type)->_._.id, Ast_IdPointer_cnst) ==  0) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"->", 3);
	} else {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)".", 2);
	}
	if (!(*gen).opt->plan9) {
		while ((up != NULL) && !Record_Selector_Search(up, var_)) {
			up = up->base;
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"_.", 3);
		}
	}
	Name(&(*gen), gen_tag, var_);
	(*type) = var_->type;
}

static void Selector_Declarator(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *decl) {
	struct Ast_RType *type = NULL;

	type = decl->type;
	if ((o7c_is(decl, Ast_FormalParam_s_tag)) && (o7c_bl(O7C_GUARD(Ast_FormalParam_s, &decl)->isVar) && (o7c_cmp(type->_._.id, Ast_IdArray_cnst) !=  0) || (o7c_cmp(type->_._.id, Ast_IdRecord_cnst) ==  0))) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(*", 3);
		GlobalName(&(*gen), gen_tag, decl);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
	} else {
		GlobalName(&(*gen), gen_tag, decl);
	}
}

static void Selector_Array(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RType **type, struct Ast_RSelector **sel, struct Ast_RDeclaration *decl, o7c_bool isDesignatorArray);
static void Array_Selector_Mult(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *decl, int j, struct Ast_RType *t) {
	while ((t != NULL) && (o7c_is(t, Ast_RArray_tag))) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" * ", 4);
		Name(&(*gen), gen_tag, decl);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"_len", 5);
		TextGenerator_Int(&(*gen)._, gen_tag, j);
		j = o7c_add(j, 1);
		t = t->_.type;
	}
}

static void Selector_Array(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RType **type, struct Ast_RSelector **sel, struct Ast_RDeclaration *decl, o7c_bool isDesignatorArray) {
	int i = O7C_INT_UNDEF;

	if (isDesignatorArray) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" + ", 4);
	} else {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"[", 2);
	}
	if ((o7c_cmp((*type)->_.type->_._.id, Ast_IdArray_cnst) !=  0) || (O7C_GUARD(Ast_RArray, &(*type))->count != NULL)) {
		if (o7c_bl((*gen).opt->checkIndex) && ((O7C_GUARD(Ast_SelArray_s, &(*sel))->index->value_ == NULL) || (O7C_GUARD(Ast_RArray, &(*type))->count == NULL) && (o7c_cmp(O7C_GUARD(Ast_RExprInteger, &O7C_GUARD(Ast_SelArray_s, &(*sel))->index->value_)->int_, 0) !=  0))) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_ind(", 9);
			ArrayDeclLen(&(*gen), gen_tag, (*type), decl, (*sel));
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
			expression(&(*gen), gen_tag, O7C_GUARD(Ast_SelArray_s, &(*sel))->index);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
		} else {
			expression(&(*gen), gen_tag, O7C_GUARD(Ast_SelArray_s, &(*sel))->index);
		}
		(*type) = (*type)->_.type;
		(*sel) = (*sel)->next;
		while (((*sel) != NULL) && (o7c_is((*sel), Ast_SelArray_s_tag))) {
			if (o7c_bl((*gen).opt->checkIndex) && ((O7C_GUARD(Ast_SelArray_s, &(*sel))->index->value_ == NULL) || (O7C_GUARD(Ast_RArray, &(*type))->count == NULL) && (o7c_cmp(O7C_GUARD(Ast_RExprInteger, &O7C_GUARD(Ast_SelArray_s, &(*sel))->index->value_)->int_, 0) !=  0))) {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"][o7c_ind(", 11);
				ArrayDeclLen(&(*gen), gen_tag, (*type), decl, (*sel));
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
				expression(&(*gen), gen_tag, O7C_GUARD(Ast_SelArray_s, &(*sel))->index);
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
			} else {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"][", 3);
				expression(&(*gen), gen_tag, O7C_GUARD(Ast_SelArray_s, &(*sel))->index);
			}
			(*sel) = (*sel)->next;
			(*type) = (*type)->_.type;
		}
	} else {
		i = 0;
		while (((*sel)->next != NULL) && (o7c_is((*sel)->next, Ast_SelArray_s_tag))) {
			Factor(&(*gen), gen_tag, O7C_GUARD(Ast_SelArray_s, &(*sel))->index);
			(*type) = (*type)->_.type;
			Array_Selector_Mult(&(*gen), gen_tag, decl, o7c_add(i, 1), (*type));
			(*sel) = (*sel)->next;
			i = o7c_add(i, 1);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" + ", 4);
		}
		Factor(&(*gen), gen_tag, O7C_GUARD(Ast_SelArray_s, &(*sel))->index);
		Array_Selector_Mult(&(*gen), gen_tag, decl, o7c_add(i, 1), (*type)->_.type);
	}
	if (!isDesignatorArray) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"]", 2);
	}
}

static void Selector(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Selectors *sels, o7c_tag_t sels_tag, int i, struct Ast_RType **typ, struct Ast_RType *desType) {
	struct Ast_RSelector *sel = NULL;
	o7c_bool ret = O7C_BOOL_UNDEF;

	if (o7c_cmp(i, 0) <  0) {
		Selector_Declarator(&(*gen), gen_tag, (*sels).decl);
	} else {
		sel = (*sels).list[o7c_ind(TranslatorLimits_MaxSelectors_cnst, i)];
		i = o7c_sub(i, 1);
		if (o7c_is(sel, Ast_SelRecord_s_tag)) {
			Selector(&(*gen), gen_tag, &(*sels), sels_tag, i, &(*typ), desType);
			Selector_Record(&(*gen), gen_tag, &(*typ), &sel);
		} else if (o7c_is(sel, Ast_SelArray_s_tag)) {
			Selector(&(*gen), gen_tag, &(*sels), sels_tag, i, &(*typ), desType);
			Selector_Array(&(*gen), gen_tag, &(*typ), &sel, (*sels).decl, (o7c_cmp(desType->_._.id, Ast_IdArray_cnst) ==  0) && (O7C_GUARD(Ast_RArray, &desType)->count == NULL));
		} else if (o7c_is(sel, Ast_SelPointer_s_tag)) {
			if ((sel->next == NULL) || !(o7c_is(sel->next, Ast_SelRecord_s_tag))) {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(*", 3);
				Selector(&(*gen), gen_tag, &(*sels), sels_tag, i, &(*typ), desType);
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
			} else {
				Selector(&(*gen), gen_tag, &(*sels), sels_tag, i, &(*typ), desType);
			}
		} else if (o7c_is(sel, Ast_SelGuard_s_tag)) {
			if (o7c_cmp(O7C_GUARD(Ast_SelGuard_s, &sel)->type->_._.id, Ast_IdPointer_cnst) ==  0) {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"O7C_GUARD(", 11);
				ret = CheckStructName(&(*gen), gen_tag, O7C_GUARD(Ast_Record_s, &O7C_GUARD(Ast_SelGuard_s, &sel)->type->_.type));
				assert(o7c_bl(ret));
				GlobalName(&(*gen), gen_tag, &O7C_GUARD(Ast_SelGuard_s, &sel)->type->_.type->_);
			} else {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"O7C_GUARD_R(", 13);
				GlobalName(&(*gen), gen_tag, &O7C_GUARD(Ast_SelGuard_s, &sel)->type->_);
			}
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", &", 4);
			Selector(&(*gen), gen_tag, &(*sels), sels_tag, i, &(*typ), desType);
			if (o7c_cmp(O7C_GUARD(Ast_SelGuard_s, &sel)->type->_._.id, Ast_IdPointer_cnst) ==  0) {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
			} else {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
				GlobalName(&(*gen), gen_tag, (*sels).decl);
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"_tag)", 6);
			}
			(*typ) = O7C_GUARD(Ast_SelGuard_s, &sel)->type;
		} else {
			assert(false);
		}
	}
}

static void Designator(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_Designator_s *des);
static void Designator_Put(struct Selectors *sels, o7c_tag_t sels_tag, struct Ast_RSelector *sel) {
	(*sels).i =  - 1;
	while (sel != NULL) {
		(*sels).i = o7c_add((*sels).i, 1);
		(*sels).list[o7c_ind(TranslatorLimits_MaxSelectors_cnst, (*sels).i)] = sel;
		if (o7c_is(sel, Ast_SelArray_s_tag)) {
			while ((sel != NULL) && (o7c_is(sel, Ast_SelArray_s_tag))) {
				sel = sel->next;
			}
		} else {
			sel = sel->next;
		}
	}
}

static void Designator(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_Designator_s *des) {
	struct Selectors sels ;
	struct Ast_RType *typ = NULL;
	memset(&sels, 0, sizeof(sels));

	Designator_Put(&sels, Selectors_tag, des->sel);
	typ = des->decl->type;
	sels.des = des;
	sels.decl = des->decl;
	/* TODO */
	(*gen).opt->lastSelectorDereference = (o7c_cmp(sels.i, 0) >  0) && (o7c_is(sels.list[o7c_ind(TranslatorLimits_MaxSelectors_cnst, sels.i)], Ast_SelPointer_s_tag));
	Selector(&(*gen), gen_tag, &sels, Selectors_tag, sels.i, &typ, des->_._.type);
}

static void CheckExpr(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *e) {
	if ((o7c_cmp((*gen).opt->varInit, GeneratorC_VarInitUndefined_cnst) ==  0) && (o7c_is(e, Ast_Designator_s_tag)) && (o7c_cmp(e->type->_._.id, Ast_IdBoolean_cnst) ==  0) && (e->value_ == NULL)) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_bl(", 8);
		expression(&(*gen), gen_tag, e);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
	} else {
		expression(&(*gen), gen_tag, e);
	}
}

static void Expression(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *expr);
static void Expression_Call(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ExprCall_s *call);
static void Call_Expression_Predefined(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ExprCall_s *call);
static void Predefined_Call_Expression_Shift(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, o7c_char shift[/*len0*/], int shift_len0, struct Ast_Parameter_s *ps) {
	TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(int)((unsigned)", 17);
	Factor(&(*gen), gen_tag, ps->expr);
	TextGenerator_Str(&(*gen)._, gen_tag, shift, shift_len0);
	Factor(&(*gen), gen_tag, ps->next->expr);
	TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
}

static void Predefined_Call_Expression_Len(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *e) {
	struct Ast_RSelector *sel = NULL;
	int i = O7C_INT_UNDEF;
	struct Ast_Designator_s *des = NULL;
	struct Ast_RExpression *count = NULL;
	o7c_bool sizeof_ = O7C_BOOL_UNDEF;

	count = O7C_GUARD(Ast_RArray, &e->type)->count;
	if (o7c_is(e, Ast_Designator_s_tag)) {
		des = O7C_GUARD(Ast_Designator_s, &e);
		sizeof_ = !(o7c_is(O7C_GUARD(Ast_Designator_s, &e)->decl, Ast_Const_s_tag)) && ((o7c_cmp(des->decl->type->_._.id, Ast_IdArray_cnst) !=  0) || !(o7c_is(des->decl, Ast_FormalParam_s_tag)));
	} else {
		sizeof_ = false;
	}
	if ((count != NULL) && !sizeof_) {
		Expression(&(*gen), gen_tag, count);
	} else if (sizeof_) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"sizeof(", 8);
		Designator(&(*gen), gen_tag, des);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)") / sizeof (", 13);
		Designator(&(*gen), gen_tag, des);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"[0])", 5);
	} else {
		GlobalName(&(*gen), gen_tag, des->decl);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"_len", 5);
		i = 0;
		sel = des->sel;
		while (sel != NULL) {
			i = o7c_add(i, 1);
			sel = sel->next;
		}
		TextGenerator_Int(&(*gen)._, gen_tag, i);
	}
}

static void Predefined_Call_Expression_New(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *e) {
	o7c_bool ret = O7C_BOOL_UNDEF;

	TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"O7C_NEW(&", 10);
	Expression(&(*gen), gen_tag, e);
	TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
	ret = CheckStructName(&(*gen), gen_tag, O7C_GUARD(Ast_Record_s, &e->type->_.type));
	assert(o7c_bl(ret));
	GlobalName(&(*gen), gen_tag, &e->type->_.type->_);
	TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"_tag)", 6);
}

static void Predefined_Call_Expression_Ord(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *e) {
	TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(int)", 6);
	Factor(&(*gen), gen_tag, e);
}

static void Predefined_Call_Expression_Inc(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *e1, struct Ast_Parameter_s *p2) {
	Expression(&(*gen), gen_tag, e1);
	if ((*gen).opt->checkArith) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" = o7c_add(", 12);
		Expression(&(*gen), gen_tag, e1);
		if (p2 == NULL) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", 1)", 5);
		} else {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
			Expression(&(*gen), gen_tag, p2->expr);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
		}
	} else if (p2 == NULL) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"++", 3);
	} else {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" += ", 5);
		Expression(&(*gen), gen_tag, p2->expr);
	}
}

static void Predefined_Call_Expression_Dec(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *e1, struct Ast_Parameter_s *p2) {
	Expression(&(*gen), gen_tag, e1);
	if ((*gen).opt->checkArith) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" = o7c_sub(", 12);
		Expression(&(*gen), gen_tag, e1);
		if (p2 == NULL) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", 1)", 5);
		} else {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
			Expression(&(*gen), gen_tag, p2->expr);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
		}
	} else if (p2 == NULL) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"--", 3);
	} else {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" -= ", 5);
		Expression(&(*gen), gen_tag, p2->expr);
	}
}

static void Call_Expression_Predefined(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ExprCall_s *call) {
	struct Ast_RExpression *e1 = NULL;
	struct Ast_Parameter_s *p2 = NULL;

	e1 = call->params->expr;
	p2 = call->params->next;
	switch (call->designator->decl->_.id) {
	case 90:
		if (o7c_cmp(call->_._.type->_._.id, Ast_IdInteger_cnst) ==  0) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"abs(", 5);
		} else {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"fabs(", 6);
		}
		Expression(&(*gen), gen_tag, e1);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
		break;
	case 107:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(", 2);
		Factor(&(*gen), gen_tag, e1);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" % 2 == 1)", 11);
		break;
	case 104:
		Predefined_Call_Expression_Len(&(*gen), gen_tag, e1);
		break;
	case 105:
		Predefined_Call_Expression_Shift(&(*gen), gen_tag, (o7c_char *)" << ", 5, call->params);
		break;
	case 91:
		Predefined_Call_Expression_Shift(&(*gen), gen_tag, (o7c_char *)" >> ", 5, call->params);
		break;
	case 111:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7_ror(", 8);
		Expression(&(*gen), gen_tag, e1);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
		Expression(&(*gen), gen_tag, p2->expr);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
		break;
	case 99:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(int)", 6);
		Factor(&(*gen), gen_tag, e1);
		break;
	case 100:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(double)", 9);
		Factor(&(*gen), gen_tag, e1);
		break;
	case 108:
		Predefined_Call_Expression_Ord(&(*gen), gen_tag, e1);
		break;
	case 96:
		if (o7c_bl((*gen).opt->checkArith) && (e1->value_ == NULL)) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_chr(", 9);
			Expression(&(*gen), gen_tag, e1);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
		} else {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(char unsigned)", 16);
			Factor(&(*gen), gen_tag, e1);
		}
		break;
	case 101:
		Predefined_Call_Expression_Inc(&(*gen), gen_tag, e1, p2);
		break;
	case 97:
		Predefined_Call_Expression_Dec(&(*gen), gen_tag, e1, p2);
		break;
	case 102:
		Expression(&(*gen), gen_tag, e1);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" |= 1u << ", 11);
		Factor(&(*gen), gen_tag, p2->expr);
		break;
	case 98:
		Expression(&(*gen), gen_tag, e1);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" &= ~(1u << ", 13);
		Factor(&(*gen), gen_tag, p2->expr);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
		break;
	case 106:
		Predefined_Call_Expression_New(&(*gen), gen_tag, e1);
		break;
	case 92:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"assert(", 8);
		CheckExpr(&(*gen), gen_tag, e1);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
		break;
	case 109:
		Expression(&(*gen), gen_tag, e1);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" *= 1 << ", 10);
		Expression(&(*gen), gen_tag, p2->expr);
		break;
	case 113:
		Expression(&(*gen), gen_tag, e1);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" /= 1 << ", 10);
		Expression(&(*gen), gen_tag, p2->expr);
		break;
	default:
		abort();
		break;
	}
}

static void Call_Expression_ActualParam(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_Parameter_s **p, struct Ast_RDeclaration **fp);
static int ActualParam_Call_Expression_ArrayDeep(struct Ast_RType *t) {
	int d = O7C_INT_UNDEF;

	d = 0;
	while (o7c_cmp(t->_._.id, Ast_IdArray_cnst) ==  0) {
		t = t->_.type;
		d = o7c_add(d, 1);
	}
	return d;
}

static void Call_Expression_ActualParam(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_Parameter_s **p, struct Ast_RDeclaration **fp) {
	struct Ast_RType *t = NULL;
	int i = O7C_INT_UNDEF, j = O7C_INT_UNDEF, dist = O7C_INT_UNDEF;

	t = (*fp)->type;
	if ((o7c_cmp(t->_._.id, Ast_IdByte_cnst) ==  0) && (o7c_cmp((*p)->expr->type->_._.id, Ast_IdInteger_cnst) ==  0) && o7c_bl((*gen).opt->checkArith) && ((*p)->expr->value_ == NULL)) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_byte(", 10);
		Expression(&(*gen), gen_tag, (*p)->expr);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
	} else {
		dist = (*p)->distance;
		if ((o7c_bl(O7C_GUARD(Ast_FormalParam_s, &(*fp))->isVar) && !(o7c_is(t, Ast_RArray_tag))) || (o7c_is(t, Ast_Record_s_tag)) || (o7c_cmp(t->_._.id, Ast_IdPointer_cnst) ==  0) && (o7c_cmp(dist, 0) >  0) && !(*gen).opt->plan9) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"&", 2);
		}
		(*gen).opt->lastSelectorDereference = false;
		Expression(&(*gen), gen_tag, (*p)->expr);
		if ((o7c_cmp(dist, 0) >  0) && !(*gen).opt->plan9) {
			if (o7c_cmp(t->_._.id, Ast_IdPointer_cnst) ==  0) {
				dist = o7c_sub(dist, 1);
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"->_", 4);
			}
			while (o7c_cmp(dist, 0) >  0) {
				dist = o7c_sub(dist, 1);
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"._", 3);
			}
		}
		t = (*p)->expr->type;
		if (o7c_cmp(t->_._.id, Ast_IdRecord_cnst) ==  0) {
			if ((*gen).opt->lastSelectorDereference) {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", NULL", 7);
			} else {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
				if ((o7c_is(O7C_GUARD(Ast_Designator_s, &(*p)->expr)->decl, Ast_FormalParam_s_tag)) && (O7C_GUARD(Ast_Designator_s, &(*p)->expr)->sel == NULL)) {
					Name(&(*gen), gen_tag, O7C_GUARD(Ast_Designator_s, &(*p)->expr)->decl);
				} else {
					GlobalName(&(*gen), gen_tag, &t->_);
				}
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"_tag", 5);
			}
		} else if (o7c_cmp((*fp)->type->_._.id, Ast_IdChar_cnst) !=  0) {
			i =  - 1;
			while ((o7c_cmp(t->_._.id, Ast_IdArray_cnst) ==  0) && (O7C_GUARD(Ast_RArray, &(*fp)->type)->count == NULL)) {
				if ((o7c_cmp(i,  - 1) ==  0) && (o7c_is((*p)->expr, Ast_Designator_s_tag))) {
					i = o7c_sub(ActualParam_Call_Expression_ArrayDeep(O7C_GUARD(Ast_Designator_s, &(*p)->expr)->decl->type), ActualParam_Call_Expression_ArrayDeep((*fp)->type));
					if (!(o7c_is(O7C_GUARD(Ast_Designator_s, &(*p)->expr)->decl, Ast_FormalParam_s_tag))) {
						j = ActualParam_Call_Expression_ArrayDeep(O7C_GUARD(Ast_Designator_s, &(*p)->expr)->_._.type);
						while (o7c_cmp(j, 1) >  0) {
							j = o7c_sub(j, 1);
							TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"[0]", 4);
						}
					}
				}
				if (O7C_GUARD(Ast_RArray, &t)->count != NULL) {
					TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
					Expression(&(*gen), gen_tag, O7C_GUARD(Ast_RArray, &t)->count);
				} else {
					TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
					Name(&(*gen), gen_tag, O7C_GUARD(Ast_Designator_s, &(*p)->expr)->decl);
					TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"_len", 5);
					TextGenerator_Int(&(*gen)._, gen_tag, i);
				}
				i = o7c_add(i, 1);
				t = t->_.type;
			}
		}
	}
	(*p) = (*p)->next;
	(*fp) = (*fp)->next;
}

static void Expression_Call(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ExprCall_s *call) {
	struct Ast_Parameter_s *p = NULL;
	struct Ast_RDeclaration *fp = NULL;

	if (o7c_is(call->designator->decl, Ast_PredefinedProcedure_s_tag)) {
		Call_Expression_Predefined(&(*gen), gen_tag, call);
	} else {
		Designator(&(*gen), gen_tag, call->designator);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(", 2);
		p = call->params;
		fp = (&(O7C_GUARD(Ast_ProcType_s, &call->designator->_._.type)->params)->_._);
		if (p != NULL) {
			Call_Expression_ActualParam(&(*gen), gen_tag, &p, &fp);
			while (p != NULL) {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
				Call_Expression_ActualParam(&(*gen), gen_tag, &p, &fp);
			}
		}
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
	}
}

static void Expression_Relation(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ExprRelation_s *rel);
static void Relation_Expression_Simple(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ExprRelation_s *rel, o7c_char str[/*len0*/], int str_len0);
static void Simple_Relation_Expression_Expr(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *e, int dist) {
	o7c_bool brace = O7C_BOOL_UNDEF;

	brace = (o7c_cmp(e->type->_._.id, Ast_IdSet_cnst) ==  0) && !(o7c_is(e, Ast_RFactor_tag));
	if (brace) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(", 2);
	} else if ((o7c_cmp(dist, 0) >  0) && (o7c_cmp(e->type->_._.id, Ast_IdPointer_cnst) ==  0) && !(*gen).opt->plan9) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"&", 2);
	}
	Expression(&(*gen), gen_tag, e);
	if ((o7c_cmp(dist, 0) >  0) && !(*gen).opt->plan9) {
		if (o7c_cmp(e->type->_._.id, Ast_IdPointer_cnst) ==  0) {
			dist = o7c_sub(dist, 1);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"->_", 4);
		}
		while (o7c_cmp(dist, 0) >  0) {
			dist = o7c_sub(dist, 1);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"._", 3);
		}
	}
	if (brace) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
	}
}

static void Simple_Relation_Expression_Len(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *e) {
	struct Ast_Designator_s *des = NULL;

	if (O7C_GUARD(Ast_RArray, &e->type)->count != NULL) {
		Expression(&(*gen), gen_tag, O7C_GUARD(Ast_RArray, &e->type)->count);
	} else {
		des = O7C_GUARD(Ast_Designator_s, &e);
		ArrayDeclLen(&(*gen), gen_tag, des->_._.type, des->decl, des->sel);
	}
}

static void Relation_Expression_Simple(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ExprRelation_s *rel, o7c_char str[/*len0*/], int str_len0) {
	if ((o7c_cmp(rel->exprs[0]->type->_._.id, Ast_IdArray_cnst) ==  0) && ((rel->exprs[0]->value_ == NULL) || !O7C_GUARD(Ast_ExprString_s, &rel->exprs[0]->value_)->asChar)) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_strcmp(", 12);
		Simple_Relation_Expression_Expr(&(*gen), gen_tag, rel->exprs[0], o7c_sub(0, rel->distance));
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
		Simple_Relation_Expression_Len(&(*gen), gen_tag, rel->exprs[0]);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
		Simple_Relation_Expression_Expr(&(*gen), gen_tag, rel->exprs[1], rel->distance);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
		Simple_Relation_Expression_Len(&(*gen), gen_tag, rel->exprs[1]);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
		TextGenerator_Str(&(*gen)._, gen_tag, str, str_len0);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"0", 2);
	} else if ((o7c_cmp((*gen).opt->varInit, GeneratorC_VarInitUndefined_cnst) ==  0) && (rel->_.value_ == NULL) && (o7c_cmp(rel->exprs[0]->type->_._.id, Ast_IdInteger_cnst) ==  0)) {
		/* TODO */
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_cmp(", 9);
		Simple_Relation_Expression_Expr(&(*gen), gen_tag, rel->exprs[0], o7c_sub(0, rel->distance));
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
		Simple_Relation_Expression_Expr(&(*gen), gen_tag, rel->exprs[1], rel->distance);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
		TextGenerator_Str(&(*gen)._, gen_tag, str, str_len0);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" 0", 3);
	} else {
		Simple_Relation_Expression_Expr(&(*gen), gen_tag, rel->exprs[0], o7c_sub(0, rel->distance));
		TextGenerator_Str(&(*gen)._, gen_tag, str, str_len0);
		Simple_Relation_Expression_Expr(&(*gen), gen_tag, rel->exprs[1], rel->distance);
	}
}

static void Relation_Expression_In(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ExprRelation_s *rel) {
	if ((rel->exprs[0]->value_ != NULL) && (o7c_in(O7C_GUARD(Ast_RExprInteger, &rel->exprs[0]->value_)->int_, O7C_SET(0, Limits_SetMax_cnst)))) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"!!(", 4);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" (1u << ", 9);
		Factor(&(*gen), gen_tag, rel->exprs[0]);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)") & ", 5);
		Factor(&(*gen), gen_tag, rel->exprs[1]);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
	} else {
		if (rel->_.value_ != NULL) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"O7C_IN(", 8);
		} else {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_in(", 8);
		}
		Expression(&(*gen), gen_tag, rel->exprs[0]);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
		Expression(&(*gen), gen_tag, rel->exprs[1]);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
	}
}

static void Expression_Relation(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ExprRelation_s *rel) {
	switch (rel->relation) {
	case 21:
		Relation_Expression_Simple(&(*gen), gen_tag, rel, (o7c_char *)" == ", 5);
		break;
	case 22:
		Relation_Expression_Simple(&(*gen), gen_tag, rel, (o7c_char *)" != ", 5);
		break;
	case 23:
		Relation_Expression_Simple(&(*gen), gen_tag, rel, (o7c_char *)" < ", 4);
		break;
	case 24:
		Relation_Expression_Simple(&(*gen), gen_tag, rel, (o7c_char *)" <= ", 5);
		break;
	case 25:
		Relation_Expression_Simple(&(*gen), gen_tag, rel, (o7c_char *)" > ", 4);
		break;
	case 26:
		Relation_Expression_Simple(&(*gen), gen_tag, rel, (o7c_char *)" >= ", 5);
		break;
	case 27:
		Relation_Expression_In(&(*gen), gen_tag, rel);
		break;
	default:
		abort();
		break;
	}
}

static void Expression_Sum(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ExprSum_s *sum) {
	o7c_bool first = O7C_BOOL_UNDEF;

	first = true;
	do {
		if (o7c_cmp(sum->add, Scanner_Minus_cnst) ==  0) {
			if (o7c_cmp(sum->_.type->_._.id, Ast_IdSet_cnst) !=  0) {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" - ", 4);
			} else if (first) {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" ~", 3);
			} else {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" & ~", 5);
			}
		} else if (o7c_cmp(sum->add, Scanner_Plus_cnst) ==  0) {
			if (o7c_cmp(sum->_.type->_._.id, Ast_IdSet_cnst) ==  0) {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" | ", 4);
			} else {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" + ", 4);
			}
		} else if (o7c_cmp(sum->add, Scanner_Or_cnst) ==  0) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" || ", 5);
		}
		CheckExpr(&(*gen), gen_tag, sum->term);
		sum = sum->next;
		first = false;
	} while (!(sum == NULL));
}

static void Expression_SumCheck(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ExprSum_s *sum) {
	struct Ast_ExprSum_s *arr[TranslatorLimits_MaxTermsInSum_cnst] ;
	int i = O7C_INT_UNDEF, last = O7C_INT_UNDEF;
	memset(&arr, 0, sizeof(arr));

	i =  - 1;
	do {
		i = o7c_add(i, 1);
		arr[o7c_ind(TranslatorLimits_MaxTermsInSum_cnst, i)] = sum;
		sum = sum->next;
	} while (!(sum == NULL));
	last = i;
	if (o7c_cmp(arr[0]->_.type->_._.id, Ast_IdInteger_cnst) ==  0) {
		while (o7c_cmp(i, 0) >  0) {
			switch (arr[o7c_ind(TranslatorLimits_MaxTermsInSum_cnst, i)]->add) {
			case 11:
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_sub(", 9);
				break;
			case 10:
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_add(", 9);
				break;
			default:
				abort();
				break;
			}
			i = o7c_sub(i, 1);
		}
	} else {
		assert(o7c_cmp(arr[0]->_.type->_._.id, Ast_IdReal_cnst) ==  0);
		while (o7c_cmp(i, 0) >  0) {
			switch (arr[o7c_ind(TranslatorLimits_MaxTermsInSum_cnst, i)]->add) {
			case 11:
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_fsub(", 10);
				break;
			case 10:
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_fadd(", 10);
				break;
			default:
				abort();
				break;
			}
			i = o7c_sub(i, 1);
		}
	}
	if (o7c_cmp(arr[0]->add, Scanner_Minus_cnst) ==  0) {
		if (o7c_cmp(arr[0]->_.type->_._.id, Ast_IdInteger_cnst) ==  0) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_sub(0, ", 12);
		} else {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_fsub(0, ", 13);
		}
		Expression(&(*gen), gen_tag, arr[0]->term);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
	} else {
		Expression(&(*gen), gen_tag, arr[0]->term);
	}
	while (o7c_cmp(i, last) <  0) {
		i = o7c_add(i, 1);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
		Expression(&(*gen), gen_tag, arr[o7c_ind(TranslatorLimits_MaxTermsInSum_cnst, i)]->term);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
	}
}

static void Expression_Term(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ExprTerm_s *term) {
	do {
		CheckExpr(&(*gen), gen_tag, &term->factor->_);
		switch (term->mult) {
		case 150:
			if (o7c_cmp(term->_.type->_._.id, Ast_IdSet_cnst) ==  0) {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" & ", 4);
			} else {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" * ", 4);
			}
			break;
		case 151:
		case 153:
			if (o7c_cmp(term->_.type->_._.id, Ast_IdSet_cnst) ==  0) {
				assert(o7c_cmp(term->mult, Scanner_Slash_cnst) ==  0);
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" ^ ", 4);
			} else {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" / ", 4);
			}
			break;
		case 152:
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" && ", 5);
			break;
		case 154:
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" % ", 4);
			break;
		default:
			abort();
			break;
		}
		if (o7c_is(term->expr, Ast_ExprTerm_s_tag)) {
			term = O7C_GUARD(Ast_ExprTerm_s, &term->expr);
		} else {
			CheckExpr(&(*gen), gen_tag, term->expr);
			term = NULL;
		}
	} while (!(term == NULL));
}

static void Expression_TermCheck(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ExprTerm_s *term) {
	struct Ast_ExprTerm_s *arr[TranslatorLimits_MaxFactorsInTerm_cnst] ;
	int i = O7C_INT_UNDEF, last = O7C_INT_UNDEF;
	memset(&arr, 0, sizeof(arr));

	arr[0] = term;
	i = 0;
	while (o7c_is(term->expr, Ast_ExprTerm_s_tag)) {
		i = o7c_add(i, 1);
		term = O7C_GUARD(Ast_ExprTerm_s, &term->expr);
		arr[o7c_ind(TranslatorLimits_MaxFactorsInTerm_cnst, i)] = term;
	}
	last = i;
	if (o7c_cmp(term->_.type->_._.id, Ast_IdInteger_cnst) ==  0) {
		while (o7c_cmp(i, 0) >=  0) {
			switch (arr[o7c_ind(TranslatorLimits_MaxFactorsInTerm_cnst, i)]->mult) {
			case 150:
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_mul(", 9);
				break;
			case 153:
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_div(", 9);
				break;
			case 154:
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_mod(", 9);
				break;
			default:
				abort();
				break;
			}
			i = o7c_sub(i, 1);
		}
	} else {
		assert(o7c_cmp(term->_.type->_._.id, Ast_IdReal_cnst) ==  0);
		while (o7c_cmp(i, 0) >=  0) {
			switch (arr[o7c_ind(TranslatorLimits_MaxFactorsInTerm_cnst, i)]->mult) {
			case 150:
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_fmul(", 10);
				break;
			case 151:
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_fdiv(", 10);
				break;
			default:
				abort();
				break;
			}
			i = o7c_sub(i, 1);
		}
	}
	Expression(&(*gen), gen_tag, &arr[0]->factor->_);
	i = 0;
	while (o7c_cmp(i, last) <  0) {
		i = o7c_add(i, 1);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
		Expression(&(*gen), gen_tag, &arr[o7c_ind(TranslatorLimits_MaxFactorsInTerm_cnst, i)]->factor->_);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
	}
	TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
	Expression(&(*gen), gen_tag, arr[o7c_ind(TranslatorLimits_MaxFactorsInTerm_cnst, last)]->expr);
	TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
}

static void Expression_Boolean(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ExprBoolean_s *e) {
	if (o7c_cmp((*gen).opt->std, GeneratorC_IsoC90_cnst) ==  0) {
		if (e->bool_) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(0 < 1)", 8);
		} else {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(0 > 1)", 8);
		}
	} else {
		if (e->bool_) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"true", 5);
		} else {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"false", 6);
		}
	}
}

static void Expression_CString(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ExprString_s *e);
static o7c_char CString_Expression_ToHex(int d) {
	assert((o7c_cmp(d, 0) >=  0) && (o7c_cmp(d, 16) <  0));
	if (o7c_cmp(d, 10) <  0) {
		d = o7c_add(d, (int)(char unsigned)'0');
	} else {
		d = o7c_add(d, (int)(char unsigned)'A' - 10);
	}
	return o7c_chr(d);
}

static void Expression_CString(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ExprString_s *e) {
	o7c_char s1[7] ;
	o7c_char s2[4] ;
	o7c_char ch = '\0';
	struct StringStore_String w ;
	memset(&s1, 0, sizeof(s1));
	memset(&s2, 0, sizeof(s2));
	memset(&w, 0, sizeof(w));

	w = e->string;
	if (e->asChar) {
		ch = o7c_chr(e->_.int_);
		if (ch == (char unsigned)'\'') {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(char unsigned)'\\''", 20);
		} else if (ch == (char unsigned)'\\') {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(char unsigned)'\\\\'", 20);
		} else if ((ch >= (char unsigned)' ') && (ch <= (char unsigned)127)) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(char unsigned)", 16);
			s2[0] = (char unsigned)'\'';
			s2[1] = ch;
			s2[2] = (char unsigned)'\'';
			s2[3] = 0x00u;
			TextGenerator_Str(&(*gen)._, gen_tag, s2, 4);
		} else {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"0x", 3);
			s2[0] = CString_Expression_ToHex(o7c_div(e->_.int_, 16));
			s2[1] = CString_Expression_ToHex(o7c_mod(e->_.int_, 16));
			s2[2] = (char unsigned)'u';
			s2[3] = 0x00u;
			TextGenerator_Str(&(*gen)._, gen_tag, s2, 4);
		}
	} else {
		if (!(*gen).insideSizeOf) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(o7c_char *)", 13);
		}
		if (w.block->s[o7c_ind(StringStore_BlockSize_cnst + 1, w.ofs)] == (char unsigned)'"') {
			TextGenerator_ScreeningString(&(*gen)._, gen_tag, &w, StringStore_String_tag);
		} else {
			s1[0] = (char unsigned)'"';
			s1[1] = (char unsigned)'\\';
			s1[2] = (char unsigned)'x';
			s1[3] = CString_Expression_ToHex(o7c_div(e->_.int_, 16));
			s1[4] = CString_Expression_ToHex(o7c_mod(e->_.int_, 16));
			s1[5] = (char unsigned)'"';
			s1[6] = 0x00u;
			TextGenerator_Str(&(*gen)._, gen_tag, s1, 7);
		}
	}
}

static void Expression_ExprInt(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, int int_) {
	if (o7c_cmp(int_, 0) >=  0) {
		TextGenerator_Int(&(*gen)._, gen_tag, int_);
	} else {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(-", 3);
		TextGenerator_Int(&(*gen)._, gen_tag, o7c_sub(0, int_));
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
	}
}

static void Expression_Set(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ExprSet_s *set);
static void Set_Expression_Item(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ExprSet_s *set) {
	if (set->exprs[0] == NULL) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"0", 2);
	} else {
		if (set->exprs[1] == NULL) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(1 << ", 7);
			Factor(&(*gen), gen_tag, set->exprs[0]);
		} else {
			if ((set->exprs[0]->value_ == NULL) || (set->exprs[1]->value_ == NULL)) {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_set(", 9);
			} else {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"O7C_SET(", 9);
			}
			Expression(&(*gen), gen_tag, set->exprs[0]);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
			Expression(&(*gen), gen_tag, set->exprs[1]);
		}
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
	}
}

static void Expression_Set(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ExprSet_s *set) {
	if (set->next == NULL) {
		Set_Expression_Item(&(*gen), gen_tag, set);
	} else {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(", 2);
		Set_Expression_Item(&(*gen), gen_tag, set);
		do {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" | ", 4);
			set = set->next;
			Set_Expression_Item(&(*gen), gen_tag, set);
		} while (!(set->next == NULL));
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
	}
}

static void Expression_IsExtension(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ExprIsExtension_s *is) {
	struct Ast_RDeclaration *decl = NULL;
	struct Ast_RType *extType = NULL;
	o7c_bool ret = O7C_BOOL_UNDEF;

	decl = is->designator->decl;
	extType = is->extType;
	if (o7c_cmp(is->designator->_._.type->_._.id, Ast_IdPointer_cnst) ==  0) {
		extType = extType->_.type;
		ret = CheckStructName(&(*gen), gen_tag, O7C_GUARD(Ast_Record_s, &extType));
		assert(o7c_bl(ret));
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_is(", 8);
		Expression(&(*gen), gen_tag, &is->designator->_._);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
	} else {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_is_r(", 10);
		GlobalName(&(*gen), gen_tag, decl);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"_tag, ", 7);
		GlobalName(&(*gen), gen_tag, decl);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
	}
	GlobalName(&(*gen), gen_tag, &extType->_);
	TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"_tag)", 6);
}

static void Expression(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *expr) {
	switch (expr->_.id) {
	case 0:
		Expression_ExprInt(&(*gen), gen_tag, O7C_GUARD(Ast_RExprInteger, &expr)->int_);
		break;
	case 1:
		Expression_Boolean(&(*gen), gen_tag, O7C_GUARD(Ast_ExprBoolean_s, &expr));
		break;
	case 4:
		if (StringStore_IsDefined(&O7C_GUARD(Ast_ExprReal_s, &expr)->str, StringStore_String_tag)) {
			TextGenerator_String(&(*gen)._, gen_tag, &O7C_GUARD(Ast_ExprReal_s, &expr)->str, StringStore_String_tag);
		} else {
			TextGenerator_Real(&(*gen)._, gen_tag, O7C_GUARD(Ast_ExprReal_s, &expr)->real);
		}
		break;
	case 12:
		Expression_CString(&(*gen), gen_tag, O7C_GUARD(Ast_ExprString_s, &expr));
		break;
	case 5:
		Expression_Set(&(*gen), gen_tag, O7C_GUARD(Ast_ExprSet_s, &expr));
		break;
	case 25:
		Expression_Call(&(*gen), gen_tag, O7C_GUARD(Ast_ExprCall_s, &expr));
		break;
	case 20:
		Log_Str((o7c_char *)"Expr Designator type.id = ", 27);
		Log_Int(expr->type->_._.id);
		Log_Str((o7c_char *)" (expr.value # NIL) = ", 23);
		Log_Int((int)(expr->value_ != NULL));
		Log_Ln();
		if ((expr->value_ != NULL) && (o7c_cmp(expr->value_->_._.id, Ast_IdString_cnst) ==  0)) {
			Expression_CString(&(*gen), gen_tag, O7C_GUARD(Ast_ExprString_s, &expr->value_));
		} else {
			Designator(&(*gen), gen_tag, O7C_GUARD(Ast_Designator_s, &expr));
		}
		break;
	case 21:
		Expression_Relation(&(*gen), gen_tag, O7C_GUARD(Ast_ExprRelation_s, &expr));
		break;
	case 22:
		if (o7c_bl((*gen).opt->checkArith) && (o7c_in(expr->type->_._.id, ((1 << Ast_IdInteger_cnst) | (1 << Ast_IdReal_cnst)))) && (expr->value_ == NULL)) {
			Expression_SumCheck(&(*gen), gen_tag, O7C_GUARD(Ast_ExprSum_s, &expr));
		} else {
			Expression_Sum(&(*gen), gen_tag, O7C_GUARD(Ast_ExprSum_s, &expr));
		}
		break;
	case 23:
		if (o7c_bl((*gen).opt->checkArith) && (o7c_in(expr->type->_._.id, ((1 << Ast_IdInteger_cnst) | (1 << Ast_IdReal_cnst)))) && (expr->value_ == NULL)) {
			Expression_TermCheck(&(*gen), gen_tag, O7C_GUARD(Ast_ExprTerm_s, &expr));
		} else {
			Expression_Term(&(*gen), gen_tag, O7C_GUARD(Ast_ExprTerm_s, &expr));
		}
		break;
	case 24:
		if (o7c_cmp(expr->type->_._.id, Ast_IdSet_cnst) ==  0) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"~", 2);
		} else {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"!", 2);
		}
		Expression(&(*gen), gen_tag, O7C_GUARD(Ast_ExprNegate_s, &expr)->expr);
		break;
	case 26:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(", 2);
		Expression(&(*gen), gen_tag, O7C_GUARD(Ast_ExprBraces_s, &expr)->expr);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
		break;
	case 6:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"NULL", 5);
		break;
	case 27:
		Expression_IsExtension(&(*gen), gen_tag, O7C_GUARD(Ast_ExprIsExtension_s, &expr));
		break;
	default:
		abort();
		break;
	}
}

static void Invert(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag) {
	O7C_GUARD(MemoryOut, &(*gen)._.out)->invert = !O7C_GUARD(MemoryOut, &(*gen)._.out)->invert;
}

static void ProcHead(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ProcType_s *proc);
static void ProcHead_Parameters(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ProcType_s *proc);
static void Parameters_ProcHead_Par(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_FormalParam_s *fp) {
	struct Ast_RType *t = NULL;
	int i = O7C_INT_UNDEF;

	declarator(&(*gen), gen_tag, &fp->_._, false, false, false);
	t = fp->_._.type;
	i = 0;
	if (o7c_cmp(t->_._.id, Ast_IdRecord_cnst) ==  0) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", o7c_tag_t ", 13);
		Name(&(*gen), gen_tag, &fp->_._);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"_tag", 5);
	} else {
		while ((o7c_cmp(t->_._.id, Ast_IdArray_cnst) ==  0) && (O7C_GUARD(Ast_RArray, &t)->count == NULL)) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", int ", 7);
			Name(&(*gen), gen_tag, &fp->_._);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"_len", 5);
			TextGenerator_Int(&(*gen)._, gen_tag, i);
			i = o7c_add(i, 1);
			t = t->_.type;
		}
	}
}

static void ProcHead_Parameters(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ProcType_s *proc) {
	struct Ast_RDeclaration *p = NULL;

	if (proc->params == NULL) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(void)", 7);
	} else {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(", 2);
		p = (&(proc->params)->_._);
		while (p != &proc->end->_._) {
			Parameters_ProcHead_Par(&(*gen), gen_tag, O7C_GUARD(Ast_FormalParam_s, &p));
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
			p = p->next;
		}
		Parameters_ProcHead_Par(&(*gen), gen_tag, O7C_GUARD(Ast_FormalParam_s, &p));
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
	}
}

static void ProcHead(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ProcType_s *proc) {
	ProcHead_Parameters(&(*gen), gen_tag, proc);
	Invert(&(*gen), gen_tag);
	type(&(*gen), gen_tag, proc->_._._.type, false, false);
	MemWriteInvert(&(*O7C_GUARD(MemoryOut, &(*gen)._.out)), NULL);
}

static void Declarator(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *decl, o7c_bool typeDecl, o7c_bool sameType, o7c_bool global) {
	struct GeneratorC_Generator g ;
	struct MemoryOut *mo = NULL;
	memset(&g, 0, sizeof(g));

	O7C_NEW(&mo, MemoryOut_tag);
	MemoryOutInit(&(*mo), MemoryOut_tag);
	TextGenerator_Init(&g._, GeneratorC_Generator_tag, &mo->_);
	TextGenerator_SetTabs(&g._, GeneratorC_Generator_tag, &(*gen)._, gen_tag);
	g.module = (*gen).module;
	g.interface_ = (*gen).interface_;
	g.opt = (*gen).opt;
	if ((o7c_is(decl, Ast_FormalParam_s_tag)) && ((o7c_bl(O7C_GUARD(Ast_FormalParam_s, &decl)->isVar) && !(o7c_is(decl->type, Ast_RArray_tag))) || (o7c_is(decl->type, Ast_Record_s_tag)))) {
		TextGenerator_Str(&g._, GeneratorC_Generator_tag, (o7c_char *)"*", 2);
	} else if (o7c_is(decl, Ast_Const_s_tag)) {
		TextGenerator_Str(&g._, GeneratorC_Generator_tag, (o7c_char *)"const ", 7);
	}
	if (global) {
		GlobalName(&g, GeneratorC_Generator_tag, decl);
	} else {
		Name(&g, GeneratorC_Generator_tag, decl);
	}
	if (o7c_is(decl, Ast_RProcedure_tag)) {
		ProcHead(&g, GeneratorC_Generator_tag, O7C_GUARD(Ast_RProcedure, &decl)->_.header);
	} else {
		mo->invert = !mo->invert;
		if (o7c_is(decl, Ast_RType_tag)) {
			type(&g, GeneratorC_Generator_tag, O7C_GUARD(Ast_RType, &decl), typeDecl, false);
		} else {
			type(&g, GeneratorC_Generator_tag, decl->type, false, sameType);
		}
	}
	MemWriteDirect(&(*gen), gen_tag, &(*mo), MemoryOut_tag);
}

static void Type(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RType *type, o7c_bool typeDecl, o7c_bool sameType);
static void Type_Simple(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, o7c_char str[/*len0*/], int str_len0) {
	TextGenerator_Str(&(*gen)._, gen_tag, str, str_len0);
	MemWriteInvert(&(*O7C_GUARD(MemoryOut, &(*gen)._.out)), NULL);
}

/*	Поскольку в Си нельзя полагаться на стабильность смещения переменных
	в структуре, неплохо бы добавить возможность генерации импортируемых или
	наследуемых структур на массив байт со смещениями.
*/
static void Type_Record(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_Record_s *rec) {
	struct Ast_RDeclaration *v = NULL;

	rec->_._._.module = (*gen).module;
	TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"struct ", 8);
	if (CheckStructName(&(*gen), gen_tag, rec)) {
		GlobalName(&(*gen), gen_tag, &rec->_._._);
	}
	v = (&(rec->vars)->_);
	if ((v == NULL) && (rec->base == NULL) && !(*gen).opt->gnu) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" { int nothing; } ", 19);
	} else {
		TextGenerator_StrOpen(&(*gen)._, gen_tag, (o7c_char *)" {", 3);
		if (rec->base != NULL) {
			GlobalName(&(*gen), gen_tag, &rec->base->_._._);
			if ((*gen).opt->plan9) {
				TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)";", 2);
			} else {
				TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)" _;", 4);
			}
		}
		while (v != NULL) {
			Declarator(&(*gen), gen_tag, v, false, false, false);
			TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)";", 2);
			v = v->next;
		}
		TextGenerator_StrClose(&(*gen)._, gen_tag, (o7c_char *)"} ", 3);
	}
	MemWriteInvert(&(*O7C_GUARD(MemoryOut, &(*gen)._.out)), NULL);
}

static void Type_Array(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RArray *arr, o7c_bool sameType) {
	struct Ast_RType *t = NULL;
	int i = O7C_INT_UNDEF;

	t = arr->_._._.type;
	MemWriteInvert(&(*O7C_GUARD(MemoryOut, &(*gen)._.out)), NULL);
	if (arr->count == NULL) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"[/*len0", 8);
		i = 0;
		while (o7c_cmp(t->_._.id, Ast_IdArray_cnst) ==  0) {
			i = o7c_add(i, 1);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", len", 6);
			TextGenerator_Int(&(*gen)._, gen_tag, i);
			t = t->_.type;
		}
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"*/]", 4);
	} else {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"[", 2);
		Expression(&(*gen), gen_tag, arr->count);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"]", 2);
	}
	Invert(&(*gen), gen_tag);
	Type(&(*gen), gen_tag, t, false, sameType);
}

static void Type(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RType *type, o7c_bool typeDecl, o7c_bool sameType) {
	if (type == NULL) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"void ", 6);
		MemWriteInvert(&(*O7C_GUARD(MemoryOut, &(*gen)._.out)), NULL);
	} else {
		if (!typeDecl && StringStore_IsDefined(&type->_.name, StringStore_String_tag)) {
			if (sameType) {
				if ((o7c_is(type, Ast_RPointer_tag)) && StringStore_IsDefined(&type->_.type->_.name, StringStore_String_tag)) {
					TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"*", 2);
				}
			} else {
				if ((o7c_is(type, Ast_RPointer_tag)) && StringStore_IsDefined(&type->_.type->_.name, StringStore_String_tag)) {
					TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"struct ", 8);
					GlobalName(&(*gen), gen_tag, &type->_.type->_);
					TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" *", 3);
				} else if (o7c_is(type, Ast_Record_s_tag)) {
					TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"struct ", 8);
					if (CheckStructName(&(*gen), gen_tag, O7C_GUARD(Ast_Record_s, &type))) {
						GlobalName(&(*gen), gen_tag, &type->_);
						TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" ", 2);
					}
				} else {
					GlobalName(&(*gen), gen_tag, &type->_);
					TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" ", 2);
				}
				if (o7c_is((*gen)._.out, MemoryOut_tag)) {
					MemWriteInvert(&(*O7C_GUARD(MemoryOut, &(*gen)._.out)), NULL);
				}
			}
		} else if (!sameType || (o7c_in(type->_._.id, ((1 << Ast_IdPointer_cnst) | (1 << Ast_IdArray_cnst) | (1 << Ast_IdProcType_cnst))))) {
			switch (type->_._.id) {
			case 0:
				Type_Simple(&(*gen), gen_tag, (o7c_char *)"int ", 5);
				break;
			case 5:
				Type_Simple(&(*gen), gen_tag, (o7c_char *)"unsigned ", 10);
				break;
			case 1:
				if ((o7c_cmp((*gen).opt->std, GeneratorC_IsoC99_cnst) >=  0) && (o7c_cmp((*gen).opt->varInit, GeneratorC_VarInitUndefined_cnst) !=  0)) {
					Type_Simple(&(*gen), gen_tag, (o7c_char *)"bool ", 6);
				} else {
					Type_Simple(&(*gen), gen_tag, (o7c_char *)"o7c_bool ", 10);
				}
				break;
			case 2:
				Type_Simple(&(*gen), gen_tag, (o7c_char *)"char unsigned ", 15);
				break;
			case 3:
				Type_Simple(&(*gen), gen_tag, (o7c_char *)"o7c_char ", 10);
				break;
			case 4:
				Type_Simple(&(*gen), gen_tag, (o7c_char *)"double ", 8);
				break;
			case 6:
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"*", 2);
				MemWriteInvert(&(*O7C_GUARD(MemoryOut, &(*gen)._.out)), NULL);
				Invert(&(*gen), gen_tag);
				Type(&(*gen), gen_tag, type->_.type, false, sameType);
				break;
			case 7:
				Type_Array(&(*gen), gen_tag, O7C_GUARD(Ast_RArray, &type), sameType);
				break;
			case 8:
				Type_Record(&(*gen), gen_tag, O7C_GUARD(Ast_Record_s, &type));
				break;
			case 10:
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(*", 3);
				MemWriteInvert(&(*O7C_GUARD(MemoryOut, &(*gen)._.out)), NULL);
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
				ProcHead(&(*gen), gen_tag, O7C_GUARD(Ast_ProcType_s, &type));
				break;
			default:
				abort();
				break;
			}
		}
		if (o7c_is((*gen)._.out, MemoryOut_tag)) {
			MemWriteInvert(&(*O7C_GUARD(MemoryOut, &(*gen)._.out)), NULL);
		}
	}
}

static void RecordTag(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_Record_s *rec) {
	if (!rec->_._._.mark || o7c_bl((*gen).opt->main_)) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"static o7c_tag_t ", 18);
	} else if ((*gen).interface_) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"extern o7c_tag_t ", 18);
	} else {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_tag_t ", 11);
	}
	GlobalName(&(*gen), gen_tag, &rec->_._._);
	TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"_tag;", 6);
	if (!rec->_._._.mark || o7c_bl((*gen).opt->main_) || o7c_bl((*gen).interface_)) {
		TextGenerator_Ln(&(*gen)._, gen_tag);
	}
}

static void TypeDecl(struct MOut *out, o7c_tag_t out_tag, struct Ast_RType *type);
static void TypeDecl_Typedef(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RType *type) {
	TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"typedef ", 9);
	Declarator(&(*gen), gen_tag, &type->_, true, false, true);
	TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)";", 2);
}

static void TypeDecl_LinkRecord(struct GeneratorC_Options_s *opt, struct Ast_Record_s *rec) {
	if (opt->records == NULL) {
		opt->records = (&(rec)->_._._._._);
	} else {
		O7C_GUARD(Ast_Record_s, &opt->recordLast)->_._._._.ext = (&(rec)->_._._._._);
	}
	opt->recordLast = (&(rec)->_._._._._);
	assert(rec->_._._._.ext == NULL);
}

static void TypeDecl(struct MOut *out, o7c_tag_t out_tag, struct Ast_RType *type) {
	TypeDecl_Typedef(&(*out).g[o7c_ind(2, (int)(o7c_bl(type->_.mark) && !(*out).opt->main_))], GeneratorC_Generator_tag, type);
	if ((o7c_cmp(type->_._.id, Ast_IdRecord_cnst) ==  0) || (o7c_cmp(type->_._.id, Ast_IdPointer_cnst) ==  0) && (type->_.type->_.next == NULL)) {
		if (o7c_cmp(type->_._.id, Ast_IdPointer_cnst) ==  0) {
			type = type->_.type;
		}
		type->_.mark = o7c_bl(type->_.mark) || (O7C_GUARD(Ast_Record_s, &type)->pointer != NULL) && (O7C_GUARD(Ast_Record_s, &type)->pointer->_._._.mark);
		if (o7c_bl(type->_.mark) && !(*out).opt->main_) {
			RecordTag(&(*out).g[Interface_cnst], GeneratorC_Generator_tag, O7C_GUARD(Ast_Record_s, &type));
		}
		RecordTag(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, O7C_GUARD(Ast_Record_s, &type));
		TypeDecl_LinkRecord((*out).opt, O7C_GUARD(Ast_Record_s, &type));
	}
}

static void Mark(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, o7c_bool mark) {
	if (o7c_cmp((*gen).localDeep, 0) ==  0) {
		if (o7c_bl(mark) && !(*gen).opt->main_) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"extern ", 8);
		} else {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"static ", 8);
		}
	}
}

static void Comment(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct StringStore_String *com, o7c_tag_t com_tag) {
	struct StringStore_Iterator i ;
	o7c_char prev = '\0';
	memset(&i, 0, sizeof(i));

	if (o7c_bl((*gen).opt->comment) && StringStore_GetIter(&i, StringStore_Iterator_tag, &(*com), com_tag, 0)) {
		do {
			prev = i.char_;
		} while (!(!StringStore_IterNext(&i, StringStore_Iterator_tag) || (prev == (char unsigned)'/') && (i.char_ == (char unsigned)'*') || (prev == (char unsigned)'*') && (i.char_ == (char unsigned)'/')));
		if (i.char_ == 0x00u) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"/*", 3);
			TextGenerator_String(&(*gen)._, gen_tag, &(*com), com_tag);
			TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"*/", 3);
		}
	}
}

static void Const(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_Const_s *const_) {
	Comment(&(*gen), gen_tag, &const_->_._.comment, StringStore_String_tag);
	TextGenerator_StrIgnoreIndent(&(*gen)._, gen_tag, (o7c_char *)"#", 2);
	TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"define ", 8);
	GlobalName(&(*gen), gen_tag, &const_->_);
	TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" ", 2);
	if (o7c_bl(const_->_.mark) && (const_->expr != NULL)) {
		Factor(&(*gen), gen_tag, &const_->expr->value_->_);
	} else {
		Factor(&(*gen), gen_tag, const_->expr);
	}
	TextGenerator_Ln(&(*gen)._, gen_tag);
}

static void Var(struct MOut *out, o7c_tag_t out_tag, struct Ast_RDeclaration *prev, struct Ast_RDeclaration *var_, o7c_bool last);
static void Var_InitZero(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *var_) {
	switch (var_->type->_._.id) {
	case 0:
	case 2:
	case 4:
	case 5:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" = 0", 5);
		break;
	case 1:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" = 0 > 1", 9);
		break;
	case 3:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" = '\\0'", 8);
		break;
	case 6:
	case 10:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" = NULL", 8);
		break;
	case 7:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" ", 2);
		break;
	case 8:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" ", 2);
		break;
	default:
		abort();
		break;
	}
}

static void Var_InitUndef(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *var_) {
	switch (var_->type->_._.id) {
	case 0:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" = O7C_INT_UNDEF", 17);
		break;
	case 1:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" = O7C_BOOL_UNDEF", 18);
		break;
	case 2:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" = 0", 5);
		break;
	case 3:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" = '\\0'", 8);
		break;
	case 4:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" = O7C_DBL_UNDEF", 17);
		break;
	case 5:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" = 0", 5);
		break;
	case 6:
	case 10:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" = NULL", 8);
		break;
	case 7:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" ", 2);
		break;
	case 8:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" ", 2);
		break;
	default:
		abort();
		break;
	}
}

static void Var(struct MOut *out, o7c_tag_t out_tag, struct Ast_RDeclaration *prev, struct Ast_RDeclaration *var_, o7c_bool last) {
	o7c_bool same = O7C_BOOL_UNDEF, mark = O7C_BOOL_UNDEF;

	mark = o7c_bl(var_->mark) && !(*out).opt->main_;
	Comment(&(*out).g[o7c_ind(2, (int)mark)], GeneratorC_Generator_tag, &var_->_.comment, StringStore_String_tag);
	same = (prev != NULL) && (prev->mark == mark) && (prev->type == var_->type);
	if (!same) {
		if (prev != NULL) {
			TextGenerator_StrLn(&(*out).g[o7c_ind(2, (int)mark)]._, GeneratorC_Generator_tag, (o7c_char *)";", 2);
		}
		Mark(&(*out).g[o7c_ind(2, (int)mark)], GeneratorC_Generator_tag, mark);
	} else {
		TextGenerator_Str(&(*out).g[o7c_ind(2, (int)mark)]._, GeneratorC_Generator_tag, (o7c_char *)", ", 3);
	}
	if (mark) {
		Declarator(&(*out).g[Interface_cnst], GeneratorC_Generator_tag, var_, false, same, true);
		if (last) {
			TextGenerator_StrLn(&(*out).g[Interface_cnst]._, GeneratorC_Generator_tag, (o7c_char *)";", 2);
		}
		if (same) {
			TextGenerator_Str(&(*out).g[Implementation_cnst]._, GeneratorC_Generator_tag, (o7c_char *)", ", 3);
		} else if (prev != NULL) {
			TextGenerator_StrLn(&(*out).g[Implementation_cnst]._, GeneratorC_Generator_tag, (o7c_char *)";", 2);
		}
	}
	Declarator(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, var_, false, same, true);
	switch ((*out).opt->varInit) {
	case 0:
		Var_InitUndef(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, var_);
		break;
	case 1:
		Var_InitZero(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, var_);
		break;
	case 2:
		if ((o7c_cmp(var_->type->_._.id, Ast_IdPointer_cnst) ==  0) && (o7c_cmp((*out).opt->memManager, GeneratorC_MemManagerCounter_cnst) ==  0)) {
			TextGenerator_Str(&(*out).g[Implementation_cnst]._, GeneratorC_Generator_tag, (o7c_char *)" = NULL", 8);
		}
		break;
	default:
		abort();
		break;
	}
	if (last) {
		TextGenerator_StrLn(&(*out).g[Implementation_cnst]._, GeneratorC_Generator_tag, (o7c_char *)";", 2);
	}
}

static void ExprThenStats(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RWhileIf **wi) {
	Expression(&(*gen), gen_tag, (*wi)->_.expr);
	TextGenerator_StrOpen(&(*gen)._, gen_tag, (o7c_char *)") {", 4);
	statements(&(*gen), gen_tag, (*wi)->stats);
	(*wi) = (*wi)->elsif;
}

static o7c_bool IsCaseElementWithRange(struct Ast_CaseElement_s *elem) {
	struct Ast_CaseLabel_s *r = NULL;

	r = elem->labels;
	while ((r != NULL) && (r->right == NULL)) {
		r = r->next;
	}
	return r != NULL;
}

static void ExprSameType(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *expr, struct Ast_RType *expectType) {
	o7c_bool reref = O7C_BOOL_UNDEF, brace = O7C_BOOL_UNDEF;
	struct Ast_Record_s *base = NULL, *type = NULL;

	base = NULL;
	reref = (o7c_cmp(expr->type->_._.id, Ast_IdPointer_cnst) ==  0) && (expr->type->_.type != expectType->_.type) && (o7c_cmp(expr->_.id, Ast_IdPointer_cnst) !=  0);
	brace = reref;
	if (!reref) {
		Expression(&(*gen), gen_tag, expr);
		if (o7c_cmp(expr->type->_._.id, Ast_IdRecord_cnst) ==  0) {
			base = O7C_GUARD(Ast_Record_s, &expectType);
			type = O7C_GUARD(Ast_Record_s, &expr->type);
		}
	} else if ((*gen).opt->plan9) {
		Expression(&(*gen), gen_tag, expr);
		brace = false;
	} else {
		base = O7C_GUARD(Ast_Record_s, &expectType->_.type);
		type = O7C_GUARD(Ast_Record_s, &expr->type->_.type)->base;
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(&(", 4);
		Expression(&(*gen), gen_tag, expr);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")->_", 5);
	}
	if ((base != NULL) && (type != base)) {
		/*ASSERT(expectType.id = Ast.IdRecord);*/
		if ((*gen).opt->plan9) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)".", 2);
			GlobalName(&(*gen), gen_tag, &expectType->_);
		} else {
			while (type != base) {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"._", 3);
				type = type->base;
			}
		}
	}
	if (brace) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
	}
}

static void ExprForSize(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *e) {
	(*gen).insideSizeOf = true;
	Expression(&(*gen), gen_tag, e);
	(*gen).insideSizeOf = false;
}

static void Statement(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RStatement *st);
static void Statement_WhileIf(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RWhileIf *wi);
static void WhileIf_Statement_Elsif(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RWhileIf **wi) {
	while (((*wi) != NULL) && ((*wi)->_.expr != NULL)) {
		TextGenerator_StrClose(&(*gen)._, gen_tag, (o7c_char *)"} else if (", 12);
		ExprThenStats(&(*gen), gen_tag, &(*wi));
	}
}

static void Statement_WhileIf(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RWhileIf *wi) {
	if (o7c_is(wi, Ast_If_s_tag)) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"if (", 5);
		ExprThenStats(&(*gen), gen_tag, &wi);
		WhileIf_Statement_Elsif(&(*gen), gen_tag, &wi);
		if (wi != NULL) {
			TextGenerator_IndentClose(&(*gen)._, gen_tag);
			TextGenerator_StrOpen(&(*gen)._, gen_tag, (o7c_char *)"} else {", 9);
			statements(&(*gen), gen_tag, wi->stats);
		}
		TextGenerator_StrLnClose(&(*gen)._, gen_tag, (o7c_char *)"}", 2);
	} else if (wi->elsif == NULL) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"while (", 8);
		ExprThenStats(&(*gen), gen_tag, &wi);
		TextGenerator_StrLnClose(&(*gen)._, gen_tag, (o7c_char *)"}", 2);
	} else {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"while (1) if (", 15);
		ExprThenStats(&(*gen), gen_tag, &wi);
		WhileIf_Statement_Elsif(&(*gen), gen_tag, &wi);
		TextGenerator_StrLnClose(&(*gen)._, gen_tag, (o7c_char *)"} else break;", 14);
	}
}

static void Statement_Repeat(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_Repeat_s *st) {
	TextGenerator_StrOpen(&(*gen)._, gen_tag, (o7c_char *)"do {", 5);
	statements(&(*gen), gen_tag, st->stats);
	if (o7c_cmp(st->_.expr->_.id, Ast_IdNegate_cnst) ==  0) {
		TextGenerator_StrClose(&(*gen)._, gen_tag, (o7c_char *)"} while (", 10);
		Expression(&(*gen), gen_tag, O7C_GUARD(Ast_ExprNegate_s, &st->_.expr)->expr);
		TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)");", 3);
	} else {
		TextGenerator_StrClose(&(*gen)._, gen_tag, (o7c_char *)"} while (!(", 12);
		Expression(&(*gen), gen_tag, st->_.expr);
		TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"));", 4);
	}
}

static void Statement_For(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_For_s *st);
static o7c_bool For_Statement_IsEndMinus1(struct Ast_ExprSum_s *sum) {
	return (sum->next != NULL) && (sum->next->next == NULL) && (o7c_cmp(sum->next->add, Scanner_Minus_cnst) ==  0) && (sum->next->term->value_ != NULL) && (o7c_cmp(O7C_GUARD(Ast_RExprInteger, &sum->next->term->value_)->int_, 1) ==  0);
}

static void Statement_For(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_For_s *st) {
	TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"for (", 6);
	GlobalName(&(*gen), gen_tag, &st->var_->_);
	TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" = ", 4);
	Expression(&(*gen), gen_tag, st->_.expr);
	TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"; ", 3);
	GlobalName(&(*gen), gen_tag, &st->var_->_);
	if (o7c_cmp(st->by, 0) >  0) {
		if ((o7c_is(st->to, Ast_ExprSum_s_tag)) && For_Statement_IsEndMinus1(O7C_GUARD(Ast_ExprSum_s, &st->to))) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" < ", 4);
			Expression(&(*gen), gen_tag, O7C_GUARD(Ast_ExprSum_s, &st->to)->term);
		} else {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" <= ", 5);
			Expression(&(*gen), gen_tag, st->to);
		}
		if (o7c_cmp(st->by, 1) ==  0) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"; ++", 5);
			GlobalName(&(*gen), gen_tag, &st->var_->_);
		} else {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"; ", 3);
			GlobalName(&(*gen), gen_tag, &st->var_->_);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" += ", 5);
			TextGenerator_Int(&(*gen)._, gen_tag, st->by);
		}
	} else {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" >= ", 5);
		Expression(&(*gen), gen_tag, st->to);
		if (o7c_cmp(st->by,  - 1) ==  0) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"; --", 5);
			GlobalName(&(*gen), gen_tag, &st->var_->_);
		} else {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"; ", 3);
			GlobalName(&(*gen), gen_tag, &st->var_->_);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" -= ", 5);
			TextGenerator_Int(&(*gen)._, gen_tag, o7c_sub(0, st->by));
		}
	}
	TextGenerator_StrOpen(&(*gen)._, gen_tag, (o7c_char *)") {", 4);
	statements(&(*gen), gen_tag, st->stats);
	TextGenerator_StrLnClose(&(*gen)._, gen_tag, (o7c_char *)"}", 2);
}

static void Statement_Assign(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_Assign_s *st);
static void Assign_Statement_AssertArraySize(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_Designator_s *des, struct Ast_RExpression *e) {
	if (o7c_bl((*gen).opt->checkIndex) && ((O7C_GUARD(Ast_RArray, &des->_._.type)->count == NULL) || (O7C_GUARD(Ast_RArray, &e->type)->count == NULL))) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"assert(", 8);
		ArrayLen(&(*gen), gen_tag, &des->_._);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" >= ", 5);
		ArrayLen(&(*gen), gen_tag, e);
		TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)");", 3);
	}
}

static void Statement_Assign(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_Assign_s *st) {
	o7c_bool retain = O7C_BOOL_UNDEF, toByte = O7C_BOOL_UNDEF;

	toByte = (o7c_cmp(st->designator->_._.type->_._.id, Ast_IdByte_cnst) ==  0) && (o7c_cmp(st->_.expr->type->_._.id, Ast_IdInteger_cnst) ==  0) && o7c_bl((*gen).opt->checkArith) && (st->_.expr->value_ == NULL);
	retain = (o7c_cmp(st->designator->_._.type->_._.id, Ast_IdPointer_cnst) ==  0) && (o7c_cmp((*gen).opt->memManager, GeneratorC_MemManagerCounter_cnst) ==  0);
	if (o7c_bl(retain) && (o7c_cmp(st->_.expr->_.id, Ast_IdPointer_cnst) ==  0)) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"O7C_NULL(&", 11);
		Designator(&(*gen), gen_tag, st->designator);
	} else {
		if (retain) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"O7C_ASSIGN(&", 13);
			Designator(&(*gen), gen_tag, st->designator);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
		} else if ((o7c_cmp(st->designator->_._.type->_._.id, Ast_IdArray_cnst) ==  0)) {
			/*    & (st.designator.type.type.id # Ast.IdString) */
			Assign_Statement_AssertArraySize(&(*gen), gen_tag, st->designator, st->_.expr);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"memcpy(", 8);
			Designator(&(*gen), gen_tag, st->designator);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", ", 3);
		} else if (toByte) {
			Designator(&(*gen), gen_tag, st->designator);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" = o7c_byte(", 13);
		} else {
			Designator(&(*gen), gen_tag, st->designator);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" = ", 4);
		}
		ExprSameType(&(*gen), gen_tag, st->_.expr, st->designator->_._.type);
		if (o7c_cmp(st->designator->_._.type->_._.id, Ast_IdArray_cnst) !=  0) {
		} else if (O7C_GUARD(Ast_RArray, &st->_.expr->type)->count != NULL) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", sizeof(", 10);
			ExprForSize(&(*gen), gen_tag, st->_.expr);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
		} else {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", (", 4);
			ArrayLen(&(*gen), gen_tag, st->_.expr);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)") * sizeof(", 12);
			ExprForSize(&(*gen), gen_tag, st->_.expr);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"[0])", 5);
		}
	}
	{ int o7c_case_expr = o7c_add(o7c_add((int)retain, (int)toByte), (int)((o7c_cmp(st->designator->_._.type->_._.id, Ast_IdArray_cnst) ==  0) && (o7c_cmp(st->designator->_._.type->_.type->_._.id, Ast_IdString_cnst) !=  0)));
		switch (o7c_case_expr) {
		case 0:
			TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)";", 2);
			break;
		case 1:
			TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)");", 3);
			break;
		case 2:
			TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"));", 4);
			break;
		default:
			abort();
			break;
		}
	}
}

static void Statement_Case(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_Case_s *st);
static void Case_Statement_CaseElement(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_CaseElement_s *elem) {
	struct Ast_CaseLabel_s *r = NULL;

	if (!IsCaseElementWithRange(elem)) {
		r = elem->labels;
		while (r != NULL) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"case ", 6);
			TextGenerator_Int(&(*gen)._, gen_tag, r->value_);
			assert(r->right == NULL);
			TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)":", 2);
			r = r->next;
		}
		TextGenerator_IndentOpen(&(*gen)._, gen_tag);
		statements(&(*gen), gen_tag, elem->stats);
		TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"break;", 7);
		TextGenerator_IndentClose(&(*gen)._, gen_tag);
	}
}

static void Case_Statement_CaseElementAsIf(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_CaseElement_s *elem, struct Ast_RExpression *caseExpr);
static void CaseElementAsIf_Case_Statement_CaseRange(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_CaseLabel_s *r, struct Ast_RExpression *caseExpr) {
	if (r->right == NULL) {
		if (caseExpr == NULL) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(o7c_case_expr == ", 19);
		} else {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(", 2);
			Expression(&(*gen), gen_tag, caseExpr);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" == ", 5);
		}
		TextGenerator_Int(&(*gen)._, gen_tag, r->value_);
	} else {
		assert(o7c_cmp(r->value_, r->right->value_) <=  0);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"(", 2);
		TextGenerator_Int(&(*gen)._, gen_tag, r->value_);
		if (caseExpr == NULL) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" <= o7c_case_expr && o7c_case_expr <= ", 39);
		} else {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" <= ", 5);
			Expression(&(*gen), gen_tag, caseExpr);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" && ", 5);
			Expression(&(*gen), gen_tag, caseExpr);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" <= ", 5);
		}
		TextGenerator_Int(&(*gen)._, gen_tag, r->right->value_);
	}
	TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)")", 2);
}

static void Case_Statement_CaseElementAsIf(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_CaseElement_s *elem, struct Ast_RExpression *caseExpr) {
	struct Ast_CaseLabel_s *r = NULL;

	TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"if (", 5);
	r = elem->labels;
	assert(r != NULL);
	CaseElementAsIf_Case_Statement_CaseRange(&(*gen), gen_tag, r, caseExpr);
	while (r->next != NULL) {
		r = r->next;
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" || ", 5);
		CaseElementAsIf_Case_Statement_CaseRange(&(*gen), gen_tag, r, caseExpr);
	}
	TextGenerator_StrOpen(&(*gen)._, gen_tag, (o7c_char *)") {", 4);
	statements(&(*gen), gen_tag, elem->stats);
	TextGenerator_StrClose(&(*gen)._, gen_tag, (o7c_char *)"}", 2);
}

static void Statement_Case(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_Case_s *st) {
	struct Ast_CaseElement_s *elem = NULL, *elemWithRange = NULL;
	struct Ast_RExpression *caseExpr = NULL;

	elemWithRange = st->elements;
	while ((elemWithRange != NULL) && !IsCaseElementWithRange(elemWithRange)) {
		elemWithRange = elemWithRange->next;
	}
	if ((elemWithRange == NULL) && !((o7c_is(st->_.expr, Ast_RFactor_tag)) && !(o7c_is(st->_.expr, Ast_ExprBraces_s_tag)))) {
		caseExpr = NULL;
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"{ int o7c_case_expr = ", 23);
		Expression(&(*gen), gen_tag, st->_.expr);
		TextGenerator_StrOpen(&(*gen)._, gen_tag, (o7c_char *)";", 2);
		TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"switch (o7c_case_expr) {", 25);
	} else {
		caseExpr = st->_.expr;
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"switch (", 9);
		Expression(&(*gen), gen_tag, caseExpr);
		TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)") {", 4);
	}
	elem = st->elements;
	do {
		Case_Statement_CaseElement(&(*gen), gen_tag, elem);
		elem = elem->next;
	} while (!(elem == NULL));
	TextGenerator_StrOpen(&(*gen)._, gen_tag, (o7c_char *)"default:", 9);
	if (elemWithRange != NULL) {
		elem = elemWithRange;
		Case_Statement_CaseElementAsIf(&(*gen), gen_tag, elem, caseExpr);
		elem = elem->next;
		while (elem != NULL) {
			if (IsCaseElementWithRange(elem)) {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)" else ", 7);
				Case_Statement_CaseElementAsIf(&(*gen), gen_tag, elem, caseExpr);
			}
			elem = elem->next;
		}
		if ((*gen).opt->caseAbort) {
			TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)" else abort();", 15);
		}
	} else if ((*gen).opt->caseAbort) {
		TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"abort();", 9);
	}
	TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"break;", 7);
	TextGenerator_StrLnClose(&(*gen)._, gen_tag, (o7c_char *)"}", 2);
	if (caseExpr == NULL) {
		TextGenerator_StrLnClose(&(*gen)._, gen_tag, (o7c_char *)"}", 2);
	}
}

static void Statement(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RStatement *st) {
	Comment(&(*gen), gen_tag, &st->_.comment, StringStore_String_tag);
	if (o7c_is(st, Ast_Assign_s_tag)) {
		Statement_Assign(&(*gen), gen_tag, O7C_GUARD(Ast_Assign_s, &st));
	} else if (o7c_is(st, Ast_Call_s_tag)) {
		(*gen).expressionSemicolon = true;
		Expression(&(*gen), gen_tag, st->expr);
		if ((*gen).expressionSemicolon) {
			TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)";", 2);
		} else {
			TextGenerator_Ln(&(*gen)._, gen_tag);
		}
	} else if (o7c_is(st, Ast_RWhileIf_tag)) {
		Statement_WhileIf(&(*gen), gen_tag, O7C_GUARD(Ast_RWhileIf, &st));
	} else if (o7c_is(st, Ast_Repeat_s_tag)) {
		Statement_Repeat(&(*gen), gen_tag, O7C_GUARD(Ast_Repeat_s, &st));
	} else if (o7c_is(st, Ast_For_s_tag)) {
		Statement_For(&(*gen), gen_tag, O7C_GUARD(Ast_For_s, &st));
	} else if (o7c_is(st, Ast_Case_s_tag)) {
		Statement_Case(&(*gen), gen_tag, O7C_GUARD(Ast_Case_s, &st));
	} else {
		assert(false);
	}
}

static void Statements(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RStatement *stats) {
	while (stats != NULL) {
		Statement(&(*gen), gen_tag, stats);
		stats = stats->next;
	}
}

static void ProcDecl(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RProcedure *proc) {
	if (o7c_bl(proc->_._._.mark) && !(*gen).opt->main_) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"extern ", 8);
	} else {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"static ", 8);
	}
	Declarator(&(*gen), gen_tag, &proc->_._._, false, false, true);
	TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)";", 2);
}

static void Qualifier(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RType *type) {
	switch (type->_._.id) {
	case 0:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"int", 4);
		break;
	case 5:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"unsigned", 9);
		break;
	case 1:
		if ((o7c_cmp((*gen).opt->std, GeneratorC_IsoC99_cnst) >=  0) && (o7c_cmp((*gen).opt->varInit, GeneratorC_VarInitUndefined_cnst) !=  0)) {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"bool", 5);
		} else {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_bool", 9);
		}
		break;
	case 2:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"char unsigned", 14);
		break;
	case 3:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_char", 9);
		break;
	case 4:
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"double", 7);
		break;
	case 6:
	case 10:
		GlobalName(&(*gen), gen_tag, &type->_);
		break;
	default:
		abort();
		break;
	}
}

static void Procedure(struct MOut *out, o7c_tag_t out_tag, struct Ast_RProcedure *proc);
static void Procedure_Implement(struct MOut *out, o7c_tag_t out_tag, struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RProcedure *proc);
static void Implement_Procedure_CloseConsts(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *consts) {
	while ((consts != NULL) && (o7c_is(consts, Ast_Const_s_tag))) {
		TextGenerator_StrIgnoreIndent(&(*gen)._, gen_tag, (o7c_char *)"#", 2);
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"undef ", 7);
		Name(&(*gen), gen_tag, consts);
		TextGenerator_Ln(&(*gen)._, gen_tag);
		consts = consts->next;
	}
}

static struct Ast_RDeclaration *Implement_Procedure_SearchRetain(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *fp) {
	while ((fp != NULL) && ((o7c_cmp(fp->type->_._.id, Ast_IdPointer_cnst) !=  0) || o7c_bl(O7C_GUARD(Ast_FormalParam_s, &fp)->isVar))) {
		fp = fp->next;
	}
	return fp;
}

static void Implement_Procedure_RetainParams(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *fp) {
	if (fp != NULL) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_retain(", 12);
		Name(&(*gen), gen_tag, fp);
		fp = fp->next;
		while (fp != NULL) {
			if ((o7c_cmp(fp->type->_._.id, Ast_IdPointer_cnst) ==  0) && !O7C_GUARD(Ast_FormalParam_s, &fp)->isVar) {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"); o7c_retain(", 15);
				Name(&(*gen), gen_tag, fp);
			}
			fp = fp->next;
		}
		TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)");", 3);
	}
}

static void Implement_Procedure_ReleaseParams(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *fp) {
	if (fp != NULL) {
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_release(", 13);
		Name(&(*gen), gen_tag, fp);
		fp = fp->next;
		while (fp != NULL) {
			if ((o7c_cmp(fp->type->_._.id, Ast_IdPointer_cnst) ==  0) && !O7C_GUARD(Ast_FormalParam_s, &fp)->isVar) {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"); o7c_release(", 16);
				Name(&(*gen), gen_tag, fp);
			}
			fp = fp->next;
		}
		TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)");", 3);
	}
}

static void Implement_Procedure_ReleaseVars(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *var_) {
	o7c_bool first = O7C_BOOL_UNDEF;

	if (o7c_cmp((*gen).opt->memManager, GeneratorC_MemManagerCounter_cnst) ==  0) {
		first = true;
		while ((var_ != NULL) && (o7c_is(var_, Ast_RVar_tag))) {
			if (o7c_cmp(var_->type->_._.id, Ast_IdPointer_cnst) ==  0) {
				if (first) {
					first = false;
					TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_release(", 13);
				} else {
					TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"); o7c_release(", 16);
				}
				Name(&(*gen), gen_tag, var_);
			}
			var_ = var_->next;
		}
		if (!first) {
			TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)");", 3);
		}
	}
}

static void Procedure_Implement(struct MOut *out, o7c_tag_t out_tag, struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RProcedure *proc) {
	struct Ast_RDeclaration *retainParams = NULL;

	Comment(&(*gen), gen_tag, &proc->_._._._.comment, StringStore_String_tag);
	Mark(&(*gen), gen_tag, proc->_._._.mark);
	Declarator(&(*gen), gen_tag, &proc->_._._, false, false, true);
	TextGenerator_StrOpen(&(*gen)._, gen_tag, (o7c_char *)" {", 3);
	(*gen).localDeep = o7c_add((*gen).localDeep, 1);
	(*gen).fixedLen = (*gen)._.len;
	if (o7c_cmp((*gen).opt->memManager, GeneratorC_MemManagerCounter_cnst) !=  0) {
		retainParams = NULL;
	} else {
		retainParams = Implement_Procedure_SearchRetain(&(*gen), gen_tag, &proc->_.header->params->_._);
		if (proc->_.return_ != NULL) {
			Qualifier(&(*gen), gen_tag, proc->_.return_->type);
			if (o7c_cmp(proc->_.return_->type->_._.id, Ast_IdPointer_cnst) ==  0) {
				TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)" o7c_return = NULL;", 20);
			} else {
				TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)" o7c_return;", 13);
			}
		}
	}
	declarations(&(*out), out_tag, &proc->_._);
	Implement_Procedure_RetainParams(&(*gen), gen_tag, retainParams);
	Statements(&(*gen), gen_tag, proc->_._.stats);
	if (proc->_.return_ == NULL) {
		Implement_Procedure_ReleaseVars(&(*gen), gen_tag, &proc->_._.vars->_);
		Implement_Procedure_ReleaseParams(&(*gen), gen_tag, retainParams);
	} else {
		if (o7c_cmp((*gen).opt->memManager, GeneratorC_MemManagerCounter_cnst) ==  0) {
			if (o7c_cmp(proc->_.return_->type->_._.id, Ast_IdPointer_cnst) ==  0) {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"O7C_ASSIGN(&o7c_return, ", 25);
				CheckExpr(&(*gen), gen_tag, proc->_.return_);
				TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)");", 3);
			} else {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_return = ", 14);
				CheckExpr(&(*gen), gen_tag, proc->_.return_);
				TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)";", 2);
			}
			Implement_Procedure_ReleaseVars(&(*gen), gen_tag, &proc->_._.vars->_);
			Implement_Procedure_ReleaseParams(&(*gen), gen_tag, retainParams);
			if (o7c_cmp(proc->_.return_->type->_._.id, Ast_IdPointer_cnst) ==  0) {
				TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"o7c_unhold(o7c_return);", 24);
			}
			TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"return o7c_return;", 19);
		} else {
			Implement_Procedure_ReleaseVars(&(*gen), gen_tag, &proc->_._.vars->_);
			Implement_Procedure_ReleaseParams(&(*gen), gen_tag, retainParams);
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"return ", 8);
			ExprSameType(&(*gen), gen_tag, proc->_.return_, proc->_.header->_._._.type);
			TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)";", 2);
		}
	}
	(*gen).localDeep = o7c_sub((*gen).localDeep, 1);
	Implement_Procedure_CloseConsts(&(*gen), gen_tag, proc->_._.start);
	TextGenerator_StrLnClose(&(*gen)._, gen_tag, (o7c_char *)"}", 2);
	TextGenerator_Ln(&(*gen)._, gen_tag);
}

static void Procedure_LocalProcs(struct MOut *out, o7c_tag_t out_tag, struct Ast_RProcedure *proc) {
	struct Ast_RDeclaration *p = NULL, *t = NULL;

	t = (&(proc->_._.types)->_);
	while ((t != NULL) && (o7c_is(t, Ast_RType_tag))) {
		TypeDecl(&(*out), out_tag, O7C_GUARD(Ast_RType, &t));
		/*IF t IS Ast.Record THEN
				RecordTag(out.g[Implementation], t(Ast.Record))
			END;*/
		t = t->next;
	}
	p = (&(proc->_._.procedures)->_._._);
	if ((p != NULL) && !(*out).opt->procLocal) {
		if (!proc->_._._.mark) {
			/* TODO также проверить наличие рекурсии из локальных процедур*/
			ProcDecl(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, proc);
		}
		do {
			Procedure(&(*out), out_tag, O7C_GUARD(Ast_RProcedure, &p));
			p = p->next;
		} while (!(p == NULL));
	}
}

static void Procedure(struct MOut *out, o7c_tag_t out_tag, struct Ast_RProcedure *proc) {
	Procedure_LocalProcs(&(*out), out_tag, proc);
	if (o7c_bl(proc->_._._.mark) && !(*out).opt->main_) {
		ProcDecl(&(*out).g[Interface_cnst], GeneratorC_Generator_tag, proc);
	}
	Procedure_Implement(&(*out), out_tag, &(*out).g[Implementation_cnst], GeneratorC_Generator_tag, proc);
}

static void LnIfWrote(struct MOut *out, o7c_tag_t out_tag);
static void LnIfWrote_Write(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag) {
	if (o7c_cmp((*gen).fixedLen, (*gen)._.len) !=  0) {
		TextGenerator_Ln(&(*gen)._, gen_tag);
		(*gen).fixedLen = (*gen)._.len;
	}
}

static void LnIfWrote(struct MOut *out, o7c_tag_t out_tag) {
	LnIfWrote_Write(&(*out).g[Interface_cnst], GeneratorC_Generator_tag);
	LnIfWrote_Write(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag);
}

static void VarsInit(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *d);
static o7c_bool VarsInit_IsConformArrayType(struct Ast_RType *type, int *id, int *deep) {
	(*deep) = 0;
	while (o7c_cmp(type->_._.id, Ast_IdArray_cnst) ==  0) {
		(*deep) = o7c_add((*deep), 1);
		type = type->_.type;
	}
	(*id) = type->_._.id;
	return o7c_in((*id), ((1 << Ast_IdReal_cnst) | (1 << Ast_IdInteger_cnst) | (1 << Ast_IdBoolean_cnst)));
}

static void VarsInit(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *d) {
	int arrDeep = O7C_INT_UNDEF, arrTypeId = O7C_INT_UNDEF, i = O7C_INT_UNDEF;

	while ((d != NULL) && (o7c_is(d, Ast_RVar_tag))) {
		if (o7c_in(d->type->_._.id, ((1 << Ast_IdArray_cnst) | (1 << Ast_IdRecord_cnst)))) {
			if ((o7c_cmp((*gen).opt->varInit, GeneratorC_VarInitZero_cnst) ==  0) || (o7c_cmp(d->type->_._.id, Ast_IdRecord_cnst) ==  0) || (o7c_cmp(d->type->_._.id, Ast_IdArray_cnst) ==  0) && !VarsInit_IsConformArrayType(d->type, &arrTypeId, &arrDeep)) {
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"memset(&", 9);
				Name(&(*gen), gen_tag, d);
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", 0, sizeof(", 13);
				Name(&(*gen), gen_tag, d);
				TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"));", 4);
			} else {
				assert(o7c_cmp((*gen).opt->varInit, GeneratorC_VarInitUndefined_cnst) ==  0);
				switch (arrTypeId) {
				case 0:
					TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_ints_undef(", 16);
					break;
				case 4:
					TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_doubles_undef(", 19);
					break;
				case 1:
					TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_bools_undef(", 17);
					break;
				default:
					abort();
					break;
				}
				Name(&(*gen), gen_tag, d);
				for (i = 2; i <= arrDeep; ++i) {
					TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"[0]", 4);
				}
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)", sizeof(", 10);
				Name(&(*gen), gen_tag, d);
				TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)") / sizeof(", 12);
				Name(&(*gen), gen_tag, d);
				for (i = 2; i <= arrDeep; ++i) {
					TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"[0]", 4);
				}
				TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"[0]));", 7);
			}
		}
		d = d->next;
	}
}

static void Declarations(struct MOut *out, o7c_tag_t out_tag, struct Ast_RDeclarations *ds) {
	struct Ast_RDeclaration *d = NULL, *prev = NULL;

	d = ds->start;
	assert((d == NULL) || !(o7c_is(d, Ast_RModule_tag)));
	while ((d != NULL) && (o7c_is(d, Ast_Import_s_tag))) {
		Import(&(*out).g[o7c_ind(2, (int)!(*out).opt->main_)], GeneratorC_Generator_tag, d);
		d = d->next;
	}
	LnIfWrote(&(*out), out_tag);
	while ((d != NULL) && (o7c_is(d, Ast_Const_s_tag))) {
		Const(&(*out).g[o7c_ind(2, (int)(o7c_bl(d->mark) && !(*out).opt->main_))], GeneratorC_Generator_tag, O7C_GUARD(Ast_Const_s, &d));
		d = d->next;
	}
	LnIfWrote(&(*out), out_tag);
	if (o7c_is(ds, Ast_RModule_tag)) {
		while ((d != NULL) && (o7c_is(d, Ast_RType_tag))) {
			TypeDecl(&(*out), out_tag, O7C_GUARD(Ast_RType, &d));
			d = d->next;
		}
		LnIfWrote(&(*out), out_tag);
		while ((d != NULL) && (o7c_is(d, Ast_RVar_tag))) {
			Var(&(*out), out_tag, NULL, d, true);
			d = d->next;
		}
	} else {
		d = (&(ds->vars)->_);
		prev = NULL;
		while ((d != NULL) && (o7c_is(d, Ast_RVar_tag))) {
			Var(&(*out), out_tag, prev, d, (d->next == NULL) || !(o7c_is(d->next, Ast_RVar_tag)));
			prev = d;
			d = d->next;
		}
		if (o7c_cmp((*out).opt->varInit, GeneratorC_VarInitNo_cnst) !=  0) {
			VarsInit(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, &ds->vars->_);
		}
		d = (&(ds->procedures)->_._._);
	}
	LnIfWrote(&(*out), out_tag);
	if (o7c_bl((*out).opt->procLocal) || (o7c_is(ds, Ast_RModule_tag))) {
		while (d != NULL) {
			Procedure(&(*out), out_tag, O7C_GUARD(Ast_RProcedure, &d));
			d = d->next;
		}
	}
}

extern struct GeneratorC_Options_s *GeneratorC_DefaultOptions(void) {
	struct GeneratorC_Options_s *o = NULL;

	O7C_NEW(&o, GeneratorC_Options_s_tag);
	if (o != NULL) {
		V_Init(&(*o)._, GeneratorC_Options_s_tag);
		o->std = GeneratorC_IsoC99_cnst;
		o->gnu = false;
		o->plan9 = false;
		o->procLocal = false;
		o->checkIndex = true;
		o->checkArith = true;
		o->caseAbort = true;
		o->comment = true;
		o->varInit = GeneratorC_VarInitUndefined_cnst;
		o->memManager = GeneratorC_MemManagerNoFree_cnst;
		o->main_ = false;
	}
	return o;
}

static void MarkExpression(struct Ast_RExpression *e) {
	if (e != NULL) {
		if (o7c_cmp(e->_.id, Ast_IdRelation_cnst) ==  0) {
			MarkExpression(O7C_GUARD(Ast_ExprRelation_s, &e)->exprs[0]);
			MarkExpression(O7C_GUARD(Ast_ExprRelation_s, &e)->exprs[1]);
		} else if (o7c_cmp(e->_.id, Ast_IdTerm_cnst) ==  0) {
			MarkExpression(&O7C_GUARD(Ast_ExprTerm_s, &e)->factor->_);
			MarkExpression(O7C_GUARD(Ast_ExprTerm_s, &e)->expr);
		} else if (o7c_cmp(e->_.id, Ast_IdSum_cnst) ==  0) {
			MarkExpression(O7C_GUARD(Ast_ExprSum_s, &e)->term);
			MarkExpression(&O7C_GUARD(Ast_ExprSum_s, &e)->next->_);
		} else if ((o7c_cmp(e->_.id, Ast_IdDesignator_cnst) ==  0) && !O7C_GUARD(Ast_Designator_s, &e)->decl->mark) {
			O7C_GUARD(Ast_Designator_s, &e)->decl->mark = true;
			MarkExpression(O7C_GUARD(Ast_Const_s, &O7C_GUARD(Ast_Designator_s, &e)->decl)->expr);
		}
	}
}

static void MarkType(struct Ast_RType *t) {
	struct Ast_RDeclaration *d = NULL;

	while ((t != NULL) && !t->_.mark) {
		t->_.mark = true;
		if (o7c_cmp(t->_._.id, Ast_IdArray_cnst) ==  0) {
			MarkExpression(O7C_GUARD(Ast_RArray, &t)->count);
			t = t->_.type;
		} else if (o7c_in(t->_._.id, ((1 << Ast_IdRecord_cnst) | (1 << Ast_IdPointer_cnst)))) {
			if (o7c_cmp(t->_._.id, Ast_IdPointer_cnst) ==  0) {
				t = t->_.type;
				t->_.mark = true;
				assert(t->_.module != NULL);
			}
			d = (&(O7C_GUARD(Ast_Record_s, &t)->vars)->_);
			while (d != NULL) {
				MarkType(d->type);
				/*IF Strings.IsDefined(d.name) THEN
					Log.StrLn(d.name.block.s)
				END;*/
				d = d->next;
			}
			t = (&(O7C_GUARD(Ast_Record_s, &t)->base)->_._);
		} else {
			t = NULL;
		}
	}
}

static void MarkUsedInMarked(struct Ast_RModule *m);
static void MarkUsedInMarked_Consts(struct Ast_Const_s *c) {
	while (c != NULL) {
		if (c->_.mark) {
			MarkExpression(c->expr);
		}
		if ((c->_.next != NULL) && (o7c_is(c->_.next, Ast_Const_s_tag))) {
			c = O7C_GUARD(Ast_Const_s, &c->_.next);
		} else {
			c = NULL;
		}
	}
}

static void MarkUsedInMarked_Types(struct Ast_RDeclaration *t) {
	while ((t != NULL) && (o7c_is(t, Ast_RType_tag))) {
		if (t->mark) {
			t->mark = false;
			MarkType(O7C_GUARD(Ast_RType, &t));
		}
		t = t->next;
	}
}

static void MarkUsedInMarked(struct Ast_RModule *m) {
	struct Ast_RDeclaration *imp = NULL;

	imp = (&(m->import_)->_);
	while ((imp != NULL) && (o7c_is(imp, Ast_Import_s_tag))) {
		MarkUsedInMarked(imp->module);
		imp = imp->next;
	}
	MarkUsedInMarked_Consts(m->_.consts);
	MarkUsedInMarked_Types(&m->_.types->_);
}

static void ImportInit(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *imp) {
	if (imp != NULL) {
		assert(o7c_is(imp, Ast_Import_s_tag));
		do {
			TextGenerator_String(&(*gen)._, gen_tag, &imp->module->_._.name, StringStore_String_tag);
			TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"_init();", 9);
			imp = imp->next;
		} while (!((imp == NULL) || !(o7c_is(imp, Ast_Import_s_tag))));
		TextGenerator_Ln(&(*gen)._, gen_tag);
	}
}

static void TagsInit(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag) {
	struct Ast_Record_s *r = NULL;

	r = NULL;
	while ((*gen).opt->records != NULL) {
		r = O7C_GUARD(Ast_Record_s, &(*gen).opt->records);
		(*gen).opt->records = r->_._._._.ext;
		r->_._._._.ext = NULL;
		TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"o7c_tag_init(", 14);
		GlobalName(&(*gen), gen_tag, &r->_._._);
		if (r->base == NULL) {
			TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"_tag, NULL);", 13);
		} else {
			TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"_tag, ", 7);
			GlobalName(&(*gen), gen_tag, &r->base->_._._);
			TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"_tag);", 7);
		}
	}
	if (r != NULL) {
		TextGenerator_Ln(&(*gen)._, gen_tag);
	}
}

static void Generate_Init(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct VDataStream_Out *out, struct Ast_RModule *module, struct GeneratorC_Options_s *opt, o7c_bool interface_) {
	TextGenerator_Init(&(*gen)._, gen_tag, out);
	(*gen).module = module;
	(*gen).localDeep = 0;
	(*gen).opt = opt;
	(*gen).fixedLen = (*gen)._.len;
	(*gen).interface_ = interface_;
	(*gen).insideSizeOf = false;
}

static void Generate_Includes(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag) {
	TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"#include <stdlib.h>", 20);
	TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"#include <stddef.h>", 20);
	TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"#include <string.h>", 20);
	TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"#include <assert.h>", 20);
	TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"#include <math.h>", 18);
	if (o7c_cmp((*gen).opt->std, GeneratorC_IsoC99_cnst) >=  0) {
		TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"#include <stdbool.h>", 21);
	}
	TextGenerator_Ln(&(*gen)._, gen_tag);
	if (o7c_cmp((*gen).opt->varInit, GeneratorC_VarInitUndefined_cnst) ==  0) {
		TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"#define O7C_BOOL_UNDEFINED", 27);
	}
	TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"#include <o7c.h>", 17);
	TextGenerator_Ln(&(*gen)._, gen_tag);
}

static void Generate_HeaderGuard(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag) {
	TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"#if !defined(HEADER_GUARD_", 27);
	TextGenerator_String(&(*gen)._, gen_tag, &(*gen).module->_._.name, StringStore_String_tag);
	TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)")", 2);
	TextGenerator_Str(&(*gen)._, gen_tag, (o7c_char *)"#define HEADER_GUARD_", 22);
	TextGenerator_String(&(*gen)._, gen_tag, &(*gen).module->_._.name, StringStore_String_tag);
	TextGenerator_Ln(&(*gen)._, gen_tag);
	TextGenerator_Ln(&(*gen)._, gen_tag);
}

static void Generate_ModuleInit(struct GeneratorC_Generator *interf, o7c_tag_t interf_tag, struct GeneratorC_Generator *impl, o7c_tag_t impl_tag, struct Ast_RModule *module) {
	if ((module->import_ == NULL) && (module->_.stats == NULL) && ((*impl).opt->records == NULL)) {
		if (o7c_cmp((*impl).opt->std, GeneratorC_IsoC99_cnst) >=  0) {
			TextGenerator_Str(&(*interf)._, interf_tag, (o7c_char *)"static inline void ", 20);
		} else {
			TextGenerator_Str(&(*interf)._, interf_tag, (o7c_char *)"O7C_INLINE void ", 17);
		}
		Name(&(*interf), interf_tag, &module->_._);
		TextGenerator_StrLn(&(*interf)._, interf_tag, (o7c_char *)"_init(void) { ; }", 18);
	} else {
		TextGenerator_Str(&(*interf)._, interf_tag, (o7c_char *)"extern void ", 13);
		Name(&(*interf), interf_tag, &module->_._);
		TextGenerator_StrLn(&(*interf)._, interf_tag, (o7c_char *)"_init(void);", 13);
		TextGenerator_Str(&(*impl)._, impl_tag, (o7c_char *)"extern void ", 13);
		Name(&(*impl), impl_tag, &module->_._);
		TextGenerator_StrOpen(&(*impl)._, impl_tag, (o7c_char *)"_init(void) {", 14);
		TextGenerator_StrLn(&(*impl)._, impl_tag, (o7c_char *)"static int initialized = 0;", 28);
		TextGenerator_StrOpen(&(*impl)._, impl_tag, (o7c_char *)"if (0 == initialized) {", 24);
		ImportInit(&(*impl), impl_tag, &module->import_->_);
		TagsInit(&(*impl), impl_tag);
		Statements(&(*impl), impl_tag, module->_.stats);
		TextGenerator_StrLnClose(&(*impl)._, impl_tag, (o7c_char *)"}", 2);
		TextGenerator_StrLn(&(*impl)._, impl_tag, (o7c_char *)"++initialized;", 15);
		TextGenerator_StrLnClose(&(*impl)._, impl_tag, (o7c_char *)"}", 2);
		TextGenerator_Ln(&(*impl)._, impl_tag);
	}
}

static void Generate_Main(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RModule *module, struct Ast_Call_s *cmd) {
	TextGenerator_StrOpen(&(*gen)._, gen_tag, (o7c_char *)"extern int main(int argc, char **argv) {", 41);
	TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"o7c_init(argc, argv);", 22);
	ImportInit(&(*gen), gen_tag, &module->import_->_);
	TagsInit(&(*gen), gen_tag);
	if (module->_.stats != NULL) {
		Statements(&(*gen), gen_tag, module->_.stats);
	}
	if (cmd != NULL) {
		Statement(&(*gen), gen_tag, &cmd->_);
	}
	TextGenerator_StrLn(&(*gen)._, gen_tag, (o7c_char *)"return o7c_exit_code;", 22);
	TextGenerator_StrLnClose(&(*gen)._, gen_tag, (o7c_char *)"}", 2);
}

extern void GeneratorC_Generate(struct VDataStream_Out *interface_, struct VDataStream_Out *implementation, struct Ast_RModule *module, struct Ast_Call_s *cmd, struct GeneratorC_Options_s *opt) {
	struct MOut out ;
	memset(&out, 0, sizeof(out));

	assert(!Ast_HasError(module));
	if (opt == NULL) {
		opt = GeneratorC_DefaultOptions();
	}
	out.opt = opt;
	opt->records = NULL;
	opt->recordLast = NULL;
	opt->index = 0;
	opt->main_ = interface_ == NULL;
	if (!opt->main_) {
		MarkUsedInMarked(module);
	}
	if (interface_ != NULL) {
		Generate_Init(&out.g[Interface_cnst], GeneratorC_Generator_tag, interface_, module, opt, true);
	}
	Generate_Init(&out.g[Implementation_cnst], GeneratorC_Generator_tag, implementation, module, opt, false);
	Comment(&out.g[o7c_ind(2, (int)!opt->main_)], GeneratorC_Generator_tag, &module->_._._.comment, StringStore_String_tag);
	Generate_Includes(&out.g[Implementation_cnst], GeneratorC_Generator_tag);
	if (!opt->main_) {
		Generate_HeaderGuard(&out.g[Interface_cnst], GeneratorC_Generator_tag);
		Import(&out.g[Implementation_cnst], GeneratorC_Generator_tag, &module->_._);
	}
	Declarations(&out, MOut_tag, &module->_);
	if (opt->main_) {
		Generate_Main(&out.g[Implementation_cnst], GeneratorC_Generator_tag, module, cmd);
	} else {
		Generate_ModuleInit(&out.g[Interface_cnst], GeneratorC_Generator_tag, &out.g[Implementation_cnst], GeneratorC_Generator_tag, module);
		TextGenerator_StrLn(&out.g[Interface_cnst]._, GeneratorC_Generator_tag, (o7c_char *)"#endif", 7);
	}
}

extern void GeneratorC_init(void) {
	static int initialized = 0;
	if (0 == initialized) {
		V_init();
		Ast_init();
		StringStore_init();
		Scanner_init();
		VDataStream_init();
		TextGenerator_init();
		Utf8_init();
		Log_init();
		Limits_init();
		TranslatorLimits_init();

		o7c_tag_init(GeneratorC_Options_s_tag, V_Base_tag);
		o7c_tag_init(GeneratorC_Generator_tag, TextGenerator_Out_tag);
		o7c_tag_init(MemoryOut_tag, VDataStream_Out_tag);
		o7c_tag_init(MOut_tag, NULL);
		o7c_tag_init(Selectors_tag, NULL);

		type = Type;
		declarator = Declarator;
		declarations = Declarations;
		statements = Statements;
		expression = Expression;
	}
	++initialized;
}


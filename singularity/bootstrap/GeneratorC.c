#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#include <o7c.h>

#include "GeneratorC.h"

#define Interface_cnst 1
#define Implementation_cnst 0

int GeneratorC_Options_s_tag[15];

int GeneratorC_Generator_tag[15];

typedef struct MemoryOut {
	struct VDataStream_Out _;
	struct GeneratorC_anon_0000 {
				char unsigned buf[4096];
		int len;
	} mem[2];
	bool invert;
} MemoryOut;
static int MemoryOut_tag[15];

typedef struct MemoryOut *PMemoryOut;
typedef struct MOut {
		struct GeneratorC_Generator g[2];
	struct GeneratorC_Options_s *opt;
} MOut;
static int MOut_tag[15];

typedef struct Selectors {
		struct Ast_RDeclaration *decl;
	struct Ast_RSelector *list[TranslatorLimits_MaxSelectors_cnst];
	int i;
} Selectors;
static int Selectors_tag[15];


static void (*type)(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RType *type, int *type_tag, bool typeDecl, bool sameType);
static void (*declarator)(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RDeclaration *decl, int *decl_tag, bool typeDecl, bool sameType, bool global);
static void (*declarations)(struct MOut *out, int *out_tag, struct Ast_RDeclarations *ds, int *ds_tag);
static void (*statements)(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RStatement *stats, int *stats_tag);
static void (*expression)(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RExpression *expr, int *expr_tag);

static void MemoryWrite(struct MemoryOut *out, int *out_tag, char unsigned buf[/*len0*/], int buf_len0, int ofs, int count) {
	bool ret;

	ret = StringStore_CopyChars((*out).mem[(int)(*out).invert].buf, 4096, &(*out).mem[(int)(*out).invert].len, buf, buf_len0, ofs, ofs + count);
	assert(ret);
}

static int MemWrite(struct VDataStream_Out *out, int *out_tag, char unsigned buf[/*len0*/], int buf_len0, int ofs, int count) {
	MemoryWrite(&(O7C_GUARD(MemoryOut, &(*out), out_tag)), MemoryOut_tag, buf, buf_len0, ofs, count);
	return count;
}

static void MemoryOutInit(struct MemoryOut *mo, int *mo_tag) {
	VDataStream_InitOut(&(*mo)._, mo_tag, MemWrite);
	(*mo).mem[0].len = 0;
	(*mo).mem[1].len = 0;
	(*mo).invert = false;
}

static void MemWriteInvert(struct MemoryOut *mo, int *mo_tag) {
	int inv;
	bool ret;

	inv = (int)(*mo).invert;
	if ((*mo).mem[inv].len == 0) {
		(*mo).invert = !(*mo).invert;
	} else {
		ret = StringStore_CopyChars((*mo).mem[inv].buf, 4096, &(*mo).mem[inv].len, (*mo).mem[1 - inv].buf, 4096, 0, (*mo).mem[1 - inv].len);
		assert(ret);
		(*mo).mem[1 - inv].len = 0;
	}
}

static void MemWriteDirect(struct GeneratorC_Generator *gen, int *gen_tag, struct MemoryOut *mo, int *mo_tag) {
	int inv;

	inv = (int)(*mo).invert;
	assert((*mo).mem[1 - inv].len == 0);
	(*gen).len = (*gen).len + VDataStream_Write(&(*(*gen).out), NULL, (*mo).mem[inv].buf, 4096, 0, (*mo).mem[inv].len);
	(*mo).mem[inv].len = 0;
}

static void Str(struct GeneratorC_Generator *gen, int *gen_tag, char unsigned str[/*len0*/], int str_len0) {
	assert(str[str_len0 - 1] == 0x00u);
	(*gen).len = (*gen).len + VDataStream_Write(&(*(*gen).out), NULL, str, str_len0, 0, str_len0 - 1);
}

static void StrLn(struct GeneratorC_Generator *gen, int *gen_tag, char unsigned str[/*len0*/], int str_len0) {
	(*gen).len = (*gen).len + VDataStream_Write(&(*(*gen).out), NULL, str, str_len0, 0, str_len0 - 1);
	(*gen).len = (*gen).len + VDataStream_Write(&(*(*gen).out), NULL, "\x0A", 2, 0, 1);
}

static void Ln(struct GeneratorC_Generator *gen, int *gen_tag) {
	(*gen).len = (*gen).len + VDataStream_Write(&(*(*gen).out), NULL, "\x0A", 2, 0, 1);
}

static void Chars(struct GeneratorC_Generator *gen, int *gen_tag, char unsigned ch, int count) {
	char unsigned c[1];

	assert(count >= 0);
	c[0] = ch;
	while (count > 0) {
		(*gen).len = (*gen).len + VDataStream_Write(&(*(*gen).out), NULL, c, 1, 0, 1);
		count--;
	}
}

static void Tabs(struct GeneratorC_Generator *gen, int *gen_tag, int adder) {
	(*gen).tabs = (*gen).tabs + adder;
	Chars(&(*gen), gen_tag, 0x09u, (*gen).tabs);
}

static void String(struct GeneratorC_Generator *gen, int *gen_tag, struct StringStore_String *word, int *word_tag) {
	(*gen).len = (*gen).len + StringStore_Write(&(*(*gen).out), NULL, &(*word), word_tag);
}

static void ScreeningString(struct GeneratorC_Generator *gen, int *gen_tag, struct StringStore_String *str, int *str_tag) {
	int i;
	int len;
	int last;
	StringStore_Block block;

	block = (*str).block;
	i = (*str).ofs;
	last = i;
	assert(block->s[i] == (char unsigned)'"');
	i++;
	len = 0;
	while (1) if (block->s[i] == 0x0Cu) {
		len = len + VDataStream_Write(&(*(*gen).out), NULL, block->s, StringStore_BlockSize_cnst + 1, last, i - last);
		block = block->next;
		i = 0;
		last = 0;
	} else if (block->s[i] == (char unsigned)'\\') {
		len = len + VDataStream_Write(&(*(*gen).out), NULL, block->s, StringStore_BlockSize_cnst + 1, last, i - last + 1);
		len = len + VDataStream_Write(&(*(*gen).out), NULL, "\\", 2, 0, 1);
		i++;
		last = i;
	} else if (block->s[i] > 0x0Cu) {
		i++;
	} else break;
	assert(block->s[i] == 0x00u);
	(*gen).len = (*gen).len + VDataStream_Write(&(*(*gen).out), NULL, block->s, StringStore_BlockSize_cnst + 1, last, i - last);
}

static void Int(struct GeneratorC_Generator *gen, int *gen_tag, int int_) {
	char unsigned buf[14];
	int i;
	bool sign;

	sign = int_ < 0;
	if (sign) {
		int_ =  - int_;
	}
	i = sizeof(buf) / sizeof (buf[0]);
	do {
		i--;
		buf[i] = (char unsigned)((int)(char unsigned)'0' + int_ % 10);
		int_ = int_ / 10;
	} while (!(int_ == 0));
	if (sign) {
		i--;
		buf[i] = (char unsigned)'-';
	}
	(*gen).len = (*gen).len + VDataStream_Write(&(*(*gen).out), NULL, buf, 14, i, sizeof(buf) / sizeof (buf[0]) - i);
}

static void Real(struct GeneratorC_Generator *gen, int *gen_tag, double real) {
	Str(&(*gen), gen_tag, "Real not implemented", 21);
}

static bool IsNameOccupied(struct StringStore_String *n, int *n_tag);
static bool IsNameOccupied_Eq(struct StringStore_String *name, int *name_tag, char unsigned str[/*len0*/], int str_len0) {
	return StringStore_IsEqualToString(&(*name), name_tag, str, str_len0);
}

static bool IsNameOccupied(struct StringStore_String *n, int *n_tag) {
	return IsNameOccupied_Eq(&(*n), n_tag, "auto", 5) || IsNameOccupied_Eq(&(*n), n_tag, "break", 6) || IsNameOccupied_Eq(&(*n), n_tag, "case", 5) || IsNameOccupied_Eq(&(*n), n_tag, "char", 5) || IsNameOccupied_Eq(&(*n), n_tag, "const", 6) || IsNameOccupied_Eq(&(*n), n_tag, "continue", 9) || IsNameOccupied_Eq(&(*n), n_tag, "default", 8) || IsNameOccupied_Eq(&(*n), n_tag, "do", 3) || IsNameOccupied_Eq(&(*n), n_tag, "double", 7) || IsNameOccupied_Eq(&(*n), n_tag, "else", 5) || IsNameOccupied_Eq(&(*n), n_tag, "enum", 5) || IsNameOccupied_Eq(&(*n), n_tag, "extern", 7) || IsNameOccupied_Eq(&(*n), n_tag, "float", 6) || IsNameOccupied_Eq(&(*n), n_tag, "for", 4) || IsNameOccupied_Eq(&(*n), n_tag, "goto", 5) || IsNameOccupied_Eq(&(*n), n_tag, "if", 3) || IsNameOccupied_Eq(&(*n), n_tag, "inline", 7) || IsNameOccupied_Eq(&(*n), n_tag, "int", 4) || IsNameOccupied_Eq(&(*n), n_tag, "long", 5) || IsNameOccupied_Eq(&(*n), n_tag, "register", 9) || IsNameOccupied_Eq(&(*n), n_tag, "return", 7) || IsNameOccupied_Eq(&(*n), n_tag, "short", 6) || IsNameOccupied_Eq(&(*n), n_tag, "signed", 7) || IsNameOccupied_Eq(&(*n), n_tag, "sizeof", 7) || IsNameOccupied_Eq(&(*n), n_tag, "static", 7) || IsNameOccupied_Eq(&(*n), n_tag, "struct", 7) || IsNameOccupied_Eq(&(*n), n_tag, "switch", 7) || IsNameOccupied_Eq(&(*n), n_tag, "typedef", 8) || IsNameOccupied_Eq(&(*n), n_tag, "union", 6) || IsNameOccupied_Eq(&(*n), n_tag, "unsigned", 9) || IsNameOccupied_Eq(&(*n), n_tag, "void", 5) || IsNameOccupied_Eq(&(*n), n_tag, "volatile", 9) || IsNameOccupied_Eq(&(*n), n_tag, "while", 6) || IsNameOccupied_Eq(&(*n), n_tag, "asm", 4) || IsNameOccupied_Eq(&(*n), n_tag, "typeof", 7) || IsNameOccupied_Eq(&(*n), n_tag, "abort", 6) || IsNameOccupied_Eq(&(*n), n_tag, "assert", 7) || IsNameOccupied_Eq(&(*n), n_tag, "bool", 5) || IsNameOccupied_Eq(&(*n), n_tag, "calloc", 7) || IsNameOccupied_Eq(&(*n), n_tag, "free", 5) || IsNameOccupied_Eq(&(*n), n_tag, "main", 5) || IsNameOccupied_Eq(&(*n), n_tag, "malloc", 7) || IsNameOccupied_Eq(&(*n), n_tag, "memcmp", 7) || IsNameOccupied_Eq(&(*n), n_tag, "memset", 7) || IsNameOccupied_Eq(&(*n), n_tag, "NULL", 5) || IsNameOccupied_Eq(&(*n), n_tag, "strcmp", 7) || IsNameOccupied_Eq(&(*n), n_tag, "strcpy", 7) || IsNameOccupied_Eq(&(*n), n_tag, "realloc", 8) || IsNameOccupied_Eq(&(*n), n_tag, "array", 6) || IsNameOccupied_Eq(&(*n), n_tag, "catch", 6) || IsNameOccupied_Eq(&(*n), n_tag, "class", 6) || IsNameOccupied_Eq(&(*n), n_tag, "decltype", 9) || IsNameOccupied_Eq(&(*n), n_tag, "delegate", 9) || IsNameOccupied_Eq(&(*n), n_tag, "delete", 7) || IsNameOccupied_Eq(&(*n), n_tag, "deprecated", 11) || IsNameOccupied_Eq(&(*n), n_tag, "dllexport", 10) || IsNameOccupied_Eq(&(*n), n_tag, "dllimport", 10) || IsNameOccupied_Eq(&(*n), n_tag, "dllexport", 10) || IsNameOccupied_Eq(&(*n), n_tag, "event", 6) || IsNameOccupied_Eq(&(*n), n_tag, "explicit", 9) || IsNameOccupied_Eq(&(*n), n_tag, "finally", 8) || IsNameOccupied_Eq(&(*n), n_tag, "each", 5) || IsNameOccupied_Eq(&(*n), n_tag, "in", 3) || IsNameOccupied_Eq(&(*n), n_tag, "friend", 7) || IsNameOccupied_Eq(&(*n), n_tag, "gcnew", 6) || IsNameOccupied_Eq(&(*n), n_tag, "generic", 8) || IsNameOccupied_Eq(&(*n), n_tag, "initonly", 9) || IsNameOccupied_Eq(&(*n), n_tag, "interface", 10) || IsNameOccupied_Eq(&(*n), n_tag, "literal", 8) || IsNameOccupied_Eq(&(*n), n_tag, "mutable", 8) || IsNameOccupied_Eq(&(*n), n_tag, "naked", 6) || IsNameOccupied_Eq(&(*n), n_tag, "namespace", 10) || IsNameOccupied_Eq(&(*n), n_tag, "new", 4) || IsNameOccupied_Eq(&(*n), n_tag, "noinline", 9) || IsNameOccupied_Eq(&(*n), n_tag, "noreturn", 9) || IsNameOccupied_Eq(&(*n), n_tag, "nothrow", 8) || IsNameOccupied_Eq(&(*n), n_tag, "novtable", 9) || IsNameOccupied_Eq(&(*n), n_tag, "nullptr", 8) || IsNameOccupied_Eq(&(*n), n_tag, "operator", 9) || IsNameOccupied_Eq(&(*n), n_tag, "private", 8) || IsNameOccupied_Eq(&(*n), n_tag, "property", 9) || IsNameOccupied_Eq(&(*n), n_tag, "protected", 10) || IsNameOccupied_Eq(&(*n), n_tag, "public", 7) || IsNameOccupied_Eq(&(*n), n_tag, "ref", 4) || IsNameOccupied_Eq(&(*n), n_tag, "safecast", 9) || IsNameOccupied_Eq(&(*n), n_tag, "sealed", 7) || IsNameOccupied_Eq(&(*n), n_tag, "selectany", 10) || IsNameOccupied_Eq(&(*n), n_tag, "super", 6) || IsNameOccupied_Eq(&(*n), n_tag, "template", 9) || IsNameOccupied_Eq(&(*n), n_tag, "this", 5) || IsNameOccupied_Eq(&(*n), n_tag, "thread", 7) || IsNameOccupied_Eq(&(*n), n_tag, "throw", 6) || IsNameOccupied_Eq(&(*n), n_tag, "try", 4) || IsNameOccupied_Eq(&(*n), n_tag, "typeid", 7) || IsNameOccupied_Eq(&(*n), n_tag, "typename", 9) || IsNameOccupied_Eq(&(*n), n_tag, "uuid", 5) || IsNameOccupied_Eq(&(*n), n_tag, "value", 6) || IsNameOccupied_Eq(&(*n), n_tag, "virtual", 8) || IsNameOccupied_Eq(&(*n), n_tag, "abstract", 9) || IsNameOccupied_Eq(&(*n), n_tag, "arguments", 10) || IsNameOccupied_Eq(&(*n), n_tag, "boolean", 8) || IsNameOccupied_Eq(&(*n), n_tag, "byte", 5) || IsNameOccupied_Eq(&(*n), n_tag, "debugger", 9) || IsNameOccupied_Eq(&(*n), n_tag, "eval", 5) || IsNameOccupied_Eq(&(*n), n_tag, "export", 7) || IsNameOccupied_Eq(&(*n), n_tag, "extends", 8) || IsNameOccupied_Eq(&(*n), n_tag, "final", 6) || IsNameOccupied_Eq(&(*n), n_tag, "function", 9) || IsNameOccupied_Eq(&(*n), n_tag, "implements", 11) || IsNameOccupied_Eq(&(*n), n_tag, "import", 7) || IsNameOccupied_Eq(&(*n), n_tag, "instanceof", 11) || IsNameOccupied_Eq(&(*n), n_tag, "interface", 10) || IsNameOccupied_Eq(&(*n), n_tag, "let", 4) || IsNameOccupied_Eq(&(*n), n_tag, "native", 7) || IsNameOccupied_Eq(&(*n), n_tag, "null", 5) || IsNameOccupied_Eq(&(*n), n_tag, "package", 8) || IsNameOccupied_Eq(&(*n), n_tag, "private", 8) || IsNameOccupied_Eq(&(*n), n_tag, "protected", 10) || IsNameOccupied_Eq(&(*n), n_tag, "synchronized", 13) || IsNameOccupied_Eq(&(*n), n_tag, "throws", 7) || IsNameOccupied_Eq(&(*n), n_tag, "transient", 10) || IsNameOccupied_Eq(&(*n), n_tag, "var", 4) || IsNameOccupied_Eq(&(*n), n_tag, "func", 5);
}

static void Name(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RDeclaration *decl, int *decl_tag) {
	struct Ast_RDeclarations *up;

	if (!(*gen).opt->procLocal && (o7c_is(NULL, decl, Ast_RProcedure_tag))) {
		up = (&O7C_GUARD(Ast_RProcedure, decl, NULL))->_._.up;
		while (!(o7c_is(NULL, up, Ast_RModule_tag))) {
			String(&(*gen), gen_tag, &up->_.name, StringStore_String_tag);
			Str(&(*gen), gen_tag, "_", 2);
			up = up->up;
		}
	}
	String(&(*gen), gen_tag, &decl->name, StringStore_String_tag);
	if (o7c_is(NULL, decl, Ast_Const_s_tag)) {
		Str(&(*gen), gen_tag, "_cnst", 6);
	} else if (IsNameOccupied(&decl->name, StringStore_String_tag)) {
		Str(&(*gen), gen_tag, "_", 2);
	}
}

static void GlobalName(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RDeclaration *decl, int *decl_tag) {
	if (decl->mark || (decl->module != NULL) && ((*gen).module != decl->module)) {
		assert(decl->module != NULL);
		String(&(*gen), gen_tag, &decl->module->_._.name, StringStore_String_tag);
		Str(&(*gen), gen_tag, "_", 2);
		String(&(*gen), gen_tag, &decl->name, StringStore_String_tag);
		if (o7c_is(NULL, decl, Ast_Const_s_tag)) {
			Str(&(*gen), gen_tag, "_cnst", 6);
		}
	} else {
		Name(&(*gen), gen_tag, decl, NULL);
	}
}

static void Import(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RDeclaration *decl, int *decl_tag) {
	Str(&(*gen), gen_tag, "#include ", 10);
	Str(&(*gen), gen_tag, "\x22", 2);
	String(&(*gen), gen_tag, &decl->module->_._.name, StringStore_String_tag);
	Str(&(*gen), gen_tag, ".h", 3);
	StrLn(&(*gen), gen_tag, "\x22", 2);
}

static void Factor(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RExpression *expr, int *expr_tag) {
	if (o7c_is(NULL, expr, Ast_RFactor_tag)) {
		expression(&(*gen), gen_tag, expr, NULL);
	} else {
		Str(&(*gen), gen_tag, "(", 2);
		expression(&(*gen), gen_tag, expr, NULL);
		Str(&(*gen), gen_tag, ")", 2);
	}
}

static bool CheckStructName(struct GeneratorC_Generator *gen, int *gen_tag, Ast_Record rec, int *rec_tag) {
	char unsigned anon[TranslatorLimits_MaxLenName_cnst * 2 + 3];
	int i;
	int j;
	int l;
	bool ret;

	if (rec->_._._.name.block == NULL) {
		if ((rec->pointer != NULL) && (rec->pointer->_._._.name.block != NULL)) {
			l = 0;
			assert(rec->_._._.module != NULL);
			rec->_._._.mark = true;
			StringStore_CopyToChars(anon, TranslatorLimits_MaxLenName_cnst * 2 + 3, &l, &rec->pointer->_._._.name, StringStore_String_tag);
			anon[l] = (char unsigned)'_';
			anon[l + 1] = (char unsigned)'s';
			anon[l + 2] = 0x00u;
			Ast_PutChars(rec->pointer->_._._.module, NULL, &rec->_._._.name, StringStore_String_tag, anon, TranslatorLimits_MaxLenName_cnst * 2 + 3, 0, l + 2);
		} else {
			l = 0;
			StringStore_CopyToChars(anon, TranslatorLimits_MaxLenName_cnst * 2 + 3, &l, &rec->_._._.module->_._.name, StringStore_String_tag);
			anon[l] = (char unsigned)'_';
			l++;
			Log_StrLn("Record", 7);
			ret = StringStore_CopyChars(anon, TranslatorLimits_MaxLenName_cnst * 2 + 3, &l, "anon_0000", 10, 0, 9);
			assert(ret);
			assert(((*gen).opt->index >= 0) && ((*gen).opt->index < 10000));
			i = (*gen).opt->index;
			j = l - 1;
			while (i > 0) {
				anon[j] = (char unsigned)((int)(char unsigned)'0' + i % 10);
				i = i / 10;
				j--;
			}
			(*gen).opt->index++;
			Ast_PutChars(rec->_._._.module, NULL, &rec->_._._.name, StringStore_String_tag, anon, TranslatorLimits_MaxLenName_cnst * 2 + 3, 0, l);
		}
	}
	return rec->_._._.name.block != NULL;
}

static void Designator(struct GeneratorC_Generator *gen, int *gen_tag, Ast_Designator des, int *des_tag);
static void Designator_Put(struct Selectors *sels, int *sels_tag, struct Ast_RSelector *sel, int *sel_tag) {
	(*sels).i =  - 1;
	while (sel != NULL) {
		(*sels).i++;
		(*sels).list[(*sels).i] = sel;
		if (o7c_is(NULL, sel, Ast_SelArray_s_tag)) {
			while ((sel != NULL) && (o7c_is(NULL, sel, Ast_SelArray_s_tag))) {
				sel = sel->next;
			}
		} else {
			sel = sel->next;
		}
	}
}

static void Designator_Array(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RType **type, int *type_tag, struct Ast_RSelector **sel, int *sel_tag, struct Ast_RDeclaration *decl, int *decl_tag) {
	struct Ast_RSelector *s;
	int i;
	int j;

	Str(&(*gen), gen_tag, "[", 2);
	if (((*type)->_.type->_._.id != Ast_IdArray_cnst) || ((&O7C_GUARD(Ast_RArray, (*type), NULL))->count != NULL)) {
		expression(&(*gen), gen_tag, (&O7C_GUARD(Ast_SelArray_s, (*sel), NULL))->index, NULL);
		(*type) = (*type)->_.type;
		(*sel) = (*sel)->next;
		while (((*sel) != NULL) && (o7c_is(NULL, (*sel), Ast_SelArray_s_tag))) {
			Str(&(*gen), gen_tag, "][", 3);
			expression(&(*gen), gen_tag, (&O7C_GUARD(Ast_SelArray_s, (*sel), NULL))->index, NULL);
			(*sel) = (*sel)->next;
			(*type) = (*type)->_.type;
		}
	} else {
		i = 0;
		while (((*sel)->next != NULL) && (o7c_is(NULL, (*sel)->next, Ast_SelArray_s_tag))) {
			Factor(&(*gen), gen_tag, (&O7C_GUARD(Ast_SelArray_s, (*sel), NULL))->index, NULL);
			(*sel) = (*sel)->next;
			s = (*sel);
			j = i;
			while ((s != NULL) && (o7c_is(NULL, s, Ast_SelArray_s_tag))) {
				Str(&(*gen), gen_tag, " * ", 4);
				Name(&(*gen), gen_tag, decl, NULL);
				Str(&(*gen), gen_tag, "_len", 5);
				Int(&(*gen), gen_tag, j);
				j++;
				s = s->next;
			}
			i++;
			(*type) = (*type)->_.type;
			Str(&(*gen), gen_tag, " + ", 4);
		}
		Factor(&(*gen), gen_tag, (&O7C_GUARD(Ast_SelArray_s, (*sel), NULL))->index, NULL);
	}
	Str(&(*gen), gen_tag, "]", 2);
}

static bool Designator_Search(struct Ast_RDeclarations *ds, int *ds_tag, struct Ast_RDeclaration *d, int *d_tag) {
	struct Ast_RDeclaration *c;

	c = (&(ds->vars)->_);
	while ((c != NULL) && (c != d)) {
		c = c->next;
	}
	return c != NULL;
}

static void Designator_Record(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RType **type, int *type_tag, struct Ast_RSelector **sel, int *sel_tag) {
	struct Ast_RDeclaration *var_;
	struct Ast_RDeclarations *up;
	int i;

	var_ = (&((&O7C_GUARD(Ast_SelRecord_s, (*sel), NULL))->var_)->_);
	if (o7c_is(NULL, (*type), Ast_RPointer_tag)) {
		up = (&O7C_GUARD(Ast_Record_s, (&O7C_GUARD(Ast_RPointer, (*type), NULL))->_._._.type, NULL))->vars;
	} else {
		up = (&O7C_GUARD(Ast_Record_s, (*type), NULL))->vars;
	}
	if ((*type)->_._.id == Ast_IdPointer_cnst) {
		Str(&(*gen), gen_tag, "->", 3);
	} else {
		Str(&(*gen), gen_tag, ".", 2);
	}
	while ((up != NULL) && !Designator_Search(up, NULL, var_, NULL)) {
		up = up->up;
		Str(&(*gen), gen_tag, "_.", 3);
		i--;
	}
	Name(&(*gen), gen_tag, var_, NULL);
	(*type) = var_->type;
}

static void Designator_Declarator(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RDeclaration *decl, int *decl_tag) {
	struct Ast_RType *type;

	type = decl->type;
	if ((o7c_is(NULL, decl, Ast_FormalParam_s_tag)) && ((&O7C_GUARD(Ast_FormalParam_s, decl, NULL))->isVar && (type->_._.id != Ast_IdArray_cnst) || (type->_._.id == Ast_IdRecord_cnst))) {
		Str(&(*gen), gen_tag, "(*", 3);
		GlobalName(&(*gen), gen_tag, decl, NULL);
		Str(&(*gen), gen_tag, ")", 2);
	} else {
		GlobalName(&(*gen), gen_tag, decl, NULL);
	}
}

static void Designator_Selector(struct GeneratorC_Generator *gen, int *gen_tag, struct Selectors *sels, int *sels_tag, int i, struct Ast_RType **typ, int *typ_tag) {
	struct Ast_RSelector *sel;
	bool ret;

	if (i < 0) {
		Designator_Declarator(&(*gen), gen_tag, (*sels).decl, NULL);
	} else {
		sel = (*sels).list[i];
		i--;
		if (o7c_is(NULL, sel, Ast_SelRecord_s_tag)) {
			Designator_Selector(&(*gen), gen_tag, &(*sels), sels_tag, i, &(*typ), NULL);
			Designator_Record(&(*gen), gen_tag, &(*typ), NULL, &sel, NULL);
		} else if (o7c_is(NULL, sel, Ast_SelArray_s_tag)) {
			Designator_Selector(&(*gen), gen_tag, &(*sels), sels_tag, i, &(*typ), NULL);
			Designator_Array(&(*gen), gen_tag, &(*typ), NULL, &sel, NULL, (*sels).decl, NULL);
		} else if (o7c_is(NULL, sel, Ast_SelPointer_s_tag)) {
			if ((sel->next == NULL) || !(o7c_is(NULL, sel->next, Ast_SelRecord_s_tag))) {
				Str(&(*gen), gen_tag, "(*", 3);
				Designator_Selector(&(*gen), gen_tag, &(*sels), sels_tag, i, &(*typ), NULL);
				Str(&(*gen), gen_tag, ")", 2);
			} else {
				Designator_Selector(&(*gen), gen_tag, &(*sels), sels_tag, i, &(*typ), NULL);
			}
		} else if (o7c_is(NULL, sel, Ast_SelGuard_s_tag)) {
			if ((&O7C_GUARD(Ast_SelGuard_s, sel, NULL))->type->_._.id == Ast_IdPointer_cnst) {
				Str(&(*gen), gen_tag, "(&O7C_GUARD(", 13);
				ret = CheckStructName(&(*gen), gen_tag, (&O7C_GUARD(Ast_Record_s, (&O7C_GUARD(Ast_SelGuard_s, sel, NULL))->type->_.type, NULL)), NULL);
				assert(ret);
				GlobalName(&(*gen), gen_tag, &(&O7C_GUARD(Ast_SelGuard_s, sel, NULL))->type->_.type->_, NULL);
			} else {
				Str(&(*gen), gen_tag, "(O7C_GUARD(", 12);
				GlobalName(&(*gen), gen_tag, &(&O7C_GUARD(Ast_SelGuard_s, sel, NULL))->type->_, NULL);
			}
			if ((&O7C_GUARD(Ast_SelGuard_s, sel, NULL))->type->_._.id == Ast_IdPointer_cnst) {
				Str(&(*gen), gen_tag, ", ", 3);
			} else {
				Str(&(*gen), gen_tag, ", &", 4);
			}
			Designator_Selector(&(*gen), gen_tag, &(*sels), sels_tag, i, &(*typ), NULL);
			if ((&O7C_GUARD(Ast_SelGuard_s, sel, NULL))->type->_._.id == Ast_IdPointer_cnst) {
				Str(&(*gen), gen_tag, ", NULL))", 9);
			} else {
				Str(&(*gen), gen_tag, ", ", 3);
				GlobalName(&(*gen), gen_tag, (*sels).decl, NULL);
				Str(&(*gen), gen_tag, "_tag))", 7);
			}
			(*typ) = (&O7C_GUARD(Ast_SelGuard_s, sel, NULL))->type;
		} else {
			assert(false);
		}
	}
}

static void Designator(struct GeneratorC_Generator *gen, int *gen_tag, Ast_Designator des, int *des_tag) {
	struct Selectors sels;
	struct Ast_RType *typ;

	Designator_Put(&sels, Selectors_tag, des->sel, NULL);
	typ = des->decl->type;
	sels.decl = des->decl;
	(*gen).opt->lastSelectorDereference = (sels.i > 0) && (o7c_is(NULL, sels.list[sels.i], Ast_SelPointer_s_tag));
	Designator_Selector(&(*gen), gen_tag, &sels, Selectors_tag, sels.i, &typ, NULL);
}

static void Expression(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RExpression *expr, int *expr_tag);
static void Expression_Predefined(struct GeneratorC_Generator *gen, int *gen_tag, Ast_ExprCall call, int *call_tag);
static void Predefined_Expression_Shift(struct GeneratorC_Generator *gen, int *gen_tag, char unsigned shift[/*len0*/], int shift_len0, Ast_Parameter ps, int *ps_tag) {
	Str(&(*gen), gen_tag, "(int)((unsigned)", 17);
	Factor(&(*gen), gen_tag, ps->expr, NULL);
	Str(&(*gen), gen_tag, shift, shift_len0);
	Factor(&(*gen), gen_tag, ps->next->expr, NULL);
	Str(&(*gen), gen_tag, ")", 2);
}

static void Predefined_Expression_Len(struct GeneratorC_Generator *gen, int *gen_tag, Ast_Designator des, int *des_tag) {
	struct Ast_RSelector *sel;
	int i;

	if ((des->decl->type->_._.id != Ast_IdArray_cnst) || !(o7c_is(NULL, des->decl, Ast_FormalParam_s_tag))) {
		Str(&(*gen), gen_tag, "sizeof(", 8);
		Designator(&(*gen), gen_tag, des, NULL);
		Str(&(*gen), gen_tag, ") / sizeof (", 13);
		Designator(&(*gen), gen_tag, des, NULL);
		Str(&(*gen), gen_tag, "[0])", 5);
	} else {
		GlobalName(&(*gen), gen_tag, des->decl, NULL);
		Str(&(*gen), gen_tag, "_len", 5);
		i = 0;
		sel = des->sel;
		while (sel != NULL) {
			i++;
			sel = sel->next;
		}
		Int(&(*gen), gen_tag, i);
	}
}

static void Predefined_Expression_New(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RExpression *e, int *e_tag) {
	bool ret;

	Expression(&(*gen), gen_tag, e, NULL);
	Str(&(*gen), gen_tag, " = o7c_new(sizeof(*", 20);
	Expression(&(*gen), gen_tag, e, NULL);
	Str(&(*gen), gen_tag, "), ", 4);
	ret = CheckStructName(&(*gen), gen_tag, (&O7C_GUARD(Ast_Record_s, e->type->_.type, NULL)), NULL);
	assert(ret);
	GlobalName(&(*gen), gen_tag, &e->type->_.type->_, NULL);
	Str(&(*gen), gen_tag, "_tag)", 6);
}

static void Predefined_Expression_Ord(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RExpression *e, int *e_tag) {
	Str(&(*gen), gen_tag, "(int)", 6);
	Factor(&(*gen), gen_tag, e, NULL);
}

static void Expression_Predefined(struct GeneratorC_Generator *gen, int *gen_tag, Ast_ExprCall call, int *call_tag) {
	struct Ast_RExpression *e1;
	Ast_Parameter p2;

	e1 = call->params->expr;
	p2 = call->params->next;
	{ int o7_case_expr = call->designator->decl->_.id;
		if ((o7_case_expr == 90)) {
			if (call->_._.type->_._.id == Ast_IdInteger_cnst) {
				Str(&(*gen), gen_tag, "abs(", 5);
			} else {
				Str(&(*gen), gen_tag, "fabs(", 6);
			}
			Expression(&(*gen), gen_tag, e1, NULL);
			Str(&(*gen), gen_tag, ")", 2);
		} else if ((o7_case_expr == 107)) {
			Str(&(*gen), gen_tag, "(", 2);
			Factor(&(*gen), gen_tag, e1, NULL);
			Str(&(*gen), gen_tag, " % 2 == 1)", 11);
		} else if ((o7_case_expr == 104)) {
			Predefined_Expression_Len(&(*gen), gen_tag, (&O7C_GUARD(Ast_Designator_s, e1, NULL)), NULL);
		} else if ((o7_case_expr == 105)) {
			Predefined_Expression_Shift(&(*gen), gen_tag, " << ", 5, call->params, NULL);
		} else if ((o7_case_expr == 91)) {
			Predefined_Expression_Shift(&(*gen), gen_tag, " >> ", 5, call->params, NULL);
		} else if ((o7_case_expr == 111)) {
			Str(&(*gen), gen_tag, "o7_ror(", 8);
			Expression(&(*gen), gen_tag, e1, NULL);
			Str(&(*gen), gen_tag, ", ", 3);
			Expression(&(*gen), gen_tag, p2->expr, NULL);
			Str(&(*gen), gen_tag, ")", 2);
		} else if ((o7_case_expr == 99)) {
			Str(&(*gen), gen_tag, "(int)", 6);
			Factor(&(*gen), gen_tag, e1, NULL);
		} else if ((o7_case_expr == 100)) {
			Str(&(*gen), gen_tag, "(double)", 9);
			Factor(&(*gen), gen_tag, e1, NULL);
		} else if ((o7_case_expr == 108)) {
			Predefined_Expression_Ord(&(*gen), gen_tag, e1, NULL);
		} else if ((o7_case_expr == 96)) {
			Str(&(*gen), gen_tag, "(char unsigned)", 16);
			Factor(&(*gen), gen_tag, e1, NULL);
		} else if ((o7_case_expr == 101)) {
			Expression(&(*gen), gen_tag, e1, NULL);
			if (p2 == NULL) {
				Str(&(*gen), gen_tag, "++", 3);
			} else {
				Str(&(*gen), gen_tag, " += ", 5);
				Expression(&(*gen), gen_tag, p2->expr, NULL);
			}
		} else if ((o7_case_expr == 97)) {
			Expression(&(*gen), gen_tag, e1, NULL);
			if (p2 == NULL) {
				Str(&(*gen), gen_tag, "--", 3);
			} else {
				Str(&(*gen), gen_tag, " -= ", 5);
				Expression(&(*gen), gen_tag, p2->expr, NULL);
			}
		} else if ((o7_case_expr == 102)) {
			Expression(&(*gen), gen_tag, e1, NULL);
			Str(&(*gen), gen_tag, " |= 1u << ", 11);
			Factor(&(*gen), gen_tag, p2->expr, NULL);
		} else if ((o7_case_expr == 98)) {
			Expression(&(*gen), gen_tag, e1, NULL);
			Str(&(*gen), gen_tag, " &= ~(1u << ", 13);
			Factor(&(*gen), gen_tag, p2->expr, NULL);
			Str(&(*gen), gen_tag, ")", 2);
		} else if ((o7_case_expr == 106)) {
			Predefined_Expression_New(&(*gen), gen_tag, e1, NULL);
		} else if ((o7_case_expr == 92)) {
			Str(&(*gen), gen_tag, "assert(", 8);
			Expression(&(*gen), gen_tag, e1, NULL);
			Str(&(*gen), gen_tag, ")", 2);
		} else if ((o7_case_expr == 109)) {
			Expression(&(*gen), gen_tag, e1, NULL);
			Str(&(*gen), gen_tag, " *= 1 << ", 10);
			Expression(&(*gen), gen_tag, p2->expr, NULL);
		} else if ((o7_case_expr == 113)) {
			Expression(&(*gen), gen_tag, e1, NULL);
			Str(&(*gen), gen_tag, " /= 1 << ", 10);
			Expression(&(*gen), gen_tag, p2->expr, NULL);
		} else assert(0); 
	}
}

static void Expression_Call(struct GeneratorC_Generator *gen, int *gen_tag, Ast_ExprCall call, int *call_tag);
static void Call_Expression_ActualParam(struct GeneratorC_Generator *gen, int *gen_tag, Ast_Parameter *p, int *p_tag, struct Ast_FormalParam_s **fp, int *fp_tag) {
	struct Ast_RType *t;
	int i;
	int dist;

	t = (*fp)->_._.type;
	dist = (*p)->distance;
	if (((*fp)->isVar && !(o7c_is(NULL, t, Ast_RArray_tag))) || (o7c_is(NULL, t, Ast_Record_s_tag)) || (t->_._.id == Ast_IdPointer_cnst) && (dist > 0)) {
		Str(&(*gen), gen_tag, "&", 2);
	}
	(*gen).opt->lastSelectorDereference = false;
	Expression(&(*gen), gen_tag, (*p)->expr, NULL);
	if (dist > 0) {
		if (t->_._.id == Ast_IdPointer_cnst) {
			dist--;
			Str(&(*gen), gen_tag, "->_", 4);
		}
		while (dist > 0) {
			dist--;
			Str(&(*gen), gen_tag, "._", 3);
		}
	}
	t = (*p)->expr->type;
	i = 0;
	if (( (1u << t->_._.id) & ((1 << Ast_IdRecord_cnst) | (1 << Ast_IdPointer_cnst)))) {
		if ((o7c_is(NULL, (*p)->expr, Ast_ExprNil_s_tag)) || (t->_._.id == Ast_IdPointer_cnst) || (*gen).opt->lastSelectorDereference) {
			Str(&(*gen), gen_tag, ", NULL", 7);
		} else {
			Str(&(*gen), gen_tag, ", ", 3);
			if ((o7c_is(NULL, (&O7C_GUARD(Ast_Designator_s, (*p)->expr, NULL))->decl, Ast_FormalParam_s_tag)) && ((&O7C_GUARD(Ast_Designator_s, (*p)->expr, NULL))->sel == NULL)) {
				Name(&(*gen), gen_tag, (&O7C_GUARD(Ast_Designator_s, (*p)->expr, NULL))->decl, NULL);
			} else {
				GlobalName(&(*gen), gen_tag, &t->_, NULL);
			}
			Str(&(*gen), gen_tag, "_tag", 5);
		}
	} else if ((*fp)->_._.type->_._.id != Ast_IdChar_cnst) {
		while ((t->_._.id == Ast_IdArray_cnst)) {
			Str(&(*gen), gen_tag, ", ", 3);
			if ((&O7C_GUARD(Ast_RArray, t, NULL))->count != NULL) {
				Expression(&(*gen), gen_tag, (&O7C_GUARD(Ast_RArray, t, NULL))->count, NULL);
			} else {
				Name(&(*gen), gen_tag, (&O7C_GUARD(Ast_Designator_s, (*p)->expr, NULL))->decl, NULL);
				Str(&(*gen), gen_tag, "_len", 5);
				Int(&(*gen), gen_tag, i);
			}
			i++;
			t = t->_.type;
		}
	}
	(*p) = (*p)->next;
	(*fp) = (&O7C_GUARD(Ast_FormalParam_s, (*fp)->_._.next, NULL));
}

static void Expression_Call(struct GeneratorC_Generator *gen, int *gen_tag, Ast_ExprCall call, int *call_tag) {
	Ast_Parameter p;
	struct Ast_FormalParam_s *fp;

	if (o7c_is(NULL, call->designator->decl, Ast_PredefinedProcedure_s_tag)) {
		Expression_Predefined(&(*gen), gen_tag, call, NULL);
	} else {
		Designator(&(*gen), gen_tag, call->designator, NULL);
		Str(&(*gen), gen_tag, "(", 2);
		p = call->params;
		if (false && (o7c_is(NULL, call->designator->decl, Ast_RProcedure_tag))) {
			fp = (&O7C_GUARD(Ast_RProcedure, call->designator->decl, NULL))->_.header->params;
		} else {
			fp = (&O7C_GUARD(Ast_ProcType_s, call->designator->_._.type, NULL))->params;
		}
		if (p != NULL) {
			Call_Expression_ActualParam(&(*gen), gen_tag, &p, NULL, &fp, NULL);
			while (p != NULL) {
				Str(&(*gen), gen_tag, ", ", 3);
				Call_Expression_ActualParam(&(*gen), gen_tag, &p, NULL, &fp, NULL);
			}
		}
		Str(&(*gen), gen_tag, ")", 2);
	}
}

static void Expression_Relation(struct GeneratorC_Generator *gen, int *gen_tag, Ast_ExprRelation rel, int *rel_tag);
static void Relation_Expression_Expr(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RExpression *e, int *e_tag, int dist) {
	if ((dist > 0) && (e->type->_._.id == Ast_IdPointer_cnst)) {
		Str(&(*gen), gen_tag, "&", 2);
	}
	Expression(&(*gen), gen_tag, e, NULL);
	if (dist > 0) {
		if (e->type->_._.id == Ast_IdPointer_cnst) {
			dist--;
			Str(&(*gen), gen_tag, "->_", 4);
		}
		while (dist > 0) {
			dist--;
			Str(&(*gen), gen_tag, "._", 3);
		}
	}
}

static void Relation_Expression_Simple(struct GeneratorC_Generator *gen, int *gen_tag, Ast_ExprRelation rel, int *rel_tag, char unsigned str[/*len0*/], int str_len0) {
	if ((rel->exprs[0]->type->_._.id == Ast_IdArray_cnst) && ((rel->exprs[0]->value_ == NULL) || !(&O7C_GUARD(Ast_ExprString_s, rel->exprs[0]->value_, NULL))->asChar)) {
		Str(&(*gen), gen_tag, "strcmp(", 8);
		Relation_Expression_Expr(&(*gen), gen_tag, rel->exprs[0], NULL,  - rel->distance);
		Str(&(*gen), gen_tag, ", ", 3);
		Relation_Expression_Expr(&(*gen), gen_tag, rel->exprs[1], NULL, rel->distance);
		Str(&(*gen), gen_tag, ")", 2);
		Str(&(*gen), gen_tag, str, str_len0);
		Str(&(*gen), gen_tag, "0", 2);
	} else {
		Relation_Expression_Expr(&(*gen), gen_tag, rel->exprs[0], NULL,  - rel->distance);
		Str(&(*gen), gen_tag, str, str_len0);
		Relation_Expression_Expr(&(*gen), gen_tag, rel->exprs[1], NULL, rel->distance);
	}
}

static void Expression_Relation(struct GeneratorC_Generator *gen, int *gen_tag, Ast_ExprRelation rel, int *rel_tag) {
	{ int o7_case_expr = rel->relation;
		if ((o7_case_expr == 21)) {
			Relation_Expression_Simple(&(*gen), gen_tag, rel, NULL, " == ", 5);
		} else if ((o7_case_expr == 22)) {
			Relation_Expression_Simple(&(*gen), gen_tag, rel, NULL, " != ", 5);
		} else if ((o7_case_expr == 23)) {
			Relation_Expression_Simple(&(*gen), gen_tag, rel, NULL, " < ", 4);
		} else if ((o7_case_expr == 24)) {
			Relation_Expression_Simple(&(*gen), gen_tag, rel, NULL, " <= ", 5);
		} else if ((o7_case_expr == 25)) {
			Relation_Expression_Simple(&(*gen), gen_tag, rel, NULL, " > ", 4);
		} else if ((o7_case_expr == 26)) {
			Relation_Expression_Simple(&(*gen), gen_tag, rel, NULL, " >= ", 5);
		} else if ((o7_case_expr == 27)) {
			Str(&(*gen), gen_tag, "(", 2);
			Str(&(*gen), gen_tag, " (1u << ", 9);
			Factor(&(*gen), gen_tag, rel->exprs[0], NULL);
			Str(&(*gen), gen_tag, ") & ", 5);
			Factor(&(*gen), gen_tag, rel->exprs[1], NULL);
			Str(&(*gen), gen_tag, ")", 2);
		} else assert(0); 
	}
}

static void Expression_Sum(struct GeneratorC_Generator *gen, int *gen_tag, Ast_ExprSum sum, int *sum_tag) {
	bool first;

	first = true;
	do {
		if (sum->add == Scanner_Minus_cnst) {
			if (sum->_.type->_._.id != Ast_IdSet_cnst) {
				Str(&(*gen), gen_tag, " - ", 4);
			} else if (first) {
				Str(&(*gen), gen_tag, " ~", 3);
			} else {
				Str(&(*gen), gen_tag, " & ~", 5);
			}
		} else if (sum->add == Scanner_Plus_cnst) {
			if (sum->_.type->_._.id == Ast_IdSet_cnst) {
				Str(&(*gen), gen_tag, " | ", 4);
			} else {
				Str(&(*gen), gen_tag, " + ", 4);
			}
		} else if (sum->add == Scanner_Or_cnst) {
			Str(&(*gen), gen_tag, " || ", 5);
		}
		Expression(&(*gen), gen_tag, sum->term, NULL);
		sum = sum->next;
		first = false;
	} while (!(sum == NULL));
}

static void Expression_Term(struct GeneratorC_Generator *gen, int *gen_tag, Ast_ExprTerm term, int *term_tag) {
	Expression(&(*gen), gen_tag, &term->factor->_, NULL);
	{ int o7_case_expr = term->mult;
		if ((o7_case_expr == 150)) {
			if (term->_.type->_._.id == Ast_IdSet_cnst) {
				Str(&(*gen), gen_tag, " & ", 4);
			} else {
				Str(&(*gen), gen_tag, " * ", 4);
			}
		} else if ((o7_case_expr == 151) || (o7_case_expr == 153)) {
			if (term->_.type->_._.id == Ast_IdSet_cnst) {
				Str(&(*gen), gen_tag, " ^ ", 4);
			} else {
				Str(&(*gen), gen_tag, " / ", 4);
			}
		} else if ((o7_case_expr == 152)) {
			Str(&(*gen), gen_tag, " && ", 5);
		} else if ((o7_case_expr == 154)) {
			Str(&(*gen), gen_tag, " % ", 4);
		} else assert(0); 
	}
	Expression(&(*gen), gen_tag, term->expr, NULL);
}

static void Expression_Boolean(struct GeneratorC_Generator *gen, int *gen_tag, Ast_ExprBoolean e, int *e_tag) {
	if ((*gen).opt->std == GeneratorC_IsoC90_cnst) {
		if (e->bool_) {
			Str(&(*gen), gen_tag, "(0 < 1)", 8);
		} else {
			Str(&(*gen), gen_tag, "(0 > 1)", 8);
		}
	} else {
		if (e->bool_) {
			Str(&(*gen), gen_tag, "true", 5);
		} else {
			Str(&(*gen), gen_tag, "false", 6);
		}
	}
}

static char unsigned Expression_ToHex(int d) {
	assert((d >= 0) && (d < 16));
	if (d < 10) {
		d += (int)(char unsigned)'0';
	} else {
		d += (int)(char unsigned)'A' - 10;
	}
	return (char unsigned)d;
}

static void Expression_CString(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_ExprString_s *e, int *e_tag) {
	char unsigned s1[7];
	char unsigned s2[4];
	char unsigned ch;
	struct StringStore_String w;

	w = e->string;
	if (e->asChar) {
		ch = (char unsigned)e->_.int_;
		if (ch == (char unsigned)'\'') {
			Str(&(*gen), gen_tag, "(char unsigned)'\\''", 20);
		} else if (ch == (char unsigned)'\\') {
			Str(&(*gen), gen_tag, "(char unsigned)'\\\\'", 20);
		} else if ((ch >= (char unsigned)' ') && (ch <= (char unsigned)127)) {
			Str(&(*gen), gen_tag, "(char unsigned)", 16);
			s2[0] = (char unsigned)'\'';
			s2[1] = ch;
			s2[2] = (char unsigned)'\'';
			s2[3] = 0x00u;
			Str(&(*gen), gen_tag, s2, 4);
		} else {
			Str(&(*gen), gen_tag, "0x", 3);
			s2[0] = Expression_ToHex(e->_.int_ / 16);
			s2[1] = Expression_ToHex(e->_.int_ % 16);
			s2[2] = (char unsigned)'u';
			s2[3] = 0x00u;
			Str(&(*gen), gen_tag, s2, 4);
		}
	} else {
		if (w.block->s[w.ofs] == (char unsigned)'"') {
			ScreeningString(&(*gen), gen_tag, &w, StringStore_String_tag);
		} else {
			s1[0] = (char unsigned)'"';
			s1[1] = (char unsigned)'\\';
			s1[2] = (char unsigned)'x';
			s1[3] = Expression_ToHex(e->_.int_ / 16);
			s1[4] = Expression_ToHex(e->_.int_ % 16);
			s1[5] = (char unsigned)'"';
			s1[6] = 0x00u;
			Str(&(*gen), gen_tag, s1, 7);
		}
	}
}

static void Expression_ExprInt(struct GeneratorC_Generator *gen, int *gen_tag, int int_) {
	if (int_ >= 0) {
		Int(&(*gen), gen_tag, int_);
	} else {
		Str(&(*gen), gen_tag, "(-", 3);
		Int(&(*gen), gen_tag,  - int_);
		Str(&(*gen), gen_tag, ")", 2);
	}
}

static void Expression_Set(struct GeneratorC_Generator *gen, int *gen_tag, Ast_ExprSet set, int *set_tag);
static void Set_Expression_Item(struct GeneratorC_Generator *gen, int *gen_tag, Ast_ExprSet set, int *set_tag) {
	if (set->exprs[0] == NULL) {
		Str(&(*gen), gen_tag, "0", 2);
	} else {
		if (set->exprs[1] == NULL) {
			Str(&(*gen), gen_tag, "(1 << ", 7);
			Factor(&(*gen), gen_tag, set->exprs[0], NULL);
		} else {
			Str(&(*gen), gen_tag, "O7C_SET(", 9);
			Expression(&(*gen), gen_tag, set->exprs[0], NULL);
			Str(&(*gen), gen_tag, ", ", 3);
			Expression(&(*gen), gen_tag, set->exprs[1], NULL);
		}
		Str(&(*gen), gen_tag, ")", 2);
	}
}

static void Expression_Set(struct GeneratorC_Generator *gen, int *gen_tag, Ast_ExprSet set, int *set_tag) {
	if (set->next == NULL) {
		Set_Expression_Item(&(*gen), gen_tag, set, NULL);
	} else {
		Str(&(*gen), gen_tag, "(", 2);
		Set_Expression_Item(&(*gen), gen_tag, set, NULL);
		do {
			Str(&(*gen), gen_tag, " | ", 4);
			set = set->next;
			Set_Expression_Item(&(*gen), gen_tag, set, NULL);
		} while (!(set->next == NULL));
		Str(&(*gen), gen_tag, ")", 2);
	}
}

static void Expression_IsExtension(struct GeneratorC_Generator *gen, int *gen_tag, Ast_ExprIsExtension is, int *is_tag) {
	struct Ast_RDeclaration *decl;
	struct Ast_RType *extType;
	bool ret;

	decl = is->designator->decl;
	extType = is->extType;
	if (is->designator->_._.type->_._.id == Ast_IdPointer_cnst) {
		extType = extType->_.type;
		ret = CheckStructName(&(*gen), gen_tag, (&O7C_GUARD(Ast_Record_s, extType, NULL)), NULL);
		assert(ret);
		Str(&(*gen), gen_tag, "o7c_is(NULL, ", 14);
		Expression(&(*gen), gen_tag, &is->designator->_._, NULL);
		Str(&(*gen), gen_tag, ", ", 3);
	} else {
		Str(&(*gen), gen_tag, "o7c_is(", 8);
		GlobalName(&(*gen), gen_tag, decl, NULL);
		Str(&(*gen), gen_tag, "_tag, ", 7);
		GlobalName(&(*gen), gen_tag, decl, NULL);
		Str(&(*gen), gen_tag, ", ", 3);
	}
	GlobalName(&(*gen), gen_tag, &extType->_, NULL);
	Str(&(*gen), gen_tag, "_tag)", 6);
}

static void Expression(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RExpression *expr, int *expr_tag) {
	{ int o7_case_expr = expr->_.id;
		if ((o7_case_expr == 0)) {
			Expression_ExprInt(&(*gen), gen_tag, (&O7C_GUARD(Ast_RExprInteger, expr, NULL))->int_);
		} else if ((o7_case_expr == 1)) {
			Expression_Boolean(&(*gen), gen_tag, (&O7C_GUARD(Ast_ExprBoolean_s, expr, NULL)), NULL);
		} else if ((o7_case_expr == 4)) {
			if ((&O7C_GUARD(Ast_ExprReal_s, expr, NULL))->str.block != NULL) {
				String(&(*gen), gen_tag, &(&O7C_GUARD(Ast_ExprReal_s, expr, NULL))->str, StringStore_String_tag);
			} else {
				Real(&(*gen), gen_tag, (&O7C_GUARD(Ast_ExprReal_s, expr, NULL))->real);
			}
		} else if ((o7_case_expr == 12)) {
			Expression_CString(&(*gen), gen_tag, (&O7C_GUARD(Ast_ExprString_s, expr, NULL)), NULL);
		} else if ((o7_case_expr == 5)) {
			Expression_Set(&(*gen), gen_tag, (&O7C_GUARD(Ast_ExprSet_s, expr, NULL)), NULL);
		} else if ((o7_case_expr == 25)) {
			Expression_Call(&(*gen), gen_tag, (&O7C_GUARD(Ast_ExprCall_s, expr, NULL)), NULL);
		} else if ((o7_case_expr == 20)) {
			if ((expr->value_ != NULL) && (expr->value_->_._.id == Ast_IdString_cnst)) {
				Expression_CString(&(*gen), gen_tag, (&O7C_GUARD(Ast_ExprString_s, expr->value_, NULL)), NULL);
			} else {
				Designator(&(*gen), gen_tag, (&O7C_GUARD(Ast_Designator_s, expr, NULL)), NULL);
			}
		} else if ((o7_case_expr == 21)) {
			Expression_Relation(&(*gen), gen_tag, (&O7C_GUARD(Ast_ExprRelation_s, expr, NULL)), NULL);
		} else if ((o7_case_expr == 22)) {
			Expression_Sum(&(*gen), gen_tag, (&O7C_GUARD(Ast_ExprSum_s, expr, NULL)), NULL);
		} else if ((o7_case_expr == 23)) {
			Expression_Term(&(*gen), gen_tag, (&O7C_GUARD(Ast_ExprTerm_s, expr, NULL)), NULL);
		} else if ((o7_case_expr == 24)) {
			if (expr->type->_._.id == Ast_IdSet_cnst) {
				Str(&(*gen), gen_tag, "~", 2);
			} else {
				Str(&(*gen), gen_tag, "!", 2);
			}
			Expression(&(*gen), gen_tag, (&O7C_GUARD(Ast_ExprNegate_s, expr, NULL))->expr, NULL);
		} else if ((o7_case_expr == 26)) {
			Str(&(*gen), gen_tag, "(", 2);
			Expression(&(*gen), gen_tag, (&O7C_GUARD(Ast_ExprBraces_s, expr, NULL))->expr, NULL);
			Str(&(*gen), gen_tag, ")", 2);
		} else if ((o7_case_expr == 6)) {
			Str(&(*gen), gen_tag, "NULL", 5);
		} else if ((o7_case_expr == 27)) {
			Expression_IsExtension(&(*gen), gen_tag, (&O7C_GUARD(Ast_ExprIsExtension_s, expr, NULL)), NULL);
		} else assert(0); 
	}
}

static void Invert(struct GeneratorC_Generator *gen, int *gen_tag) {
	(&O7C_GUARD(MemoryOut, (*gen).out, NULL))->invert = !(&O7C_GUARD(MemoryOut, (*gen).out, NULL))->invert;
}

static void ProcHead(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_ProcType_s *proc, int *proc_tag);
static void ProcHead_Parameters(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_ProcType_s *proc, int *proc_tag);
static void Parameters_ProcHead_Par(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_FormalParam_s *fp, int *fp_tag) {
	struct Ast_RType *t;
	int i;

	declarator(&(*gen), gen_tag, &fp->_._, NULL, false, false, false);
	t = fp->_._.type;
	i = 0;
	if (( (1u << t->_._.id) & ((1 << Ast_IdRecord_cnst) | (1 << Ast_IdPointer_cnst)))) {
		Str(&(*gen), gen_tag, ", int *", 8);
		Name(&(*gen), gen_tag, &fp->_._, NULL);
		Str(&(*gen), gen_tag, "_tag", 5);
	} else {
		while ((t->_._.id == Ast_IdArray_cnst) && ((&O7C_GUARD(Ast_RArray, t, NULL))->count == NULL)) {
			Str(&(*gen), gen_tag, ", int ", 7);
			Name(&(*gen), gen_tag, &fp->_._, NULL);
			Str(&(*gen), gen_tag, "_len", 5);
			Int(&(*gen), gen_tag, i);
			i++;
			t = t->_.type;
		}
	}
}

static void ProcHead_Parameters(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_ProcType_s *proc, int *proc_tag) {
	struct Ast_RDeclaration *p;

	if (proc->params == NULL) {
		Str(&(*gen), gen_tag, "(void)", 7);
	} else {
		Str(&(*gen), gen_tag, "(", 2);
		p = (&(proc->params)->_._);
		while (p != &proc->end->_._) {
			Parameters_ProcHead_Par(&(*gen), gen_tag, (&O7C_GUARD(Ast_FormalParam_s, p, NULL)), NULL);
			Str(&(*gen), gen_tag, ", ", 3);
			p = p->next;
		}
		Parameters_ProcHead_Par(&(*gen), gen_tag, (&O7C_GUARD(Ast_FormalParam_s, p, NULL)), NULL);
		Str(&(*gen), gen_tag, ")", 2);
	}
}

static void ProcHead(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_ProcType_s *proc, int *proc_tag) {
	ProcHead_Parameters(&(*gen), gen_tag, proc, NULL);
	Invert(&(*gen), gen_tag);
	type(&(*gen), gen_tag, proc->_._._.type, NULL, false, false);
	MemWriteInvert(&(*(&O7C_GUARD(MemoryOut, (*gen).out, NULL))), NULL);
}

static void Declarator(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RDeclaration *decl, int *decl_tag, bool typeDecl, bool sameType, bool global) {
	struct GeneratorC_Generator g;
	struct MemoryOut *mo;

	mo = o7c_new(sizeof(*mo), MemoryOut_tag);
	MemoryOutInit(&(*mo), MemoryOut_tag);
	V_Init(&g._, GeneratorC_Generator_tag);
	g.out = (&(mo)->_);
	g.len = 0;
	g.module = (*gen).module;
	g.tabs = (*gen).tabs;
	g.interface_ = (*gen).interface_;
	g.opt = (*gen).opt;
	if ((o7c_is(NULL, decl, Ast_FormalParam_s_tag)) && (((&O7C_GUARD(Ast_FormalParam_s, decl, NULL))->isVar && !(o7c_is(NULL, decl->type, Ast_RArray_tag))) || (o7c_is(NULL, decl->type, Ast_Record_s_tag)))) {
		Str(&g, GeneratorC_Generator_tag, "*", 2);
	} else if (o7c_is(NULL, decl, Ast_Const_s_tag)) {
		Str(&g, GeneratorC_Generator_tag, "const ", 7);
	}
	if (global) {
		GlobalName(&g, GeneratorC_Generator_tag, decl, NULL);
	} else {
		Name(&g, GeneratorC_Generator_tag, decl, NULL);
	}
	if (o7c_is(NULL, decl, Ast_RProcedure_tag)) {
		ProcHead(&g, GeneratorC_Generator_tag, (&O7C_GUARD(Ast_RProcedure, decl, NULL))->_.header, NULL);
	} else {
		mo->invert = !mo->invert;
		if (o7c_is(NULL, decl, Ast_RType_tag)) {
			type(&g, GeneratorC_Generator_tag, (&O7C_GUARD(Ast_RType, decl, NULL)), NULL, typeDecl, false);
		} else {
			type(&g, GeneratorC_Generator_tag, decl->type, NULL, false, sameType);
		}
	}
	MemWriteDirect(&(*gen), gen_tag, &(*mo), MemoryOut_tag);
}

static void Type(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RType *type, int *type_tag, bool typeDecl, bool sameType);
static void Type_Simple(struct GeneratorC_Generator *gen, int *gen_tag, char unsigned str[/*len0*/], int str_len0) {
	Str(&(*gen), gen_tag, str, str_len0);
	MemWriteInvert(&(*(&O7C_GUARD(MemoryOut, (*gen).out, NULL))), NULL);
}

static void Type_Record(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_Record_s *rec, int *rec_tag) {
	struct Ast_RDeclaration *v;

	rec->_._._.module = (*gen).module;
	Str(&(*gen), gen_tag, "struct ", 8);
	if (CheckStructName(&(*gen), gen_tag, rec, NULL)) {
		GlobalName(&(*gen), gen_tag, &rec->_._._, NULL);
	}
	v = (&(rec->vars->vars)->_);
	if ((v == NULL) && (rec->base == NULL) && (*gen).opt->gnu) {
		Str(&(*gen), gen_tag, " { int nothing; } ", 19);
	} else {
		StrLn(&(*gen), gen_tag, " {", 3);
		Tabs(&(*gen), gen_tag,  + 1);
		if (rec->base != NULL) {
			Str(&(*gen), gen_tag, "struct ", 8);
			GlobalName(&(*gen), gen_tag, &rec->base->_._._, NULL);
			StrLn(&(*gen), gen_tag, " _;", 4);
		}
		while (v != NULL) {
			Tabs(&(*gen), gen_tag, 0);
			Declarator(&(*gen), gen_tag, v, NULL, false, false, false);
			StrLn(&(*gen), gen_tag, ";", 2);
			v = v->next;
		}
		Tabs(&(*gen), gen_tag,  - 1);
		Str(&(*gen), gen_tag, "} ", 3);
	}
	MemWriteInvert(&(*(&O7C_GUARD(MemoryOut, (*gen).out, NULL))), NULL);
}

static void Type_Array(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RArray *arr, int *arr_tag, bool sameType) {
	struct Ast_RType *t;
	int i;

	t = arr->_._._.type;
	MemWriteInvert(&(*(&O7C_GUARD(MemoryOut, (*gen).out, NULL))), NULL);
	if (arr->count == NULL) {
		Str(&(*gen), gen_tag, "[/*len0", 8);
		i = 0;
		while (t->_._.id == Ast_IdArray_cnst) {
			i++;
			Str(&(*gen), gen_tag, ", len", 6);
			Int(&(*gen), gen_tag, i);
			t = t->_.type;
		}
		Str(&(*gen), gen_tag, "*/]", 4);
	} else {
		Str(&(*gen), gen_tag, "[", 2);
		Expression(&(*gen), gen_tag, arr->count, NULL);
		Str(&(*gen), gen_tag, "]", 2);
	}
	Invert(&(*gen), gen_tag);
	Type(&(*gen), gen_tag, t, NULL, false, sameType);
}

static void Type(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RType *type, int *type_tag, bool typeDecl, bool sameType) {
	if (type == NULL) {
		Str(&(*gen), gen_tag, "void ", 6);
		MemWriteInvert(&(*(&O7C_GUARD(MemoryOut, (*gen).out, NULL))), NULL);
	} else {
		if (!typeDecl && (type->_.name.block != NULL)) {
			if (!sameType) {
				if ((o7c_is(NULL, type, Ast_RPointer_tag)) && (type->_.type->_.name.block != NULL)) {
					Str(&(*gen), gen_tag, "struct ", 8);
					GlobalName(&(*gen), gen_tag, &type->_.type->_, NULL);
					Str(&(*gen), gen_tag, " *", 3);
				} else {
					if (o7c_is(NULL, type, Ast_Record_s_tag)) {
						Str(&(*gen), gen_tag, "struct ", 8);
						if (CheckStructName(&(*gen), gen_tag, (&O7C_GUARD(Ast_Record_s, type, NULL)), NULL)) {
							GlobalName(&(*gen), gen_tag, &type->_, NULL);
							Str(&(*gen), gen_tag, " ", 2);
						}
					} else {
						GlobalName(&(*gen), gen_tag, &type->_, NULL);
						Str(&(*gen), gen_tag, " ", 2);
					}
				}
				if (o7c_is(NULL, (*gen).out, MemoryOut_tag)) {
					MemWriteInvert(&(*(&O7C_GUARD(MemoryOut, (*gen).out, NULL))), NULL);
				}
			}
		} else if (!sameType || (( (1u << type->_._.id) & ((1 << Ast_IdPointer_cnst) | (1 << Ast_IdArray_cnst) | (1 << Ast_IdProcType_cnst))))) {
			{ int o7_case_expr = type->_._.id;
				if ((o7_case_expr == 0) || (o7_case_expr == 5)) {
					Type_Simple(&(*gen), gen_tag, "int ", 5);
				} else if ((o7_case_expr == 1)) {
					if ((*gen).opt->std >= GeneratorC_IsoC99_cnst) {
						Type_Simple(&(*gen), gen_tag, "bool ", 6);
					} else {
						Type_Simple(&(*gen), gen_tag, "int/* bool */ ", 15);
					}
				} else if ((o7_case_expr == 2)) {
					Type_Simple(&(*gen), gen_tag, "char unsigned ", 15);
				} else if ((o7_case_expr == 3)) {
					Type_Simple(&(*gen), gen_tag, "char unsigned ", 15);
				} else if ((o7_case_expr == 4)) {
					Type_Simple(&(*gen), gen_tag, "double ", 8);
				} else if ((o7_case_expr == 6)) {
					Str(&(*gen), gen_tag, "*", 2);
					MemWriteInvert(&(*(&O7C_GUARD(MemoryOut, (*gen).out, NULL))), NULL);
					Invert(&(*gen), gen_tag);
					Type(&(*gen), gen_tag, type->_.type, NULL, false, sameType);
				} else if ((o7_case_expr == 7)) {
					Type_Array(&(*gen), gen_tag, (&O7C_GUARD(Ast_RArray, type, NULL)), NULL, sameType);
				} else if ((o7_case_expr == 8)) {
					Type_Record(&(*gen), gen_tag, (&O7C_GUARD(Ast_Record_s, type, NULL)), NULL);
				} else if ((o7_case_expr == 10)) {
					Str(&(*gen), gen_tag, "(*", 3);
					MemWriteInvert(&(*(&O7C_GUARD(MemoryOut, (*gen).out, NULL))), NULL);
					Str(&(*gen), gen_tag, ")", 2);
					ProcHead(&(*gen), gen_tag, (&O7C_GUARD(Ast_ProcType_s, type, NULL)), NULL);
				} else assert(0); 
			}
		}
		if (o7c_is(NULL, (*gen).out, MemoryOut_tag)) {
			MemWriteInvert(&(*(&O7C_GUARD(MemoryOut, (*gen).out, NULL))), NULL);
		}
	}
}

static void RecordTag(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_Record_s *rec, int *rec_tag) {
	if (!rec->_._._.mark) {
		Str(&(*gen), gen_tag, "static int ", 12);
	} else if ((*gen).interface_) {
		Str(&(*gen), gen_tag, "extern int ", 12);
	} else {
		Str(&(*gen), gen_tag, "int ", 5);
	}
	GlobalName(&(*gen), gen_tag, &rec->_._._, NULL);
	Str(&(*gen), gen_tag, "_tag[", 6);
	Int(&(*gen), gen_tag, TranslatorLimits_MaxRecordExt_cnst);
	StrLn(&(*gen), gen_tag, "];", 3);
	Ln(&(*gen), gen_tag);
}

static void TypeDecl(struct MOut *out, int *out_tag, struct Ast_RType *type, int *type_tag);
static void TypeDecl_Typedef(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RType *type, int *type_tag) {
	Tabs(&(*gen), gen_tag, 0);
	Str(&(*gen), gen_tag, "typedef ", 9);
	Declarator(&(*gen), gen_tag, &type->_, NULL, true, false, true);
	StrLn(&(*gen), gen_tag, ";", 2);
}

static void TypeDecl_LinkRecord(struct GeneratorC_Options_s *opt, int *opt_tag, struct Ast_Record_s *rec, int *rec_tag) {
	if (opt->records == NULL) {
		opt->records = (&(rec)->_._._._._);
	} else {
		(&O7C_GUARD(Ast_Record_s, opt->recordLast, NULL))->_._._._.ext = (&(rec)->_._._._._);
	}
	opt->recordLast = (&(rec)->_._._._._);
	assert(rec->_._._._.ext == NULL);
}

static void TypeDecl(struct MOut *out, int *out_tag, struct Ast_RType *type, int *type_tag) {
	TypeDecl_Typedef(&(*out).g[(int)type->_.mark], GeneratorC_Generator_tag, type, NULL);
	if ((type->_._.id == Ast_IdRecord_cnst) || (type->_._.id == Ast_IdPointer_cnst) && (type->_.type->_.next == NULL)) {
		if (type->_._.id == Ast_IdPointer_cnst) {
			type = type->_.type;
		}
		type->_.mark = type->_.mark || ((&O7C_GUARD(Ast_Record_s, type, NULL))->pointer != NULL) && ((&O7C_GUARD(Ast_Record_s, type, NULL))->pointer->_._._.mark);
		RecordTag(&(*out).g[(int)type->_.mark], GeneratorC_Generator_tag, (&O7C_GUARD(Ast_Record_s, type, NULL)), NULL);
		if (type->_.mark) {
			RecordTag(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, (&O7C_GUARD(Ast_Record_s, type, NULL)), NULL);
		}
		TypeDecl_LinkRecord((*out).opt, NULL, (&O7C_GUARD(Ast_Record_s, type, NULL)), NULL);
	}
}

static void Mark(struct GeneratorC_Generator *gen, int *gen_tag, bool mark) {
	if ((*gen).localDeep == 0) {
		if (mark) {
			Str(&(*gen), gen_tag, "extern ", 8);
		} else {
			Str(&(*gen), gen_tag, "static ", 8);
		}
	}
}

static void Const(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_Const_s *const_, int *const__tag) {
	Str(&(*gen), gen_tag, "#define ", 9);
	GlobalName(&(*gen), gen_tag, &const_->_, NULL);
	Str(&(*gen), gen_tag, " ", 2);
	if (const_->_.mark && (const_->expr != NULL)) {
		Factor(&(*gen), gen_tag, &const_->expr->value_->_, NULL);
	} else {
		Factor(&(*gen), gen_tag, const_->expr, NULL);
	}
	Ln(&(*gen), gen_tag);
}

static void Var(struct MOut *out, int *out_tag, struct Ast_RDeclaration *prev, int *prev_tag, struct Ast_RDeclaration *var_, int *var__tag, bool last) {
	bool same;

	same = (prev != NULL) && (prev->mark == var_->mark) && (prev->type == var_->type);
	if (!same) {
		if (prev != NULL) {
			StrLn(&(*out).g[(int)var_->mark], GeneratorC_Generator_tag, ";", 2);
		}
		Tabs(&(*out).g[(int)var_->mark], GeneratorC_Generator_tag, 0);
		Mark(&(*out).g[(int)var_->mark], GeneratorC_Generator_tag, var_->mark);
	} else {
		Str(&(*out).g[(int)var_->mark], GeneratorC_Generator_tag, ", ", 3);
	}
	if (var_->mark) {
		Declarator(&(*out).g[Interface_cnst], GeneratorC_Generator_tag, var_, NULL, false, same, true);
		if (last) {
			StrLn(&(*out).g[Interface_cnst], GeneratorC_Generator_tag, ";", 2);
		}
		if (!same) {
			if (prev != NULL) {
				StrLn(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, ";", 2);
			}
			Tabs(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, 0);
		} else {
			Str(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, ", ", 3);
		}
	}
	Declarator(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, var_, NULL, false, same, true);
	if (last) {
		StrLn(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, ";", 2);
	}
}

static void Statement(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RStatement *st, int *st_tag);
static void Statement_WhileIf(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RWhileIf *wi, int *wi_tag);
static void WhileIf_Statement_ExprThenStats(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RWhileIf **wi, int *wi_tag) {
	Expression(&(*gen), gen_tag, (*wi)->_.expr, NULL);
	StrLn(&(*gen), gen_tag, ") {", 4);
	(*gen).tabs++;
	statements(&(*gen), gen_tag, (*wi)->stats, NULL);
	(*wi) = (*wi)->elsif;
}

static void WhileIf_Statement_Elsif(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RWhileIf **wi, int *wi_tag) {
	while (((*wi) != NULL) && ((*wi)->_.expr != NULL)) {
		Tabs(&(*gen), gen_tag,  - 1);
		Str(&(*gen), gen_tag, "} else if (", 12);
		WhileIf_Statement_ExprThenStats(&(*gen), gen_tag, &(*wi), NULL);
	}
}

static void Statement_WhileIf(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RWhileIf *wi, int *wi_tag) {
	if (o7c_is(NULL, wi, Ast_If_s_tag)) {
		Str(&(*gen), gen_tag, "if (", 5);
		WhileIf_Statement_ExprThenStats(&(*gen), gen_tag, &wi, NULL);
		WhileIf_Statement_Elsif(&(*gen), gen_tag, &wi, NULL);
		if (wi != NULL) {
			Tabs(&(*gen), gen_tag,  - 1);
			StrLn(&(*gen), gen_tag, "} else {", 9);
			(*gen).tabs++;
			statements(&(*gen), gen_tag, wi->stats, NULL);
		}
		Tabs(&(*gen), gen_tag,  - 1);
		StrLn(&(*gen), gen_tag, "}", 2);
	} else if (wi->elsif == NULL) {
		Str(&(*gen), gen_tag, "while (", 8);
		WhileIf_Statement_ExprThenStats(&(*gen), gen_tag, &wi, NULL);
		Tabs(&(*gen), gen_tag,  - 1);
		StrLn(&(*gen), gen_tag, "}", 2);
	} else {
		Str(&(*gen), gen_tag, "while (1) if (", 15);
		WhileIf_Statement_ExprThenStats(&(*gen), gen_tag, &wi, NULL);
		WhileIf_Statement_Elsif(&(*gen), gen_tag, &wi, NULL);
		Tabs(&(*gen), gen_tag,  - 1);
		StrLn(&(*gen), gen_tag, "} else break;", 14);
	}
}

static void Statement_Repeat(struct GeneratorC_Generator *gen, int *gen_tag, Ast_Repeat st, int *st_tag) {
	StrLn(&(*gen), gen_tag, "do {", 5);
	(*gen).tabs++;
	statements(&(*gen), gen_tag, st->stats, NULL);
	Tabs(&(*gen), gen_tag,  - 1);
	if (st->_.expr->_.id == Ast_IdNegate_cnst) {
		Str(&(*gen), gen_tag, "} while (", 10);
		Expression(&(*gen), gen_tag, (&O7C_GUARD(Ast_ExprNegate_s, st->_.expr, NULL))->expr, NULL);
		StrLn(&(*gen), gen_tag, ");", 3);
	} else {
		Str(&(*gen), gen_tag, "} while (!(", 12);
		Expression(&(*gen), gen_tag, st->_.expr, NULL);
		StrLn(&(*gen), gen_tag, "));", 4);
	}
}

static void Statement_For(struct GeneratorC_Generator *gen, int *gen_tag, Ast_For st, int *st_tag) {
	Str(&(*gen), gen_tag, "for (", 6);
	GlobalName(&(*gen), gen_tag, &st->var_->_, NULL);
	Str(&(*gen), gen_tag, " = ", 4);
	Expression(&(*gen), gen_tag, st->_.expr, NULL);
	Str(&(*gen), gen_tag, "; ", 3);
	GlobalName(&(*gen), gen_tag, &st->var_->_, NULL);
	Str(&(*gen), gen_tag, " <= ", 5);
	Expression(&(*gen), gen_tag, st->to, NULL);
	if (st->by == 1) {
		Str(&(*gen), gen_tag, "; ++", 5);
		GlobalName(&(*gen), gen_tag, &st->var_->_, NULL);
	} else {
		Str(&(*gen), gen_tag, "; ", 3);
		GlobalName(&(*gen), gen_tag, &st->var_->_, NULL);
		Str(&(*gen), gen_tag, " += ", 5);
		Int(&(*gen), gen_tag, st->by);
	}
	StrLn(&(*gen), gen_tag, ") {", 4);
	(*gen).tabs++;
	statements(&(*gen), gen_tag, st->stats, NULL);
	Tabs(&(*gen), gen_tag,  - 1);
	StrLn(&(*gen), gen_tag, "}", 2);
}

static void Statement_Assign(struct GeneratorC_Generator *gen, int *gen_tag, Ast_Assign st, int *st_tag) {
	struct Ast_Record_s *type;
	struct Ast_Record_s *base;

	Designator(&(*gen), gen_tag, st->designator, NULL);
	Str(&(*gen), gen_tag, " = ", 4);
	if ((st->_.expr->type->_._.id == Ast_IdPointer_cnst) && (st->_.expr->type->_.type != st->designator->_._.type->_.type) && !(o7c_is(NULL, st->_.expr, Ast_ExprNil_s_tag))) {
		base = (&O7C_GUARD(Ast_Record_s, st->designator->_._.type->_.type, NULL));
		type = (&O7C_GUARD(Ast_Record_s, st->_.expr->type->_.type, NULL))->base;
		Str(&(*gen), gen_tag, "(&(", 4);
		Expression(&(*gen), gen_tag, st->_.expr, NULL);
		Str(&(*gen), gen_tag, ")->_", 5);
	} else {
		base = NULL;
		Expression(&(*gen), gen_tag, st->_.expr, NULL);
	}
	if ((base != NULL) || (st->_.expr->type->_._.id == Ast_IdRecord_cnst)) {
		if (base == NULL) {
			base = (&O7C_GUARD(Ast_Record_s, st->designator->_._.type, NULL));
			type = (&O7C_GUARD(Ast_Record_s, st->_.expr->type, NULL));
		}
		while (type != base) {
			Str(&(*gen), gen_tag, "._", 3);
			type = type->base;
		}
		Log_StrLn("Assign record", 14);
	}
	if ((st->_.expr->type->_._.id == Ast_IdPointer_cnst) && (st->_.expr->type->_.type != st->designator->_._.type->_.type) && !(o7c_is(NULL, st->_.expr, Ast_ExprNil_s_tag))) {
		StrLn(&(*gen), gen_tag, ");", 3);
	} else {
		StrLn(&(*gen), gen_tag, ";", 2);
	}
}

static void Statement_CaseRange(struct GeneratorC_Generator *gen, int *gen_tag, Ast_CaseLabelRange r, int *r_tag) {
	if (r->right == NULL) {
		Str(&(*gen), gen_tag, "(o7_case_expr == ", 18);
		Int(&(*gen), gen_tag, r->left->value_);
	} else {
		assert(r->left->value_ <= r->right->value_);
		Str(&(*gen), gen_tag, "(", 2);
		Int(&(*gen), gen_tag, r->left->value_);
		Str(&(*gen), gen_tag, " <= o7_case_expr && o7_case_expr <= ", 37);
		Int(&(*gen), gen_tag, r->right->value_);
	}
	Str(&(*gen), gen_tag, ")", 2);
}

static void Statement_CaseElement(struct GeneratorC_Generator *gen, int *gen_tag, Ast_CaseElement elem, int *elem_tag) {
	Ast_CaseLabelRange r;

	Str(&(*gen), gen_tag, "if (", 5);
	r = elem->range;
	assert(r != NULL);
	Statement_CaseRange(&(*gen), gen_tag, r, NULL);
	while (r->next != NULL) {
		r = r->next;
		Str(&(*gen), gen_tag, " || ", 5);
		Statement_CaseRange(&(*gen), gen_tag, r, NULL);
	}
	StrLn(&(*gen), gen_tag, ") {", 4);
	(*gen).tabs++;
	statements(&(*gen), gen_tag, elem->stats, NULL);
	Tabs(&(*gen), gen_tag,  - 1);
	Str(&(*gen), gen_tag, "}", 2);
}

static void Statement_Case(struct GeneratorC_Generator *gen, int *gen_tag, Ast_Case st, int *st_tag) {
	Ast_CaseElement elem;

	Str(&(*gen), gen_tag, "{ int o7_case_expr = ", 22);
	Expression(&(*gen), gen_tag, st->_.expr, NULL);
	StrLn(&(*gen), gen_tag, ";", 2);
	elem = st->elements;
	Tabs(&(*gen), gen_tag,  + 1);
	Statement_CaseElement(&(*gen), gen_tag, elem, NULL);
	elem = elem->next;
	while (elem != NULL) {
		Str(&(*gen), gen_tag, " else ", 7);
		Statement_CaseElement(&(*gen), gen_tag, elem, NULL);
		elem = elem->next;
	}
	StrLn(&(*gen), gen_tag, " else assert(0); ", 18);
	Tabs(&(*gen), gen_tag,  - 1);
	StrLn(&(*gen), gen_tag, "}", 2);
}

static void Statement(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RStatement *st, int *st_tag) {
	Tabs(&(*gen), gen_tag, 0);
	if (o7c_is(NULL, st, Ast_Assign_s_tag)) {
		Statement_Assign(&(*gen), gen_tag, (&O7C_GUARD(Ast_Assign_s, st, NULL)), NULL);
	} else if (o7c_is(NULL, st, Ast_Call_s_tag)) {
		(*gen).expressionSemicolon = true;
		Expression(&(*gen), gen_tag, st->expr, NULL);
		if ((*gen).expressionSemicolon) {
			StrLn(&(*gen), gen_tag, ";", 2);
		} else {
			Ln(&(*gen), gen_tag);
		}
	} else if (o7c_is(NULL, st, Ast_RWhileIf_tag)) {
		Statement_WhileIf(&(*gen), gen_tag, (&O7C_GUARD(Ast_RWhileIf, st, NULL)), NULL);
	} else if (o7c_is(NULL, st, Ast_Repeat_s_tag)) {
		Statement_Repeat(&(*gen), gen_tag, (&O7C_GUARD(Ast_Repeat_s, st, NULL)), NULL);
	} else if (o7c_is(NULL, st, Ast_For_s_tag)) {
		Statement_For(&(*gen), gen_tag, (&O7C_GUARD(Ast_For_s, st, NULL)), NULL);
	} else if (o7c_is(NULL, st, Ast_Case_s_tag)) {
		Statement_Case(&(*gen), gen_tag, (&O7C_GUARD(Ast_Case_s, st, NULL)), NULL);
	} else {
		assert(false);
	}
}

static void Statements(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RStatement *stats, int *stats_tag) {
	while (stats != NULL) {
		Statement(&(*gen), gen_tag, stats, NULL);
		stats = stats->next;
	}
}

static void Procedure(struct MOut *out, int *out_tag, struct Ast_RProcedure *proc, int *proc_tag);
static void Procedure_CloseConsts(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RDeclaration *consts, int *consts_tag) {
	while ((consts != NULL) && (o7c_is(NULL, consts, Ast_Const_s_tag))) {
		Str(&(*gen), gen_tag, "#undef ", 8);
		Name(&(*gen), gen_tag, consts, NULL);
		Ln(&(*gen), gen_tag);
		consts = consts->next;
	}
}

static void Procedure_Implement(struct MOut *out, int *out_tag, struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RProcedure *proc, int *proc_tag) {
	Tabs(&(*gen), gen_tag, 0);
	Mark(&(*gen), gen_tag, proc->_._._.mark);
	Declarator(&(*gen), gen_tag, &proc->_._._, NULL, false, false, true);
	StrLn(&(*gen), gen_tag, " {", 3);
	(*gen).localDeep++;
	(*gen).tabs++;
	(*gen).fixedLen = (*gen).len;
	declarations(&(*out), out_tag, &proc->_._, NULL);
	Statements(&(*gen), gen_tag, proc->_._.stats, NULL);
	if (proc->_.return_ != NULL) {
		Tabs(&(*gen), gen_tag, 0);
		Str(&(*gen), gen_tag, "return ", 8);
		Expression(&(*gen), gen_tag, proc->_.return_, NULL);
		StrLn(&(*gen), gen_tag, ";", 2);
	}
	(*gen).localDeep--;
	Procedure_CloseConsts(&(*gen), gen_tag, proc->_._.start, NULL);
	Tabs(&(*gen), gen_tag,  - 1);
	StrLn(&(*gen), gen_tag, "}", 2);
	Ln(&(*gen), gen_tag);
}

static void Procedure_ProcDecl(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RProcedure *proc, int *proc_tag) {
	Tabs(&(*gen), gen_tag, 0);
	if (proc->_._._.mark) {
		Str(&(*gen), gen_tag, "extern ", 8);
	} else {
		Str(&(*gen), gen_tag, "static ", 8);
	}
	Declarator(&(*gen), gen_tag, &proc->_._._, NULL, false, false, true);
	StrLn(&(*gen), gen_tag, ";", 2);
}

static void Procedure_LocalProcs(struct MOut *out, int *out_tag, struct Ast_RProcedure *proc, int *proc_tag) {
	struct Ast_RDeclaration *p;
	struct Ast_RDeclaration *t;

	t = (&(proc->_._.types)->_);
	while ((t != NULL) && (o7c_is(NULL, t, Ast_RType_tag))) {
		TypeDecl(&(*out), out_tag, (&O7C_GUARD(Ast_RType, t, NULL)), NULL);
		t = t->next;
	}
	p = (&(proc->_._.procedures)->_._._);
	if (p != NULL) {
		if (!proc->_._._.mark && !(*out).opt->procLocal) {
			Procedure_ProcDecl(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, proc, NULL);
		}
		do {
			Procedure(&(*out), out_tag, (&O7C_GUARD(Ast_RProcedure, p, NULL)), NULL);
			p = p->next;
		} while (!(p == NULL));
	}
}

static void Procedure(struct MOut *out, int *out_tag, struct Ast_RProcedure *proc, int *proc_tag) {
	Procedure_LocalProcs(&(*out), out_tag, proc, NULL);
	if (proc->_._._.mark) {
		Procedure_ProcDecl(&(*out).g[Interface_cnst], GeneratorC_Generator_tag, proc, NULL);
	}
	Procedure_Implement(&(*out), out_tag, &(*out).g[Implementation_cnst], GeneratorC_Generator_tag, proc, NULL);
}

static void LnIfWrote(struct MOut *out, int *out_tag);
static void LnIfWrote_Write(struct GeneratorC_Generator *gen, int *gen_tag) {
	if ((*gen).fixedLen != (*gen).len) {
		Ln(&(*gen), gen_tag);
		(*gen).fixedLen = (*gen).len;
	}
}

static void LnIfWrote(struct MOut *out, int *out_tag) {
	LnIfWrote_Write(&(*out).g[Interface_cnst], GeneratorC_Generator_tag);
	LnIfWrote_Write(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag);
}

static void Declarations(struct MOut *out, int *out_tag, struct Ast_RDeclarations *ds, int *ds_tag) {
	struct Ast_RDeclaration *d;
	struct Ast_RDeclaration *prev;

	d = ds->start;
	assert(!(o7c_is(NULL, d, Ast_RModule_tag)));
	while ((d != NULL) && (o7c_is(NULL, d, Ast_Import_s_tag))) {
		Import(&(*out).g[Interface_cnst], GeneratorC_Generator_tag, d, NULL);
		d = d->next;
	}
	LnIfWrote(&(*out), out_tag);
	while ((d != NULL) && (o7c_is(NULL, d, Ast_Const_s_tag))) {
		Const(&(*out).g[d->mark], GeneratorC_Generator_tag, (&O7C_GUARD(Ast_Const_s, d, NULL)), NULL);
		d = d->next;
	}
	LnIfWrote(&(*out), out_tag);
	if (o7c_is(NULL, ds, Ast_RModule_tag)) {
		while ((d != NULL) && (o7c_is(NULL, d, Ast_RType_tag))) {
			TypeDecl(&(*out), out_tag, (&O7C_GUARD(Ast_RType, d, NULL)), NULL);
			d = d->next;
		}
		LnIfWrote(&(*out), out_tag);
	} else {
		d = (&(ds->vars)->_);
	}
	prev = NULL;
	while ((d != NULL) && (o7c_is(NULL, d, Ast_RVar_tag))) {
		Var(&(*out), out_tag, NULL, NULL, d, NULL, true);
		prev = d;
		d = d->next;
	}
	LnIfWrote(&(*out), out_tag);
	if ((*out).opt->procLocal || (o7c_is(NULL, ds, Ast_RModule_tag))) {
		while (d != NULL) {
			Procedure(&(*out), out_tag, (&O7C_GUARD(Ast_RProcedure, d, NULL)), NULL);
			d = d->next;
		}
	}
}

extern struct GeneratorC_Options_s *GeneratorC_DefaultOptions(void) {
	struct GeneratorC_Options_s *o;

	o = o7c_new(sizeof(*o), GeneratorC_Options_s_tag);
	V_Init(&(*o)._, GeneratorC_Options_s_tag);
	if (o != NULL) {
		o->std = GeneratorC_IsoC99_cnst;
		o->gnu = false;
		o->procLocal = false;
		o->main_ = false;
	}
	return o;
}

extern void GeneratorC_Init(struct GeneratorC_Generator *g, int *g_tag, struct VDataStream_Out *out, int *out_tag) {
	V_Init(&(*g)._, g_tag);
	(*g).out = out;
}

static void MarkUsedInMarked(struct Ast_RModule *m, int *m_tag);
static void MarkUsedInMarked_Expression(struct Ast_RExpression *e, int *e_tag) {
	if (e != NULL) {
		if (e->_.id == Ast_IdRelation_cnst) {
			MarkUsedInMarked_Expression((&O7C_GUARD(Ast_ExprRelation_s, e, NULL))->exprs[0], NULL);
			MarkUsedInMarked_Expression((&O7C_GUARD(Ast_ExprRelation_s, e, NULL))->exprs[1], NULL);
		} else if (e->_.id == Ast_IdTerm_cnst) {
			MarkUsedInMarked_Expression(&(&O7C_GUARD(Ast_ExprTerm_s, e, NULL))->factor->_, NULL);
			MarkUsedInMarked_Expression((&O7C_GUARD(Ast_ExprTerm_s, e, NULL))->expr, NULL);
		} else if (e->_.id == Ast_IdSum_cnst) {
			MarkUsedInMarked_Expression((&O7C_GUARD(Ast_ExprSum_s, e, NULL))->term, NULL);
			MarkUsedInMarked_Expression(&(&O7C_GUARD(Ast_ExprSum_s, e, NULL))->next->_, NULL);
		} else if ((e->_.id == Ast_IdDesignator_cnst) && !(&O7C_GUARD(Ast_Designator_s, e, NULL))->decl->mark) {
			(&O7C_GUARD(Ast_Designator_s, e, NULL))->decl->mark = true;
			MarkUsedInMarked_Expression((&O7C_GUARD(Ast_Const_s, (&O7C_GUARD(Ast_Designator_s, e, NULL))->decl, NULL))->expr, NULL);
		}
	}
}

static void MarkUsedInMarked_Consts(struct Ast_Const_s *c, int *c_tag) {
	while (c != NULL) {
		if (c->_.mark) {
			MarkUsedInMarked_Expression(c->expr, NULL);
		}
		if ((c->_.next != NULL) && (o7c_is(NULL, c->_.next, Ast_Const_s_tag))) {
			c = (&O7C_GUARD(Ast_Const_s, c->_.next, NULL));
		} else {
			c = NULL;
		}
	}
}

static void MarkUsedInMarked_Type(struct Ast_RType *t, int *t_tag) {
	struct Ast_RDeclaration *d;

	Log_StrLn("Type !!!!", 10);
	while ((t != NULL) && !t->_.mark) {
		t->_.mark = true;
		if (t->_._.id == Ast_IdArray_cnst) {
			MarkUsedInMarked_Expression((&O7C_GUARD(Ast_RArray, t, NULL))->count, NULL);
			t = t->_.type;
		} else if (( (1u << t->_._.id) & ((1 << Ast_IdRecord_cnst) | (1 << Ast_IdPointer_cnst)))) {
			if (t->_._.id == Ast_IdPointer_cnst) {
				t = t->_.type;
				t->_.mark = true;
				assert(t->_.module != NULL);
			}
			d = (&((&O7C_GUARD(Ast_Record_s, t, NULL))->vars->vars)->_);
			while (d != NULL) {
				MarkUsedInMarked_Type(d->type, NULL);
				if (d->name.block != NULL) {
					Log_StrLn(d->name.block->s, StringStore_BlockSize_cnst + 1);
				}
				d = d->next;
			}
			t = (&((&O7C_GUARD(Ast_Record_s, t, NULL))->base)->_._);
		} else {
			t = NULL;
		}
	}
}

static void MarkUsedInMarked_Types(struct Ast_RDeclaration *t, int *t_tag) {
	while ((t != NULL) && (o7c_is(NULL, t, Ast_RType_tag))) {
		if (t->mark) {
			t->mark = false;
			MarkUsedInMarked_Type((&O7C_GUARD(Ast_RType, t, NULL)), NULL);
		}
		t = t->next;
	}
}

static void MarkUsedInMarked(struct Ast_RModule *m, int *m_tag) {
	struct Ast_RDeclaration *imp;

	imp = (&(m->import_)->_);
	while ((imp != NULL) && (o7c_is(NULL, imp, Ast_Import_s_tag))) {
		MarkUsedInMarked(imp->module, NULL);
		imp = imp->next;
	}
	MarkUsedInMarked_Consts(m->_.consts, NULL);
	MarkUsedInMarked_Types(&m->_.types->_, NULL);
}

static void Generate_Init(struct GeneratorC_Generator *gen, int *gen_tag, struct VDataStream_Out *out, int *out_tag, struct Ast_RModule *module, int *module_tag, struct GeneratorC_Options_s *opt, int *opt_tag) {
	(*gen).out = out;
	(*gen).len = 0;
	(*gen).module = module;
	(*gen).tabs = 0;
	(*gen).localDeep = 0;
	opt->records = NULL;
	opt->recordLast = NULL;
	(*gen).opt = opt;
	if (!(*gen).interface_) {
		StrLn(&(*gen), gen_tag, "#include <stdlib.h>", 20);
		StrLn(&(*gen), gen_tag, "#include <stddef.h>", 20);
		StrLn(&(*gen), gen_tag, "#include <string.h>", 20);
		StrLn(&(*gen), gen_tag, "#include <assert.h>", 20);
		StrLn(&(*gen), gen_tag, "#include <math.h>", 18);
		if (opt->std >= GeneratorC_IsoC99_cnst) {
			StrLn(&(*gen), gen_tag, "#include <stdbool.h>", 21);
		}
		Ln(&(*gen), gen_tag);
		StrLn(&(*gen), gen_tag, "#include <o7c.h>", 17);
		Ln(&(*gen), gen_tag);
	}
	(*gen).fixedLen = (*gen).len;
}

static void Generate_HeaderGuard(struct GeneratorC_Generator *gen, int *gen_tag) {
	Str(&(*gen), gen_tag, "#if !defined(HEADER_GUARD_", 27);
	String(&(*gen), gen_tag, &(*gen).module->_._.name, StringStore_String_tag);
	StrLn(&(*gen), gen_tag, ")", 2);
	Str(&(*gen), gen_tag, "#define HEADER_GUARD_", 22);
	String(&(*gen), gen_tag, &(*gen).module->_._.name, StringStore_String_tag);
	Ln(&(*gen), gen_tag);
	Ln(&(*gen), gen_tag);
}

static void Generate_Tags(struct GeneratorC_Generator *gen, int *gen_tag) {
	struct Ast_Record_s *r;

	r = NULL;
	while ((*gen).opt->records != NULL) {
		r = (&O7C_GUARD(Ast_Record_s, (*gen).opt->records, NULL));
		(*gen).opt->records = r->_._._._.ext;
		r->_._._._.ext = NULL;
		Tabs(&(*gen), gen_tag, 0);
		Str(&(*gen), gen_tag, "o7c_tag_init(", 14);
		GlobalName(&(*gen), gen_tag, &r->_._._, NULL);
		if (r->base == NULL) {
			StrLn(&(*gen), gen_tag, "_tag, NULL);", 13);
		} else {
			Str(&(*gen), gen_tag, "_tag, ", 7);
			GlobalName(&(*gen), gen_tag, &r->base->_._._, NULL);
			StrLn(&(*gen), gen_tag, "_tag);", 7);
		}
	}
	if (r != NULL) {
		Ln(&(*gen), gen_tag);
	}
}

static void Generate_ImportInit(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RDeclaration *imp, int *imp_tag) {
	if (imp != NULL) {
		assert(o7c_is(NULL, imp, Ast_Import_s_tag));
		do {
			Tabs(&(*gen), gen_tag, 0);
			String(&(*gen), gen_tag, &imp->module->_._.name, StringStore_String_tag);
			StrLn(&(*gen), gen_tag, "_init_();", 10);
			imp = imp->next;
		} while (!((imp == NULL) || !(o7c_is(NULL, imp, Ast_Import_s_tag))));
		Ln(&(*gen), gen_tag);
	}
}

static void Generate_ModuleInit(struct GeneratorC_Generator *interf, int *interf_tag, struct GeneratorC_Generator *impl, int *impl_tag, struct Ast_RModule *module, int *module_tag) {
	if ((module->import_ == NULL) && (module->_.stats == NULL) && ((*impl).opt->records == NULL)) {
		if ((*impl).opt->std >= GeneratorC_IsoC99_cnst) {
			Str(&(*interf), interf_tag, "static inline void ", 20);
		} else {
			Str(&(*interf), interf_tag, "static void ", 13);
		}
		Name(&(*interf), interf_tag, &module->_._, NULL);
		StrLn(&(*interf), interf_tag, "_init_(void) { ; }", 19);
	} else {
		Str(&(*interf), interf_tag, "extern void ", 13);
		Name(&(*interf), interf_tag, &module->_._, NULL);
		StrLn(&(*interf), interf_tag, "_init_(void);", 14);
		Str(&(*impl), impl_tag, "extern void ", 13);
		Name(&(*impl), impl_tag, &module->_._, NULL);
		StrLn(&(*impl), impl_tag, "_init_(void) {", 15);
		Tabs(&(*impl), impl_tag,  + 1);
		StrLn(&(*impl), impl_tag, "static int initialized__ = 0;", 30);
		Tabs(&(*impl), impl_tag, 0);
		StrLn(&(*impl), impl_tag, "if (0 == initialized__) {", 26);
		(*impl).tabs += 1;
		Generate_ImportInit(&(*impl), impl_tag, &module->import_->_, NULL);
		Generate_Tags(&(*impl), impl_tag);
		Statements(&(*impl), impl_tag, module->_.stats, NULL);
		Tabs(&(*impl), impl_tag,  - 1);
		StrLn(&(*impl), impl_tag, "}", 2);
		Tabs(&(*impl), impl_tag, 0);
		StrLn(&(*impl), impl_tag, "++initialized__;", 17);
		Tabs(&(*impl), impl_tag,  - 1);
		StrLn(&(*impl), impl_tag, "}", 2);
		Ln(&(*impl), impl_tag);
	}
}

static void Generate_Main(struct GeneratorC_Generator *gen, int *gen_tag, struct Ast_RModule *module, int *module_tag) {
	StrLn(&(*gen), gen_tag, "extern int main(int argc, char **argv) {", 41);
	Tabs(&(*gen), gen_tag,  + 1);
	StrLn(&(*gen), gen_tag, "o7c_cli_init(argc, argv);", 26);
	Generate_ImportInit(&(*gen), gen_tag, &module->import_->_, NULL);
	Generate_Tags(&(*gen), gen_tag);
	if (module->_.stats != NULL) {
		Statements(&(*gen), gen_tag, module->_.stats, NULL);
	}
	Tabs(&(*gen), gen_tag, 0);
	StrLn(&(*gen), gen_tag, "return o7c_exit_code;", 22);
	Tabs(&(*gen), gen_tag,  - 1);
	StrLn(&(*gen), gen_tag, "}", 2);
}

extern void GeneratorC_Generate(struct GeneratorC_Generator *interface_, int *interface__tag, struct GeneratorC_Generator *implementation, int *implementation_tag, struct Ast_RModule *module, int *module_tag, struct GeneratorC_Options_s *opt, int *opt_tag) {
	struct MOut out;

	assert(!Ast_HasError(module, NULL));
	if (opt == NULL) {
		opt = GeneratorC_DefaultOptions();
	}
	if (!opt->main_) {
		MarkUsedInMarked(module, NULL);
	}
	out.opt = opt;
	out.g[Interface_cnst].interface_ = true;
	Generate_Init(&out.g[Interface_cnst], GeneratorC_Generator_tag, (*interface_).out, NULL, module, NULL, opt, NULL);
	opt->index = 0;
	Generate_HeaderGuard(&out.g[Interface_cnst], GeneratorC_Generator_tag);
	out.g[Implementation_cnst].interface_ = false;
	Generate_Init(&out.g[Implementation_cnst], GeneratorC_Generator_tag, (*implementation).out, NULL, module, NULL, opt, NULL);
	Import(&out.g[Implementation_cnst], GeneratorC_Generator_tag, &module->_._, NULL);
	Declarations(&out, MOut_tag, &module->_, NULL);
	if (opt->main_) {
		Generate_Main(&out.g[Implementation_cnst], GeneratorC_Generator_tag, module, NULL);
	} else {
		Generate_ModuleInit(&out.g[Interface_cnst], GeneratorC_Generator_tag, &out.g[Implementation_cnst], GeneratorC_Generator_tag, module, NULL);
	}
	StrLn(&out.g[Interface_cnst], GeneratorC_Generator_tag, "#endif", 7);
	(*interface_).len = out.g[Interface_cnst].len;
	(*implementation).len = out.g[Implementation_cnst].len;
}

extern void GeneratorC_init_(void) {
	static int initialized__ = 0;
	if (0 == initialized__) {
		V_init_();
		Ast_init_();
		StringStore_init_();
		Scanner_init_();
		VDataStream_init_();
		Utf8_init_();
		Log_init_();
		TranslatorLimits_init_();

		o7c_tag_init(GeneratorC_Options_s_tag, V_Base_tag);
		o7c_tag_init(GeneratorC_Generator_tag, V_Base_tag);
		o7c_tag_init(MemoryOut_tag, VDataStream_Out_tag);
		o7c_tag_init(MOut_tag, NULL);
		o7c_tag_init(Selectors_tag, NULL);

		type = Type;
		declarator = Declarator;
		declarations = Declarations;
		statements = Statements;
		expression = Expression;
	}
	++initialized__;
}


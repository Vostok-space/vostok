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
	struct VDataStream_Out _;
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
	Ast_Designator des;
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
	int o7c_return;

	MemoryWrite(&O7C_GUARD_R(MemoryOut, &(*out), out_tag), MemoryOut_tag, buf, buf_len0, ofs, count);
	o7c_return = count;
	return o7c_return;
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
	(*gen).len = o7c_add((*gen).len, VDataStream_Write(&(*(*gen).out), NULL, (*mo).mem[o7c_ind(2, inv)].buf, 4096, 0, (*mo).mem[o7c_ind(2, inv)].len));
	(*mo).mem[o7c_ind(2, inv)].len = 0;
}

static void Str(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, o7c_char str[/*len0*/], int str_len0) {
	assert(str[o7c_ind(str_len0, o7c_sub(str_len0, 1))] == 0x00u);
	(*gen).len = o7c_add((*gen).len, VDataStream_Write(&(*(*gen).out), NULL, str, str_len0, 0, o7c_sub(str_len0, 1)));
}

static void StrLn(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, o7c_char str[/*len0*/], int str_len0) {
	(*gen).len = o7c_add((*gen).len, VDataStream_Write(&(*(*gen).out), NULL, str, str_len0, 0, o7c_sub(str_len0, 1)));
	(*gen).len = o7c_add((*gen).len, VDataStream_Write(&(*(*gen).out), NULL, "\x0A", 2, 0, 1));
}

static void Ln(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag) {
	(*gen).len = o7c_add((*gen).len, VDataStream_Write(&(*(*gen).out), NULL, "\x0A", 2, 0, 1));
}

static void Chars(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, o7c_char ch, int count) {
	o7c_char c[1] /* init array */;
	memset(&c, 0, sizeof(c));

	assert(o7c_cmp(count, 0) >=  0);
	c[0] = ch;
	while (o7c_cmp(count, 0) >  0) {
		(*gen).len = o7c_add((*gen).len, VDataStream_Write(&(*(*gen).out), NULL, c, 1, 0, 1));
		count = o7c_sub(count, 1);;
	}
}

static void Tabs(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, int adder) {
	(*gen).tabs = o7c_add((*gen).tabs, adder);
	Chars(&(*gen), gen_tag, 0x09u, (*gen).tabs);
}

static void String(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct StringStore_String *word, o7c_tag_t word_tag) {
	(*gen).len = o7c_add((*gen).len, StringStore_Write(&(*(*gen).out), NULL, &(*word), word_tag));
}

static void ScreeningString(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct StringStore_String *str, o7c_tag_t str_tag) {
	int i = O7C_INT_UNDEF, len = O7C_INT_UNDEF, last = O7C_INT_UNDEF;
	StringStore_Block block = NULL;

	O7C_ASSIGN(&(block), (*str).block);
	i = (*str).ofs;
	last = i;
	assert(block->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == (char unsigned)'"');
	i = o7c_add(i, 1);;
	len = 0;
	while (1) if (block->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == 0x0Cu) {
		len = o7c_add(len, VDataStream_Write(&(*(*gen).out), NULL, block->s, StringStore_BlockSize_cnst + 1, last, o7c_sub(i, last)));
		O7C_ASSIGN(&(block), block->next);
		i = 0;
		last = 0;
	} else if (block->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == (char unsigned)'\\') {
		len = o7c_add(len, VDataStream_Write(&(*(*gen).out), NULL, block->s, StringStore_BlockSize_cnst + 1, last, o7c_add(o7c_sub(i, last), 1)));
		len = o7c_add(len, VDataStream_Write(&(*(*gen).out), NULL, "\\", 2, 0, 1));
		i = o7c_add(i, 1);;
		last = i;
	} else if (block->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] != 0x00u) {
		i = o7c_add(i, 1);;
	} else break;
	assert(block->s[o7c_ind(StringStore_BlockSize_cnst + 1, i)] == 0x00u);
	(*gen).len = o7c_add((*gen).len, VDataStream_Write(&(*(*gen).out), NULL, block->s, StringStore_BlockSize_cnst + 1, last, o7c_sub(i, last)));
	o7c_release(block);
}

static void Int(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, int int_) {
	o7c_char buf[14] /* init array */;
	int i = O7C_INT_UNDEF;
	o7c_bool sign = O7C_BOOL_UNDEF;
	memset(&buf, 0, sizeof(buf));

	sign = o7c_cmp(int_, 0) <  0;
	if (sign) {
		int_ = o7c_sub(0, int_);
	}
	i = sizeof(buf) / sizeof (buf[0]);
	do {
		i = o7c_sub(i, 1);;
		buf[o7c_ind(14, i)] = (char unsigned)(o7c_add((int)(char unsigned)'0', o7c_mod(int_, 10)));
		int_ = o7c_div(int_, 10);
	} while (!(o7c_cmp(int_, 0) ==  0));
	if (sign) {
		i = o7c_sub(i, 1);;
		buf[o7c_ind(14, i)] = (char unsigned)'-';
	}
	(*gen).len = o7c_add((*gen).len, VDataStream_Write(&(*(*gen).out), NULL, buf, 14, i, o7c_sub(sizeof(buf) / sizeof (buf[0]), i)));
}

static void Real(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, double real) {
	Str(&(*gen), gen_tag, "Real not implemented", 21);
}

static o7c_bool IsNameOccupied(struct StringStore_String *n, o7c_tag_t n_tag);
static o7c_bool IsNameOccupied_Eq(struct StringStore_String *name, o7c_tag_t name_tag, o7c_char str[/*len0*/], int str_len0) {
	o7c_bool o7c_return;

	o7c_return = StringStore_IsEqualToString(&(*name), name_tag, str, str_len0);
	return o7c_return;
}

static o7c_bool IsNameOccupied(struct StringStore_String *n, o7c_tag_t n_tag) {
	o7c_bool o7c_return;

	o7c_return = IsNameOccupied_Eq(&(*n), n_tag, "auto", 5) || IsNameOccupied_Eq(&(*n), n_tag, "break", 6) || IsNameOccupied_Eq(&(*n), n_tag, "case", 5) || IsNameOccupied_Eq(&(*n), n_tag, "char", 5) || IsNameOccupied_Eq(&(*n), n_tag, "const", 6) || IsNameOccupied_Eq(&(*n), n_tag, "continue", 9) || IsNameOccupied_Eq(&(*n), n_tag, "default", 8) || IsNameOccupied_Eq(&(*n), n_tag, "do", 3) || IsNameOccupied_Eq(&(*n), n_tag, "double", 7) || IsNameOccupied_Eq(&(*n), n_tag, "else", 5) || IsNameOccupied_Eq(&(*n), n_tag, "enum", 5) || IsNameOccupied_Eq(&(*n), n_tag, "extern", 7) || IsNameOccupied_Eq(&(*n), n_tag, "float", 6) || IsNameOccupied_Eq(&(*n), n_tag, "for", 4) || IsNameOccupied_Eq(&(*n), n_tag, "goto", 5) || IsNameOccupied_Eq(&(*n), n_tag, "if", 3) || IsNameOccupied_Eq(&(*n), n_tag, "inline", 7) || IsNameOccupied_Eq(&(*n), n_tag, "int", 4) || IsNameOccupied_Eq(&(*n), n_tag, "long", 5) || IsNameOccupied_Eq(&(*n), n_tag, "register", 9) || IsNameOccupied_Eq(&(*n), n_tag, "return", 7) || IsNameOccupied_Eq(&(*n), n_tag, "short", 6) || IsNameOccupied_Eq(&(*n), n_tag, "signed", 7) || IsNameOccupied_Eq(&(*n), n_tag, "sizeof", 7) || IsNameOccupied_Eq(&(*n), n_tag, "static", 7) || IsNameOccupied_Eq(&(*n), n_tag, "struct", 7) || IsNameOccupied_Eq(&(*n), n_tag, "switch", 7) || IsNameOccupied_Eq(&(*n), n_tag, "typedef", 8) || IsNameOccupied_Eq(&(*n), n_tag, "union", 6) || IsNameOccupied_Eq(&(*n), n_tag, "unsigned", 9) || IsNameOccupied_Eq(&(*n), n_tag, "void", 5) || IsNameOccupied_Eq(&(*n), n_tag, "volatile", 9) || IsNameOccupied_Eq(&(*n), n_tag, "while", 6) || IsNameOccupied_Eq(&(*n), n_tag, "asm", 4) || IsNameOccupied_Eq(&(*n), n_tag, "typeof", 7) || IsNameOccupied_Eq(&(*n), n_tag, "abort", 6) || IsNameOccupied_Eq(&(*n), n_tag, "assert", 7) || IsNameOccupied_Eq(&(*n), n_tag, "bool", 5) || IsNameOccupied_Eq(&(*n), n_tag, "calloc", 7) || IsNameOccupied_Eq(&(*n), n_tag, "free", 5) || IsNameOccupied_Eq(&(*n), n_tag, "main", 5) || IsNameOccupied_Eq(&(*n), n_tag, "malloc", 7) || IsNameOccupied_Eq(&(*n), n_tag, "memcmp", 7) || IsNameOccupied_Eq(&(*n), n_tag, "memset", 7) || IsNameOccupied_Eq(&(*n), n_tag, "NULL", 5) || IsNameOccupied_Eq(&(*n), n_tag, "strcmp", 7) || IsNameOccupied_Eq(&(*n), n_tag, "strcpy", 7) || IsNameOccupied_Eq(&(*n), n_tag, "realloc", 8) || IsNameOccupied_Eq(&(*n), n_tag, "array", 6) || IsNameOccupied_Eq(&(*n), n_tag, "catch", 6) || IsNameOccupied_Eq(&(*n), n_tag, "class", 6) || IsNameOccupied_Eq(&(*n), n_tag, "decltype", 9) || IsNameOccupied_Eq(&(*n), n_tag, "delegate", 9) || IsNameOccupied_Eq(&(*n), n_tag, "delete", 7) || IsNameOccupied_Eq(&(*n), n_tag, "deprecated", 11) || IsNameOccupied_Eq(&(*n), n_tag, "dllexport", 10) || IsNameOccupied_Eq(&(*n), n_tag, "dllimport", 10) || IsNameOccupied_Eq(&(*n), n_tag, "dllexport", 10) || IsNameOccupied_Eq(&(*n), n_tag, "event", 6) || IsNameOccupied_Eq(&(*n), n_tag, "explicit", 9) || IsNameOccupied_Eq(&(*n), n_tag, "finally", 8) || IsNameOccupied_Eq(&(*n), n_tag, "each", 5) || IsNameOccupied_Eq(&(*n), n_tag, "in", 3) || IsNameOccupied_Eq(&(*n), n_tag, "friend", 7) || IsNameOccupied_Eq(&(*n), n_tag, "gcnew", 6) || IsNameOccupied_Eq(&(*n), n_tag, "generic", 8) || IsNameOccupied_Eq(&(*n), n_tag, "initonly", 9) || IsNameOccupied_Eq(&(*n), n_tag, "interface", 10) || IsNameOccupied_Eq(&(*n), n_tag, "literal", 8) || IsNameOccupied_Eq(&(*n), n_tag, "mutable", 8) || IsNameOccupied_Eq(&(*n), n_tag, "naked", 6) || IsNameOccupied_Eq(&(*n), n_tag, "namespace", 10) || IsNameOccupied_Eq(&(*n), n_tag, "new", 4) || IsNameOccupied_Eq(&(*n), n_tag, "noinline", 9) || IsNameOccupied_Eq(&(*n), n_tag, "noreturn", 9) || IsNameOccupied_Eq(&(*n), n_tag, "nothrow", 8) || IsNameOccupied_Eq(&(*n), n_tag, "novtable", 9) || IsNameOccupied_Eq(&(*n), n_tag, "nullptr", 8) || IsNameOccupied_Eq(&(*n), n_tag, "operator", 9) || IsNameOccupied_Eq(&(*n), n_tag, "private", 8) || IsNameOccupied_Eq(&(*n), n_tag, "property", 9) || IsNameOccupied_Eq(&(*n), n_tag, "protected", 10) || IsNameOccupied_Eq(&(*n), n_tag, "public", 7) || IsNameOccupied_Eq(&(*n), n_tag, "ref", 4) || IsNameOccupied_Eq(&(*n), n_tag, "safecast", 9) || IsNameOccupied_Eq(&(*n), n_tag, "sealed", 7) || IsNameOccupied_Eq(&(*n), n_tag, "selectany", 10) || IsNameOccupied_Eq(&(*n), n_tag, "super", 6) || IsNameOccupied_Eq(&(*n), n_tag, "template", 9) || IsNameOccupied_Eq(&(*n), n_tag, "this", 5) || IsNameOccupied_Eq(&(*n), n_tag, "thread", 7) || IsNameOccupied_Eq(&(*n), n_tag, "throw", 6) || IsNameOccupied_Eq(&(*n), n_tag, "try", 4) || IsNameOccupied_Eq(&(*n), n_tag, "typeid", 7) || IsNameOccupied_Eq(&(*n), n_tag, "typename", 9) || IsNameOccupied_Eq(&(*n), n_tag, "uuid", 5) || IsNameOccupied_Eq(&(*n), n_tag, "value", 6) || IsNameOccupied_Eq(&(*n), n_tag, "virtual", 8) || IsNameOccupied_Eq(&(*n), n_tag, "abstract", 9) || IsNameOccupied_Eq(&(*n), n_tag, "arguments", 10) || IsNameOccupied_Eq(&(*n), n_tag, "boolean", 8) || IsNameOccupied_Eq(&(*n), n_tag, "byte", 5) || IsNameOccupied_Eq(&(*n), n_tag, "debugger", 9) || IsNameOccupied_Eq(&(*n), n_tag, "eval", 5) || IsNameOccupied_Eq(&(*n), n_tag, "export", 7) || IsNameOccupied_Eq(&(*n), n_tag, "extends", 8) || IsNameOccupied_Eq(&(*n), n_tag, "final", 6) || IsNameOccupied_Eq(&(*n), n_tag, "function", 9) || IsNameOccupied_Eq(&(*n), n_tag, "implements", 11) || IsNameOccupied_Eq(&(*n), n_tag, "import", 7) || IsNameOccupied_Eq(&(*n), n_tag, "instanceof", 11) || IsNameOccupied_Eq(&(*n), n_tag, "interface", 10) || IsNameOccupied_Eq(&(*n), n_tag, "let", 4) || IsNameOccupied_Eq(&(*n), n_tag, "native", 7) || IsNameOccupied_Eq(&(*n), n_tag, "null", 5) || IsNameOccupied_Eq(&(*n), n_tag, "package", 8) || IsNameOccupied_Eq(&(*n), n_tag, "private", 8) || IsNameOccupied_Eq(&(*n), n_tag, "protected", 10) || IsNameOccupied_Eq(&(*n), n_tag, "synchronized", 13) || IsNameOccupied_Eq(&(*n), n_tag, "throws", 7) || IsNameOccupied_Eq(&(*n), n_tag, "transient", 10) || IsNameOccupied_Eq(&(*n), n_tag, "var", 4) || IsNameOccupied_Eq(&(*n), n_tag, "func", 5) || IsNameOccupied_Eq(&(*n), n_tag, "o7c", 4) || IsNameOccupied_Eq(&(*n), n_tag, "O7C", 4) || IsNameOccupied_Eq(&(*n), n_tag, "initialized", 12) || IsNameOccupied_Eq(&(*n), n_tag, "init", 5);
	return o7c_return;
}

static void Name(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *decl) {
	struct Ast_RDeclarations *up = NULL;

	o7c_retain(decl);
	if ((o7c_is(NULL, decl, Ast_RType_tag)) && (decl->up != &decl->module->_) && (decl->up != NULL) || !o7c_bl((*gen).opt->procLocal) && (o7c_is(NULL, decl, Ast_RProcedure_tag))) {
		O7C_ASSIGN(&(up), decl->up);
		while (!(o7c_is(NULL, up, Ast_RModule_tag))) {
			String(&(*gen), gen_tag, &up->_.name, StringStore_String_tag);
			Str(&(*gen), gen_tag, "_", 2);
			O7C_ASSIGN(&(up), up->_.up);
		}
	}
	String(&(*gen), gen_tag, &decl->name, StringStore_String_tag);
	if (o7c_is(NULL, decl, Ast_Const_s_tag)) {
		Str(&(*gen), gen_tag, "_cnst", 6);
	} else if (IsNameOccupied(&decl->name, StringStore_String_tag)) {
		Str(&(*gen), gen_tag, "_", 2);
	}
	o7c_release(up);
	o7c_release(decl);
}

static void GlobalName(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *decl) {
	o7c_retain(decl);
	if (o7c_bl(decl->mark) || (decl->module != NULL) && ((*gen).module != decl->module)) {
		assert(decl->module != NULL);
		String(&(*gen), gen_tag, &decl->module->_._.name, StringStore_String_tag);
		Str(&(*gen), gen_tag, "_", 2);
		String(&(*gen), gen_tag, &decl->name, StringStore_String_tag);
		if (o7c_is(NULL, decl, Ast_Const_s_tag)) {
			Str(&(*gen), gen_tag, "_cnst", 6);
		}
	} else {
		Name(&(*gen), gen_tag, decl);
	}
	o7c_release(decl);
}

static void Import(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *decl) {
	o7c_retain(decl);
	Str(&(*gen), gen_tag, "#include ", 10);
	Str(&(*gen), gen_tag, "\x22", 2);
	String(&(*gen), gen_tag, &decl->module->_._.name, StringStore_String_tag);
	Str(&(*gen), gen_tag, ".h", 3);
	StrLn(&(*gen), gen_tag, "\x22", 2);
	o7c_release(decl);
}

static void Factor(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *expr) {
	o7c_retain(expr);
	if (o7c_is(NULL, expr, Ast_RFactor_tag)) {
		expression(&(*gen), gen_tag, expr);
	} else {
		Str(&(*gen), gen_tag, "(", 2);
		expression(&(*gen), gen_tag, expr);
		Str(&(*gen), gen_tag, ")", 2);
	}
	o7c_release(expr);
}

static o7c_bool CheckStructName(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_Record rec) {
	o7c_bool o7c_return;

	o7c_char anon[TranslatorLimits_MaxLenName_cnst * 2 + 3] /* init array */;
	int i = O7C_INT_UNDEF, j = O7C_INT_UNDEF, l = O7C_INT_UNDEF;
	o7c_bool ret = O7C_BOOL_UNDEF;
	memset(&anon, 0, sizeof(anon));

	o7c_retain(rec);
	if (rec->_._._.name.block == NULL) {
		if ((rec->pointer != NULL) && (rec->pointer->_._._.name.block != NULL)) {
			l = 0;
			assert(rec->_._._.module != NULL);
			rec->_._._.mark = true;
			StringStore_CopyToChars(anon, TranslatorLimits_MaxLenName_cnst * 2 + 3, &l, &rec->pointer->_._._.name, StringStore_String_tag);
			anon[o7c_ind(TranslatorLimits_MaxLenName_cnst * 2 + 3, l)] = (char unsigned)'_';
			anon[o7c_ind(TranslatorLimits_MaxLenName_cnst * 2 + 3, o7c_add(l, 1))] = (char unsigned)'s';
			anon[o7c_ind(TranslatorLimits_MaxLenName_cnst * 2 + 3, o7c_add(l, 2))] = 0x00u;
			Ast_PutChars(rec->pointer->_._._.module, &rec->_._._.name, StringStore_String_tag, anon, TranslatorLimits_MaxLenName_cnst * 2 + 3, 0, o7c_add(l, 2));
		} else {
			l = 0;
			StringStore_CopyToChars(anon, TranslatorLimits_MaxLenName_cnst * 2 + 3, &l, &rec->_._._.module->_._.name, StringStore_String_tag);
			anon[o7c_ind(TranslatorLimits_MaxLenName_cnst * 2 + 3, l)] = (char unsigned)'_';
			l = o7c_add(l, 1);;
			Log_StrLn("Record", 7);
			ret = StringStore_CopyChars(anon, TranslatorLimits_MaxLenName_cnst * 2 + 3, &l, "anon_0000", 10, 0, 9);
			assert(o7c_bl(ret));
			assert((o7c_cmp((*gen).opt->index, 0) >=  0) && (o7c_cmp((*gen).opt->index, 10000) <  0));
			i = (*gen).opt->index;
			j = o7c_sub(l, 1);
			while (o7c_cmp(i, 0) >  0) {
				anon[o7c_ind(TranslatorLimits_MaxLenName_cnst * 2 + 3, j)] = (char unsigned)(o7c_add((int)(char unsigned)'0', o7c_mod(i, 10)));
				i = o7c_div(i, 10);
				j = o7c_sub(j, 1);;
			}
			(*gen).opt->index = o7c_add((*gen).opt->index, 1);;
			Ast_PutChars(rec->_._._.module, &rec->_._._.name, StringStore_String_tag, anon, TranslatorLimits_MaxLenName_cnst * 2 + 3, 0, l);
		}
	}
	o7c_return = rec->_._._.name.block != NULL;
	o7c_release(rec);
	return o7c_return;
}

static void Selector(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Selectors *sels, o7c_tag_t sels_tag, int i, struct Ast_RType **typ);
static void Selector_Record(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RType **type, struct Ast_RSelector **sel);
static o7c_bool Record_Selector_Search(Ast_Record ds, struct Ast_RDeclaration *d) {
	o7c_bool o7c_return;

	struct Ast_RDeclaration *c = NULL;

	o7c_retain(ds); o7c_retain(d);
	O7C_ASSIGN(&(c), (&(ds->vars)->_));
	while ((c != NULL) && (c != d)) {
		O7C_ASSIGN(&(c), c->next);
	}
	o7c_return = c != NULL;
	o7c_release(c);
	o7c_release(ds); o7c_release(d);
	return o7c_return;
}

static void Selector_Record(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RType **type, struct Ast_RSelector **sel) {
	struct Ast_RDeclaration *var_ = NULL;
	Ast_Record up = NULL;

	O7C_ASSIGN(&(var_), (&(O7C_GUARD(Ast_SelRecord_s, &(*sel))->var_)->_));
	if (o7c_is(NULL, (*type), Ast_RPointer_tag)) {
		O7C_ASSIGN(&(up), O7C_GUARD(Ast_Record_s, &O7C_GUARD(Ast_RPointer, &(*type))->_._._.type));
	} else {
		O7C_ASSIGN(&(up), O7C_GUARD(Ast_Record_s, &(*type)));
	}
	if (o7c_cmp((*type)->_._.id, Ast_IdPointer_cnst) ==  0) {
		Str(&(*gen), gen_tag, "->", 3);
	} else {
		Str(&(*gen), gen_tag, ".", 2);
	}
	while ((up != NULL) && !Record_Selector_Search(up, var_)) {
		O7C_ASSIGN(&(up), up->base);
		Str(&(*gen), gen_tag, "_.", 3);
	}
	Name(&(*gen), gen_tag, var_);
	O7C_ASSIGN(&((*type)), var_->type);
	o7c_release(var_); o7c_release(up);
}

static void Selector_Declarator(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *decl) {
	struct Ast_RType *type = NULL;

	o7c_retain(decl);
	O7C_ASSIGN(&(type), decl->type);
	if ((o7c_is(NULL, decl, Ast_FormalParam_s_tag)) && (o7c_bl(O7C_GUARD(Ast_FormalParam_s, &decl)->isVar) && (o7c_cmp(type->_._.id, Ast_IdArray_cnst) !=  0) || (o7c_cmp(type->_._.id, Ast_IdRecord_cnst) ==  0))) {
		Str(&(*gen), gen_tag, "(*", 3);
		GlobalName(&(*gen), gen_tag, decl);
		Str(&(*gen), gen_tag, ")", 2);
	} else {
		GlobalName(&(*gen), gen_tag, decl);
	}
	o7c_release(type);
	o7c_release(decl);
}

static void Selector_Array(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RType **type, struct Ast_RSelector **sel, struct Ast_RDeclaration *decl);
static void Array_Selector_Len(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RType *type, struct Ast_RDeclaration *decl, struct Ast_RSelector *sel) {
	int i = O7C_INT_UNDEF;

	o7c_retain(type); o7c_retain(decl); o7c_retain(sel);
	if (O7C_GUARD(Ast_RArray, &type)->count != NULL) {
		expression(&(*gen), gen_tag, O7C_GUARD(Ast_RArray, &type)->count);
	} else {
		GlobalName(&(*gen), gen_tag, decl);
		Str(&(*gen), gen_tag, "_len", 5);
		i =  - 1;
		while (sel != NULL) {
			i = o7c_add(i, 1);;
			O7C_ASSIGN(&(sel), sel->next);
		}
		Int(&(*gen), gen_tag, i);
	}
	o7c_release(type); o7c_release(decl); o7c_release(sel);
}

static void Selector_Array(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RType **type, struct Ast_RSelector **sel, struct Ast_RDeclaration *decl) {
	struct Ast_RSelector *s = NULL;
	int i = O7C_INT_UNDEF, j = O7C_INT_UNDEF;

	o7c_retain(decl);
	Str(&(*gen), gen_tag, "[", 2);
	if ((o7c_cmp((*type)->_.type->_._.id, Ast_IdArray_cnst) !=  0) || (O7C_GUARD(Ast_RArray, &(*type))->count != NULL)) {
		if (o7c_bl((*gen).opt->checkIndex) && ((O7C_GUARD(Ast_SelArray_s, &(*sel))->index->value_ == NULL) || (O7C_GUARD(Ast_RArray, &(*type))->count == NULL) && (o7c_cmp(O7C_GUARD(Ast_RExprInteger, &O7C_GUARD(Ast_SelArray_s, &(*sel))->index->value_)->int_, 0) !=  0))) {
			Str(&(*gen), gen_tag, "o7c_ind(", 9);
			Array_Selector_Len(&(*gen), gen_tag, (*type), decl, (*sel));
			Str(&(*gen), gen_tag, ", ", 3);
			expression(&(*gen), gen_tag, O7C_GUARD(Ast_SelArray_s, &(*sel))->index);
			Str(&(*gen), gen_tag, ")", 2);
		} else {
			expression(&(*gen), gen_tag, O7C_GUARD(Ast_SelArray_s, &(*sel))->index);
		}
		O7C_ASSIGN(&((*type)), (*type)->_.type);
		O7C_ASSIGN(&((*sel)), (*sel)->next);
		while (((*sel) != NULL) && (o7c_is(NULL, (*sel), Ast_SelArray_s_tag))) {
			if (o7c_bl((*gen).opt->checkIndex) && ((O7C_GUARD(Ast_SelArray_s, &(*sel))->index->value_ == NULL) || (O7C_GUARD(Ast_RArray, &(*type))->count == NULL) && (o7c_cmp(O7C_GUARD(Ast_RExprInteger, &O7C_GUARD(Ast_SelArray_s, &(*sel))->index->value_)->int_, 0) !=  0))) {
				Str(&(*gen), gen_tag, "][o7c_ind(", 11);
				Array_Selector_Len(&(*gen), gen_tag, (*type), decl, (*sel));
				Str(&(*gen), gen_tag, ", ", 3);
				expression(&(*gen), gen_tag, O7C_GUARD(Ast_SelArray_s, &(*sel))->index);
				Str(&(*gen), gen_tag, ")", 2);
			} else {
				Str(&(*gen), gen_tag, "][", 3);
				expression(&(*gen), gen_tag, O7C_GUARD(Ast_SelArray_s, &(*sel))->index);
			}
			O7C_ASSIGN(&((*sel)), (*sel)->next);
			O7C_ASSIGN(&((*type)), (*type)->_.type);
		}
	} else {
		i = 0;
		while (((*sel)->next != NULL) && (o7c_is(NULL, (*sel)->next, Ast_SelArray_s_tag))) {
			Factor(&(*gen), gen_tag, O7C_GUARD(Ast_SelArray_s, &(*sel))->index);
			O7C_ASSIGN(&((*sel)), (*sel)->next);
			O7C_ASSIGN(&(s), (*sel));
			j = i;
			while ((s != NULL) && (o7c_is(NULL, s, Ast_SelArray_s_tag))) {
				Str(&(*gen), gen_tag, " * ", 4);
				Name(&(*gen), gen_tag, decl);
				Str(&(*gen), gen_tag, "_len", 5);
				Int(&(*gen), gen_tag, j);
				j = o7c_add(j, 1);;
				O7C_ASSIGN(&(s), s->next);
			}
			i = o7c_add(i, 1);;
			O7C_ASSIGN(&((*type)), (*type)->_.type);
			Str(&(*gen), gen_tag, " + ", 4);
		}
		Factor(&(*gen), gen_tag, O7C_GUARD(Ast_SelArray_s, &(*sel))->index);
	}
	Str(&(*gen), gen_tag, "]", 2);
	o7c_release(s);
	o7c_release(decl);
}

static void Selector(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Selectors *sels, o7c_tag_t sels_tag, int i, struct Ast_RType **typ) {
	struct Ast_RSelector *sel = NULL;
	o7c_bool ret = O7C_BOOL_UNDEF;

	if (o7c_cmp(i, 0) <  0) {
		Selector_Declarator(&(*gen), gen_tag, (*sels).decl);
	} else {
		O7C_ASSIGN(&(sel), (*sels).list[o7c_ind(TranslatorLimits_MaxSelectors_cnst, i)]);
		i = o7c_sub(i, 1);;
		if (o7c_is(NULL, sel, Ast_SelRecord_s_tag)) {
			Selector(&(*gen), gen_tag, &(*sels), sels_tag, i, &(*typ));
			Selector_Record(&(*gen), gen_tag, &(*typ), &sel);
		} else if (o7c_is(NULL, sel, Ast_SelArray_s_tag)) {
			Selector(&(*gen), gen_tag, &(*sels), sels_tag, i, &(*typ));
			Selector_Array(&(*gen), gen_tag, &(*typ), &sel, (*sels).decl);
		} else if (o7c_is(NULL, sel, Ast_SelPointer_s_tag)) {
			if ((sel->next == NULL) || !(o7c_is(NULL, sel->next, Ast_SelRecord_s_tag))) {
				Str(&(*gen), gen_tag, "(*", 3);
				Selector(&(*gen), gen_tag, &(*sels), sels_tag, i, &(*typ));
				Str(&(*gen), gen_tag, ")", 2);
			} else {
				Selector(&(*gen), gen_tag, &(*sels), sels_tag, i, &(*typ));
			}
		} else if (o7c_is(NULL, sel, Ast_SelGuard_s_tag)) {
			if (o7c_cmp(O7C_GUARD(Ast_SelGuard_s, &sel)->type->_._.id, Ast_IdPointer_cnst) ==  0) {
				Str(&(*gen), gen_tag, "O7C_GUARD(", 11);
				ret = CheckStructName(&(*gen), gen_tag, O7C_GUARD(Ast_Record_s, &O7C_GUARD(Ast_SelGuard_s, &sel)->type->_.type));
				assert(o7c_bl(ret));
				GlobalName(&(*gen), gen_tag, &O7C_GUARD(Ast_SelGuard_s, &sel)->type->_.type->_);
			} else {
				Str(&(*gen), gen_tag, "O7C_GUARD_R(", 13);
				GlobalName(&(*gen), gen_tag, &O7C_GUARD(Ast_SelGuard_s, &sel)->type->_);
			}
			Str(&(*gen), gen_tag, ", &", 4);
			Selector(&(*gen), gen_tag, &(*sels), sels_tag, i, &(*typ));
			if (o7c_cmp(O7C_GUARD(Ast_SelGuard_s, &sel)->type->_._.id, Ast_IdPointer_cnst) ==  0) {
				Str(&(*gen), gen_tag, ")", 2);
			} else {
				Str(&(*gen), gen_tag, ", ", 3);
				GlobalName(&(*gen), gen_tag, (*sels).decl);
				Str(&(*gen), gen_tag, "_tag)", 6);
			}
			O7C_ASSIGN(&((*typ)), O7C_GUARD(Ast_SelGuard_s, &sel)->type);
		} else {
			assert(false);
		}
	}
	o7c_release(sel);
}

static void Designator(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_Designator des);
static void Designator_Put(struct Selectors *sels, o7c_tag_t sels_tag, struct Ast_RSelector *sel) {
	o7c_retain(sel);
	(*sels).i =  - 1;
	while (sel != NULL) {
		(*sels).i = o7c_add((*sels).i, 1);;
		O7C_ASSIGN(&((*sels).list[o7c_ind(TranslatorLimits_MaxSelectors_cnst, (*sels).i)]), sel);
		if (o7c_is(NULL, sel, Ast_SelArray_s_tag)) {
			while ((sel != NULL) && (o7c_is(NULL, sel, Ast_SelArray_s_tag))) {
				O7C_ASSIGN(&(sel), sel->next);
			}
		} else {
			O7C_ASSIGN(&(sel), sel->next);
		}
	}
	o7c_release(sel);
}

static void Designator(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_Designator des) {
	struct Selectors sels /* record init */;
	struct Ast_RType *typ = NULL;
	memset(&sels, 0, sizeof(sels));

	o7c_retain(des);
	Designator_Put(&sels, Selectors_tag, des->sel);
	O7C_ASSIGN(&(typ), des->decl->type);
	O7C_ASSIGN(&(sels.des), des);
	O7C_ASSIGN(&(sels.decl), des->decl);
	(*gen).opt->lastSelectorDereference = (o7c_cmp(sels.i, 0) >  0) && (o7c_is(NULL, sels.list[o7c_ind(TranslatorLimits_MaxSelectors_cnst, sels.i)], Ast_SelPointer_s_tag));
	Selector(&(*gen), gen_tag, &sels, Selectors_tag, sels.i, &typ);
	o7c_release(typ);
	o7c_release(des);
}

static void CheckExpr(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *e) {
	o7c_retain(e);
	if ((o7c_cmp((*gen).opt->varInit, GeneratorC_VarInitUndefined_cnst) ==  0) && (o7c_is(NULL, e, Ast_Designator_s_tag)) && (o7c_cmp(e->type->_._.id, Ast_IdBoolean_cnst) ==  0) && (e->value_ == NULL)) {
		Str(&(*gen), gen_tag, "o7c_bl(", 8);
		expression(&(*gen), gen_tag, e);
		Str(&(*gen), gen_tag, ")", 2);
	} else {
		expression(&(*gen), gen_tag, e);
	}
	o7c_release(e);
}

static void Expression(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *expr);
static void Expression_Call(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_ExprCall call);
static void Call_Expression_Predefined(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_ExprCall call);
static void Predefined_Call_Expression_Shift(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, o7c_char shift[/*len0*/], int shift_len0, Ast_Parameter ps) {
	o7c_retain(ps);
	Str(&(*gen), gen_tag, "(int)((unsigned)", 17);
	Factor(&(*gen), gen_tag, ps->expr);
	Str(&(*gen), gen_tag, shift, shift_len0);
	Factor(&(*gen), gen_tag, ps->next->expr);
	Str(&(*gen), gen_tag, ")", 2);
	o7c_release(ps);
}

static void Predefined_Call_Expression_Len(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_Designator_s *des) {
	struct Ast_RSelector *sel = NULL;
	int i = O7C_INT_UNDEF;

	o7c_retain(des);
	if ((o7c_cmp(des->decl->type->_._.id, Ast_IdArray_cnst) !=  0) || !(o7c_is(NULL, des->decl, Ast_FormalParam_s_tag))) {
		Str(&(*gen), gen_tag, "sizeof(", 8);
		Designator(&(*gen), gen_tag, des);
		Str(&(*gen), gen_tag, ") / sizeof (", 13);
		Designator(&(*gen), gen_tag, des);
		Str(&(*gen), gen_tag, "[0])", 5);
	} else {
		GlobalName(&(*gen), gen_tag, des->decl);
		Str(&(*gen), gen_tag, "_len", 5);
		i = 0;
		O7C_ASSIGN(&(sel), des->sel);
		while (sel != NULL) {
			i = o7c_add(i, 1);;
			O7C_ASSIGN(&(sel), sel->next);
		}
		Int(&(*gen), gen_tag, i);
	}
	o7c_release(sel);
	o7c_release(des);
}

static void Predefined_Call_Expression_New(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *e) {
	o7c_bool ret = O7C_BOOL_UNDEF;

	o7c_retain(e);
	Expression(&(*gen), gen_tag, e);
	Str(&(*gen), gen_tag, " = o7c_new(sizeof(*", 20);
	Expression(&(*gen), gen_tag, e);
	Str(&(*gen), gen_tag, "), ", 4);
	ret = CheckStructName(&(*gen), gen_tag, O7C_GUARD(Ast_Record_s, &e->type->_.type));
	assert(o7c_bl(ret));
	GlobalName(&(*gen), gen_tag, &e->type->_.type->_);
	Str(&(*gen), gen_tag, "_tag)", 6);
	o7c_release(e);
}

static void Predefined_Call_Expression_Ord(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *e) {
	o7c_retain(e);
	Str(&(*gen), gen_tag, "(int)", 6);
	Factor(&(*gen), gen_tag, e);
	o7c_release(e);
}

static void Predefined_Call_Expression_Inc(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *e1, Ast_Parameter p2) {
	o7c_retain(e1); o7c_retain(p2);
	Expression(&(*gen), gen_tag, e1);
	if ((*gen).opt->checkArith) {
		Str(&(*gen), gen_tag, " = o7c_add(", 12);
		Expression(&(*gen), gen_tag, e1);
		if (p2 == NULL) {
			Str(&(*gen), gen_tag, ", 1);", 6);
		} else {
			Str(&(*gen), gen_tag, ", ", 3);
			Expression(&(*gen), gen_tag, p2->expr);
			Str(&(*gen), gen_tag, ");", 3);
		}
	} else if (p2 == NULL) {
		Str(&(*gen), gen_tag, "++", 3);
	} else {
		Str(&(*gen), gen_tag, " += ", 5);
		Expression(&(*gen), gen_tag, p2->expr);
	}
	o7c_release(e1); o7c_release(p2);
}

static void Predefined_Call_Expression_Dec(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *e1, Ast_Parameter p2) {
	o7c_retain(e1); o7c_retain(p2);
	Expression(&(*gen), gen_tag, e1);
	if ((*gen).opt->checkArith) {
		Str(&(*gen), gen_tag, " = o7c_sub(", 12);
		Expression(&(*gen), gen_tag, e1);
		if (p2 == NULL) {
			Str(&(*gen), gen_tag, ", 1);", 6);
		} else {
			Str(&(*gen), gen_tag, ", ", 3);
			Expression(&(*gen), gen_tag, p2->expr);
			Str(&(*gen), gen_tag, ");", 3);
		}
	} else if (p2 == NULL) {
		Str(&(*gen), gen_tag, "--", 3);
	} else {
		Str(&(*gen), gen_tag, " -= ", 5);
		Expression(&(*gen), gen_tag, p2->expr);
	}
	o7c_release(e1); o7c_release(p2);
}

static void Call_Expression_Predefined(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_ExprCall call) {
	struct Ast_RExpression *e1 = NULL;
	Ast_Parameter p2 = NULL;

	o7c_retain(call);
	O7C_ASSIGN(&(e1), call->params->expr);
	O7C_ASSIGN(&(p2), call->params->next);
	switch (call->designator->decl->_.id) {
	case 90:
		if (o7c_cmp(call->_._.type->_._.id, Ast_IdInteger_cnst) ==  0) {
			Str(&(*gen), gen_tag, "abs(", 5);
		} else {
			Str(&(*gen), gen_tag, "fabs(", 6);
		}
		Expression(&(*gen), gen_tag, e1);
		Str(&(*gen), gen_tag, ")", 2);
		break;
	case 107:
		Str(&(*gen), gen_tag, "(", 2);
		Factor(&(*gen), gen_tag, e1);
		Str(&(*gen), gen_tag, " % 2 == 1)", 11);
		break;
	case 104:
		Predefined_Call_Expression_Len(&(*gen), gen_tag, O7C_GUARD(Ast_Designator_s, &e1));
		break;
	case 105:
		Predefined_Call_Expression_Shift(&(*gen), gen_tag, " << ", 5, call->params);
		break;
	case 91:
		Predefined_Call_Expression_Shift(&(*gen), gen_tag, " >> ", 5, call->params);
		break;
	case 111:
		Str(&(*gen), gen_tag, "o7_ror(", 8);
		Expression(&(*gen), gen_tag, e1);
		Str(&(*gen), gen_tag, ", ", 3);
		Expression(&(*gen), gen_tag, p2->expr);
		Str(&(*gen), gen_tag, ")", 2);
		break;
	case 99:
		Str(&(*gen), gen_tag, "(int)", 6);
		Factor(&(*gen), gen_tag, e1);
		break;
	case 100:
		Str(&(*gen), gen_tag, "(double)", 9);
		Factor(&(*gen), gen_tag, e1);
		break;
	case 108:
		Predefined_Call_Expression_Ord(&(*gen), gen_tag, e1);
		break;
	case 96:
		Str(&(*gen), gen_tag, "(char unsigned)", 16);
		Factor(&(*gen), gen_tag, e1);
		break;
	case 101:
		Predefined_Call_Expression_Inc(&(*gen), gen_tag, e1, p2);
		break;
	case 97:
		Predefined_Call_Expression_Dec(&(*gen), gen_tag, e1, p2);
		break;
	case 102:
		Expression(&(*gen), gen_tag, e1);
		Str(&(*gen), gen_tag, " |= 1u << ", 11);
		Factor(&(*gen), gen_tag, p2->expr);
		break;
	case 98:
		Expression(&(*gen), gen_tag, e1);
		Str(&(*gen), gen_tag, " &= ~(1u << ", 13);
		Factor(&(*gen), gen_tag, p2->expr);
		Str(&(*gen), gen_tag, ")", 2);
		break;
	case 106:
		Predefined_Call_Expression_New(&(*gen), gen_tag, e1);
		break;
	case 92:
		Str(&(*gen), gen_tag, "assert(", 8);
		CheckExpr(&(*gen), gen_tag, e1);
		Str(&(*gen), gen_tag, ")", 2);
		break;
	case 109:
		Expression(&(*gen), gen_tag, e1);
		Str(&(*gen), gen_tag, " *= 1 << ", 10);
		Expression(&(*gen), gen_tag, p2->expr);
		break;
	case 113:
		Expression(&(*gen), gen_tag, e1);
		Str(&(*gen), gen_tag, " /= 1 << ", 10);
		Expression(&(*gen), gen_tag, p2->expr);
		break;
	default:
		abort();
		break;
	}
	o7c_release(e1); o7c_release(p2);
	o7c_release(call);
}

static void Call_Expression_ActualParam(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_Parameter *p, struct Ast_RDeclaration **fp) {
	struct Ast_RType *t = NULL;
	int i = O7C_INT_UNDEF, dist = O7C_INT_UNDEF;

	O7C_ASSIGN(&(t), (*fp)->type);
	dist = (*p)->distance;
	if ((o7c_bl(O7C_GUARD(Ast_FormalParam_s, &(*fp))->isVar) && !(o7c_is(NULL, t, Ast_RArray_tag))) || (o7c_is(NULL, t, Ast_Record_s_tag)) || (o7c_cmp(t->_._.id, Ast_IdPointer_cnst) ==  0) && (o7c_cmp(dist, 0) >  0)) {
		Str(&(*gen), gen_tag, "&", 2);
	}
	(*gen).opt->lastSelectorDereference = false;
	Expression(&(*gen), gen_tag, (*p)->expr);
	if (o7c_cmp(dist, 0) >  0) {
		if (o7c_cmp(t->_._.id, Ast_IdPointer_cnst) ==  0) {
			dist = o7c_sub(dist, 1);;
			Str(&(*gen), gen_tag, "->_", 4);
		}
		while (o7c_cmp(dist, 0) >  0) {
			dist = o7c_sub(dist, 1);;
			Str(&(*gen), gen_tag, "._", 3);
		}
	}
	O7C_ASSIGN(&(t), (*p)->expr->type);
	i = 0;
	if (o7c_cmp(t->_._.id, Ast_IdRecord_cnst) ==  0) {
		if ((*gen).opt->lastSelectorDereference) {
			Str(&(*gen), gen_tag, ", NULL", 7);
		} else {
			Str(&(*gen), gen_tag, ", ", 3);
			if ((o7c_is(NULL, O7C_GUARD(Ast_Designator_s, &(*p)->expr)->decl, Ast_FormalParam_s_tag)) && (O7C_GUARD(Ast_Designator_s, &(*p)->expr)->sel == NULL)) {
				Name(&(*gen), gen_tag, O7C_GUARD(Ast_Designator_s, &(*p)->expr)->decl);
			} else {
				GlobalName(&(*gen), gen_tag, &t->_);
			}
			Str(&(*gen), gen_tag, "_tag", 5);
		}
	} else if (o7c_cmp((*fp)->type->_._.id, Ast_IdChar_cnst) !=  0) {
		while ((o7c_cmp(t->_._.id, Ast_IdArray_cnst) ==  0)) {
			Str(&(*gen), gen_tag, ", ", 3);
			if (O7C_GUARD(Ast_RArray, &t)->count != NULL) {
				Expression(&(*gen), gen_tag, O7C_GUARD(Ast_RArray, &t)->count);
			} else {
				Name(&(*gen), gen_tag, O7C_GUARD(Ast_Designator_s, &(*p)->expr)->decl);
				Str(&(*gen), gen_tag, "_len", 5);
				Int(&(*gen), gen_tag, i);
			}
			i = o7c_add(i, 1);;
			O7C_ASSIGN(&(t), t->_.type);
		}
	}
	O7C_ASSIGN(&((*p)), (*p)->next);
	O7C_ASSIGN(&((*fp)), (*fp)->next);
	o7c_release(t);
}

static void Expression_Call(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_ExprCall call) {
	Ast_Parameter p = NULL;
	struct Ast_RDeclaration *fp = NULL;

	o7c_retain(call);
	if (o7c_is(NULL, call->designator->decl, Ast_PredefinedProcedure_s_tag)) {
		Call_Expression_Predefined(&(*gen), gen_tag, call);
	} else {
		Designator(&(*gen), gen_tag, call->designator);
		Str(&(*gen), gen_tag, "(", 2);
		O7C_ASSIGN(&(p), call->params);
		if (false && (o7c_is(NULL, call->designator->decl, Ast_RProcedure_tag))) {
			O7C_ASSIGN(&(fp), (&(O7C_GUARD(Ast_RProcedure, &call->designator->decl)->_.header->params)->_._));
		} else {
			O7C_ASSIGN(&(fp), (&(O7C_GUARD(Ast_ProcType_s, &call->designator->_._.type)->params)->_._));
		}
		if (p != NULL) {
			Call_Expression_ActualParam(&(*gen), gen_tag, &p, &fp);
			while (p != NULL) {
				Str(&(*gen), gen_tag, ", ", 3);
				Call_Expression_ActualParam(&(*gen), gen_tag, &p, &fp);
			}
		}
		Str(&(*gen), gen_tag, ")", 2);
	}
	o7c_release(p); o7c_release(fp);
	o7c_release(call);
}

static void Expression_Relation(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_ExprRelation rel);
static void Relation_Expression_Simple(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_ExprRelation rel, o7c_char str[/*len0*/], int str_len0);
static void Simple_Relation_Expression_Expr(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *e, int dist) {
	o7c_retain(e);
	if ((o7c_cmp(dist, 0) >  0) && (o7c_cmp(e->type->_._.id, Ast_IdPointer_cnst) ==  0)) {
		Str(&(*gen), gen_tag, "&", 2);
	}
	Expression(&(*gen), gen_tag, e);
	if (o7c_cmp(dist, 0) >  0) {
		if (o7c_cmp(e->type->_._.id, Ast_IdPointer_cnst) ==  0) {
			dist = o7c_sub(dist, 1);;
			Str(&(*gen), gen_tag, "->_", 4);
		}
		while (o7c_cmp(dist, 0) >  0) {
			dist = o7c_sub(dist, 1);;
			Str(&(*gen), gen_tag, "._", 3);
		}
	}
	o7c_release(e);
}

static void Relation_Expression_Simple(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_ExprRelation rel, o7c_char str[/*len0*/], int str_len0) {
	o7c_retain(rel);
	if ((o7c_cmp(rel->exprs[0]->type->_._.id, Ast_IdArray_cnst) ==  0) && ((rel->exprs[0]->value_ == NULL) || !O7C_GUARD(Ast_ExprString_s, &rel->exprs[0]->value_)->asChar)) {
		Str(&(*gen), gen_tag, "strcmp(", 8);
		Simple_Relation_Expression_Expr(&(*gen), gen_tag, rel->exprs[0], o7c_sub(0, rel->distance));
		Str(&(*gen), gen_tag, ", ", 3);
		Simple_Relation_Expression_Expr(&(*gen), gen_tag, rel->exprs[1], rel->distance);
		Str(&(*gen), gen_tag, ")", 2);
		Str(&(*gen), gen_tag, str, str_len0);
		Str(&(*gen), gen_tag, "0", 2);
	} else if ((o7c_cmp((*gen).opt->varInit, GeneratorC_VarInitUndefined_cnst) ==  0) && (rel->_.value_ == NULL) && (o7c_cmp(rel->exprs[0]->type->_._.id, Ast_IdInteger_cnst) ==  0)) {
		Str(&(*gen), gen_tag, "o7c_cmp(", 9);
		Simple_Relation_Expression_Expr(&(*gen), gen_tag, rel->exprs[0], o7c_sub(0, rel->distance));
		Str(&(*gen), gen_tag, ", ", 3);
		Simple_Relation_Expression_Expr(&(*gen), gen_tag, rel->exprs[1], rel->distance);
		Str(&(*gen), gen_tag, ")", 2);
		Str(&(*gen), gen_tag, str, str_len0);
		Str(&(*gen), gen_tag, " 0", 3);
	} else {
		Simple_Relation_Expression_Expr(&(*gen), gen_tag, rel->exprs[0], o7c_sub(0, rel->distance));
		Str(&(*gen), gen_tag, str, str_len0);
		Simple_Relation_Expression_Expr(&(*gen), gen_tag, rel->exprs[1], rel->distance);
	}
	o7c_release(rel);
}

static void Expression_Relation(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_ExprRelation rel) {
	o7c_retain(rel);
	switch (rel->relation) {
	case 21:
		Relation_Expression_Simple(&(*gen), gen_tag, rel, " == ", 5);
		break;
	case 22:
		Relation_Expression_Simple(&(*gen), gen_tag, rel, " != ", 5);
		break;
	case 23:
		Relation_Expression_Simple(&(*gen), gen_tag, rel, " < ", 4);
		break;
	case 24:
		Relation_Expression_Simple(&(*gen), gen_tag, rel, " <= ", 5);
		break;
	case 25:
		Relation_Expression_Simple(&(*gen), gen_tag, rel, " > ", 4);
		break;
	case 26:
		Relation_Expression_Simple(&(*gen), gen_tag, rel, " >= ", 5);
		break;
	case 27:
		Str(&(*gen), gen_tag, "!!(", 4);
		Str(&(*gen), gen_tag, " (1u << ", 9);
		Factor(&(*gen), gen_tag, rel->exprs[0]);
		Str(&(*gen), gen_tag, ") & ", 5);
		Factor(&(*gen), gen_tag, rel->exprs[1]);
		Str(&(*gen), gen_tag, ")", 2);
		break;
	default:
		abort();
		break;
	}
	o7c_release(rel);
}

static void Expression_Sum(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_ExprSum sum) {
	o7c_bool first = O7C_BOOL_UNDEF;

	o7c_retain(sum);
	first = true;
	do {
		if (o7c_cmp(sum->add, Scanner_Minus_cnst) ==  0) {
			if (o7c_cmp(sum->_.type->_._.id, Ast_IdSet_cnst) !=  0) {
				Str(&(*gen), gen_tag, " - ", 4);
			} else if (first) {
				Str(&(*gen), gen_tag, " ~", 3);
			} else {
				Str(&(*gen), gen_tag, " & ~", 5);
			}
		} else if (o7c_cmp(sum->add, Scanner_Plus_cnst) ==  0) {
			if (o7c_cmp(sum->_.type->_._.id, Ast_IdSet_cnst) ==  0) {
				Str(&(*gen), gen_tag, " | ", 4);
			} else {
				Str(&(*gen), gen_tag, " + ", 4);
			}
		} else if (o7c_cmp(sum->add, Scanner_Or_cnst) ==  0) {
			Str(&(*gen), gen_tag, " || ", 5);
		}
		CheckExpr(&(*gen), gen_tag, sum->term);
		O7C_ASSIGN(&(sum), sum->next);
		first = false;
	} while (!(sum == NULL));
	o7c_release(sum);
}

static void Expression_SumCheck(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_ExprSum sum) {
	Ast_ExprSum arr[TranslatorLimits_MaxTermsInSum_cnst] /* init array */;
	int i = O7C_INT_UNDEF, last = O7C_INT_UNDEF;
	memset(&arr, 0, sizeof(arr));

	o7c_retain(sum);
	i =  - 1;
	do {
		i = o7c_add(i, 1);;
		O7C_ASSIGN(&(arr[o7c_ind(TranslatorLimits_MaxTermsInSum_cnst, i)]), sum);
		O7C_ASSIGN(&(sum), sum->next);
	} while (!(sum == NULL));
	last = i;
	if (o7c_cmp(arr[0]->_.type->_._.id, Ast_IdInteger_cnst) ==  0) {
		while (o7c_cmp(i, 0) >  0) {
			switch (arr[o7c_ind(TranslatorLimits_MaxTermsInSum_cnst, i)]->add) {
			case 11:
				Str(&(*gen), gen_tag, "o7c_sub(", 9);
				break;
			case 10:
				Str(&(*gen), gen_tag, "o7c_add(", 9);
				break;
			default:
				abort();
				break;
			}
			i = o7c_sub(i, 1);;
		}
	} else {
		assert(o7c_cmp(arr[0]->_.type->_._.id, Ast_IdReal_cnst) ==  0);
		while (o7c_cmp(i, 0) >  0) {
			switch (arr[o7c_ind(TranslatorLimits_MaxTermsInSum_cnst, i)]->add) {
			case 11:
				Str(&(*gen), gen_tag, "o7c_fsub(", 10);
				break;
			case 10:
				Str(&(*gen), gen_tag, "o7c_fadd(", 10);
				break;
			default:
				abort();
				break;
			}
			i = o7c_sub(i, 1);;
		}
	}
	if (o7c_cmp(arr[0]->add, Scanner_Minus_cnst) ==  0) {
		if (o7c_cmp(arr[0]->_.type->_._.id, Ast_IdInteger_cnst) ==  0) {
			Str(&(*gen), gen_tag, "o7c_sub(0, ", 12);
		} else {
			Str(&(*gen), gen_tag, "o7c_fsub(0, ", 13);
		}
		Expression(&(*gen), gen_tag, arr[0]->term);
		Str(&(*gen), gen_tag, ")", 2);
	} else {
		Expression(&(*gen), gen_tag, arr[0]->term);
	}
	while (o7c_cmp(i, last) <  0) {
		i = o7c_add(i, 1);;
		Str(&(*gen), gen_tag, ", ", 3);
		Expression(&(*gen), gen_tag, arr[o7c_ind(TranslatorLimits_MaxTermsInSum_cnst, i)]->term);
		Str(&(*gen), gen_tag, ")", 2);
	}
	o7c_release(sum);
}

static void Expression_Term(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_ExprTerm term) {
	o7c_retain(term);
	do {
		CheckExpr(&(*gen), gen_tag, &term->factor->_);
		switch (term->mult) {
		case 150:
			if (o7c_cmp(term->_.type->_._.id, Ast_IdSet_cnst) ==  0) {
				Str(&(*gen), gen_tag, " & ", 4);
			} else {
				Str(&(*gen), gen_tag, " * ", 4);
			}
			break;
		case 151:
		case 153:
			if (o7c_cmp(term->_.type->_._.id, Ast_IdSet_cnst) ==  0) {
				assert(o7c_cmp(term->mult, Scanner_Slash_cnst) ==  0);
				Str(&(*gen), gen_tag, " ^ ", 4);
			} else {
				Str(&(*gen), gen_tag, " / ", 4);
			}
			break;
		case 152:
			Str(&(*gen), gen_tag, " && ", 5);
			break;
		case 154:
			Str(&(*gen), gen_tag, " % ", 4);
			break;
		default:
			abort();
			break;
		}
		if (o7c_is(NULL, term->expr, Ast_ExprTerm_s_tag)) {
			O7C_ASSIGN(&(term), O7C_GUARD(Ast_ExprTerm_s, &term->expr));
		} else {
			CheckExpr(&(*gen), gen_tag, term->expr);
			O7C_ASSIGN(&(term), NULL);
		}
	} while (!(term == NULL));
	o7c_release(term);
}

static void Expression_TermCheck(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ExprTerm_s *term) {
	struct Ast_ExprTerm_s *arr[TranslatorLimits_MaxFactorsInTerm_cnst] /* init array */;
	int i = O7C_INT_UNDEF, last = O7C_INT_UNDEF;
	memset(&arr, 0, sizeof(arr));

	o7c_retain(term);
	i =  - 1;
	O7C_ASSIGN(&(arr[0]), term);
	i = 0;
	while (o7c_is(NULL, term->expr, Ast_ExprTerm_s_tag)) {
		i = o7c_add(i, 1);;
		O7C_ASSIGN(&(term), O7C_GUARD(Ast_ExprTerm_s, &term->expr));
		O7C_ASSIGN(&(arr[o7c_ind(TranslatorLimits_MaxFactorsInTerm_cnst, i)]), term);
	}
	last = i;
	if (o7c_cmp(term->_.type->_._.id, Ast_IdInteger_cnst) ==  0) {
		while (o7c_cmp(i, 0) >=  0) {
			switch (arr[o7c_ind(TranslatorLimits_MaxFactorsInTerm_cnst, i)]->mult) {
			case 150:
				Str(&(*gen), gen_tag, "o7c_mul(", 9);
				break;
			case 153:
				Str(&(*gen), gen_tag, "o7c_div(", 9);
				break;
			case 154:
				Str(&(*gen), gen_tag, "o7c_mod(", 9);
				break;
			default:
				abort();
				break;
			}
			i = o7c_sub(i, 1);;
		}
	} else {
		assert(o7c_cmp(term->_.type->_._.id, Ast_IdReal_cnst) ==  0);
		while (o7c_cmp(i, 0) >=  0) {
			switch (arr[o7c_ind(TranslatorLimits_MaxFactorsInTerm_cnst, i)]->mult) {
			case 150:
				Str(&(*gen), gen_tag, "o7c_fmul(", 10);
				break;
			case 151:
				Str(&(*gen), gen_tag, "o7c_fdiv(", 10);
				break;
			default:
				abort();
				break;
			}
			i = o7c_sub(i, 1);;
		}
	}
	Expression(&(*gen), gen_tag, &arr[0]->factor->_);
	i = 0;
	while (o7c_cmp(i, last) <  0) {
		i = o7c_add(i, 1);;
		Str(&(*gen), gen_tag, ", ", 3);
		Expression(&(*gen), gen_tag, &arr[o7c_ind(TranslatorLimits_MaxFactorsInTerm_cnst, i)]->factor->_);
		Str(&(*gen), gen_tag, ")", 2);
	}
	Str(&(*gen), gen_tag, ", ", 3);
	Expression(&(*gen), gen_tag, arr[o7c_ind(TranslatorLimits_MaxFactorsInTerm_cnst, last)]->expr);
	Str(&(*gen), gen_tag, ")", 2);
	o7c_release(term);
}

static void Expression_Boolean(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_ExprBoolean e) {
	o7c_retain(e);
	if (o7c_cmp((*gen).opt->std, GeneratorC_IsoC90_cnst) ==  0) {
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
	o7c_release(e);
}

static void Expression_CString(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ExprString_s *e);
static o7c_char CString_Expression_ToHex(int d) {
	o7c_char o7c_return;

	assert((o7c_cmp(d, 0) >=  0) && (o7c_cmp(d, 16) <  0));
	if (o7c_cmp(d, 10) <  0) {
		d = o7c_add(d, (int)(char unsigned)'0');;
	} else {
		d = o7c_add(d, (int)(char unsigned)'A' - 10);;
	}
	o7c_return = (char unsigned)d;
	return o7c_return;
}

static void Expression_CString(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ExprString_s *e) {
	o7c_char s1[7] /* init array */;
	o7c_char s2[4] /* init array */;
	o7c_char ch = '\0';
	struct StringStore_String w /* record init */;
	memset(&s1, 0, sizeof(s1));
	memset(&s2, 0, sizeof(s2));
	memset(&w, 0, sizeof(w));

	o7c_retain(e);
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
			s2[0] = CString_Expression_ToHex(o7c_div(e->_.int_, 16));
			s2[1] = CString_Expression_ToHex(o7c_mod(e->_.int_, 16));
			s2[2] = (char unsigned)'u';
			s2[3] = 0x00u;
			Str(&(*gen), gen_tag, s2, 4);
		}
	} else {
		if (w.block->s[o7c_ind(StringStore_BlockSize_cnst + 1, w.ofs)] == (char unsigned)'"') {
			ScreeningString(&(*gen), gen_tag, &w, StringStore_String_tag);
		} else {
			s1[0] = (char unsigned)'"';
			s1[1] = (char unsigned)'\\';
			s1[2] = (char unsigned)'x';
			s1[3] = CString_Expression_ToHex(o7c_div(e->_.int_, 16));
			s1[4] = CString_Expression_ToHex(o7c_mod(e->_.int_, 16));
			s1[5] = (char unsigned)'"';
			s1[6] = 0x00u;
			Str(&(*gen), gen_tag, s1, 7);
		}
	}
	o7c_release(e);
}

static void Expression_ExprInt(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, int int_) {
	if (o7c_cmp(int_, 0) >=  0) {
		Int(&(*gen), gen_tag, int_);
	} else {
		Str(&(*gen), gen_tag, "(-", 3);
		Int(&(*gen), gen_tag, o7c_sub(0, int_));
		Str(&(*gen), gen_tag, ")", 2);
	}
}

static void Expression_Set(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_ExprSet set);
static void Set_Expression_Item(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_ExprSet set) {
	o7c_retain(set);
	if (set->exprs[0] == NULL) {
		Str(&(*gen), gen_tag, "0", 2);
	} else {
		if (set->exprs[1] == NULL) {
			Str(&(*gen), gen_tag, "(1 << ", 7);
			Factor(&(*gen), gen_tag, set->exprs[0]);
		} else {
			if ((set->exprs[0]->value_ == NULL) || (set->exprs[1]->value_ == NULL)) {
				Str(&(*gen), gen_tag, "o7c_set(", 9);
			} else {
				Str(&(*gen), gen_tag, "O7C_SET(", 9);
			}
			Expression(&(*gen), gen_tag, set->exprs[0]);
			Str(&(*gen), gen_tag, ", ", 3);
			Expression(&(*gen), gen_tag, set->exprs[1]);
		}
		Str(&(*gen), gen_tag, ")", 2);
	}
	o7c_release(set);
}

static void Expression_Set(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_ExprSet set) {
	o7c_retain(set);
	if (set->next == NULL) {
		Set_Expression_Item(&(*gen), gen_tag, set);
	} else {
		Str(&(*gen), gen_tag, "(", 2);
		Set_Expression_Item(&(*gen), gen_tag, set);
		do {
			Str(&(*gen), gen_tag, " | ", 4);
			O7C_ASSIGN(&(set), set->next);
			Set_Expression_Item(&(*gen), gen_tag, set);
		} while (!(set->next == NULL));
		Str(&(*gen), gen_tag, ")", 2);
	}
	o7c_release(set);
}

static void Expression_IsExtension(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_ExprIsExtension is) {
	struct Ast_RDeclaration *decl = NULL;
	struct Ast_RType *extType = NULL;
	o7c_bool ret = O7C_BOOL_UNDEF;

	o7c_retain(is);
	O7C_ASSIGN(&(decl), is->designator->decl);
	O7C_ASSIGN(&(extType), is->extType);
	if (o7c_cmp(is->designator->_._.type->_._.id, Ast_IdPointer_cnst) ==  0) {
		O7C_ASSIGN(&(extType), extType->_.type);
		ret = CheckStructName(&(*gen), gen_tag, O7C_GUARD(Ast_Record_s, &extType));
		assert(o7c_bl(ret));
		Str(&(*gen), gen_tag, "o7c_is(NULL, ", 14);
		Expression(&(*gen), gen_tag, &is->designator->_._);
		Str(&(*gen), gen_tag, ", ", 3);
	} else {
		Str(&(*gen), gen_tag, "o7c_is(", 8);
		GlobalName(&(*gen), gen_tag, decl);
		Str(&(*gen), gen_tag, "_tag, ", 7);
		GlobalName(&(*gen), gen_tag, decl);
		Str(&(*gen), gen_tag, ", ", 3);
	}
	GlobalName(&(*gen), gen_tag, &extType->_);
	Str(&(*gen), gen_tag, "_tag)", 6);
	o7c_release(decl); o7c_release(extType);
	o7c_release(is);
}

static void Expression(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RExpression *expr) {
	o7c_retain(expr);
	switch (expr->_.id) {
	case 0:
		Expression_ExprInt(&(*gen), gen_tag, O7C_GUARD(Ast_RExprInteger, &expr)->int_);
		break;
	case 1:
		Expression_Boolean(&(*gen), gen_tag, O7C_GUARD(Ast_ExprBoolean_s, &expr));
		break;
	case 4:
		if (O7C_GUARD(Ast_ExprReal_s, &expr)->str.block != NULL) {
			String(&(*gen), gen_tag, &O7C_GUARD(Ast_ExprReal_s, &expr)->str, StringStore_String_tag);
		} else {
			Real(&(*gen), gen_tag, O7C_GUARD(Ast_ExprReal_s, &expr)->real);
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
		Log_Str("Expr Designator type.id = ", 27);
		Log_Int(expr->type->_._.id);
		Log_Str(" (expr.value # NIL) = ", 23);
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
		if (o7c_bl((*gen).opt->checkArith) && (!!( (1u << expr->type->_._.id) & ((1 << Ast_IdInteger_cnst) | (1 << Ast_IdReal_cnst)))) && (expr->value_ == NULL)) {
			Expression_SumCheck(&(*gen), gen_tag, O7C_GUARD(Ast_ExprSum_s, &expr));
		} else {
			Expression_Sum(&(*gen), gen_tag, O7C_GUARD(Ast_ExprSum_s, &expr));
		}
		break;
	case 23:
		if (o7c_bl((*gen).opt->checkArith) && (!!( (1u << expr->type->_._.id) & ((1 << Ast_IdInteger_cnst) | (1 << Ast_IdReal_cnst)))) && (expr->value_ == NULL)) {
			Expression_TermCheck(&(*gen), gen_tag, O7C_GUARD(Ast_ExprTerm_s, &expr));
		} else {
			Expression_Term(&(*gen), gen_tag, O7C_GUARD(Ast_ExprTerm_s, &expr));
		}
		break;
	case 24:
		if (o7c_cmp(expr->type->_._.id, Ast_IdSet_cnst) ==  0) {
			Str(&(*gen), gen_tag, "~", 2);
		} else {
			Str(&(*gen), gen_tag, "!", 2);
		}
		Expression(&(*gen), gen_tag, O7C_GUARD(Ast_ExprNegate_s, &expr)->expr);
		break;
	case 26:
		Str(&(*gen), gen_tag, "(", 2);
		Expression(&(*gen), gen_tag, O7C_GUARD(Ast_ExprBraces_s, &expr)->expr);
		Str(&(*gen), gen_tag, ")", 2);
		break;
	case 6:
		Str(&(*gen), gen_tag, "NULL", 5);
		break;
	case 27:
		Expression_IsExtension(&(*gen), gen_tag, O7C_GUARD(Ast_ExprIsExtension_s, &expr));
		break;
	default:
		abort();
		break;
	}
	o7c_release(expr);
}

static void Invert(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag) {
	O7C_GUARD(MemoryOut, &(*gen).out)->invert = !O7C_GUARD(MemoryOut, &(*gen).out)->invert;
}

static void ProcHead(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ProcType_s *proc);
static void ProcHead_Parameters(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ProcType_s *proc);
static void Parameters_ProcHead_Par(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_FormalParam_s *fp) {
	struct Ast_RType *t = NULL;
	int i = O7C_INT_UNDEF;

	o7c_retain(fp);
	declarator(&(*gen), gen_tag, &fp->_._, false, false, false);
	O7C_ASSIGN(&(t), fp->_._.type);
	i = 0;
	if (o7c_cmp(t->_._.id, Ast_IdRecord_cnst) ==  0) {
		Str(&(*gen), gen_tag, ", o7c_tag_t ", 13);
		Name(&(*gen), gen_tag, &fp->_._);
		Str(&(*gen), gen_tag, "_tag", 5);
	} else {
		while ((o7c_cmp(t->_._.id, Ast_IdArray_cnst) ==  0) && (O7C_GUARD(Ast_RArray, &t)->count == NULL)) {
			Str(&(*gen), gen_tag, ", int ", 7);
			Name(&(*gen), gen_tag, &fp->_._);
			Str(&(*gen), gen_tag, "_len", 5);
			Int(&(*gen), gen_tag, i);
			i = o7c_add(i, 1);;
			O7C_ASSIGN(&(t), t->_.type);
		}
	}
	o7c_release(t);
	o7c_release(fp);
}

static void ProcHead_Parameters(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ProcType_s *proc) {
	struct Ast_RDeclaration *p = NULL;

	o7c_retain(proc);
	if (proc->params == NULL) {
		Str(&(*gen), gen_tag, "(void)", 7);
	} else {
		Str(&(*gen), gen_tag, "(", 2);
		O7C_ASSIGN(&(p), (&(proc->params)->_._));
		while (p != &proc->end->_._) {
			Parameters_ProcHead_Par(&(*gen), gen_tag, O7C_GUARD(Ast_FormalParam_s, &p));
			Str(&(*gen), gen_tag, ", ", 3);
			O7C_ASSIGN(&(p), p->next);
		}
		Parameters_ProcHead_Par(&(*gen), gen_tag, O7C_GUARD(Ast_FormalParam_s, &p));
		Str(&(*gen), gen_tag, ")", 2);
	}
	o7c_release(p);
	o7c_release(proc);
}

static void ProcHead(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_ProcType_s *proc) {
	o7c_retain(proc);
	ProcHead_Parameters(&(*gen), gen_tag, proc);
	Invert(&(*gen), gen_tag);
	type(&(*gen), gen_tag, proc->_._._.type, false, false);
	MemWriteInvert(&(*O7C_GUARD(MemoryOut, &(*gen).out)), NULL);
	o7c_release(proc);
}

static void Declarator(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *decl, o7c_bool typeDecl, o7c_bool sameType, o7c_bool global) {
	struct GeneratorC_Generator g /* record init */;
	struct MemoryOut *mo = NULL;
	memset(&g, 0, sizeof(g));

	o7c_retain(decl);
	mo = o7c_new(sizeof(*mo), MemoryOut_tag);
	MemoryOutInit(&(*mo), MemoryOut_tag);
	V_Init(&g._, GeneratorC_Generator_tag);
	O7C_ASSIGN(&(g.out), (&(mo)->_));
	g.len = 0;
	O7C_ASSIGN(&(g.module), (*gen).module);
	g.tabs = (*gen).tabs;
	g.interface_ = (*gen).interface_;
	O7C_ASSIGN(&(g.opt), (*gen).opt);
	if ((o7c_is(NULL, decl, Ast_FormalParam_s_tag)) && ((o7c_bl(O7C_GUARD(Ast_FormalParam_s, &decl)->isVar) && !(o7c_is(NULL, decl->type, Ast_RArray_tag))) || (o7c_is(NULL, decl->type, Ast_Record_s_tag)))) {
		Str(&g, GeneratorC_Generator_tag, "*", 2);
	} else if (o7c_is(NULL, decl, Ast_Const_s_tag)) {
		Str(&g, GeneratorC_Generator_tag, "const ", 7);
	}
	if (global) {
		GlobalName(&g, GeneratorC_Generator_tag, decl);
	} else {
		Name(&g, GeneratorC_Generator_tag, decl);
	}
	if (o7c_is(NULL, decl, Ast_RProcedure_tag)) {
		ProcHead(&g, GeneratorC_Generator_tag, O7C_GUARD(Ast_RProcedure, &decl)->_.header);
	} else {
		mo->invert = !mo->invert;
		if (o7c_is(NULL, decl, Ast_RType_tag)) {
			type(&g, GeneratorC_Generator_tag, O7C_GUARD(Ast_RType, &decl), typeDecl, false);
		} else {
			type(&g, GeneratorC_Generator_tag, decl->type, false, sameType);
		}
	}
	MemWriteDirect(&(*gen), gen_tag, &(*mo), MemoryOut_tag);
	o7c_release(mo);
	o7c_release(decl);
}

static void Type(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RType *type, o7c_bool typeDecl, o7c_bool sameType);
static void Type_Simple(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, o7c_char str[/*len0*/], int str_len0) {
	Str(&(*gen), gen_tag, str, str_len0);
	MemWriteInvert(&(*O7C_GUARD(MemoryOut, &(*gen).out)), NULL);
}

static void Type_Record(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_Record_s *rec) {
	struct Ast_RDeclaration *v = NULL;

	o7c_retain(rec);
	O7C_ASSIGN(&(rec->_._._.module), (*gen).module);
	Str(&(*gen), gen_tag, "struct ", 8);
	if (CheckStructName(&(*gen), gen_tag, rec)) {
		GlobalName(&(*gen), gen_tag, &rec->_._._);
	}
	O7C_ASSIGN(&(v), (&(rec->vars)->_));
	if ((v == NULL) && (rec->base == NULL) && !(*gen).opt->gnu) {
		Str(&(*gen), gen_tag, " { int nothing; } ", 19);
	} else {
		StrLn(&(*gen), gen_tag, " {", 3);
		if (rec->base != NULL) {
			Tabs(&(*gen), gen_tag,  + 1);
			Str(&(*gen), gen_tag, "struct ", 8);
			GlobalName(&(*gen), gen_tag, &rec->base->_._._);
			StrLn(&(*gen), gen_tag, " _;", 4);
		} else {
			(*gen).tabs = o7c_add((*gen).tabs, 1);;
		}
		while (v != NULL) {
			Tabs(&(*gen), gen_tag, 0);
			Declarator(&(*gen), gen_tag, v, false, false, false);
			StrLn(&(*gen), gen_tag, ";", 2);
			O7C_ASSIGN(&(v), v->next);
		}
		Tabs(&(*gen), gen_tag,  - 1);
		Str(&(*gen), gen_tag, "} ", 3);
	}
	MemWriteInvert(&(*O7C_GUARD(MemoryOut, &(*gen).out)), NULL);
	o7c_release(v);
	o7c_release(rec);
}

static void Type_Array(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RArray *arr, o7c_bool sameType) {
	struct Ast_RType *t = NULL;
	int i = O7C_INT_UNDEF;

	o7c_retain(arr);
	O7C_ASSIGN(&(t), arr->_._._.type);
	MemWriteInvert(&(*O7C_GUARD(MemoryOut, &(*gen).out)), NULL);
	if (arr->count == NULL) {
		Str(&(*gen), gen_tag, "[/*len0", 8);
		i = 0;
		while (o7c_cmp(t->_._.id, Ast_IdArray_cnst) ==  0) {
			i = o7c_add(i, 1);;
			Str(&(*gen), gen_tag, ", len", 6);
			Int(&(*gen), gen_tag, i);
			O7C_ASSIGN(&(t), t->_.type);
		}
		Str(&(*gen), gen_tag, "*/]", 4);
	} else {
		Str(&(*gen), gen_tag, "[", 2);
		Expression(&(*gen), gen_tag, arr->count);
		Str(&(*gen), gen_tag, "]", 2);
	}
	Invert(&(*gen), gen_tag);
	Type(&(*gen), gen_tag, t, false, sameType);
	o7c_release(t);
	o7c_release(arr);
}

static void Type(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RType *type, o7c_bool typeDecl, o7c_bool sameType) {
	o7c_retain(type);
	if (type == NULL) {
		Str(&(*gen), gen_tag, "void ", 6);
		MemWriteInvert(&(*O7C_GUARD(MemoryOut, &(*gen).out)), NULL);
	} else {
		if (!o7c_bl(typeDecl) && (type->_.name.block != NULL)) {
			if (sameType) {
				if ((o7c_is(NULL, type, Ast_RPointer_tag)) && (type->_.type->_.name.block != NULL)) {
					Str(&(*gen), gen_tag, "*", 2);
				}
			} else {
				if ((o7c_is(NULL, type, Ast_RPointer_tag)) && (type->_.type->_.name.block != NULL)) {
					Str(&(*gen), gen_tag, "struct ", 8);
					GlobalName(&(*gen), gen_tag, &type->_.type->_);
					Str(&(*gen), gen_tag, " *", 3);
				} else {
					if (o7c_is(NULL, type, Ast_Record_s_tag)) {
						Str(&(*gen), gen_tag, "struct ", 8);
						if (CheckStructName(&(*gen), gen_tag, O7C_GUARD(Ast_Record_s, &type))) {
							GlobalName(&(*gen), gen_tag, &type->_);
							Str(&(*gen), gen_tag, " ", 2);
						}
					} else {
						GlobalName(&(*gen), gen_tag, &type->_);
						Str(&(*gen), gen_tag, " ", 2);
					}
				}
				if (o7c_is(NULL, (*gen).out, MemoryOut_tag)) {
					MemWriteInvert(&(*O7C_GUARD(MemoryOut, &(*gen).out)), NULL);
				}
			}
		} else if (!o7c_bl(sameType) || (!!( (1u << type->_._.id) & ((1 << Ast_IdPointer_cnst) | (1 << Ast_IdArray_cnst) | (1 << Ast_IdProcType_cnst))))) {
			switch (type->_._.id) {
			case 0:
				Type_Simple(&(*gen), gen_tag, "int ", 5);
				break;
			case 5:
				Type_Simple(&(*gen), gen_tag, "unsigned ", 10);
				break;
			case 1:
				if ((o7c_cmp((*gen).opt->std, GeneratorC_IsoC99_cnst) >=  0) && (o7c_cmp((*gen).opt->varInit, GeneratorC_VarInitUndefined_cnst) !=  0)) {
					Type_Simple(&(*gen), gen_tag, "bool ", 6);
				} else {
					Type_Simple(&(*gen), gen_tag, "o7c_bool ", 10);
				}
				break;
			case 2:
				Type_Simple(&(*gen), gen_tag, "char unsigned ", 15);
				break;
			case 3:
				Type_Simple(&(*gen), gen_tag, "o7c_char ", 10);
				break;
			case 4:
				Type_Simple(&(*gen), gen_tag, "double ", 8);
				break;
			case 6:
				Str(&(*gen), gen_tag, "*", 2);
				MemWriteInvert(&(*O7C_GUARD(MemoryOut, &(*gen).out)), NULL);
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
				Str(&(*gen), gen_tag, "(*", 3);
				MemWriteInvert(&(*O7C_GUARD(MemoryOut, &(*gen).out)), NULL);
				Str(&(*gen), gen_tag, ")", 2);
				ProcHead(&(*gen), gen_tag, O7C_GUARD(Ast_ProcType_s, &type));
				break;
			default:
				abort();
				break;
			}
		}
		if (o7c_is(NULL, (*gen).out, MemoryOut_tag)) {
			MemWriteInvert(&(*O7C_GUARD(MemoryOut, &(*gen).out)), NULL);
		}
	}
	o7c_release(type);
}

static void RecordTag(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_Record_s *rec) {
	o7c_retain(rec);
	if (!o7c_bl(rec->_._._.mark) || o7c_bl((*gen).opt->main_)) {
		Str(&(*gen), gen_tag, "static o7c_tag_t ", 18);
	} else if ((*gen).interface_) {
		Str(&(*gen), gen_tag, "extern o7c_tag_t ", 18);
	} else {
		Str(&(*gen), gen_tag, "o7c_tag_t ", 11);
	}
	GlobalName(&(*gen), gen_tag, &rec->_._._);
	StrLn(&(*gen), gen_tag, "_tag;", 6);
	if (!o7c_bl(rec->_._._.mark) || o7c_bl((*gen).opt->main_) || o7c_bl((*gen).interface_)) {
		Ln(&(*gen), gen_tag);
	}
	o7c_release(rec);
}

static void TypeDecl(struct MOut *out, o7c_tag_t out_tag, struct Ast_RType *type);
static void TypeDecl_Typedef(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RType *type) {
	o7c_retain(type);
	Tabs(&(*gen), gen_tag, 0);
	Str(&(*gen), gen_tag, "typedef ", 9);
	Declarator(&(*gen), gen_tag, &type->_, true, false, true);
	StrLn(&(*gen), gen_tag, ";", 2);
	o7c_release(type);
}

static void TypeDecl_LinkRecord(struct GeneratorC_Options_s *opt, struct Ast_Record_s *rec) {
	o7c_retain(opt); o7c_retain(rec);
	if (opt->records == NULL) {
		O7C_ASSIGN(&(opt->records), (&(rec)->_._._._._));
	} else {
		O7C_ASSIGN(&(O7C_GUARD(Ast_Record_s, &opt->recordLast)->_._._._.ext), (&(rec)->_._._._._));
	}
	O7C_ASSIGN(&(opt->recordLast), (&(rec)->_._._._._));
	assert(rec->_._._._.ext == NULL);
	o7c_release(opt); o7c_release(rec);
}

static void TypeDecl(struct MOut *out, o7c_tag_t out_tag, struct Ast_RType *type) {
	o7c_retain(type);
	TypeDecl_Typedef(&(*out).g[o7c_ind(2, (int)(o7c_bl(type->_.mark) && !(*out).opt->main_))], GeneratorC_Generator_tag, type);
	if ((o7c_cmp(type->_._.id, Ast_IdRecord_cnst) ==  0) || (o7c_cmp(type->_._.id, Ast_IdPointer_cnst) ==  0) && (type->_.type->_.next == NULL)) {
		if (o7c_cmp(type->_._.id, Ast_IdPointer_cnst) ==  0) {
			O7C_ASSIGN(&(type), type->_.type);
		}
		type->_.mark = o7c_bl(type->_.mark) || (O7C_GUARD(Ast_Record_s, &type)->pointer != NULL) && (O7C_GUARD(Ast_Record_s, &type)->pointer->_._._.mark);
		if (o7c_bl(type->_.mark) && !(*out).opt->main_) {
			RecordTag(&(*out).g[Interface_cnst], GeneratorC_Generator_tag, O7C_GUARD(Ast_Record_s, &type));
		}
		RecordTag(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, O7C_GUARD(Ast_Record_s, &type));
		TypeDecl_LinkRecord((*out).opt, O7C_GUARD(Ast_Record_s, &type));
	}
	o7c_release(type);
}

static void Mark(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, o7c_bool mark) {
	if (o7c_cmp((*gen).localDeep, 0) ==  0) {
		if (o7c_bl(mark) && !(*gen).opt->main_) {
			Str(&(*gen), gen_tag, "extern ", 8);
		} else {
			Str(&(*gen), gen_tag, "static ", 8);
		}
	}
}

static void Const(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_Const_s *const_) {
	o7c_retain(const_);
	Str(&(*gen), gen_tag, "#define ", 9);
	GlobalName(&(*gen), gen_tag, &const_->_);
	Str(&(*gen), gen_tag, " ", 2);
	if (o7c_bl(const_->_.mark) && (const_->expr != NULL)) {
		Factor(&(*gen), gen_tag, &const_->expr->value_->_);
	} else {
		Factor(&(*gen), gen_tag, const_->expr);
	}
	Ln(&(*gen), gen_tag);
	o7c_release(const_);
}

static void Var(struct MOut *out, o7c_tag_t out_tag, struct Ast_RDeclaration *prev, struct Ast_RDeclaration *var_, o7c_bool last) {
	o7c_bool same = O7C_BOOL_UNDEF, mark = O7C_BOOL_UNDEF;

	o7c_retain(prev); o7c_retain(var_);
	mark = o7c_bl(var_->mark) && !(*out).opt->main_;
	same = (prev != NULL) && (prev->mark == mark) && (prev->type == var_->type);
	if (!same) {
		if (prev != NULL) {
			StrLn(&(*out).g[o7c_ind(2, (int)mark)], GeneratorC_Generator_tag, ";", 2);
		}
		Tabs(&(*out).g[o7c_ind(2, (int)mark)], GeneratorC_Generator_tag, 0);
		Mark(&(*out).g[o7c_ind(2, (int)mark)], GeneratorC_Generator_tag, mark);
	} else {
		Str(&(*out).g[o7c_ind(2, (int)mark)], GeneratorC_Generator_tag, ", ", 3);
	}
	if (mark) {
		Declarator(&(*out).g[Interface_cnst], GeneratorC_Generator_tag, var_, false, same, true);
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
	Declarator(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, var_, false, same, true);
	if (o7c_cmp((*out).opt->varInit, GeneratorC_VarInitNo_cnst) !=  0) {
		switch (var_->type->_._.id) {
		case 0:
			Str(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, " = O7C_INT_UNDEF", 17);
			break;
		case 1:
			Str(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, " = O7C_BOOL_UNDEF", 18);
			break;
		case 2:
			Str(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, " = 0", 5);
			break;
		case 3:
			Str(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, " = '\\0'", 8);
			break;
		case 4:
			Str(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, " = O7C_DBL_UNDEF", 17);
			break;
		case 5:
			Str(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, " = 0", 5);
			break;
		case 6:
		case 10:
			Str(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, " = NULL", 8);
			break;
		case 7:
			Str(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, " /* init array */", 18);
			break;
		case 8:
			Str(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, " /* record init */", 19);
			break;
		default:
			abort();
			break;
		}
	}
	if (last) {
		StrLn(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, ";", 2);
	}
	o7c_release(prev); o7c_release(var_);
}

static void ExprThenStats(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RWhileIf **wi) {
	Expression(&(*gen), gen_tag, (*wi)->_.expr);
	StrLn(&(*gen), gen_tag, ") {", 4);
	(*gen).tabs = o7c_add((*gen).tabs, 1);;
	statements(&(*gen), gen_tag, (*wi)->stats);
	O7C_ASSIGN(&((*wi)), (*wi)->elsif);
}

static o7c_bool IsCaseElementWithRange(Ast_CaseElement elem) {
	o7c_bool o7c_return;

	Ast_CaseLabel r = NULL;

	o7c_retain(elem);
	O7C_ASSIGN(&(r), elem->labels);
	while ((r != NULL) && (r->right == NULL)) {
		O7C_ASSIGN(&(r), r->next);
	}
	o7c_return = r != NULL;
	o7c_release(r);
	o7c_release(elem);
	return o7c_return;
}

static void Statement(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RStatement *st);
static void Statement_WhileIf(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RWhileIf *wi);
static void WhileIf_Statement_Elsif(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RWhileIf **wi) {
	while (((*wi) != NULL) && ((*wi)->_.expr != NULL)) {
		Tabs(&(*gen), gen_tag,  - 1);
		Str(&(*gen), gen_tag, "} else if (", 12);
		ExprThenStats(&(*gen), gen_tag, &(*wi));
	}
}

static void Statement_WhileIf(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RWhileIf *wi) {
	o7c_retain(wi);
	if (o7c_is(NULL, wi, Ast_If_s_tag)) {
		Str(&(*gen), gen_tag, "if (", 5);
		ExprThenStats(&(*gen), gen_tag, &wi);
		WhileIf_Statement_Elsif(&(*gen), gen_tag, &wi);
		if (wi != NULL) {
			Tabs(&(*gen), gen_tag,  - 1);
			StrLn(&(*gen), gen_tag, "} else {", 9);
			(*gen).tabs = o7c_add((*gen).tabs, 1);;
			statements(&(*gen), gen_tag, wi->stats);
		}
		Tabs(&(*gen), gen_tag,  - 1);
		StrLn(&(*gen), gen_tag, "}", 2);
	} else if (wi->elsif == NULL) {
		Str(&(*gen), gen_tag, "while (", 8);
		ExprThenStats(&(*gen), gen_tag, &wi);
		Tabs(&(*gen), gen_tag,  - 1);
		StrLn(&(*gen), gen_tag, "}", 2);
	} else {
		Str(&(*gen), gen_tag, "while (1) if (", 15);
		ExprThenStats(&(*gen), gen_tag, &wi);
		WhileIf_Statement_Elsif(&(*gen), gen_tag, &wi);
		Tabs(&(*gen), gen_tag,  - 1);
		StrLn(&(*gen), gen_tag, "} else break;", 14);
	}
	o7c_release(wi);
}

static void Statement_Repeat(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_Repeat st) {
	o7c_retain(st);
	StrLn(&(*gen), gen_tag, "do {", 5);
	(*gen).tabs = o7c_add((*gen).tabs, 1);;
	statements(&(*gen), gen_tag, st->stats);
	Tabs(&(*gen), gen_tag,  - 1);
	if (o7c_cmp(st->_.expr->_.id, Ast_IdNegate_cnst) ==  0) {
		Str(&(*gen), gen_tag, "} while (", 10);
		Expression(&(*gen), gen_tag, O7C_GUARD(Ast_ExprNegate_s, &st->_.expr)->expr);
		StrLn(&(*gen), gen_tag, ");", 3);
	} else {
		Str(&(*gen), gen_tag, "} while (!(", 12);
		Expression(&(*gen), gen_tag, st->_.expr);
		StrLn(&(*gen), gen_tag, "));", 4);
	}
	o7c_release(st);
}

static void Statement_For(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_For st);
static o7c_bool For_Statement_IsEndMinus1(struct Ast_ExprSum_s *sum) {
	o7c_bool o7c_return;

	o7c_retain(sum);
	o7c_return = (sum->next != NULL) && (sum->next->next == NULL) && (o7c_cmp(sum->next->add, Scanner_Minus_cnst) ==  0) && (sum->next->term->value_ != NULL) && (o7c_cmp(O7C_GUARD(Ast_RExprInteger, &sum->next->term->value_)->int_, 1) ==  0);
	o7c_release(sum);
	return o7c_return;
}

static void Statement_For(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_For st) {
	o7c_retain(st);
	Str(&(*gen), gen_tag, "for (", 6);
	GlobalName(&(*gen), gen_tag, &st->var_->_);
	Str(&(*gen), gen_tag, " = ", 4);
	Expression(&(*gen), gen_tag, st->_.expr);
	Str(&(*gen), gen_tag, "; ", 3);
	GlobalName(&(*gen), gen_tag, &st->var_->_);
	if ((o7c_is(NULL, st->to, Ast_ExprSum_s_tag)) && For_Statement_IsEndMinus1(O7C_GUARD(Ast_ExprSum_s, &st->to))) {
		Str(&(*gen), gen_tag, " < ", 4);
		Expression(&(*gen), gen_tag, O7C_GUARD(Ast_ExprSum_s, &st->to)->term);
	} else {
		Str(&(*gen), gen_tag, " <= ", 5);
		Expression(&(*gen), gen_tag, st->to);
	}
	if (o7c_cmp(st->by, 1) ==  0) {
		Str(&(*gen), gen_tag, "; ++", 5);
		GlobalName(&(*gen), gen_tag, &st->var_->_);
	} else {
		Str(&(*gen), gen_tag, "; ", 3);
		GlobalName(&(*gen), gen_tag, &st->var_->_);
		Str(&(*gen), gen_tag, " += ", 5);
		Int(&(*gen), gen_tag, st->by);
	}
	StrLn(&(*gen), gen_tag, ") {", 4);
	(*gen).tabs = o7c_add((*gen).tabs, 1);;
	statements(&(*gen), gen_tag, st->stats);
	Tabs(&(*gen), gen_tag,  - 1);
	StrLn(&(*gen), gen_tag, "}", 2);
	o7c_release(st);
}

static void Statement_Assign(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_Assign st) {
	struct Ast_Record_s *type = NULL, *base = NULL;
	o7c_bool reref = O7C_BOOL_UNDEF, retain = O7C_BOOL_UNDEF;

	o7c_retain(st);
	retain = (o7c_cmp(st->designator->_._.type->_._.id, Ast_IdPointer_cnst) ==  0) && (o7c_cmp((*gen).opt->memManager, GeneratorC_MemManagerCounter_cnst) ==  0);
	if (retain) {
		Str(&(*gen), gen_tag, "O7C_ASSIGN(&(", 14);
		Designator(&(*gen), gen_tag, st->designator);
		Str(&(*gen), gen_tag, "), ", 4);
	} else {
		Designator(&(*gen), gen_tag, st->designator);
		Str(&(*gen), gen_tag, " = ", 4);
	}
	reref = (o7c_cmp(st->_.expr->type->_._.id, Ast_IdPointer_cnst) ==  0) && (st->_.expr->type->_.type != st->designator->_._.type->_.type) && !(o7c_is(NULL, st->_.expr, Ast_ExprNil_s_tag));
	if (reref) {
		O7C_ASSIGN(&(base), O7C_GUARD(Ast_Record_s, &st->designator->_._.type->_.type));
		O7C_ASSIGN(&(type), O7C_GUARD(Ast_Record_s, &st->_.expr->type->_.type)->base);
		Str(&(*gen), gen_tag, "(&(", 4);
		Expression(&(*gen), gen_tag, st->_.expr);
		Str(&(*gen), gen_tag, ")->_", 5);
	} else {
		O7C_ASSIGN(&(base), NULL);
		Expression(&(*gen), gen_tag, st->_.expr);
	}
	if ((base != NULL) || (o7c_cmp(st->_.expr->type->_._.id, Ast_IdRecord_cnst) ==  0)) {
		if (base == NULL) {
			O7C_ASSIGN(&(base), O7C_GUARD(Ast_Record_s, &st->designator->_._.type));
			O7C_ASSIGN(&(type), O7C_GUARD(Ast_Record_s, &st->_.expr->type));
		}
		while (type != base) {
			Str(&(*gen), gen_tag, "._", 3);
			O7C_ASSIGN(&(type), type->base);
		}
		Log_StrLn("Assign record", 14);
	}
	{ int o7c_case_expr = o7c_add((int)reref, (int)retain);
		switch (o7c_case_expr) {
		case 0:
			StrLn(&(*gen), gen_tag, ";", 2);
			break;
		case 1:
			StrLn(&(*gen), gen_tag, ");", 3);
			break;
		case 2:
			StrLn(&(*gen), gen_tag, "));", 4);
			break;
		default:
			abort();
			break;
		}
	}
	o7c_release(type); o7c_release(base);
	o7c_release(st);
}

static void Statement_Case(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_Case st);
static void Case_Statement_CaseElement(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_CaseElement elem) {
	Ast_CaseLabel r = NULL;

	o7c_retain(elem);
	if (!IsCaseElementWithRange(elem)) {
		O7C_ASSIGN(&(r), elem->labels);
		while (r != NULL) {
			Tabs(&(*gen), gen_tag, 0);
			Str(&(*gen), gen_tag, "case ", 6);
			Int(&(*gen), gen_tag, r->value_);
			assert(r->right == NULL);
			StrLn(&(*gen), gen_tag, ":", 2);
			O7C_ASSIGN(&(r), r->next);
		}
		(*gen).tabs = o7c_add((*gen).tabs, 1);;
		statements(&(*gen), gen_tag, elem->stats);
		Tabs(&(*gen), gen_tag, 0);
		StrLn(&(*gen), gen_tag, "break;", 7);
		(*gen).tabs = o7c_sub((*gen).tabs, 1);;
	}
	o7c_release(r);
	o7c_release(elem);
}

static void Case_Statement_CaseElementAsIf(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_CaseElement elem, struct Ast_RExpression *caseExpr);
static void CaseElementAsIf_Case_Statement_CaseRange(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_CaseLabel r, struct Ast_RExpression *caseExpr) {
	o7c_retain(r); o7c_retain(caseExpr);
	if (r->right == NULL) {
		if (caseExpr == NULL) {
			Str(&(*gen), gen_tag, "(o7c_case_expr == ", 19);
		} else {
			Str(&(*gen), gen_tag, "(", 2);
			Expression(&(*gen), gen_tag, caseExpr);
			Str(&(*gen), gen_tag, " == ", 5);
		}
		Int(&(*gen), gen_tag, r->value_);
	} else {
		assert(o7c_cmp(r->value_, r->right->value_) <=  0);
		Str(&(*gen), gen_tag, "(", 2);
		Int(&(*gen), gen_tag, r->value_);
		if (caseExpr == NULL) {
			Str(&(*gen), gen_tag, " <= o7c_case_expr && o7c_case_expr <= ", 39);
		} else {
			Str(&(*gen), gen_tag, " <= ", 5);
			Expression(&(*gen), gen_tag, caseExpr);
			Str(&(*gen), gen_tag, " && ", 5);
			Expression(&(*gen), gen_tag, caseExpr);
			Str(&(*gen), gen_tag, " <= ", 5);
		}
		Int(&(*gen), gen_tag, r->right->value_);
	}
	Str(&(*gen), gen_tag, ")", 2);
	o7c_release(r); o7c_release(caseExpr);
}

static void Case_Statement_CaseElementAsIf(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_CaseElement elem, struct Ast_RExpression *caseExpr) {
	Ast_CaseLabel r = NULL;

	o7c_retain(elem); o7c_retain(caseExpr);
	Str(&(*gen), gen_tag, "if (", 5);
	O7C_ASSIGN(&(r), elem->labels);
	assert(r != NULL);
	CaseElementAsIf_Case_Statement_CaseRange(&(*gen), gen_tag, r, caseExpr);
	while (r->next != NULL) {
		O7C_ASSIGN(&(r), r->next);
		Str(&(*gen), gen_tag, " || ", 5);
		CaseElementAsIf_Case_Statement_CaseRange(&(*gen), gen_tag, r, caseExpr);
	}
	StrLn(&(*gen), gen_tag, ") {", 4);
	(*gen).tabs = o7c_add((*gen).tabs, 1);;
	statements(&(*gen), gen_tag, elem->stats);
	Tabs(&(*gen), gen_tag,  - 1);
	Str(&(*gen), gen_tag, "}", 2);
	o7c_release(r);
	o7c_release(elem); o7c_release(caseExpr);
}

static void Statement_Case(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, Ast_Case st) {
	Ast_CaseElement elem = NULL, elemWithRange = NULL;
	struct Ast_RExpression *caseExpr = NULL;

	o7c_retain(st);
	O7C_ASSIGN(&(elemWithRange), st->elements);
	while ((elemWithRange != NULL) && !IsCaseElementWithRange(elemWithRange)) {
		O7C_ASSIGN(&(elemWithRange), elemWithRange->next);
	}
	if ((elemWithRange == NULL) && !((o7c_is(NULL, st->_.expr, Ast_RFactor_tag)) && !(o7c_is(NULL, st->_.expr, Ast_ExprBraces_s_tag)))) {
		O7C_ASSIGN(&(caseExpr), NULL);
		Str(&(*gen), gen_tag, "{ int o7c_case_expr = ", 23);
		Expression(&(*gen), gen_tag, st->_.expr);
		StrLn(&(*gen), gen_tag, ";", 2);
		Tabs(&(*gen), gen_tag,  + 1);
		StrLn(&(*gen), gen_tag, "switch (o7c_case_expr) {", 25);
	} else {
		O7C_ASSIGN(&(caseExpr), st->_.expr);
		Str(&(*gen), gen_tag, "switch (", 9);
		Expression(&(*gen), gen_tag, caseExpr);
		StrLn(&(*gen), gen_tag, ") {", 4);
	}
	O7C_ASSIGN(&(elem), st->elements);
	do {
		Case_Statement_CaseElement(&(*gen), gen_tag, elem);
		O7C_ASSIGN(&(elem), elem->next);
	} while (!(elem == NULL));
	Tabs(&(*gen), gen_tag, 0);
	StrLn(&(*gen), gen_tag, "default:", 9);
	Tabs(&(*gen), gen_tag,  + 1);
	if (elemWithRange != NULL) {
		O7C_ASSIGN(&(elem), elemWithRange);
		Case_Statement_CaseElementAsIf(&(*gen), gen_tag, elem, caseExpr);
		O7C_ASSIGN(&(elem), elem->next);
		while (elem != NULL) {
			if (IsCaseElementWithRange(elem)) {
				Str(&(*gen), gen_tag, " else ", 7);
				Case_Statement_CaseElementAsIf(&(*gen), gen_tag, elem, caseExpr);
			}
			O7C_ASSIGN(&(elem), elem->next);
		}
		if ((*gen).opt->caseAbort) {
			StrLn(&(*gen), gen_tag, " else abort();", 15);
			Tabs(&(*gen), gen_tag, 0);
		}
	} else if ((*gen).opt->caseAbort) {
		StrLn(&(*gen), gen_tag, "abort();", 9);
		Tabs(&(*gen), gen_tag, 0);
	}
	StrLn(&(*gen), gen_tag, "break;", 7);
	Tabs(&(*gen), gen_tag,  - 1);
	StrLn(&(*gen), gen_tag, "}", 2);
	if (caseExpr == NULL) {
		Tabs(&(*gen), gen_tag,  - 1);
		StrLn(&(*gen), gen_tag, "}", 2);
	}
	o7c_release(elem); o7c_release(elemWithRange); o7c_release(caseExpr);
	o7c_release(st);
}

static void Statement(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RStatement *st) {
	o7c_retain(st);
	Tabs(&(*gen), gen_tag, 0);
	if (o7c_is(NULL, st, Ast_Assign_s_tag)) {
		Statement_Assign(&(*gen), gen_tag, O7C_GUARD(Ast_Assign_s, &st));
	} else if (o7c_is(NULL, st, Ast_Call_s_tag)) {
		(*gen).expressionSemicolon = true;
		Expression(&(*gen), gen_tag, st->expr);
		if ((*gen).expressionSemicolon) {
			StrLn(&(*gen), gen_tag, ";", 2);
		} else {
			Ln(&(*gen), gen_tag);
		}
	} else if (o7c_is(NULL, st, Ast_RWhileIf_tag)) {
		Statement_WhileIf(&(*gen), gen_tag, O7C_GUARD(Ast_RWhileIf, &st));
	} else if (o7c_is(NULL, st, Ast_Repeat_s_tag)) {
		Statement_Repeat(&(*gen), gen_tag, O7C_GUARD(Ast_Repeat_s, &st));
	} else if (o7c_is(NULL, st, Ast_For_s_tag)) {
		Statement_For(&(*gen), gen_tag, O7C_GUARD(Ast_For_s, &st));
	} else if (o7c_is(NULL, st, Ast_Case_s_tag)) {
		Statement_Case(&(*gen), gen_tag, O7C_GUARD(Ast_Case_s, &st));
	} else {
		assert(false);
	}
	o7c_release(st);
}

static void Statements(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RStatement *stats) {
	o7c_retain(stats);
	while (stats != NULL) {
		Statement(&(*gen), gen_tag, stats);
		O7C_ASSIGN(&(stats), stats->next);
	}
	o7c_release(stats);
}

static void ProcDecl(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RProcedure *proc) {
	o7c_retain(proc);
	Tabs(&(*gen), gen_tag, 0);
	if (o7c_bl(proc->_._._.mark) && !(*gen).opt->main_) {
		Str(&(*gen), gen_tag, "extern ", 8);
	} else {
		Str(&(*gen), gen_tag, "static ", 8);
	}
	Declarator(&(*gen), gen_tag, &proc->_._._, false, false, true);
	StrLn(&(*gen), gen_tag, ";", 2);
	o7c_release(proc);
}

static void Qualifier(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RType *type) {
	o7c_retain(type);
	switch (type->_._.id) {
	case 0:
		Str(&(*gen), gen_tag, "int", 4);
		break;
	case 5:
		Str(&(*gen), gen_tag, "unsigned", 9);
		break;
	case 1:
		if ((o7c_cmp((*gen).opt->std, GeneratorC_IsoC99_cnst) >=  0) && (o7c_cmp((*gen).opt->varInit, GeneratorC_VarInitUndefined_cnst) !=  0)) {
			Str(&(*gen), gen_tag, "bool", 5);
		} else {
			Str(&(*gen), gen_tag, "o7c_bool", 9);
		}
		break;
	case 2:
		Str(&(*gen), gen_tag, "char unsigned", 14);
		break;
	case 3:
		Str(&(*gen), gen_tag, "o7c_char", 9);
		break;
	case 4:
		Str(&(*gen), gen_tag, "double", 7);
		break;
	case 6:
	case 10:
		GlobalName(&(*gen), gen_tag, &type->_);
		break;
	default:
		abort();
		break;
	}
	o7c_release(type);
}

static void Procedure(struct MOut *out, o7c_tag_t out_tag, struct Ast_RProcedure *proc);
static void Procedure_Implement(struct MOut *out, o7c_tag_t out_tag, struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RProcedure *proc);
static void Implement_Procedure_CloseConsts(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *consts) {
	o7c_retain(consts);
	while ((consts != NULL) && (o7c_is(NULL, consts, Ast_Const_s_tag))) {
		Str(&(*gen), gen_tag, "#undef ", 8);
		Name(&(*gen), gen_tag, consts);
		Ln(&(*gen), gen_tag);
		O7C_ASSIGN(&(consts), consts->next);
	}
	o7c_release(consts);
}

static struct Ast_RDeclaration *Implement_Procedure_SearchRetain(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *fp) {
	Ast_Declaration o7c_return = NULL;

	o7c_retain(fp);
	while ((fp != NULL) && ((o7c_cmp(fp->type->_._.id, Ast_IdPointer_cnst) !=  0) || o7c_bl(O7C_GUARD(Ast_FormalParam_s, &fp)->isVar))) {
		O7C_ASSIGN(&(fp), fp->next);
	}
	O7C_ASSIGN(&o7c_return, fp);
	o7c_release(fp);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static void Implement_Procedure_RetainParams(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *fp) {
	o7c_retain(fp);
	if (fp != NULL) {
		Tabs(&(*gen), gen_tag, 0);
		Str(&(*gen), gen_tag, "o7c_retain(", 12);
		Name(&(*gen), gen_tag, fp);
		O7C_ASSIGN(&(fp), fp->next);
		while (fp != NULL) {
			if ((o7c_cmp(fp->type->_._.id, Ast_IdPointer_cnst) ==  0) && !O7C_GUARD(Ast_FormalParam_s, &fp)->isVar) {
				Str(&(*gen), gen_tag, "); o7c_retain(", 15);
				Name(&(*gen), gen_tag, fp);
			}
			O7C_ASSIGN(&(fp), fp->next);
		}
		StrLn(&(*gen), gen_tag, ");", 3);
	}
	o7c_release(fp);
}

static void Implement_Procedure_ReleaseParams(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *fp) {
	o7c_retain(fp);
	if (fp != NULL) {
		Tabs(&(*gen), gen_tag, 0);
		Str(&(*gen), gen_tag, "o7c_release(", 13);
		Name(&(*gen), gen_tag, fp);
		O7C_ASSIGN(&(fp), fp->next);
		while (fp != NULL) {
			if ((o7c_cmp(fp->type->_._.id, Ast_IdPointer_cnst) ==  0) && !O7C_GUARD(Ast_FormalParam_s, &fp)->isVar) {
				Str(&(*gen), gen_tag, "); o7c_release(", 16);
				Name(&(*gen), gen_tag, fp);
			}
			O7C_ASSIGN(&(fp), fp->next);
		}
		StrLn(&(*gen), gen_tag, ");", 3);
	}
	o7c_release(fp);
}

static void Implement_Procedure_ReleaseVars(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *var_) {
	o7c_bool first = O7C_BOOL_UNDEF;

	o7c_retain(var_);
	first = true;
	while ((var_ != NULL) && (o7c_is(NULL, var_, Ast_RVar_tag))) {
		if (o7c_cmp(var_->type->_._.id, Ast_IdPointer_cnst) ==  0) {
			if (first) {
				first = false;
				Tabs(&(*gen), gen_tag, 0);
				Str(&(*gen), gen_tag, "o7c_release(", 13);
			} else {
				Str(&(*gen), gen_tag, "); o7c_release(", 16);
			}
			Name(&(*gen), gen_tag, var_);
		}
		O7C_ASSIGN(&(var_), var_->next);
	}
	if (!first) {
		StrLn(&(*gen), gen_tag, ");", 3);
	}
	o7c_release(var_);
}

static void Procedure_Implement(struct MOut *out, o7c_tag_t out_tag, struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RProcedure *proc) {
	struct Ast_RDeclaration *retainParams = NULL;

	o7c_retain(proc);
	Tabs(&(*gen), gen_tag, 0);
	Mark(&(*gen), gen_tag, proc->_._._.mark);
	Declarator(&(*gen), gen_tag, &proc->_._._, false, false, true);
	StrLn(&(*gen), gen_tag, " {", 3);
	(*gen).localDeep = o7c_add((*gen).localDeep, 1);;
	(*gen).tabs = o7c_add((*gen).tabs, 1);;
	(*gen).fixedLen = (*gen).len;
	if (o7c_cmp((*gen).opt->memManager, GeneratorC_MemManagerCounter_cnst) !=  0) {
		O7C_ASSIGN(&(retainParams), NULL);
	} else {
		O7C_ASSIGN(&(retainParams), Implement_Procedure_SearchRetain(&(*gen), gen_tag, &proc->_.header->params->_._));
		if (proc->_.return_ != NULL) {
			Tabs(&(*gen), gen_tag, 0);
			Qualifier(&(*gen), gen_tag, proc->_.return_->type);
			if (o7c_cmp(proc->_.return_->type->_._.id, Ast_IdPointer_cnst) ==  0) {
				StrLn(&(*gen), gen_tag, " o7c_return = NULL;", 20);
			} else {
				StrLn(&(*gen), gen_tag, " o7c_return;", 13);
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
		Tabs(&(*gen), gen_tag, 0);
		if ((o7c_cmp((*gen).opt->memManager, GeneratorC_MemManagerCounter_cnst) ==  0) && (proc->_.return_ != NULL)) {
			if (o7c_cmp(proc->_.return_->type->_._.id, Ast_IdPointer_cnst) ==  0) {
				Str(&(*gen), gen_tag, "O7C_ASSIGN(&o7c_return, ", 25);
				CheckExpr(&(*gen), gen_tag, proc->_.return_);
				StrLn(&(*gen), gen_tag, ");", 3);
			} else {
				Str(&(*gen), gen_tag, "o7c_return = ", 14);
				CheckExpr(&(*gen), gen_tag, proc->_.return_);
				StrLn(&(*gen), gen_tag, ";", 2);
			}
			Implement_Procedure_ReleaseVars(&(*gen), gen_tag, &proc->_._.vars->_);
			Implement_Procedure_ReleaseParams(&(*gen), gen_tag, retainParams);
			if (o7c_cmp(proc->_.return_->type->_._.id, Ast_IdPointer_cnst) ==  0) {
				Tabs(&(*gen), gen_tag, 0);
				StrLn(&(*gen), gen_tag, "o7c_unhold(o7c_return);", 24);
			}
			Tabs(&(*gen), gen_tag, 0);
			StrLn(&(*gen), gen_tag, "return o7c_return;", 19);
		} else {
			Implement_Procedure_ReleaseVars(&(*gen), gen_tag, &proc->_._.vars->_);
			Implement_Procedure_ReleaseParams(&(*gen), gen_tag, retainParams);
			Str(&(*gen), gen_tag, "return ", 8);
			CheckExpr(&(*gen), gen_tag, proc->_.return_);
			StrLn(&(*gen), gen_tag, ";", 2);
		}
	}
	(*gen).localDeep = o7c_sub((*gen).localDeep, 1);;
	Implement_Procedure_CloseConsts(&(*gen), gen_tag, proc->_._.start);
	Tabs(&(*gen), gen_tag,  - 1);
	StrLn(&(*gen), gen_tag, "}", 2);
	Ln(&(*gen), gen_tag);
	o7c_release(retainParams);
	o7c_release(proc);
}

static void Procedure_LocalProcs(struct MOut *out, o7c_tag_t out_tag, struct Ast_RProcedure *proc) {
	struct Ast_RDeclaration *p = NULL, *t = NULL;

	o7c_retain(proc);
	O7C_ASSIGN(&(t), (&(proc->_._.types)->_));
	while ((t != NULL) && (o7c_is(NULL, t, Ast_RType_tag))) {
		TypeDecl(&(*out), out_tag, O7C_GUARD(Ast_RType, &t));
		O7C_ASSIGN(&(t), t->next);
	}
	O7C_ASSIGN(&(p), (&(proc->_._.procedures)->_._._));
	if (p != NULL) {
		if (!o7c_bl(proc->_._._.mark) && !(*out).opt->procLocal) {
			ProcDecl(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, proc);
		}
		do {
			Procedure(&(*out), out_tag, O7C_GUARD(Ast_RProcedure, &p));
			O7C_ASSIGN(&(p), p->next);
		} while (!(p == NULL));
	}
	o7c_release(p); o7c_release(t);
	o7c_release(proc);
}

static void Procedure(struct MOut *out, o7c_tag_t out_tag, struct Ast_RProcedure *proc) {
	o7c_retain(proc);
	Procedure_LocalProcs(&(*out), out_tag, proc);
	if (o7c_bl(proc->_._._.mark) && !(*out).opt->main_) {
		ProcDecl(&(*out).g[Interface_cnst], GeneratorC_Generator_tag, proc);
	}
	Procedure_Implement(&(*out), out_tag, &(*out).g[Implementation_cnst], GeneratorC_Generator_tag, proc);
	o7c_release(proc);
}

static void LnIfWrote(struct MOut *out, o7c_tag_t out_tag);
static void LnIfWrote_Write(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag) {
	if (o7c_cmp((*gen).fixedLen, (*gen).len) !=  0) {
		Ln(&(*gen), gen_tag);
		(*gen).fixedLen = (*gen).len;
	}
}

static void LnIfWrote(struct MOut *out, o7c_tag_t out_tag) {
	LnIfWrote_Write(&(*out).g[Interface_cnst], GeneratorC_Generator_tag);
	LnIfWrote_Write(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag);
}

static void VarsInit(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *d);
static o7c_bool VarsInit_IsConformArrayType(struct Ast_RType *type, int *id, int *deep) {
	o7c_bool o7c_return;

	o7c_retain(type);
	(*deep) = 0;
	while (o7c_cmp(type->_._.id, Ast_IdArray_cnst) ==  0) {
		(*deep) = o7c_add((*deep), 1);;
		O7C_ASSIGN(&(type), type->_.type);
	}
	(*id) = type->_._.id;
	o7c_return = !!( (1u << (*id)) & ((1 << Ast_IdReal_cnst) | (1 << Ast_IdInteger_cnst) | (1 << Ast_IdBoolean_cnst)));
	o7c_release(type);
	return o7c_return;
}

static void VarsInit(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *d) {
	int arrDeep = O7C_INT_UNDEF, arrTypeId = O7C_INT_UNDEF, i = O7C_INT_UNDEF;

	o7c_retain(d);
	while ((d != NULL) && (o7c_is(NULL, d, Ast_RVar_tag))) {
		if (!!( (1u << d->type->_._.id) & ((1 << Ast_IdArray_cnst) | (1 << Ast_IdRecord_cnst)))) {
			Tabs(&(*gen), gen_tag, 0);
			if ((o7c_cmp((*gen).opt->varInit, GeneratorC_VarInitZero_cnst) ==  0) || (o7c_cmp(d->type->_._.id, Ast_IdRecord_cnst) ==  0) || (o7c_cmp(d->type->_._.id, Ast_IdArray_cnst) ==  0) && !VarsInit_IsConformArrayType(d->type, &arrTypeId, &arrDeep)) {
				Str(&(*gen), gen_tag, "memset(&", 9);
				Name(&(*gen), gen_tag, d);
				Str(&(*gen), gen_tag, ", 0, sizeof(", 13);
				Name(&(*gen), gen_tag, d);
				StrLn(&(*gen), gen_tag, "));", 4);
			} else {
				assert(o7c_cmp((*gen).opt->varInit, GeneratorC_VarInitUndefined_cnst) ==  0);
				switch (arrTypeId) {
				case 0:
					Str(&(*gen), gen_tag, "o7c_ints_undef(", 16);
					break;
				case 4:
					Str(&(*gen), gen_tag, "o7c_doubles_undef(", 19);
					break;
				case 1:
					Str(&(*gen), gen_tag, "o7c_bools_undef(", 17);
					break;
				default:
					abort();
					break;
				}
				Name(&(*gen), gen_tag, d);
				for (i = 2; i <= arrDeep; ++i) {
					Str(&(*gen), gen_tag, "[0]", 4);
				}
				Str(&(*gen), gen_tag, ", sizeof(", 10);
				Name(&(*gen), gen_tag, d);
				Str(&(*gen), gen_tag, ") / sizeof(", 12);
				Name(&(*gen), gen_tag, d);
				for (i = 2; i <= arrDeep; ++i) {
					Str(&(*gen), gen_tag, "[0]", 4);
				}
				StrLn(&(*gen), gen_tag, "[0]));", 7);
			}
		}
		O7C_ASSIGN(&(d), d->next);
	}
	o7c_release(d);
}

static void Declarations(struct MOut *out, o7c_tag_t out_tag, struct Ast_RDeclarations *ds) {
	struct Ast_RDeclaration *d = NULL, *prev = NULL;

	o7c_retain(ds);
	O7C_ASSIGN(&(d), ds->start);
	assert((d == NULL) || !(o7c_is(NULL, d, Ast_RModule_tag)));
	while ((d != NULL) && (o7c_is(NULL, d, Ast_Import_s_tag))) {
		Import(&(*out).g[o7c_ind(2, (int)!(*out).opt->main_)], GeneratorC_Generator_tag, d);
		O7C_ASSIGN(&(d), d->next);
	}
	LnIfWrote(&(*out), out_tag);
	while ((d != NULL) && (o7c_is(NULL, d, Ast_Const_s_tag))) {
		Const(&(*out).g[o7c_ind(2, (int)(o7c_bl(d->mark) && !(*out).opt->main_))], GeneratorC_Generator_tag, O7C_GUARD(Ast_Const_s, &d));
		O7C_ASSIGN(&(d), d->next);
	}
	LnIfWrote(&(*out), out_tag);
	if (o7c_is(NULL, ds, Ast_RModule_tag)) {
		while ((d != NULL) && (o7c_is(NULL, d, Ast_RType_tag))) {
			TypeDecl(&(*out), out_tag, O7C_GUARD(Ast_RType, &d));
			O7C_ASSIGN(&(d), d->next);
		}
		LnIfWrote(&(*out), out_tag);
		while ((d != NULL) && (o7c_is(NULL, d, Ast_RVar_tag))) {
			Var(&(*out), out_tag, NULL, d, true);
			O7C_ASSIGN(&(d), d->next);
		}
	} else {
		O7C_ASSIGN(&(d), (&(ds->vars)->_));
		O7C_ASSIGN(&(prev), NULL);
		while ((d != NULL) && (o7c_is(NULL, d, Ast_RVar_tag))) {
			Var(&(*out), out_tag, prev, d, (d->next == NULL) || !(o7c_is(NULL, d->next, Ast_RVar_tag)));
			O7C_ASSIGN(&(prev), d);
			O7C_ASSIGN(&(d), d->next);
		}
		if (o7c_cmp((*out).opt->varInit, GeneratorC_VarInitNo_cnst) !=  0) {
			VarsInit(&(*out).g[Implementation_cnst], GeneratorC_Generator_tag, &ds->vars->_);
		}
	}
	LnIfWrote(&(*out), out_tag);
	if (o7c_bl((*out).opt->procLocal) || (o7c_is(NULL, ds, Ast_RModule_tag))) {
		while (d != NULL) {
			Procedure(&(*out), out_tag, O7C_GUARD(Ast_RProcedure, &d));
			O7C_ASSIGN(&(d), d->next);
		}
	}
	o7c_release(d); o7c_release(prev);
	o7c_release(ds);
}

extern struct GeneratorC_Options_s *GeneratorC_DefaultOptions(void) {
	GeneratorC_Options o7c_return = NULL;

	struct GeneratorC_Options_s *o = NULL;

	o = o7c_new(sizeof(*o), GeneratorC_Options_s_tag);
	V_Init(&(*o)._, GeneratorC_Options_s_tag);
	if (o != NULL) {
		o->std = GeneratorC_IsoC99_cnst;
		o->gnu = false;
		o->procLocal = false;
		o->checkIndex = true;
		o->checkArith = true;
		o->caseAbort = true;
		o->varInit = GeneratorC_VarInitUndefined_cnst;
		o->memManager = GeneratorC_MemManagerCounter_cnst;
		o->main_ = false;
	}
	O7C_ASSIGN(&o7c_return, o);
	o7c_release(o);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern void GeneratorC_Init(struct GeneratorC_Generator *g, o7c_tag_t g_tag, struct VDataStream_Out *out) {
	o7c_retain(out);
	V_Init(&(*g)._, g_tag);
	O7C_ASSIGN(&((*g).out), out);
	o7c_release(out);
}

static void MarkExpression(struct Ast_RExpression *e) {
	o7c_retain(e);
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
	o7c_release(e);
}

static void MarkType(struct Ast_RType *t) {
	struct Ast_RDeclaration *d = NULL;

	o7c_retain(t);
	Log_StrLn("MarkType !!!!", 14);
	while ((t != NULL) && !t->_.mark) {
		t->_.mark = true;
		if (o7c_cmp(t->_._.id, Ast_IdArray_cnst) ==  0) {
			MarkExpression(O7C_GUARD(Ast_RArray, &t)->count);
			O7C_ASSIGN(&(t), t->_.type);
		} else if (!!( (1u << t->_._.id) & ((1 << Ast_IdRecord_cnst) | (1 << Ast_IdPointer_cnst)))) {
			if (o7c_cmp(t->_._.id, Ast_IdPointer_cnst) ==  0) {
				O7C_ASSIGN(&(t), t->_.type);
				t->_.mark = true;
				assert(t->_.module != NULL);
			}
			O7C_ASSIGN(&(d), (&(O7C_GUARD(Ast_Record_s, &t)->vars)->_));
			while (d != NULL) {
				MarkType(d->type);
				if (d->name.block != NULL) {
					Log_StrLn(d->name.block->s, StringStore_BlockSize_cnst + 1);
				}
				O7C_ASSIGN(&(d), d->next);
			}
			O7C_ASSIGN(&(t), (&(O7C_GUARD(Ast_Record_s, &t)->base)->_._));
		} else {
			O7C_ASSIGN(&(t), NULL);
		}
	}
	o7c_release(d);
	o7c_release(t);
}

static void MarkUsedInMarked(struct Ast_RModule *m);
static void MarkUsedInMarked_Consts(struct Ast_Const_s *c) {
	o7c_retain(c);
	while (c != NULL) {
		if (c->_.mark) {
			MarkExpression(c->expr);
		}
		if ((c->_.next != NULL) && (o7c_is(NULL, c->_.next, Ast_Const_s_tag))) {
			O7C_ASSIGN(&(c), O7C_GUARD(Ast_Const_s, &c->_.next));
		} else {
			O7C_ASSIGN(&(c), NULL);
		}
	}
	o7c_release(c);
}

static void MarkUsedInMarked_Types(struct Ast_RDeclaration *t) {
	o7c_retain(t);
	while ((t != NULL) && (o7c_is(NULL, t, Ast_RType_tag))) {
		if (t->mark) {
			t->mark = false;
			MarkType(O7C_GUARD(Ast_RType, &t));
		}
		O7C_ASSIGN(&(t), t->next);
	}
	o7c_release(t);
}

static void MarkUsedInMarked(struct Ast_RModule *m) {
	struct Ast_RDeclaration *imp = NULL;

	o7c_retain(m);
	O7C_ASSIGN(&(imp), (&(m->import_)->_));
	while ((imp != NULL) && (o7c_is(NULL, imp, Ast_Import_s_tag))) {
		MarkUsedInMarked(imp->module);
		O7C_ASSIGN(&(imp), imp->next);
	}
	MarkUsedInMarked_Consts(m->_.consts);
	MarkUsedInMarked_Types(&m->_.types->_);
	o7c_release(imp);
	o7c_release(m);
}

static void ImportInit(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RDeclaration *imp) {
	o7c_retain(imp);
	if (imp != NULL) {
		assert(o7c_is(NULL, imp, Ast_Import_s_tag));
		do {
			Tabs(&(*gen), gen_tag, 0);
			String(&(*gen), gen_tag, &imp->module->_._.name, StringStore_String_tag);
			StrLn(&(*gen), gen_tag, "_init();", 9);
			O7C_ASSIGN(&(imp), imp->next);
		} while (!((imp == NULL) || !(o7c_is(NULL, imp, Ast_Import_s_tag))));
		Ln(&(*gen), gen_tag);
	}
	o7c_release(imp);
}

static void TagsInit(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag) {
	struct Ast_Record_s *r = NULL;

	O7C_ASSIGN(&(r), NULL);
	while ((*gen).opt->records != NULL) {
		O7C_ASSIGN(&(r), O7C_GUARD(Ast_Record_s, &(*gen).opt->records));
		O7C_ASSIGN(&((*gen).opt->records), r->_._._._.ext);
		O7C_ASSIGN(&(r->_._._._.ext), NULL);
		Tabs(&(*gen), gen_tag, 0);
		Str(&(*gen), gen_tag, "o7c_tag_init(", 14);
		GlobalName(&(*gen), gen_tag, &r->_._._);
		if (r->base == NULL) {
			StrLn(&(*gen), gen_tag, "_tag, NULL);", 13);
		} else {
			Str(&(*gen), gen_tag, "_tag, ", 7);
			GlobalName(&(*gen), gen_tag, &r->base->_._._);
			StrLn(&(*gen), gen_tag, "_tag);", 7);
		}
	}
	if (r != NULL) {
		Ln(&(*gen), gen_tag);
	}
	o7c_release(r);
}

static void Generate_Init(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct VDataStream_Out *out, struct Ast_RModule *module, struct GeneratorC_Options_s *opt) {
	o7c_retain(out); o7c_retain(module); o7c_retain(opt);
	O7C_ASSIGN(&((*gen).out), out);
	(*gen).len = 0;
	O7C_ASSIGN(&((*gen).module), module);
	(*gen).tabs = 0;
	(*gen).localDeep = 0;
	O7C_ASSIGN(&(opt->records), NULL);
	O7C_ASSIGN(&(opt->recordLast), NULL);
	O7C_ASSIGN(&((*gen).opt), opt);
	if (!(*gen).interface_) {
		StrLn(&(*gen), gen_tag, "#include <stdlib.h>", 20);
		StrLn(&(*gen), gen_tag, "#include <stddef.h>", 20);
		StrLn(&(*gen), gen_tag, "#include <string.h>", 20);
		StrLn(&(*gen), gen_tag, "#include <assert.h>", 20);
		StrLn(&(*gen), gen_tag, "#include <math.h>", 18);
		if (o7c_cmp(opt->std, GeneratorC_IsoC99_cnst) >=  0) {
			StrLn(&(*gen), gen_tag, "#include <stdbool.h>", 21);
		}
		Ln(&(*gen), gen_tag);
		if (o7c_cmp(opt->varInit, GeneratorC_VarInitUndefined_cnst) ==  0) {
			StrLn(&(*gen), gen_tag, "#define O7C_BOOL_UNDEFINED", 27);
		}
		StrLn(&(*gen), gen_tag, "#include <o7c.h>", 17);
		Ln(&(*gen), gen_tag);
	}
	(*gen).fixedLen = (*gen).len;
	o7c_release(out); o7c_release(module); o7c_release(opt);
}

static void Generate_HeaderGuard(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag) {
	Str(&(*gen), gen_tag, "#if !defined(HEADER_GUARD_", 27);
	String(&(*gen), gen_tag, &(*gen).module->_._.name, StringStore_String_tag);
	StrLn(&(*gen), gen_tag, ")", 2);
	Str(&(*gen), gen_tag, "#define HEADER_GUARD_", 22);
	String(&(*gen), gen_tag, &(*gen).module->_._.name, StringStore_String_tag);
	Ln(&(*gen), gen_tag);
	Ln(&(*gen), gen_tag);
}

static void Generate_ModuleInit(struct GeneratorC_Generator *interf, o7c_tag_t interf_tag, struct GeneratorC_Generator *impl, o7c_tag_t impl_tag, struct Ast_RModule *module) {
	o7c_retain(module);
	if ((module->import_ == NULL) && (module->_.stats == NULL) && ((*impl).opt->records == NULL)) {
		if (o7c_cmp((*impl).opt->std, GeneratorC_IsoC99_cnst) >=  0) {
			Str(&(*interf), interf_tag, "static inline void ", 20);
		} else {
			Str(&(*interf), interf_tag, "static void ", 13);
		}
		Name(&(*interf), interf_tag, &module->_._);
		StrLn(&(*interf), interf_tag, "_init(void) { ; }", 18);
	} else {
		Str(&(*interf), interf_tag, "extern void ", 13);
		Name(&(*interf), interf_tag, &module->_._);
		StrLn(&(*interf), interf_tag, "_init(void);", 13);
		Str(&(*impl), impl_tag, "extern void ", 13);
		Name(&(*impl), impl_tag, &module->_._);
		StrLn(&(*impl), impl_tag, "_init(void) {", 14);
		Tabs(&(*impl), impl_tag,  + 1);
		StrLn(&(*impl), impl_tag, "static int initialized = 0;", 28);
		Tabs(&(*impl), impl_tag, 0);
		StrLn(&(*impl), impl_tag, "if (0 == initialized) {", 24);
		(*impl).tabs = o7c_add((*impl).tabs, 1);;
		ImportInit(&(*impl), impl_tag, &module->import_->_);
		TagsInit(&(*impl), impl_tag);
		Statements(&(*impl), impl_tag, module->_.stats);
		Tabs(&(*impl), impl_tag,  - 1);
		StrLn(&(*impl), impl_tag, "}", 2);
		Tabs(&(*impl), impl_tag, 0);
		StrLn(&(*impl), impl_tag, "++initialized;", 15);
		Tabs(&(*impl), impl_tag,  - 1);
		StrLn(&(*impl), impl_tag, "}", 2);
		Ln(&(*impl), impl_tag);
	}
	o7c_release(module);
}

static void Generate_Main(struct GeneratorC_Generator *gen, o7c_tag_t gen_tag, struct Ast_RModule *module) {
	o7c_retain(module);
	StrLn(&(*gen), gen_tag, "extern int main(int argc, char **argv) {", 41);
	Tabs(&(*gen), gen_tag,  + 1);
	StrLn(&(*gen), gen_tag, "o7c_init(argc, argv);", 22);
	ImportInit(&(*gen), gen_tag, &module->import_->_);
	TagsInit(&(*gen), gen_tag);
	if (module->_.stats != NULL) {
		Statements(&(*gen), gen_tag, module->_.stats);
	}
	Tabs(&(*gen), gen_tag, 0);
	StrLn(&(*gen), gen_tag, "return o7c_exit_code;", 22);
	Tabs(&(*gen), gen_tag,  - 1);
	StrLn(&(*gen), gen_tag, "}", 2);
	o7c_release(module);
}

extern void GeneratorC_Generate(struct GeneratorC_Generator *interface_, o7c_tag_t interface__tag, struct GeneratorC_Generator *implementation, o7c_tag_t implementation_tag, struct Ast_RModule *module, struct GeneratorC_Options_s *opt) {
	struct MOut out /* record init */;
	memset(&out, 0, sizeof(out));

	o7c_retain(module); o7c_retain(opt);
	assert(!Ast_HasError(module));
	if (opt == NULL) {
		O7C_ASSIGN(&(opt), GeneratorC_DefaultOptions());
	}
	opt->main_ = (*interface_).out == NULL;
	if (!opt->main_) {
		MarkUsedInMarked(module);
	}
	O7C_ASSIGN(&(out.opt), opt);
	out.g[Interface_cnst].interface_ = true;
	Generate_Init(&out.g[Interface_cnst], GeneratorC_Generator_tag, (*interface_).out, module, opt);
	opt->index = 0;
	out.g[Implementation_cnst].interface_ = false;
	Generate_Init(&out.g[Implementation_cnst], GeneratorC_Generator_tag, (*implementation).out, module, opt);
	if (!opt->main_) {
		Generate_HeaderGuard(&out.g[Interface_cnst], GeneratorC_Generator_tag);
		Import(&out.g[Implementation_cnst], GeneratorC_Generator_tag, &module->_._);
	}
	Declarations(&out, MOut_tag, &module->_);
	if (opt->main_) {
		Generate_Main(&out.g[Implementation_cnst], GeneratorC_Generator_tag, module);
	} else {
		Generate_ModuleInit(&out.g[Interface_cnst], GeneratorC_Generator_tag, &out.g[Implementation_cnst], GeneratorC_Generator_tag, module);
		StrLn(&out.g[Interface_cnst], GeneratorC_Generator_tag, "#endif", 7);
	}
	(*interface_).len = out.g[Interface_cnst].len;
	(*implementation).len = out.g[Implementation_cnst].len;
	o7c_release(module); o7c_release(opt);
}

extern void GeneratorC_init(void) {
	static int initialized = 0;
	if (0 == initialized) {
		V_init();
		Ast_init();
		StringStore_init();
		Scanner_init();
		VDataStream_init();
		Utf8_init();
		Log_init();
		TranslatorLimits_init();

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
	++initialized;
}


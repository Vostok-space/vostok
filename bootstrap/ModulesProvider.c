#define O7_BOOL_UNDEFINED
#include <o7.h>

#include "ModulesProvider.h"

o7_tag_t ModulesProvider_Provider__s_tag;
extern void ModulesProvider_Provider__s_undef(struct ModulesProvider_Provider__s *r) {
	Ast_RProvider_undef(&r->_);
	Parser_Options_undef(&r->opt);
	memset(&r->path, 0, sizeof(r->path));
	r->sing = 0u;
	memset(&r->expectName, 0, sizeof(r->expectName));
	r->nameLen = O7_INT_UNDEF;
	r->nameOk = O7_BOOL_UNDEF;
	r->firstNotOk = O7_BOOL_UNDEF;
}

static struct Ast_RModule *GetModule(struct Ast_RProvider *p, struct Ast_RModule *host, o7_int_t name_len0, o7_char name[/*len0*/], o7_int_t ofs, o7_int_t end);
static struct Ast_RModule *GetModule_Search(struct ModulesProvider_Provider__s *p, o7_int_t name_len0, o7_char name[/*len0*/], o7_int_t ofs, o7_int_t end, o7_int_t ext_len0, o7_char ext[/*len0*/], o7_int_t *pathInd);
static struct VFileStream_RIn *GetModule_Search_Open(struct ModulesProvider_Provider__s *p, o7_int_t *pathOfs, o7_int_t name_len0, o7_char name[/*len0*/], o7_int_t ofs, o7_int_t end, o7_int_t ext_len0, o7_char ext[/*len0*/]) {
	o7_char n[1024];
	o7_int_t len, l;
	struct VFileStream_RIn *in_;
	memset(&n, 0, sizeof(n));

	len = StringStore_CalcLen(4096, O7_REF(p)->path, (*pathOfs));
	l = 0;
	if ((0 < len) && StringStore_CopyChars(1024, n, &l, 4096, O7_REF(p)->path, (*pathOfs), o7_add((*pathOfs), len)) && StringStore_CopyCharsNull(1024, n, &l, 1, PlatformExec_dirSep) && StringStore_CopyChars(1024, n, &l, name_len0, name, ofs, end) && StringStore_CopyCharsNull(1024, n, &l, ext_len0, ext)) {
		Log_Str(5, (o7_char *)"Open ");
		Log_StrLn(1024, n);
		in_ = VFileStream_OpenIn(1024, n);
	} else {
		in_ = NULL;
	}
	(*pathOfs) = o7_add(o7_add((*pathOfs), len), 1);
	return in_;
}

static struct Ast_RModule *GetModule_Search(struct ModulesProvider_Provider__s *p, o7_int_t name_len0, o7_char name[/*len0*/], o7_int_t ofs, o7_int_t end, o7_int_t ext_len0, o7_char ext[/*len0*/], o7_int_t *pathInd) {
	o7_int_t pathOfs;
	struct VFileStream_RIn *source;
	struct Ast_RModule *m;

	(*pathInd) =  - 1;
	pathOfs = 0;
	do {
		source = GetModule_Search_Open(p, &pathOfs, name_len0, name, ofs, end, ext_len0, ext);
		if (source != NULL) {
			m = Parser_Parse(&source->_, &O7_REF(p)->opt);
			VFileStream_CloseIn(&source);
			if ((m != NULL) && (O7_REF(m)->errors == NULL) && !o7_bl(O7_REF(p)->nameOk)) {
				m = NULL;
			}
		} else {
			m = NULL;
		}
		(*pathInd) = o7_add((*pathInd), 1);
	} while (!((m != NULL) || (O7_REF(p)->path[o7_ind(4096, pathOfs)] == 0x00u)));
	return m;
}

static struct Ast_RModule *GetModule(struct Ast_RProvider *p, struct Ast_RModule *host, o7_int_t name_len0, o7_char name[/*len0*/], o7_int_t ofs, o7_int_t end) {
	struct Ast_RModule *m;
	struct ModulesProvider_Provider__s *mp;
	o7_int_t pathInd = O7_INT_UNDEF, i;
	o7_char ext[4][6];
	memset(&ext, 0, sizeof(ext));

	mp = O7_GUARD(ModulesProvider_Provider__s, &p);
	O7_REF(mp)->nameLen = 0;
	O7_ASSERT(StringStore_CopyChars(TranslatorLimits_LenName_cnst + 1, O7_REF(mp)->expectName, &O7_REF(mp)->nameLen, name_len0, name, ofs, end));

	memcpy(ext[0], (o7_char *)".mod", sizeof(".mod"));
	memcpy(ext[1], (o7_char *)".Mod", sizeof(".Mod"));
	memcpy(ext[2], (o7_char *)".ob07", sizeof(".ob07"));
	memcpy(ext[3], (o7_char *)".ob", sizeof(".ob"));
	i = 0;
	do {
		m = GetModule_Search(mp, name_len0, name, ofs, end, 6, ext[o7_ind(4, i)], &pathInd);
		i = o7_add(i, 1);
	} while (!((m != NULL) || (i >= O7_LEN(ext))));
	if (m != NULL) {
		if (o7_in(pathInd, O7_REF(mp)->sing)) {
			O7_REF(m)->_._.mark = (0 < 1);
		}
	} else if (o7_bl(O7_REF(mp)->firstNotOk)) {
		O7_REF(mp)->firstNotOk = (0 > 1);
		/* TODO */
		Message_Text(37, (o7_char *)"Can not found or open file of module ");
		Out_String(TranslatorLimits_LenName_cnst + 1, O7_REF(mp)->expectName);
		Out_Ln();
	}
	return m;
}

static o7_bool RegModule(struct Ast_RProvider *p, struct Ast_RModule *m);
static o7_bool RegModule_Reg(struct ModulesProvider_Provider__s *p, struct Ast_RModule *m) {
	Log_Str(10, (o7_char *)"RegModule ");
	Log_Str(StringStore_BlockSize_cnst + 1, O7_REF(O7_REF(m)->_._.name.block)->s);
	Log_Str(3, (o7_char *)" : ");
	Log_StrLn(TranslatorLimits_LenName_cnst + 1, O7_REF(p)->expectName);
	O7_REF(p)->nameOk = o7_strcmp(StringStore_BlockSize_cnst + 1, O7_REF(O7_REF(m)->_._.name.block)->s, TranslatorLimits_LenName_cnst + 1, O7_REF(p)->expectName) == 0;
	return o7_bl(O7_REF(p)->nameOk);
}

static o7_bool RegModule(struct Ast_RProvider *p, struct Ast_RModule *m) {
	return RegModule_Reg(O7_GUARD(ModulesProvider_Provider__s, &p), m);
}

extern void ModulesProvider_New(struct ModulesProvider_Provider__s **mp, o7_int_t searchPath_len0, o7_char searchPath[/*len0*/], o7_int_t pathLen, o7_set_t definitionsInSearch) {
	o7_int_t len;

	O7_NEW(&(*mp), ModulesProvider_Provider__s);
	Ast_ProviderInit(&(*mp)->_, GetModule, RegModule);

	O7_REF((*mp))->firstNotOk = (0 < 1);
	len = 0;
	O7_ASSERT(StringStore_CopyChars(4096, O7_REF((*mp))->path, &len, searchPath_len0, searchPath, 0, pathLen));
	O7_REF((*mp))->sing = definitionsInSearch;
}

extern void ModulesProvider_SetParserOptions(struct ModulesProvider_Provider__s *p, struct Parser_Options *o) {
	O7_REF(p)->opt = (*o);
}

extern void ModulesProvider_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		Log_init();
		Out_init();
		Ast_init();
		StringStore_init();
		Parser_init();
		VFileStream_init();
		PlatformExec_init();
		Message_init();

		O7_TAG_INIT(ModulesProvider_Provider__s, Ast_RProvider);
	}
	++initialized;
}


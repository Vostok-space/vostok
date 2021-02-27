#if !defined(O7_INIT_MODEL)
#   define   O7_INIT_MODEL O7_INIT_ZERO
#endif

#include <o7.h>

#include "FileProvider.h"


#define Ext_cnst ((o7_char *)"mod;Mod;ob07;ob;obn;")

typedef struct Provider__s {
	InputProvider_R _;
	o7_char path[FileProvider_PathesMaxLen_cnst];
	o7_set_t pathForDecl;
} *Provider;
static o7_tag_t Provider__s_tag;


typedef struct Iter {
	InputProvider_Iter _;
	struct Provider__s *p;
	o7_char name[TranslatorLimits_LenName_cnst + 1];
	o7_int_t pathInd;
	o7_int_t pathOfs;
	o7_int_t extOfs;
} Iter;
static o7_tag_t Iter_tag;


static struct VDataStream_In *Next(struct V_Base *it, o7_tag_t *it_tag, o7_bool *declaration);
static struct VDataStream_In *Next_Search(struct Iter *it, o7_bool *declaration);
static struct VFileStream_RIn *Next_Search_Open(struct Iter *it, o7_bool *declaration) {
	o7_char n[1024];
	o7_int_t l, ofs;
	struct VFileStream_RIn *in_;
	memset(&n, 0, sizeof(n));

	l = 0;
	ofs = it->extOfs;
	if (Chars0X_Copy(1024, n, &l, FileProvider_PathesMaxLen_cnst, it->p->path, &it->pathOfs) && Chars0X_CopyString(1024, n, &l, 2, PlatformExec_dirSep) && Chars0X_CopyString(1024, n, &l, TranslatorLimits_LenName_cnst + 1, it->name) && Chars0X_CopyChar(1024, n, &l, (o7_char)'.') && Chars0X_CopyCharsUntil(1024, n, &l, 21, (o7_char *)"mod;Mod;ob07;ob;obn;", &ofs, (o7_char)';')) {
		Log_Str(6, (o7_char *)"Open ");
		Log_StrLn(1024, n);
		in_ = VFileStream_OpenIn(1024, n);
		*declaration = o7_in(it->pathInd, it->p->pathForDecl);
	} else {
		in_ = NULL;
	}
	it->pathOfs = o7_add(it->pathOfs, 1);
	it->pathInd = o7_add(it->pathInd, 1);
	if (it->p->path[o7_ind(FileProvider_PathesMaxLen_cnst, it->pathOfs)] == 0x00u) {
		it->extOfs = o7_add(ofs, 1);
		it->pathOfs = 0;
		it->pathInd = 0;
	}
	return in_;
}

static struct VDataStream_In *Next_Search(struct Iter *it, o7_bool *declaration) {
	struct VDataStream_In *in_;

	in_ = NULL;
	while ((in_ == NULL) && (Ext_cnst[o7_ind(21, it->extOfs)] != 0x00u)) {
		in_ = (&(Next_Search_Open(it, declaration))->_);
	}
	return in_;
}

static struct VDataStream_In *Next(struct V_Base *it, o7_tag_t *it_tag, o7_bool *declaration) {
	return Next_Search(&O7_GUARD_R(Iter, it, it_tag), declaration);
}

static struct InputProvider_Iter *GetIterator(struct InputProvider_R *p, o7_int_t name_len0, o7_char name[/*len0*/]) {
	struct Iter *it = NULL;

	O7_NEW(&it, Iter);
	if (it != NULL) {
		InputProvider_InitIter(&it->_, Next);
		it->p = O7_GUARD(Provider__s, p);
		assert(TranslatorLimits_LenName_cnst + 1 >= name_len0);
		memcpy(it->name, name, (name_len0) * sizeof(name[0]));
		it->pathInd = 0;
		it->pathOfs = 0;
		it->extOfs = 0;
	}
	return (&(it)->_);
}

extern o7_bool FileProvider_New(struct InputProvider_R **out, o7_int_t searchPathes_len0, o7_char searchPathes[/*len0*/], o7_int_t pathesLen, o7_set_t pathForDecl) {
	struct Provider__s *p = NULL;

	O7_ASSERT((0 < pathesLen) && (pathesLen <= searchPathes_len0) && (pathesLen < O7_LEN(p->path)));

	O7_NEW(&p, Provider__s);
	if (p != NULL) {
		InputProvider_Init(&p->_, GetIterator);

		ArrayCopy_Chars(FileProvider_PathesMaxLen_cnst, p->path, 0, searchPathes_len0, searchPathes, 0, pathesLen);
		p->pathForDecl = pathForDecl;
	}
	*out = (&(p)->_);
	return p != NULL;
}

extern void FileProvider_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		InputProvider_init();
		PlatformExec_init();
		VDataStream_init();
		VFileStream_init();
		Log_init();

		O7_TAG_INIT(Provider__s, InputProvider_R);
		O7_TAG_INIT(Iter, InputProvider_Iter);
	}
	++initialized;
}

#include <o7.h>

#include "CliParser.h"

#define CliParser_Args_tag V_Base_tag
extern void CliParser_Args_undef(struct CliParser_Args *r) {
	V_Base_undef(&r->_);
	memset(&r->src, 0, sizeof(r->src));
	r->srcLen = O7_INT_UNDEF;
	r->script = O7_BOOL_UNDEF;
	r->toSingleFile = O7_BOOL_UNDEF;
	memset(&r->resPath, 0, sizeof(r->resPath));
	memset(&r->tmp, 0, sizeof(r->tmp));
	r->resPathLen = O7_INT_UNDEF;
	r->srcNameEnd = O7_INT_UNDEF;
	memset(&r->modPath, 0, sizeof(r->modPath));
	memset(&r->cDirs, 0, sizeof(r->cDirs));
	memset(&r->cc, 0, sizeof(r->cc));
	r->modPathLen = O7_INT_UNDEF;
	r->sing = 0u;
	r->init = O7_INT_UNDEF;
	r->memng = O7_INT_UNDEF;
	r->arg = O7_INT_UNDEF;
	r->cStd = O7_INT_UNDEF;
	r->noNilCheck = O7_BOOL_UNDEF;
	r->noOverflowCheck = O7_BOOL_UNDEF;
	r->noIndexCheck = O7_BOOL_UNDEF;
	r->cyrillic = O7_INT_UNDEF;
}

static o7_char dirSep = '\0';

extern o7_bool CliParser_GetParam(o7_int_t *err, o7_int_t errTooLong, o7_int_t str_len0, o7_char str[/*len0*/], o7_int_t *i, o7_int_t *arg) {
	o7_int_t j;
	o7_bool ret;

	if (o7_cmp((*arg), CLI_count) >= 0) {
		(*err) = CliParser_ErrNotEnoughArgs_cnst;
		ret = (0 > 1);
	} else {
		j = (*i);
		ret = CLI_Get(str_len0, str, &(*i), (*arg));
		(*arg) = o7_add((*arg), 1);
		if (ret && o7_bl(Platform_Windows) && (str[o7_ind(str_len0, j)] == (o7_char)'\'') && (o7_cmp((*arg), CLI_count) < 0)) {
			str[o7_ind(str_len0, j)] = (o7_char)' ';
			while ((o7_cmp((*arg), CLI_count) < 0) && ret && (str[o7_ind(str_len0, o7_sub((*i), 1))] != (o7_char)'\'')) {
				str[o7_ind(str_len0, (*i))] = (o7_char)' ';
				(*i) = o7_add((*i), 1);
				ret = CLI_Get(str_len0, str, &(*i), (*arg));
				(*arg) = o7_add((*arg), 1);
			}
			str[o7_ind(str_len0, o7_sub((*i), 1))] = 0x00u;
		}
		(*i) = o7_add(j, Chars0X_Trim(str_len0, str, j));
		if (!ret || ((*i) >= o7_sub(str_len0, 1))) {
			(*err) = errTooLong;
		}
	}
	return ret;
}

static o7_bool IsEqualStr(o7_int_t str_len0, o7_char str[/*len0*/], o7_int_t ofs, o7_int_t sample_len0, o7_char sample[/*len0*/]) {
	o7_int_t i;

	i = 0;
	while ((str[o7_ind(str_len0, ofs)] == sample[o7_ind(sample_len0, i)]) && (sample[o7_ind(sample_len0, i)] != 0x00u) && (ofs < o7_sub(str_len0, 1)) && (ofs < o7_sub(sample_len0, 1))) {
		ofs = o7_add(ofs, 1);
		i = o7_add(i, 1);
	}
	return str[o7_ind(str_len0, ofs)] == sample[o7_ind(sample_len0, i)];
}

static o7_bool CopyInfr_Copy(o7_int_t str_len0, o7_char str[/*len0*/], o7_int_t *i, o7_int_t base_len0, o7_char base[/*len0*/], o7_int_t add_len0, o7_char add[/*len0*/]) {
	o7_bool ret;

	ret = Chars0X_CopyString(str_len0, str, &(*i), base_len0, base) && Chars0X_CopyString(str_len0, str, &(*i), add_len0, add);
	if (ret) {
		(*i) = o7_add((*i), 1);
		str[o7_ind(str_len0, (*i))] = 0x00u;
	}
	return ret;
}

static o7_bool CopyInfr(struct CliParser_Args *args, o7_int_t *i, o7_int_t *dirsOfs, o7_int_t *count, o7_int_t base_len0, o7_char base[/*len0*/]) {
	o7_bool ok;

	if (o7_bl(Platform_Posix)) {
		ok = CopyInfr_Copy(4096, (*args).modPath, &(*i), base_len0, base, 24, (o7_char *)"/singularity/definition")
		&& CopyInfr_Copy(4096, (*args).modPath, &(*i), base_len0, base, 9, (o7_char *)"/library")
		&& CopyInfr_Copy(4096, (*args).cDirs, &(*dirsOfs), base_len0, base, 28, (o7_char *)"/singularity/implementation");
	} else if (o7_bl(Platform_Windows)) {
		ok = CopyInfr_Copy(4096, (*args).modPath, &(*i), base_len0, base, 24, (o7_char *)"\\singularity\\definition")
		&& CopyInfr_Copy(4096, (*args).modPath, &(*i), base_len0, base, 9, (o7_char *)"\\library")
		&& CopyInfr_Copy(4096, (*args).cDirs, &(*dirsOfs), base_len0, base, 28, (o7_char *)"\\singularity\\implementation");
	} else {
		ok = (0 > 1);
	}
	if (ok) {
		(*args).sing |= 1u << (*count);
		(*count) = o7_add((*count), 2);
	}
	return ok;
}

extern o7_int_t CliParser_Options(struct CliParser_Args *args, o7_int_t *arg) {
	o7_int_t i, dirsOfs, ccLen, count, optLen, ret;
	o7_char opt[256];
	o7_bool ignore;
	memset(&opt, 0, sizeof(opt));

	i = 0;
	dirsOfs = 0;
	ccLen = 0;
	count = 0;
	ret = CliParser_ErrNo_cnst;
	optLen = 0;
	while ((ret == CliParser_ErrNo_cnst) && (count < 32) && (o7_cmp((*arg), CLI_count) < 0) && CLI_Get(256, opt, &optLen, (*arg)) && !IsEqualStr(256, opt, 0, 3, (o7_char *)"--")) {
		optLen = 0;
		(*arg) = o7_add((*arg), 1);
		if ((o7_strcmp(256, opt, 3, (o7_char *)"-i") == 0) || (o7_strcmp(256, opt, 3, (o7_char *)"-m") == 0)) {
			if (CliParser_GetParam(&ret, CliParser_ErrTooLongModuleDirs_cnst, 4096, (*args).modPath, &i, &(*arg))) {
				if (o7_strcmp(256, opt, 3, (o7_char *)"-i") == 0) {
					(*args).sing |= 1u << count;
				}
				i = o7_add(i, 1);
				(*args).modPath[o7_ind(4096, i)] = 0x00u;
				count = o7_add(count, 1);
			}
		} else if (o7_strcmp(256, opt, 3, (o7_char *)"-c") == 0) {
			if (CliParser_GetParam(&ret, CliParser_ErrTooLongCDirs_cnst, 4096, (*args).cDirs, &dirsOfs, &(*arg))) {
				dirsOfs = o7_add(dirsOfs, 1);
				(*args).cDirs[o7_ind(4096, dirsOfs)] = 0x00u;
			}
		} else if (o7_strcmp(256, opt, 4, (o7_char *)"-cc") == 0) {
			if (CliParser_GetParam(&ret, CliParser_ErrTooLongCc_cnst, 4096, (*args).cc, &ccLen, &(*arg)) && (o7_cmp((*arg), CLI_count) < 0) && CLI_Get(256, opt, &optLen, (*arg)) && (o7_strcmp(256, opt, 4, (o7_char *)"...") == 0)) {
				optLen = 0;
				(*arg) = o7_add((*arg), 1);
				ccLen = o7_add(ccLen, 1);
				ignore = CliParser_GetParam(&ret, CliParser_ErrTooLongCc_cnst, 4096, (*args).cc, &ccLen, &(*arg));
			} else if (ccLen < O7_LEN((*args).cc) - 1) {
				(*args).cc[o7_ind(4096, o7_add(ccLen, 1))] = 0x00u;
			}
		} else if (o7_strcmp(256, opt, 6, (o7_char *)"-infr") == 0) {
			if (CliParser_GetParam(&ret, CliParser_ErrTooLongModuleDirs_cnst, 256, opt, &optLen, &(*arg)) && !CopyInfr(&(*args), &i, &dirsOfs, &count, 256, opt)) {
				ret = CliParser_ErrTooLongModuleDirs_cnst;
			}
		} else if (o7_strcmp(256, opt, 6, (o7_char *)"-init") == 0) {
			if (!CliParser_GetParam(&ret, CliParser_ErrUnknownInit_cnst, 256, opt, &optLen, &(*arg))) {
			} else if (o7_strcmp(256, opt, 7, (o7_char *)"noinit") == 0) {
				(*args).init = GeneratorC_VarInitNo_cnst;
			} else if (o7_strcmp(256, opt, 6, (o7_char *)"undef") == 0) {
				(*args).init = GeneratorC_VarInitUndefined_cnst;
			} else if (o7_strcmp(256, opt, 5, (o7_char *)"zero") == 0) {
				(*args).init = GeneratorC_VarInitZero_cnst;
			} else {
				ret = CliParser_ErrUnknownInit_cnst;
			}
		} else if (o7_strcmp(256, opt, 7, (o7_char *)"-memng") == 0) {
			if (!CliParser_GetParam(&ret, CliParser_ErrUnknownMemMan_cnst, 256, opt, &optLen, &(*arg))) {
			} else if (o7_strcmp(256, opt, 7, (o7_char *)"nofree") == 0) {
				(*args).memng = GeneratorC_MemManagerNoFree_cnst;
			} else if (o7_strcmp(256, opt, 8, (o7_char *)"counter") == 0) {
				(*args).memng = GeneratorC_MemManagerCounter_cnst;
			} else if (o7_strcmp(256, opt, 2, (o7_char *)"gc") == 0) {
				(*args).memng = GeneratorC_MemManagerGC_cnst;
			} else {
				ret = CliParser_ErrUnknownMemMan_cnst;
			}
		} else if (o7_strcmp(256, opt, 3, (o7_char *)"-t") == 0) {
			ignore = CliParser_GetParam(&ret, CliParser_ErrTooLongTemp_cnst, 1024, (*args).tmp, &optLen, &(*arg));
		} else if (o7_strcmp(256, opt, 22, (o7_char *)"-no-array-index-check") == 0) {
			(*args).noIndexCheck = (0 < 1);
		} else if (o7_strcmp(256, opt, 14, (o7_char *)"-no-nil-check") == 0) {
			(*args).noNilCheck = (0 < 1);
		} else if (o7_strcmp(256, opt, 30, (o7_char *)"-no-arithmetic-overflow-check") == 0) {
			(*args).noOverflowCheck = (0 < 1);
		} else if (o7_strcmp(256, opt, 5, (o7_char *)"-C90") == 0) {
			(*args).cStd = GeneratorC_IsoC90_cnst;
		} else if (o7_strcmp(256, opt, 5, (o7_char *)"-C99") == 0) {
			(*args).cStd = GeneratorC_IsoC99_cnst;
		} else if (o7_strcmp(256, opt, 5, (o7_char *)"-C11") == 0) {
			(*args).cStd = GeneratorC_IsoC11_cnst;
		} else {
			ret = CliParser_ErrUnexpectArg_cnst;
		}
		optLen = 0;
	}
	if (ret != CliParser_ErrNo_cnst) {
	} else if (o7_add(i, 1) < O7_LEN((*args).modPath)) {
		(*args).modPathLen = o7_add(i, 1);
		(*args).modPath[o7_ind(4096, o7_add(i, 1))] = 0x00u;
		if (count >= 32) {
			ret = CliParser_ErrTooManyModuleDirs_cnst;
		}
	} else {
		ret = CliParser_ErrTooLongModuleDirs_cnst;
		(*args).modPath[O7_LEN((*args).modPath) - 1] = 0x00u;
		(*args).modPath[O7_LEN((*args).modPath) - 2] = 0x00u;
		(*args).modPath[O7_LEN((*args).modPath) - 3] = (o7_char)'#';
	}
	(void)ignore;
	return ret;
}

extern void CliParser_ArgsInit(struct CliParser_Args *args) {
	V_Init(&(*args)._);

	(*args).srcLen = 0;
	(*args).cDirs[0] = 0x00u;
	(*args).tmp[0] = 0x00u;
	(*args).cc[0] = 0x00u;
	(*args).cc[1] = 0x00u;
	(*args).sing = 0;
	(*args).init =  - 1;
	(*args).memng =  - 1;
	(*args).cStd =  - 1;
	(*args).noNilCheck = (0 > 1);
	(*args).noOverflowCheck = (0 > 1);
	(*args).noIndexCheck = (0 > 1);
	(*args).toSingleFile = (0 > 1);
}

static o7_bool IsEndByShortExt(o7_int_t name_len0, o7_char name[/*len0*/], o7_int_t *dot, o7_int_t *sep) {
	o7_int_t i;

	i = 0;
	(*dot) =  - 988;
	(*sep) =  - 977;
	while (name[o7_ind(name_len0, i)] != 0x00u) {
		if (name[o7_ind(name_len0, i)] == (o7_char)'.') {
			(*dot) = i;
		} else if ((name[o7_ind(name_len0, i)] == (o7_char)'/') || (name[o7_ind(name_len0, i)] == (o7_char)'\\')) {
			(*sep) = i;
		}
		i = o7_add(i, 1);
	}
	return ((*dot) > (*sep)) && (o7_sub(i, (*dot)) <= 4);
}

static void ParseCommand_Empty(o7_int_t src_len0, o7_char src[/*len0*/], o7_int_t *j) {
	while ((src[o7_ind(src_len0, (*j))] == (o7_char)' ') || (src[o7_ind(src_len0, (*j))] == 0x09u)) {
		(*j) = o7_add((*j), 1);
	}
}

extern o7_int_t CliParser_ParseCommand(o7_int_t src_len0, o7_char src[/*len0*/], o7_bool *script) {
	o7_int_t i, j, k;

	i = 0;
	while ((src[o7_ind(src_len0, i)] != 0x00u) && (src[o7_ind(src_len0, i)] != (o7_char)'.')) {
		i = o7_add(i, 1);
	}
	if (src[o7_ind(src_len0, i)] == (o7_char)'.') {
		j = o7_add(i, 1);
		ParseCommand_Empty(src_len0, src, &j);
		while (((o7_char)'a' <= src[o7_ind(src_len0, j)]) && (src[o7_ind(src_len0, j)] <= (o7_char)'z') || ((o7_char)'A' <= src[o7_ind(src_len0, j)]) && (src[o7_ind(src_len0, j)] <= (o7_char)'Z') || ((o7_char)'0' <= src[o7_ind(src_len0, j)]) && (src[o7_ind(src_len0, j)] <= (o7_char)'9')) {
			j = o7_add(j, 1);
		}
		k = j;
		ParseCommand_Empty(src_len0, src, &k);
		(*script) = src[o7_ind(src_len0, k)] != 0x00u;
	} else {
		(*script) = (0 > 1);
	}
	return i;
}

static o7_int_t ParseOptions(struct CliParser_Args *args, o7_int_t ret, o7_int_t *arg) {
	o7_int_t argDest, cpRet, dot = O7_INT_UNDEF, sep = O7_INT_UNDEF;
	o7_bool forRun;

	argDest = (*arg);
	(*args).srcLen = o7_add((*args).srcLen, 1);

	forRun = ret == CliParser_ResultRun_cnst;
	(*arg) = o7_add((*arg), (o7_int_t)!forRun);
	cpRet = CliParser_Options(&(*args), &(*arg));
	if (cpRet != CliParser_ErrNo_cnst) {
		ret = cpRet;
	} else {
		(*args).srcNameEnd = CliParser_ParseCommand(65536, (*args).src, &(*args).script);

		(*args).resPathLen = 0;
		(*args).resPath[0] = 0x00u;
		if (forRun) {
		} else if (CliParser_GetParam(&cpRet, CliParser_ErrTooLongOutName_cnst, 1024, (*args).resPath, &(*args).resPathLen, &argDest)) {
			(*args).toSingleFile = IsEndByShortExt(1024, (*args).resPath, &dot, &sep);
		} else {
			ret = cpRet;
		}
	}
	return ret;
}

static o7_int_t Command(struct CliParser_Args *args, o7_int_t ret) {
	o7_int_t arg;

	O7_ASSERT(o7_in(ret, O7_SET(CliParser_ResultC_cnst, CliParser_ResultRun_cnst)));

	CliParser_ArgsInit(&(*args));

	arg = 1;
	if (CliParser_GetParam(&ret, CliParser_ErrTooLongSourceName_cnst, 65536, (*args).src, &(*args).srcLen, &arg)) {
		ret = ParseOptions(&(*args), ret, &arg);
	}
	(*args).arg = o7_add(arg, 1);
	return ret;
}

extern o7_bool CliParser_Parse(struct CliParser_Args *args, o7_int_t *ret) {
	o7_int_t cmdLen;
	o7_char cmd[16];
	memset(&cmd, 0, sizeof(cmd));

	cmdLen = 0;
	if ((o7_cmp(CLI_count, 0) <= 0) || !CLI_Get(16, cmd, &cmdLen, 0)) {
		(*ret) = CliParser_ErrWrongArgs_cnst;
	} else if (o7_strcmp(16, cmd, 5, (o7_char *)"help") == 0) {
		(*ret) = CliParser_CmdHelp_cnst;
	} else if (o7_strcmp(16, cmd, 5, (o7_char *)"to-c") == 0) {
		(*ret) = Command(&(*args), CliParser_ResultC_cnst);
	} else if (o7_strcmp(16, cmd, 7, (o7_char *)"to-bin") == 0) {
		(*ret) = Command(&(*args), CliParser_ResultBin_cnst);
	} else if (o7_strcmp(16, cmd, 4, (o7_char *)"run") == 0) {
		(*ret) = Command(&(*args), CliParser_ResultRun_cnst);
	} else {
		(*ret) = CliParser_ErrUnknownCommand_cnst;
	}
	return 0 <= (*ret);
}

extern void CliParser_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		CLI_init();
		StringStore_init();
		Platform_init();
		Log_init();
		GeneratorC_init();

		if (o7_bl(Platform_Posix)) {
			dirSep = (o7_char)'/';
		} else {
			O7_ASSERT(o7_bl(Platform_Windows));
			dirSep = (o7_char)'\\';
		}
	}
	++initialized;
}


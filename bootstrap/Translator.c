#define O7_BOOL_UNDEFINED
#include <o7.h>

#include "V.h"
#include "Log.h"
#include "Out.h"
#include "CLI.h"
#include "VDataStream.h"
#include "VFileStream.h"
#include "Utf8.h"
#include "StringStore.h"
#include "SpecIdentChecker.h"
#include "Parser.h"
#include "Scanner.h"
#include "Ast.h"
#include "GeneratorC.h"
#include "TranslatorLimits.h"
#include "PlatformExec.h"
#include "CCompilerInterface.h"
#include "Message.h"
#include "CliParser.h"
#include "Platform.h"
#include "CFiles.h"
#include "OsEnv.h"
#include "FileSystemUtil.h"
#include "TextGenerator.h"
#include "ModulesStorage.h"
#include "ModulesProvider.h"

#define Translator_ErrNo_cnst 0
#define Translator_ErrParse_cnst (-1)
#define Translator_ErrCantGenJsToMem_cnst (-2)

typedef struct Translator_MsgTempDirCreated {
	V_Message _;
} Translator_MsgTempDirCreated;
#define Translator_MsgTempDirCreated_tag V_Message_tag

static void Translator_MsgTempDirCreated_undef(struct Translator_MsgTempDirCreated *r) {
	V_Message_undef(&r->_);
}

static void ErrorMessage(o7_int_t code) {
	if (code <= Parser_ErrAstBegin_cnst) {
		Message_AstError(o7_sub(code, Parser_ErrAstBegin_cnst));
	} else {
		Message_ParseError(code);
	}
}

static void IndexedErrorMessage(o7_int_t index, o7_int_t code, o7_int_t line, o7_int_t column) {
	Out_String(2, (o7_char *)"  ");
	Out_Int(index, 2);
	Out_String(2, (o7_char *)") ");

	ErrorMessage(code);

	Out_String(1, (o7_char *)"\x20");
	Out_Int(o7_add(line, 1), 0);
	Out_String(3, (o7_char *)" : ");
	Out_Int(column, 0);
	Out_Ln();
}

static void PrintErrors(struct ModulesStorage_RContainer *mc, struct Ast_RModule *module_) {
#	define SkipError_cnst (Ast_ErrImportModuleWithError_cnst + Parser_ErrAstBegin_cnst)

	o7_int_t i;
	struct Ast_RError *err;
	struct Ast_RModule *m;

	i = 0;
	m = ModulesStorage_Next(&mc);
	while (m != NULL) {
		err = O7_REF(m)->errors;
		while ((err != NULL) && (o7_cmp(O7_REF(err)->code, SkipError_cnst) == 0)) {
			err = O7_REF(err)->next;
		}
		if (err != NULL) {
			Message_Text(27, (o7_char *)"Found errors in the module ");
			Out_String(StringStore_BlockSize_cnst + 1, O7_REF(O7_REF(m)->_._.name.block)->s);
			Out_String(2, (o7_char *)": ");
			Out_Ln();
			err = O7_REF(m)->errors;
			while (err != NULL) {
				if (o7_cmp(O7_REF(err)->code, SkipError_cnst) != 0) {
					i = o7_add(i, 1);
					IndexedErrorMessage(i, o7_int(O7_REF(err)->code), o7_int(O7_REF(err)->line), o7_int(O7_REF(err)->column));
				}
				err = O7_REF(err)->next;
			}
		}
		m = ModulesStorage_Next(&mc);
	}
	if (i == 0) {
		IndexedErrorMessage(i, o7_int(O7_REF(O7_REF(module_)->errors)->code), o7_int(O7_REF(O7_REF(module_)->errors)->line), o7_int(O7_REF(O7_REF(module_)->errors)->column));
	}
#	undef SkipError_cnst
}

static o7_bool CopyModuleNameForFile(o7_int_t str_len0, o7_char str[/*len0*/], o7_int_t *len, struct StringStore_String *name) {
	return StringStore_CopyToChars(str_len0, str, &(*len), &(*name)) && (!SpecIdentChecker_IsSpecModuleName(&(*name)) || StringStore_CopyCharsNull(str_len0, str, &(*len), 1, (o7_char *)"\x5F"));
}

static o7_int_t OpenCOutput(struct VFileStream_ROut **interface_, struct VFileStream_ROut **implementation, struct Ast_RModule *module_, o7_bool isMain, o7_int_t dir_len0, o7_char dir[/*len0*/], o7_int_t dirLen, struct CCompilerInterface_Compiler *ccomp, o7_bool usecc) {
	o7_int_t destLen, ret;

	(*interface_) = NULL;
	(*implementation) = NULL;
	destLen = dirLen;
	if (!StringStore_CopyCharsNull(dir_len0, dir, &destLen, 1, PlatformExec_dirSep) || !CopyModuleNameForFile(dir_len0, dir, &destLen, &O7_REF(module_)->_._.name) || (destLen > o7_sub(dir_len0, 3))) {
		ret = CliParser_ErrTooLongOutName_cnst;
	} else {
		dir[o7_ind(dir_len0, destLen)] = (o7_char)'.';
		dir[o7_ind(dir_len0, o7_add(destLen, 2))] = 0x00u;
		if (!isMain) {
			dir[o7_ind(dir_len0, o7_add(destLen, 1))] = (o7_char)'h';
			(*interface_) = VFileStream_OpenOut(dir_len0, dir);
		}
		if (!isMain && ((*interface_) == NULL)) {
			ret = CliParser_ErrOpenH_cnst;
		} else {
			dir[o7_ind(dir_len0, o7_add(destLen, 1))] = (o7_char)'c';
			(*implementation) = VFileStream_OpenOut(dir_len0, dir);
			if ((*implementation) == NULL) {
				VFileStream_CloseOut(&(*interface_));
				ret = CliParser_ErrOpenC_cnst;
			} else {
				/* TODO */
				O7_ASSERT(!usecc || CCompilerInterface_AddC(&(*ccomp), dir_len0, dir, 0));
				Log_StrLn(dir_len0, dir);

				ret = Translator_ErrNo_cnst;
			}
		}
	}
	return ret;
}

static void NewProvider(struct ModulesStorage_Provider__s **p, struct Parser_Options *opt, struct CliParser_Args *args) {
	struct ModulesProvider_Provider__s *m = NULL;

	ModulesProvider_New(&m, 4096, (*args).modPath, o7_int((*args).modPathLen), (*args).sing);
	ModulesStorage_New(&(*p), &m->_);

	Parser_DefaultOptions(&(*opt));
	(*opt).printError = ErrorMessage;
	(*opt).provider = (&((*p))->_);

	ModulesProvider_SetParserOptions(m, &(*opt));
}

static o7_int_t GenerateC(struct Ast_RModule *module_, o7_bool isMain, struct Ast_RStatement *cmd, struct GeneratorC_Options__s *opt, o7_int_t dir_len0, o7_char dir[/*len0*/], o7_int_t dirLen, o7_int_t cDirs_len0, o7_char cDirs[/*len0*/], struct CCompilerInterface_Compiler *ccomp, o7_bool usecc) {
	struct Ast_RDeclaration *imp;
	o7_int_t ret, i, cDirsLen, nameLen;
	o7_char name[512];
	struct VFileStream_ROut *iface = NULL, *impl = NULL;
	o7_bool sing;
	memset(&name, 0, sizeof(name));

	O7_REF(module_)->_._.used = (0 < 1);

	ret = Translator_ErrNo_cnst;
	imp = (&(O7_REF(module_)->import_)->_);
	while ((ret == Translator_ErrNo_cnst) && (imp != NULL) && (o7_is(imp, &Ast_Import__s_tag))) {
		if (!o7_bl(O7_REF(O7_REF(O7_REF(imp)->module_)->m)->_._.used)) {
			ret = GenerateC(O7_REF(O7_REF(imp)->module_)->m, (0 > 1), NULL, opt, dir_len0, dir, dirLen, cDirs_len0, cDirs, &(*ccomp), usecc);
		}
		imp = O7_REF(imp)->next;
	}
	if (ret == Translator_ErrNo_cnst) {
		sing = (0 > 1);
		if (o7_bl(O7_REF(module_)->_._.mark)) {
			i = 0;
			while (!sing && (cDirs[o7_ind(cDirs_len0, i)] != 0x00u)) {
				nameLen = 0;
				cDirsLen = StringStore_CalcLen(cDirs_len0, cDirs, i);
				/* TODO */
				O7_ASSERT(StringStore_CopyChars(512, name, &nameLen, cDirs_len0, cDirs, i, o7_add(i, cDirsLen)) && StringStore_CopyCharsNull(512, name, &nameLen, 1, PlatformExec_dirSep) && CopyModuleNameForFile(512, name, &nameLen, &O7_REF(module_)->_._.name) && StringStore_CopyCharsNull(512, name, &nameLen, 2, (o7_char *)".c"));
				if (CFiles_Exist(512, name, 0)) {
					sing = (0 < 1);
					O7_ASSERT(!usecc || CCompilerInterface_AddC(&(*ccomp), 512, name, 0));
				} else {
					name[o7_ind(512, o7_sub(nameLen, 1))] = (o7_char)'h';
					sing = CFiles_Exist(512, name, 0) || sing;
				}
				i = o7_add(o7_add(i, cDirsLen), 1);
			}
		}
		if (!sing) {
			ret = OpenCOutput(&iface, &impl, module_, isMain, dir_len0, dir, dirLen, &(*ccomp), usecc);
			if (ret == Translator_ErrNo_cnst) {
				GeneratorC_Generate(&iface->_, &impl->_, module_, cmd, opt);
				VFileStream_CloseOut(&iface);
				VFileStream_CloseOut(&impl);
			}
		}
	}
	return ret;
}

static o7_bool GetTempOut(o7_int_t dirOut_len0, o7_char dirOut[/*len0*/], o7_int_t *len, struct StringStore_String *name, o7_int_t tmp_len0, o7_char tmp[/*len0*/], struct V_Base *listener) {
	o7_int_t i;
	o7_bool ok, saveTemp;
	struct Translator_MsgTempDirCreated tmpCreated;
	Translator_MsgTempDirCreated_undef(&tmpCreated);

	(*len) = 0;
	if (o7_strcmp(tmp_len0, tmp, 0, (o7_char *)"") != 0) {
		ok = (0 < 1);
		O7_ASSERT(StringStore_CopyCharsNull(dirOut_len0, dirOut, &(*len), tmp_len0, tmp));
	} else if (Platform_Posix) {
		ok = (0 < 1);
		O7_ASSERT(StringStore_CopyCharsNull(dirOut_len0, dirOut, &(*len), 9, (o7_char *)"/tmp/o7c-") && StringStore_CopyToChars(dirOut_len0, dirOut, &(*len), &(*name)));
	} else {
		O7_ASSERT(Platform_Windows);
		ok = OsEnv_Get(dirOut_len0, dirOut, &(*len), 4, (o7_char *)"temp") && StringStore_CopyCharsNull(dirOut_len0, dirOut, &(*len), 5, (o7_char *)"\\o7c-") && StringStore_CopyToChars(dirOut_len0, dirOut, &(*len), &(*name));
	}

	if (ok) {
		i = 0;
		ok = FileSystemUtil_MakeDir(dirOut_len0, dirOut);
		if (!ok && (o7_strcmp(tmp_len0, tmp, 0, (o7_char *)"") == 0)) {
			while (!ok && (i < 100)) {
				if (i == 0) {
					O7_ASSERT(StringStore_CopyCharsNull(dirOut_len0, dirOut, &(*len), 3, (o7_char *)"-00"));
				} else {
					dirOut[o7_ind(dirOut_len0, o7_sub((*len), 2))] = o7_chr(o7_add((o7_int_t)(o7_char)'0', o7_div(i, 10)));
					dirOut[o7_ind(dirOut_len0, o7_sub((*len), 1))] = o7_chr(o7_add((o7_int_t)(o7_char)'0', o7_mod(i, 10)));
				}
				ok = FileSystemUtil_MakeDir(dirOut_len0, dirOut);
				i = o7_add(i, 1);
			}
		}
		if (ok) {
			i = 0;
			if (o7_strcmp(tmp_len0, tmp, 0, (o7_char *)"") != 0) {
				saveTemp = V_Do(&(*listener), &tmpCreated._);
			} else {
				ok = StringStore_CopyCharsNull(tmp_len0, tmp, &i, dirOut_len0, dirOut);
				saveTemp = V_Do(&(*listener), &tmpCreated._);
				if (!saveTemp) {
					tmp[0] = 0x00u;
				}
			}
		}
	}
	return ok;
}

static o7_bool GetCBin(o7_int_t bin_len0, o7_char bin[/*len0*/], o7_int_t dir_len0, o7_char dir[/*len0*/], struct StringStore_String *name) {
	o7_int_t len;

	len = 0;
	return StringStore_CopyCharsNull(bin_len0, bin, &len, dir_len0, dir) && StringStore_CopyCharsNull(bin_len0, bin, &len, 1, PlatformExec_dirSep) && StringStore_CopyToChars(bin_len0, bin, &len, &(*name)) && (!Platform_Windows || StringStore_CopyCharsNull(bin_len0, bin, &len, 4, (o7_char *)".exe"));
}

static o7_bool GetTempOutC(o7_int_t dirCOut_len0, o7_char dirCOut[/*len0*/], o7_int_t *len, o7_int_t bin_len0, o7_char bin[/*len0*/], struct StringStore_String *name, o7_int_t tmp_len0, o7_char tmp[/*len0*/], struct V_Base *listener) {
	o7_bool ok;

	ok = GetTempOut(dirCOut_len0, dirCOut, &(*len), &(*name), tmp_len0, tmp, &(*listener));
	if (ok && (bin[0] == 0x00u)) {
		ok = GetCBin(bin_len0, bin, dirCOut_len0, dirCOut, &(*name));
	}
	return ok;
}

static void GenerateThroughC_SetOptions(struct GeneratorC_Options__s *opt, struct CliParser_Args *args) {
	if (o7_cmp(0, (*args).init) <= 0) {
		O7_REF(opt)->varInit = o7_int((*args).init);
	}
	if (o7_cmp(0, (*args).memng) <= 0) {
		O7_REF(opt)->memManager = o7_int((*args).memng);
	}
	if (o7_bl((*args).noNilCheck)) {
		O7_REF(opt)->checkNil = (0 > 1);
	}
	if (o7_bl((*args).noOverflowCheck)) {
		O7_REF(opt)->checkArith = (0 > 1);
	}
	if (o7_bl((*args).noIndexCheck)) {
		O7_REF(opt)->checkIndex = (0 > 1);
	}
	if (o7_cmp(0, (*args).cStd) <= 0) {
		O7_REF(opt)->std = o7_int((*args).cStd);
	}
}

static o7_int_t GenerateThroughC_Bin(o7_int_t res, struct CliParser_Args *args, struct Ast_RModule *module_, struct Ast_RStatement *call, struct GeneratorC_Options__s *opt, o7_int_t cDirs_len0, o7_char cDirs[/*len0*/], o7_int_t cc_len0, o7_char cc[/*len0*/], o7_int_t outC_len0, o7_char outC[/*len0*/], o7_int_t bin_len0, o7_char bin[/*len0*/], struct CCompilerInterface_Compiler *cmd, o7_int_t tmp_len0, o7_char tmp[/*len0*/], struct V_Base *listener) {
	o7_int_t outCLen = O7_INT_UNDEF, ret, i, nameLen, cDirsLen, ccEnd;
	o7_bool ok;
	o7_char name[512];
	memset(&name, 0, sizeof(name));

	ok = GetTempOutC(outC_len0, outC, &outCLen, bin_len0, bin, &O7_REF(module_)->_._.name, tmp_len0, tmp, &(*listener));
	if (!ok) {
		ret = CliParser_ErrCantCreateOutDir_cnst;
	} else {
		ccEnd = StringStore_CalcLen(cc_len0, cc, 0);
		if (ccEnd == 0) {
			ok = CCompilerInterface_Search(&(*cmd), res == CliParser_ResultRun_cnst);
		} else {
			ok = CCompilerInterface_Set(&(*cmd), cc_len0, cc);
		}

		if (!ok) {
			ret = CliParser_ErrCantFoundCCompiler_cnst;
		} else {
			ret = GenerateC(module_, (0 < 1), call, opt, outC_len0, outC, o7_int(outCLen), cDirs_len0, cDirs, &(*cmd), (0 < 1));
		}
		outC[o7_ind(outC_len0, outCLen)] = 0x00u;
		if (ret == Translator_ErrNo_cnst) {
			ok = ok && CCompilerInterface_AddOutput(&(*cmd), bin_len0, bin) && CCompilerInterface_AddInclude(&(*cmd), outC_len0, outC, 0);
			i = 0;
			while (ok && (cDirs[o7_ind(cDirs_len0, i)] != 0x00u)) {
				nameLen = 0;
				cDirsLen = StringStore_CalcLen(cDirs_len0, cDirs, i);
				ok = CCompilerInterface_AddInclude(&(*cmd), cDirs_len0, cDirs, i) && StringStore_CopyChars(512, name, &nameLen, cDirs_len0, cDirs, i, o7_add(i, cDirsLen)) && StringStore_CopyCharsNull(512, name, &nameLen, 1, PlatformExec_dirSep) && StringStore_CopyCharsNull(512, name, &nameLen, 4, (o7_char *)"o7.c") && (!CFiles_Exist(512, name, 0) || CCompilerInterface_AddC(&(*cmd), 512, name, 0));
				i = o7_add(o7_add(i, cDirsLen), 1);
			}
			ok = ok && ((o7_cmp(O7_REF(opt)->memManager, GeneratorC_MemManagerCounter_cnst) != 0) || CCompilerInterface_AddOpt(&(*cmd), 33, (o7_char *)"-DO7_MEMNG_MODEL=O7_MEMNG_COUNTER")) && ((o7_cmp(O7_REF(opt)->memManager, GeneratorC_MemManagerGC_cnst) != 0) || CCompilerInterface_AddOpt(&(*cmd), 28, (o7_char *)"-DO7_MEMNG_MODEL=O7_MEMNG_GC") && CCompilerInterface_AddOpt(&(*cmd), 4, (o7_char *)"-lgc")) && (!Platform_Posix || CCompilerInterface_AddOpt(&(*cmd), 3, (o7_char *)"-lm"));

			if (ok && (ccEnd < o7_sub(cc_len0, 1)) && (cc[o7_ind(cc_len0, o7_add(ccEnd, 1))] != 0x00u)) {
				ok = CCompilerInterface_AddOptByOfs(&(*cmd), cc_len0, cc, o7_add(ccEnd, 1));
			}
			/* TODO */
			O7_ASSERT(ok);
			if (CCompilerInterface_Do(&(*cmd)) != PlatformExec_Ok_cnst) {
				ret = CliParser_ErrCCompiler_cnst;
			}
		}
	}
	return ret;
}

static o7_int_t GenerateThroughC_Run(o7_int_t bin_len0, o7_char bin[/*len0*/], o7_int_t arg) {
	struct PlatformExec_Code cmd;
	o7_char buf[PlatformExec_CodeSize_cnst];
	o7_int_t len, ret;
	PlatformExec_Code_undef(&cmd);
	memset(&buf, 0, sizeof(buf));

	ret = CliParser_ErrTooLongRunArgs_cnst;
	if (PlatformExec_Init(&cmd, bin_len0, bin)) {
		len = 0;
		while ((arg < CLI_count) && CLI_Get(PlatformExec_CodeSize_cnst, buf, &len, arg) && PlatformExec_Add(&cmd, PlatformExec_CodeSize_cnst, buf)) {
			len = 0;
			arg = o7_add(arg, 1);
		}
		if (arg >= CLI_count) {
			CLI_SetExitCode(o7_add(PlatformExec_Ok_cnst, (o7_int_t)(PlatformExec_Do(&cmd) != PlatformExec_Ok_cnst)));
			ret = Translator_ErrNo_cnst;
		}
	}
	return ret;
}

static o7_int_t GenerateThroughC(o7_int_t res, struct CliParser_Args *args, struct Ast_RModule *module_, struct Ast_RStatement *call, struct V_Base *listener) {
	o7_int_t ret;
	struct GeneratorC_Options__s *opt;
	struct CCompilerInterface_Compiler ccomp;
	o7_char outC[1024];
	CCompilerInterface_Compiler_undef(&ccomp);
	memset(&outC, 0, sizeof(outC));

	O7_ASSERT(o7_in(res, CliParser_ThroughC_cnst));

	opt = GeneratorC_DefaultOptions();
	GenerateThroughC_SetOptions(opt, &(*args));
	switch (res) {
	case 2:
		O7_ASSERT(CCompilerInterface_Set(&ccomp, 2, (o7_char *)"cc"));
		ret = GenerateC(module_, (call != NULL) || o7_bl((*args).script), call, opt, 1024, (*args).resPath, o7_int((*args).resPathLen), 4096, (*args).cDirs, &ccomp, (0 > 1));
		break;
	case 3:
	case 4:
		ret = GenerateThroughC_Bin(res, &(*args), module_, call, opt, 4096, (*args).cDirs, 4096, (*args).cc, 1024, outC, 1024, (*args).resPath, &ccomp, 1024, (*args).tmp, &(*listener));
		if ((res == CliParser_ResultRun_cnst) && (ret == Translator_ErrNo_cnst)) {
			ret = GenerateThroughC_Run(1024, (*args).resPath, o7_int((*args).arg));
		}
		if ((o7_strcmp(1024, (*args).tmp, 0, (o7_char *)"") == 0) && !FileSystemUtil_RemoveDir(1024, outC) && (ret == Translator_ErrNo_cnst)) {
			ret = CliParser_ErrCantRemoveOutDir_cnst;
		}
		break;
	default:
		o7_case_fail(res);
		break;
	}
	return ret;
}

static o7_int_t Translator_Translate(o7_int_t res, struct CliParser_Args *args, struct V_Base *listener) {
	o7_int_t ret;
	struct ModulesStorage_Provider__s *mp = NULL;
	struct Ast_RModule *module_;
	struct Ast_Call__s *call = NULL;
	struct Ast_RStatement *cmd;
	struct Parser_Options opt;
	Parser_Options_undef(&opt);

	NewProvider(&mp, &opt, &(*args));

	O7_ASSERT(opt.provider != NULL);

	if (o7_bl((*args).script)) {
		module_ = Parser_Script(65536, (*args).src, &opt);
	} else {
		module_ = ModulesStorage_GetModule(&mp->_, NULL, 65536, (*args).src, 0, o7_int((*args).srcNameEnd));
	}
	if (module_ == NULL) {
		ret = Translator_ErrParse_cnst;
	} else if (O7_REF(module_)->errors != NULL) {
		ret = Translator_ErrParse_cnst;
		PrintErrors(ModulesStorage_Iterate(mp), module_);
	} else {
		if (!o7_bl((*args).script) && (o7_cmp((*args).srcNameEnd, o7_sub((*args).srcLen, 1)) < 0)) {
			ret = Ast_CommandGet(&call, module_, 65536, (*args).src, o7_add((*args).srcNameEnd, 1), o7_sub((*args).srcLen, 1));
			cmd = (&(call)->_);
		} else {
			ret = Translator_ErrNo_cnst;
			cmd = NULL;
		}
		if (ret != Ast_ErrNo_cnst) {
			Message_AstError(ret);
			Message_Ln();
		} else {
			O7_ASSERT(o7_in(res, CliParser_ThroughC_cnst));
			ret = GenerateThroughC(res, &(*args), module_, cmd, &(*listener));
		}
	}
	ModulesStorage_Unlink(&mp);
	return ret;
}

static void Translator_Help(void) {
	Message_Usage((0 < 1));
}

static o7_bool Handle(struct CliParser_Args *args, o7_int_t *ret, struct V_Base *listener) {
	if ((*ret) == CliParser_CmdHelp_cnst) {
		Translator_Help();
	} else {
		(*ret) = Translator_Translate((*ret), &(*args), &(*listener));
	}
	return 0 <= (*ret);
}

static void Translator_Start(void) {
	o7_int_t ret = O7_INT_UNDEF;
	struct CliParser_Args args;
	struct V_Base nothing;
	CliParser_Args_undef(&args);
	V_Base_undef(&nothing);

	Out_Open();
	Log_Turn((0 > 1));

	V_Init(&nothing);
	if (!CliParser_Parse(&args, &ret) || !Handle(&args, &ret, &nothing)) {
		CLI_SetExitCode(PlatformExec_Ok_cnst + 1);
		if (o7_cmp(ret, Translator_ErrParse_cnst) != 0) {
			Message_CliError(o7_int(ret));
		}
	}
}

extern int main(int argc, char *argv[]) {
	o7_init(argc, argv);
	Log_init();
	Out_init();
	CLI_init();
	VDataStream_init();
	VFileStream_init();
	StringStore_init();
	SpecIdentChecker_init();
	Parser_init();
	Scanner_init();
	Ast_init();
	GeneratorC_init();
	PlatformExec_init();
	CCompilerInterface_init();
	Message_init();
	CliParser_init();
	Platform_init();
	CFiles_init();
	OsEnv_init();
	FileSystemUtil_init();
	TextGenerator_init();
	ModulesStorage_init();
	ModulesProvider_init();

	Translator_Start();
	return o7_exit_code;
}

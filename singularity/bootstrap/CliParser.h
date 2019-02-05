#if !defined HEADER_GUARD_CliParser
#    define  HEADER_GUARD_CliParser 1

#include "V.h"
#include "CLI.h"
#include "Utf8.h"
#include "StringStore.h"
#include "Platform.h"
#include "Log.h"
#include "GeneratorC.h"

#define CliParser_CmdHelp_cnst 1
#define CliParser_ResultC_cnst 2
#define CliParser_ResultBin_cnst 3
#define CliParser_ResultRun_cnst 4

#define CliParser_ThroughC_cnst ((1u << CliParser_ResultC_cnst) | (1u << CliParser_ResultBin_cnst) | (1u << CliParser_ResultRun_cnst))

#define CliParser_ErrNo_cnst 0

#define CliParser_ErrWrongArgs_cnst (-10)
#define CliParser_ErrTooLongSourceName_cnst (-11)
#define CliParser_ErrTooLongOutName_cnst (-12)
#define CliParser_ErrOpenSource_cnst (-13)
#define CliParser_ErrOpenH_cnst (-14)
#define CliParser_ErrOpenC_cnst (-15)
#define CliParser_ErrUnknownCommand_cnst (-16)
#define CliParser_ErrNotEnoughArgs_cnst (-17)
#define CliParser_ErrTooLongModuleDirs_cnst (-18)
#define CliParser_ErrTooManyModuleDirs_cnst (-19)
#define CliParser_ErrTooLongCDirs_cnst (-20)
#define CliParser_ErrTooLongCc_cnst (-21)
#define CliParser_ErrTooLongTemp_cnst (-22)
#define CliParser_ErrCCompiler_cnst (-23)
#define CliParser_ErrTooLongRunArgs_cnst (-24)
#define CliParser_ErrUnexpectArg_cnst (-25)
#define CliParser_ErrUnknownInit_cnst (-26)
#define CliParser_ErrUnknownMemMan_cnst (-27)
#define CliParser_ErrCantCreateOutDir_cnst (-28)
#define CliParser_ErrCantRemoveOutDir_cnst (-29)
#define CliParser_ErrCantFoundCCompiler_cnst (-30)
#define CliParser_ErrJavaCompiler_cnst (-31)
#define CliParser_ErrCantFoundJavaCompiler_cnst (-32)
#define CliParser_ErrTooLongJavaDirs_cnst (-33)
#define CliParser_ErrTooLongJsDirs_cnst (-34)

#define CliParser_ErrOpenJava_cnst (-40)
#define CliParser_ErrOpenJs_cnst (-41)

typedef struct CliParser_Args {
	V_Base _;
	o7_char src[65536];
	o7_int_t srcLen;
	o7_bool script;
	o7_bool toSingleFile;
	o7_char resPath[1024];
	o7_char tmp[1024];
	o7_int_t resPathLen;
	o7_int_t srcNameEnd;
	o7_char modPath[4096];
	o7_char cDirs[4096];
	o7_char cc[4096];
	o7_int_t modPathLen;
	unsigned sing;
	o7_int_t init;
	o7_int_t memng;
	o7_int_t arg;
	o7_int_t cStd;
	o7_bool noNilCheck;
	o7_bool noOverflowCheck;
	o7_bool noIndexCheck;
	o7_int_t cyrillic;
} CliParser_Args;
#define CliParser_Args_tag V_Base_tag

extern void CliParser_Args_undef(struct CliParser_Args *r);

extern o7_bool CliParser_GetParam(o7_int_t *err, o7_int_t errTooLong, o7_int_t str_len0, o7_char str[/*len0*/], o7_int_t *i, o7_int_t *arg);

extern o7_int_t CliParser_Options(struct CliParser_Args *args, o7_int_t *arg);

extern void CliParser_ArgsInit(struct CliParser_Args *args);

extern o7_int_t CliParser_ParseCommand(o7_int_t src_len0, o7_char src[/*len0*/], o7_bool *script);

extern o7_bool CliParser_Parse(struct CliParser_Args *args, o7_int_t *ret);

extern void CliParser_init(void);
#endif

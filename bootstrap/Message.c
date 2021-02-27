#if !defined(O7_INIT_MODEL)
#   define   O7_INIT_MODEL O7_INIT_ZERO
#endif

#include <o7.h>

#include "Message.h"

static void S(o7_int_t s_len0, o7_char s[/*len0*/]) {
	Out_String(s_len0, s);
	Out_Ln();
}

static void Usage_Short(void) {
	S(63, (o7_char *)"Translator from Oberon-07 to C, Java, JavaScript, Oberon. 2021");
	S(41, (o7_char *)"Usage: ost command [parameter] {-option}");
	S(37, (o7_char *)" 0) ost help     # For detailed help");
	S(60, (o7_char *)" 1) ost to-c     Code OutDir { -m PM | -i PI | -infr Infr }");
	S(76, (o7_char *)" 2) ost to-bin   Code OutBin {-m PM|-i PI|-infr I|-c PHC|-cc CComp|-t Temp}");
	S(71, (o7_char *)" 3) ost run      Code {-m PM|-i PI|-c PHC|-cc CComp|-t Temp} [-- Args]");
}

static void Usage_Details(void) {
	S(46, (o7_char *)"1) to-c     converts modules to .h & .c files");
	S(69, (o7_char *)"2) to-bin   converts modules to executable through implicit .c files");
	S(46, (o7_char *)"3) run      executes implicit executable file");
	S(1, (o7_char *)"");
	S(64, (o7_char *)"Code is simple Oberon-source. Can be described in kind of EBNF:");
	S(79, (o7_char *)"  Code = Call { ; Call } . Call = Module [ .Procedure [ '('Parameters')' ] ] .");
	S(55, (o7_char *)"OutDir - directory for saving translated .h & .c files");
	S(40, (o7_char *)"OutBin - name of output executable file");
	S(1, (o7_char *)"");
	S(51, (o7_char *)"-m PM - Path to directory with Modules for search.");
	S(51, (o7_char *)"  For example: -m library -m source -m test/source");
	S(77, (o7_char *)"-i PI - Path to directory with Interface modules without real implementation");
	S(41, (o7_char *)"  For example: -i singularity/definition");
	S(78, (o7_char *)"-c PHC - Path to directory with .h & .c -implementations of interface modules");
	S(45, (o7_char *)"  For example: -c singularity/implementation");
	S(66, (o7_char *)"-infr Infr - path to Infr_astructure. '-infr p' is shortening to:");
	S(75, (o7_char *)"  -i p/singularity/definition -c p/singularity/implementation -m p/library");
	S(75, (o7_char *)"-t Temp - new directory, where translator store intermediate .h & .c files");
	S(42, (o7_char *)"  For example: -t result/test/ReadDir.src");
	S(71, (o7_char *)"-cc CComp - C Compiler for build .c-files, by default used 'cc -g -O1'");
	S(40, (o7_char *)"  For example: -cc 'clang -O3 -flto -s'");
	S(76, (o7_char *)"  Option CComp can be splitted by ... on two parts for compilers, which are");
	S(57, (o7_char *)"  may require some keys locates after names of .c-files.");
	S(72, (o7_char *)"  For example: -cc 'g++ -I/usr/include/openbabel-2.0' ... '-lopenbabel'");
	S(49, (o7_char *)"-- Args - command line arguments for runned code");
	S(1, (o7_char *)"");
	S(23, (o7_char *)"Generator's arguments:");
	S(72, (o7_char *)"-init ( noinit | undef | zero )  - kind of variables auto-initializing.");
	S(36, (o7_char *)"  noinit -  without initialization.");
	S(51, (o7_char *)"  undef* -  special values for error's diagnostic.");
	S(28, (o7_char *)"  zero   -  fill by zeroes.");
	S(70, (o7_char *)"-memng ( nofree | counter | gc ) - kind of dynamic memory management.");
	S(31, (o7_char *)"  nofree*  -  without release.");
	S(79, (o7_char *)"  counter  -  automatic reference counting without automatic loops destroying.");
	S(65, (o7_char *)"  gc       -  garbage collection by Boehm-Demers-Weiser library.");
	S(80, (o7_char *)"-no-array-index-check         - turn off runtime check that index within range.");
	S(71, (o7_char *)"-no-nil-check                 - turn off runtime check pointer on nil.");
	S(76, (o7_char *)"-no-arithmetic-overflow-check - turn off runtime check arithmetic overflow.");
	S(1, (o7_char *)"");
	S(65, (o7_char *)"-C90 | -C99 | -C11            - ISO standard of generated C-code");
	S(1, (o7_char *)"");
	S(76, (o7_char *)"-cyrillic[-same] - allow russian identifiers in a source.");
}

extern void Message_Usage(o7_bool full) {
	Usage_Short();
	if (full) {
		S(1, (o7_char *)"");
		Usage_Details();
	}
}

extern void Message_CliError(o7_int_t err) {
	switch (err) {
	case -10:
		Message_Usage((0 > 1));
		break;
	case -11:
		S(29, (o7_char *)"Too long name of source file");
		Out_Ln();
		break;
	case -12:
		S(26, (o7_char *)"Too long destination name");
		Out_Ln();
		break;
	case -13:
		S(25, (o7_char *)"Can not open source file");
		break;
	case -14:
		S(33, (o7_char *)"Can not open destination .h file");
		break;
	case -15:
		S(33, (o7_char *)"Can not open destination .c file");
		break;
	case -16:
		S(16, (o7_char *)"Unknown command");
		Message_Usage((0 > 1));
		break;
	case -17:
		S(42, (o7_char *)"Not enough count of arguments for command");
		break;
	case -18:
		S(44, (o7_char *)"Too long overall length of paths to modules");
		break;
	case -19:
		S(26, (o7_char *)"Too many paths to modules");
		break;
	case -20:
		S(45, (o7_char *)"Too long overall length of paths to .c files");
		break;
	case -21:
		S(38, (o7_char *)"Too long length of C compiler options");
		break;
	case -22:
		S(37, (o7_char *)"Too long name of temporary directory");
		break;
	case -23:
		S(29, (o7_char *)"Error during C compiler call");
		break;
	case -24:
		S(30, (o7_char *)"Too long command line options");
		break;
	case -25:
		S(18, (o7_char *)"Unexpected option");
		break;
	case -26:
		S(30, (o7_char *)"Unknown initialization method");
		break;
	case -27:
		S(34, (o7_char *)"Unknown kind of memory management");
		break;
	case -28:
		S(32, (o7_char *)"Can not create output directory");
		break;
	case -29:
		S(32, (o7_char *)"Can not remove output directory");
		break;
	case -30:
		S(25, (o7_char *)"Can not found C Compiler");
		break;
		break;
	default:
		o7_case_fail(err);
		break;
	}
}

extern void Message_init(void) {
	static unsigned initialized = 0;
	if (0 == initialized) {
		CliParser_init();
		Out_init();
	}
	++initialized;
}

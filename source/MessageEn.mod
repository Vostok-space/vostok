(*  English messages for interface
 *  Copyright (C) 2017-2021 ComdivByZero
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published
 *  by the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)
MODULE MessageEn;

IMPORT Cli := CliParser, Out, Utf8;

PROCEDURE S(s: ARRAY OF CHAR);
BEGIN
	Out.String(s);
	Out.Ln
END S;

PROCEDURE Usage*(full: BOOLEAN);
	PROCEDURE Short;
	BEGIN
S("Translator from Oberon-07 to C, Java, JavaScript, Oberon. 2021");
S("Usage: ost command [parameter] {-option}");
S(" 0) ost help     # For detailed help");
S(" 1) ost to-c     Code OutDir { -m PM | -i PI | -infr Infr }");
S(" 2) ost to-bin   Code OutBin {-m PM|-i PI|-infr I|-c PHC|-cc CComp|-t Temp}");
S(" 3) ost run      Code {-m PM|-i PI|-c PHC|-cc CComp|-t Temp} [-- Args]");
S(" 4) ost to-java  Code OutDir {-m PM | -i PI | -infr Infr}");
S(" 5) ost to-class Code OutDir {-m PM|-i PI|-infr I|-jv PJv|-javac JComp|-t Temp}");
S(" 6) ost run-java Code {-m PM|-i PI|-jv PJv|-t Temp} [-- Args]");
S(" 7) ost to-js    Code Out {-m PM | -i PI | -infr Infr}");
S(" 8) ost run-js   Code {-m PM|-i PI|-js PJs|-t Temp} [-- Args]");
S(" 9) ost to-mod   Code OutDir {-m PM | -i PI | -infr Infr | -std:(O7|AO|CP)}");
S(" A) ost          File.mod         [ Args ]");
S(" B) ost .Command File.mod         [ Args ]");
S(" C) ost .        File.mod Command [ Args ]")
	END Short;

	PROCEDURE Details;
	BEGIN
S("1) to-c     converts modules to .h & .c files");
S("2) to-bin   converts modules to executable through implicit .c files");
S("3) run      executes implicit executable file");
S("4) to-java  converts modules to .java files");
S("5) to-class converts modules to .class through implicit .java files");
S("6) run-java executes implicit class, created from Code");
S("7) to-js    converts modules to .js files");
S("8) run-js   executes implicit .js file, created by Code");
S("9) to-mod   converts to Oberon-modules");
S("A-C) run code of module in the file, may be used with she-bang");
S("");
S("Code is simple Oberon-source. Can be described in kind of EBNF:");
S("  Code = Call { ; Call } . Call = Module [ .Procedure [ '('Parameters')' ] ] .");
S("OutDir - directory for saving translated .h & .c files");
S("OutBin - name of output executable file");
S("");
S("-m PM - Path to directory with Modules for search.");
S("  For example: -m library -m source -m test/source");
S("-i PI - Path to directory with Interface modules without real implementation");
S("  For example: -i singularity/definition");
S("-c PHC - Path to directory with .h & .c -implementations of interface modules");
S("  For example: -c singularity/implementation");
S("-infr Infr - path to Infr_astructure. '-infr p' is shortening to:");
S("  -i p/singularity/definition -c p/singularity/implementation -m p/library");
S("-t Temp - new directory, where translator store intermediate .h & .c files");
S("  For example: -t result/test/ReadDir.src");
S("-cc CComp - C Compiler for build .c-files, by default used 'cc -g -O1'");
S("  For example: -cc 'clang -O3 -flto -s'");
S("  Option CComp can be splitted by ... on two parts for compilers, which are");
S("  may require some keys locates after names of .c-files.");
S("  For example: -cc 'g++ -I/usr/include/openbabel-2.0' ... '-lopenbabel'");
S("-- Args - command line arguments for runned code");
S("");
S("Generator's arguments:");
S("-init ( noinit | undef | zero )  - kind of variables auto-initializing.");
S("  noinit -  without initialization.");
S("  undef* -  special values for error's diagnostic.");
S("  zero   -  fill by zeroes.");
S("-memng ( nofree | counter | gc ) - kind of dynamic memory management.");
S("  nofree*  -  without release.");
S("  counter  -  automatic reference counting without automatic loops destroying.");
S("  gc       -  garbage collection by Boehm-Demers-Weiser library.");
S("-no-array-index-check         - turn off runtime check that index within range.");
S("-no-nil-check                 - turn off runtime check pointer on nil.");
S("-no-arithmetic-overflow-check - turn off runtime check arithmetic overflow.");
S("");
S("-C90 | -C99 | -C11            - ISO standard of generated C-code");
S("-out:O7|-out:AO|-out:CP       - dialect of generated Oberon-code");
S("");
S("-cyrillic[-same|-escape|-translit] - allow russian identifiers in a source.");
S("   by default used suitable method of name generation, specific for compiler.");
S("  -same     translate to identical C names.");
S("  -escape   translate with escaped unicode chars - \uXXXX.");
S("  -translit use transliteration in output names in C.")
	END Details;

BEGIN
	Short;
	IF full THEN
		S("");
		Details
	END
END Usage;

PROCEDURE CliError*(err: INTEGER);
BEGIN
	CASE err OF
	  Cli.ErrWrongArgs:
		Usage(FALSE)
	| Cli.ErrTooLongSourceName:
		S("Too long name of source file"); Out.Ln
	| Cli.ErrTooLongOutName:
		S("Too long destination name"); Out.Ln
	| Cli.ErrOpenSource:
		S("Can not open source file")
	| Cli.ErrOpenH:
		S("Can not open destination .h file")
	| Cli.ErrOpenC:
		S("Can not open destination .c file")
	| Cli.ErrUnknownCommand:
		S("Unknown command");
		Usage(FALSE)
	| Cli.ErrNotEnoughArgs:
		S("Not enough count of arguments for command")
	| Cli.ErrTooLongModuleDirs:
		S("Too long overall length of paths to modules")
	| Cli.ErrTooManyModuleDirs:
		S("Too many paths to modules")
	| Cli.ErrTooLongCDirs:
		S("Too long overall length of paths to .c files")
	| Cli.ErrTooLongCc:
		S("Too long length of C compiler options")
	| Cli.ErrTooLongTemp:
		S("Too long name of temporary directory")
	| Cli.ErrCCompiler:
		S("Error during C compiler call")
	| Cli.ErrTooLongRunArgs:
		S("Too long command line options")
	| Cli.ErrUnexpectArg:
		S("Unexpected option")
	| Cli.ErrUnknownInit:
		S("Unknown initialization method")
	| Cli.ErrUnknownMemMan:
		S("Unknown kind of memory management")
	| Cli.ErrCantCreateOutDir:
		S("Can not create output directory")
	| Cli.ErrCantRemoveOutDir:
		S("Can not remove output directory")
	| Cli.ErrCantFoundCCompiler:
		S("Can not found C Compiler")

	| Cli.ErrOpenJava:
		S("Can not open output java file")
	| Cli.ErrJavaCompiler:
		S("Error during Java compiler calling")
	| Cli.ErrCantFoundJavaCompiler:
		S("Can not found Java compiler")
	| Cli.ErrTooLongJavaDirs:
		S("Too long overall length of paths to .java files")

	| Cli.ErrOpenJs:
		S("Can not open output .js file")
	| Cli.ErrTooLongJsDirs:
		S("Too long overall length of paths to .js files")

	| Cli.ErrOpenOberon:
		S("Can not open output Oberon module")

	| Cli.ErrDisabledGenC:
		S("Generation through C is disabled")
	| Cli.ErrDisabledGenJava:
		S("Generation through Java is disabled")
	| Cli.ErrDisabledGenJs:
		S("Generation through JavaScript is disabled")
	| Cli.ErrDisabledGenOberon:
		S("Generation through Oberon is disabled")
	END
END CliError;

END MessageEn.

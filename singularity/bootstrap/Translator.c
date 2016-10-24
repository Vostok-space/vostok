#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#include <o7c.h>

#include "Translator.h"

#define ErrNo_cnst 0
#define ErrWrongArgs_cnst ( - 1)
#define ErrTooLongSourceName_cnst ( - 2)
#define ErrTooLongOutName_cnst ( - 3)
#define ErrOpenSource_cnst ( - 4)
#define ErrOpenH_cnst ( - 5)
#define ErrOpenC_cnst ( - 6)
#define ErrParse_cnst ( - 7)

typedef struct Translator_ModuleProvider_s {
	struct Ast_RProvider _;
	struct Parser_Options opt;
	char unsigned path[4096];
	struct Translator_anon_0000 {
				struct Ast_RModule *first;
		struct Ast_RModule *last;
	} modules;
} *ModuleProvider;
o7c_tag_t Translator_ModuleProvider_s_tag;

static void ErrorMessage(int code);
static void ErrorMessage_O(char unsigned s[/*len0*/], int s_len0) {
	Out_String(s, s_len0);
}

static void ErrorMessage(int code) {
	Out_Int(code - Parser_ErrAstBegin_cnst, 0);
	Out_String(" ", 2);
	if (code <= Parser_ErrAstBegin_cnst) {
		{ int o7c_case_expr = code - Parser_ErrAstBegin_cnst;
			switch (o7c_case_expr) {
			case -1:
				ErrorMessage_O("Ast.ErrImportNameDuplicate", 27);
				break;
			case -2:
				ErrorMessage_O("Повторное объявление имени в той же области видимости", 100);
				break;
			case -3:
				ErrorMessage_O("Ast.ErrReturnInModuleInit", 26);
				break;
			case -4:
				ErrorMessage_O("st.ErrMultExprDifferenTypes", 28);
				break;
			case -5:
				ErrorMessage_O("Ast.ErrNotBoolInLogicExpr", 26);
				break;
			case -6:
				ErrorMessage_O("Ast.ErrNotIntInDivOrMod", 24);
				break;
			case -7:
				ErrorMessage_O("Ast.ErrNotRealTypeForRealDiv", 29);
				break;
			case -8:
				ErrorMessage_O("Ast.ErrIntDivByZero", 20);
				break;
			case -9:
				ErrorMessage_O("Ast.ErrNotIntSetElem", 21);
				break;
			case -10:
				ErrorMessage_O("Ast.ErrSetElemOutOfRange", 25);
				break;
			case -11:
				ErrorMessage_O("Ast.ErrSetLeftElemBiggerRightElem", 34);
				break;
			case -12:
				ErrorMessage_O("Ast.ErrAddExprDifferenTypes", 28);
				break;
			case -13:
				ErrorMessage_O("Ast.ErrNotNumberAndNotSetInMul", 31);
				break;
			case -14:
				ErrorMessage_O("Ast.ErrNotNumberAndNotSetInAdd", 31);
				break;
			case -15:
				ErrorMessage_O("Ast.ErrSignForBool", 19);
				break;
			case -16:
				ErrorMessage_O("Ast.ErrNotNumberAndNotSetInMult", 32);
				break;
			case -17:
				ErrorMessage_O("Типы подвыражений в сравнении не совпадают", 80);
				break;
			case -18:
				ErrorMessage_O("Ast.ErrExprInWrongTypes", 24);
				break;
			case -19:
				ErrorMessage_O("Ast.ErrExprInRightNotSet", 25);
				break;
			case -20:
				ErrorMessage_O("Ast.ErrExprInLeftNotInteger", 28);
				break;
			case -21:
				ErrorMessage_O("Ast.ErrRelIncompatibleType", 27);
				break;
			case -22:
				ErrorMessage_O("Операция IS применима только к записям", 70);
				break;
			case -23:
				ErrorMessage_O("Ast.ErrIsExtVarNotRecord", 25);
				break;
			case -24:
				ErrorMessage_O("Постоянная сопоставляется выражению, невычислимым на этапе перевода", 128);
				break;
			case -25:
				ErrorMessage_O("Несовместимые типы в присваивании", 64);
				break;
			case -26:
				ErrorMessage_O("Ast.ErrCallNotProc", 19);
				break;
			case -28:
				ErrorMessage_O("Возвращаемое значение не задействовано в выражении", 96);
				break;
			case -27:
				ErrorMessage_O("Вызываемая процедура не возвращает значения", 83);
				break;
			case -29:
				ErrorMessage_O("Лишние параметры при вызове процедуры", 71);
				break;
			case -30:
				ErrorMessage_O("Несовместимый тип параметра", 53);
				break;
			case -31:
				ErrorMessage_O("Параметр должен быть изменяемым значением", 79);
				break;
			case -32:
				ErrorMessage_O("Не хватает фактических параметров в вызове процедуры", 99);
				break;
			case -33:
				ErrorMessage_O("Ast.ErrCaseExprNotIntOrChar", 28);
				break;
			case -34:
				ErrorMessage_O("Ast.ErrCaseElemExprTypeMismatch", 32);
				break;
			case -35:
				ErrorMessage_O("Ast.ErrCaseElemExprNotConst", 28);
				break;
			case -36:
				ErrorMessage_O("Ast.ErrCaseElemDuplicate", 25);
				break;
			case -37:
				ErrorMessage_O("Не совпадает тип меток CASE", 47);
				break;
			case -38:
				ErrorMessage_O("Ast.ErrCaseLabelLeftGreaterRight", 33);
				break;
			case -39:
				ErrorMessage_O("Ast.ErrCaseLabelNotConst", 25);
				break;
			case -40:
				ErrorMessage_O("Процедура не имеет возвращаемого значения", 79);
				break;
			case -41:
				ErrorMessage_O("Тип возвращаемого значения не совместим типом, указанном в заголовке процедуры", 147);
				break;
			case -42:
				ErrorMessage_O("Ожидался возврат значения, так как в заголовке процедуры указан возвращаемый тип", 150);
				break;
			case -43:
				ErrorMessage_O("Предварительное объявление имени не было найдено", 92);
				break;
			case -44:
				ErrorMessage_O("Недопустимое использование константы для задания собственного значения", 135);
				break;
			case -45:
				ErrorMessage_O("Импортированный модуль не был найден", 69);
				break;
			case -46:
				ErrorMessage_O("Импортированный модуль содержит ошибки", 74);
				break;
			case -49:
				ErrorMessage_O("Ast.ErrNotImplemented", 22);
				break;
			default:
				abort();
				break;
			}
		}
	} else {
		switch (code) {
		case -1:
			ErrorMessage_O("Неожиданный символ в тексте", 52);
			break;
		case -2:
			ErrorMessage_O("Значение константы слишком велико", 64);
			break;
		case -3:
			ErrorMessage_O("ErrRealScaleTooBig", 19);
			break;
		case -4:
			ErrorMessage_O("ErrWordLenTooBig", 17);
			break;
		case -5:
			ErrorMessage_O("ErrExpectHOrX", 14);
			break;
		case -6:
			ErrorMessage_O("ErrExpectDQuote", 16);
			break;
		case -7:
			ErrorMessage_O("ErrExpectDigitInScale", 22);
			break;
		case -8:
			ErrorMessage_O("Незакрытый комментарий", 44);
			break;
		case -21:
			ErrorMessage_O("Ожидается 'MODULE'", 28);
			break;
		case -22:
			ErrorMessage_O("Ожидается имя", 26);
			break;
		case -23:
			ErrorMessage_O("Ожидается ':'", 23);
			break;
		case -24:
			ErrorMessage_O("Ожидается ';'", 23);
			break;
		case -25:
			ErrorMessage_O("Ожидается 'END'", 25);
			break;
		case -26:
			ErrorMessage_O("Ожидается '.'", 23);
			break;
		case -27:
			ErrorMessage_O("Ожидается имя модуля", 39);
			break;
		case -28:
			ErrorMessage_O("Ожидается '='", 23);
			break;
		case -29:
			ErrorMessage_O("Ожидается ')'", 23);
			break;
		case -30:
			ErrorMessage_O("Ожидается ']'", 23);
			break;
		case -31:
			ErrorMessage_O("Ожидается '}'", 23);
			break;
		case -32:
			ErrorMessage_O("Ожидается OF", 22);
			break;
		case -34:
			ErrorMessage_O("Ожидается константное целочисленное выражение", 88);
			break;
		case -35:
			ErrorMessage_O("ErrExpectTo", 12);
			break;
		case -36:
			ErrorMessage_O("ErrExpectNamedType", 19);
			break;
		case -37:
			ErrorMessage_O("Ожидается запись", 32);
			break;
		case -38:
			ErrorMessage_O("Ожидается оператор", 36);
			break;
		case -39:
			ErrorMessage_O("ErrExpectThen", 14);
			break;
		case -40:
			ErrorMessage_O("ErrExpectAssign", 16);
			break;
		case -41:
			ErrorMessage_O("ErrExpectAssignOrBrace1Open", 28);
			break;
		case -42:
			ErrorMessage_O("Ожидается переменная типа запись либо указателя на неё", 102);
			break;
		case -43:
			ErrorMessage_O("ErrExpectPointer", 17);
			break;
		case -44:
			ErrorMessage_O("Ожидается тип", 26);
			break;
		case -45:
			ErrorMessage_O("Ожидается UNTIL", 25);
			break;
		case -46:
			ErrorMessage_O("ErrExpectDo", 12);
			break;
		case -47:
			ErrorMessage_O("ErrExpectVarArray", 18);
			break;
		case -48:
			ErrorMessage_O("ErrExpectDesignator", 20);
			break;
		case -49:
			ErrorMessage_O("ErrExpectVar", 13);
			break;
		case -50:
			ErrorMessage_O("Ожидается процедура", 38);
			break;
		case -51:
			ErrorMessage_O("ErrExpectConstName", 19);
			break;
		case -52:
			ErrorMessage_O("Ожидается завершающее имя процедуры", 68);
			break;
		case -53:
			ErrorMessage_O("Ожидается выражение", 38);
			break;
		case -55:
			ErrorMessage_O("Лишняя ';'", 17);
			break;
		case -70:
			ErrorMessage_O("Завершающее имя в конце модуля не совпадает с его именем", 104);
			break;
		case -71:
			ErrorMessage_O("ErrDeclarationNotVar", 21);
			break;
		case -72:
			ErrorMessage_O("ErrArrayDimensionsTooMany", 26);
			break;
		case -73:
			ErrorMessage_O("Завершающее имя в теле процедуры не совпадает с её именем", 106);
			break;
		case -74:
			ErrorMessage_O("Объявление процедуры с возвращаемым значением не содержит скобки", 122);
			break;
		case -75:
			ErrorMessage_O("Длина массива должна быть > 0", 52);
			break;
		case -90:
			ErrorMessage_O("Не реализовано", 28);
			break;
		default:
			abort();
			break;
		}
	}
}

static void PrintErrors(Ast_Error err, o7c_tag_t err_tag) {
	int i;

	Out_String("с ошибками: ", 22);
	Out_Ln();
	i = 0;
	while (err != NULL) {
		i++;
		Out_Int(i, 2);
		Out_String(") ", 3);
		ErrorMessage(err->code);
		Out_String(" ", 2);
		Out_Int(err->line + 1, 0);
		Out_String(" : ", 4);
		Out_Int(err->column + err->tabs * 3, 0);
		Out_Ln();
		err = err->next;
	}
}

static int LenStr(char unsigned str[/*len0*/], int str_len0, int ofs) {
	int i;

	i = ofs;
	while (str[i] != 0x00u) {
		i++;
	}
	return i - ofs;
}

static void CopyPath(char unsigned str[/*len0*/], int str_len0, int arg) {
	int i;

	i = 0;
	while ((arg < CLI_count) && CLI_Get(str, str_len0, &i, arg)) {
		i++;
		arg++;
	}
	if (i + 1 < str_len0) {
		str[i + 1] = 0x00u;
	} else {
		str[str_len0 - 1] = 0x00u;
		str[str_len0 - 2] = 0x00u;
		str[str_len0 - 3] = (char unsigned)'#';
	}
}

static struct Ast_RModule *SearchModule(struct Translator_ModuleProvider_s *mp, o7c_tag_t mp_tag, char unsigned name[/*len0*/], int name_len0, int ofs, int end) {
	struct Ast_RModule *m;

	m = mp->modules.first;
	while ((m != NULL) && !StringStore_IsEqualToChars(&m->_._.name, StringStore_String_tag, name, name_len0, ofs, end)) {
		assert(m != m->_._.module);
		m = m->_._.module;
	}
	return m;
}

static void AddModule(struct Translator_ModuleProvider_s *mp, o7c_tag_t mp_tag, struct Ast_RModule *m, o7c_tag_t m_tag) {
	assert(m->_._.module == m);
	m->_._.module = NULL;
	if (mp->modules.first == NULL) {
		mp->modules.first = m;
	} else {
		mp->modules.last->_._.module = m;
	}
	mp->modules.last = m;
}

static struct Ast_RModule *GetModule(struct Ast_RProvider *p, o7c_tag_t p_tag, struct Ast_RModule *host, o7c_tag_t host_tag, char unsigned name[/*len0*/], int name_len0, int ofs, int end);
static struct VFileStream_RIn *GetModule_Open(struct Translator_ModuleProvider_s *p, o7c_tag_t p_tag, int *pathOfs, char unsigned name[/*len0*/], int name_len0, int ofs, int end) {
	char unsigned n[1024];
	int len;
	int l;
	struct VFileStream_RIn *in_;

	len = LenStr(p->path, 4096, (*pathOfs));
	l = 0;
	if ((len > 0) && StringStore_CopyChars(n, 1024, &l, p->path, 4096, (*pathOfs), (*pathOfs) + len) && StringStore_CopyChars(n, 1024, &l, "/", 2, 0, 1) && StringStore_CopyChars(n, 1024, &l, name, name_len0, ofs, end) && StringStore_CopyChars(n, 1024, &l, ".ob07", 6, 0, 5)) {
		Log_Str("Открыть ", 16);
		Log_Str(n, 1024);
		Log_Ln();
		in_ = VFileStream_OpenIn(n, 1024);
	} else {
		in_ = NULL;
	}
	(*pathOfs) = (*pathOfs) + len + 2;
	return in_;
}

static struct Ast_RModule *GetModule(struct Ast_RProvider *p, o7c_tag_t p_tag, struct Ast_RModule *host, o7c_tag_t host_tag, char unsigned name[/*len0*/], int name_len0, int ofs, int end) {
	struct Ast_RModule *m;
	struct VFileStream_RIn *source;
	struct Translator_ModuleProvider_s *mp;
	int pathOfs;

	mp = (&O7C_GUARD(Translator_ModuleProvider_s, p, NULL));
	m = SearchModule(mp, NULL, name, name_len0, ofs, end);
	if (m != NULL) {
		Log_StrLn("Найден уже разобранный модуль", 56);
	} else {
		pathOfs = 0;
		do {
			source = GetModule_Open(mp, NULL, &pathOfs, name, name_len0, ofs, end);
		} while (!((source != NULL) || (mp->path[pathOfs] == 0x00u)));
		if (source != NULL) {
			m = Parser_Parse(&source->_, NULL, p, NULL, &mp->opt, Parser_Options_tag);
			VFileStream_CloseIn(&source, NULL);
			AddModule(mp, NULL, m, NULL);
		} else {
			Out_String("Не получается найти или открыть файл импортированного модуля", 114);
			Out_Ln();
		}
	}
	return m;
}

static int OpenOutput(struct VFileStream_ROut **interface_, o7c_tag_t interface__tag, struct VFileStream_ROut **implementation, o7c_tag_t implementation_tag, bool *isMain) {
	char unsigned dest[1024];
	int destLen;
	int ret;

	(*interface_) = NULL;
	(*implementation) = NULL;
	destLen = 0;
	if (!(CLI_Get(dest, 1024, &destLen, 2) && (destLen < sizeof(dest) / sizeof (dest[0]) - 2))) {
		ret = ErrTooLongOutName_cnst;
	} else {
		(*isMain) = (destLen > 3) && (dest[destLen - 3] == (char unsigned)'.') && (dest[destLen - 2] == (char unsigned)'c');
		if ((*isMain)) {
			destLen -= 2;
		}
		dest[destLen - 1] = (char unsigned)'.';
		dest[destLen] = (char unsigned)'h';
		dest[destLen + 1] = 0x00u;
		(*interface_) = VFileStream_OpenOut(dest, 1024);
		if ((*interface_) == NULL) {
			ret = ErrOpenH_cnst;
		} else {
			dest[destLen] = (char unsigned)'c';
			(*implementation) = VFileStream_OpenOut(dest, 1024);
			if ((*implementation) == NULL) {
				VFileStream_CloseOut(&(*interface_), NULL);
				ret = ErrOpenC_cnst;
			} else {
				ret = 0;
			}
		}
	}
	return ret;
}

static int Compile(struct Translator_ModuleProvider_s *mp, o7c_tag_t mp_tag, struct VFileStream_RIn *source, o7c_tag_t source_tag) {
	struct Ast_RModule *module;
	struct GeneratorC_Generator intGen;
	struct GeneratorC_Generator realGen;
	GeneratorC_Options opt;
	struct VFileStream_ROut *interface_;
	struct VFileStream_ROut *implementation;
	int ret;
	bool isMain;

	module = Parser_Parse(&source->_, NULL, &mp->_, NULL, &mp->opt, Parser_Options_tag);
	VFileStream_CloseIn(&source, NULL);
	if (module == NULL) {
		Out_String("Ожидается MODULE", 26);
		Out_Ln();
		ret = ErrParse_cnst;
	} else if (module->errors != NULL) {
		PrintErrors(module->errors, NULL);
		ret = ErrParse_cnst;
	} else {
		Out_String("Модуль переведён без ошибок", 52);
		Out_Ln();
		ret = OpenOutput(&interface_, NULL, &implementation, NULL, &isMain);
		if (ret == 0) {
			GeneratorC_Init(&intGen, GeneratorC_Generator_tag, &interface_->_, NULL);
			GeneratorC_Init(&realGen, GeneratorC_Generator_tag, &implementation->_, NULL);
			opt = GeneratorC_DefaultOptions();
			opt->main_ = isMain;
			GeneratorC_Generate(&intGen, GeneratorC_Generator_tag, &realGen, GeneratorC_Generator_tag, module, NULL, opt, NULL);
			VFileStream_CloseOut(&interface_, NULL);
			VFileStream_CloseOut(&implementation, NULL);
		}
	}
	return ret;
}

static struct Translator_ModuleProvider_s *NewProvider(void) {
	struct Translator_ModuleProvider_s *mp;

	mp = o7c_new(sizeof(*mp), Translator_ModuleProvider_s_tag);
	Ast_ProviderInit(&mp->_, NULL, GetModule);
	Parser_DefaultOptions(&mp->opt, Parser_Options_tag);
	mp->opt.printError = ErrorMessage;
	CopyPath(mp->path, 4096, 3);
	mp->modules.first = NULL;
	mp->modules.last = NULL;
	return mp;
}

static void ErrMessage(int err) {
	switch (err) {
	case -1:
		Out_String("Использование: ", 29);
		Out_String("  o7c исходный.ob07 результат {пути}", 58);
		Out_Ln();
		Out_String("  где пути ведут к интерфейсным модулям", 72);
		Out_Ln();
		Out_String("В случае успешной трансляции создаст два файла языка Си, соответствующих исходному", 154);
		Out_Ln();
		Out_String("на Обероне: результат.h и результат.c.", 67);
		Out_Ln();
		Out_String("Пути для поиска модулей следует разделять пробелами.", 98);
		break;
	case -2:
		Out_String("Слишком длинное имя исходного файла", 67);
		Out_Ln();
		break;
	case -3:
		Out_String("Слишком длинное выходное имя", 54);
		Out_Ln();
		break;
	case -4:
		Out_String("Не получается открыть исходный файл", 67);
		break;
	case -5:
		Out_String("Не получается открыть выходной .h файл", 70);
		break;
	case -6:
		Out_String("Не получается открыть выходной .c файл", 70);
		break;
	case -7:
		Out_String("Ошибка разбора исходного файла", 58);
		break;
	default:
		abort();
		break;
	}
	Out_Ln();
}

static void Main(void) {
	char unsigned src[1024];
	int srcLen;
	int ret;
	struct VFileStream_RIn *source;

	Out_Open();
	Log_Turn(false);
	if (CLI_count <= 2) {
		ret = ErrWrongArgs_cnst;
	} else {
		srcLen = 0;
		if (!CLI_Get(src, 1024, &srcLen, 1)) {
			ret = ErrTooLongSourceName_cnst;
		} else {
			source = VFileStream_OpenIn(src, 1024);
			if (source == NULL) {
				ret = ErrOpenSource_cnst;
			} else {
				ret = Compile(NewProvider(), NULL, source, NULL);
			}
		}
	}
	if (ret != 0) {
		ErrMessage(ret);
		CLI_SetExitCode(1);
	}
}

extern int main(int argc, char **argv) {
	o7c_init(argc, argv);
	Log_init_();
	Out_init_();
	CLI_init_();
	VFileStream_init_();
	Utf8_init_();
	StringStore_init_();
	Parser_init_();
	Scanner_init_();
	Ast_init_();
	GeneratorC_init_();
	TranslatorLimits_init_();

	o7c_tag_init(Translator_ModuleProvider_s_tag, Ast_RProvider_tag);

	Main();
	return o7c_exit_code;
}

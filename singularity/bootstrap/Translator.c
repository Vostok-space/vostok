#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#define O7C_BOOL_UNDEFINED
#include <o7c.h>

#include "Log.h"
#include "Out.h"
#include "CLI.h"
#include "VFileStream.h"
#include "Utf8.h"
#include "StringStore.h"
#include "Parser.h"
#include "Scanner.h"
#include "Ast.h"
#include "GeneratorC.h"
#include "TranslatorLimits.h"

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
	o7c_char fileExt[32];
	int extLen;
	o7c_char path[4096];
	struct Translator_anon_0000 {
		struct Ast_RModule *first;
		struct Ast_RModule *last;
	} modules;
} *ModuleProvider;
static o7c_tag_t Translator_ModuleProvider_s_tag;


static void ErrorMessage(int code);
static void ErrorMessage_O(o7c_char s[/*len0*/], int s_len0) {
	Out_String(s, s_len0);
}

static void ErrorMessage(int code) {
	Out_Int(o7c_sub(code, Parser_ErrAstBegin_cnst), 0);
	Out_String(" ", 2);
	if (o7c_cmp(code, Parser_ErrAstBegin_cnst) <=  0) {
		{ int o7c_case_expr = o7c_sub(code, Parser_ErrAstBegin_cnst);
			switch (o7c_case_expr) {
			case -1:
				ErrorMessage_O("Имя модуля уже встречается в списке импорта", 81);
				break;
			case -2:
				ErrorMessage_O("Повторное объявление имени в той же области видимости", 100);
				break;
			case -3:
				ErrorMessage_O("Типы подвыражений в умножении несовместимы", 81);
				break;
			case -4:
				ErrorMessage_O("Типы подвыражений в делении несовместимы", 77);
				break;
			case -5:
				ErrorMessage_O("В логическом выражении должны использоваться подвыражении логического типа", 142);
				break;
			case -6:
				ErrorMessage_O("В целочисленном делении допустимы только целочисленные подвыражения", 129);
				break;
			case -7:
				ErrorMessage_O("В дробном делении допустимы только подвыражения дробного типа", 116);
				break;
			case -8:
				ErrorMessage_O("Деление на 0", 22);
				break;
			case -9:
				ErrorMessage_O("В качестве элементов множества допустимы только целые числа", 112);
				break;
			case -10:
				ErrorMessage_O("Элемент множества выходит за границы возможных значений - 0 .. 31", 115);
				break;
			case -11:
				ErrorMessage_O("Левый элемент диапазона больше правого", 73);
				break;
			case -12:
				ErrorMessage_O("Типы подвыражений в сложении несовместимы", 79);
				break;
			case -13:
				ErrorMessage_O("В выражениях *, /, DIV, MOD допустимы только числа и множества", 104);
				break;
			case -14:
				ErrorMessage_O("В выражениях +, - допустимы только числа и множества", 94);
				break;
			case -15:
				ErrorMessage_O("Унарный знак не применим к логическому выражению", 91);
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
				ErrorMessage_O("Левый член выражения IN должен быть целочисленным", 91);
				break;
			case -21:
				ErrorMessage_O("В сравнении выражения несовместимых типов", 79);
				break;
			case -22:
				ErrorMessage_O("Проверка IS применима только к записям", 70);
				break;
			case -23:
				ErrorMessage_O("Левый член проверки IS должен иметь тип записи или указателя на неё", 122);
				break;
			case -24:
				ErrorMessage_O("Постоянная сопоставляется выражению, невычислимым на этапе перевода", 128);
				break;
			case -25:
				ErrorMessage_O("Несовместимые типы в присваивании", 64);
				break;
			case -26:
				ErrorMessage_O("Вызов допустим только для процедур и переменных процедурного типа", 123);
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
			case -58:
				ErrorMessage_O("Для переменного параметра - указателя должен использоваться аргумент того же типа", 152);
				break;
			case -32:
				ErrorMessage_O("Не хватает фактических параметров в вызове процедуры", 99);
				break;
			case -33:
				ErrorMessage_O("Выражение в CASE должно быть целочисленным или литерой", 98);
				break;
			case -34:
				ErrorMessage_O("Метки CASE должно быть целочисленными или литерами", 91);
				break;
			case -36:
				ErrorMessage_O("Дублирование значения меток в CASE", 61);
				break;
			case -37:
				ErrorMessage_O("Не совпадает тип меток CASE", 47);
				break;
			case -38:
				ErrorMessage_O("Левая часть диапазона значений в метке CASE должна быть меньше правой", 125);
				break;
			case -39:
				ErrorMessage_O("Метки CASE должны быть константами", 61);
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
			case -47:
				ErrorMessage_O("Разыменовывание применено не к указателю", 77);
				break;
			case -48:
				ErrorMessage_O("Получение элемента не массива", 56);
				break;
			case -49:
				ErrorMessage_O("Индекс массива не целочисленный", 60);
				break;
			case -50:
				ErrorMessage_O("Отрицательный индекс массива", 55);
				break;
			case -51:
				ErrorMessage_O("Индекс массива выходит за его границы", 70);
				break;
			case -52:
				ErrorMessage_O("В защите типа ожидается расширенная запись", 80);
				break;
			case -53:
				ErrorMessage_O("В защите типа ожидается указатель на расширенную запись", 104);
				break;
			case -54:
				ErrorMessage_O("В защите типа переменная должна быть либо записью, либо указателем на запись", 141);
				break;
			case -55:
				ErrorMessage_O("Селектор элемента записи применён не к записи", 85);
				break;
			case -56:
				ErrorMessage_O("Ожидалась переменная", 40);
				break;
			case -57:
				ErrorMessage_O("Итератор FOR не целочисленного типа", 64);
				break;
			case -59:
				ErrorMessage_O("Выражение в охране условного оператора должно быть логическим", 116);
				break;
			case -60:
				ErrorMessage_O("Выражение в охране цикла WHILE должно быть логическим", 95);
				break;
			case -61:
				ErrorMessage_O("Охрана цикла WHILE всегда ложна", 54);
				break;
			case -62:
				ErrorMessage_O("Цикл бесконечен, так как охрана WHILE всегда истинна", 92);
				break;
			case -63:
				ErrorMessage_O("Выражение в условии завершения цикла REPEAT должно быть логическим", 119);
				break;
			case -64:
				ErrorMessage_O("Цикл бесконечен, так как условие завершения всегда ложно", 105);
				break;
			case -65:
				ErrorMessage_O("Условие завершения всегда истинно", 64);
				break;
			case -66:
				ErrorMessage_O("Объявление не экспортировано", 55);
				break;
			case -67:
				ErrorMessage_O("Логическое отрицание применено не к логическому типу", 99);
				break;
			case -99:
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
		case -101:
			ErrorMessage_O("Ожидается 'MODULE'", 28);
			break;
		case -102:
			ErrorMessage_O("Ожидается имя", 26);
			break;
		case -103:
			ErrorMessage_O("Ожидается ':'", 23);
			break;
		case -104:
			ErrorMessage_O("Ожидается ';'", 23);
			break;
		case -105:
			ErrorMessage_O("Ожидается 'END'", 25);
			break;
		case -106:
			ErrorMessage_O("Ожидается '.'", 23);
			break;
		case -107:
			ErrorMessage_O("Ожидается имя модуля", 39);
			break;
		case -108:
			ErrorMessage_O("Ожидается '='", 23);
			break;
		case -109:
			ErrorMessage_O("Ожидается ')'", 23);
			break;
		case -110:
			ErrorMessage_O("Ожидается ']'", 23);
			break;
		case -111:
			ErrorMessage_O("Ожидается '}'", 23);
			break;
		case -112:
			ErrorMessage_O("Ожидается OF", 22);
			break;
		case -114:
			ErrorMessage_O("Ожидается константное целочисленное выражение", 88);
			break;
		case -115:
			ErrorMessage_O("Ожидается TO", 22);
			break;
		case -116:
			ErrorMessage_O("Ожидается структурный тип: массив, запись, указатель, процедурный", 121);
			break;
		case -117:
			ErrorMessage_O("Ожидается запись", 32);
			break;
		case -118:
			ErrorMessage_O("Ожидается оператор", 36);
			break;
		case -119:
			ErrorMessage_O("Ожидается THEN", 24);
			break;
		case -120:
			ErrorMessage_O("Ожидается :=", 22);
			break;
		case -122:
			ErrorMessage_O("Ожидается переменная типа запись либо указателя на неё", 102);
			break;
		case -124:
			ErrorMessage_O("Ожидается тип", 26);
			break;
		case -125:
			ErrorMessage_O("Ожидается UNTIL", 25);
			break;
		case -126:
			ErrorMessage_O("Ожидается DO", 22);
			break;
		case -128:
			ErrorMessage_O("Ожидается обозначение", 42);
			break;
		case -130:
			ErrorMessage_O("Ожидается процедура", 38);
			break;
		case -131:
			ErrorMessage_O("Ожидается имя константы", 45);
			break;
		case -132:
			ErrorMessage_O("Ожидается завершающее имя процедуры", 68);
			break;
		case -133:
			ErrorMessage_O("Ожидается выражение", 38);
			break;
		case -135:
			ErrorMessage_O("Лишняя ';'", 17);
			break;
		case -150:
			ErrorMessage_O("Завершающее имя в конце модуля не совпадает с его именем", 104);
			break;
		case -151:
			ErrorMessage_O("Слишком большая n-мерность массива", 64);
			break;
		case -152:
			ErrorMessage_O("Завершающее имя в теле процедуры не совпадает с её именем", 106);
			break;
		case -153:
			ErrorMessage_O("Объявление процедуры с возвращаемым значением не содержит скобки", 122);
			break;
		case -154:
			ErrorMessage_O("Длина массива должна быть > 0", 52);
			break;
		case -170:
			ErrorMessage_O("Не реализовано", 28);
			break;
		default:
			abort();
			break;
		}
	}
}

static void PrintErrors(Ast_Error err) {
	int i = O7C_INT_UNDEF;

	o7c_retain(err);
	Out_String("с ошибками: ", 22);
	Out_Ln();
	i = 0;
	while (err != NULL) {
		i = o7c_add(i, 1);;
		Out_Int(i, 2);
		Out_String(") ", 3);
		ErrorMessage(err->code);
		Out_String(" ", 2);
		Out_Int(o7c_add(err->line, 1), 0);
		Out_String(" : ", 4);
		Out_Int(o7c_add(err->column, o7c_mul(err->tabs, 3)), 0);
		Out_Ln();
		O7C_ASSIGN(&(err), err->next);
	}
	o7c_release(err);
}

static int LenStr(o7c_char str[/*len0*/], int str_len0, int ofs) {
	int o7c_return;

	int i = O7C_INT_UNDEF;

	i = ofs;
	while (str[o7c_ind(str_len0, i)] != 0x00u) {
		i = o7c_add(i, 1);;
	}
	o7c_return = o7c_sub(i, ofs);
	return o7c_return;
}

static void CopyPath(o7c_char str[/*len0*/], int str_len0, int arg) {
	int i = O7C_INT_UNDEF;

	i = 0;
	while ((o7c_cmp(arg, CLI_count) <  0) && CLI_Get(str, str_len0, &i, arg)) {
		i = o7c_add(i, 1);;
		arg = o7c_add(arg, 1);;
	}
	if (o7c_cmp(o7c_add(i, 1), str_len0) <  0) {
		str[o7c_ind(str_len0, o7c_add(i, 1))] = 0x00u;
	} else {
		str[o7c_ind(str_len0, o7c_sub(str_len0, 1))] = 0x00u;
		str[o7c_ind(str_len0, o7c_sub(str_len0, 2))] = 0x00u;
		str[o7c_ind(str_len0, o7c_sub(str_len0, 3))] = (char unsigned)'#';
	}
}

static struct Ast_RModule *SearchModule(struct Translator_ModuleProvider_s *mp, o7c_char name[/*len0*/], int name_len0, int ofs, int end) {
	Ast_Module o7c_return = NULL;

	struct Ast_RModule *m = NULL;

	o7c_retain(mp);
	O7C_ASSIGN(&(m), mp->modules.first);
	while ((m != NULL) && !StringStore_IsEqualToChars(&m->_._.name, StringStore_String_tag, name, name_len0, ofs, end)) {
		assert(m != m->_._.module);
		O7C_ASSIGN(&(m), m->_._.module);
	}
	O7C_ASSIGN(&o7c_return, m);
	o7c_release(m);
	o7c_release(mp);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static void AddModule(struct Translator_ModuleProvider_s *mp, struct Ast_RModule *m) {
	o7c_retain(mp); o7c_retain(m);
	assert(m->_._.module == m);
	O7C_ASSIGN(&(m->_._.module), NULL);
	if (mp->modules.first == NULL) {
		O7C_ASSIGN(&(mp->modules.first), m);
	} else {
		O7C_ASSIGN(&(mp->modules.last->_._.module), m);
	}
	O7C_ASSIGN(&(mp->modules.last), m);
	o7c_release(mp); o7c_release(m);
}

static struct Ast_RModule *GetModule(struct Ast_RProvider *p, struct Ast_RModule *host, o7c_char name[/*len0*/], int name_len0, int ofs, int end);
static struct VFileStream_RIn *GetModule_Open(struct Translator_ModuleProvider_s *p, int *pathOfs, o7c_char name[/*len0*/], int name_len0, int ofs, int end) {
	VFileStream_In o7c_return = NULL;

	o7c_char n[1024] /* init array */;
	int len = O7C_INT_UNDEF, l = O7C_INT_UNDEF;
	struct VFileStream_RIn *in_ = NULL;
	memset(&n, 0, sizeof(n));

	o7c_retain(p);
	len = LenStr(p->path, 4096, (*pathOfs));
	l = 0;
	if ((o7c_cmp(len, 0) >  0) && StringStore_CopyChars(n, 1024, &l, p->path, 4096, (*pathOfs), o7c_add((*pathOfs), len)) && StringStore_CopyChars(n, 1024, &l, "/", 2, 0, 1) && StringStore_CopyChars(n, 1024, &l, name, name_len0, ofs, end) && StringStore_CopyChars(n, 1024, &l, p->fileExt, 32, 0, p->extLen)) {
		Log_Str("Открыть ", 16);
		Log_Str(n, 1024);
		Log_Ln();
		O7C_ASSIGN(&(in_), VFileStream_OpenIn(n, 1024));
	} else {
		O7C_ASSIGN(&(in_), NULL);
	}
	(*pathOfs) = o7c_add(o7c_add((*pathOfs), len), 2);
	O7C_ASSIGN(&o7c_return, in_);
	o7c_release(in_);
	o7c_release(p);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static struct Ast_RModule *GetModule(struct Ast_RProvider *p, struct Ast_RModule *host, o7c_char name[/*len0*/], int name_len0, int ofs, int end) {
	Ast_Module o7c_return = NULL;

	struct Ast_RModule *m = NULL;
	struct VFileStream_RIn *source = NULL;
	struct Translator_ModuleProvider_s *mp = NULL;
	int pathOfs = O7C_INT_UNDEF;

	o7c_retain(p); o7c_retain(host);
	O7C_ASSIGN(&(mp), O7C_GUARD(Translator_ModuleProvider_s, &p));
	O7C_ASSIGN(&(m), SearchModule(mp, name, name_len0, ofs, end));
	if (m != NULL) {
		Log_StrLn("Найден уже разобранный модуль", 56);
	} else {
		pathOfs = 0;
		do {
			O7C_ASSIGN(&(source), GetModule_Open(mp, &pathOfs, name, name_len0, ofs, end));
		} while (!((source != NULL) || (mp->path[o7c_ind(4096, pathOfs)] == 0x00u)));
		if (source != NULL) {
			O7C_ASSIGN(&(m), Parser_Parse(&source->_, p, &mp->opt, Parser_Options_tag));
			VFileStream_CloseIn(&source);
			AddModule(mp, m);
		} else {
			Out_String("Не получается найти или открыть файл импортированного модуля", 114);
			Out_Ln();
		}
	}
	O7C_ASSIGN(&o7c_return, m);
	o7c_release(m); o7c_release(source); o7c_release(mp);
	o7c_release(p); o7c_release(host);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static int OpenOutput(struct VFileStream_ROut **interface_, struct VFileStream_ROut **implementation, o7c_bool *isMain) {
	int o7c_return;

	o7c_char dest[1024] /* init array */;
	int destLen = O7C_INT_UNDEF, ret = O7C_INT_UNDEF;
	memset(&dest, 0, sizeof(dest));

	O7C_ASSIGN(&((*interface_)), NULL);
	O7C_ASSIGN(&((*implementation)), NULL);
	destLen = 0;
	if (!(CLI_Get(dest, 1024, &destLen, 2) && (o7c_cmp(destLen, sizeof(dest) / sizeof (dest[0]) - 2) <  0))) {
		ret = ErrTooLongOutName_cnst;
	} else {
		(*isMain) = (o7c_cmp(destLen, 3) >  0) && (dest[o7c_ind(1024, o7c_sub(destLen, 3))] == (char unsigned)'.') && (dest[o7c_ind(1024, o7c_sub(destLen, 2))] == (char unsigned)'c');
		if ((*isMain)) {
			destLen = o7c_sub(destLen, 2);;
		}
		dest[o7c_ind(1024, o7c_sub(destLen, 1))] = (char unsigned)'.';
		dest[o7c_ind(1024, o7c_add(destLen, 1))] = 0x00u;
		if (!(*isMain)) {
			dest[o7c_ind(1024, destLen)] = (char unsigned)'h';
			O7C_ASSIGN(&((*interface_)), VFileStream_OpenOut(dest, 1024));
		}
		if (((*interface_) == NULL) && !(*isMain)) {
			ret = ErrOpenH_cnst;
		} else {
			dest[o7c_ind(1024, destLen)] = (char unsigned)'c';
			O7C_ASSIGN(&((*implementation)), VFileStream_OpenOut(dest, 1024));
			if ((*implementation) == NULL) {
				VFileStream_CloseOut(&(*interface_));
				ret = ErrOpenC_cnst;
			} else {
				ret = ErrNo_cnst;
			}
		}
	}
	o7c_return = ret;
	return o7c_return;
}

static int Compile(struct Translator_ModuleProvider_s *mp, struct VFileStream_RIn *source) {
	int o7c_return;

	struct Ast_RModule *module = NULL;
	struct GeneratorC_Generator intGen /* record init */, realGen /* record init */;
	GeneratorC_Options opt = NULL;
	struct VFileStream_ROut *interface_ = NULL, *implementation = NULL;
	int ret = O7C_INT_UNDEF;
	o7c_bool isMain = O7C_BOOL_UNDEF;
	memset(&intGen, 0, sizeof(intGen));
	memset(&realGen, 0, sizeof(realGen));

	o7c_retain(mp); o7c_retain(source);
	O7C_ASSIGN(&(module), Parser_Parse(&source->_, &mp->_, &mp->opt, Parser_Options_tag));
	VFileStream_CloseIn(&source);
	if (module == NULL) {
		Out_String("Ожидается MODULE", 26);
		Out_Ln();
		ret = ErrParse_cnst;
	} else if (module->errors != NULL) {
		PrintErrors(module->errors);
		ret = ErrParse_cnst;
	} else {
		Out_String("Модуль переведён без ошибок", 52);
		Out_Ln();
		ret = OpenOutput(&interface_, &implementation, &isMain);
		if (o7c_cmp(ret, ErrNo_cnst) ==  0) {
			GeneratorC_Init(&intGen, GeneratorC_Generator_tag, &interface_->_);
			GeneratorC_Init(&realGen, GeneratorC_Generator_tag, &implementation->_);
			O7C_ASSIGN(&(opt), GeneratorC_DefaultOptions());
			GeneratorC_Generate(&intGen, GeneratorC_Generator_tag, &realGen, GeneratorC_Generator_tag, module, opt);
			VFileStream_CloseOut(&interface_);
			VFileStream_CloseOut(&implementation);
		}
	}
	o7c_return = ret;
	o7c_release(module); o7c_release(opt); o7c_release(interface_); o7c_release(implementation);
	o7c_release(mp); o7c_release(source);
	return o7c_return;
}

static struct Translator_ModuleProvider_s *NewProvider(o7c_char fileExt[/*len0*/], int fileExt_len0, int extLen) {
	ModuleProvider o7c_return = NULL;

	struct Translator_ModuleProvider_s *mp = NULL;
	o7c_bool ret = O7C_BOOL_UNDEF;

	mp = o7c_new(sizeof(*mp), Translator_ModuleProvider_s_tag);
	Ast_ProviderInit(&mp->_, GetModule);
	Parser_DefaultOptions(&mp->opt, Parser_Options_tag);
	mp->opt.printError = ErrorMessage;
	CopyPath(mp->path, 4096, 3);
	O7C_ASSIGN(&(mp->modules.first), NULL);
	O7C_ASSIGN(&(mp->modules.last), NULL);
	mp->extLen = 0;
	ret = StringStore_CopyChars(mp->fileExt, 32, &mp->extLen, fileExt, fileExt_len0, 0, extLen);
	assert(o7c_bl(ret));
	O7C_ASSIGN(&o7c_return, mp);
	o7c_release(mp);
	o7c_unhold(o7c_return);
	return o7c_return;
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

static int CopyExt(o7c_char ext[/*len0*/], int ext_len0, o7c_char name[/*len0*/], int name_len0) {
	int o7c_return;

	int i = O7C_INT_UNDEF, dot = O7C_INT_UNDEF, len = O7C_INT_UNDEF;

	i = 0;
	dot =  - 1;
	while (name[o7c_ind(name_len0, i)] != 0x00u) {
		if (name[o7c_ind(name_len0, i)] == (char unsigned)'.') {
			dot = i;
		}
		i = o7c_add(i, 1);;
	}
	len = 0;
	if (!((o7c_cmp(dot, 0) >=  0) && StringStore_CopyChars(ext, ext_len0, &len, name, name_len0, dot, i)) && !StringStore_CopyChars(ext, ext_len0, &len, ".mod", 5, 0, 4)) {
		len =  - 1;
	}
	assert(o7c_cmp(len, 0) >=  0);
	o7c_return = len;
	return o7c_return;
}

static void Translator_Start(void) {
	o7c_char src[1024] /* init array */;
	o7c_char ext[32] /* init array */;
	int srcLen = O7C_INT_UNDEF, extLen = O7C_INT_UNDEF, ret = O7C_INT_UNDEF;
	struct VFileStream_RIn *source = NULL;
	memset(&src, 0, sizeof(src));
	memset(&ext, 0, sizeof(ext));

	Out_Open();
	Log_Turn(false);
	if (o7c_cmp(CLI_count, 2) <=  0) {
		ret = ErrWrongArgs_cnst;
	} else {
		srcLen = 0;
		if (!CLI_Get(src, 1024, &srcLen, 1)) {
			ret = ErrTooLongSourceName_cnst;
		} else {
			extLen = CopyExt(ext, 32, src, 1024);
			O7C_ASSIGN(&(source), VFileStream_OpenIn(src, 1024));
			if (source == NULL) {
				ret = ErrOpenSource_cnst;
			} else {
				ret = Compile(NewProvider(ext, 32, extLen), source);
			}
		}
	}
	if (o7c_cmp(ret, 0) !=  0) {
		ErrMessage(ret);
		CLI_SetExitCode(1);
	}
	o7c_release(source);
}

extern int main(int argc, char **argv) {
	o7c_init(argc, argv);
	Log_init();
	Out_init();
	CLI_init();
	VFileStream_init();
	Utf8_init();
	StringStore_init();
	Parser_init();
	Scanner_init();
	Ast_init();
	GeneratorC_init();
	TranslatorLimits_init();

	o7c_tag_init(Translator_ModuleProvider_s_tag, Ast_RProvider_tag);

	Translator_Start();
	return o7c_exit_code;
}

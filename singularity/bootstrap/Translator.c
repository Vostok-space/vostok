/*  Command line interface for Oberon-07 translator
 *  Copyright (C) 2016  ComdivByZero
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
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
#include "PlatformExec.h"

#define ResultC_cnst 0
#define ResultBin_cnst 1
#define ResultRun_cnst 2
#define ErrNo_cnst 0
#define ErrWrongArgs_cnst ( - 1)
#define ErrTooLongSourceName_cnst ( - 2)
#define ErrTooLongOutName_cnst ( - 3)
#define ErrOpenSource_cnst ( - 4)
#define ErrOpenH_cnst ( - 5)
#define ErrOpenC_cnst ( - 6)
#define ErrParse_cnst ( - 7)
#define ErrUnknownCommand_cnst ( - 8)
#define ErrNotEnoughArgs_cnst ( - 9)
#define ErrTooLongModuleDirs_cnst ( - 10)
#define ErrTooManyModuleDirs_cnst ( - 11)
#define ErrTooLongCDirs_cnst ( - 12)
#define ErrTooLongCc_cnst ( - 13)
#define ErrCCompiler_cnst ( - 14)
#define ErrTooLongRunArgs_cnst ( - 15)
#define ErrUnexpectArg_cnst ( - 16)

typedef struct Translator_ModuleProvider_s {
	Ast_RProvider _;
	struct Parser_Options opt;
	o7c_char fileExt[32];
	int extLen;
	o7c_char path[4096];
	unsigned sing;
	struct Translator_anon_0000 {
		struct Ast_RModule *first;
		struct Ast_RModule *last;
	} modules;
} *ModuleProvider;
static o7c_tag_t Translator_ModuleProvider_s_tag;


static void AstErrorMessage(int code);
static void AstErrorMessage_O(o7c_char s[/*len0*/], int s_len0) {
	Out_String(s, s_len0);
}

static void AstErrorMessage(int code) {
	switch (code) {
	case -1:
		AstErrorMessage_O((o7c_char *)"Имя модуля уже встречается в списке импорта", 81);
		break;
	case -2:
		AstErrorMessage_O((o7c_char *)"Повторное объявление имени в той же области видимости", 100);
		break;
	case -3:
		AstErrorMessage_O((o7c_char *)"Типы подвыражений в умножении несовместимы", 81);
		break;
	case -4:
		AstErrorMessage_O((o7c_char *)"Типы подвыражений в делении несовместимы", 77);
		break;
	case -5:
		AstErrorMessage_O((o7c_char *)"В логическом выражении должны использоваться подвыражении логического типа", 142);
		break;
	case -6:
		AstErrorMessage_O((o7c_char *)"В целочисленном делении допустимы только целочисленные подвыражения", 129);
		break;
	case -7:
		AstErrorMessage_O((o7c_char *)"В дробном делении допустимы только подвыражения дробного типа", 116);
		break;
	case -9:
		AstErrorMessage_O((o7c_char *)"В качестве элементов множества допустимы только целые числа", 112);
		break;
	case -10:
		AstErrorMessage_O((o7c_char *)"Элемент множества выходит за границы возможных значений - 0 .. 31", 115);
		break;
	case -11:
		AstErrorMessage_O((o7c_char *)"Левый элемент диапазона больше правого", 73);
		break;
	case -12:
		AstErrorMessage_O((o7c_char *)"Типы подвыражений в сложении несовместимы", 79);
		break;
	case -13:
		AstErrorMessage_O((o7c_char *)"В выражениях *, /, DIV, MOD допустимы только числа и множества", 104);
		break;
	case -14:
		AstErrorMessage_O((o7c_char *)"В выражениях +, - допустимы только числа и множества", 94);
		break;
	case -15:
		AstErrorMessage_O((o7c_char *)"Унарный знак не применим к логическому выражению", 91);
		break;
	case -17:
		AstErrorMessage_O((o7c_char *)"Типы подвыражений в сравнении не совпадают", 80);
		break;
	case -18:
		AstErrorMessage_O((o7c_char *)"Ast.ErrExprInWrongTypes", 24);
		break;
	case -19:
		AstErrorMessage_O((o7c_char *)"Ast.ErrExprInRightNotSet", 25);
		break;
	case -20:
		AstErrorMessage_O((o7c_char *)"Левый член выражения IN должен быть целочисленным", 91);
		break;
	case -21:
		AstErrorMessage_O((o7c_char *)"В сравнении выражения несовместимых типов", 79);
		break;
	case -22:
		AstErrorMessage_O((o7c_char *)"Проверка IS применима только к записям", 70);
		break;
	case -23:
		AstErrorMessage_O((o7c_char *)"Левый член проверки IS должен иметь тип записи или указателя на неё", 122);
		break;
	case -24:
		AstErrorMessage_O((o7c_char *)"Постоянная сопоставляется выражению, невычислимым на этапе перевода", 128);
		break;
	case -25:
		AstErrorMessage_O((o7c_char *)"Несовместимые типы в присваивании", 64);
		break;
	case -26:
		AstErrorMessage_O((o7c_char *)"Вызов допустим только для процедур и переменных процедурного типа", 123);
		break;
	case -28:
		AstErrorMessage_O((o7c_char *)"Возвращаемое значение не задействовано в выражении", 96);
		break;
	case -27:
		AstErrorMessage_O((o7c_char *)"Вызываемая процедура не возвращает значения", 83);
		break;
	case -29:
		AstErrorMessage_O((o7c_char *)"Лишние параметры при вызове процедуры", 71);
		break;
	case -30:
		AstErrorMessage_O((o7c_char *)"Несовместимый тип параметра", 53);
		break;
	case -31:
		AstErrorMessage_O((o7c_char *)"Параметр должен быть изменяемым значением", 79);
		break;
	case -58:
		AstErrorMessage_O((o7c_char *)"Для переменного параметра - указателя должен использоваться аргумент того же типа", 152);
		break;
	case -32:
		AstErrorMessage_O((o7c_char *)"Не хватает фактических параметров в вызове процедуры", 99);
		break;
	case -33:
		AstErrorMessage_O((o7c_char *)"Выражение в CASE должно быть целочисленным или литерой", 98);
		break;
	case -34:
		AstErrorMessage_O((o7c_char *)"Метки CASE должно быть целочисленными или литерами", 91);
		break;
	case -36:
		AstErrorMessage_O((o7c_char *)"Дублирование значения меток в CASE", 61);
		break;
	case -37:
		AstErrorMessage_O((o7c_char *)"Не совпадает тип меток CASE", 47);
		break;
	case -38:
		AstErrorMessage_O((o7c_char *)"Левая часть диапазона значений в метке CASE должна быть меньше правой", 125);
		break;
	case -39:
		AstErrorMessage_O((o7c_char *)"Метки CASE должны быть константами", 61);
		break;
	case -40:
		AstErrorMessage_O((o7c_char *)"Процедура не имеет возвращаемого значения", 79);
		break;
	case -41:
		AstErrorMessage_O((o7c_char *)"Тип возвращаемого значения не совместим типом, указанном в заголовке процедуры", 147);
		break;
	case -42:
		AstErrorMessage_O((o7c_char *)"Ожидался возврат значения, так как в заголовке процедуры указан возвращаемый тип", 150);
		break;
	case -43:
		AstErrorMessage_O((o7c_char *)"Предварительное объявление имени не было найдено", 92);
		break;
	case -44:
		AstErrorMessage_O((o7c_char *)"Недопустимое использование константы для задания собственного значения", 135);
		break;
	case -45:
		AstErrorMessage_O((o7c_char *)"Импортированный модуль не был найден", 69);
		break;
	case -46:
		AstErrorMessage_O((o7c_char *)"Импортированный модуль содержит ошибки", 74);
		break;
	case -47:
		AstErrorMessage_O((o7c_char *)"Разыменовывание применено не к указателю", 77);
		break;
	case -48:
		AstErrorMessage_O((o7c_char *)"Получение элемента не массива", 56);
		break;
	case -49:
		AstErrorMessage_O((o7c_char *)"Индекс массива не целочисленный", 60);
		break;
	case -50:
		AstErrorMessage_O((o7c_char *)"Отрицательный индекс массива", 55);
		break;
	case -51:
		AstErrorMessage_O((o7c_char *)"Индекс массива выходит за его границы", 70);
		break;
	case -52:
		AstErrorMessage_O((o7c_char *)"В защите типа ожидается расширенная запись", 80);
		break;
	case -53:
		AstErrorMessage_O((o7c_char *)"В защите типа ожидается указатель на расширенную запись", 104);
		break;
	case -54:
		AstErrorMessage_O((o7c_char *)"В защите типа переменная должна быть либо записью, либо указателем на запись", 141);
		break;
	case -55:
		AstErrorMessage_O((o7c_char *)"Селектор элемента записи применён не к записи", 85);
		break;
	case -56:
		AstErrorMessage_O((o7c_char *)"Ожидалась переменная", 40);
		break;
	case -57:
		AstErrorMessage_O((o7c_char *)"Итератор FOR не целочисленного типа", 64);
		break;
	case -59:
		AstErrorMessage_O((o7c_char *)"Выражение в охране условного оператора должно быть логическим", 116);
		break;
	case -60:
		AstErrorMessage_O((o7c_char *)"Выражение в охране цикла WHILE должно быть логическим", 95);
		break;
	case -61:
		AstErrorMessage_O((o7c_char *)"Охрана цикла WHILE всегда ложна", 54);
		break;
	case -62:
		AstErrorMessage_O((o7c_char *)"Цикл бесконечен, так как охрана WHILE всегда истинна", 92);
		break;
	case -63:
		AstErrorMessage_O((o7c_char *)"Выражение в условии завершения цикла REPEAT должно быть логическим", 119);
		break;
	case -64:
		AstErrorMessage_O((o7c_char *)"Цикл бесконечен, так как условие завершения всегда ложно", 105);
		break;
	case -65:
		AstErrorMessage_O((o7c_char *)"Условие завершения всегда истинно", 64);
		break;
	case -66:
		AstErrorMessage_O((o7c_char *)"Объявление не экспортировано", 55);
		break;
	case -67:
		AstErrorMessage_O((o7c_char *)"Логическое отрицание применено не к логическому типу", 99);
		break;
	case -69:
		AstErrorMessage_O((o7c_char *)"Переполнение при сложении постоянных", 70);
		break;
	case 68:
		AstErrorMessage_O((o7c_char *)"Переполнение при вычитании постоянных", 72);
		break;
	case -71:
		AstErrorMessage_O((o7c_char *)"Переполнение при умножении постоянных", 72);
		break;
	case -72:
		AstErrorMessage_O((o7c_char *)"Деление на 0", 22);
		break;
	case -73:
		AstErrorMessage_O((o7c_char *)"Значение выходит за границы BYTE", 57);
		break;
	case -74:
		AstErrorMessage_O((o7c_char *)"Значение выходит за границы CHAR", 57);
		break;
	case -75:
		AstErrorMessage_O((o7c_char *)"Ожидается целочисленное выражение", 65);
		break;
	case -76:
		AstErrorMessage_O((o7c_char *)"Ожидается константное целочисленное выражение", 88);
		break;
	case -77:
		AstErrorMessage_O((o7c_char *)"Шаг итератора не может быть равен 0", 64);
		break;
	case -78:
		AstErrorMessage_O((o7c_char *)"Для прохода от меньшего к большему шаг итератора должен быть > 0", 116);
		break;
	case -79:
		AstErrorMessage_O((o7c_char *)"Для прохода от большего к меньшему шаг итератора должен быть < 0", 116);
		break;
	case -80:
		AstErrorMessage_O((o7c_char *)"Во время итерации в FOR возможно переполнение", 82);
		break;
	case -81:
		AstErrorMessage_O((o7c_char *)"Использование не инициализированной переменной", 90);
		break;
	case -82:
		AstErrorMessage_O((o7c_char *)"Имя должно указывать на процедуру", 63);
		break;
	case -83:
		AstErrorMessage_O((o7c_char *)"В качестве команды может выступать только процедура без параметров", 125);
		break;
	default:
		abort();
		break;
	}
}

static void ParseErrorMessage(int code);
static void ParseErrorMessage_O(o7c_char s[/*len0*/], int s_len0) {
	Out_String(s, s_len0);
}

static void ParseErrorMessage(int code) {
	switch (code) {
	case -1:
		ParseErrorMessage_O((o7c_char *)"Неожиданный символ в тексте", 52);
		break;
	case -2:
		ParseErrorMessage_O((o7c_char *)"Значение константы слишком велико", 64);
		break;
	case -3:
		ParseErrorMessage_O((o7c_char *)"ErrRealScaleTooBig", 19);
		break;
	case -4:
		ParseErrorMessage_O((o7c_char *)"ErrWordLenTooBig", 17);
		break;
	case -5:
		ParseErrorMessage_O((o7c_char *)"В конце 16-ричного числа ожидается 'H' или 'X'", 77);
		break;
	case -6:
		ParseErrorMessage_O((o7c_char *)"Ожидалась ", 20);
		ParseErrorMessage_O((o7c_char *)"\x22", 2);
		break;
	case -7:
		ParseErrorMessage_O((o7c_char *)"ErrExpectDigitInScale", 22);
		break;
	case -8:
		ParseErrorMessage_O((o7c_char *)"Незакрытый комментарий", 44);
		break;
	case -101:
		ParseErrorMessage_O((o7c_char *)"Ожидается 'MODULE'", 28);
		break;
	case -102:
		ParseErrorMessage_O((o7c_char *)"Ожидается имя", 26);
		break;
	case -103:
		ParseErrorMessage_O((o7c_char *)"Ожидается ':'", 23);
		break;
	case -104:
		ParseErrorMessage_O((o7c_char *)"Ожидается ';'", 23);
		break;
	case -105:
		ParseErrorMessage_O((o7c_char *)"Ожидается 'END'", 25);
		break;
	case -106:
		ParseErrorMessage_O((o7c_char *)"Ожидается '.'", 23);
		break;
	case -107:
		ParseErrorMessage_O((o7c_char *)"Ожидается имя модуля", 39);
		break;
	case -108:
		ParseErrorMessage_O((o7c_char *)"Ожидается '='", 23);
		break;
	case -109:
		ParseErrorMessage_O((o7c_char *)"Ожидается ')'", 23);
		break;
	case -110:
		ParseErrorMessage_O((o7c_char *)"Ожидается ']'", 23);
		break;
	case -111:
		ParseErrorMessage_O((o7c_char *)"Ожидается '}'", 23);
		break;
	case -112:
		ParseErrorMessage_O((o7c_char *)"Ожидается OF", 22);
		break;
	case -115:
		ParseErrorMessage_O((o7c_char *)"Ожидается TO", 22);
		break;
	case -116:
		ParseErrorMessage_O((o7c_char *)"Ожидается структурный тип: массив, запись, указатель, процедурный", 121);
		break;
	case -117:
		ParseErrorMessage_O((o7c_char *)"Ожидается запись", 32);
		break;
	case -118:
		ParseErrorMessage_O((o7c_char *)"Ожидается оператор", 36);
		break;
	case -119:
		ParseErrorMessage_O((o7c_char *)"Ожидается THEN", 24);
		break;
	case -120:
		ParseErrorMessage_O((o7c_char *)"Ожидается :=", 22);
		break;
	case -122:
		ParseErrorMessage_O((o7c_char *)"Ожидается переменная типа запись либо указателя на неё", 102);
		break;
	case -124:
		ParseErrorMessage_O((o7c_char *)"Ожидается тип", 26);
		break;
	case -125:
		ParseErrorMessage_O((o7c_char *)"Ожидается UNTIL", 25);
		break;
	case -126:
		ParseErrorMessage_O((o7c_char *)"Ожидается DO", 22);
		break;
	case -128:
		ParseErrorMessage_O((o7c_char *)"Ожидается обозначение", 42);
		break;
	case -130:
		ParseErrorMessage_O((o7c_char *)"Ожидается процедура", 38);
		break;
	case -131:
		ParseErrorMessage_O((o7c_char *)"Ожидается имя константы", 45);
		break;
	case -132:
		ParseErrorMessage_O((o7c_char *)"Ожидается завершающее имя процедуры", 68);
		break;
	case -133:
		ParseErrorMessage_O((o7c_char *)"Ожидается выражение", 38);
		break;
	case -135:
		ParseErrorMessage_O((o7c_char *)"Лишняя ';'", 17);
		break;
	case -150:
		ParseErrorMessage_O((o7c_char *)"Завершающее имя в конце модуля не совпадает с его именем", 104);
		break;
	case -151:
		ParseErrorMessage_O((o7c_char *)"Слишком большая n-мерность массива", 64);
		break;
	case -152:
		ParseErrorMessage_O((o7c_char *)"Завершающее имя в теле процедуры не совпадает с её именем", 106);
		break;
	case -153:
		ParseErrorMessage_O((o7c_char *)"Объявление процедуры с возвращаемым значением не содержит скобки", 122);
		break;
	case -154:
		ParseErrorMessage_O((o7c_char *)"Длина массива должна быть > 0", 52);
		break;
	case -134:
		ParseErrorMessage_O((o7c_char *)"Ожидалось число или строка", 50);
		break;
	default:
		abort();
		break;
	}
}

static void ErrorMessage(int code) {
	Out_Int(o7c_sub(code, Parser_ErrAstBegin_cnst), 0);
	Out_String((o7c_char *)" ", 2);
	if (o7c_cmp(code, Parser_ErrAstBegin_cnst) <=  0) {
		AstErrorMessage(o7c_sub(code, Parser_ErrAstBegin_cnst));
	} else {
		ParseErrorMessage(code);
	}
}

static void PrintErrors(struct Ast_Error_s *err) {
	int i = O7C_INT_UNDEF;

	Out_String((o7c_char *)"Найдены ошибки: ", 30);
	Out_Ln();
	i = 0;
	while (err != NULL) {
		i = o7c_add(i, 1);
		Out_Int(i, 2);
		Out_String((o7c_char *)") ", 3);
		ErrorMessage(err->code);
		Out_String((o7c_char *)" ", 2);
		Out_Int(o7c_add(err->line, 1), 0);
		Out_String((o7c_char *)" : ", 4);
		Out_Int(o7c_add(err->column, o7c_mul(err->tabs, 3)), 0);
		Out_Ln();
		err = err->next;
	}
}

static o7c_bool IsEqualStr(o7c_char str[/*len0*/], int str_len0, int ofs, o7c_char sample[/*len0*/], int sample_len0) {
	int i = O7C_INT_UNDEF;

	i = 0;
	while ((str[o7c_ind(str_len0, ofs)] == sample[o7c_ind(sample_len0, i)]) && (sample[o7c_ind(sample_len0, i)] != 0x00u)) {
		ofs = o7c_add(ofs, 1);
		i = o7c_add(i, 1);
	}
	return str[o7c_ind(str_len0, ofs)] == sample[o7c_ind(sample_len0, i)];
}

static int CopyPath(o7c_char str[/*len0*/], int str_len0, unsigned *sing, o7c_char cDirs[/*len0*/], int cDirs_len0, o7c_char cc[/*len0*/], int cc_len0, int *arg) {
	int i = O7C_INT_UNDEF, dirsOfs = O7C_INT_UNDEF, ccLen = O7C_INT_UNDEF, count = O7C_INT_UNDEF, optLen = O7C_INT_UNDEF, ret = O7C_INT_UNDEF;
	o7c_char opt[256] ;
	memset(&opt, 0, sizeof(opt));

	i = 0;
	dirsOfs = 0;
	cDirs[0] = 0x00u;
	ccLen = 0;
	count = 0;
	(*sing) = 0;
	ret = ErrNo_cnst;
	optLen = 0;
	while ((o7c_cmp(ret, ErrNo_cnst) ==  0) && (o7c_cmp(count, 32) <  0) && (o7c_cmp((*arg), CLI_count) <  0) && CLI_Get(opt, 256, &optLen, (*arg)) && !IsEqualStr(opt, 256, 0, (o7c_char *)"--", 3)) {
		optLen = 0;
		if ((o7c_strcmp(opt, 256, (o7c_char *)"-i", 3) == 0) || (o7c_strcmp(opt, 256, (o7c_char *)"-m", 3) == 0)) {
			(*arg) = o7c_add((*arg), 1);
			if (o7c_cmp((*arg), CLI_count) >=  0) {
				ret = ErrNotEnoughArgs_cnst;
			} else if (CLI_Get(str, str_len0, &i, (*arg))) {
				if (o7c_strcmp(opt, 256, (o7c_char *)"-i", 3) == 0) {
					(*sing) |= 1u << count;
				}
				i = o7c_add(i, 1);
				count = o7c_add(count, 1);
			} else {
				ret = ErrTooLongModuleDirs_cnst;
			}
		} else if (o7c_strcmp(opt, 256, (o7c_char *)"-c", 3) == 0) {
			(*arg) = o7c_add((*arg), 1);
			if (o7c_cmp((*arg), CLI_count) >=  0) {
				ret = ErrNotEnoughArgs_cnst;
			} else if (CLI_Get(cDirs, cDirs_len0, &dirsOfs, (*arg)) && (o7c_cmp(dirsOfs, cDirs_len0) <  0)) {
				cDirs[o7c_ind(cDirs_len0, dirsOfs)] = 0x00u;
				Log_Str((o7c_char *)"cDirs = ", 9);
				Log_StrLn(cDirs, cDirs_len0);
			} else {
				ret = ErrTooLongCDirs_cnst;
			}
		} else if (o7c_strcmp(opt, 256, (o7c_char *)"-cc", 4) == 0) {
			(*arg) = o7c_add((*arg), 1);
			if (o7c_cmp((*arg), CLI_count) >=  0) {
				ret = ErrNotEnoughArgs_cnst;
			} else if (CLI_Get(cc, cc_len0, &ccLen, (*arg))) {
				ccLen = o7c_sub(ccLen, 1);
			} else {
				ret = ErrTooLongCc_cnst;
			}
		} else {
			ret = ErrUnexpectArg_cnst;
		}
		(*arg) = o7c_add((*arg), 1);
	}
	if (o7c_cmp(o7c_add(i, 1), str_len0) <  0) {
		str[o7c_ind(str_len0, o7c_add(i, 1))] = 0x00u;
		if (o7c_cmp(count, 32) >=  0) {
			ret = ErrTooManyModuleDirs_cnst;
		}
	} else {
		ret = ErrTooLongModuleDirs_cnst;
		str[o7c_ind(str_len0, o7c_sub(str_len0, 1))] = 0x00u;
		str[o7c_ind(str_len0, o7c_sub(str_len0, 2))] = 0x00u;
		str[o7c_ind(str_len0, o7c_sub(str_len0, 3))] = (char unsigned)'#';
	}
	return ret;
}

static struct Ast_RModule *SearchModule(struct Translator_ModuleProvider_s *mp, o7c_char name[/*len0*/], int name_len0, int ofs, int end) {
	struct Ast_RModule *m = NULL;

	m = mp->modules.first;
	while ((m != NULL) && !StringStore_IsEqualToChars(&m->_._.name, StringStore_String_tag, name, name_len0, ofs, end)) {
		assert(m != m->_._.module);
		m = m->_._.module;
	}
	return m;
}

static void AddModule(struct Translator_ModuleProvider_s *mp, struct Ast_RModule *m, o7c_bool sing) {
	assert(m->_._.module == m);
	m->_._.module = NULL;
	if (mp->modules.first == NULL) {
		mp->modules.first = m;
	} else {
		mp->modules.last->_._.module = m;
	}
	mp->modules.last = m;
	if (sing) {
		m->_._.mark = true;
	}
}

static struct Ast_RModule *GetModule(struct Ast_RProvider *p, struct Ast_RModule *host, o7c_char name[/*len0*/], int name_len0, int ofs, int end);
static struct VFileStream_RIn *GetModule_Open(struct Translator_ModuleProvider_s *p, int *pathOfs, o7c_char name[/*len0*/], int name_len0, int ofs, int end) {
	o7c_char n[1024] ;
	int len = O7C_INT_UNDEF, l = O7C_INT_UNDEF;
	struct VFileStream_RIn *in_ = NULL;
	memset(&n, 0, sizeof(n));

	len = StringStore_CalcLen(p->path, 4096, (*pathOfs));
	l = 0;
	if ((o7c_cmp(len, 0) >  0) && StringStore_CopyChars(n, 1024, &l, p->path, 4096, (*pathOfs), o7c_add((*pathOfs), len)) && StringStore_CopyChars(n, 1024, &l, (o7c_char *)"/", 2, 0, 1) && StringStore_CopyChars(n, 1024, &l, name, name_len0, ofs, end) && StringStore_CopyChars(n, 1024, &l, p->fileExt, 32, 0, p->extLen)) {
		Log_Str((o7c_char *)"Открыть ", 16);
		Log_Str(n, 1024);
		Log_Ln();
		in_ = VFileStream_OpenIn(n, 1024);
	} else {
		in_ = NULL;
	}
	(*pathOfs) = o7c_add(o7c_add((*pathOfs), len), 2);
	return in_;
}

static struct Ast_RModule *GetModule(struct Ast_RProvider *p, struct Ast_RModule *host, o7c_char name[/*len0*/], int name_len0, int ofs, int end) {
	struct Ast_RModule *m = NULL;
	struct VFileStream_RIn *source = NULL;
	struct Translator_ModuleProvider_s *mp = NULL;
	int pathOfs = O7C_INT_UNDEF, pathInd = O7C_INT_UNDEF;

	mp = O7C_GUARD(Translator_ModuleProvider_s, &p);
	m = SearchModule(mp, name, name_len0, ofs, end);
	if (m != NULL) {
		Log_StrLn((o7c_char *)"Найден уже разобранный модуль", 56);
	} else {
		pathInd =  - 1;
		pathOfs = 0;
		do {
			source = GetModule_Open(mp, &pathOfs, name, name_len0, ofs, end);
			pathInd = o7c_add(pathInd, 1);
		} while (!((source != NULL) || (mp->path[o7c_ind(4096, pathOfs)] == 0x00u)));
		if (source != NULL) {
			m = Parser_Parse(&source->_, p, &mp->opt, Parser_Options_tag);
			VFileStream_CloseIn(&source);
			if (m != NULL) {
				AddModule(mp, m, o7c_in(pathInd, mp->sing));
			}
		} else {
			Out_String((o7c_char *)"Не получается найти или открыть файл модуля", 81);
			Out_Ln();
		}
	}
	return m;
}

static int OpenCOutput(struct VFileStream_ROut **interface_, struct VFileStream_ROut **implementation, struct Ast_RModule *module, o7c_bool isMain, o7c_char dir[/*len0*/], int dir_len0, int dirLen) {
	int destLen = O7C_INT_UNDEF, ret = O7C_INT_UNDEF;

	(*interface_) = NULL;
	(*implementation) = NULL;
	destLen = dirLen;
	if (!StringStore_CopyChars(dir, dir_len0, &destLen, (o7c_char *)"/", 2, 0, 1) || !StringStore_CopyToChars(dir, dir_len0, &destLen, &module->_._.name, StringStore_String_tag) || (o7c_cmp(destLen, o7c_sub(dir_len0, 3)) >  0)) {
		ret = ErrTooLongOutName_cnst;
	} else {
		dir[o7c_ind(dir_len0, destLen)] = (char unsigned)'.';
		dir[o7c_ind(dir_len0, o7c_add(destLen, 2))] = 0x00u;
		if (!isMain) {
			dir[o7c_ind(dir_len0, o7c_add(destLen, 1))] = (char unsigned)'h';
			(*interface_) = VFileStream_OpenOut(dir, dir_len0);
		}
		if (!isMain && ((*interface_) == NULL)) {
			ret = ErrOpenH_cnst;
		} else {
			dir[o7c_ind(dir_len0, o7c_add(destLen, 1))] = (char unsigned)'c';
			Log_StrLn(dir, dir_len0);
			(*implementation) = VFileStream_OpenOut(dir, dir_len0);
			if ((*implementation) == NULL) {
				VFileStream_CloseOut(&(*interface_));
				ret = ErrOpenC_cnst;
			} else {
				ret = ErrNo_cnst;
			}
		}
	}
	return ret;
}

static struct Translator_ModuleProvider_s *NewProvider(void) {
	struct Translator_ModuleProvider_s *mp = NULL;

	O7C_NEW(&mp, Translator_ModuleProvider_s_tag);
	Ast_ProviderInit(&mp->_, GetModule);
	Parser_DefaultOptions(&mp->opt, Parser_Options_tag);
	mp->opt.printError = ErrorMessage;
	mp->modules.first = NULL;
	mp->modules.last = NULL;
	mp->extLen = 0;
	return mp;
}

static void PrintUsage(void);
static void PrintUsage_S(o7c_char s[/*len0*/], int s_len0) {
	Out_String(s, s_len0);
	Out_Ln();
}

static void PrintUsage(void) {
	PrintUsage_S((o7c_char *)"Использование: ", 29);
	PrintUsage_S((o7c_char *)"  1) o7c help", 14);
	PrintUsage_S((o7c_char *)"  2) o7c to-c команда вых.каталог {-m путьКмодулям | -i кат.с_интерф-ми_мод-ми}", 126);
	PrintUsage_S((o7c_char *)"Команда - это модуль[.процедура_без_параметров] .", 88);
	PrintUsage_S((o7c_char *)"В случае успешной трансляции создаст в выходном каталоге набор .h и .c-файлов,", 140);
	PrintUsage_S((o7c_char *)"соответствующих как самому исходному модулю, так и используемых им модулей,", 140);
	PrintUsage_S((o7c_char *)"кроме лежащих в каталогах, указанным после опции -i, служащих интерфейсами", 136);
	PrintUsage_S((o7c_char *)"для других .h и .с-файлов.", 44);
	PrintUsage_S((o7c_char *)"  3) o7c to-bin ком-да результат {-m пКм | -i кИм | -c .h,c-файлы} [-cc компил.]", 112);
	PrintUsage_S((o7c_char *)"После трансляции указанного модуля вызывает компилятор cc по умолчанию, либо", 141);
	PrintUsage_S((o7c_char *)"указанный после опции -cc, для сбора результата - исполнимого файла, в состав", 138);
	PrintUsage_S((o7c_char *)"которого также войдут .h,c файлы, находящиеся в каталогах, указанных после -c.", 138);
	PrintUsage_S((o7c_char *)"  4) o7c run команда {-m путь_к_м. | -i к.с_инт_м. | -c .h,c-файлы} -- параметры", 114);
	PrintUsage_S((o7c_char *)"Запускает собранный модуль с параметрами, указанными после --", 113);
}

static void ErrMessage(int err, o7c_char cmd[/*len0*/], int cmd_len0) {
	if (o7c_cmp(err, ErrParse_cnst) !=  0) {
		switch (err) {
		case -1:
			PrintUsage();
			break;
		case -2:
			Out_String((o7c_char *)"Слишком длинное имя исходного файла", 67);
			Out_Ln();
			break;
		case -3:
			Out_String((o7c_char *)"Слишком длинное выходное имя", 54);
			Out_Ln();
			break;
		case -4:
			Out_String((o7c_char *)"Не получается открыть исходный файл", 67);
			break;
		case -5:
			Out_String((o7c_char *)"Не получается открыть выходной .h файл", 70);
			break;
		case -6:
			Out_String((o7c_char *)"Не получается открыть выходной .c файл", 70);
			break;
		case -7:
			Out_String((o7c_char *)"Ошибка разбора исходного файла", 58);
			break;
		case -8:
			Out_String((o7c_char *)"Неизвестная команда: ", 40);
			Out_String(cmd, cmd_len0);
			Out_Ln();
			PrintUsage();
			break;
		case -9:
			Out_String((o7c_char *)"Недостаточно аргументов для команды: ", 70);
			Out_String(cmd, cmd_len0);
			break;
		case -10:
			Out_String((o7c_char *)"Суммарная длина путей с модулями слишком велика", 89);
			break;
		case -11:
			Out_String((o7c_char *)"Cлишком много путей с модулями", 56);
			break;
		case -12:
			Out_String((o7c_char *)"Суммарная длина путей с .c-файлами слишком велика", 90);
			break;
		case -13:
			Out_String((o7c_char *)"Длина опций компилятора C слишком велика", 75);
			break;
		case -14:
			Out_String((o7c_char *)"Ошибка при вызове компилятора C", 58);
			break;
		case -15:
			Out_String((o7c_char *)"Слишком длинные параметры командной строки", 81);
			break;
		case -16:
			Out_String((o7c_char *)"Неожиданный аргумент", 40);
			break;
		default:
			abort();
			break;
		}
		Out_Ln();
	}
}

static int GenerateC(struct Ast_RModule *module, o7c_bool isMain, struct Ast_Call_s *cmd, struct GeneratorC_Options_s *opt, o7c_char dir[/*len0*/], int dir_len0, int dirLen) {
	struct Ast_RDeclaration *imp = NULL;
	int ret = O7C_INT_UNDEF;
	struct VFileStream_ROut *iface = NULL, *impl = NULL;

	module->_._.mark = true;
	ret = ErrNo_cnst;
	imp = (&(module->import_)->_);
	while ((o7c_cmp(ret, ErrNo_cnst) ==  0) && (imp != NULL) && (o7c_is(imp, Ast_Import_s_tag))) {
		if (!imp->module->_._.mark) {
			ret = GenerateC(imp->module, false, NULL, opt, dir, dir_len0, dirLen);
		}
		imp = imp->next;
	}
	if (o7c_cmp(ret, ErrNo_cnst) ==  0) {
		ret = OpenCOutput(&iface, &impl, module, isMain, dir, dir_len0, o7c_sub(dirLen, 1));
		if (o7c_cmp(ret, ErrNo_cnst) ==  0) {
			GeneratorC_Generate(&iface->_, &impl->_, module, cmd, opt);
			VFileStream_CloseOut(&iface);
			VFileStream_CloseOut(&impl);
		}
	}
	return ret;
}

static int GetTempOutC(o7c_char dirCOut[/*len0*/], int dirCOut_len0, o7c_char bin[/*len0*/], int bin_len0, struct StringStore_String *name, o7c_tag_t name_tag) {
	int len = O7C_INT_UNDEF, binLen = O7C_INT_UNDEF;
	o7c_bool ok = O7C_BOOL_UNDEF;
	struct PlatformExec_Code cmd ;
	memset(&cmd, 0, sizeof(cmd));

	assert(dirCOut_len0 >= 10);
	memcpy(dirCOut, (o7c_char *)"/tmp/o7c-", sizeof("/tmp/o7c-"));
	len = StringStore_CalcLen(dirCOut, dirCOut_len0, 0);
	ok = StringStore_CopyToChars(dirCOut, dirCOut_len0, &len, &(*name), name_tag);
	assert(o7c_bl(ok));
	if (bin[0] == 0x00u) {
		binLen = 0;
		ok = StringStore_CopyChars(bin, bin_len0, &binLen, dirCOut, dirCOut_len0, 0, len) && StringStore_CopyCharsNull(bin, bin_len0, &binLen, (o7c_char *)"/", 2) && StringStore_CopyToChars(bin, bin_len0, &binLen, &(*name), name_tag);
		assert(o7c_bl(ok));
	}
	ok = PlatformExec_Init(&cmd, PlatformExec_Code_tag, (o7c_char *)"rm", 3) && PlatformExec_Add(&cmd, PlatformExec_Code_tag, (o7c_char *)"-rf", 4, 0) && PlatformExec_Add(&cmd, PlatformExec_Code_tag, dirCOut, dirCOut_len0, 0);
	assert(o7c_bl(ok));
	ok = o7c_cmp(PlatformExec_Do(&cmd, PlatformExec_Code_tag), PlatformExec_Ok_cnst) ==  0;
	ok = PlatformExec_Init(&cmd, PlatformExec_Code_tag, (o7c_char *)"mkdir", 6) && PlatformExec_Add(&cmd, PlatformExec_Code_tag, (o7c_char *)"-p", 3, 0) && PlatformExec_Add(&cmd, PlatformExec_Code_tag, dirCOut, dirCOut_len0, 0);
	assert(o7c_bl(ok));
	ok = o7c_cmp(PlatformExec_Do(&cmd, PlatformExec_Code_tag), PlatformExec_Ok_cnst) ==  0;
	return o7c_add(len, 1);
}

static int ToC(int res);
static int ToC_Bin(struct Ast_RModule *module, struct Ast_Call_s *call, struct GeneratorC_Options_s *opt, o7c_char cDirs[/*len0*/], int cDirs_len0, o7c_char cc[/*len0*/], int cc_len0, o7c_char bin[/*len0*/], int bin_len0) {
	o7c_char outC[1024] ;
	struct PlatformExec_Code cmd ;
	int outCLen = O7C_INT_UNDEF, ret = O7C_INT_UNDEF, i = O7C_INT_UNDEF;
	o7c_bool ok = O7C_BOOL_UNDEF;
	memset(&outC, 0, sizeof(outC));
	memset(&cmd, 0, sizeof(cmd));

	outCLen = GetTempOutC(outC, 1024, bin, bin_len0, &module->_._.name, StringStore_String_tag);
	ret = GenerateC(module, true, call, opt, outC, 1024, outCLen);
	outC[o7c_ind(1024, outCLen)] = 0x00u;
	if (o7c_cmp(ret, ErrNo_cnst) ==  0) {
		ok = PlatformExec_Init(&cmd, PlatformExec_Code_tag, (o7c_char *)"", 1);
		if (cc[0] == 0x00u) {
			ok = o7c_bl(ok) && PlatformExec_AddClean(&cmd, PlatformExec_Code_tag, (o7c_char *)"cc -g -O1", 10);
		} else {
			ok = o7c_bl(ok) && PlatformExec_AddClean(&cmd, PlatformExec_Code_tag, cc, cc_len0);
		}
		ok = o7c_bl(ok) && PlatformExec_Add(&cmd, PlatformExec_Code_tag, (o7c_char *)"-o", 3, 0) && PlatformExec_Add(&cmd, PlatformExec_Code_tag, bin, bin_len0, 0) && PlatformExec_Add(&cmd, PlatformExec_Code_tag, outC, 1024, 0) && PlatformExec_AddClean(&cmd, PlatformExec_Code_tag, (o7c_char *)"*.c -I", 7) && PlatformExec_Add(&cmd, PlatformExec_Code_tag, outC, 1024, 0);
		i = 0;
		while (o7c_bl(ok) && (cDirs[o7c_ind(cDirs_len0, i)] != 0x00u)) {
			ok = PlatformExec_Add(&cmd, PlatformExec_Code_tag, cDirs, cDirs_len0, i) && PlatformExec_AddClean(&cmd, PlatformExec_Code_tag, (o7c_char *)"/*.c -I", 8) && PlatformExec_Add(&cmd, PlatformExec_Code_tag, cDirs, cDirs_len0, i);
			i = o7c_add(o7c_add(i, StringStore_CalcLen(cDirs, cDirs_len0, i)), 1);
		}
		PlatformExec_Log(&cmd, PlatformExec_Code_tag);
		assert(o7c_bl(ok));
		if (o7c_cmp(PlatformExec_Do(&cmd, PlatformExec_Code_tag), PlatformExec_Ok_cnst) !=  0) {
			ret = ErrCCompiler_cnst;
		}
	}
	return ret;
}

static int ToC_Run(o7c_char bin[/*len0*/], int bin_len0, int arg) {
	struct PlatformExec_Code cmd ;
	o7c_char buf[65536] ;
	int len = O7C_INT_UNDEF, ret = O7C_INT_UNDEF;
	memset(&cmd, 0, sizeof(cmd));
	memset(&buf, 0, sizeof(buf));

	ret = ErrTooLongRunArgs_cnst;
	if (PlatformExec_Init(&cmd, PlatformExec_Code_tag, bin, bin_len0)) {
		arg = o7c_add(arg, 1);
		len = 0;
		while ((o7c_cmp(arg, CLI_count) <  0) && CLI_Get(buf, 65536, &len, arg) && PlatformExec_Add(&cmd, PlatformExec_Code_tag, buf, 65536, 0)) {
			len = 0;
			arg = o7c_add(arg, 1);
		}
		if (o7c_cmp(arg, CLI_count) >=  0) {
			CLI_SetExitCode(PlatformExec_Do(&cmd, PlatformExec_Code_tag));
			ret = ErrNo_cnst;
		}
	}
	return ret;
}

static int ToC_ParseCommand(o7c_char src[/*len0*/], int src_len0) {
	int i = O7C_INT_UNDEF;

	i = 0;
	while ((src[o7c_ind(src_len0, i)] != 0x00u) && (src[o7c_ind(src_len0, i)] != (char unsigned)'.')) {
		i = o7c_add(i, 1);
	}
	return i;
}

static int ToC(int res) {
	int ret = O7C_INT_UNDEF;
	o7c_char src[1024] ;
	int srcLen = O7C_INT_UNDEF, srcNameEnd = O7C_INT_UNDEF;
	o7c_char resPath[1024] ;
	int resPathLen = O7C_INT_UNDEF;
	o7c_char cDirs[4096] , cc[4096] ;
	struct Translator_ModuleProvider_s *mp = NULL;
	struct Ast_RModule *module = NULL;
	struct GeneratorC_Options_s *opt = NULL;
	int arg = O7C_INT_UNDEF;
	struct Ast_Call_s *call = NULL;
	memset(&src, 0, sizeof(src));
	memset(&resPath, 0, sizeof(resPath));
	memset(&cDirs, 0, sizeof(cDirs));
	memset(&cc, 0, sizeof(cc));

	assert(o7c_in(res, O7C_SET(ResultC_cnst, ResultRun_cnst)));
	srcLen = 0;
	arg = o7c_add(3, (int)(o7c_cmp(res, ResultRun_cnst) !=  0));
	if (o7c_cmp(CLI_count, arg) <  0) {
		ret = ErrNotEnoughArgs_cnst;
	} else if (!CLI_Get(src, 1024, &srcLen, 2)) {
		ret = ErrTooLongSourceName_cnst;
	} else {
		mp = NewProvider();
		memcpy(mp->fileExt, (o7c_char *)".mod", sizeof(".mod"));
		/* TODO */
		mp->extLen = StringStore_CalcLen(mp->fileExt, 32, 0);
		ret = CopyPath(mp->path, 4096, &mp->sing, cDirs, 4096, cc, 4096, &arg);
		if (o7c_cmp(ret, ErrNo_cnst) ==  0) {
			srcNameEnd = ToC_ParseCommand(src, 1024);
			module = GetModule(&mp->_, NULL, src, 1024, 0, srcNameEnd);
			resPathLen = 0;
			resPath[0] = 0x00u;
			if (module == NULL) {
				ret = ErrParse_cnst;
			} else if (module->errors != NULL) {
				PrintErrors(module->errors);
				ret = ErrParse_cnst;
			} else if ((o7c_cmp(res, ResultRun_cnst) !=  0) && !CLI_Get(resPath, 1024, &resPathLen, 3)) {
				ret = ErrTooLongOutName_cnst;
			} else {
				if (o7c_cmp(srcNameEnd, o7c_sub(srcLen, 1)) <  0) {
					ret = Ast_CommandGet(&call, module, src, 1024, o7c_add(srcNameEnd, 1), o7c_sub(srcLen, 1));
				} else {
					call = NULL;
				}
				if (o7c_cmp(ret, Ast_ErrNo_cnst) !=  0) {
					AstErrorMessage(ret);
					ret = ErrParse_cnst;
				} else {
					opt = GeneratorC_DefaultOptions();
					switch (res) {
					case 0:
						ret = GenerateC(module, call != NULL, call, opt, resPath, 1024, resPathLen);
						break;
					case 1:
					case 2:
						ret = ToC_Bin(module, call, opt, cDirs, 4096, cc, 4096, resPath, 1024);
						if ((o7c_cmp(res, ResultRun_cnst) ==  0) && (o7c_cmp(ret, ErrNo_cnst) ==  0)) {
							ret = ToC_Run(resPath, 1024, arg);
						}
						break;
					default:
						abort();
						break;
					}
				}
			}
		}
	}
	return ret;
}

static void Translator_Start(void) {
	o7c_char cmd[1024] ;
	int cmdLen = O7C_INT_UNDEF, ret = O7C_INT_UNDEF;
	memset(&cmd, 0, sizeof(cmd));

	Out_Open();
	Log_Turn(false);
	cmdLen = 0;
	if ((o7c_cmp(CLI_count, 1) <=  0) || !CLI_Get(cmd, 1024, &cmdLen, 1)) {
		ret = ErrWrongArgs_cnst;
	} else {
		ret = ErrNo_cnst;
		if (o7c_strcmp(cmd, 1024, (o7c_char *)"help", 5) == 0) {
			PrintUsage();
			Out_Ln();
		} else if (o7c_strcmp(cmd, 1024, (o7c_char *)"to-c", 5) == 0) {
			ret = ToC(ResultC_cnst);
		} else if (o7c_strcmp(cmd, 1024, (o7c_char *)"to-bin", 7) == 0) {
			ret = ToC(ResultBin_cnst);
		} else if (o7c_strcmp(cmd, 1024, (o7c_char *)"run", 4) == 0) {
			ret = ToC(ResultRun_cnst);
		} else {
			ret = ErrUnknownCommand_cnst;
		}
	}
	if (o7c_cmp(ret, ErrNo_cnst) !=  0) {
		CLI_SetExitCode(1);
		ErrMessage(ret, cmd, 1024);
	}
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
	PlatformExec_init();

	o7c_tag_init(Translator_ModuleProvider_s_tag, Ast_RProvider_tag);

	Translator_Start();
	return o7c_exit_code;
}

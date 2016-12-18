/*  Generator of C-code by Oberon-07 abstract syntax tree
 *  Copyright (C) 2016  ComdivByZero
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 * oftware Foundation, either version 3 of the License, or
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
#if !defined(HEADER_GUARD_GeneratorC)
#define HEADER_GUARD_GeneratorC

#include "V.h"
#include "Ast.h"
#include "StringStore.h"
#include "Scanner.h"
#include "VDataStream.h"
#include "Utf8.h"
#include "Log.h"
#include "Limits.h"
#include "TranslatorLimits.h"

#define GeneratorC_IsoC90_cnst 0
#define GeneratorC_IsoC99_cnst 1
#define GeneratorC_VarInitUndefined_cnst 0
#define GeneratorC_VarInitZero_cnst 1
#define GeneratorC_VarInitNo_cnst 2
#define GeneratorC_MemManagerNoFree_cnst 0
#define GeneratorC_MemManagerCounter_cnst 1
#define GeneratorC_MemManagerGC_cnst 2

typedef struct GeneratorC_Options_s {
	V_Base _;
	int std;
	o7c_bool gnu;
	o7c_bool plan9;
	o7c_bool procLocal;
	o7c_bool checkIndex;
	o7c_bool checkArith;
	o7c_bool caseAbort;
	int varInit;
	int memManager;
	o7c_bool main_;
	int index;
	struct V_Base *records;
	struct V_Base *recordLast;
	o7c_bool lastSelectorDereference;
} *GeneratorC_Options;
extern o7c_tag_t GeneratorC_Options_s_tag;

typedef struct GeneratorC_Generator {
	V_Base _;
	struct VDataStream_Out *out;
	int len;
	struct Ast_RModule *module;
	int localDeep;
	int fixedLen;
	int tabs;
	o7c_bool interface_;
	struct GeneratorC_Options_s *opt;
	o7c_bool expressionSemicolon;
} GeneratorC_Generator;
extern o7c_tag_t GeneratorC_Generator_tag;


extern struct GeneratorC_Options_s *GeneratorC_DefaultOptions(void);

extern void GeneratorC_Init(struct GeneratorC_Generator *g, o7c_tag_t g_tag, struct VDataStream_Out *out);

extern void GeneratorC_Generate(struct GeneratorC_Generator *interface_, o7c_tag_t interface__tag, struct GeneratorC_Generator *implementation, o7c_tag_t implementation_tag, struct Ast_RModule *module, struct GeneratorC_Options_s *opt);

extern void GeneratorC_init(void);
#endif

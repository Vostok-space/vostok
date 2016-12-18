/*  Abstract syntax tree support for Oberon-07
 *  Copyright (C) 2016  ComdivByZero
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the ndation, either version 3 of the License, or
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
#if !defined(HEADER_GUARD_TranslatorLimits)
#define HEADER_GUARD_TranslatorLimits


#define TranslatorLimits_MaxLenName_cnst 63
#define TranslatorLimits_MaxLenString_cnst 255
#define TranslatorLimits_MaxLenNumber_cnst 63
#define TranslatorLimits_MaxBlankChars_cnst 1023
#define TranslatorLimits_MaxImportedModules_cnst 127
#define TranslatorLimits_MaxGlobalConsts_cnst 2047
#define TranslatorLimits_MaxGlobalTypes_cnst 127
#define TranslatorLimits_MaxGlobalVars_cnst 255
#define TranslatorLimits_MaxVarsSeparatedByComa_cnst 31
#define TranslatorLimits_MaxGlobalProcedures_cnst 1023
#define TranslatorLimits_MaxModuleTextSize_cnst 262143
#define TranslatorLimits_MaxArrayDimension_cnst 7
#define TranslatorLimits_MaxVarsInRecord_cnst 255
#define TranslatorLimits_MaxRecordExt_cnst 15
#define TranslatorLimits_MaxParams_cnst 15
#define TranslatorLimits_MaxConsts_cnst 255
#define TranslatorLimits_MaxVars_cnst 31
#define TranslatorLimits_MaxProcedures_cnst 31
#define TranslatorLimits_MaxDeepProcedures_cnst 7
#define TranslatorLimits_MaxStatements_cnst 255
#define TranslatorLimits_MaxDeepStatements_cnst 15
#define TranslatorLimits_MaxIfBranches_cnst 255
#define TranslatorLimits_MaxSelectors_cnst 63
#define TranslatorLimits_MaxTermsInSum_cnst 255
#define TranslatorLimits_MaxFactorsInTerm_cnst 255

static inline void TranslatorLimits_init(void) { ; }
#endif

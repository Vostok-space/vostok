(*  Abstract syntax tree support for Oberon-07
 *  Copyright (C) 2016 ComdivByZero
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
MODULE TranslatorLimits;
(*
Транслятор не гарантирует сборку формально правильного модуля с частями,
характеристики которых превышают указанные ограничения, предоставленные не
столько для улучшения качества написанных/сгенерированных модулей, сколько
для предоставления возможности упрощения или оптимизации, а также повышения
надёжности транслятора там, где это может быть нужно.
Ограничения выбраны волюнтаристски.
*)
CONST
	(* Сканер *)
	(* длина имени *)
	MaxLenName*    =   63;
	(* длина содержимого строки, не включая завершающего 0 *)
	MaxLenString*  =  255;
	(* длина строкового представления числа *)
	MaxLenNumber*  =   63;
	(* количество пустых символов между значащими *)
	MaxBlankChars* = 1023;

	(* Модуль *)
	(* Кол-во ипортированных модулей *)
	MaxImportedModules*     =  127;
	(* Кол-во именованных постоянных *)
	MaxGlobalConsts*        = 2047;
	(* Кол-во типов *)
	MaxGlobalTypes*         =  127;
	(* Кол-во переменных *)
	MaxGlobalVars*          =  255;
	(* Кол-во переменных, перечисленных через запятую *)
	MaxVarsSeparatedByComa* =   31;
	(* Кол-во процедур *)
	MaxGlobalProcedures*    = 1023;
	(* Количество символов исходного кода модуля в Utf8 *)
	MaxModuleTextSize*      = 256 * 1024 - 1;

	(* Типы *)
	(* Размерность массива *)
	MaxArrayDimension* =   7;
	(* Количество переменных в структуре *)
	MaxVarsInRecord*   = 255;
	(* Глубина расширения структур *)
	MaxRecordExt*      =  15;

	(* Процедура *)
	(* Количество параметров *)
	MaxParams*         =  15;
	(* Количество именованных постоянных *)
	MaxConsts*         = 255;
	(* Количество переменных *)
	MaxVars*           =  31;
	(* Количество линейно вложенных функций *)
	MaxProcedures*     =  31;
	(* Глубина вложенности функций *)
	MaxDeepProcedures* =   7;
	(* Количество линейно вложенных операторов *)
	MaxStatements*     = 255;
	(* Вложенность операторов *)
	MaxDeepStatements* =  15;
	(* Веток IF {ELSIF} ELSE *)
	MaxIfBranches*     = 255;

	(* Выражения *)
	(* Цепочка селекторов *)
	MaxSelectors*     =  63;
	(* Количество подвыражений в одной сумме *)
	MaxTermsInSum*    = 255;
	(* Количество подвыражений в умножении *)
	MaxFactorsInTerm* = 255;

END TranslatorLimits.

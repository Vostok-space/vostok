(*  Limits for different parts of the translator
 *  Copyright (C) 2016, 2018 ComdivByZero
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
	LenName*    =   63;
	(* длина содержимого строки, не включая завершающего 0 *)
	LenString*  =  255;
	(* длина строкового представления числа *)
	LenNumber*  =   63;
	(* количество пустых символов между значащими *)
	BlankChars* = 1023;

	(* Модуль *)
	(* Кол-во ипортированных модулей *)
	ImportedModules*     =  127;
	(* Кол-во именованных постоянных *)
	GlobalConsts*        = 2047;
	(* Кол-во типов *)
	GlobalTypes*         =  127;
	(* Кол-во переменных *)
	GlobalVars*          =  255;
	(* Кол-во переменных, перечисленных через запятую *)
	VarsSeparatedByComa* =   31;
	(* Кол-во процедур *)
	GlobalProcedures*    = 1023;
	(* Количество символов исходного кода модуля в Utf8 *)
	ModuleTextSize*      = 256 * 1024 - 1;

	(* Типы *)
	(* Размерность массива *)
	ArrayDimension* =   7;
	(* Количество переменных в структуре *)
	VarsInRecord*   = 255;
	(* Глубина расширения структур *)
	RecordExt*      =  15;

	(* Процедура *)
	(* Количество параметров *)
	Params*         =  15;
	(* Количество именованных постоянных *)
	Consts*         = 255;
	(* Количество переменных *)
	Vars*           =  31;
	(* Количество линейно вложенных подпрограмм *)
	Procedures*     =  31;
	(* Глубина вложенности подпрограмм *)
	DeepProcedures* =   7;
	(* Количество линейно вложенных операторов *)
	Statements*     = 255;
	(* Вложенность операторов *)
	DeepStatements* =  15;
	(* Веток IF {ELSIF} ELSE *)
	IfBranches*     = 255;

	(* Выражения *)
	(* Цепочка селекторов *)
	Selectors*     =  63;
	(* Количество подвыражений в одной сумме *)
	TermsInSum*    = 255;
	(* Количество подвыражений в умножении *)
	FactorsInTerm* = 255;

END TranslatorLimits.

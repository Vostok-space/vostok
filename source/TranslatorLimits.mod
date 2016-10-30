(*  Abstract syntax tree support for Oberon-07
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
	MaxLenName*		=   63; (* длина имени *)
	MaxLenString*	=  255; (* длина содержимого строки, не включая завершающего 0 *)
	MaxLenNumber*	=   63; (* длина строкового представления числа *)
	MaxBlankChars*	= 1023; (* количество пустых символов между значащими *)

	(* Модуль *)
	MaxImportedModules*		=  127; (* Кол-во ипортированных модулей *)
	MaxGlobalConsts*		= 2047; (* Кол-во именованных постоянных *)
	MaxGlobalTypes*			=  127; (* Кол-во типов *)
	MaxGlobalVars*			=  255; (* Кол-во переменных *)
	MaxVarsSeparatedByComa*	=   31; (* Кол-во переменных, перечисленных через запятую *)
	MaxGlobalProcedures*	= 1023; (* Кол-во процедур *)
	MaxModuleTextSize*		= 256 * 1024 - 1; (* Количество символов исходного
												кода модуля в Utf8 *)

	(* Типы *)
	MaxArrayDimension*	=   7; (* Размерность массива *)
	MaxVarsInRecord*	= 255; (* Количество переменных в структуре *)
	MaxRecordExt*		=  15; (* Глубина расширения структур *)

	(* Процедура *)
	MaxParams*			=  15; (* Количество параметров *)
	MaxConsts*			= 255; (* Количество именованных постоянных *)
	MaxVars*			=  31; (* Количество переменных *)
	MaxProcedures*		=  31; (* Количество линейно вложенных функций *)
	MaxDeepProcedures*	=   7; (* Глубина вложенности функций *)
	MaxStatements*		= 255; (* Количество линейно вложенных операторов *)
	MaxDeepStatements*	=  15; (* Вложенность операторов *)
	MaxIfBranches*		= 255; (* Веток IF {ELSIF} ELSE *)

	(* Выражения *)
	MaxSelectors*		=  63; (* Цепочка селекторов *)

END TranslatorLimits.

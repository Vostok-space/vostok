(*  Blank interface of Java-code generator
 *
 *  Copyright (C) 2019,2021 ComdivByZero
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
MODULE GeneratorJava;

IMPORT
	Ast,
	Strings    := StringStore,
	Stream     := VDataStream,
	GenOptions;

CONST
	Supported* = FALSE;

	VarInitUndefined*   = 0;
	VarInitZero*        = 1;

	IdentEncSame*       = 0;
	IdentEncTranslit*   = 1;
	IdentEncEscUnicode* = 2;

TYPE
	ProviderProcTypeName* = POINTER TO RProviderProcTypeName;
	ProvideProcTypeName* =
		PROCEDURE(prov: ProviderProcTypeName; typ: Ast.ProcType;
		          VAR name: Strings.String): Stream.POut;
	RProviderProcTypeName* = RECORD END;

	Options* = POINTER TO RECORD(GenOptions.R) END;

PROCEDURE DefaultOptions*(): Options;
BEGIN
	ASSERT(FALSE)
	RETURN NIL
END DefaultOptions;

PROCEDURE ProviderProcTypeNameInit*(p: ProviderProcTypeName;
                                    gen: ProvideProcTypeName);
BEGIN
	ASSERT(FALSE)
END ProviderProcTypeNameInit;

PROCEDURE Generate*(out: Stream.POut;
                    module: Ast.Module; cmd: Ast.Statement;
                    provider: ProviderProcTypeName; opt: Options);
BEGIN
	ASSERT(FALSE)
END Generate;

END GeneratorJava.

(*  Blank interface of C-code generator
 *
 *  Copyright (C) 2019 ComdivByZero
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
MODULE GeneratorC;

IMPORT
	V,
	Ast,
	Stream     := VDataStream,
	FileStream := VFileStream,
	Text := TextGenerator;

CONST
	IsoC90* = 0;
	IsoC99* = 1;
	IsoC11* = 2;

	VarInitUndefined*   = 0;
	VarInitZero*        = 1;
	VarInitNo*          = 2;

	MemManagerNoFree*   = 0;
	MemManagerCounter*  = 1;
	MemManagerGC*       = 2;

	IdentEncSame*       = 0;
	IdentEncTranslit*   = 1;
	IdentEncEscUnicode* = 2;

TYPE
	Options* = POINTER TO RECORD(V.Base)
		std*: INTEGER;

		gnu*, plan9*,
		procLocal*,
		checkIndex*,
		vla*, vlaMark*,
		checkArith*,
		caseAbort*,
		checkNil*,
		o7Assert*,
		skipUnusedTag*,
		comment*,
		generatorNote*: BOOLEAN;

		varInit*,
		memManager*,
		identEnc*  : INTEGER
	END;

PROCEDURE DefaultOptions*(): Options;
BEGIN
	ASSERT(FALSE)
	RETURN NIL
END DefaultOptions;

PROCEDURE Generate*(interface, implementation: Stream.POut;
                    module: Ast.Module; cmd: Ast.Statement; opt: Options);
BEGIN
	ASSERT(FALSE)
END Generate;

END GeneratorC.

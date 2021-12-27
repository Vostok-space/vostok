(*  Common options for generators to C, Java, Js. Extracted from GeneratorC
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
MODULE GenOptions;

  IMPORT V;

  CONST
    VarInitUndefined*   = 0;
    VarInitZero*        = 1;
    VarInitNo*          = 2;

    IdentEncSame*       = 0;
    IdentEncTranslit*   = 1;
    IdentEncEscUnicode* = 2;

  TYPE
    R* = RECORD(V.Base)
      checkArith*,
      checkIndex*,
      caseAbort*,
      o7Assert*,

      comment*,
      generatorNote*,

      main*: BOOLEAN;

      varInit*,
      identEnc*  : INTEGER
    END;

    PROCEDURE Default*(VAR o: R);
    BEGIN
      V.Init(o);
      o.checkIndex    := TRUE;
      o.checkArith    := TRUE;
      o.caseAbort     := TRUE;
      o.o7Assert      := TRUE;

      o.comment       := TRUE;
      o.generatorNote := TRUE;

      o.main          := FALSE;

      o.varInit       := VarInitUndefined;
      o.identEnc      := IdentEncEscUnicode
    END Default;

END GenOptions.

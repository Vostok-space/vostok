Translation to JavaScript

Copyright (C) 2021 ComdivByZero

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

MODULE TranslatorJs;

  IMPORT
    Out,
    Parser, Ast, AstTransform,
    MessageErrOberon,
    Strings := StringStore,
    ModulesStorage, ModulesProvider, InputProvider,
    Stream := VDataStream, Mem := VMemStream,
    GeneratorJs;

  CONST
    ErrNo    =  0;
    ErrParse = -1;

  TYPE
    P* = POINTER TO RECORD
      modules: ModulesStorage.Provider;
      parseOpt: Parser.Options;
      tranOpt: AstTransform.Options
    END;

  PROCEDURE ErrorMessage(code: INTEGER; str: Strings.String);
  BEGIN
    IF code <= Parser.ErrAstBegin THEN
      MessageErrOberon.Ast(code - Parser.ErrAstBegin, str)
    ELSE
      MessageErrOberon.Syntax(code)
    END
  END ErrorMessage;

  PROCEDURE IndexedErrorMessage(index, code: INTEGER; str: Strings.String;
                                line, column: INTEGER);
  BEGIN
    Out.String("  ");
    Out.Int(index, 2); Out.String(") ");

    ErrorMessage(code, str);

    Out.String(" "); Out.Int(line + 1, 0);
    Out.String(" : "); Out.Int(column, 0);
    Out.Ln
  END IndexedErrorMessage;

  PROCEDURE PrintErrors(mc: ModulesStorage.Container; module: Ast.Module);
  CONST SkipError = Ast.ErrImportModuleWithError + Parser.ErrAstBegin;
  VAR i: INTEGER; err: Ast.Error; m: Ast.Module;
  BEGIN
    i := 0;
    m := ModulesStorage.Next(mc);
    WHILE m # NIL DO
      err := m.errors;
      WHILE (err # NIL) & (err.code = SkipError) DO
        err := err.next
      END;
      IF err # NIL THEN
        MessageErrOberon.Text("Found errors in the module ");
        Out.String(m.name.block.s); Out.String(": "); Out.Ln;
        err := m.errors;
        WHILE err # NIL DO
          IF err.code # SkipError THEN
            INC(i);
            IndexedErrorMessage(i, err.code, err.str, err.line, err.column)
          END;
          err := err.next
        END
      END;
      m := ModulesStorage.Next(mc)
    END;
    IF i = 0 THEN
      IndexedErrorMessage(i, module.errors.code, module.errors.str,
                          module.errors.line, module.errors.column)
    END
  END PrintErrors;

  PROCEDURE IsSing(m: Ast.Module): BOOLEAN;
  RETURN
    (* TODO *)
    m.mark
  END IsSing;

  PROCEDURE Generate(out: Stream.POut;
                     m: Ast.Module; opt: GeneratorJs.Options): INTEGER;
  VAR ret: INTEGER; imp: Ast.Declaration;
  BEGIN
    m.used := TRUE;

    ret := ErrNo;
    imp := m.import;
    WHILE (ret = ErrNo) & (imp # NIL) & (imp IS Ast.Import) DO
      IF ~imp.module.m.used THEN
        ret := Generate(out, imp.module.m, opt)
      END;
      imp := imp.next
    END;

    IF (ret = ErrNo) & ~IsSing(m) THEN
      GeneratorJs.Generate(out, m, NIL, opt)
    END
  RETURN
    ret
  END Generate;

  PROCEDURE New*(VAR tr: P; in: InputProvider.P): BOOLEAN;
  VAR p: ModulesProvider.Provider;
  BEGIN
    NEW(tr);
    IF (tr # NIL) & ModulesProvider.New(p, in) THEN
      ModulesStorage.New(tr.modules, p);
      AstTransform.DefaultOptions(tr.tranOpt);

      Parser.DefaultOptions(tr.parseOpt);
      tr.parseOpt.printError  := ErrorMessage;
      tr.parseOpt.cyrillic    := TRUE;
      tr.parseOpt.provider    := p;
      tr.parseOpt.multiErrors := FALSE;

      ModulesProvider.SetParserOptions(p, tr.parseOpt)
    ELSE
      tr := NIL
    END
  RETURN
    tr # NIL
  END New;

  PROCEDURE Do*(tran: P; code: ARRAY OF CHAR;
                out: Stream.POut; genOpt: GeneratorJs.Options): INTEGER;
  VAR ret: INTEGER;
      module: Ast.Module;
      str: Strings.String;
  BEGIN
    module := Parser.Script(code, tran.parseOpt);
    IF module = NIL THEN
      ret := ErrParse
    ELSIF module.errors # NIL THEN
      ret := ErrParse;
      PrintErrors(ModulesStorage.Iterate(tran.modules), module)
    ELSE
      ret := ErrNo
    END;
    IF ret # Ast.ErrNo THEN
      Strings.Undef(str);
      MessageErrOberon.Ast(ret, str); MessageErrOberon.Ln;
      ret := ErrParse
    ELSE
      Ast.ModuleReopen(module);
      AstTransform.Do(module, tran.tranOpt);
      ret := Generate(out, module, genOpt)
    END
  RETURN
    ret
  END Do;

END TranslatorJs.

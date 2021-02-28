(*  Provider of modules through file system
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
MODULE ModulesProvider;

  IMPORT
    Log := DLog, Out,
    Ast,
    Strings := StringStore, Chars0X,
    ArrayCopy,
    Parser,
    TranLim := TranslatorLimits,
    File := VFileStream, Stream := VDataStream,
    Exec := PlatformExec,
    Utf8,
    MessageErrOberon,
    InputProvider;

  TYPE
    Provider* = POINTER TO RECORD(Ast.RProvider)
      opt: Parser.Options;

      in: InputProvider.P;

      expectName: ARRAY TranLim.LenName + 1 OF CHAR;
      nameLen   : INTEGER;

      nameOk,
      firstNotOk: BOOLEAN
    END;

  PROCEDURE GetModule(p: Ast.Provider; host: Ast.Module; name: ARRAY OF CHAR): Ast.Module;
  VAR m: Ast.Module; mp: Provider;

    PROCEDURE Search(p: Provider): Ast.Module;
    VAR source: Stream.PIn;
        m: Ast.Module;
        decl: BOOLEAN;
        it: InputProvider.PIter;
    BEGIN
      m := NIL;
      IF InputProvider.Get(p.in, it, p.expectName) THEN
        REPEAT
          IF InputProvider.Next(it, source, decl) THEN
            m := Parser.Parse(source, p.opt);
            Stream.CloseIn(source);
            IF (m # NIL) & (m.errors = NIL) & ~p.nameOk THEN
              m := NIL
            ELSIF m # NIL THEN
              Log.Str(m.name.block.s); Log.Str(" : "); Log.Bool(decl); Log.Ln;
              (*TODO*)
              m.mark := decl
            END
          END
        UNTIL (m # NIL) OR (it = NIL)
      END
    RETURN
      m
    END Search;
  BEGIN
    mp := p(Provider);
    mp.nameLen := 0;
    IF ~Chars0X.CopyString(mp.expectName, mp.nameLen, name) THEN
      m := NIL;
      MessageErrOberon.Text("Name of potential module is too large - ");
      Out.String(name);
      MessageErrOberon.Ln
    ELSE
      m := Search(mp);
      IF (m = NIL) & mp.firstNotOk THEN
        mp.firstNotOk := FALSE;
        (* TODO *)
        MessageErrOberon.Text("Can not found or open file of module - ");
        Out.String(mp.expectName);
        MessageErrOberon.Ln
      END
    END
  RETURN
    m
  END GetModule;

  PROCEDURE RegModule(p: Ast.Provider; m: Ast.Module): BOOLEAN;
    PROCEDURE Reg(p: Provider; m: Ast.Module): BOOLEAN;
    BEGIN
      Log.Str("RegModule ");
      Log.Str(m.name.block.s); Log.Str(" : "); Log.StrLn(p.expectName);
      p.nameOk := m.name.block.s = p.expectName;
    RETURN
      p.nameOk
    END Reg;
  RETURN
    Reg(p(Provider), m)
  END RegModule;

  PROCEDURE New*(VAR mp: Provider; inp: InputProvider.P): BOOLEAN;
  BEGIN
    ASSERT(inp # NIL);

    NEW(mp);
    IF mp # NIL THEN
      Ast.ProviderInit(mp, GetModule, RegModule);

      mp.in := inp;
      mp.firstNotOk := TRUE;
    END
  RETURN
    mp # NIL
  END New;

  PROCEDURE SetParserOptions*(p: Provider; o: Parser.Options);
  BEGIN
    p.opt := o
  END SetParserOptions;

END ModulesProvider.

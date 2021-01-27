(*  Servo provider of modules which stores already recieved modules. Extracted from Translator
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
MODULE ModulesStorage;

  IMPORT Log, Ast, Strings := StringStore;

  TYPE
    Container* = POINTER TO RContainer;
    RContainer = RECORD
      next: Container;
      m: Ast.Module
    END;

    Provider* = POINTER TO RECORD(Ast.RProvider)
      provider: Ast.Provider;

      first, last: Container
    END;

  PROCEDURE Iterate*(p: Provider): Container;
  RETURN
    p.first
  END Iterate;

  PROCEDURE Next*(VAR it: Container): Ast.Module;
  BEGIN
    it := it.next
  RETURN
    it.m
  END Next;

  PROCEDURE Unlink*(VAR p: Provider);
  VAR c, tc: Container;
  BEGIN
    IF p # NIL THEN
      p.last.next := NIL;
      c := p.first.next;
      WHILE c # NIL DO
        tc := c;
        c := c.next;
        Ast.Unlinks(tc.m);
        tc.m := NIL
      END;
      p := NIL
    END
  END Unlink;

  PROCEDURE SearchModule(mp: Provider; name: ARRAY OF CHAR): Ast.Module;
  VAR first, mc: Container;
  BEGIN
    first := mp.first;
    mc := first.next;
    Log.StrLn("Search");
    WHILE (mc # first) & ~Strings.IsEqualToString(mc.m.name, name) DO
      Log.Str(mc.m.name.block.s); Log.Str(" : "); Log.StrLn(name);
      mc := mc.next
    END;
    Log.StrLn("End Search")
  RETURN
    mc.m
  END SearchModule;

  PROCEDURE Add(mp: Provider; m: Ast.Module);
  VAR mc: Container;
  BEGIN
    ASSERT(m.module.m = m);
    NEW(mc);
    mc.m := m;
    mc.next := mp.last.next;

    mp.last.next := mc;
    mp.last := mc
  END Add;

  PROCEDURE GetModule(p: Ast.Provider; host: Ast.Module; name: ARRAY OF CHAR): Ast.Module;
  VAR m: Ast.Module;
      mp: Provider;
  BEGIN
    mp := p(Provider);
    m := SearchModule(mp, name);
    IF m = NIL THEN
      m := Ast.ProvideModule(mp.provider, host, name)
    ELSE
      Log.Str("Найден уже разобранный модуль "); Log.StrLn(m.name.block.s)
    END
  RETURN
    m
  END GetModule;

  PROCEDURE RegModule(p: Ast.Provider; m: Ast.Module): BOOLEAN;
    PROCEDURE Reg(p: Provider; m: Ast.Module): BOOLEAN;
    VAR ok: BOOLEAN;
    BEGIN
      ok := Ast.RegModule(p.provider, m);
      IF ok THEN
        Add(p, m)
      END
    RETURN
      ok
    END Reg;
  RETURN
    Reg(p(Provider), m)
  END RegModule;

  PROCEDURE New*(VAR mp: Provider; else: Ast.Provider);
  BEGIN
    NEW(mp); Ast.ProviderInit(mp, GetModule, RegModule);

    NEW(mp.first);
    mp.first.m := NIL;
    mp.first.next := mp.first;
    mp.last := mp.first;

    mp.provider := else
  END New;

END ModulesStorage.

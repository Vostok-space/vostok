(*  Provider of modules which have access to file system with modules. Extracted from Translator
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
MODULE ModulesProvider;

  IMPORT
    Log, Out,
    Ast,
    Strings := StringStore,
    Parser,
    TranLim := TranslatorLimits,
    File := VFileStream,
    Exec := PlatformExec,
    Utf8,
    Message;

  TYPE
    Provider* = POINTER TO RECORD(Ast.RProvider)
      opt: Parser.Options;

      path: ARRAY 4096 OF CHAR;
      sing: SET;

      expectName: ARRAY TranLim.LenName + 1 OF CHAR;
      nameLen   : INTEGER;
      nameOk,
      firstNotOk: BOOLEAN
    END;

  PROCEDURE GetModule(p: Ast.Provider; host: Ast.Module;
                      name: ARRAY OF CHAR; ofs, end: INTEGER): Ast.Module;
  VAR m: Ast.Module;
      mp: Provider;
      pathInd, i: INTEGER;
      ext: ARRAY 4, 6 OF CHAR;

    PROCEDURE Search(p: Provider;
                     name: ARRAY OF CHAR; ofs, end: INTEGER;
                     ext: ARRAY OF CHAR;
                     VAR pathInd: INTEGER): Ast.Module;
    VAR pathOfs: INTEGER;
        source: File.In;
        m: Ast.Module;

      PROCEDURE Open(p: Provider; VAR pathOfs: INTEGER;
                     name: ARRAY OF CHAR; ofs, end: INTEGER;
                     ext: ARRAY OF CHAR): File.In;
      VAR n: ARRAY 1024 OF CHAR;
          len, l: INTEGER;
          in: File.In;
      BEGIN
        len := Strings.CalcLen(p.path, pathOfs);
        l := 0;
        IF (0 < len)
         & Strings.CopyChars(n, l, p.path, pathOfs, pathOfs + len)
         & Strings.CopyCharsNull(n, l, Exec.dirSep)
         & Strings.CopyChars(n, l, name, ofs, end)
         & Strings.CopyCharsNull(n, l, ext)
        THEN
          Log.Str("Open "); Log.StrLn(n);
          in := File.OpenIn(n)
        ELSE
          in := NIL
        END;
        pathOfs := pathOfs + len + 1
      RETURN
        in
      END Open;
    BEGIN
      pathInd := -1;
      pathOfs := 0;
      REPEAT
        source := Open(p, pathOfs, name, ofs, end, ext);
        IF source # NIL THEN
          m := Parser.Parse(source, p.opt);
          File.CloseIn(source);
          IF (m # NIL) & (m.errors = NIL) & ~p.nameOk THEN
            m := NIL
          END
        ELSE
          m := NIL
        END;
        INC(pathInd)
      UNTIL (m # NIL) OR (p.path[pathOfs] = Utf8.Null)
    RETURN
      m
    END Search;
  BEGIN
    mp := p(Provider);
    mp.nameLen := 0;
    ASSERT(Strings.CopyChars(mp.expectName, mp.nameLen, name, ofs, end));

    ext[0] := ".mod";
    ext[1] := ".Mod";
    ext[2] := ".ob07";
    ext[3] := ".ob";
    i := 0;
    REPEAT
      m := Search(mp, name, ofs, end, ext[i], pathInd);
      INC(i)
    UNTIL (m # NIL) OR (i >= LEN(ext));
    IF m # NIL THEN
      IF pathInd IN mp.sing THEN
        m.mark := TRUE
      END
    ELSIF mp.firstNotOk THEN
      mp.firstNotOk := FALSE;
      (* TODO *)
      Message.Text("Can not found or open file of module ");
      Out.String(mp.expectName);
      Out.Ln
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

  PROCEDURE New*(VAR mp: Provider; searchPath: ARRAY OF CHAR; pathLen: INTEGER;
                 definitionsInSearch: SET);
  VAR len: INTEGER;
  BEGIN
    NEW(mp); Ast.ProviderInit(mp, GetModule, RegModule);

    mp.firstNotOk := TRUE;
    len := 0;
    ASSERT(Strings.CopyChars(mp.path, len, searchPath, 0, pathLen));
    mp.sing := definitionsInSearch
  END New;

  PROCEDURE SetParserOptions*(p: Provider; o: Parser.Options);
  BEGIN
    p.opt := o
  END SetParserOptions;

END ModulesProvider.

(*  Storage of procedure types for Java Generator
 *  Copyright (C) 2018 ComdivByZero
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
MODULE JavaStoreProcTypes;

  IMPORT V, Ast, Strings := StringStore, Log;

  CONST

  TYPE
    Item = POINTER TO RItem;
    RItem = RECORD(V.Base)
      type: Ast.ProcType;
      name: Strings.String;

      next: Item
    END;

    Store* = POINTER TO RECORD(RItem)
      names: Strings.Store;
      items, last: Item
    END;

  PROCEDURE New*(VAR st: Store): BOOLEAN;
  BEGIN
    NEW(st);
    IF st # NIL THEN
      V.Init(st^);
      st.next := NIL;
      Strings.StoreInit(st.names);
      st.items := st;
      st.last := st.items
    END
  RETURN
    (st # NIL) & (st.items # NIL)
  END New;

  PROCEDURE Add(VAR st: Store; VAR w: Strings.String;
                pt: Ast.ProcType; generic: BOOLEAN;
                VAR name: ARRAY OF CHAR; end: INTEGER): BOOLEAN;
  VAR it: Item; rep: INTEGER; equal, new: BOOLEAN;

    PROCEDURE EqualChars(VAR eq: BOOLEAN;
                         s: Strings.String;
                         c: ARRAY OF CHAR; end: INTEGER): BOOLEAN;
    BEGIN
      eq := Strings.IsEqualToChars(s, c, 0, end)
    RETURN
      eq
    END EqualChars;

    PROCEDURE CorrectName(equal: BOOLEAN; VAR rep: INTEGER;
                          VAR name: ARRAY OF CHAR; VAR end: INTEGER): BOOLEAN;
    VAR ok: BOOLEAN; n: INTEGER;
    BEGIN
      IF equal THEN
        INC(rep);
        WHILE (name[end] # "_")
           OR ("0" <= name[end - 1]) & (name[end - 1] <= "9")
        DO
          DEC(end)
        END;
        INC(end);
        n := rep;
        WHILE (n # 0) & (end < LEN(name)) DO
          name[end] := CHR(ORD("0") + n MOD 10);
          INC(end);
          n := n DIV 10;
        END;
        ok := Strings.CopyCharsNull(name, end, "_proc");

        Log.On;
        Log.Str("Corr name: "); Log.StrLn(name);
        Log.Off
      END;
    RETURN
      ~equal OR ok
    END CorrectName;
  BEGIN
    rep   := 0;
    equal := FALSE;

    it := st.items.next;
    WHILE (it # NIL)
        & ~(  EqualChars(equal, it.name, name, end)
            & (~generic OR Ast.EqualProcTypes(it.type, pt))
           )
    DO
      ASSERT(CorrectName(equal, rep, name, end));
      equal := FALSE;
      it := it.next
    END;
    new := it = NIL;
    Log.On;
    Log.Str(" new item = "); Log.Bool(new); Log.Str(" for "); Log.StrLn(name);
    Log.Off;
    IF new THEN
      NEW(it);
      IF it # NIL THEN
        V.Init(it^);
        it.next := NIL;
        it.type := pt;
        ASSERT(CorrectName(equal, rep, name, end));
        Strings.Put(st.names, it.name, name, 0, end);

        st.last.next := it;
        st.last := it
      END
    END;
    w := it.name
  RETURN
    new
  END Add;

  (* TODO *)
  PROCEDURE GenerateName*(VAR store: Store; proc: Ast.ProcType;
                          VAR name: Strings.String): BOOLEAN;
  CONST
    GenericTypes = {Ast.IdRecord, Ast.IdPointer, Ast.IdArray, Ast.IdProcType};
  VAR p: Ast.Declaration;
      i: INTEGER;
      ok, generic: BOOLEAN;
      nm: ARRAY 4096 OF CHAR;

    PROCEDURE Type(VAR name: ARRAY OF CHAR; VAR i: INTEGER; t: Ast.Type): BOOLEAN;
    VAR ok: BOOLEAN;
    BEGIN
      CASE t.id OF
        Ast.IdInteger  ,
        Ast.IdSet      : ok := Strings.CopyCharsNull(name, i, "I")
      | Ast.IdLongInt  ,
        Ast.IdLongSet  : ok := Strings.CopyCharsNull(name, i, "J")
      | Ast.IdBoolean  : ok := Strings.CopyCharsNull(name, i, "Z")
      | Ast.IdByte     : ok := Strings.CopyCharsNull(name, i, "B")
      | Ast.IdChar     : ok := Strings.CopyCharsNull(name, i, "C")
      | Ast.IdReal     : ok := Strings.CopyCharsNull(name, i, "D")
      | Ast.IdReal32   : ok := Strings.CopyCharsNull(name, i, "F")
      | Ast.IdPointer  : ok := Strings.CopyCharsNull(name, i, "L")

      | Ast.IdArray    : ok := Strings.CopyCharsNull(name, i, "A")
      | Ast.IdRecord   : ok := Strings.CopyCharsNull(name, i, "R")
      | Ast.IdProcType : ok := Strings.CopyCharsNull(name, i, "P")
      END
    RETURN
      ok
    END Type;

  BEGIN
    i := 0;
    IF proc.type = NIL THEN
      ok := Strings.CopyCharsNull(nm, i, "V");
      generic := FALSE
    ELSE
      ok := Type(nm, i, proc.type);
      generic := proc.type.id IN GenericTypes
    END;
    p := proc.params;
    WHILE (p # NIL) & ok DO
      ok := Type(nm, i, p.type);
      generic := generic OR (p.type.id IN GenericTypes);
      p := p.next
    END;
    ok := ok & Strings.CopyCharsNull(nm, i, "_proc");
  RETURN
    Add(store, name, proc, generic, nm, i)
  END GenerateName;

END JavaStoreProcTypes.

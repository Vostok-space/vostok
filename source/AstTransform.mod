(*  Transformations of abstract syntax tree to simplify generation
 *
 *  Copyright (C) 2018-2019,2021 ComdivByZero
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
MODULE AstTransform;

  IMPORT Out, V, Ast,
         TranLim   := TranslatorLimits,
         Strings   := StringStore,
         Chars0X,
         SpecIdent := OberonSpecIdent;

  CONST
    AnonUnchanged*          = 0;
    AnonToName*             = 1;
    AnonDeclareSameScope*   = 2;
    AnonDeclareGlobalScope* = 3;
    AnonSet = {0..3};

    OutParamUnchanged*      = 0;
    OutParamToArray*        = 1;
    OutParamToArrayAndIndex*= 2;
    OutParamSet = {0..2};

  TYPE
    Options* = RECORD(V.Base)
      setSubBrace*: BOOLEAN;

      anonRecord* ,
      outParam    : INTEGER;

      (* для длины массива - 1 и маркировки прохода *)
      mark: Ast.ExprInteger;

      module: Ast.Module;
      consts: RECORD
        first, last: Ast.Const
      END;
      types: RECORD
        first, last: Ast.Type
      END;

      anon: INTEGER
    END;

  VAR
    type      : PROCEDURE(t: Ast.Type;   VAR o: Options);
    expression: PROCEDURE(VAR e: Ast.Expression; o: Options);
    incParam  : Ast.FormalParam;

  PROCEDURE Import(imp: Ast.Import; o: Options);
  END Import;

  PROCEDURE Const(c: Ast.Const; o: Options);
  END Const;

  PROCEDURE DefaultOptions*(VAR o: Options);
  BEGIN
    o.setSubBrace := TRUE;
    o.anonRecord := AnonDeclareGlobalScope;
    o.outParam := OutParamToArrayAndIndex;

    o.mark := Ast.ExprIntegerNew(1)
  END DefaultOptions;

  PROCEDURE ChangeTypeOnArray(VAR t: Ast.Type; o: Options);
  BEGIN
    ASSERT(t.id # Ast.IdArray);
    t := Ast.ArrayGet(t, o.mark (* 1 *))
  END ChangeTypeOnArray;

  PROCEDURE Var(d: Ast.Declaration; VAR o: Options);
  BEGIN
    type(d.type, o);
    IF (o.outParam # 0)
     & ~(d.type.id IN {Ast.IdArray, Ast.IdRecord}) & d(Ast.Var).inVarParam
    THEN
      ChangeTypeOnArray(d.type, o)
    END
  END Var;

  PROCEDURE NameAppend(VAR new: ARRAY OF CHAR; VAR len: INTEGER;
                       name: Strings.String; append: ARRAY OF CHAR);
  BEGIN
    len := 0;
    ASSERT(Strings.CopyToChars(new, len, name)
         & Chars0X.CopyString (new, len, append)
    )
  END NameAppend;

  PROCEDURE AstOk(err: INTEGER);
  BEGIN
    ASSERT(Ast.ErrNo = err);
  END AstOk;

  PROCEDURE FormalParam(proc: Ast.ProcType; ds: Ast.Procedure;
                        VAR sfp: Ast.Declaration; o: Options);
  VAR np, fp: Ast.FormalParam; var: Ast.Var;
      name: ARRAY TranLim.LenName + 3 OF CHAR;
      ofs: INTEGER;

      PROCEDURE AssignFormalParamToLocalArray(ds: Ast.Procedure; var, fp: Ast.Var; o: Options);
      VAR dst, src: Ast.Designator; a: Ast.Assign;
      BEGIN
        AstOk(Ast.DesignatorNew(dst, var));
        AstOk(Ast.SelArrayNew(dst.sel, dst.type, dst.value, Ast.ExprIntegerNew(0)));
        AstOk(Ast.DesignatorNew(src, fp));
        AstOk(Ast.AssignNew(a, FALSE, dst, src));
        a.next := ds.stats;
        ds.stats := a;
        a.ext := o.mark
      END AssignFormalParamToLocalArray;

  BEGIN
    fp := sfp(Ast.FormalParam);
    IF (o.outParam = 0)
    OR (fp.type.id IN {Ast.IdArray, Ast.IdRecord})
    THEN
      ;
    ELSIF Ast.ParamOut IN fp.access THEN
      fp.type := Ast.ArrayGet(fp.type, NIL);
      fp.ext := o.mark;
      IF o.outParam = OutParamToArrayAndIndex THEN
        NameAppend(name, ofs, fp.name, "_ai");
        AstOk(Ast.ParamInsert(np, fp, o.module, proc, name, 0, ofs,
                              Ast.TypeGet(Ast.IdInteger), {Ast.ParamIn}));
        sfp := np
      END
    ELSIF (ds # NIL) & fp.inVarParam THEN
      ASSERT(fp.ext = NIL);
      NameAppend(name, ofs, fp.name, "_prm");
      AstOk(Ast.VarAdd(var, ds, name, 0, ofs));
      var.type := Ast.ArrayGet(fp.type, o.mark (* 1 *));
      fp.ext := var;
      AssignFormalParamToLocalArray(ds, var, fp, o)
    END
  END FormalParam;

  PROCEDURE ProcType(p: Ast.ProcType; ds: Ast.Procedure; o: Options);
  VAR fp: Ast.Declaration;
  BEGIN
    fp := p.params;
    WHILE fp # NIL DO
      FormalParam(p, ds, fp, o);
      fp := fp.next
    END
  END ProcType;

  PROCEDURE Record(r: Ast.Record; VAR o: Options);
  VAR d: Ast.Declaration;

    (* TODO Привязать действия к опции o.anonRecord *)
    PROCEDURE Link(t: Ast.Record; VAR o: Options);

      PROCEDURE Name(d: Ast.Declaration; i: INTEGER);
      CONST Z = ORD("0");
      VAR name: ARRAY 10 OF CHAR;
      BEGIN
        name    := "Anon_";
        name[5] := CHR(Z + i DIV 1000 MOD 10);
        name[6] := CHR(Z + i DIV 100  MOD 10);
        name[7] := CHR(Z + i DIV 10   MOD 10);
        name[8] := CHR(Z + i          MOD 10);

        Ast.PutChars(d.module.m, d.name, name, 0, LEN(name) - 1)
      END Name;
    BEGIN
      IF o.types.first = NIL THEN
        o.types.first := t
      ELSE
        o.types.last.next := t
      END;
      o.types.last := t;

      t.up := o.module.dag;

      Name(t, o.anon);
      INC(o.anon);
    END Link;
  BEGIN
    IF r.pointer # NIL THEN
      r.pointer.ext := o.mark
    END;
    d := r.vars;
    WHILE d # NIL DO
      Var(d, o);
      d := d.next
    END;

    IF ~Strings.IsDefined(r.name)
     & ((r.pointer = NIL) OR ~Strings.IsDefined(r.pointer.name))
    THEN
      Link(r, o)
    END
  END Record;

  PROCEDURE Type(t: Ast.Type; VAR o: Options);

    PROCEDURE Array(a: Ast.Type; VAR o: Options);
    VAR t: Ast.Type;
    BEGIN
      t := a.type;
      WHILE t.id = Ast.IdArray DO
        t := t.type
      END;
      Type(t, o)
    END Array;
  BEGIN
    IF (o.outParam # 0) & (t.ext # o.mark) THEN
      t.ext := o.mark;
      CASE t.id OF
        Ast.IdRecord  : Record(t(Ast.Record), o)
      | Ast.IdPointer : Record(t.type(Ast.Record), o)
      | Ast.IdProcType, Ast.IdFuncType
                      : ProcType(t(Ast.ProcType), NIL, o)
      | Ast.IdArray   : Array(t, o)

      | Ast.IdInteger .. Ast.IdLongSet
                      : ;
      END
    END
  END Type;

  PROCEDURE IsChangedParam(outParam: INTEGER; v: Ast.Var; mark: Ast.ExprInteger): Ast.Factor;
  VAR t: Ast.Type; index: Ast.Factor; d: Ast.Designator;
  BEGIN
    t := v.type;
    IF t.id # Ast.IdArray THEN
      index := NIL
    ELSIF t(Ast.Array).count = mark THEN
      index := Ast.ExprIntegerNew(0)
    ELSIF (v IS Ast.FormalParam) & (v.ext = mark) THEN
      IF outParam = OutParamToArray THEN
        index := Ast.ExprIntegerNew(0)
      ELSE
        AstOk(Ast.DesignatorNew(d, v(Ast.FormalParam).next));
        index := d
      END
    ELSE
      index := NIL
    END
  RETURN
    index
  END IsChangedParam;

  PROCEDURE CutIndex*(outParam: INTEGER; e: Ast.Designator): Ast.Expression;
  VAR i: Ast.Expression; prev, sel: Ast.Selector; di: Ast.Designator;
  BEGIN
    ASSERT(outParam IN OutParamSet);

    sel  := e.sel;
    IF sel # NIL THEN
      prev := NIL;
      WHILE sel.next # NIL DO
        prev := sel;
        sel  := sel.next
      END;
      IF ~(sel IS Ast.SelArray) THEN
        i := Ast.ExprIntegerNew(0)
      ELSE
        i := sel(Ast.SelArray).index;
        IF prev = NIL THEN
          e.sel := NIL
        ELSE
          prev.next := NIL
        END
      END
    ELSIF (outParam = OutParamToArrayAndIndex) & (e.decl IS Ast.FormalParam) THEN
      AstOk(Ast.DesignatorNew(di, e.decl(Ast.FormalParam).next));
      i := di
    ELSE
      i := Ast.ExprIntegerNew(0)
    END
    RETURN i
  END CutIndex;

  PROCEDURE Designator(d: Ast.Designator; o: Options;
                       actualParam: Ast.Parameter; fp: Ast.FormalParam);
  VAR sel, last: Ast.Selector; index: Ast.Expression;

    PROCEDURE Item(o: Options; d: Ast.Designator; prev: Ast.Selector; VAR sel: Ast.Selector;
                   v: Ast.Var; mark: Ast.ExprInteger);
    VAR t: Ast.Type; index: Ast.Factor; ns: Ast.Selector;
    BEGIN
      index := IsChangedParam(o.outParam, v, mark);
      IF index # NIL THEN
        t := v.type;
        IF prev # NIL THEN
          ASSERT(prev.next = sel);
          prev.type := t
        END;
        AstOk(Ast.SelArrayNew(ns, t, NIL, index));
        (*
        ASSERT(d.type = ns.type);
        *)
        ns.next := sel;
        sel := ns
      END
    END Item;

    PROCEDURE ReplaceFormalParamByLocalArrayIfUsedAsVarParam(d: Ast.Designator);
    BEGIN
      IF (d.decl.ext # NIL) & (d.decl.ext IS Ast.Var) THEN
        d.decl := d.decl.ext(Ast.Var)
      END
    END ReplaceFormalParamByLocalArrayIfUsedAsVarParam;

  BEGIN
    sel := d.sel;
    ReplaceFormalParamByLocalArrayIfUsedAsVarParam(d);
    IF (sel # NIL) & (o.outParam # 0) & (d.decl IS Ast.Var) THEN
      Item(o, NIL, NIL, d.sel, d.decl(Ast.Var), o.mark)
    END;
    last := NIL;
    WHILE sel # NIL DO
      IF sel IS Ast.SelArray THEN
        expression(sel(Ast.SelArray).index, o)
      END;
      last := sel;
      sel := sel.next;
      IF (sel # NIL) & (o.outParam # 0) & (last IS Ast.SelRecord) THEN
        Item(o, NIL, last, last.next, last(Ast.SelRecord).var, o.mark)
      END
    END;

    IF o.outParam # 0 THEN
      IF actualParam = NIL THEN
        IF last = NIL THEN
          IF d.decl IS Ast.Var THEN
            Item(o, d, NIL, d.sel, d.decl(Ast.Var), o.mark)
          END
        ELSIF last IS Ast.SelRecord THEN
          Item(o, d, last, last.next, last(Ast.SelRecord).var, o.mark)
        END
      ELSIF (fp.type.id = Ast.IdArray) & (fp.ext = o.mark) THEN
          index := CutIndex(o.outParam, actualParam.expr(Ast.Designator));
          IF TRUE(*TODO*) OR (index.value = NIL) OR (index.value(Ast.ExprInteger).int # 0) THEN
            Ast.CallParamInsert(actualParam, fp, index, actualParam)
          END
      ELSE
        IF last = NIL THEN
          IF d.decl IS Ast.Var THEN
            Item(o, d, NIL, d.sel, d.decl(Ast.Var), o.mark)
          END
        ELSIF last IS Ast.SelRecord THEN
          Item(o, d, last, last.next, last(Ast.SelRecord).var, o.mark)
        END
      END
    END
  END Designator;

  PROCEDURE Expression(VAR e: Ast.Expression; o: Options);

    PROCEDURE Set(set: Ast.ExprSet; o: Options);
    BEGIN
      IF set.exprs[0] = NIL THEN
        ASSERT(set.exprs[1] = NIL);
        ASSERT(set.next = NIL)
      ELSE
        REPEAT
          Expression(set.exprs[0], o);
          IF set.exprs[1] # NIL THEN
            Expression(set.exprs[1], o)
          END;
          set := set.next
        UNTIL set = NIL
      END
    END Set;

    PROCEDURE Call(c: Ast.ExprCall; o: Options);
    VAR p: Ast.Parameter; fp: Ast.Declaration;
    BEGIN
      Designator(c.designator, o, NIL, NIL);
      p  := c.params;
      fp := c.designator.type(Ast.ProcType).params;
      WHILE p # NIL DO
        IF p.expr.id = Ast.IdDesignator THEN
          Designator(p.expr(Ast.Designator), o, p, fp(Ast.FormalParam))
        ELSE
          Expression(p.expr, o)
        END;
        p  := p.next;
        IF fp # NIL THEN
          fp := fp.next;
          IF (fp = NIL)
           & ((c.designator.decl.id = SpecIdent.Inc)
           OR (c.designator.decl.id = SpecIdent.Dec))
          THEN
            fp := incParam
          END
        END
      END
    END Call;

    PROCEDURE Relation(r: Ast.ExprRelation; o: Options);
    BEGIN
      Expression(r.exprs[0], o);
      Expression(r.exprs[1], o)
    END Relation;

    PROCEDURE Sum(sum: Ast.ExprSum; o: Options): Ast.ExprSum;
    VAR s: Ast.ExprSum;

      PROCEDURE IsolateAdd(VAR sum: Ast.ExprSum);
      VAR p, s: Ast.ExprSum; value: Ast.Factor;
      BEGIN
        value := sum.value;
        REPEAT
          s := sum.next;
          WHILE (s # NIL) & (s.add # Ast.Plus) DO
            s := s.next
          END;
          WHILE (s # NIL) & (s.add # Ast.Minus) DO
            p := s;
            s := s.next
          END;
          IF s # NIL THEN
            p.next := NIL;
            AstOk(Ast.ExprSumNew(sum, Ast.NoSign, Ast.ExprBracesNew(sum)));
            sum.next := s
          END
        UNTIL s = NIL;
        sum.value := value
      END IsolateAdd;

    BEGIN
      s := sum;
      REPEAT
        Expression(s.term, o);
        s := s.next;
      UNTIL s = NIL;
      IF o.setSubBrace & (sum.type.id IN Ast.Sets) THEN
        IsolateAdd(sum)
      END;
    RETURN
      sum
    END Sum;

    PROCEDURE Term(term: Ast.ExprTerm; o: Options);

      PROCEDURE Factor(f: Ast.Factor; o: Options);
      VAR e: Ast.Expression;
      BEGIN
        e := f;
        Expression(e, o);
        ASSERT(e = f)
      END Factor;

    BEGIN
      REPEAT
        Factor(term.factor, o);
        IF term.expr IS Ast.ExprTerm THEN
          term := term.expr(Ast.ExprTerm)
        ELSE
          Expression(term.expr, o);
          term := NIL
        END
      UNTIL term = NIL
    END Term;

    PROCEDURE IsExtension(is: Ast.ExprIsExtension; o: Options);
    BEGIN
      Designator(is.designator, o, NIL, NIL);
    END IsExtension;

  BEGIN
    CASE e.id OF
      Ast.IdInteger .. Ast.IdReal32, Ast.IdPointer, Ast.IdString, Ast.IdExprType
                       : (* *)
    | Ast.IdSet, Ast.IdLongSet
                       : Set(e(Ast.ExprSet), o)
    | Ast.IdCall       : Call(e(Ast.ExprCall), o)
    | Ast.IdDesignator : Designator(e(Ast.Designator), o, NIL, NIL)
    | Ast.IdRelation   : Relation(e(Ast.ExprRelation), o)
    | Ast.IdSum        : e := Sum(e(Ast.ExprSum), o)
    | Ast.IdTerm       : Term(e(Ast.ExprTerm), o)
    | Ast.IdNegate     : Expression(e(Ast.ExprNegate).expr, o)
    | Ast.IdBraces     : Expression(e(Ast.ExprBraces).expr, o)
    | Ast.IdIsExtension: IsExtension(e(Ast.ExprIsExtension), o)
    END
  END Expression;

  PROCEDURE Statements(VAR stats: Ast.Statement; o: Options);
  VAR st: Ast.Statement;

    PROCEDURE WhileIf(wi: Ast.WhileIf; o: Options);
    BEGIN
      REPEAT
        IF wi.expr # NIL THEN
          Expression(wi.expr, o)
        END;
        Statements(wi.stats, o);
        wi := wi.elsif
      UNTIL wi = NIL
    END WhileIf;

    PROCEDURE Repeat(r: Ast.Repeat; o: Options);
    BEGIN
      Statements(r.stats, o);
      Expression(r.expr, o)
    END Repeat;

    PROCEDURE For(VAR stats: Ast.Statement; for: Ast.For; o: Options);
    VAR w: Ast.While; e: Ast.ExprRelation; var, d: Ast.Designator;
        last: Ast.Statement; inc: Ast.Call; einc: Ast.ExprCall;
        fp: Ast.FormalParam; par: Ast.Parameter;
        a: Ast.Assign; rel, ident: INTEGER;
    BEGIN
      IF (o.outParam # 0) & for.var.inVarParam THEN
        AstOk(Ast.DesignatorNew(var, for.var));
        AstOk(Ast.SelArrayNew(var.sel, var.type, var.value, Ast.ExprIntegerNew(0)));
        AstOk(Ast.AssignNew(a, FALSE, var, for.expr));
        IF for.by > 0 THEN
          rel   := Ast.LessEqual;
          ident := SpecIdent.Inc
        ELSE
          rel   := Ast.GreaterEqual;
          ident := SpecIdent.Dec
        END;
        AstOk(Ast.ExprRelationNew(e, var, rel, for.to));
        AstOk(Ast.WhileNew(w, e, for.stats));
        AstOk(Ast.DesignatorNew(d, Ast.PredefinedGet(ident)));
        AstOk(Ast.CallNew(inc, d));
        einc := inc.expr(Ast.ExprCall);
        fp := d.type(Ast.ProcType).params;
        AstOk(Ast.CallParamNew(einc, einc.params, var, fp));
        IF for.by # 1 THEN
          par := einc.params;
          AstOk(Ast.CallParamNew(einc, par, Ast.ExprIntegerNew(ABS(for.by)), fp));
        END;
        last := NIL;
        Ast.StatementAdd(w.stats, last, inc);
        Ast.StatementReplace(stats, for, a);
        w.next := a.next;
        a.next := w
      ELSE
        Expression(for.expr, o);
        Expression(for.to, o);
        Statements(for.stats, o)
      END
    END For;

    PROCEDURE Case(c: Ast.Case; o: Options);
    VAR el: Ast.CaseElement;
    BEGIN
      Expression(c.expr, o);
      el := c.elements;
      WHILE el # NIL DO
        Statements(el.stats, o);
        el := el.next
      END;
      Statements(c.else, o)
    END Case;

    PROCEDURE Assign(a: Ast.Assign; o: Options);
    BEGIN
      Designator(a.designator, o, NIL, NIL);
      Expression(a.expr, o)
    END Assign;
  BEGIN
    st := stats;
    WHILE st # NIL DO
      IF st IS Ast.Assign THEN
        IF st.ext # o.mark THEN
          Assign(st(Ast.Assign), o)
        END
      ELSIF st IS Ast.Call THEN
        Expression(st.expr, o)
      ELSIF st IS Ast.WhileIf THEN
        WhileIf(st(Ast.WhileIf), o)
      ELSIF st IS Ast.Repeat THEN
        Repeat(st(Ast.Repeat), o)
      ELSIF st IS Ast.For THEN
        For(stats, st(Ast.For), o)
      ELSE ASSERT(st IS Ast.Case);
        Case(st(Ast.Case), o)
      END;
      st := st.next
    END
  END Statements;

  PROCEDURE LineName(decl: Ast.Declaration);
  VAR up: Ast.Declarations;
      prs: ARRAY TranLim.DeepProcedures + 1 OF Ast.Declarations;
      name: ARRAY 1025 OF CHAR;
      i, ofs: INTEGER;
  BEGIN
    up := decl.up.d;
    i  := 0;
    WHILE up.up # NIL DO
      prs[i] := up;
      INC(i);
      up := up.up.d
    END;
    ofs := 0;
    REPEAT
      DEC(i)
    UNTIL ~Strings.CopyToChars(name, ofs, prs[i].name)
       OR ~Chars0X.PutChar(name, ofs, "_")
       OR (i = 0);

    IF (i = 0) & Strings.CopyToChars(name, ofs, decl.name) THEN
      Ast.PutChars(decl.module.m, decl.name, name, 0, ofs)
    END
  END LineName;

  PROCEDURE ProcCutConstAndTypes(ds: Ast.Declarations; VAR o: Options);
  BEGIN
    IF ds.consts # NIL THEN
      IF o.consts.first = NIL THEN
        o.consts.first := ds.consts;
        o.consts.last := ds.consts;
        ds.consts := NIL;
        LineName(o.consts.last);
        o.consts.last.up := ds.module.m.dag;
        WHILE (o.consts.last.next # NIL) & (o.consts.last.next IS Ast.Const) DO
          o.consts.last := o.consts.last.next(Ast.Const);
          LineName(o.consts.last);
          o.consts.last.up := ds.module.m.dag
        END
      ELSE ASSERT(o.consts.last # NIL);
        o.consts.last.next := ds.consts;
        ds.consts := NIL;
        o.consts.last.up := ds.module.m.dag;
        WHILE (o.consts.last.next # NIL) & (o.consts.last.next IS Ast.Const) DO
          o.consts.last := o.consts.last.next(Ast.Const);
          LineName(o.consts.last);
          o.consts.last.up := ds.module.m.dag
        END
      END
    END;
    IF ds.types # NIL THEN
      IF o.types.first = NIL THEN
        o.types.first := ds.types;
        o.types.last := ds.types;
        ds.types := NIL;
        LineName(o.types.last);
        o.types.last.up := ds.module.m.dag;
        WHILE (o.types.last.next # NIL) & (o.types.last.next IS Ast.Type) DO
          o.types.last := o.types.last.next(Ast.Type);
          LineName(o.types.last);
          o.types.last.up := ds.module.m.dag
        END
      ELSE ASSERT(o.types.last # NIL);
        o.types.last.next := ds.types;
        ds.types := NIL;
        o.types.last.up := ds.module.m.dag;
        WHILE (o.types.last.next # NIL) & (o.types.last.next IS Ast.Type) DO
          o.types.last := o.types.last.next(Ast.Type);
          LineName(o.types.last);
          o.types.last.up := ds.module.m.dag
        END
      END
    END
  END ProcCutConstAndTypes;

  PROCEDURE Declarations(ds: Ast.Declarations; VAR o: Options);
  VAR d, last: Ast.Declaration;

    PROCEDURE Proc(p: Ast.Procedure; VAR o: Options);
    BEGIN
      ProcType(p.header, p, o);
      Declarations(p, o);
      IF p.return # NIL THEN
        Expression(p.return, o)
      END
    END Proc;

  BEGIN
    d := ds.start;
    last := NIL;
    WHILE (d # NIL) & (d IS Ast.Import) DO
      Import(d(Ast.Import), o);
      last := d;
      d := d.next
    END;

    WHILE (d # NIL) & (d IS Ast.Const) DO
      Const(d(Ast.Const), o);
      d := d.next
    END;

    WHILE (d # NIL) & (d IS Ast.Type) DO
      Type(d(Ast.Type), o);
      d := d.next
    END;

    IF ds.up # NIL THEN
      ProcCutConstAndTypes(ds, o)
    ELSE
      IF ds.consts # NIL THEN
        o.consts.first := ds.consts;
        o.consts.last := ds.consts;
        WHILE (o.consts.last.next # NIL) & (o.consts.last.next IS Ast.Const) DO
          o.consts.last := o.consts.last.next(Ast.Const)
        END
      END;
      IF ds.types # NIL THEN
        IF o.types.first = NIL THEN
          o.types.first := ds.types;
          o.types.last := ds.types
        ELSE
          o.types.last.next := ds.types
        END;
        WHILE (o.types.last.next # NIL) & (o.types.last.next IS Ast.Type) DO
          o.types.last := o.types.last.next(Ast.Type)
        END
      END
    END;

    WHILE (d # NIL) & (d IS Ast.Var) DO
      Var(d, o);
      d := d.next
    END;

    WHILE d # NIL DO
      Proc(d(Ast.Procedure), o);
      d := d.next
    END;

    IF ds.up = NIL THEN
      IF o.consts.first # NIL THEN
        ds.consts := o.consts.first;
        IF last # NIL THEN
          last.next := o.consts.first
        ELSE
          ds.start := o.consts.first
        END;
        last := o.consts.last
      END;
      IF o.types.first # NIL THEN
        ds.types := o.types.first;
        IF last # NIL THEN
          last.next := o.types.first
        ELSE
          ds.start := o.types.first
        END;
        last := o.types.last
      END
    END;
    IF last # NIL THEN
      IF ds.vars # NIL THEN
        last.next := ds.vars
      ELSE
        last.next := ds.procedures
      END
    ELSE
      IF ds.vars # NIL THEN
        ds.start := ds.vars
      ELSE
        ds.start := ds.procedures
      END
    END;

    Statements(ds.stats, o)
  END Declarations;

  PROCEDURE Transform(m: Ast.Module; VAR o: Options);
  VAR imp: Ast.Declaration;
  BEGIN
    imp := m.import;
    WHILE (imp # NIL) & (imp IS Ast.Import) DO
      IF (imp.module.m.ext # o.mark) & ~imp.module.m.spec THEN
        imp.module.m.ext := o.mark;
        Ast.ModuleReopen(imp.module.m);
        Transform(imp.module.m, o)
      END;
      imp := imp.next
    END;
    o.module := m;
    o.consts.first := NIL;
    o.consts.last  := NIL;
    o.types.first  := NIL;
    o.types.last   := NIL;
    o.anon         := 0;
    Declarations(m, o)
  END Transform;

  PROCEDURE Fix(m: Ast.Module; mark: Ast.Expression);
  VAR imp: Ast.Declaration;
  BEGIN
    imp := m.import;
    WHILE (imp # NIL) & (imp IS Ast.Import) DO
      IF imp.module.m.ext = mark THEN
        imp.module.m.ext := NIL;
        AstOk(Ast.ModuleEnd(imp.module.m));
        Fix(imp.module.m, mark)
      END;
      imp := imp.next
    END;
  END Fix;

  PROCEDURE Do*(m: Ast.Module; VAR o: Options);
  BEGIN
    ASSERT(o.anonRecord IN AnonSet);
    ASSERT(o.outParam IN OutParamSet);

    Transform(m, o);
    Fix(m, o.mark)
  END Do;

  PROCEDURE Init;
  VAR abs: Ast.Declaration;
  BEGIN
    type       := Type;
    expression := Expression;

    abs := Ast.PredefinedGet(SpecIdent.Abs);
    incParam := abs.type(Ast.ProcType).params;
    ASSERT((incParam.next = NIL) & (incParam.type.id = Ast.IdInteger))
  END Init;

BEGIN
  Init
END AstTransform.

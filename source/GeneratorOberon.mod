(*  Generator of Oberon-code by abstract syntax tree
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
MODULE GeneratorOberon;

IMPORT
  V, LongSet, Ast,
  Log, Stream := VDataStream,
  Text := TextGenerator, Strings := StringStore, Utf8Transform, Utf8,
  SpecIdent := OberonSpecIdent, Scanner, Hex,
  GenOptions, GenCommon;

CONST
  Supported* = TRUE;

  StdO7* = 1;
  StdAo* = 2;
  StdCp* = 3;

TYPE
  Options* = POINTER TO RECORD(GenOptions.R)
    std*: INTEGER;
    multibranchWhile*: BOOLEAN
  END;

  Generator = RECORD(Text.Out)
    module: Ast.Module;
    opt: Options
  END;

VAR
  declarations: PROCEDURE(VAR gen: Generator; ds: Ast.Declarations);
  statements  : PROCEDURE(VAR gen: Generator; stats: Ast.Statement);
  expression  : PROCEDURE(VAR gen: Generator; expr: Ast.Expression);
  type        : PROCEDURE(VAR gen: Generator; typ: Ast.Type);

  PROCEDURE Ident(VAR gen: Generator; ident: Strings.String);
  BEGIN
    IF SpecIdent.IsSpecName(ident) THEN
      (* TODO *)
      Text.Str(gen, "dnt")
    END;
    GenCommon.Ident(gen, ident, gen.opt.identEnc)
  END Ident;

  PROCEDURE Name(VAR gen: Generator; decl: Ast.Declaration);
  BEGIN
    Ident(gen, decl.name)
  END Name;

  PROCEDURE GlobalName(VAR gen: Generator; decl: Ast.Declaration);
  VAR imp: Ast.Import;
    PROCEDURE Imported(imp: Ast.Declaration; mod: Ast.Module): Ast.Import;
    BEGIN
      WHILE imp.module.m # mod DO
        imp := imp.next
      END
    RETURN
      imp(Ast.Import)
    END Imported;
  BEGIN
    IF (decl.module # NIL) & (gen.module # decl.module.m) THEN
      imp := Imported(gen.module.import, decl.module.m);
      Ident(gen, imp.name);
      Text.Char(gen, ".")
    END;
    Name(gen, decl)
  END GlobalName;

  PROCEDURE DefaultOptions*(): Options;
  VAR o: Options;
  BEGIN
    NEW(o);
    IF o # NIL THEN
      V.Init(o^);
      GenOptions.Default(o^);
      o.std := StdO7;
      o.multibranchWhile := o.std = StdO7
    END;
  RETURN
    o
  END DefaultOptions;

  PROCEDURE Init(VAR gen: Generator; out: Stream.POut; m: Ast.Module; opt: Options);
  BEGIN
    ASSERT(m # NIL);

    Text.Init(gen, out);

    gen.module := m;
    gen.opt    := opt
  END Init;

  PROCEDURE LnClose(VAR gen: Generator);
  BEGIN
    Text.IndentClose(gen);
    Text.Ln(gen)
  END LnClose;

  PROCEDURE Comment(VAR gen: Generator; text: Strings.String);
  BEGIN
    GenCommon.CommentOberon(gen, gen.opt^, text)
  END Comment;

  PROCEDURE EmptyLines(VAR gen: Generator; n: Ast.PNode);
  BEGIN
    IF 0 < n.emptyLines THEN
      Text.Ln(gen)
    END
  END EmptyLines;

  PROCEDURE Imports(VAR gen: Generator; d: Ast.Declaration);
    PROCEDURE Import(VAR gen: Generator; decl: Ast.Declaration);
    VAR name: Strings.String;
    BEGIN
      Name(gen, decl);
      name := decl.module.m.name;
      IF Strings.Compare(decl.name, name) # 0 THEN
        Text.Str(gen, " := ");
        Ident(gen, name)
      END
    END Import;
  BEGIN
    IF gen.opt.std = StdAo THEN
      Text.StrOpen(gen, "IMPORT O_7, SYSTEM,")
    ELSE
      Text.StrOpen(gen, "IMPORT")
    END;

    Import(gen, d);
    d := d.next;
    WHILE (d # NIL) & (d IS Ast.Import) DO
      Text.StrLn(gen, ",");
      Import(gen, d);
      d := d.next
    END;
    Text.StrLn(gen, ";");

    LnClose(gen)
  END Imports;

  PROCEDURE ExpressionBraced(VAR gen: Generator;
                             l: ARRAY OF CHAR; e: Ast.Expression; r: ARRAY OF CHAR);
  BEGIN
    Text.Str(gen, l);
    expression(gen, e);
    Text.Str(gen, r)
  END ExpressionBraced;

  PROCEDURE ExpressionInfix(VAR gen: Generator;
                            e1: Ast.Expression; oper: ARRAY OF CHAR; e2: Ast.Expression);
  BEGIN
    expression(gen, e1);
    Text.Str(gen, oper);
    expression(gen, e2)
  END ExpressionInfix;

  PROCEDURE Designator(VAR gen: Generator; des: Ast.Designator);
  VAR sel: Ast.Selector;

    PROCEDURE Selector(VAR gen: Generator; VAR sel: Ast.Selector);

      PROCEDURE Record(VAR gen: Generator; sel: Ast.Selector);
      BEGIN
        Text.Str(gen, ".");
        Name(gen, sel(Ast.SelRecord).var);
      END Record;

      PROCEDURE Array(VAR gen: Generator; VAR sel: Ast.Selector);
      BEGIN
        Text.Str(gen, "[");
        expression(gen, sel(Ast.SelArray).index);
        sel := sel.next;
        WHILE (sel # NIL) & (sel IS Ast.SelArray) DO
          Text.Char(gen, ",");
          expression(gen, sel(Ast.SelArray).index);
          sel := sel.next;
        END;
        Text.Str(gen, "]")
      END Array;

      PROCEDURE TypeGuard(VAR gen: Generator; sel: Ast.SelGuard);
      BEGIN
        Text.Char(gen, "(");
        GlobalName(gen, sel.type);
        Text.Char(gen, ")");
      END TypeGuard;
    BEGIN
      IF sel IS Ast.SelArray THEN
        Array(gen, sel)
      ELSE
        IF sel IS Ast.SelRecord THEN
          Record(gen, sel)
        ELSIF sel IS Ast.SelPointer THEN
          Text.Char(gen, "^")
        ELSE
          TypeGuard(gen, sel(Ast.SelGuard))
        END;
        sel := sel.next
      END
    END Selector;
  BEGIN
    GlobalName(gen, des.decl);
    sel := des.sel;
    WHILE sel # NIL DO
      Selector(gen, sel)
    END
  END Designator;

  PROCEDURE Char(VAR gen: Generator; code: INTEGER; usedAs: INTEGER);
  VAR s: ARRAY 4 OF CHAR;
  BEGIN
    ASSERT((0 <= code) & (code < 100H));
    IF (code < 20H) OR (code >= 80H)
    OR (code = ORD(Utf8.DQuote)) & (gen.opt.std = StdO7)
    THEN
      s[0] := "0";
      s[1] := Hex.To(code DIV 10H);
      s[2] := Hex.To(code MOD 10H);
      IF (gen.opt.std = StdO7) OR (usedAs # Ast.StrUsedAsArray) THEN
        s[3] := "X";
        Text.Data(gen, s, 0, 4)
      ELSE
        s[3] := "H";
        Text.Str(gen, "O_7.ch[");
        Text.Data(gen, s, 0, 4);
        Text.Char(gen, "]")
      END
    ELSE
      IF code = ORD(Utf8.DQuote) THEN
        s[0] := "'";
        s[2] := "'"
      ELSE
        s[0] := Utf8.DQuote;
        s[2] := Utf8.DQuote
      END;
      s[1] := CHR(code);
      Text.Data(gen, s, 0, 3)
    END
  END Char;

  PROCEDURE Expression(VAR gen: Generator; expr: Ast.Expression);

    PROCEDURE Call(VAR gen: Generator; call: Ast.ExprCall);
    VAR p: Ast.Parameter; fp: Ast.Declaration;

      PROCEDURE Predefined(VAR gen: Generator; call: Ast.ExprCall);
      VAR e1: Ast.Expression; p2: Ast.Parameter;

        PROCEDURE Ord(VAR gen: Generator; e: Ast.Expression);
        BEGIN
          IF (gen.opt.std # StdAo) OR ~(e.type.id IN {Ast.IdSet, Ast.IdBoolean}) THEN
            (* TODO *)
            ExpressionBraced(gen, "ORD(", e, ")")
          ELSIF e.type.id = Ast.IdSet THEN
            IF e.value = NIL THEN
              ExpressionBraced(gen, "O_7.Ord(", e, ")")
            ELSE
              Text.Int(gen, LongSet.Ord(e.value(Ast.ExprSetValue).set))
            END
          ELSE ASSERT(e.type.id = Ast.IdBoolean);
            IF e.value = NIL THEN
              ExpressionBraced(gen, "O_7.Bti(", e, ")")
            ELSE
              Text.Int(gen, ORD(e.value(Ast.ExprBoolean).bool))
            END
          END
        END Ord;

        PROCEDURE Assert(VAR gen: Generator; e: Ast.Expression);
        BEGIN
          IF (gen.opt.std = StdO7)
          OR (e.value = NIL) OR e.value(Ast.ExprBoolean).bool
          THEN
            ExpressionBraced(gen, "ASSERT(", e, ")")
          ELSE
            Text.Str(gen, "HALT(1)")
          END
        END Assert;

        PROCEDURE Pack(VAR gen: Generator; e1, e2: Ast.Expression);
        BEGIN
          (* TODO *)
          ExpressionBraced(gen, "PACK(", e1, ", ");
          Expression(gen, e2);
          Text.Char(gen, ")")
        END Pack;

        PROCEDURE Unpack(VAR gen: Generator; e1, e2: Ast.Expression);
        BEGIN
          (* TODO *)
          ExpressionBraced(gen, "UNPK(", e1, ", ");
          Expression(gen, e2);
          Text.Char(gen, ")")
        END Unpack;

        PROCEDURE One(VAR gen: Generator; name: ARRAY OF CHAR; e: Ast.Expression);
        BEGIN
          Text.Str(gen, name);
          ExpressionBraced(gen, "(", e, ")");
        END One;

        PROCEDURE Two(VAR gen: Generator; name: ARRAY OF CHAR; e1, e2: Ast.Expression);
        BEGIN
          Text.Str(gen, name);
          ExpressionBraced(gen, "(", e1, ", ");
          Expression(gen, e2);
          Text.Char(gen, ")")
        END Two;

        PROCEDURE MayTwo(VAR gen: Generator; name: ARRAY OF CHAR;
                         e1: Ast.Expression; p2: Ast.Parameter);
        BEGIN
          Text.Str(gen, name);
          IF p2 = NIL THEN
            ExpressionBraced(gen, "(", e1, ")");
          ELSE
            ExpressionBraced(gen, "(", e1, ", ");
            Expression(gen, p2.expr);
            Text.Char(gen, ")")
          END
        END MayTwo;

        PROCEDURE Lsl(VAR g: Generator; x, n: Ast.Expression);
        BEGIN
          CASE g.opt.std OF
            StdO7: Text.Str(g, "LSL(")
          | StdAo: Text.Str(g, "LSH(")
          | StdCp: Text.Str(g, "ASH(")
          END;
          Expression(g, x);
          ExpressionBraced(g, ", ", n, ")")
        END Lsl;

        PROCEDURE Asr(VAR g: Generator; x, n: Ast.Expression);
        BEGIN
          CASE g.opt.std OF
            StdO7: Text.Str(g, "ASR(");
            Expression(g, x);
            ExpressionBraced(g, ", ", n, ")")
          | StdAo,
            StdCp: Text.Str(g, "ASH(");
            Expression(g, x);
            ExpressionBraced(g, ", -(", n, "))")
          END;
        END Asr;

        PROCEDURE Len(VAR g: Generator; arr: Ast.Expression);
        BEGIN
          CASE g.opt.std OF
            StdO7,
            StdCp: ExpressionBraced(g, "LEN(", arr, ")")
          | StdAo: ExpressionBraced(g, "INTEGER(LEN(", arr, "))")
          END
        END Len;

        PROCEDURE Flt(VAR g: Generator; int: Ast.Expression);
        BEGIN
          CASE g.opt.std OF
            StdO7: ExpressionBraced(g, "FLT(", int, ")")
          | StdAo,
            StdCp: ExpressionBraced(g, "REAL(", int, ")")
          END
        END Flt;

      BEGIN
        e1 := call.params.expr;
        p2 := call.params.next;
        CASE call.designator.decl.id OF
          SpecIdent.Abs  : One(gen, "ABS", e1)
        | SpecIdent.Odd  : One(gen, "ODD", e1)
        | SpecIdent.Len  : Len(gen, e1)
        | SpecIdent.Lsl  : Lsl(gen, e1, p2.expr)
        | SpecIdent.Asr  : Asr(gen, e1, p2.expr)
        | SpecIdent.Ror  : Two(gen, "ROR", e1, p2.expr)
        | SpecIdent.Floor: One(gen, "FLOOR", e1)
        | SpecIdent.Flt  : Flt(gen, e1)
        | SpecIdent.Ord  : Ord(gen, e1)
        | SpecIdent.Chr  : One(gen, "CHR", e1)
        | SpecIdent.Inc  : MayTwo(gen, "INC", e1, p2)
        | SpecIdent.Dec  : MayTwo(gen, "DEC", e1, p2)
        | SpecIdent.Incl : Two(gen, "INCL", e1, p2.expr)
        | SpecIdent.Excl : Two(gen, "EXCL", e1, p2.expr)
        | SpecIdent.New  : One(gen, "NEW", e1)
        | SpecIdent.Assert: Assert(gen, e1)
        | SpecIdent.Pack : Pack(gen, e1, p2.expr)
        | SpecIdent.Unpk : Unpack(gen, e1, p2.expr)
        END
      END Predefined;

      PROCEDURE ActualParam(VAR gen: Generator; VAR p: Ast.Parameter;
                            VAR fp: Ast.Declaration);
      BEGIN
        Expression(gen, p.expr);
        p  := p.next;
        fp := fp.next
      END ActualParam;
    BEGIN
      IF call.designator.decl IS Ast.PredefinedProcedure THEN
        Predefined(gen, call)
      ELSE
        Designator(gen, call.designator);
        Text.Char(gen, "(");
        p  := call.params;
        fp := call.designator.type(Ast.ProcType).params;
        IF p # NIL THEN
          ActualParam(gen, p, fp);
          WHILE p # NIL DO
            Text.Str(gen, ", ");
            ActualParam(gen, p, fp)
          END
        END;
        Text.Char(gen, ")")
      END
    END Call;

    PROCEDURE Relation(VAR gen: Generator; rel: Ast.ExprRelation);

      PROCEDURE Infix(VAR gen: Generator; rel: Ast.ExprRelation; oper: ARRAY OF CHAR);
      BEGIN
        ExpressionInfix(gen, rel.exprs[0], oper, rel.exprs[1])
      END Infix;
    BEGIN
      CASE rel.relation OF
        Scanner.Equal        : Infix(gen, rel, " = " )
      | Scanner.Inequal      : Infix(gen, rel, " # " )
      | Scanner.Less         : Infix(gen, rel, " < " )
      | Scanner.LessEqual    : Infix(gen, rel, " <= ")
      | Scanner.Greater      : Infix(gen, rel, " > " )
      | Scanner.GreaterEqual : Infix(gen, rel, " >= ")
      | Scanner.In           : Infix(gen, rel, " IN ")
      END
    END Relation;

    PROCEDURE Sum(VAR gen: Generator; sum: Ast.ExprSum);
    BEGIN
      IF sum.add = Scanner.Minus THEN
        Text.Str(gen, " -")
      ELSIF sum.add = Scanner.Plus THEN
        Text.Str(gen, " +")
      END;
      Expression(gen, sum.term);
      sum := sum.next;
      WHILE sum # NIL DO
        IF sum.add = Scanner.Minus THEN
          Text.Str(gen, " - ")
        ELSIF sum.add = Scanner.Plus THEN
          Text.Str(gen, " + ")
        ELSIF sum.add = Scanner.Or THEN
          Text.Str(gen, " OR ")
        END;
        Expression(gen, sum.term);
        sum := sum.next
      END
    END Sum;

    PROCEDURE Term(VAR gen: Generator; term: Ast.ExprTerm);
    BEGIN
      REPEAT
        Expression(gen, term.factor);
        CASE term.mult OF
          Scanner.Asterisk : Text.Str(gen, " * "  )
        | Scanner.Slash    : Text.Str(gen, " / "  )
        | Scanner.Div      : Text.Str(gen, " DIV ")
        | Scanner.Mod      : Text.Str(gen, " MOD ")
        | Scanner.And      : Text.Str(gen, " & "  )
        END;
        IF term.expr IS Ast.ExprTerm THEN
          term := term.expr(Ast.ExprTerm);
        ELSE
          Expression(gen, term.expr);
          term := NIL
        END
      UNTIL term = NIL
    END Term;

    PROCEDURE Boolean(VAR gen: Generator; e: Ast.ExprBoolean);
    BEGIN
      IF   e.bool
      THEN Text.Str(gen, "TRUE")
      ELSE Text.Str(gen, "FALSE")
      END
    END Boolean;

    PROCEDURE String(VAR gen: Generator; e: Ast.ExprString);
    VAR w: Strings.String; s: ARRAY 4 OF CHAR;
    BEGIN
      w := e.string;
      IF Strings.IsDefined(w) & (w.block.s[w.ofs] = Utf8.DQuote) THEN
        Text.String(gen, w)
      ELSE
        ASSERT((0 <= e.int) & (e.int < 100H));
        IF (e.int < 20H) OR (e.int >= 80H)
        OR (e.int = ORD(Utf8.DQuote)) & (gen.opt.std = StdO7)
        THEN
          s[0] := "0";
          s[1] := Hex.To(e.int DIV 10H);
          s[2] := Hex.To(e.int MOD 10H);
          IF (gen.opt.std = StdO7) OR (e.usedAs # Ast.StrUsedAsArray) THEN
            s[3] := "X";
            Text.Data(gen, s, 0, 4)
          ELSE
            s[3] := "H";
            Text.Str(gen, "O_7.ch[");
            Text.Data(gen, s, 0, 4);
            Text.Char(gen, "]")
          END
        ELSE
          IF e.int = ORD(Utf8.DQuote) THEN
            s[0] := "'";
            s[2] := "'"
          ELSE
            s[0] := Utf8.DQuote;
            s[2] := Utf8.DQuote
          END;
          s[1] := CHR(e.int);
          Text.Data(gen, s, 0, 3)
        END
      END
    END String;

    PROCEDURE ExprInt(VAR gen: Generator; int: INTEGER);
    BEGIN
      IF int >= 0 THEN
        Text.Int(gen, int)
      ELSE
        Text.Str(gen, "(-");
        Text.Int(gen, -int);
        Text.Char(gen, ")")
      END
    END ExprInt;

    PROCEDURE ExprLongInt(VAR gen: Generator; int: INTEGER);
    BEGIN
      ASSERT(FALSE);
    END ExprLongInt;

    PROCEDURE SetValue(VAR gen: Generator; set: Ast.ExprSetValue);
    BEGIN
      ASSERT(FALSE);
      Text.Int(gen, ORD(set.set[0]));
    END SetValue;

    PROCEDURE Set(VAR gen: Generator; set: Ast.ExprSet);
      PROCEDURE Val(VAR gen: Generator; set: Ast.ExprSet);
        PROCEDURE Item(VAR gen: Generator; set: Ast.ExprSet);
        BEGIN
          IF set.exprs[1] = NIL THEN
            Expression(gen, set.exprs[0])
          ELSE
            ExpressionInfix(gen, set.exprs[0], " .. ", set.exprs[1]);
          END
        END Item;
      BEGIN
        IF (set.next = NIL) & (set.exprs[0] = NIL) THEN
          Text.Str(gen, "{}")
        ELSE
          Text.Char(gen, "{");
          Item(gen, set);
          set := set.next;
          WHILE set # NIL DO
            Text.Str(gen, ", ");
            Item(gen, set);
            set := set.next
          END;
          Text.Char(gen, "}")
        END
      END Val;
    BEGIN
      CASE gen.opt.std OF
        StdO7,
        StdCp: Val(gen, set)
      | StdAo: Text.Str(gen, "SET32("); Val(gen, set); Text.Str(gen, ")")
      END
    END Set;

    PROCEDURE IsExtension(VAR gen: Generator; is: Ast.ExprIsExtension);
    BEGIN
      Designator(gen, is.designator);
      Text.Str(gen, " IS ");
      GlobalName(gen, is.extType)
    END IsExtension;
  BEGIN
    CASE expr.id OF
      Ast.IdInteger:
      ExprInt(gen, expr(Ast.ExprInteger).int)
    | Ast.IdLongInt:
      ExprLongInt(gen, expr(Ast.ExprInteger).int)
    | Ast.IdBoolean:
      Boolean(gen, expr(Ast.ExprBoolean))
    | Ast.IdReal, Ast.IdReal32:
      IF Strings.IsDefined(expr(Ast.ExprReal).str)
      THEN  Text.String(gen, expr(Ast.ExprReal).str)
      ELSE  Text.Real(gen, expr(Ast.ExprReal).real)
      END
    | Ast.IdString:
      String(gen, expr(Ast.ExprString))
    | Ast.IdSet, Ast.IdLongSet:
      IF expr IS Ast.ExprSet
      THEN Set(gen, expr(Ast.ExprSet))
      ELSE SetValue(gen, expr(Ast.ExprSetValue))
      END
    | Ast.IdCall:
      Call(gen, expr(Ast.ExprCall))
    | Ast.IdDesignator:
      IF (gen.opt.std = StdO7)
      OR (expr.value = NIL) OR (expr.value.id # Ast.IdString)
      THEN  Designator(gen, expr(Ast.Designator))
      ELSE  String(gen, expr.value(Ast.ExprString))
      END
    | Ast.IdRelation:
      Relation(gen, expr(Ast.ExprRelation))
    | Ast.IdSum:
      Sum(gen, expr(Ast.ExprSum))
    | Ast.IdTerm: Term(gen, expr(Ast.ExprTerm))
    | Ast.IdNegate:
      Text.Str(gen, "~");
      Expression(gen, expr(Ast.ExprNegate).expr)
    | Ast.IdBraces:
      ExpressionBraced(gen, "(", expr(Ast.ExprBraces).expr, ")")
    | Ast.IdPointer:
      Text.Str(gen, "NIL")
    | Ast.IdIsExtension:
      IsExtension(gen, expr(Ast.ExprIsExtension))
    END
  END Expression;

  PROCEDURE Mark(VAR gen: Generator; d: Ast.Declaration);
  BEGIN
    IF d.mark THEN
      Text.Char(gen, "*")
    END
  END Mark;

  PROCEDURE MarkedName(VAR gen: Generator; d: Ast.Declaration; str: ARRAY OF CHAR);
  BEGIN
    Name(gen, d);
    Mark(gen, d);
    Text.Str(gen, str)
  END MarkedName;

  PROCEDURE Consts(VAR gen: Generator; d: Ast.Declaration);
    PROCEDURE Const(VAR gen: Generator; c: Ast.Const);
    BEGIN
      Comment(gen, c.comment);
      EmptyLines(gen, c);

      MarkedName(gen, c, " = ");
      Expression(gen, c.expr);
      Text.StrLn(gen, ";")
    END Const;
  BEGIN
    Text.StrOpen(gen, "CONST");
    WHILE (d # NIL) & (d IS Ast.Const) DO
      Const(gen, d(Ast.Const));
      d := d.next
    END;
    LnClose(gen)
  END Consts;

  PROCEDURE ProcParams(VAR gen: Generator; proc: Ast.ProcType);
  VAR p: Ast.Declaration;

    PROCEDURE SimilarParams(VAR gen: Generator; VAR p: Ast.Declaration);
    VAR fp: Ast.FormalParam;

      PROCEDURE Access(VAR gen: Generator; fp: Ast.FormalParam);
      BEGIN
        IF Ast.ParamOut IN fp.access THEN
          Text.Str(gen, "VAR ")
        ELSIF (gen.opt.std = StdAo) & (fp.type.id IN Ast.Structures) THEN
          Text.Str(gen, "CONST ")
        END
      END Access;

      PROCEDURE Similar(p1, p2: Ast.FormalParam): BOOLEAN;
      RETURN
        (p1.access = p2.access) & (p1.type = p2.type)
      END Similar;

    BEGIN
      fp := p(Ast.FormalParam);
      Access(gen, fp);
      Name(gen, p);
      p := p.next;
      WHILE (p # NIL) & Similar(fp, p(Ast.FormalParam)) DO
        Text.Str(gen, ", ");
        Name(gen, p);
        p := p.next
      END;
      Text.Str(gen, ": ");
      type(gen, fp.type)
    END SimilarParams;
  BEGIN
    IF proc.params # NIL THEN
      Text.Char(gen, "(");
      p := proc.params;
      SimilarParams(gen, p);
      WHILE p # NIL DO
        Text.Str(gen, "; ");
        SimilarParams(gen, p)
      END;
      IF proc.type = NIL THEN
        Text.Char(gen, ")")
      ELSE
        Text.Str(gen, "): ");
        type(gen, proc.type)
      END
    ELSIF proc.type # NIL THEN
      Text.Str(gen, "(): ");
      type(gen, proc.type)
    END
  END ProcParams;

  PROCEDURE Var(VAR gen: Generator; v: Ast.Var);
  BEGIN
    MarkedName(gen, v, ": ");
    type(gen, v.type)
  END Var;

  PROCEDURE VarList(VAR gen: Generator; v: Ast.Declaration);
  BEGIN
    Var(gen, v(Ast.Var));
    v := v.next;
    WHILE (v # NIL) & (v IS Ast.Var) DO
      Text.StrLn(gen, ";");
      Var(gen, v(Ast.Var));
      v := v.next
    END
  END VarList;

  PROCEDURE Type(VAR gen: Generator; typ: Ast.Type; forDecl: BOOLEAN);

    PROCEDURE Array(VAR gen: Generator; typ: Ast.Type): Ast.Type;
    BEGIN
      IF typ(Ast.Array).count = NIL THEN
        REPEAT
          ASSERT(typ(Ast.Array).count = NIL);
          Text.Str(gen, "ARRAY OF ");
          typ := typ.type
        UNTIL typ.id # Ast.IdArray
      ELSE
        Text.Str(gen, "ARRAY ");
        Expression(gen, typ(Ast.Array).count);
        typ := typ.type;
        WHILE (typ.id = Ast.IdArray) & ~Strings.IsDefined(typ.name) DO
          Text.Str(gen, ", ");
          Expression(gen, typ(Ast.Array).count);
          typ := typ.type
        END;
        Text.Str(gen, " OF ")
      END;
    RETURN
      typ
    END Array;

    PROCEDURE Record(VAR gen: Generator; rec: Ast.Record);
    BEGIN
      IF (gen.opt.std = StdCp) & rec.hasExt THEN
        Text.Str(gen, "EXTENSIBLE ")
      END;
      IF rec.base = NIL THEN
        Text.StrOpen(gen, "RECORD")
      ELSE
        Text.Str(gen, "RECORD(");
        GlobalName(gen, rec.base);
        Text.StrOpen(gen, ")")
      END;
      IF rec.vars # NIL THEN
        VarList(gen, rec.vars)
      END;
      Text.Ln(gen);
      Text.StrClose(gen, "END")
    END Record;

  BEGIN
    IF ~forDecl & Strings.IsDefined(typ.name) THEN
      GlobalName(gen, typ)
    ELSE
      CASE typ.id OF
        Ast.IdInteger:
        Text.Str(gen, "INTEGER")
      | Ast.IdSet:
        CASE gen.opt.std OF
          StdO7,
          StdCp: Text.Str(gen, "SET")
        | StdAo: Text.Str(gen, "SET32")
        END
      | Ast.IdLongInt:
        Text.Str(gen, "LONGINT")
      | Ast.IdLongSet:
        CASE gen.opt.std OF
          StdAo: Text.Str(gen, "SET64")
        END
      | Ast.IdBoolean:
        Text.Str(gen, "BOOLEAN")
      | Ast.IdByte:
        CASE gen.opt.std OF
          StdO7,
          StdCp: Text.Str(gen, "BYTE")
        | StdAo: Text.Str(gen, "UNSIGNED8")
        END
      | Ast.IdChar:
        CASE gen.opt.std OF
          StdO7,
          StdAo: Text.Str(gen, "CHAR")
        | StdCp: Text.Str(gen, "SHORTCHAR")
        END
      | Ast.IdReal:
        Text.Str(gen, "REAL")
      | Ast.IdReal32:
        Text.Str(gen, "SHORTREAL")
      | Ast.IdRecord:
        Record(gen, typ(Ast.Record))
      | Ast.IdProcType:
        Text.Str(gen, "PROCEDURE ");
        ProcParams(gen, typ(Ast.ProcType))
      | Ast.IdPointer:
        Text.Str(gen, "POINTER TO ");
        Type(gen, typ.type, FALSE)
      | Ast.IdArray:
        Type(gen, Array(gen, typ), FALSE)
      END
    END
  END Type;

  PROCEDURE ReferenceToType(VAR gen: Generator; t: Ast.Type);
  BEGIN
    Type(gen, t, FALSE)
  END ReferenceToType;

  PROCEDURE Types(VAR gen: Generator; d: Ast.Declaration);
    PROCEDURE Decl(VAR gen: Generator; t: Ast.Type);
    BEGIN
      MarkedName(gen, t, " = ");
      Type(gen, t, TRUE);
      Text.StrLn(gen, ";")
    END Decl;
  BEGIN
    Text.StrOpen(gen, "TYPE");
    WHILE (d # NIL) & (d IS Ast.Type) DO
      Decl(gen, d(Ast.Type));
      d := d.next
    END;
    LnClose(gen)
  END Types;

  PROCEDURE Vars(VAR gen: Generator; d: Ast.Declaration);
  BEGIN
    Text.StrOpen(gen, "VAR");
    VarList(gen, d);
    Text.StrLnClose(gen, ";");
  END Vars;

  PROCEDURE ExprThenStats(VAR gen: Generator; VAR wi: Ast.WhileIf; then: ARRAY OF CHAR);
  BEGIN
    Expression(gen, wi.expr);
    Text.StrOpen(gen, then);
    statements(gen, wi.stats);
    wi := wi.elsif
  END ExprThenStats;

  PROCEDURE Statement(VAR gen: Generator; st: Ast.Statement);

    PROCEDURE WhileIf(VAR gen: Generator; wi: Ast.WhileIf);

      PROCEDURE Elsif(VAR gen: Generator; VAR wi: Ast.WhileIf; then: ARRAY OF CHAR);
      BEGIN
        WHILE (wi # NIL) & (wi.expr # NIL) DO
          Text.LnStrClose(gen, "ELSIF ");
          ExprThenStats(gen, wi, then)
        END
      END Elsif;
    BEGIN
      IF wi IS Ast.If THEN
        Text.Str(gen, "IF ");
        ExprThenStats(gen, wi, " THEN");
        Elsif(gen, wi, " THEN");
        IF wi # NIL THEN
          Text.StrLnClose(gen, "");
          Text.StrOpen(gen, "ELSE");
          statements(gen, wi.stats)
        END;
        Text.LnStrClose(gen, "END")
      ELSIF (wi.elsif = NIL) OR gen.opt.multibranchWhile THEN
        Text.Str(gen, "WHILE ");
        ExprThenStats(gen, wi, " DO");
        Elsif(gen, wi, " DO");
        Text.LnStrClose(gen, "END")
      ELSE
        Text.Str(gen, "LOOP IF ");
        ExprThenStats(gen, wi, " THEN");
        Elsif(gen, wi, " THEN");
        Text.LnStrClose(gen, "ELSE EXIT END END")
      END
    END WhileIf;

    PROCEDURE Repeat(VAR gen: Generator; st: Ast.Repeat);
    BEGIN
      Text.StrOpen(gen, "REPEAT");
      statements(gen, st.stats);
      Text.LnStrClose(gen, "UNTIL ");
      Expression(gen, st.expr);
    END Repeat;

    PROCEDURE For(VAR gen: Generator; st: Ast.For);
    BEGIN
      Text.Str(gen, "FOR ");
      GlobalName(gen, st.var);
      ExpressionBraced(gen, " := ", st.expr, " TO ");
      Expression(gen, st.to);
      IF st.by # 1 THEN
        Text.Str(gen, " BY ");
        Text.Int(gen, st.by)
      END;
      Text.StrOpen(gen, " DO");
      statements(gen, st.stats);
      Text.LnStrClose(gen, "END")
    END For;

    PROCEDURE Assign(VAR gen: Generator; st: Ast.Assign);
    VAR toByte: BOOLEAN;

    BEGIN
      IF (gen.opt.std = StdAo)
       & (st.expr.type.id = Ast.IdArray) & (st.expr.type(Ast.Array).count = NIL)
      THEN
        Text.Str(gen, "SYSTEM.MOVE(SYSTEM.ADR(");
        Designator(gen, st.designator);
        ExpressionBraced(gen, "), SYSTEM.ADR(", st.expr, "), SIZEOF(");
        Type(gen, st.expr.type.type, FALSE);
        ExpressionBraced(gen, ") * LEN(", st.expr, "))")
      ELSE
        Designator(gen, st.designator);
        toByte := (gen.opt.std # StdO7)
                & (st.designator.type.id = Ast.IdByte)
                & (st.expr.type.id IN {Ast.IdInteger, Ast.IdLongInt});
        IF toByte THEN
          ExpressionBraced(gen, " := UNSIGNED8(", st.expr, ")")
        ELSE
          Text.Str(gen, " := ");
          Expression(gen, st.expr)
        END
      END
    END Assign;

    PROCEDURE Case(VAR gen: Generator; st: Ast.Case);
    VAR elem: Ast.CaseElement;

      PROCEDURE CaseElement(VAR gen: Generator; elem: Ast.CaseElement; tid: INTEGER);
      VAR r: Ast.CaseLabel;
        PROCEDURE Range(VAR gen: Generator; r: Ast.CaseLabel; tid: INTEGER);
          PROCEDURE Label(VAR gen: Generator; l: Ast.CaseLabel; tid: INTEGER);
          BEGIN
            IF l.qual # NIL THEN
              GlobalName(gen, l.qual)
            ELSIF tid = Ast.IdInteger THEN
              Text.Int(gen, l.value);
            ELSE ASSERT(tid = Ast.IdChar);
              Char(gen, l.value, Ast.StrUsedAsChar)
            END
          END Label;
        BEGIN
          Label(gen, r, tid);
          IF r.right # NIL THEN
            Text.Str(gen, " .. ");
            Label(gen, r.right, tid)
          END
        END Range;
      BEGIN
        r := elem.labels;
        Range(gen, r, tid);
        r := r.next;
        WHILE r # NIL DO
          Text.Str(gen, ", ");
          Range(gen, r, tid);
          r := r.next
        END;
        Text.StrOpen(gen, ":");
        statements(gen, elem.stats);
        Text.StrLnClose(gen, "")
      END CaseElement;
    BEGIN
      ExpressionBraced(gen, "CASE ", st.expr, " OF");
      Text.Ln(gen);
      Text.Str(gen, "  ");
      elem := st.elements;
      CaseElement(gen, elem, st.expr.type.id);
      elem := elem.next;
      WHILE elem # NIL DO
        Text.Str(gen, "| ");
        CaseElement(gen, elem, st.expr.type.id);
        elem := elem.next
      END;
      IF gen.opt.caseAbort & (gen.opt.std # StdO7) THEN
        (* TODO *)
        Text.StrLn(gen, "ELSE HALT(1)")
      END;
      Text.Str(gen, "END");
    END Case;
  BEGIN
    Comment(gen, st.comment);
    IF 0 < st.emptyLines THEN
      Text.Ln(gen)
    END;
    IF st IS Ast.Assign THEN
      Assign(gen, st(Ast.Assign))
    ELSIF st IS Ast.Call THEN
      Expression(gen, st.expr)
    ELSIF st IS Ast.WhileIf THEN
      WhileIf(gen, st(Ast.WhileIf))
    ELSIF st IS Ast.Repeat THEN
      Repeat(gen, st(Ast.Repeat))
    ELSIF st IS Ast.For THEN
      For(gen, st(Ast.For))
    ELSE ASSERT(st IS Ast.Case);
      Case(gen, st(Ast.Case))
    END
  END Statement;

  PROCEDURE Statements(VAR gen: Generator; stat: Ast.Statement);
  BEGIN
    IF stat # NIL THEN
      Statement(gen, stat);
      stat := stat.next;
      WHILE stat # NIL DO
        Text.StrLn(gen, ";");
        Statement(gen, stat);
        stat := stat.next
      END
    END
  END Statements;

  PROCEDURE Procedure(VAR gen: Generator; p: Ast.Procedure);
    PROCEDURE Return(VAR gen: Generator; stats: BOOLEAN; ret: Ast.Expression);
    BEGIN
      IF ret # NIL THEN
        IF stats THEN
          Text.StrLn(gen, ";")
        END;
        Text.Str(gen, "RETURN ");
        Expression(gen, ret)
      END
    END Return;
  BEGIN
    Text.Str(gen, "PROCEDURE ");
    MarkedName(gen, p, "");
    ProcParams(gen, p.header);
    Text.StrLn(gen, ";");
    declarations(gen, p);
    Text.StrOpen(gen, "BEGIN");
    Statements(gen, p.stats);
    Return(gen, p.stats # NIL, p.return);
    Text.Ln(gen);
    Text.StrClose(gen, "END ");
    Name(gen, p);
    Text.StrLn(gen, ";")
  END Procedure;

  PROCEDURE Declarations(VAR gen: Generator; ds: Ast.Declarations);
  VAR d: Ast.Declaration;
  BEGIN
    IF ds.consts # NIL THEN
      Consts(gen, ds.consts)
    END;

    IF ds.types # NIL THEN
      Types(gen, ds.types)
    END;

    IF ds.vars # NIL THEN
      Vars(gen, ds.vars)
    END;

    IF (ds.vars # NIL) & (ds.procedures # NIL) THEN
      Text.Ln(gen)
    END;

    Text.IndentOpen(gen);
    d := ds.procedures;
    WHILE d # NIL DO
      Procedure(gen, d(Ast.Procedure));
      Text.Ln(gen);
      d := d.next
    END;
    Text.IndentClose(gen)
  END Declarations;

  PROCEDURE Generate*(out: Stream.POut; module: Ast.Module; opt: Options);
  VAR gen: Generator;
  BEGIN
    Init(gen, out, module, opt);

    Text.Str(gen, "MODULE ");
    Name(gen, module);
    Text.StrLn(gen, ";");

    IF module.import # NIL THEN
      Imports(gen, module.import)
    ELSIF gen.opt.std = StdAo THEN
      Text.StrLn(gen, "IMPORT O_7;")
    END;
    Declarations(gen, module);
    IF module.stats # NIL THEN
      Text.StrOpen(gen, "BEGIN");
      Statements(gen, module.stats);
      Text.StrLnClose(gen, "")
    END;

    Text.Str(gen, "END ");
    Name(gen, module);
    Text.StrLn(gen, ".")
  END Generate;

BEGIN
  declarations := Declarations;
  statements   := Statements;
  expression   := Expression;
  type         := ReferenceToType
END GeneratorOberon.

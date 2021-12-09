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
  Log := DLog, Stream := VDataStream,
  Text := TextGenerator, Strings := StringStore, Utf8Transform, Utf8,
  SpecIdent := OberonSpecIdent, Hex,
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
  declarations: PROCEDURE(VAR g: Generator; ds: Ast.Declarations);
  statements  : PROCEDURE(VAR g: Generator; stats: Ast.Statement);
  expression  : PROCEDURE(VAR g: Generator; expr: Ast.Expression);
  type        : PROCEDURE(VAR g: Generator; typ: Ast.Type);

  PROCEDURE Ident(VAR g: Generator; ident: Strings.String);
  BEGIN
    IF SpecIdent.IsSpecName(ident) THEN
      (* TODO *)
      Text.Str(g, "dnt")
    END;
    GenCommon.Ident(g, ident, g.opt.identEnc)
  END Ident;

  PROCEDURE Name(VAR g: Generator; decl: Ast.Declaration);
  BEGIN
    Ident(g, decl.name)
  END Name;

  PROCEDURE GlobalName(VAR g: Generator; decl: Ast.Declaration);
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
    IF (decl.module # NIL) & (g.module # decl.module.m) THEN
      imp := Imported(g.module.import, decl.module.m);
      Ident(g, imp.name);
      Text.Char(g, ".")
    END;
    Name(g, decl)
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

  PROCEDURE Init(VAR g: Generator; out: Stream.POut; m: Ast.Module; opt: Options);
  BEGIN
    ASSERT(m # NIL);

    IF opt.std IN {StdCp, StdAo} THEN
      opt.caseAbort := FALSE
    END;
    Text.Init(g, out);

    g.module := m;
    g.opt    := opt
  END Init;

  PROCEDURE LnClose(VAR g: Generator);
  BEGIN
    Text.IndentClose(g);
    Text.Ln(g)
  END LnClose;

  PROCEDURE Comment(VAR g: Generator; text: Strings.String);
  BEGIN
    GenCommon.CommentOberon(g, g.opt^, text)
  END Comment;

  PROCEDURE EmptyLines(VAR g: Generator; n: Ast.PNode);
  BEGIN
    IF 0 < n.emptyLines THEN
      Text.Ln(g)
    END
  END EmptyLines;

  PROCEDURE Imports(VAR g: Generator; d: Ast.Declaration);
    PROCEDURE Import(VAR g: Generator; decl: Ast.Declaration);
    VAR name: Strings.String;
    BEGIN
      Name(g, decl);
      name := decl.module.m.name;
      IF Strings.Compare(decl.name, name) # 0 THEN
        Text.Str(g, " := ");
        Ident(g, name)
      END
    END Import;
  BEGIN
    CASE g.opt.std OF
      StdO7: Text.StrOpen(g, "IMPORT")
    | StdAo,
      StdCp: Text.StrOpen(g, "IMPORT O_7, SYSTEM,")
    END;

    Import(g, d);
    d := d.next;
    WHILE (d # NIL) & (d IS Ast.Import) DO
      Text.StrLn(g, ",");
      Import(g, d);
      d := d.next
    END;
    Text.StrLn(g, ";");

    LnClose(g)
  END Imports;

  PROCEDURE ExpressionBraced(VAR g: Generator;
                             l: ARRAY OF CHAR; e: Ast.Expression; r: ARRAY OF CHAR);
  BEGIN
    Text.Str(g, l);
    expression(g, e);
    Text.Str(g, r)
  END ExpressionBraced;

  PROCEDURE ExpressionInfix(VAR g: Generator;
                            e1: Ast.Expression; oper: ARRAY OF CHAR; e2: Ast.Expression);
  BEGIN
    expression(g, e1);
    Text.Str(g, oper);
    expression(g, e2)
  END ExpressionInfix;

  PROCEDURE Designator(VAR g: Generator; des: Ast.Designator);
  VAR sel: Ast.Selector;

    PROCEDURE Selector(VAR g: Generator; VAR sel: Ast.Selector);

      PROCEDURE Record(VAR g: Generator; sel: Ast.Selector);
      BEGIN
        Text.Str(g, ".");
        Name(g, sel(Ast.SelRecord).var);
      END Record;

      PROCEDURE Array(VAR g: Generator; VAR sel: Ast.Selector);
      BEGIN
        Text.Str(g, "[");
        expression(g, sel(Ast.SelArray).index);
        sel := sel.next;
        WHILE (sel # NIL) & (sel IS Ast.SelArray) DO
          Text.Char(g, ",");
          expression(g, sel(Ast.SelArray).index);
          sel := sel.next;
        END;
        Text.Str(g, "]")
      END Array;

      PROCEDURE TypeGuard(VAR g: Generator; sel: Ast.SelGuard);
      BEGIN
        Text.Char(g, "(");
        GlobalName(g, sel.type);
        Text.Char(g, ")");
      END TypeGuard;
    BEGIN
      IF sel IS Ast.SelArray THEN
        Array(g, sel)
      ELSE
        IF sel IS Ast.SelRecord THEN
          Record(g, sel)
        ELSIF sel IS Ast.SelPointer THEN
          Text.Char(g, "^")
        ELSE
          TypeGuard(g, sel(Ast.SelGuard))
        END;
        sel := sel.next
      END
    END Selector;
  BEGIN
    GlobalName(g, des.decl);
    sel := des.sel;
    WHILE sel # NIL DO
      Selector(g, sel)
    END
  END Designator;

  PROCEDURE Char(VAR g: Generator; code: INTEGER; usedAs: INTEGER);
  VAR s: ARRAY 4 OF CHAR;
  BEGIN
    ASSERT((0 <= code) & (code < 100H));
    IF (code < 20H) OR (code >= 7FH)
    OR (code = ORD(Utf8.DQuote)) & (g.opt.std = StdO7)
    THEN
      s[0] := "0";
      s[1] := Hex.To(code DIV 10H);
      s[2] := Hex.To(code MOD 10H);
      IF (g.opt.std = StdO7) OR (usedAs # Ast.StrUsedAsArray) THEN
        s[3] := "X";
        Text.Data(g, s, 0, 4)
      ELSE
        s[3] := "H";
        Text.Str(g, "O_7.ch[");
        Text.Data(g, s, 0, 4);
        Text.Char(g, "]")
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
      Text.Data(g, s, 0, 3)
    END
  END Char;

  PROCEDURE AssignExpr(VAR g: Generator; desType: Ast.Type; expr: Ast.Expression);
  VAR toByte: BOOLEAN;
  BEGIN
    toByte := (g.opt.std # StdO7)
            & (desType.id = Ast.IdByte)
            & (expr.type.id IN {Ast.IdInteger, Ast.IdLongInt});
    IF toByte THEN
      CASE g.opt.std OF
        StdAo: ExpressionBraced(g, "UNSIGNED8(", expr, ")")
      | StdCp: ExpressionBraced(g, "O_7.Byte(", expr, ")")
      END
    ELSE
      expression(g, expr)
    END
  END AssignExpr;

  PROCEDURE Expression(VAR g: Generator; expr: Ast.Expression);

    PROCEDURE Call(VAR g: Generator; call: Ast.ExprCall);
    VAR p: Ast.Parameter; fp: Ast.Declaration;

      PROCEDURE Predefined(VAR g: Generator; call: Ast.ExprCall);
      VAR e1: Ast.Expression; p2: Ast.Parameter;

        PROCEDURE Ord(VAR g: Generator; e: Ast.Expression);
        BEGIN
          IF (g.opt.std = StdO7) OR ~(e.type.id IN {Ast.IdSet, Ast.IdBoolean}) THEN
            (* TODO *)
            ExpressionBraced(g, "ORD(", e, ")")
          ELSIF e.type.id = Ast.IdSet THEN
            IF e.value = NIL THEN
              ExpressionBraced(g, "O_7.Ord(", e, ")")
            ELSE
              Text.Int(g, LongSet.Ord(e.value(Ast.ExprSetValue).set))
            END
          ELSE ASSERT(e.type.id = Ast.IdBoolean);
            IF e.value = NIL THEN
              ExpressionBraced(g, "O_7.Bti(", e, ")")
            ELSE
              Text.Int(g, ORD(e.value(Ast.ExprBoolean).bool))
            END
          END
        END Ord;

        PROCEDURE Assert(VAR g: Generator; e: Ast.Expression);
        BEGIN
          IF (g.opt.std = StdO7)
          OR (e.value = NIL) OR e.value(Ast.ExprBoolean).bool
          THEN
            ExpressionBraced(g, "ASSERT(", e, ")")
          ELSE
            Text.Str(g, "HALT(1)")
          END
        END Assert;

        PROCEDURE Pack(VAR g: Generator; e1, e2: Ast.Expression);
        BEGIN
          CASE g.opt.std OF
            StdO7: Text.Str(g, "PACK(")
          | StdAo,
            StdCp: Text.Str(g, "O_7.Pack(")
          END;
          Expression(g, e1);
          ExpressionBraced(g, ", ", e2, ")")
        END Pack;

        PROCEDURE Unpack(VAR g: Generator; e1, e2: Ast.Expression);
        BEGIN
          CASE g.opt.std OF
            StdO7: Text.Str(g, "UNPK(")
          | StdAo,
            StdCp: Text.Str(g, "O_7.Unpk(")
          END;
          Expression(g, e1);
          ExpressionBraced(g, ", ", e2, ")")
        END Unpack;

        PROCEDURE One(VAR g: Generator; name: ARRAY OF CHAR; e: Ast.Expression);
        BEGIN
          Text.Str(g, name);
          ExpressionBraced(g, "(", e, ")");
        END One;

        PROCEDURE Two(VAR g: Generator; name: ARRAY OF CHAR; e1, e2: Ast.Expression);
        BEGIN
          Text.Str(g, name);
          ExpressionBraced(g, "(", e1, ", ");
          Expression(g, e2);
          Text.Char(g, ")")
        END Two;

        PROCEDURE MayTwo(VAR g: Generator; name: ARRAY OF CHAR;
                         e1: Ast.Expression; p2: Ast.Parameter);
        BEGIN
          Text.Str(g, name);
          IF p2 = NIL THEN
            ExpressionBraced(g, "(", e1, ")");
          ELSE
            ExpressionBraced(g, "(", e1, ", ");
            Expression(g, p2.expr);
            Text.Char(g, ")")
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
          | StdAo: ExpressionBraced(g, "REAL(", int, ")")
          | StdCp: ExpressionBraced(g, "(0.0 + ", int, ")")
          END
        END Flt;

        PROCEDURE Chr(VAR g: Generator; int: Ast.Expression);
        BEGIN
          CASE g.opt.std OF
            StdO7,
            StdAo: ExpressionBraced(g, "CHR(", int, ")")
          | StdCp: ExpressionBraced(g, "SHORT(CHR(", int, "))")
          END
        END Chr;

        PROCEDURE Floor(VAR g: Generator; r: Ast.Expression);
        BEGIN
          CASE g.opt.std OF
            StdO7,
            StdAo: ExpressionBraced(g, "FLOOR(", r, ")")
          | StdCp: ExpressionBraced(g, "SHORT(ENTIER(", r, "))")
          END
        END Floor;

        PROCEDURE Ror(VAR g: Generator; v, n: Ast.Expression);
        BEGIN
          CASE g.opt.std OF
            StdO7,
            StdAo: Text.Str(g, "ROR(")
          | StdCp: Text.Str(g, "O_7.Ror(")
          END;
          Expression(g, v);
          ExpressionBraced(g, ", ", n, ")")
        END Ror;

      BEGIN
        e1 := call.params.expr;
        p2 := call.params.next;
        CASE call.designator.decl.id OF
          SpecIdent.Abs  : One(g, "ABS", e1)
        | SpecIdent.Odd  : One(g, "ODD", e1)
        | SpecIdent.Len  : Len(g, e1)
        | SpecIdent.Lsl  : Lsl(g, e1, p2.expr)
        | SpecIdent.Asr  : Asr(g, e1, p2.expr)
        | SpecIdent.Ror  : Ror(g, e1, p2.expr)
        | SpecIdent.Floor: Floor(g, e1)
        | SpecIdent.Flt  : Flt(g, e1)
        | SpecIdent.Ord  : Ord(g, e1)
        | SpecIdent.Chr  : Chr(g, e1)
        | SpecIdent.Inc  : MayTwo(g, "INC", e1, p2)
        | SpecIdent.Dec  : MayTwo(g, "DEC", e1, p2)
        | SpecIdent.Incl : Two(g, "INCL", e1, p2.expr)
        | SpecIdent.Excl : Two(g, "EXCL", e1, p2.expr)
        | SpecIdent.New  : One(g, "NEW", e1)
        | SpecIdent.Assert: Assert(g, e1)
        | SpecIdent.Pack : Pack(g, e1, p2.expr)
        | SpecIdent.Unpk : Unpack(g, e1, p2.expr)
        END
      END Predefined;

      PROCEDURE ActualParam(VAR g: Generator; VAR p: Ast.Parameter;
                            VAR fp: Ast.Declaration);
      BEGIN
        AssignExpr(g, fp.type, p.expr);
        p  := p.next;
        fp := fp.next
      END ActualParam;
    BEGIN
      IF call.designator.decl IS Ast.PredefinedProcedure THEN
        Predefined(g, call)
      ELSE
        Designator(g, call.designator);
        Text.Char(g, "(");
        p  := call.params;
        fp := call.designator.type(Ast.ProcType).params;
        IF p # NIL THEN
          ActualParam(g, p, fp);
          WHILE p # NIL DO
            Text.Str(g, ", ");
            ActualParam(g, p, fp)
          END
        END;
        Text.Char(g, ")")
      END
    END Call;

    PROCEDURE Relation(VAR g: Generator; rel: Ast.ExprRelation);

      PROCEDURE Infix(VAR g: Generator; rel: Ast.ExprRelation; oper: ARRAY OF CHAR);
      BEGIN
        ExpressionInfix(g, rel.exprs[0], oper, rel.exprs[1])
      END Infix;
    BEGIN
      CASE rel.relation OF
        Ast.Equal        : Infix(g, rel, " = " )
      | Ast.Inequal      : Infix(g, rel, " # " )
      | Ast.Less         : Infix(g, rel, " < " )
      | Ast.LessEqual    : Infix(g, rel, " <= ")
      | Ast.Greater      : Infix(g, rel, " > " )
      | Ast.GreaterEqual : Infix(g, rel, " >= ")
      | Ast.In           : Infix(g, rel, " IN ")
      END
    END Relation;

    PROCEDURE Sum(VAR g: Generator; sum: Ast.ExprSum);
    BEGIN
      IF sum.add = Ast.Minus THEN
        Text.Str(g, " -")
      ELSIF sum.add = Ast.Plus THEN
        Text.Str(g, " +")
      END;
      Expression(g, sum.term);
      sum := sum.next;
      WHILE sum # NIL DO
        IF sum.add = Ast.Minus THEN
          Text.Str(g, " - ")
        ELSIF sum.add = Ast.Plus THEN
          Text.Str(g, " + ")
        ELSIF sum.add = Ast.Or THEN
          Text.Str(g, " OR ")
        END;
        Expression(g, sum.term);
        sum := sum.next
      END
    END Sum;

    PROCEDURE Term(VAR g: Generator; term: Ast.ExprTerm);
    BEGIN
      REPEAT
        Expression(g, term.factor);
        CASE term.mult OF
          Ast.Mult : Text.Str(g, " * "  )
        | Ast.Rdiv : Text.Str(g, " / "  )
        | Ast.Div  : Text.Str(g, " DIV ")
        | Ast.Mod  : Text.Str(g, " MOD ")
        | Ast.And  : Text.Str(g, " & "  )
        END;
        IF term.expr IS Ast.ExprTerm THEN
          term := term.expr(Ast.ExprTerm);
        ELSE
          Expression(g, term.expr);
          term := NIL
        END
      UNTIL term = NIL
    END Term;

    PROCEDURE Boolean(VAR g: Generator; e: Ast.ExprBoolean);
    BEGIN
      IF   e.bool
      THEN Text.Str(g, "TRUE")
      ELSE Text.Str(g, "FALSE")
      END
    END Boolean;

    PROCEDURE String(VAR g: Generator; e: Ast.ExprString);
    VAR w: Strings.String;
    BEGIN
      w := e.string;
      IF Strings.IsDefined(w) & (w.block.s[w.ofs] = Utf8.DQuote) THEN
        IF (g.opt.std # StdCp) OR Strings.IsUtfLess(w, 100H) THEN
          Text.String(g, w)
        ELSE
          (* TODO трансформация в UTF-8 *)
          Text.Str(g, "SHORT(");
          Text.String(g, w);
          Text.Char(g, ")")
        END
      ELSE
        Char(g, e.int, e.usedAs)
      END
    END String;

    PROCEDURE ExprInt(VAR g: Generator; int: INTEGER);
    BEGIN
      IF int >= 0 THEN
        Text.Int(g, int)
      ELSE
        Text.Str(g, "(-");
        Text.Int(g, -int);
        Text.Char(g, ")")
      END
    END ExprInt;

    PROCEDURE ExprLongInt(VAR g: Generator; int: INTEGER);
    BEGIN
      ASSERT(FALSE);
    END ExprLongInt;

    PROCEDURE SetValue(VAR g: Generator; set: Ast.ExprSetValue);
    BEGIN
      ASSERT(FALSE);
      Text.Int(g, ORD(set.set[0]));
    END SetValue;

    PROCEDURE Set(VAR g: Generator; set: Ast.ExprSet);
      PROCEDURE Val(VAR g: Generator; set: Ast.ExprSet);
        PROCEDURE Item(VAR g: Generator; set: Ast.ExprSet);
        BEGIN
          IF set.exprs[1] = NIL THEN
            Expression(g, set.exprs[0])
          ELSE
            ExpressionInfix(g, set.exprs[0], " .. ", set.exprs[1]);
          END
        END Item;
      BEGIN
        IF (set.next = NIL) & (set.exprs[0] = NIL) THEN
          Text.Str(g, "{}")
        ELSE
          Text.Char(g, "{");
          Item(g, set);
          set := set.next;
          WHILE set # NIL DO
            Text.Str(g, ", ");
            Item(g, set);
            set := set.next
          END;
          Text.Char(g, "}")
        END
      END Val;
    BEGIN
      CASE g.opt.std OF
        StdO7,
        StdCp: Val(g, set)
      | StdAo: Text.Str(g, "SET32("); Val(g, set); Text.Str(g, ")")
      END
    END Set;

    PROCEDURE IsExtension(VAR g: Generator; is: Ast.ExprIsExtension);
    BEGIN
      Designator(g, is.designator);
      Text.Str(g, " IS ");
      GlobalName(g, is.extType)
    END IsExtension;
  BEGIN
    CASE expr.id OF
      Ast.IdInteger:
      ExprInt(g, expr(Ast.ExprInteger).int)
    | Ast.IdLongInt:
      ExprLongInt(g, expr(Ast.ExprInteger).int)
    | Ast.IdBoolean:
      Boolean(g, expr(Ast.ExprBoolean))
    | Ast.IdReal, Ast.IdReal32:
      IF Strings.IsDefined(expr(Ast.ExprReal).str)
      THEN  Text.String(g, expr(Ast.ExprReal).str)
      ELSE  Text.Real(g, expr(Ast.ExprReal).real)
      END
    | Ast.IdString:
      String(g, expr(Ast.ExprString))
    | Ast.IdSet, Ast.IdLongSet:
      IF expr IS Ast.ExprSet
      THEN Set(g, expr(Ast.ExprSet))
      ELSE SetValue(g, expr(Ast.ExprSetValue))
      END
    | Ast.IdCall:
      Call(g, expr(Ast.ExprCall))
    | Ast.IdDesignator:
      IF (g.opt.std = StdO7)
      OR (expr.value = NIL) OR (expr.value.id # Ast.IdString)
      THEN  Designator(g, expr(Ast.Designator))
      ELSE  String(g, expr.value(Ast.ExprString))
      END
    | Ast.IdRelation:
      Relation(g, expr(Ast.ExprRelation))
    | Ast.IdSum:
      Sum(g, expr(Ast.ExprSum))
    | Ast.IdTerm: Term(g, expr(Ast.ExprTerm))
    | Ast.IdNegate:
      Text.Str(g, "~");
      Expression(g, expr(Ast.ExprNegate).expr)
    | Ast.IdBraces:
      ExpressionBraced(g, "(", expr(Ast.ExprBraces).expr, ")")
    | Ast.IdPointer:
      Text.Str(g, "NIL")
    | Ast.IdIsExtension:
      IsExtension(g, expr(Ast.ExprIsExtension))
    END
  END Expression;

  PROCEDURE Mark(VAR g: Generator; d: Ast.Declaration);
  BEGIN
    IF d.mark THEN
      Text.Char(g, "*")
    END
  END Mark;

  PROCEDURE MarkedName(VAR g: Generator; d: Ast.Declaration; str: ARRAY OF CHAR);
  BEGIN
    Name(g, d);
    Mark(g, d);
    Text.Str(g, str)
  END MarkedName;

  PROCEDURE Consts(VAR g: Generator; d: Ast.Declaration);
    PROCEDURE Const(VAR g: Generator; c: Ast.Const);
    BEGIN
      Comment(g, c.comment);
      EmptyLines(g, c);

      MarkedName(g, c, " = ");
      Expression(g, c.expr);
      Text.StrLn(g, ";")
    END Const;
  BEGIN
    Text.StrOpen(g, "CONST");
    WHILE (d # NIL) & (d IS Ast.Const) DO
      Const(g, d(Ast.Const));
      d := d.next
    END;
    LnClose(g)
  END Consts;

  PROCEDURE ProcParams(VAR g: Generator; proc: Ast.ProcType);
  VAR p: Ast.Declaration;

    PROCEDURE SimilarParams(VAR g: Generator; VAR p: Ast.Declaration);
    VAR fp: Ast.FormalParam;

      PROCEDURE Access(VAR g: Generator; fp: Ast.FormalParam);
      BEGIN
        IF Ast.ParamOut IN fp.access THEN
          Text.Str(g, "VAR ")
        ELSIF fp.type.id IN Ast.Structures THEN
          CASE g.opt.std OF
            StdO7: ;
          | StdAo: Text.Str(g, "CONST ")
          | StdCp: Text.Str(g, "IN ")
          END
        END
      END Access;

      PROCEDURE Similar(p1, p2: Ast.FormalParam): BOOLEAN;
      RETURN
        (p1.access = p2.access) & (p1.type = p2.type)
      END Similar;

    BEGIN
      fp := p(Ast.FormalParam);
      Access(g, fp);
      Name(g, p);
      p := p.next;
      WHILE (p # NIL) & Similar(fp, p(Ast.FormalParam)) DO
        Text.Str(g, ", ");
        Name(g, p);
        p := p.next
      END;
      Text.Str(g, ": ");
      type(g, fp.type)
    END SimilarParams;
  BEGIN
    IF proc.params # NIL THEN
      Text.Char(g, "(");
      p := proc.params;
      SimilarParams(g, p);
      WHILE p # NIL DO
        Text.Str(g, "; ");
        SimilarParams(g, p)
      END;
      IF proc.type = NIL THEN
        Text.Char(g, ")")
      ELSE
        Text.Str(g, "): ");
        type(g, proc.type)
      END
    ELSIF proc.type # NIL THEN
      Text.Str(g, "(): ");
      type(g, proc.type)
    END
  END ProcParams;

  PROCEDURE VarList(VAR g: Generator; v: Ast.Declaration);

    PROCEDURE ListSameType(VAR g: Generator; VAR v: Ast.Declaration);
    VAR p: Ast.Declaration;
    BEGIN
      MarkedName(g, v, "");
      p := v;
      v := v.next;
      WHILE (v # NIL) & (p.type = v.type) & (v IS Ast.Var) DO
        Text.Str(g, ", ");
        MarkedName(g, v, "");
        p := v;
        v := v.next
      END;
      Text.Str(g, ": ");
      type(g, p.type)
    END ListSameType;

  BEGIN
    ListSameType(g, v);
    WHILE (v # NIL) & (v IS Ast.Var) DO
      Text.StrLn(g, ";");
      ListSameType(g, v)
    END
  END VarList;

  PROCEDURE Type(VAR g: Generator; typ: Ast.Type; forDecl: BOOLEAN);

    PROCEDURE Array(VAR g: Generator; typ: Ast.Type): Ast.Type;
    BEGIN
      IF typ(Ast.Array).count = NIL THEN
        REPEAT
          ASSERT(typ(Ast.Array).count = NIL);
          Text.Str(g, "ARRAY OF ");
          typ := typ.type
        UNTIL typ.id # Ast.IdArray
      ELSE
        Text.Str(g, "ARRAY ");
        Expression(g, typ(Ast.Array).count);
        typ := typ.type;
        WHILE (typ.id = Ast.IdArray) & ~Strings.IsDefined(typ.name) DO
          Text.Str(g, ", ");
          Expression(g, typ(Ast.Array).count);
          typ := typ.type
        END;
        Text.Str(g, " OF ")
      END;
    RETURN
      typ
    END Array;

    PROCEDURE Record(VAR g: Generator; rec: Ast.Record);
    BEGIN
      IF (g.opt.std = StdCp) & rec.hasExt THEN
        Text.Str(g, "EXTENSIBLE ")
      END;
      IF rec.base = NIL THEN
        Text.StrOpen(g, "RECORD")
      ELSE
        Text.Str(g, "RECORD(");
        GlobalName(g, rec.base);
        Text.StrOpen(g, ")")
      END;
      IF rec.vars # NIL THEN
        VarList(g, rec.vars)
      END;
      Text.LnStrClose(g, "END")
    END Record;

  BEGIN
    IF ~forDecl & Strings.IsDefined(typ.name) THEN
      GlobalName(g, typ)
    ELSE
      CASE typ.id OF
        Ast.IdInteger:
        CASE g.opt.std OF
          StdO7,
          StdCp: Text.Str(g, "INTEGER")
        | StdAo: Text.Str(g, "SIGNED32")
        END
      | Ast.IdSet:
        CASE g.opt.std OF
          StdO7,
          StdCp: Text.Str(g, "SET")
        | StdAo: Text.Str(g, "SET32")
        END
      | Ast.IdLongInt:
        CASE g.opt.std OF
          StdCp: Text.Str(g, "LONGINT")
        | StdAo: Text.Str(g, "SIGNED64")
        END
      | Ast.IdLongSet:
        CASE g.opt.std OF
          StdAo: Text.Str(g, "SET64")
        END
      | Ast.IdBoolean:
        Text.Str(g, "BOOLEAN")
      | Ast.IdByte:
        CASE g.opt.std OF
          StdO7,
          StdCp: Text.Str(g, "BYTE")
        | StdAo: Text.Str(g, "UNSIGNED8")
        END
      | Ast.IdChar:
        CASE g.opt.std OF
          StdO7,
          StdAo: Text.Str(g, "CHAR")
        | StdCp: Text.Str(g, "SHORTCHAR")
        END
      | Ast.IdReal:
        CASE g.opt.std OF
          StdO7,
          StdCp: Text.Str(g, "REAL")
        | StdAo: Text.Str(g, "FLOAT64")
        END
      | Ast.IdReal32:
        CASE g.opt.std OF
          StdCp: Text.Str(g, "SHORTREAL")
        | StdAo: Text.Str(g, "FLOAT32")
        END
      | Ast.IdRecord:
        Record(g, typ(Ast.Record))
      | Ast.IdProcType, Ast.IdFuncType:
        Text.Str(g, "PROCEDURE ");
        ProcParams(g, typ(Ast.ProcType))
      | Ast.IdPointer:
        Text.Str(g, "POINTER TO ");
        Type(g, typ.type, FALSE)
      | Ast.IdArray:
        Type(g, Array(g, typ), FALSE)
      END
    END
  END Type;

  PROCEDURE ReferenceToType(VAR g: Generator; t: Ast.Type);
  BEGIN
    Type(g, t, FALSE)
  END ReferenceToType;

  PROCEDURE Types(VAR g: Generator; d: Ast.Declaration);
    PROCEDURE Decl(VAR g: Generator; t: Ast.Type);
    BEGIN
      MarkedName(g, t, " = ");
      Type(g, t, TRUE);
      Text.StrLn(g, ";")
    END Decl;
  BEGIN
    Text.StrOpen(g, "TYPE");
    WHILE (d # NIL) & (d IS Ast.Type) DO
      Decl(g, d(Ast.Type));
      d := d.next
    END;
    LnClose(g)
  END Types;

  PROCEDURE Vars(VAR g: Generator; d: Ast.Declaration);
  BEGIN
    Text.StrOpen(g, "VAR");
    VarList(g, d);
    Text.StrLnClose(g, ";");
  END Vars;

  PROCEDURE ExprThenStats(VAR g: Generator; VAR wi: Ast.WhileIf; then: ARRAY OF CHAR);
  BEGIN
    Expression(g, wi.expr);
    Text.StrOpen(g, then);
    statements(g, wi.stats);
    wi := wi.elsif
  END ExprThenStats;

  PROCEDURE Statement(VAR g: Generator; st: Ast.Statement);

    PROCEDURE WhileIf(VAR g: Generator; wi: Ast.WhileIf);

      PROCEDURE Elsif(VAR g: Generator; VAR wi: Ast.WhileIf; then: ARRAY OF CHAR);
      BEGIN
        WHILE (wi # NIL) & (wi.expr # NIL) DO
          Text.LnStrClose(g, "ELSIF ");
          ExprThenStats(g, wi, then)
        END
      END Elsif;
    BEGIN
      IF wi IS Ast.If THEN
        Text.Str(g, "IF ");
        ExprThenStats(g, wi, " THEN");
        Elsif(g, wi, " THEN");
        IF wi # NIL THEN
          Text.StrLnClose(g, "");
          Text.StrOpen(g, "ELSE");
          statements(g, wi.stats)
        END;
        Text.LnStrClose(g, "END")
      ELSIF (wi.elsif = NIL) OR g.opt.multibranchWhile THEN
        Text.Str(g, "WHILE ");
        ExprThenStats(g, wi, " DO");
        Elsif(g, wi, " DO");
        Text.LnStrClose(g, "END")
      ELSE
        Text.Str(g, "LOOP IF ");
        ExprThenStats(g, wi, " THEN");
        Elsif(g, wi, " THEN");
        Text.LnStrClose(g, "ELSE EXIT END END")
      END
    END WhileIf;

    PROCEDURE Repeat(VAR g: Generator; st: Ast.Repeat);
    BEGIN
      Text.StrOpen(g, "REPEAT");
      statements(g, st.stats);
      Text.LnStrClose(g, "UNTIL ");
      Expression(g, st.expr);
    END Repeat;

    PROCEDURE For(VAR g: Generator; st: Ast.For);
    BEGIN
      Text.Str(g, "FOR ");
      GlobalName(g, st.var);
      ExpressionBraced(g, " := ", st.expr, " TO ");
      Expression(g, st.to);
      IF st.by # 1 THEN
        Text.Str(g, " BY ");
        Text.Int(g, st.by)
      END;
      Text.StrOpen(g, " DO");
      statements(g, st.stats);
      Text.LnStrClose(g, "END")
    END For;

    PROCEDURE Assign(VAR g: Generator; st: Ast.Assign);
    BEGIN
      IF (g.opt.std IN {StdAo, StdCp})
       & (st.expr.type.id = Ast.IdArray) & (st.expr.type(Ast.Array).count = NIL)
      THEN
        ExpressionBraced(g, "ASSERT(LEN(", st.expr, ") <= LEN(");
        Designator(g, st.designator);
        Text.StrLn(g, "));");

        ExpressionBraced(g, "SYSTEM.MOVE(SYSTEM.ADR(", st.expr, "), SYSTEM.ADR(");
        Designator(g, st.designator);
        CASE g.opt.std OF
          StdAo: Text.Str(g, "), SIZEOF(")
        | StdCp: Text.Str(g, "), SIZE(")
        END;
        Type(g, st.expr.type.type, FALSE);
        Text.Str(g, "))")
      ELSE
        Designator(g, st.designator);
        Text.Str(g, " := ");
        AssignExpr(g, st.designator.type, st.expr)
      END
    END Assign;

    PROCEDURE Case(VAR g: Generator; st: Ast.Case);
    VAR elem: Ast.CaseElement;

      PROCEDURE CaseElement(VAR g: Generator; elem: Ast.CaseElement; tid: INTEGER);
      VAR r: Ast.CaseLabel;
        PROCEDURE Range(VAR g: Generator; r: Ast.CaseLabel; tid: INTEGER);
          PROCEDURE Label(VAR g: Generator; l: Ast.CaseLabel; tid: INTEGER);
          BEGIN
            IF l.qual # NIL THEN
              GlobalName(g, l.qual)
            ELSIF tid = Ast.IdInteger THEN
              Text.Int(g, l.value);
            ELSE ASSERT(tid = Ast.IdChar);
              Char(g, l.value, Ast.StrUsedAsChar)
            END
          END Label;
        BEGIN
          Label(g, r, tid);
          IF r.right # NIL THEN
            Text.Str(g, " .. ");
            Label(g, r.right, tid)
          END
        END Range;
      BEGIN
        r := elem.labels;
        Range(g, r, tid);
        r := r.next;
        WHILE r # NIL DO
          Text.Str(g, ", ");
          Range(g, r, tid);
          r := r.next
        END;
        Text.StrOpen(g, ":");
        statements(g, elem.stats);
        Text.StrLnClose(g, "")
      END CaseElement;
    BEGIN
      ExpressionBraced(g, "CASE ", st.expr, " OF");
      Text.Ln(g);
      Text.Str(g, "  ");
      elem := st.elements;
      CaseElement(g, elem, st.expr.type.id);
      elem := elem.next;
      WHILE elem # NIL DO
        Text.Str(g, "| ");
        CaseElement(g, elem, st.expr.type.id);
        elem := elem.next
      END;
      IF g.opt.caseAbort & (g.opt.std # StdO7) THEN
        (* TODO *)
        Text.StrLn(g, "ELSE HALT(1)")
      END;
      Text.Str(g, "END");
    END Case;
  BEGIN
    Comment(g, st.comment);
    IF 0 < st.emptyLines THEN
      Text.Ln(g)
    END;
    IF st IS Ast.Assign THEN
      Assign(g, st(Ast.Assign))
    ELSIF st IS Ast.Call THEN
      Expression(g, st.expr)
    ELSIF st IS Ast.WhileIf THEN
      WhileIf(g, st(Ast.WhileIf))
    ELSIF st IS Ast.Repeat THEN
      Repeat(g, st(Ast.Repeat))
    ELSIF st IS Ast.For THEN
      For(g, st(Ast.For))
    ELSE ASSERT(st IS Ast.Case);
      Case(g, st(Ast.Case))
    END
  END Statement;

  PROCEDURE Statements(VAR g: Generator; stat: Ast.Statement);
  BEGIN
    IF stat # NIL THEN
      Statement(g, stat);
      stat := stat.next;
      WHILE stat # NIL DO
        Text.StrLn(g, ";");
        Statement(g, stat);
        stat := stat.next
      END
    END
  END Statements;

  PROCEDURE Procedure(VAR g: Generator; p: Ast.Procedure);
    PROCEDURE Return(VAR g: Generator; stats: BOOLEAN; ret: Ast.Expression);
    BEGIN
      IF ret # NIL THEN
        IF stats THEN
          Text.StrLn(g, ";")
        END;
        Text.Str(g, "RETURN ");
        Expression(g, ret)
      END
    END Return;
  BEGIN
    Text.Str(g, "PROCEDURE ");
    MarkedName(g, p, "");
    ProcParams(g, p.header);
    Text.StrLn(g, ";");
    declarations(g, p);
    Text.StrOpen(g, "BEGIN");
    Statements(g, p.stats);
    Return(g, p.stats # NIL, p.return);
    Text.LnStrClose(g, "END ");
    Name(g, p);
    Text.StrLn(g, ";")
  END Procedure;

  PROCEDURE Declarations(VAR g: Generator; ds: Ast.Declarations);
  VAR d: Ast.Declaration;
  BEGIN
    IF ds.consts # NIL THEN
      Consts(g, ds.consts)
    END;

    IF ds.types # NIL THEN
      Types(g, ds.types)
    END;

    IF ds.vars # NIL THEN
      Vars(g, ds.vars)
    END;

    IF (ds.vars # NIL) & (ds.procedures # NIL) THEN
      Text.Ln(g)
    END;

    Text.IndentOpen(g);
    d := ds.procedures;
    WHILE d # NIL DO
      Procedure(g, d(Ast.Procedure));
      Text.Ln(g);
      d := d.next
    END;
    Text.IndentClose(g)
  END Declarations;

  PROCEDURE Generate*(out: Stream.POut; module: Ast.Module; opt: Options);
  VAR g: Generator;
  BEGIN
    Init(g, out, module, opt);

    Text.Str(g, "MODULE ");
    Name(g, module);
    Text.StrLn(g, ";");

    IF module.import # NIL THEN
      Imports(g, module.import)
    ELSIF g.opt.std IN {StdAo, StdCp} THEN
      Text.StrLn(g, "IMPORT O_7, SYSTEM;")
    END;
    Declarations(g, module);
    IF module.stats # NIL THEN
      Text.StrOpen(g, "BEGIN");
      Statements(g, module.stats);
      Text.StrLnClose(g, "")
    END;

    Text.Str(g, "END ");
    Name(g, module);
    Text.StrLn(g, ".")
  END Generate;

BEGIN
  declarations := Declarations;
  statements   := Statements;
  expression   := Expression;
  type         := ReferenceToType
END GeneratorOberon.

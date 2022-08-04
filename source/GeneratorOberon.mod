(*  Generator of Oberon-code by abstract syntax tree
 *
 *  Copyright (C) 2019,2021-2022 ComdivByZero
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
  TranLim := TranslatorLimits,
  GenOptions, GenCommon;

CONST
  Supported* = TRUE;

  StdO7* = 1;
  StdAo* = 2;
  StdCp* = 3;

TYPE
  Options* = POINTER TO RECORD(GenOptions.R)
    std*: INTEGER;
    multibranchWhile*,
    declaration*, import*,
    plantUml*: BOOLEAN
  END;

  Generator = RECORD(Text.Out)
    module: Ast.Module;
    presentAlternative: BOOLEAN;
    opt: Options
  END;

VAR
  declarations: PROCEDURE(VAR g: Generator; ds: Ast.Declarations);
  statements  : PROCEDURE(VAR g: Generator; stats: Ast.Statement);
  expression  : PROCEDURE(VAR g: Generator; expr: Ast.Expression);
  type        : PROCEDURE(VAR g: Generator; typ: Ast.Type);

PROCEDURE Str    (VAR g: Text.Out; s: ARRAY OF CHAR); BEGIN Text.Str    (g, s) END Str;
PROCEDURE StrLn  (VAR g: Text.Out; s: ARRAY OF CHAR); BEGIN Text.StrLn  (g, s) END StrLn;
PROCEDURE StrOpen(VAR g: Text.Out; s: ARRAY OF CHAR); BEGIN Text.StrOpen(g, s) END StrOpen;
PROCEDURE Ln     (VAR g: Text.Out);                   BEGIN Text.Ln     (g)    END Ln;
PROCEDURE Int    (VAR g: Text.Out; i: INTEGER);       BEGIN Text.Int    (g, i) END Int;
PROCEDURE Chr    (VAR g: Text.Out; c: CHAR);          BEGIN Text.Char   (g, c) END Chr;
PROCEDURE StrLnClose(VAR g: Text.Out; s: ARRAY OF CHAR); BEGIN Text.StrLnClose(g, s) END StrLnClose;
PROCEDURE LnStrClose(VAR g: Text.Out; s: ARRAY OF CHAR); BEGIN Text.LnStrClose(g, s) END LnStrClose;

  PROCEDURE Ident(VAR g: Generator; ident: Strings.String);
  BEGIN
    IF SpecIdent.IsSpecName(ident) THEN
      (* TODO *)
      Str(g, "dnt")
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
      Chr(g, ".")
    END;
    IF decl.mark OR ~g.opt.declaration THEN
      Name(g, decl)
    ELSE
      Str(g, "<*>")
    END
  END GlobalName;

  PROCEDURE DefaultOptions*(): Options;
  VAR o: Options;
  BEGIN
    NEW(o);
    IF o # NIL THEN
      V.Init(o^);
      GenOptions.Default(o^);
      o.std := StdO7;
      o.plantUml := FALSE;
      o.multibranchWhile := (o.std = StdO7) & ~o.plantUml;
      o.declaration := FALSE;
      o.import := FALSE;
      o.identEnc := GenOptions.IdentEncSame
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
    opt.multibranchWhile := (opt.std = StdO7) & ~opt.plantUml;

    Text.Init(g, out);
    g.module := m;
    g.opt    := opt
  END Init;

  PROCEDURE LnClose(VAR g: Generator);
  BEGIN
    Text.IndentClose(g);
    Ln(g)
  END LnClose;

  PROCEDURE Comment(VAR g: Generator; text: Strings.String; justText: BOOLEAN);
  BEGIN
    ASSERT(justText OR g.opt.plantUml);

    IF justText THEN
      GenCommon.CommentOberon(g, g.opt^, text)
    ELSIF g.opt.comment & Strings.IsDefined(text) & ~Strings.SearchSubString(text, "end note") THEN
      StrOpen(g, "note");
      Text.String(g, text);
      Ln(g);
      StrLnClose(g, "end note")
    END
  END Comment;

  PROCEDURE EmptyLines(VAR g: Generator; n: Ast.PNode);
  BEGIN
    IF 0 < n.emptyLines THEN
      Ln(g)
    END
  END EmptyLines;

  PROCEDURE PlantUmlPrefix(VAR g: Generator);
  BEGIN
    IF g.opt.plantUml THEN
      Chr(g, ":")
    END
  END PlantUmlPrefix;

  PROCEDURE Imports(VAR g: Generator; d: Ast.Declaration);
    PROCEDURE Import(VAR g: Generator; decl: Ast.Declaration);
    VAR name: Strings.String;
    BEGIN
      Name(g, decl);
      name := decl.module.m.name;
      IF Strings.Compare(decl.name, name) # 0 THEN
        Str(g, " := ");
        Ident(g, name)
      END
    END Import;
  BEGIN
    IF g.opt.plantUml THEN
      StrLn(g, "card IMPORT {");
      Chr(g, ":")
    ELSIF (g.opt.std = StdO7) OR g.opt.declaration THEN
      Ln(g);
      StrOpen(g, "IMPORT")
    ELSE ASSERT(g.opt.std IN {StdAo, StdCp});
      Ln(g);
      StrOpen(g, "IMPORT O_7, SYSTEM,")
    END;

    Import(g, d);
    d := d.next;
    WHILE (d # NIL) & (d.id = Ast.IdImport) DO
      StrLn(g, ",");
      Import(g, d);
      d := d.next
    END;
    StrLn(g, ";");

    IF g.opt.plantUml THEN
      StrLn(g, "kill");
      StrLn(g, "}")
    ELSE
      LnClose(g)
    END
  END Imports;

  PROCEDURE ExpressionBraced(VAR g: Generator;
                             l: ARRAY OF CHAR; e: Ast.Expression; r: ARRAY OF CHAR);
  BEGIN
    Str(g, l);
    expression(g, e);
    Str(g, r)
  END ExpressionBraced;

  PROCEDURE ExpressionInfix(VAR g: Generator;
                            e1: Ast.Expression; oper: ARRAY OF CHAR; e2: Ast.Expression);
  BEGIN
    expression(g, e1);
    Str(g, oper);
    expression(g, e2)
  END ExpressionInfix;

  PROCEDURE Designator(VAR g: Generator; des: Ast.Designator);
  VAR sel: Ast.Selector;

    PROCEDURE Selector(VAR g: Generator; VAR sel: Ast.Selector);

      PROCEDURE Record(VAR g: Generator; sel: Ast.Selector);
      BEGIN
        Str(g, ".");
        Name(g, sel(Ast.SelRecord).var);
      END Record;

      PROCEDURE Array(VAR g: Generator; VAR sel: Ast.Selector);
      BEGIN
        Str(g, "[");
        expression(g, sel(Ast.SelArray).index);
        sel := sel.next;
        WHILE (sel # NIL) & (sel IS Ast.SelArray) DO
          Chr(g, ",");
          expression(g, sel(Ast.SelArray).index);
          sel := sel.next;
        END;
        Str(g, "]")
      END Array;

      PROCEDURE TypeGuard(VAR g: Generator; sel: Ast.SelGuard);
      BEGIN
        Chr(g, "(");
        GlobalName(g, sel.type);
        Chr(g, ")");
      END TypeGuard;
    BEGIN
      IF sel IS Ast.SelArray THEN
        Array(g, sel)
      ELSE
        IF sel IS Ast.SelRecord THEN
          Record(g, sel)
        ELSIF sel IS Ast.SelPointer THEN
          Chr(g, "^")
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
        Str(g, "O_7.ch[");
        Text.Data(g, s, 0, 4);
        Chr(g, "]")
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
      Text.Data(g, s, 0, 3);
      IF g.opt.plantUml & (s[1] = "|") THEN
        g.presentAlternative := TRUE
      END
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
              Int(g, LongSet.Ord(e.value(Ast.ExprSetValue).set))
            END
          ELSE ASSERT(e.type.id = Ast.IdBoolean);
            IF e.value = NIL THEN
              ExpressionBraced(g, "O_7.Bti(", e, ")")
            ELSE
              Int(g, ORD(e.value(Ast.ExprBoolean).bool))
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
            Str(g, "HALT(1)")
          END
        END Assert;

        PROCEDURE Pack(VAR g: Generator; e1, e2: Ast.Expression);
        BEGIN
          CASE g.opt.std OF
            StdO7: Str(g, "PACK(")
          | StdAo,
            StdCp: Str(g, "O_7.Pack(")
          END;
          Expression(g, e1);
          ExpressionBraced(g, ", ", e2, ")")
        END Pack;

        PROCEDURE Unpack(VAR g: Generator; e1, e2: Ast.Expression);
        BEGIN
          CASE g.opt.std OF
            StdO7: Str(g, "UNPK(")
          | StdAo,
            StdCp: Str(g, "O_7.Unpk(")
          END;
          Expression(g, e1);
          ExpressionBraced(g, ", ", e2, ")")
        END Unpack;

        PROCEDURE One(VAR g: Generator; name: ARRAY OF CHAR; e: Ast.Expression);
        BEGIN
          Str(g, name);
          ExpressionBraced(g, "(", e, ")");
        END One;

        PROCEDURE Two(VAR g: Generator; name: ARRAY OF CHAR; e1, e2: Ast.Expression);
        BEGIN
          Str(g, name);
          ExpressionBraced(g, "(", e1, ", ");
          Expression(g, e2);
          Chr(g, ")")
        END Two;

        PROCEDURE MayTwo(VAR g: Generator; name: ARRAY OF CHAR;
                         e1: Ast.Expression; p2: Ast.Parameter);
        BEGIN
          Str(g, name);
          IF p2 = NIL THEN
            ExpressionBraced(g, "(", e1, ")");
          ELSE
            ExpressionBraced(g, "(", e1, ", ");
            Expression(g, p2.expr);
            Chr(g, ")")
          END
        END MayTwo;

        PROCEDURE Lsl(VAR g: Generator; x, n: Ast.Expression);
        BEGIN
          CASE g.opt.std OF
            StdO7: Str(g, "LSL(")
          | StdAo: Str(g, "LSH(")
          | StdCp: Str(g, "ASH(")
          END;
          Expression(g, x);
          ExpressionBraced(g, ", ", n, ")")
        END Lsl;

        PROCEDURE Asr(VAR g: Generator; x, n: Ast.Expression);
        BEGIN
          CASE g.opt.std OF
            StdO7: Str(g, "ASR(");
            Expression(g, x);
            ExpressionBraced(g, ", ", n, ")")
          | StdAo,
            StdCp: Str(g, "ASH(");
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

        PROCEDURE Chrf(VAR g: Generator; int: Ast.Expression);
        BEGIN
          CASE g.opt.std OF
            StdO7,
            StdAo: ExpressionBraced(g, "CHR(", int, ")")
          | StdCp: ExpressionBraced(g, "SHORT(CHR(", int, "))")
          END
        END Chrf;

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
            StdAo: Str(g, "ROR(")
          | StdCp: Str(g, "O_7.Ror(")
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
        | SpecIdent.Chr  : Chrf(g, e1)
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
        Chr(g, "(");
        p  := call.params;
        fp := call.designator.type(Ast.ProcType).params;
        IF p # NIL THEN
          ActualParam(g, p, fp);
          WHILE p # NIL DO
            Str(g, ", ");
            ActualParam(g, p, fp)
          END
        END;
        Chr(g, ")")
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
        Str(g, " -")
      ELSIF sum.add = Ast.Plus THEN
        Str(g, " +")
      END;
      Expression(g, sum.term);
      sum := sum.next;
      WHILE sum # NIL DO
        IF sum.add = Ast.Minus THEN
          Str(g, " - ")
        ELSIF sum.add = Ast.Plus THEN
          Str(g, " + ")
        ELSIF sum.add = Ast.Or THEN
          Str(g, " OR ")
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
          Ast.Mult : Str(g, " * "  )
        | Ast.Rdiv : Str(g, " / "  )
        | Ast.Div  : Str(g, " DIV ")
        | Ast.Mod  : Str(g, " MOD ")
        | Ast.And  : Str(g, " & "  )
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
      THEN Str(g, "TRUE")
      ELSE Str(g, "FALSE")
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
          Str(g, "SHORT(");
          Text.String(g, w);
          Chr(g, ")")
        END;
        IF g.opt.plantUml & Strings.SearchSubString(w, "|") THEN
          g.presentAlternative := TRUE
        END
      ELSE
        Char(g, e.int, e.usedAs)
      END
    END String;

    PROCEDURE ExprInt(VAR g: Generator; int: INTEGER);
    BEGIN
      IF int >= 0 THEN
        Int(g, int)
      ELSE
        Str(g, "(-");
        Int(g, -int);
        Chr(g, ")")
      END
    END ExprInt;

    PROCEDURE ExprLongInt(VAR g: Generator; int: INTEGER);
    BEGIN
      ASSERT(FALSE);
    END ExprLongInt;

    PROCEDURE ValueOfSet(VAR g: Generator; set: Ast.ExprSetValue);
    BEGIN
      ASSERT(FALSE);
      Int(g, ORD(set.set[0]));
    END ValueOfSet;

    PROCEDURE Set(VAR g: Generator; set: Ast.ExprSet);
    VAR braces: ARRAY 3 OF CHAR;
      PROCEDURE Val(VAR g: Generator; set: Ast.ExprSet; braces: ARRAY OF CHAR);
        PROCEDURE Item(VAR g: Generator; set: Ast.ExprSet);
        BEGIN
          IF set.exprs[1] = NIL THEN
            Expression(g, set.exprs[0])
          ELSE
            ExpressionInfix(g, set.exprs[0], " .. ", set.exprs[1])
          END
        END Item;
      BEGIN
        IF (set.next = NIL) & (set.exprs[0] = NIL) THEN
          Str(g, braces)
        ELSE
          Chr(g, braces[0]);
          Item(g, set);
          set := set.next;
          WHILE set # NIL DO
            Str(g, ", ");
            Item(g, set);
            set := set.next
          END;
          Chr(g, braces[1])
        END
      END Val;
    BEGIN
      IF g.opt.plantUml THEN
        braces := "()"
      ELSE
        braces := "{}"
      END;
      CASE g.opt.std OF
        StdO7,
        StdCp: Val(g, set, braces)
      | StdAo: Str(g, "SET32("); Val(g, set, braces); Str(g, ")")
      END
    END Set;

    PROCEDURE IsExtension(VAR g: Generator; is: Ast.ExprIsExtension);
    BEGIN
      Designator(g, is.designator);
      Str(g, " IS ");
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
      ELSE ValueOfSet(g, expr(Ast.ExprSetValue))
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
      Str(g, "~");
      Expression(g, expr(Ast.ExprNegate).expr)
    | Ast.IdBraces:
      ExpressionBraced(g, "(", expr(Ast.ExprBraces).expr, ")")
    | Ast.IdPointer:
      Str(g, "NIL")
    | Ast.IdIsExtension:
      IsExtension(g, expr(Ast.ExprIsExtension))
    END
  END Expression;

  PROCEDURE Mark(VAR g: Generator; d: Ast.Declaration);
  BEGIN
    IF d.mark & ~g.opt.declaration THEN
      Chr(g, "*")
    END
  END Mark;

  PROCEDURE MarkedName(VAR g: Generator; d: Ast.Declaration; str: ARRAY OF CHAR);
  BEGIN
    Name(g, d);
    Mark(g, d);
    Str(g, str)
  END MarkedName;

  PROCEDURE FirstMarked(VAR d: Ast.Declaration);
  VAR id: INTEGER;
  BEGIN
    IF d # NIL THEN
      id := d.id;
      WHILE (d # NIL) & (d.id = id) & ~d.mark DO
        d := d.next
      END;
      IF (d # NIL) & (d.id # id) THEN
        d := NIL
      END
    END
  END FirstMarked;

  PROCEDURE Consts(VAR g: Generator; d: Ast.Declaration);
    PROCEDURE Const(VAR g: Generator; c: Ast.Const);
    BEGIN
      Comment(g, c.comment, TRUE);
      EmptyLines(g, c);

      MarkedName(g, c, " = ");
      Expression(g, c.expr);
      IF g.opt.plantUml THEN
        Ln(g)
      ELSE
        StrLn(g, ";")
      END
    END Const;
  BEGIN
    IF g.opt.plantUml THEN
      Str(g, ":")
    ELSE
      StrOpen(g, "CONST")
    END;
    WHILE (d # NIL) & (d.id = Ast.IdConst) DO
      IF d.mark OR ~g.opt.declaration THEN
        Const(g, d(Ast.Const))
      END;
      d := d.next
    END;
    IF g.opt.plantUml THEN
      StrLn(g, ";")
    ELSE
      LnClose(g)
    END
  END Consts;

  PROCEDURE ProcParams(VAR g: Generator; proc: Ast.ProcType);
  VAR p: Ast.Declaration;

    PROCEDURE SimilarParams(VAR g: Generator; VAR p: Ast.Declaration);
    VAR fp: Ast.FormalParam;

      PROCEDURE Access(VAR g: Generator; fp: Ast.FormalParam);
      BEGIN
        IF Ast.ParamOut IN fp.access THEN
          Str(g, "VAR ")
        ELSIF fp.type.id IN Ast.Structures THEN
          CASE g.opt.std OF
            StdO7: ;
          | StdAo: Str(g, "CONST ")
          | StdCp: Str(g, "IN ")
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
        Str(g, ", ");
        Name(g, p);
        p := p.next
      END;
      Str(g, ": ");
      type(g, fp.type)
    END SimilarParams;
  BEGIN
    IF proc.params # NIL THEN
      Chr(g, "(");
      p := proc.params;
      SimilarParams(g, p);
      WHILE p # NIL DO
        Str(g, "; ");
        SimilarParams(g, p)
      END;
      IF proc.type = NIL THEN
        Chr(g, ")")
      ELSE
        Str(g, "): ");
        type(g, proc.type)
      END
    ELSIF proc.type # NIL THEN
      Str(g, "(): ");
      type(g, proc.type)
    END
  END ProcParams;

  PROCEDURE VarList(VAR g: Generator; v: Ast.Declaration);

    PROCEDURE ListSameType(VAR g: Generator; VAR v: Ast.Declaration; sep: ARRAY OF CHAR);
    VAR p: Ast.Declaration;

      PROCEDURE Next(g: Generator; VAR v: Ast.Declaration): BOOLEAN;
      BEGIN
        REPEAT
          v := v.next
        UNTIL (v = NIL) OR (v.id # Ast.IdVar) OR v.mark OR ~g.opt.declaration
      RETURN
        (v # NIL) & (v.id = Ast.IdVar)
      END Next;

    BEGIN
      MarkedName(g, v, "");
      p := v;
      WHILE Next(g, v) & (p.type = v.type) DO
        Str(g, ", ");
        MarkedName(g, v, "");
        p := v
      END;
      Str(g, sep);
      type(g, p.type)
    END ListSameType;

  BEGIN
    ListSameType(g, v, ": ");
    WHILE (v # NIL) & (v.id = Ast.IdVar) DO
      IF g.opt.plantUml THEN
        Ln(g)
      ELSE
        StrLn(g, ";")
      END;
      ListSameType(g, v, ": ")
    END
  END VarList;

  PROCEDURE Type(VAR g: Generator; typ: Ast.Type; forDecl: BOOLEAN);

    PROCEDURE Array(VAR g: Generator; typ: Ast.Type): Ast.Type;
    BEGIN
      IF typ(Ast.Array).count = NIL THEN
        REPEAT
          ASSERT(typ(Ast.Array).count = NIL);
          Str(g, "ARRAY OF ");
          typ := typ.type
        UNTIL typ.id # Ast.IdArray
      ELSE
        Str(g, "ARRAY ");
        Expression(g, typ(Ast.Array).count);
        typ := typ.type;
        WHILE (typ.id = Ast.IdArray) & ~Strings.IsDefined(typ.name) DO
          Str(g, ", ");
          Expression(g, typ(Ast.Array).count);
          typ := typ.type
        END;
        Str(g, " OF ")
      END;
    RETURN
      typ
    END Array;

    PROCEDURE Record(VAR g: Generator; rec: Ast.Record);
    VAR v: Ast.Declaration; base: ARRAY TranLim.RecordExt OF Ast.Record; i: INTEGER;

      PROCEDURE BasesForDecl(VAR base: ARRAY OF Ast.Record): INTEGER;
      VAR i: INTEGER;
      BEGIN
        i := 0;
        WHILE (base[i] # NIL) & ~base[i].mark DO
          INC(i);
          base[i] := base[i - 1].base
        END
      RETURN
        i
      END BasesForDecl;

      PROCEDURE ExportedFromBase(VAR g: Generator; base: ARRAY OF Ast.Record; i: INTEGER): BOOLEAN;
      VAR v: Ast.Declaration; mark: BOOLEAN;
      BEGIN
        v := NIL;
        WHILE (i > 0) & (v = NIL) DO
          DEC(i);
          v := base[i].vars;
          FirstMarked(v)
        END;
        mark := v # NIL;
        IF mark THEN
          VarList(g, v);
          WHILE i > 0 DO
            DEC(i);
            v := base[i].vars;
            FirstMarked(v);
            IF v # NIL THEN
              StrLn(g, ";");
              VarList(g, v)
            END
          END
        END
      RETURN
        mark
      END ExportedFromBase;

    BEGIN
      IF (g.opt.std = StdCp)
       & rec.hasExt
       & (rec.mark OR ~g.opt.declaration)
      THEN
        Str(g, "EXTENSIBLE ")
      END;

      base[0] := rec.base;
      IF g.opt.declaration THEN
        i := BasesForDecl(base)
      ELSE
        i := 0
      END;
      IF base[i] = NIL THEN
        StrOpen(g, "RECORD")
      ELSE
        Str(g, "RECORD(");
        GlobalName(g, base[i]);
        StrOpen(g, ")")
      END;
      v := rec.vars;
      IF g.opt.declaration THEN
        FirstMarked(v);
        IF ExportedFromBase(g, base, i) & (v # NIL) THEN
          StrLn(g, ";")
        END
      END;
      IF v # NIL THEN
        VarList(g, v)
      END;
      Text.LnStrClose(g, "END")
    END Record;

  BEGIN
    IF ~forDecl
      & Strings.IsDefined(typ.name)
      & (typ.mark OR ~g.opt.declaration)
    THEN
      GlobalName(g, typ)
    ELSE
      CASE typ.id OF
        Ast.IdInteger:
        CASE g.opt.std OF
          StdO7,
          StdCp: Str(g, "INTEGER")
        | StdAo: Str(g, "SIGNED32")
        END
      | Ast.IdSet:
        CASE g.opt.std OF
          StdO7,
          StdCp: Str(g, "SET")
        | StdAo: Str(g, "SET32")
        END
      | Ast.IdLongInt:
        CASE g.opt.std OF
          StdCp: Str(g, "LONGINT")
        | StdAo: Str(g, "SIGNED64")
        END
      | Ast.IdLongSet:
        CASE g.opt.std OF
          StdAo: Str(g, "SET64")
        END
      | Ast.IdBoolean:
        Str(g, "BOOLEAN")
      | Ast.IdByte:
        CASE g.opt.std OF
          StdO7,
          StdCp: Str(g, "BYTE")
        | StdAo: Str(g, "UNSIGNED8")
        END
      | Ast.IdChar:
        CASE g.opt.std OF
          StdO7,
          StdAo: Str(g, "CHAR")
        | StdCp: Str(g, "SHORTCHAR")
        END
      | Ast.IdReal:
        CASE g.opt.std OF
          StdO7,
          StdCp: Str(g, "REAL")
        | StdAo: Str(g, "FLOAT64")
        END
      | Ast.IdReal32:
        CASE g.opt.std OF
          StdCp: Str(g, "SHORTREAL")
        | StdAo: Str(g, "FLOAT32")
        END
      | Ast.IdRecord:
        Record(g, typ(Ast.Record))
      | Ast.IdProcType, Ast.IdFuncType:
        Str(g, "PROCEDURE ");
        ProcParams(g, typ(Ast.ProcType))
      | Ast.IdPointer:
        Str(g, "POINTER TO ");
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
      Comment(g, t.comment, TRUE);
      EmptyLines(g, t);
      MarkedName(g, t, " = ");
      Type(g, t, TRUE);
      IF g.opt.plantUml THEN
        Ln(g)
      ELSE
        StrLn(g, ";")
      END;
    END Decl;
  BEGIN
    IF g.opt.plantUml THEN
      Str(g, ":")
    ELSE
      StrOpen(g, "TYPE")
    END;
    WHILE (d # NIL) & (d.id IN Ast.DeclarableTypes) DO
      IF d.mark OR ~g.opt.declaration THEN
        Decl(g, d(Ast.Type))
      END;
      d := d.next
    END;
    IF g.opt.plantUml THEN
      StrLn(g, ";")
    ELSE
      LnClose(g)
    END
  END Types;

  PROCEDURE Vars(VAR g: Generator; d: Ast.Declaration);
  BEGIN
    IF g.opt.plantUml THEN
      Str(g, ":");
      VarList(g, d);
      StrLn(g, ";")
    ELSE
      StrOpen(g, "VAR");
      VarList(g, d);
      StrLnClose(g, ";")
    END
  END Vars;

  PROCEDURE ExtractNegate(e: Ast.Expression; VAR sube: Ast.Expression): BOOLEAN;
  BEGIN
    IF e IS Ast.ExprNegate THEN
      sube := e(Ast.ExprNegate).expr;
      IF sube IS Ast.ExprBraces THEN
        sube := sube(Ast.ExprBraces).expr
      END
    ELSE
      sube := NIL
    END
  RETURN
    sube # NIL
  END ExtractNegate;

  PROCEDURE ExprThenStats(VAR g: Generator; VAR wi: Ast.WhileIf; then, thenNeg: ARRAY OF CHAR);
  VAR sub: Ast.Expression;
  BEGIN
    IF (thenNeg # "") & ExtractNegate(wi.expr, sub) THEN
      Expression(g, sub);
      StrOpen(g, thenNeg)
    ELSE
      Expression(g, wi.expr);
      StrOpen(g, then)
    END;
    statements(g, wi.stats);
    wi := wi.elsif
  END ExprThenStats;

  PROCEDURE Statement(VAR g: Generator; st: Ast.Statement);

    PROCEDURE WhileIf(VAR g: Generator; wi: Ast.WhileIf);

      PROCEDURE Wr(VAR g: Generator; wi: Ast.WhileIf;
                   begin, then, thenNeg, elsif, else, end: ARRAY OF CHAR);

        PROCEDURE Elsif(VAR g: Generator; VAR wi: Ast.WhileIf; then, thenNeg, elsif: ARRAY OF CHAR);
        BEGIN
          WHILE (wi # NIL) & (wi.expr # NIL) DO
            LnStrClose(g, elsif);
            ExprThenStats(g, wi, then, thenNeg)
          END
        END Elsif;
      BEGIN
        Str(g, begin);
        ExprThenStats(g, wi, then, thenNeg);
        Elsif(g, wi, then, thenNeg, elsif);
        IF wi # NIL THEN
          LnClose(g);
          StrOpen(g, else);
          statements(g, wi.stats)
        END;
        LnStrClose(g, end)
      END Wr;
    BEGIN
      IF wi IS Ast.If THEN
        IF g.opt.plantUml THEN
          Wr(g, wi, "if (", ") then (yes)", ") then (no)", "elseif (", "else", "endif")
        ELSE
          Wr(g, wi, "IF ", " THEN", "", "ELSIF ", "ELSE", "END")
        END;
      ELSIF (wi.elsif = NIL) OR g.opt.multibranchWhile THEN
        IF g.opt.plantUml THEN
          Wr(g, wi, "while (", ") is (yes)", ") is (no)", "", "", "endwhile")
        ELSE
          Wr(g, wi, "WHILE ", " DO", "", "ELSIF ", "", "END")
        END
      ELSE
        IF g.opt.plantUml THEN
          StrOpen(g, "repeat");
          Wr(g, wi, "if (", ") then (yes)", ") then (no)", "elseif (", "", "");
          StrOpen(g, "else");
          StrLn(g, ":stop;");
          Text.StrClose(g, "endif");
          LnStrClose(g, "repeat while(continue?) not (stop) ")
        ELSE
          Wr(g, wi, "LOOP IF ", " THEN", "", "ELSIF ", "", "ELSE EXIT END END")
        END
      END
    END WhileIf;

    PROCEDURE Repeat(VAR g: Generator; st: Ast.Repeat);
    VAR sub: Ast.Expression;
    BEGIN
      IF g.opt.plantUml THEN
        StrOpen(g, "repeat");
        statements(g, st.stats);
        LnStrClose(g, "repeat while (");
        IF ExtractNegate(st.expr, sub) THEN
          Expression(g, sub);
          Str(g, ") is (yes) not (no)")
        ELSE
          Expression(g, st.expr);
          Str(g, ") is (no) not (yes)")
        END
      ELSE
        StrOpen(g, "REPEAT");
        statements(g, st.stats);
        LnStrClose(g, "UNTIL ");
        Expression(g, st.expr)
      END
    END Repeat;

    PROCEDURE For(VAR g: Generator; st: Ast.For);
    BEGIN
      IF g.opt.plantUml THEN
        Str(g, "while (")
      END;
      Str(g, "FOR ");
      GlobalName(g, st.var);
      ExpressionBraced(g, " := ", st.expr, " TO ");
      Expression(g, st.to);
      IF st.by # 1 THEN
        Str(g, " BY ");
        Int(g, st.by)
      END;
      IF g.opt.plantUml THEN
        StrOpen(g, ")");
        statements(g, st.stats);
        LnStrClose(g, "endwhile (end)")
      ELSE
        StrOpen(g, " DO");
        statements(g, st.stats);
        LnStrClose(g, "END")
      END
    END For;

    PROCEDURE Assign(VAR g: Generator; st: Ast.Assign);
    BEGIN
      IF (g.opt.std IN {StdAo, StdCp})
       & (st.expr.type.id = Ast.IdArray) & (st.expr.type(Ast.Array).count = NIL)
      THEN
        ExpressionBraced(g, "ASSERT(LEN(", st.expr, ") <= LEN(");
        Designator(g, st.designator);
        StrLn(g, "));");

        ExpressionBraced(g, "SYSTEM.MOVE(SYSTEM.ADR(", st.expr, "), SYSTEM.ADR(");
        Designator(g, st.designator);
        CASE g.opt.std OF
          StdAo: Str(g, "), SIZEOF(")
        | StdCp: Str(g, "), SIZE(")
        END;
        Type(g, st.expr.type.type, FALSE);
        Str(g, "))")
      ELSE
        Designator(g, st.designator);
        Str(g, " := ");
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
              Int(g, l.value);
            ELSE ASSERT(tid = Ast.IdChar);
              Char(g, l.value, Ast.StrUsedAsChar)
            END
          END Label;
        BEGIN
          Label(g, r, tid);
          IF r.right # NIL THEN
            Str(g, " .. ");
            Label(g, r.right, tid)
          END
        END Range;
      BEGIN
        r := elem.labels;
        IF g.opt.plantUml THEN Str(g, "case (") END;
        Range(g, r, tid);
        r := r.next;
        WHILE r # NIL DO
          Str(g, ", ");
          Range(g, r, tid);
          r := r.next
        END;
        IF g.opt.plantUml THEN
          StrOpen(g, ")")
        ELSE
          StrOpen(g, ":")
        END;
        statements(g, elem.stats);
        LnClose(g)
      END CaseElement;
    BEGIN
      IF g.opt.plantUml THEN
        ExpressionBraced(g, "switch (", st.expr, ")");
        Ln(g)
      ELSE
        ExpressionBraced(g, "CASE ", st.expr, " OF");
        Ln(g);
        Str(g, "  ")
      END;
      elem := st.elements;
      CaseElement(g, elem, st.expr.type.id);
      elem := elem.next;
      WHILE elem # NIL DO
        IF ~g.opt.plantUml THEN Str(g, "| ") END;
        CaseElement(g, elem, st.expr.type.id);
        elem := elem.next
      END;
      IF g.opt.plantUml THEN
        Str(g, "endswitch")
      ELSE
        IF g.opt.caseAbort & (g.opt.std # StdO7) THEN
          (* TODO *)
          StrLn(g, "ELSE HALT(1)")
        END;
        Str(g, "END")
      END
    END Case;

    PROCEDURE Call(VAR g: Generator; call: Ast.ExprCall);
    BEGIN
      PlantUmlPrefix(g);
      g.presentAlternative := FALSE;
      IF call.params = NIL THEN
        Designator(g, call.designator)
      ELSE
        Expression(g, call)
      END;
      IF ~g.opt.plantUml THEN
        ;
      ELSIF (call.designator.decl IS Ast.PredefinedProcedure)
         OR g.presentAlternative
      THEN
        Chr(g, ";")
      ELSE
        Chr(g, "|")
      END
    END Call;
  BEGIN
    IF ~g.opt.plantUml THEN
      Comment(g, st.comment, TRUE)
    END;
    IF 0 < st.emptyLines THEN
      Ln(g)
    END;
    IF st IS Ast.Assign THEN
      IF g.opt.plantUml THEN
        Chr(g, ":");
        Assign(g, st(Ast.Assign));
        Chr(g, ";")
      ELSE
        Assign(g, st(Ast.Assign))
      END
    ELSIF st IS Ast.Call THEN
      Call(g, st.expr(Ast.ExprCall))
    ELSIF st IS Ast.WhileIf THEN
      WhileIf(g, st(Ast.WhileIf))
    ELSIF st IS Ast.Repeat THEN
      Repeat(g, st(Ast.Repeat))
    ELSIF st IS Ast.For THEN
      For(g, st(Ast.For))
    ELSE ASSERT(st IS Ast.Case);
      Case(g, st(Ast.Case))
    END;
    IF g.opt.plantUml THEN
      Ln(g);
      Comment(g, st.comment, FALSE)
    END;
  END Statement;

  PROCEDURE Statements(VAR g: Generator; stat: Ast.Statement);
  BEGIN
    IF stat # NIL THEN
      Statement(g, stat);
      stat := stat.next;
      WHILE stat # NIL DO
        IF ~g.opt.plantUml THEN
          StrLn(g, ";")
        END;
        Statement(g, stat);
        stat := stat.next
      END
    END
  END Statements;

  PROCEDURE Procedure(VAR g: Generator; p: Ast.Procedure);
    PROCEDURE Return(VAR g: Generator; stats: BOOLEAN; ret: Ast.Expression);
    BEGIN
      IF ret # NIL THEN
        IF g.opt.plantUml THEN
          IF stats THEN
            Ln(g)
          END;
          (* Невидимая { нужна из-за слабости разборщика Plang UML *)
          ExpressionBraced(g, ": RETURN ", ret, "<color:white>{}")
        ELSE
          IF stats THEN
            StrLn(g, ";")
          END;
          ExpressionBraced(g, "RETURN ", ret, "")
        END
      END
    END Return;
  BEGIN
    IF g.opt.plantUml THEN
      Str(g, "group PROCEDURE ");
      MarkedName(g, p, "");
      ProcParams(g, p.header);
      Ln(g);
      Comment(g, p.comment, FALSE)
    ELSE
      Comment(g, p.comment, TRUE);
      Str(g, "PROCEDURE ");
      MarkedName(g, p, "");
      ProcParams(g, p.header);
      StrLn(g, ";")
    END;
    IF ~g.opt.declaration THEN
      declarations(g, p);
      IF g.opt.plantUml THEN
        Text.IndentOpen(g);
        IF p.stats # NIL THEN
          StrLn(g, "start")
        END
      ELSIF (p.stats # NIL)
         OR (g.opt.std # StdO7) & (p.return # NIL)
      THEN
        StrOpen(g, "BEGIN")
      ELSE
        Text.IndentOpen(g)
      END;
      Statements(g, p.stats);
      Return(g, p.stats # NIL, p.return);
      IF g.opt.plantUml THEN
        Ln(g);
        IF p.return = NIL THEN
          StrLn(g, "stop")
        ELSE
          StrLn(g, "kill")
        END;
        StrLnClose(g, "end group")
      ELSE
        LnStrClose(g, "END ");
        Name(g, p);
        StrLn(g, ";")
      END
    END
  END Procedure;

  PROCEDURE Declarations(VAR g: Generator; ds: Ast.Declarations);
  VAR c, t, v, p: Ast.Declaration; decl: BOOLEAN;
  BEGIN
    c := ds.consts;
    t := ds.types;
    v := ds.vars;
    p := ds.procedures;
    IF g.opt.declaration THEN
      FirstMarked(c);
      FirstMarked(t);
      FirstMarked(v);
      FirstMarked(p)
    END;

    decl := (c # NIL) OR (t # NIL) OR (v # NIL);
    IF g.opt.plantUml THEN
      IF decl THEN
        StrLn(g, "card Declarations {")
      END
    ELSIF decl OR (p # NIL) THEN
      Ln(g)
    END;

    IF c # NIL THEN
      Consts(g, c)
    END;

    IF t # NIL THEN
      Types(g, t)
    END;

    IF v # NIL THEN
      Vars(g, v)
    END;

    IF decl & g.opt.plantUml THEN
      StrLn(g, "kill");
      StrLn(g, "}")
    END;

    WHILE p # NIL DO
      IF p.mark OR ~g.opt.declaration THEN
        EmptyLines(g, p);
        Procedure(g, p(Ast.Procedure))
      END;
      p := p.next
    END
  END Declarations;

  PROCEDURE Generate*(out: Stream.POut; module: Ast.Module; opt: Options);
  VAR g: Generator;
  BEGIN
    Init(g, out, module, opt);

    IF g.opt.plantUml THEN
      StrLn(g, "@startuml");
      Str(g, "package ");
      Chr(g, Utf8.DQuote);
      Str(g, "MODULE ");
      Name(g, module);
      Chr(g, Utf8.DQuote);
      StrLn(g, " {")
    ELSE
      IF g.opt.declaration THEN
        Str(g, "DEFINITION ")
      ELSE
        Str(g, "MODULE ")
      END;
      Name(g, module);
      StrLn(g, ";")
    END;

    IF ~opt.declaration THEN
      (* TODO *)
      opt.import := TRUE
    END;

    IF ~opt.import THEN
      ;
    ELSIF module.import # NIL THEN
      Imports(g, module.import)
    ELSIF (g.opt.std IN {StdAo, StdCp}) & ~g.opt.declaration THEN
      StrLn(g, "IMPORT O_7, SYSTEM;")
    END;
    Declarations(g, module);
    Ln(g);
    IF (module.stats # NIL) & ~g.opt.declaration THEN
      IF g.opt.plantUml THEN
        StrOpen(g, "group initialization");
        StrLn(g, "start");
        Statements(g, module.stats);
        Ln(g);
        StrLn(g, "stop");
        StrLnClose(g, "end group")
      ELSE
        StrOpen(g, "BEGIN");
        Statements(g, module.stats);
        LnClose(g)
      END
    END;

    IF g.opt.plantUml THEN
      StrLn(g, "}");
      StrLn(g, "@enduml")
    ELSE
      Str(g, "END ");
      Name(g, module);
      StrLn(g, ".")
    END
  END Generate;

BEGIN
  declarations := Declarations;
  statements   := Statements;
  expression   := Expression;
  type         := ReferenceToType
END GeneratorOberon.

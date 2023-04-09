(*  Generator of Oberon-code by abstract syntax tree
 *
 *  Copyright (C) 2019,2021-2023 ComdivByZero
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
  SpecIdent := OberonSpecIdent, Hex, RuHex, Chars0X,
  TranLim := TranslatorLimits,
  GenOptions, GenCommon;

CONST
  Supported* = TRUE;

  StdO7* = 1;
  StdAo* = 2;
  StdCp* = 3;

  StdE1* = 1AH;

  ForTypes = 7; (* Для ProcParams *)

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

    sep, sep1: CHAR;
    sep1Sp, assign: ARRAY 6 OF CHAR;
    retVar: Ast.Declaration;

    opt: Options
  END;

VAR
  declarations: PROCEDURE(VAR g: Generator; ds: Ast.Declarations);
  statements  : PROCEDURE(VAR g: Generator; stats: Ast.Statement);
  expression  : PROCEDURE(VAR g: Generator; expr: Ast.Expression);
  type        : PROCEDURE(VAR g: Generator; typ: Ast.Type);

  stdRetName  : Strings.String;


PROCEDURE Str    (VAR g: Text.Out; s: ARRAY OF CHAR); BEGIN Text.Str    (g, s) END Str;
PROCEDURE StrLn  (VAR g: Text.Out; s: ARRAY OF CHAR); BEGIN Text.StrLn  (g, s) END StrLn;
PROCEDURE StrOpen(VAR g: Text.Out; s: ARRAY OF CHAR); BEGIN Text.StrOpen(g, s) END StrOpen;
PROCEDURE Ln     (VAR g: Text.Out);                   BEGIN Text.Ln     (g)    END Ln;
PROCEDURE Int    (VAR g: Text.Out; i: INTEGER);       BEGIN Text.Int    (g, i) END Int;
PROCEDURE Int3   (VAR g: Text.Out; i: INTEGER);       BEGIN Text.IntBy3 (g, i, "`") END Int3;
PROCEDURE Chr    (VAR g: Text.Out; c: CHAR);          BEGIN Text.Char   (g, c) END Chr;
PROCEDURE SepLn  (VAR g: Generator); BEGIN Text.Char(g, g.sep); Text.Ln(g)     END SepLn;
(*PROCEDURE Sep1Sp (VAR g: Generator); BEGIN Text.Str(g, g.sep1Sp)               END Sep1Sp;*)
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
      IF g.opt.std = StdE1 THEN
        Chr(g, "`")
      ELSE
        Chr(g, ".")
      END
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
      o.multibranchWhile := (o.std IN {StdO7, StdE1}) & ~o.plantUml;
      o.declaration := FALSE;
      o.import := FALSE;
      o.identEnc := GenOptions.IdentEncSame
    END
  RETURN
    o
  END DefaultOptions;

  PROCEDURE Init(VAR g: Generator; out: Stream.POut; m: Ast.Module; opt: Options);
  BEGIN
    ASSERT(m # NIL);

    g.retVar := NIL;
    g.sep := ";";
    g.sep1 := ",";
    g.sep1Sp := ", ";
    g.assign := " := ";
    IF opt.std IN {StdCp, StdAo} THEN
      opt.caseAbort := FALSE
    ELSIF opt.std = StdE1 THEN
      g.sep  := ".";
      (*
      g.sep1 := ";";
      g.sep1Sp := "; ";
      *)
      g.assign := " ← ";
    END;
    opt.multibranchWhile := (opt.std IN {StdO7, StdE1}) & ~opt.plantUml;

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
        Str(g, g.assign);
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
    ELSIF g.opt.std = StdE1 THEN
      Ln(g);
      StrOpen(g, "((")
    ELSE ASSERT(g.opt.std IN {StdAo, StdCp});
      Ln(g);
      StrOpen(g, "IMPORT O_7, SYSTEM,")
    END;

    Import(g, d);
    d := d.next;
    WHILE (d # NIL) & (d.id = Ast.IdImport) DO
      Chr(g, g.sep1); Ln(g);
      Import(g, d);
      d := d.next
    END;

    IF g.opt.plantUml THEN
      SepLn(g);
      StrLn(g, "kill");
      StrLn(g, "}")
    ELSIF g.opt.std = StdE1 THEN
      LnClose(g);
      StrLn(g, "))")
    ELSE
      StrLnClose(g, ";")
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

  PROCEDURE Decimal(VAR g: Generator; val: INTEGER);
  BEGIN
    IF g.opt.std = StdE1 THEN
      Int3(g, val)
    ELSE
      Int(g, val)
    END
  END Decimal;

  PROCEDURE Designator(VAR g: Generator; des: Ast.Designator);
  VAR sel: Ast.Selector;

    PROCEDURE Selector(VAR g: Generator; VAR sel: Ast.Selector);

      PROCEDURE Record(VAR g: Generator; sel: Ast.Selector);
      BEGIN
        IF g.opt.std = StdE1 THEN
          Str(g, "˙")
        ELSE
          Chr(g, ".")
        END;
        Name(g, sel(Ast.SelRecord).var);
      END Record;

      PROCEDURE Array(VAR g: Generator; VAR sel: Ast.Selector);
      BEGIN
        Str(g, "[");
        expression(g, sel(Ast.SelArray).index);
        sel := sel.next;
        WHILE (sel # NIL) & (sel IS Ast.SelArray) DO
          Chr(g, g.sep1);
          expression(g, sel(Ast.SelArray).index);
          sel := sel.next;
        END;
        Str(g, "]")
      END Array;

      PROCEDURE TypeGuard(VAR g: Generator; sel: Ast.SelGuard);
      BEGIN
        IF g.opt.std = StdE1 THEN
          Str(g, ":(")
        ELSE
          Chr(g, "(")
        END;
        GlobalName(g, sel.type);
        Chr(g, ")")
      END TypeGuard;
    BEGIN
      IF sel IS Ast.SelArray THEN
        Array(g, sel)
      ELSE
        IF sel IS Ast.SelRecord THEN
          Record(g, sel)
        ELSIF sel IS Ast.SelPointer THEN
          IF g.opt.std = StdE1 THEN
            Str(g, "↑")
          ELSE
            Chr(g, "^")
          END
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
  VAR s: ARRAY 9 OF CHAR; i: INTEGER;
  BEGIN
    ASSERT((0 <= code) & (code < 100H));
    IF (code < 20H) OR (code >= 7FH)
    OR (code = ORD(Utf8.DQuote)) & (g.opt.std = StdO7)
    THEN
      IF g.opt.std = StdE1 THEN
        IF code > 9FH THEN
          s[0] := "0";
          s[1] := "0";
          i := 2
        ELSE
          i := 0
        END;
        RuHex.To(code DIV 10H, s, i);
        RuHex.To(code MOD 10H, s, i);
        ASSERT(Chars0X.CopyString(s, i, "л"));
        Text.Data(g, s, 0, i)
      ELSE
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
      END
    ELSE
      IF (code = ORD(Utf8.DQuote)) OR (g.opt.std = StdE1) THEN
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
    toByte := ~(g.opt.std IN {StdO7, StdE1})
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

  PROCEDURE Access1a(VAR g: Generator; access: SET);
  BEGIN
    IF    ~(Ast.ParamOut IN access) THEN
      ;
    ELSIF ~(Ast.ParamIn  IN access) THEN
      Str(g, "→ ")
    ELSE
      Str(g, "↔ ")
    END
  END Access1a;

  PROCEDURE Access(VAR g: Generator; fp: Ast.FormalParam; declaration: BOOLEAN);
  BEGIN
    IF g.opt.std = StdE1 THEN
      Access1a(g, fp.access)
    ELSIF declaration THEN
      IF Ast.ParamOut IN fp.access THEN
        Str(g, "VAR ")
      ELSIF fp.type.id IN Ast.Structures THEN
        CASE g.opt.std OF
          StdO7,
          StdE1: ;
        | StdAo: Str(g, "CONST ")
        | StdCp: Str(g, "IN ")
        END
      END
    END
  END Access;

  PROCEDURE Factor(VAR g: Generator; expr: Ast.Expression);
  BEGIN
    IF expr.id IN Ast.IdFactors THEN
      (* TODO *)
      expression(g, expr)
    ELSE
      ExpressionBraced(g, "(", expr, ")");
    END
  END Factor;

  PROCEDURE Expression(VAR g: Generator; expr: Ast.Expression);

    PROCEDURE Call(VAR g: Generator; call: Ast.ExprCall);
    VAR p: Ast.Parameter; fp: Ast.Declaration; isNum: BOOLEAN;

      PROCEDURE Predefined(VAR g: Generator; call: Ast.ExprCall);
      VAR e1: Ast.Expression; p2: Ast.Parameter;

        PROCEDURE Ord(VAR g: Generator; e: Ast.Expression);
        BEGIN
          IF g.opt.std = StdE1 THEN
            Factor(g, e);
            Str(g, ":Ц")
          ELSIF (g.opt.std = StdO7) OR ~(e.type.id IN {Ast.IdSet, Ast.IdBoolean}) THEN
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
          IF g.opt.std = StdE1 THEN
            IF (e.value = NIL) OR e.value(Ast.ExprBoolean).bool THEN
              Str(g, "!! ");
              Expression(g, e)
            ELSE
              Str(g, "🚫")
            END
          ELSIF (g.opt.std = StdO7)
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
          | StdE1: Str(g, "УПАК(");
            Access1a(g, {Ast.ParamIn, Ast.ParamOut});
          | StdAo,
            StdCp: Str(g, "O_7.Pack(")
          END;
          Expression(g, e1);
          ExpressionBraced(g, g.sep1Sp, e2, ")")
        END Pack;

        PROCEDURE Unpack(VAR g: Generator; e1, e2: Ast.Expression);
        BEGIN
          CASE g.opt.std OF
            StdO7: Str(g, "UNPK(")
          | StdE1: Str(g, "РАСП(");
            Access1a(g, {Ast.ParamIn, Ast.ParamOut});
            Expression(g, e1);
            Str(g, g.sep1Sp);
            Access1a(g, {Ast.ParamOut})
          | StdAo,
            StdCp: Str(g, "O_7.Unpk(")
          END;
          IF g.opt.std # StdE1 THEN
            Expression(g, e1);
            Str(g, g.sep1Sp)
          END;
          Expression(g, e2);
          Chr(g, ")")
        END Unpack;

        PROCEDURE One(VAR g: Generator; name: ARRAY OF CHAR; e: Ast.Expression; acc: SET);
        BEGIN
          Str(g, name);
          Chr(g, "(");
          IF g.opt.std = StdE1 THEN Access1a(g, acc) END;
          Expression(g, e);
          Chr(g, ")")
        END One;

        PROCEDURE Two(VAR g: Generator; name: ARRAY OF CHAR; e1: Ast.Expression; acc1: SET;
                                                             e2: Ast.Expression);
        BEGIN
          Str(g, name);
          Chr(g, "(");
          IF g.opt.std = StdE1 THEN Access1a(g, acc1) END;
          Expression(g, e1);
          Str(g, g.sep1Sp);
          Expression(g, e2);
          Chr(g, ")")
        END Two;

        PROCEDURE MayTwo(VAR g: Generator; name: ARRAY OF CHAR;
                         e1: Ast.Expression; acc: SET; p2: Ast.Parameter);
        BEGIN
          Str(g, name);
          Chr(g, "(");
          IF g.opt.std = StdE1 THEN Access1a(g, acc) END;
          Expression(g, e1);
          IF p2 # NIL THEN
            Str(g, g.sep1Sp);
            Expression(g, p2.expr);
          END;
          Chr(g, ")")
        END MayTwo;

        PROCEDURE Lsl(VAR g: Generator; x, n: Ast.Expression);
        BEGIN
          CASE g.opt.std OF
            StdO7,
            StdE1: Str(g, "LSL(")
          | StdAo: Str(g, "LSH(")
          | StdCp: Str(g, "ASH(")
          END;
          Expression(g, x);
          ExpressionBraced(g, g.sep1Sp, n, ")")
        END Lsl;

        PROCEDURE Asr(VAR g: Generator; x, n: Ast.Expression);
        BEGIN
          CASE g.opt.std OF
            StdO7,
            StdE1: Str(g, "ASR(");
            Expression(g, x);
            ExpressionBraced(g, g.sep1Sp, n, ")")
          | StdAo,
            StdCp: Str(g, "ASH(");
            Expression(g, x);
            Str(g, g.sep1Sp);
            ExpressionBraced(g, "-(", n, "))")
          END;
        END Asr;

        PROCEDURE Len(VAR g: Generator; arr: Ast.Expression);
        BEGIN
          CASE g.opt.std OF
            StdO7,
            StdCp: ExpressionBraced(g, "LEN(", arr, ")")
          | StdE1: ExpressionBraced(g, "ДЛИНА(", arr, ")")
          | StdAo: ExpressionBraced(g, "INTEGER(LEN(", arr, "))")
          END
        END Len;

        PROCEDURE Flt(VAR g: Generator; int: Ast.Expression);
        BEGIN
          CASE g.opt.std OF
            StdO7: ExpressionBraced(g, "FLT(", int, ")")
          | StdE1: Factor(g, int); Str(g, ":Д")
          | StdAo: ExpressionBraced(g, "REAL(", int, ")")
          | StdCp: ExpressionBraced(g, "(0.0 + ", int, ")")
          END
        END Flt;

        PROCEDURE Chrf(VAR g: Generator; int: Ast.Expression);
        BEGIN
          CASE g.opt.std OF
            StdO7,
            StdAo: ExpressionBraced(g, "CHR(", int, ")")
          | StdE1: Factor(g, int); Str(g, ":Л")
          | StdCp: ExpressionBraced(g, "SHORT(CHR(", int, "))")
          END
        END Chrf;

        PROCEDURE Floor(VAR g: Generator; r: Ast.Expression);
        BEGIN
          CASE g.opt.std OF
            StdO7,
            StdAo: ExpressionBraced(g, "FLOOR(", r, ")")
          | StdE1:
            Factor(g, r);
            Str(g, ":Ц")
          | StdCp: ExpressionBraced(g, "SHORT(ENTIER(", r, "))")
          END
        END Floor;

        PROCEDURE Ror(VAR g: Generator; v, n: Ast.Expression);
        BEGIN
          CASE g.opt.std OF
            StdO7,
            StdE1,
            StdAo: Str(g, "ROR(")
          | StdCp: Str(g, "O_7.Ror(")
          END;
          Expression(g, v);
          ExpressionBraced(g, g.sep1Sp, n, ")")
        END Ror;

        PROCEDURE Inc(VAR g: Generator; v: Ast.Expression; p: Ast.Parameter);
        BEGIN
          Expression(g, v);
          IF p = NIL THEN
            Str(g, " += 1")
          ELSE
            Str(g, " += ");
            Expression(g, p.expr)
          END
        END Inc;

        PROCEDURE Dec(VAR g: Generator; v: Ast.Expression; p: Ast.Parameter);
        BEGIN
          Expression(g, v);
          IF p = NIL THEN
            Str(g, " -= 1")
          ELSE
            Str(g, " -= ");
            Expression(g, p.expr)
          END
        END Dec;

      BEGIN
        e1 := call.params.expr;
        p2 := call.params.next;
        CASE call.designator.decl.id OF
          SpecIdent.Abs  :
          IF g.opt.std = StdE1 THEN
            One(g, "АБС", e1, {})
          ELSE
            One(g, "ABS", e1, {})
          END
        | SpecIdent.Odd  :
          IF g.opt.std = StdE1 THEN
            ExpressionBraced(g, "(", e1, " % 2 = 1)")
          ELSE
            One(g, "ODD", e1, {})
          END
        | SpecIdent.Len  : Len(g, e1)
        | SpecIdent.Lsl  : Lsl(g, e1, p2.expr)
        | SpecIdent.Asr  : Asr(g, e1, p2.expr)
        | SpecIdent.Ror  : Ror(g, e1, p2.expr)
        | SpecIdent.Floor: Floor(g, e1)
        | SpecIdent.Flt  : Flt(g, e1)
        | SpecIdent.Ord  : Ord(g, e1)
        | SpecIdent.Chr  : Chrf(g, e1)
        | SpecIdent.Inc  :
          IF g.opt.std = StdE1 THEN
            Inc(g, e1, p2)
          ELSE
            MayTwo(g, "INC", e1, {Ast.ParamIn, Ast.ParamOut}, p2)
          END
        | SpecIdent.Dec  :
          IF g.opt.std = StdE1 THEN
            Dec(g, e1, p2)
          ELSE
            MayTwo(g, "DEC", e1, {Ast.ParamIn, Ast.ParamOut}, p2)
          END
        | SpecIdent.Incl :
          IF g.opt.std = StdE1 THEN
            Expression(g, e1);
            ExpressionBraced(g, " += {", p2.expr, "}")
          ELSE
            Two(g, "INCL", e1, {Ast.ParamIn, Ast.ParamOut}, p2.expr)
          END
        | SpecIdent.Excl :
          IF g.opt.std = StdE1 THEN
            Expression(g, e1);
            ExpressionBraced(g, " -= {", p2.expr, "}")
          ELSE
            Two(g, "EXCL", e1, {Ast.ParamIn, Ast.ParamOut}, p2.expr)
          END
        | SpecIdent.New  :
          IF g.opt.std = StdE1 THEN
            One(g, "ВЫДЕЛИ", e1, {Ast.ParamOut})
          ELSE
            One(g, "NEW", e1, {Ast.ParamOut})
          END
        | SpecIdent.Assert: Assert(g, e1)
        | SpecIdent.Pack : Pack(g, e1, p2.expr)
        | SpecIdent.Unpk : Unpack(g, e1, p2.expr)
        END
      END Predefined;

      PROCEDURE ActualParam(VAR g: Generator; VAR p: Ast.Parameter;
                            VAR fp: Ast.Declaration);
      BEGIN
        Access(g, fp(Ast.FormalParam), FALSE);
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
          isNum := (g.opt.std = StdE1) & (p.expr.id IN Ast.Numbers);
          ActualParam(g, p, fp);
          WHILE p # NIL DO
            IF isNum THEN
              Str(g, " , ")
            ELSE
              Str(g, g.sep1Sp)
            END;
            isNum := (g.opt.std = StdE1) & (p.expr.id IN Ast.Numbers);
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

      PROCEDURE InfixOpt(VAR g: Generator; rel: Ast.ExprRelation; oper, oper1a: ARRAY OF CHAR);
      BEGIN
        IF g.opt.std = StdE1 THEN
          ExpressionInfix(g, rel.exprs[0], oper1a, rel.exprs[1])
        ELSE
          ExpressionInfix(g, rel.exprs[0], oper, rel.exprs[1])
        END
      END InfixOpt;

    BEGIN
      CASE rel.relation OF
        Ast.Equal        : Infix(g, rel, " = " )
      | Ast.Inequal      : InfixOpt(g, rel, " # ", " ≠ ")
      | Ast.Less         : Infix(g, rel, " < " )
      | Ast.LessEqual    : InfixOpt(g, rel, " <= ", " ≤ ")
      | Ast.Greater      : Infix(g, rel, " > " )
      | Ast.GreaterEqual : InfixOpt(g, rel, " >= ", " ≥ ")
      | Ast.In           : InfixOpt(g, rel, " IN ", " ∈ ")
      END
    END Relation;

    PROCEDURE Sum(VAR g: Generator; sum: Ast.ExprSum);
    BEGIN
      IF ~(sum.add IN {Ast.Minus, Ast.Plus}) THEN
        ;
      ELSIF (g.opt.std = StdE1) & ~(sum.type.id IN Ast.Sets) & ~(sum.term.id IN Ast.Numbers) THEN
        IF sum.add = Ast.Minus THEN
          Str(g, "0 - ")
        ELSE
          Str(g, "0 + ")
        END
      ELSE
        IF sum.add = Ast.Minus THEN
          Str(g, "-")
        ELSE
          Str(g, "+")
        END
      END;
      Expression(g, sum.term);
      sum := sum.next;
      WHILE sum # NIL DO
        IF sum.add = Ast.Minus THEN
          Str(g, " - ")
        ELSIF sum.add = Ast.Plus THEN
          IF (g.opt.std = StdE1) & (sum.type.id IN Ast.Sets) THEN
            Str(g, " ∪ ")
          ELSE
            Str(g, " + ")
          END
        ELSIF sum.add = Ast.Or THEN
          IF g.opt.std = StdE1 THEN
            Str(g, "  ∨  ")
          ELSE
            Str(g, " OR ")
          END
        END;
        Expression(g, sum.term);
        sum := sum.next
      END
    END Sum;

    PROCEDURE Term(VAR g: Generator; term: Ast.ExprTerm);
    BEGIN
      REPEAT
        Expression(g, term.factor);
        IF g.opt.std = StdE1 THEN
          CASE term.mult OF
            Ast.Mult :
              IF (g.opt.std = StdE1) & (term.type.id IN Ast.Sets) THEN
                Str(g, " ∩ ")
              ELSE
                Str(g, " ⋅ ")
              END
          | Ast.Rdiv :
              IF (g.opt.std = StdE1) & (term.type.id IN Ast.Sets) THEN
                Str(g, " ∆ ")
              ELSE
                Str(g, " / ")
              END
          | Ast.Div  : Str(g, " ÷ " )
          | Ast.Mod  : Str(g, " |÷| " )
          | Ast.And  : Str(g, " ∧ ")
          END
        ELSE
          CASE term.mult OF
            Ast.Mult : Str(g, " * "  )
          | Ast.Rdiv : Str(g, " / "  )
          | Ast.Div  : Str(g, " DIV ")
          | Ast.Mod  : Str(g, " MOD ")
          | Ast.And  : Str(g, " & "  )
          END
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
      IF g.opt.std = StdE1 THEN
        IF   e.bool
        THEN Str(g, "ДА")
        ELSE Str(g, "НЕТ")
        END
      ELSE
        IF   e.bool
        THEN Str(g, "TRUE")
        ELSE Str(g, "FALSE")
        END
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
        Decimal(g, int)
      ELSE
        Str(g, "(-");
        Decimal(g, -int);
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
    VAR braceOpen, braceClose, empty: ARRAY 4 OF CHAR;
      PROCEDURE Val(VAR g: Generator; set: Ast.ExprSet; braceOpen, braceClose, empty: ARRAY OF CHAR);
        PROCEDURE Item(VAR g: Generator; set: Ast.ExprSet);
        BEGIN
          IF set.exprs[1] = NIL THEN
            Expression(g, set.exprs[0])
          ELSE
            ExpressionInfix(g, set.exprs[0], " .. ", set.exprs[1])
          END
        END Item;
      BEGIN
        IF (set.next # NIL) OR (set.exprs[0] # NIL) THEN
          Str(g, braceOpen);
          Item(g, set);
          set := set.next;
          WHILE set # NIL DO
            Str(g, g.sep1Sp);
            Item(g, set);
            set := set.next
          END;
          Str(g, braceClose)
        ELSE
          Str(g, empty)
        END
      END Val;
    BEGIN
      empty := "";
      IF g.opt.std = StdE1 THEN
        braceOpen := "{"; braceClose := "}";
        empty := "∅"
      ELSE
        IF g.opt.plantUml THEN
          braceOpen := "("; braceClose := ")"
        ELSE
          braceOpen := "{"; braceClose := "}"
        END;
        empty[0] := braceOpen[0];
        empty[1] := braceClose[0];
        empty[2] := 0X
      END;
      CASE g.opt.std OF
        StdO7,
        StdE1,
        StdCp: Val(g, set, braceOpen, braceClose, empty)
      | StdAo: Str(g, "SET32("); Val(g, set, braceOpen, braceClose, empty); Str(g, ")")
      END
    END Set;

    PROCEDURE IsExtension(VAR g: Generator; is: Ast.ExprIsExtension);
    BEGIN
      Designator(g, is.designator);
      IF g.opt.std = StdE1 THEN
        (*Str(g, " Е "*)
        Str(g, " ЭТО ")
      ELSE
        Str(g, " IS ")
      END;
      GlobalName(g, is.extType)
    END IsExtension;

    PROCEDURE NegateTo(VAR g: Generator; e: Ast.Expression);
    VAR e0: Ast.Expression; r: Ast.ExprRelation; is: Ast.ExprIsExtension; not: ARRAY 3 OF CHAR;
    BEGIN
      IF g.opt.std = StdE1 THEN
        not := "¬";
        IF e.id = Ast.IdBraces THEN
          e0 := e(Ast.ExprBraces).expr;
          IF e0.id = Ast.IdRelation THEN
            r := e0(Ast.ExprRelation);
            IF r.relation = Ast.In THEN
              not := "";
              ExpressionBraced(g, "(", r.exprs[0], " ∉ ");
              Expression(g, r.exprs[1]);
              Chr(g, ")")
            END
          ELSIF e0.id = Ast.IdIsExtension THEN
            not := "";
            is := e0(Ast.ExprIsExtension);
            Chr(g, "(");
            Designator(g, is.designator);
            Str(g, " НЕ ");
            GlobalName(g, is.extType);
            Chr(g, ")")
          END
        END
      ELSE
        not := "~"
      END;
      IF not # "" THEN
        Str(g, not);
        Expression(g, e)
      END
    END NegateTo;
  BEGIN
    CASE expr.id OF
      Ast.IdInteger:
      ExprInt(g, expr(Ast.ExprInteger).int)
    | Ast.IdLongInt:
      ExprLongInt(g, expr(Ast.ExprInteger).int)
    | Ast.IdBoolean:
      Boolean(g, expr(Ast.ExprBoolean))
    | Ast.IdReal, Ast.IdReal32:
      IF  ~Strings.IsDefined(expr(Ast.ExprReal).str) THEN
        Text.Real(g, expr(Ast.ExprReal).real)
      ELSIF g.opt.std = StdE1 THEN
        Text.RealString(g, expr(Ast.ExprReal).str)
      ELSE
        Text.String(g, expr(Ast.ExprReal).str)
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
      IF (g.opt.std IN {StdO7, StdE1})
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
      NegateTo(g, expr(Ast.ExprNegate).expr);
    | Ast.IdBraces:
      ExpressionBraced(g, "(", expr(Ast.ExprBraces).expr, ")")
    | Ast.IdPointer:
      IF g.opt.std = StdE1 THEN
        Str(g, "()")
      ELSE
        Str(g, "NIL")
      END
    | Ast.IdIsExtension:
      IsExtension(g, expr(Ast.ExprIsExtension))
    END
  END Expression;

  PROCEDURE MarkedName(VAR g: Generator; d: Ast.Declaration; str: ARRAY OF CHAR);
  VAR m: BOOLEAN;
    PROCEDURE PtrMark(r: Ast.Record): BOOLEAN;
    RETURN
      (r.pointer # NIL) & r.pointer.mark
    END PtrMark;
  BEGIN
    m := d.mark & ~g.opt.declaration;
    IF g.opt.std = StdE1 THEN
      IF (d.id = Ast.IdRecord) & (m OR PtrMark(d(Ast.Record))) THEN
        Chr(g, "*")
      ELSIF m THEN
        Chr(g, "+")
      ELSIF (d.id # Ast.IdProc) & ((d.up = NIL) OR (d.up.d.up = NIL)) THEN
        Chr(g, " ")
      END;
      Name(g, d)
    ELSE
      Name(g, d);
      IF m THEN Chr(g, "*") END
    END;
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
        SepLn(g)
      END
    END Const;
  BEGIN
    IF g.opt.plantUml THEN
      Str(g, ":")
    ELSIF g.opt.std = StdE1 THEN
      Text.Ln(g)
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
    ELSIF g.opt.std = StdE1 THEN
      Ln(g)
    ELSE
      LnClose(g)
    END
  END Consts;

  PROCEDURE ProcParams(VAR g: Generator; proc: Ast.ProcType; opt: SET);
  VAR p: Ast.Declaration;

    PROCEDURE SimilarParams(VAR g: Generator; VAR p: Ast.Declaration);
    VAR fp: Ast.FormalParam;

      PROCEDURE Similar(p1, p2: Ast.FormalParam): BOOLEAN;
      RETURN
        (p1.access = p2.access) & (p1.type = p2.type)
      END Similar;

    BEGIN
      fp := p(Ast.FormalParam);
      Access(g, fp, TRUE);
      Name(g, p);
      p := p.next;
      WHILE (p # NIL) & Similar(fp, p(Ast.FormalParam)) DO
        Str(g, g.sep1Sp);
        IF g.opt.std = StdE1 THEN
          Access1a(g, fp.access)
        END;
        Name(g, p);
        p := p.next
      END;
      Str(g, ": ");
      type(g, fp.type)
    END SimilarParams;
  BEGIN
    IF proc.params # NIL THEN
      IF (g.opt.std # StdE1) OR ~(ForTypes IN opt) THEN
        Chr(g, "(")
      END;
      p := proc.params;
      SimilarParams(g, p);
      WHILE p # NIL DO
        Str(g, "; ");
        SimilarParams(g, p)
      END;
      IF proc.type = NIL THEN
        Chr(g, ")")
      ELSE
        IF g.opt.std # StdE1 THEN
          Str(g, "): ")
        ELSIF g.retVar # NIL THEN
          Str(g, ") → ");
          Name(g, g.retVar);
          Str(g, ": ")
        ELSE
          Str(g, ") → ответ: ")
        END;
        type(g, proc.type)
      END
    ELSIF proc.type # NIL THEN
      IF g.opt.std # StdE1 THEN
        Str(g, "(): ")
      ELSE
        IF ForTypes IN opt THEN
          Str(g, ") ")
        END;
        IF g.retVar # NIL THEN
          Str(g, " → ");
          Name(g, g.retVar);
          Str(g, ": ")
        ELSE
          Str(g, " → ответ: ")
        END
      END;
      type(g, proc.type)
    ELSIF g.opt.std = StdE1 THEN
      Str(g, "()")
    END
  END ProcParams;

  PROCEDURE VarList(VAR g: Generator; v: Ast.Declaration);

    PROCEDURE ListSameType(VAR g: Generator; VAR v: Ast.Declaration; sep: ARRAY OF CHAR);
    VAR p: Ast.Declaration;

      PROCEDURE Next(g: Generator; VAR v: Ast.Declaration): BOOLEAN;
      BEGIN
        REPEAT
          v := v.next
        UNTIL (v = NIL) OR (v.id # Ast.IdVar) OR v.mark
           OR ~g.opt.declaration & (v # g.retVar)
      RETURN
        (v # NIL) & (v.id = Ast.IdVar)
      END Next;

    BEGIN
      MarkedName(g, v, "");
      p := v;
      WHILE Next(g, v) & (p.type = v.type) DO
        Str(g, g.sep1Sp);
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
        SepLn(g)
      END;
      ListSameType(g, v, ": ")
    END
  END VarList;

  PROCEDURE Type(VAR g: Generator; typ: Ast.Type; forDecl: BOOLEAN);

    PROCEDURE Array(VAR g: Generator; typ: Ast.Type): Ast.Type;
    VAR a1: BOOLEAN; expr: PROCEDURE(VAR g: Generator; e: Ast.Expression);
    BEGIN
      a1 := g.opt.std = StdE1;
      IF typ(Ast.Array).count = NIL THEN
        REPEAT
          ASSERT(typ(Ast.Array).count = NIL);
          IF a1 THEN
            Str(g, "×")
          ELSE
            Str(g, "ARRAY OF ")
          END;
          typ := typ.type
        UNTIL typ.id # Ast.IdArray
      ELSE
        IF ~a1 THEN
          Str(g, "ARRAY ")
        END;
        IF g.opt.std = StdE1 THEN
          expr := Factor
        ELSE
          expr := Expression
        END;
        expr(g, typ(Ast.Array).count);
        typ := typ.type;
        WHILE (typ.id = Ast.IdArray) & ~Strings.IsDefined(typ.name) DO
          IF a1 THEN
            Str(g, " × ")
          ELSE
            Str(g, g.sep1Sp)
          END;
          expr(g, typ(Ast.Array).count);
          typ := typ.type
        END;
        IF a1 THEN
          Str(g, " × ")
        ELSE
          Str(g, " OF ")
        END
      END
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
          Ln(g);
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

      v := rec.vars;
      IF g.opt.declaration THEN  FirstMarked(v)  END;

      IF g.opt.std = StdE1 THEN
        IF base[i] = NIL THEN
          Str(g, "(;")
        ELSE
          Str(g, "(: ");
          GlobalName(g, base[i]);
          Chr(g, ";")
        END;
        IF v # NIL THEN
          Text.IndentOpen(g); Ln(g);
          VarList(g, v); LnClose(g)
        END;
        Chr(g, ")")
      ELSE
        IF base[i] = NIL THEN
          Str(g, "RECORD")
        ELSE
          Str(g, "RECORD(");
          GlobalName(g, base[i]);
          Chr(g, ")")
        END;
        IF g.opt.declaration & ExportedFromBase(g, base, i) & (v # NIL) THEN
          StrLn(g, ";")
        END;
        IF v # NIL THEN
          Text.IndentOpen(g); Ln(g);
          VarList(g, v); LnClose(g)
        ELSE
          Chr(g, " ")
        END;
        Str(g, "END")
      END
    END Record;

  BEGIN
    IF ~forDecl
      & Strings.IsDefined(typ.name)
      & (typ.mark OR ~g.opt.declaration)
    THEN
      IF (g.opt.std = StdE1) & (typ.id = Ast.IdPointer) THEN
        Str(g, "(↑)")
      END;
      GlobalName(g, typ)
    ELSE
      CASE typ.id OF
        Ast.IdInteger:
        CASE g.opt.std OF
          StdO7,
          StdCp: Str(g, "INTEGER")
        | StdAo: Str(g, "SIGNED32")
        | StdE1: Str(g, "Ц")
        END
      | Ast.IdSet:
        CASE g.opt.std OF
          StdO7,
          StdCp: Str(g, "SET")
        | StdAo: Str(g, "SET32")
        | StdE1: Str(g, "М")
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
        IF g.opt.std = StdE1 THEN
          Str(g, "П")
        ELSE
          Str(g, "BOOLEAN")
        END
      | Ast.IdByte:
        CASE g.opt.std OF
          StdO7,
          StdCp: Str(g, "BYTE")
        | StdAo: Str(g, "UNSIGNED8")
        | StdE1: Str(g, "Б")
        END
      | Ast.IdChar:
        CASE g.opt.std OF
          StdO7,
          StdAo: Str(g, "CHAR")
        | StdCp: Str(g, "SHORTCHAR")
        | StdE1: Str(g, "Л")
        END
      | Ast.IdReal:
        CASE g.opt.std OF
          StdO7,
          StdCp: Str(g, "REAL")
        | StdAo: Str(g, "FLOAT64")
        | StdE1: Str(g, "Д")
        END
      | Ast.IdReal32:
        CASE g.opt.std OF
          StdCp: Str(g, "SHORTREAL")
        | StdAo: Str(g, "FLOAT32")
        END
      | Ast.IdRecord:
        Record(g, typ(Ast.Record))
      | Ast.IdProcType, Ast.IdFuncType:
        IF g.opt.std = StdE1 THEN
          Str(g, "ВИД(; ")
        ELSE
          Str(g, "PROCEDURE")
        END;
        ProcParams(g, typ(Ast.ProcType), {ForTypes})
      | Ast.IdPointer:
        IF g.opt.std # StdE1 THEN
          Str(g, "POINTER TO ")
        ELSIF ~forDecl THEN
          Str(g, "(↑)")
        END;
        Type(g, typ.type, FALSE)
      | Ast.IdArray:
        IF g.opt.std = StdE1 THEN
          Chr(g, "[");
          Type(g, Array(g, typ), FALSE);
          Chr(g, "]")
        ELSE
          Type(g, Array(g, typ), FALSE)
        END
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
        SepLn(g)
      END;
    END Decl;
  BEGIN
    IF g.opt.plantUml THEN
      Str(g, ":")
    ELSIF g.opt.std = StdE1 THEN
      Ln(g)
    ELSE
      StrOpen(g, "TYPE")
    END;
    WHILE (d # NIL) & (d.id < 32) & (d.id IN Ast.DeclarableTypes) DO
      IF d.mark OR ~g.opt.declaration THEN
        Decl(g, d(Ast.Type))
      END;
      d := d.next
    END;
    IF g.opt.plantUml THEN
      StrLn(g, ";")
    ELSIF g.opt.std = StdE1 THEN
      Ln(g)
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
    ELSIF g.opt.std = StdE1 THEN
      VarList(g, d); Chr(g, g.sep); Ln(g); Ln(g)
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
                   begin, then, thenNeg, elsif, elsifThen, else, end: ARRAY OF CHAR);

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
        Elsif(g, wi, elsifThen, thenNeg, elsif);
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
          Wr(g, wi, "if (", ") then (yes)", ") then (no)", "elseif (", ") then (yes)", "else", "endif")
        ELSIF g.opt.std = StdE1 THEN
          Wr(g, wi, "??  ", "  (", "", ":?  ", ";", "::", ")")
        ELSE
          Wr(g, wi, "IF ", " THEN", "", "ELSIF ", " THEN", "ELSE", "END")
        END
      ELSIF (wi.elsif = NIL) OR g.opt.multibranchWhile THEN
        IF g.opt.plantUml THEN
          Wr(g, wi, "while (", ") is (yes)", ") is (no)", "", "", "", "endwhile")
        ELSIF g.opt.std = StdE1 THEN
          Wr(g, wi, "(↺)?  ", "  (", "", ":?    ", ";", "", ")")
        ELSE
          Wr(g, wi, "WHILE ", " DO", "", "ELSIF ", " DO", "", "END")
        END
      ELSE
        IF g.opt.plantUml THEN
          StrOpen(g, "repeat");
          Wr(g, wi, "if (", ") then (yes)", ") then (no)", "elseif (", ") then (yes)", "", "");
          StrOpen(g, "else");
          StrLn(g, ":stop;");
          Text.StrClose(g, "endif");
          LnStrClose(g, "repeat while(continue?) not (stop) ")
        ELSE
          Wr(g, wi, "LOOP IF ", " THEN", "", "ELSIF ", " THEN", "", "ELSE EXIT END END")
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
      ELSIF g.opt.std = StdE1 THEN
        StrOpen(g, "(↺) (");
        statements(g, st.stats);
        LnStrClose(g, ") ДО ");
        Expression(g, st.expr)
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
      IF g.opt.std = StdE1 THEN
        Str(g, "(↺) ");
        GlobalName(g, st.var);
        ExpressionBraced(g, g.assign, st.expr, " .. ");
      ELSE
        Str(g, "FOR ");
        GlobalName(g, st.var);
        ExpressionBraced(g, g.assign, st.expr, " TO ");
      END;
      Expression(g, st.to);
      IF st.by # 1 THEN
        IF g.opt.std = StdE1 THEN
          Str(g, " ПО ")
        ELSE
          Str(g, " BY ")
        END;
        Decimal(g, st.by)
      END;
      IF g.opt.plantUml THEN
        StrOpen(g, ")");
        statements(g, st.stats);
        LnStrClose(g, "endwhile (end)")
      ELSIF g.opt.std = StdE1 THEN
        StrOpen(g, " (");
        statements(g, st.stats);
        LnStrClose(g, ")")
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
        Str(g, "))");
        SepLn(g);

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
        Str(g, g.assign);
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
              Decimal(g, l.value);
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
        IF g.opt.plantUml THEN
          Str(g, "case (")
        ELSIF g.opt.std = StdE1 THEN
          Str(g, "• ")
        END;
        Range(g, r, tid);
        r := r.next;
        WHILE r # NIL DO
          Str(g, g.sep1Sp);
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
      ELSIF g.opt.std = StdE1 THEN
        ExpressionBraced(g, "??? ", st.expr, " (");
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
        IF ~g.opt.plantUml & (g.opt.std # StdE1) THEN Str(g, "| ") END;
        CaseElement(g, elem, st.expr.type.id);
        elem := elem.next
      END;
      IF g.opt.plantUml THEN
        Str(g, "endswitch")
      ELSE
        IF g.opt.caseAbort & ~(g.opt.std IN {StdO7, StdE1}) THEN
          (* TODO *)
          StrLn(g, "ELSE HALT(1)")
        END;
        IF g.opt.std = StdE1 THEN
          IF st.else = NIL THEN
            StrLn(g, ":: 🚫")
          END;
          Chr(g, ")")
        ELSE
          Str(g, "END")
        END
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
          SepLn(g)
        END;
        Statement(g, stat);
        stat := stat.next
      END
    ELSIF g.opt.std = StdE1 THEN
      Chr(g, g.sep)
    END
  END Statements;

  PROCEDURE Procedure(VAR g: Generator; p: Ast.Procedure);
  VAR retVar: Ast.Declaration; startLine: INTEGER;

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
          IF stats & (g.retVar = NIL) THEN
            IF g.opt.std = StdO7 THEN
              Ln(g)
            ELSE
              SepLn(g)
            END
          END;
          IF g.opt.std # StdE1 THEN
            ExpressionBraced(g, "RETURN ", ret, "")
          ELSE
            IF g.retVar = NIL THEN
              ExpressionBraced(g, "ответ ← ", ret, "")
            END
          END
        END
      END
    END Return;

    PROCEDURE TryGetVar(e: Ast.Expression): Ast.Declaration;
    VAR d: Ast.Designator; v: Ast.Declaration;
    BEGIN
      v := NIL;
      IF (e # NIL) & (e.id = Ast.IdDesignator) THEN
        d := e(Ast.Designator);
        IF ~Ast.IsGlobal(d.decl) & ~(d.decl IS Ast.FormalParam) THEN
          v := d.decl
        END
      END
    RETURN
      v
    END TryGetVar;

    PROCEDURE End(VAR g: Generator; p: Ast.Procedure; startLine: INTEGER);
    BEGIN
      IF g.opt.plantUml THEN
        Ln(g);
        IF p.return = NIL THEN
          StrLn(g, "stop")
        ELSE
          StrLn(g, "kill")
        END;
        StrLnClose(g, "end group")
      ELSIF g.opt.std # StdE1 THEN
        LnStrClose(g, "END ");
        Name(g, p); SepLn(g)
      ELSIF (g.lines - startLine >= 16) OR ~Ast.IsGlobal(p) THEN
        LnStrClose(g, ") ");
        Name(g, p); SepLn(g)
      ELSE
        LnStrClose(g, ")."); Ln(g)
      END
    END End;

  BEGIN
    startLine := g.lines;
    IF g.opt.plantUml THEN
      Str(g, "group PROCEDURE ");
      MarkedName(g, p, "");
      ProcParams(g, p.header, {});
      Ln(g);
      Comment(g, p.comment, FALSE)
    ELSE
      Comment(g, p.comment, TRUE);
      IF g.opt.std = StdE1 THEN
        Str(g, "== ")
      ELSE
        Str(g, "PROCEDURE ")
      END;
      MarkedName(g, p, "");
      IF g.opt.std = StdE1 THEN
        retVar := g.retVar;
        g.retVar := TryGetVar(p.return);
        ProcParams(g, p.header, {});
        StrOpen(g, " (")
      ELSE
        ProcParams(g, p.header, {});
        SepLn(g)
      END
    END;
    IF ~g.opt.declaration THEN
      declarations(g, p);
      IF g.opt.plantUml THEN
        Text.IndentOpen(g);
        IF p.stats # NIL THEN
          StrLn(g, "start")
        END
      ELSIF g.opt.std = StdE1 THEN
        ;
      ELSIF (p.stats # NIL)
         OR (g.opt.std # StdO7) & (p.return # NIL)
      THEN
        StrOpen(g, "BEGIN")
      ELSE
        Text.IndentOpen(g)
      END;
      IF (p.stats # NIL) OR (p.return = NIL) THEN
        Statements(g, p.stats)
      END;
      Return(g, p.stats # NIL, p.return);
      End(g, p, startLine);
      IF g.opt.std = StdE1 THEN  g.retVar := retVar  END;
    END
  END Procedure;

  PROCEDURE Declarations(VAR g: Generator; ds: Ast.Declarations);
  VAR c, t, v, p: Ast.Declaration; decl, mod: BOOLEAN;

    PROCEDURE Ctv(VAR g: Generator; c, t, v: Ast.Declaration);
    BEGIN
      IF c # NIL THEN
        Consts(g, c)
      END;

      IF t # NIL THEN
        Types(g, t)
      END;

      IF v # NIL THEN
        Vars(g, v)
      END
    END Ctv;

    PROCEDURE Procs(VAR g: Generator; p: Ast.Declaration);
    BEGIN
      IF p # NIL THEN
        REPEAT
          IF p.mark OR ~g.opt.declaration THEN
            EmptyLines(g, p);
            Procedure(g, p(Ast.Procedure))
          END;
          p := p.next
        UNTIL p = NIL;
        Ln(g)
      END
    END Procs;

  BEGIN
    c := ds.consts;
    t := ds.types;
    v := ds.vars;
    IF (v # NIL) & (v = g.retVar) THEN
      v := v.next;
      IF (v # NIL) & (v.id # Ast.IdVar) THEN
        v := NIL
      END
    END;
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
    (*
    ELSIF decl OR (p # NIL) THEN
      Ln(g)
    *)
    END;

    mod := ds.up = NIL;
    IF ~mod & (g.opt.std = StdE1) THEN
      Procs(g, p);
      Ctv(g, c, t, v)
    ELSE
      Ctv(g, c, t, v);
      IF decl & g.opt.plantUml THEN
        StrLn(g, "kill");
        StrLn(g, "}")
      END;
      IF mod THEN
        Procs(g, p)
      ELSE
        Text.IndentOpen(g);
          Procs(g, p);
        Text.IndentClose(g)
      END
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
    ELSIF g.opt.std = StdE1 THEN
      Str(g, "==== ");
      Name(g, module);
      StrOpen(g, " (");
    ELSE
      IF    g.opt.declaration
      THEN  Str(g, "DEFINITION ")
      ELSE  Str(g, "MODULE ")
      END;
      Name(g, module);
      SepLn(g);
      Text.IndentOpen(g)
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
    IF (module.stats # NIL) & ~g.opt.declaration THEN
      IF g.opt.plantUml THEN
        StrOpen(g, "group initialization");
        StrLn(g, "start");
        Statements(g, module.stats);
        Ln(g);
        StrLn(g, "stop");
        StrLnClose(g, "end group")
      ELSIF g.opt.std = StdE1 THEN
        StrOpen(g, "== (");
        Statements(g, module.stats);
        Ln(g);
        StrLnClose(g, ").");
        Ln(g)
      ELSE
        Text.IndentClose(g);
        StrOpen(g, "BEGIN");
        Statements(g, module.stats); Ln(g)
      END
    END;

    IF g.opt.plantUml THEN
      StrLn(g, "}");
      StrLn(g, "@enduml")
    ELSIF g.opt.std = StdE1 THEN
      Text.StrClose(g, ") ");
      Name(g, module);
      StrLn(g, ".");
      StrLn(g, "====")
    ELSE
      Text.StrClose(g, "END ");
      Name(g, module);
      StrLn(g, ".")
    END
  END Generate;

BEGIN
  declarations := Declarations;
  statements   := Statements;
  expression   := Expression;
  type         := ReferenceToType;

  Strings.Undef(stdRetName)
END GeneratorOberon.

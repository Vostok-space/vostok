(*  Generator of C-code by Oberon-07 abstract syntax tree
 *  Copyright (C) 2016  ComdivByZero
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
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
MODULE GeneratorC;

IMPORT
	V,
	Ast,
	Strings := StringStore,
	Scanner,
	Stream := VDataStream,
	Text := TextGenerator,
	Utf8,
	Log,
	Limits,
	TranLim := TranslatorLimits;

CONST
	Interface = 1;
	Implementation = 0;

	IsoC90* = 0;
	IsoC99* = 1;

	VarInitUndefined*   = 0;
	VarInitZero*        = 1;
	VarInitNo*          = 2;

	MemManagerNoFree*   = 0;
	MemManagerCounter*  = 1;
	MemManagerGC*       = 2;

TYPE
	Options* = POINTER TO RECORD(V.Base)
		std*: INTEGER;
		gnu*, plan9*,
		procLocal*,
		checkIndex*,
		checkArith*,
		caseAbort*,
		comment*: BOOLEAN;

		varInit*,
		memManager*: INTEGER;

		main: BOOLEAN;

		index: INTEGER;
		records, recordLast: V.PBase; (* для генерации тэгов *)

		lastSelectorDereference: BOOLEAN
	END;

	Generator* = RECORD(Text.Out)
		module: Ast.Module;

		localDeep: INTEGER;(* Вложенность процедур *)

		fixedLen: INTEGER;

		interface: BOOLEAN;
		opt: Options;

		expressionSemicolon: BOOLEAN
	END;

	MemoryOut = RECORD(Stream.Out)
		mem: ARRAY 2 OF RECORD
				buf: ARRAY 4096 OF CHAR;
				len: INTEGER
			END;
		invert: BOOLEAN
	END;

	PMemoryOut = POINTER TO MemoryOut;

	MOut = RECORD
		g: ARRAY 2 OF Generator;
		opt: Options
	END;

	Selectors = RECORD
		des: Ast.Designator;
		decl: Ast.Declaration;
		list: ARRAY TranLim.MaxSelectors OF Ast.Selector;
		i: INTEGER
	END;

VAR
	type: PROCEDURE(VAR gen: Generator; type: Ast.Type;
	                typeDecl, sameType: BOOLEAN);
	declarator: PROCEDURE(VAR gen: Generator; decl: Ast.Declaration;
	                      typeDecl, sameType, global: BOOLEAN);
	declarations: PROCEDURE(VAR out: MOut; ds: Ast.Declarations);
	statements: PROCEDURE(VAR gen: Generator; stats: Ast.Statement);
	expression: PROCEDURE(VAR gen: Generator; expr: Ast.Expression);

PROCEDURE MemoryWrite(VAR out: MemoryOut; buf: ARRAY OF CHAR; ofs, count: INTEGER);
VAR ret: BOOLEAN;
BEGIN
	ret := Strings.CopyChars(
		out.mem[ORD(out.invert)].buf, out.mem[ORD(out.invert)].len,
		buf, ofs, ofs + count
	);
	ASSERT(ret)
END MemoryWrite;

PROCEDURE MemWrite(VAR out: Stream.Out;
                   buf: ARRAY OF CHAR; ofs, count: INTEGER): INTEGER;
BEGIN
	MemoryWrite(out(MemoryOut), buf, ofs, count)
	RETURN count
END MemWrite;

PROCEDURE MemoryOutInit(VAR mo: MemoryOut);
BEGIN
	Stream.InitOut(mo, MemWrite);
	mo.mem[0].len := 0;
	mo.mem[1].len := 0;
	mo.invert := FALSE
END MemoryOutInit;

PROCEDURE MemWriteInvert(VAR mo: MemoryOut);
VAR inv: INTEGER;
	ret: BOOLEAN;
BEGIN
	inv := ORD(mo.invert);
	IF mo.mem[inv].len = 0 THEN
		mo.invert := ~mo.invert
	ELSE
		ret := Strings.CopyChars(mo.mem[inv].buf, mo.mem[inv].len,
		                         mo.mem[1 - inv].buf, 0, mo.mem[1 - inv].len);
		ASSERT(ret);
		mo.mem[1 - inv].len := 0
	END
END MemWriteInvert;

PROCEDURE MemWriteDirect(VAR gen: Generator; VAR mo: MemoryOut);
VAR inv: INTEGER;
BEGIN
	inv := ORD(mo.invert);
	ASSERT(mo.mem[1 - inv].len = 0);
	Text.Data(gen, mo.mem[inv].buf, 0, mo.mem[inv].len);
	mo.mem[inv].len := 0
END MemWriteDirect;

PROCEDURE IsNameOccupied(n: Strings.String): BOOLEAN;

	PROCEDURE Eq(name: Strings.String; str: ARRAY OF CHAR): BOOLEAN;
		RETURN Strings.IsEqualToString(name, str)
	END Eq;

	RETURN Eq(n, "auto")
	    OR Eq(n, "break")
	    OR Eq(n, "case")
	    OR Eq(n, "char")
	    OR Eq(n, "const")
	    OR Eq(n, "continue")
	    OR Eq(n, "default")
	    OR Eq(n, "do")
	    OR Eq(n, "double")
	    OR Eq(n, "else")
	    OR Eq(n, "enum")
	    OR Eq(n, "extern")
	    OR Eq(n, "float")
	    OR Eq(n, "for")
	    OR Eq(n, "goto")
	    OR Eq(n, "if")
	    OR Eq(n, "inline")
	    OR Eq(n, "int")
	    OR Eq(n, "long")
	    OR Eq(n, "register")
	    OR Eq(n, "return")
	    OR Eq(n, "short")
	    OR Eq(n, "signed")
	    OR Eq(n, "sizeof")
	    OR Eq(n, "static")
	    OR Eq(n, "struct")
	    OR Eq(n, "switch")
	    OR Eq(n, "typedef")
	    OR Eq(n, "union")
	    OR Eq(n, "unsigned")
	    OR Eq(n, "void")
	    OR Eq(n, "volatile")
	    OR Eq(n, "while")

	    OR Eq(n, "asm")
	    OR Eq(n, "typeof")

	    OR Eq(n, "abort")
	    OR Eq(n, "assert")
	    OR Eq(n, "bool")
	    OR Eq(n, "calloc")
	    OR Eq(n, "free")
	    OR Eq(n, "main")
	    OR Eq(n, "malloc")
	    OR Eq(n, "memcmp")
	    OR Eq(n, "memcpy")
	    OR Eq(n, "memset")
	    OR Eq(n, "NULL")
	    OR Eq(n, "strcmp")
	    OR Eq(n, "strcpy")
	    OR Eq(n, "realloc")

	    OR Eq(n, "array")
	    OR Eq(n, "catch")
	    OR Eq(n, "class")
	    OR Eq(n, "decltype")
	    OR Eq(n, "delegate")
	    OR Eq(n, "delete")
	    OR Eq(n, "deprecated")
	    OR Eq(n, "dllexport")
	    OR Eq(n, "dllimport")
	    OR Eq(n, "dllexport")
	    OR Eq(n, "event")
	    OR Eq(n, "explicit")
	    OR Eq(n, "finally")
	    OR Eq(n, "each")
	    OR Eq(n, "in")
	    OR Eq(n, "friend")
	    OR Eq(n, "gcnew")
	    OR Eq(n, "generic")
	    OR Eq(n, "initonly")
	    OR Eq(n, "interface")
	    OR Eq(n, "literal")
	    OR Eq(n, "mutable")
	    OR Eq(n, "naked")
	    OR Eq(n, "namespace")
	    OR Eq(n, "new")
	    OR Eq(n, "noinline")
	    OR Eq(n, "noreturn")
	    OR Eq(n, "nothrow")
	    OR Eq(n, "novtable")
	    OR Eq(n, "nullptr")
	    OR Eq(n, "operator")
	    OR Eq(n, "private")
	    OR Eq(n, "property")
	    OR Eq(n, "protected")
	    OR Eq(n, "public")
	    OR Eq(n, "ref")
	    OR Eq(n, "safecast")
	    OR Eq(n, "sealed")
	    OR Eq(n, "selectany")
	    OR Eq(n, "super")
	    OR Eq(n, "template")
	    OR Eq(n, "this")
	    OR Eq(n, "thread")
	    OR Eq(n, "throw")
	    OR Eq(n, "try")
	    OR Eq(n, "typeid")
	    OR Eq(n, "typename")
	    OR Eq(n, "uuid")
	    OR Eq(n, "value")
	    OR Eq(n, "virtual")

	    OR Eq(n, "abstract")
	    OR Eq(n, "arguments")
	    OR Eq(n, "boolean")
	    OR Eq(n, "byte")
	    OR Eq(n, "debugger")
	    OR Eq(n, "eval")
	    OR Eq(n, "export")
	    OR Eq(n, "extends")
	    OR Eq(n, "final")
	    OR Eq(n, "function")
	    OR Eq(n, "implements")
	    OR Eq(n, "import")
	    OR Eq(n, "instanceof")
	    OR Eq(n, "interface")
	    OR Eq(n, "let")
	    OR Eq(n, "native")
	    OR Eq(n, "null")
	    OR Eq(n, "package")
	    OR Eq(n, "private")
	    OR Eq(n, "protected")
	    OR Eq(n, "synchronized")
	    OR Eq(n, "throws")
	    OR Eq(n, "transient")
	    OR Eq(n, "var")

	    OR Eq(n, "func")

	    OR Eq(n, "o7c")
	    OR Eq(n, "O7C")
	    OR Eq(n, "initialized")
	    OR Eq(n, "init")
END IsNameOccupied;

PROCEDURE Name(VAR gen: Generator; decl: Ast.Declaration);
VAR up: Ast.Declarations;
BEGIN
	IF (decl IS Ast.Type) & (decl.up # decl.module) & (decl.up # NIL)
	OR ~gen.opt.procLocal & (decl IS Ast.Procedure)
	THEN
		up := decl.up;
		WHILE ~(up IS Ast.Module) DO
			Text.String(gen, up.name);
			Text.Str(gen, "_");
			up := up.up
		END
	END;
	Text.String(gen, decl.name);
	IF decl IS Ast.Const THEN
		Text.Str(gen, "_cnst")
	ELSIF IsNameOccupied(decl.name) THEN
		Text.Str(gen, "_")
	END
END Name;

PROCEDURE GlobalName(VAR gen: Generator; decl: Ast.Declaration);
BEGIN
	IF decl.mark OR (decl.module # NIL) & (gen.module # decl.module) THEN
		ASSERT(decl.module # NIL);
		Text.String(gen, decl.module.name);
		Text.Str(gen, "_");
		Text.String(gen, decl.name);
		IF decl IS Ast.Const THEN
			Text.Str(gen, "_cnst")
		END
	ELSE
		Name(gen, decl)
	END
END GlobalName;

PROCEDURE Import(VAR gen: Generator; decl: Ast.Declaration);
BEGIN
	Text.Str(gen, "#include "); Text.Str(gen, Utf8.DQuote);
	Text.String(gen, decl.module.name);
	Text.Str(gen, ".h");
	Text.StrLn(gen, Utf8.DQuote)
END Import;

PROCEDURE Factor(VAR gen: Generator; expr: Ast.Expression);
BEGIN
	IF expr IS Ast.Factor THEN
		expression(gen, expr)
	ELSE
		Text.Str(gen, "(");
		expression(gen, expr);
		Text.Str(gen, ")")
	END
END Factor;

PROCEDURE CheckStructName(VAR gen: Generator; rec: Ast.Record): BOOLEAN;
VAR anon: ARRAY TranLim.MaxLenName * 2 + 3 OF CHAR;
	i, j, l: INTEGER;
	ret: BOOLEAN;
BEGIN
	IF ~Strings.IsDefined(rec.name) THEN
		IF (rec.pointer # NIL) & Strings.IsDefined(rec.pointer.name) THEN
			l := 0;
			ASSERT(rec.module # NIL);
			rec.mark := TRUE;
			Strings.CopyToChars(anon, l, rec.pointer.name);

			anon[l] := "_";
			anon[l + 1] := "s";
			anon[l + 2] := Utf8.Null;
			Ast.PutChars(rec.pointer.module, rec.name, anon, 0, l + 2)
		ELSE
			l := 0;
			Strings.CopyToChars(anon, l, rec.module.name);
			anon[l] := "_";
			INC(l);

			Log.StrLn("Record");

			ret := Strings.CopyChars(anon, l, "anon_0000", 0, 9);
			ASSERT(ret);
			ASSERT((gen.opt.index >= 0) & (gen.opt.index < 10000));
			i := gen.opt.index;
			(*Log.Int(i); Log.Ln;*)
			j := l - 1;
			WHILE i > 0 DO
				anon[j] := CHR(ORD("0") + i MOD 10);
				i := i DIV 10;
				DEC(j)
			END;
			INC(gen.opt.index);
			Ast.PutChars(rec.module, rec.name, anon, 0, l)
		END
	END
	RETURN Strings.IsDefined(rec.name)
END CheckStructName;

PROCEDURE ArrayDeclLen(VAR gen: Generator; type: Ast.Type;
                       decl: Ast.Declaration; sel: Ast.Selector);
VAR i: INTEGER;
BEGIN
	IF type(Ast.Array).count # NIL THEN
		expression(gen, type(Ast.Array).count)
	ELSE
		GlobalName(gen, decl);
		Text.Str(gen, "_len");
		i := -1;
		WHILE sel # NIL DO
			INC(i);
			sel := sel.next
		END;
		Text.Int(gen, i)
	END
END ArrayDeclLen;

PROCEDURE ArrayLen(VAR gen: Generator; e: Ast.Expression);
VAR i: INTEGER;
	des: Ast.Designator;
	t: Ast.Type;
BEGIN
	IF e.type(Ast.Array).count # NIL THEN
		expression(gen, e.type(Ast.Array).count)
	ELSE
		des := e(Ast.Designator);
		GlobalName(gen, des.decl);
		Text.Str(gen, "_len");
		i := 0;
		t := des.type;
		WHILE t # e.type DO
			INC(i);
			t := t.type
		END;
		Text.Int(gen, i)
	END
END ArrayLen;

PROCEDURE Selector(VAR gen: Generator; sels: Selectors; i: INTEGER;
                   VAR typ: Ast.Type; desType: Ast.Type);
VAR sel: Ast.Selector;
	ret: BOOLEAN;

	PROCEDURE Record(VAR gen: Generator; VAR type: Ast.Type; VAR sel: Ast.Selector);
	VAR var: Ast.Declaration;
		up: Ast.Record;

		PROCEDURE Search(ds: Ast.Record; d: Ast.Declaration): BOOLEAN;
		VAR c: Ast.Declaration;
		BEGIN
			c := ds.vars;
			WHILE (c # NIL) & (c # d) DO
				c := c.next
			END
			RETURN c # NIL
		END Search;
	BEGIN
		var := sel(Ast.SelRecord).var;
		IF type IS Ast.Pointer THEN
			up := type(Ast.Pointer).type(Ast.Record)
		ELSE
			up := type(Ast.Record)
		END;

		IF type.id = Ast.IdPointer THEN
			Text.Str(gen, "->")
		ELSE
			Text.Str(gen, ".")
		END;

		IF ~gen.opt.plan9 THEN
			WHILE (up # NIL) & ~Search(up, var) DO
				up := up.base;
				Text.Str(gen, "_.")
			END
		END;

		Name(gen, var);

		type := var.type
	END Record;

	PROCEDURE Declarator(VAR gen: Generator; decl: Ast.Declaration);
	VAR type: Ast.Type;
	BEGIN
		type := decl.type;
		IF	(decl IS Ast.FormalParam) & (
				decl(Ast.FormalParam).isVar & (type.id # Ast.IdArray)
				OR
				(type.id = Ast.IdRecord)
			)
		THEN
			Text.Str(gen, "(*");
			GlobalName(gen, decl);
			Text.Str(gen, ")")
		ELSE
			GlobalName(gen, decl)
		END
	END Declarator;

	PROCEDURE Array(VAR gen: Generator; VAR type: Ast.Type;
	                VAR sel: Ast.Selector; decl: Ast.Declaration;
	                isDesignatorArray: BOOLEAN);
	VAR i: INTEGER;

		PROCEDURE Mult(VAR gen: Generator;
		               decl: Ast.Declaration; j: INTEGER; t: Ast.Type);
		BEGIN
			WHILE (t # NIL) & (t IS Ast.Array) DO
				Text.Str(gen, " * ");
				Name(gen, decl);
				Text.Str(gen, "_len");
				Text.Int(gen, j);
				INC(j);
				t := t.type
			END
		END Mult;
	BEGIN
		IF isDesignatorArray THEN
			Text.Str(gen, " + ")
		ELSE
			Text.Str(gen, "[")
		END;
		IF (type.type.id # Ast.IdArray) OR (type(Ast.Array).count # NIL)
		THEN
			IF gen.opt.checkIndex
			 & (   (sel(Ast.SelArray).index.value = NIL)
			    OR (type(Ast.Array).count = NIL)
			     & (sel(Ast.SelArray).index.value(Ast.ExprInteger).int # 0)
			   )
			THEN
				Text.Str(gen, "o7c_ind(");
				ArrayDeclLen(gen, type, decl, sel);
				Text.Str(gen, ", ");
				expression(gen, sel(Ast.SelArray).index);
				Text.Str(gen, ")")
			ELSE
				expression(gen, sel(Ast.SelArray).index)
			END;
			type := type.type;
			sel := sel.next;
			WHILE (sel # NIL) & (sel IS Ast.SelArray) DO
				IF gen.opt.checkIndex
				 & (   (sel(Ast.SelArray).index.value = NIL)
				    OR (type(Ast.Array).count = NIL)
				     & (sel(Ast.SelArray).index.value(Ast.ExprInteger).int # 0)
				   )
				THEN
					Text.Str(gen, "][o7c_ind(");
					ArrayDeclLen(gen, type, decl, sel);
					Text.Str(gen, ", ");
					expression(gen, sel(Ast.SelArray).index);
					Text.Str(gen, ")")
				ELSE
					Text.Str(gen, "][");
					expression(gen, sel(Ast.SelArray).index)
				END;
				sel := sel.next;
				type := type.type
			END
		ELSE
			i := 0;
			WHILE (sel.next # NIL) & (sel.next IS Ast.SelArray) DO
				Factor(gen, sel(Ast.SelArray).index);
				type := type.type;
				Mult(gen, decl, i + 1, type);
				sel := sel.next;
				INC(i);
				Text.Str(gen, " + ")
			END;
			Factor(gen, sel(Ast.SelArray).index);
			Mult(gen, decl, i + 1, type.type)
		END;
		IF ~isDesignatorArray THEN
			Text.Str(gen, "]")
		END
	END Array;
BEGIN
	IF i < 0 THEN
		Declarator(gen, sels.decl)
	ELSE
		sel := sels.list[i];
		DEC(i);
		IF sel IS Ast.SelRecord THEN
			Selector(gen, sels, i, typ, desType);
			Record(gen, typ, sel)
		ELSIF sel IS Ast.SelArray THEN
			Selector(gen, sels, i, typ, desType);
			Array(gen, typ, sel, sels.decl,
			      (desType.id = Ast.IdArray) & (desType(Ast.Array).count = NIL))
		ELSIF sel IS Ast.SelPointer THEN
			IF (sel.next = NIL) OR ~(sel.next IS Ast.SelRecord) THEN
				Text.Str(gen, "(*");
				Selector(gen, sels, i, typ, desType);
				Text.Str(gen, ")")
			ELSE
				Selector(gen, sels, i, typ, desType)
			END
		ELSIF sel IS Ast.SelGuard THEN
			IF sel(Ast.SelGuard).type.id = Ast.IdPointer THEN
				Text.Str(gen, "O7C_GUARD(");
				ret := CheckStructName(gen, sel(Ast.SelGuard).type.type(Ast.Record));
				ASSERT(ret);
				GlobalName(gen, sel(Ast.SelGuard).type.type)
			ELSE
				Text.Str(gen, "O7C_GUARD_R(");
				GlobalName(gen, sel(Ast.SelGuard).type)
			END;
			Text.Str(gen, ", &");
			Selector(gen, sels, i, typ, desType);
			IF sel(Ast.SelGuard).type.id = Ast.IdPointer THEN
				Text.Str(gen, ")")
			ELSE
				Text.Str(gen, ", ");
				GlobalName(gen, sels.decl);
				Text.Str(gen, "_tag)")
			END;
			typ := sel(Ast.SelGuard).type
		ELSE
			ASSERT(FALSE)
		END
	END
END Selector;

PROCEDURE Designator(VAR gen: Generator; des: Ast.Designator);
VAR
	sels: Selectors;
	typ: Ast.Type;

	PROCEDURE Put(VAR sels: Selectors; sel: Ast.Selector);
	BEGIN
		sels.i := -1;
		WHILE sel # NIL DO
			INC(sels.i);
			sels.list[sels.i] := sel;
			IF sel IS Ast.SelArray THEN
				WHILE (sel # NIL) & (sel IS Ast.SelArray) DO
					sel := sel.next
				END
			ELSE
				sel := sel.next
			END
		END
	END Put;

BEGIN
	Put(sels, des.sel);
	typ := des.decl.type;
	sels.des := des;
	sels.decl := des.decl;(* TODO *)
	gen.opt.lastSelectorDereference := (sels.i > 0)
	                                 & (sels.list[sels.i] IS Ast.SelPointer);
	Selector(gen, sels, sels.i, typ, des.type)
END Designator;

PROCEDURE CheckExpr(VAR gen: Generator; e: Ast.Expression);
BEGIN
	IF (gen.opt.varInit = VarInitUndefined)
	 & (e IS Ast.Designator)
	 & (e.type.id = Ast.IdBoolean)
	 & (e.value = NIL)
	THEN
		Text.Str(gen, "o7c_bl(");
		expression(gen, e);
		Text.Str(gen, ")")
	ELSE
		expression(gen, e)
	END
END CheckExpr;

PROCEDURE Expression(VAR gen: Generator; expr: Ast.Expression);

	PROCEDURE Call(VAR gen: Generator; call: Ast.ExprCall);
	VAR p: Ast.Parameter;
		fp: Ast.Declaration;

		PROCEDURE Predefined(VAR gen: Generator; call: Ast.ExprCall);
		VAR e1: Ast.Expression;
			p2: Ast.Parameter;

			PROCEDURE Shift(VAR gen: Generator; shift: ARRAY OF CHAR;
			                ps: Ast.Parameter);
			BEGIN
				Text.Str(gen, "(int)((unsigned)");
				Factor(gen, ps.expr);
				Text.Str(gen, shift);
				Factor(gen, ps.next.expr);
				Text.Str(gen, ")")
			END Shift;

			PROCEDURE Len(VAR gen: Generator; des: Ast.Designator);
			VAR sel: Ast.Selector;
				i: INTEGER;
			BEGIN
				IF  (des.decl.type.id # Ast.IdArray)
				OR ~(des.decl IS Ast.FormalParam) THEN
					Text.Str(gen, "sizeof(");
					Designator(gen, des);
					Text.Str(gen, ") / sizeof (");
					Designator(gen, des);
					Text.Str(gen, "[0])")
				ELSIF des.type(Ast.Array).count # NIL THEN
					Expression(gen, des.type(Ast.Array).count)
				ELSE
					GlobalName(gen, des.decl);
					Text.Str(gen, "_len");
					i := 0;
					sel := des.sel;
					WHILE sel # NIL DO
						INC(i);
						sel := sel.next
					END;
					Text.Int(gen, i)
				END
			END Len;

			PROCEDURE New(VAR gen: Generator; e: Ast.Expression);
			VAR ret: BOOLEAN;
			BEGIN
				Text.Str(gen, "O7C_NEW(&");
				Expression(gen, e);
				Text.Str(gen, ", ");
				ret := CheckStructName(gen, e.type.type(Ast.Record));
				ASSERT(ret);
				GlobalName(gen, e.type.type);
				Text.Str(gen, "_tag)")
			END New;

			PROCEDURE Ord(VAR gen: Generator; e: Ast.Expression);
			BEGIN
				Text.Str(gen, "(int)");
				Factor(gen, e)
			END Ord;

			PROCEDURE Inc(VAR gen: Generator;
			              e1: Ast.Expression; p2: Ast.Parameter);
			BEGIN
				Expression(gen, e1);
				IF gen.opt.checkArith THEN
					Text.Str(gen, " = o7c_add(");
					Expression(gen, e1);
					IF p2 = NIL THEN
						Text.Str(gen, ", 1)")
					ELSE
						Text.Str(gen, ", ");
						Expression(gen, p2.expr);
						Text.Str(gen, ")")
					END
				ELSIF p2 = NIL THEN
					Text.Str(gen, "++")
				ELSE
					Text.Str(gen, " += ");
					Expression(gen, p2.expr)
				END
			END Inc;

			PROCEDURE Dec(VAR gen: Generator;
			              e1: Ast.Expression; p2: Ast.Parameter);
			BEGIN
				Expression(gen, e1);
				IF gen.opt.checkArith THEN
					Text.Str(gen, " = o7c_sub(");
					Expression(gen, e1);
					IF p2 = NIL THEN
						Text.Str(gen, ", 1)")
					ELSE
						Text.Str(gen, ", ");
						Expression(gen, p2.expr);
						Text.Str(gen, ")")
					END
				ELSIF p2 = NIL THEN
					Text.Str(gen, "--")
				ELSE
					Text.Str(gen, " -= ");
					Expression(gen, p2.expr)
				END
			END Dec;
		BEGIN
			e1 := call.params.expr;
			p2 := call.params.next;
			CASE call.designator.decl.id OF
			  Scanner.Abs:
				IF call.type.id = Ast.IdInteger THEN
					Text.Str(gen, "abs(")
				ELSE
					Text.Str(gen, "fabs(")
				END;
				Expression(gen, e1);
				Text.Str(gen, ")")
			| Scanner.Odd:
				Text.Str(gen, "(");
				Factor(gen, e1);
				Text.Str(gen, " % 2 == 1)")
			| Scanner.Len:
				Len(gen, e1(Ast.Designator))
			| Scanner.Lsl:
				Shift(gen, " << ", call.params)
			| Scanner.Asr:
				Shift(gen, " >> ", call.params)
			| Scanner.Ror:
				Text.Str(gen, "o7_ror(");
				Expression(gen, e1);
				Text.Str(gen, ", ");
				Expression(gen, p2.expr);
				Text.Str(gen, ")")
			| Scanner.Floor:
				Text.Str(gen, "(int)");
				Factor(gen, e1)
			| Scanner.Flt:
				Text.Str(gen, "(double)");
				Factor(gen, e1)
			| Scanner.Ord:
				Ord(gen, e1)
			| Scanner.Chr:
				IF gen.opt.checkArith & (e1.value = NIL) THEN
					Text.Str(gen, "o7c_chr(");
					Factor(gen, e1);
					Text.Str(gen, ")")
				ELSE
					Text.Str(gen, "(char unsigned)");
					Factor(gen, e1)
				END
			| Scanner.Inc:
				Inc(gen, e1, p2)
			| Scanner.Dec:
				Dec(gen, e1, p2)
			| Scanner.Incl:
				Expression(gen, e1);
				Text.Str(gen, " |= 1u << ");
				Factor(gen, p2.expr)
			| Scanner.Excl:
				Expression(gen, e1);
				Text.Str(gen, " &= ~(1u << ");
				Factor(gen, p2.expr);
				Text.Str(gen, ")")
			| Scanner.New:
				New(gen, e1)
			| Scanner.Assert:
				Text.Str(gen, "assert(");
				CheckExpr(gen, e1);
				Text.Str(gen, ")")
			| Scanner.Pack:
				Expression(gen, e1);
				Text.Str(gen, " *= 1 << ");
				Expression(gen, p2.expr)
			| Scanner.Unpk:
				Expression(gen, e1);
				Text.Str(gen, " /= 1 << ");
				Expression(gen, p2.expr)
			END
		END Predefined;

		PROCEDURE ActualParam(VAR gen: Generator; VAR p: Ast.Parameter;
		                      VAR fp: Ast.Declaration);
		VAR t: Ast.Type;
			i, j, dist: INTEGER;

			PROCEDURE ArrayDeep(t: Ast.Type): INTEGER;
			VAR d: INTEGER;
			BEGIN
				d := -1;
				REPEAT
					t := t.type;
					INC(d)
				UNTIL t = NIL
				RETURN d
			END ArrayDeep;
		BEGIN
			t := fp.type;
			IF (t.id = Ast.IdByte) & (p.expr.type.id = Ast.IdInteger)
			 & gen.opt.checkArith & (p.expr.value = NIL)
			THEN
				Text.Str(gen, "o7c_byte(");
				Expression(gen, p.expr);
				Text.Str(gen, ")")
			ELSE
				dist := p.distance;
				IF (fp(Ast.FormalParam).isVar & ~(t IS Ast.Array))
				OR (t IS Ast.Record)
				OR (t.id = Ast.IdPointer) & (dist > 0) & ~gen.opt.plan9
				THEN
					Text.Str(gen, "&")
				END;
				gen.opt.lastSelectorDereference := FALSE;
				Expression(gen, p.expr);

				IF (dist > 0) & ~gen.opt.plan9 THEN
					IF t.id = Ast.IdPointer THEN
						DEC(dist);
						Text.Str(gen, "->_")
					END;
					WHILE dist > 0 DO
						DEC(dist);
						Text.Str(gen, "._")
					END
				END;

				t := p.expr.type;
				IF t.id = Ast.IdRecord THEN
					IF gen.opt.lastSelectorDereference THEN
						Text.Str(gen, ", NULL")
					ELSE
						Text.Str(gen, ", ");
						IF (p.expr(Ast.Designator).decl IS Ast.FormalParam)
						 & (p.expr(Ast.Designator).sel = NIL)
						THEN
							Name(gen, p.expr(Ast.Designator).decl)
						ELSE
							GlobalName(gen, t)
						END;
						Text.Str(gen, "_tag")
					END
				ELSIF fp.type.id # Ast.IdChar THEN
					i := -1;
					WHILE (t.id = Ast.IdArray)
					    & (fp.type(Ast.Array).count = NIL)
					DO
						IF t(Ast.Array).count # NIL THEN
							Text.Str(gen, ", ");
							Expression(gen, t(Ast.Array).count)
						ELSE
							IF i = -1 THEN
								i := ArrayDeep(p.expr(Ast.Designator).decl.type)
								   - ArrayDeep(fp.type);
								IF ~(p.expr(Ast.Designator).decl IS Ast.FormalParam)
								THEN
									FOR j := 0 TO i - 1 DO
										Text.Str(gen, "[0]")
									END
								END
							END;
							Text.Str(gen, ", ");
							Name(gen, p.expr(Ast.Designator).decl);
							Text.Str(gen, "_len");
							Text.Int(gen, i)
						END;
						INC(i);
						t := t.type
					END
				END
			END;

			p := p.next;
			fp := fp.next
		END ActualParam;
	BEGIN
		IF call.designator.decl IS Ast.PredefinedProcedure THEN
			Predefined(gen, call)
		ELSE
			Designator(gen, call.designator);
			Text.Str(gen, "(");
			p  := call.params;
			fp := call.designator.type(Ast.ProcType).params;
			IF p # NIL THEN
				ActualParam(gen, p, fp);
				WHILE p # NIL DO
					Text.Str(gen, ", ");
					ActualParam(gen, p, fp)
				END
			END;
			Text.Str(gen, ")")
		END
	END Call;

	PROCEDURE Relation(VAR gen: Generator; rel: Ast.ExprRelation);

		PROCEDURE Simple(VAR gen: Generator; rel: Ast.ExprRelation;
		                 str: ARRAY OF CHAR);

			PROCEDURE Expr(VAR gen: Generator; e: Ast.Expression; dist: INTEGER);
			VAR brace: BOOLEAN;
			BEGIN
				brace := (e.type.id = Ast.IdSet)
				      & ~(e IS Ast.Factor);
				IF brace THEN
					Text.Str(gen, "(")
				ELSIF (dist > 0) & (e.type.id = Ast.IdPointer) & ~gen.opt.plan9 THEN
					Text.Str(gen, "&")
				END;
				Expression(gen, e);
				IF (dist > 0) & ~gen.opt.plan9 THEN
					IF e.type.id = Ast.IdPointer THEN
						DEC(dist);
						Text.Str(gen, "->_")
					END;
					WHILE dist > 0 DO
						DEC(dist);
						Text.Str(gen, "._")
					END
				END;
				IF brace THEN
					Text.Str(gen, ")")
				END
			END Expr;

			PROCEDURE Len(VAR gen: Generator; e: Ast.Expression);
			VAR des: Ast.Designator;
			BEGIN
				IF e.type(Ast.Array).count # NIL THEN
					Expression(gen, e.type(Ast.Array).count)
				ELSE
					des := e(Ast.Designator);
					ArrayDeclLen(gen, des.type, des.decl, des.sel)
				END
			END Len;
		BEGIN
			IF (rel.exprs[0].type.id = Ast.IdArray)
			 & (  (rel.exprs[0].value = NIL)
			   OR ~rel.exprs[0].value(Ast.ExprString).asChar
			   )
			THEN
				Text.Str(gen, "o7c_strcmp(");

				Expr(gen, rel.exprs[0], -rel.distance);
				Text.Str(gen, ", ");
				Len(gen, rel.exprs[0]);

				Text.Str(gen, ", ");

				Expr(gen, rel.exprs[1], rel.distance);
				Text.Str(gen, ", ");
				Len(gen, rel.exprs[1]);

				Text.Str(gen, ")");
				Text.Str(gen, str);
				Text.Str(gen, "0")
			ELSIF (gen.opt.varInit = VarInitUndefined)
			    & (rel.value = NIL)
			    & (rel.exprs[0].type.id = Ast.IdInteger) (* TODO *)
			THEN
				Text.Str(gen, "o7c_cmp(");
				Expr(gen, rel.exprs[0], -rel.distance);
				Text.Str(gen, ", ");
				Expr(gen, rel.exprs[1], rel.distance);
				Text.Str(gen, ")");
				Text.Str(gen, str);
				Text.Str(gen, " 0")
			ELSE
				Expr(gen, rel.exprs[0], -rel.distance);
				Text.Str(gen, str);
				Expr(gen, rel.exprs[1], rel.distance)
			END
		END Simple;

		PROCEDURE In(VAR gen: Generator; rel: Ast.ExprRelation);
		BEGIN
			IF (rel.exprs[0].value # NIL)
			 & (rel.exprs[0].value(Ast.ExprInteger).int IN {0 .. Limits.SetMax})
			THEN
				Text.Str(gen, "!!(");
				Text.Str(gen, " (1u << ");
				Factor(gen, rel.exprs[0]);
				Text.Str(gen, ") & ");
				Factor(gen, rel.exprs[1]);
				Text.Str(gen, ")")
			ELSE
				IF rel.value # NIL THEN
					Text.Str(gen, "O7C_IN(")
				ELSE
					Text.Str(gen, "o7c_in(")
				END;
				Expression(gen, rel.exprs[0]);
				Text.Str(gen, ", ");
				Expression(gen, rel.exprs[1]);
				Text.Str(gen, ")")
			END
		END In;
	BEGIN
		CASE rel.relation OF
		  Scanner.Equal        : Simple(gen, rel, " == ")
		| Scanner.Inequal      : Simple(gen, rel, " != ")
		| Scanner.Less         : Simple(gen, rel, " < ")
		| Scanner.LessEqual    : Simple(gen, rel, " <= ")
		| Scanner.Greater      : Simple(gen, rel, " > ")
		| Scanner.GreaterEqual : Simple(gen, rel, " >= ")
		| Scanner.In           : In(gen, rel)
		END
	END Relation;

	PROCEDURE Sum(VAR gen: Generator; sum: Ast.ExprSum);
	VAR first: BOOLEAN;
	BEGIN
		first := TRUE;
		REPEAT
			IF sum.add = Scanner.Minus THEN
				IF sum.type.id # Ast.IdSet THEN
					Text.Str(gen, " - ")
				ELSIF first THEN
					Text.Str(gen, " ~")
				ELSE
					Text.Str(gen, " & ~")
				END
			ELSIF sum.add = Scanner.Plus THEN
				IF sum.type.id = Ast.IdSet THEN
					Text.Str(gen, " | ")
				ELSE
					Text.Str(gen, " + ")
				END
			ELSIF sum.add = Scanner.Or THEN
				Text.Str(gen, " || ")
			END;
			CheckExpr(gen, sum.term);
			sum := sum.next;
			first := FALSE
		UNTIL sum = NIL
	END Sum;

	PROCEDURE SumCheck(VAR gen: Generator; sum: Ast.ExprSum);
	VAR arr: ARRAY TranLim.MaxTermsInSum OF Ast.ExprSum;
		i, last: INTEGER;
	BEGIN
		i := -1;
		REPEAT
			INC(i);
			arr[i] := sum;
			sum := sum.next
		UNTIL sum = NIL;
		last := i;
		IF arr[0].type.id = Ast.IdInteger THEN
			WHILE i > 0 DO
				CASE arr[i].add OF
				  Scanner.Minus:
					Text.Str(gen, "o7c_sub(")
				| Scanner.Plus:
					Text.Str(gen, "o7c_add(")
				END;
				DEC(i)
			END
		ELSE ASSERT(arr[0].type.id = Ast.IdReal);
			WHILE i > 0 DO
				CASE arr[i].add OF
				  Scanner.Minus:
					Text.Str(gen, "o7c_fsub(")
				| Scanner.Plus:
					Text.Str(gen, "o7c_fadd(")
				END;
				DEC(i)
			END
		END;
		IF arr[0].add = Scanner.Minus THEN
			IF arr[0].type.id = Ast.IdInteger THEN
				Text.Str(gen, "o7c_sub(0, ")
			ELSE
				Text.Str(gen, "o7c_fsub(0, ")
			END;
			Expression(gen, arr[0].term);
			Text.Str(gen, ")")
		ELSE
			Expression(gen, arr[0].term)
		END;
		WHILE i < last DO
			INC(i);
			Text.Str(gen, ", ");
			Expression(gen, arr[i].term);
			Text.Str(gen, ")")
		END
	END SumCheck;

	PROCEDURE Term(VAR gen: Generator; term: Ast.ExprTerm);
	BEGIN
		REPEAT
			CheckExpr(gen, term.factor);
			CASE term.mult OF
			  Scanner.Asterisk           :
				IF term.type.id = Ast.IdSet THEN
					Text.Str(gen, " & ")
				ELSE
					Text.Str(gen, " * ")
				END
			| Scanner.Slash, Scanner.Div :
				IF term.type.id = Ast.IdSet THEN
					ASSERT(term.mult = Scanner.Slash);
					Text.Str(gen, " ^ ")
				ELSE
					Text.Str(gen, " / ")
				END
			| Scanner.And                : Text.Str(gen, " && ")
			| Scanner.Mod                : Text.Str(gen, " % ")
			END;
			IF term.expr IS Ast.ExprTerm THEN
				term := term.expr(Ast.ExprTerm)
			ELSE
				CheckExpr(gen, term.expr);
				term := NIL
			END
		UNTIL term = NIL
	END Term;

	PROCEDURE TermCheck(VAR gen: Generator; term: Ast.ExprTerm);
	VAR arr: ARRAY TranLim.MaxFactorsInTerm OF Ast.ExprTerm;
		i, last: INTEGER;
	BEGIN
		i := -1;
		arr[0] := term;
		i := 0;
		WHILE term.expr IS Ast.ExprTerm DO
			INC(i);
			term := term.expr(Ast.ExprTerm);
			arr[i] := term
		END;
		last := i;
		IF term.type.id = Ast.IdInteger THEN
			WHILE i >= 0 DO
				CASE arr[i].mult OF
				  Scanner.Asterisk : Text.Str(gen, "o7c_mul(")
				| Scanner.Div      : Text.Str(gen, "o7c_div(")
				| Scanner.Mod      : Text.Str(gen, "o7c_mod(")
				END;
				DEC(i)
			END
		ELSE ASSERT(term.type.id = Ast.IdReal);
			WHILE i >= 0 DO
				CASE arr[i].mult OF
				  Scanner.Asterisk : Text.Str(gen, "o7c_fmul(")
				| Scanner.Slash    : Text.Str(gen, "o7c_fdiv(")
				END;
				DEC(i)
			END
		END;
		Expression(gen, arr[0].factor);
		i := 0;
		WHILE i < last DO
			INC(i);
			Text.Str(gen, ", ");
			Expression(gen, arr[i].factor);
			Text.Str(gen, ")")
		END;
		Text.Str(gen, ", ");
		Expression(gen, arr[last].expr);
		Text.Str(gen, ")")
	END TermCheck;

	PROCEDURE Boolean(VAR gen: Generator; e: Ast.ExprBoolean);
	BEGIN
		IF gen.opt.std = IsoC90 THEN
			IF e.bool
			THEN Text.Str(gen, "(0 < 1)")
			ELSE Text.Str(gen, "(0 > 1)")
			END
		ELSE
			IF e.bool
			THEN Text.Str(gen, "true")
			ELSE Text.Str(gen, "false")
			END
		END
	END Boolean;

	PROCEDURE CString(VAR gen: Generator; e: Ast.ExprString);
	VAR s1: ARRAY 7 OF CHAR;
		s2: ARRAY 4 OF CHAR;
		ch: CHAR;
		w: Strings.String;

		PROCEDURE ToHex(d: INTEGER): CHAR;
		BEGIN
			ASSERT((d >= 0) & (d < 16));
			IF d < 10 THEN
				INC(d, ORD("0"))
			ELSE
				INC(d, ORD("A") - 10)
			END
			RETURN CHR(d)
		END ToHex;
	BEGIN
		w := e.string;
		IF e.asChar THEN
			ch := CHR(e.int);
			IF ch = "'" THEN
				Text.Str(gen, "(char unsigned)'\''")
			ELSIF ch = "\" THEN
				Text.Str(gen, "(char unsigned)'\\'")
			ELSIF (ch >= " ") & (ch <= CHR(127)) THEN
				Text.Str(gen, "(char unsigned)");
				s2[0] := "'";
				s2[1] := ch;
				s2[2] := "'";
				s2[3] := Utf8.Null;
				Text.Str(gen, s2)
			ELSE
				Text.Str(gen, "0x");
				s2[0] := ToHex(e.int DIV 16);
				s2[1] := ToHex(e.int MOD 16);
				s2[2] := "u";
				s2[3] := Utf8.Null;
				Text.Str(gen, s2)
			END
		ELSE
			IF w.block.s[w.ofs] = Utf8.DQuote THEN
				Text.ScreeningString(gen, w)
			ELSE
				s1[0] := Utf8.DQuote;
				s1[1] := "\";
				s1[2] := "x";
				s1[3] := ToHex(e.int DIV 16);
				s1[4] := ToHex(e.int MOD 16);
				s1[5] := Utf8.DQuote;
				s1[6] := Utf8.Null;
				Text.Str(gen, s1)
			END
		END
	END CString;

	PROCEDURE ExprInt(VAR gen: Generator; int: INTEGER);
	BEGIN
		IF int >= 0 THEN
			Text.Int(gen, int)
		ELSE
			Text.Str(gen, "(-");
			Text.Int(gen, -int);
			Text.Str(gen, ")")
		END
	END ExprInt;

	PROCEDURE Set(VAR gen: Generator; set: Ast.ExprSet);
		PROCEDURE Item(VAR gen: Generator; set: Ast.ExprSet);
		BEGIN
			IF set.exprs[0] = NIL THEN
				Text.Str(gen, "0")
			ELSE
				IF set.exprs[1] = NIL THEN
					Text.Str(gen, "(1 << ");
					Factor(gen, set.exprs[0])
				ELSE
					IF (set.exprs[0].value = NIL) OR (set.exprs[1].value = NIL)
					THEN Text.Str(gen, "o7c_set(")
					ELSE Text.Str(gen, "O7C_SET(")
					END;
					Expression(gen, set.exprs[0]);
					Text.Str(gen, ", ");
					Expression(gen, set.exprs[1])
				END;
				Text.Str(gen, ")")
			END
		END Item;
	BEGIN
		IF set.next = NIL THEN
			Item(gen, set)
		ELSE
			Text.Str(gen, "(");
			Item(gen, set);
			REPEAT
				Text.Str(gen, " | ");
				set := set.next;
				Item(gen, set)
			UNTIL set.next = NIL;
			Text.Str(gen, ")")
		END
	END Set;

	PROCEDURE IsExtension(VAR gen: Generator; is: Ast.ExprIsExtension);
	VAR decl: Ast.Declaration;
		extType: Ast.Type;
		ret: BOOLEAN;
	BEGIN
		decl := is.designator.decl;
		extType := is.extType;
		IF is.designator.type.id = Ast.IdPointer THEN
			extType := extType.type;
			ret := CheckStructName(gen, extType(Ast.Record));
			ASSERT(ret);
			Text.Str(gen, "o7c_is(");
			Expression(gen, is.designator);
			Text.Str(gen, ", ")
		ELSE
			Text.Str(gen, "o7c_is_r(");
			GlobalName(gen, decl);
			Text.Str(gen, "_tag, ");
			GlobalName(gen, decl);
			Text.Str(gen, ", ")
		END;
		GlobalName(gen, extType);
		Text.Str(gen, "_tag)")
	END IsExtension;
BEGIN
	CASE expr.id OF
	  Ast.IdInteger:
		ExprInt(gen, expr(Ast.ExprInteger).int)
	| Ast.IdBoolean:
		Boolean(gen, expr(Ast.ExprBoolean))
	| Ast.IdReal:
		IF Strings.IsDefined(expr(Ast.ExprReal).str)
		THEN	Text.String(gen, expr(Ast.ExprReal).str)
		ELSE	Text.Real(gen, expr(Ast.ExprReal).real)
		END
	| Ast.IdString:
		CString(gen, expr(Ast.ExprString))
	| Ast.IdSet:
		Set(gen, expr(Ast.ExprSet))
	| Ast.IdCall:
		Call(gen, expr(Ast.ExprCall))
	| Ast.IdDesignator:
		Log.Str("Expr Designator type.id = ");
		Log.Int(expr.type.id);
		Log.Str(" (expr.value # NIL) = ");
		Log.Int(ORD(expr.value # NIL));
		Log.Ln;
		IF (expr.value # NIL) & (expr.value.id = Ast.IdString)
		THEN	CString(gen, expr.value(Ast.ExprString))
		ELSE	Designator(gen, expr(Ast.Designator))
		END
	| Ast.IdRelation:
		Relation(gen, expr(Ast.ExprRelation))
	| Ast.IdSum:
		IF	  gen.opt.checkArith
			& (expr.type.id IN {Ast.IdInteger, Ast.IdReal})
			& (expr.value = NIL)
		THEN	SumCheck(gen, expr(Ast.ExprSum))
		ELSE	Sum(gen, expr(Ast.ExprSum))
		END
	| Ast.IdTerm:
		IF	  gen.opt.checkArith
			& (expr.type.id IN {Ast.IdInteger, Ast.IdReal})
			& (expr.value = NIL)
		THEN	TermCheck(gen, expr(Ast.ExprTerm))
		ELSE	Term(gen, expr(Ast.ExprTerm))
		END
	| Ast.IdNegate:
		IF expr.type.id = Ast.IdSet
		THEN	Text.Str(gen, "~")
		ELSE	Text.Str(gen, "!")
		END;
		Expression(gen, expr(Ast.ExprNegate).expr)
	| Ast.IdBraces:
		Text.Str(gen, "(");
		Expression(gen, expr(Ast.ExprBraces).expr);
		Text.Str(gen, ")")
	| Ast.IdPointer:
		Text.Str(gen, "NULL")
	| Ast.IdIsExtension:
		IsExtension(gen, expr(Ast.ExprIsExtension))
	END
END Expression;

PROCEDURE Invert(VAR gen: Generator);
BEGIN
	gen.out(PMemoryOut).invert := ~gen.out(PMemoryOut).invert
END Invert;

PROCEDURE ProcHead(VAR gen: Generator; proc: Ast.ProcType);

	PROCEDURE Parameters(VAR gen: Generator; proc: Ast.ProcType);
	VAR p: Ast.Declaration;

		PROCEDURE Par(VAR gen: Generator; fp: Ast.FormalParam);
		VAR t: Ast.Type;
			i: INTEGER;
		BEGIN
			declarator(gen, fp, FALSE, FALSE(*TODO*), FALSE);
			t := fp.type;
			i := 0;
			IF t.id = Ast.IdRecord THEN
				Text.Str(gen, ", o7c_tag_t ");
				Name(gen, fp);
				Text.Str(gen, "_tag")
			ELSE
				WHILE (t.id = Ast.IdArray) & (t(Ast.Array).count = NIL) DO
					Text.Str(gen, ", int ");
					Name(gen, fp);
					Text.Str(gen, "_len");
					Text.Int(gen, i);
					INC(i);
					t := t.type
				END
			END
		END Par;
	BEGIN
		IF proc.params = NIL THEN
			Text.Str(gen, "(void)")
		ELSE
			Text.Str(gen, "(");
			p := proc.params;
			WHILE p # proc.end DO
				Par(gen, p(Ast.FormalParam));
				Text.Str(gen, ", ");
				p := p.next
			END;
			Par(gen, p(Ast.FormalParam));
			Text.Str(gen, ")")
		END
	END Parameters;
BEGIN
	Parameters(gen, proc);
	Invert(gen);
	type(gen, proc.type, FALSE, FALSE(* TODO *));
	MemWriteInvert(gen.out(PMemoryOut)^)
END ProcHead;

PROCEDURE Declarator(VAR gen: Generator; decl: Ast.Declaration;
                     typeDecl, sameType, global: BOOLEAN);
VAR g: Generator;
	mo: PMemoryOut;
BEGIN
	NEW(mo); MemoryOutInit(mo^);
	Text.Init(g, mo);
	Text.SetTabs(g, gen);
	g.module := gen.module;
	g.interface := gen.interface;
	g.opt := gen.opt;

	IF (decl IS Ast.FormalParam) &
	   ((decl(Ast.FormalParam).isVar & ~(decl.type IS Ast.Array)) OR
	   (decl.type IS Ast.Record))
	THEN
		Text.Str(g, "*")
	ELSIF decl IS Ast.Const THEN
		Text.Str(g, "const ")
	END;
	IF global THEN
		GlobalName(g, decl)
	ELSE
		Name(g, decl)
	END;
	IF decl IS Ast.Procedure THEN
		ProcHead(g, decl(Ast.Procedure).header)
	ELSE
		mo.invert := ~mo.invert;
		IF decl IS Ast.Type THEN
			type(g, decl(Ast.Type), typeDecl, FALSE)
		ELSE
			type(g, decl.type, FALSE, sameType)
		END
	END;

	MemWriteDirect(gen, mo^)
END Declarator;

PROCEDURE Type(VAR gen: Generator; type: Ast.Type; typeDecl, sameType: BOOLEAN);

	PROCEDURE Simple(VAR gen: Generator; str: ARRAY OF CHAR);
	BEGIN
		Text.Str(gen, str);
		MemWriteInvert(gen.out(PMemoryOut)^)
	END Simple;

(*	Поскольку в Си нельзя полагаться на стабильность смещения переменных
	в структуре, неплохо бы добавить возможность генерации импортируемых или
	наследуемых структур на массив байт со смещениями.
*)
	PROCEDURE Record(VAR gen: Generator; rec: Ast.Record);
	VAR v: Ast.Declaration;
	BEGIN

		rec.module := gen.module;
		Text.Str(gen, "struct ");
		IF CheckStructName(gen, rec) THEN
			GlobalName(gen, rec)
		END;
		v := rec.vars;
		IF (v = NIL) & (rec.base = NIL) & ~gen.opt.gnu THEN
			Text.Str(gen, " { int nothing; } ")
		ELSE
			Text.StrOpen(gen, " {");

			IF rec.base # NIL THEN
				GlobalName(gen, rec.base);
				IF gen.opt.plan9 THEN
					Text.StrLn(gen, ";")
				ELSE
					Text.StrLn(gen, " _;")
				END
			END;

			WHILE v # NIL DO
				Declarator(gen, v, FALSE, FALSE, FALSE);
				Text.StrLn(gen, ";");
				v := v.next
			END;
			DEC(gen.tabs);
			Text.Str(gen, "} ")
		END;
		MemWriteInvert(gen.out(PMemoryOut)^)
	END Record;

	PROCEDURE Array(VAR gen: Generator; arr: Ast.Array; sameType: BOOLEAN);
	VAR t: Ast.Type;
		i: INTEGER;
	BEGIN
		t := arr.type;
		MemWriteInvert(gen.out(PMemoryOut)^);
		IF arr.count = NIL THEN
			Text.Str(gen, "[/*len0");
			i := 0;
			WHILE t.id = Ast.IdArray DO
				INC(i);
				Text.Str(gen, ", len");
				Text.Int(gen, i);
				t := t.type
			END;
			Text.Str(gen, "*/]")
		ELSE
			Text.Str(gen, "[");
			Expression(gen, arr.count);
			Text.Str(gen, "]")
		END;
		Invert(gen);
		Type(gen, t, FALSE, sameType)
	END Array;
BEGIN
	IF type = NIL THEN
		Text.Str(gen, "void ");
		MemWriteInvert(gen.out(PMemoryOut)^)
	ELSE
		IF ~typeDecl & Strings.IsDefined(type.name) THEN
			IF sameType THEN
				IF (type IS Ast.Pointer) & Strings.IsDefined(type.type.name)
				THEN	Text.Str(gen, "*")
				END
			ELSE
				IF (type IS Ast.Pointer) & Strings.IsDefined(type.type.name)
				THEN
					Text.Str(gen, "struct ");
					GlobalName(gen, type.type); Text.Str(gen, " *")
				ELSIF type IS Ast.Record THEN
					Text.Str(gen, "struct ");
					IF CheckStructName(gen, type(Ast.Record)) THEN
						GlobalName(gen, type); Text.Str(gen, " ")
					END
				ELSE
					GlobalName(gen, type); Text.Str(gen, " ")
				END;
				IF gen.out IS PMemoryOut THEN
					MemWriteInvert(gen.out(PMemoryOut)^)
				END
			END
		ELSIF ~sameType OR (type.id IN {Ast.IdPointer, Ast.IdArray, Ast.IdProcType})
		THEN
			CASE type.id OF
			  Ast.IdInteger:
				Simple(gen, "int ")
			| Ast.IdSet:
				Simple(gen, "unsigned ")
			| Ast.IdBoolean:
				IF (gen.opt.std >= IsoC99)
				 & (gen.opt.varInit # VarInitUndefined)
				THEN	Simple(gen, "bool ")
				ELSE	Simple(gen, "o7c_bool ")
				END
			| Ast.IdByte:
				Simple(gen, "char unsigned ")
			| Ast.IdChar:
				Simple(gen, "o7c_char ")
			| Ast.IdReal:
				Simple(gen, "double ")
			| Ast.IdPointer:
				Text.Str(gen, "*");
				MemWriteInvert(gen.out(PMemoryOut)^);
				Invert(gen);
				Type(gen, type.type, FALSE, sameType)
			| Ast.IdArray:
				Array(gen, type(Ast.Array), sameType)
			| Ast.IdRecord:
				Record(gen, type(Ast.Record))
			| Ast.IdProcType:
				Text.Str(gen, "(*");
				MemWriteInvert(gen.out(PMemoryOut)^);
				Text.Str(gen, ")");
				ProcHead(gen, type(Ast.ProcType))
			END
		END;
		IF gen.out IS PMemoryOut THEN
			MemWriteInvert(gen.out(PMemoryOut)^)
		END
	END
END Type;

PROCEDURE RecordTag(VAR gen: Generator; rec: Ast.Record);
BEGIN
	IF ~rec.mark OR gen.opt.main THEN
		Text.Str(gen, "static o7c_tag_t ")
	ELSIF gen.interface THEN
		Text.Str(gen, "extern o7c_tag_t ")
	ELSE
		Text.Str(gen, "o7c_tag_t ")
	END;
	GlobalName(gen, rec);
	Text.StrLn(gen, "_tag;");
	IF ~rec.mark OR gen.opt.main OR gen.interface THEN
		Text.Ln(gen)
	END
END RecordTag;

PROCEDURE TypeDecl(VAR out: MOut; type: Ast.Type);

	PROCEDURE Typedef(VAR gen: Generator; type: Ast.Type);
	BEGIN
		Text.Str(gen, "typedef ");
		Declarator(gen, type, TRUE, FALSE, TRUE);
		Text.StrLn(gen, ";")
	END Typedef;

	PROCEDURE LinkRecord(opt: Options; rec: Ast.Record);
	BEGIN
		IF opt.records = NIL THEN
			opt.records := rec
		ELSE
			opt.recordLast(Ast.Record).ext := rec
		END;
		opt.recordLast := rec;
		ASSERT(rec.ext = NIL)
	END LinkRecord;
BEGIN
	Typedef(out.g[ORD(type.mark & ~out.opt.main)], type);
	IF (type.id = Ast.IdRecord)
	OR (type.id = Ast.IdPointer) & (type.type.next = NIL)
	THEN
		IF type.id = Ast.IdPointer THEN
			type := type.type
		END;
		type.mark := type.mark
		          OR (type(Ast.Record).pointer # NIL)
		           & (type(Ast.Record).pointer.mark);
		IF type.mark & ~out.opt.main THEN
			RecordTag(out.g[Interface], type(Ast.Record))
		END;
		RecordTag(out.g[Implementation], type(Ast.Record));
		LinkRecord(out.opt, type(Ast.Record))
	END
END TypeDecl;

PROCEDURE Mark(VAR gen: Generator; mark: BOOLEAN);
BEGIN
	IF gen.localDeep = 0 THEN
		IF mark & ~gen.opt.main THEN
			Text.Str(gen, "extern ")
		ELSE
			Text.Str(gen, "static ")
		END
	END
END Mark;

PROCEDURE Comment(VAR gen: Generator; com: Strings.String);
VAR i: Strings.Iterator;
	prev: CHAR;
BEGIN
	IF gen.opt.comment & Strings.GetIter(i, com, 0) THEN
		REPEAT
			prev := i.char
		UNTIL ~Strings.IterNext(i)
		   OR (prev = "/") & (i.char = "*")
		   OR (prev = "*") & (i.char = "/");

		IF i.char = Utf8.Null THEN
			Text.Str(gen, "/*");
			Text.String(gen, com);
			Text.StrLn(gen, "*/")
		END
	END
END Comment;

PROCEDURE Const(VAR gen: Generator; const: Ast.Const);
BEGIN
	Comment(gen, const.comment);
	Text.StrIgnoreIndent(gen, "#");
	Text.Str(gen, "define ");
	GlobalName(gen, const);
	Text.Str(gen, " ");
	IF const.mark & (const.expr # NIL) THEN
		Factor(gen, const.expr.value)
	ELSE
		Factor(gen, const.expr)
	END;
	Text.Ln(gen)
END Const;

PROCEDURE Var(VAR out: MOut; prev, var: Ast.Declaration; last: BOOLEAN);
VAR same, mark: BOOLEAN;

	PROCEDURE InitZero(VAR gen: Generator; var: Ast.Declaration);
	BEGIN
		CASE var.type.id OF
		  Ast.IdInteger, Ast.IdByte, Ast.IdReal, Ast.IdSet:
			Text.Str(gen, " = 0")
		| Ast.IdBoolean:
			Text.Str(gen, " = 0 > 1")
		| Ast.IdChar:
			Text.Str(gen, " = '\0'")
		| Ast.IdPointer, Ast.IdProcType:
			Text.Str(gen, " = NULL")
		| Ast.IdArray:
			Text.Str(gen, " ")
		| Ast.IdRecord:
			Text.Str(gen, " ")
		END
	END InitZero;

	PROCEDURE InitUndef(VAR gen: Generator; var: Ast.Declaration);
	BEGIN
		CASE var.type.id OF
		  Ast.IdInteger:
			Text.Str(gen, " = O7C_INT_UNDEF")
		| Ast.IdBoolean:
			Text.Str(gen, " = O7C_BOOL_UNDEF")
		| Ast.IdByte:
			Text.Str(gen, " = 0")
		| Ast.IdChar:
			Text.Str(gen, " = '\0'")
		| Ast.IdReal:
			Text.Str(gen, " = O7C_DBL_UNDEF")
		| Ast.IdSet:
			Text.Str(gen, " = 0")
		| Ast.IdPointer, Ast.IdProcType:
			Text.Str(gen, " = NULL")
		| Ast.IdArray:
			Text.Str(gen, " ")
		| Ast.IdRecord:
			Text.Str(gen, " ")
		END
	END InitUndef;
BEGIN
	mark := var.mark & ~out.opt.main;
	Comment(out.g[ORD(mark)], var.comment);
	same := (prev # NIL) & (prev.mark = mark) & (prev.type = var.type);
	IF ~same THEN
		IF prev # NIL THEN
			Text.StrLn(out.g[ORD(mark)], ";")
		END;
		Mark(out.g[ORD(mark)], mark)
	ELSE
		Text.Str(out.g[ORD(mark)], ", ")
	END;
	IF mark THEN
		Declarator(out.g[Interface], var, FALSE, same, TRUE);
		IF last THEN
			Text.StrLn(out.g[Interface], ";")
		END;

		IF same THEN
			Text.Str(out.g[Implementation], ", ")
		ELSIF prev # NIL THEN
			Text.StrLn(out.g[Implementation], ";")
		END
	END;

	Declarator(out.g[Implementation], var, FALSE, same, TRUE);

	CASE out.opt.varInit OF
	  VarInitUndefined:
		InitUndef(out.g[Implementation], var)
	| VarInitZero:
		InitZero(out.g[Implementation], var)
	| VarInitNo:
		IF (var.type.id = Ast.IdPointer)
		 & (out.opt.memManager = MemManagerCounter)
		THEN
			Text.Str(out.g[Implementation], " = NULL")
		END
	END;

	IF last THEN
		Text.StrLn(out.g[Implementation], ";")
	END
END Var;

PROCEDURE ExprThenStats(VAR gen: Generator; VAR wi: Ast.WhileIf);
BEGIN
	Expression(gen, wi.expr);
	Text.StrOpen(gen, ") {");
	statements(gen, wi.stats);
	wi := wi.elsif
END ExprThenStats;

PROCEDURE IsCaseElementWithRange(elem: Ast.CaseElement): BOOLEAN;
VAR r: Ast.CaseLabel;
BEGIN
	r := elem.labels;
	WHILE (r # NIL) & (r.right = NIL) DO
		r := r.next
	END
	RETURN r # NIL
END IsCaseElementWithRange;

PROCEDURE Statement(VAR gen: Generator; st: Ast.Statement);

	PROCEDURE WhileIf(VAR gen: Generator; wi: Ast.WhileIf);

		PROCEDURE Elsif(VAR gen: Generator; VAR wi: Ast.WhileIf);
		BEGIN
			WHILE (wi # NIL) & (wi.expr # NIL) DO
				DEC(gen.tabs);
				Text.Str(gen, "} else if (");
				ExprThenStats(gen, wi)
			END
		END Elsif;
	BEGIN
		IF wi IS Ast.If THEN
			Text.Str(gen, "if (");
			ExprThenStats(gen, wi);
			Elsif(gen, wi);
			IF wi # NIL THEN
				DEC(gen.tabs);
				Text.StrOpen(gen, "} else {");
				statements(gen, wi.stats)
			END;
			Text.StrClose(gen, "}")
		ELSIF wi.elsif = NIL THEN
			Text.Str(gen, "while (");
			ExprThenStats(gen, wi);
			Text.StrClose(gen, "}")
		ELSE
			Text.Str(gen, "while (1) if (");
			ExprThenStats(gen, wi);
			Elsif(gen, wi);
			Text.StrClose(gen, "} else break;")
		END
	END WhileIf;

	PROCEDURE Repeat(VAR gen: Generator; st: Ast.Repeat);
	BEGIN
		Text.StrOpen(gen, "do {");
		statements(gen, st.stats);
		DEC(gen.tabs);
		IF st.expr.id = Ast.IdNegate THEN
			Text.Str(gen, "} while (");
			Expression(gen, st.expr(Ast.ExprNegate).expr);
			Text.StrLn(gen, ");")
		ELSE
			Text.Str(gen, "} while (!(");
			Expression(gen, st.expr);
			Text.StrLn(gen, "));")
		END
	END Repeat;

	PROCEDURE For(VAR gen: Generator; st: Ast.For);
		PROCEDURE IsEndMinus1(sum: Ast.ExprSum): BOOLEAN;
		RETURN (sum.next # NIL)
		     & (sum.next.next = NIL)
		     & (sum.next.add = Scanner.Minus)
		     & (sum.next.term.value # NIL)
		     & (sum.next.term.value(Ast.ExprInteger).int = 1)
		END IsEndMinus1;
	BEGIN
		Text.Str(gen, "for (");
		GlobalName(gen, st.var);
		Text.Str(gen, " = ");
		Expression(gen, st.expr);
		Text.Str(gen, "; ");
		GlobalName(gen, st.var);
		IF st.by > 0 THEN
			IF (st.to IS Ast.ExprSum) & IsEndMinus1(st.to(Ast.ExprSum)) THEN
				Text.Str(gen, " < ");
				Expression(gen, st.to(Ast.ExprSum).term)
			ELSE
				Text.Str(gen, " <= ");
				Expression(gen, st.to)
			END;
			IF st.by = 1 THEN
				Text.Str(gen, "; ++");
				GlobalName(gen, st.var)
			ELSE
				Text.Str(gen, "; ");
				GlobalName(gen, st.var);
				Text.Str(gen, " += ");
				Text.Int(gen, st.by)
			END
		ELSE
			Text.Str(gen, " >= ");
			Expression(gen, st.to);
			IF st.by = -1 THEN
				Text.Str(gen, "; --");
				GlobalName(gen, st.var)
			ELSE
				Text.Str(gen, "; ");
				GlobalName(gen, st.var);
				Text.Str(gen, " -= ");
				Text.Int(gen, -st.by)
			END
		END;
		Text.StrOpen(gen, ") {");
		statements(gen, st.stats);
		Text.StrClose(gen, "}")
	END For;

	PROCEDURE Assign(VAR gen: Generator; st: Ast.Assign);
	VAR type, base: Ast.Record;
		reref, retain, toByte: BOOLEAN;

		PROCEDURE AssertArraySize(VAR gen: Generator;
		                          des: Ast.Designator; e: Ast.Expression);
		BEGIN
			IF gen.opt.checkIndex
			 & (  (des.type(Ast.Array).count = NIL)
			   OR (e.type(Ast.Array).count   = NIL)
			   )
			THEN
				Text.Str(gen, "assert(");
				ArrayLen(gen, des);
				Text.Str(gen, " <= ");
				ArrayLen(gen, e);
				Text.StrLn(gen, ");")
			END
		END AssertArraySize;
	BEGIN
		toByte := (st.designator.type.id = Ast.IdByte)
		        & (st.expr.type.id = Ast.IdInteger)
		        & gen.opt.checkArith & (st.expr.value = NIL);
		retain := (st.designator.type.id = Ast.IdPointer)
		        & (gen.opt.memManager = MemManagerCounter);
		IF retain & (st.expr.id = Ast.IdPointer) THEN
			Text.Str(gen, "O7C_NULL(&");
			Designator(gen, st.designator);
			reref := FALSE
		ELSE
			IF retain THEN
				Text.Str(gen, "O7C_ASSIGN(&");
				Designator(gen, st.designator);
				Text.Str(gen, ", ")
			ELSIF (st.designator.type.id = Ast.IdArray)
			(*    & (st.designator.type.type.id # Ast.IdString) *)
			THEN
				AssertArraySize(gen, st.designator, st.expr);
				Text.Str(gen, "memcpy(");
				Designator(gen, st.designator);
				Text.Str(gen, ", ")
			ELSIF toByte THEN
				Designator(gen, st.designator);
				Text.Str(gen, " = o7c_byte(")
			ELSE
				Designator(gen, st.designator);
				Text.Str(gen, " = ")
			END;
			base := NIL;
			reref := (st.expr.type.id = Ast.IdPointer)
			       & (st.expr.type.type # st.designator.type.type)
			       & (st.expr.id # Ast.IdPointer);
			IF ~reref THEN
				Expression(gen, st.expr);
				IF st.expr.type.id = Ast.IdRecord THEN
					base := st.designator.type(Ast.Record);
					type := st.expr.type(Ast.Record)
				ELSIF (st.designator.type.id = Ast.IdArray)
				(*  & (st.designator.type.type.id # Ast.IdString) *)
				THEN
					IF st.expr.type(Ast.Array).count # NIL THEN
						Text.Str(gen, ", sizeof(");
						Expression(gen, st.expr);
						Text.Str(gen, ")")
					ELSE
						Text.Str(gen, ", (");
						ArrayLen(gen, st.expr);
						Text.Str(gen, ") * sizeof(");
						Expression(gen, st.expr);
						Text.Str(gen, "[0])")
					END
				END
			ELSIF gen.opt.plan9 THEN
				Expression(gen, st.expr);
				reref := FALSE
			ELSE
				base := st.designator.type.type(Ast.Record);
				type := st.expr.type.type(Ast.Record).base;
				Text.Str(gen, "(&(");
				Expression(gen, st.expr);
				Text.Str(gen, ")->_")
			END;
			IF (base # NIL) & (type # base) THEN
				(*ASSERT(st.designator.type.id = Ast.IdRecord);*)
				IF gen.opt.plan9 THEN
					Text.Str(gen, ".");
					GlobalName(gen, st.designator.type)
				ELSE
					WHILE type # base DO
						Text.Str(gen, "._");
						type := type.base
					END
				END
			END
		END;
		CASE ORD(reref) + ORD(retain) + ORD(toByte)
		   + ORD((st.designator.type.id = Ast.IdArray)
		       & (st.designator.type.type.id # Ast.IdString)
		        )
		OF
		  0: Text.StrLn(gen, ";")
		| 1: Text.StrLn(gen, ");")
		| 2: Text.StrLn(gen, "));")
		END
	END Assign;

	PROCEDURE Case(VAR gen: Generator; st: Ast.Case);
	VAR elem, elemWithRange: Ast.CaseElement;
		caseExpr: Ast.Expression;

		PROCEDURE CaseElement(VAR gen: Generator; elem: Ast.CaseElement);
		VAR r: Ast.CaseLabel;
		BEGIN
			IF ~IsCaseElementWithRange(elem) THEN
				r := elem.labels;
				WHILE r # NIL DO
					Text.Str(gen, "case ");
					Text.Int(gen, r.value);
					ASSERT(r.right = NIL);
					Text.StrLn(gen, ":");

					r := r.next
				END;
				INC(gen.tabs);
				statements(gen, elem.stats);
				Text.StrLn(gen, "break;");
				DEC(gen.tabs, 1)
			END
		END CaseElement;

		PROCEDURE CaseElementAsIf(VAR gen: Generator; elem: Ast.CaseElement;
		                          caseExpr: Ast.Expression);
		VAR r: Ast.CaseLabel;

			PROCEDURE CaseRange(VAR gen: Generator; r: Ast.CaseLabel;
			                    caseExpr: Ast.Expression);
			BEGIN
				IF r.right = NIL THEN
					IF caseExpr = NIL THEN
						Text.Str(gen, "(o7c_case_expr == ")
					ELSE
						Text.Str(gen, "(");
						Expression(gen, caseExpr);
						Text.Str(gen, " == ")
					END;
					Text.Int(gen, r.value)
				ELSE
					ASSERT(r.value <= r.right.value);
					Text.Str(gen, "(");
					Text.Int(gen, r.value);
					IF caseExpr = NIL THEN
						Text.Str(gen, " <= o7c_case_expr && o7c_case_expr <= ")
					ELSE
						Text.Str(gen, " <= ");
						Expression(gen, caseExpr);
						Text.Str(gen, " && ");
						Expression(gen, caseExpr);
						Text.Str(gen, " <= ")
					END;
					Text.Int(gen, r.right.value)
				END;
				Text.Str(gen, ")")
			END CaseRange;
		BEGIN
			Text.Str(gen, "if (");
			r := elem.labels;
			ASSERT(r # NIL);
			CaseRange(gen, r, caseExpr);
			WHILE r.next # NIL DO
				r := r.next;
				Text.Str(gen, " || ");
				CaseRange(gen, r, caseExpr)
			END;
			Text.StrOpen(gen, ") {");
			statements(gen, elem.stats);
			DEC(gen.tabs);
			Text.Str(gen, "}")
		END CaseElementAsIf;
	BEGIN
		elemWithRange := st.elements;
		WHILE (elemWithRange # NIL) & ~IsCaseElementWithRange(elemWithRange) DO
			elemWithRange := elemWithRange.next
		END;
		IF (elemWithRange = NIL)
		& ~((st.expr IS Ast.Factor) & ~(st.expr IS Ast.ExprBraces))
		THEN
			caseExpr := NIL;
			Text.Str(gen, "{ int o7c_case_expr = ");
			Expression(gen, st.expr);
			Text.StrOpen(gen, ";");
			Text.StrLn(gen, "switch (o7c_case_expr) {")
		ELSE
			caseExpr := st.expr;
			Text.Str(gen, "switch (");
			Expression(gen, caseExpr);
			Text.StrLn(gen, ") {")
		END;
		elem := st.elements;
		REPEAT
			CaseElement(gen, elem);
			elem := elem.next
		UNTIL elem = NIL;
		Text.StrOpen(gen, "default:");
		IF elemWithRange # NIL THEN
			elem := elemWithRange;
			CaseElementAsIf(gen, elem, caseExpr);
			elem := elem.next;
			WHILE elem # NIL DO
				IF IsCaseElementWithRange(elem) THEN
					Text.Str(gen, " else ");
					CaseElementAsIf(gen, elem, caseExpr)
				END;
				elem := elem.next
			END;
			IF gen.opt.caseAbort THEN
				Text.StrLn(gen, " else abort();")
			END
		ELSIF gen.opt.caseAbort THEN
			Text.StrLn(gen, "abort();")
		END;
		Text.StrLn(gen, "break;");
		Text.StrClose(gen, "}");
		IF caseExpr = NIL THEN
			Text.StrClose(gen, "}")
		END
	END Case;
BEGIN
	Comment(gen, st.comment);
	IF st IS Ast.Assign THEN
		Assign(gen, st(Ast.Assign))
	ELSIF st IS Ast.Call THEN
		gen.expressionSemicolon := TRUE;
		Expression(gen, st.expr);
		IF gen.expressionSemicolon THEN
			Text.StrLn(gen, ";")
		ELSE
			Text.Ln(gen)
		END
	ELSIF st IS Ast.WhileIf THEN
		WhileIf(gen, st(Ast.WhileIf))
	ELSIF st IS Ast.Repeat THEN
		Repeat(gen, st(Ast.Repeat))
	ELSIF st IS Ast.For THEN
		For(gen, st(Ast.For))
	ELSIF st IS Ast.Case THEN
		Case(gen, st(Ast.Case))
	ELSE
		ASSERT(FALSE)
	END
END Statement;

PROCEDURE Statements(VAR gen: Generator; stats: Ast.Statement);
BEGIN
	WHILE stats # NIL DO
		Statement(gen, stats);
		stats := stats.next
	END
END Statements;

PROCEDURE ProcDecl(VAR gen: Generator; proc: Ast.Procedure);
BEGIN
	IF proc.mark & ~gen.opt.main THEN
		Text.Str(gen, "extern ")
	ELSE
		Text.Str(gen, "static ")
	END;
	Declarator(gen, proc, FALSE, FALSE, TRUE);
	Text.StrLn(gen, ";")
END ProcDecl;

PROCEDURE Qualifier(VAR gen: Generator; type: Ast.Type);
BEGIN
	CASE type.id OF
	  Ast.IdInteger:
		Text.Str(gen, "int")
	| Ast.IdSet:
		Text.Str(gen, "unsigned")
	| Ast.IdBoolean:
		IF (gen.opt.std >= IsoC99)
		 & (gen.opt.varInit # VarInitUndefined)
		THEN	Text.Str(gen, "bool")
		ELSE	Text.Str(gen, "o7c_bool")
		END
	| Ast.IdByte:
		Text.Str(gen, "char unsigned")
	| Ast.IdChar:
		Text.Str(gen, "o7c_char")
	| Ast.IdReal:
		Text.Str(gen, "double")
	| Ast.IdPointer, Ast.IdProcType:
		GlobalName(gen, type)
	END
END Qualifier;

PROCEDURE Procedure(VAR out: MOut; proc: Ast.Procedure);

	PROCEDURE Implement(VAR out: MOut; VAR gen: Generator; proc: Ast.Procedure);
	VAR retainParams: Ast.Declaration;

		PROCEDURE CloseConsts(VAR gen: Generator; consts: Ast.Declaration);
		BEGIN
			WHILE (consts # NIL) & (consts IS Ast.Const) DO
				Text.StrIgnoreIndent(gen, "#");
				Text.Str(gen, "undef ");
				Name(gen, consts);
				Text.Ln(gen);
				consts := consts.next
			END
		END CloseConsts;

		PROCEDURE SearchRetain(gen: Generator; fp: Ast.Declaration): Ast.Declaration;
		BEGIN
			WHILE (fp # NIL)
			    & ((fp.type.id # Ast.IdPointer) OR fp(Ast.FormalParam).isVar)
			DO
				fp := fp.next
			END
			RETURN fp
		END SearchRetain;

		PROCEDURE RetainParams(VAR gen: Generator; fp: Ast.Declaration);
		BEGIN
			IF fp # NIL THEN
				Text.Str(gen, "o7c_retain(");
				Name(gen, fp);
				fp := fp.next;
				WHILE fp # NIL DO
					IF (fp.type.id = Ast.IdPointer) & ~fp(Ast.FormalParam).isVar
					THEN
						Text.Str(gen, "); o7c_retain(");
						Name(gen, fp)
					END;
					fp := fp.next
				END;
				Text.StrLn(gen, ");")
			END
		END RetainParams;

		PROCEDURE ReleaseParams(VAR gen: Generator; fp: Ast.Declaration);
		BEGIN
			IF fp # NIL THEN
				Text.Str(gen, "o7c_release(");
				Name(gen, fp);
				fp := fp.next;
				WHILE fp # NIL DO
					IF (fp.type.id = Ast.IdPointer) & ~fp(Ast.FormalParam).isVar
					THEN
						Text.Str(gen, "); o7c_release(");
						Name(gen, fp)
					END;
					fp := fp.next
				END;
				Text.StrLn(gen, ");")
			END
		END ReleaseParams;

		PROCEDURE ReleaseVars(VAR gen: Generator; var: Ast.Declaration);
		VAR first: BOOLEAN;
		BEGIN
			IF gen.opt.memManager = MemManagerCounter THEN
				first := TRUE;
				WHILE (var # NIL) & (var IS Ast.Var) DO
					IF var.type.id = Ast.IdPointer THEN
						IF first THEN
							first := FALSE;
							Text.Str(gen, "o7c_release(")
						ELSE
							Text.Str(gen, "); o7c_release(")
						END;
						Name(gen, var)
					END;
					var := var.next
				END;
				IF ~first THEN
					Text.StrLn(gen, ");")
				END
			END
		END ReleaseVars;
	BEGIN
		Comment(gen, proc.comment);
		Mark(gen, proc.mark);
		Declarator(gen, proc, FALSE, FALSE(*TODO*), TRUE);
		Text.StrOpen(gen, " {");

		INC(gen.localDeep);

		gen.fixedLen := gen.len;

		IF gen.opt.memManager # MemManagerCounter THEN
			retainParams := NIL
		ELSE
			retainParams := SearchRetain(gen, proc.header.params);
			IF proc.return # NIL THEN
				Qualifier(gen, proc.return.type);
				IF proc.return.type.id = Ast.IdPointer
				THEN	Text.StrLn(gen, " o7c_return = NULL;")
				ELSE	Text.StrLn(gen, " o7c_return;")
				END
			END
		END;
		declarations(out, proc);

		RetainParams(gen, retainParams);

		Statements(gen, proc.stats);

		IF proc.return = NIL THEN
			ReleaseVars(gen, proc.vars);
			ReleaseParams(gen, retainParams)
		ELSE
			IF (gen.opt.memManager = MemManagerCounter) & (proc.return # NIL)
			THEN
				IF proc.return.type.id = Ast.IdPointer THEN
					Text.Str(gen, "O7C_ASSIGN(&o7c_return, ");
					CheckExpr(gen, proc.return);
					Text.StrLn(gen, ");")
				ELSE
					Text.Str(gen, "o7c_return = ");
					CheckExpr(gen, proc.return);
					Text.StrLn(gen, ";")
				END;
				ReleaseVars(gen, proc.vars);
				ReleaseParams(gen, retainParams);
				IF proc.return.type.id = Ast.IdPointer THEN
					Text.StrLn(gen, "o7c_unhold(o7c_return);")
				END;
				Text.StrLn(gen, "return o7c_return;")
			ELSE
				ReleaseVars(gen, proc.vars);
				ReleaseParams(gen, retainParams);
				Text.Str(gen, "return ");
				CheckExpr(gen, proc.return);
				Text.StrLn(gen, ";")
			END
		END;

		DEC(gen.localDeep);
		CloseConsts(gen, proc.start);
		Text.StrClose(gen, "}");
		Text.Ln(gen)
	END Implement;

	PROCEDURE LocalProcs(VAR out: MOut; proc: Ast.Procedure);
	VAR p, t: Ast.Declaration;
	BEGIN
		t := proc.types;
		WHILE (t # NIL) & (t IS Ast.Type) DO
			TypeDecl(out, t(Ast.Type));
			(*IF t IS Ast.Record THEN
				RecordTag(out.g[Implementation], t(Ast.Record))
			END;*)
			t := t.next
		END;
		p := proc.procedures;
		IF (p # NIL) & ~out.opt.procLocal THEN
			IF ~proc.mark & ~out.opt.procLocal THEN
				(* TODO также проверить наличие рекурсии из локальных процедур*)
				ProcDecl(out.g[Implementation], proc)
			END;
			REPEAT
				Procedure(out, p(Ast.Procedure));
				p := p.next
			UNTIL p = NIL
		END
	END LocalProcs;
BEGIN
	LocalProcs(out, proc);
	IF proc.mark & ~out.opt.main THEN
		ProcDecl(out.g[Interface], proc)
	END;
	Implement(out, out.g[Implementation], proc)
END Procedure;

PROCEDURE LnIfWrote(VAR out: MOut);

	PROCEDURE Write(VAR gen: Generator);
	BEGIN
		IF gen.fixedLen # gen.len THEN
			Text.Ln(gen);
			gen.fixedLen := gen.len
		END
	END Write;
BEGIN
	Write(out.g[Interface]);
	Write(out.g[Implementation])
END LnIfWrote;

PROCEDURE VarsInit(VAR gen: Generator; d: Ast.Declaration);
VAR arrDeep, arrTypeId, i: INTEGER;

	PROCEDURE IsConformArrayType(type: Ast.Type; VAR id, deep: INTEGER): BOOLEAN;
	BEGIN
		deep := 0;
		WHILE type.id = Ast.IdArray DO
			INC(deep);
			type := type.type
		END;
		id := type.id
		RETURN id IN {Ast.IdReal, Ast.IdInteger, Ast.IdBoolean}
	END IsConformArrayType;
BEGIN
	WHILE (d # NIL) & (d IS Ast.Var) DO
		IF d.type.id IN {Ast.IdArray, Ast.IdRecord} THEN
			IF (gen.opt.varInit = VarInitZero)
			OR (d.type.id = Ast.IdRecord)
			OR    (d.type.id = Ast.IdArray)
			    & ~IsConformArrayType(d.type, arrTypeId, arrDeep)
			THEN
				Text.Str(gen, "memset(&");
				Name(gen, d);
				Text.Str(gen, ", 0, sizeof(");
				Name(gen, d);
				Text.StrLn(gen, "));")
			ELSE
				ASSERT(gen.opt.varInit = VarInitUndefined);
				CASE arrTypeId OF
				  Ast.IdInteger:
					Text.Str(gen, "o7c_ints_undef(")
				| Ast.IdReal:
					Text.Str(gen, "o7c_doubles_undef(")
				| Ast.IdBoolean:
					Text.Str(gen, "o7c_bools_undef(")
				END;
				Name(gen, d);
				FOR i := 2 TO arrDeep DO
					Text.Str(gen, "[0]")
				END;
				Text.Str(gen, ", sizeof(");
				Name(gen, d);
				Text.Str(gen, ") / sizeof(");
				Name(gen, d);
				FOR i := 2 TO arrDeep DO
					Text.Str(gen, "[0]")
				END;
				Text.StrLn(gen, "[0]));")
			END
		END;
		d := d.next
	END
END VarsInit;

PROCEDURE Declarations(VAR out: MOut; ds: Ast.Declarations);
VAR d, prev: Ast.Declaration;
BEGIN
	d := ds.start;
	ASSERT((d = NIL) OR ~(d IS Ast.Module));
	WHILE (d # NIL) & (d IS Ast.Import) DO
		Import(out.g[ORD(~out.opt.main)], d);
		d := d.next
	END;
	LnIfWrote(out);

	WHILE (d # NIL) & (d IS Ast.Const) DO
		Const(out.g[ORD(d.mark & ~out.opt.main)], d(Ast.Const));
		d := d.next
	END;
	LnIfWrote(out);

	IF ds IS Ast.Module THEN
		WHILE (d # NIL) & (d IS Ast.Type) DO
			TypeDecl(out, d(Ast.Type));
			d := d.next
		END;
		LnIfWrote(out);

		WHILE (d # NIL) & (d IS Ast.Var) DO
			Var(out, NIL, d, TRUE);
			d := d.next
		END
	ELSE
		d := ds.vars;

		prev := NIL;
		WHILE (d # NIL) & (d IS Ast.Var) DO
			Var(out, prev, d, (d.next = NIL) OR ~(d.next IS Ast.Var));
			prev := d;
			d := d.next
		END;
		IF out.opt.varInit # VarInitNo THEN
			VarsInit(out.g[Implementation], ds.vars)
		END;

		d := ds.procedures
	END;
	LnIfWrote(out);

	IF out.opt.procLocal OR (ds IS Ast.Module) THEN
		WHILE d # NIL DO
			Procedure(out, d(Ast.Procedure));
			d := d.next
		END
	END
END Declarations;

PROCEDURE DefaultOptions*(): Options;
VAR o: Options;
BEGIN
	NEW(o); V.Init(o^);
	IF o # NIL THEN
		o.std := IsoC99;
		o.gnu := FALSE;
		o.plan9 := FALSE;
		o.procLocal := FALSE;
		o.checkIndex := TRUE;
		o.checkArith := TRUE;
		o.caseAbort := TRUE;
		o.comment := TRUE;
		o.varInit := VarInitUndefined;
		o.memManager := MemManagerNoFree;
		o.main := FALSE
	END
	RETURN o
END DefaultOptions;


PROCEDURE MarkExpression(e: Ast.Expression);
BEGIN
	IF e # NIL THEN
		IF e.id = Ast.IdRelation THEN
			MarkExpression(e(Ast.ExprRelation).exprs[0]);
			MarkExpression(e(Ast.ExprRelation).exprs[1])
		ELSIF e.id = Ast.IdTerm THEN
			MarkExpression(e(Ast.ExprTerm).factor);
			MarkExpression(e(Ast.ExprTerm).expr)
		ELSIF e.id = Ast.IdSum THEN
			MarkExpression(e(Ast.ExprSum).term);
			MarkExpression(e(Ast.ExprSum).next)
		ELSIF (e.id = Ast.IdDesignator)
			& ~e(Ast.Designator).decl.mark
		THEN
			e(Ast.Designator).decl.mark := TRUE;
			MarkExpression(e(Ast.Designator).decl(Ast.Const).expr)
		END
	END
END MarkExpression;

PROCEDURE MarkType(t: Ast.Type);
VAR d: Ast.Declaration;
BEGIN
	WHILE (t # NIL) & ~t.mark DO
		t.mark := TRUE;
		IF t.id = Ast.IdArray THEN
			MarkExpression(t(Ast.Array).count);
			t := t.type
		ELSIF t.id IN {Ast.IdRecord, Ast.IdPointer} THEN
			IF t.id = Ast.IdPointer THEN
				t := t.type;
				t.mark := TRUE;
				ASSERT(t.module # NIL)
			END;
			d := t(Ast.Record).vars;
			WHILE d # NIL DO
				MarkType(d.type);
				IF Strings.IsDefined(d.name) THEN
					Log.StrLn(d.name.block.s)
				END;
				d := d.next
			END;
			t := t(Ast.Record).base
		ELSE
			t := NIL
		END
	END
END MarkType;

PROCEDURE MarkUsedInMarked(m: Ast.Module);
VAR imp: Ast.Declaration;

	PROCEDURE Consts(c: Ast.Const);
	BEGIN
		WHILE c # NIL DO
			IF c.mark THEN
				MarkExpression(c.expr)
			END;
			IF (c.next # NIL) & (c.next IS Ast.Const) THEN
				c := c.next(Ast.Const)
			ELSE
				c := NIL
			END
		END
	END Consts;

	PROCEDURE Types(t: Ast.Declaration);
	BEGIN
		WHILE (t # NIL) & (t IS Ast.Type) DO
			IF t.mark THEN
				t.mark := FALSE;
				MarkType(t(Ast.Type))
			END;
			t := t.next
		END
	END Types;

BEGIN
	imp := m.import;
	WHILE (imp # NIL) & (imp IS Ast.Import) DO
		MarkUsedInMarked(imp.module);
		imp := imp.next
	END;
	Consts(m.consts);
	Types(m.types)
END MarkUsedInMarked;

PROCEDURE ImportInit(VAR gen: Generator; imp: Ast.Declaration);
BEGIN
	IF imp # NIL THEN
		ASSERT(imp IS Ast.Import);

		REPEAT
			Text.String(gen, imp.module.name);
			Text.StrLn(gen, "_init();");

			imp := imp.next
		UNTIL (imp = NIL) OR ~(imp IS Ast.Import);
		Text.Ln(gen)
	END
END ImportInit;

PROCEDURE TagsInit(VAR gen: Generator);
VAR r: Ast.Record;
BEGIN
	r := NIL;
	WHILE gen.opt.records # NIL DO
		r := gen.opt.records(Ast.Record);
		gen.opt.records := r.ext;
		r.ext := NIL;

		Text.Str(gen, "o7c_tag_init(");
		GlobalName(gen, r);
		IF r.base = NIL THEN
			Text.StrLn(gen, "_tag, NULL);")
		ELSE
			Text.Str(gen, "_tag, ");
			GlobalName(gen, r.base);
			Text.StrLn(gen, "_tag);")
		END
	END;
	IF r # NIL THEN
		Text.Ln(gen)
	END
END TagsInit;

PROCEDURE Generate*(interface, implementation: Stream.POut;
                    module: Ast.Module; opt: Options);
VAR out: MOut;

	PROCEDURE Init(VAR gen: Generator; out: Stream.POut;
	               module: Ast.Module; opt: Options; interface: BOOLEAN);
	BEGIN
		Text.Init(gen, out);
		gen.module := module;
		gen.localDeep := 0;

		opt.records := NIL;
		opt.recordLast := NIL;
		gen.opt := opt;

		gen.fixedLen := gen.len;

		gen.interface := interface
	END Init;

	PROCEDURE Includes(VAR gen: Generator);
	BEGIN
		Text.StrLn(gen, "#include <stdlib.h>");
		Text.StrLn(gen, "#include <stddef.h>");
		Text.StrLn(gen, "#include <string.h>");
		Text.StrLn(gen, "#include <assert.h>");
		Text.StrLn(gen, "#include <math.h>");
		IF gen.opt.std >= IsoC99 THEN
			Text.StrLn(gen, "#include <stdbool.h>")
		END;
		Text.Ln(gen);
		IF gen.opt.varInit = VarInitUndefined THEN
			Text.StrLn(gen, "#define O7C_BOOL_UNDEFINED")
		END;
		Text.StrLn(gen, "#include <o7c.h>");
		Text.Ln(gen)
	END Includes;

	PROCEDURE HeaderGuard(VAR gen: Generator);
	BEGIN
		Text.Str(gen, "#if !defined(HEADER_GUARD_");
		Text.String(gen, gen.module.name);
		Text.StrLn(gen, ")");
		Text.Str(gen, "#define HEADER_GUARD_");
		Text.String(gen, gen.module.name);
		Text.Ln(gen); Text.Ln(gen)
	END HeaderGuard;

	PROCEDURE ModuleInit(VAR interf, impl: Generator; module: Ast.Module);
	BEGIN
		IF (module.import = NIL)
		 & (module.stats = NIL)
		 & (impl.opt.records = NIL)
		THEN
			IF impl.opt.std >= IsoC99 THEN
				Text.Str(interf, "static inline void ")
			ELSE
				Text.Str(interf, "static void ")
			END;
			Name(interf, module);
			Text.StrLn(interf, "_init(void) { ; }")
		ELSE
			Text.Str(interf, "extern void ");
			Name(interf, module);
			Text.StrLn(interf, "_init(void);");

			Text.Str(impl, "extern void ");
			Name(impl, module);
			Text.StrOpen(impl, "_init(void) {");
			Text.StrLn(impl, "static int initialized = 0;");
			Text.StrLn(impl, "if (0 == initialized) {");
			INC(impl.tabs, 1);
			ImportInit(impl, module.import);
			TagsInit(impl);
			Statements(impl, module.stats);
			Text.StrClose(impl, "}");
			Text.StrLn(impl, "++initialized;");
			Text.StrClose(impl, "}");
			Text.Ln(impl)
		END
	END ModuleInit;

	PROCEDURE Main(VAR gen: Generator; module: Ast.Module);
	BEGIN
		Text.StrOpen(gen, "extern int main(int argc, char **argv) {");
		Text.StrLn(gen, "o7c_init(argc, argv);");
		ImportInit(gen, module.import);
		TagsInit(gen);
		IF module.stats # NIL THEN
			Statements(gen, module.stats)
		END;
		Text.StrLn(gen, "return o7c_exit_code;");
		Text.StrClose(gen, "}")
	END Main;
BEGIN
	ASSERT(~Ast.HasError(module));

	IF opt = NIL THEN
		opt := DefaultOptions()
	END;
	opt.main := interface = NIL;

	IF ~opt.main THEN
		MarkUsedInMarked(module)
	END;

	out.opt := opt;

	IF interface # NIL THEN
		Init(out.g[Interface], interface, module, opt, TRUE)
	END;
	opt.index := 0;

	Init(out.g[Implementation], implementation, module, opt, FALSE);

	Comment(out.g[ORD(~opt.main)], module.comment);

	Includes(out.g[Implementation]);

	IF ~opt.main THEN
		HeaderGuard(out.g[Interface]);
		Import(out.g[Implementation], module)
	END;

	Declarations(out, module);

	IF opt.main THEN
		Main(out.g[Implementation], module)
	ELSE
		ModuleInit(out.g[Interface], out.g[Implementation], module);
		Text.StrLn(out.g[Interface], "#endif")
	END
END Generate;

BEGIN
	type := Type;
	declarator := Declarator;
	declarations := Declarations;
	statements := Statements;
	expression := Expression
END GeneratorC.

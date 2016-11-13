(*  Command line interface for Oberon-07 translator 
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
MODULE Translator;

IMPORT
	Log,
	Out,
	CLI,
	File := VFileStream,
	Utf8,
	Strings := StringStore,
	Parser,
	Scanner,
	Ast,
	GeneratorC,
	TranLim := TranslatorLimits;

CONST
	ErrNo					=  0;
	ErrWrongArgs			= -1;
	ErrTooLongSourceName	= -2;
	ErrTooLongOutName		= -3;
	ErrOpenSource			= -4;
	ErrOpenH				= -5;
	ErrOpenC				= -6;
	ErrParse				= -7;

TYPE
	ModuleProvider = POINTER TO RECORD(Ast.RProvider)
		opt: Parser.Options;
		fileExt: ARRAY 32 OF CHAR;
		extLen: INTEGER;
		path: ARRAY 4096 OF CHAR;
		modules: RECORD
			first, last: Ast.Module
		END
	END;

PROCEDURE ErrorMessage(code: INTEGER);

	PROCEDURE O(s: ARRAY OF CHAR);
	BEGIN
		Out.String(s)
	END O;
BEGIN
	Out.Int(code - Parser.ErrAstBegin, 0); Out.String(" ");
	IF code <= Parser.ErrAstBegin THEN
		CASE code - Parser.ErrAstBegin OF
		  Ast.ErrImportNameDuplicate		:
			O("Имя модуля уже встречается в списке импорта")
		| Ast.ErrDeclarationNameDuplicate	:
			O("Повторное объявление имени в той же области видимости")
		| Ast.ErrMultExprDifferentTypes		:
			O("Типы подвыражений в умножении несовместимы")
		| Ast.ErrDivExprDifferentTypes		:
			O("Типы подвыражений в делении несовместимы")
		| Ast.ErrNotBoolInLogicExpr			:
			O("В логическом выражении должны использоваться подвыражении логического типа")
		| Ast.ErrNotIntInDivOrMod			:
			O("В целочисленном делении допустимы только целочисленные подвыражения")
		| Ast.ErrNotRealTypeForRealDiv		:
			O("В дробном делении допустимы только подвыражения дробного типа")
		| Ast.ErrIntDivByZero				:
			O("Деление на 0")
		| Ast.ErrNotIntSetElem				:
			O("В качестве элементов множества допустимы только целые числа")
		| Ast.ErrSetElemOutOfRange			:
			O("Элемент множества выходит за границы возможных значений - 0 .. 31")
		| Ast.ErrSetLeftElemBiggerRightElem	:
			O("Левый элемент диапазона больше правого")
		| Ast.ErrAddExprDifferenTypes		:
			O("Типы подвыражений в сложении несовместимы")
		| Ast.ErrNotNumberAndNotSetInMult	:
			O("В выражениях *, /, DIV, MOD допустимы только числа и множества")
		| Ast.ErrNotNumberAndNotSetInAdd	:
			O("В выражениях +, - допустимы только числа и множества")
		| Ast.ErrSignForBool				:
			O("Унарный знак не применим к логическому выражению")
		| Ast.ErrRelationExprDifferenTypes	:
			O("Типы подвыражений в сравнении не совпадают")
		| Ast.ErrExprInWrongTypes			:
			O("Ast.ErrExprInWrongTypes")
		| Ast.ErrExprInRightNotSet			:
			O("Ast.ErrExprInRightNotSet")
		| Ast.ErrExprInLeftNotInteger		:
			O("Левый член выражения IN должен быть целочисленным")
		| Ast.ErrRelIncompatibleType		:
			O("В сравнении выражения несовместимых типов")
		| Ast.ErrIsExtTypeNotRecord			:
			O("Проверка IS применима только к записям")
		| Ast.ErrIsExtVarNotRecord			:
			O("Левый член проверки IS должен иметь тип записи или указателя на неё")
		| Ast.ErrConstDeclExprNotConst		:
			O("Постоянная сопоставляется выражению, невычислимым на этапе перевода")
		| Ast.ErrAssignIncompatibleType		:
			O("Несовместимые типы в присваивании")
		| Ast.ErrCallNotProc				:
			O("Вызов допустим только для процедур и переменных процедурного типа")
		| Ast.ErrCallIgnoredReturn			:
			O("Возвращаемое значение не задействовано в выражении")
		| Ast.ErrCallExprWithoutReturn		:
			O("Вызываемая процедура не возвращает значения")
		| Ast.ErrCallExcessParam			:
			O("Лишние параметры при вызове процедуры")
		| Ast.ErrCallIncompatibleParamType	:
			O("Несовместимый тип параметра")
		| Ast.ErrCallExpectVarParam			:
			O("Параметр должен быть изменяемым значением")
		| Ast.ErrCallVarPointerTypeNotSame	:
			O("Для переменного параметра - указателя должен использоваться аргумент того же типа")
		| Ast.ErrCallParamsNotEnough		:
			O("Не хватает фактических параметров в вызове процедуры")
		| Ast.ErrCaseExprNotIntOrChar		:
			O("Выражение в CASE должно быть целочисленным или литерой")
		| Ast.ErrCaseElemExprTypeMismatch	:
			O("Метки CASE должно быть целочисленными или литерами")
		| Ast.ErrCaseElemDuplicate			:
			O("Дублирование значения меток в CASE")
		| Ast.ErrCaseRangeLabelsTypeMismatch:
			O("Не совпадает тип меток CASE")
		| Ast.ErrCaseLabelLeftNotLessRight	:
			O("Левая часть диапазона значений в метке CASE должна быть меньше правой")
		| Ast.ErrCaseLabelNotConst			:
			O("Метки CASE должны быть константами")
		| Ast.ErrProcHasNoReturn			:
			O("Процедура не имеет возвращаемого значения")
		| Ast.ErrReturnIncompatibleType		:
			O("Тип возвращаемого значения не совместим типом, указанном в заголовке процедуры")
		| Ast.ErrExpectReturn				:
			O("Ожидался возврат значения, так как в заголовке процедуры указан возвращаемый тип")
		| Ast.ErrDeclarationNotFound		:
			O("Предварительное объявление имени не было найдено")
		| Ast.ErrConstRecursive				:
			O("Недопустимое использование константы для задания собственного значения")
		| Ast.ErrImportModuleNotFound		:
			O("Импортированный модуль не был найден")
		| Ast.ErrImportModuleWithError		:
			O("Импортированный модуль содержит ошибки")
		| Ast.ErrDerefToNotPointer			:
			O("Разыменовывание применено не к указателю")
		| Ast.ErrArrayItemToNotArray		:
			O("Получение элемента не массива")
		| Ast.ErrArrayIndexNotInt			:
			O("Индекс массива не целочисленный")
		| Ast.ErrArrayIndexNegative			:
			O("Отрицательный индекс массива")
		| Ast.ErrArrayIndexOutOfRange		:
			O("Индекс массива выходит за его границы")
		| Ast.ErrGuardExpectRecordExt		:
			O("В защите типа ожидается расширенная запись")
		| Ast.ErrGuardExpectPointerExt		:
			O("В защите типа ожидается указатель на расширенную запись")
		| Ast.ErrGuardedTypeNotExtensible	:
			O("В защите типа переменная должна быть либо записью, либо указателем на запись")
		| Ast.ErrDotSelectorToNotRecord		:
			O("Селектор элемента записи применён не к записи")
		| Ast.ErrDeclarationNotVar			:
			O("Ожидалась переменная")
		| Ast.ErrForIteratorNotInteger		:
			O("Итератор FOR не целочисленного типа")
		| Ast.ErrNotBoolInIfCondition		:
			O("Выражение в охране условного оператора должно быть логическим")
		| Ast.ErrNotBoolInWhileCondition	:
			O("Выражение в охране цикла WHILE должно быть логическим")
		| Ast.ErrWhileConditionAlwaysFalse	:
			O("Охрана цикла WHILE всегда ложна")
		| Ast.ErrWhileConditionAlwaysTrue	:
			O("Цикл бесконечен, так как охрана WHILE всегда истинна")
		| Ast.ErrNotBoolInUntil:
			O("Выражение в условии завершения цикла REPEAT должно быть логическим")
		| Ast.ErrUntilAlwaysFalse			:
			O("Цикл бесконечен, так как условие завершения всегда ложно")
		| Ast.ErrUntilAlwaysTrue			:
			O("Условие завершения всегда истинно")
		| Ast.ErrDeclarationIsPrivate:
			O("Объявление не экспортировано")
		| Ast.ErrNegateNotBool:
			O("Логическое отрицание применено не к логическому типу")

		| Ast.ErrNotImplemented				:
			O("Ast.ErrNotImplemented")
		END
	ELSE
		CASE code OF
		  Scanner.ErrUnexpectChar			:
			O("Неожиданный символ в тексте")
		| Scanner.ErrNumberTooBig			:
			O("Значение константы слишком велико")
		| Scanner.ErrRealScaleTooBig		:
			O("ErrRealScaleTooBig")
		| Scanner.ErrWordLenTooBig			:
			O("ErrWordLenTooBig")
		| Scanner.ErrExpectHOrX				:
			O("ErrExpectHOrX")
		| Scanner.ErrExpectDQuote			:
			O("ErrExpectDQuote")
		| Scanner.ErrExpectDigitInScale		:
			O("ErrExpectDigitInScale")
		| Scanner.ErrUnclosedComment		:
			O("Незакрытый комментарий")

		| Parser.ErrExpectModule			:
			O("Ожидается 'MODULE'")
		| Parser.ErrExpectIdent				:
			O("Ожидается имя")
		| Parser.ErrExpectColon				:
			O("Ожидается ':'")
		| Parser.ErrExpectSemicolon			:
			O("Ожидается ';'")
		| Parser.ErrExpectEnd				:
			O("Ожидается 'END'")
		| Parser.ErrExpectDot				:
			O("Ожидается '.'")
		| Parser.ErrExpectModuleName		:
			O("Ожидается имя модуля")
		| Parser.ErrExpectEqual				:
			O("Ожидается '='")
		| Parser.ErrExpectBrace1Close		:
			O("Ожидается ')'")
		| Parser.ErrExpectBrace2Close		:
			O("Ожидается ']'")
		| Parser.ErrExpectBrace3Close		:
			O("Ожидается '}'")
		| Parser.ErrExpectOf				:
			O("Ожидается OF")
		| Parser.ErrExpectConstIntExpr		:
			O("Ожидается константное целочисленное выражение")
		| Parser.ErrExpectTo				:
			O("ErrExpectTo")
		| Parser.ErrExpectNamedType			:
			O("ErrExpectNamedType")
		| Parser.ErrExpectRecord			:
			O("Ожидается запись")
		| Parser.ErrExpectStatement			:
			O("Ожидается оператор")
		| Parser.ErrExpectThen				:
			O("ErrExpectThen")
		| Parser.ErrExpectAssign:
			O("ErrExpectAssign")
		| Parser.ErrExpectAssignOrBrace1Open:
			O("ErrExpectAssignOrBrace1Open")
		| Parser.ErrExpectVarRecordOrPointer:
			O("Ожидается переменная типа запись либо указателя на неё")
		| Parser.ErrExpectType				:
			O("Ожидается тип")
		| Parser.ErrExpectUntil				:
			O("Ожидается UNTIL")
		| Parser.ErrExpectDo				:
			O("ErrExpectDo")
		| Parser.ErrExpectDesignator		:
			O("ErrExpectDesignator")
		| Parser.ErrExpectVar				:
			O("ErrExpectVar")
		| Parser.ErrExpectProcedure			:
			O("Ожидается процедура")
		| Parser.ErrExpectConstName			:
			O("ErrExpectConstName")
		| Parser.ErrExpectProcedureName		:
			O("Ожидается завершающее имя процедуры")
		| Parser.ErrExpectExpression		:
			O("Ожидается выражение")
		| Parser.ErrExcessSemicolon			:
			O("Лишняя ';'")
		| Parser.ErrEndModuleNameNotMatch	:
			O("Завершающее имя в конце модуля не совпадает с его именем")
		| Parser.ErrArrayDimensionsTooMany	:
			O("ErrArrayDimensionsTooMany")
		| Parser.ErrEndProcedureNameNotMatch:
			O("Завершающее имя в теле процедуры не совпадает с её именем")
		| Parser.ErrFunctionWithoutBraces	:
			O("Объявление процедуры с возвращаемым значением не содержит скобки")
		| Parser.ErrArrayLenLess1			:
			O("Длина массива должна быть > 0")

		| Parser.ErrNotImplemented			:
			O("Не реализовано")
		END
	END

END ErrorMessage;

PROCEDURE PrintErrors(err: Ast.Error);
VAR i: INTEGER;
BEGIN
	Out.String("с ошибками: "); Out.Ln;
	i := 0;
	WHILE err # NIL DO
		INC(i);
		Out.Int(i, 2); Out.String(") ");
		ErrorMessage(err.code);
		Out.String(" "); Out.Int(err.line + 1, 0);
		Out.String(" : "); Out.Int(err.column + err.tabs * 3, 0);
		Out.Ln;

		err := err.next
	END
END PrintErrors;

PROCEDURE LenStr(str: ARRAY OF CHAR; ofs: INTEGER): INTEGER;
VAR i: INTEGER;
BEGIN
	i := ofs;
	WHILE str[i] # Utf8.Null DO
		INC(i)
	END
	RETURN i - ofs
END LenStr;

PROCEDURE CopyPath(VAR str: ARRAY OF CHAR; arg: INTEGER);
VAR i: INTEGER;
BEGIN
	i := 0;
	WHILE (arg < CLI.count) & CLI.Get(str, i, arg) DO
		INC(i);
		INC(arg)
	END;
	IF i + 1 < LEN(str) THEN
		str[i + 1] := Utf8.Null
	ELSE
		str[LEN(str) - 1] := Utf8.Null;
		str[LEN(str) - 2] := Utf8.Null;
		str[LEN(str) - 3] := "#"
	END
END CopyPath;

PROCEDURE SearchModule(mp: ModuleProvider;
					   name: ARRAY OF CHAR; ofs, end: INTEGER): Ast.Module;
VAR m: Ast.Module;
BEGIN
	m := mp.modules.first;
	WHILE (m # NIL) & ~Strings.IsEqualToChars(m.name, name, ofs, end) DO
		ASSERT(m # m.module);
		m := m.module
	END
	RETURN m
END SearchModule;

PROCEDURE AddModule(mp: ModuleProvider; m: Ast.Module);
BEGIN
	ASSERT(m.module = m);
	m.module := NIL;
	IF mp.modules.first = NIL THEN
		mp.modules.first := m
	ELSE
		mp.modules.last.module := m
	END;
	mp.modules.last := m
END AddModule;

PROCEDURE GetModule(p: Ast.Provider; host: Ast.Module;
					name: ARRAY OF CHAR; ofs, end: INTEGER): Ast.Module;
VAR m: Ast.Module;
	source: File.In;
	mp: ModuleProvider;
	pathOfs: INTEGER;

	PROCEDURE Open(p: ModuleProvider; VAR pathOfs: INTEGER;
				   name: ARRAY OF CHAR; ofs, end: INTEGER): File.In;
	VAR n: ARRAY 1024 OF CHAR;
		len, l: INTEGER;
		in: File.In;
	BEGIN
		len := LenStr(p.path, pathOfs);
		l := 0;
		IF (len > 0)
		 & Strings.CopyChars(n, l, p.path, pathOfs, pathOfs + len)
		 & Strings.CopyChars(n, l, "/", 0, 1)
		 & Strings.CopyChars(n, l, name, ofs, end)
		 & Strings.CopyChars(n, l, p.fileExt, 0, p.extLen)
		THEN
			Log.Str("Открыть "); Log.Str(n); Log.Ln;
			in := File.OpenIn(n)
		ELSE
			in := NIL
		END;
		pathOfs := pathOfs + len + 2
		RETURN in
	END Open;
BEGIN
	mp := p(ModuleProvider);
	m := SearchModule(mp, name, ofs, end);
	IF m # NIL THEN
		Log.StrLn("Найден уже разобранный модуль")
	ELSE
		pathOfs := 0;
		REPEAT
			source := Open(mp, pathOfs, name, ofs, end)
		UNTIL (source # NIL) OR (mp.path[pathOfs] = Utf8.Null);
		IF source # NIL THEN
			m := Parser.Parse(source, p, mp.opt);
			File.CloseIn(source);
			AddModule(mp, m)
		ELSE
			Out.String("Не получается найти или открыть файл импортированного модуля");
			Out.Ln
		END
	END
	RETURN m
END GetModule;

PROCEDURE OpenOutput(VAR interface, implementation: File.Out;
					 VAR isMain: BOOLEAN): INTEGER;
VAR dest: ARRAY 1024 OF CHAR;
	destLen: INTEGER;
	ret: INTEGER;
BEGIN
	interface := NIL;
	implementation := NIL;
	destLen := 0;
	IF ~(CLI.Get(dest, destLen, 2) & (destLen < LEN(dest) - 2)) THEN
		ret := ErrTooLongOutName
	ELSE
		isMain := (destLen > 3)
			  & (dest[destLen - 3] = ".") & (dest[destLen - 2] = "c");
		IF isMain THEN
			DEC(destLen, 2)
		END;
		dest[destLen - 1] := ".";
		dest[destLen + 1] := Utf8.Null;
		IF ~isMain THEN
			dest[destLen] := "h";
			interface := File.OpenOut(dest)
		END;
		IF (interface = NIL) & ~isMain THEN
			ret := ErrOpenH
		ELSE
			dest[destLen] := "c";
			implementation := File.OpenOut(dest);
			IF implementation = NIL THEN
				File.CloseOut(interface);
				ret := ErrOpenC
			ELSE
				ret := ErrNo
			END
		END
	END
	RETURN ret
END OpenOutput;

PROCEDURE Compile(mp: ModuleProvider; source: File.In): INTEGER;
VAR module: Ast.Module;
	intGen, realGen: GeneratorC.Generator;
	opt: GeneratorC.Options;
	interface, implementation: File.Out;
	ret: INTEGER;
	isMain: BOOLEAN;
BEGIN
	module := Parser.Parse(source, mp, mp.opt);
	File.CloseIn(source);
	IF module = NIL THEN
		Out.String("Ожидается MODULE"); Out.Ln;
		ret := ErrParse
	ELSIF module.errors # NIL THEN
		PrintErrors(module.errors);
		ret := ErrParse
	ELSE
		Out.String("Модуль переведён без ошибок"); Out.Ln;

		ret := OpenOutput(interface, implementation, isMain);
		IF ret = ErrNo THEN
			GeneratorC.Init(intGen, interface);
			GeneratorC.Init(realGen, implementation);
			opt := GeneratorC.DefaultOptions();
			GeneratorC.Generate(intGen, realGen, module, opt);

			File.CloseOut(interface);
			File.CloseOut(implementation)
		END
	END
	RETURN ret
END Compile;

PROCEDURE NewProvider(fileExt: ARRAY OF CHAR; extLen: INTEGER): ModuleProvider;
VAR mp: ModuleProvider;
	ret: BOOLEAN;
BEGIN
	NEW(mp); Ast.ProviderInit(mp, GetModule);
	Parser.DefaultOptions(mp.opt);
	mp.opt.printError := ErrorMessage;
	CopyPath(mp.path, 3);
	mp.modules.first := NIL;
	mp.modules.last := NIL;

	mp.extLen := 0;
	ret := Strings.CopyChars(mp.fileExt, mp.extLen, fileExt, 0, extLen);
	ASSERT(ret)

	RETURN mp
END NewProvider;

PROCEDURE ErrMessage(err: INTEGER);
BEGIN
	CASE err OF
	  ErrWrongArgs:
		Out.String("Использование: ");
		Out.String("  o7c исходный.ob07 результат {пути}"); Out.Ln;
		Out.String("  где пути ведут к интерфейсным модулям"); Out.Ln;
		Out.String(
"В случае успешной трансляции создаст два файла языка Си, соответствующих исходному"
		);
		Out.Ln;
		Out.String("на Обероне: результат.h и результат.c.");
		Out.Ln;
		Out.String("Пути для поиска модулей следует разделять пробелами.")
	| ErrTooLongSourceName:
		Out.String("Слишком длинное имя исходного файла"); Out.Ln
	| ErrTooLongOutName:
		Out.String("Слишком длинное выходное имя"); Out.Ln
	| ErrOpenSource:
		Out.String("Не получается открыть исходный файл")
	| ErrOpenH:
		Out.String("Не получается открыть выходной .h файл")
	| ErrOpenC:
		Out.String("Не получается открыть выходной .c файл")
	| ErrParse:
		Out.String("Ошибка разбора исходного файла")
	END;
	Out.Ln
END ErrMessage;

PROCEDURE CopyExt(VAR ext: ARRAY OF CHAR; name: ARRAY OF CHAR): INTEGER;
VAR i, dot, len: INTEGER;
BEGIN
	i := 0;
	dot := -1;
	WHILE name[i] # Utf8.Null DO
		IF name[i] = "." THEN
			dot := i
		END;
		INC(i)
	END;
	len := 0;
	IF ~((dot >= 0) & Strings.CopyChars(ext, len, name, dot, i))
	 & ~Strings.CopyChars(ext, len, ".mod", 0, 4)
	THEN
		len := -1
	END;
	ASSERT(len >= 0)
	RETURN len
END CopyExt;

PROCEDURE Start*;
VAR src: ARRAY 1024 OF CHAR;
	ext: ARRAY 32 OF CHAR;
	srcLen, extLen: INTEGER;
	ret: INTEGER;
	source: File.In;
BEGIN
	Out.Open;
	Log.Turn(FALSE);

	IF CLI.count <= 2 THEN
		ret := ErrWrongArgs
	ELSE
		srcLen := 0;
		IF ~CLI.Get(src, srcLen, 1) THEN
			ret := ErrTooLongSourceName
		ELSE
			extLen := CopyExt(ext, src);
			source := File.OpenIn(src);
			IF source = NIL THEN
				ret := ErrOpenSource
			ELSE
				ret := Compile(NewProvider(ext, extLen), source)
			END
		END
	END;
	IF ret # 0 THEN
		ErrMessage(ret);
		CLI.SetExitCode(1)
	END
END Start;

BEGIN
	Start
END Translator.

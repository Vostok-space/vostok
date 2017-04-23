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
	TranLim := TranslatorLimits,
	Exec := OsExec;

CONST
	ResultC   = 0;
	ResultBin = 1;
	ResultRun = 2;

	ErrNo                   =   0;
	ErrWrongArgs            = - 1;
	ErrTooLongSourceName    = - 2;
	ErrTooLongOutName       = - 3;
	ErrOpenSource           = - 4;
	ErrOpenH                = - 5;
	ErrOpenC                = - 6;
	ErrParse                = - 7;
	ErrUnknownCommand       = - 8;
	ErrNotEnoughArgs        = - 9;
	ErrTooLongModuleDirs    = -10;
	ErrTooManyModuleDirs    = -11;
	ErrTooLongCDirs         = -12;
	ErrTooLongCc            = -13;
	ErrCCompiler            = -14;
	ErrTooLongRunArgs       = -15;
	ErrUnexpectArg          = -16;
TYPE
	ModuleProvider = POINTER TO RECORD(Ast.RProvider)
		opt: Parser.Options;
		fileExt: ARRAY 32 OF CHAR;
		extLen: INTEGER;
		path: ARRAY 4096 OF CHAR;
		sing: SET;
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
		  Ast.ErrImportNameDuplicate:
			O("Имя модуля уже встречается в списке импорта")
		| Ast.ErrDeclarationNameDuplicate:
			O("Повторное объявление имени в той же области видимости")
		| Ast.ErrMultExprDifferentTypes:
			O("Типы подвыражений в умножении несовместимы")
		| Ast.ErrDivExprDifferentTypes:
			O("Типы подвыражений в делении несовместимы")
		| Ast.ErrNotBoolInLogicExpr:
			O("В логическом выражении должны использоваться подвыражении логического типа")
		| Ast.ErrNotIntInDivOrMod:
			O("В целочисленном делении допустимы только целочисленные подвыражения")
		| Ast.ErrNotRealTypeForRealDiv:
			O("В дробном делении допустимы только подвыражения дробного типа")
		| Ast.ErrNotIntSetElem:
			O("В качестве элементов множества допустимы только целые числа")
		| Ast.ErrSetElemOutOfRange:
			O("Элемент множества выходит за границы возможных значений - 0 .. 31")
		| Ast.ErrSetLeftElemBiggerRightElem:
			O("Левый элемент диапазона больше правого")
		| Ast.ErrAddExprDifferenTypes:
			O("Типы подвыражений в сложении несовместимы")
		| Ast.ErrNotNumberAndNotSetInMult:
			O("В выражениях *, /, DIV, MOD допустимы только числа и множества")
		| Ast.ErrNotNumberAndNotSetInAdd:
			O("В выражениях +, - допустимы только числа и множества")
		| Ast.ErrSignForBool:
			O("Унарный знак не применим к логическому выражению")
		| Ast.ErrRelationExprDifferenTypes:
			O("Типы подвыражений в сравнении не совпадают")
		| Ast.ErrExprInWrongTypes:
			O("Ast.ErrExprInWrongTypes")
		| Ast.ErrExprInRightNotSet:
			O("Ast.ErrExprInRightNotSet")
		| Ast.ErrExprInLeftNotInteger:
			O("Левый член выражения IN должен быть целочисленным")
		| Ast.ErrRelIncompatibleType:
			O("В сравнении выражения несовместимых типов")
		| Ast.ErrIsExtTypeNotRecord:
			O("Проверка IS применима только к записям")
		| Ast.ErrIsExtVarNotRecord:
			O("Левый член проверки IS должен иметь тип записи или указателя на неё")
		| Ast.ErrConstDeclExprNotConst:
			O("Постоянная сопоставляется выражению, невычислимым на этапе перевода")
		| Ast.ErrAssignIncompatibleType:
			O("Несовместимые типы в присваивании")
		| Ast.ErrCallNotProc:
			O("Вызов допустим только для процедур и переменных процедурного типа")
		| Ast.ErrCallIgnoredReturn:
			O("Возвращаемое значение не задействовано в выражении")
		| Ast.ErrCallExprWithoutReturn:
			O("Вызываемая процедура не возвращает значения")
		| Ast.ErrCallExcessParam:
			O("Лишние параметры при вызове процедуры")
		| Ast.ErrCallIncompatibleParamType:
			O("Несовместимый тип параметра")
		| Ast.ErrCallExpectVarParam:
			O("Параметр должен быть изменяемым значением")
		| Ast.ErrCallVarPointerTypeNotSame:
			O("Для переменного параметра - указателя должен использоваться аргумент того же типа")
		| Ast.ErrCallParamsNotEnough:
			O("Не хватает фактических параметров в вызове процедуры")
		| Ast.ErrCaseExprNotIntOrChar:
			O("Выражение в CASE должно быть целочисленным или литерой")
		| Ast.ErrCaseElemExprTypeMismatch:
			O("Метки CASE должно быть целочисленными или литерами")
		| Ast.ErrCaseElemDuplicate:
			O("Дублирование значения меток в CASE")
		| Ast.ErrCaseRangeLabelsTypeMismatch:
			O("Не совпадает тип меток CASE")
		| Ast.ErrCaseLabelLeftNotLessRight:
			O("Левая часть диапазона значений в метке CASE должна быть меньше правой")
		| Ast.ErrCaseLabelNotConst:
			O("Метки CASE должны быть константами")
		| Ast.ErrProcHasNoReturn:
			O("Процедура не имеет возвращаемого значения")
		| Ast.ErrReturnIncompatibleType:
			O("Тип возвращаемого значения не совместим типом, указанном в заголовке процедуры")
		| Ast.ErrExpectReturn:
			O("Ожидался возврат значения, так как в заголовке процедуры указан возвращаемый тип")
		| Ast.ErrDeclarationNotFound:
			O("Предварительное объявление имени не было найдено")
		| Ast.ErrConstRecursive:
			O("Недопустимое использование константы для задания собственного значения")
		| Ast.ErrImportModuleNotFound:
			O("Импортированный модуль не был найден")
		| Ast.ErrImportModuleWithError:
			O("Импортированный модуль содержит ошибки")
		| Ast.ErrDerefToNotPointer:
			O("Разыменовывание применено не к указателю")
		| Ast.ErrArrayItemToNotArray:
			O("Получение элемента не массива")
		| Ast.ErrArrayIndexNotInt:
			O("Индекс массива не целочисленный")
		| Ast.ErrArrayIndexNegative:
			O("Отрицательный индекс массива")
		| Ast.ErrArrayIndexOutOfRange:
			O("Индекс массива выходит за его границы")
		| Ast.ErrGuardExpectRecordExt:
			O("В защите типа ожидается расширенная запись")
		| Ast.ErrGuardExpectPointerExt:
			O("В защите типа ожидается указатель на расширенную запись")
		| Ast.ErrGuardedTypeNotExtensible:
			O("В защите типа переменная должна быть либо записью, либо указателем на запись")
		| Ast.ErrDotSelectorToNotRecord:
			O("Селектор элемента записи применён не к записи")
		| Ast.ErrDeclarationNotVar:
			O("Ожидалась переменная")
		| Ast.ErrForIteratorNotInteger:
			O("Итератор FOR не целочисленного типа")
		| Ast.ErrNotBoolInIfCondition:
			O("Выражение в охране условного оператора должно быть логическим")
		| Ast.ErrNotBoolInWhileCondition:
			O("Выражение в охране цикла WHILE должно быть логическим")
		| Ast.ErrWhileConditionAlwaysFalse:
			O("Охрана цикла WHILE всегда ложна")
		| Ast.ErrWhileConditionAlwaysTrue:
			O("Цикл бесконечен, так как охрана WHILE всегда истинна")
		| Ast.ErrNotBoolInUntil:
			O("Выражение в условии завершения цикла REPEAT должно быть логическим")
		| Ast.ErrUntilAlwaysFalse:
			O("Цикл бесконечен, так как условие завершения всегда ложно")
		| Ast.ErrUntilAlwaysTrue:
			O("Условие завершения всегда истинно")
		| Ast.ErrDeclarationIsPrivate:
			O("Объявление не экспортировано")
		| Ast.ErrNegateNotBool:
			O("Логическое отрицание применено не к логическому типу")
		| Ast.ErrConstAddOverflow:
			O("Переполнение при сложении постоянных")
		| Ast.ErrConstSubOverflow:
			O("Переполнение при вычитании постоянных")
		| Ast.ErrConstMultOverflow:
			O("Переполнение при умножении постоянных")
		| Ast.ErrConstDivByZero:
			O("Деление на 0")
		| Ast.ErrValueOutOfRangeOfByte:
			O("Значение выходит за границы BYTE")
		| Ast.ErrValueOutOfRangeOfChar:
			O("Значение выходит за границы CHAR")
		| Ast.ErrExpectIntExpr:
			O("Ожидается целочисленное выражение")
		| Ast.ErrExpectConstIntExpr:
			O("Ожидается константное целочисленное выражение")
		| Ast.ErrForByZero:
			O("Шаг итератора не может быть равен 0")
		| Ast.ErrByShouldBePositive:
			O("Для прохода от меньшего к большему шаг итератора должен быть > 0")
		| Ast.ErrByShouldBeNegative:
			O("Для прохода от большего к меньшему шаг итератора должен быть < 0")
		| Ast.ErrForPossibleOverflow:
			O("Во время итерации в FOR возможно переполнение")
		| Ast.ErrVarUninitialized:
			O("Использование не инициализированной переменной")
		END
	ELSE
		CASE code OF
		  Scanner.ErrUnexpectChar:
			O("Неожиданный символ в тексте")
		| Scanner.ErrNumberTooBig:
			O("Значение константы слишком велико")
		| Scanner.ErrRealScaleTooBig:
			O("ErrRealScaleTooBig")
		| Scanner.ErrWordLenTooBig:
			O("ErrWordLenTooBig")
		| Scanner.ErrExpectHOrX:
			O("В конце 16-ричного числа ожидается 'H' или 'X'")
		| Scanner.ErrExpectDQuote:
			O("Ожидалась "); O(Utf8.DQuote)
		| Scanner.ErrExpectDigitInScale:
			O("ErrExpectDigitInScale")
		| Scanner.ErrUnclosedComment:
			O("Незакрытый комментарий")

		| Parser.ErrExpectModule:
			O("Ожидается 'MODULE'")
		| Parser.ErrExpectIdent:
			O("Ожидается имя")
		| Parser.ErrExpectColon:
			O("Ожидается ':'")
		| Parser.ErrExpectSemicolon:
			O("Ожидается ';'")
		| Parser.ErrExpectEnd:
			O("Ожидается 'END'")
		| Parser.ErrExpectDot:
			O("Ожидается '.'")
		| Parser.ErrExpectModuleName:
			O("Ожидается имя модуля")
		| Parser.ErrExpectEqual:
			O("Ожидается '='")
		| Parser.ErrExpectBrace1Close:
			O("Ожидается ')'")
		| Parser.ErrExpectBrace2Close:
			O("Ожидается ']'")
		| Parser.ErrExpectBrace3Close:
			O("Ожидается '}'")
		| Parser.ErrExpectOf:
			O("Ожидается OF")
		| Parser.ErrExpectTo:
			O("Ожидается TO")
		| Parser.ErrExpectStructuredType:
			O("Ожидается структурный тип: массив, запись, указатель, процедурный")
		| Parser.ErrExpectRecord:
			O("Ожидается запись")
		| Parser.ErrExpectStatement:
			O("Ожидается оператор")
		| Parser.ErrExpectThen:
			O("Ожидается THEN")
		| Parser.ErrExpectAssign:
			O("Ожидается :=")
		| Parser.ErrExpectVarRecordOrPointer:
			O("Ожидается переменная типа запись либо указателя на неё")
		| Parser.ErrExpectType:
			O("Ожидается тип")
		| Parser.ErrExpectUntil:
			O("Ожидается UNTIL")
		| Parser.ErrExpectDo:
			O("Ожидается DO")
		| Parser.ErrExpectDesignator:
			O("Ожидается обозначение")
		| Parser.ErrExpectProcedure:
			O("Ожидается процедура")
		| Parser.ErrExpectConstName:
			O("Ожидается имя константы")
		| Parser.ErrExpectProcedureName:
			O("Ожидается завершающее имя процедуры")
		| Parser.ErrExpectExpression:
			O("Ожидается выражение")
		| Parser.ErrExcessSemicolon:
			O("Лишняя ';'")
		| Parser.ErrEndModuleNameNotMatch:
			O("Завершающее имя в конце модуля не совпадает с его именем")
		| Parser.ErrArrayDimensionsTooMany:
			O("Слишком большая n-мерность массива")
		| Parser.ErrEndProcedureNameNotMatch:
			O("Завершающее имя в теле процедуры не совпадает с её именем")
		| Parser.ErrFunctionWithoutBraces:
			O("Объявление процедуры с возвращаемым значением не содержит скобки")
		| Parser.ErrArrayLenLess1:
			O("Длина массива должна быть > 0")
		| Parser.ErrExpectIntOrStrOrQualident:
			O("Ожидалось число или строка")
		END
	END

END ErrorMessage;

PROCEDURE PrintErrors(err: Ast.Error);
VAR i: INTEGER;
BEGIN
	Out.String("Найдены ошибки: "); Out.Ln;
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

PROCEDURE IsEqualStr(str: ARRAY OF CHAR; ofs: INTEGER; sample: ARRAY OF CHAR)
                    : BOOLEAN;
VAR i: INTEGER;
BEGIN
	i := 0;
	WHILE (str[ofs] = sample[i]) & (sample[i] # Utf8.Null) DO
		INC(ofs);
		INC(i)
	END
	RETURN str[ofs] = sample[i]
END IsEqualStr;

PROCEDURE CopyPath(VAR str: ARRAY OF CHAR; VAR sing: SET;
                   VAR cDirs: ARRAY OF CHAR; VAR cc: ARRAY OF CHAR;
                   VAR arg: INTEGER): INTEGER;
VAR i, dirsOfs, ccLen, count, optLen: INTEGER;
	ret: INTEGER;
	opt: ARRAY 256 OF CHAR;
BEGIN
	i := 0;
	dirsOfs := 0;
	cDirs[0] := Utf8.Null;
	ccLen := 0;
	count := 0;
	sing := {};
	ret := ErrNo;
	optLen := 0;
	WHILE (ret = ErrNo) & (count < 32)
	    & (arg < CLI.count) & CLI.Get(opt, optLen, arg) & ~IsEqualStr(opt, 0, "--")
	DO
		optLen := 0;
		IF (opt = "-i") OR (opt = "-m") THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := ErrNotEnoughArgs
			ELSIF CLI.Get(str, i, arg) THEN
				IF opt = "-i" THEN
					INCL(sing, count)
				END;
				INC(i);
				INC(count)
			ELSE
				ret := ErrTooLongModuleDirs
			END
		ELSIF opt = "-c" THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := ErrNotEnoughArgs
			ELSIF CLI.Get(cDirs, dirsOfs, arg) & (dirsOfs < LEN(cDirs)) THEN
				cDirs[dirsOfs] := Utf8.Null;
				Log.Str("cDirs = ");
				Log.StrLn(cDirs)
			ELSE
				ret := ErrTooLongCDirs
			END
		ELSIF opt = "-cc" THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := ErrNotEnoughArgs
			ELSIF CLI.Get(cc, ccLen, arg) THEN
				DEC(ccLen)
			ELSE
				ret := ErrTooLongCc
			END
		ELSE
			ret := ErrUnexpectArg
		END;
		INC(arg)
	END;
	IF i + 1 < LEN(str) THEN
		str[i + 1] := Utf8.Null;
		IF count >= 32 THEN
			ret := ErrTooManyModuleDirs
		END;
	ELSE
		ret := ErrTooLongModuleDirs;
		str[LEN(str) - 1] := Utf8.Null;
		str[LEN(str) - 2] := Utf8.Null;
		str[LEN(str) - 3] := "#"
	END
	RETURN ret
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

PROCEDURE AddModule(mp: ModuleProvider; m: Ast.Module; sing: BOOLEAN);
BEGIN
	ASSERT(m.module = m);
	m.module := NIL;
	IF mp.modules.first = NIL THEN
		mp.modules.first := m
	ELSE
		mp.modules.last.module := m
	END;
	mp.modules.last := m;
	IF sing THEN
		m.mark := TRUE
	END
END AddModule;

PROCEDURE GetModule(p: Ast.Provider; host: Ast.Module;
                    name: ARRAY OF CHAR; ofs, end: INTEGER): Ast.Module;
VAR m: Ast.Module;
	source: File.In;
	mp: ModuleProvider;
	pathOfs, pathInd: INTEGER;

	PROCEDURE Open(p: ModuleProvider; VAR pathOfs: INTEGER;
	               name: ARRAY OF CHAR; ofs, end: INTEGER): File.In;
	VAR n: ARRAY 1024 OF CHAR;
		len, l: INTEGER;
		in: File.In;
	BEGIN
		len := Strings.CalcLen(p.path, pathOfs);
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
		pathInd := -1;
		pathOfs := 0;
		REPEAT
			source := Open(mp, pathOfs, name, ofs, end);
			INC(pathInd)
		UNTIL (source # NIL) OR (mp.path[pathOfs] = Utf8.Null);
		IF source # NIL THEN
			m := Parser.Parse(source, p, mp.opt);
			File.CloseIn(source);
			AddModule(mp, m, pathInd IN mp.sing)
		ELSE
			Out.String("Не получается найти или открыть файл импортированного модуля");
			Out.Ln
		END
	END
	RETURN m
END GetModule;

PROCEDURE OpenCOutput(VAR interface, implementation: File.Out;
                      module: Ast.Module; isMain: BOOLEAN;
                      VAR dir: ARRAY OF CHAR; dirLen: INTEGER): INTEGER;
VAR destLen: INTEGER;
	ret: INTEGER;
BEGIN
	interface := NIL;
	implementation := NIL;
	destLen := dirLen;
	IF ~Strings.CopyChars(dir, destLen, "/", 0, 1)
	OR ~Strings.CopyToChars(dir, destLen, module.name)
	OR (destLen > LEN(dir) - 3)
	THEN
		ret := ErrTooLongOutName
	ELSE
		dir[destLen] := ".";
		dir[destLen + 2] := Utf8.Null;
		IF ~isMain THEN
			dir[destLen + 1] := "h";
			interface := File.OpenOut(dir)
		END;
		IF  ~isMain & (interface = NIL) THEN
			ret := ErrOpenH
		ELSE
			dir[destLen + 1] := "c";
			Out.String(dir); Out.Ln;
			implementation := File.OpenOut(dir);
			IF implementation = NIL THEN
				File.CloseOut(interface);
				ret := ErrOpenC
			ELSE
				ret := ErrNo
			END
		END
	END
	RETURN ret
END OpenCOutput;

PROCEDURE NewProvider(): ModuleProvider;
VAR mp: ModuleProvider;
BEGIN
	NEW(mp); Ast.ProviderInit(mp, GetModule);
	Parser.DefaultOptions(mp.opt);
	mp.opt.printError := ErrorMessage;
	mp.modules.first := NIL;
	mp.modules.last := NIL;
	mp.extLen := 0;
	RETURN mp
END NewProvider;

PROCEDURE PrintUsage;
	PROCEDURE S(s: ARRAY OF CHAR);
	BEGIN
		Out.String(s);
		Out.Ln
	END S;
BEGIN
S("Использование: ");
S("  1) o7c help");
S("  2) o7c to-c исх.mod вых.каталог {-m путьКмодулям | -i кат.с_интерф-ми_мод-ми}");
S("В случае успешной трансляции создаст в выходном каталоге набор .h и .c-файлов,");
S("соответствующих как самому исходному модулю, так и используемых им модулей,");
S("кроме лежащих в каталогах, указанным после опции -i, служащих интерфейсами");
S("для других .h и .с-файлов.");
S("  3) o7c to-bin исх.mod результат {-m путь_к_м. | -i к.с_инт_м. | -c .h,c-файлы}");
S("После трансляции указанного модуля вызывает компилятор C для сбора результата -");
S("исполнимого файла, в состав которого также войдут .h и .c файлы, находящиеся");
S("в каталогах, указанных после -c.");
S("  4) o7c run исх.mod {-m путь_к_м. | -i к.с_инт_м. | -c .h,c-файлы} -- параметры");
S("Запускает собранный модуль с параметрами, указанными после --")
END PrintUsage;

PROCEDURE ErrMessage(err: INTEGER; cmd: ARRAY OF CHAR);
BEGIN
	IF err # ErrParse THEN
		CASE err OF
		  ErrWrongArgs:
			PrintUsage
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
		| ErrUnknownCommand:
			Out.String("Неизвестная команда: ");
			Out.String(cmd); Out.Ln;
			PrintUsage
		| ErrNotEnoughArgs:
			Out.String("Недостаточно аргументов для команды: ");
			Out.String(cmd)
		| ErrTooLongModuleDirs:
			Out.String("Суммарная длина путей с модулями слишком велика")
		| ErrTooManyModuleDirs:
			Out.String("Cлишком много путей с модулями")
		| ErrTooLongCDirs:
			Out.String("Суммарная длина путей с .c-файлами слишком велика")
		| ErrTooLongCc:
			Out.String("Длина опций компилятора C слишком велика")
		| ErrCCompiler:
			Out.String("Ошибка при вызове компилятора C")
		| ErrTooLongRunArgs:
			Out.String("Слишком длинные параметры командной строки")
		| ErrUnexpectArg:
			Out.String("Неожиданный аргумент")
		END;
		Out.Ln
	END
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

PROCEDURE GenerateC(module: Ast.Module; isMain: BOOLEAN; opt: GeneratorC.Options;
                    VAR dir: ARRAY OF CHAR; dirLen: INTEGER): INTEGER;
VAR imp: Ast.Declaration;
	ret: INTEGER;
	iface, impl: File.Out;
BEGIN
	module.mark := TRUE;

	ret := ErrNo;
	imp := module.import;
	WHILE (ret = ErrNo) & (imp # NIL) & (imp IS Ast.Import) DO
		IF ~imp.module.mark THEN
			ret := GenerateC(imp.module, FALSE, opt, dir, dirLen)
		END;
		imp := imp.next
	END;
	IF ret = ErrNo THEN
		ret := OpenCOutput(iface, impl, module, isMain, dir, dirLen - 1);
		IF ret = ErrNo THEN
			GeneratorC.Generate(iface, impl, module, opt);
			File.CloseOut(iface);
			File.CloseOut(impl)
		END
	END
	RETURN ret
END GenerateC;

PROCEDURE GetTempOutC(VAR dirCOut, bin: ARRAY OF CHAR; name: Strings.String)
                     : INTEGER;
VAR len, cmdLen, binLen: INTEGER;
	ok: BOOLEAN;
	cmd: ARRAY 6144 OF CHAR;
BEGIN
	dirCOut := "/tmp/o7c-";
	len := Strings.CalcLen(dirCOut, 0);
	ok := Strings.CopyToChars(dirCOut, len, name);
	ASSERT(ok);
	IF bin[0] = Utf8.Null THEN
		binLen := 0;
		ok := Strings.CopyChars(bin, binLen, dirCOut, 0, len)
		    & Strings.CopyCharsNull(bin, binLen, "/")
		    & Strings.CopyToChars(bin, binLen, name);
		ASSERT(ok)
	END;
	cmd := "mkdir -p ";
	cmdLen := Strings.CalcLen(cmd, 0);
	ok := Strings.CopyChars(cmd, cmdLen, dirCOut, 0, len);
	ASSERT(ok);
	IF Exec.Do(cmd) = Exec.Ok THEN
		cmd := "rm -f ";
		cmdLen := Strings.CalcLen(cmd, 0);
		ok := Strings.CopyChars(cmd, cmdLen, dirCOut, 0, len)
		    & Strings.CopyCharsNull(cmd, cmdLen, "/*");
		ASSERT(ok);
		ok := Exec.Do(cmd) = Exec.Ok
	END
	RETURN len + 1
END GetTempOutC;

PROCEDURE ToC(res: INTEGER): INTEGER;
VAR ret: INTEGER;
	src: ARRAY 1024 OF CHAR;
	srcLen: INTEGER;
	resPath: ARRAY 1024 OF CHAR;
	resPathLen: INTEGER;
	cDirs, cc: ARRAY 4096 OF CHAR;
	mp: ModuleProvider;
	module: Ast.Module;
	source: File.In;
	opt: GeneratorC.Options;
	arg: INTEGER;

	PROCEDURE Bin(module: Ast.Module; opt: GeneratorC.Options;
	              cDirs, cc: ARRAY OF CHAR; VAR bin: ARRAY OF CHAR): INTEGER;
	VAR outC: ARRAY 1024 OF CHAR;
		cmd: ARRAY 8192 OF CHAR;
		outCLen, cmdLen: INTEGER;
		ret, i, len: INTEGER;
		ok: BOOLEAN;
	BEGIN
		outCLen := GetTempOutC(outC, bin, module.name);
		ret := GenerateC(module, TRUE, opt, outC, outCLen);
		IF ret = ErrNo THEN
			IF cc[0] = Utf8.Null THEN
				cmd := "cc -g -O1";
				cmdLen := Strings.CalcLen(cmd, 0)
			ELSE
				cmdLen := 0
			END;
			ok := ((cmdLen > 0) OR Strings.CopyCharsNull(cmd, cmdLen, cc))
			    & Strings.CopyCharsNull(cmd, cmdLen, " -o ")
			    & Strings.CopyCharsNull(cmd, cmdLen, bin)
			    & Strings.CopyCharsNull(cmd, cmdLen, " ")
			    & Strings.CopyChars(cmd, cmdLen, outC, 0, outCLen)
			    & Strings.CopyCharsNull(cmd, cmdLen, "*.c -I")
			    & Strings.CopyChars(cmd, cmdLen, outC, 0, outCLen - 1);
			i := 0;
			WHILE ok & (cDirs[i] # Utf8.Null) DO
				len := Strings.CalcLen(cDirs, i);
				ok := Strings.CopyCharsNull(cmd, cmdLen, " ")
				    & Strings.CopyChars(cmd, cmdLen, cDirs, i, i + len)
				    & Strings.CopyCharsNull(cmd, cmdLen, "/*.c -I")
				    & Strings.CopyChars(cmd, cmdLen, cDirs, i, i + len);
				i := i + len + 1
			END;
			Out.String(cmd); Out.Ln;
			ASSERT(ok);
			IF Exec.Do(cmd) # Exec.Ok THEN
				ret := ErrCCompiler
			END
		END
		RETURN ret
	END Bin;

	PROCEDURE Run(bin: ARRAY OF CHAR; arg: INTEGER): INTEGER;
	VAR cmd, buf: ARRAY 65536 OF CHAR;
		len, blen: INTEGER;
		ret: INTEGER;

		PROCEDURE Copy(VAR d: ARRAY OF CHAR; VAR i: INTEGER; s: ARRAY OF CHAR)
		              : BOOLEAN;
		VAR j: INTEGER;
		BEGIN
			j := 0;
			WHILE (i < LEN(d) - 2) & (s[j] = Utf8.DQuote) DO
				d[i] := "\";
				d[i + 1] := Utf8.DQuote;
				INC(i, 2);
				INC(j)
			ELSIF (i < LEN(d) - 1) & (s[j] # Utf8.Null) DO
				d[i] := s[j];
				INC(i);
				INC(j)
			END;
			d[i] := Utf8.Null
			RETURN s[j] = Utf8.Null
		END Copy;
	BEGIN
		len := Strings.CalcLen(bin, 0);
		cmd := bin;
		INC(arg);
		blen := 0;
		WHILE (arg < CLI.count)
		    & Strings.CopyCharsNull(cmd, len, " ")
		    & Strings.CopyCharsNull(cmd, len, Utf8.DQuote)
		    & CLI.Get(buf, blen, arg) & Copy(cmd, len, buf)
		    & Strings.CopyCharsNull(cmd, len, Utf8.DQuote)
		DO
			blen := 0;
			INC(arg)
		END;
		IF arg >= CLI.count THEN
			CLI.SetExitCode(Exec.Do(cmd));
			ret := ErrNo
		ELSE
			ret := ErrTooLongRunArgs
		END
		RETURN ret
	END Run;
BEGIN
	ASSERT(res IN {ResultC .. ResultRun});

	srcLen := 0;
	arg := 3 + ORD(res # ResultRun);
	IF CLI.count < arg THEN
		ret := ErrNotEnoughArgs
	ELSIF ~CLI.Get(src, srcLen, 2) THEN
		ret := ErrTooLongSourceName
	ELSE
		mp := NewProvider();
		mp.extLen := CopyExt(mp.fileExt, src);
		ret := CopyPath(mp.path, mp.sing, cDirs, cc, arg);
		IF ret = ErrNo THEN
			source := File.OpenIn(src);
			IF source = NIL THEN
				ret := ErrOpenSource
			ELSE
				module := Parser.Parse(source, mp, mp.opt);
				File.CloseIn(source);
				resPathLen := 0;
				resPath[0] := Utf8.Null;
				IF module = NIL THEN
					ret := ErrParse
				ELSIF module.errors # NIL THEN
					PrintErrors(module.errors);
					ret := ErrParse
				ELSIF (res # ResultRun) & ~CLI.Get(resPath, resPathLen, 3) THEN
					ret := ErrTooLongOutName
				ELSE
					opt := GeneratorC.DefaultOptions();
					CASE res OF
					  ResultC:
						ret := GenerateC(module, TRUE, opt, resPath, resPathLen)
					| ResultBin, ResultRun:
						ret := Bin(module, opt, cDirs, cc, resPath);
						IF (res = ResultRun) & (ret = ErrNo) THEN
							ret := Run(resPath, arg)
						END
					END
				END
			END
		END
	END
	RETURN ret
END ToC;

PROCEDURE Start*;
VAR cmd: ARRAY 1024 OF CHAR;
	cmdLen: INTEGER;
	ret: INTEGER;
BEGIN
	Out.Open;
	Log.Turn(FALSE);

	cmdLen := 0;
	IF (CLI.count <= 1) OR ~CLI.Get(cmd, cmdLen, 1) THEN
		ret := ErrWrongArgs
	ELSE
		ret := ErrNo;
		IF cmd = "help" THEN
			PrintUsage;
			Out.Ln
		ELSIF cmd = "to-c" THEN
			ret := ToC(ResultC)
		ELSIF cmd = "to-bin" THEN
			ret := ToC(ResultBin)
		ELSIF cmd = "run" THEN
			ret := ToC(ResultRun)
		ELSE
			ret := ErrUnknownCommand
		END
	END;
	IF ret # ErrNo THEN
		CLI.SetExitCode(1);
		ErrMessage(ret, cmd)
	END
END Start;

BEGIN
	Start
END Translator.

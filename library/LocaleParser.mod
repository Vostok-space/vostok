(* Copyright 2018-2019 ComdivByZero
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *)

(* Разборщик строки с локалью на подстроки. Формат локали соответствует тому,
 * что можно получить в значении переменной окружения LANG в POSIX.
 *
 * Пример:
 *   locale = "ru_RU.UTF-8"
 *  ->
 *   lang = "ru"     state = "RU"     enc = "UTF-8"
 *)
MODULE LocaleParser;

  IMPORT Chars0X;

  PROCEDURE ParseByOfs*(locale: ARRAY OF CHAR; ofs: INTEGER;
                        VAR lang, state, enc: ARRAY OF CHAR): BOOLEAN;
  VAR tOfs: INTEGER;
      ok: BOOLEAN;
  BEGIN
    ASSERT(LEN(lang)  > 2);
    ASSERT(LEN(state) > 2);
    ASSERT(LEN(enc)   > 2);

    tOfs := 0;
    ok := Chars0X.CopyAtMost(lang, tOfs, locale, ofs, 2)
        & (locale[ofs] = "_");
    IF ok THEN
      INC(ofs);
      tOfs := 0;
      ok := Chars0X.CopyAtMost(state, tOfs, locale, ofs, 2)
          & (locale[ofs] = ".");
      IF ok THEN
        INC(ofs);
        tOfs := 0;
        ok := Chars0X.Copy(enc, tOfs, locale, ofs)
      END
    END
  RETURN
    ok
  END ParseByOfs;

  PROCEDURE Parse*(locale: ARRAY OF CHAR; VAR lang, state, enc: ARRAY OF CHAR)
                  : BOOLEAN;
  RETURN
    ParseByOfs(locale, 0, lang, state, enc)
  END Parse;

END LocaleParser.

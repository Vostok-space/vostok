Partial wrapper for Windows-specific windows.h

Copyright 2022 ComdivByZero

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

MODULE Windows;

CONST
  Cp866*  = 866;
  Cp1251* = 1251;
  Utf8*   = 65001;

  (* Неполный список MS-LSID *)
  LangNeutral*  = 00H;
  Arabic*       = 01H;
  Bulgarian*    = 02H;
  Catalan*      = 03H;
  Chinese*      = 04H;
  Czech*        = 05H;
  Danish*       = 06H;
  Geramn*       = 07H;
  Greek*        = 08H;
  English*      = 09H;
  Spanish*      = 0AH;
  Finnish*      = 0BH;
  French*       = 0CH;
  Hebrew*       = 0DH;
  Hungarian*    = 0EH;
  Icelandic*    = 0FH;
  Italian*      = 10H;
  Japanese*     = 11H;
  Korean*       = 12H;
  Dutch*        = 13H;
  Norwegian*    = 14H;
  Polish*       = 15H;
  Portuguese*   = 16H;
  Romansh*      = 17H;
  Romanian*     = 18H;
  Russian*      = 19H;
  Croatian*     = 1AH;
  Slovak*       = 1BH;
  Albanian*     = 1CH;
  Swedish*      = 1DH;
  Thai*         = 1EH;
  Turkish*      = 1FH;
  Urdu*         = 20H;
  Indonesian*   = 21H;
  Ukrainian*    = 22H;
  Belarusian*   = 23H;
  Slovenian*    = 24H;
  Estonian*     = 25H;
  Latvian*      = 26H;
  Lithuanian*   = 27H;
  Tajik*        = 28H;
  Farsi*        = 29H;
  Vietnamese*   = 2AH;
  Armenian*     = 2BH;
  Azeri*        = 2CH;
  Basque*       = 2DH;

  (* TODO more*)
  Macedonian*   = 2FH;
  Afrikaans*    = 30H;
  Georgian*     = 37H;
  Hindi*        = 39H;
  Kazakh*       = 3FH;
  Kyrgyz*       = 40H;
  Uzbek*        = 43H;
  Tatar*        = 44H;

(* Возвращает MS-LCID *)
PROCEDURE GetUserDefaultUILanguage*(): INTEGER;
RETURN
  LangNeutral
END GetUserDefaultUILanguage;

PROCEDURE SetConsoleCP*(code: INTEGER): BOOLEAN;
RETURN
  FALSE
END SetConsoleCP;

PROCEDURE SetConsoleOutputCP*(code: INTEGER): BOOLEAN;
RETURN
  FALSE
END SetConsoleOutputCP;

END Windows.

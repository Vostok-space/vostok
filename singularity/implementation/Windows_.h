/*
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
*/

#if !defined HEADER_GUARD_Windows
#    define  HEADER_GUARD_Windows 1

#define Windows_Cp866_cnst 866
#define Windows_Cp1251_cnst 1251
#define Windows_Utf8_cnst 65001

/* Неполный список MS-LSID */
#define Windows_LangNeutral_cnst  0
#define Windows_Arabic_cnst       1
#define Windows_Bulgarian_cnst    2
#define Windows_Catalan_cnst      3
#define Windows_Chinese_cnst      4
#define Windows_Czech_cnst        5
#define Windows_Danish_cnst       6
#define Windows_Geramn_cnst       7
#define Windows_Greek_cnst        8
#define Windows_English_cnst      9
#define Windows_Spanish_cnst      10
#define Windows_Finnish_cnst      11
#define Windows_French_cnst       12
#define Windows_Hebrew_cnst       13
#define Windows_Hungarian_cnst    14
#define Windows_Icelandic_cnst    15
#define Windows_Italian_cnst      16
#define Windows_Japanese_cnst     17
#define Windows_Korean_cnst       18
#define Windows_Dutch_cnst        19
#define Windows_Norwegian_cnst    20
#define Windows_Polish_cnst       21
#define Windows_Portuguese_cnst   22
#define Windows_Romansh_cnst      23
#define Windows_Romanian_cnst     24
#define Windows_Russian_cnst      25
#define Windows_Croatian_cnst     26
#define Windows_Slovak_cnst       27
#define Windows_Albanian_cnst     28
#define Windows_Swedish_cnst      29
#define Windows_Thai_cnst         30
#define Windows_Turkish_cnst      31
#define Windows_Urdu_cnst         32
#define Windows_Indonesian_cnst   33
#define Windows_Ukrainian_cnst    34
#define Windows_Belarusian_cnst   35
#define Windows_Slovenian_cnst    36
#define Windows_Estonian_cnst     37
#define Windows_Latvian_cnst      38
#define Windows_Lithuanian_cnst   39
#define Windows_Tajik_cnst        40
#define Windows_Farsi_cnst        41
#define Windows_Vietnamese_cnst   42
#define Windows_Armenian_cnst     43
#define Windows_Azeri_cnst        44
#define Windows_Basque_cnst       45
#define Windows_Macedonian_cnst   47
#define Windows_Afrikaans_cnst    48
#define Windows_Georgian_cnst     55
#define Windows_Faeroese_cnst     56
#define Windows_Hindi_cnst        57
#define Windows_Kazakh_cnst       63
#define Windows_Kyrgyz_cnst       64
#define Windows_Uzbek_cnst        67
#define Windows_Tatar_cnst        68

extern o7_int_t Windows_GetUserDefaultUILanguage(void);

extern o7_cbool
  Windows_SetConsoleCP      (o7_int_t code),
  Windows_SetConsoleOutputCP(o7_int_t code);

O7_INLINE void Windows_init(void) { ; }
O7_INLINE void Windows_done(void) { ; }
#endif

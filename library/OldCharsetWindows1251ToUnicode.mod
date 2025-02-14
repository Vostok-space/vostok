Direct conversion code of old charset Windows-1251 to Unicode code point.

Copyright 2025 ComdivByZero

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

MODULE OldCharsetWindows1251ToUnicode;

 CONST Supported* = TRUE;

 PROCEDURE Do*(wc: INTEGER): INTEGER;
 VAR uc: INTEGER;
 BEGIN
  ASSERT(wc DIV 100H = 0);

  IF wc < 80H THEN
    uc := wc
  ELSIF wc >= 0C0H THEN
    uc := wc + (410H - 0C0H)
  ELSE
    CASE wc OF
      080H: uc := 0402H (* Ђ *)
    | 081H: uc := 0403H (* Ѓ *)
    | 082H: uc := 201AH (* ‚ *)
    | 083H: uc := 0453H (* ѓ *)
    | 084H: uc := 201EH (* „ *)
    | 085H: uc := 2026H (* … *)
    | 086H: uc := 2020H (* † *)
    | 087H: uc := 2021H (* ‡ *)
    | 088H: uc := 20ACH (* € *)
    | 089H: uc := 2030H (* ‰ *)
    | 08AH: uc := 0409H (* Љ *)
    | 08BH: uc := 2039H (* ‹ *)
    | 08CH: uc := 040AH (* Њ *)
    | 08DH: uc := 040CH (* Ќ *)
    | 08EH: uc := 040BH (* Ћ *)
    | 08FH: uc := 040FH (* Џ *)
    | 090H: uc := 0452H (* ђ *)
    | 091H: uc := 2018H (* ‘ *)
    | 092H: uc := 2019H (* ’ *)
    | 093H: uc := 201CH (* “ *)
    | 094H: uc := 201DH (* ” *)
    | 095H: uc := 2022H (* • *)
    | 096H: uc := 2013H (* – *)
    | 097H: uc := 2014H (* — *)
    | 098H: uc := 0FFFFH (* 98H отсутствует в самой Windows1251 *)
    | 099H: uc := 2122H (* ™ *)
    | 09AH: uc := 0459H (* љ *)
    | 09BH: uc := 203AH (* › *)
    | 09CH: uc := 045AH (* њ *)
    | 09DH: uc := 045CH (* ќ *)
    | 09EH: uc := 045BH (* ћ *)
    | 09FH: uc := 045FH (* џ *)
    | 0A0H: uc :=  0A0H (* Неразрывный пробел *)
    | 0A1H: uc := 040EH (* Ў *)
    | 0A2H: uc := 045EH (* ў *)
    | 0A3H: uc := 0408H (* Ј *)
    | 0A4H: uc := 00A4H (* ¤ *)
    | 0A5H: uc := 0490H (* Ґ *)
    | 0A6H: uc := 00A6H (* ¦ *)
    | 0A7H: uc := 00A7H (* § *)
    | 0A8H: uc := 0401H (* Ё *)
    | 0A9H: uc :=  0A9H (* © *)
    | 0AAH: uc := 0404H (* Є *)
    | 0ABH: uc :=  0ABH (* « *)
    | 0ACH: uc :=  0ACH (* ¬ *)
    | 0ADH: uc :=  0ADH (* мягкий перенос *)
    | 0AEH: uc :=  0AEH (* ® *)
    | 0AFH: uc := 0407H (* Ї *)
    | 0B0H: uc :=  0B0H (* ° *)
    | 0B1H: uc :=  0B1H (* ± *)
    | 0B2H: uc := 0406H (* І *)
    | 0B3H: uc := 0456H (* і *)
    | 0B4H: uc := 0491H (* ґ *)
    | 0B5H: uc :=  0B5H (* µ *)
    | 0B6H: uc :=  0B6H (* ¶ *)
    | 0B7H: uc :=  0B7H (* · *)
    | 0B8H: uc := 0451H (* ё *)
    | 0B9H: uc := 2116H (* № *)
    | 0BAH: uc := 0454H (* є *)
    | 0BBH: uc :=  0BBH (* » *)
    | 0BCH: uc := 0458H (* ј *)
    | 0BDH: uc := 0405H (* Ѕ *)
    | 0BEH: uc := 0455H (* ѕ *)
    | 0BFH: uc := 0457H (* ї *)
    END
  END
 RETURN
  uc
 END Do;

END OldCharsetWindows1251ToUnicode.

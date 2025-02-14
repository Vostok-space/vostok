Direct conversion code of old charset Windows-1251 to UTF-8.
Currently not supported.

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

MODULE OldCharsetWindows1251ToUtf8;

 CONST Supported* = TRUE;

 PROCEDURE Two(VAR out: ARRAY OF CHAR; VAR i: INTEGER; c0, c1: CHAR): BOOLEAN;
 VAR ok: BOOLEAN;
 BEGIN
  ok := i < LEN(out) - 2;
  IF ok THEN
    out[i    ] := c0;
    out[i + 1] := c1;
    INC(i, 2)
  END
 RETURN
  ok
 END Two;

 PROCEDURE Three(VAR out: ARRAY OF CHAR; VAR i: INTEGER; c0, c1, c2: CHAR): BOOLEAN;
 VAR ok: BOOLEAN;
 BEGIN
  ok := i < LEN(out) - 3;
  IF ok THEN
    out[i    ] := c0;
    out[i + 1] := c1;
    out[i + 2] := c2;
    INC(i, 3)
  END
 RETURN
  ok
 END Three;

 PROCEDURE Do*(VAR out: ARRAY OF CHAR; VAR ofs: INTEGER; wc: INTEGER): BOOLEAN;
 VAR ok: BOOLEAN;
 BEGIN
  ASSERT(wc DIV 100H = 0);
  ASSERT((0 <= ofs) & (ofs < LEN(out) - 1));

  IF wc < 80H THEN
    ok := ofs < LEN(out);
    IF ok THEN
      out[ofs] := CHR(wc);
      INC(ofs)
    END
  ELSIF wc >= 0C0H THEN
    IF wc < 0F0H THEN
      ok := Two(out, ofs, 0D0X, CHR(wc + (410H - 0C0H - 400H + 80H)))
    ELSE
      ok := Two(out, ofs, 0D1X, CHR(wc + (410H - 0C0H - 440H + 80H)))
    END
  ELSE
    CASE wc OF
      080H: ok := Two(out, ofs, 0D0X, 82X); (* Ђ *)
    | 081H: ok := Two(out, ofs, 0D0X, 83X); (* Ѓ *)
    | 082H: ok := Three(out, ofs, 0E2X, 80X, 9AX); (* ‚ *)
    | 083H: ok := Two(out, ofs, 0D1X, 93X); (* ѓ *)
    | 084H: ok := Three(out, ofs, 0E2X, 80X, 9EX); (* „ *)
    | 085H: ok := Three(out, ofs, 0E2X, 80X, 0A6X); (* … *)
    | 086H: ok := Three(out, ofs, 0E2X, 80X, 0A0X); (* † *)
    | 087H: ok := Three(out, ofs, 0E2X, 80X, 0A1X); (* ‡ *)
    | 088H: ok := Three(out, ofs, 0E2X, 82X, 0ACX); (* € *)
    | 089H: ok := Three(out, ofs, 0E2X, 80X, 0B0X); (* ‰ *)
    | 08AH: ok := Two(out, ofs, 0D0X, 89X); (* Љ *)
    | 08BH: ok := Three(out, ofs, 0E2X, 80X, 0B9X); (* ‹ *)
    | 08CH: ok := Two(out, ofs, 0D0X, 8AX); (* Њ *)
    | 08DH: ok := Two(out, ofs, 0D0X, 8CX); (* Ќ *)
    | 08EH: ok := Two(out, ofs, 0D0X, 8BX); (* Ћ *)
    | 08FH: ok := Two(out, ofs, 0D0X, 8FX); (* Џ *)
    | 090H: ok := Two(out, ofs, 0D1X, 92X); (* ђ *)
    | 091H: ok := Three(out, ofs, 0E2X, 80X, 98X); (* ‘ *)
    | 092H: ok := Three(out, ofs, 0E2X, 80X, 99X); (* ’ *)
    | 093H: ok := Three(out, ofs, 0E2X, 80X, 9CX); (* “ *)
    | 094H: ok := Three(out, ofs, 0E2X, 80X, 9DX); (* ” *)
    | 095H: ok := Three(out, ofs, 0E2X, 80X, 0A2X); (* • *)
    | 096H: ok := Three(out, ofs, 0E2X, 80X, 93X); (* – *)
    | 097H: ok := Three(out, ofs, 0E2X, 80X, 94X); (* — *)
    | 098H: ok := Three(out, ofs, 0EFX, 0BFX, 0BFX); (* 98H отсутствует в Windows-1251 0FFFFH *)
    | 099H: ok := Three(out, ofs, 0E2X, 84X, 0A2X); (* ™ *)
    | 09AH: ok := Two(out, ofs, 0D1X, 99X); (* љ *)
    | 09BH: ok := Three(out, ofs, 0E2X, 80X, 0BAX); (* › *)
    | 09CH: ok := Two(out, ofs, 0D1X, 9AX); (* њ *)
    | 09DH: ok := Two(out, ofs, 0D1X, 9CX); (* ќ *)
    | 09EH: ok := Two(out, ofs, 0D1X, 9BX); (* ћ *)
    | 09FH: ok := Two(out, ofs, 0D1X, 9FX); (* џ *)
    | 0A0H: ok := Two(out, ofs, 0C2X, 0A0X); (* Неразрывный пробел *)
    | 0A1H: ok := Two(out, ofs, 0D0X, 8EX); (* Ў *)
    | 0A2H: ok := Two(out, ofs, 0D1X, 9EX); (* ў *)
    | 0A3H: ok := Two(out, ofs, 0D0X, 88X); (* Ј *)
    | 0A4H: ok := Two(out, ofs, 0C2X, 0A4X); (* ¤ *)
    | 0A5H: ok := Two(out, ofs, 0D2X, 90X); (* Ґ *)
    | 0A6H: ok := Two(out, ofs, 0C2X, 0A6X); (* ¦ *)
    | 0A7H: ok := Two(out, ofs, 0C2X, 0A7X); (* § *)
    | 0A8H: ok := Two(out, ofs, 0D0X, 81X); (* Ё *)
    | 0A9H: ok := Two(out, ofs, 0C2X, 0A9X); (* © *)
    | 0AAH: ok := Two(out, ofs, 0D0X, 84X); (* Є *)
    | 0ABH: ok := Two(out, ofs, 0C2X, 0ABX); (* « *)
    | 0ACH: ok := Two(out, ofs, 0C2X, 0ACX); (* ¬ *)
    | 0ADH: ok := Two(out, ofs, 0C2X, 0ADX); (* мягкий перенос *)
    | 0AEH: ok := Two(out, ofs, 0C2X, 0AEX); (* ® *)
    | 0AFH: ok := Two(out, ofs, 0D0X, 87X); (* Ї *)
    | 0B0H: ok := Two(out, ofs, 0C2X, 0B0X); (* ° *)
    | 0B1H: ok := Two(out, ofs, 0C2X, 0B1X); (* ± *)
    | 0B2H: ok := Two(out, ofs, 0D0X, 86X); (* І *)
    | 0B3H: ok := Two(out, ofs, 0D1X, 96X); (* і *)
    | 0B4H: ok := Two(out, ofs, 0D2X, 91X); (* ґ *)
    | 0B5H: ok := Two(out, ofs, 0C2X, 0B5X); (* µ *)
    | 0B6H: ok := Two(out, ofs, 0C2X, 0B6X); (* ¶ *)
    | 0B7H: ok := Two(out, ofs, 0C2X, 0B7X); (* · *)
    | 0B8H: ok := Two(out, ofs, 0D1X, 91X); (* ё *)
    | 0B9H: ok := Three(out, ofs, 0E2X, 84X, 96X); (* № *)
    | 0BAH: ok := Two(out, ofs, 0D1X, 94X); (* є *)
    | 0BBH: ok := Two(out, ofs, 0C2X, 0BBX); (* » *)
    | 0BCH: ok := Two(out, ofs, 0D1X, 98X); (* ј *)
    | 0BDH: ok := Two(out, ofs, 0D0X, 85X); (* Ѕ *)
    | 0BEH: ok := Two(out, ofs, 0D1X, 95X); (* ѕ *)
    | 0BFH: ok := Two(out, ofs, 0D1X, 97X); (* ї *)
    END
  END
 RETURN
  ok
 END Do;

END OldCharsetWindows1251ToUtf8.

(* Copyright 2018,2021 ComdivByZero
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
MODULE AndroidPaint;

  CONST
    AntiAlias*          = 0;
    FilterBitmap*       = 1;
    Dither*             = 2;
    UnderlineText*      = 3;
    StrikeThruText*     = 4;
    FakeBoldText*       = 5;
    LinearText*         = 6;
    SubpixelText*       = 7;
    EmbeddedBitmapText* = 10;

    AllFlags = {0 .. 7, 10};

  TYPE
    T* = POINTER TO RECORD END;
    Align = POINTER TO RECORD END;

  VAR
    Center*, Left*, Right*: Align;

  PROCEDURE New*(): T;
  RETURN
    NIL
  END New;

  PROCEDURE SetColor*(p: T; color: INTEGER);
  BEGIN
    ASSERT(p # NIL);
    ASSERT((0 <= color) & (color < 1000000H))
  END SetColor;

  PROCEDURE SetOpacity*(p: T; opacity: INTEGER);
  BEGIN
    ASSERT(p # NIL);
    ASSERT((0 <= opacity) & (opacity < 100H))
  END SetOpacity;

  PROCEDURE SetStyleFill*(p: T);
  BEGIN
    ASSERT(p # NIL)
  END SetStyleFill;

  PROCEDURE SetTextSize*(p: T; size: REAL);
  BEGIN
    ASSERT(p # NIL);
    ASSERT(0.0 < size)
  END SetTextSize;

  PROCEDURE SetTextAlign*(p: T; align: Align);
  BEGIN
    ASSERT(p # NIL);
    ASSERT(align # NIL)
  END SetTextAlign;

  PROCEDURE SetFlags*(p: T; flags: SET);
  BEGIN
    ASSERT(p # NIL);
    ASSERT(flags - AllFlags = {})
  END SetFlags;

  PROCEDURE SetWordSpacing*(p: T; add: REAL);
  BEGIN
    ASSERT(p # NIL);
    ASSERT(0.0 <= add)
  END SetWordSpacing;

  PROCEDURE MeasureText*(p: T; txt: ARRAY OF CHAR; ofs: INTEGER): REAL;
  BEGIN
    ASSERT(p # NIL);
    ASSERT((0 <= ofs) & (ofs < LEN(txt)))
  RETURN
    0.0
  END MeasureText;

  PROCEDURE Ascent*(p: T): REAL;
  BEGIN
    ASSERT(p # NIL)
  RETURN
    0.0
  END Ascent;

  PROCEDURE Descent*(p: T): REAL;
  BEGIN
    ASSERT(p # NIL)
  RETURN
    0.0
  END Descent;

END AndroidPaint.

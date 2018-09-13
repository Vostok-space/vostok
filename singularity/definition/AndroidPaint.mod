(* Copyright 2018 ComdivByZero
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

  TYPE
    T* = POINTER TO RECORD END;

  PROCEDURE New*(): T;
  RETURN
    NIL
  END New;

  PROCEDURE SetColor*(p: T; color: INTEGER);
  BEGIN
    ASSERT((0 <= color) & (color < 1000000H));
    ASSERT(FALSE)
  END SetColor;

  PROCEDURE SetOpacity*(p: T; opacity: INTEGER);
  BEGIN
    ASSERT((0 <= opacity) & (opacity < 100H));
    ASSERT(FALSE)
  END SetOpacity;

  PROCEDURE SetStyleFill*(p: T);
  BEGIN
    ASSERT(FALSE)
  END SetStyleFill;

END AndroidPaint.

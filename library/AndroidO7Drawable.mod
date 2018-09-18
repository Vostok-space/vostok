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
MODULE AndroidO7Drawable;

IMPORT
  Canvas := AndroidCanvas, Activity := AndroidO7Activity;

TYPE
  RContext* = RECORD END;
  Context*  = POINTER TO RContext;
  Drawer*   = PROCEDURE(ctx: Context; cnv: Canvas.T);

  VAR drawer : Drawer;
      context: Context;

  PROCEDURE Nothing(ctx: Context; cnv: Canvas.T);
  END Nothing;

  PROCEDURE Draw*(cnv: Canvas.T);
  BEGIN
    drawer(context, cnv)
  END Draw;

  PROCEDURE SetDrawer*(d: Drawer; c: Context);
  BEGIN
    ASSERT((d # NIL) OR (c = NIL));
    IF d = NIL THEN
      drawer := Nothing
    ELSE
      drawer  := d;
      context := c;

      Activity.SetDrawable
    END
  END SetDrawer;

  PROCEDURE Width*(): INTEGER;
  RETURN
    Activity.GetViewWidth()
  END Width;

  PROCEDURE Height*(): INTEGER;
  RETURN
    Activity.GetViewHeight()
  END Height;

  PROCEDURE Invalidate*;
  BEGIN
    Activity.Invalidate
  END Invalidate;

BEGIN
  drawer  := Nothing;
  context := NIL
END AndroidO7Drawable.

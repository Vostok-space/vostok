Simple draw module for examples from Niklaus Wirth's "Algorithms and Data Structures"
Generates SVG

Copyright 2023 ComdivByZero

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

MODULE AdDraw;

 IMPORT log;

 CONST width* = 1024; height* = 800;

 VAR st, x, y: INTEGER;
  view: RECORD x, y, w, h: INTEGER END;

 PROCEDURE Init;
 BEGIN
  log.sn("<?xml version='1.0' encoding='UTF-8' standalone='no'?>");
  log.sn("<!DOCTYPE svg PUBLIC '-//W3C//DTD SVG 1.1//EN' 'http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd'>");
  log.sn("<!-- ?!:SVG -->");
  log.s("<svg width='"); log.i(view.w); log.s("' height='"); log.i(view.h);
  log.s("' viewBox='"); log.i(view.x); log.c(" "); log.i(view.y);
  log.c(" "); log.i(view.w); log.c(" "); log.i(view.h);
  log.sn("' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'>");
  log.s("<rect fill='#FFF' stroke='#000' x='");
  log.i(0); log.s("' y='"); log.i(0);
  log.s("' width='"); log.i(width); log.s("' height='"); log.i(height);
  log.sn("'/>");
  log.s("<path fill='none' stroke='black' stroke-width='1' d='")
 END Init;

 PROCEDURE Done;
 BEGIN
  log.sn("'/>");
  log.sn("</svg>")
 END Done;

 PROCEDURE End*;
 BEGIN
  IF st > 0 THEN
    st := 0;
    Done
  END
 END End;

 (*clear drawing plane*)
 PROCEDURE Clear*; BEGIN End END Clear;

 PROCEDURE Set*(nx, ny: INTEGER);
 BEGIN
  x := nx; y := ny;
  IF st = 2 THEN st := 1 END
 END Set;

 PROCEDURE SetView*(vx, vy, w, h: INTEGER);
 BEGIN
  ASSERT(w >= 0); ASSERT(h >= 0);
  ASSERT(st = 0);

  view.x := vx;
  view.y := vy;
  view.w := w;
  view.h := h;
 END SetView;

 PROCEDURE Move(dir, len: INTEGER);
 BEGIN
  CASE dir MOD 8 OF
    0: log.s(" h"); log.i( len)
  | 1: log.s(" l"); log.i( len); log.c(" "); log.i( len)
  | 2: log.s(" v"); log.i( len)
  | 3: log.s(" l"); log.i(-len); log.c(" "); log.i( len)
  | 4: log.s(" h"); log.i(-len)
  | 5: log.s(" l"); log.i(-len); log.c(" "); log.i(-len)
  | 6: log.s(" v"); log.i(-len)
  | 7: log.s(" l"); log.i(len) ; log.c(" "); log.i(-len)
  END
 END Move;

 (*draw line of length len in direction dir*45 degrees; move pen accordingly*)
 PROCEDURE line*(dir, len: INTEGER);
 BEGIN
  ASSERT(len >= 0);
  IF st = 0 THEN Init; st := 1 END;
  IF st = 1 THEN
    log.n; log.s("M "); log.i(x); log.c(" "); log.i(y);
    st := 2
  END;
  IF len > 0 THEN Move(dir, len) END
 END line;

BEGIN
 st := 0;
 x := 0; y := 0;
 SetView(0, 0, 1024, 800)
END AdDraw.

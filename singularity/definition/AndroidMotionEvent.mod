Interface of the wrapper of android.view.MotionEvent class

Copyright 2021 ComdivByZero

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

MODULE AndroidMotionEvent;

  CONST
    Down*       = 0;
    Up*         = 1;
    Move*       = 2;
    Cancel*     = 3;
    Outside*    = 4;
    PointerDown*= 5;
    PointerUp*  = 6;
    HoverMove*  = 7;
    HoverEnter* = 9;
    HoverExit*  = 10;

  TYPE
    T* = POINTER TO RECORD END;

  PROCEDURE GetAction*(p: T): INTEGER;
  BEGIN
    ASSERT(p # NIL);
    ASSERT(FALSE)
  RETURN
    0
  END GetAction;

  PROCEDURE GetPointerId*(p: T; index: INTEGER): INTEGER;
  BEGIN
    ASSERT(p # NIL);
    ASSERT(0 <= index);
    ASSERT(FALSE)
  RETURN
    0
  END GetPointerId;

  PROCEDURE GetSource*(p: T): INTEGER;
  BEGIN
    ASSERT(p # NIL);
    ASSERT(FALSE)
  RETURN
    0
  END GetSource;

  PROCEDURE GetX*(p: T; index: INTEGER): REAL;
  BEGIN
    ASSERT(p # NIL);
    ASSERT(0 <= index);
    ASSERT(FALSE)
  RETURN
    0.0
  END GetX;

  PROCEDURE GetXPrecision*(p: T): REAL;
  BEGIN
    ASSERT(p # NIL);
    ASSERT(FALSE)
  RETURN
    0.0
  END GetXPrecision;

  PROCEDURE GetY*(p: T; index: INTEGER): REAL;
  BEGIN
    ASSERT(p # NIL);
    ASSERT(0 <= index);
    ASSERT(FALSE)
  RETURN
    0.0
  END GetY;

  PROCEDURE GetYPrecision*(p: T): REAL;
  BEGIN
    ASSERT(p # NIL);
    ASSERT(FALSE)
  RETURN
    0.0
  END GetYPrecision;

  PROCEDURE GetSize*(p: T; index: INTEGER): REAL;
  BEGIN
    ASSERT(p # NIL);
    ASSERT(0 <= index);
    ASSERT(FALSE)
  RETURN
    0.0
  END GetSize;

  PROCEDURE GetToolMajor*(p: T; index: INTEGER): REAL;
  BEGIN
    ASSERT(p # NIL);
    ASSERT(0 <= index);
    ASSERT(FALSE)
  RETURN
    0.0
  END GetToolMajor;

  PROCEDURE GetToolMinor*(p: T; index: INTEGER): REAL;
  BEGIN
    ASSERT(p # NIL);
    ASSERT(0 <= index);
    ASSERT(FALSE)
  RETURN
    0.0
  END GetToolMinor;

  PROCEDURE GetTouchMajor*(p: T; index: INTEGER): REAL;
  BEGIN
    ASSERT(p # NIL);
    ASSERT(0 <= index);
    ASSERT(FALSE)
  RETURN
    0.0
  END GetTouchMajor;

  PROCEDURE GetTouchMinor*(p: T; index: INTEGER): REAL;
  BEGIN
    ASSERT(p # NIL);
    ASSERT(0 <= index);
    ASSERT(FALSE)
  RETURN
    0.0
  END GetTouchMinor;

END AndroidMotionEvent.

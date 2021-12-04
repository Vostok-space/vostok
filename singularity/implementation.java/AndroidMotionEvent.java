/* The wrapper of android.view.MotionEvent class
 *
 *  Copyright 2021 ComdivByZero
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
 */
package o7;

import o7.O7;

public final class AndroidMotionEvent {

public static final int
	Down        = 0,
	Up          = 1,
	Move        = 2,
	Cancel      = 3,
	Outside     = 4,
	PointerDown = 5,
	PointerUp   = 6,
	HoverMove   = 7,
	HoverEnter  = 9,
	HoverExit   = 10;

public static class T {
	final android.view.MotionEvent me;
	T(android.view.MotionEvent me) {
		this.me = me;
	}
}

public static int GetAction(T me) {
	return me.me.getAction();
}

public static int GetPointerId(T me, int index) {
	return me.me.getPointerId(index);
}

public static int GetSource(T me) {
	return me.me.getSource();
}

public static double GetX(T me, int index) {
	return me.me.getX(index);
}

public static double GetXPrecision(T me) {
	return me.me.getXPrecision();
}

public static double GetY(T me, int index) {
	return me.me.getY(index);
}

public static double GetYPrecision(T me) {
	return me.me.getYPrecision();
}

public static double GetSize(T me, int index) {
	return me.me.getSize(index);
}

public static double GetToolMajor(T me, int index) {
	return me.me.getToolMajor(index);
}

public static double GetToolMinor(T me, int index) {
	return me.me.getToolMinor(index);
}

public static double GetTouchMajor(T me, int index) {
	return me.me.getTouchMajor(index);
}

public static double GetTouchMinor(T me, int index) {
	return me.me.getTouchMinor(index);
}

public static T wrap(android.view.MotionEvent me) {
	return new T(me);
}

static {
	assert Down        == android.view.MotionEvent.ACTION_DOWN;
	assert Up          == android.view.MotionEvent.ACTION_UP;
	assert Move        == android.view.MotionEvent.ACTION_MOVE;
	assert Cancel      == android.view.MotionEvent.ACTION_CANCEL;
	assert Outside     == android.view.MotionEvent.ACTION_OUTSIDE;
	assert PointerDown == android.view.MotionEvent.ACTION_POINTER_DOWN;
	assert PointerUp   == android.view.MotionEvent.ACTION_POINTER_UP;
	assert HoverMove   == android.view.MotionEvent.ACTION_HOVER_MOVE;
	assert HoverEnter  == android.view.MotionEvent.ACTION_HOVER_ENTER;
	assert HoverExit   == android.view.MotionEvent.ACTION_HOVER_EXIT;
}

}

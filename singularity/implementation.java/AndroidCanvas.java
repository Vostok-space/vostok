/* Copyright 2018 ComdivByZero
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
import o7.AndroidPaint;

public final class AndroidCanvas {

public static class T {
	public final android.graphics.Canvas c;

	public T() {
		this.c = new android.graphics.Canvas();
	}
	T(final android.graphics.Canvas c) {
		this.c = c;
	}
}

public static T wrap(final android.graphics.Canvas c) {
	O7.asrt(c != null);
	return new T(c);
}

public static void
Line(T cnv, double startX, double startY, double stopX, double stopY,
     AndroidPaint.T paint)
{
	cnv.c.drawLine((float)startX, (float)startY, (float)stopX, (float)stopY, paint);
}

public static void
Rect(T cnv, double left, double top, double right, double bottom,
     AndroidPaint.T paint)
{
	cnv.c.drawRect((float)left, (float)top, (float)right, (float)bottom, paint);
}

public static void Path(T cnv, o7.AndroidGraphPath.T path, o7.AndroidPaint.T paint) {
	cnv.c.drawPath(path, paint);
}

public static int Width  (T cnv) { return cnv.c.getWidth();  }
public static int Height (T cnv) { return cnv.c.getHeight(); }
public static int Density(T cnv) { return cnv.c.getDensity();}

public static void SetDensity(T cnv, int density) { cnv.c.setDensity(density); }

}

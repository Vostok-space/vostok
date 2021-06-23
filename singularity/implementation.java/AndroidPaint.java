/* Copyright 2018,2021 ComdivByZero
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

public final class AndroidPaint {

public static final int AntiAlias = 0;
public static final int FilterBitmap = 1;
public static final int Dither = 2;
public static final int UnderlineText = 3;
public static final int StrikeThruText = 4;
public static final int FakeBoldText = 5;
public static final int LinearText = 6;
public static final int SubpixelText = 7;
public static final int EmbeddedBitmapText = 10;

private static final int AllFlags = (O7.set(0, 7) | (1 << 10));

public static class T extends android.graphics.Paint {}

public static final T.Align
	Center = T.Align.CENTER,
	Left   = T.Align.LEFT,
	Right  = T.Align.RIGHT;

public static T New() {
	return new T();
}

public static void SetColor(T p, int color) {
	O7.asrt((0 <= color) && (color < 0x100_0000));
	p.setColor(color | 0xFF00_0000);
}

public static void SetAlpha(T p, int value) {
	O7.asrt((0 <= value) && (value < 0x100));
	p.setAlpha(value);
}

public static void SetStyleFill(T p) {
	p.setStyle(android.graphics.Paint.Style.FILL);
}

public static void SetTextSize(T p, double size) {
	O7.asrt(0 < size);
	p.setTextSize((float)size);
}

public static void SetTextAlign(T p, T.Align a) {
	p.setTextAlign(a);
}

public static void SetFlags(T p, int flags) {
	O7.asrt((flags & ~AllFlags) == 0);
	p.setFlags(flags);
}

public static void SetWordSpacing(T p, double add) {
	O7.asrt(0.0 <= add);
	p.setWordSpacing((float)add);
}

public static double MeasureText(T p, byte[] txt, int ofs) {
	O7.asrt((0 <= ofs) && (ofs < txt.length));
	return p.measureText(O7.string(txt, ofs));
}

public static double Ascent(T p) {
	return p.ascent();
}

public static double Descent(T p) {
	return p.descent();
}

}

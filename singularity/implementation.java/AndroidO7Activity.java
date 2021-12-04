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

public final class AndroidO7Activity {

public static android.app.Activity act = null;
private static android.view.View view = null;

private static final class View extends android.view.View {
	private o7.AndroidCanvas.T wrapper = o7.AndroidCanvas.wrap(null);

	public View(android.content.Context context) {
		super(context);
	}
	@Override
	protected void onDraw(android.graphics.Canvas canvas) {
		if (this.wrapper.c != canvas) {
			this.wrapper = o7.AndroidCanvas.wrap(canvas);
		}
		o7.AndroidO7Drawable.Draw(this.wrapper);
	}
	@Override
	public boolean onTouchEvent(android.view.MotionEvent event) {
		return o7.AndroidO7Drawable.Touched(o7.AndroidMotionEvent.wrap(event));
	}
}

public static void SetDrawable() {
	view = new View(act);
	act.setContentView(view);
}

public static void Destroy() {
	act = null;
	view = null;
	o7.AndroidO7Drawable.Destroy();
}

public static void Invalidate() {
	view.invalidate();
}

public static int GetViewWidth() {
	return view.getWidth();
}

public static int GetViewHeight() {
	return view.getHeight();
}

}

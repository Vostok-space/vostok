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
private static android.widget.ImageView image_view = null;

private static class Draw extends android.graphics.drawable.Drawable {
	private o7.AndroidCanvas.T wrapper;
	@Override
	public void draw(android.graphics.Canvas canvas) {
		if ((this.wrapper == null) || (this.wrapper.c != canvas)) {
			this.wrapper = o7.AndroidCanvas.wrap(canvas);
		}
		o7.AndroidO7Drawable.Draw(this.wrapper);
	}
	@Override
	public int  getOpacity() { return 0; }
	@Override
	public void setColorFilter(android.graphics.ColorFilter colorFilter) {}
	@Override
	public void setAlpha(int alpha) {}
}

private static android.widget.ImageView newImageView() {
	final android.widget.ImageView iv;
	final Draw draw;

	iv = new android.widget.ImageView(act);
	draw = new Draw();
	iv.setImageDrawable(draw);
	draw.setCallback(new android.graphics.drawable.Drawable.Callback() {
		@Override
		public void invalidateDrawable(android.graphics.drawable.Drawable who) {
			iv.invalidate();
		}
		@Override
		public void scheduleDrawable(android.graphics.drawable.Drawable who,
		                             java.lang.Runnable what, long when) {}
		@Override
		public void unscheduleDrawable(android.graphics.drawable.Drawable who,
		                               java.lang.Runnable what) {}
	});
	return iv;
}

public static void SetDrawable() {
	image_view = newImageView();
	act.setContentView(image_view);
}

public static void Destroy() {
	act = null;
	image_view = null;
	o7.AndroidO7Drawable.Destroy();
}

public static void Invalidate() {
	image_view.invalidate();
}

public static int GetViewWidth() {
	return image_view.getWidth();
}

public static int GetViewHeight() {
	return image_view.getHeight();
}

}

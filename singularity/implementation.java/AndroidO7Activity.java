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

public final class AndroidO7Activity {

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
	android.widget.ImageView iv;
	iv = new android.widget.ImageView(o7.android.Activity.act);
	iv.setImageDrawable(new Draw());
	return iv;
}

public static void SetDrawable() {
	o7.android.Activity.act.setContentView(newImageView());
}

}

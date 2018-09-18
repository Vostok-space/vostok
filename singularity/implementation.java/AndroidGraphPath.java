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

public final class AndroidGraphPath {

public static class T extends android.graphics.Path { }

public static T New() {
	return new T();
}

public static void Reset(T p) {
	p.reset();
}

public static void MoveTo(T p, double x, double y) {
	p.moveTo((float)x, (float)y);
}

public static void LineTo(T p, double x, double y) {
	p.lineTo((float)x, (float)y);
}

}

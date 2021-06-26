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

public final class JavaRand {

private static java.security.SecureRandom rand = null;

public static boolean Open() {
	rand = new java.security.SecureRandom();
	return true;
}

public static void Close() {
	rand = null;
}

private static void partialRead(byte[] buf, int ofs, int count) {
	byte[] b = new byte[16];
	while (count > 16) {
		rand.nextBytes(b);
		java.lang.System.arraycopy(b, 0, buf, ofs, 16);
		ofs   += 16;
		count -= 16;
	}
	rand.nextBytes(b);
	java.lang.System.arraycopy(b, 0, buf, ofs, count);
}

public static boolean Read(byte[] buf, int ofs, int count) {
	O7.asrt(0 < count);
	O7.asrt(0 <= ofs && ofs <= buf.length - count);
	if (ofs == 0 && count == buf.length) {
		rand.nextBytes(buf);
	} else {
		partialRead(buf, ofs, count);
	}
	return true;
}

}

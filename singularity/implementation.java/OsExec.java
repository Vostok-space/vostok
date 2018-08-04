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

public final class OsExec {

public static final int Ok = 0;

public static int Do(final byte[] cmd) {
    int ret;
    try {
        ret = Runtime.getRuntime().exec(O7.string(cmd)).waitFor();
    } catch (InterruptedException | java.io.IOException e) {
        ret = -1;
        System.err.println(e);
    }
    return ret;
}

}

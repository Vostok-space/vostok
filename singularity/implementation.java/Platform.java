/* Copyright 2018-2019 ComdivByZero
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

public final class Platform {

public static final boolean Posix,
                            Linux,
                            Bsd,
                            Mingw,
                            Dos,
                            Windows,
                            Darwin,

                            C,
                            Java,
                            JavaScript;


static {
    Posix      = true;
    Linux      = true;
    Bsd        = false;
    Mingw      = false;
    Dos        = false;
    Windows    = false;
    Darwin     = false;

    C          = false;
    Java       = true;
    JavaScript = false;
}

}

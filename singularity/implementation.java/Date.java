/* Copyright 2025 ComdivByZero
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

public final class Date {

public static class T {
    int year;
    int month;
    int day;
    int hour;
    int minute;
    int second;
    public void assign(T r) {
        this.year = r.year;
        this.month = r.month;
        this.day = r.day;
        this.hour = r.hour;
        this.minute = r.minute;
        this.second = r.second;
    }
}

public static boolean Local(T t) {
    java.time.LocalDateTime d;

    d = java.time.LocalDateTime.now();
    t.year = d.getYear();
    t.month = d.getMonthValue() - 1;
    t.day = d.getDayOfMonth();
    t.hour = d.getHour();
    t.minute = d.getMinute();
    t.second = d.getSecond();
    return true;
}

}

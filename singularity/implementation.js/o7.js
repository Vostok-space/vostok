/* Copyright 2018-2020 ComdivByZero
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
var o7;
(function(o7) { "use strict";

  var utf8Enc, utf8Dec, u8array, toUtf8, utf8Cache, utf8ToStr;

  utf8Cache = [];

  o7.export = {};
  o7.import = o7.export;

  function assert(check, msg) {
    if (check) {
      ;
    } else if (msg) {
      throw new Error(msg);
    } else {
      throw new Error("assertion is false");
    }
  }
  o7.assert = assert;

  function indexOut(index, length) {
    return new RangeError("array index - " + index + " out of bounds - 0 .. " + length);
  }

  /* TODO */
  function array() {
    var lens;

    lens = arguments;
    function create(li) {
      var a, len, i;

      len = lens[li];
      a = new Array(len);
      li += 1;
      if (li < lens.length) {
        for (i = 0; i < len; i += 1) {
          a[i] = create(li);
        }
      }
      return a;
    }
    return create(0);
  }
  o7.array = array;

  function newArray(len) {
    var array = new Array(len);
    this.at = function(index) {
      if (0 <= index && index < len) {
        return array[index];
      } else {
        throw indexOut(index, array);
      }
    };
    this.put = function(index, value) {
      if (0 <= index && index < len) {
        array[index] = value;
      } else {
        throw indexOut(index, array);
      }
    };
  }
  o7.newArray = newArray;

  o7.at = function(array, index) {
    if (0 <= index && index < array.length) {
      return array[index];
    } else {
      throw indexOut(index, array.length);
    }
  };

  o7.put = function(array, index, value) {
    if (0 <= index && index < array.length) {
      array[index] = value;
    } else {
      throw indexOut(index, array.length);
    }
  };

  function ind(index, length) {
    if (0 <= index && index < length) {
      return value;
    } else {
      throw indexOut(index, length);
    }
  }
  o7.ind = ind;

  o7.caseFail = function(val) {
    throw new RangeError("Unexpected value in case = " + val);
  };

  o7.cti = function(char) {
    return char.charCodeAt(0);
  };

  o7.itc = function(int) {
    if (0 <= int && int < 0x100) {
      return int;
    } else {
      throw new RangeError("Char range overflow during cast from " + int);
    }
  };

  o7.bti = function(bool) {
    var i;
    if (bool) {
      i = 1;
    } else {
      i = 0;
    }
    return i;
  };

  o7.sti = function(bitset) {
    if (0 <= bitset && bitset < 0x80000000) {
      return bitset;
    } else {
      throw new RangeError("Set " + bitset + " can not be converted to integer");
    }
  };

  o7.itb = function(int) {
    if (0 <= int && int < 0x100) {
      return int;
    } else {
      throw new RangeError("Byte range is overflowed during cast from " + int);
    }
  };

  o7.floor = function(double) {
    var v;
    v = Math.floor(double);
    if ((-0x80000000 < v) && (v < 0x80000000)) {
      return v;
    } else {
      throw new RangeError("floor overflow " + v);
    }
  };

  o7.flt = function(int) {
    /* TODO */
    return int;
  };

  o7.scalb = function(double, int) {
    /* TODO */
    return double * Math.pow(2, int);
  };

  o7.frexp = function(d, n, n_i) {
    /* TODO */
    var abs, exp, x;
    if (d !== 0.0) {
      abs = Math.abs(d);
      exp = Math.max(-1023, Math.floor(Math.log(abs) * Math.LOG2E) + 1);
      x = abs * Math.pow(2, -exp);

      while (x < 1.0) {
        x   *= 2.0;
        exp -= 1;
      }
      while (x >= 2.0) {
        x   /= 2.0;
        exp += 1;
      }
      if (d < 0.0) {
        x = -x;
      }
      n[n_i] = exp;
    } else {
      x      = 0.0;
      n[n_i] = 0.0;
    }
    return x;
  }

  o7.in = function(n, st) {
    return (0 <= n) && (n <= 31) && (0 != (st & (1 << n)));
  };

  if (typeof Uint8Array !== 'undefined') {
    u8array = function(array) {
      return new Uint8Array(array);
    }
  } else {
    u8array = function(array) {
      return array;
    };
  }

  function arrayUtf8ToStr(bytes) {
    var str, buf, i, len, ch, ch1, ch2, ch3, ok;

    buf = [];
    len = bytes.length;
    i = 0;
    ok = true;
    while (i < len && bytes[i] != 0) {
      ch = bytes[i];
      i += 1;
      if (ch < 0x0080) {
        buf.push(String.fromCharCode(ch));
      } else if (ch < 0x00C0) {
        ok = false;
      } else if (ch < 0x00E0) {
        if (i < len) {
          ch1 = bytes[i];
          i += 1;
          ok = (ch1 >> 6) == 2;
          buf.push(String.fromCharCode(((ch & 0x001F) << 6) | (ch1 & 0x003F)));
        } else {
          ok = false;
        }
      } else if (ch < 0x00F0) {
        if (i + 1 < len) {
          ch1 = bytes[i];
          i += 1;
          ch2 = bytes[i];
          i += 1;
          ok = ((ch1 >> 6) == 2) && ((ch2 >> 6) == 2);
          buf.push(String.fromCharCode(((ch & 0x000F) << 12) | ((ch1 & 0x003F) << 6) | (ch2 & 0x003F)));
        } else {
          ok = false;
        }
      } else {
        if (i + 2 < len) {
          ch1 = bytes[i];
          i += 1;
          ch2 = bytes[i];
          i += 1;
          ch3 = bytes[i];
          i += 1;
          ok = ((ch1 >> 6) == 2) && ((ch2 >> 6) == 2) && ((ch3 >> 6) == 2);
          buf.push(String.fromCharCode(((ch & 0x0007) << 18) | ((ch1 & 0x003F) << 12) | ((ch2 & 0x003F) << 6) | (ch3 & 0x003F)));
        } else {
          ok = false;
        }
      }
    }
    if (ok) {
      str = buf.join('');
    } else {
      str = null;
    }
    return str;
  };

  if (typeof TextDecoder !== 'undefined') {
    utf8Enc = new TextEncoder('utf-8');
    utf8Dec = new TextDecoder('utf-8');

    toUtf8 = function(str) {
      var a, b;
      a = utf8Enc.encode(str);
      if (a.push) {
        a.push(0x0);
      } else {
        b = new Uint8Array(a.length + 1);
        b.set(a, 0);
        b[a.length] = 0x0;
        a = b;
      }
      return a;
    };

    utf8ToStr = function(bytes) {
      var str;
      if (bytes instanceof Uint8Array) {
        str = utf8Dec.decode(bytes);
      } else {
        str = arrayUtf8ToStr(bytes);
      }
      return str;
    };
  } else {
    /* str must be correct utf16 string */
    toUtf8 = function(str) {
      var bytes, si, ch, len;
      bytes = [];
      si = 0;
      len = str.length;
      while (si < len) {
        ch = str.charCodeAt(si);
        if (ch < 0x0080) {
          bytes.push(ch);
        } else if (ch < 0x0800) {
          bytes.push((ch >> 6) | 0x00C0,
                     (ch & 0x003F) | 0x0080);
        } else if ((ch & 0xFC00) == 0xD800) {
          si += 1;
          ch = 0x10000 | ((ch & 0x03FF) << 10) | (str.charCodeAt(si) & 0x03FF);
          bytes.push((ch >> 18) | 0x00F0,
                     ((ch >> 12) & 0x003F) | 0x0080,
                     ((ch >> 6 ) & 0x003F) | 0x0080,
                     (ch & 0x003F) | 0x0080);
        } else {
          bytes.push((ch >> 12) | 0x00E0,
                     ((ch >> 6) & 0x003F) | 0x0080,
                     (ch & 0x003F) | 0x0080);
        }
        si += 1;
      }
      bytes.push(0x0);
      return u8array(bytes);
    };

    utf8ToStr = arrayUtf8ToStr;
  }
  o7.utf8ToStr = utf8ToStr;

  o7.toUtf8 = function(str) {
    var utf;
    utf = utf8Cache[str];
    if (!utf) {
        utf = toUtf8(str);
        utf8Cache[str] = utf;
    }
    return utf;
  };

  o7.utf8ByOfsToStr = function(bytes, ofs) {
    if (ofs > 0) {
      bytes = bytes.slice(ofs);
    }
    return utf8ToStr(bytes);
  }

  /* str must be correct 7bit ASCII string */
  o7.toAscii = function(str) {
    var bytes, len, i;
    len = str.length;
    bytes = new Uint8Array(len);
    for (i = 0; i < len; i += 1) {
      /* assert str.charCodeAt(i) < 0x80 */
      bytes[i] = str.charCodeAt(i);
    }
    return bytes;
  };


  o7.extend = function(ext, base) {
    function proto() {}
    proto.prototype = base.prototype;

    ext.prototype = new proto();
    ext.base = base;
    return ext;
  };

  o7.add = function(a, b) {
    var r;
    r = a + b;
    if (-0x80000000 < r && r < 0x80000000) {
      return r;
    } else {
      throw new RangeError("integer overflow in " + a + " + " + b + " = " + r);
    }
  };

  o7.sub = function(a, b) {
    var r;
    r = a - b;
    if (-0x80000000 < r && r < 0x80000000) {
      return r;
    } else {
      throw new RangeError("integer overflow in " + a + " - " + b + " = " + r);
    }
  };

  o7.mul = function(a, b) {
    var r;
    r = a * b | 0;
    if (-0x80000000 < r && r < 0x80000000) {
      return r;
    } else {
      throw new RangeError("integer overflow in " + a + " * " + b + " = " + r);
    }
  };

  o7.div = function(a, b) {
    var mask;
    if (b > 0) {
      mask = a >> 31;
      return mask ^ ((mask ^ a) / b);
    } else {
      throw new RangeError("divider can't be < 1");
    }
  };

  o7.mod = function(a, b) {
    var mask;
    if (b > 0) {
      mask = a >> 31;
      return (b & mask) + (mask ^ ((mask ^ a) % b));
    } else {
      throw new RangeError("divider can't be < 1");
    }
  };

  o7.set = function(low, high) {
    if (high > 31) {
      throw new RangeError("high limit = " + high + " > 31");
    } else if (low < 0) {
      throw new RangeError("low limit = " + low + " < 0");
    } else if (low > high) {
      throw new RangeError("low limit = " + low + " > " + high + " - high limit");
    } else {
      return (~0 << low) & (~0 >>> (31 - high));
    }
  };

  o7.ror = function(n, shift) {
    assert(n     >= 0);
    assert(shift >= 0);
    shift &= 31;
    n = (n >>> shift) | (n << (32 - shift));
    assert(n     >= 0);
    return n;
  }

  o7.strcmp = function(s1, s2) {
    var i;
    i = 0;
    while ((s1[i] == s2[i]) && (s1[i] != 0)) {
      i += 1;
    }
    return s1[i] - s2[i];
  };


  function strchcmp(s1, c2) {
    var c1, ret;

    c1 = s1[0];
    ret = c1 - c2;
    if (ret == 0 && c1 != 0 && s1.length > 1 && s1[1] != 0) {
        ret = s1[1];
    }
    return ret;
  }

  o7.strchcmp = strchcmp;

  o7.chstrcmp = function(c1, s2) {
    return -strchcmp(s2, c1);
  };

  /* Copy chars */
  o7.strcpy = function(d, s) {
    var len, i;

    len = s.length;
    assert(d.length >= len);
    for (i = 0; i < len; i += 1) {
      d[i] = s[i];
    }
    assert(i == len);
    assert(d[i - 1] == 0);
  };

  o7.copy = function(d, s) {
      var i, len;
      len = d.length;
      for (i = 0; i < len; i += 1) {
          d[i] = s[i];
      }
  };

  o7.exit_code = 0;
  o7.main = function(main) {
    main();
    if (o7.exit_code != 0 && typeof process !== 'undefined') {
      process.exit(o7.exit_code);
    }
  };

}) (o7 || (o7 = {}));

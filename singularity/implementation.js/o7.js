/* Copyright 2018-2021 ComdivByZero
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

  var utf8Enc, utf8Dec, u8array, toUtf8, utf8Cache, utf8ToStr, proc;

  utf8Cache = [];

  o7.export = {};
  o7.import = o7.export;

  if (typeof process === 'undefined' || !process.exit) {
    proc = {exit : function(code) { if (code != 0) throw code; }};
  } else {
    proc = process;
  }

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

  function sarray() {
    var lens;

    lens = arguments;
    function create(li) {
      var array, len, i;

      len = lens[li];
      array = new Array(len);
      this._ = array;
      this.length = len;
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
      this.inc = function(index, val) {
        if (0 <= index && index < len) {
          array[index] = add(array[index], val);
        } else {
          throw indexOut(index, array);
        }
      };
      this.incl = function(index, val) {
        if (0 <= index && index < len) {
          array[index] |= incl(val);
        } else {
          throw indexOut(index, array);
        }
      };
      this.excl = function(index, val) {
        if (0 <= index && index < len) {
          array[index] &= excl(val);
        } else {
          throw indexOut(index, array);
        }
      };
      li += 1;
      if (li < lens.length) {
        for (i = 0; i < len; i += 1) {
          array[i] = new create(li);
        }
      }
    }
    return new create(0);
  }
  o7.sarray = sarray;

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

  function getjsa(o7array) {
    var ja;
    if (o7array._) {
      ja = o7array._;
    } else {
      ja = o7array;
    }
    return ja;
  }
  o7.getjsa = getjsa;

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
    n = getjsa(n);
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

  u8array = function(array) {
    function create() {
      var len;

      len = array.length;
      this.length = len;
      this._ = array;
      this.at = function(index) {
        if (0 <= index && index < len) {
          return array[index];
        } else {
          throw indexOut(index, array);
        }
      };
      this.put = function(index, val) {
        if (0 <= index && index < len) {
          array[index] = val;
        } else {
          throw indexOut(index, array);
        }
      };
      this.inc = function(index, val) {
        if (0 <= index && index < len) {
          val += array[index];
          if (0 <= val && val <= 0xFF) {
            array[index] = val;
          }
        } else {
          throw indexOut(index, array);
        }
      };
    }
    return new create();
  };

  function arrayUtf8ToStr(bytes) {
    var str, buf, i, len, ch, ch1, ch2, ch3, ok;

    buf = [];
    len = bytes.length;
    i = 0;
    ok = true;
    while (i < len && bytes[i] != 0) {
      ch = bytes[i];
      i += 1;
      if (ch < 0x80) {
        buf.push(String.fromCharCode(ch));
      } else if (ch < 0xC0) {
        ok = false;
      } else if (ch < 0xE0) {
        if (i < len) {
          ch1 = bytes[i];
          i += 1;
          if ((ch1 >> 6) == 2) {
            buf.push(String.fromCharCode(((ch & 0x1F) << 6) | (ch1 & 0x3F)));
          } else {
            ok = false;
          }
        } else {
          ok = false;
        }
      } else if (ch < 0xF0) {
        if (i + 1 < len) {
          ch1 = bytes[i];
          ch2 = bytes[i + 1];
          i += 2;
          if (((ch1 >> 6) == 2) && ((ch2 >> 6) == 2)) {
            buf.push(String.fromCharCode(((ch & 0xF) << 12) | ((ch1 & 0x3F) << 6) | (ch2 & 0x3F)));
          } else {
            ok = false;
          }
        } else {
          ok = false;
        }
      } else {
        if (i + 2 < len) {
          ch1 = bytes[i];
          ch2 = bytes[i + 1];
          ch3 = bytes[i + 2];
          i += 3;
          if (((ch1 >> 6) == 2) && ((ch2 >> 6) == 2) && ((ch3 >> 6) == 2)) {
            buf.push(String.fromCodePoint(((ch & 0x7) << 18) | ((ch1 & 0x3F) << 12) | ((ch2 & 0x3F) << 6) | (ch3 & 0x3F)));
          } else {
            ok = false;
          }
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

    if (utf8Enc.encode("!").push) {
      toUtf8 = function(str) {
        var a;
        a = utf8Enc.encode(str);
        a.push(0);
        return u8array(a);
      };
    } else {
      toUtf8 = function(str) {
        var a, b;
        a = utf8Enc.encode(str);
        b = new Uint8Array(a.length + 1);
        b.set(a, 0);
        b[a.length] = 0;
        return u8array(b);
      };
    }

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
        if (ch < 0x80) {
          bytes.push(ch);
        } else if (ch < 0x800) {
          bytes.push((ch >> 6) | 0xC0,
                     (ch & 0x3F) | 0x80);
        } else if ((ch & 0xFC00) == 0xD800) {
          si += 1;
          ch = 0x10000 | ((ch & 0x3FF) << 10) | (str.charCodeAt(si) & 0x3FF);
          bytes.push((ch >> 18) | 0xF0,
                     ((ch >> 12) & 0x3F) | 0x80,
                     ((ch >> 6 ) & 0x3F) | 0x80,
                     (ch & 0x3F) | 0x80);
        } else {
          bytes.push((ch >> 12) | 0xE0,
                     ((ch >> 6) & 0x3F) | 0x80,
                     (ch & 0x3F) | 0x80);
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
    bytes = getjsa(bytes);
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

  function add(a, b) {
    var r;
    r = a + b;
    if (-0x80000000 < r && r < 0x80000000) {
      return r;
    } else {
      throw new RangeError("integer overflow in " + a + " + " + b + " = " + r);
    }
  }
  o7.add = add;

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
    r = a * b;
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
      throw new RangeError("Integer divider can't be < 1");
    }
  };

  o7.mod = function(a, b) {
    var mask;
    if (b > 0) {
      mask = a >> 31;
      return (b & mask) + (mask ^ ((mask ^ a) % b));
    } else {
      throw new RangeError("Integer divider can't be < 1");
    }
  };

  function fadd(a, b) {
    var s;
    s = a + b;
    if (isFinite(s)) {
      return s;
    } else {
      /* TODO */
      throw new RangeError("Fraction out of range in " + a + " + " + b + " = " + s);
    }
  }
  o7.fadd = fadd;

  function fsub(a, b) {
    var s;
    s = a - b;
    if (isFinite(s)) {
      return s;
    } else {
      /* TODO */
      throw new RangeError("Fraction out of range in " + a + " - " + b + " = " + s);
    }
  }
  o7.fsub = fsub;

  function fmul(a, b) {
    var s;
    s = a * b;
    if (isFinite(s)) {
      return s;
    } else {
      /* TODO */
      throw new RangeError("Fraction out of range in " + a + " * " + b + " = " + s);
    }
  }
  o7.fmul = fmul;

  function fdiv(a, b) {
    var s;
    s = a / b;
    if (isFinite(s)) {
      return s;
    } else {
      /* TODO */
      throw new RangeError("Fraction out of range in " + a + " / " + b + " = " + s);
    }
  }
  o7.fdiv = fdiv;

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

  function setRangeError(val) {
    return new RangeError("set item = " + val + " out of range 0 .. 31");
  }

  function incl(val) {
    if (0 <= val && val <= 31) {
      return 1 << val;
    } else {
      throw setRangeError(val);
    }
  }
  o7.incl = incl;

  function excl(val) {
    if (0 <= val && val <= 31) {
      return ~(1 << val);
    } else {
      throw setRangeError(val);
    }
  }
  o7.excl = excl;

  o7.ror = function(n, shift) {
    assert(n     >= 0);
    assert(shift >= 0);
    shift &= 31;
    n = (n >>> shift) | (n << (32 - shift));
    assert(n     >= 0);
    return n;
  }

  function inited(val) {
    if (isFinite(val)) {
      return val;
    } else {
      throw new RangeError("Uninitialized value");
    }
  }
  o7.inited = inited;

  o7.cmp = function(a, b) {
    var d;
    d = a - b;
    if (isFinite(d)) {
      ;
    } else if (inited(a) < inited(b)) {
      d = -1;
    } else if (a > b) {
      d = 1;
    } else {
      d = 0;
    }
    return d
  }

  o7.strcmp = function(s1, s2) {
    var i;
    i = 0;
    s1 = getjsa(s1);
    s2 = getjsa(s2);
    while ((s1[i] == s2[i]) && (s1[i] != 0)) {
      i += 1;
    }
    return s1[i] - s2[i];
  };

  function strchcmp(s1, c2) {
    var c1, ret;

    s1 = getjsa(s1);
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

    d = getjsa(d);
    s = getjsa(s);

    len = s.length;
    assert(d.length >= len);
    for (i = 0; i < len; i += 1) {
      d[i] = s[i];
    }
    assert(d[len - 1] == 0);
  };

  function copy(d, s) {
    var i, len;
    d = getjsa(d);
    s = getjsa(s);
    len = d.length;
    if ((s[0] instanceof Object) && s[0].length) {
      for (i = 0; i < len; i += 1) {
        copy(d[i], s[i]);
      }
    } else {
      for (i = 0; i < len; i += 1) {
        d[i] = s[i];
      }
    }
  }
  o7.copy = copy;

  o7.exit_code = 0;
  o7.main = function(main) {
    main();
    if (o7.exit_code != 0) {
      proc.exit(o7.exit_code);
    }
  };

}) (o7 || (o7 = {}));

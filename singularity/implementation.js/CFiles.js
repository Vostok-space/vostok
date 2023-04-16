/* Copyright 2019-2021,2023 ComdivByZero
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
(function() { 'use strict';

var module = {};
o7.export.CFiles = module;

var getjsa, utf8ByOfsToStr, fs, proc;

var KiB = 1024;
module.KiB = KiB;
var MiB = 1024 * KiB;
module.MiB = MiB;
var GiB = 1024 * MiB;
module.GiB = GiB;

function File() {}
File.prototype.assign = function(r) {}

utf8ByOfsToStr = o7.utf8ByOfsToStr;

if (typeof require !== 'undefined' && typeof process !== 'undefined') {
	fs = require('fs');
} else {
	fs = null;
}

function wrapFile1(file) {
	var f;
	f = new File();
	f.fd = file.fd;
	f.notsync = true;
	return f;
}

/* TODO сохранение буфера до Сlose */
function bufGet(size) {
	var data;
	if (Buffer.allocUnsafe) {
		data = Buffer.allocUnsafe(size);
	} else {
		data = new Buffer(size);
	}
	return data;
}

function wrapFile2(file) {
	var f;
	f = new File();
	f.f = file;
	return f;
}


if (fs != null) {
	module.in_ = wrapFile1(process.stdin);
	module.out = wrapFile1(process.stdout);
	module.err = wrapFile1(process.stderr);

	module.Open = function(bytes_name, ofs, mode) {
		var f, name, fd, smode, i;

		f = null;
		name = utf8ByOfsToStr(bytes_name, ofs);
		if (name != null) {
			smode = "r";
			for (i = 0; i < mode.length; i += 1) {
				if (mode[i] == 'w'.charCodeAt(0)) {
					smode = "w+";
				}
			}
			try {
				fd = fs.openSync(name, smode, 6 * 64 + 6 * 8 + 6);
			} catch (exc) {
				fd = -1;
			}
			if (fd != -1) {
				f = new File();
				f.fd = fd;
			}
		}
		return f;
	}

	module.Close = function(file, file_ai) {
		if (file[file_ai]) {
			fs.closeSync(file[file_ai].fd);
			file[file_ai] = null;
		}
	}

	module.Read = function(file, buf, ofs, count) {
		var data, read, i;
		if (typeof buf !== 'Uint8Array') {
			data = bufGet(count);
			read = fs.readSync(file.fd, data, 0, count);
			for (i = 0; i < read; i += 1) {
				buf[i + ofs] = data[i];
			}
		} else {
			read = fs.readSync(file.fd, buf, ofs, count);
		}
		return read;
	}

	module.Write = function(file, buf, ofs, count) {
		var data, write, i;
		if (typeof buf !== 'Uint8Array') {
			data = bufGet(count);
			for (i = 0; i < count; i += 1) {
				data[i] = buf[i + ofs];
			}
			write = fs.writeSync(file.fd, data, 0, count);
		} else {
			write = fs.writeSync(file.fd, buf, ofs, count);
		}
		return write;
	}

	module.Flush = function(file) {
		return file.notsync || 0 === fs.fdatasyncSync(file.fd);
	}

	module.Remove = function(name, ofs) {
		var str;
		str = utf8ByOfsToStr(name, ofs);
		if (str != null) {
			fs.unlinkSync(str);
		}
		/* TODO недостаточное условие */
		return str != null;
	}

	module.Exist = function(name, ofs) {
		var str;
		str = utf8ByOfsToStr(name, ofs);
		return str != null && fs.existsSync(str);
	}

	module.Rename = function(src, sofs, dest, dofs) {
		var s, d;
		s = utf8ByOfsToStr(src, sofs);
		d = utf8ByOfsToStr(dest, dofs);
		fs.renameSync(s, d);
		/* TODO */
		return true;
	}

} else if (typeof std !== 'undefined') {
	module.in_ = wrapFile2(std.in);
	module.out = wrapFile2(std.out);
	module.err = wrapFile2(std.err);

	module.Open = function(bytes_name, ofs, mode) {
		var f, name, file, smode;

		f = null;
		name = utf8ByOfsToStr(bytes_name, ofs);
		smode = utf8ByOfsToStr(mode, 0);
		if (name != null && smode != null) {
			file = std.open(name, smode);
			if (file != null) {
				f = new File();
				f.f = file;
			}
		}
		return f;
	}

	module.Close = function(file, file_ai) {
		if (file[file_ai]) {
			file[file_ai].f.close();
			file[file_ai] = null;
		}
	}

	module.Read = function(file, buf, ofs, count) {
		var data, read, i;
		data = new ArrayBuffer(count);
		read = file.f.read(data, 0, count);
		if (read > 0) {
			data = new Uint8Array(data);
			for (i = 0; i < read; i += 1) {
				buf[i + ofs] = data[i];
			}
		}
		return read;
	}

	module.Write = function(file, buf, ofs, count) {
		var ab, data, i;
		ab = new ArrayBuffer(count);
		data = new Uint8Array(ab);
		for (i = 0; i < count; i += 1) {
			data[i] = buf[i + ofs];
		}
		return file.f.write(ab, 0, count);
	}

	module.Flush = function(file) { return file.flush() == 0; }

	module.Remove = function(name, ofs) {
		var str;
		str = utf8ByOfsToStr(name, ofs);
		return (str != null) && (os.remove(str) == 0);
	}

	module.Exist = function(name, ofs) {
		var name, f;
		name = utf8ByOfsToStr(name, ofs);
		f = null;
		if (name != null) {
			f = std.open(name, "rb");
			if (f != null) {
				f.close();
			}
		}
		return f != null;
	}

	module.Seek = function(file, gibs, bytes) {
		o7.assert(gibs >= 0);
		o7.assert(bytes >= 0 && bytes <= GiB);
		return 0 == file.seek(BigInt(gibs) * BigInt(GiB) + BigInt(bytes), std.SEEK_SET);
	}

	module.Tell = function(file, gibs, gibs_ai, bytes, bytes_ai) {
		var pos, ok;
		pos = file.tello();
		ok = pos >= BigInt(0);
		if (ok) {
			gibs[gibs_ai] = Number(pos / BigInt(GiB));
			bytes[bytes_ai] = Number(pos % BigInt(GiB));
		}
		return ok;
	}

	module.Rename = function(src, sofs, dest, dofs) {
		var s, d;
		s = utf8ByOfsToStr(src, sofs);
		d = utf8ByOfsToStr(dest, dofs);
		return 0 == os.rename(s, d);
	}

} else {
	module.in_ = new File();
	module.out = new File();
	module.err = new File();

	module.Open = function(bytes_name, ofs, mode) { return null; }
	module.Close = function(file, file_ai) {}
	module.Read = function(file, buf, ofs, count) { return 0; }
	module.Write = function(file, buf, ofs, count) { return 0; }
	module.Flush = function(file) { return false; }
	module.Remove = function(name, ofs)  { return false; }
	module.Exist = function(name, ofs) { return false; }
	module.Rename = function(src, sofs, dest, dofs) { return false; }
}

module.ReadChars = function(file, buf, ofs, count) {
	return module.Read(file, buf, ofs, count);
}
module.WriteChars = function(file, buf, ofs, count) {
	return module.Write(file, buf, ofs, count);
}

if (!module.Seek) {
	module.Seek = function(file, gibs, bytes) { return false; };
	module.Tell = function(file, gibs, gibs_ai, bytes, bytes_ai) { return false; };
}

return module;
})();

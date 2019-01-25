/* Copyright 2019 ComdivByZero
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
var o7;
(function(o7) { 'use strict';

var module = {};
o7.CFiles = module;

var fs;

var KiB = 1024;
module.KiB = KiB;
var MiB = 1024 * KiB;
module.MiB = MiB;
var GiB = 1024 * MiB;
module.GiB = GiB;

function File() {}
File.prototype.assign = function(r) {}

function Open(bytes_name, ofs, mode) {
	var f, name, fd, smode, i;

	f = null;
	if (fs) {
		name = o7.utf8ToStr1(bytes_name, ofs);
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
	}
	return f;
}
module.Open = Open;

function Close(file, file_ai) {
	if (file[file_ai]) {
		fs.closeSync(file[file_ai].fd);
		file[file_ai] = null;
	}
}
module.Close = Close;

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

function Read(file, buf, ofs, count) {
	var data, read, i;
	if (typeof buf !== 'Uint8Aarray') {
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
module.Read = Read;

function Write(file, buf, ofs, count) {
	var data, write, i;
	if (typeof buf !== 'Uint8Aarray') {
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
module.Write = Write;

function ReadChars(file, buf, ofs, count) {
	return Read(file, buf, ofs, count);
}
module.ReadChars = ReadChars;

function WriteChars(file, buf, ofs, count) {
	return Write(file, buf, ofs, count);
}
module.WriteChars = WriteChars;

function Flush(file) {
	return file.notsync || 0 === fs.fdatasyncSync(file.fd);
}
module.Flush = Flush;

/* полная позиция = gibs * GiB + bytes; 0 <= bytes < GiB */
function Seek(file, gibs, bytes) {
	/* нет в node*/
	return false;
}
module.Seek = Seek;

function Tell(file, gibs, gibs_ai, bytes, bytes_ai) {
	/* нет в node*/
	return false;
}
module.Tell = Tell;

function Remove(name, ofs) {
	var str;
	str = o7.utf8ToStr1(name, ofs);
	if (str != null) {
		fs.unlinkSync(str);
	}
	/* TODO недостаточное условие */
	return str != null;
}
module.Remove = Remove;

function Exist(name, ofs) {
	var str;
	str = o7.utf8ToStr1(name, ofs);
	return str != null && fs.existsSync(str);
}
module.Exist = Exist;

function wrapFile(file) {
	var f;
	f = new File();
	f.fd = file.fd;
	f.notsync = true;
	return f;
}

fs = require('fs');
module.in_ = wrapFile(process.stdin);
module.out = wrapFile(process.stdout);
module.err = wrapFile(process.stderr);

return module;
})(o7 || (o7 = {}));


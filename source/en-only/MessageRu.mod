(*  Stub for russian messages for interface
 *  Copyright (C) 2020-2021 ComdivByZero
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published
 *  by the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)
MODULE MessageRu;

IMPORT MessageEn;

PROCEDURE Usage*(full: BOOLEAN);
BEGIN
	MessageEn.Usage(full)
END Usage;

PROCEDURE CliError*(err: INTEGER);
BEGIN
	MessageEn.CliError(err)
END CliError;

END MessageRu.

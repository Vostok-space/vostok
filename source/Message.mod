(*  Wrapper for modules with localized messages for interface
 *  Copyright (C) 2018-2019 ComdivByZero
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
MODULE Message;

IMPORT Env := OsEnv, Platform, LocaleParser,
       Strings := StringStore,
       InterfaceLang,
       MessageUk, MessageRu, MessageEn, Out;

CONST
	En = InterfaceLang.En;
	Ru = InterfaceLang.Ru;
	Uk = InterfaceLang.Uk;

PROCEDURE Usage*(full: BOOLEAN);
BEGIN
	CASE InterfaceLang.lang OF
	  En: MessageEn.Usage(full)
	| Ru: MessageRu.Usage(full)
	| Uk: MessageUk.Usage(full)
	END
END Usage;

PROCEDURE CliError*(err: INTEGER);
BEGIN
	CASE InterfaceLang.lang OF
	  En: MessageEn.CliError(err)
	| Ru: MessageRu.CliError(err)
	| Uk: MessageUk.CliError(err)
	END
END CliError;

END Message.

(*  Read Eval Print Loop for Oberon commands
 *  Copyright (C) 2018 ComdivByZero
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published
 *  by the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)
MODULE Repl;

  IMPORT Out, Cli := CliParser, EditLine, Message, Translator, Utf8;

  PROCEDURE Loop(VAR args: Cli.Args);
  VAR err: INTEGER;
  BEGIN
    args.script := TRUE;
    WHILE EditLine.Read("O7: ", args.src) DO
      IF args.src[0] # Utf8.Null THEN
        err := Translator.Translate(Cli.ResultRun, args);
        IF (err # Translator.ErrNo) & (err # Translator.ErrParse) THEN
          Message.CliError(err)
        END
      END
    END
  END Loop;

  PROCEDURE Go*;
  VAR args: Cli.Args; err: INTEGER;
  BEGIN
    Cli.ArgsInit(args);
    args.arg := 0;
    err := Cli.Options(args, args.arg);
    IF err # Cli.ErrNo THEN
      Message.CliError(err)
    ELSE
      Loop(args)
    END
  END Go;

BEGIN
  Out.Open
END Repl.

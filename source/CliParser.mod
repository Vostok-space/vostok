MODULE CliParser;

CONST
	ResultC*   = 0;
	ResultBin* = 1;
	ResultRun* = 2;

	ErrNo*                   =   0;

	ErrWrongArgs*            = -10;
	ErrTooLongSourceName*    = -11;
	ErrTooLongOutName*       = -12;
	ErrOpenSource*           = -13;
	ErrOpenH*                = -14;
	ErrOpenC*                = -15;
	ErrUnknownCommand*       = -16;
	ErrNotEnoughArgs*        = -17;
	ErrTooLongModuleDirs*    = -18;
	ErrTooManyModuleDirs*    = -19;
	ErrTooLongCDirs*         = -20;
	ErrTooLongCc*            = -21;
	ErrTooLongInit*          = -22;
	ErrCCompiler*            = -23;
	ErrTooLongRunArgs*       = -24;
	ErrUnexpectArg*          = -25;
	ErrUnknownInit*          = -26;
	ErrCantCreateOutDir*     = -27;
	ErrCantRemoveOutDir*     = -28;

END CliParser.

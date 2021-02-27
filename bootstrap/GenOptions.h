#if !defined HEADER_GUARD_GenOptions
#    define  HEADER_GUARD_GenOptions 1

#include "V.h"

#define GenOptions_VarInitUndefined_cnst 0
#define GenOptions_VarInitZero_cnst 1
#define GenOptions_VarInitNo_cnst 2

#define GenOptions_IdentEncSame_cnst 0
#define GenOptions_IdentEncTranslit_cnst 1
#define GenOptions_IdentEncEscUnicode_cnst 2

typedef struct GenOptions_R {
	V_Base _;
	o7_bool checkArith;
	o7_bool checkIndex;
	o7_bool caseAbort;
	o7_bool o7Assert;

	o7_bool comment;
	o7_bool generatorNote;

	o7_bool main_;

	o7_int_t varInit;
	o7_int_t identEnc;
} GenOptions_R;
#define GenOptions_R_tag V_Base_tag


extern void GenOptions_Default(struct GenOptions_R *o);

#endif

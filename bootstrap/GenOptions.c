#if !defined(O7_INIT_MODEL)
#   define   O7_INIT_MODEL O7_INIT_ZERO
#endif

#include <o7.h>

#include "GenOptions.h"

#define GenOptions_R_tag V_Base_tag

extern void GenOptions_Default(struct GenOptions_R *o) {
	o->checkIndex = (0 < 1);
	o->checkArith = (0 < 1);
	o->caseAbort = (0 < 1);
	o->o7Assert = (0 < 1);

	o->comment = (0 < 1);
	o->generatorNote = (0 < 1);

	o->main_ = (0 > 1);

	o->varInit = GenOptions_VarInitUndefined_cnst;
	o->identEnc = GenOptions_IdentEncEscUnicode_cnst;
}

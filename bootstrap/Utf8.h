#if !defined HEADER_GUARD_Utf8
#    define  HEADER_GUARD_Utf8 1

#include "TypesLimits.h"

#define Utf8_Null_cnst (0x00u)
#define Utf8_TransmissionEnd_cnst (0x04u)
#define Utf8_Bell_cnst (0x07u)
#define Utf8_BackSpace_cnst (0x08u)
#define Utf8_Tab_cnst (0x09u)
#define Utf8_NewLine_cnst (0x0Au)
#define Utf8_NewPage_cnst (0x0Cu)
#define Utf8_CarRet_cnst (0x0Du)
#define Utf8_Idle_cnst (0x16u)
#define Utf8_DQuote_cnst ((o7_char)'"')
#define Utf8_Delete_cnst ((o7_char)'')

typedef struct Utf8_R {
	o7_int_t val;
	o7_int_t len;
} Utf8_R;
#define Utf8_R_tag o7_base_tag

extern o7_bool Utf8_EqualIgnoreCase(o7_char a, o7_char b);

#endif

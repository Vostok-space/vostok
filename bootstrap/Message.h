#if !defined HEADER_GUARD_Message
#    define  HEADER_GUARD_Message 1

#include "CliParser.h"
#include "Out.h"
#include "Utf8.h"

extern void Message_Usage(o7_bool full);

extern void Message_CliError(o7_int_t err);

extern void Message_init(void);
#endif

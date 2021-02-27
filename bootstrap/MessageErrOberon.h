#if !defined HEADER_GUARD_MessageErrOberon
#    define  HEADER_GUARD_MessageErrOberon 1

#include "Ast.h"
#include "Parser.h"
#include "Scanner.h"
#include "Out.h"
#include "Utf8.h"

extern void MessageErrOberon_Ast(o7_int_t code, struct StringStore_String *str);

extern void MessageErrOberon_Syntax(o7_int_t code);

extern void MessageErrOberon_Text(o7_int_t str_len0, o7_char str[/*len0*/]);

extern void MessageErrOberon_Ln(void);

extern void MessageErrOberon_init(void);
#endif

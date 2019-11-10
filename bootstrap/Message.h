#if !defined HEADER_GUARD_Message
#    define  HEADER_GUARD_Message 1

#include "Ast.h"
#include "Parser.h"
#include "CliParser.h"
#include "Scanner.h"
#include "Out.h"
#include "Utf8.h"

extern void Message_AstError(o7_int_t code, struct StringStore_String *str);

extern void Message_ParseError(o7_int_t code);

extern void Message_Usage(o7_bool full);

extern void Message_CliError(o7_int_t err);

extern void Message_Text(o7_int_t str_len0, o7_char str[/*len0*/]);

extern void Message_Ln(void);

extern void Message_init(void);
#endif

#if !defined HEADER_GUARD_Scanner
#    define  HEADER_GUARD_Scanner 1

#include "V.h"
#include "VDataStream.h"
#include "Utf8.h"
#include "TranslatorLimits.h"
#include "StringStore.h"
#include "Log.h"


#define Scanner_EndOfFile_cnst 0

#define Scanner_Plus_cnst 1
#define Scanner_Minus_cnst 2
#define Scanner_Or_cnst 3

#define Scanner_Dot_cnst 4
#define Scanner_Range_cnst 5
#define Scanner_Comma_cnst 6
#define Scanner_Colon_cnst 7
#define Scanner_Assign_cnst 8
#define Scanner_Semicolon_cnst 9
#define Scanner_Dereference_cnst 10

#define Scanner_RelationFirst_cnst 11
#define Scanner_Equal_cnst 11
#define Scanner_Inequal_cnst 12
#define Scanner_Less_cnst 13
#define Scanner_LessEqual_cnst 14
#define Scanner_Greater_cnst 15
#define Scanner_GreaterEqual_cnst 16
#define Scanner_In_cnst 17
#define Scanner_Is_cnst 18
#define Scanner_RelationLast_cnst 18

#define Scanner_MultFirst_cnst 19
#define Scanner_Asterisk_cnst 19
#define Scanner_Slash_cnst 20
#define Scanner_And_cnst 21
#define Scanner_Div_cnst 22
#define Scanner_Mod_cnst 23
#define Scanner_MultLast_cnst 23

#define Scanner_Negate_cnst 24
#define Scanner_Alternative_cnst 25
#define Scanner_Brace1Open_cnst 26
#define Scanner_Brace1Close_cnst 27
#define Scanner_Brace2Open_cnst 28
#define Scanner_Brace2Close_cnst 29
#define Scanner_Brace3Open_cnst 30
#define Scanner_Brace3Close_cnst 31

#define Scanner_Number_cnst 32
#define Scanner_CharHex_cnst 33
#define Scanner_String_cnst 34
#define Scanner_Ident_cnst 35

#define Scanner_ErrUnexpectChar_cnst (-1)
#define Scanner_ErrNumberTooBig_cnst (-2)
#define Scanner_ErrRealScaleTooBig_cnst (-3)
#define Scanner_ErrWordLenTooBig_cnst (-4)
#define Scanner_ErrExpectHOrX_cnst (-5)
#define Scanner_ErrExpectDQuote_cnst (-6)
#define Scanner_ErrExpectDigitInScale_cnst (-7)
#define Scanner_ErrUnclosedComment_cnst (-8)

#define Scanner_ErrMin_cnst (-100)

#define Scanner_BlockSize_cnst 8192

typedef struct Scanner_Scanner {
	V_Base _;
	struct VDataStream_In *in_;
	o7_int_t line;
	o7_int_t column;
	o7_char buf[Scanner_BlockSize_cnst * 2 + 1];
	o7_int_t ind;

	o7_int_t lexStart;
	o7_int_t lexEnd;
	o7_int_t emptyLines;

	o7_bool isReal;
	o7_bool isChar;
	o7_int_t integer;
	double real;

	struct Scanner_Scanner__anon__0000 {
		o7_bool cyrillic;
		o7_int_t tabSize;
	} opt;

	o7_int_t commentOfs;
	o7_int_t commentEnd;
} Scanner_Scanner;
#define Scanner_Scanner_tag V_Base_tag

extern void Scanner_Scanner_undef(struct Scanner_Scanner *r);

extern void Scanner_Init(struct Scanner_Scanner *s, struct VDataStream_In *in_);

extern o7_bool Scanner_InitByString(struct Scanner_Scanner *s, o7_int_t in__len0, o7_char in_[/*len0*/]);

extern o7_int_t Scanner_Next(struct Scanner_Scanner *s);

extern o7_bool Scanner_TakeCommentPos(struct Scanner_Scanner *s, o7_int_t *ofs, o7_int_t *end);

extern void Scanner_ResetComment(struct Scanner_Scanner *s);

extern void Scanner_init(void);
#endif

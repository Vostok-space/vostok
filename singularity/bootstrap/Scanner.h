#if !defined(HEADER_GUARD_Scanner)
#define HEADER_GUARD_Scanner

#include "V.h"
#include "VDataStream.h"
#include "Utf8.h"
#include "TranslatorLimits.h"
#include "Log.h"

#define Scanner_EndOfFile_cnst 0
#define Scanner_UnexpectChar_cnst 1
#define Scanner_Plus_cnst 10
#define Scanner_Minus_cnst 11
#define Scanner_Dot_cnst 14
#define Scanner_Range_cnst 15
#define Scanner_Comma_cnst 16
#define Scanner_Colon_cnst 17
#define Scanner_Assign_cnst 18
#define Scanner_Semicolon_cnst 19
#define Scanner_Dereference_cnst 20
#define Scanner_RelationFirst_cnst 21
#define Scanner_Equal_cnst 21
#define Scanner_Inequal_cnst 22
#define Scanner_Less_cnst 23
#define Scanner_LessEqual_cnst 24
#define Scanner_Greater_cnst 25
#define Scanner_GreaterEqual_cnst 26
#define Scanner_In_cnst 27
#define Scanner_Is_cnst 28
#define Scanner_RelationLast_cnst 28
#define Scanner_Negate_cnst 29
#define Scanner_Alternative_cnst 31
#define Scanner_Brace1Open_cnst 32
#define Scanner_Brace1Close_cnst 33
#define Scanner_Brace2Open_cnst 34
#define Scanner_Brace2Close_cnst 35
#define Scanner_Brace3Open_cnst 36
#define Scanner_Brace3Close_cnst 37
#define Scanner_Number_cnst 40
#define Scanner_CharHex_cnst 41
#define Scanner_String_cnst 42
#define Scanner_Ident_cnst 43
#define Scanner_Array_cnst 50
#define Scanner_Begin_cnst 51
#define Scanner_By_cnst 52
#define Scanner_Case_cnst 53
#define Scanner_Const_cnst 54
#define Scanner_Do_cnst 56
#define Scanner_Else_cnst 57
#define Scanner_Elsif_cnst 58
#define Scanner_End_cnst 59
#define Scanner_False_cnst 60
#define Scanner_For_cnst 61
#define Scanner_If_cnst 62
#define Scanner_Import_cnst 63
#define Scanner_Module_cnst 67
#define Scanner_Nil_cnst 68
#define Scanner_Of_cnst 69
#define Scanner_Or_cnst 70
#define Scanner_Pointer_cnst 71
#define Scanner_Procedure_cnst 72
#define Scanner_Record_cnst 73
#define Scanner_Repeat_cnst 74
#define Scanner_Return_cnst 75
#define Scanner_Then_cnst 76
#define Scanner_To_cnst 77
#define Scanner_True_cnst 78
#define Scanner_Type_cnst 79
#define Scanner_Until_cnst 80
#define Scanner_Var_cnst 81
#define Scanner_While_cnst 82
#define Scanner_MultFirst_cnst 150
#define Scanner_Asterisk_cnst 150
#define Scanner_Slash_cnst 151
#define Scanner_And_cnst 152
#define Scanner_Div_cnst 153
#define Scanner_Mod_cnst 154
#define Scanner_MultLast_cnst 154
#define Scanner_PredefinedFirst_cnst 90
#define Scanner_Abs_cnst 90
#define Scanner_Asr_cnst 91
#define Scanner_Assert_cnst 92
#define Scanner_Boolean_cnst 93
#define Scanner_Byte_cnst 94
#define Scanner_Char_cnst 95
#define Scanner_Chr_cnst 96
#define Scanner_Dec_cnst 97
#define Scanner_Excl_cnst 98
#define Scanner_Floor_cnst 99
#define Scanner_Flt_cnst 100
#define Scanner_Inc_cnst 101
#define Scanner_Incl_cnst 102
#define Scanner_Integer_cnst 103
#define Scanner_Len_cnst 104
#define Scanner_Lsl_cnst 105
#define Scanner_New_cnst 106
#define Scanner_Odd_cnst 107
#define Scanner_Ord_cnst 108
#define Scanner_Pack_cnst 109
#define Scanner_Real_cnst 110
#define Scanner_Ror_cnst 111
#define Scanner_Set_cnst 112
#define Scanner_Unpk_cnst 113
#define Scanner_PredefinedLast_cnst 113
#define Scanner_ErrUnexpectChar_cnst (-1)
#define Scanner_ErrNumberTooBig_cnst (-2)
#define Scanner_ErrRealScaleTooBig_cnst (-3)
#define Scanner_ErrWordLenTooBig_cnst (-4)
#define Scanner_ErrExpectHOrX_cnst (-5)
#define Scanner_ErrExpectDQuote_cnst (-6)
#define Scanner_ErrExpectDigitInScale_cnst (-7)
#define Scanner_ErrUnclosedComment_cnst (-8)
#define Scanner_ErrMin_cnst (-100)
#define Scanner_BlockSize_cnst 65536

typedef struct Scanner_Scanner {
	struct V_Base _;
	struct VDataStream_In *in_;
	int line;
	int column;
	int tabs;
	char unsigned buf[Scanner_BlockSize_cnst * 2 + 1];
	int ind;
	int lexStart;
	int lexEnd;
	int lexLen;
	bool isReal;
	bool isChar;
	int integer;
	double real;
} Scanner_Scanner;
extern o7c_tag_t Scanner_Scanner_tag;


extern void Scanner_Init(struct Scanner_Scanner *s, o7c_tag_t s_tag, struct VDataStream_In *in_, o7c_tag_t in__tag);

extern int Scanner_CheckPredefined(char unsigned buf[/*len0*/], int buf_len0, int begin, int end);

extern int Scanner_Next(struct Scanner_Scanner *s, o7c_tag_t s_tag);

extern void Scanner_init_(void);
#endif

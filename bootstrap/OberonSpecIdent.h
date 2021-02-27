#if !defined HEADER_GUARD_OberonSpecIdent
#    define  HEADER_GUARD_OberonSpecIdent 1

#include "Utf8.h"
#include "StringStore.h"

#define OberonSpecIdent_Array_cnst 100
#define OberonSpecIdent_Begin_cnst 101
#define OberonSpecIdent_By_cnst 102
#define OberonSpecIdent_Case_cnst 103
#define OberonSpecIdent_Const_cnst 104
#define OberonSpecIdent_Div_cnst 105
#define OberonSpecIdent_Do_cnst 106
#define OberonSpecIdent_Else_cnst 107
#define OberonSpecIdent_Elsif_cnst 108
#define OberonSpecIdent_End_cnst 109
#define OberonSpecIdent_False_cnst 110
#define OberonSpecIdent_For_cnst 111
#define OberonSpecIdent_If_cnst 112
#define OberonSpecIdent_Import_cnst 113
#define OberonSpecIdent_In_cnst 114
#define OberonSpecIdent_Is_cnst 115
#define OberonSpecIdent_Mod_cnst 116
#define OberonSpecIdent_Module_cnst 117
#define OberonSpecIdent_Nil_cnst 118
#define OberonSpecIdent_Of_cnst 119
#define OberonSpecIdent_Or_cnst 120
#define OberonSpecIdent_Pointer_cnst 121
#define OberonSpecIdent_Procedure_cnst 122
#define OberonSpecIdent_Record_cnst 123
#define OberonSpecIdent_Repeat_cnst 124
#define OberonSpecIdent_Return_cnst 125
#define OberonSpecIdent_Then_cnst 126
#define OberonSpecIdent_To_cnst 127
#define OberonSpecIdent_True_cnst 128
#define OberonSpecIdent_Type_cnst 129
#define OberonSpecIdent_Until_cnst 130
#define OberonSpecIdent_Var_cnst 131
#define OberonSpecIdent_While_cnst 132
#define OberonSpecIdent_PredefinedFirst_cnst 200
#define OberonSpecIdent_Abs_cnst 200
#define OberonSpecIdent_Asr_cnst 201
#define OberonSpecIdent_Assert_cnst 202
#define OberonSpecIdent_Boolean_cnst 203
#define OberonSpecIdent_Byte_cnst 204
#define OberonSpecIdent_Char_cnst 205
#define OberonSpecIdent_Chr_cnst 206
#define OberonSpecIdent_Dec_cnst 207
#define OberonSpecIdent_Excl_cnst 208
#define OberonSpecIdent_Floor_cnst 209
#define OberonSpecIdent_Flt_cnst 210
#define OberonSpecIdent_Inc_cnst 211
#define OberonSpecIdent_Incl_cnst 212
#define OberonSpecIdent_Integer_cnst 213
#define OberonSpecIdent_Len_cnst 214
#define OberonSpecIdent_LongInt_cnst 215
#define OberonSpecIdent_LongSet_cnst 216
#define OberonSpecIdent_Lsl_cnst 217
#define OberonSpecIdent_New_cnst 218
#define OberonSpecIdent_Odd_cnst 219
#define OberonSpecIdent_Ord_cnst 220
#define OberonSpecIdent_Pack_cnst 221
#define OberonSpecIdent_Real_cnst 222
#define OberonSpecIdent_Real32_cnst 223
#define OberonSpecIdent_Ror_cnst 224
#define OberonSpecIdent_Set_cnst 225
#define OberonSpecIdent_Unpk_cnst 226
#define OberonSpecIdent_PredefinedLast_cnst 226

extern o7_bool OberonSpecIdent_IsModule(o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t ind, o7_int_t end);

extern o7_bool OberonSpecIdent_IsKeyWord(o7_int_t *kw, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t ind, o7_int_t end);

extern o7_bool OberonSpecIdent_IsPredefined(o7_int_t *pd, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t begin, o7_int_t end);

extern o7_bool OberonSpecIdent_IsSpecName(struct StringStore_String *n);

extern void OberonSpecIdent_init(void);
#endif

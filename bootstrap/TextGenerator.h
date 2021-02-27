#if !defined HEADER_GUARD_TextGenerator
#    define  HEADER_GUARD_TextGenerator 1

#include "V.h"
#include "Utf8.h"
#include "Hex.h"
#include "StringStore.h"
#include "Chars0X.h"
#include "VDataStream.h"
#include "TypesLimits.h"

typedef struct TextGenerator_Out {
	V_Base _;
	struct VDataStream_Out *out;
	o7_int_t len;
	o7_int_t tabs;
	o7_bool isNewLine;
	o7_char defered[1];
} TextGenerator_Out;
#define TextGenerator_Out_tag V_Base_tag


extern void TextGenerator_Init(struct TextGenerator_Out *g, struct VDataStream_Out *out);

extern void TextGenerator_SetTabs(struct TextGenerator_Out *g, struct TextGenerator_Out *d);

extern void TextGenerator_CharFill(struct TextGenerator_Out *gen, o7_char ch, o7_int_t count);

extern void TextGenerator_Char(struct TextGenerator_Out *gen, o7_char ch);

extern void TextGenerator_DeferChar(struct TextGenerator_Out *gen, o7_char ch);

extern void TextGenerator_CancelDeferedOrWriteChar(struct TextGenerator_Out *gen, o7_char ch);

extern void TextGenerator_Str(struct TextGenerator_Out *gen, o7_int_t str_len0, o7_char str[/*len0*/]);

extern void TextGenerator_StrLn(struct TextGenerator_Out *gen, o7_int_t str_len0, o7_char str[/*len0*/]);

extern void TextGenerator_Ln(struct TextGenerator_Out *gen);

extern void TextGenerator_StrOpen(struct TextGenerator_Out *gen, o7_int_t str_len0, o7_char str[/*len0*/]);

extern void TextGenerator_IndentOpen(struct TextGenerator_Out *gen);

extern void TextGenerator_IndentClose(struct TextGenerator_Out *gen);

extern void TextGenerator_StrClose(struct TextGenerator_Out *gen, o7_int_t str_len0, o7_char str[/*len0*/]);

extern void TextGenerator_StrLnClose(struct TextGenerator_Out *gen, o7_int_t str_len0, o7_char str[/*len0*/]);

extern void TextGenerator_LnStrClose(struct TextGenerator_Out *gen, o7_int_t str_len0, o7_char str[/*len0*/]);

extern void TextGenerator_StrIgnoreIndent(struct TextGenerator_Out *gen, o7_int_t str_len0, o7_char str[/*len0*/]);

extern void TextGenerator_String(struct TextGenerator_Out *gen, struct StringStore_String *word);

extern void TextGenerator_Data(struct TextGenerator_Out *gen, o7_int_t data_len0, o7_char data[/*len0*/], o7_int_t ofs, o7_int_t count);

extern void TextGenerator_ScreeningString(struct TextGenerator_Out *gen, struct StringStore_String *str);

extern void TextGenerator_Int(struct TextGenerator_Out *gen, o7_int_t int_);

extern void TextGenerator_Real(struct TextGenerator_Out *gen, double real);

extern void TextGenerator_HexSeparateHighBit(struct TextGenerator_Out *gen, o7_int_t v, o7_bool highBit);

extern void TextGenerator_Hex(struct TextGenerator_Out *gen, o7_int_t v);

extern void TextGenerator_Set(struct TextGenerator_Out *gen, o7_set_t *set);

extern void TextGenerator_init(void);
#endif

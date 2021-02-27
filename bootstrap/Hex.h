#if !defined HEADER_GUARD_Hex
#    define  HEADER_GUARD_Hex 1


#define Hex_Range_cnst 0xFFFFu

extern o7_char Hex_To(o7_int_t d);

extern o7_bool Hex_InRange(o7_char ch);

extern o7_int_t Hex_From(o7_char d);

#endif

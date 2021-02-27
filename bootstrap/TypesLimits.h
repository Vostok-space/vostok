#if !defined HEADER_GUARD_TypesLimits
#    define  HEADER_GUARD_TypesLimits 1

#define TypesLimits_IntegerMax_cnst 2147483647
#define TypesLimits_IntegerMin_cnst (-2147483647)

#define TypesLimits_CharMax_cnst (0xFFu)

#define TypesLimits_ByteMax_cnst 255

#define TypesLimits_SetMax_cnst 31

extern o7_bool TypesLimits_InByteRange(o7_int_t v);

extern o7_bool TypesLimits_InCharRange(o7_int_t v);

extern o7_bool TypesLimits_InSetRange(o7_int_t v);

#endif

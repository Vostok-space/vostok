#if !defined(HEADER_GUARD_Limits)
#define HEADER_GUARD_Limits


#define Limits_IntegerMax_cnst 2147483647
#define Limits_IntegerMin_cnst (-2147483647)
#define Limits_CharMax_cnst "\xFF"
#define Limits_ByteMax_cnst 255
#define Limits_SetMax_cnst 31

extern o7c_bool Limits_IsNan(double r);

extern o7c_bool Limits_InByteRange(int v);

extern o7c_bool Limits_InCharRange(int v);

static inline void Limits_init(void) { ; }
#endif

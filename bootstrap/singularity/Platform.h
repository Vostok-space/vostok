#if !defined HEADER_GUARD_Platform
#    define  HEADER_GUARD_Platform 1

extern o7_cbool const
  Platform_Posix,
  Platform_Linux,
  Platform_Bsd,
  Platform_Mingw,
  Platform_Dos,
  Platform_Windows,
  Platform_Darwin,
  Platform_Haiku,
  Platform_C,
  Platform_Java,
  Platform_Javascript;

O7_ALWAYS_INLINE void Platform_init(void) {}
O7_ALWAYS_INLINE void Platform_done(void) {}
#endif

#define O7_BOOL_UNDEFINED
#include <o7.h>

#include "Platform.h"

#if defined(__linux__) || defined(__linux)
  o7_cbool const Platform_Linux = 0 < 1;
#else
  o7_cbool const Platform_Linux = 0 > 1;
#endif

#if defined(_WIN16) || defined(_WIN32) || defined(_WIN64)
  o7_cbool const Platform_Windows = 0 < 1;
#else
  o7_cbool const Platform_Windows = 0 > 1;
#endif

#if defined(__MINGW32__) || defined(__MINGW64__)
  o7_cbool const Platform_Mingw = 0 < 1;
#else
  o7_cbool const Platform_Mingw = 0 > 1;
#endif

#if defined(__FreeBSD__) || defined(__NetBSD__) || defined(__OpenBSD__) || defined(__bsdi__)
# define Platform_Bsd_Macro
  o7_cbool const Platform_Bsd = 0 < 1;
#else
  o7_cbool const Platform_Bsd = 0 > 1;
#endif

#if defined(MSDOS) || defined(__MSDOS__) || defined(__DOS__)
  o7_cbool const Platform_Dos = 0 < 1;
#else
  o7_cbool const Platform_Dos = 0 > 1;
#endif

#if defined(__APPLE__)
  o7_cbool const Platform_Darwin = 0 < 1;
#else
  o7_cbool const Platform_Darwin = 0 > 1;
#endif

#if defined(__HAIKU__)
  o7_cbool const Platform_Haiku = 0 < 1;
#else
  o7_cbool const Platform_Haiku = 0 > 1;
#endif

#if defined(__unix__) || defined(__unix) \
 || defined(__linux__) || defined(__linux) || defined(Platform_Bsd_Macro) \
 || defined(__minix__) || defined(__minix) \
 || defined(__APPLE__) || defined(__HAIKU__) \
 || defined(__sun__) || defined(__sun)
  o7_cbool const Platform_Posix = 0 < 1;
#else
  o7_cbool const Platform_Posix = 0 > 1;
#endif

o7_cbool const Platform_C          = 0 < 1;
o7_cbool const Platform_Java       = 0 > 1;
o7_cbool const Platform_Javascript = 0 > 1;

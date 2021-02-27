#if !defined HEADER_GUARD_CFiles
#    define  HEADER_GUARD_CFiles 1

#define CFiles_KiB_cnst 1024
#define CFiles_MiB_cnst (CFiles_KiB_cnst * 1024)
#define CFiles_GiB_cnst (CFiles_MiB_cnst * 1024)

typedef struct CFiles_Implement* CFiles_File;

extern CFiles_File CFiles_in, CFiles_out, CFiles_err;

extern CFiles_File CFiles_Open(
	O7_FPA(o7_char, name), o7_int_t ofs,
	O7_FPA(o7_char, mode));

extern void CFiles_Close(CFiles_File *file);

extern int CFiles_Read (CFiles_File file, O7_FPA(o7_char, buf), o7_int_t ofs, o7_int_t count);
extern int CFiles_Write(CFiles_File file, O7_FPA(o7_char, buf), o7_int_t ofs, o7_int_t count);

O7_ALWAYS_INLINE
int CFiles_ReadChars(CFiles_File file, O7_FPA(o7_char, buf), o7_int_t ofs, o7_int_t count) {
	return CFiles_Read(file, O7_APA(buf), ofs, count);
}

O7_ALWAYS_INLINE
int CFiles_WriteChars(CFiles_File file, O7_FPA(o7_char, buf), o7_int_t ofs, o7_int_t count) {
	return CFiles_Write(file, O7_APA(buf), ofs, count);
}

extern o7_bool CFiles_Flush(CFiles_File file);

extern o7_int_t CFiles_Seek(CFiles_File file, o7_int_t gibs, o7_int_t bytes);

extern o7_int_t CFiles_Tell(CFiles_File file, o7_int_t *gibs, o7_int_t *bytes);

extern o7_int_t CFiles_Remove(O7_FPA(o7_char const, name), o7_int_t ofs);

extern o7_bool CFiles_Exist(O7_FPA(o7_char const, name), o7_int_t ofs);

extern void CFiles_init(void);
O7_ALWAYS_INLINE void CFiles_done(void) { ; }

#endif

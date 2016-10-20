#if !defined(HEADER_GUARD_CFiles)
#define HEADER_GUARD_CFiles

typedef struct CFiles_Implement* CFiles_File;

extern CFiles_File CFiles_Open(char unsigned name[/*len*/], int name_len, int ofs,
							   char unsigned mode[/*len*/], int mode_len);

extern void CFiles_Close(CFiles_File *file, int *file_tag);

extern int CFiles_Read(CFiles_File file, int *file_tag,
					   char unsigned buf[/*len*/], int buf_len, int ofs, int count);

extern int CFiles_Write(CFiles_File file, int *file_tag,
						char unsigned buf[/*len*/], int buf_len, int ofs, int count);

extern void CFiles_init_(void);

#endif

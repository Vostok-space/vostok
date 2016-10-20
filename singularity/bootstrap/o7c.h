#if !defined(HEADER_GUARD_o7c)
#define HEADER_GUARD_o7c

#if !defined(O7C_MAX_RECORD_EXT)
#	define O7C_MAX_RECORD_EXT 15
#endif

#if !defined(O7C_INLINE)
#	if __STDC_VERSION__ >= 199901L
#		define O7C_INLINE inline
#	else
#		define O7C_INLINE 
#	endif
#endif

#if defined(O7C_TAG_ID_TYPE)
	typedef O7C_TAG_ID_TYPE o7c_id_t;
#else
	typedef int o7c_id_t;
#endif

typedef o7c_id_t o7c_tag_t[O7C_MAX_RECORD_EXT];

extern void o7c_tag_init(o7c_tag_t ext, o7c_tag_t const base);

static O7C_INLINE void* o7c_new(int size, o7c_tag_t const tag) {
	void *mem;
	mem = malloc(sizeof(o7c_id_t *) + size);
	if (NULL != mem) {
		*(o7c_id_t const **)mem = tag;
		mem = (void *)((o7c_id_t **)mem + 1);
	}
	return mem;
}

static O7C_INLINE o7c_id_t const * o7c_dynamic_tag(void const *mem) {
	return *((o7c_id_t const **)mem - 1);
}

static O7C_INLINE int
	o7c_is(o7c_tag_t const base, void const *strct, o7c_tag_t const ext)
{
	if (NULL != strct) {
		if (NULL == base) {
			base = o7c_dynamic_tag(strct);
		}
	}
	return (NULL != strct) && (base[ext[0]] == ext[ext[0]]);
}

static O7C_INLINE void const*
	o7c_must(o7c_tag_t const base, void const *strct, o7c_tag_t const ext)
{
	assert((NULL == strct) || o7c_is(base, strct, ext));
	return strct;
}

extern void o7c_cli_init(int argc, char *argv[]);

extern int o7c_exit_code;

#define O7C_GUARD(ExtType, strct, base) \
	(*(struct ExtType *)o7c_must(base, strct, ExtType##_tag))

#define O7C_SET(low, high) ((~0u << low) & (~0u >> (sizeof(int) * 8 - 1 - high)))

#endif

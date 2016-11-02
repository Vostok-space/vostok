/* Copyright 2016 ComdivByZero
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#if !defined(HEADER_GUARD_o7c)
#define HEADER_GUARD_o7c

#if !defined(O7C_INLINE)
#	if __STDC_VERSION__ >= 199901L
#		define O7C_INLINE inline
#	elif __GNUC__ > 2
#		define O7C_INLINE __inline__
#	else
#		define O7C_INLINE 
#	endif
#endif

#if defined(O7C_BOOL)
	typedef O7C_BOOL o7c_bool;
#elif __STDC_VERSION__ >= 199901L
	typedef _Bool o7c_bool;
#else
	typedef int o7c_bool;
#endif

typedef char unsigned o7c_char;

#if __GNUC__ > 2
#	define O7C_ATTR_ALWAYS_INLINE __attribute__((always_inline))
#else
#	define O7C_ATTR_ALWAYS_INLINE
#endif

#if defined(O7C_LSAN_LEAK_IGNORE)
#	include <sanitizer/lsan_interface.h>
	static O7C_INLINE void* o7c_malloc(size_t size) O7C_ATTR_ALWAYS_INLINE;
	static O7C_INLINE void* o7c_malloc(size_t size) {
		void *mem;
		mem = malloc(size);
		__lsan_ignore_object(mem);
		return mem;
	}
#else
	static O7C_INLINE void* o7c_malloc(size_t size) O7C_ATTR_ALWAYS_INLINE;
	static O7C_INLINE void* o7c_malloc(size_t size) {
		return malloc(size);
	}
#endif

#if !defined(O7C_MAX_RECORD_EXT)
#	define O7C_MAX_RECORD_EXT 15
#endif

#if defined(O7C_TAG_ID_TYPE)
	typedef O7C_TAG_ID_TYPE o7c_id_t;
#else
	typedef int o7c_id_t;
#endif

typedef o7c_id_t o7c_tag_t[O7C_MAX_RECORD_EXT + 1];

static O7C_INLINE int o7c_index(int len, int ind) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE int o7c_index(int len, int ind) {
	assert(len > 0);
	assert((unsigned)ind < (unsigned)len);
	return ind;
}

extern void o7c_tag_init(o7c_tag_t ext, o7c_tag_t const base);

static O7C_INLINE void* o7c_new(int size, o7c_tag_t const tag)
	O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE void* o7c_new(int size, o7c_tag_t const tag) {
	void *mem;
	mem = o7c_malloc(sizeof(o7c_id_t *) + size);
	if (NULL != mem) {
		*(o7c_id_t const **)mem = tag;
		mem = (void *)((o7c_id_t **)mem + 1);
	}
	return mem;
}

static O7C_INLINE o7c_id_t const * o7c_dynamic_tag(void const *mem)
	O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE o7c_id_t const * o7c_dynamic_tag(void const *mem) {
	return *((o7c_id_t const **)mem - 1);
}

static O7C_INLINE o7c_bool o7c_is(o7c_tag_t const base, void const *strct,
	o7c_tag_t const ext) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE o7c_bool
	o7c_is(o7c_tag_t const base, void const *strct, o7c_tag_t const ext)
{
	if ((NULL == base) && (NULL != strct)) {
		base = o7c_dynamic_tag(strct);
	}
	return (NULL != strct) && (base[ext[0]] == ext[ext[0]]);
}

static O7C_INLINE void const* o7c_must(o7c_tag_t const base, void const *strct,
	o7c_tag_t const ext) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE void const*
	o7c_must(o7c_tag_t const base, void const *strct, o7c_tag_t const ext)
{
	assert((NULL == strct) || o7c_is(base, strct, ext));
	return strct;
}

#define O7C_GUARD(ExtType, strct, base) \
	(*(struct ExtType *)o7c_must(base, strct, ExtType##_tag))

static O7C_INLINE unsigned o7c_set(int low, int high) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE unsigned o7c_set(int low, int high) {
	assert(low >= 0);
	assert(high <= 31);
	assert(low <= high);
	return (~0u << low) & (~0u >> (31 - high));
}

#define O7C_SET(low, high) ((~0u << low) & (~0u >> (31 - high)))

extern void o7c_init(int argc, char *argv[]);

extern int o7c_exit_code;

#endif

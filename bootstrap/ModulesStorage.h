#if !defined HEADER_GUARD_ModulesStorage
#    define  HEADER_GUARD_ModulesStorage 1

#include "Log.h"
#include "Ast.h"
#include "StringStore.h"

typedef struct ModulesStorage_RContainer *ModulesStorage_Container;
typedef struct ModulesStorage_RContainer {
	struct ModulesStorage_RContainer *next;
	struct Ast_RModule *m;
} ModulesStorage_RContainer;
#define ModulesStorage_RContainer_tag o7_base_tag

extern void ModulesStorage_RContainer_undef(struct ModulesStorage_RContainer *r);

typedef struct ModulesStorage_Provider__s {
	Ast_RProvider _;
	struct Ast_RProvider *provider;

	struct ModulesStorage_RContainer *first;
	struct ModulesStorage_RContainer *last;
} *ModulesStorage_Provider;
extern o7_tag_t ModulesStorage_Provider__s_tag;

extern void ModulesStorage_Provider__s_undef(struct ModulesStorage_Provider__s *r);

extern struct ModulesStorage_RContainer *ModulesStorage_Iterate(struct ModulesStorage_Provider__s *p);

extern struct Ast_RModule *ModulesStorage_Next(struct ModulesStorage_RContainer **it);

extern void ModulesStorage_Unlink(struct ModulesStorage_Provider__s **p);

extern struct Ast_RModule *ModulesStorage_GetModule(struct Ast_RProvider *p, struct Ast_RModule *host, o7_int_t name_len0, o7_char name[/*len0*/], o7_int_t ofs, o7_int_t end);

extern void ModulesStorage_New(struct ModulesStorage_Provider__s **mp, struct Ast_RProvider *else_);

extern void ModulesStorage_init(void);
#endif

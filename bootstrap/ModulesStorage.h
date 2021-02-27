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


typedef struct ModulesStorage_Provider__s {
	Ast_RProvider _;
	struct Ast_RProvider *provider;

	struct ModulesStorage_RContainer *first;
	struct ModulesStorage_RContainer *last;
} *ModulesStorage_Provider;
extern o7_tag_t ModulesStorage_Provider__s_tag;


extern struct ModulesStorage_RContainer *ModulesStorage_Iterate(struct ModulesStorage_Provider__s *p);

extern struct Ast_RModule *ModulesStorage_Next(struct ModulesStorage_RContainer **it);

extern void ModulesStorage_Unlink(struct ModulesStorage_Provider__s **p);

extern void ModulesStorage_New(struct ModulesStorage_Provider__s **mp, struct Ast_RProvider *else_);

extern void ModulesStorage_init(void);
#endif

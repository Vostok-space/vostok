#if !defined(O7_INIT_MODEL)
#   define   O7_INIT_MODEL O7_INIT_ZERO
#endif

#include <o7.h>

#include "V.h"

#define V_Message_tag o7_base_tag
#define V_Base_tag V_Message_tag
#define V_Error_tag V_Base_tag
#define V_MsgFinalize_tag V_Base_tag
#define V_MsgNeedMemory_tag V_Base_tag
#define V_MsgCopy_tag V_Base_tag
#define V_MsgLinks_tag V_Base_tag
#define V_MsgHash_tag V_Base_tag

static o7_bool Nothing(struct V_Message *this_, struct V_Message *mes) {
	return (0 > 1);
}

extern void V_Init(struct V_Base *base) {
	base->do_ = Nothing;
}

extern void V_SetDo(struct V_Base *base, V_Handle do_) {
	V_Handle nothing;

	nothing = Nothing;
	O7_ASSERT(base->do_ == nothing);
	base->do_ = do_;
}

extern o7_bool V_Do(struct V_Base *handler, struct V_Message *message) {
	return handler->do_(&(*handler)._, message);
}

#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#include <o7c.h>

#include "V.h"

o7c_tag_t V_Message_tag;
o7c_tag_t V_Base_tag;
o7c_tag_t V_Error_tag;
o7c_tag_t V_MsgFinalize_tag;
o7c_tag_t V_MsgNeedMemory_tag;
o7c_tag_t V_MsgCopy_tag;
o7c_tag_t V_MsgLinks_tag;
o7c_tag_t V_MsgContentPass_tag;
o7c_tag_t V_MsgHash_tag;

static bool Nothing(struct V_Base *this_, o7c_tag_t this__tag, struct V_Message *mes, o7c_tag_t mes_tag) {
	return false;
}

extern void V_Init(struct V_Base *base, o7c_tag_t base_tag) {
	(*base).do_ = Nothing;
}

extern void V_SetDo(struct V_Base *base, o7c_tag_t base_tag, V_Handle do_) {
	assert((*base).do_ == Nothing);
	(*base).do_ = do_;
}

extern bool V_Do(struct V_Base *handler, o7c_tag_t handler_tag, struct V_Message *message, o7c_tag_t message_tag) {
	return (*handler).do_(&(*handler), handler_tag, &(*message), message_tag);
}

extern void V_init_(void) {
	static int initialized__ = 0;
	if (0 == initialized__) {
		o7c_tag_init(V_Message_tag, NULL);
		o7c_tag_init(V_Base_tag, V_Message_tag);
		o7c_tag_init(V_Error_tag, V_Base_tag);
		o7c_tag_init(V_MsgFinalize_tag, V_Base_tag);
		o7c_tag_init(V_MsgNeedMemory_tag, V_Base_tag);
		o7c_tag_init(V_MsgCopy_tag, V_Base_tag);
		o7c_tag_init(V_MsgLinks_tag, V_Base_tag);
		o7c_tag_init(V_MsgContentPass_tag, V_Base_tag);
		o7c_tag_init(V_MsgHash_tag, V_Base_tag);

	}
	++initialized__;
}


#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#include <o7c.h>

#include "V.h"

int V_Message_tag[15];

int V_Base_tag[15];

int V_Error_tag[15];

int V_MsgFinalize_tag[15];

int V_MsgNeedMemory_tag[15];

int V_MsgCopy_tag[15];

int V_MsgLinks_tag[15];

int V_MsgContentPass_tag[15];

int V_MsgHash_tag[15];


static bool Nothing(struct V_Base *this_, int *this__tag, struct V_Message *mes, int *mes_tag) {
	return false;
}

extern void V_Init(struct V_Base *base, int *base_tag) {
	(*base).do_ = Nothing;
}

extern void V_SetDo(struct V_Base *base, int *base_tag, V_Handle do_) {
	assert((*base).do_ == Nothing);
	(*base).do_ = do_;
}

extern bool V_Do(struct V_Base *handler, int *handler_tag, struct V_Message *message, int *message_tag) {
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


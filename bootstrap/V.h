#if !defined HEADER_GUARD_V
#    define  HEADER_GUARD_V 1


typedef struct V_Message { char nothing; } V_Message;
#define V_Message_tag o7_base_tag

typedef struct V_Message *V_PMessage;

typedef o7_bool (*V_Handle)(struct V_Message *this_, struct V_Message *mes);

typedef struct V_Base {
	V_Message _;
	V_Handle do_;
} V_Base;
#define V_Base_tag V_Message_tag

typedef struct V_Base *V_PBase;

typedef struct V_Error {
	V_Base _;
} V_Error;
#define V_Error_tag V_Base_tag

typedef struct V_Error *V_PError;

typedef struct V_MsgFinalize {
	V_Base _;
} V_MsgFinalize;
#define V_MsgFinalize_tag V_Base_tag

typedef struct V_MsgNeedMemory {
	V_Base _;
} V_MsgNeedMemory;
#define V_MsgNeedMemory_tag V_Base_tag

typedef struct V_MsgCopy {
	V_Base _;
	struct V_Base *copy;
} V_MsgCopy;
#define V_MsgCopy_tag V_Base_tag

typedef struct V_MsgLinks {
	V_Base _;
	o7_int_t diff;
	o7_int_t count;
} V_MsgLinks;
#define V_MsgLinks_tag V_Base_tag

typedef struct V_MsgHash {
	V_Base _;
	o7_int_t hash;
} V_MsgHash;
#define V_MsgHash_tag V_Base_tag


extern void V_Init(struct V_Base *base);

extern void V_SetDo(struct V_Base *base, V_Handle do_);

extern o7_bool V_Do(struct V_Base *handler, struct V_Message *message);

#endif

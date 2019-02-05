#if !defined HEADER_GUARD_V
#    define  HEADER_GUARD_V 1

#define V_ContentPassOpen_cnst 0
#define V_ContentPassNext_cnst 1
#define V_ContentPassClose_cnst 2

typedef struct V_Message { char nothing; } V_Message;
#define V_Message_tag o7_base_tag

extern void V_Message_undef(struct V_Message *r);
typedef struct V_Message *V_PMessage;

typedef o7_bool (*V_Handle)(struct V_Message *this_, struct V_Message *mes);

typedef struct V_Base {
	V_Message _;
	V_Handle do_;
} V_Base;
#define V_Base_tag V_Message_tag

extern void V_Base_undef(struct V_Base *r);
typedef struct V_Base *V_PBase;

typedef struct V_Error {
	V_Base _;
} V_Error;
#define V_Error_tag V_Base_tag

extern void V_Error_undef(struct V_Error *r);
typedef struct V_Error *V_PError;

typedef struct V_MsgFinalize {
	V_Base _;
} V_MsgFinalize;
#define V_MsgFinalize_tag V_Base_tag

extern void V_MsgFinalize_undef(struct V_MsgFinalize *r);
typedef struct V_MsgNeedMemory {
	V_Base _;
} V_MsgNeedMemory;
#define V_MsgNeedMemory_tag V_Base_tag

extern void V_MsgNeedMemory_undef(struct V_MsgNeedMemory *r);
typedef struct V_MsgCopy {
	V_Base _;
	struct V_Base *copy;
} V_MsgCopy;
#define V_MsgCopy_tag V_Base_tag

extern void V_MsgCopy_undef(struct V_MsgCopy *r);
typedef struct V_MsgLinks {
	V_Base _;
	o7_int_t diff;
	o7_int_t count;
} V_MsgLinks;
#define V_MsgLinks_tag V_Base_tag

extern void V_MsgLinks_undef(struct V_MsgLinks *r);
typedef struct V_MsgContentPass {
	V_Base _;
	o7_int_t id;
} V_MsgContentPass;
#define V_MsgContentPass_tag V_Base_tag

extern void V_MsgContentPass_undef(struct V_MsgContentPass *r);
typedef struct V_MsgHash {
	V_Base _;
	o7_int_t hash;
} V_MsgHash;
#define V_MsgHash_tag V_Base_tag

extern void V_MsgHash_undef(struct V_MsgHash *r);

extern void V_Init(struct V_Base *base);

extern void V_SetDo(struct V_Base *base, V_Handle do_);

extern o7_bool V_Do(struct V_Base *handler, struct V_Message *message);
#endif

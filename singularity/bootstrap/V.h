#if !defined(HEADER_GUARD_V)
#define HEADER_GUARD_V


#define V_ContentPassOpen_cnst 0
#define V_ContentPassNext_cnst 1
#define V_ContentPassClose_cnst 2

typedef struct V_Message {
} V_Message;
extern o7c_tag_t V_Message_tag;

typedef struct V_Message *V_PMessage;
typedef struct V_Base {
	struct V_Message _;
	bool (*do_)(struct V_Base *this_, o7c_tag_t this__tag, struct V_Message *mes, o7c_tag_t mes_tag);
} V_Base;
extern o7c_tag_t V_Base_tag;

typedef struct V_Base *V_PBase;
typedef struct V_Error {
	struct V_Base _;
} V_Error;
extern o7c_tag_t V_Error_tag;

typedef struct V_Error *V_PError;
typedef bool (*V_Handle)(struct V_Base *this_, o7c_tag_t this__tag, struct V_Message *mes, o7c_tag_t mes_tag);
typedef struct V_MsgFinalize {
	struct V_Base _;
} V_MsgFinalize;
extern o7c_tag_t V_MsgFinalize_tag;

typedef struct V_MsgNeedMemory {
	struct V_Base _;
} V_MsgNeedMemory;
extern o7c_tag_t V_MsgNeedMemory_tag;

typedef struct V_MsgCopy {
	struct V_Base _;
	struct V_Base *copy;
} V_MsgCopy;
extern o7c_tag_t V_MsgCopy_tag;

typedef struct V_MsgLinks {
	struct V_Base _;
	int diff;
	int count;
} V_MsgLinks;
extern o7c_tag_t V_MsgLinks_tag;

typedef struct V_MsgContentPass {
	struct V_Base _;
	int id;
} V_MsgContentPass;
extern o7c_tag_t V_MsgContentPass_tag;

typedef struct V_MsgHash {
	struct V_Base _;
	int hash;
} V_MsgHash;
extern o7c_tag_t V_MsgHash_tag;


extern void V_Init(struct V_Base *base, o7c_tag_t base_tag);

extern void V_SetDo(struct V_Base *base, o7c_tag_t base_tag, V_Handle do_);

extern bool V_Do(struct V_Base *handler, o7c_tag_t handler_tag, struct V_Message *message, o7c_tag_t message_tag);

extern void V_init(void);
#endif

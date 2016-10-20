#if !defined(HEADER_GUARD_V)
#define HEADER_GUARD_V


#define V_ContentPassOpen_cnst 0
#define V_ContentPassNext_cnst 1
#define V_ContentPassClose_cnst 2

typedef struct V_Message {
	} V_Message;
extern int V_Message_tag[15];

typedef struct V_Message *V_PMessage;
typedef struct V_Base {
	struct V_Message _;
	bool (*do_)(struct V_Base *this_, int *this__tag, struct V_Message *mes, int *mes_tag);
} V_Base;
extern int V_Base_tag[15];

typedef struct V_Base *V_PBase;
typedef struct V_Error {
	struct V_Base _;
} V_Error;
extern int V_Error_tag[15];

typedef struct V_Error *V_PError;
typedef bool (*V_Handle)(struct V_Base *this_, int *this__tag, struct V_Message *mes, int *mes_tag);
typedef struct V_MsgFinalize {
	struct V_Base _;
} V_MsgFinalize;
extern int V_MsgFinalize_tag[15];

typedef struct V_MsgNeedMemory {
	struct V_Base _;
} V_MsgNeedMemory;
extern int V_MsgNeedMemory_tag[15];

typedef struct V_MsgCopy {
	struct V_Base _;
	struct V_Base *copy;
} V_MsgCopy;
extern int V_MsgCopy_tag[15];

typedef struct V_MsgLinks {
	struct V_Base _;
	int diff;
	int count;
} V_MsgLinks;
extern int V_MsgLinks_tag[15];

typedef struct V_MsgContentPass {
	struct V_Base _;
	int id;
} V_MsgContentPass;
extern int V_MsgContentPass_tag[15];

typedef struct V_MsgHash {
	struct V_Base _;
	int hash;
} V_MsgHash;
extern int V_MsgHash_tag[15];


extern void V_Init(struct V_Base *base, int *base_tag);

extern void V_SetDo(struct V_Base *base, int *base_tag, V_Handle do_);

extern bool V_Do(struct V_Base *handler, int *handler_tag, struct V_Message *message, int *message_tag);

extern void V_init_(void);
#endif

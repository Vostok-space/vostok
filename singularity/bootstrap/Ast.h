#if !defined(HEADER_GUARD_Ast)
#define HEADER_GUARD_Ast

#include "Log.h"
#include "Utf8.h"
#include "Limits.h"
#include "V.h"
#include "Scanner.h"
#include "StringStore.h"
#include "TranslatorLimits.h"

#define Ast_ErrNo_cnst 0
#define Ast_ErrImportNameDuplicate_cnst (-1)
#define Ast_ErrDeclarationNameDuplicate_cnst (-2)
#define Ast_ErrReturnInModuleInit_cnst (-3)
#define Ast_ErrMultExprDifferenTypes_cnst (-4)
#define Ast_ErrNotBoolInLogicExpr_cnst (-5)
#define Ast_ErrNotIntInDivOrMod_cnst (-6)
#define Ast_ErrNotRealTypeForRealDiv_cnst (-7)
#define Ast_ErrIntDivByZero_cnst (-8)
#define Ast_ErrNotIntSetElem_cnst (-9)
#define Ast_ErrSetElemOutOfRange_cnst (-10)
#define Ast_ErrSetLeftElemBiggerRightElem_cnst (-11)
#define Ast_ErrAddExprDifferenTypes_cnst (-12)
#define Ast_ErrNotNumberAndNotSetInMul_cnst (-13)
#define Ast_ErrNotNumberAndNotSetInAdd_cnst (-14)
#define Ast_ErrSignForBool_cnst (-15)
#define Ast_ErrNotNumberAndNotSetInMult_cnst (-16)
#define Ast_ErrRelationExprDifferenTypes_cnst (-17)
#define Ast_ErrExprInWrongTypes_cnst (-18)
#define Ast_ErrExprInRightNotSet_cnst (-19)
#define Ast_ErrExprInLeftNotInteger_cnst (-20)
#define Ast_ErrRelIncompatibleType_cnst (-21)
#define Ast_ErrIsExtTypeNotRecord_cnst (-22)
#define Ast_ErrIsExtVarNotRecord_cnst (-23)
#define Ast_ErrConstDeclExprNotConst_cnst (-24)
#define Ast_ErrAssignIncompatibleType_cnst (-25)
#define Ast_ErrCallNotProc_cnst (-26)
#define Ast_ErrCallExprWithoutReturn_cnst (-27)
#define Ast_ErrCallIgnoredReturn_cnst (-28)
#define Ast_ErrCallExcessParam_cnst (-29)
#define Ast_ErrCallIncompatibleParamType_cnst (-30)
#define Ast_ErrCallExpectVarParam_cnst (-31)
#define Ast_ErrCallParamsNotEnough_cnst (-32)
#define Ast_ErrCaseExprNotIntOrChar_cnst (-33)
#define Ast_ErrCaseElemExprTypeMismatch_cnst (-34)
#define Ast_ErrCaseElemExprNotConst_cnst (-35)
#define Ast_ErrCaseElemDuplicate_cnst (-36)
#define Ast_ErrCaseRangeLabelsTypeMismatch_cnst (-37)
#define Ast_ErrCaseLabelLeftGreaterRight_cnst (-38)
#define Ast_ErrCaseLabelNotConst_cnst (-39)
#define Ast_ErrProcHasNoReturn_cnst (-40)
#define Ast_ErrReturnIncompatibleType_cnst (-41)
#define Ast_ErrExpectReturn_cnst (-42)
#define Ast_ErrDeclarationNotFound_cnst (-43)
#define Ast_ErrConstRecursive_cnst (-44)
#define Ast_ErrImportModuleNotFound_cnst (-45)
#define Ast_ErrImportModuleWithError_cnst (-46)
#define Ast_ErrNotImplemented_cnst (-49)
#define Ast_ErrMin_cnst (-50)
#define Ast_NoId_cnst (-1)
#define Ast_IdInteger_cnst 0
#define Ast_IdBoolean_cnst 1
#define Ast_IdByte_cnst 2
#define Ast_IdChar_cnst 3
#define Ast_IdReal_cnst 4
#define Ast_IdSet_cnst 5
#define Ast_IdPointer_cnst 6
#define Ast_PredefinedTypesCount_cnst 7
#define Ast_IdArray_cnst 7
#define Ast_IdRecord_cnst 8
#define Ast_IdRecordForward_cnst 9
#define Ast_IdProcType_cnst 10
#define Ast_IdNamed_cnst 11
#define Ast_IdString_cnst 12
#define Ast_IdDesignator_cnst 20
#define Ast_IdRelation_cnst 21
#define Ast_IdSum_cnst 22
#define Ast_IdTerm_cnst 23
#define Ast_IdNegate_cnst 24
#define Ast_IdCall_cnst 25
#define Ast_IdBraces_cnst 26
#define Ast_IdIsExtension_cnst 27
#define Ast_IdImport_cnst 32
#define Ast_IdConst_cnst 33
#define Ast_IdVar_cnst 34
#define Ast_IdError_cnst 35

typedef struct Ast_RModule *Ast_Module;
typedef struct Ast_RProvider *Ast_Provider;
typedef struct Ast_RModule *(*Ast_Provide)(struct Ast_RProvider *p, o7c_tag_t p_tag, struct Ast_RModule *host, o7c_tag_t host_tag, char unsigned name[/*len0*/], int name_len0, int ofs, int end);
typedef struct Ast_RProvider {
	struct V_Base _;
	Ast_Provide get;
} Ast_RProvider;
extern o7c_tag_t Ast_RProvider_tag;
typedef struct Ast_Node {
	struct V_Base _;
	int id;
	struct V_Base *ext;
} Ast_Node;
extern o7c_tag_t Ast_Node_tag;
typedef struct Ast_Error_s {
	struct Ast_Node _;
	int code;
	int line;
	int column;
	int tabs;
	int bytes;
	struct Ast_Error_s *next;
} *Ast_Error;
extern o7c_tag_t Ast_Error_s_tag;
typedef struct Ast_RType *Ast_Type;
typedef struct Ast_RDeclaration *Ast_Declaration;
typedef struct Ast_RDeclarations *Ast_Declarations;
typedef struct Ast_RDeclaration {
	struct Ast_Node _;
	struct Ast_RModule *module;
	struct Ast_RDeclarations *up;
	struct StringStore_String name;
	bool mark;
	struct Ast_RType *type;
	struct Ast_RDeclaration *next;
} Ast_RDeclaration;
extern o7c_tag_t Ast_RDeclaration_tag;
typedef struct Ast_RArray *Ast_Array;
typedef struct Ast_RType {
	struct Ast_RDeclaration _;
	struct Ast_RArray *array_;
} Ast_RType;
extern o7c_tag_t Ast_RType_tag;
typedef struct Ast_Byte_s {
	struct Ast_RType _;
} *Ast_Byte;
extern o7c_tag_t Ast_Byte_s_tag;
typedef struct Ast_RExpression *Ast_Expression;
typedef struct Ast_Const_s {
	struct Ast_RDeclaration _;
	struct Ast_RExpression *expr;
	bool finished;
} *Ast_Const;
extern o7c_tag_t Ast_Const_s_tag;
typedef struct Ast_RConstruct *Ast_Construct;
typedef struct Ast_RConstruct {
	struct Ast_RType _;
} Ast_RConstruct;
extern o7c_tag_t Ast_RConstruct_tag;
typedef struct Ast_RArray {
	struct Ast_RConstruct _;
	struct Ast_RExpression *count;
} Ast_RArray;
extern o7c_tag_t Ast_RArray_tag;
typedef struct Ast_RPointer *Ast_Pointer;
typedef struct Ast_Record_s {
	struct Ast_RConstruct _;
	struct Ast_Record_s *base;
	struct Ast_RDeclarations *vars;
	struct Ast_RPointer *pointer;
} *Ast_Record;
extern o7c_tag_t Ast_Record_s_tag;
typedef struct Ast_RPointer {
	struct Ast_RConstruct _;
} Ast_RPointer;
extern o7c_tag_t Ast_RPointer_tag;
typedef struct Ast_RVar *Ast_Var;
typedef struct Ast_RVar {
	struct Ast_RDeclaration _;
} Ast_RVar;
extern o7c_tag_t Ast_RVar_tag;
typedef struct Ast_FormalParam_s {
	struct Ast_RVar _;
	bool isVar;
} *Ast_FormalParam;
extern o7c_tag_t Ast_FormalParam_s_tag;
typedef struct Ast_ProcType_s {
	struct Ast_RConstruct _;
	struct Ast_FormalParam_s *params;
	struct Ast_FormalParam_s *end;
} *Ast_ProcType;
extern o7c_tag_t Ast_ProcType_s_tag;
typedef struct Ast_RStatement *Ast_Statement;
typedef struct Ast_RProcedure *Ast_Procedure;
typedef struct Ast_RDeclarations {
	struct Ast_RDeclaration _;
	struct Ast_RDeclaration *start;
	struct Ast_RDeclaration *end;
	struct Ast_Const_s *consts;
	struct Ast_RType *types;
	struct Ast_RVar *vars;
	struct Ast_RProcedure *procedures;
	struct Ast_Record_s *recordsForward;
	struct Ast_RStatement *stats;
} Ast_RDeclarations;
extern o7c_tag_t Ast_RDeclarations_tag;
typedef struct Ast_Import_s {
	struct Ast_RDeclaration _;
} *Ast_Import;
extern o7c_tag_t Ast_Import_s_tag;
typedef struct Ast_RModule {
	struct Ast_RDeclarations _;
	struct StringStore_Store store;
	struct Ast_Import_s *import_;
	struct Ast_Error_s *errors;
	struct Ast_Error_s *errLast;
} Ast_RModule;
extern o7c_tag_t Ast_RModule_tag;
typedef struct Ast_RGeneralProcedure *Ast_GeneralProcedure;
typedef struct Ast_RGeneralProcedure {
	struct Ast_RDeclarations _;
	struct Ast_ProcType_s *header;
	struct Ast_RExpression *return_;
} Ast_RGeneralProcedure;
extern o7c_tag_t Ast_RGeneralProcedure_tag;
typedef struct Ast_RProcedure {
	struct Ast_RGeneralProcedure _;
	int distance;
} Ast_RProcedure;
extern o7c_tag_t Ast_RProcedure_tag;
typedef struct Ast_PredefinedProcedure_s {
	struct Ast_RGeneralProcedure _;
} *Ast_PredefinedProcedure;
extern o7c_tag_t Ast_PredefinedProcedure_s_tag;
typedef struct Ast_RFactor *Ast_Factor;
typedef struct Ast_RExpression {
	struct Ast_Node _;
	struct Ast_RType *type;
	struct Ast_RFactor *value_;
} Ast_RExpression;
extern o7c_tag_t Ast_RExpression_tag;
typedef struct Ast_RSelector *Ast_Selector;
typedef struct Ast_RSelector {
	struct Ast_Node _;
	struct Ast_RSelector *next;
} Ast_RSelector;
extern o7c_tag_t Ast_RSelector_tag;
typedef struct Ast_SelPointer_s {
	struct Ast_RSelector _;
} *Ast_SelPointer;
extern o7c_tag_t Ast_SelPointer_s_tag;
typedef struct Ast_SelGuard_s {
	struct Ast_RSelector _;
	struct Ast_RType *type;
} *Ast_SelGuard;
extern o7c_tag_t Ast_SelGuard_s_tag;
typedef struct Ast_SelArray_s {
	struct Ast_RSelector _;
	struct Ast_RExpression *index;
} *Ast_SelArray;
extern o7c_tag_t Ast_SelArray_s_tag;
typedef struct Ast_SelRecord_s {
	struct Ast_RSelector _;
	struct Ast_RVar *var_;
} *Ast_SelRecord;
extern o7c_tag_t Ast_SelRecord_s_tag;
typedef struct Ast_RFactor {
	struct Ast_RExpression _;
} Ast_RFactor;
extern o7c_tag_t Ast_RFactor_tag;
typedef struct Ast_Designator_s {
	struct Ast_RFactor _;
	struct Ast_RDeclaration *decl;
	struct Ast_RSelector *sel;
} *Ast_Designator;
extern o7c_tag_t Ast_Designator_s_tag;
typedef struct Ast_ExprNumber {
	struct Ast_RFactor _;
} Ast_ExprNumber;
extern o7c_tag_t Ast_ExprNumber_tag;
typedef struct Ast_RExprInteger {
	struct Ast_ExprNumber _;
	int int_;
} Ast_RExprInteger;
extern o7c_tag_t Ast_RExprInteger_tag;
typedef struct Ast_RExprInteger *Ast_ExprInteger;
typedef struct Ast_ExprReal_s {
	struct Ast_ExprNumber _;
	double real;
	struct StringStore_String str;
} *Ast_ExprReal;
extern o7c_tag_t Ast_ExprReal_s_tag;
typedef struct Ast_ExprBoolean_s {
	struct Ast_RFactor _;
	bool bool_;
} *Ast_ExprBoolean;
extern o7c_tag_t Ast_ExprBoolean_s_tag;
typedef struct Ast_ExprString_s {
	struct Ast_RExprInteger _;
	struct StringStore_String string;
	bool asChar;
} *Ast_ExprString;
extern o7c_tag_t Ast_ExprString_s_tag;
typedef struct Ast_ExprNil_s {
	struct Ast_RFactor _;
} *Ast_ExprNil;
extern o7c_tag_t Ast_ExprNil_s_tag;
typedef struct Ast_ExprSet_s {
	struct Ast_RFactor _;
	int set;
	struct Ast_RExpression *exprs[2];
	struct Ast_ExprSet_s *next;
} *Ast_ExprSet;
extern o7c_tag_t Ast_ExprSet_s_tag;
typedef struct Ast_ExprNegate_s {
	struct Ast_RFactor _;
	struct Ast_RExpression *expr;
} *Ast_ExprNegate;
extern o7c_tag_t Ast_ExprNegate_s_tag;
typedef struct Ast_ExprBraces_s {
	struct Ast_RFactor _;
	struct Ast_RExpression *expr;
} *Ast_ExprBraces;
extern o7c_tag_t Ast_ExprBraces_s_tag;
typedef struct Ast_ExprRelation_s {
	struct Ast_RExpression _;
	int relation;
	int distance;
	struct Ast_RExpression *exprs[2];
} *Ast_ExprRelation;
extern o7c_tag_t Ast_ExprRelation_s_tag;
typedef struct Ast_ExprIsExtension_s {
	struct Ast_RExpression _;
	struct Ast_Designator_s *designator;
	struct Ast_RType *extType;
} *Ast_ExprIsExtension;
extern o7c_tag_t Ast_ExprIsExtension_s_tag;
typedef struct Ast_ExprSum_s {
	struct Ast_RExpression _;
	int add;
	struct Ast_RExpression *term;
	struct Ast_ExprSum_s *next;
} *Ast_ExprSum;
extern o7c_tag_t Ast_ExprSum_s_tag;
typedef struct Ast_ExprTerm_s {
	struct Ast_RExpression _;
	struct Ast_RFactor *factor;
	int mult;
	struct Ast_RExpression *expr;
} *Ast_ExprTerm;
extern o7c_tag_t Ast_ExprTerm_s_tag;
typedef struct Ast_Parameter_s {
	struct Ast_Node _;
	struct Ast_RExpression *expr;
	struct Ast_Parameter_s *next;
	int distance;
} *Ast_Parameter;
extern o7c_tag_t Ast_Parameter_s_tag;
typedef struct Ast_ExprCall_s {
	struct Ast_RFactor _;
	struct Ast_Designator_s *designator;
	struct Ast_Parameter_s *params;
} *Ast_ExprCall;
extern o7c_tag_t Ast_ExprCall_s_tag;
typedef struct Ast_RStatement {
	struct Ast_Node _;
	struct Ast_RExpression *expr;
	struct Ast_RStatement *next;
} Ast_RStatement;
extern o7c_tag_t Ast_RStatement_tag;
typedef struct Ast_RWhileIf *Ast_WhileIf;
typedef struct Ast_RWhileIf {
	struct Ast_RStatement _;
	struct Ast_RStatement *stats;
	struct Ast_RWhileIf *elsif;
} Ast_RWhileIf;
extern o7c_tag_t Ast_RWhileIf_tag;
typedef struct Ast_If_s {
	struct Ast_RWhileIf _;
} *Ast_If;
extern o7c_tag_t Ast_If_s_tag;
typedef struct Ast_CaseLabel_s {
	struct Ast_Node _;
	int value_;
	struct Ast_RDeclaration *qual;
} *Ast_CaseLabel;
extern o7c_tag_t Ast_CaseLabel_s_tag;
typedef struct Ast_CaseLabelRange_s {
	struct Ast_Node _;
	struct Ast_CaseLabel_s *left;
	struct Ast_CaseLabel_s *right;
	struct Ast_CaseLabelRange_s *next;
} *Ast_CaseLabelRange;
extern o7c_tag_t Ast_CaseLabelRange_s_tag;
typedef struct Ast_CaseElement_s {
	struct Ast_Node _;
	struct Ast_CaseLabelRange_s *range;
	struct Ast_RStatement *stats;
	struct Ast_CaseElement_s *next;
} *Ast_CaseElement;
extern o7c_tag_t Ast_CaseElement_s_tag;
typedef struct Ast_Case_s {
	struct Ast_RStatement _;
	struct Ast_CaseElement_s *elements;
} *Ast_Case;
extern o7c_tag_t Ast_Case_s_tag;
typedef struct Ast_Repeat_s {
	struct Ast_RStatement _;
	struct Ast_RStatement *stats;
} *Ast_Repeat;
extern o7c_tag_t Ast_Repeat_s_tag;
typedef struct Ast_For_s {
	struct Ast_RStatement _;
	struct Ast_RExpression *to;
	struct Ast_RVar *var_;
	int by;
	struct Ast_RStatement *stats;
} *Ast_For;
extern o7c_tag_t Ast_For_s_tag;
typedef struct Ast_While_s {
	struct Ast_RWhileIf _;
} *Ast_While;
extern o7c_tag_t Ast_While_s_tag;
typedef struct Ast_Assign_s {
	struct Ast_RStatement _;
	struct Ast_Designator_s *designator;
	int distance;
} *Ast_Assign;
extern o7c_tag_t Ast_Assign_s_tag;
typedef struct Ast_Call_s {
	struct Ast_RStatement _;
} *Ast_Call;
extern o7c_tag_t Ast_Call_s_tag;
typedef struct Ast_StatementError_s {
	struct Ast_RStatement _;
} *Ast_StatementError;
extern o7c_tag_t Ast_StatementError_s_tag;

extern void Ast_PutChars(struct Ast_RModule *m, o7c_tag_t m_tag, struct StringStore_String *w, o7c_tag_t w_tag, char unsigned s[/*len0*/], int s_len0, int begin, int end);

extern struct Ast_RModule *Ast_ModuleNew(char unsigned name[/*len0*/], int name_len0, int begin, int end);

extern struct Ast_RModule *Ast_GetModuleByName(struct Ast_RProvider *p, o7c_tag_t p_tag, struct Ast_RModule *host, o7c_tag_t host_tag, char unsigned name[/*len0*/], int name_len0, int ofs, int end);

extern int Ast_ImportAdd(struct Ast_RModule *m, o7c_tag_t m_tag, char unsigned buf[/*len0*/], int buf_len0, int nameOfs, int nameEnd, int realOfs, int realEnd, struct Ast_RProvider *p, o7c_tag_t p_tag);

extern int Ast_ConstAdd(struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, char unsigned buf[/*len0*/], int buf_len0, int begin, int end);

extern int Ast_ConstSetExpression(struct Ast_Const_s *const_, o7c_tag_t const__tag, struct Ast_RExpression *expr, o7c_tag_t expr_tag);

extern int Ast_TypeAdd(struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, char unsigned buf[/*len0*/], int buf_len0, int begin, int end, struct Ast_RType **td, o7c_tag_t td_tag);

extern int Ast_VarAdd(struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, char unsigned buf[/*len0*/], int buf_len0, int begin, int end);

extern struct Ast_ProcType_s *Ast_ProcTypeNew(void);

extern int Ast_ParamAdd(struct Ast_RModule *module, o7c_tag_t module_tag, struct Ast_ProcType_s *proc, o7c_tag_t proc_tag, char unsigned buf[/*len0*/], int buf_len0, int begin, int end);

extern void Ast_AddError(struct Ast_RModule *m, o7c_tag_t m_tag, int error, int line, int column, int tabs);

extern struct Ast_RType *Ast_TypeGet(int id);

extern struct Ast_RArray *Ast_ArrayGet(struct Ast_RType *t, o7c_tag_t t_tag, struct Ast_RExpression *count, o7c_tag_t count_tag);

extern struct Ast_RPointer *Ast_PointerGet(struct Ast_Record_s *t, o7c_tag_t t_tag);

extern void Ast_RecordSetBase(struct Ast_Record_s *r, o7c_tag_t r_tag, struct Ast_Record_s *base, o7c_tag_t base_tag);

extern struct Ast_Record_s *Ast_RecordNew(struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, struct Ast_Record_s *base, o7c_tag_t base_tag);

extern struct Ast_RDeclaration *Ast_DeclarationSearch(struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, char unsigned buf[/*len0*/], int buf_len0, int begin, int end);

extern int Ast_DeclarationGet(struct Ast_RDeclaration **d, o7c_tag_t d_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, char unsigned buf[/*len0*/], int buf_len0, int begin, int end);

extern struct Ast_RExprInteger *Ast_ExprIntegerNew(int int_);

extern struct Ast_ExprReal_s *Ast_ExprRealNew(double real, struct Ast_RModule *m, o7c_tag_t m_tag, char unsigned buf[/*len0*/], int buf_len0, int begin, int end);

extern struct Ast_ExprReal_s *Ast_ExprRealNewByValue(double real);

extern struct Ast_ExprBoolean_s *Ast_ExprBooleanNew(bool bool_);

extern struct Ast_ExprString_s *Ast_ExprStringNew(struct Ast_RModule *m, o7c_tag_t m_tag, char unsigned buf[/*len0*/], int buf_len0, int begin, int end);

extern struct Ast_ExprString_s *Ast_ExprCharNew(int int_);

extern struct Ast_ExprNil_s *Ast_ExprNilNew(void);

extern struct Ast_ExprBraces_s *Ast_ExprBracesNew(struct Ast_RExpression *expr, o7c_tag_t expr_tag);

extern struct Ast_ExprSet_s *Ast_ExprSetByValue(int set);

extern int Ast_ExprSetNew(struct Ast_ExprSet_s **e, o7c_tag_t e_tag, struct Ast_RExpression *expr1, o7c_tag_t expr1_tag, struct Ast_RExpression *expr2, o7c_tag_t expr2_tag);

extern struct Ast_ExprNegate_s *Ast_ExprNegateNew(struct Ast_RExpression *expr, o7c_tag_t expr_tag);

extern struct Ast_Designator_s *Ast_DesignatorNew(struct Ast_RDeclaration *decl, o7c_tag_t decl_tag);

extern struct Ast_SelPointer_s *Ast_SelPointerNew(void);

extern struct Ast_SelArray_s *Ast_SelArrayNew(struct Ast_RExpression *index, o7c_tag_t index_tag);

extern struct Ast_SelRecord_s *Ast_SelRecordNew(struct Ast_RVar *var_, o7c_tag_t var__tag);

extern struct Ast_SelGuard_s *Ast_SelGuardNew(struct Ast_RType *t, o7c_tag_t t_tag);

extern bool Ast_IsRecordExtension(int *distance, struct Ast_Record_s *t0, o7c_tag_t t0_tag, struct Ast_Record_s *t1, o7c_tag_t t1_tag);

extern bool Ast_CompatibleTypes(int *distance, struct Ast_RType *t1, o7c_tag_t t1_tag, struct Ast_RType *t2, o7c_tag_t t2_tag);

extern int Ast_ExprIsExtensionNew(struct Ast_ExprIsExtension_s **e, o7c_tag_t e_tag, struct Ast_RExpression **des, o7c_tag_t des_tag, struct Ast_RType *type, o7c_tag_t type_tag);

extern int Ast_ExprRelationNew(struct Ast_ExprRelation_s **e, o7c_tag_t e_tag, struct Ast_RExpression *expr1, o7c_tag_t expr1_tag, int relation, struct Ast_RExpression *expr2, o7c_tag_t expr2_tag);

extern int Ast_ExprSumNew(struct Ast_ExprSum_s **e, o7c_tag_t e_tag, int add, struct Ast_RExpression *term, o7c_tag_t term_tag);

extern int Ast_ExprSumAdd(struct Ast_RExpression *fullSum, o7c_tag_t fullSum_tag, struct Ast_ExprSum_s **lastAdder, o7c_tag_t lastAdder_tag, int add, struct Ast_RExpression *term, o7c_tag_t term_tag);

extern int Ast_ExprTermNew(struct Ast_ExprTerm_s **e, o7c_tag_t e_tag, struct Ast_RFactor *factor, o7c_tag_t factor_tag, int mult, struct Ast_RExpression *factorOrTerm, o7c_tag_t factorOrTerm_tag);

extern int Ast_ExprTermAdd(struct Ast_RExpression *fullTerm, o7c_tag_t fullTerm_tag, struct Ast_ExprTerm_s **lastTerm, o7c_tag_t lastTerm_tag, int mult, struct Ast_RExpression *factorOrTerm, o7c_tag_t factorOrTerm_tag);

extern int Ast_ExprCallNew(struct Ast_ExprCall_s **e, o7c_tag_t e_tag, struct Ast_Designator_s *des, o7c_tag_t des_tag);

extern bool Ast_IsChangeable(struct Ast_RModule *cur, o7c_tag_t cur_tag, struct Ast_RVar *v, o7c_tag_t v_tag);

extern bool Ast_IsVar(struct Ast_RExpression *e, o7c_tag_t e_tag);

extern int Ast_ProcedureAdd(struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, struct Ast_RProcedure **p, o7c_tag_t p_tag, char unsigned buf[/*len0*/], int buf_len0, int begin, int end);

extern int Ast_ProcedureSetReturn(struct Ast_RProcedure *p, o7c_tag_t p_tag, struct Ast_RExpression *e, o7c_tag_t e_tag);

extern int Ast_ProcedureEnd(struct Ast_RProcedure *p, o7c_tag_t p_tag);

extern int Ast_CallParamNew(struct Ast_ExprCall_s *call, o7c_tag_t call_tag, struct Ast_Parameter_s **lastParam, o7c_tag_t lastParam_tag, struct Ast_RExpression *e, o7c_tag_t e_tag, struct Ast_FormalParam_s **currentFormalParam, o7c_tag_t currentFormalParam_tag);

extern int Ast_CallParamsEnd(struct Ast_ExprCall_s *call, o7c_tag_t call_tag, struct Ast_FormalParam_s *currentFormalParam, o7c_tag_t currentFormalParam_tag);

extern int Ast_CallNew(struct Ast_Call_s **c, o7c_tag_t c_tag, struct Ast_Designator_s *des, o7c_tag_t des_tag);

extern struct Ast_If_s *Ast_IfNew(struct Ast_RExpression *expr, o7c_tag_t expr_tag, struct Ast_RStatement *stats, o7c_tag_t stats_tag);

extern struct Ast_While_s *Ast_WhileNew(struct Ast_RExpression *expr, o7c_tag_t expr_tag, struct Ast_RStatement *stats, o7c_tag_t stats_tag);

extern struct Ast_Repeat_s *Ast_RepeatNew(struct Ast_RExpression *expr, o7c_tag_t expr_tag, struct Ast_RStatement *stats, o7c_tag_t stats_tag);

extern struct Ast_For_s *Ast_ForNew(struct Ast_RVar *var_, o7c_tag_t var__tag, struct Ast_RExpression *init, o7c_tag_t init_tag, struct Ast_RExpression *to, o7c_tag_t to_tag, int by, struct Ast_RStatement *stats, o7c_tag_t stats_tag);

extern int Ast_CaseNew(struct Ast_Case_s **case_, o7c_tag_t case__tag, struct Ast_RExpression *expr, o7c_tag_t expr_tag);

extern int Ast_CaseLabelNew(struct Ast_CaseLabel_s **label, o7c_tag_t label_tag, int id, int value_);

extern int Ast_CaseLabelQualNew(struct Ast_CaseLabel_s **label, o7c_tag_t label_tag, struct Ast_RDeclaration *decl, o7c_tag_t decl_tag);

extern int Ast_CaseRangeNew(struct Ast_CaseLabelRange_s **range, o7c_tag_t range_tag, struct Ast_CaseLabel_s *label1, o7c_tag_t label1_tag, struct Ast_CaseLabel_s *label2, o7c_tag_t label2_tag);

extern int Ast_CaseRangeListAdd(struct Ast_Case_s *case_, o7c_tag_t case__tag, struct Ast_CaseLabelRange_s *first, o7c_tag_t first_tag, struct Ast_CaseLabelRange_s *new_, o7c_tag_t new__tag);

extern struct Ast_CaseElement_s *Ast_CaseElementNew(void);

extern int Ast_CaseElementAdd(struct Ast_Case_s *case_, o7c_tag_t case__tag, struct Ast_CaseElement_s *elem, o7c_tag_t elem_tag);

extern int Ast_AssignNew(struct Ast_Assign_s **a, o7c_tag_t a_tag, struct Ast_Designator_s *des, o7c_tag_t des_tag, struct Ast_RExpression *expr, o7c_tag_t expr_tag);

extern struct Ast_StatementError_s *Ast_StatementErrorNew(void);

extern bool Ast_HasError(struct Ast_RModule *m, o7c_tag_t m_tag);

extern void Ast_ProviderInit(struct Ast_RProvider *p, o7c_tag_t p_tag, Ast_Provide get);

extern void Ast_init_(void);
#endif

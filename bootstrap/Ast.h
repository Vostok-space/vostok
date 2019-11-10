#if !defined HEADER_GUARD_Ast
#    define  HEADER_GUARD_Ast 1

#include "Log.h"
#include "Out.h"
#include "Utf8.h"
#include "TypesLimits.h"
#include "V.h"
#include "Scanner.h"
#include "OberonSpecIdent.h"
#include "StringStore.h"
#include "Chars0X.h"
#include "TranslatorLimits.h"
#include "CheckIntArithmetic.h"
#include "LongSet.h"

#define Ast_ErrNo_cnst 0
#define Ast_ErrImportNameDuplicate_cnst (-1)
#define Ast_ErrImportSelf_cnst (-2)
#define Ast_ErrImportLoop_cnst (-3)
#define Ast_ErrDeclarationNameDuplicate_cnst (-4)
#define Ast_ErrDeclarationNameHide_cnst (-5)
#define Ast_ErrPredefinedNameHide_cnst (-6)
#define Ast_ErrMultExprDifferentTypes_cnst (-7)
#define Ast_ErrDivExprDifferentTypes_cnst (-8)
#define Ast_ErrNotBoolInLogicExpr_cnst (-9)
#define Ast_ErrNotIntInDivOrMod_cnst (-10)
#define Ast_ErrNotRealTypeForRealDiv_cnst (-11)
#define Ast_ErrNotIntSetElem_cnst (-12)
#define Ast_ErrSetElemOutOfRange_cnst (-13)
#define Ast_ErrSetLeftElemBiggerRightElem_cnst (-14)
#define Ast_ErrSetElemMaxNotConvertToInt_cnst (-15)
#define Ast_ErrAddExprDifferenTypes_cnst (-16)
#define Ast_ErrNotNumberAndNotSetInMult_cnst (-17)
#define Ast_ErrNotNumberAndNotSetInAdd_cnst (-18)
#define Ast_ErrSignForBool_cnst (-19)
#define Ast_ErrRelationExprDifferenTypes_cnst (-20)
#define Ast_ErrExprInWrongTypes_cnst (-21)
#define Ast_ErrExprInRightNotSet_cnst (-22)
#define Ast_ErrExprInLeftNotInteger_cnst (-23)
#define Ast_ErrRelIncompatibleType_cnst (-24)
#define Ast_ErrIsExtTypeNotRecord_cnst (-25)
#define Ast_ErrIsExtVarNotRecord_cnst (-26)
#define Ast_ErrIsExtMeshupPtrAndRecord_cnst (-27)
#define Ast_ErrIsExtExpectRecordExt_cnst (-28)
#define Ast_ErrConstDeclExprNotConst_cnst (-29)
#define Ast_ErrAssignIncompatibleType_cnst (-30)
#define Ast_ErrAssignExpectVarParam_cnst (-31)
#define Ast_ErrAssignStringToNotEnoughArray_cnst (-111)
#define Ast_ErrCallNotProc_cnst (-32)
#define Ast_ErrCallExprWithoutReturn_cnst (-33)
#define Ast_ErrCallIgnoredReturn_cnst (-34)
#define Ast_ErrCallExcessParam_cnst (-35)
#define Ast_ErrCallIncompatibleParamType_cnst (-36)
#define Ast_ErrCallExpectVarParam_cnst (-37)
#define Ast_ErrCallParamsNotEnough_cnst (-38)
#define Ast_ErrCallVarPointerTypeNotSame_cnst (-39)
#define Ast_ErrCaseExprNotIntOrChar_cnst (-40)
#define Ast_ErrCaseLabelNotIntOrChar_cnst (-41)
#define Ast_ErrCaseElemExprTypeMismatch_cnst (-42)
#define Ast_ErrCaseElemDuplicate_cnst (-43)
#define Ast_ErrCaseRangeLabelsTypeMismatch_cnst (-44)
#define Ast_ErrCaseLabelLeftNotLessRight_cnst (-45)
#define Ast_ErrCaseLabelNotConst_cnst (-46)
#define Ast_ErrCaseElseAlreadyExist_cnst (-47)
#define Ast_ErrProcHasNoReturn_cnst (-48)
#define Ast_ErrReturnIncompatibleType_cnst (-49)
#define Ast_ErrExpectReturn_cnst (-50)
#define Ast_ErrDeclarationNotFound_cnst (-51)
#define Ast_ErrDeclarationIsPrivate_cnst (-52)
#define Ast_ErrConstRecursive_cnst (-53)
#define Ast_ErrImportModuleNotFound_cnst (-54)
#define Ast_ErrImportModuleWithError_cnst (-55)
#define Ast_ErrDerefToNotPointer_cnst (-56)
#define Ast_ErrArrayLenLess1_cnst (-57)
#define Ast_ErrArrayLenTooBig_cnst (-58)
#define Ast_ErrArrayItemToNotArray_cnst (-59)
#define Ast_ErrArrayIndexNotInt_cnst (-60)
#define Ast_ErrArrayIndexNegative_cnst (-61)
#define Ast_ErrArrayIndexOutOfRange_cnst (-62)
#define Ast_ErrGuardExpectRecordExt_cnst (-63)
#define Ast_ErrGuardExpectPointerExt_cnst (-64)
#define Ast_ErrGuardedTypeNotExtensible_cnst (-65)
#define Ast_ErrDotSelectorToNotRecord_cnst (-66)
#define Ast_ErrDeclarationNotVar_cnst (-67)
#define Ast_ErrForIteratorNotInteger_cnst (-68)
#define Ast_ErrNotBoolInIfCondition_cnst (-69)
#define Ast_ErrNotBoolInWhileCondition_cnst (-70)
#define Ast_ErrWhileConditionAlwaysFalse_cnst (-71)
#define Ast_ErrWhileConditionAlwaysTrue_cnst (-72)
#define Ast_ErrNotBoolInUntil_cnst (-73)
#define Ast_ErrUntilAlwaysFalse_cnst (-74)
#define Ast_ErrUntilAlwaysTrue_cnst (-75)
#define Ast_ErrNegateNotBool_cnst (-76)
#define Ast_ErrConstAddOverflow_cnst (-77)
#define Ast_ErrConstSubOverflow_cnst (-78)
#define Ast_ErrConstMultOverflow_cnst (-79)
#define Ast_ErrComDivByZero_cnst (-80)
#define Ast_ErrNegativeDivisor_cnst (-81)

#define Ast_ErrValueOutOfRangeOfByte_cnst (-82)
#define Ast_ErrValueOutOfRangeOfChar_cnst (-83)

#define Ast_ErrExpectIntExpr_cnst (-84)
#define Ast_ErrExpectConstIntExpr_cnst (-85)
#define Ast_ErrForByZero_cnst (-86)
#define Ast_ErrByShouldBePositive_cnst (-87)
#define Ast_ErrByShouldBeNegative_cnst (-88)
#define Ast_ErrForPossibleOverflow_cnst (-89)

#define Ast_ErrVarUninitialized_cnst (-90)
#define Ast_ErrVarMayUninitialized_cnst (-91)

#define Ast_ErrDeclarationNotProc_cnst (-92)
#define Ast_ErrProcNotCommandHaveReturn_cnst (-93)
#define Ast_ErrProcNotCommandHaveParams_cnst (-94)

#define Ast_ErrReturnTypeArrayOrRecord_cnst (-95)
#define Ast_ErrRecordForwardUndefined_cnst (-96)
#define Ast_ErrPointerToNotRecord_cnst (-97)
#define Ast_ErrVarOfRecordForward_cnst (-98)
#define Ast_ErrVarOfPointerToRecordForward_cnst (-99)
#define Ast_ErrArrayTypeOfRecordForward_cnst (-100)
#define Ast_ErrArrayTypeOfPointerToRecordForward_cnst (-101)
#define Ast_ErrAssertConstFalse_cnst (-102)
#define Ast_ErrDeclarationUnused_cnst (-103)
#define Ast_ErrProcNestedTooDeep_cnst (-104)

#define Ast_ErrExpectProcNameWithoutParams_cnst (-105)

#define Ast_ErrMin_cnst (-200)

#define Ast_ParamIn_cnst 0
#define Ast_ParamOut_cnst 1

#define Ast_NoId_cnst (-1)
#define Ast_IdInteger_cnst 0
#define Ast_IdLongInt_cnst 1
#define Ast_IdBoolean_cnst 2
#define Ast_IdByte_cnst 3
#define Ast_IdChar_cnst 4
#define Ast_IdReal_cnst 5
#define Ast_IdReal32_cnst 6
#define Ast_IdSet_cnst 7
#define Ast_IdLongSet_cnst 8
#define Ast_IdPointer_cnst 9
#define Ast_PredefinedTypesCount_cnst 10

#define Ast_IdArray_cnst 10
#define Ast_IdRecord_cnst 11
#define Ast_IdRecordForward_cnst 12
#define Ast_IdProcType_cnst 13
#define Ast_IdNamed_cnst 14
#define Ast_IdString_cnst 15

#define Ast_IdDesignator_cnst 20
#define Ast_IdRelation_cnst 21
#define Ast_IdSum_cnst 22
#define Ast_IdTerm_cnst 23
#define Ast_IdNegate_cnst 24
#define Ast_IdCall_cnst 25
#define Ast_IdBraces_cnst 26
#define Ast_IdIsExtension_cnst 27

#define Ast_IdError_cnst 31

#define Ast_IdImport_cnst 32
#define Ast_IdConst_cnst 33
#define Ast_IdVar_cnst 34
#define Ast_IdProc_cnst 35

#define Ast_InitedNo_cnst 0
#define Ast_InitedNil_cnst 1
#define Ast_InitedValue_cnst 2
#define Ast_InitedFail_cnst 3
#define Ast_InitedCheck_cnst 4
#define Ast_Used_cnst 5
#define Ast_Dereferenced_cnst 6

#define Ast_Integers_cnst 0xBu
#define Ast_Reals_cnst 0x60u
#define Ast_Numbers_cnst 0x6Bu
#define Ast_Sets_cnst 0x180u
/* в RExpression.properties для учёта того, что сравнение с NIL не может
	   быть константным в clang */
#define Ast_ExprPointerTouch_cnst 0
/* в RExpression.properties для учёта того, что в вычислении константного
	   выражения присутствовало отрицательное делимое */
#define Ast_ExprIntNegativeDividentTouch_cnst 1
/* в RType для индикации того, что переменная этого типа была присвоена,
	   что важно при подсчёте ссылок */
#define Ast_TypeAssigned_cnst 0

#define Ast_Plus_cnst 1
#define Ast_Minus_cnst 2
#define Ast_Or_cnst 3
#define Ast_NoSign_cnst 0

typedef struct Ast_RModule *Ast_Module;
typedef struct Ast_ModuleBag__s {
	struct Ast_RModule *m;
} *Ast_ModuleBag;
#define Ast_ModuleBag__s_tag o7_base_tag

extern void Ast_ModuleBag__s_undef(struct Ast_ModuleBag__s *r);

typedef struct Ast_RProvider *Ast_Provider;

typedef struct Ast_RModule *(*Ast_Provide)(struct Ast_RProvider *p, struct Ast_RModule *host, o7_int_t name_len0, o7_char name[/*len0*/], o7_int_t ofs, o7_int_t end);

typedef o7_bool (*Ast_Register)(struct Ast_RProvider *p, struct Ast_RModule *m);

typedef struct Ast_RProvider {
	V_Base _;
	Ast_Provide get;
	Ast_Register reg;
} Ast_RProvider;
#define Ast_RProvider_tag V_Base_tag

extern void Ast_RProvider_undef(struct Ast_RProvider *r);

typedef struct Ast_Node {
	V_Base _;
	o7_int_t id;
	struct StringStore_String comment;
	o7_int_t emptyLines;
	struct V_Base *ext;
} Ast_Node;
#define Ast_Node_tag V_Base_tag

extern void Ast_Node_undef(struct Ast_Node *r);

typedef struct Ast_RError *Ast_Error;
typedef struct Ast_RError {
	Ast_Node _;
	o7_int_t code;
	o7_int_t line;
	o7_int_t column;
	o7_int_t bytes;
	struct StringStore_String str;
	struct Ast_RError *next;
} Ast_RError;
#define Ast_RError_tag Ast_Node_tag

extern void Ast_RError_undef(struct Ast_RError *r);

typedef struct Ast_RType *Ast_Type;
typedef struct Ast_RDeclaration *Ast_Declaration;
typedef struct Ast_RDeclarations *Ast_Declarations;
typedef struct Ast_DeclarationsBag__s {
	struct Ast_RDeclarations *d;
} *Ast_DeclarationsBag;
#define Ast_DeclarationsBag__s_tag o7_base_tag

extern void Ast_DeclarationsBag__s_undef(struct Ast_DeclarationsBag__s *r);
typedef struct Ast_RDeclaration {
	Ast_Node _;
	struct Ast_ModuleBag__s *module_;
	struct Ast_DeclarationsBag__s *up;

	struct StringStore_String name;
	o7_bool mark;
	o7_bool used;
	struct Ast_RType *type;
	struct Ast_RDeclaration *next;
} Ast_RDeclaration;
#define Ast_RDeclaration_tag Ast_Node_tag

extern void Ast_RDeclaration_undef(struct Ast_RDeclaration *r);

typedef struct Ast_RArray *Ast_Array;
typedef struct Ast_RType {
	Ast_RDeclaration _;
	struct Ast_RArray *array_;

	o7_set_t properties;
} Ast_RType;
extern o7_tag_t Ast_RType_tag;

extern void Ast_RType_undef(struct Ast_RType *r);

typedef struct Ast_Byte__s {
	Ast_RType _;
} *Ast_Byte;
#define Ast_Byte__s_tag Ast_RType_tag

extern void Ast_Byte__s_undef(struct Ast_Byte__s *r);

typedef struct Ast_RExpression *Ast_Expression;

typedef struct Ast_Const__s {
	Ast_RDeclaration _;
	struct Ast_RExpression *expr;
	o7_bool finished;
} *Ast_Const;
extern o7_tag_t Ast_Const__s_tag;

extern void Ast_Const__s_undef(struct Ast_Const__s *r);

typedef struct Ast_RConstruct *Ast_Construct;
typedef struct Ast_RConstruct {
	Ast_RType _;
} Ast_RConstruct;
extern o7_tag_t Ast_RConstruct_tag;

extern void Ast_RConstruct_undef(struct Ast_RConstruct *r);

typedef struct Ast_RArray {
	Ast_RConstruct _;
	struct Ast_RExpression *count;
} Ast_RArray;
extern o7_tag_t Ast_RArray_tag;

extern void Ast_RArray_undef(struct Ast_RArray *r);

typedef struct Ast_RPointer *Ast_Pointer;

typedef struct Ast_RVarState *Ast_VarState;
typedef struct Ast_RVarState {
	o7_set_t inited;
	o7_bool inCondition;

	struct Ast_RVarState *root;
	struct Ast_RVarState *if_;
	struct Ast_RVarState *else_;
} Ast_RVarState;
#define Ast_RVarState_tag o7_base_tag

extern void Ast_RVarState_undef(struct Ast_RVarState *r);

typedef struct Ast_RVar *Ast_Var;
typedef struct Ast_RVar {
	Ast_RDeclaration _;
	struct Ast_RVarState *state;

	o7_bool checkInit;
	o7_bool inVarParam;
} Ast_RVar;
extern o7_tag_t Ast_RVar_tag;

extern void Ast_RVar_undef(struct Ast_RVar *r);

typedef struct Ast_RRecord *Ast_Record;
typedef struct Ast_RRecord {
	Ast_RConstruct _;
	struct Ast_RRecord *base;
	struct Ast_RVar *vars;
	struct Ast_RPointer *pointer;

	o7_bool needTag;
	o7_bool inAssign;
	o7_bool complete;
} Ast_RRecord;
extern o7_tag_t Ast_RRecord_tag;

extern void Ast_RRecord_undef(struct Ast_RRecord *r);

typedef struct Ast_RPointer {
	Ast_RConstruct _;
} Ast_RPointer;
extern o7_tag_t Ast_RPointer_tag;

extern void Ast_RPointer_undef(struct Ast_RPointer *r);

typedef struct Ast_RNeedTagList *Ast_NeedTagList;
typedef struct Ast_RFormalParam *Ast_FormalParam;
typedef struct Ast_RFormalParam {
	Ast_RVar _;
	o7_set_t access;

	struct Ast_RNeedTagList *needTag;
	struct Ast_RFormalParam *link;
} Ast_RFormalParam;
extern o7_tag_t Ast_RFormalParam_tag;

extern void Ast_RFormalParam_undef(struct Ast_RFormalParam *r);
typedef struct Ast_RNeedTagList {
	V_Base _;
	struct Ast_RNeedTagList *next;
	o7_bool value_;

	o7_int_t count;
	struct Ast_RFormalParam *first;
	struct Ast_RFormalParam *last;
} Ast_RNeedTagList;
#define Ast_RNeedTagList_tag V_Base_tag

extern void Ast_RNeedTagList_undef(struct Ast_RNeedTagList *r);

typedef struct Ast_RProcType {
	Ast_RConstruct _;
	struct Ast_RFormalParam *params;
	struct Ast_RFormalParam *end;
} Ast_RProcType;
extern o7_tag_t Ast_RProcType_tag;

extern void Ast_RProcType_undef(struct Ast_RProcType *r);

typedef struct Ast_RProcType *Ast_ProcType;

typedef struct Ast_RStatement *Ast_Statement;
typedef struct Ast_RProcedure *Ast_Procedure;
typedef struct Ast_RDeclarations {
	Ast_RDeclaration _;
	struct Ast_DeclarationsBag__s *dag;

	struct Ast_RDeclaration *start;
	struct Ast_RDeclaration *end;

	struct Ast_Const__s *consts;
	struct Ast_RType *types;
	struct Ast_RVar *vars;
	struct Ast_RVar *varsEnd;
	struct Ast_RProcedure *procedures;

	o7_int_t recordForwardCount;

	struct Ast_RStatement *stats;
} Ast_RDeclarations;
#define Ast_RDeclarations_tag Ast_RDeclaration_tag

extern void Ast_RDeclarations_undef(struct Ast_RDeclarations *r);

typedef struct Ast_Import__s {
	Ast_RDeclaration _;
} *Ast_Import;
extern o7_tag_t Ast_Import__s_tag;

extern void Ast_Import__s_undef(struct Ast_Import__s *r);

typedef struct Ast_RModule {
	Ast_RDeclarations _;
	struct Ast_ModuleBag__s *bag;
	struct StringStore_Store store;

	o7_bool script;
	o7_bool errorHide;

	o7_bool handleImport;
	struct Ast_Import__s *import_;

	o7_bool fixed;
	o7_bool spec;
	struct Ast_RDeclaration *unusedDecl;

	struct Ast_RError *errors;
	struct Ast_RError *errLast;
} Ast_RModule;
extern o7_tag_t Ast_RModule_tag;

extern void Ast_RModule_undef(struct Ast_RModule *r);

typedef struct Ast_RGeneralProcedure *Ast_GeneralProcedure;
typedef struct Ast_RGeneralProcedure {
	Ast_RDeclarations _;
	struct Ast_RProcType *header;
	struct Ast_RExpression *return_;
} Ast_RGeneralProcedure;
extern o7_tag_t Ast_RGeneralProcedure_tag;

extern void Ast_RGeneralProcedure_undef(struct Ast_RGeneralProcedure *r);

typedef struct Ast_RProcedure {
	Ast_RGeneralProcedure _;
	o7_int_t deep;

	o7_bool usedAsValue;
} Ast_RProcedure;
extern o7_tag_t Ast_RProcedure_tag;

extern void Ast_RProcedure_undef(struct Ast_RProcedure *r);

typedef struct Ast_PredefinedProcedure__s {
	Ast_RGeneralProcedure _;
} *Ast_PredefinedProcedure;
extern o7_tag_t Ast_PredefinedProcedure__s_tag;

extern void Ast_PredefinedProcedure__s_undef(struct Ast_PredefinedProcedure__s *r);

typedef struct Ast_RFactor *Ast_Factor;

typedef struct Ast_RExpression {
	Ast_Node _;
	struct Ast_RType *type;

	o7_set_t properties;
	struct Ast_RFactor *value_;
} Ast_RExpression;
#define Ast_RExpression_tag Ast_Node_tag

extern void Ast_RExpression_undef(struct Ast_RExpression *r);

typedef struct Ast_RSelector *Ast_Selector;
typedef struct Ast_RSelector {
	Ast_Node _;
	struct Ast_RType *type;
	struct Ast_RSelector *next;
} Ast_RSelector;
#define Ast_RSelector_tag Ast_Node_tag

extern void Ast_RSelector_undef(struct Ast_RSelector *r);

typedef struct Ast_SelPointer__s {
	Ast_RSelector _;
} *Ast_SelPointer;
extern o7_tag_t Ast_SelPointer__s_tag;

extern void Ast_SelPointer__s_undef(struct Ast_SelPointer__s *r);

typedef struct Ast_SelGuard__s {
	Ast_RSelector _;
} *Ast_SelGuard;
extern o7_tag_t Ast_SelGuard__s_tag;

extern void Ast_SelGuard__s_undef(struct Ast_SelGuard__s *r);

typedef struct Ast_SelArray__s {
	Ast_RSelector _;
	struct Ast_RExpression *index;
} *Ast_SelArray;
extern o7_tag_t Ast_SelArray__s_tag;

extern void Ast_SelArray__s_undef(struct Ast_SelArray__s *r);

typedef struct Ast_SelRecord__s {
	Ast_RSelector _;
	struct Ast_RVar *var_;
} *Ast_SelRecord;
extern o7_tag_t Ast_SelRecord__s_tag;

extern void Ast_SelRecord__s_undef(struct Ast_SelRecord__s *r);

typedef struct Ast_RFactor {
	Ast_RExpression _;
	struct Ast_RFactor *nextValue;
} Ast_RFactor;
extern o7_tag_t Ast_RFactor_tag;

extern void Ast_RFactor_undef(struct Ast_RFactor *r);

typedef struct Ast_Designator__s {
	Ast_RFactor _;
	struct Ast_RDeclaration *decl;
	o7_set_t inited;
	struct Ast_RSelector *sel;
} *Ast_Designator;
extern o7_tag_t Ast_Designator__s_tag;

extern void Ast_Designator__s_undef(struct Ast_Designator__s *r);

typedef struct Ast_ExprNumber {
	Ast_RFactor _;
} Ast_ExprNumber;
#define Ast_ExprNumber_tag Ast_RFactor_tag

extern void Ast_ExprNumber_undef(struct Ast_ExprNumber *r);

typedef struct Ast_RExprInteger {
	Ast_ExprNumber _;
	o7_int_t int_;
} Ast_RExprInteger;
extern o7_tag_t Ast_RExprInteger_tag;

extern void Ast_RExprInteger_undef(struct Ast_RExprInteger *r);
typedef struct Ast_RExprInteger *Ast_ExprInteger;

typedef struct Ast_ExprReal__s {
	Ast_ExprNumber _;
	double real;
	struct StringStore_String str;
} *Ast_ExprReal;
extern o7_tag_t Ast_ExprReal__s_tag;

extern void Ast_ExprReal__s_undef(struct Ast_ExprReal__s *r);

typedef struct Ast_ExprBoolean__s {
	Ast_RFactor _;
	o7_bool bool_;
} *Ast_ExprBoolean;
extern o7_tag_t Ast_ExprBoolean__s_tag;

extern void Ast_ExprBoolean__s_undef(struct Ast_ExprBoolean__s *r);

typedef struct Ast_ExprString__s {
	Ast_RExprInteger _;
	struct StringStore_String string;
	o7_bool asChar;
} *Ast_ExprString;
extern o7_tag_t Ast_ExprString__s_tag;

extern void Ast_ExprString__s_undef(struct Ast_ExprString__s *r);

typedef struct Ast_ExprNil__s {
	Ast_RFactor _;
} *Ast_ExprNil;
#define Ast_ExprNil__s_tag Ast_RFactor_tag

extern void Ast_ExprNil__s_undef(struct Ast_ExprNil__s *r);

typedef struct Ast_RExprSet *Ast_ExprSet;
typedef struct Ast_RExprSet {
	Ast_RFactor _;
	struct Ast_RExpression *exprs[2];

	struct Ast_RExprSet *next;
} Ast_RExprSet;
extern o7_tag_t Ast_RExprSet_tag;

extern void Ast_RExprSet_undef(struct Ast_RExprSet *r);
typedef struct Ast_ExprSetValue__s {
	Ast_RFactor _;
	LongSet_Type set;
	o7_bool long_;
} *Ast_ExprSetValue;
extern o7_tag_t Ast_ExprSetValue__s_tag;

extern void Ast_ExprSetValue__s_undef(struct Ast_ExprSetValue__s *r);

typedef struct Ast_ExprNegate__s {
	Ast_RFactor _;
	struct Ast_RExpression *expr;
} *Ast_ExprNegate;
extern o7_tag_t Ast_ExprNegate__s_tag;

extern void Ast_ExprNegate__s_undef(struct Ast_ExprNegate__s *r);

typedef struct Ast_ExprBraces__s {
	Ast_RFactor _;
	struct Ast_RExpression *expr;
} *Ast_ExprBraces;
extern o7_tag_t Ast_ExprBraces__s_tag;

extern void Ast_ExprBraces__s_undef(struct Ast_ExprBraces__s *r);

typedef struct Ast_ExprRelation__s {
	Ast_RExpression _;
	o7_int_t relation;
	o7_int_t distance;
	struct Ast_RExpression *exprs[2];
} *Ast_ExprRelation;
extern o7_tag_t Ast_ExprRelation__s_tag;

extern void Ast_ExprRelation__s_undef(struct Ast_ExprRelation__s *r);

typedef struct Ast_ExprIsExtension__s {
	Ast_RExpression _;
	struct Ast_Designator__s *designator;
	struct Ast_RType *extType;
} *Ast_ExprIsExtension;
extern o7_tag_t Ast_ExprIsExtension__s_tag;

extern void Ast_ExprIsExtension__s_undef(struct Ast_ExprIsExtension__s *r);

typedef struct Ast_RExprSum *Ast_ExprSum;
typedef struct Ast_RExprSum {
	Ast_RExpression _;
	o7_int_t add;
	struct Ast_RExpression *term;

	struct Ast_RExprSum *next;
} Ast_RExprSum;
extern o7_tag_t Ast_RExprSum_tag;

extern void Ast_RExprSum_undef(struct Ast_RExprSum *r);

typedef struct Ast_ExprTerm__s {
	Ast_RExpression _;
	struct Ast_RFactor *factor;
	o7_int_t mult;
	struct Ast_RExpression *expr;
} *Ast_ExprTerm;
extern o7_tag_t Ast_ExprTerm__s_tag;

extern void Ast_ExprTerm__s_undef(struct Ast_ExprTerm__s *r);

typedef struct Ast_RParameter *Ast_Parameter;
typedef struct Ast_RParameter {
	Ast_Node _;
	struct Ast_RExpression *expr;
	struct Ast_RParameter *next;
	o7_int_t distance;
} Ast_RParameter;
#define Ast_RParameter_tag Ast_Node_tag

extern void Ast_RParameter_undef(struct Ast_RParameter *r);

typedef struct Ast_ExprCall__s {
	Ast_RFactor _;
	struct Ast_Designator__s *designator;
	struct Ast_RParameter *params;
} *Ast_ExprCall;
extern o7_tag_t Ast_ExprCall__s_tag;

extern void Ast_ExprCall__s_undef(struct Ast_ExprCall__s *r);

typedef struct Ast_RStatement {
	Ast_Node _;
	struct Ast_RExpression *expr;

	struct Ast_RStatement *next;
} Ast_RStatement;
#define Ast_RStatement_tag Ast_Node_tag

extern void Ast_RStatement_undef(struct Ast_RStatement *r);

typedef struct Ast_RWhileIf *Ast_WhileIf;
typedef struct Ast_RWhileIf {
	Ast_RStatement _;
	struct Ast_RStatement *stats;

	struct Ast_RWhileIf *elsif;
} Ast_RWhileIf;
extern o7_tag_t Ast_RWhileIf_tag;

extern void Ast_RWhileIf_undef(struct Ast_RWhileIf *r);

typedef struct Ast_If__s {
	Ast_RWhileIf _;
} *Ast_If;
extern o7_tag_t Ast_If__s_tag;

extern void Ast_If__s_undef(struct Ast_If__s *r);

typedef struct Ast_RCaseLabel *Ast_CaseLabel;
typedef struct Ast_RCaseLabel {
	Ast_Node _;
	o7_int_t value_;
	struct Ast_RDeclaration *qual;

	struct Ast_RCaseLabel *right;
	struct Ast_RCaseLabel *next;
} Ast_RCaseLabel;
#define Ast_RCaseLabel_tag Ast_Node_tag

extern void Ast_RCaseLabel_undef(struct Ast_RCaseLabel *r);
typedef struct Ast_RCaseElement *Ast_CaseElement;
typedef struct Ast_RCaseElement {
	Ast_Node _;
	struct Ast_RCaseLabel *labels;
	struct Ast_RStatement *stats;
	struct Ast_RCaseElement *next;
} Ast_RCaseElement;
#define Ast_RCaseElement_tag Ast_Node_tag

extern void Ast_RCaseElement_undef(struct Ast_RCaseElement *r);
typedef struct Ast_Case__s {
	Ast_RStatement _;
	struct Ast_RCaseElement *elements;

	struct Ast_RStatement *else_;
} *Ast_Case;
extern o7_tag_t Ast_Case__s_tag;

extern void Ast_Case__s_undef(struct Ast_Case__s *r);

typedef struct Ast_Repeat__s {
	Ast_RStatement _;
	struct Ast_RStatement *stats;
} *Ast_Repeat;
extern o7_tag_t Ast_Repeat__s_tag;

extern void Ast_Repeat__s_undef(struct Ast_Repeat__s *r);

typedef struct Ast_For__s {
	Ast_RStatement _;
	struct Ast_RExpression *to;
	struct Ast_RVar *var_;
	o7_int_t by;
	struct Ast_RStatement *stats;
} *Ast_For;
extern o7_tag_t Ast_For__s_tag;

extern void Ast_For__s_undef(struct Ast_For__s *r);

typedef struct Ast_While__s {
	Ast_RWhileIf _;
} *Ast_While;
#define Ast_While__s_tag Ast_RWhileIf_tag

extern void Ast_While__s_undef(struct Ast_While__s *r);

typedef struct Ast_Assign__s {
	Ast_RStatement _;
	struct Ast_Designator__s *designator;
	o7_int_t distance;
} *Ast_Assign;
extern o7_tag_t Ast_Assign__s_tag;

extern void Ast_Assign__s_undef(struct Ast_Assign__s *r);

typedef struct Ast_Call__s {
	Ast_RStatement _;
} *Ast_Call;
extern o7_tag_t Ast_Call__s_tag;

extern void Ast_Call__s_undef(struct Ast_Call__s *r);

typedef struct Ast_StatementError__s {
	Ast_RStatement _;
} *Ast_StatementError;
#define Ast_StatementError__s_tag Ast_RStatement_tag

extern void Ast_StatementError__s_undef(struct Ast_StatementError__s *r);

extern void Ast_PutChars(struct Ast_RModule *m, struct StringStore_String *w, o7_int_t s_len0, o7_char s[/*len0*/], o7_int_t begin, o7_int_t end);

extern void Ast_NodeSetComment(struct Ast_Node *n, struct Ast_RModule *m, o7_int_t com_len0, o7_char com[/*len0*/], o7_int_t ofs, o7_int_t end);

extern void Ast_DeclSetComment(struct Ast_RDeclaration *d, o7_int_t com_len0, o7_char com[/*len0*/], o7_int_t ofs, o7_int_t end);

extern void Ast_ModuleSetComment(struct Ast_RModule *m, o7_int_t com_len0, o7_char com[/*len0*/], o7_int_t ofs, o7_int_t end);

extern struct Ast_RModule *Ast_ModuleNew(o7_int_t name_len0, o7_char name[/*len0*/], o7_int_t begin, o7_int_t end);

extern struct Ast_RModule *Ast_ScriptNew(void);

extern struct Ast_RModule *Ast_ProvideModule(struct Ast_RProvider *prov, struct Ast_RModule *host, o7_int_t name_len0, o7_char name[/*len0*/], o7_int_t ofs, o7_int_t end);

extern struct Ast_ModuleBag__s *Ast_GetModuleByName(struct Ast_RProvider *prov, struct Ast_RModule *host, o7_int_t name_len0, o7_char name[/*len0*/], o7_int_t ofs, o7_int_t end);

extern o7_bool Ast_RegModule(struct Ast_RProvider *provider, struct Ast_RModule *m);

extern o7_int_t Ast_ModuleEnd(struct Ast_RModule *m);

extern void Ast_ModuleReopen(struct Ast_RModule *m);

extern void Ast_ImportHandle(struct Ast_RModule *m);

extern void Ast_ImportEnd(struct Ast_RModule *m);

extern o7_int_t Ast_ImportAdd(struct Ast_RProvider *prov, struct Ast_RModule *m, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t nameOfs, o7_int_t nameEnd, o7_int_t realOfs, o7_int_t realEnd);

extern o7_int_t Ast_ConstAdd(struct Ast_RDeclarations *ds, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t begin, o7_int_t end);

extern o7_int_t Ast_ConstSetExpression(struct Ast_Const__s *const_, struct Ast_RExpression *expr);

extern o7_int_t Ast_TypeAdd(struct Ast_RDeclarations *ds, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t begin, o7_int_t end, struct Ast_RType **td);

extern o7_int_t Ast_CheckUndefRecordForward(struct Ast_RDeclarations *ds);

extern void Ast_TurnIf(struct Ast_RDeclarations *ds);

extern void Ast_TurnElse(struct Ast_RDeclarations *ds);

extern void Ast_TurnFail(struct Ast_RDeclarations *ds);

extern void Ast_BackFromBranch(struct Ast_RDeclarations *ds);

extern o7_int_t Ast_VarAdd(struct Ast_RVar **v, struct Ast_RDeclarations *ds, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t begin, o7_int_t end);

extern struct Ast_RProcType *Ast_ProcTypeNew(o7_bool forType);

extern o7_int_t Ast_ParamAdd(struct Ast_RModule *module_, struct Ast_RProcType *proc, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t begin, o7_int_t end, o7_set_t access);

extern o7_int_t Ast_ParamInsert(struct Ast_RFormalParam **new_, struct Ast_RFormalParam *prev, struct Ast_RModule *module_, struct Ast_RProcType *proc, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t begin, o7_int_t end, struct Ast_RType *type, o7_set_t access);

extern o7_bool Ast_IsNeedTag(struct Ast_RFormalParam *p);

extern o7_int_t Ast_ProcTypeSetReturn(struct Ast_RProcType *proc, struct Ast_RType *type);

extern void Ast_AddError(struct Ast_RModule *m, o7_int_t error, o7_int_t line, o7_int_t column);

extern struct Ast_RType *Ast_TypeGet(o7_int_t id);

extern struct Ast_RArray *Ast_ArrayGet(struct Ast_RType *t, struct Ast_RExpression *count);

extern o7_int_t Ast_MultArrayLenByExpr(o7_int_t *size, struct Ast_RExpression *e);

extern struct Ast_RPointer *Ast_PointerGet(struct Ast_RRecord *t);

extern void Ast_PointerSetRecord(struct Ast_RPointer *tp, struct Ast_RRecord *subtype);

extern o7_int_t Ast_PointerSetType(struct Ast_RPointer *tp, struct Ast_RType *subtype);

extern void Ast_RecordSetBase(struct Ast_RRecord *r, struct Ast_RRecord *base);

extern struct Ast_RRecord *Ast_RecordNew(struct Ast_RDeclarations *ds, struct Ast_RRecord *base);

extern struct Ast_RRecord *Ast_RecordForwardNew(struct Ast_RDeclarations *ds, o7_int_t name_len0, o7_char name[/*len0*/], o7_int_t begin, o7_int_t end);

extern o7_int_t Ast_RecordEnd(struct Ast_RRecord *r);

extern struct Ast_RDeclaration *Ast_PredefinedGet(o7_int_t id);

extern struct Ast_RDeclaration *Ast_DeclarationSearch(struct Ast_RDeclarations *ds, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t begin, o7_int_t end);

extern struct Ast_RType *Ast_TypeErrorNew(void);

extern struct Ast_RDeclaration *Ast_DeclErrorNew(struct Ast_RDeclarations *ds, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t begin, o7_int_t end);

extern o7_int_t Ast_DeclarationGet(struct Ast_RDeclaration **d, struct Ast_RProvider *prov, struct Ast_RDeclarations *ds, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t begin, o7_int_t end);

extern o7_int_t Ast_VarGet(struct Ast_RVar **v, struct Ast_RDeclarations *ds, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t begin, o7_int_t end);

extern o7_int_t Ast_ForIteratorGet(struct Ast_RVar **v, struct Ast_RDeclarations *ds, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t begin, o7_int_t end);

extern struct Ast_RExprInteger *Ast_ExprIntegerNew(o7_int_t int_);

extern struct Ast_ExprReal__s *Ast_ExprRealNew(double real, struct Ast_RModule *m, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t begin, o7_int_t end);

extern struct Ast_ExprReal__s *Ast_ExprRealNewByValue(double real);

extern struct Ast_ExprBoolean__s *Ast_ExprBooleanGet(o7_bool bool_);

extern struct Ast_ExprString__s *Ast_ExprStringNew(struct Ast_RModule *m, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t begin, o7_int_t end);

extern struct Ast_ExprString__s *Ast_ExprCharNew(o7_int_t int_);

extern struct Ast_ExprNil__s *Ast_ExprNilGet(void);

extern struct Ast_RExpression *Ast_ExprErrNew(void);

extern struct Ast_ExprBraces__s *Ast_ExprBracesNew(struct Ast_RExpression *expr);

extern struct Ast_ExprSetValue__s *Ast_ExprSetByValue(LongSet_Type set);

extern o7_int_t Ast_ExprSetNew(struct Ast_RExprSet **base, struct Ast_RExprSet **e, struct Ast_RExpression *expr1, struct Ast_RExpression *expr2);

extern o7_int_t Ast_ExprNegateNew(struct Ast_ExprNegate__s **neg, struct Ast_RExpression *expr);

extern o7_int_t Ast_DesignatorNew(struct Ast_Designator__s **d, struct Ast_RDeclaration *decl);

extern o7_int_t Ast_DesignatorUsed(struct Ast_Designator__s *d, o7_bool varParam, o7_bool inLoop);

extern o7_int_t Ast_CheckInited(struct Ast_RDeclarations *ds);

extern o7_bool Ast_IsRecordExtension(o7_int_t *distance, struct Ast_RRecord *t0, struct Ast_RRecord *t1);

extern o7_int_t Ast_SelPointerNew(struct Ast_RSelector **sel, struct Ast_RType **type);

extern o7_int_t Ast_SelArrayNew(struct Ast_RSelector **sel, struct Ast_RType **type, struct Ast_RExpression *index);

extern o7_int_t Ast_RecordVarAdd(struct Ast_RVar **v, struct Ast_RRecord *r, o7_int_t name_len0, o7_char name[/*len0*/], o7_int_t begin, o7_int_t end);

extern o7_int_t Ast_RecordVarGet(struct Ast_RVar **v, struct Ast_RRecord *r, o7_int_t name_len0, o7_char name[/*len0*/], o7_int_t begin, o7_int_t end);

extern o7_int_t Ast_VarListSetType(struct Ast_RDeclaration *first, struct Ast_RType *t);

extern o7_int_t Ast_ArraySetType(struct Ast_RArray *a, struct Ast_RType *t);

extern o7_int_t Ast_ArrayGetSubtype(struct Ast_RArray *a, struct Ast_RType **subtype);

extern o7_int_t Ast_SelRecordNew(struct Ast_RSelector **sel, struct Ast_RType **type, o7_int_t name_len0, o7_char name[/*len0*/], o7_int_t begin, o7_int_t end);

extern o7_int_t Ast_SelGuardNew(struct Ast_RSelector **sel, struct Ast_Designator__s *des, struct Ast_RDeclaration *guard);

extern o7_bool Ast_EqualProcTypes(struct Ast_RProcType *t1, struct Ast_RProcType *t2);

extern o7_bool Ast_CompatibleTypes(o7_int_t *distance, struct Ast_RType *t1, struct Ast_RType *t2, o7_bool param);

extern o7_int_t Ast_ExprIsExtensionNew(struct Ast_ExprIsExtension__s **e, struct Ast_RExpression *des, struct Ast_RType *type);

extern o7_int_t Ast_ExprRelationNew(struct Ast_ExprRelation__s **e, struct Ast_RExpression *expr1, o7_int_t relation, struct Ast_RExpression *expr2);

extern o7_int_t Ast_ExprSumNew(struct Ast_RExprSum **e, o7_int_t add, struct Ast_RExpression *term);

extern o7_int_t Ast_ExprSumAdd(struct Ast_RExpression *fullSum, struct Ast_RExprSum **lastAdder, o7_int_t add, struct Ast_RExpression *term);

extern o7_int_t Ast_ExprTermNew(struct Ast_ExprTerm__s **e, struct Ast_RFactor *factor, o7_int_t mult, struct Ast_RExpression *factorOrTerm);

extern o7_int_t Ast_ExprTermAdd(struct Ast_RExpression *fullTerm, struct Ast_ExprTerm__s **lastTerm, o7_int_t mult, struct Ast_RExpression *factorOrTerm);

extern o7_int_t Ast_ExprCallNew(struct Ast_ExprCall__s **e, struct Ast_Designator__s *des);

extern o7_bool Ast_IsGlobal(struct Ast_RDeclaration *d);

extern o7_bool Ast_IsChangeable(struct Ast_Designator__s *des);

extern o7_bool Ast_IsVar(struct Ast_RExpression *e);

extern o7_bool Ast_IsFormalParam(struct Ast_RExpression *e);

extern o7_int_t Ast_ProcedureAdd(struct Ast_RDeclarations *ds, struct Ast_RProcedure **p, o7_int_t buf_len0, o7_char buf[/*len0*/], o7_int_t begin, o7_int_t end);

extern o7_int_t Ast_ProcedureSetReturn(struct Ast_RProcedure *p, struct Ast_RExpression *e);

extern o7_int_t Ast_ProcedureEnd(struct Ast_RProcedure *p);

extern o7_int_t Ast_CallParamNew(struct Ast_ExprCall__s *call, struct Ast_RParameter **lastParam, struct Ast_RExpression *e, struct Ast_RFormalParam **currentFormalParam);

extern void Ast_CallParamInsert(struct Ast_RParameter *par, struct Ast_RFormalParam **fp, struct Ast_RExpression *expr, struct Ast_RParameter **np);

extern o7_int_t Ast_CallParamsEnd(struct Ast_ExprCall__s *call, struct Ast_RFormalParam *currentFormalParam, struct Ast_RDeclarations *ds);

extern o7_int_t Ast_CallNew(struct Ast_Call__s **c, struct Ast_Designator__s *des);

extern o7_int_t Ast_CallBeginGet(struct Ast_Call__s **call, struct Ast_RModule *m, o7_bool acceptParams, o7_int_t name_len0, o7_char name[/*len0*/], o7_int_t begin, o7_int_t end);

extern o7_int_t Ast_CommandGet(struct Ast_Call__s **call, struct Ast_RModule *m, o7_int_t name_len0, o7_char name[/*len0*/], o7_int_t begin, o7_int_t end);

extern o7_int_t Ast_IfNew(struct Ast_If__s **if_, struct Ast_RExpression *expr, struct Ast_RStatement *stats);

extern o7_int_t Ast_WhileNew(struct Ast_While__s **w, struct Ast_RExpression *expr, struct Ast_RStatement *stats);

extern o7_int_t Ast_RepeatNew(struct Ast_Repeat__s **r, struct Ast_RStatement *stats);

extern o7_int_t Ast_RepeatSetUntil(struct Ast_Repeat__s *r, struct Ast_RExpression *e);

extern o7_int_t Ast_ForSetBy(struct Ast_For__s *for_, struct Ast_RExpression *by);

extern o7_int_t Ast_ForSetTo(struct Ast_For__s *for_, struct Ast_RExpression *to);

extern o7_int_t Ast_ForNew(struct Ast_For__s **f, struct Ast_RVar *var_, struct Ast_RExpression *init, struct Ast_RExpression *to, o7_int_t by, struct Ast_RStatement *stats);

extern o7_int_t Ast_CaseNew(struct Ast_Case__s **case_, struct Ast_RExpression *expr);

extern o7_int_t Ast_CaseElseSet(struct Ast_Case__s *case_, struct Ast_RStatement *else_);

extern o7_int_t Ast_CaseRangeSearch(struct Ast_Case__s *case_, o7_int_t int_);

extern o7_int_t Ast_CaseLabelNew(struct Ast_RCaseLabel **label, o7_int_t id, o7_int_t value_);

extern o7_int_t Ast_CaseLabelQualNew(struct Ast_RCaseLabel **label, struct Ast_RDeclaration *decl);

extern o7_int_t Ast_CaseRangeNew(struct Ast_RCaseLabel *left, struct Ast_RCaseLabel *right);

extern o7_int_t Ast_CaseRangeListAdd(struct Ast_Case__s *case_, struct Ast_RCaseLabel *first, struct Ast_RCaseLabel *new_);

extern struct Ast_RCaseElement *Ast_CaseElementNew(struct Ast_RCaseLabel *labels);

extern o7_int_t Ast_CaseElementAdd(struct Ast_Case__s *case_, struct Ast_RCaseElement *elem);

extern o7_int_t Ast_AssignNew(struct Ast_Assign__s **a, o7_bool inLoops, struct Ast_Designator__s *des, struct Ast_RExpression *expr);

extern struct Ast_StatementError__s *Ast_StatementErrorNew(void);

extern o7_bool Ast_HasError(struct Ast_RModule *m);

extern void Ast_ProviderInit(struct Ast_RProvider *p, Ast_Provide get, Ast_Register reg);

extern void Ast_Unlinks(struct Ast_RModule *m);

extern void Ast_init(void);
#endif

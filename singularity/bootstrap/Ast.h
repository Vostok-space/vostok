/*  Abstract syntax tree support for Oberon-07
 *  Copyright (C) 2016  ComdivByZero
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#if !defined(HEADER_GUARD_Ast)
#define HEADER_GUARD_Ast

#include "Log.h"
#include "Utf8.h"
#include "Limits.h"
#include "V.h"
#include "Scanner.h"
#include "StringStore.h"
#include "TranslatorLimits.h"
#include "Arithmetic.h"

#define Ast_ErrNo_cnst 0
#define Ast_ErrImportNameDuplicate_cnst (-1)
#define Ast_ErrDeclarationNameDuplicate_cnst (-2)
#define Ast_ErrMultExprDifferentTypes_cnst (-3)
#define Ast_ErrDivExprDifferentTypes_cnst (-4)
#define Ast_ErrNotBoolInLogicExpr_cnst (-5)
#define Ast_ErrNotIntInDivOrMod_cnst (-6)
#define Ast_ErrNotRealTypeForRealDiv_cnst (-7)
#define Ast_ErrNotIntSetElem_cnst (-9)
#define Ast_ErrSetElemOutOfRange_cnst (-10)
#define Ast_ErrSetLeftElemBiggerRightElem_cnst (-11)
#define Ast_ErrAddExprDifferenTypes_cnst (-12)
#define Ast_ErrNotNumberAndNotSetInMult_cnst (-13)
#define Ast_ErrNotNumberAndNotSetInAdd_cnst (-14)
#define Ast_ErrSignForBool_cnst (-15)
#define Ast_ErrRelationExprDifferenTypes_cnst (-17)
#define Ast_ErrExprInWrongTypes_cnst (-18)
#define Ast_ErrExprInRightNotSet_cnst (-19)
#define Ast_ErrExprInLeftNotInteger_cnst (-20)
#define Ast_ErrRelIncompatibleType_cnst (-21)
#define Ast_ErrIsExtTypeNotRecord_cnst (-22)
#define Ast_ErrIsExtVarNotRecord_cnst (-23)
#define Ast_ErrConstDeclExprNotConst_cnst (-24)
#define Ast_ErrAssignIncompatibleType_cnst (-25)
#define Ast_ErrAssignExpectVarParam_cnst (-84)
#define Ast_ErrCallNotProc_cnst (-26)
#define Ast_ErrCallExprWithoutReturn_cnst (-27)
#define Ast_ErrCallIgnoredReturn_cnst (-28)
#define Ast_ErrCallExcessParam_cnst (-29)
#define Ast_ErrCallIncompatibleParamType_cnst (-30)
#define Ast_ErrCallExpectVarParam_cnst (-31)
#define Ast_ErrCallParamsNotEnough_cnst (-32)
#define Ast_ErrCallVarPointerTypeNotSame_cnst (-58)
#define Ast_ErrCaseExprNotIntOrChar_cnst (-33)
#define Ast_ErrCaseLabelNotIntOrChar_cnst (-68)
#define Ast_ErrCaseElemExprTypeMismatch_cnst (-34)
#define Ast_ErrCaseElemDuplicate_cnst (-36)
#define Ast_ErrCaseRangeLabelsTypeMismatch_cnst (-37)
#define Ast_ErrCaseLabelLeftNotLessRight_cnst (-38)
#define Ast_ErrCaseLabelNotConst_cnst (-39)
#define Ast_ErrProcHasNoReturn_cnst (-40)
#define Ast_ErrReturnIncompatibleType_cnst (-41)
#define Ast_ErrExpectReturn_cnst (-42)
#define Ast_ErrDeclarationNotFound_cnst (-43)
#define Ast_ErrDeclarationIsPrivate_cnst (-66)
#define Ast_ErrConstRecursive_cnst (-44)
#define Ast_ErrImportModuleNotFound_cnst (-45)
#define Ast_ErrImportModuleWithError_cnst (-46)
#define Ast_ErrDerefToNotPointer_cnst (-47)
#define Ast_ErrArrayItemToNotArray_cnst (-48)
#define Ast_ErrArrayIndexNotInt_cnst (-49)
#define Ast_ErrArrayIndexNegative_cnst (-50)
#define Ast_ErrArrayIndexOutOfRange_cnst (-51)
#define Ast_ErrGuardExpectRecordExt_cnst (-52)
#define Ast_ErrGuardExpectPointerExt_cnst (-53)
#define Ast_ErrGuardedTypeNotExtensible_cnst (-54)
#define Ast_ErrDotSelectorToNotRecord_cnst (-55)
#define Ast_ErrDeclarationNotVar_cnst (-56)
#define Ast_ErrForIteratorNotInteger_cnst (-57)
#define Ast_ErrNotBoolInIfCondition_cnst (-59)
#define Ast_ErrNotBoolInWhileCondition_cnst (-60)
#define Ast_ErrWhileConditionAlwaysFalse_cnst (-61)
#define Ast_ErrWhileConditionAlwaysTrue_cnst (-62)
#define Ast_ErrNotBoolInUntil_cnst (-63)
#define Ast_ErrUntilAlwaysFalse_cnst (-64)
#define Ast_ErrUntilAlwaysTrue_cnst (-65)
#define Ast_ErrNegateNotBool_cnst (-67)
#define Ast_ErrConstAddOverflow_cnst (-69)
#define Ast_ErrConstSubOverflow_cnst 68
#define Ast_ErrConstMultOverflow_cnst (-71)
#define Ast_ErrConstDivByZero_cnst (-72)
#define Ast_ErrValueOutOfRangeOfByte_cnst (-73)
#define Ast_ErrValueOutOfRangeOfChar_cnst (-74)
#define Ast_ErrExpectIntExpr_cnst (-75)
#define Ast_ErrExpectConstIntExpr_cnst (-76)
#define Ast_ErrForByZero_cnst (-77)
#define Ast_ErrByShouldBePositive_cnst (-78)
#define Ast_ErrByShouldBeNegative_cnst (-79)
#define Ast_ErrForPossibleOverflow_cnst (-80)
#define Ast_ErrVarUninitialized_cnst (-81)
#define Ast_ErrDeclarationNotProc_cnst (-82)
#define Ast_ErrProcNotCommandHaveParams_cnst (-83)
#define Ast_ErrMin_cnst (-100)
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
#define Ast_IdError_cnst 31
#define Ast_IdImport_cnst 32
#define Ast_IdConst_cnst 33
#define Ast_IdVar_cnst 34

typedef struct Ast_RModule *Ast_Module;
typedef struct Ast_RProvider *Ast_Provider;
typedef struct Ast_RModule *(*Ast_Provide)(struct Ast_RProvider *p, struct Ast_RModule *host, o7c_char name[/*len0*/], int name_len0, int ofs, int end);
typedef struct Ast_RProvider {
	V_Base _;
	Ast_Provide get;
} Ast_RProvider;
extern o7c_tag_t Ast_RProvider_tag;

typedef struct Ast_Node {
	V_Base _;
	int id;
	struct StringStore_String comment;
	struct V_Base *ext;
} Ast_Node;
extern o7c_tag_t Ast_Node_tag;

typedef struct Ast_Error_s {
	Ast_Node _;
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
	Ast_Node _;
	struct Ast_RModule *module;
	struct Ast_RDeclarations *up;
	struct StringStore_String name;
	o7c_bool mark;
	struct Ast_RType *type;
	struct Ast_RDeclaration *next;
} Ast_RDeclaration;
extern o7c_tag_t Ast_RDeclaration_tag;

typedef struct Ast_RArray *Ast_Array;
typedef struct Ast_RType {
	Ast_RDeclaration _;
	struct Ast_RArray *array_;
} Ast_RType;
extern o7c_tag_t Ast_RType_tag;

typedef struct Ast_Byte_s {
	Ast_RType _;
} *Ast_Byte;
extern o7c_tag_t Ast_Byte_s_tag;

typedef struct Ast_RExpression *Ast_Expression;
typedef struct Ast_Const_s {
	Ast_RDeclaration _;
	struct Ast_RExpression *expr;
	o7c_bool finished;
} *Ast_Const;
extern o7c_tag_t Ast_Const_s_tag;

typedef struct Ast_RConstruct *Ast_Construct;
typedef struct Ast_RConstruct {
	Ast_RType _;
} Ast_RConstruct;
extern o7c_tag_t Ast_RConstruct_tag;

typedef struct Ast_RArray {
	Ast_RConstruct _;
	struct Ast_RExpression *count;
} Ast_RArray;
extern o7c_tag_t Ast_RArray_tag;

typedef struct Ast_RPointer *Ast_Pointer;
typedef struct Ast_RVar *Ast_Var;
typedef struct Ast_RVar {
	Ast_RDeclaration _;
	o7c_bool inited;
} Ast_RVar;
extern o7c_tag_t Ast_RVar_tag;

typedef struct Ast_Record_s {
	Ast_RConstruct _;
	struct Ast_Record_s *base;
	struct Ast_RVar *vars;
	struct Ast_RPointer *pointer;
} *Ast_Record;
extern o7c_tag_t Ast_Record_s_tag;

typedef struct Ast_RPointer {
	Ast_RConstruct _;
} Ast_RPointer;
extern o7c_tag_t Ast_RPointer_tag;

typedef struct Ast_FormalParam_s {
	Ast_RVar _;
	o7c_bool isVar;
} *Ast_FormalParam;
extern o7c_tag_t Ast_FormalParam_s_tag;

typedef struct Ast_ProcType_s {
	Ast_RConstruct _;
	struct Ast_FormalParam_s *params;
	struct Ast_FormalParam_s *end;
} *Ast_ProcType;
extern o7c_tag_t Ast_ProcType_s_tag;

typedef struct Ast_RStatement *Ast_Statement;
typedef struct Ast_RProcedure *Ast_Procedure;
typedef struct Ast_RDeclarations {
	Ast_RDeclaration _;
	struct Ast_RDeclaration *start;
	struct Ast_RDeclaration *end;
	struct Ast_Const_s *consts;
	struct Ast_RType *types;
	struct Ast_RVar *vars;
	struct Ast_RProcedure *procedures;
	struct Ast_RStatement *stats;
} Ast_RDeclarations;
extern o7c_tag_t Ast_RDeclarations_tag;

typedef struct Ast_Import_s {
	Ast_RDeclaration _;
} *Ast_Import;
extern o7c_tag_t Ast_Import_s_tag;

typedef struct Ast_RModule {
	Ast_RDeclarations _;
	struct StringStore_Store store;
	struct Ast_Import_s *import_;
	o7c_bool fixed;
	struct Ast_Error_s *errors;
	struct Ast_Error_s *errLast;
} Ast_RModule;
extern o7c_tag_t Ast_RModule_tag;

typedef struct Ast_RGeneralProcedure *Ast_GeneralProcedure;
typedef struct Ast_RGeneralProcedure {
	Ast_RDeclarations _;
	struct Ast_ProcType_s *header;
	struct Ast_RExpression *return_;
} Ast_RGeneralProcedure;
extern o7c_tag_t Ast_RGeneralProcedure_tag;

typedef struct Ast_RProcedure {
	Ast_RGeneralProcedure _;
	int distance;
} Ast_RProcedure;
extern o7c_tag_t Ast_RProcedure_tag;

typedef struct Ast_PredefinedProcedure_s {
	Ast_RGeneralProcedure _;
} *Ast_PredefinedProcedure;
extern o7c_tag_t Ast_PredefinedProcedure_s_tag;

typedef struct Ast_RFactor *Ast_Factor;
typedef struct Ast_RExpression {
	Ast_Node _;
	struct Ast_RType *type;
	struct Ast_RFactor *value_;
} Ast_RExpression;
extern o7c_tag_t Ast_RExpression_tag;

typedef struct Ast_RSelector *Ast_Selector;
typedef struct Ast_RSelector {
	Ast_Node _;
	struct Ast_RSelector *next;
} Ast_RSelector;
extern o7c_tag_t Ast_RSelector_tag;

typedef struct Ast_SelPointer_s {
	Ast_RSelector _;
} *Ast_SelPointer;
extern o7c_tag_t Ast_SelPointer_s_tag;

typedef struct Ast_SelGuard_s {
	Ast_RSelector _;
	struct Ast_RType *type;
} *Ast_SelGuard;
extern o7c_tag_t Ast_SelGuard_s_tag;

typedef struct Ast_SelArray_s {
	Ast_RSelector _;
	struct Ast_RExpression *index;
} *Ast_SelArray;
extern o7c_tag_t Ast_SelArray_s_tag;

typedef struct Ast_SelRecord_s {
	Ast_RSelector _;
	struct Ast_RVar *var_;
} *Ast_SelRecord;
extern o7c_tag_t Ast_SelRecord_s_tag;

typedef struct Ast_RFactor {
	Ast_RExpression _;
} Ast_RFactor;
extern o7c_tag_t Ast_RFactor_tag;

typedef struct Ast_Designator_s {
	Ast_RFactor _;
	struct Ast_RDeclaration *decl;
	struct Ast_RSelector *sel;
} *Ast_Designator;
extern o7c_tag_t Ast_Designator_s_tag;

typedef struct Ast_ExprNumber {
	Ast_RFactor _;
} Ast_ExprNumber;
extern o7c_tag_t Ast_ExprNumber_tag;

typedef struct Ast_RExprInteger {
	Ast_ExprNumber _;
	int int_;
} Ast_RExprInteger;
extern o7c_tag_t Ast_RExprInteger_tag;

typedef struct Ast_RExprInteger *Ast_ExprInteger;
typedef struct Ast_ExprReal_s {
	Ast_ExprNumber _;
	double real;
	struct StringStore_String str;
} *Ast_ExprReal;
extern o7c_tag_t Ast_ExprReal_s_tag;

typedef struct Ast_ExprBoolean_s {
	Ast_RFactor _;
	o7c_bool bool_;
} *Ast_ExprBoolean;
extern o7c_tag_t Ast_ExprBoolean_s_tag;

typedef struct Ast_ExprString_s {
	Ast_RExprInteger _;
	struct StringStore_String string;
	o7c_bool asChar;
} *Ast_ExprString;
extern o7c_tag_t Ast_ExprString_s_tag;

typedef struct Ast_ExprNil_s {
	Ast_RFactor _;
} *Ast_ExprNil;
extern o7c_tag_t Ast_ExprNil_s_tag;

typedef struct Ast_ExprSet_s {
	Ast_RFactor _;
	unsigned set;
	struct Ast_RExpression *exprs[2];
	struct Ast_ExprSet_s *next;
} *Ast_ExprSet;
extern o7c_tag_t Ast_ExprSet_s_tag;

typedef struct Ast_ExprNegate_s {
	Ast_RFactor _;
	struct Ast_RExpression *expr;
} *Ast_ExprNegate;
extern o7c_tag_t Ast_ExprNegate_s_tag;

typedef struct Ast_ExprBraces_s {
	Ast_RFactor _;
	struct Ast_RExpression *expr;
} *Ast_ExprBraces;
extern o7c_tag_t Ast_ExprBraces_s_tag;

typedef struct Ast_ExprRelation_s {
	Ast_RExpression _;
	int relation;
	int distance;
	struct Ast_RExpression *exprs[2];
} *Ast_ExprRelation;
extern o7c_tag_t Ast_ExprRelation_s_tag;

typedef struct Ast_ExprIsExtension_s {
	Ast_RExpression _;
	struct Ast_Designator_s *designator;
	struct Ast_RType *extType;
} *Ast_ExprIsExtension;
extern o7c_tag_t Ast_ExprIsExtension_s_tag;

typedef struct Ast_ExprSum_s {
	Ast_RExpression _;
	int add;
	struct Ast_RExpression *term;
	struct Ast_ExprSum_s *next;
} *Ast_ExprSum;
extern o7c_tag_t Ast_ExprSum_s_tag;

typedef struct Ast_ExprTerm_s {
	Ast_RExpression _;
	struct Ast_RFactor *factor;
	int mult;
	struct Ast_RExpression *expr;
} *Ast_ExprTerm;
extern o7c_tag_t Ast_ExprTerm_s_tag;

typedef struct Ast_Parameter_s {
	Ast_Node _;
	struct Ast_RExpression *expr;
	struct Ast_Parameter_s *next;
	int distance;
} *Ast_Parameter;
extern o7c_tag_t Ast_Parameter_s_tag;

typedef struct Ast_ExprCall_s {
	Ast_RFactor _;
	struct Ast_Designator_s *designator;
	struct Ast_Parameter_s *params;
} *Ast_ExprCall;
extern o7c_tag_t Ast_ExprCall_s_tag;

typedef struct Ast_RStatement {
	Ast_Node _;
	struct Ast_RExpression *expr;
	struct Ast_RStatement *next;
} Ast_RStatement;
extern o7c_tag_t Ast_RStatement_tag;

typedef struct Ast_RWhileIf *Ast_WhileIf;
typedef struct Ast_RWhileIf {
	Ast_RStatement _;
	struct Ast_RStatement *stats;
	struct Ast_RWhileIf *elsif;
} Ast_RWhileIf;
extern o7c_tag_t Ast_RWhileIf_tag;

typedef struct Ast_If_s {
	Ast_RWhileIf _;
} *Ast_If;
extern o7c_tag_t Ast_If_s_tag;

typedef struct Ast_CaseLabel_s {
	Ast_Node _;
	int value_;
	struct Ast_RDeclaration *qual;
	struct Ast_CaseLabel_s *right;
	struct Ast_CaseLabel_s *next;
} *Ast_CaseLabel;
extern o7c_tag_t Ast_CaseLabel_s_tag;

typedef struct Ast_CaseElement_s {
	Ast_Node _;
	struct Ast_CaseLabel_s *labels;
	struct Ast_RStatement *stats;
	struct Ast_CaseElement_s *next;
} *Ast_CaseElement;
extern o7c_tag_t Ast_CaseElement_s_tag;

typedef struct Ast_Case_s {
	Ast_RStatement _;
	struct Ast_CaseElement_s *elements;
} *Ast_Case;
extern o7c_tag_t Ast_Case_s_tag;

typedef struct Ast_Repeat_s {
	Ast_RStatement _;
	struct Ast_RStatement *stats;
} *Ast_Repeat;
extern o7c_tag_t Ast_Repeat_s_tag;

typedef struct Ast_For_s {
	Ast_RStatement _;
	struct Ast_RExpression *to;
	struct Ast_RVar *var_;
	int by;
	struct Ast_RStatement *stats;
} *Ast_For;
extern o7c_tag_t Ast_For_s_tag;

typedef struct Ast_While_s {
	Ast_RWhileIf _;
} *Ast_While;
extern o7c_tag_t Ast_While_s_tag;

typedef struct Ast_Assign_s {
	Ast_RStatement _;
	struct Ast_Designator_s *designator;
	int distance;
} *Ast_Assign;
extern o7c_tag_t Ast_Assign_s_tag;

typedef struct Ast_Call_s {
	Ast_RStatement _;
} *Ast_Call;
extern o7c_tag_t Ast_Call_s_tag;

typedef struct Ast_StatementError_s {
	Ast_RStatement _;
} *Ast_StatementError;
extern o7c_tag_t Ast_StatementError_s_tag;


extern void Ast_PutChars(struct Ast_RModule *m, struct StringStore_String *w, o7c_tag_t w_tag, o7c_char s[/*len0*/], int s_len0, int begin, int end);

extern void Ast_NodeSetComment(struct Ast_Node *n, o7c_tag_t n_tag, struct Ast_RModule *m, o7c_char com[/*len0*/], int com_len0, int ofs, int end);

extern void Ast_DeclSetComment(struct Ast_RDeclaration *d, o7c_char com[/*len0*/], int com_len0, int ofs, int end);

extern void Ast_ModuleSetComment(struct Ast_RModule *m, o7c_char com[/*len0*/], int com_len0, int ofs, int end);

extern struct Ast_RModule *Ast_ModuleNew(o7c_char name[/*len0*/], int name_len0, int begin, int end);

extern struct Ast_RModule *Ast_GetModuleByName(struct Ast_RProvider *p, struct Ast_RModule *host, o7c_char name[/*len0*/], int name_len0, int ofs, int end);

extern int Ast_ModuleEnd(struct Ast_RModule *m);

extern int Ast_ImportAdd(struct Ast_RModule *m, o7c_char buf[/*len0*/], int buf_len0, int nameOfs, int nameEnd, int realOfs, int realEnd, struct Ast_RProvider *p);

extern int Ast_ConstAdd(struct Ast_RDeclarations *ds, o7c_char buf[/*len0*/], int buf_len0, int begin, int end);

extern int Ast_ConstSetExpression(struct Ast_Const_s *const_, struct Ast_RExpression *expr);

extern int Ast_TypeAdd(struct Ast_RDeclarations *ds, o7c_char buf[/*len0*/], int buf_len0, int begin, int end, struct Ast_RType **td);

extern int Ast_VarAdd(struct Ast_RDeclarations *ds, o7c_char buf[/*len0*/], int buf_len0, int begin, int end);

extern struct Ast_ProcType_s *Ast_ProcTypeNew(void);

extern int Ast_ParamAdd(struct Ast_RModule *module, struct Ast_ProcType_s *proc, o7c_char buf[/*len0*/], int buf_len0, int begin, int end);

extern void Ast_AddError(struct Ast_RModule *m, int error, int line, int column, int tabs);

extern struct Ast_RType *Ast_TypeGet(int id);

extern struct Ast_RArray *Ast_ArrayGet(struct Ast_RType *t, struct Ast_RExpression *count);

extern struct Ast_RPointer *Ast_PointerGet(struct Ast_Record_s *t);

extern void Ast_RecordSetBase(struct Ast_Record_s *r, struct Ast_Record_s *base);

extern struct Ast_Record_s *Ast_RecordNew(struct Ast_RDeclarations *ds, struct Ast_Record_s *base);

extern struct Ast_RDeclaration *Ast_DeclarationSearch(struct Ast_RDeclarations *ds, o7c_char buf[/*len0*/], int buf_len0, int begin, int end);

extern int Ast_DeclarationGet(struct Ast_RDeclaration **d, struct Ast_RDeclarations *ds, o7c_char buf[/*len0*/], int buf_len0, int begin, int end);

extern int Ast_VarGet(struct Ast_RVar **v, struct Ast_RDeclarations *ds, o7c_char buf[/*len0*/], int buf_len0, int begin, int end);

extern int Ast_ForIteratorGet(struct Ast_RVar **v, struct Ast_RDeclarations *ds, o7c_char buf[/*len0*/], int buf_len0, int begin, int end);

extern struct Ast_RExprInteger *Ast_ExprIntegerNew(int int_);

extern struct Ast_ExprReal_s *Ast_ExprRealNew(double real, struct Ast_RModule *m, o7c_char buf[/*len0*/], int buf_len0, int begin, int end);

extern struct Ast_ExprReal_s *Ast_ExprRealNewByValue(double real);

extern struct Ast_ExprBoolean_s *Ast_ExprBooleanNew(o7c_bool bool_);

extern struct Ast_ExprString_s *Ast_ExprStringNew(struct Ast_RModule *m, o7c_char buf[/*len0*/], int buf_len0, int begin, int end);

extern struct Ast_ExprString_s *Ast_ExprCharNew(int int_);

extern struct Ast_ExprNil_s *Ast_ExprNilNew(void);

extern struct Ast_RExpression *Ast_ExprErrNew(void);

extern struct Ast_ExprBraces_s *Ast_ExprBracesNew(struct Ast_RExpression *expr);

extern struct Ast_ExprSet_s *Ast_ExprSetByValue(unsigned set);

extern int Ast_ExprSetNew(struct Ast_ExprSet_s **e, struct Ast_RExpression *expr1, struct Ast_RExpression *expr2);

extern int Ast_ExprNegateNew(struct Ast_ExprNegate_s **neg, struct Ast_RExpression *expr);

extern int Ast_DesignatorNew(struct Ast_Designator_s **d, struct Ast_RDeclaration *decl);

extern int Ast_CheckDesignatorAsValue(struct Ast_Designator_s *d);

extern o7c_bool Ast_IsRecordExtension(int *distance, struct Ast_Record_s *t0, struct Ast_Record_s *t1);

extern int Ast_SelPointerNew(struct Ast_RSelector **sel, struct Ast_RType **type);

extern int Ast_SelArrayNew(struct Ast_RSelector **sel, struct Ast_RType **type, struct Ast_RExpression *index);

extern int Ast_RecordVarAdd(struct Ast_RVar **v, struct Ast_Record_s *r, o7c_char name[/*len0*/], int name_len0, int begin, int end);

extern int Ast_RecordVarGet(struct Ast_RVar **v, struct Ast_Record_s *r, o7c_char name[/*len0*/], int name_len0, int begin, int end);

extern int Ast_SelRecordNew(struct Ast_RSelector **sel, struct Ast_RType **type, o7c_char name[/*len0*/], int name_len0, int begin, int end);

extern int Ast_SelGuardNew(struct Ast_RSelector **sel, struct Ast_RType **type, struct Ast_RDeclaration *guard);

extern o7c_bool Ast_CompatibleTypes(int *distance, struct Ast_RType *t1, struct Ast_RType *t2);

extern int Ast_ExprIsExtensionNew(struct Ast_ExprIsExtension_s **e, struct Ast_RExpression **des, struct Ast_RType *type);

extern int Ast_ExprRelationNew(struct Ast_ExprRelation_s **e, struct Ast_RExpression *expr1, int relation, struct Ast_RExpression *expr2);

extern int Ast_ExprSumNew(struct Ast_ExprSum_s **e, int add, struct Ast_RExpression *term);

extern int Ast_ExprSumAdd(struct Ast_RExpression *fullSum, struct Ast_ExprSum_s **lastAdder, int add, struct Ast_RExpression *term);

extern int Ast_ExprTermNew(struct Ast_ExprTerm_s **e, struct Ast_RFactor *factor, int mult, struct Ast_RExpression *factorOrTerm);

extern int Ast_ExprTermAdd(struct Ast_RExpression *fullTerm, struct Ast_ExprTerm_s **lastTerm, int mult, struct Ast_RExpression *factorOrTerm);

extern int Ast_ExprCallNew(struct Ast_ExprCall_s **e, struct Ast_Designator_s *des);

extern o7c_bool Ast_IsChangeable(struct Ast_RModule *cur, struct Ast_RVar *v);

extern o7c_bool Ast_IsVar(struct Ast_RExpression *e);

extern int Ast_ProcedureAdd(struct Ast_RDeclarations *ds, struct Ast_RProcedure **p, o7c_char buf[/*len0*/], int buf_len0, int begin, int end);

extern int Ast_ProcedureSetReturn(struct Ast_RProcedure *p, struct Ast_RExpression *e);

extern int Ast_ProcedureEnd(struct Ast_RProcedure *p);

extern int Ast_CallParamNew(struct Ast_ExprCall_s *call, struct Ast_Parameter_s **lastParam, struct Ast_RExpression *e, struct Ast_FormalParam_s **currentFormalParam);

extern int Ast_CallParamsEnd(struct Ast_ExprCall_s *call, struct Ast_FormalParam_s *currentFormalParam);

extern int Ast_CallNew(struct Ast_Call_s **c, struct Ast_Designator_s *des);

extern int Ast_CommandGet(struct Ast_Call_s **call, struct Ast_RModule *m, o7c_char name[/*len0*/], int name_len0, int begin, int end);

extern int Ast_IfNew(struct Ast_If_s **if_, struct Ast_RExpression *expr, struct Ast_RStatement *stats);

extern int Ast_WhileNew(struct Ast_While_s **w, struct Ast_RExpression *expr, struct Ast_RStatement *stats);

extern int Ast_RepeatNew(struct Ast_Repeat_s **r, struct Ast_RStatement *stats);

extern int Ast_RepeatSetUntil(struct Ast_Repeat_s *r, struct Ast_RExpression *e);

extern int Ast_ForSetBy(struct Ast_For_s *for_, struct Ast_RExpression *by);

extern int Ast_ForSetTo(struct Ast_For_s *for_, struct Ast_RExpression *to);

extern int Ast_ForNew(struct Ast_For_s **f, struct Ast_RVar *var_, struct Ast_RExpression *init_, struct Ast_RExpression *to, int by, struct Ast_RStatement *stats);

extern int Ast_CaseNew(struct Ast_Case_s **case_, struct Ast_RExpression *expr);

extern int Ast_CaseRangeSearch(struct Ast_Case_s *case_, int int_);

extern int Ast_CaseLabelNew(struct Ast_CaseLabel_s **label, int id, int value_);

extern int Ast_CaseLabelQualNew(struct Ast_CaseLabel_s **label, struct Ast_RDeclaration *decl);

extern int Ast_CaseRangeNew(struct Ast_CaseLabel_s *left, struct Ast_CaseLabel_s *right);

extern int Ast_CaseRangeListAdd(struct Ast_Case_s *case_, struct Ast_CaseLabel_s *first, struct Ast_CaseLabel_s *new_);

extern struct Ast_CaseElement_s *Ast_CaseElementNew(struct Ast_CaseLabel_s *labels);

extern int Ast_CaseElementAdd(struct Ast_Case_s *case_, struct Ast_CaseElement_s *elem);

extern int Ast_AssignNew(struct Ast_Assign_s **a, struct Ast_Designator_s *des, struct Ast_RExpression *expr);

extern struct Ast_StatementError_s *Ast_StatementErrorNew(void);

extern o7c_bool Ast_HasError(struct Ast_RModule *m);

extern void Ast_ProviderInit(struct Ast_RProvider *p, Ast_Provide get);

extern void Ast_init(void);
#endif

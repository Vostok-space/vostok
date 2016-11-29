#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#define O7C_BOOL_UNDEFINED
#include <o7c.h>

#include "Ast.h"

o7c_tag_t Ast_RProvider_tag;
o7c_tag_t Ast_Node_tag;
o7c_tag_t Ast_Error_s_tag;
o7c_tag_t Ast_RDeclaration_tag;
o7c_tag_t Ast_RType_tag;
o7c_tag_t Ast_Byte_s_tag;
o7c_tag_t Ast_Const_s_tag;
o7c_tag_t Ast_RConstruct_tag;
o7c_tag_t Ast_RArray_tag;
o7c_tag_t Ast_RVar_tag;
o7c_tag_t Ast_Record_s_tag;
o7c_tag_t Ast_RPointer_tag;
o7c_tag_t Ast_FormalParam_s_tag;
o7c_tag_t Ast_ProcType_s_tag;
o7c_tag_t Ast_RDeclarations_tag;
o7c_tag_t Ast_Import_s_tag;
o7c_tag_t Ast_RModule_tag;
o7c_tag_t Ast_RGeneralProcedure_tag;
o7c_tag_t Ast_RProcedure_tag;
o7c_tag_t Ast_PredefinedProcedure_s_tag;
o7c_tag_t Ast_RExpression_tag;
o7c_tag_t Ast_RSelector_tag;
o7c_tag_t Ast_SelPointer_s_tag;
o7c_tag_t Ast_SelGuard_s_tag;
o7c_tag_t Ast_SelArray_s_tag;
o7c_tag_t Ast_SelRecord_s_tag;
o7c_tag_t Ast_RFactor_tag;
o7c_tag_t Ast_Designator_s_tag;
o7c_tag_t Ast_ExprNumber_tag;
o7c_tag_t Ast_RExprInteger_tag;
o7c_tag_t Ast_ExprReal_s_tag;
o7c_tag_t Ast_ExprBoolean_s_tag;
o7c_tag_t Ast_ExprString_s_tag;
o7c_tag_t Ast_ExprNil_s_tag;
o7c_tag_t Ast_ExprSet_s_tag;
o7c_tag_t Ast_ExprNegate_s_tag;
o7c_tag_t Ast_ExprBraces_s_tag;
o7c_tag_t Ast_ExprRelation_s_tag;
o7c_tag_t Ast_ExprIsExtension_s_tag;
o7c_tag_t Ast_ExprSum_s_tag;
o7c_tag_t Ast_ExprTerm_s_tag;
o7c_tag_t Ast_Parameter_s_tag;
o7c_tag_t Ast_ExprCall_s_tag;
o7c_tag_t Ast_RStatement_tag;
o7c_tag_t Ast_RWhileIf_tag;
o7c_tag_t Ast_If_s_tag;
o7c_tag_t Ast_CaseLabel_s_tag;
o7c_tag_t Ast_CaseElement_s_tag;
o7c_tag_t Ast_Case_s_tag;
o7c_tag_t Ast_Repeat_s_tag;
o7c_tag_t Ast_For_s_tag;
o7c_tag_t Ast_While_s_tag;
o7c_tag_t Ast_Assign_s_tag;
o7c_tag_t Ast_Call_s_tag;
o7c_tag_t Ast_StatementError_s_tag;

static struct Ast_RType *types[Ast_PredefinedTypesCount_cnst] ;
static struct Ast_RDeclaration *predefined[Scanner_PredefinedLast_cnst - Scanner_PredefinedFirst_cnst + 1] ;

extern void Ast_PutChars(struct Ast_RModule *m, struct StringStore_String *w, o7c_tag_t w_tag, o7c_char s[/*len0*/], int s_len0, int begin, int end) {
	o7c_retain(m);
	StringStore_Put(&m->store, StringStore_Store_tag, &(*w), w_tag, s, s_len0, begin, end);
	o7c_release(m);
}

static void NodeInit(struct Ast_Node *n, o7c_tag_t n_tag) {
	V_Init(&(*n)._, n_tag);
	(*n).id =  - 1;
	O7C_NULL(&(*n).ext);
}

static void DeclInit(struct Ast_RDeclaration *d, struct Ast_RDeclarations *ds) {
	o7c_retain(d); o7c_retain(ds);
	if (ds == NULL) {
		O7C_NULL(&d->module);
	} else if (ds->_.module == NULL) {
		O7C_ASSIGN(&d->module, O7C_GUARD(Ast_RModule, &ds));
	} else {
		O7C_ASSIGN(&d->module, ds->_.module);
	}
	O7C_ASSIGN(&d->up, ds);
	d->mark = false;
	O7C_NULL(&d->name.block);
	d->name.ofs =  - 1;
	O7C_NULL(&d->type);
	O7C_NULL(&d->next);
	o7c_release(d); o7c_release(ds);
}

static void DeclConnect(struct Ast_RDeclaration *d, struct Ast_RDeclarations *ds, o7c_char name[/*len0*/], int name_len0, int start, int end) {
	o7c_retain(d); o7c_retain(ds);
	assert(d != NULL);
	assert(name[0] != 0x00u);
	assert(!(o7c_is(NULL, d, Ast_RModule_tag)));
	assert((ds->start == NULL) || !(o7c_is(NULL, ds->start, Ast_RModule_tag)));
	DeclInit(d, ds);
	if (ds->end != NULL) {
		assert(ds->end->next == NULL);
		O7C_ASSIGN(&ds->end->next, d);
	} else {
		assert(ds->start == NULL);
		O7C_ASSIGN(&ds->start, d);
	}
	assert(!(o7c_is(NULL, ds->start, Ast_RModule_tag)));
	O7C_ASSIGN(&ds->end, d);
	Ast_PutChars(d->module, &d->name, StringStore_String_tag, name, name_len0, start, end);
	o7c_release(d); o7c_release(ds);
}

static void DeclarationsInit(struct Ast_RDeclarations *d, struct Ast_RDeclarations *up) {
	o7c_retain(d); o7c_retain(up);
	DeclInit(&d->_, NULL);
	O7C_NULL(&d->_.up);
	O7C_NULL(&d->start);
	O7C_NULL(&d->end);
	O7C_NULL(&d->consts);
	O7C_NULL(&d->types);
	O7C_NULL(&d->vars);
	O7C_NULL(&d->procedures);
	O7C_ASSIGN(&d->_.up, up);
	O7C_NULL(&d->stats);
	o7c_release(d); o7c_release(up);
}

static void DeclarationsConnect(struct Ast_RDeclarations *d, struct Ast_RDeclarations *up, o7c_char name[/*len0*/], int name_len0, int start, int end) {
	o7c_retain(d); o7c_retain(up);
	DeclarationsInit(d, up);
	if (name[0] != 0x00u) {
		DeclConnect(&d->_, up, name, name_len0, start, end);
	} else {
		DeclInit(&d->_, up);
	}
	O7C_ASSIGN(&d->_.up, up);
	o7c_release(d); o7c_release(up);
}

extern struct Ast_RModule *Ast_ModuleNew(o7c_char name[/*len0*/], int name_len0, int begin, int end) {
	Ast_Module o7c_return = NULL;

	struct Ast_RModule *m = NULL;

	O7C_NEW(&m, Ast_RModule_tag);
	NodeInit(&(*m)._._._, Ast_RModule_tag);
	DeclarationsInit(&m->_, NULL);
	m->fixed = false;
	O7C_NULL(&m->import_);
	O7C_NULL(&m->errors);
	O7C_NULL(&m->errLast);
	StringStore_StoreInit(&m->store, StringStore_Store_tag);
	Ast_PutChars(m, &m->_._.name, StringStore_String_tag, name, name_len0, begin, end);
	O7C_ASSIGN(&m->_._.module, m);
	Log_Str("Module ", 8);
	Log_Str(m->_._.name.block->s, StringStore_BlockSize_cnst + 1);
	Log_StrLn(" ", 2);
	O7C_ASSIGN(&o7c_return, m);
	o7c_release(m);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern struct Ast_RModule *Ast_GetModuleByName(struct Ast_RProvider *p, struct Ast_RModule *host, o7c_char name[/*len0*/], int name_len0, int ofs, int end) {
	Ast_Module o7c_return = NULL;

	o7c_retain(p); o7c_retain(host);
	O7C_ASSIGN(&o7c_return, p->get(p, host, name, name_len0, ofs, end));
	o7c_release(p); o7c_release(host);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern int Ast_ModuleEnd(struct Ast_RModule *m) {
	int o7c_return;

	o7c_retain(m);
	assert(!m->fixed);
	m->fixed = true;
	o7c_return = Ast_ErrNo_cnst;
	o7c_release(m);
	return o7c_return;
}

static int ImportAdd_Load(struct Ast_RModule **res, struct Ast_RModule *host, o7c_char buf[/*len0*/], int buf_len0, int realOfs, int realEnd, struct Ast_RProvider *p) {
	int o7c_return;

	o7c_char n[TranslatorLimits_MaxLenName_cnst] ;
	int l = O7C_INT_UNDEF, err = O7C_INT_UNDEF;
	memset(&n, 0, sizeof(n));

	o7c_retain(host); o7c_retain(p);
	l = 0;
	assert(StringStore_CopyChars(n, TranslatorLimits_MaxLenName_cnst, &l, buf, buf_len0, realOfs, realEnd));
	Log_Str("Модуль '", 15);
	Log_Str(n, TranslatorLimits_MaxLenName_cnst);
	Log_StrLn("' загружается", 25);
	O7C_ASSIGN(&(*res), Ast_GetModuleByName(p, host, buf, buf_len0, realOfs, realEnd));
	if ((*res) == NULL) {
		O7C_ASSIGN(&(*res), Ast_ModuleNew(buf, buf_len0, realOfs, realEnd));
		err = Ast_ErrImportModuleNotFound_cnst;
	} else if ((*res)->errors != NULL) {
		err = Ast_ErrImportModuleWithError_cnst;
	} else {
		err = Ast_ErrNo_cnst;
	}
	Log_Str("Модуль получен: ", 30);
	Log_Int((int)((*res) != NULL));
	Log_Ln();
	o7c_return = err;
	o7c_release(host); o7c_release(p);
	return o7c_return;
}

static o7c_bool ImportAdd_IsDup(struct Ast_Import_s *i, o7c_char buf[/*len0*/], int buf_len0, int nameOfs, int nameEnd, int realOfs, int realEnd) {
	o7c_bool o7c_return;

	o7c_retain(i);
	o7c_return = StringStore_IsEqualToChars(&i->_.name, StringStore_String_tag, buf, buf_len0, nameOfs, nameEnd) || (o7c_cmp(realOfs, nameOfs) !=  0) && ((o7c_cmp(i->_.name.ofs, i->_.module->_._.name.ofs) !=  0) || (i->_.name.block != i->_.module->_._.name.block)) && StringStore_IsEqualToChars(&i->_.module->_._.name, StringStore_String_tag, buf, buf_len0, realOfs, realEnd);
	o7c_release(i);
	return o7c_return;
}

extern int Ast_ImportAdd(struct Ast_RModule *m, o7c_char buf[/*len0*/], int buf_len0, int nameOfs, int nameEnd, int realOfs, int realEnd, struct Ast_RProvider *p) {
	int o7c_return;

	struct Ast_Import_s *imp = NULL;
	struct Ast_RDeclaration *i = NULL;
	int err = O7C_INT_UNDEF;

	o7c_retain(m); o7c_retain(p);
	assert(!m->fixed);
	O7C_ASSIGN(&i, (&(m->import_)->_));
	assert((i == NULL) || (o7c_is(NULL, m->_.end, Ast_Import_s_tag)));
	while ((i != NULL) && !ImportAdd_IsDup(O7C_GUARD(Ast_Import_s, &i), buf, buf_len0, nameOfs, nameEnd, realOfs, realEnd)) {
		O7C_ASSIGN(&i, i->next);
	}
	if (i != NULL) {
		err = Ast_ErrImportNameDuplicate_cnst;
	} else {
		O7C_NEW(&imp, Ast_Import_s_tag);
		imp->_._.id = Ast_IdImport_cnst;
		DeclConnect(&imp->_, &m->_, buf, buf_len0, nameOfs, nameEnd);
		imp->_.mark = true;
		if (m->import_ == NULL) {
			O7C_ASSIGN(&m->import_, imp);
		}
		err = ImportAdd_Load(&imp->_.module, m, buf, buf_len0, realOfs, realEnd, p);
	}
	o7c_return = err;
	o7c_release(imp); o7c_release(i);
	o7c_release(m); o7c_release(p);
	return o7c_return;
}

static struct Ast_RDeclaration *SearchName(struct Ast_RDeclaration *d, o7c_char buf[/*len0*/], int buf_len0, int begin, int end) {
	Ast_Declaration o7c_return = NULL;

	o7c_retain(d);
	while ((d != NULL) && !StringStore_IsEqualToChars(&d->name, StringStore_String_tag, buf, buf_len0, begin, end)) {
		assert(!(o7c_is(NULL, d, Ast_RModule_tag)));
		O7C_ASSIGN(&d, d->next);
	}
	if (d != NULL) {
		Log_Str("Найдено объявление ", 37);
		while (o7c_cmp(begin, end) !=  0) {
			Log_Char(buf[o7c_ind(buf_len0, begin)]);
			begin = o7c_mod((o7c_add(begin, 1)), (o7c_sub(buf_len0, 1)));
		}
		Log_Str(" id = ", 7);
		Log_Int(d->_.id);
		Log_Ln();
	}
	O7C_ASSIGN(&o7c_return, d);
	o7c_release(d);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern int Ast_ConstAdd(struct Ast_RDeclarations *ds, o7c_char buf[/*len0*/], int buf_len0, int begin, int end) {
	int o7c_return;

	struct Ast_Const_s *c = NULL;
	int err = O7C_INT_UNDEF;

	o7c_retain(ds);
	assert(!ds->_.module->fixed);
	if (SearchName(ds->start, buf, buf_len0, begin, end) != NULL) {
		err = Ast_ErrDeclarationNameDuplicate_cnst;
	} else {
		err = Ast_ErrNo_cnst;
	}
	O7C_NEW(&c, Ast_Const_s_tag);
	c->_._.id = Ast_IdConst_cnst;
	DeclConnect(&c->_, ds, buf, buf_len0, begin, end);
	O7C_NULL(&c->expr);
	c->finished = false;
	if (ds->consts == NULL) {
		O7C_ASSIGN(&ds->consts, c);
	}
	o7c_return = err;
	o7c_release(c);
	o7c_release(ds);
	return o7c_return;
}

extern int Ast_ConstSetExpression(struct Ast_Const_s *const_, struct Ast_RExpression *expr) {
	int o7c_return;

	int err = O7C_INT_UNDEF;

	o7c_retain(const_); o7c_retain(expr);
	const_->finished = true;
	err = Ast_ErrNo_cnst;
	if (expr != NULL) {
		O7C_ASSIGN(&const_->expr, expr);
		O7C_ASSIGN(&const_->_.type, expr->type);
		if ((expr->type != NULL) && (expr->value_ == NULL)) {
			err = Ast_ErrConstDeclExprNotConst_cnst;
		}
	}
	o7c_return = err;
	o7c_release(const_); o7c_release(expr);
	return o7c_return;
}

static void TypeAdd_MoveForwardDeclToLast(struct Ast_RDeclarations *ds, struct Ast_Record_s *rec) {
	o7c_retain(ds); o7c_retain(rec);
	assert(rec->pointer->_._._.next == &rec->_._._);
	rec->_._._._.id = Ast_IdRecord_cnst;
	if (rec->_._._.next != NULL) {
		O7C_ASSIGN(&rec->pointer->_._._.next, rec->_._._.next);
		O7C_NULL(&rec->_._._.next);
		O7C_ASSIGN(&ds->end->next, (&(rec)->_._._));
		O7C_ASSIGN(&ds->end, (&(rec)->_._._));
	}
	o7c_release(ds); o7c_release(rec);
}

extern int Ast_TypeAdd(struct Ast_RDeclarations *ds, o7c_char buf[/*len0*/], int buf_len0, int begin, int end, struct Ast_RType **td) {
	int o7c_return;

	struct Ast_RDeclaration *d = NULL;
	int err = O7C_INT_UNDEF;

	o7c_retain(ds);
	assert(!ds->_.module->fixed);
	O7C_ASSIGN(&d, SearchName(ds->start, buf, buf_len0, begin, end));
	if ((d == NULL) || (o7c_cmp(d->_.id, Ast_IdRecordForward_cnst) ==  0)) {
		err = Ast_ErrNo_cnst;
	} else {
		err = Ast_ErrDeclarationNameDuplicate_cnst;
	}
	if ((d == NULL) || (o7c_cmp(err, Ast_ErrDeclarationNameDuplicate_cnst) ==  0)) {
		assert((*td) != NULL);
		DeclConnect(&(*td)->_, ds, buf, buf_len0, begin, end);
		if (ds->types == NULL) {
			O7C_ASSIGN(&ds->types, (*td));
		}
	} else {
		O7C_ASSIGN(&(*td), O7C_GUARD(Ast_RType, &d));
		TypeAdd_MoveForwardDeclToLast(ds, O7C_GUARD(Ast_Record_s, &d));
	}
	o7c_return = err;
	o7c_release(d);
	o7c_release(ds);
	return o7c_return;
}

static void ChecklessVarAdd(struct Ast_RVar **v, struct Ast_RDeclarations *ds, o7c_char buf[/*len0*/], int buf_len0, int begin, int end) {
	o7c_retain(ds);
	O7C_NEW(&(*v), Ast_RVar_tag);
	(*v)->_._.id = Ast_IdVar_cnst;
	DeclConnect(&(*v)->_, ds, buf, buf_len0, begin, end);
	O7C_NULL(&(*v)->_.type);
	if (ds->vars == NULL) {
		O7C_ASSIGN(&ds->vars, (*v));
	}
	o7c_release(ds);
}

extern int Ast_VarAdd(struct Ast_RDeclarations *ds, o7c_char buf[/*len0*/], int buf_len0, int begin, int end) {
	int o7c_return;

	struct Ast_RVar *v = NULL;
	int err = O7C_INT_UNDEF;

	o7c_retain(ds);
	assert((ds->_.module == NULL) || !ds->_.module->fixed);
	if (SearchName(ds->start, buf, buf_len0, begin, end) == NULL) {
		err = Ast_ErrNo_cnst;
	} else {
		err = Ast_ErrDeclarationNameDuplicate_cnst;
	}
	ChecklessVarAdd(&v, ds, buf, buf_len0, begin, end);
	o7c_return = err;
	o7c_release(v);
	o7c_release(ds);
	return o7c_return;
}

static void TInit(struct Ast_RType *t, int id) {
	o7c_retain(t);
	NodeInit(&(*t)._._, Ast_RType_tag);
	DeclInit(&t->_, NULL);
	t->_._.id = id;
	O7C_NULL(&t->array_);
	o7c_release(t);
}

extern struct Ast_ProcType_s *Ast_ProcTypeNew(void) {
	Ast_ProcType o7c_return = NULL;

	struct Ast_ProcType_s *p = NULL;

	O7C_NEW(&p, Ast_ProcType_s_tag);
	TInit(&p->_._, Ast_IdProcType_cnst);
	O7C_NULL(&p->params);
	O7C_NULL(&p->end);
	O7C_ASSIGN(&o7c_return, p);
	o7c_release(p);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static void ParamAddPredefined(struct Ast_ProcType_s *proc, struct Ast_RType *type, o7c_bool isVar) {
	struct Ast_FormalParam_s *v = NULL;

	o7c_retain(proc); o7c_retain(type);
	O7C_NEW(&v, Ast_FormalParam_s_tag);
	NodeInit(&(*v)._._._, Ast_FormalParam_s_tag);
	if (proc->end == NULL) {
		O7C_ASSIGN(&proc->params, v);
	} else {
		O7C_ASSIGN(&proc->end->_._.next, (&(v)->_._));
	}
	O7C_ASSIGN(&proc->end, v);
	O7C_NULL(&v->_._.module);
	v->_._.mark = false;
	O7C_NULL(&v->_._.next);
	O7C_ASSIGN(&v->_._.type, type);
	v->isVar = isVar;
	o7c_release(v);
	o7c_release(proc); o7c_release(type);
}

extern int Ast_ParamAdd(struct Ast_RModule *module, struct Ast_ProcType_s *proc, o7c_char buf[/*len0*/], int buf_len0, int begin, int end) {
	int o7c_return;

	int err = O7C_INT_UNDEF;

	o7c_retain(module); o7c_retain(proc);
	if (SearchName(&proc->params->_._, buf, buf_len0, begin, end) == NULL) {
		err = Ast_ErrNo_cnst;
	} else {
		err = Ast_ErrDeclarationNameDuplicate_cnst;
	}
	ParamAddPredefined(proc, NULL, false);
	Ast_PutChars(module, &proc->end->_._.name, StringStore_String_tag, buf, buf_len0, begin, end);
	o7c_return = err;
	o7c_release(module); o7c_release(proc);
	return o7c_return;
}

extern void Ast_AddError(struct Ast_RModule *m, int error, int line, int column, int tabs) {
	struct Ast_Error_s *e = NULL;

	o7c_retain(m);
	O7C_NEW(&e, Ast_Error_s_tag);
	NodeInit(&(*e)._, Ast_Error_s_tag);
	O7C_NULL(&e->next);
	e->code = error;
	e->line = line;
	e->column = column;
	e->tabs = tabs;
	if (m->errLast == NULL) {
		O7C_ASSIGN(&m->errors, e);
	} else {
		O7C_ASSIGN(&m->errLast->next, e);
	}
	O7C_ASSIGN(&m->errLast, e);
	o7c_release(e);
	o7c_release(m);
}

extern struct Ast_RType *Ast_TypeGet(int id) {
	Ast_Type o7c_return = NULL;

	assert(types[o7c_ind(Ast_PredefinedTypesCount_cnst, id)] != NULL);
	O7C_ASSIGN(&o7c_return, types[o7c_ind(Ast_PredefinedTypesCount_cnst, id)]);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern struct Ast_RArray *Ast_ArrayGet(struct Ast_RType *t, struct Ast_RExpression *count) {
	Ast_Array o7c_return = NULL;

	struct Ast_RArray *a = NULL;

	o7c_retain(t); o7c_retain(count);
	if ((count != NULL) || (t == NULL) || (t->array_ == NULL)) {
		O7C_NEW(&a, Ast_RArray_tag);
		TInit(&a->_._, Ast_IdArray_cnst);
		O7C_ASSIGN(&a->count, count);
		if ((t != NULL) && (count == NULL)) {
			O7C_ASSIGN(&t->array_, a);
		}
		O7C_ASSIGN(&a->_._._.type, t);
	} else {
		O7C_ASSIGN(&a, t->array_);
	}
	O7C_ASSIGN(&o7c_return, a);
	o7c_release(a);
	o7c_release(t); o7c_release(count);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern struct Ast_RPointer *Ast_PointerGet(struct Ast_Record_s *t) {
	Ast_Pointer o7c_return = NULL;

	struct Ast_RPointer *p = NULL;

	o7c_retain(t);
	if ((t == NULL) || (t->pointer == NULL)) {
		O7C_NEW(&p, Ast_RPointer_tag);
		TInit(&p->_._, Ast_IdPointer_cnst);
		O7C_ASSIGN(&p->_._._.type, (&(t)->_._));
		if (t != NULL) {
			O7C_ASSIGN(&t->pointer, p);
		}
	} else {
		O7C_ASSIGN(&p, t->pointer);
	}
	O7C_ASSIGN(&o7c_return, p);
	o7c_release(p);
	o7c_release(t);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern void Ast_RecordSetBase(struct Ast_Record_s *r, struct Ast_Record_s *base) {
	o7c_retain(r); o7c_retain(base);
	assert(r->base == NULL);
	assert(r->vars == NULL);
	O7C_ASSIGN(&r->base, base);
	o7c_release(r); o7c_release(base);
}

extern struct Ast_Record_s *Ast_RecordNew(struct Ast_RDeclarations *ds, struct Ast_Record_s *base) {
	Ast_Record o7c_return = NULL;

	struct Ast_Record_s *r = NULL;

	o7c_retain(ds); o7c_retain(base);
	O7C_NEW(&r, Ast_Record_s_tag);
	TInit(&r->_._, Ast_IdRecord_cnst);
	O7C_NULL(&r->pointer);
	O7C_NULL(&r->vars);
	O7C_NULL(&r->base);
	Ast_RecordSetBase(r, base);
	O7C_ASSIGN(&o7c_return, r);
	o7c_release(r);
	o7c_release(ds); o7c_release(base);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static struct Ast_RDeclaration *SearchPredefined(o7c_char buf[/*len0*/], int buf_len0, int begin, int end) {
	Ast_Declaration o7c_return = NULL;

	struct Ast_RDeclaration *d = NULL;
	int l = O7C_INT_UNDEF;

	l = Scanner_CheckPredefined(buf, buf_len0, begin, end);
	Log_Str("SearchPredefined ", 18);
	Log_Int(l);
	Log_Ln();
	if ((o7c_cmp(l, Scanner_PredefinedFirst_cnst) >=  0) && (o7c_cmp(l, Scanner_PredefinedLast_cnst) <=  0)) {
		O7C_ASSIGN(&d, predefined[o7c_ind(Scanner_PredefinedLast_cnst - Scanner_PredefinedFirst_cnst + 1, o7c_sub(l, Scanner_PredefinedFirst_cnst))]);
		assert(d != NULL);
	} else {
		O7C_NULL(&d);
	}
	O7C_ASSIGN(&o7c_return, d);
	o7c_release(d);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern struct Ast_RDeclaration *Ast_DeclarationSearch(struct Ast_RDeclarations *ds, o7c_char buf[/*len0*/], int buf_len0, int begin, int end) {
	Ast_Declaration o7c_return = NULL;

	struct Ast_RDeclaration *d = NULL;

	o7c_retain(ds);
	if (o7c_is(NULL, ds, Ast_RProcedure_tag)) {
		O7C_ASSIGN(&d, SearchName(&O7C_GUARD(Ast_RProcedure, &ds)->_.header->params->_._, buf, buf_len0, begin, end));
	} else {
		O7C_NULL(&d);
	}
	if (d == NULL) {
		O7C_ASSIGN(&d, SearchName(ds->start, buf, buf_len0, begin, end));
		if (o7c_is(NULL, ds, Ast_RProcedure_tag)) {
			if (d == NULL) {
				do {
					O7C_ASSIGN(&ds, ds->_.up);
				} while (!((ds == NULL) || (o7c_is(NULL, ds, Ast_RModule_tag))));
				O7C_ASSIGN(&d, SearchName(ds->start, buf, buf_len0, begin, end));
			}
		} else {
			while ((d == NULL) && (ds->_.up != NULL)) {
				O7C_ASSIGN(&ds, ds->_.up);
				O7C_ASSIGN(&d, SearchName(ds->start, buf, buf_len0, begin, end));
			}
		}
		if (d == NULL) {
			O7C_ASSIGN(&d, SearchPredefined(buf, buf_len0, begin, end));
		}
	}
	O7C_ASSIGN(&o7c_return, d);
	o7c_release(d);
	o7c_release(ds);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern int Ast_DeclarationGet(struct Ast_RDeclaration **d, struct Ast_RDeclarations *ds, o7c_char buf[/*len0*/], int buf_len0, int begin, int end) {
	int o7c_return;

	int err = O7C_INT_UNDEF;

	o7c_retain(ds);
	O7C_ASSIGN(&(*d), Ast_DeclarationSearch(ds, buf, buf_len0, begin, end));
	if ((*d) == NULL) {
		err = Ast_ErrDeclarationNotFound_cnst;
		O7C_NEW(&(*d), Ast_RDeclaration_tag);
		(*d)->_.id = Ast_IdError_cnst;
		DeclConnect((*d), ds, buf, buf_len0, begin, end);
		O7C_NEW(&(*d)->type, Ast_RType_tag);
		DeclInit(&(*d)->type->_, NULL);
		(*d)->type->_._.id = Ast_IdError_cnst;
	} else if (!o7c_bl((*d)->mark) && ((*d)->module != NULL) && o7c_bl((*d)->module->fixed)) {
		err = Ast_ErrDeclarationIsPrivate_cnst;
	} else if ((o7c_is(NULL, (*d), Ast_Const_s_tag)) && !O7C_GUARD(Ast_Const_s, &(*d))->finished) {
		err = Ast_ErrConstRecursive_cnst;
		O7C_GUARD(Ast_Const_s, &(*d))->finished = true;
	} else {
		err = Ast_ErrNo_cnst;
	}
	o7c_return = err;
	o7c_release(ds);
	return o7c_return;
}

extern int Ast_VarGet(struct Ast_RVar **v, struct Ast_RDeclarations *ds, o7c_char buf[/*len0*/], int buf_len0, int begin, int end) {
	int o7c_return;

	int err = O7C_INT_UNDEF;
	struct Ast_RDeclaration *d = NULL;

	o7c_retain(ds);
	O7C_ASSIGN(&d, Ast_DeclarationSearch(ds, buf, buf_len0, begin, end));
	if (d == NULL) {
		err = Ast_ErrDeclarationNotFound_cnst;
	} else if (o7c_cmp(d->_.id, Ast_IdVar_cnst) !=  0) {
		err = Ast_ErrDeclarationNotVar_cnst;
	} else {
		err = Ast_ErrNo_cnst;
	}
	if (o7c_cmp(err, Ast_ErrNo_cnst) ==  0) {
		O7C_ASSIGN(&(*v), O7C_GUARD(Ast_RVar, &d));
		if (!o7c_bl(d->mark) && o7c_bl(d->module->fixed)) {
			err = Ast_ErrDeclarationIsPrivate_cnst;
		}
	} else {
		ChecklessVarAdd(&(*v), ds, buf, buf_len0, begin, end);
	}
	o7c_return = err;
	o7c_release(d);
	o7c_release(ds);
	return o7c_return;
}

extern int Ast_ForIteratorGet(struct Ast_RVar **v, struct Ast_RDeclarations *ds, o7c_char buf[/*len0*/], int buf_len0, int begin, int end) {
	int o7c_return;

	int err = O7C_INT_UNDEF;

	o7c_retain(ds);
	err = Ast_VarGet(&(*v), ds, buf, buf_len0, begin, end);
	if ((*v) != NULL) {
		if ((*v)->_.type == NULL) {
			O7C_ASSIGN(&(*v)->_.type, Ast_TypeGet(Ast_IdInteger_cnst));
		} else if (o7c_cmp((*v)->_.type->_._.id, Ast_IdInteger_cnst) !=  0) {
			err = Ast_ErrForIteratorNotInteger_cnst;
		}
	}
	o7c_return = err;
	o7c_release(ds);
	return o7c_return;
}

static void ExprInit(struct Ast_RExpression *e, int id, struct Ast_RType *t) {
	o7c_retain(e); o7c_retain(t);
	NodeInit(&(*e)._, Ast_RExpression_tag);
	e->_.id = id;
	O7C_ASSIGN(&e->type, t);
	O7C_NULL(&e->value_);
	o7c_release(e); o7c_release(t);
}

extern struct Ast_RExprInteger *Ast_ExprIntegerNew(int int_) {
	Ast_ExprInteger o7c_return = NULL;

	struct Ast_RExprInteger *e = NULL;

	O7C_NEW(&e, Ast_RExprInteger_tag);
	ExprInit(&e->_._._, Ast_IdInteger_cnst, Ast_TypeGet(Ast_IdInteger_cnst));
	e->int_ = int_;
	O7C_ASSIGN(&e->_._._.value_, (&(e)->_._));
	O7C_ASSIGN(&o7c_return, e);
	o7c_release(e);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern struct Ast_ExprReal_s *Ast_ExprRealNew(double real, struct Ast_RModule *m, o7c_char buf[/*len0*/], int buf_len0, int begin, int end) {
	Ast_ExprReal o7c_return = NULL;

	struct Ast_ExprReal_s *e = NULL;

	o7c_retain(m);
	assert(m != NULL);
	O7C_NEW(&e, Ast_ExprReal_s_tag);
	ExprInit(&e->_._._, Ast_IdReal_cnst, Ast_TypeGet(Ast_IdReal_cnst));
	e->real = real;
	O7C_ASSIGN(&e->_._._.value_, (&(e)->_._));
	Ast_PutChars(m, &e->str, StringStore_String_tag, buf, buf_len0, begin, end);
	O7C_ASSIGN(&o7c_return, e);
	o7c_release(e);
	o7c_release(m);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern struct Ast_ExprReal_s *Ast_ExprRealNewByValue(double real) {
	Ast_ExprReal o7c_return = NULL;

	struct Ast_ExprReal_s *e = NULL;

	O7C_NEW(&e, Ast_ExprReal_s_tag);
	ExprInit(&e->_._._, Ast_IdReal_cnst, Ast_TypeGet(Ast_IdReal_cnst));
	e->real = real;
	O7C_ASSIGN(&e->_._._.value_, (&(e)->_._));
	O7C_NULL(&e->str.block);
	O7C_ASSIGN(&o7c_return, e);
	o7c_release(e);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern struct Ast_ExprBoolean_s *Ast_ExprBooleanNew(o7c_bool bool_) {
	Ast_ExprBoolean o7c_return = NULL;

	struct Ast_ExprBoolean_s *e = NULL;

	O7C_NEW(&e, Ast_ExprBoolean_s_tag);
	ExprInit(&e->_._, Ast_IdBoolean_cnst, Ast_TypeGet(Ast_IdBoolean_cnst));
	e->bool_ = bool_;
	O7C_ASSIGN(&e->_._.value_, (&(e)->_));
	O7C_ASSIGN(&o7c_return, e);
	o7c_release(e);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern struct Ast_ExprString_s *Ast_ExprStringNew(struct Ast_RModule *m, o7c_char buf[/*len0*/], int buf_len0, int begin, int end) {
	Ast_ExprString o7c_return = NULL;

	struct Ast_ExprString_s *e = NULL;
	int len = O7C_INT_UNDEF;

	o7c_retain(m);
	len = o7c_sub(end, begin);
	if (o7c_cmp(len, 0) <  0) {
		len = o7c_sub(o7c_add(len, buf_len0), 1);
	}
	len = o7c_sub(len, 2);;
	O7C_NEW(&e, Ast_ExprString_s_tag);
	ExprInit(&e->_._._._, Ast_IdString_cnst, &Ast_ArrayGet(Ast_TypeGet(Ast_IdChar_cnst), &Ast_ExprIntegerNew(o7c_add(len, 1))->_._._)->_._);
	e->_.int_ =  - 1;
	e->asChar = false;
	Ast_PutChars(m, &e->string, StringStore_String_tag, buf, buf_len0, begin, end);
	O7C_ASSIGN(&e->_._._._.value_, (&(e)->_._._));
	O7C_ASSIGN(&o7c_return, e);
	o7c_release(e);
	o7c_release(m);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern struct Ast_ExprString_s *Ast_ExprCharNew(int int_) {
	Ast_ExprString o7c_return = NULL;

	struct Ast_ExprString_s *e = NULL;

	O7C_NEW(&e, Ast_ExprString_s_tag);
	ExprInit(&e->_._._._, Ast_IdString_cnst, &Ast_ArrayGet(Ast_TypeGet(Ast_IdChar_cnst), &Ast_ExprIntegerNew(2)->_._._)->_._);
	e->string.ofs =  - 1;
	O7C_NULL(&e->string.block);
	e->_.int_ = int_;
	e->asChar = true;
	O7C_ASSIGN(&e->_._._._.value_, (&(e)->_._._));
	O7C_ASSIGN(&o7c_return, e);
	o7c_release(e);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern struct Ast_ExprNil_s *Ast_ExprNilNew(void) {
	Ast_ExprNil o7c_return = NULL;

	struct Ast_ExprNil_s *e = NULL;

	O7C_NEW(&e, Ast_ExprNil_s_tag);
	ExprInit(&e->_._, Ast_IdPointer_cnst, Ast_TypeGet(Ast_IdPointer_cnst));
	assert(e->_._.type->_.type == NULL);
	O7C_ASSIGN(&e->_._.value_, (&(e)->_));
	O7C_ASSIGN(&o7c_return, e);
	o7c_release(e);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern struct Ast_ExprBraces_s *Ast_ExprBracesNew(struct Ast_RExpression *expr) {
	Ast_ExprBraces o7c_return = NULL;

	struct Ast_ExprBraces_s *e = NULL;

	o7c_retain(expr);
	O7C_NEW(&e, Ast_ExprBraces_s_tag);
	ExprInit(&e->_._, Ast_IdBraces_cnst, expr->type);
	O7C_ASSIGN(&e->expr, expr);
	O7C_ASSIGN(&e->_._.value_, expr->value_);
	O7C_ASSIGN(&o7c_return, e);
	o7c_release(e);
	o7c_release(expr);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern struct Ast_ExprSet_s *Ast_ExprSetByValue(unsigned set) {
	Ast_ExprSet o7c_return = NULL;

	struct Ast_ExprSet_s *e = NULL;

	O7C_NEW(&e, Ast_ExprSet_s_tag);
	ExprInit(&e->_._, Ast_IdSet_cnst, Ast_TypeGet(Ast_IdSet_cnst));
	O7C_NULL(&e->exprs[0]);
	O7C_NULL(&e->exprs[1]);
	e->set = set;
	O7C_NULL(&e->next);
	O7C_ASSIGN(&o7c_return, e);
	o7c_release(e);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static o7c_bool ExprSetNew_CheckRange(int int_) {
	o7c_bool o7c_return;

	o7c_return = (o7c_cmp(int_, 0) >=  0) && (o7c_cmp(int_, Limits_SetMax_cnst) <=  0);
	return o7c_return;
}

extern int Ast_ExprSetNew(struct Ast_ExprSet_s **e, struct Ast_RExpression *expr1, struct Ast_RExpression *expr2) {
	int o7c_return;

	int err = O7C_INT_UNDEF;

	o7c_retain(expr1); o7c_retain(expr2);
	O7C_NEW(&(*e), Ast_ExprSet_s_tag);
	ExprInit(&(*e)->_._, Ast_IdSet_cnst, Ast_TypeGet(Ast_IdSet_cnst));
	O7C_ASSIGN(&(*e)->exprs[0], expr1);
	O7C_ASSIGN(&(*e)->exprs[1], expr2);
	O7C_NULL(&(*e)->next);
	err = Ast_ErrNo_cnst;
	if ((expr1 == NULL) && (expr2 == NULL)) {
		(*e)->set = 0;
	} else if ((expr1 != NULL) && (expr1->type != NULL) && ((expr2 == NULL) || (expr2->type != NULL))) {
		if ((o7c_cmp(expr1->type->_._.id, Ast_IdInteger_cnst) !=  0) || (expr2 != NULL) && (o7c_cmp(expr2->type->_._.id, Ast_IdInteger_cnst) !=  0)) {
			err = Ast_ErrNotIntSetElem_cnst;
		} else if ((expr1->value_ != NULL) && ((expr2 == NULL) || (expr2->value_ != NULL))) {
			if (!ExprSetNew_CheckRange(O7C_GUARD(Ast_RExprInteger, &expr1->value_)->int_) || ((expr2 != NULL) && !ExprSetNew_CheckRange(O7C_GUARD(Ast_RExprInteger, &expr2->value_)->int_))) {
				err = Ast_ErrSetElemOutOfRange_cnst;
			} else if (expr2 == NULL) {
				(*e)->set = (1 << O7C_GUARD(Ast_RExprInteger, &expr1->value_)->int_);
				O7C_ASSIGN(&(*e)->_._.value_, (&((*e))->_));
			} else if (o7c_cmp(O7C_GUARD(Ast_RExprInteger, &expr1->value_)->int_, O7C_GUARD(Ast_RExprInteger, &expr2->value_)->int_) >  0) {
				err = Ast_ErrSetLeftElemBiggerRightElem_cnst;
			} else {
				(*e)->set = o7c_set(O7C_GUARD(Ast_RExprInteger, &expr1->value_)->int_, O7C_GUARD(Ast_RExprInteger, &expr2->value_)->int_);
				O7C_ASSIGN(&(*e)->_._.value_, (&((*e))->_));
			}
		}
	}
	o7c_return = err;
	o7c_release(expr1); o7c_release(expr2);
	return o7c_return;
}

extern int Ast_ExprNegateNew(struct Ast_ExprNegate_s **neg, struct Ast_RExpression *expr) {
	int o7c_return;

	int err = O7C_INT_UNDEF;

	o7c_retain(expr);
	O7C_NEW(&(*neg), Ast_ExprNegate_s_tag);
	ExprInit(&(*neg)->_._, Ast_IdNegate_cnst, Ast_TypeGet(Ast_IdBoolean_cnst));
	O7C_ASSIGN(&(*neg)->expr, expr);
	if (o7c_cmp(expr->type->_._.id, Ast_IdBoolean_cnst) !=  0) {
		err = Ast_ErrNegateNotBool_cnst;
	} else {
		err = Ast_ErrNo_cnst;
		if (expr->value_ != NULL) {
			O7C_ASSIGN(&(*neg)->_._.value_, (&(Ast_ExprBooleanNew(!O7C_GUARD(Ast_ExprBoolean_s, &expr->value_)->bool_))->_));
		}
	}
	o7c_return = err;
	o7c_release(expr);
	return o7c_return;
}

extern struct Ast_Designator_s *Ast_DesignatorNew(struct Ast_RDeclaration *decl) {
	Ast_Designator o7c_return = NULL;

	struct Ast_Designator_s *d = NULL;

	o7c_retain(decl);
	O7C_NEW(&d, Ast_Designator_s_tag);
	ExprInit(&d->_._, Ast_IdDesignator_cnst, NULL);
	O7C_ASSIGN(&d->decl, decl);
	O7C_NULL(&d->sel);
	O7C_ASSIGN(&d->_._.type, decl->type);
	if (o7c_is(NULL, decl, Ast_Const_s_tag)) {
		O7C_ASSIGN(&d->_._.value_, O7C_GUARD(Ast_Const_s, &decl)->expr->value_);
	} else if (o7c_is(NULL, decl, Ast_RGeneralProcedure_tag)) {
		O7C_ASSIGN(&d->_._.type, (&(O7C_GUARD(Ast_RGeneralProcedure, &decl)->header)->_._));
	}
	O7C_ASSIGN(&o7c_return, d);
	o7c_release(d);
	o7c_release(decl);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern o7c_bool Ast_IsRecordExtension(int *distance, struct Ast_Record_s *t0, struct Ast_Record_s *t1) {
	o7c_bool o7c_return;

	int dist = O7C_INT_UNDEF;

	o7c_retain(t0); o7c_retain(t1);
	Log_Str("IsRecordExtension ", 19);
	if ((t0 != NULL) && (t1 != NULL)) {
		dist = 0;
		do {
			O7C_ASSIGN(&t1, t1->base);
			dist = o7c_add(dist, 1);;
		} while (!((t0 == t1) || (t1 == NULL)));
		if (t0 == t1) {
			(*distance) = dist;
		}
	} else {
		O7C_NULL(&t0);
		O7C_NULL(&t1);
	}
	Log_Int((int)(t0 == t1));
	Log_Ln();
	o7c_return = t0 == t1;
	o7c_release(t0); o7c_release(t1);
	return o7c_return;
}

static void SelInit(struct Ast_RSelector *s) {
	o7c_retain(s);
	NodeInit(&(*s)._, Ast_RSelector_tag);
	O7C_NULL(&s->next);
	o7c_release(s);
}

extern int Ast_SelPointerNew(struct Ast_RSelector **sel, struct Ast_RType **type) {
	int o7c_return;

	struct Ast_SelPointer_s *sp = NULL;
	int err = O7C_INT_UNDEF;

	O7C_NEW(&sp, Ast_SelPointer_s_tag);
	SelInit(&sp->_);
	O7C_ASSIGN(&(*sel), (&(sp)->_));
	if (o7c_is(NULL, (*type), Ast_RPointer_tag)) {
		err = Ast_ErrNo_cnst;
		O7C_ASSIGN(&(*type), (*type)->_.type);
	} else {
		err = Ast_ErrDerefToNotPointer_cnst;
	}
	o7c_return = err;
	o7c_release(sp);
	return o7c_return;
}

extern int Ast_SelArrayNew(struct Ast_RSelector **sel, struct Ast_RType **type, struct Ast_RExpression *index) {
	int o7c_return;

	struct Ast_SelArray_s *sa = NULL;
	int err = O7C_INT_UNDEF;

	o7c_retain(index);
	O7C_NEW(&sa, Ast_SelArray_s_tag);
	SelInit(&sa->_);
	O7C_ASSIGN(&sa->index, index);
	O7C_ASSIGN(&(*sel), (&(sa)->_));
	if (!(o7c_is(NULL, (*type), Ast_RArray_tag))) {
		err = Ast_ErrArrayItemToNotArray_cnst;
	} else if (o7c_cmp(index->type->_._.id, Ast_IdInteger_cnst) !=  0) {
		err = Ast_ErrArrayIndexNotInt_cnst;
	} else if ((index->value_ != NULL) && (o7c_cmp(O7C_GUARD(Ast_RExprInteger, &index->value_)->int_, 0) <  0)) {
		err = Ast_ErrArrayIndexNegative_cnst;
	} else if ((index->value_ != NULL) && (O7C_GUARD(Ast_RArray, &(*type))->count != NULL) && (O7C_GUARD(Ast_RArray, &(*type))->count->value_ != NULL) && (o7c_cmp(O7C_GUARD(Ast_RExprInteger, &index->value_)->int_, O7C_GUARD(Ast_RExprInteger, &O7C_GUARD(Ast_RArray, &(*type))->count->value_)->int_) >=  0)) {
		err = Ast_ErrArrayIndexOutOfRange_cnst;
	} else {
		err = Ast_ErrNo_cnst;
	}
	O7C_ASSIGN(&(*type), (*type)->_.type);
	o7c_return = err;
	o7c_release(sa);
	o7c_release(index);
	return o7c_return;
}

static struct Ast_RVar *RecordVarSearch(struct Ast_Record_s *r, o7c_char name[/*len0*/], int name_len0, int begin, int end) {
	Ast_Var o7c_return = NULL;

	struct Ast_RDeclaration *d = NULL;
	struct Ast_RVar *v = NULL;

	o7c_retain(r);
	O7C_ASSIGN(&d, SearchName(&r->vars->_, name, name_len0, begin, end));
	while ((d == NULL) && (r->base != NULL)) {
		O7C_ASSIGN(&r, r->base);
		O7C_ASSIGN(&d, SearchName(&r->vars->_, name, name_len0, begin, end));
	}
	if (d != NULL) {
		O7C_ASSIGN(&v, O7C_GUARD(Ast_RVar, &d));
	} else {
		O7C_NULL(&v);
	}
	O7C_ASSIGN(&o7c_return, v);
	o7c_release(d); o7c_release(v);
	o7c_release(r);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static struct Ast_RVar *RecordChecklessVarAdd(struct Ast_Record_s *r, o7c_char name[/*len0*/], int name_len0, int begin, int end) {
	Ast_Var o7c_return = NULL;

	struct Ast_RVar *v = NULL;
	struct Ast_RDeclaration *last = NULL;

	o7c_retain(r);
	O7C_NEW(&v, Ast_RVar_tag);
	DeclInit(&v->_, NULL);
	O7C_ASSIGN(&v->_.module, r->_._._.module);
	Ast_PutChars(v->_.module, &v->_.name, StringStore_String_tag, name, name_len0, begin, end);
	if (r->vars == NULL) {
		O7C_ASSIGN(&r->vars, v);
	} else {
		O7C_ASSIGN(&last, (&(r->vars)->_));
		while (last->next != NULL) {
			O7C_ASSIGN(&last, last->next);
		}
		O7C_ASSIGN(&last->next, (&(v)->_));
	}
	O7C_ASSIGN(&o7c_return, v);
	o7c_release(v); o7c_release(last);
	o7c_release(r);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern int Ast_RecordVarAdd(struct Ast_RVar **v, struct Ast_Record_s *r, o7c_char name[/*len0*/], int name_len0, int begin, int end) {
	int o7c_return;

	int err = O7C_INT_UNDEF;

	o7c_retain(r);
	O7C_ASSIGN(&(*v), RecordVarSearch(r, name, name_len0, begin, end));
	if ((*v) == NULL) {
		err = Ast_ErrNo_cnst;
	} else {
		err = Ast_ErrDeclarationNameDuplicate_cnst;
	}
	O7C_ASSIGN(&(*v), RecordChecklessVarAdd(r, name, name_len0, begin, end));
	o7c_return = err;
	o7c_release(r);
	return o7c_return;
}

extern int Ast_RecordVarGet(struct Ast_RVar **v, struct Ast_Record_s *r, o7c_char name[/*len0*/], int name_len0, int begin, int end) {
	int o7c_return;

	int err = O7C_INT_UNDEF;

	o7c_retain(r);
	O7C_ASSIGN(&(*v), RecordVarSearch(r, name, name_len0, begin, end));
	if ((*v) != NULL) {
		err = Ast_ErrNo_cnst;
	} else {
		err = Ast_ErrDeclarationNotFound_cnst;
		O7C_ASSIGN(&(*v), RecordChecklessVarAdd(r, name, name_len0, begin, end));
		O7C_ASSIGN(&(*v)->_.type, Ast_TypeGet(Ast_IdInteger_cnst));
	}
	o7c_return = err;
	o7c_release(r);
	return o7c_return;
}

extern int Ast_SelRecordNew(struct Ast_RSelector **sel, struct Ast_RType **type, o7c_char name[/*len0*/], int name_len0, int begin, int end) {
	int o7c_return;

	struct Ast_SelRecord_s *sr = NULL;
	int err = O7C_INT_UNDEF;
	struct Ast_Record_s *record = NULL;
	struct Ast_RVar *var_ = NULL;

	O7C_NEW(&sr, Ast_SelRecord_s_tag);
	SelInit(&sr->_);
	O7C_NULL(&var_);
	err = Ast_ErrNo_cnst;
	if ((*type) != NULL) {
		if (!(o7c_in((*type)->_._.id, ((1 << Ast_IdRecord_cnst) | (1 << Ast_IdPointer_cnst))))) {
			err = Ast_ErrDotSelectorToNotRecord_cnst;
		} else {
			if (o7c_cmp((*type)->_._.id, Ast_IdRecord_cnst) ==  0) {
				O7C_ASSIGN(&record, O7C_GUARD(Ast_Record_s, &(*type)));
			} else if ((*type)->_.type == NULL) {
				O7C_NULL(&record);
			} else {
				O7C_ASSIGN(&record, O7C_GUARD(Ast_Record_s, &(*type)->_.type));
			}
			if (record != NULL) {
				err = Ast_RecordVarGet(&var_, record, name, name_len0, begin, end);
				if (var_ != NULL) {
					O7C_ASSIGN(&(*type), var_->_.type);
				} else {
					O7C_NULL(&(*type));
				}
			}
		}
	}
	O7C_ASSIGN(&sr->var_, var_);
	O7C_ASSIGN(&(*sel), (&(sr)->_));
	o7c_return = err;
	o7c_release(sr); o7c_release(record); o7c_release(var_);
	return o7c_return;
}

extern int Ast_SelGuardNew(struct Ast_RSelector **sel, struct Ast_RType **type, struct Ast_RDeclaration *guard) {
	int o7c_return;

	struct Ast_SelGuard_s *sg = NULL;
	int err = O7C_INT_UNDEF, dist = O7C_INT_UNDEF;

	o7c_retain(guard);
	O7C_NEW(&sg, Ast_SelGuard_s_tag);
	SelInit(&sg->_);
	err = Ast_ErrNo_cnst;
	if (!(o7c_in((*type)->_._.id, ((1 << Ast_IdRecord_cnst) | (1 << Ast_IdPointer_cnst))))) {
		err = Ast_ErrGuardedTypeNotExtensible_cnst;
	} else if (o7c_cmp((*type)->_._.id, Ast_IdRecord_cnst) ==  0) {
		if (!(o7c_is(NULL, guard, Ast_Record_s_tag)) || !Ast_IsRecordExtension(&dist, O7C_GUARD(Ast_Record_s, &(*type)), O7C_GUARD(Ast_Record_s, &guard))) {
			err = Ast_ErrGuardExpectRecordExt_cnst;
		} else {
			O7C_ASSIGN(&(*type), (&(O7C_GUARD(Ast_Record_s, &guard))->_._));
		}
	} else {
		if (!(o7c_is(NULL, guard, Ast_RPointer_tag)) || !Ast_IsRecordExtension(&dist, O7C_GUARD(Ast_Record_s, &O7C_GUARD(Ast_RPointer, &(*type))->_._._.type), O7C_GUARD(Ast_Record_s, &O7C_GUARD(Ast_RPointer, &guard)->_._._.type))) {
			err = Ast_ErrGuardExpectPointerExt_cnst;
		} else {
			O7C_ASSIGN(&(*type), (&(O7C_GUARD(Ast_RPointer, &guard))->_._));
		}
	}
	O7C_ASSIGN(&sg->type, (*type));
	O7C_ASSIGN(&(*sel), (&(sg)->_));
	o7c_return = err;
	o7c_release(sg);
	o7c_release(guard);
	return o7c_return;
}

static o7c_bool CompatibleTypes_EqualProcTypes(struct Ast_ProcType_s *t1, struct Ast_ProcType_s *t2) {
	o7c_bool o7c_return;

	o7c_bool comp = O7C_BOOL_UNDEF;
	struct Ast_RDeclaration *fp1 = NULL, *fp2 = NULL;

	o7c_retain(t1); o7c_retain(t2);
	comp = t1->_._._.type == t2->_._._.type;
	if (comp) {
		O7C_ASSIGN(&fp1, (&(t1->params)->_._));
		O7C_ASSIGN(&fp2, (&(t2->params)->_._));
		while ((fp1 != NULL) && (fp2 != NULL) && (o7c_is(NULL, fp1, Ast_FormalParam_s_tag)) && (o7c_is(NULL, fp2, Ast_FormalParam_s_tag)) && (fp1->type == fp2->type) && (O7C_GUARD(Ast_FormalParam_s, &fp1)->isVar == O7C_GUARD(Ast_FormalParam_s, &fp2)->isVar)) {
			O7C_ASSIGN(&fp1, fp1->next);
			O7C_ASSIGN(&fp2, fp2->next);
		}
		comp = ((fp1 == NULL) || !(o7c_is(NULL, fp1, Ast_FormalParam_s_tag))) && ((fp2 == NULL) || !(o7c_is(NULL, fp2, Ast_FormalParam_s_tag)));
	}
	o7c_return = o7c_bl(comp);
	o7c_release(fp1); o7c_release(fp2);
	o7c_release(t1); o7c_release(t2);
	return o7c_return;
}

extern o7c_bool Ast_CompatibleTypes(int *distance, struct Ast_RType *t1, struct Ast_RType *t2) {
	o7c_bool o7c_return;

	o7c_bool comp = O7C_BOOL_UNDEF;

	o7c_retain(t1); o7c_retain(t2);
	(*distance) = 0;
	comp = (t1 == NULL) || (t2 == NULL);
	if (!comp) {
		comp = t1 == t2;
		Log_Str("Идентификаторы типов : ", 43);
		Log_Int(t1->_._.id);
		Log_Str(" : ", 4);
		Log_Int(t2->_._.id);
		Log_Ln();
		if (!o7c_bl(comp) && (o7c_cmp(t1->_._.id, t2->_._.id) ==  0) && (o7c_in(t1->_._.id, ((1 << Ast_IdArray_cnst) | (1 << Ast_IdPointer_cnst) | (1 << Ast_IdRecord_cnst) | (1 << Ast_IdProcType_cnst))))) {
			switch (t1->_._.id) {
			case 7:
				comp = Ast_CompatibleTypes(&(*distance), t1->_.type, t2->_.type);
				break;
			case 6:
				comp = (t1->_.type == NULL) || (t2->_.type == NULL) || Ast_IsRecordExtension(&(*distance), O7C_GUARD(Ast_Record_s, &t1->_.type), O7C_GUARD(Ast_Record_s, &t2->_.type));
				break;
			case 8:
				comp = Ast_IsRecordExtension(&(*distance), O7C_GUARD(Ast_Record_s, &t1), O7C_GUARD(Ast_Record_s, &t2));
				break;
			case 10:
				comp = CompatibleTypes_EqualProcTypes(O7C_GUARD(Ast_ProcType_s, &t1), O7C_GUARD(Ast_ProcType_s, &t2));
				break;
			default:
				abort();
				break;
			}
		}
	}
	o7c_return = o7c_bl(comp);
	o7c_release(t1); o7c_release(t2);
	return o7c_return;
}

extern int Ast_ExprIsExtensionNew(struct Ast_ExprIsExtension_s **e, struct Ast_RExpression **des, struct Ast_RType *type) {
	int o7c_return;

	int err = O7C_INT_UNDEF;

	o7c_retain(type);
	O7C_NEW(&(*e), Ast_ExprIsExtension_s_tag);
	ExprInit(&(*e)->_, Ast_IdIsExtension_cnst, Ast_TypeGet(Ast_IdBoolean_cnst));
	O7C_NULL(&(*e)->designator);
	O7C_ASSIGN(&(*e)->extType, type);
	err = Ast_ErrNo_cnst;
	if ((type != NULL) && !(o7c_in(type->_._.id, ((1 << Ast_IdPointer_cnst) | (1 << Ast_IdRecord_cnst))))) {
		err = Ast_ErrIsExtTypeNotRecord_cnst;
	} else if ((*des) != NULL) {
		if (o7c_is(NULL, (*des), Ast_Designator_s_tag)) {
			O7C_ASSIGN(&(*e)->designator, O7C_GUARD(Ast_Designator_s, &(*des)));
			if (((*des)->type != NULL) && !(o7c_in((*des)->type->_._.id, ((1 << Ast_IdPointer_cnst) | (1 << Ast_IdRecord_cnst))))) {
				err = Ast_ErrIsExtVarNotRecord_cnst;
			}
		} else {
			err = Ast_ErrIsExtVarNotRecord_cnst;
		}
	}
	o7c_return = err;
	o7c_release(type);
	return o7c_return;
}

static o7c_bool CompatibleAsCharAndString(struct Ast_RType *t1, struct Ast_RExpression **e2) {
	o7c_bool o7c_return;

	o7c_bool ret = O7C_BOOL_UNDEF;

	o7c_retain(t1);
	Log_Str("1 CompatibleAsCharAndString ", 29);
	Log_Int((int)((*e2)->value_ != NULL));
	Log_Ln();
	ret = (o7c_cmp(t1->_._.id, Ast_IdChar_cnst) ==  0) && ((*e2)->value_ != NULL) && (o7c_is(NULL, (*e2)->value_, Ast_ExprString_s_tag)) && (o7c_cmp(O7C_GUARD(Ast_ExprString_s, &(*e2)->value_)->_.int_, 0) >=  0);
	if (o7c_bl(ret) && !O7C_GUARD(Ast_ExprString_s, &(*e2)->value_)->asChar) {
		if (o7c_is(NULL, (*e2), Ast_ExprString_s_tag)) {
			O7C_ASSIGN(&(*e2), (&(Ast_ExprCharNew(O7C_GUARD(Ast_ExprString_s, &(*e2)->value_)->_.int_))->_._._._));
		} else {
			O7C_ASSIGN(&(*e2)->value_, (&(Ast_ExprCharNew(O7C_GUARD(Ast_ExprString_s, &(*e2)->value_)->_.int_))->_._._));
		}
		assert(o7c_bl(O7C_GUARD(Ast_ExprString_s, &(*e2)->value_)->asChar));
	}
	o7c_return = o7c_bl(ret);
	o7c_release(t1);
	return o7c_return;
}

static o7c_bool ExprRelationNew_CheckType(struct Ast_RType *t1, struct Ast_RType *t2, struct Ast_RExpression **e1, struct Ast_RExpression **e2, int relation, int *distance, int *err) {
	o7c_bool o7c_return;

	o7c_bool continue_ = O7C_BOOL_UNDEF;
	int dist1 = O7C_INT_UNDEF, dist2 = O7C_INT_UNDEF;

	o7c_retain(t1); o7c_retain(t2);
	dist1 = 0;
	dist2 = 0;
	if ((t1 == NULL) || (t2 == NULL)) {
		continue_ = false;
	} else if (o7c_cmp(relation, Scanner_In_cnst) ==  0) {
		continue_ = (o7c_cmp(t1->_._.id, Ast_IdInteger_cnst) ==  0) && (o7c_cmp(t2->_._.id, Ast_IdSet_cnst) ==  0);
		if (!continue_) {
			(*err) = o7c_add(o7c_add(o7c_sub(Ast_ErrExprInWrongTypes_cnst, 3), (int)(o7c_cmp(t1->_._.id, Ast_IdInteger_cnst) !=  0)), o7c_mul((int)(o7c_cmp(t2->_._.id, Ast_IdSet_cnst) !=  0), 2));
		}
	} else if (!Ast_CompatibleTypes(&dist1, t1, t2) && !Ast_CompatibleTypes(&dist2, t2, t1) && !CompatibleAsCharAndString(t1, &(*e2)) && !CompatibleAsCharAndString(t2, &(*e1))) {
		(*err) = Ast_ErrRelationExprDifferenTypes_cnst;
		continue_ = false;
	} else if ((o7c_in(t1->_._.id, ((1 << Ast_IdInteger_cnst) | (1 << Ast_IdReal_cnst) | (1 << Ast_IdChar_cnst)))) || (o7c_cmp(t1->_._.id, Ast_IdArray_cnst) ==  0) && (o7c_cmp(t1->_.type->_._.id, Ast_IdChar_cnst) ==  0)) {
		continue_ = true;
	} else if (o7c_in(t1->_._.id, ((1 << Ast_IdRecord_cnst) | (1 << Ast_IdArray_cnst)))) {
		continue_ = false;
		(*err) = Ast_ErrRelIncompatibleType_cnst;
	} else {
		continue_ = (o7c_cmp(relation, Scanner_Equal_cnst) ==  0) || (o7c_cmp(relation, Scanner_Inequal_cnst) ==  0) || (o7c_cmp(t1->_._.id, Ast_IdSet_cnst) ==  0) && ((o7c_cmp(relation, Scanner_LessEqual_cnst) ==  0) || (o7c_cmp(relation, Scanner_GreaterEqual_cnst) ==  0));
		if (!continue_) {
			(*err) = Ast_ErrRelIncompatibleType_cnst;
		}
	}
	(*distance) = o7c_sub(dist1, dist2);
	o7c_return = o7c_bl(continue_);
	o7c_release(t1); o7c_release(t2);
	return o7c_return;
}

extern int Ast_ExprRelationNew(struct Ast_ExprRelation_s **e, struct Ast_RExpression *expr1, int relation, struct Ast_RExpression *expr2) {
	int o7c_return;

	int err = O7C_INT_UNDEF;
	o7c_bool res = O7C_BOOL_UNDEF;
	struct Ast_RExpression *v1 = NULL, *v2 = NULL;

	o7c_retain(expr1); o7c_retain(expr2);
	assert((o7c_cmp(relation, Scanner_RelationFirst_cnst) >=  0) && (o7c_cmp(relation, Scanner_RelationLast_cnst) <  0));
	O7C_NEW(&(*e), Ast_ExprRelation_s_tag);
	ExprInit(&(*e)->_, Ast_IdRelation_cnst, Ast_TypeGet(Ast_IdBoolean_cnst));
	O7C_ASSIGN(&(*e)->exprs[0], expr1);
	O7C_ASSIGN(&(*e)->exprs[1], expr2);
	(*e)->relation = relation;
	err = Ast_ErrNo_cnst;
	if ((expr1 != NULL) && (expr2 != NULL) && ExprRelationNew_CheckType(expr1->type, expr2->type, &(*e)->exprs[0], &(*e)->exprs[1], relation, &(*e)->distance, &err) && (expr1->value_ != NULL) && (expr2->value_ != NULL) && (o7c_cmp(relation, Scanner_Is_cnst) !=  0)) {
		O7C_ASSIGN(&v1, (&((*e)->exprs[0]->value_)->_));
		O7C_ASSIGN(&v2, (&((*e)->exprs[1]->value_)->_));
		switch (relation) {
		case 21:
			switch (expr1->type->_._.id) {
			case 0:
			case 3:
				res = o7c_cmp(O7C_GUARD(Ast_RExprInteger, &v1)->int_, O7C_GUARD(Ast_RExprInteger, &v2)->int_) ==  0;
				break;
			case 1:
				res = O7C_GUARD(Ast_ExprBoolean_s, &v1)->bool_ == O7C_GUARD(Ast_ExprBoolean_s, &v2)->bool_;
				break;
			case 4:
				res = O7C_GUARD(Ast_ExprReal_s, &v1)->real == O7C_GUARD(Ast_ExprReal_s, &v2)->real;
				break;
			case 5:
				res = O7C_GUARD(Ast_ExprSet_s, &v1)->set == O7C_GUARD(Ast_ExprSet_s, &v2)->set;
				break;
			case 6:
				res = false;
				break;
			case 7:
				res = false;
				break;
			case 10:
				res = false;
				break;
			default:
				abort();
				break;
			}
			break;
		case 22:
			switch (expr1->type->_._.id) {
			case 0:
			case 3:
				res = o7c_cmp(O7C_GUARD(Ast_RExprInteger, &v1)->int_, O7C_GUARD(Ast_RExprInteger, &v2)->int_) !=  0;
				break;
			case 1:
				res = O7C_GUARD(Ast_ExprBoolean_s, &v1)->bool_ != O7C_GUARD(Ast_ExprBoolean_s, &v2)->bool_;
				break;
			case 4:
				res = O7C_GUARD(Ast_ExprReal_s, &v1)->real != O7C_GUARD(Ast_ExprReal_s, &v2)->real;
				break;
			case 5:
				res = O7C_GUARD(Ast_ExprSet_s, &v1)->set != O7C_GUARD(Ast_ExprSet_s, &v2)->set;
				break;
			case 6:
				res = false;
				break;
			case 7:
				res = false;
				break;
			case 10:
				res = false;
				break;
			default:
				abort();
				break;
			}
			break;
		case 23:
			switch (expr1->type->_._.id) {
			case 0:
			case 3:
				res = o7c_cmp(O7C_GUARD(Ast_RExprInteger, &v1)->int_, O7C_GUARD(Ast_RExprInteger, &v2)->int_) <  0;
				break;
			case 4:
				res = O7C_GUARD(Ast_ExprReal_s, &v1)->real < O7C_GUARD(Ast_ExprReal_s, &v2)->real;
				break;
			case 7:
				res = false;
				break;
			default:
				abort();
				break;
			}
			break;
		case 24:
			switch (expr1->type->_._.id) {
			case 0:
			case 3:
				res = o7c_cmp(O7C_GUARD(Ast_RExprInteger, &v1)->int_, O7C_GUARD(Ast_RExprInteger, &v2)->int_) <=  0;
				break;
			case 4:
				res = O7C_GUARD(Ast_ExprReal_s, &v1)->real <= O7C_GUARD(Ast_ExprReal_s, &v2)->real;
				break;
			case 5:
				res = O7C_GUARD(Ast_ExprSet_s, &v1)->set <= O7C_GUARD(Ast_ExprSet_s, &v2)->set;
				break;
			case 7:
				res = false;
				break;
			default:
				abort();
				break;
			}
			break;
		case 25:
			switch (expr1->type->_._.id) {
			case 0:
			case 3:
				res = o7c_cmp(O7C_GUARD(Ast_RExprInteger, &v1)->int_, O7C_GUARD(Ast_RExprInteger, &v2)->int_) >  0;
				break;
			case 4:
				res = O7C_GUARD(Ast_ExprReal_s, &v1)->real > O7C_GUARD(Ast_ExprReal_s, &v2)->real;
				break;
			case 7:
				res = false;
				break;
			default:
				abort();
				break;
			}
			break;
		case 26:
			switch (expr1->type->_._.id) {
			case 0:
			case 3:
				res = o7c_cmp(O7C_GUARD(Ast_RExprInteger, &v1)->int_, O7C_GUARD(Ast_RExprInteger, &v2)->int_) >=  0;
				break;
			case 4:
				res = O7C_GUARD(Ast_ExprReal_s, &v1)->real >= O7C_GUARD(Ast_ExprReal_s, &v2)->real;
				break;
			case 5:
				res = O7C_GUARD(Ast_ExprSet_s, &v1)->set >= O7C_GUARD(Ast_ExprSet_s, &v2)->set;
				break;
			case 7:
				res = false;
				break;
			default:
				abort();
				break;
			}
			break;
		case 27:
			res = o7c_in(O7C_GUARD(Ast_RExprInteger, &v1)->int_, O7C_GUARD(Ast_ExprSet_s, &v2)->set);
			break;
		default:
			abort();
			break;
		}
		O7C_ASSIGN(&(*e)->_.value_, (&(Ast_ExprBooleanNew(res))->_));
	}
	o7c_return = err;
	o7c_release(v1); o7c_release(v2);
	o7c_release(expr1); o7c_release(expr2);
	return o7c_return;
}

static int LexToSign(int lex) {
	int o7c_return;

	int s = O7C_INT_UNDEF;

	if ((o7c_cmp(lex,  - 1) ==  0) || (o7c_cmp(lex, Scanner_Plus_cnst) ==  0)) {
		s =  + 1;
	} else {
		assert(o7c_cmp(lex, Scanner_Minus_cnst) ==  0);
		s =  - 1;
	}
	o7c_return = s;
	return o7c_return;
}

static void ExprSumCreate(struct Ast_ExprSum_s **e, int add, struct Ast_RExpression *sum, struct Ast_RExpression *term) {
	struct Ast_RType *t = NULL;

	o7c_retain(sum); o7c_retain(term);
	O7C_NEW(&(*e), Ast_ExprSum_s_tag);
	if ((sum != NULL) && (sum->type != NULL) && (o7c_in(sum->type->_._.id, ((1 << Ast_IdReal_cnst) | (1 << Ast_IdInteger_cnst))))) {
		O7C_ASSIGN(&t, sum->type);
	} else if (term != NULL) {
		O7C_ASSIGN(&t, term->type);
	} else {
		O7C_NULL(&t);
	}
	ExprInit(&(*e)->_, Ast_IdSum_cnst, t);
	O7C_NULL(&(*e)->next);
	(*e)->add = add;
	O7C_ASSIGN(&(*e)->term, term);
	o7c_release(t);
	o7c_release(sum); o7c_release(term);
}

extern int Ast_ExprSumNew(struct Ast_ExprSum_s **e, int add, struct Ast_RExpression *term) {
	int o7c_return;

	int err = O7C_INT_UNDEF;

	o7c_retain(term);
	assert((o7c_cmp(add,  - 1) ==  0) || (o7c_cmp(add, Scanner_Plus_cnst) ==  0) || (o7c_cmp(add, Scanner_Minus_cnst) ==  0));
	ExprSumCreate(&(*e), add, NULL, term);
	err = Ast_ErrNo_cnst;
	if ((*e)->_.type != NULL) {
		if (!(o7c_in((*e)->_.type->_._.id, ((1 << Ast_IdInteger_cnst) | (1 << Ast_IdReal_cnst) | (1 << Ast_IdSet_cnst)))) && (o7c_cmp(add,  - 1) !=  0)) {
			if (o7c_cmp((*e)->_.type->_._.id, Ast_IdBoolean_cnst) !=  0) {
				err = Ast_ErrNotNumberAndNotSetInAdd_cnst;
			} else {
				err = Ast_ErrSignForBool_cnst;
			}
		} else if (term->value_ != NULL) {
			switch ((*e)->_.type->_._.id) {
			case 0:
				O7C_ASSIGN(&(*e)->_.value_, (&(Ast_ExprIntegerNew(o7c_mul(O7C_GUARD(Ast_RExprInteger, &term->value_)->int_, LexToSign(add))))->_._));
				break;
			case 4:
				O7C_ASSIGN(&(*e)->_.value_, (&(Ast_ExprRealNewByValue(o7c_fmul(O7C_GUARD(Ast_ExprReal_s, &term->value_)->real, (double)LexToSign(add))))->_._));
				break;
			case 5:
				if (o7c_cmp(add, Scanner_Minus_cnst) !=  0) {
					O7C_ASSIGN(&(*e)->_.value_, (&(Ast_ExprSetByValue(O7C_GUARD(Ast_ExprSet_s, &term->value_)->set))->_));
				} else {
					O7C_ASSIGN(&(*e)->_.value_, (&(Ast_ExprSetByValue( ~O7C_GUARD(Ast_ExprSet_s, &term->value_)->set))->_));
				}
				break;
			case 1:
				O7C_ASSIGN(&(*e)->_.value_, (&(Ast_ExprBooleanNew(O7C_GUARD(Ast_ExprBoolean_s, &term->value_)->bool_))->_));
				break;
			default:
				abort();
				break;
			}
		}
	}
	o7c_return = err;
	o7c_release(term);
	return o7c_return;
}

static o7c_bool ExprSumAdd_CheckType(struct Ast_RExpression *e1, struct Ast_RExpression *e2, int add, int *err) {
	o7c_bool o7c_return;

	o7c_bool continue_ = O7C_BOOL_UNDEF;

	o7c_retain(e1); o7c_retain(e2);
	if ((e1->type == NULL) || (e2->type == NULL)) {
		continue_ = false;
	} else if (o7c_cmp(e1->type->_._.id, e2->type->_._.id) !=  0) {
		(*err) = Ast_ErrAddExprDifferenTypes_cnst;
		continue_ = false;
	} else if (o7c_cmp(add, Scanner_Or_cnst) ==  0) {
		continue_ = o7c_cmp(e1->type->_._.id, Ast_IdBoolean_cnst) ==  0;
		if (!continue_) {
			(*err) = Ast_ErrNotBoolInLogicExpr_cnst;
		}
	} else {
		continue_ = o7c_in(e1->type->_._.id, ((1 << Ast_IdInteger_cnst) | (1 << Ast_IdReal_cnst) | (1 << Ast_IdSet_cnst)));
		if (!continue_) {
			(*err) = Ast_ErrNotNumberAndNotSetInAdd_cnst;
		}
	}
	o7c_return = o7c_bl(continue_);
	o7c_release(e1); o7c_release(e2);
	return o7c_return;
}

extern int Ast_ExprSumAdd(struct Ast_RExpression *fullSum, struct Ast_ExprSum_s **lastAdder, int add, struct Ast_RExpression *term) {
	int o7c_return;

	struct Ast_ExprSum_s *e = NULL;
	int err = O7C_INT_UNDEF;

	o7c_retain(fullSum); o7c_retain(term);
	assert((o7c_cmp(add, Scanner_Plus_cnst) ==  0) || (o7c_cmp(add, Scanner_Minus_cnst) ==  0) || (o7c_cmp(add, Scanner_Or_cnst) ==  0));
	ExprSumCreate(&e, add, fullSum, term);
	err = Ast_ErrNo_cnst;
	if ((fullSum != NULL) && (term != NULL) && ExprSumAdd_CheckType(fullSum, term, add, &err) && (fullSum->value_ != NULL) && (term->value_ != NULL)) {
		if (o7c_cmp(add, Scanner_Or_cnst) ==  0) {
			if (O7C_GUARD(Ast_ExprBoolean_s, &term->value_)->bool_) {
				O7C_GUARD(Ast_ExprBoolean_s, &fullSum->value_)->bool_ = true;
			}
		} else {
			switch (term->type->_._.id) {
			case 0:
				if (!Arithmetic_Add(&O7C_GUARD(Ast_RExprInteger, &fullSum->value_)->int_, O7C_GUARD(Ast_RExprInteger, &fullSum->value_)->int_, o7c_mul(O7C_GUARD(Ast_RExprInteger, &term->value_)->int_, LexToSign(add)))) {
					err = o7c_add(Ast_ErrConstAddOverflow_cnst, (int)(o7c_cmp(add, Scanner_Minus_cnst) ==  0));
				}
				break;
			case 4:
				O7C_GUARD(Ast_ExprReal_s, &fullSum->value_)->real = o7c_fadd(O7C_GUARD(Ast_ExprReal_s, &fullSum->value_)->real, o7c_fmul(O7C_GUARD(Ast_ExprReal_s, &term->value_)->real, (double)LexToSign(add)));
				break;
			case 5:
				if (o7c_cmp(add, Scanner_Plus_cnst) ==  0) {
					O7C_GUARD(Ast_ExprSet_s, &fullSum->value_)->set = O7C_GUARD(Ast_ExprSet_s, &fullSum->value_)->set | O7C_GUARD(Ast_ExprSet_s, &term->value_)->set;
				} else {
					O7C_GUARD(Ast_ExprSet_s, &fullSum->value_)->set = O7C_GUARD(Ast_ExprSet_s, &fullSum->value_)->set & ~O7C_GUARD(Ast_ExprSet_s, &term->value_)->set;
				}
				break;
			default:
				abort();
				break;
			}
		}
	} else if (fullSum != NULL) {
		O7C_NULL(&fullSum->value_);
	}
	if ((*lastAdder) != NULL) {
		O7C_ASSIGN(&(*lastAdder)->next, e);
	}
	O7C_ASSIGN(&(*lastAdder), e);
	o7c_return = err;
	o7c_release(e);
	o7c_release(fullSum); o7c_release(term);
	return o7c_return;
}

static int MultCalc(struct Ast_RExpression *res, struct Ast_RExpression *a, int mult, struct Ast_RExpression *b);
static o7c_bool MultCalc_CheckType(struct Ast_RExpression *e1, struct Ast_RExpression *e2, int mult, int *err) {
	o7c_bool o7c_return;

	o7c_bool continue_ = O7C_BOOL_UNDEF;

	o7c_retain(e1); o7c_retain(e2);
	if ((e1->type == NULL) || (e2->type == NULL)) {
		continue_ = false;
	} else if (o7c_cmp(e1->type->_._.id, e2->type->_._.id) !=  0) {
		continue_ = false;
		if (o7c_cmp(mult, Scanner_And_cnst) ==  0) {
			(*err) = Ast_ErrNotBoolInLogicExpr_cnst;
		} else if (o7c_cmp(mult, Scanner_Asterisk_cnst) ==  0) {
			(*err) = Ast_ErrMultExprDifferentTypes_cnst;
		} else {
			(*err) = Ast_ErrDivExprDifferentTypes_cnst;
		}
	} else if (o7c_cmp(mult, Scanner_And_cnst) ==  0) {
		continue_ = o7c_cmp(e1->type->_._.id, Ast_IdBoolean_cnst) ==  0;
		if (!continue_) {
			(*err) = Ast_ErrNotBoolInLogicExpr_cnst;
		}
	} else if (!(o7c_in(e1->type->_._.id, ((1 << Ast_IdInteger_cnst) | (1 << Ast_IdReal_cnst) | (1 << Ast_IdSet_cnst))))) {
		continue_ = false;
		(*err) = Ast_ErrNotNumberAndNotSetInMult_cnst;
	} else if ((o7c_cmp(mult, Scanner_Div_cnst) ==  0) || (o7c_cmp(mult, Scanner_Mod_cnst) ==  0)) {
		continue_ = o7c_cmp(e1->type->_._.id, Ast_IdInteger_cnst) ==  0;
		if (!continue_) {
			(*err) = Ast_ErrNotIntInDivOrMod_cnst;
		}
	} else if ((o7c_cmp(mult, Scanner_Slash_cnst) ==  0) && (o7c_cmp(e1->type->_._.id, Ast_IdInteger_cnst) ==  0)) {
		continue_ = false;
		(*err) = Ast_ErrNotRealTypeForRealDiv_cnst;
	} else {
		continue_ = true;
	}
	o7c_return = o7c_bl(continue_);
	o7c_release(e1); o7c_release(e2);
	return o7c_return;
}

static void MultCalc_Int(struct Ast_RExpression *res, struct Ast_RExpression *a, int mult, struct Ast_RExpression *b, int *err) {
	int i = O7C_INT_UNDEF, i1 = O7C_INT_UNDEF, i2 = O7C_INT_UNDEF;

	o7c_retain(res); o7c_retain(a); o7c_retain(b);
	i1 = O7C_GUARD(Ast_RExprInteger, &a->value_)->int_;
	i2 = O7C_GUARD(Ast_RExprInteger, &b->value_)->int_;
	if (o7c_cmp(mult, Scanner_Asterisk_cnst) ==  0) {
		if (!Arithmetic_Mul(&i, i1, i2)) {
			(*err) = Ast_ErrConstMultOverflow_cnst;
		}
	} else if (o7c_cmp(i2, 0) ==  0) {
		(*err) = Ast_ErrConstDivByZero_cnst;
		O7C_NULL(&res->value_);
	} else if (o7c_cmp(mult, Scanner_Div_cnst) ==  0) {
		i = o7c_div(i1, i2);
	} else {
		i = o7c_mod(i1, i2);
	}
	if (o7c_cmp((*err), Ast_ErrNo_cnst) ==  0) {
		if (res->value_ == NULL) {
			O7C_ASSIGN(&res->value_, (&(Ast_ExprIntegerNew(i))->_._));
		} else {
			O7C_GUARD(Ast_RExprInteger, &res->value_)->int_ = i;
		}
	}
	o7c_release(res); o7c_release(a); o7c_release(b);
}

static void MultCalc_Rl(struct Ast_RExpression *res, struct Ast_RExpression *a, int mult, struct Ast_RExpression *b) {
	double r = O7C_DBL_UNDEF, r1 = O7C_DBL_UNDEF, r2 = O7C_DBL_UNDEF;

	o7c_retain(res); o7c_retain(a); o7c_retain(b);
	r1 = O7C_GUARD(Ast_ExprReal_s, &a->value_)->real;
	r2 = O7C_GUARD(Ast_ExprReal_s, &b->value_)->real;
	if (o7c_cmp(mult, Scanner_Asterisk_cnst) ==  0) {
		r = o7c_fmul(r1, r2);
	} else {
		r = o7c_fdiv(r1, r2);
	}
	if (res->value_ == NULL) {
		O7C_ASSIGN(&res->value_, (&(Ast_ExprRealNewByValue(r))->_._));
	} else {
		O7C_GUARD(Ast_ExprReal_s, &res->value_)->real = r;
	}
	o7c_release(res); o7c_release(a); o7c_release(b);
}

static void MultCalc_St(struct Ast_RExpression *res, struct Ast_RExpression *a, int mult, struct Ast_RExpression *b) {
	unsigned s = 0, s1 = 0, s2 = 0;

	o7c_retain(res); o7c_retain(a); o7c_retain(b);
	s1 = O7C_GUARD(Ast_ExprSet_s, &a->value_)->set;
	s2 = O7C_GUARD(Ast_ExprSet_s, &b->value_)->set;
	if (o7c_cmp(mult, Scanner_Asterisk_cnst) ==  0) {
		s = s1 & s2;
	} else {
		s = s1 ^ s2;
	}
	if (res->value_ == NULL) {
		O7C_ASSIGN(&res->value_, (&(Ast_ExprSetByValue(s))->_));
	} else {
		O7C_GUARD(Ast_ExprSet_s, &res->value_)->set = s;
	}
	o7c_release(res); o7c_release(a); o7c_release(b);
}

static int MultCalc(struct Ast_RExpression *res, struct Ast_RExpression *a, int mult, struct Ast_RExpression *b) {
	int o7c_return;

	int err = O7C_INT_UNDEF;
	o7c_bool bool_ = O7C_BOOL_UNDEF;

	o7c_retain(res); o7c_retain(a); o7c_retain(b);
	err = Ast_ErrNo_cnst;
	if (MultCalc_CheckType(a, b, mult, &err) && (a->value_ != NULL) && (b->value_ != NULL)) {
		switch (a->type->_._.id) {
		case 0:
			MultCalc_Int(res, a, mult, b, &err);
			break;
		case 4:
			MultCalc_Rl(res, a, mult, b);
			break;
		case 1:
			bool_ = o7c_bl(O7C_GUARD(Ast_ExprBoolean_s, &a->value_)->bool_) && o7c_bl(O7C_GUARD(Ast_ExprBoolean_s, &b->value_)->bool_);
			if (res->value_ == NULL) {
				O7C_ASSIGN(&res->value_, (&(Ast_ExprBooleanNew(bool_))->_));
			} else {
				O7C_GUARD(Ast_ExprBoolean_s, &res->value_)->bool_ = bool_;
			}
			break;
		case 5:
			MultCalc_St(res, a, mult, b);
			break;
		default:
			abort();
			break;
		}
	} else {
		O7C_NULL(&res->value_);
		if ((o7c_in((o7c_sub(mult, Scanner_Div_cnst)), ((1 << 0) | (1 << 1)))) && (b->value_ != NULL) && (o7c_cmp(b->value_->_.type->_._.id, Ast_IdInteger_cnst) ==  0) && (o7c_cmp(O7C_GUARD(Ast_RExprInteger, &b->value_)->int_, 0) ==  0)) {
			err = Ast_ErrConstDivByZero_cnst;
		}
	}
	o7c_return = err;
	o7c_release(res); o7c_release(a); o7c_release(b);
	return o7c_return;
}

static int ExprTermGeneral(struct Ast_ExprTerm_s **e, struct Ast_RExpression *result, struct Ast_RFactor *factor, int mult, struct Ast_RExpression *factorOrTerm) {
	int o7c_return;

	o7c_retain(result); o7c_retain(factor); o7c_retain(factorOrTerm);
	assert((o7c_cmp(mult, Scanner_MultFirst_cnst) >=  0) && (o7c_cmp(mult, Scanner_MultLast_cnst) <=  0));
	assert((o7c_is(NULL, factorOrTerm, Ast_RFactor_tag)) || (o7c_is(NULL, factorOrTerm, Ast_ExprTerm_s_tag)));
	O7C_NEW(&(*e), Ast_ExprTerm_s_tag);
	ExprInit(&(*e)->_, Ast_IdTerm_cnst, factorOrTerm->type);
	O7C_ASSIGN(&(*e)->factor, factor);
	(*e)->mult = mult;
	O7C_ASSIGN(&(*e)->expr, factorOrTerm);
	if (result == NULL) {
		O7C_ASSIGN(&result, (&((*e))->_));
	}
	O7C_ASSIGN(&(*e)->factor, factor);
	o7c_return = MultCalc(result, &factor->_, mult, factorOrTerm);
	o7c_release(result); o7c_release(factor); o7c_release(factorOrTerm);
	return o7c_return;
}

extern int Ast_ExprTermNew(struct Ast_ExprTerm_s **e, struct Ast_RFactor *factor, int mult, struct Ast_RExpression *factorOrTerm) {
	int o7c_return;

	o7c_retain(factor); o7c_retain(factorOrTerm);
	o7c_return = ExprTermGeneral(&(*e), &(*e)->_, factor, mult, factorOrTerm);
	o7c_release(factor); o7c_release(factorOrTerm);
	return o7c_return;
}

extern int Ast_ExprTermAdd(struct Ast_RExpression *fullTerm, struct Ast_ExprTerm_s **lastTerm, int mult, struct Ast_RExpression *factorOrTerm) {
	int o7c_return;

	struct Ast_ExprTerm_s *e = NULL;
	int err = O7C_INT_UNDEF;

	o7c_retain(fullTerm); o7c_retain(factorOrTerm);
	if ((*lastTerm) != NULL) {
		assert((*lastTerm)->expr != NULL);
		err = ExprTermGeneral(&e, fullTerm, O7C_GUARD(Ast_RFactor, &(*lastTerm)->expr), mult, factorOrTerm);
		O7C_ASSIGN(&(*lastTerm)->expr, (&(e)->_));
		O7C_ASSIGN(&(*lastTerm), e);
	} else {
		err = ExprTermGeneral(&(*lastTerm), fullTerm, NULL, mult, factorOrTerm);
	}
	o7c_return = err;
	o7c_release(e);
	o7c_release(fullTerm); o7c_release(factorOrTerm);
	return o7c_return;
}

static int ExprCallCreate(struct Ast_ExprCall_s **e, struct Ast_Designator_s *des, o7c_bool func_) {
	int o7c_return;

	int err = O7C_INT_UNDEF;
	struct Ast_RType *t = NULL;
	struct Ast_ProcType_s *pt = NULL;

	o7c_retain(des);
	O7C_NULL(&t);
	err = Ast_ErrNo_cnst;
	if (des != NULL) {
		Log_Str("ExprCallCreate des.decl.id = ", 30);
		Log_Int(des->decl->_.id);
		Log_Ln();
		if (o7c_cmp(des->decl->_.id, Ast_IdError_cnst) ==  0) {
			O7C_ASSIGN(&pt, Ast_ProcTypeNew());
			O7C_ASSIGN(&des->decl->type, (&(pt)->_._));
			O7C_ASSIGN(&des->_._.type, (&(pt)->_._));
		} else if (des->_._.type != NULL) {
			if (o7c_is(NULL, des->_._.type, Ast_ProcType_s_tag)) {
				O7C_ASSIGN(&t, des->_._.type->_.type);
				if ((t != NULL) != func_) {
					err = o7c_add(Ast_ErrCallIgnoredReturn_cnst, (int)func_);
				}
			} else {
				err = Ast_ErrCallNotProc_cnst;
			}
		}
	}
	O7C_NEW(&(*e), Ast_ExprCall_s_tag);
	ExprInit(&(*e)->_._, Ast_IdCall_cnst, t);
	O7C_ASSIGN(&(*e)->designator, des);
	O7C_NULL(&(*e)->params);
	o7c_return = err;
	o7c_release(t); o7c_release(pt);
	o7c_release(des);
	return o7c_return;
}

extern int Ast_ExprCallNew(struct Ast_ExprCall_s **e, struct Ast_Designator_s *des) {
	int o7c_return;

	o7c_retain(des);
	o7c_return = ExprCallCreate(&(*e), des, true);
	o7c_release(des);
	return o7c_return;
}

extern o7c_bool Ast_IsChangeable(struct Ast_RModule *cur, struct Ast_RVar *v) {
	o7c_bool o7c_return;

	o7c_retain(cur); o7c_retain(v);
	Log_StrLn("IsChangeable", 13);
	o7c_return = (!(o7c_is(NULL, v, Ast_FormalParam_s_tag)) || (O7C_GUARD(Ast_FormalParam_s, &v)->isVar) || !((o7c_is(NULL, v->_.type, Ast_RArray_tag)) || (o7c_is(NULL, v->_.type, Ast_Record_s_tag))));
	o7c_release(cur); o7c_release(v);
	return o7c_return;
}

extern o7c_bool Ast_IsVar(struct Ast_RExpression *e) {
	o7c_bool o7c_return;

	o7c_retain(e);
	Log_Str("IsVar: e.id = ", 15);
	Log_Int(e->_.id);
	Log_Ln();
	o7c_return = (o7c_is(NULL, e, Ast_Designator_s_tag)) && (o7c_is(NULL, O7C_GUARD(Ast_Designator_s, &e)->decl, Ast_RVar_tag));
	o7c_release(e);
	return o7c_return;
}

extern int Ast_ProcedureAdd(struct Ast_RDeclarations *ds, struct Ast_RProcedure **p, o7c_char buf[/*len0*/], int buf_len0, int begin, int end) {
	int o7c_return;

	int err = O7C_INT_UNDEF;

	o7c_retain(ds);
	if (SearchName(ds->start, buf, buf_len0, begin, end) == NULL) {
		err = Ast_ErrNo_cnst;
	} else {
		err = Ast_ErrDeclarationNameDuplicate_cnst;
	}
	O7C_NEW(&(*p), Ast_RProcedure_tag);
	NodeInit(&(*(*p))._._._._, Ast_RProcedure_tag);
	DeclarationsConnect(&(*p)->_._, ds, buf, buf_len0, begin, end);
	O7C_ASSIGN(&(*p)->_.header, Ast_ProcTypeNew());
	(*p)->_._._._.id = Ast_IdProcType_cnst;
	O7C_NULL(&(*p)->_.return_);
	if (ds->procedures == NULL) {
		O7C_ASSIGN(&ds->procedures, (*p));
	}
	o7c_return = err;
	o7c_release(ds);
	return o7c_return;
}

extern int Ast_ProcedureSetReturn(struct Ast_RProcedure *p, struct Ast_RExpression *e) {
	int o7c_return;

	int err = O7C_INT_UNDEF;

	o7c_retain(p); o7c_retain(e);
	assert(p->_.return_ == NULL);
	err = Ast_ErrNo_cnst;
	if (p->_.header->_._._.type == NULL) {
		err = Ast_ErrProcHasNoReturn_cnst;
	} else if (e != NULL) {
		O7C_ASSIGN(&p->_.return_, e);
		if (!Ast_CompatibleTypes(&p->distance, p->_.header->_._._.type, e->type) && !CompatibleAsCharAndString(p->_.header->_._._.type, &p->_.return_)) {
			err = Ast_ErrReturnIncompatibleType_cnst;
		}
	}
	o7c_return = err;
	o7c_release(p); o7c_release(e);
	return o7c_return;
}

extern int Ast_ProcedureEnd(struct Ast_RProcedure *p) {
	int o7c_return;

	int err = O7C_INT_UNDEF;

	o7c_retain(p);
	if ((p->_.header->_._._.type != NULL) && (p->_.return_ == NULL)) {
		err = Ast_ErrExpectReturn_cnst;
	} else {
		err = Ast_ErrNo_cnst;
	}
	o7c_return = err;
	o7c_release(p);
	return o7c_return;
}

static o7c_bool CallParamNew_TypeVariation(struct Ast_ExprCall_s *call, struct Ast_RType *tp, struct Ast_FormalParam_s *fp) {
	o7c_bool o7c_return;

	o7c_bool comp = O7C_BOOL_UNDEF;
	int id = O7C_INT_UNDEF;

	o7c_retain(call); o7c_retain(tp); o7c_retain(fp);
	comp = o7c_is(NULL, call->designator->decl, Ast_PredefinedProcedure_s_tag);
	if (comp) {
		id = call->designator->decl->_.id;
		if (o7c_cmp(id, Scanner_New_cnst) ==  0) {
			comp = o7c_cmp(tp->_._.id, Ast_IdPointer_cnst) ==  0;
		} else if (o7c_cmp(id, Scanner_Abs_cnst) ==  0) {
			comp = o7c_in(tp->_._.id, ((1 << Ast_IdInteger_cnst) | (1 << Ast_IdReal_cnst)));
			O7C_ASSIGN(&call->_._.type, tp);
		} else if (o7c_cmp(id, Scanner_Len_cnst) ==  0) {
			comp = o7c_cmp(tp->_._.id, Ast_IdArray_cnst) ==  0;
		} else {
			comp = (o7c_cmp(id, Scanner_Ord_cnst) ==  0) && (o7c_in(tp->_._.id, ((1 << Ast_IdInteger_cnst) | (1 << Ast_IdChar_cnst) | (1 << Ast_IdSet_cnst) | (1 << Ast_IdBoolean_cnst))));
		}
	}
	o7c_return = o7c_bl(comp);
	o7c_release(call); o7c_release(tp); o7c_release(fp);
	return o7c_return;
}

static void CallParamNew_ParamsVariation(struct Ast_ExprCall_s *call, struct Ast_RExpression *e, int *err) {
	int id = O7C_INT_UNDEF;

	o7c_retain(call); o7c_retain(e);
	id = call->designator->decl->_.id;
	if (o7c_cmp(id, Ast_IdError_cnst) !=  0) {
		if ((o7c_cmp(id, Scanner_Inc_cnst) !=  0) && (o7c_cmp(id, Scanner_Dec_cnst) !=  0) || (call->params->next != NULL)) {
			(*err) = Ast_ErrCallExcessParam_cnst;
		} else if (o7c_cmp(e->type->_._.id, Ast_IdInteger_cnst) !=  0) {
			(*err) = Ast_ErrCallIncompatibleParamType_cnst;
		}
	}
	o7c_release(call); o7c_release(e);
}

extern int Ast_CallParamNew(struct Ast_ExprCall_s *call, struct Ast_Parameter_s **lastParam, struct Ast_RExpression *e, struct Ast_FormalParam_s **currentFormalParam) {
	int o7c_return;

	int err = O7C_INT_UNDEF, distance = O7C_INT_UNDEF;

	o7c_retain(call); o7c_retain(e);
	err = Ast_ErrNo_cnst;
	if ((*currentFormalParam) != NULL) {
		if (!Ast_CompatibleTypes(&distance, (*currentFormalParam)->_._.type, e->type) && !CompatibleAsCharAndString((*currentFormalParam)->_._.type, &e) && !CallParamNew_TypeVariation(call, e->type, (*currentFormalParam))) {
			err = Ast_ErrCallIncompatibleParamType_cnst;
		} else if ((*currentFormalParam)->isVar) {
			if (!(Ast_IsVar(e) && Ast_IsChangeable(call->designator->decl->module, O7C_GUARD(Ast_RVar, &O7C_GUARD(Ast_Designator_s, &e)->decl)))) {
				err = Ast_ErrCallExpectVarParam_cnst;
			} else if ((e->type != NULL) && (o7c_cmp(e->type->_._.id, Ast_IdPointer_cnst) ==  0) && (e->type != (*currentFormalParam)->_._.type) && ((*currentFormalParam)->_._.type != NULL) && ((*currentFormalParam)->_._.type->_.type != NULL) && (e->type->_.type != NULL)) {
				err = Ast_ErrCallVarPointerTypeNotSame_cnst;
			}
		}
		if (((*currentFormalParam)->_._.next != NULL) && (o7c_is(NULL, (*currentFormalParam)->_._.next, Ast_FormalParam_s_tag))) {
			O7C_ASSIGN(&(*currentFormalParam), O7C_GUARD(Ast_FormalParam_s, &(*currentFormalParam)->_._.next));
		} else {
			O7C_NULL(&(*currentFormalParam));
		}
	} else {
		distance = 0;
		CallParamNew_ParamsVariation(call, e, &err);
	}
	if ((*lastParam) == NULL) {
		O7C_NEW(&(*lastParam), Ast_Parameter_s_tag);
	} else {
		assert((*lastParam)->next == NULL);
		O7C_NEW(&(*lastParam)->next, Ast_Parameter_s_tag);
		O7C_ASSIGN(&(*lastParam), (*lastParam)->next);
	}
	NodeInit(&(*(*lastParam))._, Ast_Parameter_s_tag);
	O7C_ASSIGN(&(*lastParam)->expr, e);
	(*lastParam)->distance = distance;
	O7C_NULL(&(*lastParam)->next);
	o7c_return = err;
	o7c_release(call); o7c_release(e);
	return o7c_return;
}

extern int Ast_CallParamsEnd(struct Ast_ExprCall_s *call, struct Ast_FormalParam_s *currentFormalParam) {
	int o7c_return;

	struct Ast_RFactor *v = NULL;

	o7c_retain(call); o7c_retain(currentFormalParam);
	if ((currentFormalParam == NULL) && (o7c_is(NULL, call->designator->decl, Ast_PredefinedProcedure_s_tag)) && (call->designator->decl->type->_.type != NULL)) {
		O7C_ASSIGN(&v, call->params->expr->value_);
		if (v != NULL) {
			switch (call->designator->decl->_.id) {
			case 90:
				if (o7c_cmp(v->_.type->_._.id, Ast_IdReal_cnst) ==  0) {
					if (O7C_GUARD(Ast_ExprReal_s, &v)->real < 0.0) {
						O7C_ASSIGN(&call->_._.value_, (&(Ast_ExprRealNewByValue(o7c_fsub(0, O7C_GUARD(Ast_ExprReal_s, &v)->real)))->_._));
					} else {
						O7C_ASSIGN(&call->_._.value_, v);
					}
				} else {
					assert(o7c_cmp(v->_.type->_._.id, Ast_IdInteger_cnst) ==  0);
					O7C_ASSIGN(&call->_._.value_, (&(Ast_ExprIntegerNew(abs(O7C_GUARD(Ast_RExprInteger, &v)->int_)))->_._));
				}
				break;
			case 107:
				O7C_ASSIGN(&call->_._.value_, (&(Ast_ExprBooleanNew((O7C_GUARD(Ast_RExprInteger, &v)->int_ % 2 == 1)))->_));
				break;
			case 105:
				if (call->params->next->expr->value_ != NULL) {
					O7C_ASSIGN(&call->_._.value_, (&(Ast_ExprIntegerNew((int)((unsigned)O7C_GUARD(Ast_RExprInteger, &v)->int_ << O7C_GUARD(Ast_RExprInteger, &call->params->next->expr->value_)->int_)))->_._));
				}
				break;
			case 91:
				if (call->params->next->expr->value_ != NULL) {
					O7C_ASSIGN(&call->_._.value_, (&(Ast_ExprIntegerNew((int)((unsigned)O7C_GUARD(Ast_RExprInteger, &v)->int_ >> O7C_GUARD(Ast_RExprInteger, &call->params->next->expr->value_)->int_)))->_._));
				}
				break;
			case 111:
				if (call->params->next->expr->value_ != NULL) {
					O7C_ASSIGN(&call->_._.value_, (&(Ast_ExprIntegerNew((int)((unsigned)O7C_GUARD(Ast_RExprInteger, &v)->int_ >> O7C_GUARD(Ast_RExprInteger, &call->params->next->expr->value_)->int_)))->_._));
				}
				break;
			case 99:
				O7C_ASSIGN(&call->_._.value_, (&(Ast_ExprIntegerNew((int)O7C_GUARD(Ast_ExprReal_s, &v)->real))->_._));
				break;
			case 100:
				O7C_ASSIGN(&call->_._.value_, (&(Ast_ExprRealNewByValue((double)O7C_GUARD(Ast_RExprInteger, &v)->int_))->_._));
				break;
			case 108:
				if (o7c_cmp(v->_.type->_._.id, Ast_IdChar_cnst) ==  0) {
					O7C_ASSIGN(&call->_._.value_, v);
				} else if (o7c_is(NULL, v, Ast_ExprString_s_tag)) {
					if (o7c_cmp(O7C_GUARD(Ast_ExprString_s, &v)->_.int_,  - 1) >  0) {
						O7C_ASSIGN(&call->_._.value_, (&(Ast_ExprIntegerNew(O7C_GUARD(Ast_ExprString_s, &v)->_.int_))->_._));
					} else {
						assert(false);
					}
				} else if (o7c_cmp(v->_.type->_._.id, Ast_IdBoolean_cnst) ==  0) {
					O7C_ASSIGN(&call->_._.value_, (&(Ast_ExprIntegerNew((int)O7C_GUARD(Ast_ExprBoolean_s, &v)->bool_))->_._));
				} else if (o7c_cmp(v->_.type->_._.id, Ast_IdSet_cnst) ==  0) {
					O7C_ASSIGN(&call->_._.value_, (&(Ast_ExprIntegerNew((int)O7C_GUARD(Ast_ExprSet_s, &v)->set))->_._));
				} else {
					Log_Str("Неправильный id типа = ", 40);
					Log_Int(v->_.type->_._.id);
					Log_Ln();
					assert(false);
				}
				break;
			case 96:
				O7C_ASSIGN(&call->_._.value_, v);
				break;
			default:
				abort();
				break;
			}
		} else if ((o7c_cmp(call->designator->decl->_.id, Scanner_Len_cnst) ==  0) && (O7C_GUARD(Ast_RArray, &call->params->expr->type)->count != NULL)) {
			O7C_ASSIGN(&call->_._.value_, O7C_GUARD(Ast_RArray, &call->params->expr->type)->count->value_);
		}
	}
	o7c_return = o7c_mul((int)(currentFormalParam != NULL), Ast_ErrCallParamsNotEnough_cnst);
	o7c_release(v);
	o7c_release(call); o7c_release(currentFormalParam);
	return o7c_return;
}

static void StatInit(struct Ast_RStatement *s, struct Ast_RExpression *e) {
	o7c_retain(s); o7c_retain(e);
	NodeInit(&(*s)._, Ast_RStatement_tag);
	O7C_ASSIGN(&s->expr, e);
	O7C_NULL(&s->next);
	o7c_release(s); o7c_release(e);
}

extern int Ast_CallNew(struct Ast_Call_s **c, struct Ast_Designator_s *des) {
	int o7c_return;

	int err = O7C_INT_UNDEF;
	struct Ast_ExprCall_s *e = NULL;

	o7c_retain(des);
	err = ExprCallCreate(&e, des, false);
	O7C_NEW(&(*c), Ast_Call_s_tag);
	StatInit(&(*c)->_, &e->_._);
	o7c_return = err;
	o7c_release(e);
	o7c_release(des);
	return o7c_return;
}

extern int Ast_IfNew(struct Ast_If_s **if_, struct Ast_RExpression *expr, struct Ast_RStatement *stats) {
	int o7c_return;

	int err = O7C_INT_UNDEF;

	o7c_retain(expr); o7c_retain(stats);
	O7C_NEW(&(*if_), Ast_If_s_tag);
	StatInit(&(*if_)->_._, expr);
	O7C_ASSIGN(&(*if_)->_.stats, stats);
	O7C_NULL(&(*if_)->_.elsif);
	if ((expr != NULL) && (o7c_cmp(expr->type->_._.id, Ast_IdBoolean_cnst) !=  0)) {
		err = Ast_ErrNotBoolInIfCondition_cnst;
	} else {
		err = Ast_ErrNo_cnst;
	}
	o7c_return = err;
	o7c_release(expr); o7c_release(stats);
	return o7c_return;
}

static void CheckCondition(int *err, struct Ast_RExpression *expr, int adder) {
	o7c_retain(expr);
	(*err) = Ast_ErrNo_cnst;
	if (expr != NULL) {
		if (o7c_cmp(expr->type->_._.id, Ast_IdBoolean_cnst) !=  0) {
			(*err) = o7c_add(Ast_ErrNotBoolInWhileCondition_cnst, adder);
		} else if (expr->value_ != NULL) {
			(*err) = o7c_sub(o7c_add(Ast_ErrWhileConditionAlwaysFalse_cnst, adder), (int)O7C_GUARD(Ast_ExprBoolean_s, &expr->value_)->bool_);
		}
	}
	o7c_release(expr);
}

extern int Ast_WhileNew(struct Ast_While_s **w, struct Ast_RExpression *expr, struct Ast_RStatement *stats) {
	int o7c_return;

	int err = O7C_INT_UNDEF;

	o7c_retain(expr); o7c_retain(stats);
	O7C_NEW(&(*w), Ast_While_s_tag);
	StatInit(&(*w)->_._, expr);
	O7C_ASSIGN(&(*w)->_.stats, stats);
	O7C_NULL(&(*w)->_.elsif);
	CheckCondition(&err, expr, 0);
	o7c_return = err;
	o7c_release(expr); o7c_release(stats);
	return o7c_return;
}

extern int Ast_RepeatNew(struct Ast_Repeat_s **r, struct Ast_RStatement *stats) {
	int o7c_return;

	o7c_retain(stats);
	O7C_NEW(&(*r), Ast_Repeat_s_tag);
	StatInit(&(*r)->_, NULL);
	O7C_ASSIGN(&(*r)->stats, stats);
	o7c_return = Ast_ErrNo_cnst;
	o7c_release(stats);
	return o7c_return;
}

extern int Ast_RepeatSetUntil(struct Ast_Repeat_s *r, struct Ast_RExpression *e) {
	int o7c_return;

	int err = O7C_INT_UNDEF;

	o7c_retain(r); o7c_retain(e);
	assert(r->_.expr == NULL);
	O7C_ASSIGN(&r->_.expr, e);
	CheckCondition(&err, e, Ast_ErrNotBoolInUntil_cnst - Ast_ErrNotBoolInWhileCondition_cnst);
	o7c_return = err;
	o7c_release(r); o7c_release(e);
	return o7c_return;
}

extern struct Ast_For_s *Ast_ForNew(struct Ast_RVar *var_, struct Ast_RExpression *init_, struct Ast_RExpression *to, int by, struct Ast_RStatement *stats) {
	Ast_For o7c_return = NULL;

	struct Ast_For_s *f = NULL;

	o7c_retain(var_); o7c_retain(init_); o7c_retain(to); o7c_retain(stats);
	O7C_NEW(&f, Ast_For_s_tag);
	StatInit(&f->_, init_);
	O7C_ASSIGN(&f->var_, var_);
	O7C_ASSIGN(&f->to, to);
	f->by = by;
	O7C_ASSIGN(&f->stats, stats);
	O7C_ASSIGN(&o7c_return, f);
	o7c_release(f);
	o7c_release(var_); o7c_release(init_); o7c_release(to); o7c_release(stats);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern int Ast_CaseNew(struct Ast_Case_s **case_, struct Ast_RExpression *expr) {
	int o7c_return;

	int err = O7C_INT_UNDEF;

	o7c_retain(expr);
	O7C_NEW(&(*case_), Ast_Case_s_tag);
	StatInit(&(*case_)->_, expr);
	O7C_NULL(&(*case_)->elements);
	if ((expr->type != NULL) && !(o7c_in(expr->type->_._.id, ((1 << Ast_IdInteger_cnst) | (1 << Ast_IdChar_cnst))))) {
		err = Ast_ErrCaseExprNotIntOrChar_cnst;
	} else {
		err = Ast_ErrNo_cnst;
	}
	o7c_return = err;
	o7c_release(expr);
	return o7c_return;
}

extern int Ast_CaseRangeSearch(struct Ast_Case_s *case_, int int_) {
	int o7c_return;

	struct Ast_CaseElement_s *e = NULL;

	o7c_retain(case_);
	assert(false);
	O7C_ASSIGN(&e, case_->elements);
	if (e != NULL) {
		while (e->next != NULL) {
			O7C_ASSIGN(&e, e->next);
		}
		if (e->stats != NULL) {
			O7C_NULL(&e);
		}
	}
	o7c_return = 0;
	o7c_release(e);
	o7c_release(case_);
	return o7c_return;
}

extern int Ast_CaseLabelNew(struct Ast_CaseLabel_s **label, int id, int value_) {
	int o7c_return;

	assert(o7c_in(id, ((1 << Ast_IdInteger_cnst) | (1 << Ast_IdChar_cnst))));
	O7C_NEW(&(*label), Ast_CaseLabel_s_tag);
	NodeInit(&(*(*label))._, Ast_CaseLabel_s_tag);
	O7C_NULL(&(*label)->qual);
	(*label)->_.id = id;
	(*label)->value_ = value_;
	O7C_NULL(&(*label)->right);
	O7C_NULL(&(*label)->next);
	o7c_return = Ast_ErrNo_cnst;
	return o7c_return;
}

extern int Ast_CaseLabelQualNew(struct Ast_CaseLabel_s **label, struct Ast_RDeclaration *decl) {
	int o7c_return;

	int err = O7C_INT_UNDEF, i = O7C_INT_UNDEF;

	o7c_retain(decl);
	if (!(o7c_is(NULL, decl, Ast_Const_s_tag))) {
		err = Ast_ErrCaseLabelNotConst_cnst;
	} else if (!(o7c_in(O7C_GUARD(Ast_Const_s, &decl)->expr->type->_._.id, ((1 << Ast_IdInteger_cnst) | (1 << Ast_IdChar_cnst)))) && !((o7c_is(NULL, O7C_GUARD(Ast_Const_s, &decl)->expr, Ast_ExprString_s_tag)) && (o7c_cmp(O7C_GUARD(Ast_ExprString_s, &O7C_GUARD(Ast_Const_s, &decl)->expr)->_.int_,  - 1) >  0))) {
		err = Ast_ErrCaseLabelNotIntOrChar_cnst;
	} else {
		if (o7c_cmp(O7C_GUARD(Ast_Const_s, &decl)->expr->type->_._.id, Ast_IdInteger_cnst) ==  0) {
			err = Ast_CaseLabelNew(&(*label), Ast_IdInteger_cnst, O7C_GUARD(Ast_RExprInteger, &O7C_GUARD(Ast_Const_s, &decl)->expr->value_)->int_);
		} else {
			i = O7C_GUARD(Ast_ExprString_s, &O7C_GUARD(Ast_Const_s, &decl)->expr->value_)->_.int_;
			if (o7c_cmp(i, 0) <  0) {
				i = (int)O7C_GUARD(Ast_ExprString_s, &O7C_GUARD(Ast_Const_s, &decl)->expr->value_)->string.block->s[0];
			}
			err = Ast_CaseLabelNew(&(*label), Ast_IdChar_cnst, i);
		}
		if ((*label) != NULL) {
			O7C_ASSIGN(&(*label)->qual, decl);
		}
	}
	o7c_return = err;
	o7c_release(decl);
	return o7c_return;
}

extern int Ast_CaseRangeNew(struct Ast_CaseLabel_s *left, struct Ast_CaseLabel_s *right) {
	int o7c_return;

	int err = O7C_INT_UNDEF;

	o7c_retain(left); o7c_retain(right);
	assert((left->right == NULL) && (left->next == NULL));
	assert((right == NULL) || (right->right == NULL) && (right->next == NULL));
	O7C_ASSIGN(&left->right, right);
	if ((right != NULL) && (o7c_cmp(left->_.id, right->_.id) !=  0)) {
		err = Ast_ErrCaseRangeLabelsTypeMismatch_cnst;
	} else if (o7c_cmp(left->value_, right->value_) >=  0) {
		err = Ast_ErrCaseLabelLeftNotLessRight_cnst;
	} else {
		err = Ast_ErrNo_cnst;
	}
	o7c_return = err;
	o7c_release(left); o7c_release(right);
	return o7c_return;
}

static o7c_bool IsRangesCross(struct Ast_CaseLabel_s *l1, struct Ast_CaseLabel_s *l2) {
	o7c_bool o7c_return;

	o7c_bool cross = O7C_BOOL_UNDEF;

	o7c_retain(l1); o7c_retain(l2);
	if (o7c_cmp(l1->value_, l2->value_) <  0) {
		cross = (l1->right != NULL) && (o7c_cmp(l1->right->value_, l2->value_) >=  0);
	} else {
		cross = (o7c_cmp(l1->value_, l2->value_) ==  0) || (l2->right != NULL) && (o7c_cmp(l2->right->value_, l1->value_) >=  0);
	}
	o7c_return = o7c_bl(cross);
	o7c_release(l1); o7c_release(l2);
	return o7c_return;
}

static o7c_bool IsListCrossRange(struct Ast_CaseLabel_s *list, struct Ast_CaseLabel_s *range) {
	o7c_bool o7c_return;

	o7c_retain(list); o7c_retain(range);
	while ((list != NULL) && !IsRangesCross(list, range)) {
		O7C_ASSIGN(&list, list->next);
	}
	o7c_return = list != NULL;
	o7c_release(list); o7c_release(range);
	return o7c_return;
}

static o7c_bool IsElementsCrossRange(struct Ast_CaseElement_s *elem, struct Ast_CaseLabel_s *range) {
	o7c_bool o7c_return;

	o7c_retain(elem); o7c_retain(range);
	while ((elem != NULL) && !IsListCrossRange(elem->labels, range)) {
		O7C_ASSIGN(&elem, elem->next);
	}
	o7c_return = elem != NULL;
	o7c_release(elem); o7c_release(range);
	return o7c_return;
}

extern int Ast_CaseRangeListAdd(struct Ast_Case_s *case_, struct Ast_CaseLabel_s *first, struct Ast_CaseLabel_s *new_) {
	int o7c_return;

	int err = O7C_INT_UNDEF;

	o7c_retain(case_); o7c_retain(first); o7c_retain(new_);
	assert(new_->next == NULL);
	if (o7c_cmp(case_->_.expr->type->_._.id, new_->_.id) !=  0) {
		err = Ast_ErrCaseRangeLabelsTypeMismatch_cnst;
	} else {
		if (IsElementsCrossRange(case_->elements, new_)) {
			err = Ast_ErrCaseElemDuplicate_cnst;
		} else {
			err = Ast_ErrNo_cnst;
		}
		while (first->next != NULL) {
			O7C_ASSIGN(&first, first->next);
		}
		O7C_ASSIGN(&first->next, new_);
	}
	o7c_return = err;
	o7c_release(case_); o7c_release(first); o7c_release(new_);
	return o7c_return;
}

extern struct Ast_CaseElement_s *Ast_CaseElementNew(struct Ast_CaseLabel_s *labels) {
	Ast_CaseElement o7c_return = NULL;

	struct Ast_CaseElement_s *elem = NULL;

	o7c_retain(labels);
	O7C_NEW(&elem, Ast_CaseElement_s_tag);
	NodeInit(&(*elem)._, Ast_CaseElement_s_tag);
	O7C_NULL(&elem->next);
	O7C_ASSIGN(&elem->labels, labels);
	O7C_NULL(&elem->stats);
	O7C_ASSIGN(&o7c_return, elem);
	o7c_release(elem);
	o7c_release(labels);
	o7c_unhold(o7c_return);
	return o7c_return;
}

extern int Ast_CaseElementAdd(struct Ast_Case_s *case_, struct Ast_CaseElement_s *elem) {
	int o7c_return;

	int err = O7C_INT_UNDEF;
	struct Ast_CaseElement_s *last = NULL;

	o7c_retain(case_); o7c_retain(elem);
	if (case_->elements == NULL) {
		O7C_ASSIGN(&case_->elements, elem);
	} else {
		O7C_ASSIGN(&last, case_->elements);
		while (last->next != NULL) {
			O7C_ASSIGN(&last, last->next);
		}
		O7C_ASSIGN(&last->next, elem);
	}
	err = Ast_ErrNo_cnst;
	o7c_return = err;
	o7c_release(last);
	o7c_release(case_); o7c_release(elem);
	return o7c_return;
}

extern int Ast_AssignNew(struct Ast_Assign_s **a, struct Ast_Designator_s *des, struct Ast_RExpression *expr) {
	int o7c_return;

	int err = O7C_INT_UNDEF;

	o7c_retain(des); o7c_retain(expr);
	O7C_NEW(&(*a), Ast_Assign_s_tag);
	StatInit(&(*a)->_, expr);
	O7C_ASSIGN(&(*a)->designator, des);
	if ((expr != NULL) && (des != NULL) && !Ast_CompatibleTypes(&(*a)->distance, des->_._.type, expr->type) && !CompatibleAsCharAndString(des->_._.type, &(*a)->_.expr)) {
		err = Ast_ErrAssignIncompatibleType_cnst;
	} else {
		err = Ast_ErrNo_cnst;
	}
	o7c_return = err;
	o7c_release(des); o7c_release(expr);
	return o7c_return;
}

extern struct Ast_StatementError_s *Ast_StatementErrorNew(void) {
	Ast_StatementError o7c_return = NULL;

	struct Ast_StatementError_s *s = NULL;

	O7C_NEW(&s, Ast_StatementError_s_tag);
	StatInit(&s->_, NULL);
	O7C_ASSIGN(&o7c_return, s);
	o7c_release(s);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static void PredefinedDeclarationsInit(void);
static void PredefinedDeclarationsInit_TypeNew(int s, int t) {
	struct Ast_RType *td = NULL;
	struct Ast_Byte_s *tb = NULL;

	if (true || (o7c_cmp(s, Scanner_Byte_cnst) !=  0)) {
		O7C_NEW(&td, Ast_RType_tag);
	} else {
		O7C_NEW(&tb, Ast_Byte_s_tag);
		O7C_ASSIGN(&td, (&(tb)->_));
	}
	TInit(td, t);
	O7C_ASSIGN(&predefined[o7c_ind(Scanner_PredefinedLast_cnst - Scanner_PredefinedFirst_cnst + 1, o7c_sub(s, Scanner_PredefinedFirst_cnst))], (&(td)->_));
	O7C_ASSIGN(&types[o7c_ind(Ast_PredefinedTypesCount_cnst, t)], td);
	o7c_release(td); o7c_release(tb);
}

static struct Ast_ProcType_s *PredefinedDeclarationsInit_ProcNew(int s, int t) {
	Ast_ProcType o7c_return = NULL;

	struct Ast_PredefinedProcedure_s *td = NULL;

	O7C_NEW(&td, Ast_PredefinedProcedure_s_tag);
	NodeInit(&(*td)._._._._, Ast_PredefinedProcedure_s_tag);
	DeclInit(&td->_._._, NULL);
	O7C_ASSIGN(&predefined[o7c_ind(Scanner_PredefinedLast_cnst - Scanner_PredefinedFirst_cnst + 1, o7c_sub(s, Scanner_PredefinedFirst_cnst))], (&(td)->_._._));
	O7C_ASSIGN(&td->_.header, Ast_ProcTypeNew());
	O7C_ASSIGN(&td->_._._.type, (&(td->_.header)->_._));
	td->_._._._.id = s;
	if (o7c_cmp(t, Ast_NoId_cnst) >  0) {
		O7C_ASSIGN(&td->_.header->_._._.type, Ast_TypeGet(t));
	}
	O7C_ASSIGN(&o7c_return, td->_.header);
	o7c_release(td);
	o7c_unhold(o7c_return);
	return o7c_return;
}

static void PredefinedDeclarationsInit(void) {
	struct Ast_ProcType_s *tp = NULL;
	struct Ast_RType *typeInt = NULL, *typeReal = NULL;

	PredefinedDeclarationsInit_TypeNew(Scanner_Byte_cnst, Ast_IdByte_cnst);
	PredefinedDeclarationsInit_TypeNew(Scanner_Integer_cnst, Ast_IdInteger_cnst);
	PredefinedDeclarationsInit_TypeNew(Scanner_Char_cnst, Ast_IdChar_cnst);
	PredefinedDeclarationsInit_TypeNew(Scanner_Set_cnst, Ast_IdSet_cnst);
	PredefinedDeclarationsInit_TypeNew(Scanner_Boolean_cnst, Ast_IdBoolean_cnst);
	PredefinedDeclarationsInit_TypeNew(Scanner_Real_cnst, Ast_IdReal_cnst);
	O7C_NEW(&types[Ast_IdPointer_cnst], Ast_RType_tag);
	NodeInit(&(*types[Ast_IdPointer_cnst])._._, Ast_RType_tag);
	DeclInit(&types[Ast_IdPointer_cnst]->_, NULL);
	types[Ast_IdPointer_cnst]->_._.id = Ast_IdPointer_cnst;
	O7C_ASSIGN(&typeInt, Ast_TypeGet(Ast_IdInteger_cnst));
	O7C_ASSIGN(&tp, PredefinedDeclarationsInit_ProcNew(Scanner_Abs_cnst, Ast_IdInteger_cnst));
	ParamAddPredefined(tp, typeInt, false);
	O7C_ASSIGN(&tp, PredefinedDeclarationsInit_ProcNew(Scanner_Asr_cnst, Ast_IdInteger_cnst));
	ParamAddPredefined(tp, typeInt, false);
	ParamAddPredefined(tp, typeInt, false);
	O7C_ASSIGN(&tp, PredefinedDeclarationsInit_ProcNew(Scanner_Assert_cnst, Ast_NoId_cnst));
	ParamAddPredefined(tp, Ast_TypeGet(Ast_IdBoolean_cnst), false);
	O7C_ASSIGN(&tp, PredefinedDeclarationsInit_ProcNew(Scanner_Chr_cnst, Ast_IdChar_cnst));
	ParamAddPredefined(tp, typeInt, false);
	O7C_ASSIGN(&tp, PredefinedDeclarationsInit_ProcNew(Scanner_Dec_cnst, Ast_NoId_cnst));
	ParamAddPredefined(tp, typeInt, false);
	O7C_ASSIGN(&tp, PredefinedDeclarationsInit_ProcNew(Scanner_Excl_cnst, Ast_NoId_cnst));
	ParamAddPredefined(tp, Ast_TypeGet(Ast_IdSet_cnst), true);
	ParamAddPredefined(tp, typeInt, false);
	O7C_ASSIGN(&typeReal, Ast_TypeGet(Ast_IdReal_cnst));
	O7C_ASSIGN(&tp, PredefinedDeclarationsInit_ProcNew(Scanner_Floor_cnst, Ast_IdInteger_cnst));
	ParamAddPredefined(tp, typeReal, false);
	O7C_ASSIGN(&tp, PredefinedDeclarationsInit_ProcNew(Scanner_Flt_cnst, Ast_IdReal_cnst));
	ParamAddPredefined(tp, typeInt, false);
	O7C_ASSIGN(&tp, PredefinedDeclarationsInit_ProcNew(Scanner_Inc_cnst, Ast_NoId_cnst));
	ParamAddPredefined(tp, typeInt, true);
	O7C_ASSIGN(&tp, PredefinedDeclarationsInit_ProcNew(Scanner_Incl_cnst, Ast_NoId_cnst));
	ParamAddPredefined(tp, Ast_TypeGet(Ast_IdSet_cnst), true);
	ParamAddPredefined(tp, typeInt, false);
	O7C_ASSIGN(&tp, PredefinedDeclarationsInit_ProcNew(Scanner_Len_cnst, Ast_IdInteger_cnst));
	ParamAddPredefined(tp, &Ast_ArrayGet(typeInt, NULL)->_._, false);
	O7C_ASSIGN(&tp, PredefinedDeclarationsInit_ProcNew(Scanner_Lsl_cnst, Ast_IdInteger_cnst));
	ParamAddPredefined(tp, typeInt, false);
	ParamAddPredefined(tp, typeInt, false);
	O7C_ASSIGN(&tp, PredefinedDeclarationsInit_ProcNew(Scanner_New_cnst, Ast_NoId_cnst));
	ParamAddPredefined(tp, Ast_TypeGet(Ast_IdPointer_cnst), true);
	O7C_ASSIGN(&tp, PredefinedDeclarationsInit_ProcNew(Scanner_Odd_cnst, Ast_IdBoolean_cnst));
	ParamAddPredefined(tp, typeInt, false);
	O7C_ASSIGN(&tp, PredefinedDeclarationsInit_ProcNew(Scanner_Ord_cnst, Ast_IdInteger_cnst));
	ParamAddPredefined(tp, Ast_TypeGet(Ast_IdChar_cnst), false);
	O7C_ASSIGN(&tp, PredefinedDeclarationsInit_ProcNew(Scanner_Pack_cnst, Ast_IdReal_cnst));
	ParamAddPredefined(tp, typeReal, true);
	O7C_ASSIGN(&tp, PredefinedDeclarationsInit_ProcNew(Scanner_Ror_cnst, Ast_IdInteger_cnst));
	ParamAddPredefined(tp, typeInt, false);
	ParamAddPredefined(tp, typeInt, false);
	O7C_ASSIGN(&tp, PredefinedDeclarationsInit_ProcNew(Scanner_Unpk_cnst, Ast_IdReal_cnst));
	ParamAddPredefined(tp, typeReal, true);
	o7c_release(tp); o7c_release(typeInt); o7c_release(typeReal);
}

extern o7c_bool Ast_HasError(struct Ast_RModule *m) {
	o7c_bool o7c_return;

	o7c_retain(m);
	o7c_return = m->errLast != NULL;
	o7c_release(m);
	return o7c_return;
}

extern void Ast_ProviderInit(struct Ast_RProvider *p, Ast_Provide get) {
	o7c_retain(p);
	V_Init(&(*p)._, Ast_RProvider_tag);
	p->get = get;
	o7c_release(p);
}

extern void Ast_init(void) {
	static int initialized = 0;
	if (0 == initialized) {
		Log_init();
		Utf8_init();
		Limits_init();
		V_init();
		Scanner_init();
		StringStore_init();
		TranslatorLimits_init();
		Arithmetic_init();

		o7c_tag_init(Ast_RProvider_tag, V_Base_tag);
		o7c_tag_init(Ast_Node_tag, V_Base_tag);
		o7c_tag_init(Ast_Error_s_tag, Ast_Node_tag);
		o7c_tag_init(Ast_RDeclaration_tag, Ast_Node_tag);
		o7c_tag_init(Ast_RType_tag, Ast_RDeclaration_tag);
		o7c_tag_init(Ast_Byte_s_tag, Ast_RType_tag);
		o7c_tag_init(Ast_Const_s_tag, Ast_RDeclaration_tag);
		o7c_tag_init(Ast_RConstruct_tag, Ast_RType_tag);
		o7c_tag_init(Ast_RArray_tag, Ast_RConstruct_tag);
		o7c_tag_init(Ast_RVar_tag, Ast_RDeclaration_tag);
		o7c_tag_init(Ast_Record_s_tag, Ast_RConstruct_tag);
		o7c_tag_init(Ast_RPointer_tag, Ast_RConstruct_tag);
		o7c_tag_init(Ast_FormalParam_s_tag, Ast_RVar_tag);
		o7c_tag_init(Ast_ProcType_s_tag, Ast_RConstruct_tag);
		o7c_tag_init(Ast_RDeclarations_tag, Ast_RDeclaration_tag);
		o7c_tag_init(Ast_Import_s_tag, Ast_RDeclaration_tag);
		o7c_tag_init(Ast_RModule_tag, Ast_RDeclarations_tag);
		o7c_tag_init(Ast_RGeneralProcedure_tag, Ast_RDeclarations_tag);
		o7c_tag_init(Ast_RProcedure_tag, Ast_RGeneralProcedure_tag);
		o7c_tag_init(Ast_PredefinedProcedure_s_tag, Ast_RGeneralProcedure_tag);
		o7c_tag_init(Ast_RExpression_tag, Ast_Node_tag);
		o7c_tag_init(Ast_RSelector_tag, Ast_Node_tag);
		o7c_tag_init(Ast_SelPointer_s_tag, Ast_RSelector_tag);
		o7c_tag_init(Ast_SelGuard_s_tag, Ast_RSelector_tag);
		o7c_tag_init(Ast_SelArray_s_tag, Ast_RSelector_tag);
		o7c_tag_init(Ast_SelRecord_s_tag, Ast_RSelector_tag);
		o7c_tag_init(Ast_RFactor_tag, Ast_RExpression_tag);
		o7c_tag_init(Ast_Designator_s_tag, Ast_RFactor_tag);
		o7c_tag_init(Ast_ExprNumber_tag, Ast_RFactor_tag);
		o7c_tag_init(Ast_RExprInteger_tag, Ast_ExprNumber_tag);
		o7c_tag_init(Ast_ExprReal_s_tag, Ast_ExprNumber_tag);
		o7c_tag_init(Ast_ExprBoolean_s_tag, Ast_RFactor_tag);
		o7c_tag_init(Ast_ExprString_s_tag, Ast_RExprInteger_tag);
		o7c_tag_init(Ast_ExprNil_s_tag, Ast_RFactor_tag);
		o7c_tag_init(Ast_ExprSet_s_tag, Ast_RFactor_tag);
		o7c_tag_init(Ast_ExprNegate_s_tag, Ast_RFactor_tag);
		o7c_tag_init(Ast_ExprBraces_s_tag, Ast_RFactor_tag);
		o7c_tag_init(Ast_ExprRelation_s_tag, Ast_RExpression_tag);
		o7c_tag_init(Ast_ExprIsExtension_s_tag, Ast_RExpression_tag);
		o7c_tag_init(Ast_ExprSum_s_tag, Ast_RExpression_tag);
		o7c_tag_init(Ast_ExprTerm_s_tag, Ast_RExpression_tag);
		o7c_tag_init(Ast_Parameter_s_tag, Ast_Node_tag);
		o7c_tag_init(Ast_ExprCall_s_tag, Ast_RFactor_tag);
		o7c_tag_init(Ast_RStatement_tag, Ast_Node_tag);
		o7c_tag_init(Ast_RWhileIf_tag, Ast_RStatement_tag);
		o7c_tag_init(Ast_If_s_tag, Ast_RWhileIf_tag);
		o7c_tag_init(Ast_CaseLabel_s_tag, Ast_Node_tag);
		o7c_tag_init(Ast_CaseElement_s_tag, Ast_Node_tag);
		o7c_tag_init(Ast_Case_s_tag, Ast_RStatement_tag);
		o7c_tag_init(Ast_Repeat_s_tag, Ast_RStatement_tag);
		o7c_tag_init(Ast_For_s_tag, Ast_RStatement_tag);
		o7c_tag_init(Ast_While_s_tag, Ast_RWhileIf_tag);
		o7c_tag_init(Ast_Assign_s_tag, Ast_RStatement_tag);
		o7c_tag_init(Ast_Call_s_tag, Ast_RStatement_tag);
		o7c_tag_init(Ast_StatementError_s_tag, Ast_RStatement_tag);

		PredefinedDeclarationsInit();
	}
	++initialized;
}


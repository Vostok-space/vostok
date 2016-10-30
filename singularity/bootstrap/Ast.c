#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

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
o7c_tag_t Ast_Record_s_tag;
o7c_tag_t Ast_RPointer_tag;
o7c_tag_t Ast_RVar_tag;
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

static struct Ast_RType *types[Ast_PredefinedTypesCount_cnst];
static struct Ast_RDeclaration *predefined[Scanner_PredefinedLast_cnst - Scanner_PredefinedFirst_cnst + 1];

extern void Ast_PutChars(struct Ast_RModule *m, o7c_tag_t m_tag, struct StringStore_String *w, o7c_tag_t w_tag, char unsigned s[/*len0*/], int s_len0, int begin, int end) {
	StringStore_Put(&m->store, StringStore_Store_tag, &(*w), w_tag, s, s_len0, begin, end);
}

static void NodeInit(struct Ast_Node *n, o7c_tag_t n_tag) {
	V_Init(&(*n)._, n_tag);
	(*n).id =  - 1;
	(*n).ext = NULL;
}

static void DeclInit(struct Ast_RDeclaration *d, o7c_tag_t d_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag) {
	if (ds == NULL) {
		d->module = NULL;
	} else if (ds->_.module == NULL) {
		d->module = (&O7C_GUARD(Ast_RModule, ds, NULL));
	} else {
		d->module = ds->_.module;
	}
	d->up = ds;
	d->mark = false;
	d->name.block = NULL;
	d->name.ofs =  - 1;
	d->type = NULL;
	d->next = NULL;
}

static void DeclConnect(struct Ast_RDeclaration *d, o7c_tag_t d_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, char unsigned name[/*len0*/], int name_len0, int start, int end) {
	assert(d != NULL);
	assert(name[0] != 0x00u);
	assert(!(o7c_is(NULL, d, Ast_RModule_tag)));
	assert(!(o7c_is(NULL, ds->start, Ast_RModule_tag)));
	DeclInit(d, NULL, ds, NULL);
	if (ds->end != NULL) {
		assert(ds->end->next == NULL);
		ds->end->next = d;
	} else {
		assert(ds->start == NULL);
		ds->start = d;
	}
	assert(!(o7c_is(NULL, ds->start, Ast_RModule_tag)));
	ds->end = d;
	Ast_PutChars(d->module, NULL, &d->name, StringStore_String_tag, name, name_len0, start, end);
}

static void DeclarationsInit(struct Ast_RDeclarations *d, o7c_tag_t d_tag, struct Ast_RDeclarations *up, o7c_tag_t up_tag) {
	DeclInit(&d->_, NULL, NULL, NULL);
	d->_.up = NULL;
	d->start = NULL;
	d->end = NULL;
	d->consts = NULL;
	d->types = NULL;
	d->vars = NULL;
	d->procedures = NULL;
	d->recordsForward = NULL;
	d->_.up = up;
	d->stats = NULL;
}

static void DeclarationsConnect(struct Ast_RDeclarations *d, o7c_tag_t d_tag, struct Ast_RDeclarations *up, o7c_tag_t up_tag, char unsigned name[/*len0*/], int name_len0, int start, int end) {
	DeclarationsInit(d, NULL, up, NULL);
	if (name[0] != 0x00u) {
		DeclConnect(&d->_, NULL, up, NULL, name, name_len0, start, end);
	} else {
		DeclInit(&d->_, NULL, up, NULL);
	}
	d->_.up = up;
}

extern struct Ast_RModule *Ast_ModuleNew(char unsigned name[/*len0*/], int name_len0, int begin, int end) {
	struct Ast_RModule *m;

	m = o7c_new(sizeof(*m), Ast_RModule_tag);
	NodeInit(&(*m)._._._, Ast_RModule_tag);
	DeclarationsInit(&m->_, NULL, NULL, NULL);
	m->import_ = NULL;
	m->errors = NULL;
	m->errLast = NULL;
	StringStore_StoreInit(&m->store, StringStore_Store_tag);
	Ast_PutChars(m, NULL, &m->_._.name, StringStore_String_tag, name, name_len0, begin, end);
	m->_._.module = m;
	Log_Str("Module ", 8);
	Log_Str(m->_._.name.block->s, StringStore_BlockSize_cnst + 1);
	Log_StrLn(" ", 2);
	return m;
}

extern struct Ast_RModule *Ast_GetModuleByName(struct Ast_RProvider *p, o7c_tag_t p_tag, struct Ast_RModule *host, o7c_tag_t host_tag, char unsigned name[/*len0*/], int name_len0, int ofs, int end) {
	return p->get(p, NULL, host, NULL, name, name_len0, ofs, end);
}

static int ImportAdd_Load(struct Ast_RModule **res, o7c_tag_t res_tag, struct Ast_RModule *host, o7c_tag_t host_tag, char unsigned buf[/*len0*/], int buf_len0, int realOfs, int realEnd, struct Ast_RProvider *p, o7c_tag_t p_tag) {
	char unsigned n[TranslatorLimits_MaxLenName_cnst];
	int l;
	int err;

	l = 0;
	assert(StringStore_CopyChars(n, TranslatorLimits_MaxLenName_cnst, &l, buf, buf_len0, realOfs, realEnd));
	Log_Str("Модуль '", 15);
	Log_Str(n, TranslatorLimits_MaxLenName_cnst);
	Log_StrLn("' загружается", 25);
	(*res) = Ast_GetModuleByName(p, NULL, host, NULL, buf, buf_len0, realOfs, realEnd);
	if ((*res) == NULL) {
		(*res) = Ast_ModuleNew(buf, buf_len0, realOfs, realEnd);
		err = Ast_ErrImportModuleNotFound_cnst;
	} else if ((*res)->errors != NULL) {
		err = Ast_ErrImportModuleWithError_cnst;
	} else {
		err = Ast_ErrNo_cnst;
	}
	Log_Str("Модуль получен: ", 30);
	Log_Int((int)((*res) != NULL));
	Log_Ln();
	return err;
}

static bool ImportAdd_IsDup(struct Ast_Import_s *i, o7c_tag_t i_tag, char unsigned buf[/*len0*/], int buf_len0, int nameOfs, int nameEnd, int realOfs, int realEnd) {
	return StringStore_IsEqualToChars(&i->_.name, StringStore_String_tag, buf, buf_len0, nameOfs, nameEnd) || (realOfs != nameOfs) && ((i->_.name.ofs != i->_.module->_._.name.ofs) || (i->_.name.block != i->_.module->_._.name.block)) && StringStore_IsEqualToChars(&i->_.module->_._.name, StringStore_String_tag, buf, buf_len0, realOfs, realEnd);
}

extern int Ast_ImportAdd(struct Ast_RModule *m, o7c_tag_t m_tag, char unsigned buf[/*len0*/], int buf_len0, int nameOfs, int nameEnd, int realOfs, int realEnd, struct Ast_RProvider *p, o7c_tag_t p_tag) {
	struct Ast_Import_s *imp;
	int err;

	imp = m->import_;
	assert((imp == NULL) || (o7c_is(NULL, m->_.end, Ast_Import_s_tag)));
	while ((imp != NULL) && !ImportAdd_IsDup(imp, NULL, buf, buf_len0, nameOfs, nameEnd, realOfs, realEnd)) {
		imp = (&O7C_GUARD(Ast_Import_s, imp->_.next, NULL));
	}
	if (imp != NULL) {
		err = Ast_ErrImportNameDuplicate_cnst;
	} else {
		imp = o7c_new(sizeof(*imp), Ast_Import_s_tag);
		imp->_._.id = Ast_IdImport_cnst;
		DeclConnect(&imp->_, NULL, &m->_, NULL, buf, buf_len0, nameOfs, nameEnd);
		if (m->import_ == NULL) {
			m->import_ = imp;
		}
		err = ImportAdd_Load(&imp->_.module, NULL, m, NULL, buf, buf_len0, realOfs, realEnd, p, NULL);
	}
	return err;
}

static struct Ast_RDeclaration *SearchName(struct Ast_RDeclaration *d, o7c_tag_t d_tag, char unsigned buf[/*len0*/], int buf_len0, int begin, int end) {
	while ((d != NULL) && ((o7c_is(NULL, d, Ast_RModule_tag)) || !StringStore_IsEqualToChars(&d->name, StringStore_String_tag, buf, buf_len0, begin, end))) {
		d = d->next;
	}
	if (d != NULL) {
		Log_Str("Найдено объявление ", 37);
		while (begin != end) {
			Log_Char(buf[begin]);
			begin = (begin + 1) % (buf_len0 - 1);
		}
		Log_Str(" id = ", 7);
		Log_Int(d->_.id);
		Log_Ln();
	}
	return d;
}

extern int Ast_ConstAdd(struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, char unsigned buf[/*len0*/], int buf_len0, int begin, int end) {
	struct Ast_Const_s *c;
	int err;

	if (SearchName(ds->start, NULL, buf, buf_len0, begin, end) != NULL) {
		err = Ast_ErrDeclarationNameDuplicate_cnst;
	} else {
		err = Ast_ErrNo_cnst;
	}
	c = o7c_new(sizeof(*c), Ast_Const_s_tag);
	c->_._.id = Ast_IdConst_cnst;
	DeclConnect(&c->_, NULL, ds, NULL, buf, buf_len0, begin, end);
	c->expr = NULL;
	c->finished = false;
	if (ds->consts == NULL) {
		ds->consts = c;
	}
	return err;
}

extern int Ast_ConstSetExpression(struct Ast_Const_s *const_, o7c_tag_t const__tag, struct Ast_RExpression *expr, o7c_tag_t expr_tag) {
	int err;

	const_->finished = true;
	err = Ast_ErrNo_cnst;
	if (expr != NULL) {
		const_->expr = expr;
		const_->_.type = expr->type;
		if ((expr->type != NULL) && (expr->value_ == NULL)) {
			err = Ast_ErrConstDeclExprNotConst_cnst;
		}
	}
	return err;
}

static void TypeAdd_MoveForwardDeclToLast(struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, struct Ast_Record_s *rec, o7c_tag_t rec_tag) {
	assert(rec->pointer->_._._.next == &rec->_._._);
	rec->_._._._.id = Ast_IdRecord_cnst;
	if (rec->_._._.next != NULL) {
		rec->pointer->_._._.next = rec->_._._.next;
		rec->_._._.next = NULL;
		ds->end->next = (&(rec)->_._._);
		ds->end = (&(rec)->_._._);
	}
}

extern int Ast_TypeAdd(struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, char unsigned buf[/*len0*/], int buf_len0, int begin, int end, struct Ast_RType **td, o7c_tag_t td_tag) {
	struct Ast_RDeclaration *d;
	int err;

	d = SearchName(ds->start, NULL, buf, buf_len0, begin, end);
	if ((d == NULL) || (d->_.id == Ast_IdRecordForward_cnst)) {
		err = Ast_ErrNo_cnst;
	} else {
		err = Ast_ErrDeclarationNameDuplicate_cnst;
	}
	if ((d == NULL) || (err == Ast_ErrDeclarationNameDuplicate_cnst)) {
		assert((*td) != NULL);
		DeclConnect(&(*td)->_, NULL, ds, NULL, buf, buf_len0, begin, end);
		if (ds->types == NULL) {
			ds->types = (*td);
		}
	} else {
		(*td) = (&O7C_GUARD(Ast_RType, d, NULL));
		TypeAdd_MoveForwardDeclToLast(ds, NULL, (&O7C_GUARD(Ast_Record_s, d, NULL)), NULL);
	}
	return err;
}

static void ChecklessVarAdd(struct Ast_RVar **v, o7c_tag_t v_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, char unsigned buf[/*len0*/], int buf_len0, int begin, int end) {
	(*v) = o7c_new(sizeof(*(*v)), Ast_RVar_tag);
	(*v)->_._.id = Ast_IdVar_cnst;
	DeclConnect(&(*v)->_, NULL, ds, NULL, buf, buf_len0, begin, end);
	(*v)->_.type = NULL;
	if (ds->vars == NULL) {
		ds->vars = (*v);
	}
}

extern int Ast_VarAdd(struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, char unsigned buf[/*len0*/], int buf_len0, int begin, int end) {
	struct Ast_RVar *v;
	int err;

	if (SearchName(ds->start, NULL, buf, buf_len0, begin, end) == NULL) {
		err = Ast_ErrNo_cnst;
	} else {
		err = Ast_ErrDeclarationNameDuplicate_cnst;
	}
	ChecklessVarAdd(&v, NULL, ds, NULL, buf, buf_len0, begin, end);
	return err;
}

static void TInit(struct Ast_RType *t, o7c_tag_t t_tag, int id) {
	NodeInit(&(*t)._._, Ast_RType_tag);
	DeclInit(&t->_, NULL, NULL, NULL);
	t->_._.id = id;
	t->array_ = NULL;
}

extern struct Ast_ProcType_s *Ast_ProcTypeNew(void) {
	struct Ast_ProcType_s *p;

	p = o7c_new(sizeof(*p), Ast_ProcType_s_tag);
	TInit(&p->_._, NULL, Ast_IdProcType_cnst);
	p->params = NULL;
	p->end = NULL;
	return p;
}

static void ParamAddPredefined(struct Ast_ProcType_s *proc, o7c_tag_t proc_tag, struct Ast_RType *type, o7c_tag_t type_tag, bool isVar) {
	struct Ast_FormalParam_s *v;

	v = o7c_new(sizeof(*v), Ast_FormalParam_s_tag);
	NodeInit(&(*v)._._._, Ast_FormalParam_s_tag);
	if (proc->end == NULL) {
		proc->params = v;
	} else {
		proc->end->_._.next = (&(v)->_._);
	}
	proc->end = v;
	v->_._.module = NULL;
	v->_._.mark = false;
	v->_._.next = NULL;
	v->_._.type = type;
	v->isVar = isVar;
}

extern int Ast_ParamAdd(struct Ast_RModule *module, o7c_tag_t module_tag, struct Ast_ProcType_s *proc, o7c_tag_t proc_tag, char unsigned buf[/*len0*/], int buf_len0, int begin, int end) {
	int err;

	if (SearchName(&proc->params->_._, NULL, buf, buf_len0, begin, end) == NULL) {
		err = Ast_ErrNo_cnst;
	} else {
		err = Ast_ErrDeclarationNameDuplicate_cnst;
	}
	ParamAddPredefined(proc, NULL, NULL, NULL, false);
	Ast_PutChars(module, NULL, &proc->end->_._.name, StringStore_String_tag, buf, buf_len0, begin, end);
	return err;
}

extern void Ast_AddError(struct Ast_RModule *m, o7c_tag_t m_tag, int error, int line, int column, int tabs) {
	struct Ast_Error_s *e;

	e = o7c_new(sizeof(*e), Ast_Error_s_tag);
	NodeInit(&(*e)._, Ast_Error_s_tag);
	e->next = NULL;
	e->code = error;
	e->line = line;
	e->column = column;
	e->tabs = tabs;
	if (m->errLast == NULL) {
		m->errors = e;
	} else {
		m->errLast->next = e;
	}
	m->errLast = e;
}

extern struct Ast_RType *Ast_TypeGet(int id) {
	assert(types[id] != NULL);
	return types[id];
}

extern struct Ast_RArray *Ast_ArrayGet(struct Ast_RType *t, o7c_tag_t t_tag, struct Ast_RExpression *count, o7c_tag_t count_tag) {
	struct Ast_RArray *a;

	if ((count != NULL) || (t == NULL) || (t->array_ == NULL)) {
		a = o7c_new(sizeof(*a), Ast_RArray_tag);
		TInit(&a->_._, NULL, Ast_IdArray_cnst);
		a->count = count;
		if ((t != NULL) && (count == NULL)) {
			t->array_ = a;
		}
		a->_._._.type = t;
	} else {
		a = t->array_;
	}
	return a;
}

extern struct Ast_RPointer *Ast_PointerGet(struct Ast_Record_s *t, o7c_tag_t t_tag) {
	struct Ast_RPointer *p;

	if ((t == NULL) || (t->pointer == NULL)) {
		p = o7c_new(sizeof(*p), Ast_RPointer_tag);
		TInit(&p->_._, NULL, Ast_IdPointer_cnst);
		p->_._._.type = (&(t)->_._);
		if (t != NULL) {
			t->pointer = p;
		}
	} else {
		p = t->pointer;
	}
	return p;
}

extern void Ast_RecordSetBase(struct Ast_Record_s *r, o7c_tag_t r_tag, struct Ast_Record_s *base, o7c_tag_t base_tag) {
	r->base = base;
	if (base != NULL) {
		r->vars->_.up = base->vars;
	}
}

extern struct Ast_Record_s *Ast_RecordNew(struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, struct Ast_Record_s *base, o7c_tag_t base_tag) {
	struct Ast_Record_s *r;

	r = o7c_new(sizeof(*r), Ast_Record_s_tag);
	TInit(&r->_._, NULL, Ast_IdRecord_cnst);
	r->pointer = NULL;
	r->vars = o7c_new(sizeof(*r->vars), Ast_RDeclarations_tag);
	NodeInit(&(*r->vars)._._, NULL);
	DeclarationsConnect(r->vars, NULL, ds, NULL, "", 1,  - 1,  - 1);
	r->vars->_.up = NULL;
	Ast_RecordSetBase(r, NULL, base, NULL);
	return r;
}

static struct Ast_RDeclaration *SearchPredefined(char unsigned buf[/*len0*/], int buf_len0, int begin, int end) {
	struct Ast_RDeclaration *d;
	int l;

	l = Scanner_CheckPredefined(buf, buf_len0, begin, end);
	Log_Str("SearchPredefined ", 18);
	Log_Int(l);
	Log_Ln();
	if ((l >= Scanner_PredefinedFirst_cnst) && (l <= Scanner_PredefinedLast_cnst)) {
		d = predefined[l - Scanner_PredefinedFirst_cnst];
		assert(d != NULL);
	} else {
		d = NULL;
	}
	return d;
}

extern struct Ast_RDeclaration *Ast_DeclarationSearch(struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, char unsigned buf[/*len0*/], int buf_len0, int begin, int end) {
	struct Ast_RDeclaration *d;

	if (o7c_is(NULL, ds, Ast_RProcedure_tag)) {
		d = SearchName(&(&O7C_GUARD(Ast_RProcedure, ds, NULL))->_.header->params->_._, NULL, buf, buf_len0, begin, end);
	} else {
		d = NULL;
	}
	if (d == NULL) {
		d = SearchName(ds->start, NULL, buf, buf_len0, begin, end);
		while ((d == NULL) && (ds->_.up != NULL)) {
			ds = ds->_.up;
			d = SearchName(ds->start, NULL, buf, buf_len0, begin, end);
		}
		if (d == NULL) {
			d = SearchPredefined(buf, buf_len0, begin, end);
		}
	}
	return d;
}

extern int Ast_DeclarationGet(struct Ast_RDeclaration **d, o7c_tag_t d_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, char unsigned buf[/*len0*/], int buf_len0, int begin, int end) {
	int err;

	(*d) = Ast_DeclarationSearch(ds, NULL, buf, buf_len0, begin, end);
	if ((*d) == NULL) {
		err = Ast_ErrDeclarationNotFound_cnst;
		(*d) = o7c_new(sizeof(*(*d)), Ast_RDeclaration_tag);
		(*d)->_.id = Ast_IdError_cnst;
		DeclConnect((*d), NULL, ds, NULL, buf, buf_len0, begin, end);
	} else if ((o7c_is(NULL, (*d), Ast_Const_s_tag)) && !(&O7C_GUARD(Ast_Const_s, (*d), NULL))->finished) {
		err = Ast_ErrConstRecursive_cnst;
		(&O7C_GUARD(Ast_Const_s, (*d), NULL))->finished = true;
	} else {
		err = Ast_ErrNo_cnst;
	}
	return err;
}

extern int Ast_VarGet(struct Ast_RVar **v, o7c_tag_t v_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, char unsigned buf[/*len0*/], int buf_len0, int begin, int end) {
	int err;
	struct Ast_RDeclaration *d;

	d = Ast_DeclarationSearch(ds, NULL, buf, buf_len0, begin, end);
	if (d == NULL) {
		err = Ast_ErrDeclarationNotFound_cnst;
	} else if (d->_.id != Ast_IdVar_cnst) {
		err = Ast_ErrDeclarationNotVar_cnst;
	} else {
		err = Ast_ErrNo_cnst;
	}
	if (err == Ast_ErrNo_cnst) {
		(*v) = (&O7C_GUARD(Ast_RVar, d, NULL));
	} else {
		ChecklessVarAdd(&(*v), NULL, ds, NULL, buf, buf_len0, begin, end);
	}
	return err;
}

extern int Ast_ForIteratorGet(struct Ast_RVar **v, o7c_tag_t v_tag, struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, char unsigned buf[/*len0*/], int buf_len0, int begin, int end) {
	int err;

	err = Ast_VarGet(&(*v), NULL, ds, NULL, buf, buf_len0, begin, end);
	if ((*v) != NULL) {
		if ((*v)->_.type == NULL) {
			(*v)->_.type = Ast_TypeGet(Ast_IdInteger_cnst);
		} else if ((*v)->_.type->_._.id != Ast_IdInteger_cnst) {
			err = Ast_ErrForIteratorNotInteger_cnst;
		}
	}
	return err;
}

static void ExprInit(struct Ast_RExpression *e, o7c_tag_t e_tag, int id, struct Ast_RType *t, o7c_tag_t t_tag) {
	NodeInit(&(*e)._, Ast_RExpression_tag);
	e->_.id = id;
	e->type = t;
	e->value_ = NULL;
}

extern struct Ast_RExprInteger *Ast_ExprIntegerNew(int int_) {
	struct Ast_RExprInteger *e;

	e = o7c_new(sizeof(*e), Ast_RExprInteger_tag);
	ExprInit(&e->_._._, NULL, Ast_IdInteger_cnst, Ast_TypeGet(Ast_IdInteger_cnst), NULL);
	e->int_ = int_;
	e->_._._.value_ = (&(e)->_._);
	return e;
}

extern struct Ast_ExprReal_s *Ast_ExprRealNew(double real, struct Ast_RModule *m, o7c_tag_t m_tag, char unsigned buf[/*len0*/], int buf_len0, int begin, int end) {
	struct Ast_ExprReal_s *e;

	assert(m != NULL);
	e = o7c_new(sizeof(*e), Ast_ExprReal_s_tag);
	ExprInit(&e->_._._, NULL, Ast_IdReal_cnst, Ast_TypeGet(Ast_IdReal_cnst), NULL);
	e->real = real;
	e->_._._.value_ = (&(e)->_._);
	Ast_PutChars(m, NULL, &e->str, StringStore_String_tag, buf, buf_len0, begin, end);
	return e;
}

extern struct Ast_ExprReal_s *Ast_ExprRealNewByValue(double real) {
	struct Ast_ExprReal_s *e;

	e = o7c_new(sizeof(*e), Ast_ExprReal_s_tag);
	ExprInit(&e->_._._, NULL, Ast_IdReal_cnst, Ast_TypeGet(Ast_IdReal_cnst), NULL);
	e->real = real;
	e->_._._.value_ = (&(e)->_._);
	e->str.block = NULL;
	return e;
}

extern struct Ast_ExprBoolean_s *Ast_ExprBooleanNew(bool bool_) {
	struct Ast_ExprBoolean_s *e;

	e = o7c_new(sizeof(*e), Ast_ExprBoolean_s_tag);
	ExprInit(&e->_._, NULL, Ast_IdBoolean_cnst, Ast_TypeGet(Ast_IdBoolean_cnst), NULL);
	e->bool_ = bool_;
	e->_._.value_ = (&(e)->_);
	return e;
}

extern struct Ast_ExprString_s *Ast_ExprStringNew(struct Ast_RModule *m, o7c_tag_t m_tag, char unsigned buf[/*len0*/], int buf_len0, int begin, int end) {
	struct Ast_ExprString_s *e;
	int len;

	len = end - begin;
	if (len < 0) {
		len = len + buf_len0 - 1;
	}
	len -= 2;
	e = o7c_new(sizeof(*e), Ast_ExprString_s_tag);
	ExprInit(&e->_._._._, NULL, Ast_IdString_cnst, &Ast_ArrayGet(Ast_TypeGet(Ast_IdChar_cnst), NULL, &Ast_ExprIntegerNew(len + 1)->_._._, NULL)->_._, NULL);
	e->_.int_ =  - 1;
	e->asChar = false;
	Ast_PutChars(m, NULL, &e->string, StringStore_String_tag, buf, buf_len0, begin, end);
	e->_._._._.value_ = (&(e)->_._._);
	return e;
}

extern struct Ast_ExprString_s *Ast_ExprCharNew(int int_) {
	struct Ast_ExprString_s *e;

	e = o7c_new(sizeof(*e), Ast_ExprString_s_tag);
	ExprInit(&e->_._._._, NULL, Ast_IdString_cnst, &Ast_ArrayGet(Ast_TypeGet(Ast_IdChar_cnst), NULL, &Ast_ExprIntegerNew(2)->_._._, NULL)->_._, NULL);
	e->string.ofs =  - 1;
	e->string.block = NULL;
	e->_.int_ = int_;
	e->asChar = true;
	e->_._._._.value_ = (&(e)->_._._);
	return e;
}

extern struct Ast_ExprNil_s *Ast_ExprNilNew(void) {
	struct Ast_ExprNil_s *e;

	e = o7c_new(sizeof(*e), Ast_ExprNil_s_tag);
	ExprInit(&e->_._, NULL, Ast_IdPointer_cnst, Ast_TypeGet(Ast_IdPointer_cnst), NULL);
	assert(e->_._.type->_.type == NULL);
	e->_._.value_ = (&(e)->_);
	return e;
}

extern struct Ast_ExprBraces_s *Ast_ExprBracesNew(struct Ast_RExpression *expr, o7c_tag_t expr_tag) {
	struct Ast_ExprBraces_s *e;

	e = o7c_new(sizeof(*e), Ast_ExprBraces_s_tag);
	ExprInit(&e->_._, NULL, Ast_IdBraces_cnst, expr->type, NULL);
	e->expr = expr;
	e->_._.value_ = expr->value_;
	return e;
}

extern struct Ast_ExprSet_s *Ast_ExprSetByValue(int set) {
	struct Ast_ExprSet_s *e;

	e = o7c_new(sizeof(*e), Ast_ExprSet_s_tag);
	ExprInit(&e->_._, NULL, Ast_IdSet_cnst, Ast_TypeGet(Ast_IdSet_cnst), NULL);
	e->exprs[0] = NULL;
	e->exprs[1] = NULL;
	e->set = set;
	e->next = NULL;
	return e;
}

static bool ExprSetNew_CheckRange(int int_) {
	return (int_ >= 0) && (int_ <= Limits_SetMax_cnst);
}

extern int Ast_ExprSetNew(struct Ast_ExprSet_s **e, o7c_tag_t e_tag, struct Ast_RExpression *expr1, o7c_tag_t expr1_tag, struct Ast_RExpression *expr2, o7c_tag_t expr2_tag) {
	int err;

	(*e) = o7c_new(sizeof(*(*e)), Ast_ExprSet_s_tag);
	ExprInit(&(*e)->_._, NULL, Ast_IdSet_cnst, Ast_TypeGet(Ast_IdSet_cnst), NULL);
	(*e)->exprs[0] = expr1;
	(*e)->exprs[1] = expr2;
	(*e)->next = NULL;
	err = Ast_ErrNo_cnst;
	if ((expr1 == NULL) && (expr2 == NULL)) {
		(*e)->set = 0;
	} else if ((expr1 != NULL) && (expr1->type != NULL) && ((expr2 == NULL) || (expr2->type != NULL))) {
		if ((expr1->type->_._.id != Ast_IdInteger_cnst) || (expr2 != NULL) && (expr2->type->_._.id != Ast_IdInteger_cnst)) {
			err = Ast_ErrNotIntSetElem_cnst;
		} else if ((expr1->value_ != NULL) && ((expr2 == NULL) || (expr2->value_ != NULL))) {
			if (!ExprSetNew_CheckRange((&O7C_GUARD(Ast_RExprInteger, expr1->value_, NULL))->int_) || ((expr2 != NULL) && !ExprSetNew_CheckRange((&O7C_GUARD(Ast_RExprInteger, expr2->value_, NULL))->int_))) {
				err = Ast_ErrSetElemOutOfRange_cnst;
			} else if (expr2 == NULL) {
				(*e)->set = (1 << (&O7C_GUARD(Ast_RExprInteger, expr1->value_, NULL))->int_);
				(*e)->_._.value_ = (&((*e))->_);
			} else if ((&O7C_GUARD(Ast_RExprInteger, expr1->value_, NULL))->int_ > (&O7C_GUARD(Ast_RExprInteger, expr2->value_, NULL))->int_) {
				err = Ast_ErrSetLeftElemBiggerRightElem_cnst;
			} else {
				(*e)->set = O7C_SET((&O7C_GUARD(Ast_RExprInteger, expr1->value_, NULL))->int_, (&O7C_GUARD(Ast_RExprInteger, expr2->value_, NULL))->int_);
				(*e)->_._.value_ = (&((*e))->_);
			}
		}
	}
	return err;
}

extern struct Ast_ExprNegate_s *Ast_ExprNegateNew(struct Ast_RExpression *expr, o7c_tag_t expr_tag) {
	struct Ast_ExprNegate_s *e;

	e = o7c_new(sizeof(*e), Ast_ExprNegate_s_tag);
	ExprInit(&e->_._, NULL, Ast_IdNegate_cnst, Ast_TypeGet(Ast_IdBoolean_cnst), NULL);
	e->expr = expr;
	if (expr->value_ != NULL) {
		e->_._.value_ = (&(Ast_ExprBooleanNew(!(&O7C_GUARD(Ast_ExprBoolean_s, expr->value_, NULL))->bool_))->_);
	}
	return e;
}

extern struct Ast_Designator_s *Ast_DesignatorNew(struct Ast_RDeclaration *decl, o7c_tag_t decl_tag) {
	struct Ast_Designator_s *d;

	d = o7c_new(sizeof(*d), Ast_Designator_s_tag);
	ExprInit(&d->_._, NULL, Ast_IdDesignator_cnst, NULL, NULL);
	d->decl = decl;
	d->sel = NULL;
	d->_._.type = decl->type;
	if (o7c_is(NULL, decl, Ast_Const_s_tag)) {
		d->_._.value_ = (&O7C_GUARD(Ast_Const_s, decl, NULL))->expr->value_;
	} else if (o7c_is(NULL, decl, Ast_RGeneralProcedure_tag)) {
		d->_._.type = (&((&O7C_GUARD(Ast_RGeneralProcedure, decl, NULL))->header)->_._);
	}
	return d;
}

extern bool Ast_IsRecordExtension(int *distance, struct Ast_Record_s *t0, o7c_tag_t t0_tag, struct Ast_Record_s *t1, o7c_tag_t t1_tag) {
	Log_Str("IsRecordExtension ", 19);
	(*distance) = 0;
	if ((t0 != NULL) && (t1 != NULL)) {
		do {
			t1 = t1->base;
			(*distance)++;
		} while (!((t0 == t1) || (t1 == NULL)));
	}
	Log_Int((int)(t0 == t1));
	Log_Ln();
	return t0 == t1;
}

static void SelInit(struct Ast_RSelector *s, o7c_tag_t s_tag) {
	NodeInit(&(*s)._, Ast_RSelector_tag);
	s->next = NULL;
}

extern int Ast_SelPointerNew(struct Ast_RSelector **sel, o7c_tag_t sel_tag, struct Ast_RType **type, o7c_tag_t type_tag) {
	struct Ast_SelPointer_s *sp;
	int err;

	sp = o7c_new(sizeof(*sp), Ast_SelPointer_s_tag);
	SelInit(&sp->_, NULL);
	(*sel) = (&(sp)->_);
	if (o7c_is(NULL, (*type), Ast_RPointer_tag)) {
		err = Ast_ErrNo_cnst;
		(*type) = (*type)->_.type;
	} else {
		err = Ast_ErrDerefToNotPointer_cnst;
	}
	return err;
}

extern int Ast_SelArrayNew(struct Ast_RSelector **sel, o7c_tag_t sel_tag, struct Ast_RType **type, o7c_tag_t type_tag, struct Ast_RExpression *index, o7c_tag_t index_tag) {
	struct Ast_SelArray_s *sa;
	int err;

	sa = o7c_new(sizeof(*sa), Ast_SelArray_s_tag);
	SelInit(&sa->_, NULL);
	sa->index = index;
	(*sel) = (&(sa)->_);
	if (!(o7c_is(NULL, (*type), Ast_RArray_tag))) {
		err = Ast_ErrArrayItemToNotArray_cnst;
	} else if (index->type->_._.id != Ast_IdInteger_cnst) {
		err = Ast_ErrArrayIndexNotInt_cnst;
	} else if ((index->value_ != NULL) && ((&O7C_GUARD(Ast_RExprInteger, index->value_, NULL))->int_ < 0)) {
		err = Ast_ErrArrayIndexNegative_cnst;
	} else if ((index->value_ != NULL) && ((&O7C_GUARD(Ast_RArray, (*type), NULL))->count != NULL) && ((&O7C_GUARD(Ast_RArray, (*type), NULL))->count->value_ != NULL) && ((&O7C_GUARD(Ast_RExprInteger, index->value_, NULL))->int_ >= (&O7C_GUARD(Ast_RExprInteger, (&O7C_GUARD(Ast_RArray, (*type), NULL))->count->value_, NULL))->int_)) {
		err = Ast_ErrArrayIndexOutOfRange_cnst;
	} else {
		err = Ast_ErrNo_cnst;
	}
	(*type) = (*type)->_.type;
	return err;
}

extern int Ast_SelRecordNew(struct Ast_RSelector **sel, o7c_tag_t sel_tag, struct Ast_RType **type, o7c_tag_t type_tag, char unsigned name[/*len0*/], int name_len0, int begin, int end) {
	struct Ast_SelRecord_s *sr;
	int err;
	struct Ast_RDeclaration *var_;
	struct Ast_RDeclarations *vars;

	sr = o7c_new(sizeof(*sr), Ast_SelRecord_s_tag);
	SelInit(&sr->_, NULL);
	var_ = NULL;
	err = Ast_ErrNo_cnst;
	if ((*type) != NULL) {
		if (!(( (1u << (*type)->_._.id) & ((1 << Ast_IdRecord_cnst) | (1 << Ast_IdPointer_cnst))))) {
			err = Ast_ErrDotSelectorToNotRecord_cnst;
		} else {
			if ((*type)->_._.id == Ast_IdRecord_cnst) {
				vars = (&O7C_GUARD(Ast_Record_s, (*type), NULL))->vars;
			} else if ((*type)->_.type == NULL) {
				vars = NULL;
			} else {
				vars = (&O7C_GUARD(Ast_Record_s, (*type)->_.type, NULL))->vars;
			}
			if (vars != NULL) {
				err = Ast_DeclarationGet(&var_, NULL, vars, NULL, name, name_len0, begin, end);
				if (var_ != NULL) {
					(*type) = var_->type;
				} else {
					(*type) = NULL;
				}
			}
		}
	}
	sr->var_ = (&O7C_GUARD(Ast_RVar, var_, NULL));
	(*sel) = (&(sr)->_);
	return err;
}

extern int Ast_SelGuardNew(struct Ast_RSelector **sel, o7c_tag_t sel_tag, struct Ast_RType **type, o7c_tag_t type_tag, struct Ast_RDeclaration *guard, o7c_tag_t guard_tag) {
	struct Ast_SelGuard_s *sg;
	int err;
	int dist;

	sg = o7c_new(sizeof(*sg), Ast_SelGuard_s_tag);
	SelInit(&sg->_, NULL);
	err = Ast_ErrNo_cnst;
	if (!(( (1u << (*type)->_._.id) & ((1 << Ast_IdRecord_cnst) | (1 << Ast_IdPointer_cnst))))) {
		err = Ast_ErrGuardedTypeNotExtensible_cnst;
	} else if ((*type)->_._.id == Ast_IdRecord_cnst) {
		if (!(o7c_is(NULL, guard, Ast_Record_s_tag)) || !Ast_IsRecordExtension(&dist, (&O7C_GUARD(Ast_Record_s, (*type), NULL)), NULL, (&O7C_GUARD(Ast_Record_s, guard, NULL)), NULL)) {
			err = Ast_ErrGuardExpectRecordExt_cnst;
		} else {
			(*type) = (&((&O7C_GUARD(Ast_Record_s, guard, NULL)))->_._);
		}
	} else {
		if (!(o7c_is(NULL, guard, Ast_RPointer_tag)) || !Ast_IsRecordExtension(&dist, (&O7C_GUARD(Ast_Record_s, (&O7C_GUARD(Ast_RPointer, (*type), NULL))->_._._.type, NULL)), NULL, (&O7C_GUARD(Ast_Record_s, (&O7C_GUARD(Ast_RPointer, guard, NULL))->_._._.type, NULL)), NULL)) {
			err = Ast_ErrGuardExpectPointerExt_cnst;
		} else {
			(*type) = (&((&O7C_GUARD(Ast_RPointer, guard, NULL)))->_._);
		}
	}
	sg->type = (*type);
	(*sel) = (&(sg)->_);
	return err;
}

static bool CompatibleTypes_EqualProcTypes(struct Ast_ProcType_s *t1, o7c_tag_t t1_tag, struct Ast_ProcType_s *t2, o7c_tag_t t2_tag) {
	bool comp;
	struct Ast_RDeclaration *fp1;
	struct Ast_RDeclaration *fp2;

	comp = t1->_._._.type == t2->_._._.type;
	if (comp) {
		fp1 = (&(t1->params)->_._);
		fp2 = (&(t2->params)->_._);
		while ((fp1 != NULL) && (fp2 != NULL) && (o7c_is(NULL, fp1, Ast_FormalParam_s_tag)) && (o7c_is(NULL, fp2, Ast_FormalParam_s_tag)) && (fp1->type == fp2->type) && ((&O7C_GUARD(Ast_FormalParam_s, fp1, NULL))->isVar == (&O7C_GUARD(Ast_FormalParam_s, fp2, NULL))->isVar)) {
			fp1 = fp1->next;
			fp2 = fp2->next;
		}
		comp = ((fp1 == NULL) || !(o7c_is(NULL, fp1, Ast_FormalParam_s_tag))) && ((fp2 == NULL) || !(o7c_is(NULL, fp2, Ast_FormalParam_s_tag)));
	}
	return comp;
}

extern bool Ast_CompatibleTypes(int *distance, struct Ast_RType *t1, o7c_tag_t t1_tag, struct Ast_RType *t2, o7c_tag_t t2_tag) {
	bool comp;

	comp = (t1 == NULL) || (t2 == NULL);
	if (!comp) {
		comp = t1 == t2;
		Log_Str("Идентификаторы типов : ", 43);
		Log_Int(t1->_._.id);
		Log_Str(" : ", 4);
		Log_Int(t2->_._.id);
		Log_Ln();
		(*distance) = 0;
		if (!comp && (t1->_._.id == t2->_._.id) && (( (1u << t1->_._.id) & ((1 << Ast_IdArray_cnst) | (1 << Ast_IdPointer_cnst) | (1 << Ast_IdRecord_cnst) | (1 << Ast_IdProcType_cnst))))) {
			switch (t1->_._.id) {
			case 7:
				comp = Ast_CompatibleTypes(&(*distance), t1->_.type, NULL, t2->_.type, NULL);
				break;
			case 6:
				comp = (t1->_.type == NULL) || (t2->_.type == NULL) || Ast_IsRecordExtension(&(*distance), (&O7C_GUARD(Ast_Record_s, t1->_.type, NULL)), NULL, (&O7C_GUARD(Ast_Record_s, t2->_.type, NULL)), NULL);
				break;
			case 8:
				comp = Ast_IsRecordExtension(&(*distance), (&O7C_GUARD(Ast_Record_s, t1, NULL)), NULL, (&O7C_GUARD(Ast_Record_s, t2, NULL)), NULL);
				break;
			case 10:
				comp = CompatibleTypes_EqualProcTypes((&O7C_GUARD(Ast_ProcType_s, t1, NULL)), NULL, (&O7C_GUARD(Ast_ProcType_s, t2, NULL)), NULL);
				break;
			default:
				abort();
				break;
			}
		}
	}
	return comp;
}

extern int Ast_ExprIsExtensionNew(struct Ast_ExprIsExtension_s **e, o7c_tag_t e_tag, struct Ast_RExpression **des, o7c_tag_t des_tag, struct Ast_RType *type, o7c_tag_t type_tag) {
	int err;

	(*e) = o7c_new(sizeof(*(*e)), Ast_ExprIsExtension_s_tag);
	ExprInit(&(*e)->_, NULL, Ast_IdIsExtension_cnst, Ast_TypeGet(Ast_IdBoolean_cnst), NULL);
	(*e)->designator = NULL;
	(*e)->extType = type;
	err = Ast_ErrNo_cnst;
	if ((type != NULL) && !(( (1u << type->_._.id) & ((1 << Ast_IdPointer_cnst) | (1 << Ast_IdRecord_cnst))))) {
		err = Ast_ErrIsExtTypeNotRecord_cnst;
	} else if ((*des) != NULL) {
		if (o7c_is(NULL, (*des), Ast_Designator_s_tag)) {
			(*e)->designator = (&O7C_GUARD(Ast_Designator_s, (*des), NULL));
			if (!(( (1u << (*des)->type->_._.id) & ((1 << Ast_IdPointer_cnst) | (1 << Ast_IdRecord_cnst))))) {
				err = Ast_ErrIsExtVarNotRecord_cnst;
			}
		} else {
			err = Ast_ErrIsExtVarNotRecord_cnst;
		}
	}
	return err;
}

static bool CompatibleAsCharAndString(struct Ast_RType *t1, o7c_tag_t t1_tag, struct Ast_RExpression **e2, o7c_tag_t e2_tag) {
	bool ret;

	Log_Str("1 CompatibleAsCharAndString ", 29);
	Log_Int((int)((*e2)->value_ != NULL));
	Log_Ln();
	ret = (t1->_._.id == Ast_IdChar_cnst) && ((*e2)->value_ != NULL) && (o7c_is(NULL, (*e2)->value_, Ast_ExprString_s_tag)) && ((&O7C_GUARD(Ast_ExprString_s, (*e2)->value_, NULL))->_.int_ >= 0);
	if (ret && !(&O7C_GUARD(Ast_ExprString_s, (*e2)->value_, NULL))->asChar) {
		if (o7c_is(NULL, (*e2), Ast_ExprString_s_tag)) {
			(*e2) = (&(Ast_ExprCharNew((&O7C_GUARD(Ast_ExprString_s, (*e2)->value_, NULL))->_.int_))->_._._._);
		} else {
			(*e2)->value_ = (&(Ast_ExprCharNew((&O7C_GUARD(Ast_ExprString_s, (*e2)->value_, NULL))->_.int_))->_._._);
		}
		assert((&O7C_GUARD(Ast_ExprString_s, (*e2)->value_, NULL))->asChar);
	}
	return ret;
}

static bool ExprRelationNew_CheckType(struct Ast_RType *t1, o7c_tag_t t1_tag, struct Ast_RType *t2, o7c_tag_t t2_tag, struct Ast_RExpression **e1, o7c_tag_t e1_tag, struct Ast_RExpression **e2, o7c_tag_t e2_tag, int relation, int *distance, int *err) {
	bool continue_;
	int dist1;
	int dist2;

	dist1 = 0;
	dist2 = 0;
	if ((t1 == NULL) || (t2 == NULL)) {
		continue_ = false;
	} else if (relation == Scanner_In_cnst) {
		continue_ = (t1->_._.id == Ast_IdInteger_cnst) && (t2->_._.id == Ast_IdSet_cnst);
		if (!continue_) {
			(*err) = Ast_ErrExprInWrongTypes_cnst - 3 + (int)(t1->_._.id != Ast_IdInteger_cnst) + (int)(t2->_._.id != Ast_IdSet_cnst) * 2;
		}
	} else if (!Ast_CompatibleTypes(&dist1, t1, NULL, t2, NULL) && !Ast_CompatibleTypes(&dist2, t2, NULL, t1, NULL) && !CompatibleAsCharAndString(t1, NULL, &(*e2), NULL) && !CompatibleAsCharAndString(t2, NULL, &(*e1), NULL)) {
		(*err) = Ast_ErrRelationExprDifferenTypes_cnst;
		continue_ = false;
	} else if ((( (1u << t1->_._.id) & ((1 << Ast_IdInteger_cnst) | (1 << Ast_IdReal_cnst) | (1 << Ast_IdChar_cnst)))) || (t1->_._.id == Ast_IdArray_cnst) && (t1->_.type->_._.id == Ast_IdChar_cnst)) {
		continue_ = true;
	} else if (( (1u << t1->_._.id) & ((1 << Ast_IdRecord_cnst) | (1 << Ast_IdArray_cnst)))) {
		continue_ = false;
		(*err) = Ast_ErrRelIncompatibleType_cnst;
	} else {
		continue_ = (relation == Scanner_Equal_cnst) || (relation == Scanner_Inequal_cnst) || (t1->_._.id == Ast_IdSet_cnst) && ((relation == Scanner_LessEqual_cnst) || (relation == Scanner_GreaterEqual_cnst));
		if (!continue_) {
			(*err) = Ast_ErrRelIncompatibleType_cnst;
		}
	}
	(*distance) = dist1 - dist2;
	return continue_;
}

extern int Ast_ExprRelationNew(struct Ast_ExprRelation_s **e, o7c_tag_t e_tag, struct Ast_RExpression *expr1, o7c_tag_t expr1_tag, int relation, struct Ast_RExpression *expr2, o7c_tag_t expr2_tag) {
	int err;
	bool res;
	struct Ast_RExpression *v1;
	struct Ast_RExpression *v2;

	assert((relation >= Scanner_RelationFirst_cnst) && (relation < Scanner_RelationLast_cnst));
	(*e) = o7c_new(sizeof(*(*e)), Ast_ExprRelation_s_tag);
	ExprInit(&(*e)->_, NULL, Ast_IdRelation_cnst, Ast_TypeGet(Ast_IdBoolean_cnst), NULL);
	(*e)->exprs[0] = expr1;
	(*e)->exprs[1] = expr2;
	(*e)->relation = relation;
	err = Ast_ErrNo_cnst;
	if ((expr1 != NULL) && (expr2 != NULL) && ExprRelationNew_CheckType(expr1->type, NULL, expr2->type, NULL, &(*e)->exprs[0], NULL, &(*e)->exprs[1], NULL, relation, &(*e)->distance, &err) && (expr1->value_ != NULL) && (expr2->value_ != NULL) && (relation != Scanner_Is_cnst)) {
		v1 = (&((*e)->exprs[0]->value_)->_);
		v2 = (&((*e)->exprs[1]->value_)->_);
		switch (relation) {
		case 21:
			switch (expr1->type->_._.id) {
			case 0:
			case 3:
				res = (&O7C_GUARD(Ast_RExprInteger, v1, NULL))->int_ == (&O7C_GUARD(Ast_RExprInteger, v2, NULL))->int_;
				break;
			case 1:
				res = (&O7C_GUARD(Ast_ExprBoolean_s, v1, NULL))->bool_ == (&O7C_GUARD(Ast_ExprBoolean_s, v2, NULL))->bool_;
				break;
			case 4:
				res = (&O7C_GUARD(Ast_ExprReal_s, v1, NULL))->real == (&O7C_GUARD(Ast_ExprReal_s, v2, NULL))->real;
				break;
			case 5:
				res = (&O7C_GUARD(Ast_ExprSet_s, v1, NULL))->set == (&O7C_GUARD(Ast_ExprSet_s, v2, NULL))->set;
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
				res = (&O7C_GUARD(Ast_RExprInteger, v1, NULL))->int_ != (&O7C_GUARD(Ast_RExprInteger, v2, NULL))->int_;
				break;
			case 1:
				res = (&O7C_GUARD(Ast_ExprBoolean_s, v1, NULL))->bool_ != (&O7C_GUARD(Ast_ExprBoolean_s, v2, NULL))->bool_;
				break;
			case 4:
				res = (&O7C_GUARD(Ast_ExprReal_s, v1, NULL))->real != (&O7C_GUARD(Ast_ExprReal_s, v2, NULL))->real;
				break;
			case 5:
				res = (&O7C_GUARD(Ast_ExprSet_s, v1, NULL))->set != (&O7C_GUARD(Ast_ExprSet_s, v2, NULL))->set;
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
				res = (&O7C_GUARD(Ast_RExprInteger, v1, NULL))->int_ < (&O7C_GUARD(Ast_RExprInteger, v2, NULL))->int_;
				break;
			case 4:
				res = (&O7C_GUARD(Ast_ExprReal_s, v1, NULL))->real < (&O7C_GUARD(Ast_ExprReal_s, v2, NULL))->real;
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
				res = (&O7C_GUARD(Ast_RExprInteger, v1, NULL))->int_ <= (&O7C_GUARD(Ast_RExprInteger, v2, NULL))->int_;
				break;
			case 4:
				res = (&O7C_GUARD(Ast_ExprReal_s, v1, NULL))->real <= (&O7C_GUARD(Ast_ExprReal_s, v2, NULL))->real;
				break;
			case 5:
				res = (&O7C_GUARD(Ast_ExprSet_s, v1, NULL))->set <= (&O7C_GUARD(Ast_ExprSet_s, v2, NULL))->set;
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
				res = (&O7C_GUARD(Ast_RExprInteger, v1, NULL))->int_ > (&O7C_GUARD(Ast_RExprInteger, v2, NULL))->int_;
				break;
			case 4:
				res = (&O7C_GUARD(Ast_ExprReal_s, v1, NULL))->real > (&O7C_GUARD(Ast_ExprReal_s, v2, NULL))->real;
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
				res = (&O7C_GUARD(Ast_RExprInteger, v1, NULL))->int_ >= (&O7C_GUARD(Ast_RExprInteger, v2, NULL))->int_;
				break;
			case 4:
				res = (&O7C_GUARD(Ast_ExprReal_s, v1, NULL))->real >= (&O7C_GUARD(Ast_ExprReal_s, v2, NULL))->real;
				break;
			case 5:
				res = (&O7C_GUARD(Ast_ExprSet_s, v1, NULL))->set >= (&O7C_GUARD(Ast_ExprSet_s, v2, NULL))->set;
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
			res = ( (1u << (&O7C_GUARD(Ast_RExprInteger, v1, NULL))->int_) & (&O7C_GUARD(Ast_ExprSet_s, v2, NULL))->set);
			break;
		default:
			abort();
			break;
		}
		(*e)->_.value_ = (&(Ast_ExprBooleanNew(res))->_);
	}
	return err;
}

static int LexToSign(int lex) {
	int s;

	if ((lex ==  - 1) || (lex == Scanner_Plus_cnst)) {
		s =  + 1;
	} else {
		assert(lex == Scanner_Minus_cnst);
		s =  - 1;
	}
	return s;
}

static void ExprSumCreate(struct Ast_ExprSum_s **e, o7c_tag_t e_tag, int add, struct Ast_RExpression *sum, o7c_tag_t sum_tag, struct Ast_RExpression *term, o7c_tag_t term_tag) {
	struct Ast_RType *t;

	(*e) = o7c_new(sizeof(*(*e)), Ast_ExprSum_s_tag);
	if ((sum != NULL) && (sum->type != NULL) && (( (1u << sum->type->_._.id) & ((1 << Ast_IdReal_cnst) | (1 << Ast_IdInteger_cnst))))) {
		t = sum->type;
	} else if (term != NULL) {
		t = term->type;
	} else {
		t = NULL;
	}
	ExprInit(&(*e)->_, NULL, Ast_IdSum_cnst, t, NULL);
	(*e)->next = NULL;
	(*e)->add = add;
	(*e)->term = term;
}

extern int Ast_ExprSumNew(struct Ast_ExprSum_s **e, o7c_tag_t e_tag, int add, struct Ast_RExpression *term, o7c_tag_t term_tag) {
	int err;

	assert((add ==  - 1) || (add == Scanner_Plus_cnst) || (add == Scanner_Minus_cnst));
	ExprSumCreate(&(*e), NULL, add, NULL, NULL, term, NULL);
	err = Ast_ErrNo_cnst;
	if ((*e)->_.type != NULL) {
		if (!(( (1u << (*e)->_.type->_._.id) & ((1 << Ast_IdInteger_cnst) | (1 << Ast_IdReal_cnst) | (1 << Ast_IdSet_cnst)))) && (add !=  - 1)) {
			if ((*e)->_.type->_._.id != Ast_IdBoolean_cnst) {
				err = Ast_ErrNotNumberAndNotSetInAdd_cnst;
			} else {
				err = Ast_ErrSignForBool_cnst;
			}
		} else if (term->value_ != NULL) {
			switch ((*e)->_.type->_._.id) {
			case 0:
				(*e)->_.value_ = (&(Ast_ExprIntegerNew((&O7C_GUARD(Ast_RExprInteger, term->value_, NULL))->int_ * LexToSign(add)))->_._);
				break;
			case 4:
				(*e)->_.value_ = (&(Ast_ExprRealNewByValue((&O7C_GUARD(Ast_ExprReal_s, term->value_, NULL))->real * (double)LexToSign(add)))->_._);
				break;
			case 5:
				if (add != Scanner_Minus_cnst) {
					(*e)->_.value_ = (&(Ast_ExprSetByValue((&O7C_GUARD(Ast_ExprSet_s, term->value_, NULL))->set))->_);
				} else {
					(*e)->_.value_ = (&(Ast_ExprSetByValue( ~(&O7C_GUARD(Ast_ExprSet_s, term->value_, NULL))->set))->_);
				}
				break;
			case 1:
				(*e)->_.value_ = (&(Ast_ExprBooleanNew((&O7C_GUARD(Ast_ExprBoolean_s, term->value_, NULL))->bool_))->_);
				break;
			default:
				abort();
				break;
			}
		}
	}
	return err;
}

static bool ExprSumAdd_CheckType(struct Ast_RExpression *e1, o7c_tag_t e1_tag, struct Ast_RExpression *e2, o7c_tag_t e2_tag, int add, int *err) {
	bool continue_;

	if ((e1->type == NULL) || (e2->type == NULL)) {
		continue_ = false;
	} else if (e1->type->_._.id != e2->type->_._.id) {
		(*err) = Ast_ErrAddExprDifferenTypes_cnst;
		continue_ = false;
	} else if (add == Scanner_Or_cnst) {
		continue_ = e1->type->_._.id == Ast_IdBoolean_cnst;
		if (!continue_) {
			(*err) = Ast_ErrNotBoolInLogicExpr_cnst;
		}
	} else {
		continue_ = (e1->type->_._.id == Ast_IdInteger_cnst) || (e1->type->_._.id == Ast_IdReal_cnst) || (e1->type->_._.id == Ast_IdSet_cnst);
		if (!continue_) {
			(*err) = Ast_ErrNotNumberAndNotSetInAdd_cnst;
		}
	}
	return continue_;
}

extern int Ast_ExprSumAdd(struct Ast_RExpression *fullSum, o7c_tag_t fullSum_tag, struct Ast_ExprSum_s **lastAdder, o7c_tag_t lastAdder_tag, int add, struct Ast_RExpression *term, o7c_tag_t term_tag) {
	struct Ast_ExprSum_s *e;
	int err;

	assert((add == Scanner_Plus_cnst) || (add == Scanner_Minus_cnst) || (add == Scanner_Or_cnst));
	ExprSumCreate(&e, NULL, add, fullSum, NULL, term, NULL);
	err = Ast_ErrNo_cnst;
	if ((fullSum != NULL) && (term != NULL) && ExprSumAdd_CheckType(fullSum, NULL, term, NULL, add, &err) && (fullSum->value_ != NULL) && (term->value_ != NULL)) {
		if (add == Scanner_Or_cnst) {
			if ((&O7C_GUARD(Ast_ExprBoolean_s, term->value_, NULL))->bool_) {
				(&O7C_GUARD(Ast_ExprBoolean_s, fullSum->value_, NULL))->bool_ = true;
			}
		} else {
			switch (term->type->_._.id) {
			case 0:
				(&O7C_GUARD(Ast_RExprInteger, fullSum->value_, NULL))->int_ = (&O7C_GUARD(Ast_RExprInteger, fullSum->value_, NULL))->int_ + (&O7C_GUARD(Ast_RExprInteger, term->value_, NULL))->int_ * LexToSign(add);
				break;
			case 4:
				(&O7C_GUARD(Ast_ExprReal_s, fullSum->value_, NULL))->real = (&O7C_GUARD(Ast_ExprReal_s, fullSum->value_, NULL))->real + (&O7C_GUARD(Ast_ExprReal_s, term->value_, NULL))->real * (double)LexToSign(add);
				break;
			case 5:
				if (add == Scanner_Plus_cnst) {
					(&O7C_GUARD(Ast_ExprSet_s, fullSum->value_, NULL))->set = (&O7C_GUARD(Ast_ExprSet_s, fullSum->value_, NULL))->set | (&O7C_GUARD(Ast_ExprSet_s, term->value_, NULL))->set;
				} else {
					(&O7C_GUARD(Ast_ExprSet_s, fullSum->value_, NULL))->set = (&O7C_GUARD(Ast_ExprSet_s, fullSum->value_, NULL))->set & ~(&O7C_GUARD(Ast_ExprSet_s, term->value_, NULL))->set;
				}
				break;
			default:
				abort();
				break;
			}
		}
	} else if (fullSum != NULL) {
		fullSum->value_ = NULL;
	}
	if ((*lastAdder) != NULL) {
		(*lastAdder)->next = e;
	}
	(*lastAdder) = e;
	return err;
}

static int MultCalc(struct Ast_RExpression *res, o7c_tag_t res_tag, struct Ast_RExpression *a, o7c_tag_t a_tag, int mult, struct Ast_RExpression *b, o7c_tag_t b_tag);
static bool MultCalc_CheckType(struct Ast_RExpression *e1, o7c_tag_t e1_tag, struct Ast_RExpression *e2, o7c_tag_t e2_tag, int mult, int *err) {
	bool continue_;

	if ((e1->type == NULL) || (e2->type == NULL)) {
		continue_ = false;
	} else if (e1->type->_._.id != e2->type->_._.id) {
		continue_ = false;
		(*err) = Ast_ErrMultExprDifferenTypes_cnst;
	} else if (mult == Scanner_And_cnst) {
		continue_ = e1->type->_._.id == Ast_IdBoolean_cnst;
		if (!continue_) {
			(*err) = Ast_ErrNotBoolInLogicExpr_cnst;
		}
	} else if ((e1->type->_._.id != Ast_IdInteger_cnst) && (e1->type->_._.id != Ast_IdReal_cnst) && (e1->type->_._.id != Ast_IdSet_cnst)) {
		continue_ = false;
		(*err) = Ast_ErrNotNumberAndNotSetInMult_cnst;
	} else if ((mult == Scanner_Div_cnst) || (mult == Scanner_Mod_cnst)) {
		continue_ = e1->type->_._.id == Ast_IdInteger_cnst;
		if (!continue_) {
			(*err) = Ast_ErrNotIntInDivOrMod_cnst;
		}
	} else if ((mult == Scanner_Slash_cnst) && (e1->type->_._.id == Ast_IdInteger_cnst)) {
		continue_ = false;
		(*err) = Ast_ErrNotRealTypeForRealDiv_cnst;
	} else {
		continue_ = true;
	}
	return continue_;
}

static void MultCalc_Int(struct Ast_RExpression *res, o7c_tag_t res_tag, struct Ast_RExpression *a, o7c_tag_t a_tag, int mult, struct Ast_RExpression *b, o7c_tag_t b_tag, int *err) {
	int i;
	int i1;
	int i2;

	i1 = (&O7C_GUARD(Ast_RExprInteger, a->value_, NULL))->int_;
	i2 = (&O7C_GUARD(Ast_RExprInteger, b->value_, NULL))->int_;
	if (mult == Scanner_Asterisk_cnst) {
		i = i1 * i2;
	} else if (i2 == 0) {
		(*err) = Ast_ErrIntDivByZero_cnst;
		res->value_ = NULL;
	} else if (mult == Scanner_Div_cnst) {
		i = i1 / i2;
	} else {
		i = i1 % i2;
	}
	if ((*err) == Ast_ErrNo_cnst) {
		if (res->value_ == NULL) {
			res->value_ = (&(Ast_ExprIntegerNew(i))->_._);
		} else {
			(&O7C_GUARD(Ast_RExprInteger, res->value_, NULL))->int_ = i;
		}
	}
}

static void MultCalc_Rl(struct Ast_RExpression *res, o7c_tag_t res_tag, struct Ast_RExpression *a, o7c_tag_t a_tag, int mult, struct Ast_RExpression *b, o7c_tag_t b_tag) {
	double r;
	double r1;
	double r2;

	r1 = (&O7C_GUARD(Ast_ExprReal_s, a->value_, NULL))->real;
	r2 = (&O7C_GUARD(Ast_ExprReal_s, b->value_, NULL))->real;
	if (mult == Scanner_Asterisk_cnst) {
		r = r1 * r2;
	} else {
		r = r1 / r2;
	}
	if (res->value_ == NULL) {
		res->value_ = (&(Ast_ExprRealNewByValue(r))->_._);
	} else {
		(&O7C_GUARD(Ast_ExprReal_s, res->value_, NULL))->real = r;
	}
}

static void MultCalc_St(struct Ast_RExpression *res, o7c_tag_t res_tag, struct Ast_RExpression *a, o7c_tag_t a_tag, int mult, struct Ast_RExpression *b, o7c_tag_t b_tag) {
	int s;
	int s1;
	int s2;

	s1 = (&O7C_GUARD(Ast_ExprSet_s, a->value_, NULL))->set;
	s2 = (&O7C_GUARD(Ast_ExprSet_s, b->value_, NULL))->set;
	if (mult == Scanner_Asterisk_cnst) {
		s = s1 & s2;
	} else {
		s = s1 ^ s2;
	}
	if (res->value_ == NULL) {
		res->value_ = (&(Ast_ExprSetByValue(s))->_);
	} else {
		(&O7C_GUARD(Ast_ExprSet_s, res->value_, NULL))->set = s;
	}
}

static int MultCalc(struct Ast_RExpression *res, o7c_tag_t res_tag, struct Ast_RExpression *a, o7c_tag_t a_tag, int mult, struct Ast_RExpression *b, o7c_tag_t b_tag) {
	int err;
	bool bool_;

	err = Ast_ErrNo_cnst;
	if (MultCalc_CheckType(a, NULL, b, NULL, mult, &err) && (a->value_ != NULL) && (b->value_ != NULL)) {
		switch (a->type->_._.id) {
		case 0:
			MultCalc_Int(res, NULL, a, NULL, mult, b, NULL, &err);
			break;
		case 4:
			MultCalc_Rl(res, NULL, a, NULL, mult, b, NULL);
			break;
		case 1:
			bool_ = (&O7C_GUARD(Ast_ExprBoolean_s, a->value_, NULL))->bool_ && (&O7C_GUARD(Ast_ExprBoolean_s, b->value_, NULL))->bool_;
			if (res->value_ == NULL) {
				res->value_ = (&(Ast_ExprBooleanNew(bool_))->_);
			} else {
				(&O7C_GUARD(Ast_ExprBoolean_s, res->value_, NULL))->bool_ = bool_;
			}
			break;
		case 5:
			MultCalc_St(res, NULL, a, NULL, mult, b, NULL);
			break;
		default:
			abort();
			break;
		}
	} else {
		res->value_ = NULL;
	}
	return err;
}

static int ExprTermGeneral(struct Ast_ExprTerm_s **e, o7c_tag_t e_tag, struct Ast_RExpression *result, o7c_tag_t result_tag, struct Ast_RFactor *factor, o7c_tag_t factor_tag, int mult, struct Ast_RExpression *factorOrTerm, o7c_tag_t factorOrTerm_tag) {
	assert((mult >= Scanner_MultFirst_cnst) && (mult <= Scanner_MultLast_cnst));
	assert((o7c_is(NULL, factorOrTerm, Ast_RFactor_tag)) || (o7c_is(NULL, factorOrTerm, Ast_ExprTerm_s_tag)));
	(*e) = o7c_new(sizeof(*(*e)), Ast_ExprTerm_s_tag);
	ExprInit(&(*e)->_, NULL, Ast_IdTerm_cnst, factorOrTerm->type, NULL);
	(*e)->factor = factor;
	(*e)->mult = mult;
	(*e)->expr = factorOrTerm;
	if (result == NULL) {
		result = (&((*e))->_);
	}
	(*e)->factor = factor;
	return MultCalc(result, NULL, &factor->_, NULL, mult, factorOrTerm, NULL);
}

extern int Ast_ExprTermNew(struct Ast_ExprTerm_s **e, o7c_tag_t e_tag, struct Ast_RFactor *factor, o7c_tag_t factor_tag, int mult, struct Ast_RExpression *factorOrTerm, o7c_tag_t factorOrTerm_tag) {
	return ExprTermGeneral(&(*e), NULL, &(*e)->_, NULL, factor, NULL, mult, factorOrTerm, NULL);
}

extern int Ast_ExprTermAdd(struct Ast_RExpression *fullTerm, o7c_tag_t fullTerm_tag, struct Ast_ExprTerm_s **lastTerm, o7c_tag_t lastTerm_tag, int mult, struct Ast_RExpression *factorOrTerm, o7c_tag_t factorOrTerm_tag) {
	struct Ast_ExprTerm_s *e;
	int err;

	if ((*lastTerm) != NULL) {
		assert((*lastTerm)->expr != NULL);
		err = ExprTermGeneral(&e, NULL, fullTerm, NULL, (&O7C_GUARD(Ast_RFactor, (*lastTerm)->expr, NULL)), NULL, mult, factorOrTerm, NULL);
		(*lastTerm)->expr = (&(e)->_);
		(*lastTerm) = e;
	} else {
		err = ExprTermGeneral(&(*lastTerm), NULL, fullTerm, NULL, NULL, NULL, mult, factorOrTerm, NULL);
	}
	return err;
}

static int ExprCallCreate(struct Ast_ExprCall_s **e, o7c_tag_t e_tag, struct Ast_Designator_s *des, o7c_tag_t des_tag, bool func_) {
	int err;
	struct Ast_RType *t;
	struct Ast_ProcType_s *pt;

	t = NULL;
	err = Ast_ErrNo_cnst;
	if (des != NULL) {
		Log_Str("ExprCallCreate des.decl.id = ", 30);
		Log_Int(des->decl->_.id);
		Log_Ln();
		if (des->decl->_.id == Ast_IdError_cnst) {
			pt = Ast_ProcTypeNew();
			des->decl->type = (&(pt)->_._);
			des->_._.type = (&(pt)->_._);
		} else if (des->_._.type != NULL) {
			if (o7c_is(NULL, des->_._.type, Ast_ProcType_s_tag)) {
				t = des->_._.type->_.type;
				if ((t != NULL) != func_) {
					err = Ast_ErrCallIgnoredReturn_cnst + (int)func_;
				}
			} else {
				err = Ast_ErrCallNotProc_cnst;
			}
		}
	}
	(*e) = o7c_new(sizeof(*(*e)), Ast_ExprCall_s_tag);
	ExprInit(&(*e)->_._, NULL, Ast_IdCall_cnst, t, NULL);
	(*e)->designator = des;
	(*e)->params = NULL;
	return err;
}

extern int Ast_ExprCallNew(struct Ast_ExprCall_s **e, o7c_tag_t e_tag, struct Ast_Designator_s *des, o7c_tag_t des_tag) {
	return ExprCallCreate(&(*e), NULL, des, NULL, true);
}

extern bool Ast_IsChangeable(struct Ast_RModule *cur, o7c_tag_t cur_tag, struct Ast_RVar *v, o7c_tag_t v_tag) {
	Log_StrLn("IsChangeable", 13);
	return (!(o7c_is(NULL, v, Ast_FormalParam_s_tag)) || ((&O7C_GUARD(Ast_FormalParam_s, v, NULL))->isVar) || !((o7c_is(NULL, v->_.type, Ast_RArray_tag)) || (o7c_is(NULL, v->_.type, Ast_Record_s_tag))));
}

extern bool Ast_IsVar(struct Ast_RExpression *e, o7c_tag_t e_tag) {
	Log_Str("IsVar: e.id = ", 15);
	Log_Int(e->_.id);
	Log_Ln();
	return (o7c_is(NULL, e, Ast_Designator_s_tag)) && (o7c_is(NULL, (&O7C_GUARD(Ast_Designator_s, e, NULL))->decl, Ast_RVar_tag));
}

extern int Ast_ProcedureAdd(struct Ast_RDeclarations *ds, o7c_tag_t ds_tag, struct Ast_RProcedure **p, o7c_tag_t p_tag, char unsigned buf[/*len0*/], int buf_len0, int begin, int end) {
	int err;

	if (SearchName(ds->start, NULL, buf, buf_len0, begin, end) == NULL) {
		err = Ast_ErrNo_cnst;
	} else {
		err = Ast_ErrDeclarationNameDuplicate_cnst;
	}
	(*p) = o7c_new(sizeof(*(*p)), Ast_RProcedure_tag);
	NodeInit(&(*(*p))._._._._, Ast_RProcedure_tag);
	DeclarationsConnect(&(*p)->_._, NULL, ds, NULL, buf, buf_len0, begin, end);
	(*p)->_.header = Ast_ProcTypeNew();
	(*p)->_._._._.id = Ast_IdProcType_cnst;
	(*p)->_.return_ = NULL;
	if (ds->procedures == NULL) {
		ds->procedures = (*p);
	}
	return err;
}

extern int Ast_ProcedureSetReturn(struct Ast_RProcedure *p, o7c_tag_t p_tag, struct Ast_RExpression *e, o7c_tag_t e_tag) {
	int err;

	assert(p->_.return_ == NULL);
	err = Ast_ErrNo_cnst;
	if (p->_.header->_._._.type == NULL) {
		err = Ast_ErrProcHasNoReturn_cnst;
	} else if (e != NULL) {
		p->_.return_ = e;
		if (!Ast_CompatibleTypes(&p->distance, p->_.header->_._._.type, NULL, e->type, NULL) && !CompatibleAsCharAndString(p->_.header->_._._.type, NULL, &p->_.return_, NULL)) {
			err = Ast_ErrReturnIncompatibleType_cnst;
		}
	}
	return err;
}

extern int Ast_ProcedureEnd(struct Ast_RProcedure *p, o7c_tag_t p_tag) {
	int err;

	if ((p->_.header->_._._.type != NULL) && (p->_.return_ == NULL)) {
		err = Ast_ErrExpectReturn_cnst;
	} else {
		err = Ast_ErrNo_cnst;
	}
	return err;
}

static bool CallParamNew_TypeVariation(struct Ast_ExprCall_s *call, o7c_tag_t call_tag, struct Ast_RType *tp, o7c_tag_t tp_tag, struct Ast_FormalParam_s *fp, o7c_tag_t fp_tag) {
	bool comp;
	int id;

	comp = o7c_is(NULL, call->designator->decl, Ast_PredefinedProcedure_s_tag);
	if (comp) {
		id = call->designator->decl->_.id;
		if (id == Scanner_New_cnst) {
			comp = tp->_._.id == Ast_IdPointer_cnst;
		} else if (id == Scanner_Abs_cnst) {
			comp = ( (1u << tp->_._.id) & ((1 << Ast_IdInteger_cnst) | (1 << Ast_IdReal_cnst)));
			call->_._.type = tp;
		} else if (id == Scanner_Len_cnst) {
			comp = tp->_._.id == Ast_IdArray_cnst;
		} else {
			comp = (id == Scanner_Ord_cnst) && (( (1u << tp->_._.id) & ((1 << Ast_IdInteger_cnst) | (1 << Ast_IdChar_cnst) | (1 << Ast_IdSet_cnst) | (1 << Ast_IdBoolean_cnst))));
		}
	}
	return comp;
}

static void CallParamNew_ParamsVariation(struct Ast_ExprCall_s *call, o7c_tag_t call_tag, struct Ast_RExpression *e, o7c_tag_t e_tag, int *err) {
	int id;

	id = call->designator->decl->_.id;
	if (id != Ast_IdError_cnst) {
		if ((id != Scanner_Inc_cnst) && (id != Scanner_Dec_cnst) || (call->params->next != NULL)) {
			(*err) = Ast_ErrCallExcessParam_cnst;
		} else if (e->type->_._.id != Ast_IdInteger_cnst) {
			(*err) = Ast_ErrCallIncompatibleParamType_cnst;
		}
	}
}

extern int Ast_CallParamNew(struct Ast_ExprCall_s *call, o7c_tag_t call_tag, struct Ast_Parameter_s **lastParam, o7c_tag_t lastParam_tag, struct Ast_RExpression *e, o7c_tag_t e_tag, struct Ast_FormalParam_s **currentFormalParam, o7c_tag_t currentFormalParam_tag) {
	int err;
	int distance;

	err = Ast_ErrNo_cnst;
	if ((*currentFormalParam) != NULL) {
		if (!Ast_CompatibleTypes(&distance, (*currentFormalParam)->_._.type, NULL, e->type, NULL) && !CompatibleAsCharAndString((*currentFormalParam)->_._.type, NULL, &e, NULL) && !CallParamNew_TypeVariation(call, NULL, e->type, NULL, (*currentFormalParam), NULL)) {
			err = Ast_ErrCallIncompatibleParamType_cnst;
		} else if ((*currentFormalParam)->isVar && !(Ast_IsVar(e, NULL) && Ast_IsChangeable(call->designator->decl->module, NULL, (&O7C_GUARD(Ast_RVar, (&O7C_GUARD(Ast_Designator_s, e, NULL))->decl, NULL)), NULL))) {
			err = Ast_ErrCallExpectVarParam_cnst;
		}
		if (((*currentFormalParam)->_._.next != NULL) && (o7c_is(NULL, (*currentFormalParam)->_._.next, Ast_FormalParam_s_tag))) {
			(*currentFormalParam) = (&O7C_GUARD(Ast_FormalParam_s, (*currentFormalParam)->_._.next, NULL));
		} else {
			(*currentFormalParam) = NULL;
		}
	} else {
		distance = 0;
		CallParamNew_ParamsVariation(call, NULL, e, NULL, &err);
	}
	if ((*lastParam) == NULL) {
		(*lastParam) = o7c_new(sizeof(*(*lastParam)), Ast_Parameter_s_tag);
	} else {
		assert((*lastParam)->next == NULL);
		(*lastParam)->next = o7c_new(sizeof(*(*lastParam)->next), Ast_Parameter_s_tag);
		(*lastParam) = (*lastParam)->next;
	}
	NodeInit(&(*(*lastParam))._, Ast_Parameter_s_tag);
	(*lastParam)->expr = e;
	(*lastParam)->distance = distance;
	(*lastParam)->next = NULL;
	return err;
}

extern int Ast_CallParamsEnd(struct Ast_ExprCall_s *call, o7c_tag_t call_tag, struct Ast_FormalParam_s *currentFormalParam, o7c_tag_t currentFormalParam_tag) {
	struct Ast_RFactor *v;
	char unsigned ch;

	if ((currentFormalParam == NULL) && (o7c_is(NULL, call->designator->decl, Ast_PredefinedProcedure_s_tag)) && (call->designator->decl->type->_.type != NULL)) {
		v = call->params->expr->value_;
		if (v != NULL) {
			switch (call->designator->decl->_.id) {
			case 90:
				if (v->_.type->_._.id == Ast_IdReal_cnst) {
					if ((&O7C_GUARD(Ast_ExprReal_s, v, NULL))->real < 0.0) {
						call->_._.value_ = (&(Ast_ExprRealNewByValue( - (&O7C_GUARD(Ast_ExprReal_s, v, NULL))->real))->_._);
					} else {
						call->_._.value_ = v;
					}
				} else {
					assert(v->_.type->_._.id == Ast_IdInteger_cnst);
					call->_._.value_ = (&(Ast_ExprIntegerNew(abs((&O7C_GUARD(Ast_RExprInteger, v, NULL))->int_)))->_._);
				}
				break;
			case 107:
				call->_._.value_ = (&(Ast_ExprBooleanNew(((&O7C_GUARD(Ast_RExprInteger, v, NULL))->int_ % 2 == 1)))->_);
				break;
			case 105:
				if (call->params->next->expr->value_ != NULL) {
					call->_._.value_ = (&(Ast_ExprIntegerNew((int)((unsigned)(&O7C_GUARD(Ast_RExprInteger, v, NULL))->int_ << (&O7C_GUARD(Ast_RExprInteger, call->params->next->expr->value_, NULL))->int_)))->_._);
				}
				break;
			case 91:
				if (call->params->next->expr->value_ != NULL) {
					call->_._.value_ = (&(Ast_ExprIntegerNew((int)((unsigned)(&O7C_GUARD(Ast_RExprInteger, v, NULL))->int_ >> (&O7C_GUARD(Ast_RExprInteger, call->params->next->expr->value_, NULL))->int_)))->_._);
				}
				break;
			case 111:
				if (call->params->next->expr->value_ != NULL) {
					call->_._.value_ = (&(Ast_ExprIntegerNew((int)((unsigned)(&O7C_GUARD(Ast_RExprInteger, v, NULL))->int_ >> (&O7C_GUARD(Ast_RExprInteger, call->params->next->expr->value_, NULL))->int_)))->_._);
				}
				break;
			case 99:
				call->_._.value_ = (&(Ast_ExprIntegerNew((int)(&O7C_GUARD(Ast_ExprReal_s, v, NULL))->real))->_._);
				break;
			case 100:
				call->_._.value_ = (&(Ast_ExprRealNewByValue((double)(&O7C_GUARD(Ast_RExprInteger, v, NULL))->int_))->_._);
				break;
			case 108:
				if (v->_.type->_._.id == Ast_IdChar_cnst) {
					call->_._.value_ = v;
				} else if (o7c_is(NULL, v, Ast_ExprString_s_tag)) {
					if ((&O7C_GUARD(Ast_ExprString_s, v, NULL))->_.int_ >  - 1) {
						call->_._.value_ = (&(Ast_ExprIntegerNew((int)ch))->_._);
					} else {
						assert(false);
					}
				} else if (v->_.type->_._.id == Ast_IdBoolean_cnst) {
					call->_._.value_ = (&(Ast_ExprIntegerNew((int)(&O7C_GUARD(Ast_ExprBoolean_s, v, NULL))->bool_))->_._);
				} else if (v->_.type->_._.id == Ast_IdSet_cnst) {
					call->_._.value_ = (&(Ast_ExprIntegerNew((int)(&O7C_GUARD(Ast_ExprSet_s, v, NULL))->set))->_._);
				} else {
					Log_Str("Неправильный id типа = ", 40);
					Log_Int(v->_.type->_._.id);
					Log_Ln();
					assert(false);
				}
				break;
			case 96:
				call->_._.value_ = v;
				break;
			default:
				abort();
				break;
			}
		} else if ((call->designator->decl->_.id == Scanner_Len_cnst) && ((&O7C_GUARD(Ast_RArray, call->params->expr->type, NULL))->count != NULL)) {
			call->_._.value_ = (&O7C_GUARD(Ast_RArray, call->params->expr->type, NULL))->count->value_;
		}
	}
	return (int)(currentFormalParam != NULL) * Ast_ErrCallParamsNotEnough_cnst;
}

static void StatInit(struct Ast_RStatement *s, o7c_tag_t s_tag, struct Ast_RExpression *e, o7c_tag_t e_tag) {
	NodeInit(&(*s)._, Ast_RStatement_tag);
	s->expr = e;
	s->next = NULL;
}

extern int Ast_CallNew(struct Ast_Call_s **c, o7c_tag_t c_tag, struct Ast_Designator_s *des, o7c_tag_t des_tag) {
	int err;
	struct Ast_ExprCall_s *e;

	err = ExprCallCreate(&e, NULL, des, NULL, false);
	(*c) = o7c_new(sizeof(*(*c)), Ast_Call_s_tag);
	StatInit(&(*c)->_, NULL, &e->_._, NULL);
	return err;
}

extern struct Ast_If_s *Ast_IfNew(struct Ast_RExpression *expr, o7c_tag_t expr_tag, struct Ast_RStatement *stats, o7c_tag_t stats_tag) {
	struct Ast_If_s *if_;

	if_ = o7c_new(sizeof(*if_), Ast_If_s_tag);
	StatInit(&if_->_._, NULL, expr, NULL);
	if_->_.stats = stats;
	if_->_.elsif = NULL;
	return if_;
}

extern struct Ast_While_s *Ast_WhileNew(struct Ast_RExpression *expr, o7c_tag_t expr_tag, struct Ast_RStatement *stats, o7c_tag_t stats_tag) {
	struct Ast_While_s *w;

	w = o7c_new(sizeof(*w), Ast_While_s_tag);
	StatInit(&w->_._, NULL, expr, NULL);
	w->_.stats = stats;
	w->_.elsif = NULL;
	return w;
}

extern struct Ast_Repeat_s *Ast_RepeatNew(struct Ast_RExpression *expr, o7c_tag_t expr_tag, struct Ast_RStatement *stats, o7c_tag_t stats_tag) {
	struct Ast_Repeat_s *r;

	r = o7c_new(sizeof(*r), Ast_Repeat_s_tag);
	StatInit(&r->_, NULL, expr, NULL);
	r->stats = stats;
	return r;
}

extern struct Ast_For_s *Ast_ForNew(struct Ast_RVar *var_, o7c_tag_t var__tag, struct Ast_RExpression *init, o7c_tag_t init_tag, struct Ast_RExpression *to, o7c_tag_t to_tag, int by, struct Ast_RStatement *stats, o7c_tag_t stats_tag) {
	struct Ast_For_s *f;

	f = o7c_new(sizeof(*f), Ast_For_s_tag);
	StatInit(&f->_, NULL, init, NULL);
	f->var_ = var_;
	f->to = to;
	f->by = by;
	f->stats = stats;
	return f;
}

extern int Ast_CaseNew(struct Ast_Case_s **case_, o7c_tag_t case__tag, struct Ast_RExpression *expr, o7c_tag_t expr_tag) {
	int err;

	(*case_) = o7c_new(sizeof(*(*case_)), Ast_Case_s_tag);
	StatInit(&(*case_)->_, NULL, expr, NULL);
	(*case_)->elements = NULL;
	if ((expr->type != NULL) && !(( (1u << expr->type->_._.id) & ((1 << Ast_IdInteger_cnst) | (1 << Ast_IdChar_cnst))))) {
		err = Ast_ErrCaseExprNotIntOrChar_cnst;
	} else {
		err = Ast_ErrNo_cnst;
	}
	return err;
}

static int CaseRangeSearch(struct Ast_Case_s *case_, o7c_tag_t case__tag, int int_) {
	struct Ast_CaseElement_s *e;

	e = case_->elements;
	if (e != NULL) {
		while (e->next != NULL) {
			e = e->next;
		}
		if (e->stats != NULL) {
			e = NULL;
		}
	}
	return 0;
}

extern int Ast_CaseLabelNew(struct Ast_CaseLabel_s **label, o7c_tag_t label_tag, int id, int value_) {
	assert(( (1u << id) & ((1 << Ast_IdInteger_cnst) | (1 << Ast_IdChar_cnst))));
	(*label) = o7c_new(sizeof(*(*label)), Ast_CaseLabel_s_tag);
	NodeInit(&(*(*label))._, Ast_CaseLabel_s_tag);
	(*label)->qual = NULL;
	(*label)->_.id = id;
	(*label)->value_ = value_;
	(*label)->right = NULL;
	(*label)->next = NULL;
	return Ast_ErrNo_cnst;
}

extern int Ast_CaseLabelQualNew(struct Ast_CaseLabel_s **label, o7c_tag_t label_tag, struct Ast_RDeclaration *decl, o7c_tag_t decl_tag) {
	int err;
	int i;

	if (!(o7c_is(NULL, decl, Ast_Const_s_tag))) {
		err = Ast_ErrCaseLabelNotConst_cnst;
	} else if (!(( (1u << (&O7C_GUARD(Ast_Const_s, decl, NULL))->expr->type->_._.id) & ((1 << Ast_IdInteger_cnst) | (1 << Ast_IdChar_cnst)))) && !((o7c_is(NULL, (&O7C_GUARD(Ast_Const_s, decl, NULL))->expr, Ast_ExprString_s_tag)) && ((&O7C_GUARD(Ast_ExprString_s, (&O7C_GUARD(Ast_Const_s, decl, NULL))->expr, NULL))->_.int_ >  - 1))) {
		err = Ast_ErrCaseExprNotIntOrChar_cnst;
	} else {
		if ((&O7C_GUARD(Ast_Const_s, decl, NULL))->expr->type->_._.id == Ast_IdInteger_cnst) {
			err = Ast_CaseLabelNew(&(*label), NULL, Ast_IdInteger_cnst, (&O7C_GUARD(Ast_RExprInteger, (&O7C_GUARD(Ast_Const_s, decl, NULL))->expr->value_, NULL))->int_);
		} else {
			i = (&O7C_GUARD(Ast_ExprString_s, (&O7C_GUARD(Ast_Const_s, decl, NULL))->expr->value_, NULL))->_.int_;
			if (i < 0) {
				i = (int)(&O7C_GUARD(Ast_ExprString_s, (&O7C_GUARD(Ast_Const_s, decl, NULL))->expr->value_, NULL))->string.block->s[0];
			}
			err = Ast_CaseLabelNew(&(*label), NULL, Ast_IdChar_cnst, i);
		}
		if ((*label) != NULL) {
			(*label)->qual = decl;
		}
	}
	return err;
}

extern int Ast_CaseRangeNew(struct Ast_CaseLabel_s *left, o7c_tag_t left_tag, struct Ast_CaseLabel_s *right, o7c_tag_t right_tag) {
	int err;

	assert((left->right == NULL) && (left->next == NULL));
	assert((right == NULL) || (right->right == NULL) && (right->next == NULL));
	left->right = right;
	if ((right != NULL) && (left->_.id != right->_.id)) {
		err = Ast_ErrCaseRangeLabelsTypeMismatch_cnst;
	} else if (left->value_ >= right->value_) {
		err = Ast_ErrCaseLabelLeftNotLessRight_cnst;
	} else {
		err = Ast_ErrNo_cnst;
	}
	return err;
}

static bool IsRangesCross(struct Ast_CaseLabel_s *l1, o7c_tag_t l1_tag, struct Ast_CaseLabel_s *l2, o7c_tag_t l2_tag) {
	bool cross;

	if (l1->value_ < l2->value_) {
		cross = (l1->right != NULL) && (l1->right->value_ >= l2->value_);
	} else {
		cross = (l1->value_ == l2->value_) || (l2->right != NULL) && (l2->right->value_ >= l1->value_);
	}
	return cross;
}

static bool IsListCrossRange(struct Ast_CaseLabel_s *list, o7c_tag_t list_tag, struct Ast_CaseLabel_s *range, o7c_tag_t range_tag) {
	while ((list != NULL) && !IsRangesCross(list, NULL, range, NULL)) {
		list = list->next;
	}
	return list != NULL;
}

static bool IsElementsCrossRange(struct Ast_CaseElement_s *elem, o7c_tag_t elem_tag, struct Ast_CaseLabel_s *range, o7c_tag_t range_tag) {
	while ((elem != NULL) && !IsListCrossRange(elem->labels, NULL, range, NULL)) {
		elem = elem->next;
	}
	return elem != NULL;
}

extern int Ast_CaseRangeListAdd(struct Ast_Case_s *case_, o7c_tag_t case__tag, struct Ast_CaseLabel_s *first, o7c_tag_t first_tag, struct Ast_CaseLabel_s *new_, o7c_tag_t new__tag) {
	int err;

	assert(new_->next == NULL);
	if (case_->_.expr->type->_._.id != new_->_.id) {
		err = Ast_ErrCaseRangeLabelsTypeMismatch_cnst;
	} else {
		if (IsElementsCrossRange(case_->elements, NULL, new_, NULL)) {
			err = Ast_ErrCaseElemDuplicate_cnst;
		} else {
			err = Ast_ErrNo_cnst;
		}
		while (first->next != NULL) {
			first = first->next;
		}
		first->next = new_;
	}
	return err;
}

extern struct Ast_CaseElement_s *Ast_CaseElementNew(struct Ast_CaseLabel_s *labels, o7c_tag_t labels_tag) {
	struct Ast_CaseElement_s *elem;

	elem = o7c_new(sizeof(*elem), Ast_CaseElement_s_tag);
	NodeInit(&(*elem)._, Ast_CaseElement_s_tag);
	elem->next = NULL;
	elem->labels = labels;
	elem->stats = NULL;
	return elem;
}

extern int Ast_CaseElementAdd(struct Ast_Case_s *case_, o7c_tag_t case__tag, struct Ast_CaseElement_s *elem, o7c_tag_t elem_tag) {
	int err;
	struct Ast_CaseElement_s *last;

	if (case_->elements == NULL) {
		case_->elements = elem;
	} else {
		last = case_->elements;
		while (last->next != NULL) {
			last = last->next;
		}
		last->next = elem;
	}
	err = Ast_ErrNo_cnst;
	return err;
}

extern int Ast_AssignNew(struct Ast_Assign_s **a, o7c_tag_t a_tag, struct Ast_Designator_s *des, o7c_tag_t des_tag, struct Ast_RExpression *expr, o7c_tag_t expr_tag) {
	int err;

	(*a) = o7c_new(sizeof(*(*a)), Ast_Assign_s_tag);
	StatInit(&(*a)->_, NULL, expr, NULL);
	(*a)->designator = des;
	if ((expr != NULL) && (des != NULL) && !Ast_CompatibleTypes(&(*a)->distance, des->_._.type, NULL, expr->type, NULL) && !CompatibleAsCharAndString(des->_._.type, NULL, &(*a)->_.expr, NULL)) {
		err = Ast_ErrAssignIncompatibleType_cnst;
	} else {
		err = Ast_ErrNo_cnst;
	}
	return err;
}

extern struct Ast_StatementError_s *Ast_StatementErrorNew(void) {
	struct Ast_StatementError_s *s;

	s = o7c_new(sizeof(*s), Ast_StatementError_s_tag);
	StatInit(&s->_, NULL, NULL, NULL);
	return s;
}

static void PredefinedDeclarationsInit(void);
static void PredefinedDeclarationsInit_TypeNew(int s, int t) {
	struct Ast_RType *td;
	struct Ast_Byte_s *tb;

	if (true || (s != Scanner_Byte_cnst)) {
		td = o7c_new(sizeof(*td), Ast_RType_tag);
	} else {
		tb = o7c_new(sizeof(*tb), Ast_Byte_s_tag);
		td = (&(tb)->_);
	}
	TInit(td, NULL, t);
	predefined[s - Scanner_PredefinedFirst_cnst] = (&(td)->_);
	types[t] = td;
}

static struct Ast_ProcType_s *PredefinedDeclarationsInit_ProcNew(int s, int t) {
	struct Ast_PredefinedProcedure_s *td;

	td = o7c_new(sizeof(*td), Ast_PredefinedProcedure_s_tag);
	NodeInit(&(*td)._._._._, Ast_PredefinedProcedure_s_tag);
	DeclInit(&td->_._._, NULL, NULL, NULL);
	predefined[s - Scanner_PredefinedFirst_cnst] = (&(td)->_._._);
	td->_.header = Ast_ProcTypeNew();
	td->_._._.type = (&(td->_.header)->_._);
	td->_._._._.id = s;
	if (t > Ast_NoId_cnst) {
		td->_.header->_._._.type = Ast_TypeGet(t);
	}
	return td->_.header;
}

static void PredefinedDeclarationsInit(void) {
	struct Ast_ProcType_s *tp;
	struct Ast_RType *typeInt;
	struct Ast_RType *typeReal;

	PredefinedDeclarationsInit_TypeNew(Scanner_Byte_cnst, Ast_IdByte_cnst);
	PredefinedDeclarationsInit_TypeNew(Scanner_Integer_cnst, Ast_IdInteger_cnst);
	PredefinedDeclarationsInit_TypeNew(Scanner_Char_cnst, Ast_IdChar_cnst);
	PredefinedDeclarationsInit_TypeNew(Scanner_Set_cnst, Ast_IdSet_cnst);
	PredefinedDeclarationsInit_TypeNew(Scanner_Boolean_cnst, Ast_IdBoolean_cnst);
	PredefinedDeclarationsInit_TypeNew(Scanner_Real_cnst, Ast_IdReal_cnst);
	types[Ast_IdPointer_cnst] = o7c_new(sizeof(*types[Ast_IdPointer_cnst]), Ast_RType_tag);
	NodeInit(&(*types[Ast_IdPointer_cnst])._._, Ast_RType_tag);
	DeclInit(&types[Ast_IdPointer_cnst]->_, NULL, NULL, NULL);
	types[Ast_IdPointer_cnst]->_._.id = Ast_IdPointer_cnst;
	typeInt = Ast_TypeGet(Ast_IdInteger_cnst);
	tp = PredefinedDeclarationsInit_ProcNew(Scanner_Abs_cnst, Ast_IdInteger_cnst);
	ParamAddPredefined(tp, NULL, typeInt, NULL, false);
	tp = PredefinedDeclarationsInit_ProcNew(Scanner_Asr_cnst, Ast_IdInteger_cnst);
	ParamAddPredefined(tp, NULL, typeInt, NULL, false);
	ParamAddPredefined(tp, NULL, typeInt, NULL, false);
	tp = PredefinedDeclarationsInit_ProcNew(Scanner_Assert_cnst, Ast_NoId_cnst);
	ParamAddPredefined(tp, NULL, Ast_TypeGet(Ast_IdBoolean_cnst), NULL, false);
	tp = PredefinedDeclarationsInit_ProcNew(Scanner_Chr_cnst, Ast_IdChar_cnst);
	ParamAddPredefined(tp, NULL, typeInt, NULL, false);
	tp = PredefinedDeclarationsInit_ProcNew(Scanner_Dec_cnst, Ast_NoId_cnst);
	ParamAddPredefined(tp, NULL, typeInt, NULL, false);
	tp = PredefinedDeclarationsInit_ProcNew(Scanner_Excl_cnst, Ast_NoId_cnst);
	ParamAddPredefined(tp, NULL, Ast_TypeGet(Ast_IdSet_cnst), NULL, true);
	ParamAddPredefined(tp, NULL, typeInt, NULL, false);
	typeReal = Ast_TypeGet(Ast_IdReal_cnst);
	tp = PredefinedDeclarationsInit_ProcNew(Scanner_Floor_cnst, Ast_IdInteger_cnst);
	ParamAddPredefined(tp, NULL, typeReal, NULL, false);
	tp = PredefinedDeclarationsInit_ProcNew(Scanner_Flt_cnst, Ast_IdReal_cnst);
	ParamAddPredefined(tp, NULL, typeInt, NULL, false);
	tp = PredefinedDeclarationsInit_ProcNew(Scanner_Inc_cnst, Ast_NoId_cnst);
	ParamAddPredefined(tp, NULL, typeInt, NULL, true);
	tp = PredefinedDeclarationsInit_ProcNew(Scanner_Incl_cnst, Ast_NoId_cnst);
	ParamAddPredefined(tp, NULL, Ast_TypeGet(Ast_IdSet_cnst), NULL, true);
	ParamAddPredefined(tp, NULL, typeInt, NULL, false);
	tp = PredefinedDeclarationsInit_ProcNew(Scanner_Len_cnst, Ast_IdInteger_cnst);
	ParamAddPredefined(tp, NULL, &Ast_ArrayGet(typeInt, NULL, NULL, NULL)->_._, NULL, false);
	tp = PredefinedDeclarationsInit_ProcNew(Scanner_Lsl_cnst, Ast_IdInteger_cnst);
	ParamAddPredefined(tp, NULL, typeInt, NULL, false);
	ParamAddPredefined(tp, NULL, typeInt, NULL, false);
	tp = PredefinedDeclarationsInit_ProcNew(Scanner_New_cnst, Ast_NoId_cnst);
	ParamAddPredefined(tp, NULL, Ast_TypeGet(Ast_IdPointer_cnst), NULL, true);
	tp = PredefinedDeclarationsInit_ProcNew(Scanner_Odd_cnst, Ast_IdBoolean_cnst);
	ParamAddPredefined(tp, NULL, typeInt, NULL, false);
	tp = PredefinedDeclarationsInit_ProcNew(Scanner_Ord_cnst, Ast_IdInteger_cnst);
	ParamAddPredefined(tp, NULL, Ast_TypeGet(Ast_IdChar_cnst), NULL, false);
	tp = PredefinedDeclarationsInit_ProcNew(Scanner_Pack_cnst, Ast_IdReal_cnst);
	ParamAddPredefined(tp, NULL, typeReal, NULL, true);
	tp = PredefinedDeclarationsInit_ProcNew(Scanner_Ror_cnst, Ast_IdInteger_cnst);
	ParamAddPredefined(tp, NULL, typeInt, NULL, false);
	ParamAddPredefined(tp, NULL, typeInt, NULL, false);
	tp = PredefinedDeclarationsInit_ProcNew(Scanner_Unpk_cnst, Ast_IdReal_cnst);
	ParamAddPredefined(tp, NULL, typeReal, NULL, true);
}

extern bool Ast_HasError(struct Ast_RModule *m, o7c_tag_t m_tag) {
	return m->errLast != NULL;
}

extern void Ast_ProviderInit(struct Ast_RProvider *p, o7c_tag_t p_tag, Ast_Provide get) {
	V_Init(&(*p)._, Ast_RProvider_tag);
	p->get = get;
}

extern void Ast_init_(void) {
	static int initialized__ = 0;
	if (0 == initialized__) {
		Log_init_();
		Utf8_init_();
		Limits_init_();
		V_init_();
		Scanner_init_();
		StringStore_init_();
		TranslatorLimits_init_();

		o7c_tag_init(Ast_RProvider_tag, V_Base_tag);
		o7c_tag_init(Ast_Node_tag, V_Base_tag);
		o7c_tag_init(Ast_Error_s_tag, Ast_Node_tag);
		o7c_tag_init(Ast_RDeclaration_tag, Ast_Node_tag);
		o7c_tag_init(Ast_RType_tag, Ast_RDeclaration_tag);
		o7c_tag_init(Ast_Byte_s_tag, Ast_RType_tag);
		o7c_tag_init(Ast_Const_s_tag, Ast_RDeclaration_tag);
		o7c_tag_init(Ast_RConstruct_tag, Ast_RType_tag);
		o7c_tag_init(Ast_RArray_tag, Ast_RConstruct_tag);
		o7c_tag_init(Ast_Record_s_tag, Ast_RConstruct_tag);
		o7c_tag_init(Ast_RPointer_tag, Ast_RConstruct_tag);
		o7c_tag_init(Ast_RVar_tag, Ast_RDeclaration_tag);
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
	++initialized__;
}


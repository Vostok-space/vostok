/* Copyright 2025 ComdivByZero
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#if !defined HEADER_GUARD_Real64
#    define  HEADER_GUARD_Real64 1

#include "o7.h"

typedef struct Real64_T {
    double v;
} Real64_T;
#define Real64_T_tag o7_base_tag

O7_ALWAYS_INLINE void Real64_T_undef(void *v) { ((Real64_T*)v)->v = O7_DBL_UNDEF; }

O7_CONST_INLINE o7_cbool Real64_IsNan(Real64_T *r) { return r->v != r->v; }
O7_CONST_INLINE o7_cbool Real64_IsFinite(Real64_T *r) { return o7_isfinite(r->v); }

O7_ALWAYS_INLINE void Real64_From(Real64_T *r, double s) { r->v = s; }

O7_ALWAYS_INLINE o7_cbool Real64_To(double *r, Real64_T *s) {
    o7_cbool ok;

    ok = o7_isfinite(s->v);
    if (ok) { *r = s->v; }
    return ok;
}

O7_ALWAYS_INLINE void Real64_Neg(Real64_T *r, Real64_T *a) { r->v = -a->v; }
O7_ALWAYS_INLINE void Real64_Add(Real64_T *r, Real64_T *a, Real64_T *b) { r->v = a->v + b->v; }
O7_ALWAYS_INLINE void Real64_Sub(Real64_T *r, Real64_T *a, Real64_T *b) { r->v = a->v - b->v; }
O7_ALWAYS_INLINE void Real64_Mul(Real64_T *r, Real64_T *a, Real64_T *b) { r->v = a->v * b->v; }
O7_ALWAYS_INLINE void Real64_Div(Real64_T *r, Real64_T *a, Real64_T *b) { r->v = a->v / b->v; }

O7_ALWAYS_INLINE void Real64_Pack(Real64_T *r, o7_int_t  n) {
    r->v = o7_c_ldexp(r->v, n);
}
O7_ALWAYS_INLINE void Real64_Unpk(Real64_T *r, o7_int_t *n) {
    r->v = o7_c_frexp(r->v, n);
}

O7_CONST_INLINE o7_int_t Real64_CmpReal(Real64_T *a, double b) {
    o7_int_t c;

    if (a->v < b) {
        c = -1;
    } else if (a->v > b) {
        c = +1;
    } else {
        c = 0;
    }
    return c;
}

O7_CONST_INLINE o7_int_t Real64_Cmp(Real64_T *a, struct Real64_T *b) {
    return Real64_CmpReal(a, b->v);
}

O7_ALWAYS_INLINE void Real64_init(void) {}
O7_ALWAYS_INLINE void Real64_done(void) {}

#endif

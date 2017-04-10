/*  Base extensible records for Translator
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
 *)
(* база всего сущего, авось пригодится для чего-нибудь эдакого */
#if !defined(HEADER_GUARD_V)
#define HEADER_GUARD_V


#define V_ContentPassOpen_cnst 0
#define V_ContentPassNext_cnst 1
#define V_ContentPassClose_cnst 2

typedef struct V_Message { int nothing; } V_Message;
extern o7c_tag_t V_Message_tag;

typedef struct V_Message *V_PMessage;
typedef struct V_Base {
	V_Message _;
	o7c_bool (*do_)(struct V_Base *this_, o7c_tag_t this__tag, struct V_Message *mes, o7c_tag_t mes_tag);
} V_Base;
extern o7c_tag_t V_Base_tag;

typedef struct V_Base *V_PBase;
typedef struct V_Error {
	V_Base _;
} V_Error;
extern o7c_tag_t V_Error_tag;

typedef struct V_Error *V_PError;
typedef o7c_bool (*V_Handle)(struct V_Base *this_, o7c_tag_t this__tag, struct V_Message *mes, o7c_tag_t mes_tag);
typedef struct V_MsgFinalize {
	V_Base _;
} V_MsgFinalize;
extern o7c_tag_t V_MsgFinalize_tag;

typedef struct V_MsgNeedMemory {
	V_Base _;
} V_MsgNeedMemory;
extern o7c_tag_t V_MsgNeedMemory_tag;

typedef struct V_MsgCopy {
	V_Base _;
	struct V_Base *copy;
} V_MsgCopy;
extern o7c_tag_t V_MsgCopy_tag;

typedef struct V_MsgLinks {
	V_Base _;
	int diff;
	int count;
} V_MsgLinks;
extern o7c_tag_t V_MsgLinks_tag;

typedef struct V_MsgContentPass {
	V_Base _;
	int id;
} V_MsgContentPass;
extern o7c_tag_t V_MsgContentPass_tag;

typedef struct V_MsgHash {
	V_Base _;
	int hash;
} V_MsgHash;
extern o7c_tag_t V_MsgHash_tag;


extern void V_Init(struct V_Base *base, o7c_tag_t base_tag);

extern void V_SetDo(struct V_Base *base, o7c_tag_t base_tag, V_Handle do_);

extern o7c_bool V_Do(struct V_Base *handler, o7c_tag_t handler_tag, struct V_Message *message, o7c_tag_t message_tag);

extern void V_init(void);
#endif

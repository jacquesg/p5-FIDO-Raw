#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newRV_noinc
#define NEED_sv_2pvbyte
#define NEED_sv_2pv_flags

#include "ppport.h"

#ifndef MUTABLE_AV
#define MUTABLE_AV(p) ((AV *)MUTABLE_PTR(p))
#endif

/* internally generated errors */
#define ASSERT            -10000
#define USAGE             -10001
#define RESOLVE           -10002

/* internally generated classes */
#define INTERNAL          -20000

#ifdef _MSC_VER
#pragma warning (disable : 4244 4267 )
#endif


STATIC MGVTBL null_mg_vtbl = {
	NULL, /* get */
	NULL, /* set */
	NULL, /* len */
	NULL, /* clear */
	NULL, /* free */
#if MGf_COPY
	NULL, /* copy */
#endif /* MGf_COPY */
#if MGf_DUP
	NULL, /* dup */
#endif /* MGf_DUP */
#if MGf_LOCAL
	NULL, /* local */
#endif /* MGf_LOCAL */
};

STATIC void xs_object_magic_attach_struct (pTHX_ SV *sv, void *ptr)
{
	sv_magicext (sv, NULL, PERL_MAGIC_ext, &null_mg_vtbl, ptr, 0);
}

STATIC void *xs_object_magic_get_struct (pTHX_ SV *sv)
{
	MAGIC *mg = NULL;

	if (SvTYPE (sv) >= SVt_PVMG)
	{
		MAGIC *tmp;

		for (tmp = SvMAGIC(sv); tmp;
			tmp = tmp -> mg_moremagic) {
			if ((tmp -> mg_type == PERL_MAGIC_ext) &&
				(tmp -> mg_virtual == &null_mg_vtbl))
				mg = tmp;
		}
	}

	return (mg) ? mg -> mg_ptr : NULL;
}

#define FIDO_SV_TO_MAGIC(SV) \
	xs_object_magic_get_struct(aTHX_ SvRV(SV))

#define FIDO_NEW_OBJ(rv, class, sv)				\
	STMT_START {						\
		(rv) = sv_setref_pv(newSV(0), class, sv);	\
	} STMT_END

#define FIDO_NEW_OBJ_WITH_MAGIC(rv, class, sv, magic)		\
	STMT_START {						\
		(rv) = sv_setref_pv(newSV(0), class, sv);	\
								\
		xs_object_magic_attach_struct(			\
			aTHX_ SvRV(rv), SvREFCNT_inc_NN(magic)	\
		);						\
	} STMT_END

#define FIDO_OBJ_SET_MAGIC(sv, magic) \
	STMT_START {						\
		xs_object_magic_attach_struct(			\
			aTHX_ SvRV(sv), SvREFCNT_inc_NN(magic)	\
		);						\
	} STMT_END


MODULE = FIDO::Raw			PACKAGE = FIDO::Raw

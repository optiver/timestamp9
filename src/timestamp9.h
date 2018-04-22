
#pragma once

extern "C" {

#include <ctype.h>
#include "fmgr.h"

}

typedef long long timestamp9;

#define DatumGetTimestamp9(X) ((timestamp9) GET_8_BYTES(X))
#define Timestamp9GetDatum(X) ((Datum) SET_8_BYTES(X))

#define PG_GETARG_TIMESTAMP9(n)	DatumGetTimestamp9(PG_GETARG_DATUM(n))
#define PG_RETURN_TIMESTAMP9(x)	return Timestamp9GetDatum(x)

extern "C" {

extern Datum timestamp9_in(PG_FUNCTION_ARGS);
extern Datum timestamp9_out(PG_FUNCTION_ARGS);
extern Datum timestamp9_recv(PG_FUNCTION_ARGS);
extern Datum timestamp9_send(PG_FUNCTION_ARGS);

extern Datum timestamp9_eq(PG_FUNCTION_ARGS);
extern Datum timestamp9_ne(PG_FUNCTION_ARGS);
extern Datum timestamp9_lt(PG_FUNCTION_ARGS);
extern Datum timestamp9_le(PG_FUNCTION_ARGS);
extern Datum timestamp9_gt(PG_FUNCTION_ARGS);
extern Datum timestamp9_ge(PG_FUNCTION_ARGS);

extern Datum bt_timestamp9_cmp(PG_FUNCTION_ARGS);

extern Datum timestamp9_to_timestamptz(PG_FUNCTION_ARGS);
extern Datum timestamptz_to_timestamp9(PG_FUNCTION_ARGS);
}


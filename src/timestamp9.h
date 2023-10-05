
#pragma once

#include <ctype.h>
#include "fmgr.h"
#include "postgres.h"

#define PG16_GE (PG_VERSION_NUM >= 160000)

typedef long long timestamp9;

#define DatumGetTimestamp9(X) ((timestamp9) (X))
#define Timestamp9GetDatum(X) ((Datum) (X))

#define PG_GETARG_TIMESTAMP9(n)	DatumGetTimestamp9(PG_GETARG_DATUM(n))
#define PG_RETURN_TIMESTAMP9(x)	return Timestamp9GetDatum(x)

#define TIMESTAMP9_END_JULIAN (2547239) /* == date2j(2262, 1, 1) */
#define TIMESTAMP9_MIN_JULIAN (2341973) /* == date2j(1700, 1, 1) */

/* Timestamp limits */
#define MIN_TIMESTAMP9  INT64CONST(-8520336000000000000)
/* == (TIMESTAMP9_MIN_JULIAN - UNIX_EPOCH_JDATE) * (nanoseconds per day) */
#define END_TIMESTAMP9	INT64CONST(9214646400000000000)
/* == (TIMESTAMP9_END_JULIAN - UNIX_EPOCH_JDATE) * (nanoseconds per day) */

/* Range-check a timestamp9 */
#define IS_VALID_TIMESTAMP9(t) (MIN_TIMESTAMP9 <= (t) && (t) < END_TIMESTAMP9)

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
extern Datum timestamp9_to_timestamp(PG_FUNCTION_ARGS);
extern Datum timestamp_to_timestamp9(PG_FUNCTION_ARGS);
extern Datum timestamp9_to_date(PG_FUNCTION_ARGS);
extern Datum date_to_timestamp9(PG_FUNCTION_ARGS);

extern Datum timestamp9_larger(PG_FUNCTION_ARGS);
extern Datum timestamp9_smaller(PG_FUNCTION_ARGS);
extern Datum timestamp9_interval_pl(PG_FUNCTION_ARGS);
extern Datum interval_timestamp9_pl(PG_FUNCTION_ARGS);
extern Datum timestamp9_interval_mi(PG_FUNCTION_ARGS);

int parse_gmt_offset(const char*, bool*);

long long parse_fractional_ratio(const char*, size_t, bool*);

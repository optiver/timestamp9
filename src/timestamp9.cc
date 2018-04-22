extern "C" {
#include "postgres.h"

#include <ctype.h>
#include <limits.h>

#include "access/hash.h"
#include "catalog/pg_type.h"
#include "libpq/pqformat.h"
#include "utils/array.h"
#include "utils/builtins.h"
#include "utils/timestamp.h"
}

#include <ctime>

#include "timestamp9.h"

extern "C" {

PG_MODULE_MAGIC;

PG_FUNCTION_INFO_V1(timestamp9_in);
PG_FUNCTION_INFO_V1(timestamp9_out);
PG_FUNCTION_INFO_V1(timestamp9_recv);
PG_FUNCTION_INFO_V1(timestamp9_send);

PG_FUNCTION_INFO_V1(timestamp9_eq);
PG_FUNCTION_INFO_V1(timestamp9_ne);
PG_FUNCTION_INFO_V1(timestamp9_lt);
PG_FUNCTION_INFO_V1(timestamp9_le);
PG_FUNCTION_INFO_V1(timestamp9_gt);
PG_FUNCTION_INFO_V1(timestamp9_ge);

PG_FUNCTION_INFO_V1(bt_timestamp9_cmp);

PG_FUNCTION_INFO_V1(timestamp9_to_timestamptz);
PG_FUNCTION_INFO_V1(timestamptz_to_timestamp9);
}

/*****************************************************************************
 *	 USER I/O ROUTINES														 *
 *****************************************************************************/

#define kT_ns_in_s  (int64_t)1000000000
#define kT_ns_in_us (int64_t)1000

/*
 *	timestamp9_in		- converts "num" to timestamp9
 */
Datum
timestamp9_in(PG_FUNCTION_ARGS)
{
	char *num = PG_GETARG_CSTRING(0);
	tm tm_{};
	long long ns;
	char plusmin;
	int gmt_offset;
	int num_read = sscanf(num, "%d-%d-%d %d:%d:%d.%lld %c%d", &tm_.tm_year, &tm_.tm_mon, &tm_.tm_mday, &tm_.tm_hour, &tm_.tm_min, &tm_.tm_sec, &ns, &plusmin, &gmt_offset);
	auto ret = 0ll;
	if (num_read == 9)
	{
	  tm_.tm_year -= 1900;
	  tm_.tm_mon--;
	  gmt_offset = ((gmt_offset / 100) * 60 + gmt_offset % 100) * 60;
	  if (plusmin == '-')
		  gmt_offset = -gmt_offset;
	  auto tt = timegm(&tm_);
	  tt = tt + tm_.tm_gmtoff - gmt_offset;
	  ret = (long long)tt * kT_ns_in_s + (ns % kT_ns_in_s);
	}
	else
	{
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("invalid input format for timestamp9, required format y-m-d h:m:s.ns +tz \"%s\"",
						num)));
	}
	PG_RETURN_TIMESTAMP9(ret);
}

/*
 *	timestamp9_out		- converts timestamp9 to "num"
 */
Datum
timestamp9_out(PG_FUNCTION_ARGS)
{
	timestamp9		arg1 = PG_GETARG_TIMESTAMP9(0);
	char	   *result = (char *) palloc(41);	/* sign, 3 digits, '\0' */

  time_t secs = (time_t)(arg1 / kT_ns_in_s);
  tm tm_;
  localtime_r(&secs, &tm_);
  size_t offset = strftime(result, 41, "%Y-%m-%d %H:%M:%S", &tm_);
  offset += sprintf(result + offset, ".%llu", (arg1 % kT_ns_in_s));
  offset += strftime(result + offset, 41, " %z", &tm_);
  
	PG_RETURN_CSTRING(result);
}

/*
 *	timestamp9_recv		- converts external binary format to timestamp9
 */
Datum
timestamp9_recv(PG_FUNCTION_ARGS)
{
	StringInfo	buf = (StringInfo) PG_GETARG_POINTER(0);

	PG_RETURN_TIMESTAMP9((timestamp9) pq_getmsgint64(buf));
}

/*
 * timestamp9_send			- converts timestamp9 to binary format
 */
Datum
timestamp9_send(PG_FUNCTION_ARGS)
{
	timestamp9		arg1 = PG_GETARG_TIMESTAMP9(0);
	StringInfoData buf;

	pq_begintypsend(&buf);
	pq_sendint64(&buf, arg1);
	PG_RETURN_BYTEA_P(pq_endtypsend(&buf));
}


Datum
timestamp9_eq(PG_FUNCTION_ARGS)
{
	PG_RETURN_BOOL(PG_GETARG_TIMESTAMP9(0) == PG_GETARG_TIMESTAMP9(1));
}

Datum
timestamp9_ne(PG_FUNCTION_ARGS)
{
	PG_RETURN_BOOL(PG_GETARG_TIMESTAMP9(0) != PG_GETARG_TIMESTAMP9(1));
}

Datum
timestamp9_lt(PG_FUNCTION_ARGS)
{
	PG_RETURN_BOOL(PG_GETARG_TIMESTAMP9(0) < PG_GETARG_TIMESTAMP9(1));
}

Datum
timestamp9_le(PG_FUNCTION_ARGS)
{
	PG_RETURN_BOOL(PG_GETARG_TIMESTAMP9(0) <= PG_GETARG_TIMESTAMP9(1));
}

Datum
timestamp9_gt(PG_FUNCTION_ARGS)
{
	PG_RETURN_BOOL(PG_GETARG_TIMESTAMP9(0) > PG_GETARG_TIMESTAMP9(1));
}

Datum
timestamp9_ge(PG_FUNCTION_ARGS)
{
	PG_RETURN_BOOL(PG_GETARG_TIMESTAMP9(0) >= PG_GETARG_TIMESTAMP9(1));
}

Datum
bt_timestamp9_cmp(PG_FUNCTION_ARGS)
{
	timestamp9 a = PG_GETARG_TIMESTAMP9(0);
	timestamp9 b = PG_GETARG_TIMESTAMP9(1);

	PG_RETURN_INT32((a < b) ? -1 : (a > b));
}

Datum timestamp9_to_timestamptz(PG_FUNCTION_ARGS)
{
	auto ts9 = PG_GETARG_TIMESTAMP9(0);
	auto us = ts9 / 1000;
	us -= ((POSTGRES_EPOCH_JDATE - UNIX_EPOCH_JDATE) * SECS_PER_DAY * USECS_PER_SEC);

	/* Recheck in case roundoff produces something just out of range */
	if (!IS_VALID_TIMESTAMP(us))
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("timestamp9 out of range: \"%lld\"",
						PG_GETARG_TIMESTAMP9(0))));


	PG_RETURN_TIMESTAMPTZ(us);
}

Datum timestamptz_to_timestamp9(PG_FUNCTION_ARGS)
{
	auto ts = PG_GETARG_TIMESTAMPTZ(0);
	ts += ((POSTGRES_EPOCH_JDATE - UNIX_EPOCH_JDATE) * SECS_PER_DAY * USECS_PER_SEC);
	auto ns = ts * 1000;
	
	PG_RETURN_TIMESTAMP9(ns);
}

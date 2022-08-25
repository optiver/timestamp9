
#include "postgres.h"

#include <ctype.h>
#include <limits.h>
#include <time.h>

#include "access/hash.h"
#include "catalog/pg_type.h"
#include "libpq/pqformat.h"
#include "utils/array.h"
#include "utils/builtins.h"
#include "utils/timestamp.h"
#include "utils/date.h"
#include "utils/datetime.h"
#include "pgtime.h"

#include "timestamp9.h"

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
PG_FUNCTION_INFO_V1(timestamp9_to_timestamp);
PG_FUNCTION_INFO_V1(timestamp_to_timestamp9);
PG_FUNCTION_INFO_V1(timestamp9_to_date);
PG_FUNCTION_INFO_V1(date_to_timestamp9);

PG_FUNCTION_INFO_V1(timestamp9_larger);
PG_FUNCTION_INFO_V1(timestamp9_smaller);
PG_FUNCTION_INFO_V1(timestamp9_interval_pl);
PG_FUNCTION_INFO_V1(interval_timestamp9_pl);
PG_FUNCTION_INFO_V1(timestamp9_interval_mi);

#define kT_ns_in_s  (int64_t)1000000000
#define kT_ns_in_us (int64_t)1000

#define NO_COLON_TZ_OFFSET_LEN (size_t)4 /* length of string 0200 */
#define COLON_TZ_OFFSET_LEN (size_t)5 /* length of string 02:00 */

static TimestampTz
timestamp9_to_timestamptz_internal(timestamp9 ts9)
{
	int64 us = ts9 / 1000;
	us -= ((POSTGRES_EPOCH_JDATE - UNIX_EPOCH_JDATE) * SECS_PER_DAY * USECS_PER_SEC);

	/* Recheck in case roundoff produces something just out of range */
	if (!IS_VALID_TIMESTAMP(us))
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
					errmsg("timestamp9 out of range: \"%lld\"",
						   ts9)));
	return us;
}

static timestamp9
timestamptz_to_timestamp9_internal(TimestampTz ts)
{
	int64 ns;
	ts += ((POSTGRES_EPOCH_JDATE - UNIX_EPOCH_JDATE) * SECS_PER_DAY * USECS_PER_SEC);
	ns = ts * 1000;
	return ns;
}

static timestamp9
date2timestamp9(DateADT dateVal)
{
	timestamp9 result;
	struct pg_tm tt;
	struct pg_tm* tm = &tt;
	int tz;

	if (DATE_IS_NOBEGIN(dateVal) || DATE_IS_NOEND(dateVal))
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
					errmsg("date out of range for timestamp")));
	else
	{
		/*
		 * Date's range is wider than timestamp's, so check for boundaries.
		 * Since dates have the same minimum values as timestamps, only upper
		 * boundary need be checked for overflow.
		 */
		if (dateVal >= (TIMESTAMP9_END_JULIAN - UNIX_EPOCH_JDATE))
			ereport(ERROR,
					(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
						errmsg("date out of range for timestamp")));

		j2date(dateVal + POSTGRES_EPOCH_JDATE,
			   &(tm->tm_year), &(tm->tm_mon), &(tm->tm_mday));
		tm->tm_hour = 0;
		tm->tm_min = 0;
		tm->tm_sec = 0;
		tz = DetermineTimeZoneOffset(tm, session_timezone);

		result = dateVal * USECS_PER_DAY * kT_ns_in_us + tz * USECS_PER_SEC * kT_ns_in_us +
			(POSTGRES_EPOCH_JDATE - UNIX_EPOCH_JDATE) * USECS_PER_DAY * kT_ns_in_us;
	}

	return result;
}

static TimestampTz
timestamp2timestamptz(Timestamp timestamp)
{
	TimestampTz result;
	struct pg_tm tt;
	struct pg_tm* tm = &tt;
	fsec_t fsec;
	int tz;

	if (TIMESTAMP_NOT_FINITE(timestamp))
		result = timestamp;
	else
	{
		if (timestamp2tm(timestamp, NULL, tm, &fsec, NULL, NULL) != 0)
			ereport(ERROR,
					(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
						errmsg("timestamp out of range")));

		tz = DetermineTimeZoneOffset(tm, session_timezone);

		if (tm2timestamp(tm, fsec, &tz, &result) != 0)
			ereport(ERROR,
					(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
						errmsg("timestamp out of range")));
	}

	return result;
}

static Timestamp
timestamptz2timestamp(TimestampTz timestamp)
{
	Timestamp result;
	struct pg_tm tt;
	struct pg_tm* tm = &tt;
	fsec_t fsec;
	int tz;

	if (TIMESTAMP_NOT_FINITE(timestamp))
		result = timestamp;
	else
	{
		if (timestamp2tm(timestamp, &tz, tm, &fsec, NULL, NULL) != 0)
			ereport(ERROR,
					(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
						errmsg("timestamp out of range")));
		if (tm2timestamp(tm, fsec, NULL, &result) != 0)
			ereport(ERROR,
					(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
						errmsg("timestamp out of range")));
	}
	return result;
}

/*
 *	timestamp9_in		- converts "num" to timestamp9
 */
Datum
timestamp9_in(PG_FUNCTION_ARGS)
{
	char *str = PG_GETARG_CSTRING(0);

	timestamp9 result = 0ll;
	fsec_t fsec;
	struct pg_tm tt;
	struct pg_tm* p_tm = &tt;
	int dtype;
	int tz;
	int nf;
	char *field[MAXDATEFIELDS];
	int ftype[MAXDATEFIELDS];
	char lowstr[MAXDATELEN + MAXDATEFIELDS];
	long long ratio;
	bool fractional_valid = false;
	size_t len = strlen(str);
	int parsed_length;
	long long ns;

	if (len > MAXDATELEN)
	{
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
					errmsg("input string too long. invalid input format for timestamp9"
						   )));
	}

	/* first try the raw nanosecond bigint format: eg. 1554809728000100000 */
	if(sscanf(str, "%lld%n", &ns, &parsed_length) == 1)
	{
		if ((size_t)parsed_length == len)
		{
			PG_RETURN_TIMESTAMP9(ns);
		}
	}

	ratio = parse_fractional_ratio(str, len, &fractional_valid);

	/* then try postgres parsing of up-to microsecond fractional second timestamp (to allow greater flexibility in input) */
	if (ratio <= 100 ||
		ParseDateTime(str, lowstr, MAXDATELEN + MAXDATEFIELDS, field, ftype, MAXDATEFIELDS, &nf) != 0 ||
		DecodeDateTime(field, ftype, nf, &dtype, p_tm, &fsec, &tz) != 0)
	{
		/* it doesn't work - try our own simple parsing then */
		struct tm tm_ = {0};
		long long ns;
		char plusmin;
		char gmt_offset_str[6] = ""; /* length of XX:XX plus 1 according to sscanf rules to accomodate \0 */
		int gmt_offset = 0;
		int num_read;
		time_t tt;

		num_read = sscanf(str, "%d-%d-%d %d:%d:%d.%lld %c%5s", &tm_.tm_year, &tm_.tm_mon, &tm_.tm_mday, &tm_.tm_hour, &tm_.tm_min, &tm_.tm_sec, &ns, &plusmin, gmt_offset_str);
		if (num_read == 9 && fractional_valid)
		{
			bool offset_valid = false;
			gmt_offset = parse_gmt_offset(gmt_offset_str, &offset_valid);

			if (!offset_valid)
			{
				ereport(ERROR,
						(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
							errmsg("invalid input format for timestamp9: could not parse gmt offset, required format y-m-d h:m:s.ns +tz \"%s\"",
								   str)));
			}

			tm_.tm_year -= 1900;
			tm_.tm_mon--;
			if (plusmin == '-')
				gmt_offset = -gmt_offset;
			tt = timegm(&tm_);
			tt = tt + tm_.tm_gmtoff - gmt_offset;

			result = (long long)tt * kT_ns_in_s + (ns * ratio);
		}
		else
		{
			ereport(ERROR,
					(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
						errmsg("invalid input format for timestamp9, required format y-m-d h:m:s.ns +tz \"%s\"",
							   str)));
		}
		PG_RETURN_TIMESTAMP9(result);
	}

	switch (dtype)
	{
	case DTK_DATE:
	{
		Timestamp pg_ts;
		if (tm2timestamp(p_tm, fsec, &tz, &pg_ts) != 0)
		{
			ereport(ERROR,
					(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
						errmsg("invalid input format for timestamp9, required format y-m-d h:m:s.ns +tz \"%s\"",
							   str)));
		}
		pg_ts += ((POSTGRES_EPOCH_JDATE - UNIX_EPOCH_JDATE) * SECS_PER_DAY * USECS_PER_SEC);
		result = pg_ts * 1000;
		break;
	}
	default:
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
					errmsg("invalid input format for timestamp9, required format y-m-d h:m:s.ns +tz \"%s\"",
						   str)));
	}

	PG_RETURN_TIMESTAMP9(result);
}

long long parse_fractional_ratio(const char* str, size_t len, bool* fractional_valid)
{
	bool count = false;
	long long ratio = 1000000000ll;
	size_t i = 0;
	*fractional_valid = false;

	while (i < len)
	{
		if (count && (str[i] == ' ' || str[i] == '+' || str[i] == '-' || str[i] == 'Z'))
		{
			*fractional_valid = (ratio > 0);
			break;
		}

		if (count)
			ratio /= 10;

		if (str[i] == '.')
			count = true;
		i++;
	}
	return ratio;
}

int parse_gmt_offset(const char * str, bool* valid)
{
	int gmt_offset_sec = 0;
	const char * colon_at = strchr(str, ':');
	size_t len = strlen(str);
	*valid = false;

	if (colon_at == NULL)
	{
		if (len == NO_COLON_TZ_OFFSET_LEN)  /*being extra safe here as sscanf can give false positives on wrong format*/
		{
			int num_read = sscanf(str, "%d", &gmt_offset_sec);
			if (num_read  == 1)
			{
				*valid = true;
				gmt_offset_sec = ((gmt_offset_sec / 100) * 60 + gmt_offset_sec % 100) * 60;
			}
		}
	}
	else
	{
		if(len == COLON_TZ_OFFSET_LEN)
		{
			int offset_hour = 0, offset_minute = 0;
			int num_read = sscanf(str, "%d:%d", &offset_hour, &offset_minute);
			if (num_read == 2)
			{
				*valid = true;
				gmt_offset_sec = offset_hour * 60 * 60 + offset_minute * 60;
			}
		}
	}
	return gmt_offset_sec;
}


/*
 *	timestamp9_out		- converts timestamp9 to "num"
 */
Datum
timestamp9_out(PG_FUNCTION_ARGS)
{
	timestamp9 arg1 = PG_GETARG_TIMESTAMP9(0);
	char *result = (char *) palloc(41);
	time_t secs = (time_t)(arg1 / kT_ns_in_s);
	struct pg_tm *tm_;
	size_t offset;
	long long int mod = (arg1 % kT_ns_in_s);
	if (mod < 0)
	{
		mod += kT_ns_in_s;
		secs -= 1;
	}

	tm_ = pg_localtime(&secs, session_timezone);
	if (!tm_)
		ereport(ERROR,
			(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
			 errmsg("timestamp9 out of range")));

	offset = pg_strftime(result, 41, "%Y-%m-%d %H:%M:%S", tm_);
	offset += sprintf(result + offset, ".%09lld", mod);
	offset += pg_strftime(result + offset, 41, " %z", tm_);

	PG_RETURN_CSTRING(result);
}

/*
 *	timestamp9_recv		- converts external binary format to timestamp9
 */
Datum
timestamp9_recv(PG_FUNCTION_ARGS)
{
	StringInfo buf = (StringInfo) PG_GETARG_POINTER(0);

	PG_RETURN_TIMESTAMP9((timestamp9) pq_getmsgint64(buf));
}

/*
 * timestamp9_send			- converts timestamp9 to binary format
 */
Datum
timestamp9_send(PG_FUNCTION_ARGS)
{
	timestamp9 arg1 = PG_GETARG_TIMESTAMP9(0);
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
	timestamp9 ts9 = PG_GETARG_TIMESTAMP9(0);
	TimestampTz us = timestamp9_to_timestamptz_internal(ts9);
	PG_RETURN_TIMESTAMPTZ(us);
}

Datum timestamptz_to_timestamp9(PG_FUNCTION_ARGS)
{
	TimestampTz ts = PG_GETARG_TIMESTAMPTZ(0);
	timestamp9 ns = timestamptz_to_timestamp9_internal(ts);

	PG_RETURN_TIMESTAMP9(ns);
}

Datum timestamp9_to_timestamp(PG_FUNCTION_ARGS)
{
	timestamp9 ts9 = PG_GETARG_TIMESTAMP9(0);
	TimestampTz us = ts9 / 1000;
	us -= ((POSTGRES_EPOCH_JDATE - UNIX_EPOCH_JDATE) * SECS_PER_DAY * USECS_PER_SEC);

	/* Recheck in case roundoff produces something just out of range */
	if (!IS_VALID_TIMESTAMP(us))
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
					errmsg("timestamp9 out of range: \"%lld\"",
						   PG_GETARG_TIMESTAMP9(0))));

	us = timestamptz2timestamp(us);
	PG_RETURN_TIMESTAMP(us);
}

Datum timestamp_to_timestamp9(PG_FUNCTION_ARGS)
{
	timestamp9 ns;
	TimestampTz ts = PG_GETARG_TIMESTAMP(0);
	ts = timestamp2timestamptz(ts);
	ts += ((POSTGRES_EPOCH_JDATE - UNIX_EPOCH_JDATE) * SECS_PER_DAY * USECS_PER_SEC);
	ns = ts * 1000;

	PG_RETURN_TIMESTAMP9(ns);
}

Datum timestamp9_to_date(PG_FUNCTION_ARGS)
{
	timestamp9 ts9 = PG_GETARG_TIMESTAMP9(0);
	TimestampTz timestamp = timestamp9_to_timestamptz_internal(ts9);
	DateADT result;
	struct pg_tm tt,
		*tm = &tt;
	fsec_t fsec;
	int tz;

	if (timestamp2tm(timestamp, &tz, tm, &fsec, NULL, NULL) != 0)
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
					errmsg("timestamp out of range")));

	result = date2j(tm->tm_year, tm->tm_mon, tm->tm_mday) - POSTGRES_EPOCH_JDATE;

	PG_RETURN_DATEADT(result);
}


Datum date_to_timestamp9(PG_FUNCTION_ARGS)
{
	DateADT date = PG_GETARG_DATEADT(0);
	timestamp9 ts = date2timestamp9(date);
	PG_RETURN_TIMESTAMP9(ts);
}

Datum timestamp9_larger(PG_FUNCTION_ARGS)
{
	timestamp9 a = PG_GETARG_TIMESTAMP9(0);
	timestamp9 b = PG_GETARG_TIMESTAMP9(1);
	if (a > b)
		PG_RETURN_TIMESTAMP9(a);
	else
		PG_RETURN_TIMESTAMP9(b);
}

Datum timestamp9_smaller(PG_FUNCTION_ARGS)
{
	timestamp9 a = PG_GETARG_TIMESTAMP9(0);
	timestamp9 b = PG_GETARG_TIMESTAMP9(1);
	if (a < b)
		PG_RETURN_TIMESTAMP9(a);
	else
		PG_RETURN_TIMESTAMP9(b);
}

Datum timestamp9_interval_pl(PG_FUNCTION_ARGS)
{
	timestamp9 ts = PG_GETARG_TIMESTAMP9(0);
	Interval* intvl = PG_GETARG_INTERVAL_P(1);

	TimestampTz tstz = timestamp9_to_timestamptz_internal(ts);
	timestamp9 new_ts = timestamptz_to_timestamp9_internal(
				DatumGetTimestampTz(
					DirectFunctionCall2(timestamptz_pl_interval,
										TimestampTzGetDatum(tstz),
										IntervalPGetDatum(intvl))));
	new_ts += ts % 1000;
	PG_RETURN_TIMESTAMP9(new_ts);
}

Datum interval_timestamp9_pl(PG_FUNCTION_ARGS)
{
	Interval* intvl = PG_GETARG_INTERVAL_P(0);
	timestamp9 ts = PG_GETARG_TIMESTAMP9(1);

	TimestampTz tstz = timestamp9_to_timestamptz_internal(ts);
	timestamp9 new_ts = timestamptz_to_timestamp9_internal(
				DatumGetTimestampTz(
					DirectFunctionCall2(timestamptz_pl_interval,
										TimestampTzGetDatum(tstz),
										IntervalPGetDatum(intvl))));
	new_ts += ts % 1000;
	PG_RETURN_TIMESTAMP9(new_ts);
}

Datum timestamp9_interval_mi(PG_FUNCTION_ARGS)
{
	timestamp9 ts = PG_GETARG_TIMESTAMP9(0);
	Interval* intvl = PG_GETARG_INTERVAL_P(1);
	Interval tspan;
	TimestampTz tstz;
	timestamp9 new_ts;

	tspan.month = -intvl->month;
	tspan.day = -intvl->day;
	tspan.time = -intvl->time;

	tstz = timestamp9_to_timestamptz_internal(ts);
	new_ts = timestamptz_to_timestamp9_internal(DatumGetTimestampTz(DirectFunctionCall2(timestamptz_pl_interval,
																	TimestampTzGetDatum(tstz),
																	IntervalPGetDatum(&tspan))));
	new_ts += ts % 1000;
	PG_RETURN_TIMESTAMP9(new_ts);
}

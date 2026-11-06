-- Set timezone to UTC-2 so that timestamp9 can have consistent timezone configuration
-- on machines in different timezones.
set timezone to 'UTC-2';

-- Test that we are able to convert nanoseconds to timestamp9.
select 0::bigint::timestamp9;
select 9223372036854775807::timestamp9;

-- Test that we are able to convert various formats of timestamps to timestamp9 type.
select '2019-09-19 08:30:05.123456789 +0200'::timestamp9;
select '2019-09-19 08:30:05.123456789-0200'::timestamp9;
select '2019-09-19 08:30:05.123456789+02:00'::timestamp9;
select '2019-09-19 08:30:05.123456789 -02:00'::timestamp9;
select '2019-09-19 08:30:05'::timestamp9;

-- Test that we are able to control the timezone of timestamp9 via the 'timezone' GUC.
set timezone to 'UTC-8';
select '2019-09-19 08:30:05 +0800'::timestamp9;
set timezone to 'Europe/London';
select '2019-09-19 08:30:05 +0100'::timestamp9;
-- NOTE: If we don't specify the timezone when parsing the time, it follows the timezone
-- of the current session by default.
select '2019-09-19 08:30:05'::timestamp9;
select '2019-09-19 08:30:05.123456789'::timestamp9;
-- Test that we can use various timezones.
select '2019-09-19 08:30:05.123456789 Europe/London'::timestamp9;
select '2019-09-19 08:30:05.123456789 utc-2'::timestamp9;
set timezone to 'UTC-2';

-- Test that we are able to reject bad inputs.
select '2022-01-25 00:00:00.123456789 +'::timestamp9;
select '2022-01-25 00:00:00.123456789 abcd'::timestamp9;

-- Test that we are able to compare timestamp9 values.
select '2019-09-19'::timestamp9 < '2019-09-20'::timestamp9, greatest('2020-06-06'::timestamp9, '2019-01-01'::timestamp9);
select '2019-09-19'::timestamp9 > '2019-09-20'::timestamp9, least('2020-06-06'::timestamp9, '2019-01-01'::timestamp9);
select '2019-09-19'::timestamp9 >= '2019-09-20'::timestamp9;
select '2019-09-20'::timestamp9 >= '2019-09-20'::timestamp9;
select '2019-09-19'::timestamp9 <= '2019-09-20'::timestamp9;
select '2019-09-20'::timestamp9 <= '2019-09-20'::timestamp9;
select '2019-09-19'::timestamp9 = '2019-09-20'::timestamp9;
select '2019-09-20'::timestamp9 = '2019-09-20'::timestamp9;

-- Test that we can do arith calculations with timestamp9.
select '2019-09-19 23:00:00.123456789 +0200'::timestamp9 + interval '1 year';
select '2019-09-19 23:00:00.123456789 +0200'::timestamp9 - interval '2 years';

select '2019-09-19 23:00:00.123456789 +0200'::timestamp9 + interval '1 mon';
select '2019-09-19 23:00:00.123456789 +0200'::timestamp9 - interval '2 mons';

select '2019-09-19 23:00:00.123456789 +0200'::timestamp9 + interval '1 day';
select '2019-09-19 23:00:00.123456789 +0200'::timestamp9 - interval '2 days';

select '2019-09-19 23:00:00.123456789 +0200'::timestamp9 + interval '1 hour';
select '2019-09-19 23:00:00.123456789 +0200'::timestamp9 - interval '2 hours';

select '2019-09-19 23:00:00.123456789 +0200'::timestamp9 + interval '1 min';
select '2019-09-19 23:00:00.123456789 +0200'::timestamp9 - interval '2 mins';

select '2019-09-19 23:00:00.123456789 +0200'::timestamp9 + interval '1 sec';
select '2019-09-19 23:00:00.123456789 +0200'::timestamp9 - interval '2 secs';

select '2019-09-19 23:00:00.123456789 +0200'::timestamp9 + interval '1 millisecond';
select '2019-09-19 23:00:00.123456789 +0200'::timestamp9 - interval '2 milliseconds';

select '2019-09-19 23:00:00.123456789 +0200'::timestamp9 + interval '1 microsecond';
select '2019-09-19 23:00:00.123456789 +0200'::timestamp9 - interval '2 microseconds';

CREATE TABLE tbl(ts timestamp9);
CREATE INDEX ON tbl USING hash (ts);

CREATE TABLE tbl1(ts timestamp9) PARTITION BY HASH (ts);

-- Test that out-of-range values raise an error instead of silently wrapping around.
set timezone to 'UTC';

-- Both boundaries use the full bigint range and round-trip without losing nanoseconds.
select ts, ts::bigint from (values
    ('-9223372036854775808'::bigint::timestamp9),
    ('9223372036854775807'::bigint::timestamp9),
    ('1677-09-21 00:12:43.145224192 +0000'::timestamp9),
    ('2262-04-11 23:47:16.854775807 +0000'::timestamp9)
) as bounds(ts);

-- One nanosecond beyond either boundary must not wrap around.
select '1677-09-21 00:12:43.145224191 +0000'::timestamp9;
select '2262-04-11 23:47:16.854775808 +0000'::timestamp9;

-- Raw numeric input must fit in a bigint and consume the whole string.
select '-9223372036854775808'::timestamp9, '9223372036854775807'::timestamp9;
select '9223372036854775808'::timestamp9;
select '-9223372036854775809'::timestamp9;
select ' +0001'::timestamp9::bigint;
select '2019-09-19'::timestamp9;

-- The PostgreSQL text parser must use the same range checks.
select '2262-04-11 23:47:16 +0000'::timestamp9;
select '3000-01-01'::timestamp9;

-- Timestamp casts accept the nearest representable microseconds at each boundary.
select '1677-09-21 00:12:43.145225'::timestamp::timestamp9,
       '2262-04-11 23:47:16.854775'::timestamp::timestamp9;
select '1677-09-21 00:12:43.145225 +0000'::timestamptz::timestamp9,
       '2262-04-11 23:47:16.854775 +0000'::timestamptz::timestamp9;
select '2362-04-01'::timestamp::timestamp9;
select '2362-04-01'::timestamptz::timestamp9;
select '1600-01-01'::timestamp::timestamp9;
select '1677-09-21 00:12:43.145224'::timestamptz::timestamp9;
select '2262-04-11 23:47:16.854776'::timestamptz::timestamp9;
select 'infinity'::timestamptz::timestamp9;
select '-infinity'::timestamp::timestamp9;

-- Date casts check both bounds after converting from the PostgreSQL epoch.
select '2262-04-11'::date::timestamp9, '1677-09-22'::date::timestamp9;
select '2262-04-12'::date::timestamp9;
select '2270-01-01'::date::timestamp9;
select '1677-09-21'::date::timestamp9;
select '1600-01-01'::date::timestamp9;
select 'infinity'::date::timestamp9;
select '-infinity'::date::timestamp9;

-- Interval arithmetic rejects overflow and preserves the nanosecond remainder.
select '9223372036854775807'::timestamp9 + interval '1 day';
select '-9223372036854775808'::timestamp9 - interval '1 day';
select interval '1 day' + '9223372036854775807'::timestamp9;
select '9223372036854775807'::timestamp9 - interval '1 day';
select '-9223372036854775808'::timestamp9 + interval '1 day';
select interval '1 day' + '-9223372036854775808'::timestamp9;
select '9223372036854775807'::timestamp9 + interval '0';
select '-9223372036854775808'::timestamp9 - interval '0';

-- The final remainder alone can overflow, even when the microseconds fit.
select '808'::timestamp9 + interval '106751 days 23:47:16.854775';
select interval '106751 days 23:47:16.854775' + '808'::timestamp9;
select '-809'::timestamp9 - interval '106751 days 23:47:16.854775';
select '807'::timestamp9 + interval '106751 days 23:47:16.854775';
select '-808'::timestamp9 - interval '106751 days 23:47:16.854775';

-- A remainder of the opposite sign can bring the final result exactly into range.
select '-193'::timestamp9 + interval '106751 days 23:47:16.854776';
select '192'::timestamp9 - interval '106751 days 23:47:16.854776';

-- This file consists of tests for checking overflows and validating timestamp9 value range.
set timezone to 'UTC+0';

-- The maximum and minimum values of nanoseconds.
-- 1900-01-01 00:00:00.000000000 UTC+0.
select '-2208988800000000000'::timestamp9;
-- 2261-12-31 23:59:59.999999999 UTC+0.
select '9214646399999999999'::timestamp9;

-- Input out-of-range nanoseconds.
-- 1899-12-31 23:59:59.999999999 UTC+0.
select '-2208988800000000001'::timestamp9;
-- 2262-01-01 00:00:00.000000000 UTC+0.
select '9214646400000000000'::timestamp9;

-- The maximum and minimum values of timestamp9 values.
select '1900-01-01 00:00:00.000000000 UTC+0'::timestamp9;
select '2261-12-31 23:59:59.999999999 UTC+0'::timestamp9;

-- Input out-of-range timestamp9 values.
select '1899-12-31 23:59:59.999999999 UTC+0'::timestamp9;
select '2262-01-01 00:00:00.000000000 UTC+0'::timestamp9;

-- Convert out-of-range TimestampTz values to timestamp9.
select '1899-12-30 23:59:59.999999999 UTC+0'::timestamptz::timestamp9;
select '2262-01-01 00:00:00.000000000 UTC+0'::timestamptz::timestamp9;

-- Convert out-of-range Timestamp values to timestamp9.
select '1899-12-30 23:59:59.999999999'::timestamp::timestamp9;
select '2262-01-01 00:00:00.000000000'::timestamp::timestamp9;

-- Convert out-of-range date values to timestamp9.
select '1899-12-30'::date::timestamp9;
select '2262-01-01'::date::timestamp9;

-- Test various overflows caused by arithmetic calculations on timestamp9 values.
select '1900-01-01 00:00:00.000000000 UTC+0'::timestamp9 - interval '1us';
select '2261-12-31 23:59:59.999999999 UTC+0'::timestamp9 + interval '1us';
select interval '1us' + '2261-12-31 23:59:59.999999999 UTC+0'::timestamp9;

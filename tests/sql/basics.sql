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
set timezone to 'UTC-2';


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

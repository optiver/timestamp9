-- Test timezone handling

-- Set timezone to UTC-2 for consistent results
set timezone to 'UTC-2';

-- Test various offset formats
SELECT '2019-09-19 08:30:05.123456789 +0000'::timestamp9;
SELECT '2019-09-19 08:30:05.123456789 +00:00'::timestamp9;
SELECT '2019-09-19 08:30:05.123456789 +00'::timestamp9;
SELECT '2019-09-19 08:30:05.123456789 -0500'::timestamp9;
SELECT '2019-09-19 08:30:05.123456789 -05:00'::timestamp9;
SELECT '2019-09-19 08:30:05.123456789 +0530'::timestamp9;
SELECT '2019-09-19 08:30:05.123456789 +05:30'::timestamp9;

-- Test named timezone abbreviations
SELECT '2019-09-19 08:30:05.123456789 UTC'::timestamp9;
SELECT '2019-09-19 08:30:05.123456789 GMT'::timestamp9;

-- Test session timezone changes
set timezone to 'UTC';
SELECT '2019-09-19 08:30:05'::timestamp9;

set timezone to 'America/New_York';
SELECT '2019-09-19 08:30:05'::timestamp9;

set timezone to 'Europe/London';
SELECT '2019-09-19 08:30:05'::timestamp9;

set timezone to 'Asia/Tokyo';
SELECT '2019-09-19 08:30:05'::timestamp9;

-- Reset timezone
set timezone to 'UTC-2';

-- Test named timezones in timestamp string
SELECT '2019-09-19 08:30:05.123456789 America/New_York'::timestamp9;
SELECT '2019-09-19 08:30:05.123456789 Europe/London'::timestamp9;
SELECT '2019-09-19 08:30:05.123456789 Asia/Tokyo'::timestamp9;

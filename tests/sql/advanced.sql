-- Test new functions added in version 1.5.0

-- Set timezone to UTC-2 for consistent results
set timezone to 'UTC-2';

-- Test timestamp9_now()
SELECT timestamp9_now() IS NOT NULL;
SELECT timestamp9_now() > '2020-01-01'::timestamp9;

-- Test timestamp9_diff()
SELECT timestamp9_diff('2019-09-20 00:00:00 +0000'::timestamp9, '2019-09-19 00:00:00 +0000'::timestamp9);
SELECT timestamp9_diff('2019-09-19 00:00:00 +0000'::timestamp9, '2019-09-19 00:00:00 +0000'::timestamp9);
SELECT timestamp9_diff('2019-09-19 00:00:00 +0000'::timestamp9, '2019-09-20 00:00:00 +0000'::timestamp9);

-- Test timestamp9_epoch()
SELECT timestamp9_epoch('1970-01-01 00:00:00 +0000'::timestamp9);
SELECT timestamp9_epoch('1970-01-01 00:00:01 +0000'::timestamp9);
SELECT timestamp9_epoch('1970-01-01 00:00:00.000000001 +0000'::timestamp9);

-- Test epoch_to_timestamp9()
SELECT epoch_to_timestamp9(0.0);
SELECT epoch_to_timestamp9(1.0);
SELECT epoch_to_timestamp9(0.000000001);

-- Test round-trip: epoch_to_timestamp9(timestamp9_epoch(ts)) = ts
SELECT epoch_to_timestamp9(timestamp9_epoch('2019-09-19 08:30:05.123456789 +0200'::timestamp9)) = '2019-09-19 08:30:05.123456789 +0200'::timestamp9;
SELECT epoch_to_timestamp9(timestamp9_epoch('1970-01-01 00:00:00 +0000'::timestamp9)) = '1970-01-01 00:00:00 +0000'::timestamp9;

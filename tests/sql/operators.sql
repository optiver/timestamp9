-- Test operators and indexes

-- Set timezone to UTC-2 for consistent results
set timezone to 'UTC-2';

-- Test all comparison operators with same timestamps
SELECT '2019-09-19 08:30:05.123456789 +0200'::timestamp9 = '2019-09-19 08:30:05.123456789 +0200'::timestamp9;
SELECT '2019-09-19 08:30:05.123456789 +0200'::timestamp9 != '2019-09-19 08:30:05.123456789 +0300'::timestamp9;
SELECT '2019-09-19 08:30:05.123456789 +0200'::timestamp9 < '2019-09-19 08:30:05.123456789 +0100'::timestamp9;
SELECT '2019-09-19 08:30:05.123456789 +0200'::timestamp9 <= '2019-09-19 08:30:05.123456789 +0200'::timestamp9;
SELECT '2019-09-19 08:30:05.123456789 +0200'::timestamp9 > '2019-09-19 08:30:05.123456789 +0300'::timestamp9;
SELECT '2019-09-19 08:30:05.123456789 +0200'::timestamp9 >= '2019-09-19 08:30:05.123456789 +0200'::timestamp9;

-- Test min/max aggregates
SELECT min(ts), max(ts) FROM (VALUES
	('2019-01-01 00:00:00'::timestamp9),
	('2019-06-15 12:30:00'::timestamp9),
	('2019-12-31 23:59:59'::timestamp9)
) AS t(ts);

-- Test ORDER BY
SELECT ts FROM (VALUES
	('2019-06-15 12:30:00'::timestamp9),
	('2019-01-01 00:00:00'::timestamp9),
	('2019-12-31 23:59:59'::timestamp9)
) AS t(ts) ORDER BY ts;

-- Test b-tree index usage
CREATE TABLE test_btree(ts timestamp9);
CREATE INDEX idx_btree ON test_btree USING btree (ts);
INSERT INTO test_btree VALUES ('2019-01-01 00:00:00'), ('2019-06-15 12:30:00'), ('2019-12-31 23:59:59');
SELECT * FROM test_btree WHERE ts > '2019-06-01 00:00:00'::timestamp9 ORDER BY ts;
DROP TABLE test_btree;

-- Test hash index usage
CREATE TABLE test_hash(ts timestamp9);
CREATE INDEX idx_hash ON test_hash USING hash (ts);
INSERT INTO test_hash VALUES ('2019-01-01 00:00:00'), ('2019-06-15 12:30:00'), ('2019-12-31 23:59:59');
SELECT * FROM test_hash WHERE ts = '2019-06-15 12:30:00'::timestamp9;
DROP TABLE test_hash;

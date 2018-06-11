
CREATE OR REPLACE FUNCTION timestamp9_to_date(timestamp9) RETURNS date AS
'$libdir/timestamp9'
LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;

CREATE CAST (timestamp9 AS date)
WITH FUNCTION timestamp9_to_date(timestamp9) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION date_to_timestamp9(date) RETURNS timestamp9 AS
'$libdir/timestamp9'
LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;

CREATE CAST (date AS timestamp9)
WITH FUNCTION date_to_timestamp9(date) AS IMPLICIT;

CREATE OR REPLACE FUNCTION hash_timestamp9(timestamp9) RETURNS integer AS
'hashint8'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;

CREATE OPERATOR CLASS hash_timestamp9_ops
FOR TYPE timestamp9 USING hash FAMILY integer_ops AS
	OPERATOR 1 =,
	FUNCTION 1 hash_timestamp9(timestamp9);

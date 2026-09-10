-- Upgrade script from timestamp9 1.4.0 to 1.5.0
-- Adds: timestamp9_now(), timestamp9_diff(), timestamp9_epoch(), epoch_to_timestamp9()

CREATE FUNCTION timestamp9_now() RETURNS timestamp9 AS
'$libdir/timestamp9'
	LANGUAGE c VOLATILE STRICT PARALLEL SAFE;

CREATE FUNCTION timestamp9_diff(timestamp9, timestamp9) RETURNS interval AS
'$libdir/timestamp9'
	LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;

CREATE FUNCTION timestamp9_epoch(timestamp9) RETURNS double precision AS
'$libdir/timestamp9'
	LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;

CREATE FUNCTION epoch_to_timestamp9(double precision) RETURNS timestamp9 AS
'$libdir/timestamp9'
	LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;

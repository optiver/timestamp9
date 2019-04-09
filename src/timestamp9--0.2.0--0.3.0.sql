
CREATE FUNCTION timestamp9_larger(timestamp9, timestamp9) RETURNS timestamp9 AS
'$libdir/timestamp9'
LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;

CREATE AGGREGATE max(timestamp9) (
	SFUNC = timestamp9_larger,
	STYPE = timestamp9,
	SORTOP = >
);

CREATE FUNCTION timestamp9_smaller(timestamp9, timestamp9) RETURNS timestamp9 AS
'$libdir/timestamp9'
LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE AGGREGATE min(timestamp9) (
	SFUNC = timestamp9_smaller,
	STYPE = timestamp9,
	SORTOP = <
);

CREATE FUNCTION timestamp9_interval_pl(timestamp9, interval) RETURNS timestamp9 AS
'$libdir/timestamp9'
	LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE OPERATOR + (
	LEFTARG = timestamp9,
	RIGHTARG = interval,
	PROCEDURE = timestamp9_interval_pl,
	COMMUTATOR = +
	);

CREATE FUNCTION timestamp9_interval_mi(timestamp9, interval) RETURNS timestamp9 AS
'$libdir/timestamp9'
	LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE OPERATOR - (
	LEFTARG = timestamp9,
	RIGHTARG = interval,
	PROCEDURE = timestamp9_interval_mi
	);

CREATE FUNCTION interval_timestamp9_pl(interval, timestamp9) RETURNS timestamp9 AS
'$libdir/timestamp9'
	LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE OPERATOR + (
	LEFTARG = interval,
	RIGHTARG = timestamp9,
	PROCEDURE = interval_timestamp9_pl,
	COMMUTATOR = +
	);

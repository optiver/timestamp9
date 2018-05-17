CREATE OR REPLACE FUNCTION timestamp9_in(cstring) RETURNS timestamp9 AS
'$libdir/timestamp9'
LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE OR REPLACE FUNCTION timestamp9_out(timestamp9) RETURNS cstring AS
'$libdir/timestamp9'
LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE OR REPLACE FUNCTION timestamp9_recv(internal) RETURNS timestamp9 AS
'$libdir/timestamp9'
LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE OR REPLACE FUNCTION timestamp9_send(timestamp9) RETURNS bytea AS
'$libdir/timestamp9'
LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE TYPE timestamp9 (
 INPUT = timestamp9_in,
 OUTPUT = timestamp9_out,
 RECEIVE = timestamp9_recv,
 SEND = timestamp9_send,
 INTERNALLENGTH = 8,
 PASSEDBYVALUE,
 ALIGNMENT = double,
 STORAGE = plain
);

CREATE OR REPLACE FUNCTION timestamp9_to_timestamptz(timestamp9) RETURNS timestamptz AS
'$libdir/timestamp9'
LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;

CREATE CAST (timestamp9 AS timestamptz)
WITH FUNCTION timestamp9_to_timestamptz(timestamp9) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION timestamptz_to_timestamp9(timestamptz) RETURNS timestamp9 AS
'$libdir/timestamp9'
LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;

CREATE CAST (timestamptz AS timestamp9)
WITH FUNCTION timestamptz_to_timestamp9(timestamptz) AS IMPLICIT;


CREATE OR REPLACE FUNCTION timestamp9_to_timestamp(timestamp9) RETURNS timestamp AS
'$libdir/timestamp9'
LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;

CREATE CAST (timestamp9 AS timestamp)
WITH FUNCTION timestamp9_to_timestamp(timestamp9) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION timestamp_to_timestamp9(timestamp) RETURNS timestamp9 AS
'$libdir/timestamp9'
LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;

CREATE CAST (timestamp AS timestamp9)
WITH FUNCTION timestamp_to_timestamp9(timestamp) AS IMPLICIT;


CREATE CAST (timestamp9 AS bigint)
WITHOUT FUNCTION AS ASSIGNMENT;
CREATE CAST (bigint AS timestamp9)
WITHOUT FUNCTION AS IMPLICIT;

CREATE OR REPLACE FUNCTION timestamp9_lt(timestamp9, timestamp9) RETURNS bool AS
'MODULE_PATHNAME'
LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE OPERATOR < (
	LEFTARG = timestamp9,
	RIGHTARG = timestamp9,
	PROCEDURE = timestamp9_lt,
	COMMUTATOR = >,
	NEGATOR = >=,
	RESTRICT = scalarltsel,
	JOIN = scalarltjoinsel
);

CREATE OR REPLACE FUNCTION timestamp9_le(timestamp9, timestamp9) RETURNS bool AS
'MODULE_PATHNAME'
LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE OPERATOR <= (
	LEFTARG = timestamp9,
	RIGHTARG = timestamp9,
	PROCEDURE = timestamp9_le,
	COMMUTATOR = >=,
	NEGATOR = >,
	RESTRICT = scalarltsel,
	JOIN = scalarltjoinsel
);

CREATE OR REPLACE FUNCTION timestamp9_gt(timestamp9, timestamp9) RETURNS bool AS
'MODULE_PATHNAME'
LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE OPERATOR > (
	LEFTARG = timestamp9,
	RIGHTARG = timestamp9,
	PROCEDURE = timestamp9_gt,
	COMMUTATOR = <,
	NEGATOR = <=,
	RESTRICT = scalargtsel,
	JOIN = scalargtjoinsel
);

CREATE OR REPLACE FUNCTION timestamp9_ge(timestamp9, timestamp9) RETURNS bool AS
'MODULE_PATHNAME'
LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE OPERATOR >= (
	LEFTARG = timestamp9,
	RIGHTARG = timestamp9,
	PROCEDURE = timestamp9_ge,
	COMMUTATOR = <=,
	NEGATOR = <,
	RESTRICT = scalargtsel,
	JOIN = scalargtjoinsel
);

CREATE OR REPLACE FUNCTION timestamp9_eq(timestamp9, timestamp9) RETURNS bool AS
'MODULE_PATHNAME'
LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE OPERATOR = (
	LEFTARG = timestamp9,
	RIGHTARG = timestamp9,
	PROCEDURE = timestamp9_eq,
	COMMUTATOR = =,
	NEGATOR = <>,
	RESTRICT = eqsel,
	JOIN = eqjoinsel,
	HASHES,
	MERGES
);

CREATE OR REPLACE FUNCTION timestamp9_ne(timestamp9, timestamp9) RETURNS bool AS
'MODULE_PATHNAME'
LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE OPERATOR <> (
	LEFTARG = timestamp9,
	RIGHTARG = timestamp9,
	PROCEDURE = timestamp9_ne,
	COMMUTATOR = <>,
	NEGATOR = =,
	RESTRICT = neqsel,
	JOIN = neqjoinsel,
	MERGES
);

CREATE OR REPLACE FUNCTION bt_timestamp9_cmp(timestamp9, timestamp9) RETURNS int AS
'MODULE_PATHNAME'
LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;


CREATE OPERATOR CLASS btree_timestamp9_ops
DEFAULT FOR TYPE timestamp9 USING btree FAMILY integer_ops AS
	OPERATOR 1 <,
	OPERATOR 2 <=,
	OPERATOR 3 =,
	OPERATOR 4 >=,
	OPERATOR 5 >,
	FUNCTION 1 bt_timestamp9_cmp(timestamp9, timestamp9);

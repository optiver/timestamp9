DROP OPERATOR CLASS hash_timestamp9_ops USING hash;

CREATE OPERATOR CLASS hash_timestamp9_ops
DEFAULT FOR TYPE timestamp9 USING hash FAMILY integer_ops AS
	OPERATOR 1 =,
	FUNCTION 1 hash_timestamp9(timestamp9);

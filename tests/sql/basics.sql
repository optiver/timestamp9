select 0::bigint::timestamp9;
select 9223372036854775807::timestamp9;
select '2019-09-19 08:30:05.123456789 +0200'::timestamp9;
select '2019-09-19 08:30:05.123456789-0200'::timestamp9;
select '2019-09-19 08:30:05.123456789+02:00'::timestamp9;
select '2019-09-19 08:30:05.123456789 -02:00'::timestamp9;
select '2019-09-19 08:30:05'::timestamp9;
select '2019-09-19'::timestamp9 < '2019-09-20'::timestamp9, greatest('2020-06-06'::timestamp9, '2019-01-01'::timestamp9);
select '2019-09-19 23:00:00.123456789 +0200'::timestamp9 + interval '1d';

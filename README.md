## Extension timestamp9
An efficient nanosecond precision timestamp type for Postgres

## Build & install
```
git clone https://github.com/fvannee/timestamp9.git
cd timestamp9
mkdir build
cd build
cmake ..
# or: cmake .. -DPG_CONFIG=/path/to/pg_config
make
sudo make install
```

## Usage
Internally, timestamp9 is stored in a 64-bit number as the number of nanoseconds since the UNIX epoch. This means the minimum and maximum representable time is:

```
postgres=# select 0::bigint::timestamp9;
             timestamp9
-------------------------------------
 1970-01-01 01:00:00.000000000 +0100
(1 row)

postgres=# select 9223372036854775807::timestamp9;
             timestamp9
-------------------------------------
 2262-04-12 01:47:16.854775807 +0200
(1 row)

```

Timestamp input can be given either as the number of nanoseconds since Jan 1st 1970, which can be casted to timestamp9 as above, or it can be casted from text format. Both regular Postgres timestamptz text format, as well as a custom nanosecond text format are supported as inputs.
```
postgres=# select '2019-09-19 08:30:05.123456789 +0200'::timestamp9;
             timestamp9
-------------------------------------
 2019-09-19 08:30:05.123456789 +0200
(1 row)

postgres=# select '2019-09-19 08:30:05'::timestamp9;
             timestamp9
-------------------------------------
 2019-09-19 08:30:05.000000000 +0200
(1 row)
```

A subset of the default operators and conversions is supported for timestamp9 types:
- Cast from/to timestamp(tz)
```
postgres=# select now()::timestamp9::timestamptz::timestamp::timestamp9;
                 now
-------------------------------------
 2019-09-19 23:22:07.973781000 +0200
(1 row)
```
- Cast from/to date
```
postgres=# select current_date::timestamp9;
            current_date
-------------------------------------
 2019-09-19 00:00:00.000000000 +0200
(1 row)
```
- Comparisons like greater than, less than etc. as well as use in btree/hash indices
```
postgres=# select '2019-09-19'::timestamp9 < '2019-09-20'::timestamp9, greatest(now()::timestamp9, '2019-01-01'::timestamp9);
 ?column? |              greatest
----------+-------------------------------------
 t        | 2019-09-19 23:27:21.364791000 +0200
(1 row)
```
- Addition and subtraction of intervals
```
postgres=# select '2019-09-19 23:00:00.123456789 +0200'::timestamp9 + interval '1d';
              ?column?
-------------------------------------
 2019-09-20 23:00:00.123456789 +0200
(1 row)
```

# License

---

Timestamp9 is:

Copyright 2023 Optiver IP B.V.

Licensed under the MIT License (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at

```
https://opensource.org/license/mit/
```

Unless required by applicable law or explicitly agreed by an authorized representative of Optiver IP B.V. in
writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. Please see the License for the specific language governing
permissions and limitations under the License.

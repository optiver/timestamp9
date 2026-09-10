# timestamp9

A PostgreSQL extension providing a **nanosecond-precision timestamp data type** for applications requiring higher precision than the built-in `timestamp` type (which is limited to microseconds).

## Why timestamp9?

PostgreSQL's built-in `timestamptz` and `timestamp` types store timestamps with microsecond precision (6 decimal places). While sufficient for most applications, certain domains require nanosecond precision:

- **High-frequency trading (HFT)** - Timestamps from exchange feeds often include nanosecond precision
- **Financial systems** - Accurate event ordering across distributed systems
- **Scientific data** - High-resolution sensor data and measurements
- **Performance profiling** - Sub-microsecond timing for code execution

### Comparison with Alternatives

| Type | Precision | Storage | Operators | Indexes | Casts |
|------|-----------|----------|-----------|---------|-------|
| `timestamp9` | Nanosecond (9 digits) | 8 bytes | ✓ | B-tree, Hash | ✓ |
| `timestamptz` | Microsecond (6 digits) | 8 bytes | ✓ | B-tree, Hash, GiST | ✓ |
| `bigint` | None (raw ns) | 8 bytes | ✗ | B-tree | Manual |

Using `bigint` for nanoseconds works but lacks:
- Comparison operators (`<`, `>`, `=`, etc.)
- Type casts to/from `timestamp`, `timestamptz`, `date`
- Aggregate functions (`min`, `max`)
- Index operator classes

`timestamp9` provides all of these as a first-class PostgreSQL type.

## Supported PostgreSQL Versions

- PostgreSQL 14
- PostgreSQL 15
- PostgreSQL 16
- PostgreSQL 17

## Installation

### Linux / macOS

```bash
# Clone the repository
git clone https://github.com/optiver/timestamp9.git
cd timestamp9

# Build
mkdir build && cd build
cmake .. -DPG_CONFIG=/path/to/pg_config
make

# Install (requires superuser)
sudo make install
```

The `pg_config` path is typically:
- `/usr/lib/postgresql/16/bin/pg_config` (Debian/Ubuntu)
- `/usr/pgsql-16/bin/pg_config` (RHEL/CentOS)
- `/usr/local/bin/pg_config` (Homebrew on macOS)

### Windows

1. Install PostgreSQL with development headers
2. Ensure CMake and Visual Studio (or MSVC) are installed
3. Run:
   ```cmd
   mkdir build
   cd build
   cmake .. -DPG_CONFIG="C:\PostgreSQL\16\bin\pg_config"
   cmake --build . --config Release
   cmake --install . --config Release
   ```

## Quick Start

```sql
-- Enable the extension
CREATE EXTENSION timestamp9;

-- Create a table with nanosecond timestamps
CREATE TABLE events (
    id serial PRIMARY KEY,
    ts timestamp9 NOT NULL,
    data text
);

-- Insert with nanosecond precision
INSERT INTO events (ts, data) VALUES
    ('2024-01-15 10:30:45.123456789 +0000', 'Event A'),
    ('2024-01-15 10:30:45.123456789 +0100', 'Event B');

-- Query with comparisons
SELECT * FROM events WHERE ts > '2024-01-15 09:00:00 +0000'::timestamp9;

-- Get current time with nanosecond precision
SELECT timestamp9_now();

-- Convert to/from Unix epoch
SELECT timestamp9_epoch('2024-01-15 10:30:45.123456789 +0000'::timestamp9);
SELECT epoch_to_timestamp9(1705315845.123456789);

-- Compute difference between timestamps
SELECT timestamp9_diff('2024-01-15 10:30:45'::timestamp9, '2024-01-15 10:30:46'::timestamp9);
```

## Type Reference

### Storage

`timestamp9` is stored as a 64-bit signed integer representing nanoseconds since Unix epoch (1970-01-01 00:00:00 UTC).

- **Minimum value**: 0 (Unix epoch)
- **Maximum value**: 9223372036854775807 (~ year 2262)
- **Storage size**: 8 bytes

### Input Formats

The `timestamp9` type accepts multiple input formats:

```sql
-- Raw nanoseconds since Unix epoch
SELECT 1705315845123456789::timestamp9;

-- ISO-style timestamp with nanoseconds
SELECT '2024-01-15 10:30:45.123456789 +0000'::timestamp9;

-- Without timezone (uses session timezone)
SELECT '2024-01-15 10:30:45.123456789'::timestamp9;

-- Various timezone formats
SELECT '2024-01-15 10:30:45.123456789 +00:00'::timestamp9;
SELECT '2024-01-15 10:30:45.123456789 UTC'::timestamp9;
SELECT '2024-01-15 10:30:45.123456789 America/New_York'::timestamp9;
```

## Functions

| Function | Description |
|----------|-------------|
| `timestamp9_now()` | Returns current timestamp with nanosecond precision |
| `timestamp9_diff(ts1, ts2)` | Returns interval between `ts2` and `ts1` |
| `timestamp9_epoch(ts)` | Converts timestamp9 to Unix epoch as `double precision` |
| `epoch_to_timestamp9(double)` | Converts Unix epoch to timestamp9 |

### Cast Functions

Casts to/from standard types are provided:

```sql
-- To timestamp9
SELECT '2024-01-15 10:30:45'::timestamptz::timestamp9;
SELECT '2024-01-15'::date::timestamp9;
SELECT 1705315845123456789::bigint::timestamp9;

-- From timestamp9
SELECT ts::timestamptz FROM events;
SELECT ts::timestamp FROM events;
SELECT ts::date FROM events;
SELECT ts::bigint FROM events;
```

### Aggregate Functions

```sql
SELECT min(ts), max(ts) FROM events;
```

## Operators

### Comparison Operators

| Operator | Description |
|----------|-------------|
| `=` | Equal |
| `<>` | Not equal |
| `<` | Less than |
| `<=` | Less than or equal |
| `>` | Greater than |
| `>=` | Greater than or equal |

### Arithmetic Operators

| Operator | Description |
|----------|-------------|
| `timestamp9 + interval` | Add interval |
| `interval + timestamp9` | Add interval |
| `timestamp9 - interval` | Subtract interval |

```sql
SELECT '2024-01-15 10:30:45'::timestamp9 + interval '1 hour';
SELECT '2024-01-15 10:30:45'::timestamp9 - interval '1 day';
```

## Indexing

### B-tree Index (Default)

```sql
CREATE INDEX idx_events_ts ON events USING btree (ts);
```

### Hash Index

```sql
CREATE INDEX idx_events_ts_hash ON events USING hash (ts);
```

## Performance Considerations

### Storage

- 8 bytes per value (same as `bigint` and `timestamptz`)
- No additional overhead compared to storing raw nanoseconds as `bigint`

### When to Use timestamp9

- You need **nanosecond precision** in timestamps
- You want to perform **comparisons, sorting, and aggregations** directly in SQL
- You need to **cast between timestamp types** without manual conversion
- You want **index support** for fast lookups

### When NOT to Use timestamp9

- Microsecond precision is sufficient (use built-in `timestamptz`)
- You need to store timestamps beyond year 2262
- You need to store the original timezone (timestamp9 stores UTC only)
- You need timezone-aware range types

### Security Considerations

- Nanosecond timestamps can reveal precise timing information
- Consider precision requirements for your use case
- The type validates input range to prevent overflow

## Limitations

- **Date range**: Limited to years 1970 through ~2262 due to int64 storage
- **Timezone**: Does not store the original timezone; always outputs in session timezone
- **Range types**: No `tsrange9` or `tstzrange9` types (future enhancement)
- **GiST index**: Not supported (future enhancement)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to timestamp9.

## License

Apache License 2.0 - See [LICENSE](LICENSE) for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

# How to Contribute

Timestamp9 welcomes contributions from everyone. Here are some guidelines that will help you get started:

## Getting Started

* Make sure you have a GitHub account.
* Create an issue, or comment saying you're working on an existing issue.
* Fork the repository and create a branch for your changes.

## Development Environment Setup

### Prerequisites

- **PostgreSQL** 14+ with development headers
- **CMake** 3.4+
- **C compiler** (gcc, clang, or MSVC)
- **pg_config** in PATH or available at a known location

### Linux (Debian/Ubuntu)

```bash
# Install PostgreSQL and development packages
sudo apt-get update
sudo apt-get install postgresql-16 postgresql-server-dev-16 cmake build-essential

# Clone and build
git clone https://github.com/optiver/timestamp9.git
cd timestamp9
mkdir build && cd build
cmake .. -DPG_CONFIG=/usr/lib/postgresql/16/bin/pg_config
make
```

### Linux (RHEL/CentOS/Fedora)

```bash
# Install PostgreSQL from PGDG repository
sudo dnf install postgresql16-server postgresql16-devel cmake gcc

# Build
mkdir build && cd build
cmake .. -DPG_CONFIG=/usr/pgsql-16/bin/pg_config
make
```

### macOS (Homebrew)

```bash
# Install PostgreSQL
brew install postgresql@16 cmake

# Build
mkdir build && cd build
cmake .. -DPG_CONFIG=$(brew --prefix postgresql@16)/bin/pg_config
make
```

### Windows

1. Install PostgreSQL with development headers from [EDB](https://www.enterprisedb.com/downloads/postgres-postgresql-downloads)
2. Install [CMake](https://cmake.org/download/) and Visual Studio (or Build Tools for Visual Studio)
3. Build:
   ```cmd
   mkdir build
   cd build
   cmake .. -DPG_CONFIG="C:\PostgreSQL\16\bin\pg_config"
   cmake --build . --config Release
   ```

## Running Tests

### Build and Install

```bash
cd build
cmake .. -DPG_CONFIG=/path/to/pg_config
make
sudo make install
```

### Run Regression Tests

```bash
# Using a temporary PostgreSQL instance
make regresscheck

# Using an existing local PostgreSQL instance
make regresschecklocal
```

The tests use `pg_regress` and require a running PostgreSQL instance or the ability to create a temporary one.

### Adding New Tests

1. Add SQL test cases to `tests/sql/` (e.g., `tests/sql/new_feature.sql`)
2. Create expected output in `tests/expected/` (e.g., `tests/expected/new_feature.out`)
3. Run tests to verify the expected output matches actual output

## Code Style Guidelines

### C Code

- Follow [PostgreSQL coding conventions](https://www.postgresql.org/docs/current/source.html)
- Use 4-space indentation (tabs are acceptable per PostgreSQL style)
- Keep functions focused and well-commented
- Add `PG_FUNCTION_INFO_V1` declarations for all SQL-callable functions
- Use `PG_GETARG_*` and `PG_RETURN_*` macros for parameter handling

### SQL Code

- Use uppercase for SQL keywords (`SELECT`, `CREATE FUNCTION`, etc.)
- Use lowercase for identifiers
- Include `IMMUTABLE`, `STABLE`, or `VOLATILE` as appropriate
- Mark functions `PARALLEL SAFE` when safe for parallel execution
- Mark functions `LEAKPROOF` when they don't leak information

## Making Changes

Contributions to timestamp9 should be made in the form of GitHub pull requests. Each pull request will be reviewed by a core developer and after some feedback, will be merged to master.

### Pull Request Checklist

* [ ] Branch from master or rebase your branch to current master.
* [ ] Each commit should compile and pass tests.
* [ ] Add tests relevant to any fixed bug or new feature.
* [ ] Update documentation (README.md, comments) as needed.
* [ ] Follow the code style guidelines above.

## Adding New Functions

To add a new function:

1. **C implementation** in `src/timestamp9.c`:
   ```c
   PG_FUNCTION_INFO_V1(my_new_function);

   Datum
   my_new_function(PG_FUNCTION_ARGS)
   {
       timestamp9 ts = PG_GETARG_TIMESTAMP9(0);
       // ... implementation ...
       PG_RETURN_INT64(result);
   }
   ```

2. **Declaration** in `src/timestamp9.h`:
   ```c
   extern Datum my_new_function(PG_FUNCTION_ARGS);
   ```

3. **SQL definition** in `src/timestamp9.sql`:
   ```sql
   CREATE FUNCTION my_new_function(timestamp9) RETURNS bigint AS
   '$libdir/timestamp9'
       LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
   ```

4. **Migration script** (for new version) in `src/timestamp9--X.Y.Z--X.Y.W.sql`

5. **Tests** in `tests/sql/` with expected output in `tests/expected/`

## Getting Help

* Open a [GitHub Issue](https://github.com/optiver/timestamp9/issues) for bugs or feature requests
* Check existing issues before creating new ones

Thank you for contributing to timestamp9!

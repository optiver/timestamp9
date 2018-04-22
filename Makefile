PG_CONFIG   ?= /usr/lib/postgresql/10/bin/pg_config

EXTENSION = timestamp9
EXTVERSION = 0.1.0
EXTSQL = $(EXTENSION)--$(EXTVERSION).sql

MODULES = timestamp9
OBJS = timestamp9.o
DATA_built = timestamp9.sql
DATA = uninstall_timestamp9.sql
#DOCS = doc/timestamp9.md
REGRESS = timestamp9

SQL_IN = timestamp9.sql.in
EXTRA_CLEAN += $(SQL_IN) $(EXTSQL)

USE_EXTENSION = $(shell $(PG_CONFIG) --version | grep -qE " 8\.|9\.0" && echo no || echo yes)

ifeq ($(USE_EXTENSION),yes)
all: $(EXTSQL)

$(EXTSQL): $(EXTENSION).sql
	cp $< $@

DATA = $(EXTSQL)
endif

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

$(SQL_IN): timestamp9.sql.in.c
	$(CC) -E -P $(CPPFLAGS) $< > $@

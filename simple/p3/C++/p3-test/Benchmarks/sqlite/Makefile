# /* For copyright information, see olden_v1.01/COPYRIGHT */

include ../../Makefile.defs

SRC_DIR=/ncstate_ece566_spring2020/simple/p3/C++/p3-test/../../../../wolfbench/Benchmarks/sqlite
INSTALL_DIR=/ncstate_ece566_spring2020/simple/p3/C++/p3-test/install/bin

vpath %.c $(SRC_DIR)
vpath %.cpp $(SRC_DIR)

programs = sql

.PHONY: all install

all: $(addsuffix $(EXTRA_SUFFIX),$(programs))

install: all

DEFS    = -DSQLITE_THREADSAFE=0 -DSQLITE_OMIT_LOAD_EXTENSION

SOURCES = test.c sqlite3.c

# test information
INFILE  = /dev/null
OUTFILE = $(programs)$(EXTRA_SUFFIX).out
ARGS    = 
COMPARE = /ncstate_ece566_spring2020/simple/p3/C++/p3-test/../../../../wolfbench/Benchmarks/sqlite/output.sql $(OUTFILE)

include /ncstate_ece566_spring2020/simple/p3/C++/p3-test/../../../../wolfbench/Makefile.benchmark
include ../../Makefile.config

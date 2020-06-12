# /* For copyright information, see olden_v1.01/COPYRIGHT */

include ../../Makefile.defs

SRC_DIR=/ncstate_ece566_spring2020/simple/p3/C++/p3-test/../../../../wolfbench/Benchmarks/bh
INSTALL_DIR=/ncstate_ece566_spring2020/simple/p3/C++/p3-test/install/bin

vpath %.c $(SRC_DIR)
vpath %.cpp $(SRC_DIR)

programs=bh

.PHONY: all install

all: $(addsuffix $(EXTRA_SUFFIX),$(programs))

install: all

DEFS    = -U__GNUC__ -D_NO_LONGLONG

SOURCES = newbh.c util.c args.c

# test information
INFILE  = /dev/null
OUTFILE = $(addsuffix $(EXTRA_SUFFIX).out,$(programs))
ARGS    = 11000 1
COMPARE = /ncstate_ece566_spring2020/simple/p3/C++/p3-test/../../../../wolfbench/Benchmarks/bh/output.bh $(addsuffix $(EXTRA_SUFFIX).out,$(programs))

include /ncstate_ece566_spring2020/simple/p3/C++/p3-test/../../../../wolfbench/Makefile.benchmark
include ../../Makefile.config

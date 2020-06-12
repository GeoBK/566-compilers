# /* For copyright information, see olden_v1.01/COPYRIGHT */

include ../../Makefile.defs

SRC_DIR=/ncstate_ece566_spring2020/tutorial/5/C++/dce-test/../../../../wolfbench/Benchmarks/bitcount
INSTALL_DIR=/ncstate_ece566_spring2020/tutorial/5/C++/dce-test/install/bin

vpath %.c $(SRC_DIR)
vpath %.cpp $(SRC_DIR)

programs = bitcount

.PHONY: all install

all: $(addsuffix $(EXTRA_SUFFIX),$(programs))

install: all

DEFS    = 

SOURCES = bitcnt_1.c bitcnt_2.c bitcnt_3.c bitcnt_4.c bitcnts.c bitfiles.c bitstrng.c bstr_i.c

# test information
INFILE  = /dev/null
OUTFILE = $(addsuffix $(EXTRA_SUFFIX),$(programs)).out
ARGS    = 1125000
COMPARE = /ncstate_ece566_spring2020/tutorial/5/C++/dce-test/../../../../wolfbench/Benchmarks/bitcount/output.bitcount $(OUTFILE)

include /ncstate_ece566_spring2020/tutorial/5/C++/dce-test/../../../../wolfbench/Makefile.benchmark
include ../../Makefile.config

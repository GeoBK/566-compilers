# /* For copyright information, see olden_v1.01/COPYRIGHT */

include ../../Makefile.defs

SRC_DIR=/ncstate_ece566_spring2020/tutorial/5/C++/dce-test/../../../../wolfbench/Benchmarks/hanoi
INSTALL_DIR=/ncstate_ece566_spring2020/tutorial/5/C++/dce-test/install/bin

vpath %.c $(SRC_DIR)
vpath %.cpp $(SRC_DIR)

programs = hanoi

.PHONY: all install

all: $(addsuffix $(EXTRA_SUFFIX),$(programs)) 

install: all 

DEFS    = 

SOURCES = hanoi.c

# test information
INFILE  = /dev/null
OUTFILE = $(programs)$(EXTRA_SUFFIX).out
ARGS    = 2000 18
COMPARE = /ncstate_ece566_spring2020/tutorial/5/C++/dce-test/../../../../wolfbench/Benchmarks/hanoi/output.hanoi $(OUTFILE)

include /ncstate_ece566_spring2020/tutorial/5/C++/dce-test/../../../../wolfbench/Makefile.benchmark
include ../../Makefile.config

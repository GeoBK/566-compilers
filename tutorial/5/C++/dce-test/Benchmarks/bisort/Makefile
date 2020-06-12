# /* For copyright information, see olden_v1.01/COPYRIGHT */

include ../../Makefile.defs

SRC_DIR=/ncstate_ece566_spring2020/tutorial/5/C++/dce-test/../../../../wolfbench/Benchmarks/bisort
INSTALL_DIR=/ncstate_ece566_spring2020/tutorial/5/C++/dce-test/install/bin

vpath %.c $(SRC_DIR)
vpath %.cpp $(SRC_DIR)

programs = bisort

.PHONY: all install

all:  $(addsuffix $(EXTRA_SUFFIX),$(programs)) 

install: all 

DEFS    = -U__GNUC__ -D_NO_LONGLONG -DNOTESTP -DONEONLY

SOURCES = swap.c bitonic.c args.c

# test information
INFILE  = /dev/null
OUTFILE = $(programs).out
ARGS    = 2000000 1 5
COMPARE = 

include /ncstate_ece566_spring2020/tutorial/5/C++/dce-test/../../../../wolfbench/Makefile.benchmark
include ../../Makefile.config

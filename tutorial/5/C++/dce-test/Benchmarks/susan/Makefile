# /* For copyright information, see olden_v1.01/COPYRIGHT */

include ../../Makefile.defs

SRC_DIR=/ncstate_ece566_spring2020/tutorial/5/C++/dce-test/../../../../wolfbench/Benchmarks/susan
INSTALL_DIR=/ncstate_ece566_spring2020/tutorial/5/C++/dce-test/install/bin

vpath %.c $(SRC_DIR)
vpath %.cpp $(SRC_DIR)

programs = susan

.PHONY: all install

all: $(addsuffix $(EXTRA_SUFFIX),$(programs))

install: all 

DEFS    = 

SOURCES = susan.c

# test information
INFILE  = /dev/null
OUTFILE = $(programs)$(EXTRA_SUFFIX).out
ARGS    = /ncstate_ece566_spring2020/tutorial/5/C++/dce-test/../../../../wolfbench/Benchmarks/susan/input_large.pgm output_large$(EXTRA_SUFFIX).smoothing.pgm -s -d 15
COMPARE = /ncstate_ece566_spring2020/tutorial/5/C++/dce-test/../../../../wolfbench/Benchmarks/susan/output_large.smoothing.pgm output_large$(EXTRA_SUFFIX).smoothing.pgm /ncstate_ece566_spring2020/tutorial/5/C++/dce-test/../../../../wolfbench/Benchmarks/susan/output.$(programs) $(OUTFILE)

include /ncstate_ece566_spring2020/tutorial/5/C++/dce-test/../../../../wolfbench/Makefile.benchmark
include ../../Makefile.config

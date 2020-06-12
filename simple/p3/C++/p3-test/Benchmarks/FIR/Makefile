# /* For copyright information, see olden_v1.01/COPYRIGHT */

include ../../Makefile.defs

SRC_DIR=/ncstate_ece566_spring2020/simple/p3/C++/p3-test/../../../../wolfbench/Benchmarks/FIR
INSTALL_DIR=/ncstate_ece566_spring2020/simple/p3/C++/p3-test/install/bin

vpath %.c $(SRC_DIR)
vpath %.cpp $(SRC_DIR)

programs = fir

.PHONY: all install

all: $(addsuffix $(EXTRA_SUFFIX),$(programs))

install: all 

DEFS    = 

SOURCES = fir.c

# test information
INFILE  = /dev/null
OUTFILE = $(programs)$(EXTRA_SUFFIX).out
ARGS    = /ncstate_ece566_spring2020/simple/p3/C++/p3-test/../../../../wolfbench/Benchmarks/FIR/input.pcm
COMPARE = /ncstate_ece566_spring2020/simple/p3/C++/p3-test/../../../../wolfbench/Benchmarks/FIR/outputFloat.pcm outputFloat.pcm

include /ncstate_ece566_spring2020/simple/p3/C++/p3-test/../../../../wolfbench/Makefile.benchmark
include ../../Makefile.config

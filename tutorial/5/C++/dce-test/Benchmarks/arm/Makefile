# /* For copyright information, see olden_v1.01/COPYRIGHT */

include ../../Makefile.defs

SRC_DIR=/ncstate_ece566_spring2020/tutorial/5/C++/dce-test/../../../../wolfbench/Benchmarks/arm
INSTALL_DIR=/ncstate_ece566_spring2020/tutorial/5/C++/dce-test/install/bin

vpath %.c $(SRC_DIR)
vpath %.cpp $(SRC_DIR)

programs = arm

.PHONY: all install

all: $(addsuffix $(EXTRA_SUFFIX),$(programs)) 

install: all

DEFS    = -U__GNUC__ -D_NO_LONGLONG -DPLAIN -DOLDEN

SOURCES = arm.c

# test information
INFILE  = /ncstate_ece566_spring2020/tutorial/5/C++/dce-test/../../../../wolfbench/Benchmarks/arm/i.4
OUTFILE = $(addsuffix $(EXTRA_SUFFIX),$(programs)).output.stderr
ARGS    = 
COMPARE = /ncstate_ece566_spring2020/tutorial/5/C++/dce-test/../../../../wolfbench/Benchmarks/arm/arm.output.stderr $(OUTFILE)

include /ncstate_ece566_spring2020/tutorial/5/C++/dce-test/../../../../wolfbench/Makefile.benchmark
include ../../Makefile.config

# /* For copyright information, see olden_v1.01/COPYRIGHT */

include ../../Makefile.defs

SRC_DIR=/ncstate_ece566_spring2020/simple/p3/C++/p3-test/../../../../wolfbench/Benchmarks/CRC32
INSTALL_DIR=/ncstate_ece566_spring2020/simple/p3/C++/p3-test/install/bin

vpath %.c $(SRC_DIR)
vpath %.cpp $(SRC_DIR)

programs = crc32

.PHONY: all install

all: $(addsuffix $(EXTRA_SUFFIX),$(programs))

install: all 

DEFS    = 

SOURCES = crc_32.c

# test information
INFILE  = /dev/null
OUTFILE = output_large$(EXTRA_SUFFIX).out
ARGS    = /ncstate_ece566_spring2020/simple/p3/C++/p3-test/../../../../wolfbench/Benchmarks/adpcm/large.pcm
COMPARE= /ncstate_ece566_spring2020/simple/p3/C++/p3-test/../../../../wolfbench/Benchmarks/CRC32/output_large.txt output_large$(EXTRA_SUFFIX).out

include /ncstate_ece566_spring2020/simple/p3/C++/p3-test/../../../../wolfbench/Makefile.benchmark
include ../../Makefile.config

# /* For copyright information, see olden_v1.01/COPYRIGHT */

include ../../Makefile.defs

SRC_DIR=/ncstate_ece566_spring2020/tutorial/5/C++/dce-test/../../../../wolfbench/Benchmarks/adpcm
INSTALL_DIR=/ncstate_ece566_spring2020/tutorial/5/C++/dce-test/install/bin

vpath %.c $(SRC_DIR)
vpath %.cpp $(SRC_DIR)

programs = adpcm

.PHONY: all install

all: $(addsuffix $(EXTRA_SUFFIX),$(programs))

install: all

DEFS    = -U__GNUC__ -D_NO_LONGLONG -DPLAIN -DOLDEN

SOURCES = adpcm.c rawdaudio.c

# test information
INFILE  = /ncstate_ece566_spring2020/tutorial/5/C++/dce-test/../../../../wolfbench/Benchmarks/adpcm/large.pcm
OUTFILE = output_large.adpcm
ARGS    = 
COMPARE = `tar xzf /ncstate_ece566_spring2020/tutorial/5/C++/dce-test/../../../../wolfbench/Benchmarks/adpcm/output_large.adpcm.tgz; echo output_large.adpcm` $(OUTFILE)

include /ncstate_ece566_spring2020/tutorial/5/C++/dce-test/../../../../wolfbench/Makefile.benchmark
include ../../Makefile.config

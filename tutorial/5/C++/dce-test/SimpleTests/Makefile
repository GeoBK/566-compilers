include ../Makefile.defs

SRC_DIR=/ncstate_ece566_spring2020/tutorial/5/C++/dce-test/../../../../wolfbench/SimpleTests
INSTALL_DIR=/ncstate_ece566_spring2020/tutorial/5/C++/dce-test/install/bin

vpath %.c $(SRC_DIR)
vpath %.cpp $(SRC_DIR)

programs = hello 

exes = $(addsuffix $(EXTRA_SUFFIX),$(programs))

.PHONY: all install

all: $(exes)

install: all $(addsuffix -install,$(exes))

test: all $(addsuffix -test,$(exes))

ftest: all $(addsuffix -ftest,$(exes))

profile: all $(addsuffix -profile,$(exes))

compare: 

include ../../../../../wolfbench/Makefile.single
include ../Makefile.config

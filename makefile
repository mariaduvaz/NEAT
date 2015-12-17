#----------------------------------------------------------------
# Revised Makefile (19/02/2014 PS)
# How to call:
# calling as normal
#     > make
# will trigger the default compiler options.
#
# You can now also call using
#     > make CO=debug
# for extra warnings, gprof and gdb output, exception trapping
# at runtime, and bounds-checking.
# This option is slow (about 2x slower than make all)
#
# For working code, call
#     > make CO=fast
# to enable optimisation. This is about 2x faster than normal
# (using gfortran) but has little error trapping.
#
# Finally,
#     > make new
# simply calls clean then all to force a re-build.
#
# I have also included similar options for ifort. Since I have
# the compiler here, and it is potentially significantly faster,
# it may be useful when it comes time to do science.
#
#----------------------------------------------------------------

FC=gfortran
LD=gfortran
FFLAGS=-ffree-line-length-0 -Jsource/

ifeq ($(FC),gfortran)
  ifeq ($(CO),debug)
    FFLAGS += -fbounds-check -Wall -Wuninitialized #-ffpe-trap=zero,overflow,invalid,underflow,denormal
  endif
  ifeq ($(CO),debug2)
    FFLAGS += -g -pg -fbounds-check -Wall -Wuninitialized #-ffpe-trap=zero,overflow,invalid,underflow,denormal
  endif
  ifeq ($(CO),debug3)
    FFLAGS += -g -pg -fbounds-check -Wall -Wuninitialized -ffpe-trap=zero,overflow,invalid,underflow,denormal
  endif
  ifeq ($(CO),pedantic)
    FFLAGS += -g -pg -fbounds-check -Wall -Wuninitialized -Werror -pedantic -ffpe-trap=zero,overflow,invalid,underflow,denormal
  endif
  ifeq ($(CO),fast)
    FFLAGS += -O3 -fno-backtrace
  endif
endif

ifeq ($(FC),ifort)
  FFLAGS = -O0 #-warn all -warn errors
  LD=ifort
  ifeq ($(CO),debug)
    FFLAGS = -pg -g -check bounds -check uninit -warn all -warn nodeclarations -WB -zero -traceback # -std
  endif
  ifeq ($(CO),pedantic)
    FFLAGS = -pg -g -check bounds -check uninit -warn all -warn nodeclarations -WB -zero -traceback -std
  endif
  ifeq ($(CO),fast)
    FFLAGS = -axavx -msse3 -O3 -ip -ipo # for today's CPUs
#    FFLAGS = -fast -tune pn4 # for older pentium 4
  endif
endif

.PHONY: all clean install

new: clean all

all: neat

%.o: %.f95
	$(FC) $(FFLAGS) $< -c -o $@

neat: source/types.o source/oii_diagnostics.o source/hydrogen.o source/extinction.o source/rec_lines.o source/helium.o source/equib_routines.o source/filereading.o source/abundances.o source/quicksort.o source/linefinder.o source/neat.o
	$(LD) $(LDFLAGS) $(FFLAGS) -o $@ $^

clean:
	rm -f neat source/*.o source/*.mod

install:
	test -e ${PREFIX}/etc/neat || mkdir ${PREFIX}/etc/neat
	install -m 644 Atomic-data/*.* ${PREFIX}/etc/neat
	install neat ${PREFIX}/usr/bin
#	install -g 0 -o 0 -m 644 man/neat.1 ${MANDIR}
#	gzip -f ${MANDIR}/neat.1
#	ln -s -f ${MANDIR}/neat.1.gz ${MANDIR}/neatcube.1.gz

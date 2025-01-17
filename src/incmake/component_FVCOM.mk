########################################################################

# This is a template for a component makefile fragment.  In this case,
# the component is "FOO" and so the file would be renamed to
# component_FOO.mk.

# The build and clean rules are set to those of the "build_std"
# function in the old NEMSAppBuilder.  For a different build system,
# the $(foo_mk) and clean_FOO rules.

# Note that in the build and clean rules, any shell variables must
# have double dollar signs ($$) to prevent Make from interpreting them.

# Also note that the commands in the build or clean rules must be a
# single valid shell command line, hence the "; \" at the end of every
# statement.

# clean_FOO: 
# 	something $$happens ; \
# 	something $$else $$happens

# The correct way to run a submake is this:
#
#   +$(MODULE_LOGIC) ; exec $(MAKE) -C $(FOO_SRCDIR) $(FOO_ALL_OPTS) target
#
# If you don't need modules, and you don't care if the "make" succeeds
# (such as when you're cleaning), then this works:
#
#   +-$(MAKE) -C $(FOO_SRCDIR) $(FOO_ALL_OPTS) clean
#
# Meanings of those characters:
#
#   +      = this rule runs "make." Ensures job server (-j) is passed on
#   -      = ignore the exit status of this rule (as if -k was used)
#   $(MAKE) = the path to the "make" program used to run this makefile
#   $(MODULE_LOGIC) = load modules or source the modulefile, if relevant
#   exec $(MAKE)    = the shell process is replaced by "make."  This is
#                     needed to correctly pass on the job server information
#   -C $(FOO_SRCDIR) = cd to $(FOO_SRCDIR) before running make
#   $(FOO_ALL_OPTS)  = pass on all FOO options from the $(FOO_ALL_OPTS) variable
#   target or clean  = the "make" target to build

########################################################################

# Location of source code and installation
FVCOM_SRCDIR?=$(ROOTDIR)/FVCOM
FVCOM_BINDIR?=$(ROOTDIR)/FVCOM_INSTALL
FVCOM_NUOPC_SRCDIR?=$(FVCOM_SRCDIR)/nuopc

# Location of the ESMF makefile fragment for this component:
fvcom_mk = $(FVCOM_BINDIR)/fvcom.mk
all_component_mk_files+=$(fvcom_mk)

# Make sure the expected directories exist and are non-empty:
$(call require_dir,$(FVCOM_SRCDIR),FVCOM source directory)
$(call require_dir,$(FVCOM_NUOPC_SRCDIR),FVCOM NUOPC source directory)

ifeq ($(NEMS_COMPILER),gnu)
  EXT_GCC_FLAGS:=$(shell if [ `gcc --version | head -1 | awk '{print $$NF}' | cut -d '.' -f 1` -ge 10 ]; then \
                         echo "-fallow-argument-mismatch -fallow-invalid-boz"; fi)
  COMPFLAG=-DGFORTRAN
  DEBFLGS="$(EXT_GCC_FLAGS)"
else ifeq ($(NEMS_COMPILER),intel)
  COMPFLAG=-DIFORT
else ifeq ($(NEMS_COMPILER),pgi)
  COMPFLAG=
else
  COMPFLAG=$(COMPILER_FLAG)
endif

FVCOM_OPTS= \
  TOPDIR=$(FVCOM_SRCDIR)/src \
  COMPFLAG=$(COMPFLAG) \
  DEBFLGS=$(DEBFLGS) \
  CC=$(PCC) CXX=$(PCXX) FC=$(PFC) F90=$(PF90) \
  INCLUDEPATH="$(INCLUDEPATH)" LIBPATH="$(LIBPATH)" \
  DTINCS="$(DTINCS)" DTLIBS=-ljulian \
  FLAG_USE_NETCDF4=-DUSE_NETCDF4 \
  IOINCS="-I$(NETCDFHOME)/include" \
  IOLIBS="-L$(NETCDFHOME)/lib -lnetcdff -lnetcdf" \
  FLAG_6=-DPROJ \
  PROJINCS="$(PROJINCS)" PROJLIBS="$(PROJLIBS)" \
  FLAG_411=-DMETIS_5 \
  PARLIB="-L$(METISHOME)/lib -lmetis" \
  PARTINCS="-I$(METISHOME)/include" \
  PARTLIBS="-L$(METISHOME)/lib -lmetis"

FVCOM_ALL_OPTS= \
  COMP_SRCDIR="$(FVCOM_SRCDIR)" \
  COMP_BINDIR="$(FVCOM_BINDIR)" \
  MACHINE_ID="$(MACHINE_ID)" \
  $(FVCOM_OPTS)

########################################################################

# Rule for building this component:

build_FVCOM: $(fvcom_mk)

$(fvcom_mk): configure
	+$(MODULE_LOGIC) ; cd $(FVCOM_SRCDIR)/src ; \
	                   exec $(MAKE) $(FVCOM_OPTS) FLAG_81=-DNUOPC libfvcom
	+$(MODULE_LOGIC) ; cd $(FVCOM_NUOPC_SRCDIR) ; \
	                   exec $(MAKE) $(FVCOM_ALL_OPTS)  \
	                   DESTDIR=/ "INSTDIR=$(FVCOM_BINDIR)" nuopcinstall
	test -d "$(FVCOM_BINDIR)"
	test -s $(fvcom_mk)

########################################################################

# Rule for cleaning the SRCDIR and BINDIR:

clean_FVCOM_NUOPC:
	+cd $(FVCOM_NUOPC_SRCDIR); exec rm -f *.o *.mod
	@echo ""

distclean_FVCOM_NUOPC: clean_FVCOM_NUOPC
	+cd $(FVCOM_NUOPC_SRCDIR) ; exec rm -f libfvcom_cap.a fvcom.mk
	@echo ""

clean_FVCOM: clean_FVCOM_NUOPC
	+cd $(FVCOM_SRCDIR)/src ; exec $(MAKE) -k clean

distclean_FVCOM: clean_FVCOM
	+cd $(FVCOM_SRCDIR)/src ; exec $(MAKE) -k distclean
	rm -rf $(FVCOM_BINDIR)

########################################################################
### Panagiotis Velissariou <panagiotis.velissariou@noaa.gov> - 18/05/2021
### Carsten Lemmen <carsten.lemmen@hereon.de> - 19/06/2021
###
### Version: 1.2 (01/29/2023)
### Version: 1.1 (06/19/2021)
########################################################################

# Location of source code and installation
SCHISM_ROOTDIR?=$(ROOTDIR)/SCHISM
SCHISM_SRCDIR?=$(SCHISM_ROOTDIR)/schism/src
SCHISM_BLDDIR?=$(SCHISM_ROOTDIR)/build
SCHISM_BINDIR?=$(ROOTDIR)/SCHISM_INSTALL

# Export destination and build directories for schism-esmf Makefile, which
# expects SCHISM_BUILD_DIR and SCHISM_NO_PARMETIS to be set
export SCHISM_BUILD_DIR:=$(SCHISM_BDLDIR)
export SCHISM_NO_PARMETIS:=OFF

# SCHISM needs the compilers for C, Fortran and CXX, the latter ones
# are defined in ESMFMKFILE, the former is computed here (@todo test), by
# trying mpicxx, mpiicpc and mpicpc as CXXCOMPILER
include $(ESMFMKFILE)
ESMF_CCOMPILER=$(subst mpicxx,mpicc,$(ESMF_CXXCOMPILER))
ifeq ($(ESMF_CCOMPILER),$(ESMF_CXXCOMPILER))
ESMF_CCOMPILER:=$(subst mpiicpc,mpiicc,$(ESMF_CXXCOMPILER))
endif
ifeq ($(ESMF_CCOMPILER),$(ESMF_CXXCOMPILER))
ESMF_CCOMPILER:=$(subst mpicpc,mpicc,$(ESMF_CXXCOMPILER))
endif

# Location of the ESMF makefile fragment for this component:
schism_mk = $(SCHISM_BINDIR)/schism.mk
all_component_mk_files+=$(schism_mk)

# Make sure the expected directories exist and are non-empty:
$(call require_dir,$(SCHISM_SRCDIR),SCHISM source directory)

# ENV for SCHISM - exchange with NEMS ENV

SCHISM_ALL_OPTS= \
  COMP_SRCDIR="$(SCHISM_SRCDIR)" \
  COMP_BINDIR="$(SCHISM_BINDIR)" \
  MACHINE_ID="$(MACHINE_ID)"

########################################################################
# Rule for building this component:

build_SCHISM: $(schism_mk)

$(schism_mk): configure $(CONFDIR)/configure.nems
  ### Configure CMake build for SCHISM
	+$(MODULE_LOGIC); echo "SCHISM_SRCDIR = $(SCHISM_SRCDIR)"; exec cmake -S $(SCHISM_SRCDIR) -B $(SCHISM_BLDDIR) \
	   -DCMAKE_VERBOSE_MAKEFILE=TRUE -DCMAKE_Fortran_COMPILER=$(ESMF_F90COMPILER) \
	   -DCMAKE_CXX_COMPILER=$(ESMF_CXXCOMPILER) -DCMAKE_C_COMPILER=$(ESMF_CCOMPILER) \
	   -DOLDIO=ON -DUSE_WW3=OFF -DPREC_EVAP=OFF -DNO_PARMETIS=$(SCHISM_NO_PARMETIS)

  ### Compile the SCHISM components
	+cd $(SCHISM_BLDDIR); exec $(MAKE) pschism

	### Compile the SCHISM cap, this uses the SCHISM_BUILD_DIR and SCHISM_NO_PARMETIS exported variables
	make -C  $(SCHISM_ROOTDIR)/schism-esmf DESTDIR=$(SCHISM_BINDIR) \
	  SCHISM_BUILD_DIR=$(SCHISM_BLDDIR) install-nuopc
	@echo ""
	test -d "$(SCHISM_BINDIR)"
	@echo ""
	test -s $(schism_mk)
	@echo ""

########################################################################

# Rule for cleaning the SRCDIR and BINDIR:

clean_SCHISM:
	+cd $(SCHISM_ROOTDIR)/schism-esmf; exec $(MAKE) DESTDIR=$(SCHISM_BINDIR) SCHISM_BUILD_DIR=$(SCHISM_BLDDIR) -k clean
ifneq ($(wildcard $(SCHISM_BLDDIR)/Makefile),)
	+cd $(SCHISM_BLDDIR) ; exec $(MAKE) -k clean
endif
	@echo ""

distclean_SCHISM: clean_SCHISM
	+cd $(SCHISM_ROOTDIR)/schism-esmf; exec $(MAKE) DESTDIR=$(SCHISM_BINDIR) SCHISM_BUILD_DIR=$(SCHISM_BLDDIR) -k distclean
	rm -rf $(SCHISM_BLDDIR) $(SCHISM_BINDIR)
	@echo ""

distclean_NUOPC:
	+cd $(SCHISM_ROOTDIR)/schism-esmf; exec $(MAKE) DESTDIR=$(SCHISM_BINDIR) SCHISM_BUILD_DIR=$(SCHISM_BLDDIR) -k distclean
	@echo ""

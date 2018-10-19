########################################################################
#
# This file cleans up the component list and handles inter-component
# dependencies.
#
########################################################################

REQUESTED_COMPONENTS:=$(COMPONENTS)

########################################################################

# Separate with spaces, not commas and remove leading or trailing space

cleaned_components:=$(COMPONENTS)
cleaned_components:=$(strip $(subst $(comma),$(space),$(cleaned_components)))
override COMPONENTS:=$(cleaned_components)

########################################################################

# Given components like this:
#   COMPONENTS=FMS CCPP FV3%32BIT=Y
# Turn it into:
#   COMPONENTS=FMS CCPP FV3
#   FV3_MAKEOPT=32BIT=Y

# *_part: functions to get the "FV3" or "32BIT=Y" part of FV3%32BIT=Y:
comp_part = $(word 1,$(call split,$(percent),$(1)))
args_part = $(call rest,$(call split,$(percent),$(1)))

# assign_args: function that sets FV3_MAKEOPT=32BIT=Y from FV3%32BIT=Y
# and give an $(info) message about it.
assign_args = $(eval $(call comp_part,$(1))_MAKEOPT += $(call args_part,$(1)))$(info $(1) => $(call comp_part,$(1))_MAKEOPT += $(call args_part,$(1)))

# unpercent: function to filter for the COMPONENTS list.  Sets the
# FOO_MAKEOPT variable and returns the component name.
unpercent = $(if $(findstring $(percent),$(1)),$(call comp_part,$(1))$(call assign_args,$(1)),$(1))

percented:=$(COMPONENTS)
unpercented:=$(foreach COMP,$(percented),$(call unpercent,$(COMP)))

override COMPONENTS:=$(unpercented)

#########################################################################

# Handle depedencies between components

# We'll make this file which will contain the new components:
new_components_file=$(NEMSDIR)/src/conf/components.mk

# First, delete the file:
$(and $(shell rm -f $(new_components_file)),)

# Now recurse into dependencies.mk to generate the new component list:
$(and $(shell $(MAKE) -f $(NEMSDIR)/src/incmake/dependencies.mk COMPONENTS="$(COMPONENTS)" TARGET="$(new_components_file)" COMPONENTS),)

# If the file does not exist, then the components are invalid, or none
# were specified:
ifeq (,$(wildcard $(new_components_file)))
  $(error Invalid or missing COMPONENTS)
endif

# Get the new component list:
include $(new_components_file)

.INTERMEDIATE: $(new_components_file)

# If the resulting COMPONENTS variable is empty, then something els3e when wrong.
ifeq ($(COMPONENTS),)
  $(error Invalid or missing COMPONENTS)
endif

########################################################################

# Tools to print component options.

# $(call one_component_vars,COMPONENT,OPT)
# Looks for the $(COMPONENT)_$(OPT)OPT variable and prints it via
# $(info) if it exists.  Return value is the variable name, if the
# variable is set, and the empty string otherwise.
one_component_vars=$(if $($(1)_$(2)),$(info $(space)$(space)$(1)_$(2) = $($(1)_$(2)))$(1)_$(2))

# $(call print_component_vars,COMPONENT,OPT)
# Looks for the FOO_MAKEOPT, FOO_BUILDOPT, and FOO_CONFOPT variables,
# for each component FOO.  Prints a message about each one that is
# set, via the $(info) function.
print_component_vars=$(foreach opt,BUILDOPT MAKEOPT CONFOPT BINDIR SRCDIR,$(foreach comp,$(COMPONENTS),$(call one_component_vars,$(comp),$(opt))))
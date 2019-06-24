#
# This is a project Makefile. It is assumed the directory this Makefile resides in is a
# project subdirectory.
#

PROJECT_NAME := esp-sbfe-flash

MAKE_RESTARTS?=
$(info --------------- SBFE Subproject ---------------)
$(info Make execution : restart $(MAKE_RESTARTS), level $(MAKELEVEL))

# Name of component to use
# found in the COMPONENT_DIRS
COMPONENTS := esptool_py esp-sbfe-flash esp-sbfe-burn

COMPONENT_DIRS = $(PROJECT_PATH) $(IDF_PATH)/components

IS_BOOTLOADER_BUILD := 1
export IS_BOOTLOADER_BUILD


# The following report warning, but should not be defined
#CONFIG_SECURE_BOOT_BUILD_SIGNED_BINARIES?=
#CONFIG_SECURE_BOOT_ENABLED?=

ifneq ($(V),)
$(foreach V,$(sort $(.VARIABLES)), \
	$(if $(filter SBFE_VAR%, \
	$V),$(info - $V : $($V)) ))
endif


SBFE_VAR_DRY_RUN?=
SBFE_FLH_DRYRUN=
ifneq ($(SBFE_VAR_DRY_RUN),)
$(info --------------- SBFE Processing in Dry Run ---------------)
SBFE_FLH_DRYRUN=echo "\t\t"
endif

include ../esp-sbfe-common/esp-sbfe-common.mk

include $(IDF_PATH)/make/project.mk

$(info COMPONENT_DIRS : $(COMPONENT_DIRS))
$(info --- ESP SBFE Flash Makefile --- )
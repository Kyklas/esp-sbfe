#
# ESP Secure Boot & Flash Encryption functions
#

$(info Definition of SBFE Function)

# Variable for the bootloader
# since the bootloader has secure boot
# it has dedicated variable
SBFE_VAR_BL_BIN=
SBFE_VAR_BL_OFFSET=

# For other binaries to process
# declaration is made via templates
SBFE_VAR_BIN_IDX?=

#
# Help to define SBFE Var to be exported
# $1 index
# $2 binary
# $3 offset
# $4 encryption (1-enable)
#
define sbfe-declare-binary
$(info SBFE declaration of binary $1)
$(eval SBFE_VAR_BIN_IDX+=$1)
$(eval SBFE_VAR_BIN_$(1)_BIN=$2)
$(eval SBFE_VAR_BIN_$(1)_OFFSET=$3)
$(eval SBFE_VAR_BIN_$(1)_ENC=$4)
$(call sbfe-declare-target,$1)
endef

define sbfe-declare-target
$(info SBFE declaration of binary target $1)
sbfe-flash-$1: sbfe-flash-check sbfe-export $(SBFE_VAR_BIN_$(1)_BIN)
	$$(SBFE_CMD_MAKE) $$@
endef

ifneq ($(MAKE_LEVEL),0)




endif

$(eval $(call sbfe-declare-binary,test1,mybin,myoffset,1))
#
# ESP Secure Boot & Flash Encryption functions
#

#
# SBFE binary declaration is for variable related to the binary file
#
# Help to define SBFE Var to be exported
# $1 index
# $2 binary
# $3 offset
# $4 encryption (1-enable)
#
define sbfe-declare-binary
$(if $(V),$(info SBFE - declaration of binary variables for $1))
$(eval SBFE_VAR_BIN_IDX+=$1)
$(eval SBFE_VAR_BIN_$(1)_BIN=$2)
$(eval SBFE_VAR_BIN_$(1)_OFFSET=$3)
$(eval SBFE_VAR_BIN_$(1)_ENC=$4)
$(eval SBFE_VAR_BIN_$(1)_SECBT=$5)
$(call sbfe-declare-binary-target,$1)
endef

#
# SBFE binary target declaration is for calling flashing the binary
#
define sbfe-declare-binary-target
$(if $(V),$(info SBFE - declaration of binary target for $1))
sbfe-flash-$1: sbfe-flash-check sbfe-export $(SBFE_VAR_BIN_$(1)_BIN)
	$$(SBFE_CMD_MAKE) $$@
endef

#
# SBFE flash declaration is for variable related to multiple binary files
#
# Will reference different binary file that should be declared before
#
define sbfe-declare-flash
$(if $(V),$(info SBFE - declaration of flash variable for $1))
$(eval SBFE_VAR_FLSH_IDX+=$1)
$(eval SBFE_VAR_FLSH_$(1)_TARGET=$1)
$(eval SBFE_VAR_FLSH_$(1)_BIN_IDX=$2)
$(call sbfe-declare-flash-target,$1)
endef

#
# SBFE flash target declaration is for calling flashing multiple binaries
#
define sbfe-declare-flash-target
$(if $(V),$(info SBFE - declaration of flash target for $1))

sbfe-flash-$1-dep: $(foreach bin,$(SBFE_VAR_FLSH_$(1)_BIN_IDX), $(SBFE_VAR_BIN_$(bin)_BIN))
	echo Dependency :
	$$(call sbfe-print-list, $$^)

sbfe-flash-$1: sbfe-flash-check sbfe-export sbfe-flash-$1-dep
	$$(SBFE_CMD_MAKE) $$@
endef



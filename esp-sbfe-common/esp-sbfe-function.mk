#
# ESP Secure Boot & Flash Encryption functions
#

$(info Definition of SBFE Function : $(MAKELEVEL))

SBFE_FLH_DRYRUN=
ifeq ($(SBFE_VAR_DRY_RUN),1)
SBFE_FLH_DRYRUN=echo "\t\t"
endif

SBFE_STYLE_CLEAR:=$(shell printf `tput sgr0`)
SBFE_STYLE_TARGET:=$(shell printf `tput setaf 6;tput bold`)
SBFE_STYLE_DEP:=$(shell printf `tput setaf 2;tput bold`)
SBFE_STYLE_KEY:=$(shell printf `tput setaf 1;tput bold`)

# Variable for the bootloader
# since the bootloader has secure boot
# it has dedicated variable
SBFE_VAR_BL_BIN=
SBFE_VAR_BL_OFFSET=

# For other binaries to process
# declaration is made via templates
SBFE_VAR_BIN_IDX?=
SBFE_VAR_FLSH_IDX?=

ifeq ($(MAKELEVEL),0)

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
$(eval SBFE_VAR_BIN_$(1)_SECBT=$5)
$(call sbfe-declare-target,$1)
endef

define sbfe-declare-target
$(info SBFE declaration of binary target $1)
sbfe-flash-$1: sbfe-flash-check sbfe-export $(SBFE_VAR_BIN_$(1)_BIN)
	$$(SBFE_CMD_MAKE) $$@
endef

#
# Help to define SBFE combined binary to flash
#
define sbfe-declare-flash-target
$(info SBFE declaration of flash target $1)
$(eval SBFE_VAR_FLSH_IDX+=$1)
$(eval SBFE_VAR_FLSH_$(1)_TARGET=$1)
$(eval SBFE_VAR_FLSH_$(1)_BIN_IDX=$2)
$(call sbfe-declare-target-flash-target,$1)
endef

define sbfe-declare-target-flash-target
$(info SBFE declaration of binary target $1)

sbfe-flash-$1-dep: $(foreach bin,$(SBFE_VAR_FLSH_$(1)_BIN_IDX), $(SBFE_VAR_BIN_$(bin)_BIN))
	echo Dependency :
	$$(call sbfe-print-list, $$^)

sbfe-flash-$1: sbfe-flash-check sbfe-export sbfe-flash-$1-dep
	$$(SBFE_CMD_MAKE) $$@
endef

else # Make level is 0

define sbfe-declare-target
ifneq ($(SBFE_VAR_BIN_$(1)_BIN),)
ifneq ($(SBFE_VAR_BIN_$(1)_OFFSET),)

$(info SBFE declaration of binary target $1)

ifeq ($(SBFE_VAR_BIN_$(1)_SECBT).$(SBFE_VAR_SECURE_BOOT),1.1)
# Save original filename
$(eval SBFE_VAR_BIN_$(1)_BIN_ORJ:=$(SBFE_VAR_BIN_$(1)_BIN))

$(eval SBFE_FLSH_BIN_$(1)_BIN_SECBT=$(basename $(SBFE_VAR_BIN_$(1)_BIN))-digest.bin)

.INTERMEDIATE: $(SBFE_FLSH_BIN_$(1)_BIN_SECBT) 

$(SBFE_FLSH_BIN_$(1)_BIN_SECBT) : $(SBFE_VAR_BIN_$(1)_BIN_ORJ) $(SBFE_VAR_KEY_DIR)/$(SBFE_VAR_SB_KEY_FILENAME)
	echo "Generating $(SBFE_STYLE_TARGET)$$(notdir $$@)$(SBFE_STYLE_CLEAR) from $(SBFE_STYLE_DEP)$$(notdir $$<)$(SBFE_STYLE_CLEAR)"
	echo "Secure Boot Key : $(SBFE_STYLE_KEY)$(SBFE_VAR_KEY_DIR)/$(SBFE_VAR_SB_KEY_FILENAME)$(SBFE_STYLE_CLEAR)"
	$(SBFE_FLH_DRYRUN)  $(ESPSECUREPY) digest_secure_bootloader \
				-k $(SBFE_VAR_KEY_DIR)/$(SBFE_VAR_SB_KEY_FILENAME) \
				-o $$@ $$<

# set to the new secure digiest
# the variable does not change but it's value does
# pointing to another file
$(if $(filter $(SBFE_VAR_BIN_$(1)_SECBT).$(SBFE_VAR_SECURE_BOOT),1.1), \
	$(eval SBFE_VAR_BIN_$(1)_BIN:=$(SBFE_FLSH_BIN_$(1)_BIN_SECBT)))
# Changing offset
$(if $(filter $(SBFE_VAR_BIN_$(1)_SECBT).$(SBFE_VAR_SECURE_BOOT),1.1), \
	$(eval SBFE_VAR_BIN_$(1)_OFFSET:=0))

endif

ifeq ($(SBFE_VAR_BIN_$(1)_ENC).$(SBFE_VAR_FLASH_ENCRYPTION),1.1)
# Flashing with encrypted binary

$(eval SBFE_FLSH_BIN_$(1)_BIN_ENC=$(basename $(SBFE_VAR_BIN_$(1)_BIN))-encrypted.bin)

.INTERMEDIATE: $(SBFE_FLSH_BIN_$(1)_BIN_ENC)

$(SBFE_FLSH_BIN_$(1)_BIN_ENC): $(SBFE_VAR_BIN_$(1)_BIN) $(SBFE_VAR_KEY_DIR)/$(SBFE_VAR_FE_KEY_FILENAME)
	echo "Generating $(SBFE_STYLE_TARGET)$$(notdir $$@)$(SBFE_STYLE_CLEAR) from $(SBFE_STYLE_DEP)$$(notdir $$<)$(SBFE_STYLE_CLEAR)"
	echo "Encryption Key : $(SBFE_STYLE_KEY)$(SBFE_VAR_KEY_DIR)/$(SBFE_VAR_FE_KEY_FILENAME)$(SBFE_STYLE_CLEAR)"
	$(SBFE_FLH_DRYRUN) $(ESPSECUREPY) encrypt_flash_data \
			-k $(SBFE_VAR_KEY_DIR)/$(SBFE_VAR_FE_KEY_FILENAME) \
			-a $(SBFE_VAR_BIN_$(1)_OFFSET) -o $$@ $$<
		
SBFE_FLSH_BIN_$(1)_DEP=$(SBFE_FLSH_BIN_$(1)_BIN_ENC)
SBFE_FLSH_BIN_$(1)_ARG=$(SBFE_VAR_BIN_$(1)_OFFSET) $(SBFE_FLSH_BIN_$(1)_BIN_ENC)
else
# Flashing directly binary
SBFE_FLSH_BIN_$(1)_DEP=$(SBFE_VAR_BIN_$(1)_BIN)
SBFE_FLSH_BIN_$(1)_ARG=$(SBFE_VAR_BIN_$(1)_OFFSET) $(SBFE_VAR_BIN_$(1)_BIN)
endif

sbfe-flash-$1: $$(SBFE_FLSH_BIN_$(1)_DEP)
	echo Processing Flashing \'$1\' : $$@
	$$(call sbfe-print-list, $$^)
	$$(call sbfe-print-list, $$(SBFE_FLSH_BIN_$(1)_ARG))
	$(SBFE_FLH_DRYRUN) $(ESPTOOLPY_WRITE_FLASH) $$(SBFE_FLSH_BIN_$(1)_ARG)
endif # SBFE_VAR_BIN_$(1)_OFFSET is not null
endif # SBFE_VAR_BIN_$(1)_BIN is not null
	
endef # sbfe-declare-target

define sbfe-declare-flash-target
$(info SBFE declaration of flash target $1)
$(info - TGT - $(SBFE_VAR_FLSH_$(1)_TARGET))
$(info - IDX - $(SBFE_VAR_FLSH_$(1)_BIN_IDX))
$(call sbfe-declare-flash-target-def,$1,$(SBFE_VAR_FLSH_$(1)_BIN_IDX))
endef

#
# $1 name
# $2 list of binary target
#
define sbfe-declare-flash-target-def

SBFE_FLSH_TGT_$(1)_DEP=$(foreach bin,$2, $(SBFE_FLSH_BIN_$(bin)_DEP) )
SBFE_FLSH_TGT_$(1)_ARG=$(foreach bin,$2, $(SBFE_FLSH_BIN_$(bin)_ARG) )

sbfe-flash-$1: $$(SBFE_FLSH_TGT_$(1)_DEP)
	echo Processing Flash Target \'$1\' : $$@
	$$(call sbfe-print-list, $$^)
	$$(call sbfe-print-list, $$(SBFE_FLSH_TGT_$(1)_ARG))
	$(SBFE_FLH_DRYRUN) $(ESPTOOLPY_WRITE_FLASH) $$(SBFE_FLSH_TGT_$(1)_ARG)

endef # sbfe-declare-flash-target

endif # make level is more than 0

define sbfe-print-list
	printf "$(foreach v,$1,\t$(v)\n)\n"
endef




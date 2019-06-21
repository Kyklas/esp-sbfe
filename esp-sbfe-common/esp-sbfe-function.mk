#
# ESP Secure Boot & Flash Encryption functions
#

$(info Definition of SBFE Function : $(MAKELEVEL))

# Variable for the bootloader
# since the bootloader has secure boot
# it has dedicated variable
SBFE_VAR_BL_BIN=
SBFE_VAR_BL_OFFSET=

# For other binaries to process
# declaration is made via templates
SBFE_VAR_BIN_IDX?=

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
$(call sbfe-declare-target,$1)
endef

define sbfe-declare-target
$(info SBFE declaration of binary target $1)
sbfe-flash-$1: sbfe-flash-check sbfe-export $(SBFE_VAR_BIN_$(1)_BIN)
	$$(SBFE_CMD_MAKE) $$@
endef

else # Make level is 0

SBFE_FLH_DRYRUN=echo

define sbfe-declare-target
$(info SBFE declaration of binary target $1)
ifeq ($(SBFE_VAR_BIN_$(1)_ENC).$(SBFE_VAR_FLASH_ENCRYPTION),1.1)
# Flashing with encrypted binary

$(eval SBFE_FLSH_BIN_$(1)_BIN_ENC=$(basename $(SBFE_VAR_BIN_$(1)_BIN))-encrypted.bin)

$(SBFE_FLSH_BIN_$(1)_BIN_ENC): $(SBFE_VAR_BIN_$(1)_BIN) $(SBFE_VAR_KEY_DIR)/$(SBFE_VAR_FE_KEY_FILENAME)
	echo "Generating $$@ from $$<"
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
	echo Processing Flashing \'$1\' : $$@ $$<
	$(call sbfe-print-list, $$<)
	$(call sbfe-print-list, $$(SBFE_FLSH_BIN_$(1)_ARG))
	$(SBFE_FLH_DRYRUN) $(ESPTOOLPY_WRITE_FLASH) $$(SBFE_FLSH_BIN_$(1)_ARG)
	
endef

endif # make level is more than 0

define sbfe-print-list
	printf "$(foreach v,$1,\t$(v)\n)\n"
endef


# for testing
ifeq ($(MAKELEVEL),0)
	
$(eval $(call sbfe-declare-binary,test1,mybin,myoffset,1))
$(eval $(call sbfe-declare-binary,test0,mybin,myoffset,0))
$(eval $(call sbfe-declare-binary,test,mybin,myoffset,))

endif

mybin:
	echo "Bummy Binary"



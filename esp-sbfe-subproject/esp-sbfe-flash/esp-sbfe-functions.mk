#
# ESP Secure Boot & Flash Encryption functions
#

SBFE_VAR_DRY_RUN?=
SBFE_FLH_DRYRUN=
ifeq ($(SBFE_VAR_DRY_RUN),1)
SBFE_FLH_DRYRUN=echo "\t\t"
endif

# Set the binary and flash index list empty if not defined
SBFE_VAR_BIN_IDX?=
SBFE_VAR_FLSH_IDX?=

define sbfe-declare-binary-target
ifneq ($(SBFE_VAR_BIN_$(1)_BIN),)
ifneq ($(SBFE_VAR_BIN_$(1)_OFFSET),)

$(if $(V),$(info SBFE - declaration of binary target $1))

ifeq ($(SBFE_VAR_BIN_$(1)_SECBT).$(SBFE_VAR_SECURE_BOOT),1.1)
# Save original filename
$(eval SBFE_VAR_BIN_$(1)_BIN_ORJ:=$(SBFE_VAR_BIN_$(1)_BIN))

$(eval SBFE_FLSH_BIN_$(1)_BIN_SECBT=$(basename $(SBFE_VAR_BIN_$(1)_BIN))-digest.bin)

.INTERMEDIATE: $(SBFE_FLSH_BIN_$(1)_BIN_SECBT) 

$(SBFE_FLSH_BIN_$(1)_BIN_SECBT) : $(SBFE_VAR_BIN_$(1)_BIN_ORJ) $(SBFE_VAR_KEY_DIR)/$(SBFE_VAR_SB_KEY_FILENAME)
	echo "Generating $(SBFE_STYLE_TARGET)$$(notdir $$@)$(SBFE_STYLE_CLEAR) from $(SBFE_STYLE_DEP)$$(notdir $$<)$(SBFE_STYLE_CLEAR)"; \
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

endif # Secure Boot check

ifeq ($(SBFE_VAR_BIN_$(1)_ENC).$(SBFE_VAR_FLASH_ENCRYPTION),1.1)
# Flashing with encrypted binary

$(eval SBFE_FLSH_BIN_$(1)_BIN_ENC=$(basename $(SBFE_VAR_BIN_$(1)_BIN))-encrypted.bin)

.INTERMEDIATE: $(SBFE_FLSH_BIN_$(1)_BIN_ENC)

$(SBFE_FLSH_BIN_$(1)_BIN_ENC): $(SBFE_VAR_BIN_$(1)_BIN) $(SBFE_VAR_KEY_DIR)/$(SBFE_VAR_FE_KEY_FILENAME)
	echo "Generating $(SBFE_STYLE_TARGET)$$(notdir $$@)$(SBFE_STYLE_CLEAR) from $(SBFE_STYLE_DEP)$$(notdir $$<)$(SBFE_STYLE_CLEAR)"; \
	echo "Encryption Key : $(SBFE_STYLE_KEY)$(SBFE_VAR_KEY_DIR)/$(SBFE_VAR_FE_KEY_FILENAME)$(SBFE_STYLE_CLEAR)"
	$(SBFE_FLH_DRYRUN) $(ESPSECUREPY) encrypt_flash_data \
			-k $(SBFE_VAR_KEY_DIR)/$(SBFE_VAR_FE_KEY_FILENAME) \
			-a $(SBFE_VAR_BIN_$(1)_OFFSET) -o $$@ $$<
		
SBFE_FLSH_BIN_$(1)_DEP=$(SBFE_FLSH_BIN_$(1)_BIN_ENC)
SBFE_FLSH_BIN_$(1)_ARG=$(SBFE_VAR_BIN_$(1)_OFFSET) $(SBFE_FLSH_BIN_$(1)_BIN_ENC)
else # Flash Encryption enabled
# Flashing directly binary
SBFE_FLSH_BIN_$(1)_DEP=$(SBFE_VAR_BIN_$(1)_BIN)
SBFE_FLSH_BIN_$(1)_ARG=$(SBFE_VAR_BIN_$(1)_OFFSET) $(SBFE_VAR_BIN_$(1)_BIN)
endif # Flash Encryption disabled

sbfe-flash-$1: $$(SBFE_FLSH_BIN_$(1)_DEP)
	echo Flashing Binary \'$1\'
	$$(call sbfe-print-list, $$^)
	$$(call sbfe-print-list, $$(SBFE_FLSH_BIN_$(1)_ARG))
	$(SBFE_FLH_DRYRUN) $(ESPTOOLPY_WRITE_FLASH) $$(SBFE_FLSH_BIN_$(1)_ARG)
endif # SBFE_VAR_BIN_$(1)_OFFSET is not null
endif # SBFE_VAR_BIN_$(1)_BIN is not null
	
endef # sbfe-declare-binary-target

define sbfe-declare-flash-target
$(if $(V),$(info SBFE - declaration of flash target $1))

SBFE_FLSH_TGT_$(1)_DEP=$(foreach bin,$(SBFE_VAR_FLSH_$(1)_BIN_IDX), $(SBFE_FLSH_BIN_$(bin)_DEP) )
SBFE_FLSH_TGT_$(1)_ARG=$(foreach bin,$(SBFE_VAR_FLSH_$(1)_BIN_IDX), $(SBFE_FLSH_BIN_$(bin)_ARG) )

sbfe-flash-$1: $$(SBFE_FLSH_TGT_$(1)_DEP)
	echo "Flashing Binaries : $(foreach bin,$(SBFE_VAR_FLSH_$(1)_BIN_IDX),'$(bin)' )"
	$$(call sbfe-print-list, $$^)
	$$(call sbfe-print-list, $$(SBFE_FLSH_TGT_$(1)_ARG))
	$(SBFE_FLH_DRYRUN) $(ESPTOOLPY_WRITE_FLASH) $$(SBFE_FLSH_TGT_$(1)_ARG)

endef # sbfe-declare-flash-target



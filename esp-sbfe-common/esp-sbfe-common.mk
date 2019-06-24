
SBFE_STYLE_CLEAR:=$(shell printf `tput sgr0`)
SBFE_STYLE_TARGET:=$(shell printf `tput setaf 6;tput bold`)
SBFE_STYLE_DEP:=$(shell printf `tput setaf 2;tput bold`)
SBFE_STYLE_KEY:=$(shell printf `tput setaf 1;tput bold`)

SBFE_STYLE_NOTIFY:=$(SBFE_STYLE_KEY)
define sbfe_notify
	printf "$(SBFE_STYLE_NOTIFY)\n\t$1$(SBFE_STYLE_CLEAR)\n\n"
endef


define sbfe-print-list
	printf "$(foreach v,$1,\t$(v)\n)\n"
endef

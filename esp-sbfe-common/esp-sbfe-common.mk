define sbfe-print-list
	printf "$(foreach v,$1,\t$(v)\n)\n"
endef

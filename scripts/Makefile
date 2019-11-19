prefix=/usr/local

all:
	@echo "usage: make install"
	@echo "       make uninstall"

install:
	@mkdir -p $(prefix)/bin/
	@echo '#!/bin/bash' > $(prefix)/bin/opscripts
	@echo '##$(shell pwd)' >> $(prefix)/bin/opscripts
	@echo 'exec "$(shell pwd)/opscripts" "$$@"' >> $(prefix)/bin/opscripts
	@chmod 755 $(prefix)/bin/opscripts
	@chmod 755 opscripts
	@echo 'install finished! type "opscripts" to show usages.'
uninstall:
	@rm -f $(prefix)/bin/opscripts
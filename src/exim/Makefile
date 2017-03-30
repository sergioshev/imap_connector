TEMPLATE_TARGETS_EXEC=exim-init
TEMPLATE_TARGETS_COMON=exim.conf
TEMPLATE_SECRETS = passwd.client

TEMPLATE_TARGETS = $(TEMPLATE_TARGETS_COMON) $(TEMPLATE_TARGETS_EXEC) \
	$(TEMPLATE_SECRETS)

NORMAL_TARGETS=

include ../Makefile.rules

.PHON: install
install : all
	$(foreach dir, $(EXIM_SPOOL_DIR) \
		$(EXIM_LOG_DIR) $(EXIM_CONF_DIR), install \
		-g $(EXIM_GROUP) -m 755 -d $(dir) &&) true
	install -g $(EXIM_GROUP) $(TEMPLATE_TARGETS_COMON) $(EXIM_CONF_DIR)
	install -m 640 -g $(EXIM_GROUP) $(TEMPLATE_SECRETS) \
		$(EXIM_CONF_DIR)
	install -m 755 -g $(EXIM_GROUP) $(TEMPLATE_TARGETS_EXEC) \
		$(EXIM_CONF_DIR)
	$(foreach dir, $(EXIM_LOG_DIR) $(EXIM_SPOOL_DIR), \
		chown -R $(EXIM_USER) $(dir) && ) true
	ln -f -s $(shell which exim4) $(EXIM_CONF_DIR)

.PHONY: purge
purge: clean
	$(foreach dir, $(EXIM_SPOOL_DIR) \
		$(EXIM_LOG_DIR) $(EXIM_CONF_DIR) \
		$(EXIM_LIBS),rm -r -f $(dir) ; )


TEMPLATE_TARGETS_EXEC=Imap_daemon

TEMPLATE_TARGETS = $(TEMPLATE_TARGETS_EXEC) \
  Imapconnector.conf.pl Imapconnector.pm \
  Imap_daemon.pl

NORMAL_TARGETS = Imapconnector_exchange.pl Imapconnector_test.pl

include ../Makefile.rules

.PHONY: install
install : all
	$(foreach dir,$(PERLMODULE_DIR), install \
		-m 755 -d $(dir) && ) true
	install -m 644 $(TEMPLATE_TARGETS) $(PERLMODULE_DIR)
	install -m 644 $(NORMAL_TARGETS) $(PERLMODULE_DIR)
	install -m 755 $(TEMPLATE_TARGETS_EXEC) /etc/init.d
	update-rc.d $(TEMPLATE_TARGETS_EXEC) defaults

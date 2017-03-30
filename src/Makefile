include Makefile.defs

SUBDIRS = exim perl

all install: % : 
	$(foreach I,$(SUBDIRS),$(MAKE) -C $I $@ && ) true


clean : % :
	$(foreach I,$(SUBDIRS),$(MAKE) -C $I $@ && ) true





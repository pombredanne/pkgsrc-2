DESTDIR=

TOPDIR=..
include $(TOPDIR)/Config.mk

SCRIPTS := 
SUBDIRS :=

man:
#	for bin in ${SCRIPTS} ; do ( pod2man --section=1 $$bin $(DESTDIR)/usr/local/man/man1/$$bin.1 ) ; done

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install: man
#	install -d -m 0755 $(DESTDIR)/usr/bin
#	install    -m 0755 $(SCRIPTS) $(DESTDIR)/usr/bin
#	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	cd $(DESTDIR)/usr/bin; rm -f $(SCRIPTS)
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done

clean:

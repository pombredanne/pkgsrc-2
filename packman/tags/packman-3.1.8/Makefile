include ./Config.mk

DESTDIR=
BINDIR=usr/bin
MANDIR=usr/share/man/man3
SOURCEDIR=/usr/src/redhat/SOURCES
OSCARLIBDIR=$(LIBDIR)/OSCAR
PKGDEST=

all:
	/usr/bin/pod2man --section=3 packman       | gzip > packman.3.gz
	

install: all
	@echo "Installing Perl modules in $(DESTDIR)/$(OSCARLIBDIR)"
	install -d -m 0755 $(DESTDIR)/$(OSCARLIBDIR)
	install -d -m 0755 $(DESTDIR)/$(OSCARLIBDIR)/PackMan/
	install -d -m 0755 $(DESTDIR)/$(BINDIR)
	install -d -m 0755 $(DESTDIR)/$(MANDIR)
	install    -m 0755 packman               $(DESTDIR)/$(BINDIR)
	install    -m 0755 PackMan.pm            $(DESTDIR)/$(OSCARLIBDIR)
	install    -m 0755 PackManDefs.pm        $(DESTDIR)/$(OSCARLIBDIR)
	install    -m 0755 PackMan/DEB.pm        $(DESTDIR)/$(OSCARLIBDIR)/PackMan/
	install    -m 0755 PackMan/RPM.pm        $(DESTDIR)/$(OSCARLIBDIR)/PackMan/
	install    -m 0644 packman.3.gz          $(DESTDIR)/$(MANDIR)

deb ::
	@if [ -n "$$UNSIGNED_OSCAR_PKG" ]; then \
		echo "dpkg-buildpackage -rfakeroot -us -uc"; \
		dpkg-buildpackage -rfakeroot -us -uc; \
	else \
		echo "dpkg-buildpackage -rfakeroot"; \
		dpkg-buildpackage -rfakeroot; \
	fi
	@if [ -n "$(PKGDEST)" ]; then \
        mv ../packman*.deb $(PKGDEST); \
    fi

rpm: dist
	cp packman.tar.gz $(SOURCEDIR)
	rpmbuild -bb ./packman.spec
	@if [ -n "$(PKGDEST)" ]; then \
		mv `rpm --eval '%{_topdir}'`/RPMS/noarch/packman-*.noarch.rpm $(PKGDEST); \
	fi

clean:
	rm -f *~
	rm -f packman.3.gz 
	rm -f build-stamp configure-stamp
	rm -rf debian/files debian/packman
	rm -f ./packman.tar.gz
	rm -rf deb

dist: clean
	rm -rf /tmp/packman
	mkdir /tmp/packman
	cp -rf * /tmp/packman
	cd /tmp/packman; rm -rf `find . -name .svn`
	cd /tmp; tar czf ./packman.tar.gz packman
	mv /tmp/packman.tar.gz .

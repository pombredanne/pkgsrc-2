use ExtUtils::MakeMaker;
use lib '/usr/local/lib/systemimager/perl','/usr/lib/systemimager/perl';

# The global version is stored here so that it can be used by 
# the man page string in rewriting POD2MAN_EXE

my $version = "1.04";
my $release = "1";
my $releasex = "1";

sub MY::postamble {
    my $string = <<EOF;

POD2MAN_EXE = /usr/bin/pod2man "--center=System Installer" "--release=System Installer v$version"
POD2MAN = \$(PERL) -we '\%m=\@ARGV;for (keys \%m){' \\
-e 'next if -e \$\$m{\$\$_} && -M \$\$m{\$\$_} < -M \$\$_ && -M \$\$m{\$\$_} < -M "Makefile";' \\
-e 'print "Manifying \$\$m{\$\$_}\\n";' \\
-e 'system(qq[\$\$^X ].q["-I\$(PERL_ARCHLIB)" "-I\$(PERL_LIB)" \$(POD2MAN_EXE) ].qq[\$\$_>\$\$m{\$\$_}])==0 or warn "Couldn\\047t install \$\$m{\$\$_}\\n";' \\
-e 'chmod(oct(\$(PERM_RW))), \$\$m{\$\$_} or warn "chmod \$(PERM_RW) \$\$m{\$\$_}: \$\$!\\n";}'

POD2MAN5_EXE = \$(POD2MAN_EXE) "--section=5"

deb_prep ::
\tperl -pi.bak -e 's/^VERSION.*/VERSION = $version/' debian/rules

deb :: deb_prep dist
\tmkdir -p /tmp/scdeb
\tmv systeminstaller-$version.tar.gz /tmp/scdeb && cd /tmp/scdeb && tar -xvzf systeminstaller-$version.tar.gz && cd systeminstaller-$version && dpkg-buildpackage && rm -rf /tmp/scdeb/systeminstaller-$version
\techo "Debian Packages have been built in /tmp/scdeb"

rpm_prep ::
\tperl -pi.bak -e 's/\%define version\\b.*/\%define version         $version/' sin.spec
\tperl -pi.bak -e 's/\%define release\\b.*/\%define release         $release/' sin.spec
\tperl -pi.bak -e 's/\%define releasex\\b.*/\%define releasex         $releasex/' sin.spec

rpm :: srpm
\trpm -tb --target noarch \$(NAME)-\$(VERSION).tar.gz

srpm :: rpm_prep dist
\trpm -ts --target noarch \$(NAME)-\$(VERSION).tar.gz

ext_install :: conf
\tmkdir -p \$(PREFIX)/../var/lib/sis
\ttouch  \$(PREFIX)/../var/lib/sis/image
\ttouch  \$(PREFIX)/../var/lib/sis/adapter
\ttouch  \$(PREFIX)/../var/lib/sis/client

\$(PREFIX)/../etc/systeminstaller/systeminstaller.conf : samples/systeminstaller.conf \$(PREFIX)/../etc/systeminstaller
\tinstall samples/systeminstaller.conf \$(PREFIX)/../etc/systeminstaller/

\$(PREFIX)/../etc/systeminstaller/tksis.conf : samples/tksis.conf \$(PREFIX)/../etc/systeminstaller
\tinstall samples/tksis.conf \$(PREFIX)/../etc/systeminstaller/

\$(PREFIX)/../etc/systeminstaller :
\tinstall -d \$(PREFIX)/../etc/systeminstaller

conf: \$(PREFIX)/../etc/systeminstaller/tksis.conf \$(PREFIX)/../etc/systeminstaller/systeminstaller.conf

img_install ::
\tinstall -d \$(PREFIX)/share/systeminstaller/images
\tinstall tksis/images/monitor.xpm \$(PREFIX)/share/systeminstaller/images
\tinstall tksis/images/image.xpm \$(PREFIX)/share/systeminstaller/images

distinfo_install ::

\t for file in `find distinfo | grep -v CVS`; do \\
\t\t if [[ -d \$\$file ]]; then \\
\t\t\t install -d \$(PREFIX)/share/systeminstaller/\$\$file; \\
\t\t else \\
\t\t\t install \$\$file \$(PREFIX)/share/systeminstaller/\$\$file; \\
\t\t fi; \\
\t done


manifest :

\t if [[ -f MANIFEST ]]; then \\
\t\t mv MANIFEST MANIFEST.bak; \\
\t fi
\t cp MANIFEST.stub MANIFEST
\t for file in `find distinfo | grep -v CVS`; do \\
\t\t if [[ -f \$\$file ]]; then \\
\t\t\t echo \$\$file >> MANIFEST; \\
\t\t fi; \\
\t done

manext_install ::
\tcd doc && \\
\tinstall -d \$(INSTALLMAN1DIR)/../man5 && \\
\t\$(POD2MAN5_EXE) systeminstaller.conf.pod \$(INSTALLMAN1DIR)/../man5/systeminstaller.conf.5 && \\
\t\$(POD2MAN5_EXE) SIS.pod \$(INSTALLMAN1DIR)/../man1/SIS.1 && \\
\tcd ..

install :: all pure_install doc_install ext_install manext_install img_install distinfo_install

set_ver::
\tperl -pi.bak -e 's/SIVERSION=.*/SIVERSION="$version";/' ./lib/SystemInstaller/Env.pm
\tperl -pi.bak -e 's/SIVERSION=.*/SIVERSION="$version";/' ./blib/lib/SystemInstaller/Env.pm

all :: set_ver

EOF
}
#all :: set_ver pure_all htmlifypods manifypods

WriteMakefile(
              'VERSION' => $version,
              'NAME' => 'systeminstaller',
              'EXE_FILES' => [qw(
				bin/mksiadapter
				bin/mksidisk
				bin/mksiimage 
				bin/buildimage
				bin/mksimachine
				bin/mksirange
				bin/mkdhcpconf
				bin/mkpkgcache
				bin/simigratedb
				tksis/tksis
				)],
              'INSTALLBIN' => "/usr/bin",
              'INSTALLSITELIB' => "/usr/lib/systeminstaller",
              'PREREQ_PM' => {
			      MLDBM => '2',
                              AppConfig => '1.52',
                             },
             );

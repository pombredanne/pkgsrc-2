#
# $Id: ganglia.spec.in 788 2007-05-18 17:22:00Z bernardli $
#
# ganglia.spec.  Generated from ganglia.spec.in by configure.
#
# IMPORTANT NOTE:
# This spec file has a noarch section.  RPM is braindead in that it cannot
# build mixed architecture packages.  As a workaround, you must build
# the RPMs using the following commandline
#
# % rpmbuild -ta --target noarch,i386 ganglia-3.0.6.tar.gz
#
Summary: Ganglia Distributed Monitoring System
Name: ganglia
Version: 3.0.6
URL: http://ganglia.info/
Release: 1 
License: BSD
Vendor: Ganglia Development Team <ganglia-developers@lists.sourceforge.net>
Group: System Environment/Base
Source: %{name}-%{version}.tar.gz
Buildroot: /tmp/%{name}-%{version}-buildroot
Prefix: /usr
BuildRequires: libpng-devel, libart_lgpl-devel, gcc-c++
%if %{?suse_version:1}0
BuildRequires: rrdtool, freetype2-devel
%else
BuildRequires: rrdtool-devel, freetype-devel
%endif

%description
Ganglia is a scalable, real-time monitoring and execution environment

######################################################################
################## noarch section ####################################
######################################################################
%ifarch noarch
%package web
Summary: Ganglia Web Frontend
Group: System Environment/Base
Obsoletes: ganglia-webfrontend
Provides: ganglia-webfrontend
# We should put rrdtool as a Requires too but rrdtool rpm support is very weak
# so most people install from source
#Requires: ganglia-gmetad >=  3.0.6
Requires: php-gd
%if 0%{?suse_version}
%define web_prefixdir /srv/www/htdocs/ganglia
%else
%define web_prefixdir /var/www/html/ganglia
%endif
Prefix: %{web_prefixdir}

%description web
This package provides a web frontend to display the XML tree published by
ganglia, and to provide historical graphs of collected metrics. This website is
written in the PHP4 language.

#######################################################################
#######################################################################
%else

%package gmetad
Summary: Ganglia Meta daemon http://ganglia.sourceforge.net/
Group: System Environment/Base
Obsoletes: ganglia-monitor-core-gmetad ganglia-monitor-core

%description gmetad
Ganglia is a scalable, real-time monitoring and execution environment
with all execution requests and statistics expressed in an open
well-defined XML format.

This gmetad daemon aggregates monitoring data from several clusters
to form a monitoring grid. It also keeps metric history using rrdtool.

%package gmond
Summary: Ganglia Monitor daemon http://ganglia.sourceforge.net/
Group: System Environment/Base
Obsoletes: ganglia-monitor-core-gmond ganglia-monitor-core

%description gmond
Ganglia is a scalable, real-time monitoring and execution environment
with all execution requests and statistics expressed in an open
well-defined XML format.

This gmond daemon provides the ganglia service within a single cluster or
Multicast domain.

%package devel
Summary: Ganglia Library http://ganglia.sourceforge.net/
Group: System Environment/Base
Obsoletes: ganglia-monitor-core-lib 

%description devel
The Ganglia Monitoring Core library provides a set of functions that programmers
can use to build scalable cluster or grid applications

%endif

##
## PREP
##

%prep 
%setup

##
## BUILD
##
%build
%configure --with-gmetad
%ifnarch noarch
make
%endif

##
## PRE
##
%pre

%ifnarch noarch
##
## POST GMETA
##
%post gmetad
/sbin/chkconfig --add gmetad

##
## POST GMON
##
%post gmond
/sbin/chkconfig --add gmond

`rpm -q ganglia-monitor-core-gmond| grep "is not installed" > /dev/null 2>&1`
if [[ $? != 0 ]]; then
  # They have an old configuration file format
  echo "-----------------------------------------------------------"
  echo "IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT"
  echo "-----------------------------------------------------------"
  echo "It appears that you are upgrading from ganglia gmond version"
  echo "2.5.x.  The configuration file has changed and you need to "
  echo "convert your old 2.5.x configuration file to the new format."
  echo ""   
  echo "To convert your old configuration file to the new format"
  echo "simply run the command:"
  echo ""
  echo "% gmond --convert old.conf > new.conf"
  echo ""
  echo "This conversion was not made automatic to prevent unknowningly"
  echo "altering your configuration without your notice."
fi
   

##
## PREUN GMETA
##
%preun gmetad
if [ "$1" = 0 ]
then
   /etc/init.d/gmetad stop
   /sbin/chkconfig --del gmetad
fi

##
## PREUN GMON
##
%preun gmond
if [ "$1" = 0 ]
then
   /etc/init.d/gmond stop
   /sbin/chkconfig --del gmond
fi

#ifnarch noarch
%endif

##
## INSTALL
##
%install
## Flush any old RPM build root
%__rm -rf $RPM_BUILD_ROOT

%ifarch noarch

%__mkdir -p $RPM_BUILD_ROOT/%{web_prefixdir}
%__cp -rf %{_builddir}/%{name}-%{version}/web/* $RPM_BUILD_ROOT/%{web_prefixdir}
%__rm -rf $RPM_BUILD_ROOT/%{web_prefixdir}/*.in

%else

## Create the directory structure
%__mkdir -p $RPM_BUILD_ROOT/etc/init.d
%__mkdir -p $RPM_BUILD_ROOT/var/lib/ganglia/rrds
%__mkdir -p $RPM_BUILD_ROOT%{_mandir}/man5

## Move the files into the structure
%if 0%{?suse_version}
   %__cp -f %{_builddir}/%{name}-%{version}/gmond/gmond.init.SuSE $RPM_BUILD_ROOT/etc/init.d/gmond
   %__cp -f %{_builddir}/%{name}-%{version}/gmetad/gmetad.init.SuSE $RPM_BUILD_ROOT/etc/init.d/gmetad
%else
   %__cp -f %{_builddir}/%{name}-%{version}/gmond/gmond.init $RPM_BUILD_ROOT/etc/init.d/gmond
   %__cp -f %{_builddir}/%{name}-%{version}/gmetad/gmetad.init $RPM_BUILD_ROOT/etc/init.d/gmetad
%endif

# We just output the default gmond.conf from gmond using the '-t' flag
%{_builddir}/%{name}-%{version}/gmond/gmond -t > $RPM_BUILD_ROOT/etc/gmond.conf
%__cp -f %{_builddir}/%{name}-%{version}/gmetad/gmetad.conf $RPM_BUILD_ROOT/etc/gmetad.conf

%__make DESTDIR=$RPM_BUILD_ROOT install
%__make -C gmond gmond.conf.5
%__install -m 0644 %{_builddir}/%{name}-%{version}/gmond/gmond.conf.5 $RPM_BUILD_ROOT%{_mandir}/man5/gmond.conf.5

%endif

%ifnarch noarch
##
## FILES GMETA
##

%files gmetad
%defattr(-,root,root)
%attr(0755,nobody,nobody)/var/lib/ganglia/rrds
%{_sbindir}/gmetad
/etc/init.d/gmetad
%config(noreplace) /etc/gmetad.conf

##
## FILES GMON
##
%files gmond
%defattr(-,root,root)
%attr(0500,root,root)%{_bindir}/gmetric
%attr(0555,root,root)%{_bindir}/gstat
%{_sbindir}/gmond
/etc/init.d/gmond
%{_mandir}/man5/gmond.conf.5*
%config(noreplace) /etc/gmond.conf

##
## FILES DEVEL
##
%files devel
%{_includedir}/ganglia.h
%{_libdir}/libganglia*
%{_bindir}/ganglia-config

%else

##
## FILES WEB
##
%files web
%defattr(-,root,root)
%dir %{web_prefixdir}/
%config(noreplace) %{web_prefixdir}/conf.php
%{web_prefixdir}/AUTHORS
%{web_prefixdir}/auth.php
%{web_prefixdir}/ChangeLog
%{web_prefixdir}/class.TemplatePower.inc.php
%{web_prefixdir}/cluster_legend.html
%{web_prefixdir}/cluster_view.php
%{web_prefixdir}/COPYING
%{web_prefixdir}/footer.php
%{web_prefixdir}/functions.php
%{web_prefixdir}/ganglia.php
%{web_prefixdir}/get_context.php
%{web_prefixdir}/get_ganglia.php
%{web_prefixdir}/graph.php
%{web_prefixdir}/grid_tree.php
%{web_prefixdir}/header.php
%{web_prefixdir}/host_gmetrics.php
%{web_prefixdir}/host_view.php
%{web_prefixdir}/index.php
%{web_prefixdir}/Makefile.am
%{web_prefixdir}/meta_view.php
%{web_prefixdir}/node_legend.html
%{web_prefixdir}/physical_view.php
%{web_prefixdir}/pie.php
%{web_prefixdir}/private_clusters
%{web_prefixdir}/show_node.php
%{web_prefixdir}/styles.css
%{web_prefixdir}/templates
%{web_prefixdir}/version.php

%endif

##
## CLEAN
##
%clean
%__rm -rf $RPM_BUILD_ROOT

##
## CHANGELOG
##
%changelog
* Fri May 18 2007 Bernard Li <bernard@vanhpc.org>
- Add php-gd to web subpackage Requires
* Wed May 16 2007 Bernard Li <bernard@vanhpc.org>
- %{web_prefixdir}/version.php.in -> %{web_prefixdir}/version.php
- Explicitly delete %{web_prefixdir}/*.in
* Tue Apr 03 2007 Bernard Li <bernard@vanhpc.org>
- Applied patch from Marcus Rueckert
- Use different web_prefixdir for SuSE
- More extensive use of RPM macroes (eg. %{_mandir}, %{_sbindir})
* Mon Jan 08 2007 Bernard Li <bernard@vanhpc.org>
- Do not automatically start/restart services as this may cause 
  ganglia to startup with bad config.
* Mon Aug 28 2006 Bernard Li <bli@bcgsc.ca>
- Added gcc-c++ to BuildRequires
* Sun Jul 23 2006 Bernard Li <bli@bcgsc.ca>
- Changed make install prefix=$RPM_BUILD_ROOT/usr to
  make DESTDIR=$RPM_BUILD_ROOT install (suggested by Jarod Wilson
  <jwilson@redhat.com>)
* Mon Jun 05 2006 Bernard Li <bli@bcgsc.ca>
- Changed /etc/rc.d/init.d -> /etc/init.d
* Mon May 22 2006 Bernard Li <bli@bcgsc.ca>
- Add rrdtool/rrdtool-devel, freetype2-devel/freetype-devel,
  libart_lgpl-devel to BuildRequires
- Use /usr/lib64 for x86_64
* Sun May 21 2006 Bernard Li <bli@bcgsc.ca>
- Correct init scripts dir for SuSE
- Add BuildRequires for libpng-devel
* Fri Feb 25 2006 Bernard Li <bli@bcgsc.ca>
- Use SuSE specific init scripts if /etc/SuSE-release file exists
* Fri Dec 10 2004 Matt Massie <massie@cs.berkeley.edu>
- Updated the spec file for 2.6.0 release
* Tue Apr 13 2004 Brooks Davis <brooks@one-eyed-alien.net>
- Use the autoconf variable varstatedir instead of /var/lib for consistancy.
* Thu Feb 19 2004 Matt Massie <massie@cs.berkeley.edu>
- Removed the /usr/include/ganglia directory from the lib rpm and
  changed the deprecated Copyright to License
* Mon Oct 14 2002 Federico Sacerdoti <fds@sdsc.edu>
- Split package into -gmetad and -gmond subpackages for clarity,
  and separation of purpose/functionality.
* Thu Sep 19 2002 Federico Sacerdoti <fds@sdsc.edu>
- Added config files, made /var/lib/ganglia for RRD storage.
* Mon Mar 11 2002 Matt Massie <massie@cs.berkeley.edu>
- Added support for libganglia, added Prefix: for RPM relocation
* Wed Feb 27 2002 Matt Massie <massie@cs.berkeley.edu>
- Merge gmetric and gmond together into one RPM.  Fix some small bugs.
* Fri Nov  2 2001 Matt Massie <massie@cs.berkeley.edu>
- initial release

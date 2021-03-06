# $Id: yume.spec 171M 2006-05-28 20:48:14Z (lokal) $
Summary: Wrapper to yum for clusters
Name: yume
Version: 1.7
Vendor: NEC HPCE
Release: 1
License: GPL
Packager: Erich Focht <efocht@hpce.nec.com>
Source: %{name}.tar.gz
Group: System Environment/Tools
BuildArch: noarch
BuildRoot: %{_tmppath}/%{name}
Requires: yum
Requires: perl-IO-Tty
# actually "createrepo" is also needed, but only on the master node,
# so don't add it to the requires.
AutoReqProv: no

%description 

Tool for setting up, exporting yum repositories and executing
yum commands for only these repositories. Use it as high level RPM
replacement which resolves dependencies automatically. This tool
is very useful for clusters. It can:
- prepare an rpm repository
- export it through apache
- execute yum commands applying only to this repository (locally)
- execute yum commands on the cluster nodes applying only to this repository.
This makes installing packages, creating cluster node images, updating
revisions much simpler than with rpm.

%prep
%setup -n %{name}


%build


%install

install -d -o root -g root -m 755 $RPM_BUILD_ROOT%{_bindir}
install -d -o root -g root -m 755 $RPM_BUILD_ROOT%{_datadir}/%{name}
install -d -o root -g root -m 755 $RPM_BUILD_ROOT%{_mandir}/man8
install -o root -g root -m 755  yume $RPM_BUILD_ROOT%{_bindir}
install -o root -g root -m 755  yume-opkg $RPM_BUILD_ROOT%{_bindir}
install -o root -g root -m 755  ptty_try $RPM_BUILD_ROOT%{_bindir}
install -o root -g root -m 755  *.rpmlist $RPM_BUILD_ROOT%{_datadir}/%{name}
install -o root -g root -m 755  yume.8 $RPM_BUILD_ROOT%{_mandir}/man8

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%{_bindir}/*
%{_datadir}/%{name}/*
%{_mandir}/man8/yume*

%changelog
* Thu May 25 2006 Erich Focht
- added mirror:http://mirrorlist_url/ option handling
* Mon Mar 06 2006 Erich Focht
- significantly improved functionality of yume-opkg
* Tue Feb 21 2006 Erich Focht
- limit architectures of installed packages (if not specified),
  this should avoid installing all compatible architectures of a package
  on a x86_64. Detects arch from name of repository.
* Mon Feb 20 2006 Erich Focht
- added env variable YUME_VERBOSE
- added debugging output
- added correct return codes when subcommands fail
* Thu Feb 16 2006 Erich Focht
- removed need for "--" to separate yum arguments
- changed exported repository URL path to /repo/$repopath
- added default repository detection for OSCAR clusters.
* Wed Feb 01 2006 Erich Focht
- added ptty_try (otherwise no progress bar in systeminstaller)
- updated version to 0.3-1
* Mon Dec 12 2005 Erich Focht
- chop trailing "/" from repo paths, otherwise getting trouble with basename
- version 0.2-6
* Thu Sep 15 2005 Erich Focht
- added yume-opkg
- added rpmlists for rhel4 i386 and x86_64 to /usr/share/yume
* Thu Sep 08 2005 Erich Focht
- initial RPM

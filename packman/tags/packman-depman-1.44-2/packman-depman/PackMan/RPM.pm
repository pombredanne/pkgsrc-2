package PackMan::RPM;

# Copyright (c) 2003-2004 The Trustees of Indiana University.
#                         All rights reserved.
#

use strict;
use warnings;

use Carp;

our $VERSION;
$VERSION = "r" . q$Rev: 19 $ =~ /(\d+)/;

# Must use this form due to compile-time checks by PackMan.
use base qw(PackMan);

# Preloaded methods go here.
# boilerplate constructor because PackMan's is "abstract"
sub new {
  ref (my $class = shift) and croak ("constructor called on instance");
  my $new  = { ChRoot => shift };
  bless ($new, $class);
  return ($new);
}

# convenient constructor alias
sub RPM { 
  return (new (@_)) 
}

# Called by PackMan->new to determine which installed concrete PackMan handler
# claims to be able to manage packages on the target system. Args are the
# root directory being passed to the PackMan constructor.
sub usable {

  my @DISTROFILES = qw( fedora-release
                        mandrake-release
                        mandrakelinux-release
			mandriva-release
                        redhat-release
                        redhat-release-as
                        aaa_version
                        aaa_base
                        sl-release
                        centos-release
                      );

  ref (shift) and croak ("usable is a class method");
  my $chroot = shift;
  my $rc;

  if (defined $chroot) {
    if (! ($chroot =~ '^/')) {
      croak ("chroot argument must be an absolute path.");
    }
  }

  foreach my $distro (@DISTROFILES) {
    if (defined $chroot) {
      $rc = system ("rpm --query --root=${chroot} ${distro} > /dev/null 2>&1");
    } else {
      $rc = system ("rpm --query ${distro} > /dev/null 2>&1");
    }
    if (($rc / 256) == 0) {
      return (1);
    }
  }

  return (0);
}

# How rpm(8) installs packages (aggregatable)
sub install_command_line {
  1, 'rpm --install -vh #args'
}

# How rpm(8) upgrades installed packages (aggregatable)
sub update_command_line {
  1, 'rpm --upgrade -vh #args'
}

# How rpm(8) removes installed packages (aggregatable)
sub remove_command_line {
  1, 'rpm --erase #args'
}

# How rpm(8) queries installed packages (not aggregatable)
sub query_installed_command_line {
  0, 'rpm --query #args'
}

# How rpm(8) queries installed package versions (not aggregatable)
sub query_version_command_line {
  0, 'rpm --query --queryformat %{VERSION}\n #args'
}

# How rpm(8) changes root
sub chroot_arg_command_line {
  '--root #chroot'
}

1;
__END__
=head1 NAME

PackMan::RPM - Perl extension for Package Manager abstraction for RPMs

=head1 SYNOPSIS

  Constructors

  # in environment where RPM is the default package manager:
  use PackMan;
  $pm = PackMan->new;

  use PackMan::RPM;
  $pm = RPM->new;	or RPM->RPM;

  use PackMan;
  $pm = PackMan->RPM;

  use PackMan;
  $pm = PackMan::RPM->new;	or PackMan::RPM->RPM;

  For more, see PackMan.

=head1 ABSTRACT

  Specific Package Manager module for PackMan use. Relies on PackMan
  methods inheritted from PackMan, supplying just the specific
  command-line invocations for rpm(8).

=head1 DESCRIPTION

  Uses PackMan methods suffixed with _command_line to specify the
  actual command-line strings the built-in PackMan methods should
  use. The first return value from the _command_line methods is the
  boolean indicating whether or not the command is
  aggregatable. Aggregatable describes a command where the underlying
  package manager is capable of outputting the per-argument response
  on a single line, and thus all arguments can be aggregated into a
  single command-line invocation. If an operation is not aggregatable,
  PackMan will iterate over the argument list and invoke the package
  manager separately for each, collecting output and final success or
  failure return value.

  The second return value is the string representing the command as it
  would be invoked on the command-line. ote that no shell processing
  will be done on these, so variable dereferencing and quoting and the
  like won't work. The third return value is a reference to a list of
  return values from the command that indicate success. If the third
  return value is omitted, zero (0) will be assumed.

  At least one of each method: update, install, remove,
  query_installed, query_version, must be defined as either
  themselves, overriding the PackMan built-in, or in its _command_line
  form, relying on the PackMan built-in. If defined as itself, the
  _command_line form is never used by PackMan in any way.

  In the _command_line string, the special tokens #args and #chroot
  may be used to indicate where the arguments to the method call
  should be grafted in, and for chrooted PackMan's, where the
  chroot_args_command_line syntax should be grafted in. The method
  call arguments will replace #args everywhere it appears in the
  _comand_line form (multiple instances are possible). In the case of
  aggregatable invocations, the entire method argument list is
  substituted. For non-aggregatable invocations, the individual
  file/package is substituted on an iteration by iteration basis.

  The syntax specified to replace the #chroot token is put in
  chroot_args_command_line. It is just a fragment of command-line
  syntax and is not meant to be a command-line to invoke by itself, so
  it doesn't take an aggregatable flag. The #chroot token in
  chroot_args_command_line is fundamentally different from the #chroot
  token in the other _command_line forms. The #chroot token within
  chroot_args_command_line is replaced by the actual value passed to
  the chroot method. The #chroot token in the invokable _command_line
  forms is only replaced by the syntax from chroot_args_command_line
  if the PackMan object has had a chroot defined for it, otherwise,
  all #chroot tags in those _command_line forms are deleted before
  each invocation.

  Each token, #args and #chroot, has a default location if it is
  omitted.  #args goes at the end of the invocation argument list, and
  #chroot goes immediately before the first #args token. In
  chroot_args_command_line, #chroot goes on the end, like #args for
  the other _command_line forms. As such, in this example of a
  specific PackMan module, all instances of #args and #chroot tokens
  could be removed and it would operate in exactly the same way. If
  these default token locations are not suitable for some other
  specific package manager, the tokens can be placed anywhere after
  the first whitespace character (after the package manager's name).

  I used the long format arguments in this example. A package manager
  abstraction module author is, of course, free to implement his
  abstraction any way he wishes. So long as it inherits from PackMan
  and is located under the PackMan directory, PackMan will be able to
  find it and use it.

  For suggestions for expansions upon or alterations to the PackMan
  API, don't hesitate to e-mail the author. Use "Subject: PackMan:
  ...". For questions about this module, use "Subject: PackMan::RPM:
  ...". For questions about creating a new PackMan specific module
  (ex. Debian, Slackware, Stampede, et al.), use "Subject:
  PackMan::specific: ..."

=head2 EXPORT

  None by default.

=head1 SEE ALSO

  PackMan
  rpm(8)

=head1 AUTHOR

  Jeff Squyres, E<lt>jsquyres@lam-mpi.orgE<gt>
  Matt Garrett, E<lt>magarret@OSL.IU.eduE<gt>

=head1 COPYRIGHT AND LICENSE

  Copyright (c) 2003-2004 The Trustees of Indiana University.
                          All rights reserved.

=cut

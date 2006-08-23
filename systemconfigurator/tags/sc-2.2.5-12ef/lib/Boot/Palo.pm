package Boot::Palo;

#   $Header: /cvsroot/systemconfig/systemconfig/lib/Boot/Palo.pm,v 1.4 2001/08/21 12:54:18 sdague Exp $

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
 
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
 
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#   dann frazier <dannf@ldl.fc.hp.com>
#   based on code by Donghwa John Kim <johkim@us.ibm.com>

=head1 NAME

Boot::Palo - Palo bootloader configuration module.

=head1 SYNOPSIS

  my $bootloader = new Boot::Palo(%bootvars);

  if($bootloader->footprint()) {
      $bootloader->setup();
  }

  my @fileschanged = $bootloader->files();

=cut

use strict;
use Carp;
use vars qw($VERSION);
use Boot;
use Util::Log qw(:all);
use Util::Cmd qw(:all);

$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

push @Boot::boottypes, qw(Boot::Palo);

sub new {
    my $class = shift;
    my %this = (
                root => "",
                filesmod => [],
		bootloader_exe =>"",
		boot_bootdev => "",
		boot_append => "",
		boot_recovery => "",         ### Recovery kernel
		boot_complete => 0,
                @_,
                config_file => "/etc/palo.conf",
               );

    $this{config_file} = $this{root} . $this{config_file};
    $this{bootloader_exe} = which("palo");

    debug("bootloader_exe has been set to " . $this{bootloader_exe});

    bless \%this, $class;
}

=head1 METHODS

The following methods exist in this module:

=over 4

=item files()

The files() method is merely an accessor method for the all files
touched by the instance during its run.

=cut

sub files {
    my $this = shift;
    return @{$this->{filesmod}};
}

=item footprint()

This method returns 1 if executable Palo bootloader is installed. 

=cut

sub footprint_config {
    my $this = shift;

    return -e $$this{config_file};
}

sub footprint_loader {
    my $this = shift;
    return $$this{bootloader_exe};
}

=item setup_config()

This method read the System Configurator's config file and translates it
into the bootloader's "native" config file. 

=cut

sub install_config {
    my $this = shift;

    if(!$$this{boot_bootdev})
    {
	croak("Error: BOOTDEV must be specified.\n");
    }
    if(!$$this{boot_rootdev}) 
    {
	croak("Error: ROOTDEV must be specified.\n");;
    }
    if(!$$this{boot_defaultboot}) 
    {
	croak("Error: DEFAULTBOOT must be specified.\n");;
    }
    open(OUT,">$$this{config_file}") or croak("Couldn\'t open $$this{config_file} for writing");
    
    print OUT <<PALOCONF;
##################################################
# This file is generated by System Configurator. #
##################################################

# palo.conf -- default arguments for palo
# 
# See /usr/share/doc/palo/README.html and run 'palo --help' for
# more information

# The following arguments are set up for booting from /dev/sda3, specifically
# mounting partition 3 as root, and using /boot/vmlinux as both the
# recovery kernel, and the default dynamically-booted kernel.
# --recoverykernel=/boot/vmlinux
# --bootloader=/boot/iplboot
# --init-partitioned=/dev/sda
# --commandline=3/boot/vmlinux HOME=/ TERM=linux root=/dev/sda3

--bootloader=/boot/iplboot
--init-partitioned=$this->{boot_bootdev}
PALOCONF

    foreach my $key (sort keys %$this) {
	if ($key =~ /^(kernel\d+)_path/) {
	    $this->setup_kernel($1,\*OUT);
	}
    }
    close(OUT);

    push @{$this->{filesmod}}, "$$this{config_file}";
    
    if ($this->{boot_complete} == 0) {
	croak("Didn't find an image labelled as the default.\n");
    }
    
    1;
}

=item setup_kernel()

An "internal" method.
This method sets up a kernel image as specified in the config file.

=cut

sub setup_kernel {
    my ($this, $kernel, $outfh) = @_;
    my $bootpartition = "";
    my $pathbase;
    my @path = split /\//, $this->{$kernel . "_path"};

    ### kernel image labels are not used by palo.  however, labels are 
    ### required in the config file to specify the recovery and default kernels
    if ($$this{$kernel . "_label"} eq $$this{boot_defaultboot}) {

	### determine the partition number on which the kernel resides
	open(FSTAB, "<$this->{root}/etc/fstab")
	    or croak("Couldn't open $this->{root}/etc/fstab for reading");
	while(!$bootpartition) {
	    seek FSTAB,0,0;
	    pop @path;
	    if ( @path == 0 ) { 
		croak("Unable to determine the partition on which " . $this->{$kernel . "_path"} . " resides");
	    }
	    $pathbase = join '/', @path;
	    if (!$pathbase) { $pathbase = "/"; }
	    
	    while(<FSTAB>) {
		next if (/^\s*\#/);
		if (/^.*\/dev\/.+?(\d+?)\s*$pathbase/) { $bootpartition = $1; }
	    }
	}
	close FSTAB;
	unless ($bootpartition) {
	    croak("Device on which kernel resides cannot be derived from $this->{root}/etc/fstab.");
	    close($outfh);
	}

	print $outfh "--commandline=" . $bootpartition . $$this{$kernel . "_path"} . " ";

	### the local append overwrites the global append
	if ($$this{$kernel . "_append"}) {
	    print $outfh $$this{$kernel . "_append"};
	}
	else {
	    print $outfh $this->{boot_append};
	}
	print $outfh "\n";

	$$this{boot_complete} = 1;
    }

    ### recovery kernel must be in F0 partition
    if ($$this{$kernel . "_label"} eq $$this{boot_recovery}) {
	print $outfh "--recoverykernel=" . $$this{$kernel . "_path"};
    }
}

=item run_loader()

Commit is used as an "internal" method. 

This method invokes the Palo executable.

A user can set "NOCOMMIT" option to a true value to prevent this method from
being invoked. Notice that commit() does not check the value of "NOCOMMIT", 
but its value is checked in setup() method which calls this method. 

=cut

sub install_loader {
    my $this = shift;

    my $chroot = ($$this{root}) ? "-r $$this{root}" : "";

    my $output = qx/$this->{bootloader_exe} $chroot 2>&1/;
    my $exitval = $? >> 8;
    
    if ($exitval) {
        croak("Error: Cannot execute $this->{bootloader_exe}.\n$output\n");
    }
    1;
}

=back

=head1 AUTHOR

  dann frazier <dannf@ldl.fc.hp.com>

=head1 SEE ALSO

L<Boot>, L<perl>

=cut

1;

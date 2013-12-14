package SystemConfig::Boot::Aboot;

#   $Header$

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

#   dann frazier <dannf@dannf.org>
#   based on code by Donghwa John Kim <johkim@us.ibm.com>

=head1 NAME

SystemConfig::Boot::Aboot - Aboot bootloader configuration module.

=head1 SYNOPSIS

  my $bootloader = new SystemConfig::Boot::Aboot(%bootvars);

  if($bootloader->footprint()) {
      $bootloader->setup();
  }

  my @fileschanged = $bootloader->files();

=cut

use strict;
use Carp;
use vars qw($VERSION);
use SystemConfig::Boot;
use SystemConfig::Boot::Path;
use SystemConfig::Util::Log qw(:all);
use SystemConfig::Util::Cmd qw(:all);

$VERSION = sprintf("%d", q$Revision: 664 $ =~ /(\d+)/);

push @SystemConfig::Boot::boottypes, qw(SystemConfig::Boot::Aboot);

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
               );

    $this{config_file} = $this{root} . "/etc/aboot.conf";
    $this{bootloader_exe} = $this{root} . "/sbin/swriteboot";

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

This method returns 1 if executable Aboot bootloader is installed. 

=cut

sub footprint_config {
    my $this = shift;

    return -e $this->{config_file};
}

sub footprint_loader {
    my $this = shift;
    
    return -e $this->{bootloader_exe};
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
    
    print OUT <<ABOOTCONF;
##################################################
# This file is generated by System Configurator. #
##################################################

# aboot.conf -- default arguments for aboot
# 
# See aboot.conf(5)for more information

ABOOTCONF
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
    my $bootpartition;
    BEGIN {
	my $cnt = 0;
	sub inc_cnt { ++$cnt; }
    }
    my $label;
    
    ### kernel image labels are not used by aboot.
    ### required in the config file to specify the default kernel
    if ($$this{$kernel . "_label"} eq $$this{boot_defaultboot}) {
	$label = 0;
    }
    else { $label = inc_cnt(); }
    
    my ($kern_dev, $kernel_mnt) =
	SystemConfig::Boot::Path->get_mountinfo($this->{$kernel . "_path"},
				  "$this->{root}/etc/fstab");
    if ($kern_dev =~ /(\d+)$/) {
	$bootpartition = $1;
    }
    unless ($bootpartition) {
	croak("Device on which kernel resides couldn't be derived from $this->{root}/etc/fstab.");
    }

    print $outfh "$label:$bootpartition" .
	SystemConfig::Boot::Path->strip_parent($kernel_mnt, $this->{$kernel . "_path"});


    ### the local append overwrites the global append
    if ($$this{$kernel . "_append"}) {
	print $outfh " " . $$this{$kernel . "_append"};
    }
    else {
	print $outfh $this->{boot_append};
    }

    ### aboot requires the kernel & initrd to be on the same partition.
    if ($$this{$kernel . "_initrd"}) {
	my ($initrd_dev, $initrd_mnt) =
	    SystemConfig::Boot::Path->get_mountinfo($this->{$kernel . "_initrd"},
				      "$this->{root}/etc/fstab");
	### there should never be a case where both of these comparisons
	### fail... but test them both, just in case
	if (($initrd_dev ne $kern_dev) or ($initrd_mnt ne $kernel_mnt)) {
	    croak($this->{$kernel . "_initrd"} . " and " .
		  $this->{$kernel . "_path"} .
		  " do not appear to be on the same partition");
	}
	my $relative_initrd =
	    SystemConfig::Boot::Path->strip_parent($initrd_mnt,
				     $this->{$kernel . "_initrd"});
	print $outfh " initrd=$relative_initrd";
    }
    print $outfh "\n";

    $$this{boot_complete} = 1;
}

=item run_loader()

Commit is used as an "internal" method. 

This method invokes the swriteboot utility.

A user can set "NOCOMMIT" option to a true value to prevent this method from
being invoked. Notice that commit() does not check the value of "NOCOMMIT", 
but its value is checked in setup() method which calls this method. 

=cut

sub install_loader {
    my $this = shift;
    
    ## find the partition number containing the config file
    my ($config_dev, $config_mnt) =
	SystemConfig::Boot::Path->get_mountinfo("$$this{config_file}",
				  "$this->{root}/etc/fstab");
    my $config_part;
    if ($config_dev =~ /(\d+)$/) {
	$config_part = $1;
    }
    else {
	croak("Couldn't determine the partition number that holds $$this{config_file}");
    }

    my $chroot = ($$this{root}) ? "chroot $$this{root}" : "";

    verbose("$chroot /sbin/swriteboot $$this{boot_bootdev} /boot/bootlx 2>&1\n");
    my $output = qx^$chroot /sbin/swriteboot $$this{boot_bootdev} /boot/bootlx 2>&1^;
    my $exitval = $? >> 8;
    if ($exitval) {
        croak("Error: Cannot execute /sbin/swriteboot $$this->{boot_bootdev} bootlx.\n$output\n");
    }
    
    verbose("$chroot /sbin/abootconf $$this{boot_bootdev} $config_part 2>&1\n");
    $output = qx^$chroot /sbin/abootconf $$this{boot_bootdev} $config_part 2>&1^;
    $exitval = $? >> 8;
    if ($exitval) {
        croak("Error: Cannot execute $this->{bootloader_exe}.\n$output\n");
    }

    return 1;
}

=back

=head1 AUTHOR

  dann frazier <dannf@dannf.org>

=head1 SEE ALSO

L<SystemConfig::Boot>, L<perl>

=cut

1;

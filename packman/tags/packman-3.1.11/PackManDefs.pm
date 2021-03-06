package OSCAR::PackManDefs;

# $Id: ODA_Defs.pm 7426 2008-09-20 09:22:54Z valleegr $
#
# Copyright (c) 2008 Geoffroy Vallee <valleegr@ornl.gov>
#                    Oak Ridge National Laboratory.
#                    All rights reserved.

use strict;
use base qw(Exporter);


use constant ERROR      => -1;
use constant SUCCESS    => 0;

my @ISA = qw(Exporter);

our @EXPORT = qw(
                ERROR
                SUCCESS
                );

1;

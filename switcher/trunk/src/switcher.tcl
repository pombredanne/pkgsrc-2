#%Module -*- tcl -*-
#
# Copyright (c) 2002-2004 The Trustees of Indiana University.  
#                         All rights reserved.
#
# This file is part of the Env-switcher software package.  For license
# information, see the LICENSE file in the top-level directory of the
# Env-switcher source distribution.
#
# $Id: switcher.tcl.in,v 1.15 2004/05/14 02:43:21 jsquyres Exp $
#

proc ModulesHelp { } {
  puts stderr "\tThis module sets up the OSCAR switcher subsystem."
  puts stderr "\tIt adds the following path to the modules \"use\" path:"
  puts stderr "\t\t${prefix}/share/env-switcher"
  puts stderr "\tIt also adds the following path to the path:"
  puts stderr "\t\t/opt/env-switcher/bin"
  puts stderr "\tIt also adds the following path to the man path:"
  puts stderr "\t\t${prefix}/share/man"
}

module-whatis	"Sets up the OSCAR switcher subsystem."

proc process_switcher_output {action output} {

  # We may well have gotten multiple lines from the output of
  # switcher.  So split them by \n, and process them individually.

  set lines [split $output "\n"]
  foreach line $lines {

    # If we got a line beginning with "echo", then switcher just
    # wanted this line output.  So just output it.

    if { [string first "echo" $line] == 0 } {
      puts "$line"
    } else {

      # Otherwise, it was a module name.  So either load or unload it.

      if { [string compare "load" $action] == 0 } {
	module load $line
      } elseif { [string compare "unload" $action] == 0 } {
	module unload $line
      } else {
	puts "echo ERROR: Unknown switcher action ($action): '$line' ignored;"
      }
    }
  }
}

# If we're removing the switcher module, unload all the modules that
# switcher loaded.

set have_switcher [file exists /bin/switcher]
set am_removing [module-info mode remove]

if { $have_switcher && $am_removing } {
  process_switcher_output "announce" [exec switcher --announce]
  process_switcher_output "unload" [exec switcher --show-exec]
}

# Append to the $PATH and MANPATH

append-path PATH /opt/env-switcher/bin
append-path MANPATH ${prefix}/share/man

# Tell modules to use the datadir, where the directory tree containing
# the <name> modulefiles will be

module use ${prefix}/share/env-switcher

# Setup a "reload" command that effectively ditches any current
# modules/switcher environment and sets up the current environment to
# be what the current switcher settings are.

set-alias switcher_reload "cd ${prefix}/share/env-switcher > /dev/null ; module unload */* ; module load switcher ; cd - > /dev/null"

# If we're not removing the module, call switcher to announce what
# modules we're loading (per user/system settings, of course)

if { $have_switcher && ! $am_removing } {
  process_switcher_output "announce" [exec switcher --announce]

  # Now invoke the switcher perl script to get a list of the modules
  # that need to be loaded.  If we get a non-empty string back, load
  # them.  Only do this if we're loading the module.

  process_switcher_output "load" [exec switcher --show-exec]
}
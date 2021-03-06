#ifndef __XENVM_H
#define __XENVM_H

#include <iostream>

#include "ProfileXMLNode.h"
#include "VMContainer.h"

/** @author Geoffroy Vallee.
  *
  * This class defines all the caracteristics of a xen VM. 
  * Should be created every time we want to manipulate a xen VM.
  */

#define MAX_LINE_LENGHT 128

using namespace std;

class Glib::ustring;

class vmm_hpc : public VirtualMachine {

public:
	vmm_hpc(ProfileXMLNode* profile);
	vmm_hpc(ProfileXMLNode* profile, Glib::ustring preCommand, Glib::ustring
cmd);
	~vmm_hpc();
	int boot_vm();
	int create_image();	
    int install_vm_from_cdrom ();
	int install_vm_from_net ();
    int migrate (string destination_id);
    int pause ();
    int unpause ();
    int status ();

    /** net_script1 is a script that can be used for networking */
    string net_script1; 

    /** net_script2 is a second script that can be used for networking */
    string net_script2;

    /** unbridge_nic1 is a flag to know if the nic1 has to be bridged or not.
      * 0 means that the nic should be bridged, 1 that the nics should not */
    int unbridge_nic1; 

    /** unbridge_nic2 is a flag to know if the nic2 has to be bridged or not. 
      * 0 means that the nic should be bridged, 1 that the nics should not */
    int unbridge_nic2;

private:
    /* command to create a VM (e.g. "xm create") */
	Glib::ustring vmmhpcCommand;

    /* command to execute before the actual creation for a VM (e.g. "sudo
    modprobe tun") */
	Glib::ustring preVMCommand;

    /* Location of the image the emulation of a netboot */
	Glib::ustring netbootImage;

	ProfileXMLNode* profile;

    /* load vmm-hpc configuration from the file ~/.v2m/vmmhpcrc */
    /* GV: Deprecated? */
	void load_config ();

    /* write vmm-hpc configuration to the file ~/.v2m/xenrc */
    /* GV: Deprecated? */
	void write_config ();  			

    /* set the command to create a VM */
	void setCommand(Glib::ustring command);	

    /* set the command to execute before the creation of a VM, for instance
    in order to launch the tun kernel module */
	void setPreVMCommand(Glib::ustring command);	

    /* get the command to create a VM */
	Glib::ustring getCommand();	

    /* get the command to execute before the creation of a VM */
	Glib::ustring getPreVMCommand();
						   
    /* get the image location for emulation of a netboot */
	Glib::ustring getNetbootImage();	

    /* open the configuration file (~/.v2m/vmmhpcrc) */
    /* GV: Deprecated? */
	void openConfigFile ();			

    /* close the configuration file (~/.v2m/vmmhpcrc) */
    /* GV: Deprecated? */
	void closeConfigFile ();		

    /* read configuration file and load configuration */
	void readConfig ();

    /* get default configuration */
	void setDefaultValues(); 		

    string generate_script_unbridge_nic (int);
    int check_vmmhpc_net_config ();
    int generate_config_file(string,string);
    int __boot_vm (string);
    int mount_image();
    int umount_image();
};

#endif

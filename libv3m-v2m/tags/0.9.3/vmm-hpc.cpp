/*
 *  Copyright (c) 2007 Oak Ridge National Laboratory, 
 *                     Geoffroy Vallee <valleegr@ornl.gov>
 *                     All rights reserved
 *  This file is part of the libv3m software.  For license information,
 *  see the COPYING file in the top level directory of the source
 */

#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include "vmm-hpc.h"
#include "ProfileXMLNode.h"
#include "VMSettings.h"
#include "vm_status.h"

/**
  * @author Geoffroy Vallee.
  */
vmm_hpc::vmm_hpc(ProfileXMLNode* p, 
                 Glib::ustring preCommand, 
                 Glib::ustring cmd) 
{
  profile = p;
  preVMCommand = preCommand;
  vmmhpcCommand = cmd;
  unbridge_nic1 = 0;
  unbridge_nic2 = 0;
}

/**
  * @author Geoffroy Vallee.
  */
vmm_hpc::vmm_hpc(ProfileXMLNode* p) 
{
  profile = p;

  // We load configuration information from /etc/v3m/vm.conf
  std::cout << "Creating a new VMM-HPC VM\n" << std::endl;
  VMSettings settings;
  vmmhpcCommand = settings.getVMMHPCCommand();
  preVMCommand = settings.getVMMHPCPrecommand();
  netbootImage = settings.getNetbootImage();
  unbridge_nic1 = 0;
  unbridge_nic2 = 0;
}

/**
  * @author Geoffroy Vallee.
  *
  * Class destructor
  */
vmm_hpc::~vmm_hpc()
{
}

/**
  * @author Geoffroy Vallee.
  *
  * Creates a VMM-HPC image. Location is the image path (including the image
  * name) and size the image size in MB.
  *
  * @return 0 if success, -1 else.
  *
  * @todo Currently we use /dev/loop7, this is hardcoded. Long term, we want
  *       to get the first available loopback entry in /dev (using losetup -f?).
  */
int vmm_hpc::create_image()
{
    /* We get profile data */
    profile_data_t data = profile->get_profile_data ();

    /* We check if the image location and size exist */
    if ((data.image).compare ("N/A") == 0 || (data.image).compare("") == 0) {
        cerr << "Impossible to create the image, location not found ("
             << data.image << ")" << endl;
        return -1;
    }
    if ((data.image_size).compare ("N/A") == 0 || 
        (data.image_size).compare("") == 0) {
        cerr << "Impossible to create the image, size not found" << endl;
        return -1;
    }

    /* we get the image location */
    string location = data.image;
    string size = data.image_size;

    /* We create the image */
    Glib::ustring cmd = "dd if=/dev/zero of=" + location + " bs=1M count=" 
                        + size;
    cout << "Command to create the VMM-HPC image: " << cmd.c_str() << endl;
    if (system (cmd.c_str())) {
        cout << "ERROR executing " << cmd << endl;
        return -1;
    }

    cmd = "sudo /sbin/losetup /dev/loop7 " + location;
    if (system (cmd.c_str())) {
        cout << "ERROR executing " << cmd << endl;
        return -1;
    }
    /* We generate the fdisk script */
    cmd = "sudo rm -f /tmp/fdisk_script.txt";
    if (system (cmd.c_str())) {
        cout << "ERROR executing " << cmd << endl;
        return -1;
    }
    string filename = "/tmp/fdisk_script.txt";
    ofstream file_op;
    file_op.open(filename.c_str());
    file_op << "n" << endl;
    file_op << "p" << endl;
    file_op << "1" << endl;
    file_op << endl;
    file_op << endl;
    file_op << "w" << endl;    
    file_op.close();
    cmd = "sudo /sbin/fdisk /dev/loop7 < /tmp/fdisk_script.txt";
    cout << "Command to create the VMM-HPC image: " << cmd << endl;
    system (cmd.c_str());
    cmd = "sudo /sbin/kpartx -av /dev/loop7";
    cout << "Command to map the VMM-HPC image in the system: " << cmd << endl;
    if (system (cmd.c_str())) {
        cerr << "ERROR executing " << cmd << endl;
        return -1;
    }
    cmd = "sudo /sbin/mke2fs -F -j -T ext2 /dev/mapper/loop7p1";
    cout << "Command to format the VMM-HPC image: " << cmd << endl;
    if (system (cmd.c_str())) {
        cerr << "ERROR executing " << cmd << endl;
        return -1;
    }
    cmd = "sudo mkdir -p /mnt/v2m; sudo mount /dev/mapper/loop7p1 /mnt/v2m";
    cout << "Command to mount the VMM-HPC image: " << cmd << endl;
    if (system (cmd.c_str())) {
        cerr << "ERROR executing " << cmd << endl;
        return -1;
    }
    cmd = "sudo umount /mnt/v2m";
    cout << "Command to umount the VMM-HPC image: " << cmd << endl;
    if (system (cmd.c_str())) {
        cerr << "ERROR executing " << cmd << endl;
        return -1;
    }
    cout << "The new VMM-HPC image is ready" << endl;

    return 0;
}

/**
  * @author Geoffroy Vallee.
  *
  * Creates a VMM-HPC image. Location is the image path (including the image
  * name) and size the image size in MB 
  *
  * @return 0 if sucess, -1 else.
  */
int vmm_hpc::install_vm_from_cdrom ()
{
    cerr << "Not yet supported by this virtualization solution" << endl;
    return -1;
}

/**
  * @author Geoffroy Vallee.
  *
  * Creates a VMM-HPC image from a network installation, using OSCAR.
  *
  * @return 0 if success, -1 else.
  * @todo This current version does not work with a virtual disk
  */

int vmm_hpc::install_vm_from_net ()
{
    Glib::ustring cmd, mac_addr;
    Glib::ustring netboot_image = getNetbootImage ();

    profile_data_t data = profile->get_profile_data ();

    cout << "Netboot image: " << netboot_image << endl;

    cout << "Network configuration: " << data.nic1_mac << " - " 
         << data.nic2_mac << endl;
    /* We check that the VM has at least one network connection */
    /* we take the first mac as network interface for network boot */
    if ((data.nic1_mac).compare ("N/A") == 0 || 
        (data.nic1_mac).compare ("") == 0) {
            if ((data.nic2_mac).compare ("N/A") == 0 ||
                (data.nic2_mac).compare ("") == 0) {
                    cerr << "ERROR: the VM does not have a NIC, network "
                         << "installation impossible" << endl;
            } else {
                mac_addr = data.nic2_mac;
            }
    } else {
        mac_addr = data.nic1_mac;
    }

    /* we check if the image for netboot emulation exists */
    ifstream myfile (netboot_image.c_str());
    if (!myfile.is_open()) {
        cerr << "ERROR: Impossible to find the image for netboot emulation (" 
             << netboot_image << "). Netboot impossible." << endl;
        return -1;
    }

    /* We generate the configuration file for the netboot emulation */
    string filename = "/tmp/" + data.name + "_netboot.cfg";
    if (generate_config_file (filename,netboot_image)) {
        cerr << "Impossible to generate the configuration file" << endl;
        return -1;
    }
    cout << "Configuration file created: " << filename << endl;

    cout << "Booting the VM for netboot simulation" << endl;
    if (__boot_vm (filename)) {
        cerr << "ERROR: Impossible to boot the VM up" << endl;
        return -1;
    }

    return 0;
}

/** @author Geoffroy Vallee.
  *
  * Boots up a virtual machine, based on a configuration file (low-level
  * function).
  * Note that boot_vm is the interface exposed to users in order to boot
  * a VM for which the image already exists. This function only call the
  * the command for the creation of a VM.
  *
  * Private function.
  */
int vmm_hpc::__boot_vm (string filename)
{
    Glib::ustring cmd;

    profile_data_t data = profile->get_profile_data ();

    cmd = getPreVMCommand ();
    if (cmd.compare ("")) {
        cout << "Executing: " << cmd << endl;
        if (system (cmd.c_str())) {
            cerr << "ERROR executing: " << cmd << endl;
            return -1;
        }
    }
    cmd = getCommand ();
    cmd += " ";
    cmd += filename;
    cout << "Executing: " << cmd << endl;
    if (system (cmd.c_str())) {
        cerr << "ERROR executing: " << cmd << endl;
        return -1;
    }

    if (unbridge_nic1 = 1)
        if (system (net_script1.c_str())) {
            cerr  << "ERROR setting the network up" << endl;
            return -1;
        }
    if (unbridge_nic2 = 1)
        if (system (net_script2.c_str())) {
            cerr  << "ERROR setting the network up" << endl;
            return -1;
        }

    return 0;
}

/**
  * @author Geoffroy Vallee.
  *
  * Migrates a virtual machine.
  *
  * @param destination_id Identifier (string) of the node where the virtual
  * machine has to be migrated.
  * @return 0 is success, -1 else.
  */
int vmm_hpc::migrate (string destination_id)
{
    cout << "Migrating VM to " << destination_id << endl;

    /* first we check that the destination id is not empty */
    if (destination_id.compare("") == 0) {
        cerr << "ERROR destination ID invalid" << endl;
        return -1;
    }

    /* we get the VM's name */
    profile_data_t data = profile->get_profile_data ();

    /* we then migrate the VM */
    string cmd = "xm migrate " + data.name + " " + destination_id;
    if (system (cmd.c_str())) {
        cerr << "ERROR executing " << cmd << endl;
        return -1;
    }

    return 0;
}

/**
  * @author Geoffroy Vallee.
  *
  * Check the network tools (e.g., checks if the 'ip' and 'brctl' commands are
  * available or not.
  *
  * @return 0 if success, -1 else.
  */
int vmm_hpc::check_vmmhpc_net_config ()
{
    // We test first few commands
    std::string cmd;
    fstream fin, fin2;
    fin.open("/sbin/ip",ios::in);
    fin2.open("/bin/ip",ios::in);
    if( !fin.is_open() && !fin2.is_open()) {
        cout << "The 'ip' command seems to not be available, it is not ";
        cout << "possible to have any virtual network";
        return -1;
    } 
    fin.close();
    fin2.close();
    fin.open("/usr/sbin/brctl",ios::in);
    if ( !fin.is_open() ) {
        cout << "The 'brctl command seems to not available, it is not ";
        cout << "possible to have any virtual network";
        return -1;
    }
    return 0;
}

/**
  * @author Geoffroy Vallee.
  * 
  * Pauses a virutal machine.
  *
  * @return 0 is success, -1 else.
  */
int vmm_hpc::pause ()
{
    cout << "Pausing VM" << endl;

    /* we get the VM's name */
    profile_data_t data = profile->get_profile_data ();

    /* we then pause the VM */
    string cmd = "xm pause " + data.name;
    if (system (cmd.c_str())) {
        cerr << "ERROR executing " << cmd << endl;
        return -1;
    }

    return 0;
}

/**
  * @author Geoffroy Vallee.
  *
  * Unpauses a virtual machine.
  *
  * @return 0 is success, -1 else.
  */
int vmm_hpc::unpause ()
{
    cout << "Unpausing a VM" << endl;

    /* we get the VM's name */
    profile_data_t data = profile->get_profile_data ();

    /* we then unpause the VM */
    string cmd = "xm unpause " + data.name;
    if (system (cmd.c_str())) {
        cerr << "ERROR executing " << cmd << endl;
        return -1;
    }

    return 0;
}


/**
  * @author Geoffroy Vallee.
  *
  * Sets the command to execute before the creation of a virtual machine.
  *
  * @param cmd String representing the command that needs to be executed before
  * the creation of the virtual machine.
  */
void vmm_hpc::setPreVMCommand(Glib::ustring cmd)
{
  vmm_hpc::preVMCommand = cmd;
}

/**
  * @author Geoffroy Vallee.
  *
  * Gets the command to execute before the creation of a virtual machine.
  */
Glib::ustring vmm_hpc::getPreVMCommand()
{
  return vmm_hpc::preVMCommand;
}

/**
  * @author Geoffroy Vallee.
  * 
  * Sets the VMM-HPC command
  */
void vmm_hpc::setCommand(Glib::ustring command)
{
  vmm_hpc::vmmhpcCommand = command;
}


/**
  * @author Geoffroy Vallee.
  *
  * Gets the VMM-HPC command.
  */
Glib::ustring vmm_hpc::getCommand()
{
  return vmm_hpc::vmmhpcCommand;
}


/**
  * @author Geoffroy Vallee.
  *
  * Gets the image location used for netboot emulation. Used for system 
  * installation within the virtual machine using OSCAR.
  *
  * @return the location is available, an empty string else.
  */
Glib::ustring vmm_hpc::getNetbootImage ()
{
    return vmm_hpc::netbootImage;
}


/**
 * @author Geoffroy Vallee.
 *
 * Generates the script that will unbridged a nic (bridge created by default by
 * VMM-HPC).
 * 
 * @param nic_id NIC identifier (0 for the first NIC, 1 for the second NIC).
 * @return script path if success.
 */
string vmm_hpc::generate_script_unbridge_nic (int nic_id) 
{
    ostringstream myStream;
    myStream << nic_id; // convert int to string
    string nicId = myStream.str();
    profile_data_t data = profile->get_profile_data ();
    string f = "/tmp/" + data.name + "_unbridge_nic" + nicId;
    ofstream script;
    script.open(f.c_str());
    script << "#!/bin/sh\n";
    script << "#\n\n";
    script << "# Get the domain id\n";
    script << "DOMAIN_ID=`xm list | grep " << data.name 
           << " | awk '{ print $2}'`\n";
    script << "# we assume the bridge is xenbr0\n";
    script << "/usr/sbin/brctl delif xenbr0 vif${DOMAIN_ID}." << nicId << "\n";
    script << "# we do not give an IP to the unbridged interface, do not\n";
    script << "# really know how to deal with that.\n";
    script.close();
    string cmd = "chmod a+x " + f;
    if (system (cmd.c_str())) {
        cerr << "ERROR creating a VMM-HPC network configuration script" << endl;
        exit (-1);
    }
    return f;
}

int vmm_hpc::generate_config_file (string filename,string netboot_Image)
{
    profile_data_t data = profile->get_profile_data ();

    /* We create the VMM-HPC configuration file. */
    ofstream file_op;
    file_op.open(filename.c_str());
    file_op << "name = \"" << data.name <<"\"\n";
    file_op << "kernel = \"/boot/vmlinuz-2.6-vmm_hpc\"\n";
//    file_op << "initrd = \"initrd-2.6.16-vmm_hpc3_86.1_fc4.img\"\n";
    file_op << "memory = " << data.memory << "\n";
    file_op << "disk = ['file:"+netboot_Image+","
            << "sda1,w', 'phy:/dev/mapper/loop7p1,hda1,w']\n";
    /* Network setup: first we deal with nic1 */
    if ((data.nic1_type).compare ("BRIDGED_TAP") == 0)
        file_op << "vif = [ 'mac=" + data.nic1_mac + "' ]\n";
    if ((data.nic1_type).compare ("TUN/TAP") == 0 ||
        (data.nic1_type).compare ("VLAN") == 0) {
            // We declare the NIC
            if (check_vmmhpc_net_config ()) {
                cerr << "Tools are missing in order to setup the network";
                return -1;
            }
            file_op << "vif = [ 'mac=" + data.nic1_mac 
                        + ", bridge=xenbr0' ]\n";
            // We generate the script to modify the bridge automatically created
            // by VMM-HPC. 
            // 0 because it is the first NIC
            net_script1 = generate_script_unbridge_nic (0); 
            unbridge_nic1 = 1;
    }
    if ((data.nic2_type).compare ("BRIDGED_TAP") == 0) {
       if (check_vmmhpc_net_config ()) {
            cerr << "Tools are missing in order to setup the network";
            return -1;
        }
        file_op << "vif = [ 'mac=" + data.nic2_mac + "' ]\n";
    }
    if ((data.nic2_type).compare ("TUN/TAP") == 0 ||
(data.nic2_type).compare ("VLAN") == 0) {
        if (check_vmmhpc_net_config ()) {
            cerr << "Tools are missing in order to setup the network";
            return -1;
        }
        // We declare the NIC
        file_op << "vif = [ 'mac=" + data.nic2_mac + "' ]\n";
        // We generate the script to modify the bridge automatically created
        // by VMM-HPC
        // 1 because it is the second NIC
        net_script2 = generate_script_unbridge_nic (1); 
        unbridge_nic2 = 1;
    }
    file_op << "root=\"/dev/sda1 ro\"\nserial='pty'";
    file_op.close();
    std::cout << "Configuration file created: " << filename << std::endl;

    return 0;
}

/**
  * @author Geoffroy Vallee.
  * 
  * Function called to create a new vmm_hpc virtual machine.
  * Metwork configuration:
  * - if BRIDGED_TAP, nothing to do, default VMM-HPC behavior,
  * - if TUN/TAP, the NIC has to be removed from the bridge created by VMM-HPC
  * - if VLAN, same thing.
  *
  * Note that we currently assume the VMM-HPC kernel is
  * /boot/vmlinuz-2.6-vmm_hpc
  *
  * @return 0 if success, -1 else.
  */
int vmm_hpc::boot_vm () 
{
    Glib::ustring cmd;

    cout << "Create_vm for VMM-HPC" << endl;

    if (profile == NULL) {
        cerr << "Profile not found" << endl;
        return -1;
    }

    profile_data_t data = profile->get_profile_data ();
    Glib::ustring netboot_image = getNetbootImage ();

    string filename = "/tmp/" + data.name + "_vmm_hpc.cfg";
    if (vmm_hpc::generate_config_file(filename,netboot_image)) {
        cerr << "ERROR: Impossible to generate the config file" << endl;
        return -1;
    }

    vmm_hpc::mount_image();

    cout << "Booting the VM for netboot simulation" << endl;
    if (__boot_vm(filename)) {
        cerr << "ERROR: Impossible to boot the VM up" << endl;
        return -1;
    }

    return 0;
}

/**
 * @author Geoffroy Vallee and Kulat Charoenpornwattana.
 *
 * Returns Virtual Machines status.
 * 
 * @return -1 if virtual machine not found,
 *          0 if running,
 *          1 if paused,
 *          2 if crashed,
 *          3 if shutdown,
 *          4 if unknown,
 */
int vmm_hpc::status()
{ 
    int pos,status = -1;
    string line;
    string cmd = 
        "xm list | grep -v \" Time(s)\\|Domain-0\" > vmm_hpc_status.tmp";

    profile_data_t data = profile->get_profile_data ();
    string vmname = data.name;

    if (system (cmd.c_str())) {
        cerr << "ERROR executing " << cmd << endl;
        exit(-1);
    }

    ifstream vmm_hpc_status_file("vmm_hpc_status.tmp");

    if(!vmm_hpc_status_file.is_open()){
        cout << "Unable to open file";
    }else{
        while (!vmm_hpc_status_file.eof()){
            getline (vmm_hpc_status_file,line);
            pos = line.find(" ",0);
            if (pos > 0){
                if (vmname.compare(line.substr(0,pos)) == 0){
                    line = line.erase(0,pos);
                    if((line.find("r-----",0) != string::npos) ||
                       (line.find("-b----",0) != string::npos))
                        status = RUNNING;
                    else if(line.find("--p---",0) != string::npos)
                        status = PAUSE;
                    else if(line.find("---s--",0) != string::npos)
                        status = SHUTDOWN;
                    else if((line.find("----c-",0) != string::npos) ||
                            (line.find("-----d",0) != string::npos))
                        status = CRASH;
                    else
                        status = UNKNOWN;
                }
            }
        }
    }
    vmm_hpc_status_file.close();

    cmd = "rm -f vmm_hpc_status.tmp ";
    if (system (cmd.c_str())) {
        cerr << "ERROR executing " << cmd << endl;
        exit(-1);
    }

    return status;
}

/**
 * @author Geoffroy Vallee, 04 August 2007.
 *
 * Mount the image for a para-virtualized image. Not that with 
 * para-virtualization most of the time users use a virtual partition, not a
 * virtual disk. We want to use a virtual disk in order to be able to switch
 * between virtualization solution. So we mount the virtual disk (losetup, 
 * kpartx), we then mount the virtual partition inside the virtual disk (mount)
 * and finally we expose the virtual partition to the virutal machine.
 *
 * @return 0 if success, -1 else
 *
 * @todo * Find a way to dynamically find the first available loopback device,
 *        currently /dev/loop7 is hardcoded (cf losetup -f).
 *       * Find a way to describe the partition table in the virtual disk. 
 *        Currently we assume we use only /dev/hda1
 */
int vmm_hpc::mount_image()
{
    Glib::ustring cmd;
    profile_data_t data = profile->get_profile_data ();
    string location = data.image;

    cmd = "sudo /sbin/losetup /dev/loop7 " + location;
    if (system (cmd.c_str())) {
        cout << "ERROR executing " << cmd << endl;
        return -1;
    }
    cmd = "sudo /sbin/kpartx -av /dev/loop7";
    cout << "Command to map the VMM-HPC image in the system: " << cmd << endl;
    if (system (cmd.c_str())) {
        cerr << "ERROR executing " << cmd << endl;
        return -1;
    }
//    cmd = "sudo mkdir -p /mnt/v2m; sudo mount /dev/mapper/loop7p1 /mnt/v2m";
//    cout << "Command to mount the VMM-HPC image: " << cmd << endl;
//    if (system (cmd.c_str())) {
//        cerr << "ERROR executing " << cmd << endl;
//        return -1;
//    }
    cout << "Image mounted (/mnt/v2m)" << endl;
}

/**
 * @author Geoffroy Vallee, 04 August 2007.
 *
 * Mount the image for a para-virtualized image. Not that with
 * para-virtualization most of the time users use a virtual partition, not a
 * virtual disk. We want to use a virtual disk in order to be able to switch
 * between virtualization solution. So we mount the virtual disk (losetup,
 * kpartx), we then mount the virtual partition inside the virtual disk (mount)
 * and finally we expose the virtual partition to the virtual machine.
 *
 * @return 0 if success, -1 else
 *
 * @todo Cf todo list of mount_image()
 */
int vmm_hpc::umount_image () 
{
    Glib::ustring cmd;
    profile_data_t data = profile->get_profile_data ();
    string location = data.image;

//    cmd = "sudo umount /mnt/v2m";
//    cout << "Command to umount the VMM-HPC image: " << cmd << endl;
//    if (system (cmd.c_str())) {
//        cerr << "ERROR executing " << cmd << endl;
//        return -1;
//    }
    cmd = "sudo /sbin/kpartx -d /dev/loop7";
    cout << "Command to unmap the VMM-HPC image in the system: " << cmd << endl;
    if (system (cmd.c_str())) {
        cerr << "ERROR executing " << cmd << endl;
        return -1;
    }
    cmd = "sudo /sbin/losetup -d /dev/loop7 " + location;
    if (system (cmd.c_str())) {
        cout << "ERROR executing " << cmd << endl;
        return -1;
    }

    cout << "Image umounted" << endl;
}

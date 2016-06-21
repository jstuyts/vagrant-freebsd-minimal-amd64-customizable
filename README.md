## Current State

In working order, but documentation is lacking. 

## About

TBD

## Requirements

TBD

## Usage

TBD

### Shell

    config.ssh.shell = "sh"

### NFS

Uses NFS because the Guest Additions provided by FreeBSD do not support VirtualBox shared folders.

Install: https://github.com/winnfsd/vagrant-winnfsd

Replace with `winnfsd.exe` in `<home directory>\.vagrant.d\gems\gems\vagrant-winnfsd-1.1.0\bin` with the version in this
directory. This version is a debug build built using Visual Studio 2015 of commit 
[631920e - Fix appveyor mount option](https://github.com/marcharding/winnfsd/commit/631920ea944beb2b4938d66f7a6c8341cd51e87a)
 
Static IPv4 address because DHCP is not working. This must be in the range of the private network: Usually 172.28.128.5 and up.

Example configuration:

    config.vm.synced_folder ".", "/vagrant", type: "nfs"
    config.vm.network "private_network", ip: "172.28.128.254"

Issues with vagrant-winnfsd:

* [Can't see the file list in guest](https://github.com/winnfsd/vagrant-winnfsd/issues/78) (Solved if you use the version of `winnfsd.exe` in this project.) 
* [No guest IP was given to the Vagrant core NFS helper](https://github.com/winnfsd/vagrant-winnfsd/issues/88) (Solved if you use a static IP address.)

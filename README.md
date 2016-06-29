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

Static IPv4 address because DHCP is not working. This must be in the range of the private network: Usually 172.28.128.5 and up.

Example configuration:

    config.vm.synced_folder ".", "/vagrant", type: "nfs"
    config.vm.network "private_network", ip: "172.28.128.254"

Issues with vagrant-winnfsd:

* [No guest IP was given to the Vagrant core NFS helper](https://github.com/winnfsd/vagrant-winnfsd/issues/88) (Solved if you use a static IP address.)

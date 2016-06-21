param
  (
  [parameter( Mandatory = $true )][hashtable]$Data
  )

$PrimaryDisk = $Data.Disks[0]

$ActualRootFileSystemCode = coalesce $Data.RootFileSystemCode, 'zfs'
if ( $ActualRootFileSystemCode -eq 'zfs' ) {
  $ActualZfsSwapSizeInGibibytes = coalesce $Data.ZfsSwapSizeInGibibytes, '2'
"export ZFSBOOT_DISKS=""ada0""
export ZFSBOOT_SWAP_SIZE=""$( $Data.ZfsSwapSizeInGibibytes )G"""
} else {
  $PartitionsSpecification = ''
  $IsFirstPartition = $true
  $PrimaryDisk.Partitions | ForEach-Object {
    $Partition = $_

    if ( $IsFirstPartition ) {
      $IsFirstPartition = $false
    } else {
      $PartitionsSpecification += ', '
    }

    if ( $Partition.SizeInKibibytes -ne $null ) {
      $ActualPartitionSize = "$( $Partition.SizeInKibibytes )k"
    } else {
      $ActualPartitionSize = "$( $Partition.SizeInMebibytes )M"
    }
    $ActualType = coalesce $Partition.Type, 'freebsd-ufs'
    $PartitionsSpecification += "$ActualPartitionSize $( $ActualType )"
    if ( $ActualType -eq 'freebsd-ufs' ) {
      $PartitionsSpecification += " $( $Partition.MountPoint )"
    }
  }
"PARTITIONS=""ada0 { $PartitionsSpecification }"""
}

$ActualTimeZoneCode = coalesce $Data.TimeZoneCode, 'UTC'
$ActualNamesOfAdditionalPackagesToInstall = coalesce $Data.NamesOfAdditionalPackagesToInstall, ''
"export nonInteractive=""YES""
DISTRIBUTIONS=""kernel.txz base.txz""
#!

echo 'hostname=""freebsd""' >> /etc/rc.conf
echo 'ifconfig_em0=""DHCP""' >> /etc/rc.conf
echo 'sshd_enable=""YES""' >> /etc/rc.conf
# NFS is started because VirtualBox shared folders are not working with the
# VirtualBox Guest Additions provided by FreeBSD. Use vagrant-winnfsd to run
# an NFS server on Windows. See 'README.md' for known issues with this plug-in
# and their solution : https://github.com/winnfsd/vagrant-winnfsd/
echo 'nfs_client_enable=""YES""' >> /etc/rc.conf

ln -s /usr/share/zoneinfo/$ActualTimeZoneCode /etc/localtime

dhclient em0

ASSUME_ALWAYS_YES=YES pkg bootstrap
ASSUME_ALWAYS_YES=YES pkg update
ASSUME_ALWAYS_YES=YES pkg upgrade
# Install the VirtualBox Guest Additions because VirtualBox does not supply them.
# See:
# * http://www.virtualbox.org/manual/ch04.html#idm1803
# * https://www.freebsd.org/doc/handbook/virtualization-guest-virtualbox-guest-additions.html
ASSUME_ALWAYS_YES=YES pkg install sudo virtualbox-ose-additions $ActualNamesOfAdditionalPackagesToInstall

echo 'vagrant' | pw useradd vagrant -h 0 -m
echo 'vagrant' | pw usermod root -h 0
cat <<EOF > /usr/local/etc/sudoers.d/vagrant
Defaults:vagrant !requiretty
vagrant ALL=(ALL) NOPASSWD: ALL
EOF
chmod 440 /usr/local/etc/sudoers.d/vagrant
mkdir -p /home/vagrant/.ssh
# A copy of: https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub
# Now there is no need to install package 'ca_root_nss'.
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key' >/home/vagrant/.ssh/authorized_keys
chmod 0700 /home/vagrant/.ssh
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

poweroff
"

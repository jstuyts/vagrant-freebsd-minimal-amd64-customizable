@{
    Name = 'example-freebsd-tiny-amd64';
    # Optional. Default: 256
    MemorySizeInMebibytes = 256;

    # Optional. Default: zfs. Valid values: zfs, ufs
    #
    # Note: ZFS will need more memory than the default of 256 MiB. With 1 GiB
    # the system starts without ZFS warnings.
    #
    # Note: In FreeBSD 10.3 root on ZFS is still experimental.
    RootFileSystemCode = 'zfs'

    # Optional, only applicable if "RootFileSystemCode" is "zfs". Default: 2
    ZfsSwapSizeInGibibytes = 2

    Disks = @(
        @{
            # Optional. Default: 16384
            # SizeInMebibytes = 16384;

            # Optional, only applicable if "RootFileSystemCode" is "ufs".
            Partitions = @(
                @{
                    # The size of the partition can be specified in kibibytes
                    # ("SizeInKibibytes") or mebibytes ("SizeInMebibytes").
                    #
                    # The boot partition cannot be too large. 512 kiB works
                    # fine.
                    SizeInKibibytes = 512;
                    # Optional. Default: 'freebsd-ufs'
                    Type = 'freebsd-boot';
                },
                @{
                    SizeInMebibytes = 2048;
                    Type = 'freebsd-swap';
                },
                @{
                    # Specifying a size that would put the end of the last
                    # partition past the end of the disk, will make the
                    # partition end at the end of the disk.
                    SizeInMebibytes = 16384;
                    Type = 'freebsd-ufs';
                    # Required when "Type" is "freebsd-ufs".
                    MountPoint = '/';
                }
            );
        },
        @{
            # Optional. Default: 16384
            SizeInMebibytes = 16384;
        }
    );

    IsoUrl = 'ftp://ftp.freebsd.org/pub/FreeBSD/releases/amd64/amd64/ISO-IMAGES/11.0/FreeBSD-11.0-RELEASE-amd64-disc1.iso.xz';
    IsoSha512 = 'c572439d8431bd3def669bf4e304fa06ca9ee6dda4bfa31755220dc879e15e0508f7b8e56fa4c0a664c848864c3b52d7e0e285b2a6529a386915b03b371f86b2';

    # Optional. Default: UTC
    TimeZoneCode = 'Europe/Brussels';

    # Optional. Default: <empty string>
    NamesOfAdditionalPackagesToInstall = 'less nano';

    # Optional. Default: '.\installerconfig-template.ps1'
    InstallerconfigTemplateScript = '.\installerconfig-template.ps1';
}

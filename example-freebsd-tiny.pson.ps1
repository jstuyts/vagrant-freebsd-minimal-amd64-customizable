@{
    Name = 'example-freebsd-tiny-amd64';
    # Optional. Default: 256
    MemorySizeInMebibytes = 256;

    # Optional. Default: zfs. Valid values: zfs, ufs
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

    IsoUrl = 'ftp://ftp.freebsd.org/pub/FreeBSD/releases/amd64/amd64/ISO-IMAGES/10.3/FreeBSD-10.3-RELEASE-amd64-disc1.iso';
    IsoSha512 = '8137966d9b62eb4bf597b047a8a43ae9f9a06f23ab7c812f229d32cbfab5bb0cc27089dcfb5d233e50a18620b75606e31ff01bb3084517746664b3b3c46c9d04';

    # Optional. Default: UTC
    TimeZoneCode = 'Europe/Brussels';

    # Optional. Default: <empty string>
    NamesOfAdditionalPackagesToInstall = 'less nano';

    # Optional. Default: '.\installerconfig-template.ps1'
    InstallerconfigTemplateScript = '.\installerconfig-template.ps1';
}

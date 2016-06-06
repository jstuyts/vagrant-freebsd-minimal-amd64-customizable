@{
    Name = 'example-freebsd-tiny-amd64';
    # Optional. Default: 360
    MemorySizeInMebibytes = 2048;

    # Optional. Default: $false
    #
    # It is best to use the "vagrant-vbguest" plug-in as this will install a
    # version of the guest additions that matches the version of VirtualBox:
    #     https://github.com/dotless-de/vagrant-vbguest
    #
    # If you do install the guest additions from the FreeBSD repositories,
    # then it is best to prevent the "vagrant-vbguest" plug-in from trying to
    # upgrade the guest additions. Add the following to your "Vagrantfile":
    #     config.vbguest.no_install = true
    InstallGuestAdditions = $false;

    Disks = @(
        @{
            # Optional. Default: 16384
            SizeInMebibytes = 16384;
            # Optional. Default: <none>
            BiosBootPartitionName = 'grub';
            Partitions = @(
                @{
                    SizeInMebibytes = 4096;
                    Type = 'filesystem';
                    # Optional. Default: 'ext4'
                    FilesystemCode = 'ext4';
                    # Optional. Default: <none>
                    MountPoint = '/';
                    # Optional. Default: $false
                    IsBootable = $true;
                    # Optional. Default: <none>
                    PartitionName = 'host';
                    # Optional. Default: <none>
                    Label = 'host';
                },
                @{
                    SizeInMebibytes = 2048;
                    Type = 'swap';
                    # Optional. Default: <none>
                    PartitionName = 'swap';
                },
                @{
                    SizeInMebibytes = 10237;
                    Type = 'empty';
                    # Optional. Default: <none>
                    PartitionName = 'firstpool';
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

    # Optional. Default: US
    CountryCode = 'US';
    # Optional. Default: en
    LanguageCode = 'en';
    # Optional. Default: UTF-8
    CharacterEncodingCode = 'UTF-8';

    # Optional. Default: us
    KeymapCode = 'us';

    # Optional. Default: GMT+0
    TimeZoneCode = 'GMT+0';

    # Optional. Default: true
    MustClockBeSynchronizedUsingNtp = 'true';

    # Optional. Default: true
    MustNonFreePackagesBeAvailable = 'true';

    # Optional. Default: <empty string>
    NamesOfAdditionalPackagesToInstall = 'less vim';

    # Optional. Default: false
    MustJoinPopularityContest = 'false';

    # Optional. Default: 'late_command.sh'
    PostInstallationScript = 'late_command.sh';
}

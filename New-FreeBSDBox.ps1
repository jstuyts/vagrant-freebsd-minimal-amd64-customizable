<#
.SYNOPSIS
    Creates a Vagrant box for FreeBSD.

.DESCRIPTION
    The New-FreeBSDBox function creates a Vagrant box with a minimal
    installation of FreeBSD. The box is customizable using the definition
    file, which is written in PowerShell object notation (PSON).

    The following things can be customized in the definition file:
    * The name of the box.
    * The amount of memory in the box.
    * The number of disks.
    * The partioning of the first disk.

    SECURITY NOTE: The contents of the definition file are not parsed, but are fed 
    directly to PowerShell. ONLY USE DEFINITION FILES YOU FULL TRUST.

.PARAMETER DefinitionFile
    The path to the definition file. The contents must be PowerShell object
    notation (PSON).

    SECURITY NOTE: The contents of this file are not parsed, but are fed directly to
    PowerShell. ONLY USE DEFINITION FILES YOU FULL TRUST.

.PARAMETER Headless
    If given the VirtualBox GUI of the virtual machine will not be shown.

.EXAMPLE
    C:\PS> New-FreeBSDBox.ps1 mem_2GiB-disk_40GiB(system_8GiB-swap_1GiB).pson.ps1
    Assuming the definition file describes a box with the following characteristics:
    * 2 GiB of memory
    * 1 disk of 40 GiB
    * A system partition of 8 GiB
    * A swap partition of 1 GiB

    New-FreeBSDBox will create a VirtualBox virtual machine, install
    FreeBSD on it and package the virtual machine as a Vagrant box.
#>
param
  (
  [parameter( Mandatory = $true )][string]$DefinitionFile,
  [parameter( Mandatory = $false )][switch]$Headless
  )

function Assert-CommandExists
  {
  param
    (
    [parameter( Mandatory = $true )][string[]]$ApplicationName,
    [parameter( Mandatory = $true )][string[]]$Command,
    [parameter( Mandatory = $false )][string[]]$Parameters,
    [parameter( Mandatory = $true )][string[]]$HomePageUrl
    )

  try
    {
    & $Command $Parameters | Out-Null
    }
  catch
    {
    # No action needed. Ignore errors and rely on the return value for command detection.
    }
  finally
    {
    $DoesCommandExist = $?
    }
  if ( -not $DoesCommandExist )
    {
    throw "`"$Command`" (which is part of $ApplicationName) must be installed and added to `"`$env:Path`". Download from: $HomePageUrl"
    }
  }

function Get-PortCountParameterName
  {
  $VirtualBoxVersion = & VBoxManage --version
  if ( $VirtualBoxVersion -lt '4.3' )
    {
    $result = '--sataportcount'
    }
  else
    {
    $result = '--portcount'
    }

  $result;
  }

function Test-RunningVirtualMachine
  {
  param
    (
    [parameter( Mandatory = $true )][string[]]$Name
    )

  ( & VBoxManage list runningvms | Select-String $Name -SimpleMatch ) -ne $null
  }

function Stop-VirtualMachineIfRunning
  {
  param
    (
    [parameter( Mandatory = $true )][string[]]$Name
    )

  if ( Test-RunningVirtualMachine $Name )
    {
    & VBoxManage controlvm $Name poweroff
    }
  }

function Test-VirtualMachine
  {
  param
    (
    [parameter( Mandatory = $true )][string[]]$Name
    )

  & VBoxManage showvminfo $Name | Out-Null
  $?
  }

function Unregister-VirtualMachineIfExists
  {
  param
    (
    [parameter( Mandatory = $true )][string[]]$Name
    )

  if ( Test-VirtualMachine $Name )
    {
    & VBoxManage unregistervm $Name --delete
    }
  }

function Remove-ItemIfExists
  {
  param
    (
    [parameter( Mandatory = $true )][string[]]$Path
    )

  if ( Test-Path $Path )
    {
    Remove-Item $Path -Recurse -Force
    }
  }

function Assert-FileHasSha512Hash
  {
  param
    (
    [parameter( Mandatory = $true )][string[]]$Path,
    [parameter( Mandatory = $true )][string[]]$ExpectedSha512
    )

  $ActualSha512 = ( Get-FileHash $Path -Algorithm SHA512 ).Hash
  if ( ( $ExpectedSha512.ToLower() ) -ne ( $ActualSha512.ToLower() ) )
    {
    throw "`"$Path`" was expected to have SHA-512: $ExpectedSha512, but actually has SHA-512: $ActualSha512"
    }
  }

function Wait-InstallationFinished
  {
  param
    (
    [parameter( Mandatory = $true )][string[]]$Name
    )

  while ( Test-RunningVirtualMachine $Name )
    {
    Start-Sleep -Seconds 2
    }
  }

function Copy-ToUnixItem
  {
  param
    (
    [parameter( Mandatory = $true )][string[]]$SourcePath,
    [parameter( Mandatory = $true )][string[]]$DestinationPath
    )

  $Contents = Get-Content $SourcePath -Raw
  $ContentsWithUnixLineEndings = $Contents -replace '\r?\n', "`n"
  $ContentsWithUnixLineEndingsAsUtf8Bytes = [System.Text.Encoding]::UTF8.GetBytes( $ContentsWithUnixLineEndings )
  Set-Content $DestinationPath $ContentsWithUnixLineEndingsAsUtf8Bytes -Encoding Byte
  }

function coalesce
  {
  param
    (
    [parameter( Mandatory = $false )][object[]]$Values
    )

  $result = $null

  $ValueIndex = 0
  while ( $result -eq $null -and $ValueIndex -lt $Values.Length )
    {
    $result = $Values[ $ValueIndex ]
    $ValueIndex += 1
    }

  $result
  }

# Parameter validation

if ( -not ( Test-Path $DefinitionFile ) )
  {
  throw "`"$DefinitionFile`" does not exist."
  }

# Environment validation

Assert-CommandExists -ApplicationName Vagrant -Command vagrant -Parameters --version -HomePageUrl https://www.vagrantup.com/
Assert-CommandExists -ApplicationName VirtualBox -Command VBoxManage -Parameters '-v' -HomePageUrl https://www.virtualbox.org/
Assert-CommandExists -ApplicationName 7-Zip -Command 7z -Parameters t, 7z-presence-test.zip -HomePageUrl http://7-zip.org/
Assert-CommandExists -ApplicationName 'Open Source for Win32 by TumaGonx Zakkum' -Command mkisofs -Parameters -version -HomePageUrl http://opensourcepack.blogspot.nl/p/cdrtools.html
Assert-CommandExists -ApplicationName 'Open Source for Win32 by TumaGonx Zakkum' -Command isoinfo -Parameters -version -HomePageUrl http://opensourcepack.blogspot.nl/p/cdrtools.html

# Load the definition

$Definition = & $DefinitionFile

# Environment-specific values

$IsoFolderPath = Join-Path ( Get-Location ) iso
$CustomIsoPath = Join-Path $IsoFolderPath custom.iso

$BuildFolderPath = Join-Path ( Get-Location ) build
$BuildVboxFolderPath = Join-Path $BuildFolderPath vbox
$BuildIsoFolderPath = Join-Path $BuildFolderPath iso
$BuildIsoCustomFolderPath = Join-Path $BuildIsoFolderPath custom
$BuildIsoDuplicateFolderPath = Join-Path $BuildIsoFolderPath duplicate

$StartvmParameters = 'startvm', $Definition.Name
if ( $Headless )
  {
  $StartvmParameters += '--type', 'headless'
  }

# The main script

Stop-VirtualMachineIfRunning $Definition.Name
Unregister-VirtualMachineIfExists $Definition.Name

Remove-ItemIfExists $BuildFolderPath
Remove-ItemIfExists $CustomIsoPath
Remove-ItemIfExists ( Join-Path ( Get-Location ) "$( $Definition.Name ).box" )

if ( -not ( Test-path $IsoFolderPath ) )
  {
  New-Item -Type Directory $IsoFolderPath | Out-Null
  }
New-Item -Type Directory $BuildVboxFolderPath | Out-Null
New-Item -Type Directory $BuildIsoCustomFolderPath | Out-Null

$IsoUrlAsUri = [Uri]$Definition.IsoUrl
$IsoUrlPathSegments = $IsoUrlAsUri.Segments
$LocalInstallationIsoPath = Join-Path $IsoFolderPath ( $IsoUrlPathSegments[ $IsoUrlPathSegments.Length - 1 ] )
if ( -not ( Test-Path $LocalInstallationIsoPath ) )
  {
  Invoke-WebRequest $IsoUrlAsUri -OutFile $LocalInstallationIsoPath
  }
Assert-FileHasSha512Hash $LocalInstallationIsoPath $Definition.IsoSha512

if ( -not ( Test-Path $CustomIsoPath ) )
  {
  # -aou: Automatically rename all filename collisions because the ISO
  # contains filenames that only differ by case.
  & 7z x -aou $LocalInstallationIsoPath "-o$BuildIsoCustomFolderPath" | Out-Null

  $CustomRockRidgeMovedFolderPath = Join-Path $BuildIsoCustomFolderPath '.rr_moved'
  Remove-Item -Force -Recurse $CustomRockRidgeMovedFolderPath

  $CustomIsoBootFilesFolderPath = Join-Path $BuildIsoCustomFolderPath '`[BOOT`]'
  Remove-Item -Force -Recurse $CustomIsoBootFilesFolderPath
  
  $DuplicateFiles = Get-ChildItem $BuildIsoCustomFolderPath -Recurse -Filter *_1* | Where-Object {
    # The filter also finds files with a non-alphanumeric character followed
    # by "1", and filenames containing "_1" that are not duplicates, so this
    # filter ensures only the actual duplicates will be present.
    $_.Name.EndsWith( '_1' + $_.Extension )
  } | ForEach-Object {
    if ( $_.Directory -ne $null ) {
      if ( ( Get-Item ( Join-Path $_.Directory ( $_.Name.Replace( '_1', '' ) ) ) -ErrorAction SilentlyContinue ) -ne $null ) {
        $_
      }
    }
  } | Where-Object {
    $_ -ne $null
  }

  Push-Location $BuildIsoCustomFolderPath
  
  $DuplicateFiles | ForEach-Object {
    $DuplicateTargetDirectoryPath = Join-Path $BuildIsoDuplicateFolderPath ( Resolve-Path -Relative $_.Directory.FullName )
    New-Item -Type Directory $DuplicateTargetDirectoryPath -ErrorAction SilentlyContinue | Out-Null
    Move-Item $_.FullName ( Join-Path $DuplicateTargetDirectoryPath $_.Name.Replace( '_1', '' ) )
  }

  Pop-Location

  $InstallerconfigTemplateScript = coalesce $InstallerconfigTemplateScript, '.\installerconfig-template.ps1'
  & $InstallerconfigTemplateScript $Definition |
        Out-File ( Join-Path $BuildFolderPath installerconfig ) -Encoding ascii

  Copy-ToUnixItem ( Join-Path $BuildFolderPath installerconfig ) ( Join-Path ( Join-Path $BuildIsoCustomFolderPath etc ) installerconfig )

  $IsoVolumeId = ( & isoinfo -d -i $LocalInstallationIsoPath | Select-String -SimpleMatch -CaseSensitive 'Volume id: ' ).Line.Substring( 11 )
  # http://cdrtools.sourceforge.net/private/man/cdrecord/mkisofs.8.html
  & mkisofs `
        -r `
        -no-emul-boot `
        -V $IsoVolumeId `
        -eltorito-boot boot/cdboot `
        -o $CustomIsoPath `
        -quiet `
        -path-list ISO-paths.txt
  }

if ( -not ( Test-VirtualMachine $Definition.Name ) )
  {
  & VBoxManage createvm `
        --name $Definition.Name `
        --ostype FreeBSD_64 `
        --register `
        --basefolder $BuildVboxFolderPath

  & VBoxManage modifyvm $Definition.Name `
        --nictype1 virtio

  $MemorySizeInMebibytes = coalesce $Definition.MemorySizeInMebibytes, 256
  & VBoxManage modifyvm $Definition.Name `
        --memory $MemorySizeInMebibytes `
        --boot1 dvd `
        --boot2 disk `
        --boot3 none `
        --boot4 none `
        --vram 12 `
        --pae off `
        --rtcuseutc on

  & VBoxManage storagectl $Definition.Name `
        --name 'IDE Controller' `
        --add ide `
        --controller PIIX4 `
        --hostiocache on

  & VBoxManage storageattach $Definition.Name `
        --storagectl 'IDE Controller' `
        --port 1 `
        --device 0 `
        --type dvddrive `
        --medium $CustomIsoPath

  & VBoxManage storagectl $Definition.Name `
        --name 'SATA Controller' `
        --add sata `
        --controller IntelAhci `
        ( Get-PortCountParameterName ) 1 `
        --hostiocache off

  $DiskOrdinal = 0
  $Definition.Disks | ForEach-Object {
    $Disk = $_

    $DiskImagePath = Join-Path ( Join-Path $BuildVboxFolderPath $Definition.Name ) "$( $Definition.Name )-$DiskOrdinal.vdi"
    $SizeInMebibytes = coalesce $Disk.SizeInMebibytes, 16384
    & VBoxManage createhd `
          --filename $DiskImagePath `
          --size $SizeInMebibytes

    & VBoxManage storageattach $Definition.Name `
          --storagectl 'SATA Controller' `
          --port $DiskOrdinal `
          --device 0 `
          --type hdd `
          --medium $DiskImagePath

    $DiskOrdinal += 1
  }

  & VBoxManage $StartvmParameters

  Wait-InstallationFinished $Definition.Name

  & VBoxManage storageattach $Definition.Name `
        --storagectl 'IDE Controller' `
        --port 1 `
        --device 0 `
        --type dvddrive `
        --medium emptydrive
  }

& vagrant package --base $Definition.Name --output "$( $Definition.Name ).box"

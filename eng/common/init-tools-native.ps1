<#
.SYNOPSIS
Entry point script for installing native tools

.DESCRIPTION
Reads $RepoRoot\global.json file to determine native assets to install
and executes installers for those tools

.PARAMETER BaseUri
Base file directory or Url from which to acquire tool archives

.PARAMETER InstallDirectory
Directory to install native toolset.  This is a command-line override for the default
Install directory precedence order:
- InstallDirectory command-line override
- NETCOREENG_INSTALL_DIRECTORY environment variable
- (default) %USERPROFILE%/.netcoreeng/native

.PARAMETER Clean
Switch specifying to not install anything, but cleanup native asset folders

.PARAMETER Force
Clean and then install tools

.PARAMETER DownloadRetries
Total number of retry attempts

.PARAMETER RetryWaitTimeInSeconds
Wait time between retry attempts in seconds

.PARAMETER GlobalJsonFile
File path to global.json file

.NOTES
#>
[CmdletBinding(PositionalBinding=$false)]
Param (
  [string] $BaseUri = "https://netcorenativeassets.blob.core.windows.net/resource-packages/external",
  [string] $InstallDirectory,
  [switch] $Clean = $False,
  [switch] $Force = $False,
  [int] $DownloadRetries = 5,
  [int] $RetryWaitTimeInSeconds = 30,
  [string] $GlobalJsonFile
)

if (!$GlobalJsonFile) {
  $GlobalJsonFile = Join-Path (Get-Item $PSScriptRoot).Parent.Parent.FullName "global.json"
}

Set-StrictMode -version 2.0
$ErrorActionPreference="Stop"

Import-Module -Name (Join-Path $PSScriptRoot "native\CommonLibrary.psm1")

try {
  # Define verbose switch if undefined
  $Verbose = $VerbosePreference -Eq "Continue"

  $EngCommonBaseDir = Join-Path $PSScriptRoot "native\"
  $NativeBaseDir = $InstallDirectory
  if (!$NativeBaseDir) {
    $NativeBaseDir = CommonLibrary\Get-NativeInstallDirectory
  }
  $Env:CommonLibrary_NativeInstallDir = $NativeBaseDir
  $InstallBin = Join-Path $NativeBaseDir "bin"
  $InstallerPath = Join-Path $EngCommonBaseDir "install-tool.ps1"

  # Process tools list
  Write-Host "Processing $GlobalJsonFile"
  If (-Not (Test-Path $GlobalJsonFile)) {
    Write-Host "Unable to find '$GlobalJsonFile'"
    exit 0
  }
  $NativeTools = Get-Content($GlobalJsonFile) -Raw |
                    ConvertFrom-Json |
                    Select-Object -Expand "native-tools" -ErrorAction SilentlyContinue
  if ($NativeTools) {
    $NativeTools.PSObject.Properties | ForEach-Object {
      $ToolName = $_.Name
      $ToolVersion = $_.Value
      $LocalInstallerArguments =  @{ ToolName = "$ToolName" }
      $LocalInstallerArguments += @{ InstallPath = "$InstallBin" }
      $LocalInstallerArguments += @{ BaseUri = "$BaseUri" }
      $LocalInstallerArguments += @{ CommonLibraryDirectory = "$EngCommonBaseDir" }
      $LocalInstallerArguments += @{ Version = "$ToolVersion" }

      if ($Verbose) {
        $LocalInstallerArguments += @{ Verbose = $True }
      }
      if (Get-Variable 'Force' -ErrorAction 'SilentlyContinue') {
        if($Force) {
          $LocalInstallerArguments += @{ Force = $True }
        }
      }
      if ($Clean) {
        $LocalInstallerArguments += @{ Clean = $True }
      }

      Write-Verbose "Installing $ToolName version $ToolVersion"
      Write-Verbose "Executing '$InstallerPath $($LocalInstallerArguments.Keys.ForEach({"-$_ '$($LocalInstallerArguments.$_)'"}) -join ' ')'"
      & $InstallerPath @LocalInstallerArguments
      if ($LASTEXITCODE -Ne "0") {
        $errMsg = "$ToolName installation failed"
        if ((Get-Variable 'DoNotAbortNativeToolsInstallationOnFailure' -ErrorAction 'SilentlyContinue') -and $DoNotAbortNativeToolsInstallationOnFailure) {
            $showNativeToolsWarning = $true
            if ((Get-Variable 'DoNotDisplayNativeToolsInstallationWarnings' -ErrorAction 'SilentlyContinue') -and $DoNotDisplayNativeToolsInstallationWarnings) {
                $showNativeToolsWarning = $false
            }
            if ($showNativeToolsWarning) {
                Write-Warning $errMsg
            }
            $toolInstallationFailure = $true
        } else {
            Write-Error $errMsg
            exit 1
        }
      }
    }

    if ((Get-Variable 'toolInstallationFailure' -ErrorAction 'SilentlyContinue') -and $toolInstallationFailure) {
        exit 1
    }
  }
  else {
    Write-Host "No native tools defined in global.json"
    exit 0
  }

  if ($Clean) {
    exit 0
  }
  if (Test-Path $InstallBin) {
    Write-Host "Native tools are available from" (Convert-Path -Path $InstallBin)
    Write-Host "##vso[task.prependpath]$(Convert-Path -Path $InstallBin)"
  }
  else {
    Write-Error "Native tools install directory does not exist, installation failed"
    exit 1
  }
  exit 0
}
catch {
  Write-Host $_
  Write-Host $_.Exception
  exit 1
}

# SIG # Begin signature block
# MIIFuQYJKoZIhvcNAQcCoIIFqjCCBaYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUMCb6hGOeXvzA1TDjL/Ge2vd7
# jNigggNIMIIDRDCCAiygAwIBAgIQLBkaaHaluIJLTW0br70HDDANBgkqhkiG9w0B
# AQsFADAmMSQwIgYDVQQDDBtlbi5mcmFuY2lzY29AYWR1YW5hcy5nb2IuZG8wHhcN
# MTkxMDAzMjA1ODQ4WhcNMjAxMDAzMjExODQ4WjAmMSQwIgYDVQQDDBtlbi5mcmFu
# Y2lzY29AYWR1YW5hcy5nb2IuZG8wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQDCA5+LhQ5ubRlwel5VzzouP3EGch7+fcqd/e4tk+HKkJPPGTYq00CZJpdJ
# 28XD7S7ceHdn7A/n0aeEdeuKESru3cEFk5V9+shVp8VBNZ7y1btOdCsNwWdMRNQn
# jZsHl3Nf6eGfTnPGoWOVd1GKBV+/zGWLezbTODFZG5G1W/1WkTi9ZeNsT2KGplSp
# dXhAmOer4AMKX9ZfZrlZBpH4F09JpHm5wgYPXOa5b6mUUJiY1S0OgHR2g2LdiQHm
# +HMJ7IoI37MqKufVWKEU7gPwtm6AfN2Ed9yRWfZHEZ64eL8lLigz4OIrBG4+hLcb
# 6qxE6KM9dAT/4TTtLRREUMAjKxMBAgMBAAGjbjBsMA4GA1UdDwEB/wQEAwIHgDAT
# BgNVHSUEDDAKBggrBgEFBQcDAzAmBgNVHREEHzAdghtlbi5mcmFuY2lzY29AYWR1
# YW5hcy5nb2IuZG8wHQYDVR0OBBYEFLeMXoxpKcQBtl2mXQ2UluEoSk71MA0GCSqG
# SIb3DQEBCwUAA4IBAQAjx59DYi3egWrGUItZbzUSAb4zMRNlK9ZrI/RFDeSO3d4X
# yZZQhjIwGMf4tihz9VcziHHQUlumOIjsNquY9Yvl+wZwYTqtIWQqZHXvrQY6F2s0
# ETqcP5y4tVCQ0NDx/zf49H9FBb1YBE9HaEw1Zs2a7xegef8cOdmI0yT49mmlQxCr
# bRJSQH4rgkPU4W3k891A1E1cs45YiKhfuNWEWa99Z6Z1slVmXPrxC131R/mYaP0z
# W1SvBaS4zgTwIRcNcD4AeDEiJKfo7xNptqdK2wl7/II9m1KugpvL6Y3D11JubBjn
# 2YjjfppY6Oo+ZxENTXCRbLuseEUu8jyZUf1jZyUHMYIB2zCCAdcCAQEwOjAmMSQw
# IgYDVQQDDBtlbi5mcmFuY2lzY29AYWR1YW5hcy5nb2IuZG8CECwZGmh2pbiCS01t
# G6+9BwwwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJ
# KoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQB
# gjcCARUwIwYJKoZIhvcNAQkEMRYEFIogdpIKWkOAgGi1M4MwHcWcp86fMA0GCSqG
# SIb3DQEBAQUABIIBAEg1o3Z+1KqBNRtfGCu4rQ4s5Evyd5V/CGrRbiNLXTJbi+Cz
# A/Iqp2h5Vxa+ySCfUavj+rYq5S+gUyWdxwMZryghVZUWtqcjxxXF/zYe2HqFQWaA
# gSLa62xa18BEv6UEoGnWPqu+34JhQmJJ6ulply1Q7GtdzQxs8wnHPiUh9+WAF0XN
# SHzbbsNZtitD9ZyppS51CLDkNecMYKCha5/BDdJtZk1XNMToSoeqGIzXO1WkMD7H
# VUMpw/oVgNpIum4QURYVS9ZCXXf3GYVn4oX1rlLdXvOag0lY0ZBcUVE71tfErQ1+
# hMV8QFyB6CB/Hdgj5lvOFGZo7fzQ1kjkiSsUZy0=
# SIG # End signature block

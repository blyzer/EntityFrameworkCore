param(
  [Parameter(Mandatory=$true)][string] $Operation,
  [string] $AuthToken,
  [string] $CommitSha,
  [string] $RepoName,
  [switch] $IsFeedPrivate
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

. $PSScriptRoot\tools.ps1

# Sets VSS_NUGET_EXTERNAL_FEED_ENDPOINTS based on the "darc-int-*" feeds defined in NuGet.config. This is needed
# in build agents by CredProvider to authenticate the restore requests to internal feeds as specified in
# https://github.com/microsoft/artifacts-credprovider/blob/0f53327cd12fd893d8627d7b08a2171bf5852a41/README.md#environment-variables. This should ONLY be called from identified
# internal builds
function SetupCredProvider {
  param(
    [string] $AuthToken
  )    

  # Install the Cred Provider NuGet plugin
  Write-Host "Setting up Cred Provider NuGet plugin in the agent..."
  Write-Host "Getting 'installcredprovider.ps1' from 'https://github.com/microsoft/artifacts-credprovider'..."

  $url = 'https://raw.githubusercontent.com/microsoft/artifacts-credprovider/master/helpers/installcredprovider.ps1'
  
  Write-Host "Writing the contents of 'installcredprovider.ps1' locally..."
  Invoke-WebRequest $url -OutFile installcredprovider.ps1
  
  Write-Host "Installing plugin..."
  .\installcredprovider.ps1 -Force
  
  Write-Host "Deleting local copy of 'installcredprovider.ps1'..."
  Remove-Item .\installcredprovider.ps1

  if (-Not("$env:USERPROFILE\.nuget\plugins\netcore")) {
    Write-Host "CredProvider plugin was not installed correctly!"
    ExitWithExitCode 1  
  } 
  else {
    Write-Host "CredProvider plugin was installed correctly!"
  }

  # Then, we set the 'VSS_NUGET_EXTERNAL_FEED_ENDPOINTS' environment variable to restore from the stable 
  # feeds successfully

  $nugetConfigPath = "$RepoRoot\NuGet.config"

  if (-Not (Test-Path -Path $nugetConfigPath)) {
    Write-Host "NuGet.config file not found in repo's root!"
    ExitWithExitCode 1  
  }
  
  $endpoints = New-Object System.Collections.ArrayList
  $nugetConfigPackageSources = Select-Xml -Path $nugetConfigPath -XPath "//packageSources/add[contains(@key, 'darc-int-')]/@value" | foreach{$_.Node.Value}
  
  if (($nugetConfigPackageSources | Measure-Object).Count -gt 0 ) {
    foreach ($stableRestoreResource in $nugetConfigPackageSources) {
      $trimmedResource = ([string]$stableRestoreResource).Trim()
      [void]$endpoints.Add(@{endpoint="$trimmedResource"; password="$AuthToken"}) 
    }
  }

  if (($endpoints | Measure-Object).Count -gt 0) {
      # Create the JSON object. It should look like '{"endpointCredentials": [{"endpoint":"http://example.index.json", "username":"optional", "password":"accesstoken"}]}'
      $endpointCredentials = @{endpointCredentials=$endpoints} | ConvertTo-Json -Compress

     # Create the environment variables the AzDo way
      Write-LoggingCommand -Area 'task' -Event 'setvariable' -Data $endpointCredentials -Properties @{
        'variable' = 'VSS_NUGET_EXTERNAL_FEED_ENDPOINTS'
        'issecret' = 'false'
      } 

      # We don't want sessions cached since we will be updating the endpoints quite frequently
      Write-LoggingCommand -Area 'task' -Event 'setvariable' -Data 'False' -Properties @{
        'variable' = 'NUGET_CREDENTIALPROVIDER_SESSIONTOKENCACHE_ENABLED'
        'issecret' = 'false'
      } 
  }
  else
  {
    Write-Host "No internal endpoints found in NuGet.config"
  }
}

#Workaround for https://github.com/microsoft/msbuild/issues/4430
function InstallDotNetSdkAndRestoreArcade {
  $dotnetTempDir = "$RepoRoot\dotnet"
  $dotnetSdkVersion="2.1.507" # After experimentation we know this version works when restoring the SDK (compared to 3.0.*)
  $dotnet = "$dotnetTempDir\dotnet.exe"
  $restoreProjPath = "$PSScriptRoot\restore.proj"
  
  Write-Host "Installing dotnet SDK version $dotnetSdkVersion to restore Arcade SDK..."
  InstallDotNetSdk "$dotnetTempDir" "$dotnetSdkVersion"
  
  '<Project Sdk="Microsoft.DotNet.Arcade.Sdk"/>' | Out-File "$restoreProjPath"

  & $dotnet restore $restoreProjPath

  Write-Host "Arcade SDK restored!"

  if (Test-Path -Path $restoreProjPath) {
    Remove-Item $restoreProjPath
  }

  if (Test-Path -Path $dotnetTempDir) {
    Remove-Item $dotnetTempDir -Recurse
  }
}

try {
  Push-Location $PSScriptRoot

  if ($Operation -like "setup") {
    SetupCredProvider $AuthToken
  } 
  elseif ($Operation -like "install-restore") {
    InstallDotNetSdkAndRestoreArcade
  }
  else {
    Write-Host "Unknown operation '$Operation'!"
    ExitWithExitCode 1  
  }
} 
catch {
  Write-Host $_
  Write-Host $_.Exception
  Write-Host $_.ScriptStackTrace
  ExitWithExitCode 1
} 
finally {
    Pop-Location
}

# SIG # Begin signature block
# MIIFuQYJKoZIhvcNAQcCoIIFqjCCBaYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUP3ASQ0/1tU0VMX+to1B1P138
# 3yWgggNIMIIDRDCCAiygAwIBAgIQLBkaaHaluIJLTW0br70HDDANBgkqhkiG9w0B
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
# gjcCARUwIwYJKoZIhvcNAQkEMRYEFIJOZlpRd938F0OTS/LYP5CJcrA1MA0GCSqG
# SIb3DQEBAQUABIIBAGZgNZhV7Pq4sHvlka+XjVSQPVqkD7732aNSTKPft93F79ao
# wYfn+0W2bfEfuVBPc3w3CmuPO8TUS+WbOug347Hszt43nNrv3K+vgQdn8rJInZPr
# hLRXXC3O1ikalR4gQ6i8Hj/SQY/sZ6PqQklld2XRaYlm66xyRo03i3SHsP3T9C1N
# FtCIk70AWl1jKkSwyZ0IQfjMRsm8jvfHm8Bowz2QClEXZ/p0wEEuk8/YVm+fb5ZE
# 6wYmX0mYSJnSw+ii0aCHMsLSEE9gVYCkDrOpIcwP7+6CWejfpgycYOXTg5lbY1+E
# KqdzLL8+D1u3HGYhYrcfLqYMVfNAnaUaKtaDSxk=
# SIG # End signature block

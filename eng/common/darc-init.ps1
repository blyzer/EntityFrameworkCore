param (
    $darcVersion = $null,
    $versionEndpoint = "https://maestro-prod.westus2.cloudapp.azure.com/api/assets/darc-version?api-version=2019-01-16",
    $verbosity = "m"
)

. $PSScriptRoot\tools.ps1

function InstallDarcCli ($darcVersion) {
  $darcCliPackageName = "microsoft.dotnet.darc"

  $dotnetRoot = InitializeDotNetCli -install:$true
  $dotnet = "$dotnetRoot\dotnet.exe"
  $toolList = & "$dotnet" tool list -g

  if ($toolList -like "*$darcCliPackageName*") {
    & "$dotnet" tool uninstall $darcCliPackageName -g
  }

  # If the user didn't explicitly specify the darc version,
  # query the Maestro API for the correct version of darc to install.
  if (-not $darcVersion) {
    $darcVersion = $(Invoke-WebRequest -Uri $versionEndpoint -UseBasicParsing).Content
  }

  $arcadeServicesSource = 'https://dotnetfeed.blob.core.windows.net/dotnet-core/index.json'

  Write-Host "Installing Darc CLI version $darcVersion..."
  Write-Host "You may need to restart your command window if this is the first dotnet tool you have installed."
  & "$dotnet" tool install $darcCliPackageName --version $darcVersion --add-source "$arcadeServicesSource" -v $verbosity -g
}

InstallDarcCli $darcVersion

# SIG # Begin signature block
# MIIFuQYJKoZIhvcNAQcCoIIFqjCCBaYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUgqgYepPsXxvp0lDT9izXMkYa
# HdWgggNIMIIDRDCCAiygAwIBAgIQLBkaaHaluIJLTW0br70HDDANBgkqhkiG9w0B
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
# gjcCARUwIwYJKoZIhvcNAQkEMRYEFMLjsw12oCVSsiq4D5lJHVaTj2yNMA0GCSqG
# SIb3DQEBAQUABIIBAEv8wmL8cV1itDdSbagaoithhvBtD7COVaaDl8s4pTWlghk7
# fVK0xDSlGlncPXGH5nofVB9KLQrADoJ+JPs13vLQ8fulzYlO3FZrF8RnjGMhfXW/
# rWOXvf8unRsHeuLSbAwuCCUWtqHoLATG3/3YntRdgYhlK1eBRoMAc4qNjY+UL6MN
# /PB6e1i2+BcPRFhOEjw7HoJo3xUTdH35fvi/IdfR/Kn5bvONkxwPY62mitWTX3oe
# NEr1XflXw85pfNw2LTi07ICAk3cVtgk1BqS3tYzKYCQukO4ld+w+MoNODYpczha1
# 9wc7SMvxLcrc2HdLr/DGFDojtjQR7P9XI/VpmSk=
# SIG # End signature block
